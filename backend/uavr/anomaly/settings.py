"""Detector thresholds: defaults here, operator overrides in the anomaly_setting table."""

from dataclasses import dataclass

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..db.models import AnomalySetting


@dataclass(frozen=True)
class Param:
    default: float
    minimum: float
    maximum: float
    unit: str
    en: str
    zh: str


PARAMS: dict[str, Param] = {
    "lookback_hours": Param(48, 6, 336, "h", "Detection window", "偵測時間範圍"),
    "stop_speed_kn": Param(1.0, 0.1, 5, "kn", "Stop: speed below", "停留：航速低於"),
    "stop_min_minutes": Param(120, 15, 1440, "min", "Stop: for at least", "停留：持續至少"),
    "gap_minutes_ais": Param(45, 5, 720, "min", "Reporting gap (AIS) longer than", "回報中斷（AIS）超過"),
    "gap_minutes_mda": Param(480, 30, 2880, "min", "Reporting gap (sensor) longer than", "回報中斷（感測器）超過"),
    "deviation_cell_min_tracks": Param(
        3, 1, 50, "tracks", "Off-lane: area used by fewer than", "偏離航道：該區歷史航跡少於"
    ),
    "deviation_min_points": Param(2, 1, 20, "positions", "Off-lane: at least", "偏離航道：至少"),
    "cluster_radius_m": Param(2000, 200, 20000, "m", "Cluster: vessels within", "聚集：船舶相距"),
    "cluster_window_minutes": Param(60, 10, 720, "min", "Cluster: within the same", "聚集：同一時段"),
    "cluster_min_tracks": Param(3, 2, 10, "vessels", "Cluster: at least", "聚集：至少"),
    "near_zone_m": Param(5000, 500, 30000, "m", "Approach: closer to a protected area than", "接近：距保護區少於"),
    "stat_percentile": Param(
        99.5, 90, 99.99, "%", "Statistical: alert above percentile of past traffic", "統計：高於歷史航行之百分位"
    ),
    "alert_min_score": Param(35, 0, 100, "", "Alert when risk score at least", "風險分數達此值才警示"),
    "suppress_hours": Param(24, 1, 720, "h", "False alarm: stay quiet for", "誤報：靜默時間"),
}


def defaults() -> dict[str, float]:
    return {k: p.default for k, p in PARAMS.items()}


async def load(session: AsyncSession) -> dict[str, float]:
    s = defaults()
    for row in (await session.execute(select(AnomalySetting))).scalars():
        p = PARAMS.get(row.key)
        if p is not None:
            s[row.key] = min(max(row.value, p.minimum), p.maximum)
    return s
