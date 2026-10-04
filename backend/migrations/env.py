import asyncio

from alembic import context
from sqlalchemy.ext.asyncio import create_async_engine

from uavr.config import get_settings
from uavr.db.models import Base

target_metadata = Base.metadata


def include_object(obj, name, type_, reflected, compare_to):
    # Views are created by migrations, not by the ORM metadata.
    return not (type_ == "table" and reflected and compare_to is None)


def do_run(connection):
    context.configure(
        connection=connection, target_metadata=target_metadata, include_object=include_object, compare_type=True
    )
    with context.begin_transaction():
        context.run_migrations()


async def run_async():
    url = context.config.attributes.get("url") or get_settings().database_url
    engine = create_async_engine(url, connect_args={"init_command": "SET time_zone = '+00:00'"})
    async with engine.connect() as conn:
        await conn.run_sync(do_run)
    await engine.dispose()


asyncio.run(run_async())
