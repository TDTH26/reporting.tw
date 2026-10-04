from fastapi import Request
from sqlalchemy.ext.asyncio import AsyncSession

from ..db.models import AuditLog
from .hashing import client_ip
from .principal import Principal


async def audit(
    session: AsyncSession,
    p: Principal | None,
    action: str,
    object_type: str | None = None,
    object_id: str | None = None,
    request: Request | None = None,
    **details,
) -> None:
    """Record a view, export, registry lookup, CCTV access or admin change. Caller commits."""
    session.add(
        AuditLog(
            user_id=p.user_id if p else None,
            username=p.username if p else None,
            action=action,
            object_type=object_type,
            object_id=object_id,
            ip=client_ip(request) if request else None,
            details=details,
        )
    )
