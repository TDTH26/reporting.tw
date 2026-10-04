"""tusd HTTP hooks. Evidence media upload resumably via tusd straight into the object store.

pre-create:  validates the per-file upload token and declared size, pins the object id to the
             evidence id so the stored key is predictable.
post-finish: re-hashes the stored object and compares it with the SHA-256 computed on the device
             at capture time (chain of custody).

The hook endpoint must only be reachable from tusd (network policy / nginx deny).
"""

import logging
from datetime import UTC, datetime

from fastapi import APIRouter, Depends, Request
from sqlalchemy.ext.asyncio import AsyncSession

from ..ai import jobs as ai_jobs
from ..db.models import Case, Evidence, Observation
from ..db.session import get_session
from ..domain.enums import CaseAction
from ..live.bus import publish_case
from ..routing.router import case_for_incident, event
from ..storage import files
from .informant_auth import check_upload

log = logging.getLogger(__name__)
router = APIRouter(prefix="/v1/uploads", tags=["uploads"], include_in_schema=False)


def _reject(code: int, msg: str) -> dict:
    return {"RejectUpload": True, "HTTPResponse": {"StatusCode": code, "Body": msg}}


def _header(req: dict, name: str) -> str | None:
    for k, v in (req.get("Header") or {}).items():
        if k.lower() == name.lower():
            return v[0] if isinstance(v, list) and v else v
    return None


@router.post("/hooks")
async def tus_hook(request: Request, session: AsyncSession = Depends(get_session)) -> dict:
    body = await request.json()
    kind = body.get("Type")
    ev = body.get("Event", {})
    upload = ev.get("Upload", {})
    http = ev.get("HTTPRequest", {})

    if kind == "pre-create":
        token = _header(http, "Upload-Token") or (upload.get("MetaData") or {}).get("upload_token")
        eid = check_upload(token or "")
        if eid is None:
            return _reject(403, "invalid upload token")
        e = await session.get(Evidence, eid)
        if e is None:
            return _reject(404, "unknown evidence")
        if e.status != "pending":
            return _reject(409, "already uploaded")
        size = upload.get("Size")
        if e.size_bytes and size and int(size) != e.size_bytes:
            return _reject(400, "size does not match declaration")
        return {
            "ChangeFileInfo": {"ID": str(e.id), "MetaData": {"evidence_id": str(e.id), "sha256": e.sha256_declared}}
        }

    if kind == "post-finish":
        meta = upload.get("MetaData") or {}
        storage = upload.get("Storage") or {}
        try:
            import uuid

            eid = uuid.UUID(meta.get("evidence_id", ""))
        except ValueError:
            return {}
        e = await session.get(Evidence, eid)
        if e is None:
            return {}
        # tusd filestore reports the absolute file path; it must lie inside UAVR_DATA_DIR.
        key = files.key_for(storage["Path"]) if storage.get("Path") else None
        key = key or f"uploads/{e.id}"
        await finalize(session, e, key, upload.get("ID"))
        await session.commit()
        return {}

    return {}


async def finalize(session: AsyncSession, e: Evidence, key: str, upload_id: str | None) -> None:
    digest, size = await files.sha256_of(key)
    e.storage_key = key
    e.tus_upload_id = upload_id
    e.sha256_verified = digest
    e.size_bytes = size
    e.uploaded_at = datetime.now(UTC)
    e.status = "verified" if digest == e.sha256_declared else "hash_mismatch"
    files.seal(key)  # stored unmodified from here on
    if e.status == "hash_mismatch":
        log.warning("evidence %s hash mismatch", e.id)
    await ai_jobs.enqueue_evidence(session, e)
    obs = await session.get(Observation, e.observation_id)
    if obs and obs.incident_id:
        case: Case | None = await case_for_incident(session, obs.incident_id, lock=False)
        if case:
            session.add(
                event(
                    case,
                    CaseAction.evidence_received,
                    data={"evidence_id": str(e.id), "kind": e.kind, "status": e.status},
                )
            )
            await session.flush()
            await publish_case(session, "case.evidence", case)
