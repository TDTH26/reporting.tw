"""Envelope encryption for defense-only fields.

Production deployments plug in a key provider backed by the defense agency's KMS/HSM, so the
platform operator never holds the key in clear. Dev/test uses a static local key.
"""

import base64
import hashlib
import os
from typing import Protocol

from cryptography.hazmat.primitives.ciphers.aead import AESGCM

from ..config import get_settings


class KeyProvider(Protocol):
    key_id: str

    def wrap(self, dek: bytes) -> bytes: ...
    def unwrap(self, wrapped: bytes) -> bytes: ...


class LocalKeyProvider:
    key_id = "local-dev"

    def __init__(self, secret: str):
        self._kek = AESGCM(hashlib.sha256(secret.encode()).digest())

    def wrap(self, dek: bytes) -> bytes:
        nonce = os.urandom(12)
        return nonce + self._kek.encrypt(nonce, dek, b"dek")

    def unwrap(self, wrapped: bytes) -> bytes:
        return self._kek.decrypt(wrapped[:12], wrapped[12:], b"dek")


_provider: KeyProvider | None = None


def provider() -> KeyProvider:
    global _provider
    if _provider is None:
        _provider = LocalKeyProvider(get_settings().dev_key)
    return _provider


def encrypt(plaintext: str, aad: bytes = b"") -> bytes:
    """Format: b'v1' | len(wrapped) (2 bytes) | wrapped DEK | nonce | ciphertext."""
    dek = AESGCM.generate_key(bit_length=256)
    wrapped = provider().wrap(dek)
    nonce = os.urandom(12)
    ct = AESGCM(dek).encrypt(nonce, plaintext.encode(), aad)
    return b"v1" + len(wrapped).to_bytes(2, "big") + wrapped + nonce + ct


def decrypt(blob: bytes, aad: bytes = b"") -> str:
    assert blob[:2] == b"v1"
    n = int.from_bytes(blob[2:4], "big")
    wrapped, rest = blob[4 : 4 + n], blob[4 + n :]
    dek = provider().unwrap(wrapped)
    return AESGCM(dek).decrypt(rest[:12], rest[12:], aad).decode()


def b64(b: bytes) -> str:
    return base64.urlsafe_b64encode(b).decode()
