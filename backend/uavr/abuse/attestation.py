"""Device attestation (Google Play Integrity, standard request with a requestHash)."""

import json
import logging
import time
from dataclasses import dataclass
from typing import Protocol

import httpx
import jwt

from ..config import get_settings

log = logging.getLogger(__name__)


@dataclass
class Verdict:
    result: str  # passed | failed | unavailable
    detail: str = ""


class Verifier(Protocol):
    async def verify(self, token: str | None, request_hash: str, package: str | None) -> Verdict: ...


class DevVerifier:
    """Accepts the literal tokens 'dev-pass' / 'dev-fail' so flows can be tested without Google."""

    async def verify(self, token, request_hash, package) -> Verdict:
        if not token:
            return Verdict("unavailable")
        if token == "dev-pass":
            return Verdict("passed")
        if token == "dev-fail":
            return Verdict("failed", "dev")
        return Verdict("failed", "unknown dev token")


class PlayIntegrityVerifier:
    SCOPE = "https://www.googleapis.com/auth/playintegrity"

    def __init__(self, credentials_file: str, packages: list[str]):
        with open(credentials_file) as f:
            self._sa = json.load(f)
        self._packages = set(packages)
        self._token: tuple[str, float] | None = None

    async def _access_token(self, client: httpx.AsyncClient) -> str:
        if self._token and self._token[1] > time.time() + 60:
            return self._token[0]
        now = int(time.time())
        assertion = jwt.encode(
            {
                "iss": self._sa["client_email"],
                "scope": self.SCOPE,
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
        body = r.json()
        self._token = (body["access_token"], time.time() + body.get("expires_in", 3600))
        return self._token[0]

    async def verify(self, token, request_hash, package) -> Verdict:
        if not token:
            return Verdict("unavailable")
        if package not in self._packages:
            return Verdict("failed", "package")
        try:
            async with httpx.AsyncClient(timeout=5) as client:
                at = await self._access_token(client)
                r = await client.post(
                    f"https://playintegrity.googleapis.com/v1/{package}:decodeIntegrityToken",
                    headers={"Authorization": f"Bearer {at}"},
                    json={"integrity_token": token},
                )
                r.raise_for_status()
                payload = r.json()["tokenPayloadExternal"]
        except Exception as e:  # network trouble must never block a report
            log.warning("play integrity unavailable: %s", e)
            return Verdict("unavailable", str(e))
        req = payload.get("requestDetails", {})
        app = payload.get("appIntegrity", {})
        dev = payload.get("deviceIntegrity", {})
        if req.get("requestHash") != request_hash or req.get("requestPackageName") != package:
            return Verdict("failed", "request binding")
        if app.get("appRecognitionVerdict") != "PLAY_RECOGNIZED":
            return Verdict("failed", "app")
        if "MEETS_DEVICE_INTEGRITY" not in dev.get("deviceRecognitionVerdict", []):
            return Verdict("failed", "device")
        return Verdict("passed")


_verifier: Verifier | None = None


def verifier() -> Verifier:
    global _verifier
    if _verifier is None:
        s = get_settings()
        if s.play_integrity_credentials_file:
            _verifier = PlayIntegrityVerifier(s.play_integrity_credentials_file, s.play_integrity_packages)
        else:
            _verifier = DevVerifier()
    return _verifier
