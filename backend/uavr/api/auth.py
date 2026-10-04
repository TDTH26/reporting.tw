"""Staff login: POST /v1/auth/login -> access token (15 min) + refresh token (rotated on every refresh)."""

import secrets
import uuid
from datetime import UTC, datetime, timedelta
from typing import Literal

from fastapi import APIRouter, Depends, HTTPException, Request, status
from pydantic import BaseModel, Field
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from ..abuse.limits import hit
from ..config import get_settings
from ..db.models import AppUser, StaffSession
from ..db.session import get_session
from ..security.audit import audit
from ..security.auth import access_token_for, current_staff
from ..security.hashing import client_ip, keyed_hash
from ..security.passwords import hash_password, policy_error, verify_password
from ..security.principal import Principal

router = APIRouter(prefix="/v1/auth", tags=["auth"])
LOGIN_ATTEMPTS_PER_IP = 30  # per 10 minutes


class LoginIn(BaseModel):
    username: str = Field(max_length=128)
    password: str = Field(max_length=256)
    client: Literal["console", "field"] = "console"


class RefreshIn(BaseModel):
    refresh_token: str = Field(max_length=200)


class PasswordIn(BaseModel):
    current_password: str = Field(max_length=256)
    new_password: str = Field(max_length=256)


class TokenOut(BaseModel):
    access_token: str
    refresh_token: str
    expires_in: int
    token_type: str = "Bearer"


def _now() -> datetime:
    return datetime.now(UTC)


async def _issue(session: AsyncSession, u: AppUser, client: str | None) -> TokenOut:
    s = get_settings()
    secret = secrets.token_urlsafe(32)
    sess = StaffSession(
        id=uuid.uuid4(),
        user_id=u.id,
        token_hash=keyed_hash("refresh", secret),
        client=client,
        expires_at=_now() + timedelta(seconds=s.refresh_token_ttl_s),
    )
    session.add(sess)
    await session.flush()
    return TokenOut(
        access_token=access_token_for(u), refresh_token=f"{sess.id}.{secret}", expires_in=s.access_token_ttl_s
    )


@router.post("/login", response_model=TokenOut)
async def login(body: LoginIn, request: Request, session: AsyncSession = Depends(get_session)) -> TokenOut:
    s = get_settings()
    ip = client_ip(request) or "?"
    if await hit(session, b"l:" + keyed_hash("login-ip", ip)[:20], _now()) > LOGIN_ATTEMPTS_PER_IP:
        await session.commit()
        raise HTTPException(status.HTTP_429_TOO_MANY_REQUESTS, "too many login attempts, try again later")
    u = (await session.execute(select(AppUser).where(AppUser.username == body.username.strip()))).scalar_one_or_none()
    if u is not None and u.locked_until and u.locked_until > _now():
        await session.commit()
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "account temporarily locked, try again later")
    ok = verify_password(body.password, u.password_hash if u else None)
    if not ok or u is None or not u.active:
        if u is not None:
            u.failed_logins = (u.failed_logins or 0) + 1
            if u.failed_logins >= s.login_max_failures:
                u.locked_until = _now() + timedelta(seconds=s.login_lockout_s)
                u.failed_logins = 0
        await audit(session, None, "auth.login_failed", "user", body.username[:64], request)
        await session.commit()
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "invalid username or password")
    u.failed_logins, u.locked_until, u.last_seen = 0, None, _now()
    out = await _issue(session, u, body.client)
    await audit(session, None, "auth.login", "user", str(u.id), request, username=u.username, client=body.client)
    await session.commit()
    return out


async def _session_for(session: AsyncSession, token: str) -> StaffSession:
    try:
        sid, secret = token.split(".", 1)
        sess = await session.get(StaffSession, uuid.UUID(sid), with_for_update=True)
    except ValueError:
        sess = None
    if sess is None or sess.revoked or sess.expires_at < _now() or sess.token_hash != keyed_hash("refresh", secret):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "session expired, please sign in again")
    return sess


@router.post("/refresh", response_model=TokenOut)
async def refresh(body: RefreshIn, session: AsyncSession = Depends(get_session)) -> TokenOut:
    old = await _session_for(session, body.refresh_token)
    u = await session.get(AppUser, old.user_id)
    if u is None or not u.active:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "account disabled")
    old.revoked, old.last_used = True, _now()  # rotation: a stolen refresh token works at most once
    out = await _issue(session, u, old.client)
    await session.commit()
    return out


@router.post("/logout", status_code=204)
async def logout(body: RefreshIn, session: AsyncSession = Depends(get_session)) -> None:
    try:
        sess = await _session_for(session, body.refresh_token)
        sess.revoked = True
        await session.commit()
    except HTTPException:
        pass


@router.post("/password", status_code=204)
async def change_password(
    body: PasswordIn,
    request: Request,
    p: Principal = Depends(current_staff),
    session: AsyncSession = Depends(get_session),
) -> None:
    u = await session.get(AppUser, p.user_id)
    if not verify_password(body.current_password, u.password_hash):
        raise HTTPException(status.HTTP_403_FORBIDDEN, "current password is wrong")
    if err := policy_error(body.new_password, u.username):
        raise HTTPException(422, err)
    u.password_hash, u.password_changed_at = hash_password(body.new_password), _now()
    await session.execute(update(StaffSession).where(StaffSession.user_id == u.id).values(revoked=True))
    await audit(session, p, "auth.password_changed", "user", str(u.id), request)
    await session.commit()
