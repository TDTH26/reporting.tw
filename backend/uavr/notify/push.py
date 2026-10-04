"""Informant push notifications. Payloads never contain case details, only a prompt to open the app."""

import json
import logging
import time
from typing import Protocol

import httpx
import jwt

from ..config import get_settings

log = logging.getLogger(__name__)

# Shown by the OS; the app fetches the actual status with its token after opening.
GENERIC = {
    "zh-TW": ("可疑載具通報", "您的通報有新進度，請開啟 App 查看。"),
    "en": ("Suspicious Craft Report", "There is an update on your report. Open the app to see it."),
    "vi": ("Báo cáo phương tiện đáng ngờ", "Báo cáo của bạn có cập nhật mới. Mở ứng dụng để xem."),
    "id": ("Lapor Wahana Mencurigakan", "Ada pembaruan pada laporan Anda. Buka aplikasi untuk melihatnya."),
    "th": ("แจ้งยานพาหนะต้องสงสัย", "รายงานของคุณมีความคืบหน้า เปิดแอปเพื่อดู"),
    "fil": ("Ulat sa Kahina-hinalang Sasakyan", "May update sa iyong ulat. Buksan ang app para makita."),
    "de": (
        "Verdächtige Luft/See-Objekte melden",
        "Es gibt Neuigkeiten zu Ihrer Meldung. Öffnen Sie die App, um sie zu sehen.",
    ),
    "fr": (
        "Signalement d'engins suspects",
        "Votre signalement a été mis à jour. Ouvrez l'application pour le consulter.",
    ),
}


class PushSender(Protocol):
    async def send(self, push_token: str, language: str) -> None: ...


class LogSender:
    async def send(self, push_token: str, language: str) -> None:
        log.info("push (dev) to %s… in %s", push_token[:8], language)


class FcmSender:
    def __init__(self, credentials_file: str):
        with open(credentials_file) as f:
            self._sa = json.load(f)
        self._token: tuple[str, float] | None = None

    async def _access_token(self, client: httpx.AsyncClient) -> str:
        if self._token and self._token[1] > time.time() + 60:
            return self._token[0]
        now = int(time.time())
        assertion = jwt.encode(
            {
                "iss": self._sa["client_email"],
                "scope": "https://www.googleapis.com/auth/firebase.messaging",
                "aud": self._sa["token_uri"],
                "iat": now,
                "exp": now + 3600,
            },
            self._sa["private_key"],
            algorithm="RS256",
        )
        r = await client.post(
            self._sa["token_uri"],
            data={"grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer", "assertion": assertion},
        )
        r.raise_for_status()
        b = r.json()
        self._token = (b["access_token"], time.time() + b.get("expires_in", 3600))
        return self._token[0]

    async def send(self, push_token: str, language: str) -> None:
        title, body = GENERIC.get(language, GENERIC["en"])
        async with httpx.AsyncClient(timeout=10) as client:
            at = await self._access_token(client)
            r = await client.post(
                f"https://fcm.googleapis.com/v1/projects/{self._sa['project_id']}/messages:send",
                headers={"Authorization": f"Bearer {at}"},
                json={
                    "message": {
                        "token": push_token,
                        "notification": {"title": title, "body": body},
                        "data": {"type": "status_update"},
                        "android": {"priority": "normal"},
                    }
                },
            )
            r.raise_for_status()


_sender: PushSender | None = None


def sender() -> PushSender:
    global _sender
    if _sender is None:
        f = get_settings().fcm_credentials_file
        _sender = FcmSender(f) if f else LogSender()
    return _sender
