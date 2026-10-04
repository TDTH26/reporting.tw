"""Administration: zones and routing, desks, templates, feed credentials, audit log."""

import hashlib
import uuid
from datetime import UTC, datetime

from fastapi import APIRouter, Depends, File, Form, HTTPException, Query, Request, UploadFile
from pydantic import BaseModel, Field
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from ..db.models import AiJob, AppUser, AuditLog, Desk, FeedClient, StaffSession, Template, VideoFeed, Zone
from ..db.session import get_session
from ..domain.enums import LANGUAGES, ZoneType
from ..feeds.validate import FEEDS
from ..geoutil import bounds, normalize_multipolygon
from ..live.bus import publish_broadcast
from ..security.audit import audit
from ..security.auth import require
from ..security.passwords import hash_password, policy_error
from ..security.principal import ROLE_ADMIN, ROLE_SUPERVISOR, STAFF_ROLES, Principal
from ..storage import files
from .agency_schemas import DeskIn, FeedClientIn, TemplateIn, UserIn, UserUpdateIn, ZoneIn
from .atreides import FEED as ATREIDES_FEED
from .ingest import mint_feed_key

router = APIRouter(prefix="/v1/admin", tags=["admin"])
ADMIN = require(ROLE_ADMIN)


def _zone_values(body: ZoneIn) -> dict:
    if body.zone_type not in ZoneType.__members__:
        raise HTTPException(422, f"zone_type must be one of {list(ZoneType.__members__)}")
    try:
        geom = normalize_multipolygon(body.geometry)
    except Exception as e:
        raise HTTPException(422, f"invalid geometry: {e}") from e
    v = body.model_dump(exclude={"geometry"})
    v["geometry"] = geom
    v["min_lat"], v["min_lon"], v["max_lat"], v["max_lon"] = bounds(geom)
    return v


@router.post("/zones", status_code=201)
async def create_zone(
    body: ZoneIn, request: Request, p: Principal = Depends(ADMIN), session: AsyncSession = Depends(get_session)
) -> dict:
    if p.clearance < body.classification:
        raise HTTPException(403, "cannot create a zone above your clearance")
    z = Zone(**_zone_values(body))
    session.add(z)
    await session.flush()
    await audit(session, p, "zone.create", "zone", str(z.id), request, code=z.code)
    await publish_broadcast(session, "zones.changed", {"zone_id": z.id}, min_clearance=z.classification)
    await session.commit()
    return {"id": z.id}


@router.put("/zones/{zone_id}")
async def update_zone(
    zone_id: int,
    body: ZoneIn,
    request: Request,
    p: Principal = Depends(ADMIN),
    session: AsyncSession = Depends(get_session),
) -> dict:
    z = await session.get(Zone, zone_id)
    if z is None or z.classification > p.clearance or body.classification > p.clearance:
        raise HTTPException(404, "zone not found")
    for k, v in _zone_values(body).items():
        setattr(z, k, v)
    await audit(session, p, "zone.update", "zone", str(z.id), request, code=z.code)
    await publish_broadcast(session, "zones.changed", {"zone_id": z.id}, min_clearance=z.classification)
    await session.commit()
    return {"id": z.id}


@router.post("/desks", status_code=201)
async def create_desk(
    body: DeskIn, request: Request, p: Principal = Depends(ADMIN), session: AsyncSession = Depends(get_session)
) -> dict:
    d = Desk(**body.model_dump())
    session.add(d)
    await session.flush()
    await audit(session, p, "desk.create", "desk", str(d.id), request, code=d.code)
    await session.commit()
    return {"id": d.id}


@router.put("/desks/{desk_id}")
async def update_desk(
    desk_id: int,
    body: DeskIn,
    request: Request,
    p: Principal = Depends(ADMIN),
    session: AsyncSession = Depends(get_session),
) -> dict:
    d = await session.get(Desk, desk_id)
    if d is None:
        raise HTTPException(404, "desk not found")
    for k, v in body.model_dump().items():
        setattr(d, k, v)
    await audit(session, p, "desk.update", "desk", str(d.id), request)
    await session.commit()
    return {"id": d.id}


@router.put("/templates/{code}")
async def upsert_template(
    code: str,
    body: TemplateIn,
    request: Request,
    p: Principal = Depends(ADMIN),
    session: AsyncSession = Depends(get_session),
) -> dict:
    missing = [lang for lang in LANGUAGES if not body.texts.get(lang)]
    if missing:
        raise HTTPException(422, f"templates must be translated into every language; missing {missing}")
    t = await session.get(Template, code)
    if t is None:
        t = Template(code=code)
        session.add(t)
    for k, v in body.model_dump(exclude={"code"}).items():
        setattr(t, k, v)
    await audit(session, p, "template.upsert", "template", code, request)
    await session.commit()
    return {"code": code}


@router.get("/feed-clients")
async def feed_clients(p: Principal = Depends(ADMIN), session: AsyncSession = Depends(get_session)) -> list[dict]:
    rows = (await session.execute(select(FeedClient).order_by(FeedClient.id))).scalars()
    return [
        {
            "id": f.id,
            "name": f.name,
            "sources": f.sources,
            "classification": f.classification,
            "active": f.active,
            "last_used": f.last_used.isoformat() if f.last_used else None,
        }
        for f in rows
    ]


@router.post("/feed-clients", status_code=201)
async def create_feed_client(
    body: FeedClientIn, request: Request, p: Principal = Depends(ADMIN), session: AsyncSession = Depends(get_session)
) -> dict:
    bad = [s for s in body.sources if s not in FEEDS and s != ATREIDES_FEED]
    if bad:
        raise HTTPException(422, f"unknown feeds {bad}")
    key, h = mint_feed_key()
    fc = FeedClient(name=body.name, sources=body.sources, classification=body.classification, key_hash=h)
    session.add(fc)
    await session.flush()
    await audit(session, p, "feed_client.create", "feed_client", str(fc.id), request, name=body.name)
    await session.commit()
    return {"id": fc.id, "key": key, "note": "The key is shown once. Store it in the feed system's secret store."}


@router.post("/feed-clients/{fc_id}/revoke")
async def revoke_feed_client(
    fc_id: int, request: Request, p: Principal = Depends(ADMIN), session: AsyncSession = Depends(get_session)
) -> dict:
    fc = await session.get(FeedClient, fc_id)
    if fc is None:
        raise HTTPException(404, "not found")
    fc.active = False
    await audit(session, p, "feed_client.revoke", "feed_client", str(fc.id), request)
    await session.commit()
    return {"id": fc.id, "active": False}


@router.get("/audit")
async def audit_log(
    user: str | None = None,
    action: str | None = None,
    object_id: str | None = None,
    frm: datetime | None = Query(None, alias="from"),
    to: datetime | None = None,
    limit: int = Query(200, le=2000),
    p: Principal = Depends(require(ROLE_ADMIN, ROLE_SUPERVISOR)),
    session: AsyncSession = Depends(get_session),
) -> list[dict]:
    q = select(AuditLog).order_by(AuditLog.at.desc()).limit(limit)
    if user:
        q = q.where(AuditLog.username == user)
    if action:
        q = q.where(AuditLog.action.like(f"{action}%"))
    if object_id:
        q = q.where(AuditLog.object_id == object_id)
    if frm:
        q = q.where(AuditLog.at >= frm)
    if to:
        q = q.where(AuditLog.at <= to)
    await audit(session, p, "audit.view", None, None, None, filters={"user": user, "action": action})
    rows = (await session.execute(q)).scalars().all()
    await session.commit()
    return [
        {
            "id": a.id,
            "at": a.at.isoformat(),
            "username": a.username,
            "action": a.action,
            "object_type": a.object_type,
            "object_id": a.object_id,
            "ip": a.ip,
            "details": a.details,
        }
        for a in rows
    ]


# ------------------------------------------------------------------ staff accounts


def _user_view(u: AppUser) -> dict:
    return {
        "id": str(u.id),
        "username": u.username,
        "display_name": u.display_name,
        "active": u.active,
        "roles": u.roles,
        "agency_id": u.agency_id,
        "desk_id": u.desk_id,
        "clearance": u.clearance,
        "field_unit": u.field_unit,
        "language": u.language,
        "on_duty": u.on_duty,
        "locked": bool(u.locked_until and u.locked_until > datetime.now(UTC)),
        "last_seen": u.last_seen.isoformat() if u.last_seen else None,
        "has_password": bool(u.password_hash),
    }


async def _apply_user(session: AsyncSession, u: AppUser, body) -> None:
    if bad := [r for r in body.roles if r not in STAFF_ROLES]:
        raise HTTPException(422, f"unknown roles {bad}")
    if body.desk_id is not None:
        desk = await session.get(Desk, body.desk_id)
        if desk is None:
            raise HTTPException(422, "unknown desk")
        u.agency_id = desk.agency_id
    else:
        u.agency_id = body.agency_id
    u.desk_id, u.roles, u.clearance = body.desk_id, sorted(body.roles), body.clearance
    u.field_unit, u.language, u.display_name = body.field_unit, body.language, body.display_name


@router.get("/users")
async def list_users(p: Principal = Depends(ADMIN), session: AsyncSession = Depends(get_session)) -> list[dict]:
    return [_user_view(u) for u in (await session.execute(select(AppUser).order_by(AppUser.username))).scalars()]


@router.post("/users", status_code=201)
async def create_user(
    body: UserIn, request: Request, p: Principal = Depends(ADMIN), session: AsyncSession = Depends(get_session)
) -> dict:
    if (await session.execute(select(AppUser).where(AppUser.username == body.username))).scalar_one_or_none():
        raise HTTPException(409, "username exists")
    if err := policy_error(body.password, body.username):
        raise HTTPException(422, err)
    if body.clearance > p.clearance:
        raise HTTPException(403, "cannot grant a clearance above your own")
    u = AppUser(id=uuid.uuid4(), username=body.username, password_hash=hash_password(body.password), active=True)
    await _apply_user(session, u, body)
    session.add(u)
    await session.flush()
    await audit(session, p, "user.create", "user", str(u.id), request, username=u.username, roles=u.roles)
    await session.commit()
    return _user_view(u)


@router.put("/users/{user_id}")
async def update_user(
    user_id: uuid.UUID,
    body: UserUpdateIn,
    request: Request,
    p: Principal = Depends(ADMIN),
    session: AsyncSession = Depends(get_session),
) -> dict:
    u = await session.get(AppUser, user_id)
    if u is None:
        raise HTTPException(404, "user not found")
    if body.clearance > p.clearance:
        raise HTTPException(403, "cannot grant a clearance above your own")
    await _apply_user(session, u, body)
    revoke = False
    if body.password:
        if err := policy_error(body.password, u.username):
            raise HTTPException(422, err)
        u.password_hash, u.failed_logins, u.locked_until = hash_password(body.password), 0, None
        u.password_changed_at, revoke = datetime.now(UTC), True
    if body.active is not None and body.active != u.active:
        if user_id == p.user_id and not body.active:
            raise HTTPException(409, "you cannot deactivate yourself")
        u.active, revoke = body.active, revoke or not body.active
    if revoke:
        await session.execute(update(StaffSession).where(StaffSession.user_id == u.id).values(revoked=True))
    await audit(
        session,
        p,
        "user.update",
        "user",
        str(u.id),
        request,
        roles=u.roles,
        active=u.active,
        password_reset=bool(body.password),
    )
    await session.commit()
    return _user_view(u)


class VideoFeedIn(BaseModel):
    id: str = Field(..., pattern=r"^[A-Za-z0-9_.-]{1,64}$")
    name: str = Field(..., max_length=200)
    owner: str | None = Field(None, max_length=200)
    lat: float = Field(..., ge=-90, le=90)
    lon: float = Field(..., ge=-180, le=180)
    bearing_deg: float | None = Field(None, ge=0, lt=360)
    fov_deg: float | None = Field(None, gt=0, le=180)
    domains: list[str] = ["aerial", "surface"]
    sample_interval_s: int = Field(120, ge=1, le=86400)
    snapshot_url: str | None = None
    stream_url: str | None = None
    # Watch area in image coordinates: polygon [[x, y], ...] with 0..1 values (e.g. a runway or pier).
    alert_zone: list[list[float]] | None = None
    active: bool = True


@router.put("/video-feeds/{feed_id}")
async def upsert_video_feed(
    feed_id: str,
    body: VideoFeedIn,
    request: Request,
    p: Principal = Depends(require(ROLE_ADMIN)),
    session: AsyncSession = Depends(get_session),
) -> dict:
    if body.id != feed_id:
        raise HTTPException(422, "id in the body must match the URL")
    if body.alert_zone is not None and (
        len(body.alert_zone) < 3 or any(len(pt) != 2 or not all(0 <= c <= 1 for c in pt) for pt in body.alert_zone)
    ):
        raise HTTPException(422, "alert_zone needs 3+ points with x, y between 0 and 1")
    f = await session.get(VideoFeed, feed_id)
    if f is None:
        f = VideoFeed(id=feed_id)
        session.add(f)
    for k, v in body.model_dump().items():
        setattr(f, k, v)
    await audit(session, p, "admin.video_feed", "video_feed", feed_id, request)
    await session.commit()
    return {"id": feed_id}


@router.post("/video-feeds/{feed_id}/frames", status_code=202)
async def upload_frame(
    feed_id: str,
    file: UploadFile = File(...),
    captured_at: datetime | None = Form(None),
    p: Principal = Depends(require(ROLE_ADMIN)),
    session: AsyncSession = Depends(get_session),
) -> dict:
    """Queue one frame for detection and tracking, as if the camera had sent it (recorded video replays)."""
    f = await session.get(VideoFeed, feed_id)
    if f is None:
        raise HTTPException(404, "video feed not found")
    data = await file.read(8 << 20 + 1)
    if len(data) > 8 << 20 or not data.startswith(b"\xff\xd8"):
        raise HTTPException(422, "send a JPEG frame up to 8 MB")
    at = (captured_at or datetime.now(UTC)).astimezone(UTC)
    digest = hashlib.sha256(data).hexdigest()
    key = f"frames/{f.id}/{at:%Y%m%dT%H%M%S%f}-{digest[:12]}.jpg"
    files.put_bytes(key, data, "image/jpeg")
    job = AiJob(kind="frame", priority=8, feed_id=f.id, frame_key=key, frame_at=at)
    session.add(job)
    await session.commit()
    return {"job_id": job.id, "frame_key": key}
