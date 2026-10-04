import hmac
import uuid
from datetime import UTC, datetime

from fastapi import Depends, Header, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from ..db.models import InformantToken
from ..db.session import get_session
from ..security.hashing import keyed_hash, new_secret


def mint_token(secret: str | None = None) -> tuple[uuid.UUID, str, bytes]:
    tid = uuid.uuid4()
    secret = secret or new_secret()
    return tid, f"{tid}.{secret}", keyed_hash("informant-token", secret)


def secret_matches(tok: InformantToken, secret: str) -> bool:
    return hmac.compare_digest(tok.secret_hash, keyed_hash("informant-token", secret))


async def current_informant(
    x_report_token: str = Header(..., alias="X-Report-Token"),
    session: AsyncSession = Depends(get_session),
) -> InformantToken:
    try:
        tid_s, secret = x_report_token.split(".", 1)
        tid = uuid.UUID(tid_s)
    except ValueError:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "invalid token") from None
    tok = await session.get(InformantToken, tid)
    if tok is None or not hmac.compare_digest(tok.secret_hash, keyed_hash("informant-token", secret)):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "invalid token")
    tok.last_seen = datetime.now(UTC)
    return tok


def sign_upload(evidence_id: uuid.UUID) -> str:
    return f"{evidence_id}.{keyed_hash('upload', str(evidence_id)).hex()[:32]}"


def check_upload(token: str) -> uuid.UUID | None:
    try:
        eid_s, sig = token.split(".", 1)
        eid = uuid.UUID(eid_s)
    except (ValueError, AttributeError):
        return None
    good = keyed_hash("upload", str(eid)).hex()[:32]
    return eid if hmac.compare_digest(sig, good) else None
