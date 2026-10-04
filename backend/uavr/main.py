import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .api import admin, agency, analytics, atreides, auth, ingest, maritime, media, reports, uploads, ws
from .config import Settings, get_settings
from .db.session import dispose
from .live.hub import hub

log = logging.getLogger("uavr")


@asynccontextmanager
async def lifespan(app: FastAPI):
    s = get_settings()
    if not s.is_dev:
        weak = [
            n
            for n in ("jwt_secret", "pepper", "dev_key")
            if getattr(s, n) == Settings.model_fields[n].default or len(getattr(s, n)) < 24
        ]
        if weak:
            raise RuntimeError(f"set strong production secrets for: {', '.join('UAVR_' + w.upper() for w in weak)}")
    from .storage.files import root

    log.info("evidence stored in %s", root())
    await hub.start()
    yield
    await hub.stop()
    await dispose()


app = FastAPI(
    title="UAV Sighting Reporting System API",
    version="1.0.0",
    description="Informant, agency, field, ingestion and analytics APIs for reporting.tw.",
    lifespan=lifespan,
)

s = get_settings()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"] if s.is_dev else s.cors_origins,
    allow_methods=["*"],
    allow_headers=["*"],
)

for r in (
    auth.router,
    reports.router,
    media.router,
    uploads.router,
    agency.router,
    agency.field_router,
    atreides.feed_router,  # before ingest.router's /{feed}
    ingest.router,
    atreides.router,
    maritime.router,
    analytics.router,
    admin.router,
    ws.router,
):
    app.include_router(r)


@app.get("/healthz", include_in_schema=False)
async def healthz() -> dict:
    return {"ok": True}
