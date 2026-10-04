"""Analytics API: aggregates for agency dashboards and hotspot maps (staff only, nothing public).

Reads the analytics views (v_incident_facts, v_case_response), never raw evidence. Percentiles are computed in
Python because MySQL 8 has no percentile aggregate.
"""

import statistics
from datetime import UTC, datetime, timedelta

from fastapi import APIRouter, Depends, Query
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from ..db.session import get_session
from ..security.audit import audit
from ..security.auth import require
from ..security.principal import ROLE_ADMIN, ROLE_ANALYST, ROLE_NATIONAL, ROLE_SUPERVISOR, Principal

router = APIRouter(prefix="/v1/analytics", tags=["analytics"])
ANALYSTS = (ROLE_ANALYST, ROLE_SUPERVISOR, ROLE_NATIONAL)


def _window(frm: datetime | None, to: datetime | None) -> tuple[datetime, datetime]:
    to = to or datetime.now(UTC)
    frm = frm or to - timedelta(days=30)

    def naive(d: datetime) -> datetime:  # DATETIME columns hold UTC without a zone
        return d.astimezone(UTC).replace(tzinfo=None) if d.tzinfo else d

    return naive(frm), naive(to)


def _scope(p: Principal, alias: str = "f") -> tuple[str, dict]:
    """Agency scoping + clearance; national command sees every agency."""
    cond = f"{alias}.classification <= :clearance"
    params = {"clearance": p.clearance}
    if not p.has(ROLE_NATIONAL):
        cond += f" AND {alias}.agency_id = :agency"
        params["agency"] = p.agency_id or -1
    return cond, params


def _pct(values: list[float], q: float) -> float | None:
    if not values:
        return None
    if len(values) == 1:
        return values[0]
    return statistics.quantiles(sorted(values), n=100, method="inclusive")[round(q * 100) - 1]


async def _rows(session: AsyncSession, sql: str, params: dict) -> list[dict]:
    return [dict(r) for r in (await session.execute(text(sql), params)).mappings().all()]


@router.get("/summary")
async def summary(
    frm: datetime | None = Query(None, alias="from"),
    to: datetime | None = None,
    p: Principal = Depends(require(*ANALYSTS)),
    session: AsyncSession = Depends(get_session),
) -> dict:
    frm, to = _window(frm, to)
    cond, params = _scope(p)
    params |= {"frm": frm, "to": to}
    [row] = await _rows(
        session,
        f"""
        SELECT COUNT(*) AS incidents,
               COALESCE(SUM(f.severity = 3), 0) AS critical,
               COALESCE(SUM(f.severity = 2), 0) AS medium,
               COALESCE(SUM(f.severity = 1), 0) AS low,
               COALESCE(SUM(f.auth_status = 'likely_authorized'), 0) AS authorized,
               COALESCE(SUM(f.has_remote_id), 0) AS with_remote_id,
               COALESCE(SUM(f.sensor_confirmed), 0) AS sensor_confirmed,
               COALESCE(SUM(f.false_report), 0) AS false_reports,
               COALESCE(SUM(f.observation_count), 0) AS observations
        FROM v_incident_facts f WHERE f.first_seen BETWEEN :frm AND :to AND {cond}
    """,
        params,
    )
    acks = [
        r["s"]
        for r in await _rows(
            session,
            f"""
        SELECT TIMESTAMPDIFF(MICROSECOND, f.created_at, f.acked_at) / 1e6 AS s
        FROM v_case_response f WHERE f.created_at BETWEEN :frm AND :to AND f.acked_at IS NOT NULL AND {cond}
    """,
            params,
        )
    ]
    acks = [float(a) for a in acks]
    return {
        "from": frm,
        "to": to,
        **{k: int(v) for k, v in row.items()},
        "ack_p50": _pct(acks, 0.5),
        "ack_p90": _pct(acks, 0.9),
    }


@router.get("/hotspots")
async def hotspots(
    frm: datetime | None = Query(None, alias="from"),
    to: datetime | None = None,
    cell_deg: float = Query(0.01, ge=0.001, le=0.5),
    severity_min: int = Query(1, ge=1, le=3),
    hour: int | None = Query(None, ge=0, le=23),
    dow: int | None = Query(None, ge=1, le=7),
    zone_id: int | None = None,
    p: Principal = Depends(require(*ANALYSTS)),
    session: AsyncSession = Depends(get_session),
) -> dict:
    frm, to = _window(frm, to)
    cond, params = _scope(p)
    extra = ""
    if hour is not None:
        extra += " AND f.hour_local = :hour"
        params["hour"] = hour
    if dow is not None:
        extra += " AND f.dow_local = :dow"
        params["dow"] = dow
    if zone_id is not None:
        extra += " AND JSON_CONTAINS(f.matched_zone_ids, CAST(:zone AS JSON))"
        params["zone"] = str(zone_id)
    rows = await _rows(
        session,
        f"""
        SELECT AVG(f.est_lat) AS lat, AVG(f.est_lon) AS lon, COUNT(*) AS count,
               SUM(f.severity = 3) AS critical, SUM(f.auth_status <> 'likely_authorized') AS unauthorized
        FROM v_incident_facts f
        WHERE f.first_seen BETWEEN :frm AND :to AND f.severity >= :sev AND f.est_lat IS NOT NULL AND {cond} {extra}
        GROUP BY FLOOR(f.est_lat / :cell), FLOOR(f.est_lon / :cell)
        ORDER BY count DESC LIMIT 5000
    """,
        {**params, "frm": frm, "to": to, "sev": severity_min, "cell": cell_deg},
    )
    cells = [
        {
            "lat": float(r["lat"]),
            "lon": float(r["lon"]),
            "count": int(r["count"]),
            "critical": int(r["critical"]),
            "unauthorized": int(r["unauthorized"]),
        }
        for r in rows
    ]
    return {"cell_deg": cell_deg, "cells": cells}


@router.get("/time-of-day")
async def time_of_day(
    frm: datetime | None = Query(None, alias="from"),
    to: datetime | None = None,
    p: Principal = Depends(require(*ANALYSTS)),
    session: AsyncSession = Depends(get_session),
) -> dict:
    frm, to = _window(frm, to)
    cond, params = _scope(p)
    rows = await _rows(
        session,
        f"""
        SELECT f.dow_local AS dow, f.hour_local AS hour, COUNT(*) AS count
        FROM v_incident_facts f WHERE f.first_seen BETWEEN :frm AND :to AND {cond}
        GROUP BY f.dow_local, f.hour_local
    """,
        {**params, "frm": frm, "to": to},
    )
    grid = [[0] * 24 for _ in range(7)]
    for r in rows:
        grid[int(r["dow"]) - 1][int(r["hour"])] = int(r["count"])
    return {"grid": grid, "dow_labels": ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]}


@router.get("/zones")
async def by_zone(
    frm: datetime | None = Query(None, alias="from"),
    to: datetime | None = None,
    p: Principal = Depends(require(*ANALYSTS)),
    session: AsyncSession = Depends(get_session),
) -> list:
    frm, to = _window(frm, to)
    cond, params = _scope(p)
    rows = await _rows(
        session,
        f"""
        SELECT z.id AS zone_id, z.code, z.name, z.name_zh, z.zone_type,
               COUNT(*) AS incidents,
               SUM(f.auth_status = 'likely_authorized') AS authorized,
               SUM(f.auth_status = 'no_permit') AS no_permit,
               SUM(f.auth_status = 'unknown') AS unknown
        FROM v_incident_facts f
        JOIN incident i ON i.id = f.incident_id
        JOIN JSON_TABLE(i.matched_zone_ids, '$[*]' COLUMNS (zid INT PATH '$')) j
        JOIN zone z ON z.id = j.zid
        WHERE f.first_seen BETWEEN :frm AND :to AND z.classification <= :clearance AND {cond}
        GROUP BY z.id, z.code, z.name, z.name_zh, z.zone_type ORDER BY incidents DESC
    """,
        {**params, "frm": frm, "to": to},
    )
    return [{**r, **{k: int(r[k]) for k in ("incidents", "authorized", "no_permit", "unknown")}} for r in rows]


@router.get("/repeat-offenders")
async def repeat_offenders(
    frm: datetime | None = Query(None, alias="from"),
    to: datetime | None = None,
    min_incidents: int = Query(2, ge=2),
    p: Principal = Depends(require(*ANALYSTS)),
    session: AsyncSession = Depends(get_session),
) -> dict:
    frm, to = _window(frm, to)
    cond, params = _scope(p)
    params |= {"frm": frm, "to": to, "min": min_incidents}
    by_serial = await _rows(
        session,
        f"""
        SELECT j.serial, COUNT(*) AS incidents,
               SUM(f.auth_status <> 'likely_authorized') AS unauthorized,
               MAX(f.last_seen) AS last_seen,
               GROUP_CONCAT(f.case_number ORDER BY f.first_seen DESC SEPARATOR ',') AS cases
        FROM v_incident_facts f
        JOIN incident i ON i.id = f.incident_id
        JOIN JSON_TABLE(i.remote_id_serials, '$[*]' COLUMNS (serial VARCHAR(64) PATH '$')) j
        WHERE f.first_seen BETWEEN :frm AND :to AND {cond}
        GROUP BY j.serial HAVING COUNT(*) >= :min ORDER BY incidents DESC LIMIT 200
    """,
        params,
    )
    by_owner = await _rows(
        session,
        f"""
        SELECT f.owner_ref, MAX(f.owner_name) AS owner_name, COUNT(*) AS incidents,
               COUNT(DISTINCT f.registry_serial) AS drones,
               SUM(f.auth_status <> 'likely_authorized') AS unauthorized,
               MAX(f.last_seen) AS last_seen
        FROM v_incident_facts f
        WHERE f.owner_ref IS NOT NULL AND f.first_seen BETWEEN :frm AND :to AND {cond}
        GROUP BY f.owner_ref HAVING COUNT(*) >= :min ORDER BY incidents DESC LIMIT 200
    """,
        params,
    )
    for r in by_serial:
        r["cases"] = (r["cases"] or "").split(",")
        r["incidents"], r["unauthorized"] = int(r["incidents"]), int(r["unauthorized"])
    for r in by_owner:
        r["incidents"], r["drones"], r["unauthorized"] = int(r["incidents"]), int(r["drones"]), int(r["unauthorized"])
    await audit(session, p, "analytics.repeat_offenders", None, None, None)
    await session.commit()
    return {"by_serial": by_serial, "by_owner": by_owner}


@router.get("/response")
async def response_performance(
    frm: datetime | None = Query(None, alias="from"),
    to: datetime | None = None,
    group: str = Query("agency", pattern="^(agency|desk)$"),
    p: Principal = Depends(require(*ANALYSTS)),
    session: AsyncSession = Depends(get_session),
) -> list:
    frm, to = _window(frm, to)
    cond, params = _scope(p)
    key, table = ("agency_id", "agency") if group == "agency" else ("desk_id", "desk")
    rows = await _rows(
        session,
        f"""
        SELECT f.{key} AS id, g.code, g.name, g.name_zh, f.severity,
               TIMESTAMPDIFF(MICROSECOND, f.created_at, f.acked_at) / 1e6 AS ack_s,
               TIMESTAMPDIFF(MICROSECOND, f.created_at, f.resolved_at) / 1e6 AS resolve_s,
               f.reroutes
        FROM v_case_response f JOIN {table} g ON g.id = f.{key}
        WHERE f.created_at BETWEEN :frm AND :to AND {cond}
    """,
        {**params, "frm": frm, "to": to},
    )
    groups: dict[tuple, list[dict]] = {}
    for r in rows:
        groups.setdefault((r["id"], r["code"], r["name"], r["name_zh"], r["severity"]), []).append(r)
    out = []
    for (gid, code, name, name_zh, sev), rs in sorted(groups.items(), key=lambda kv: (kv[0][1], -kv[0][4])):
        acks = [float(r["ack_s"]) for r in rs if r["ack_s"] is not None]
        resolves = [float(r["resolve_s"]) for r in rs if r["resolve_s"] is not None]
        out.append(
            {
                "id": gid,
                "code": code,
                "name": name,
                "name_zh": name_zh,
                "severity": sev,
                "cases": len(rs),
                "ack_p50_s": _pct(acks, 0.5),
                "ack_p90_s": _pct(acks, 0.9),
                "resolve_p50_s": _pct(resolves, 0.5),
                "reroute_rate": sum(1 for r in rs if (r["reroutes"] or 0) > 0) / len(rs),
                "unacked_rate": sum(1 for r in rs if r["ack_s"] is None) / len(rs),
            }
        )
    return out


@router.get("/source-quality")
async def source_quality(
    frm: datetime | None = Query(None, alias="from"),
    to: datetime | None = None,
    p: Principal = Depends(require(*ANALYSTS)),
    session: AsyncSession = Depends(get_session),
) -> list:
    frm, to = _window(frm, to)
    cond, params = _scope(p)
    rows = await _rows(
        session,
        f"""
        SELECT o.source_type, COUNT(*) AS incidents,
               AVG(f.sensor_confirmed) AS sensor_confirmed_share,
               AVG(CASE WHEN f.outcome_code IS NOT NULL THEN f.false_report END) AS false_report_rate,
               AVG(f.has_remote_id) AS remote_id_coverage
        FROM v_incident_facts f
        JOIN (SELECT DISTINCT incident_id, source_type FROM observation) o ON o.incident_id = f.incident_id
        WHERE f.first_seen BETWEEN :frm AND :to AND {cond}
        GROUP BY o.source_type ORDER BY incidents DESC
    """,
        {**params, "frm": frm, "to": to},
    )
    return [
        {k: (float(v) if k.endswith(("share", "rate", "coverage")) and v is not None else v) for k, v in r.items()}
        for r in rows
    ]


@router.post("/refresh", status_code=202)
async def refresh(p: Principal = Depends(require(ROLE_ADMIN, ROLE_NATIONAL))) -> dict:
    return {"refreshed": True}


async def refresh_views(session: AsyncSession) -> None:
    """Analytics views are plain views in MySQL: always current, nothing to refresh."""
