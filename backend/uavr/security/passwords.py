"""Staff password hashing (scrypt from the standard library) and policy."""

import base64
import hashlib
import hmac
import os

N, R, P = 2**15, 8, 1
MIN_LENGTH = 12


def hash_password(password: str) -> str:
    salt = os.urandom(16)
    dk = hashlib.scrypt(password.encode(), salt=salt, n=N, r=R, p=P, maxmem=64 * 1024 * 1024, dklen=32)
    return f"scrypt${N}${R}${P}${base64.b64encode(salt).decode()}${base64.b64encode(dk).decode()}"


def verify_password(password: str, stored: str | None) -> bool:
    if not stored or not stored.startswith("scrypt$"):
        # Burn comparable time so unknown users are not distinguishable by timing.
        hashlib.scrypt(password.encode(), salt=b"0" * 16, n=N, r=R, p=P, maxmem=64 * 1024 * 1024, dklen=32)
        return False
    _, n, r, p, salt, dk = stored.split("$")
    got = hashlib.scrypt(
        password.encode(), salt=base64.b64decode(salt), n=int(n), r=int(r), p=int(p), maxmem=64 * 1024 * 1024, dklen=32
    )
    return hmac.compare_digest(got, base64.b64decode(dk))


def policy_error(password: str, username: str = "") -> str | None:
    if len(password) < MIN_LENGTH:
        return f"password must have at least {MIN_LENGTH} characters"
    if username and username.lower() in password.lower():
        return "password must not contain the username"
    return None
