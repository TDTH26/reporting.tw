"""Rate limiting and spam scoring. State lives in MySQL (no Redis by design)."""

from dataclasses import dataclass
from datetime import UTC, datetime

from sqlalchemy import select, text
from sqlalchemy.ext.asyncio import AsyncSession

from ..config import get_settings
from ..db.models import DeviceReputation, Evidence

WINDOW_S = 600


def _window(t: datetime) -> datetime:
    ts = int(t.timestamp())
    return datetime.fromtimestamp(ts - ts % WINDOW_S, UTC)


async def hit(session: AsyncSession, key: bytes, t: datetime) -> int:
    """Increment a rate counter and return the new count.

    Commits immediately, so the shared counter row is not locked for the rest of the request (a busy network
    would otherwise serialise a genuine surge). Call it before the request makes any other changes.
    """
    # MySQL has no RETURNING: LAST_INSERT_ID(expr) hands the new count back on this connection.
    await session.execute(
        text(
            "INSERT INTO rate_counter (`key`, window_start, count) VALUES (:k, :w, LAST_INSERT_ID(1)) "
            "ON DUPLICATE KEY UPDATE count = LAST_INSERT_ID(count + 1)"
        ),
        {"k": key, "w": _window(t).replace(tzinfo=None)},
    )
    n = int((await session.execute(text("SELECT LAST_INSERT_ID()"))).scalar_one())
    await session.commit()
    return n


@dataclass
class AbuseAssessment:
    reject: bool
    spam_score: float
    reasons: list[str]


async def assess(
    session: AsyncSession,
    *,
    device_hash: bytes | None,
    network_hash: bytes | None,
    attestation: str,
    is_web: bool,
    evidence_hashes: list[str],
    t: datetime,
) -> AbuseAssessment:
    s = get_settings()
    reasons: list[str] = []
    score = 0.0

    if device_hash is not None:
        n = await hit(session, b"d:" + device_hash, t)
        if n > s.device_reports_per_10min:
            return AbuseAssessment(True, 1.0, ["device_rate_limit"])
        if n > 3:
            score += 0.1 * (n - 3)
            reasons.append("device_burst")
        rep = await session.get(DeviceReputation, device_hash)
        if rep and rep.flagged:
            score += 0.5
            reasons.append("flagged_device")
        elif rep and rep.false_reports >= 3 and rep.false_reports > rep.confirmed_reports:
            score += 0.3
            reasons.append("history_of_false_reports")
    else:
        score += 0.2
        reasons.append("no_device_id")

    if network_hash is not None:
        # Mobile carriers use CGNAT, so a busy network is only a soft signal, never a block.
        n = await hit(session, b"n:" + network_hash, t)
        if n > s.network_soft_reports_per_10min:
            score += 0.2
            reasons.append("network_burst")

    if attestation == "failed":
        score += 0.4
        reasons.append("attestation_failed")
    elif attestation == "unavailable" and not is_web:
        score += 0.15
        reasons.append("attestation_unavailable")

    if evidence_hashes:
        dup = (
            await session.execute(select(Evidence.id).where(Evidence.sha256_declared.in_(evidence_hashes)).limit(1))
        ).first()
        if dup:
            score += 0.3
            reasons.append("reused_media")

    return AbuseAssessment(False, min(score, 0.95), reasons)
