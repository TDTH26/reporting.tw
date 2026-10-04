"""Evidence tier on the local filesystem (UAVR_DATA_DIR).

Layout: uploads/<evidence id> (written by tusd's filestore), frames/<feed>/<time>-<hash>.jpg (sampled camera
frames). Verified evidence is made read-only and never rewritten (chain of custody). Staff download it through
short-lived signed URLs served by the API (/v1/media/...), so the files are never exposed directly.
"""

import asyncio
import hashlib
import hmac
import os
import time
from pathlib import Path

from ..config import get_settings
from ..security.hashing import keyed_hash


def root() -> Path:
    p = get_settings().data_dir
    p.mkdir(parents=True, exist_ok=True)
    return p


def path_for(key: str) -> Path:
    """Resolve a storage key inside the data directory (rejects absolute paths and '..')."""
    base = root().resolve()
    p = (base / key).resolve()
    if base not in p.parents:
        raise ValueError(f"invalid storage key {key!r}")
    return p


def key_for(path: str) -> str | None:
    """Storage key for an absolute path reported by tusd, or None if it is outside the data directory."""
    try:
        return str(Path(path).resolve().relative_to(root().resolve()))
    except ValueError:
        return None


def _sha256_sync(key: str) -> tuple[str, int]:
    h = hashlib.sha256()
    n = 0
    with open(path_for(key), "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
            n += len(chunk)
    return h.hexdigest(), n


async def sha256_of(key: str) -> tuple[str, int]:
    return await asyncio.to_thread(_sha256_sync, key)


async def get_bytes(key: str) -> bytes:
    return await asyncio.to_thread(path_for(key).read_bytes)


def put_bytes(key: str, data: bytes, content_type: str | None = None) -> None:
    """Write a new object atomically and seal it read-only."""
    p = path_for(key)
    p.parent.mkdir(parents=True, exist_ok=True)
    tmp = p.with_name(p.name + ".part")
    tmp.write_bytes(data)
    os.replace(tmp, p)
    seal(key)


def seal(key: str) -> None:
    try:
        os.chmod(path_for(key), 0o440)
    except OSError:
        pass


def _sig(key: str, exp: int) -> str:
    return keyed_hash("media", f"{key}|{exp}").hex()[:40]


def signed_url(key: str, expires: int = 300) -> str:
    exp = int(time.time()) + expires
    return f"{get_settings().public_api_url.rstrip('/')}/v1/media/{key}?e={exp}&s={_sig(key, exp)}"


def verify(key: str, exp: int, sig: str) -> bool:
    return exp >= time.time() and hmac.compare_digest(sig, _sig(key, exp))
