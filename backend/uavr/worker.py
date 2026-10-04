"""Background worker (same codebase): ack timeouts and re-routing, push delivery, housekeeping.

Run any number of replicas; work is claimed with SELECT ... FOR UPDATE SKIP LOCKED.
    python -m uavr.worker
"""

import asyncio
import logging
import signal
from datetime import UTC, datetime, timedelta

from sqlalchemy import select, text, update

from .ai import jobs as ai_jobs
from .anomaly import engine as anomaly
from .api.analytics import refresh_views
from .cases import service
from .config import get_settings
from .db.models import Case, Incident, InformantToken, PushOutbox
from .db.session import sessionmaker
from .domain.enums import CaseState
from .notify.push import sender
from .routing.router import overdue_cases, reroute

log = logging.getLogger("uavr.worker")


async def escalate_overdue() -> int:
    """Re-route every New case whose acknowledgement deadline has passed."""
    async with sessionmaker()() as s:
        cases = await overdue_cases(s)
        for c in cases:
            await reroute(s, c, reason="ack_timeout")
        await s.commit()
        return len(cases)


async def deliver_push(batch: int = 100) -> int:
    async with sessionmaker()() as s:
        rows = (
            await s.execute(
                select(PushOutbox, InformantToken)
                .join(InformantToken, InformantToken.id == PushOutbox.token_id)
                .where(PushOutbox.sent_at.is_(None), PushOutbox.attempts < 5)
                .order_by(PushOutbox.id)
                .limit(batch)
                .with_for_update(of=PushOutbox, skip_locked=True)
            )
        ).all()
        # One push per token per batch is enough: the app fetches every update when opened.
        seen = set()
        for ob, tok in rows:
            ob.attempts += 1
            if tok.id in seen or not tok.push_token:
                ob.sent_at = datetime.now(UTC)
                continue
            seen.add(tok.id)
            try:
                await sender().send(tok.push_token, tok.language)
                ob.sent_at = datetime.now(UTC)
            except Exception as e:
                ob.error = str(e)[:500]
        await s.commit()
        return len(rows)


async def maritime_alerts() -> None:
    async with sessionmaker()() as s:
        out = await anomaly.run(s)
        await s.commit()
    if out["alerts_new"]:
        log.info("maritime alerts: %s", out)


async def housekeeping() -> None:
    s_ = get_settings()
    async with sessionmaker()() as s:
        # Incidents with no new observations stop absorbing reports (a new sighting opens a new incident).
        await s.execute(
            update(Incident)
            .where(
                Incident.active, Incident.last_seen < datetime.now(UTC) - timedelta(seconds=s_.incident_idle_close_s)
            )
            .values(active=False)
        )
        # Resolved cases are locked for analytics after the grace period.
        stale = (
            (
                await s.execute(
                    select(Case)
                    .where(
                        Case.state == CaseState.resolved.value,
                        Case.resolved_at < datetime.now(UTC) - timedelta(seconds=s_.resolved_autoclose_s),
                    )
                    .limit(200)
                    .with_for_update(of=Case, skip_locked=True)
                )
            )
            .unique()
            .scalars()
            .all()
        )
        for c in stale:
            await service.close(s, c, None)
        await s.execute(text("DELETE FROM rate_counter WHERE window_start < UTC_TIMESTAMP() - INTERVAL 1 DAY"))
        await s.commit()
    async with sessionmaker()() as s:
        await refresh_views(s)


ai_tasks: set[asyncio.Task] = set()


async def loop(stop: asyncio.Event) -> None:
    last_house = last_maritime = 0.0
    while not stop.is_set():
        try:
            n = await escalate_overdue()
            if n:
                log.info("re-routed %d overdue case(s)", n)
            await deliver_push()
            await ai_jobs.sample_feeds()
            # Fill free model slots; each call runs in the background so timers keep ticking.
            for _ in range(get_settings().ai_max_concurrent):
                t = asyncio.create_task(ai_jobs.run_one())
                ai_tasks.add(t)
                t.add_done_callback(ai_tasks.discard)
            now = asyncio.get_running_loop().time()
            if now - last_house > 300:
                await housekeeping()
                last_house = now
            if now - last_maritime > 300:
                last_maritime = now
                await maritime_alerts()
        except Exception:
            log.exception("worker iteration failed")
        try:
            await asyncio.wait_for(stop.wait(), timeout=2)
        except TimeoutError:
            pass


def main() -> None:
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s %(message)s")
    stop = asyncio.Event()

    async def run():
        lp = asyncio.get_running_loop()
        for sig in (signal.SIGINT, signal.SIGTERM):
            lp.add_signal_handler(sig, stop.set)
        log.info("worker started")
        await loop(stop)

    asyncio.run(run())


if __name__ == "__main__":
    main()
