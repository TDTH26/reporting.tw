"""Atreides maritime sensor (MDA) section: batches, summary and tracks for the console, plus the CSV feed.

Staff (except field officers) read; admins upload or delete batches. Atreides can push exports directly to
POST /v1/ingest/atreides with a feed key that lists the "atreides" source.
"""

import hmac
from collections import Counter, defaultdict
from datetime import UTC, datetime

from fastapi import APIRouter, Depends, File, Form, Header, HTTPException, Query, Request, UploadFile
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from .. import atreides
from ..db.models import AtreidesBatch, AtreidesDetection, FeedClient
from ..db.session import get_session
from ..security.audit import audit
from ..security.auth import require
from ..security.hashing import keyed_hash
from ..security.principal import ROLE_ADMIN, ROLE_ANALYST, ROLE_DISPATCHER, ROLE_NATIONAL, ROLE_SUPERVISOR, Principal

router = APIRouter(prefix="/v1/atreides", tags=["atreides"])
feed_router = APIRouter(prefix="/v1/ingest", tags=["ingestion"])

FEED = "atreides"
MAX_CSV_BYTES = 50 * 1024 * 1024
readers = require(ROLE_DISPATCHER, ROLE_SUPERVISOR, ROLE_ANALYST, ROLE_ADMIN, ROLE_NATIONAL)


def _iso(t: datetime | None) -> str | None:
    return t.astimezone(UTC).isoformat().replace("+00:00", "Z") if t else None


def _batch(b: AtreidesBatch) -> dict:
    return {
        "id": b.id,
        "filename": b.filename,
        "rows": b.rows,
        "accepted": b.accepted,
        "dropped": b.dropped,
        "tracks": b.tracks,
        "first_at": _iso(b.first_at),
        "last_at": _iso(b.last_at),
        "shifted_s": b.shifted_s,
        "received_via": b.received_via,
        "received_by": b.received_by,
        "created_at": _iso(b.created_at),
    }


def _filters(batch_id: int | None, role: str | None):
    conds = []
    if batch_id is not None:
        conds.append(AtreidesDetection.batch_id == batch_id)
    if role:
        conds.append(AtreidesDetection.role == role)
    return conds


@router.get("/batches")
async def batches(_: Principal = Depends(readers), session: AsyncSession = Depends(get_session)) -> list[dict]:
    rows = (await session.execute(select(AtreidesBatch).order_by(AtreidesBatch.id.desc()))).scalars()
    return [_batch(b) for b in rows]


@router.get("/summary")
async def summary(
    batch_id: int | None = None,
    _: Principal = Depends(readers),
    session: AsyncSession = Depends(get_session),
) -> dict:
    conds = _filters(batch_id, None)
    D = AtreidesDetection
    agg = (
        await session.execute(
            select(
                func.count(),
                func.count(func.distinct(D.track_id)),
                func.min(D.at),
                func.max(D.at),
                func.min(D.lat),
                func.min(D.lon),
                func.max(D.lat),
                func.max(D.lon),
            ).where(*conds)
        )
    ).one()
    by_role = dict((await session.execute(select(D.role, func.count()).where(*conds).group_by(D.role))).all())
    by_conf = dict(
        (
            await session.execute(
                select(D.primary_confidence, func.count()).where(*conds).group_by(D.primary_confidence)
            )
        ).all()
    )
    route_rows = (await session.execute(select(func.count()).where(*conds, D.track_id.like("%-R%")))).scalar_one()
    routes = (
        await session.execute(select(func.count(func.distinct(D.track_id))).where(*conds, D.track_id.like("%-R%")))
    ).scalar_one()
    return {
        "detections": agg[0],
        "tracks": agg[1],
        "routes": routes,
        "route_detections": route_rows,
        "single_contacts": agg[0] - route_rows,
        "first_at": _iso(agg[2]),
        "last_at": _iso(agg[3]),
        "bbox": None
        if agg[4] is None
        else {"min_lat": agg[4], "min_lon": agg[5], "max_lat": agg[6], "max_lon": agg[7]},
        "by_role": {r: by_role.get(r, 0) for r in atreides.ROLES},
        "by_confidence": {c: by_conf.get(c, 0) for c in ("high", "low")},
    }


@router.get("/tracks")
async def tracks(
    batch_id: int | None = None,
    role: str | None = Query(None, pattern="^(mobile_asset|fixed_site|ambiguous)$"),
    min_points: int = Query(1, ge=1),
    high_confidence: bool = False,
    limit: int = Query(3000, le=20000),
    _: Principal = Depends(readers),
    session: AsyncSession = Depends(get_session),
) -> list[dict]:
    """Routes (several detections) and single contacts; positions in time order."""
    D = AtreidesDetection
    conds = _filters(batch_id, role)
    if high_confidence:
        conds.append(D.primary_confidence == "high")
    rows = (await session.execute(select(D).where(*conds).order_by(D.track_id, D.at))).scalars()
    by_track: dict[str, list[AtreidesDetection]] = defaultdict(list)
    for d in rows:
        by_track[d.track_id].append(d)
    out = []
    for tid, ds in by_track.items():
        if len(ds) < min_points:
            continue
        first, last = ds[0], ds[-1]
        out.append(
            {
                "track_id": tid,
                "batch_id": first.batch_id,
                "role": Counter(d.role for d in ds).most_common(1)[0][0],
                "confidence": first.primary_confidence,
                "reasoning": first.primary_reasoning,
                "source_role": first.source_role,
                "source_confidence": first.source_confidence,
                "source_reasoning": first.source_reasoning,
                "points": len(ds),
                "span_km": first.primary_route_span_km if len(ds) > 1 else 0,
                "first_at": _iso(first.at),
                "last_at": _iso(last.at),
                "last": {"lat": last.lat, "lon": last.lon},
                "path": [[d.lat, d.lon] for d in ds] if len(ds) > 1 else [],
            }
        )
    out.sort(key=lambda t: (-t["points"], t["last_at"] or ""))
    return out[:limit]


@router.post("/batches", status_code=201)
async def upload(
    request: Request,
    file: UploadFile = File(...),
    shift_to_now: bool = Form(False),
    p: Principal = Depends(require(ROLE_ADMIN)),
    session: AsyncSession = Depends(get_session),
) -> dict:
    data = await file.read(MAX_CSV_BYTES + 1)
    if len(data) > MAX_CSV_BYTES:
        raise HTTPException(413, "file too large")
    try:
        b = await atreides.import_csv(
            session, data.decode("utf-8-sig"), file.filename or "upload.csv", "upload", p.username, shift_to_now
        )
    except (atreides.ParseError, UnicodeDecodeError) as e:
        raise HTTPException(422, str(e)) from e
    await audit(session, p, "atreides.upload", "atreides_batch", str(b.id), request, rows=b.accepted)
    out = _batch(b)
    await session.commit()
    return out


@router.delete("/batches/{batch_id}", status_code=204)
async def remove(
    batch_id: int,
    request: Request,
    p: Principal = Depends(require(ROLE_ADMIN)),
    session: AsyncSession = Depends(get_session),
) -> None:
    if not await atreides.delete_batch(session, batch_id):
        raise HTTPException(404, "batch not found")
    await audit(session, p, "atreides.delete", "atreides_batch", str(batch_id), request)
    await session.commit()


@feed_router.post("/atreides", status_code=201)
async def feed(
    request: Request,
    filename: str = Query("feed.csv", max_length=255),
    shift_to_now: bool = False,
    x_feed_key: str = Header(..., alias="X-Feed-Key"),
    session: AsyncSession = Depends(get_session),
) -> dict:
    """Atreides pushes an export as text/csv (same columns as the sample file)."""
    h = keyed_hash("feed", x_feed_key)
    fc = (await session.execute(select(FeedClient).where(FeedClient.key_hash == h))).scalar_one_or_none()
    if fc is None or not fc.active or not hmac.compare_digest(fc.key_hash, h):
        raise HTTPException(401, "unknown feed key")
    if FEED not in fc.sources:
        raise HTTPException(403, "this key may not post to atreides")
    data = await request.body()
    if len(data) > MAX_CSV_BYTES:
        raise HTTPException(413, "file too large")
    try:
        b = await atreides.import_csv(session, data.decode("utf-8-sig"), filename, "feed", fc.name[:64], shift_to_now)
    except (atreides.ParseError, UnicodeDecodeError) as e:
        raise HTTPException(422, str(e)) from e
    fc.last_used = datetime.now(UTC)
    out = _batch(b)
    await session.commit()
    return out
