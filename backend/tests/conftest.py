import asyncio
import os
import subprocess
import uuid
from pathlib import Path

import pytest

MYSQL = os.environ.get("UAVR_TEST_MYSQL", "uavr:uavr@127.0.0.1:33306")
TEST_DB = "uavr_test"
os.environ["UAVR_ENV"] = "test"
os.environ["UAVR_DATABASE_URL"] = f"mysql+asyncmy://{MYSQL}/{TEST_DB}"
os.environ.setdefault("UAVR_PEPPER", "test-pepper")
os.environ["UAVR_DATA_DIR"] = __import__("tempfile").mkdtemp(prefix="uavr-test-data-")
os.environ["UAVR_FEATHERLESS_API_KEY"] = "test-key"  # never used: tests replace the model call

from uavr.config import get_settings  # noqa: E402

get_settings.cache_clear()

BACKEND = Path(__file__).resolve().parents[1]
STATIC_TABLES = {"agency", "desk", "zone", "template", "feed_client", "counter", "alembic_version"}


async def _admin(sql: str) -> None:
    import asyncmy

    user, rest = MYSQL.split(":", 1)
    password, host = rest.split("@", 1)
    host, port = host.split(":")
    conn = await asyncmy.connect(host=host, port=int(port), user=user, password=password)
    async with conn.cursor() as cur:
        await cur.execute(sql)
    await conn.commit()
    conn.close()


@pytest.fixture(scope="session", autouse=True)
def database():
    asyncio.run(_admin(f"DROP DATABASE IF EXISTS {TEST_DB}"))
    asyncio.run(_admin(f"CREATE DATABASE {TEST_DB} CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci"))
    env = {**os.environ}
    subprocess.run(["alembic", "upgrade", "head"], cwd=BACKEND, env=env, check=True, capture_output=True)
    subprocess.run(
        ["python", "-m", "uavr.seed", "--dev-feed-key", "test-feed-key"],
        cwd=BACKEND,
        env=env,
        check=True,
        capture_output=True,
    )
    yield


@pytest.fixture(autouse=True)
async def clean():
    from sqlalchemy import text

    from uavr.db.session import sessionmaker

    async with sessionmaker()() as s:
        tables = (
            (
                await s.execute(
                    text(
                        "SELECT table_name FROM information_schema.tables WHERE table_schema = DATABASE() "
                        "AND table_type = 'BASE TABLE'"
                    )
                )
            )
            .scalars()
            .all()
        )
        await s.execute(text("SET FOREIGN_KEY_CHECKS = 0"))
        for t in tables:
            if t not in STATIC_TABLES:
                await s.execute(text(f"TRUNCATE TABLE `{t}`"))
        await s.execute(text("SET FOREIGN_KEY_CHECKS = 1"))
        await s.execute(text("UPDATE counter SET value = 0 WHERE name = 'case_number'"))
        await s.commit()
    yield


@pytest.fixture
async def client():
    import httpx

    from uavr.main import app

    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as c:
        yield c


@pytest.fixture
async def desks():
    from sqlalchemy import select

    from uavr.db.models import Desk
    from uavr.db.session import sessionmaker

    async with sessionmaker()() as s:
        return {d.code: d for d in (await s.execute(select(Desk))).unique().scalars()}


def staff_headers(desk, roles=("dispatcher",), clearance=None, field_unit=False, user_id=None, username=None):
    from uavr.security.auth import issue_dev_token

    tok = issue_dev_token(
        user_id=user_id or uuid.uuid4(),
        username=username or f"user-{uuid.uuid4().hex[:6]}",
        roles=list(roles),
        agency=desk.agency_id if desk else None,
        desk=desk.id if desk else None,
        clearance=desk.clearance if clearance is None and desk else (clearance or 0),
        field_unit=field_unit,
    )
    return {"Authorization": f"Bearer {tok}"}


@pytest.fixture
def staff():
    return staff_headers
