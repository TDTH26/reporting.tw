from collections.abc import AsyncIterator

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, async_sessionmaker, create_async_engine

from ..config import get_settings

_engine: AsyncEngine | None = None
_sessionmaker: async_sessionmaker | None = None


class LockingSession(AsyncSession):
    """MySQL named locks (GET_LOCK) belong to the connection, and SQLAlchemy hands the connection back to the pool
    at commit/rollback. So they are released on the same connection just *before* the transaction ends.

    That is safe for fusion: rows this transaction inserted or locked stay X-locked until COMMIT, and the next
    transaction's SELECT ... FOR UPDATE over the same area waits for them, so it cannot miss the new incident.
    """

    async def _release_named_locks(self) -> None:
        if self.info.pop("named_locks", None):
            try:
                await self.execute(text("SELECT RELEASE_ALL_LOCKS()"))
            except Exception:  # broken connection: the locks die with it
                pass

    async def commit(self) -> None:
        await self._release_named_locks()
        await super().commit()

    async def rollback(self) -> None:
        await self._release_named_locks()
        await super().rollback()

    async def close(self) -> None:
        if self.info.get("named_locks"):
            await self.rollback()
        await super().close()


def engine() -> AsyncEngine:
    global _engine, _sessionmaker
    if _engine is None:
        _engine = create_async_engine(
            get_settings().database_url,
            pool_size=20,
            max_overflow=20,
            pool_recycle=3600,
            pool_pre_ping=True,
            # Each statement sees the latest committed rows (fusion relies on this after taking its locks).
            isolation_level="READ COMMITTED",
            connect_args={"init_command": "SET time_zone = '+00:00'", "charset": "utf8mb4"},
        )
        _sessionmaker = async_sessionmaker(_engine, expire_on_commit=False, class_=LockingSession)
    return _engine


def sessionmaker() -> async_sessionmaker:
    engine()
    assert _sessionmaker is not None
    return _sessionmaker


async def get_session() -> AsyncIterator[AsyncSession]:
    async with sessionmaker()() as session:
        yield session


async def dispose() -> None:
    global _engine, _sessionmaker
    if _engine is not None:
        await _engine.dispose()
    _engine = None
    _sessionmaker = None
