"""AI job queue: informant/field photos (priority 3) and sampled video frames (priority 8).

Model calls take seconds to minutes, so they never run inside the report request. Jobs are claimed under
an advisory lock so that `running` jobs across *all* worker replicas stay within the provider's
concurrency budget; busy/rate-limited calls are re-queued with exponential backoff.
"""

import hashlib
import logging
import shutil
import uuid
from datetime import UTC, datetime, timedelta

import httpx
from sqlalchemy import func, select, text
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import aliased

from ..config import get_settings
from ..db.models import AiJob, Evidence, Incident, Observation, VideoFeed
from ..db.session import sessionmaker
from ..domain.enums import BASE_CONFIDENCE, SourceType
from ..fusion.engine import fuse, recompute
from ..routing.router import apply_incident_update
from ..storage import files
from . import triage, video_tracker
from .client import AiError, AiUnavailable, chat, jpeg_data_url

log = logging.getLogger(__name__)
CLAIM_ROW = "ai_claim"  # counter row locked FOR UPDATE: transaction-scoped, released at commit
MAX_ATTEMPTS = 6
FRAME_MIN_CONFIDENCE = 0.5
IMAGE_MIMES = ("image/jpeg", "image/png", "image/webp", "image/heic")


def _now() -> datetime:
    return datetime.now(UTC)


async def enqueue_evidence(session: AsyncSession, e: Evidence) -> None:
    """Called when an uploaded photo is verified. Videos/audio are not sent (frames/audio models later)."""
    s = get_settings()
    if not s.ai_enabled or not s.ai_api_key or e.kind != "photo" or e.status != "verified":
        return
    session.add(AiJob(kind="evidence", priority=3, observation_id=e.observation_id, evidence_id=e.id))


async def claim(session: AsyncSession) -> AiJob | None:
    s = get_settings()
    # Serialise claims across workers so `running` never exceeds the provider budget.
    await session.execute(text("SELECT value FROM counter WHERE name = :n FOR UPDATE"), {"n": CLAIM_ROW})
    stale = _now() - timedelta(seconds=s.ai_timeout_s * 2)
    # A worker that died mid-call leaves a `running` row; give its slot back after a timeout.
    await session.execute(
        text("UPDATE ai_job SET status='queued' WHERE status='running' AND started_at < :t"), {"t": stale}
    )
    running = (await session.execute(select(func.count()).where(AiJob.status == "running"))).scalar_one()
    busy = aliased(AiJob)
    if running >= s.ai_max_concurrent:
        return None
    job = (
        await session.execute(
            select(AiJob)
            .where(
                AiJob.status == "queued",
                AiJob.not_before <= _now(),
                # Tracking needs one camera's frames in order: never two running for the same feed.
                (AiJob.feed_id.is_(None))
                | AiJob.feed_id.not_in(select(busy.feed_id).where(busy.status == "running", busy.feed_id.is_not(None))),
            )
            .order_by(AiJob.priority, AiJob.id)
            .limit(1)
            .with_for_update(skip_locked=True)
        )
    ).scalar_one_or_none()
    if job:
        job.status, job.started_at, job.attempts = "running", _now(), job.attempts + 1
    await session.commit()
    return job


async def run_one() -> bool:
    """Claim and execute one job. Returns False when nothing could be claimed."""
    async with sessionmaker()() as s:
        job = await claim(s)
    if job is None:
        return False
    try:
        if job.kind == "evidence":
            result, latency = await _triage_evidence(job)
        else:
            result, latency = await _detect_frame(job)
    except AiUnavailable as e:
        await _requeue(job.id, str(e))
        return True
    except (AiError, OSError) as e:
        await _finish(job.id, "failed", error=str(e)[:1000])
        return True
    await _finish(job.id, "done", result=result, latency=latency)
    return True


async def _requeue(job_id: int, error: str) -> None:
    async with sessionmaker()() as s:
        j = await s.get(AiJob, job_id)
        j.error = error
        if j.attempts >= MAX_ATTEMPTS:
            j.status, j.finished_at = "failed", _now()
        else:
            j.status = "queued"
            j.not_before = _now() + timedelta(seconds=min(600, 30 * 2 ** (j.attempts - 1)))
        await s.commit()


async def _finish(job_id: int, status: str, *, result=None, latency=None, error=None) -> None:
    async with sessionmaker()() as s:
        j = await s.get(AiJob, job_id)
        j.status, j.finished_at, j.result, j.latency_s, j.error = status, _now(), result, latency, error
        j.model = get_settings().ai_model
        await s.commit()


async def _triage_evidence(job: AiJob) -> tuple[dict, float]:
    async with sessionmaker()() as s:
        e = await s.get(Evidence, job.evidence_id)
        o = await s.get(Observation, job.observation_id)
        key, domain, ctype = e.storage_key, o.craft_domain, o.craft_type
    data = await files.get_bytes(key)
    text_out, latency = await chat(triage.triage_messages(jpeg_data_url(data), domain, ctype))
    res = triage.parse_triage(text_out)
    assessment = {
        **res.model_dump(),
        "threat_level": res.threat_level if res.relevant else 1,
        "model": get_settings().ai_model,
        "prompt_version": triage.PROMPT_VERSION,
        "evidence_id": str(job.evidence_id),
        "at": _now().isoformat(),
    }
    await _apply(job.observation_id, assessment)
    return assessment, latency


async def _apply(observation_id: uuid.UUID, assessment: dict) -> None:
    async with sessionmaker()() as s:
        o = await s.get(Observation, observation_id)
        o.ai_assessment = assessment
        await s.flush()
        if o.incident_id:
            inc = await s.get(Incident, o.incident_id, with_for_update=True)
            await recompute(s, inc)
            await apply_incident_update(s, inc, created=False)
        await s.commit()


# ------------------------------------------------------------------ video feeds


async def sample_feeds(limit: int = 10) -> int:
    """Fetch due frames and queue them for detection, unless the queue is already busy."""
    s_ = get_settings()
    if not s_.ai_enabled or not s_.ai_api_key:
        return 0
    async with sessionmaker()() as s:
        backlog = (
            await s.execute(select(func.count()).where(AiJob.kind == "frame", AiJob.status.in_(["queued", "running"])))
        ).scalar_one()
        if backlog >= s_.video_frame_backlog:
            return 0
        feeds = await session_feeds(s)
        now = _now()
        due = [
            f
            for f in feeds
            if f.last_sampled_at is None or (now - f.last_sampled_at).total_seconds() >= f.sample_interval_s
        ]
        due.sort(key=lambda f: f.last_sampled_at or datetime.min.replace(tzinfo=UTC))
        due = due[: min(limit, s_.video_frame_backlog - backlog)]
        n = 0
        for f in due:
            f.last_sampled_at = _now()
            try:
                frame = await grab_frame(f)
            except Exception as e:  # camera offline etc.: record and move on
                f.last_error = str(e)[:500]
                continue
            digest = hashlib.sha256(frame).hexdigest()
            if digest == f.last_frame_sha256:
                continue  # static scene, nothing new to look at
            f.last_frame_sha256, f.last_error = digest, None
            key = f"frames/{f.id}/{_now():%Y%m%dT%H%M%S}-{digest[:12]}.jpg"
            files.put_bytes(key, frame, "image/jpeg")
            s.add(AiJob(kind="frame", priority=8, feed_id=f.id, frame_key=key))
            n += 1
        await s.commit()
        return n


async def session_feeds(s: AsyncSession) -> list[VideoFeed]:
    return list(
        (await s.execute(select(VideoFeed).where(VideoFeed.active).with_for_update(skip_locked=True))).scalars()
    )


async def grab_frame(f: VideoFeed) -> bytes:
    if f.snapshot_url:
        async with httpx.AsyncClient(timeout=10, follow_redirects=True) as c:
            r = await c.get(f.snapshot_url)
            r.raise_for_status()
            if len(r.content) > 8 << 20:
                raise ValueError("frame too large")
            return r.content
    if f.stream_url and shutil.which("ffmpeg"):
        import asyncio

        proc = await asyncio.create_subprocess_exec(
            "ffmpeg",
            "-loglevel",
            "error",
            "-y",
            "-i",
            f.stream_url,
            "-frames:v",
            "1",
            "-f",
            "image2",
            "-",
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )
        out, err = await asyncio.wait_for(proc.communicate(), timeout=20)
        if proc.returncode != 0:
            raise ValueError(err.decode()[:300])
        return out
    raise ValueError("feed has no snapshot_url (and no ffmpeg for stream_url)")


async def _detect_frame(job: AiJob) -> tuple[dict, float]:
    async with sessionmaker()() as s:
        f = await s.get(VideoFeed, job.feed_id)
        domains = list(f.domains or ["aerial", "surface"])
    data = await files.get_bytes(job.frame_key)
    text_out, latency = await chat(triage.frame_messages(jpeg_data_url(data), domains), max_tokens=600)
    res = triage.parse_frame(text_out)
    keep = [d for d in res.detections if d.confidence >= FRAME_MIN_CONFIDENCE and d.craft_domain in domains]
    at = job.frame_at or _now()
    tracks: list[str] = []
    if keep:
        async with sessionmaker()() as s:
            f = await s.get(VideoFeed, job.feed_id)
            dets = [
                video_tracker.Det(
                    d.craft_domain,
                    d.craft_type,
                    d.confidence,
                    tuple(d.box) if d.box else None,
                    d.horizontal_position,
                    d.description,
                )
                for d in keep
            ]
            matched = await video_tracker.update_tracks(s, f, dets, at, job.frame_key)
            tracks = [t.key for _d, t in matched]
            info = [(d, t.key, list(t.behaviours)) for d, (_det, t) in zip(keep, matched, strict=True)]
            await s.commit()
        for d, key, behaviours in info:
            await _frame_observation(job, d, data, at, key, behaviours)
    return {
        "detections": [d.model_dump() for d in res.detections],
        "observations": len(keep),
        "tracks": tracks,
        "prompt_version": triage.FRAME_PROMPT_VERSION,
    }, latency


async def _frame_observation(
    job: AiJob, d: triage.Detection, frame: bytes, at: datetime, track_key: str, behaviours: list[dict]
) -> None:
    async with sessionmaker()() as s:
        f = await s.get(VideoFeed, job.feed_id)
        bearing = None
        if f.bearing_deg is not None:
            fov = f.fov_deg or 60
            if d.box:  # bearing from the box centre across the field of view
                offset = ((d.box[0] + d.box[2]) / 2 - 0.5) * fov
            else:
                offset = {"left": -1, "center": 0, "right": 1}[d.horizontal_position] * fov / 3
            bearing = (f.bearing_deg + offset) % 360
        o = Observation(
            id=uuid.uuid4(),
            source_type=SourceType.video_ai.value,
            source_id=f"feed:{f.id}:{track_key}",
            observed_at=at,
            observer_lat=f.lat,
            observer_lon=f.lon,
            bearing_deg=bearing,
            bearing_accuracy_deg=((f.fov_deg or 60) / (12 if d.box else 4)) if bearing is not None else None,
            craft_domain=d.craft_domain,
            craft_type=d.craft_type,
            confidence=BASE_CONFIDENCE[SourceType.video_ai] * d.confidence,
            classification=f.classification,
            fidelity="low",
            attestation="agency_feed",
            description="; ".join([d.description, *(b["text"] for b in behaviours)]).strip("; ")[:500],
            description_lang="en",
            ai_assessment={
                **d.model_dump(),
                "model": get_settings().ai_model,
                "prompt_version": triage.FRAME_PROMPT_VERSION,
                "frame_key": job.frame_key,
            },
            raw_payload={
                "feed": f.id,
                "frame_key": job.frame_key,
                "detection": d.model_dump(),
                "track": track_key,
                "behaviours": behaviours,
            },
            schema_version="video-ai/1",
        )
        s.add(o)
        digest = hashlib.sha256(frame).hexdigest()
        s.add(
            Evidence(
                id=uuid.uuid4(),
                observation_id=o.id,
                kind="photo",
                mime_type="image/jpeg",
                sha256_declared=digest,
                sha256_verified=digest,
                status="verified",
                size_bytes=len(frame),
                captured_at=at,
                uploaded_at=_now(),
                attestation="agency_feed",
                storage_key=job.frame_key,
            )
        )
        await s.flush()
        inc, created = await fuse(s, o)
        await apply_incident_update(s, inc, created)
        await s.commit()
