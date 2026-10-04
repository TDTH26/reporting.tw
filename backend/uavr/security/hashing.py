"""Keyed hashes for anything that must be matched later but never stored in clear."""

import hashlib
import hmac
import ipaddress
import secrets

from ..config import get_settings


def keyed_hash(purpose: str, value: str) -> bytes:
    key = hashlib.sha256(f"{get_settings().pepper}:{purpose}".encode()).digest()
    return hmac.new(key, value.encode(), hashlib.sha256).digest()


def new_secret() -> str:
    return secrets.token_urlsafe(32)


def network_of(ip: str | None) -> str | None:
    """Group addresses by /24 (IPv4) or /48 (IPv6) for network-level rate limiting."""
    if not ip:
        return None
    try:
        addr = ipaddress.ip_address(ip)
    except ValueError:
        return None
    prefix = 24 if addr.version == 4 else 48
    return str(ipaddress.ip_network(f"{ip}/{prefix}", strict=False))


def client_ip(request) -> str | None:
    """Caller's IP: the CDN header when configured (see Settings.client_ip_header), else the socket peer."""
    from ..config import get_settings

    header = get_settings().client_ip_header
    if header and (v := request.headers.get(header)):
        return v.strip()
    return request.client.host if request.client else None
