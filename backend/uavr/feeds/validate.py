"""Validation against the platform's versioned feed schemas (schemas/feeds/v1/*.json)."""

import json
from functools import lru_cache

from jsonschema import Draft202012Validator, FormatChecker

from ..config import get_settings

FEEDS = ("sensor-track", "remote-id", "adsb", "ais", "weather", "registry", "permit", "cctv", "video-feed")


@lru_cache
def validator(feed: str, version: str = "v1") -> Draft202012Validator:
    path = get_settings().schema_dir / version / f"{feed}.json"
    schema = json.loads(path.read_text())
    Draft202012Validator.check_schema(schema)
    return Draft202012Validator(schema, format_checker=FormatChecker())


def errors(feed: str, payload: dict, limit: int = 50) -> list[dict]:
    out = []
    for e in sorted(validator(feed).iter_errors(payload), key=lambda e: list(e.absolute_path)):
        out.append({"path": "/" + "/".join(str(p) for p in e.absolute_path), "message": e.message})
        if len(out) >= limit:
            break
    return out
