"""Evidence downloads through short-lived signed URLs (issued by /v1/agency/evidence/{id}/url, audited there)."""

import mimetypes

from fastapi import APIRouter, HTTPException
from fastapi.responses import FileResponse

from ..storage import files

router = APIRouter(tags=["media"], include_in_schema=False)


@router.get("/v1/media/{key:path}")
async def media(key: str, e: int, s: str) -> FileResponse:
    if not files.verify(key, e, s):
        raise HTTPException(403, "link expired or invalid")
    try:
        p = files.path_for(key)
    except ValueError:
        raise HTTPException(404, "not found") from None
    if not p.is_file():
        raise HTTPException(404, "not found")
    return FileResponse(
        p,
        media_type=mimetypes.guess_type(p.name)[0] or "application/octet-stream",
        headers={"Cache-Control": "private, no-store", "Content-Disposition": "inline"},
    )
