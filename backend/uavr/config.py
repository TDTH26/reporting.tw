from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="UAVR_", env_file=".env", extra="ignore")

    env: str = "dev"  # dev | test | prod
    database_url: str = "mysql+asyncmy://uavr:uavr@127.0.0.1:33306/uavr"

    # Evidence storage (local filesystem) and the public API base used in signed media links.
    data_dir: Path = Path(__file__).resolve().parents[2] / "data"
    public_api_url: str = "http://localhost:8480/api"
    max_upload_bytes: int = 200 * 1024 * 1024

    # Resumable upload server (tusd)
    tus_public_url: str = "http://localhost:8180/files/"
    tus_hook_secret: str = "dev-hook-secret"

    # Staff login (built in). jwt_secret signs access tokens: set a long random value in production.
    jwt_secret: str = "dev-jwt-secret-change-me-0123456789abcdef"
    token_audience: str = "uavr-api"
    access_token_ttl_s: int = 900
    refresh_token_ttl_s: int = 12 * 3600
    login_max_failures: int = 5
    login_lockout_s: int = 900

    # Server-side secret used to hash informant tokens, device IDs and networks.
    pepper: str = "dev-pepper-change-me"
    # Key provider secret for encrypted defense notes (local provider until a KMS is wired).
    dev_key: str = "dev-only-32-byte-key-change-me!!"

    translate_url: str | None = None
    fcm_credentials_file: str | None = None
    play_integrity_credentials_file: str | None = None
    play_integrity_packages: list[str] = ["tw.reporting.app", "tw.reporting.field"]

    # Header carrying the real client IP when behind a CDN (e.g. "CF-Connecting-IP" with Cloudflare). Only set
    # this when the origin accepts traffic from the CDN alone (firewall), otherwise clients could spoof it.
    client_ip_header: str | None = None

    cors_origins: list[str] = ["https://reporting.tw", "https://www.reporting.tw"]

    # AI triage (Featherless, OpenAI-compatible). Accepted risk: media leaves Taiwan (design doc).
    ai_enabled: bool = True
    ai_base_url: str = "https://api.featherless.ai/v1"
    ai_model: str = "Qwen/Qwen3-VL-30B-A3B-Instruct"
    featherless_api_key: str | None = None
    featherless_credentials_file: str | None = None  # JSON {"FEATHERLESS_API_KEY": "..."}
    # Plan budget is 4 concurrency units; Qwen3-VL-30B-A3B costs 2 -> 2 requests at a time, all workers combined.
    ai_max_concurrent: int = 2
    ai_timeout_s: float = 240.0
    ai_max_image_px: int = 1280
    video_frame_backlog: int = 4  # skip sampling while this many frame jobs are waiting

    schema_dir: Path = Path(__file__).resolve().parents[2] / "schemas" / "feeds"

    # Fusion tuning
    cluster_radius_m: float = 2000.0
    cluster_window_s: int = 900
    incident_idle_close_s: int = 1800
    default_sighting_range_m: float = 300.0
    adsb_proximity_m: float = 5000.0
    adsb_vertical_m: float = 600.0

    # Abuse limits
    device_reports_per_10min: int = 10
    network_soft_reports_per_10min: int = 60

    # Default acknowledgement timeouts (seconds) per severity, overridable per zone.
    ack_timeouts: dict[str, int] = {"3": 120, "2": 600, "1": 3600}
    resolved_autoclose_s: int = 7 * 24 * 3600

    @property
    def ai_api_key(self) -> str | None:
        if self.featherless_api_key:
            return self.featherless_api_key
        if self.featherless_credentials_file:
            import json

            try:
                return json.loads(Path(self.featherless_credentials_file).read_text())["FEATHERLESS_API_KEY"]
            except (OSError, KeyError, ValueError):
                return None
        return None

    @property
    def is_dev(self) -> bool:
        return self.env in ("dev", "test")


@lru_cache
def get_settings() -> Settings:
    return Settings()
