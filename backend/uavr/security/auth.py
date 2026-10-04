"""Staff authentication, built in: username + password -> short-lived access token (HS256) + rotating
refresh token. Access tokens carry the attributes ABAC needs (roles, agency, desk, clearance, field unit);
every request still checks that the account exists and is active, so deactivation takes effect at once.
"""

import time
import uuid
from datetime import UTC, datetime

import jwt
from fastapi import Depends, HTTPException, Request, WebSocket, status
from sqlalchemy.dialects.mysql import insert
from sqlalchemy.ext.asyncio import AsyncSession

from ..config import get_settings
from ..db.models import AppUser
from ..db.session import get_session
from .principal import STAFF_ROLES, Principal

ISSUER = "uavr"


def _encode(claims: dict) -> str:
    s = get_settings()
    now = int(time.time())
    return jwt.encode(
        {"iss": ISSUER, "aud": s.token_audience, "iat": now, "exp": now + s.access_token_ttl_s, **claims},
        s.jwt_secret,
        algorithm="HS256",
    )


def access_token_for(u: AppUser) -> str:
    return _encode(
        {
            "sub": str(u.id),
            "preferred_username": u.username,
            "name": u.display_name or u.username,
            "realm_access": {"roles": list(u.roles or [])},
            "agency": u.agency_id,
            "desk": u.desk_id,
            "clearance": u.clearance,
            "field_unit": u.field_unit,
            "locale": u.language,
        }
    )


def issue_dev_token(
    *,
    user_id: uuid.UUID,
    username: str,
    roles: list[str],
    agency: int | None,
    desk: int | None,
    clearance: int = 0,
    field_unit: bool = False,
    ttl: int = 3600,
) -> str:
    """Tests and local tooling only: a token for an account that may not exist yet (created on first use)."""
    if not get_settings().is_dev:
        raise RuntimeError("dev tokens are disabled outside dev/test")
    return _encode(
        {
            "sub": str(user_id),
            "preferred_username": username,
            "name": username,
            "realm_access": {"roles": roles},
            "agency": agency,
            "desk": desk,
            "clearance": clearance,
            "field_unit": field_unit,
            "dev": True,
        }
    )


def decode_token(token: str) -> dict:
    s = get_settings()
    try:
        return jwt.decode(token, s.jwt_secret, algorithms=["HS256"], audience=s.token_audience, issuer=ISSUER)
    except jwt.PyJWTError as e:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, f"invalid token: {e}") from e


def principal_from_claims(c: dict) -> Principal:
    roles = frozenset(r for r in c.get("realm_access", {}).get("roles", []) if r in STAFF_ROLES)
    if not roles:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "no staff role")
    return Principal(
        user_id=uuid.UUID(c["sub"]),
        username=c.get("preferred_username", c["sub"]),
        display_name=c.get("name", ""),
        agency_id=c.get("agency"),
        desk_id=c.get("desk"),
        roles=roles,
        clearance=int(c.get("clearance") or 0),
        field_unit=bool(c.get("field_unit")),
        language=c.get("locale") or "zh-TW",
    )


async def _check_account(session: AsyncSession, claims: dict, p: Principal) -> None:
    u = await session.get(AppUser, p.user_id)
    if u is None and claims.get("dev") and get_settings().is_dev:
        values = dict(
            id=p.user_id,
            username=p.username,
            display_name=p.display_name,
            agency_id=p.agency_id,
            desk_id=p.desk_id,
            roles=sorted(p.roles),
            clearance=p.clearance,
            field_unit=p.field_unit,
            active=True,
        )
        await session.execute(insert(AppUser).values(**values).prefix_with("IGNORE"))
        await session.commit()
        return
    if u is None or not u.active:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "account disabled")
    now = datetime.now(UTC)
    if u.last_seen is None or (now - u.last_seen).total_seconds() > 60:
        u.last_seen = now
        await session.commit()


def _bearer(headers) -> str:
    auth = headers.get("authorization", "")
    if not auth.lower().startswith("bearer "):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "missing bearer token")
    return auth[7:]


async def current_staff(request: Request, session: AsyncSession = Depends(get_session)) -> Principal:
    claims = decode_token(_bearer(request.headers))
    p = principal_from_claims(claims)
    await _check_account(session, claims, p)
    request.state.principal = p
    return p


async def staff_from_websocket(ws: WebSocket, session: AsyncSession) -> Principal:
    token = ws.query_params.get("token") or ws.headers.get("authorization", "")[7:]
    claims = decode_token(token)
    p = principal_from_claims(claims)
    await _check_account(session, claims, p)
    return p


def require(*roles: str):
    async def dep(p: Principal = Depends(current_staff)) -> Principal:
        if not p.has(*roles):
            raise HTTPException(status.HTTP_403_FORBIDDEN, f"requires one of {roles}")
        return p

    return dep
