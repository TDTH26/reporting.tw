"""Minimal OpenAI-compatible chat client for Featherless."""

import base64
import io
import time

import httpx
from PIL import Image

from ..config import get_settings


class AiUnavailable(Exception):
    """Retryable: provider busy (503), rate limited (429), timeout or network error."""


class AiError(Exception):
    """Not retryable: bad request, auth, unparseable output."""


def jpeg_data_url(data: bytes, max_px: int | None = None) -> str:
    """Downscale (keeps upload small and latency down) and re-encode as JPEG."""
    max_px = max_px or get_settings().ai_max_image_px
    img = Image.open(io.BytesIO(data))
    img = img.convert("RGB")
    img.thumbnail((max_px, max_px))
    out = io.BytesIO()
    img.save(out, format="JPEG", quality=85)
    return "data:image/jpeg;base64," + base64.b64encode(out.getvalue()).decode()


async def chat(messages: list[dict], *, max_tokens: int = 800) -> tuple[str, float]:
    s = get_settings()
    key = s.ai_api_key
    if not key:
        raise AiError("no Featherless API key configured")
    body = {"model": s.ai_model, "messages": messages, "max_tokens": max_tokens, "temperature": 0.1}
    t0 = time.monotonic()
    try:
        async with httpx.AsyncClient(timeout=s.ai_timeout_s) as c:
            r = await c.post(
                f"{s.ai_base_url}/chat/completions",
                json=body,
                # Featherless is behind Cloudflare, which rejects some default client user agents.
                headers={"Authorization": f"Bearer {key}", "User-Agent": "reporting.tw/1.0"},
            )
    except (httpx.TimeoutException, httpx.NetworkError) as e:
        raise AiUnavailable(f"{type(e).__name__}: {e}") from e
    latency = time.monotonic() - t0
    if r.status_code in (429, 502, 503, 504):
        raise AiUnavailable(f"HTTP {r.status_code}")
    if r.status_code >= 400:
        raise AiError(f"HTTP {r.status_code}: {r.text[:300]}")
    try:
        return r.json()["choices"][0]["message"]["content"] or "", latency
    except (KeyError, IndexError, ValueError) as e:
        raise AiError(f"unexpected response: {r.text[:300]}") from e
