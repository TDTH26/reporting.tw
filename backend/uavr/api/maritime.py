"""Maritime behaviour alerts: review queue, explanations, operator decisions, thresholds and evaluation.

Readers: every console role except field officers. Decisions and notes: dispatchers, supervisors, national,
admins. Thresholds, re-runs and the simulator: supervisors and admins.
"""

from datetime import UTC, datetime, timedelta
from typing import Literal

from fastapi import APIRouter, Body, Depends, HTTPException, Query, Request
from pydantic import BaseModel, Field
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from ..anomaly import engine
from ..anomaly import settings as anomaly_settings
from ..anomaly.simulate import simulate
from ..db.models import AnomalyEvaluation, AnomalySetting, TrackAlert, TrackAlertEvent, Zone
from ..db.session import get_session
from ..security.audit import audit
from ..security.auth import require
from ..security.principal import (
    ROLE_ADMIN,
    ROLE_ANALYST,
    ROLE_DISPATCHER,
    ROLE_NATIONAL,
    ROLE_SUPERVISOR,
    Principal,
)

router = APIRouter(prefix="/v1/maritime", tags=["maritime"])
readers = require(ROLE_DISPATCHER, ROLE_SUPERVISOR, ROLE_ANALYST, ROLE_ADMIN, ROLE_NATIONAL)
deciders = require(ROLE_DISPATCHER, ROLE_SUPERVISOR, ROLE_ADMIN, ROLE_NATIONAL)
tuners = require(ROLE_SUPERVISOR, ROLE_ADMIN)


def _iso(t: datetime | None) -> str | None:
    return t.astimezone(UTC).isoformat().replace("+00:00", "Z") if t else None


def _alert(a: TrackAlert) -> dict:
    return {
        "id": a.id,
        "source_id": a.source_id,
        "source_kind": a.source_kind,
        "track_id": a.track_id,
        "kinds": a.kinds,
        "method": a.method,
        "score": a.score,
        "rule_score": a.rule_score,
        "stat_score": a.stat_score,
        "confidence": a.confidence,
        "reasons": a.reasons,
        "uncertainty": a.uncertainty,
        "status": a.status,
        "first_at": _iso(a.first_at),
        "last_at": _iso(a.last_at),
        "position": {"lat": a.lat, "lon": a.lon},
        "zone_ids": a.zone_ids,
        "case_id": str(a.case_id) if a.case_id else None,
        "suppress_until": _iso(a.suppress_until),
        "updated_by": a.updated_by,
        "updated_at": _iso(a.updated_at),
    }


@router.get("/alerts")
async def alerts(
    status: str = Query("open,acknowledged", description="comma-separated; 'all' for every status"),
    source_id: str | None = None,
    kind: str | None = None,
    min_score: int = 0,
    limit: int = Query(300, le=2000),
    _: Principal = Depends(readers),
    session: AsyncSession = Depends(get_session),
) -> dict:
    q = select(TrackAlert).where(TrackAlert.score >= min_score)
    if status != "all":
        q = q.where(TrackAlert.status.in_([s for s in status.split(",") if s]))
    if source_id:
        q = q.where(TrackAlert.source_id == source_id)
    if kind:
        q = q.where(func.json_contains(TrackAlert.kinds, f'"{kind}"'))
    rows = (
        await session.execute(q.order_by(TrackAlert.score.desc(), TrackAlert.last_at.desc()).limit(limit))
    ).scalars()
    counts = dict((await session.execute(select(TrackAlert.status, func.count()).group_by(TrackAlert.status))).all())
    return {"alerts": [_alert(a) for a in rows], "counts": counts}


async def _get(session: AsyncSession, alert_id: int, lock: bool = False) -> TrackAlert:
    q = select(TrackAlert).where(TrackAlert.id == alert_id)
    if lock:
        q = q.with_for_update()
    a = (await session.execute(q)).scalar_one_or_none()
    if a is None:
        raise HTTPException(404, "alert not found")
    return a


@router.get("/alerts/{alert_id}")
async def alert_detail(
    alert_id: int, _: Principal = Depends(readers), session: AsyncSession = Depends(get_session)
) -> dict:
    a = await _get(session, alert_id)
    events = (
        await session.execute(
            select(TrackAlertEvent)
            .where(TrackAlertEvent.alert_id == a.id)
            .order_by(TrackAlertEvent.at, TrackAlertEvent.id)
        )
    ).scalars()
    pts = await engine.track_points(session, a.source_id, a.track_id, hours=24 * 14)
    zones = []
    if a.zone_ids:
        zones = [
            {"id": z.id, "name": z.name, "name_zh": z.name_zh, "zone_type": z.zone_type, "geometry": z.geometry}
            for z in (await session.execute(select(Zone).where(Zone.id.in_(a.zone_ids)))).scalars()
        ]
    return {
        **_alert(a),
        "track": [{"t": _iso(p.at), "lat": p.lat, "lon": p.lon, "sog_kn": p.sog_kn} for p in pts[-500:]],
        "vessel": next(
            ({"name": p.name, "mmsi": p.mmsi, "ship_type": p.ship_type} for p in pts if p.name or p.mmsi), None
        ),
        "zones": zones,
        "events": [{"at": _iso(e.at), "actor": e.actor, "action": e.action, "detail": e.detail} for e in events],
    }


class DecisionIn(BaseModel):
    status: Literal["open", "acknowledged", "false_alarm", "dismissed"]
    note: str | None = Field(None, max_length=2000)
    suppress_hours: float | None = Field(None, ge=0, le=720)


@router.post("/alerts/{alert_id}/status")
async def decide(
    alert_id: int,
    body: DecisionIn,
    request: Request,
    p: Principal = Depends(deciders),
    session: AsyncSession = Depends(get_session),
) -> dict:
    a = await _get(session, alert_id, lock=True)
    if a.status == "escalated":
        raise HTTPException(409, "alert was escalated to a case; handle it there")
    now = datetime.now(UTC)
    a.status, a.updated_by, a.updated_at = body.status, p.username, now
    if body.status in ("false_alarm", "dismissed"):
        cfg = await anomaly_settings.load(session)
        hours = body.suppress_hours if body.suppress_hours is not None else cfg["suppress_hours"]
        a.suppress_until = now + timedelta(hours=hours)
    else:
        a.suppress_until = None
    action = "reopened" if body.status == "open" else body.status
    session.add(
        TrackAlertEvent(
            alert_id=a.id,
            at=now,
            actor=p.username,
            action=action,
            detail={"note": body.note, "suppress_until": _iso(a.suppress_until)},
        )
    )
    await audit(session, p, f"maritime.{action}", "track_alert", str(a.id), request)
    out = _alert(a)
    await session.commit()
    return out


class NoteIn(BaseModel):
    text: str = Field(..., min_length=1, max_length=2000)


@router.post("/alerts/{alert_id}/notes")
async def note(
    alert_id: int, body: NoteIn, p: Principal = Depends(deciders), session: AsyncSession = Depends(get_session)
) -> dict:
    a = await _get(session, alert_id)
    session.add(
        TrackAlertEvent(
            alert_id=a.id, at=datetime.now(UTC), actor=p.username, action="note", detail={"text": body.text}
        )
    )
    await session.commit()
    return {"ok": True}


@router.post("/alerts/{alert_id}/escalate")
async def escalate(
    alert_id: int, request: Request, p: Principal = Depends(deciders), session: AsyncSession = Depends(get_session)
) -> dict:
    a = await _get(session, alert_id, lock=True)
    if a.status == "escalated":
        raise HTTPException(409, "already escalated")
    case_id = await engine.escalate(session, a, p.username)
    now = datetime.now(UTC)
    a.status, a.case_id, a.updated_by, a.updated_at = "escalated", case_id, p.username, now
    session.add(
        TrackAlertEvent(
            alert_id=a.id,
            at=now,
            actor=p.username,
            action="escalated",
            detail={"case_id": str(case_id) if case_id else None},
        )
    )
    await audit(session, p, "maritime.escalate", "track_alert", str(a.id), request)
    out = _alert(a)
    await session.commit()
    return out


@router.get("/settings")
async def get_settings_(_: Principal = Depends(readers), session: AsyncSession = Depends(get_session)) -> list[dict]:
    cur = await anomaly_settings.load(session)
    return [
        {
            "key": k,
            "value": cur[k],
            "default": p.default,
            "min": p.minimum,
            "max": p.maximum,
            "unit": p.unit,
            "label_en": p.en,
            "label_zh": p.zh,
        }
        for k, p in anomaly_settings.PARAMS.items()
    ]


@router.put("/settings")
async def put_settings(
    body: dict[str, float],
    request: Request,
    p: Principal = Depends(tuners),
    session: AsyncSession = Depends(get_session),
) -> list[dict]:
    bad = [k for k in body if k not in anomaly_settings.PARAMS]
    if bad:
        raise HTTPException(422, f"unknown settings {bad}")
    for k, v in body.items():
        prm = anomaly_settings.PARAMS[k]
        if not prm.minimum <= v <= prm.maximum:
            raise HTTPException(422, f"{k} must be between {prm.minimum:g} and {prm.maximum:g}")
        row = await session.get(AnomalySetting, k)
        if row is None:
            session.add(AnomalySetting(key=k, value=v, updated_by=p.username))
        else:
            row.value, row.updated_by, row.updated_at = v, p.username, datetime.now(UTC)
    await audit(session, p, "maritime.settings", "anomaly_setting", None, request, changes=body)
    await session.flush()
    await engine.run(session)  # new thresholds take effect at once
    await session.commit()
    return await get_settings_(p, session)


@router.post("/run")
async def run_now(p: Principal = Depends(tuners), session: AsyncSession = Depends(get_session)) -> dict:
    out = await engine.run(session)
    await session.commit()
    return out


def _evaluation(ev: AnomalyEvaluation) -> dict:
    return {
        "id": ev.id,
        "created_at": _iso(ev.created_at),
        "source_id": ev.source_id,
        "tracks": ev.tracks,
        "anomalous": ev.anomalous,
        "results": ev.results,
        "settings": ev.settings,
    }


@router.get("/evaluation")
async def evaluation(_: Principal = Depends(readers), session: AsyncSession = Depends(get_session)) -> dict | None:
    ev = (
        await session.execute(select(AnomalyEvaluation).order_by(AnomalyEvaluation.id.desc()).limit(1))
    ).scalar_one_or_none()
    return _evaluation(ev) if ev else None


@router.post("/evaluation")
async def evaluate_now(
    resimulate: bool = Body(False, embed=True),
    p: Principal = Depends(tuners),
    session: AsyncSession = Depends(get_session),
) -> dict:
    """Compare the detectors on the labelled simulated tracks (optionally regenerate them first)."""
    if resimulate:
        await simulate(session)
        await session.flush()
        await engine.run(session, "sim")
    ev = await engine.evaluate(session)
    if ev is None:
        raise HTTPException(409, "no labelled tracks: run with resimulate=true")
    out = _evaluation(ev)
    await session.commit()
    return out
