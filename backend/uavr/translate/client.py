"""Self-hosted machine translation (LibreTranslate API) for free-text informant descriptions."""

import logging

import httpx

from ..config import get_settings

log = logging.getLogger(__name__)

# App language codes -> LibreTranslate codes
LT_CODES = {"zh-TW": "zt", "en": "en", "vi": "vi", "id": "id", "th": "th", "fil": "tl", "de": "de", "fr": "fr"}


async def translate(text: str, source: str | None, target: str) -> str | None:
    url = get_settings().translate_url
    if not url or not text:
        return None
    try:
        async with httpx.AsyncClient(timeout=8) as c:
            r = await c.post(
                f"{url}/translate",
                json={
                    "q": text,
                    "source": LT_CODES.get(source or "", "auto"),
                    "target": LT_CODES.get(target, "en"),
                    "format": "text",
                },
            )
            r.raise_for_status()
            return r.json().get("translatedText")
    except Exception as e:
        log.warning("translation failed: %s", e)
        return None
