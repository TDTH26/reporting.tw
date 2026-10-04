"""Per-process WebSocket hub. MySQL has no LISTEN/NOTIFY, so every API process polls `live_event`
(one indexed query per POLL_INTERVAL for all its clients) and fans new rows out.

Ordering note: seq is assigned at INSERT but rows become visible at COMMIT, so a lower seq can appear after a
higher one. The poller therefore re-reads a short window behind the newest seq and skips seqs it has already
delivered; resume replays everything after last_seq plus the last 30 s, and clients de-duplicate by seq.
"""

import asyncio
import contextlib
import logging
from dataclasses import dataclass, field
from datetime import UTC, datetime, timedelta

from fastapi import WebSocket
from sqlalchemy import or_, select, text

from ..db.models import LiveEvent
from ..db.session import sessionmaker
from ..security.principal import ROLE_ANALYST, ROLE_DISPATCHER, ROLE_NATIONAL, ROLE_SUPERVISOR, Principal

log = logging.getLogger(__name__)
MAX_REPLAY = 2000


def view_for(p: Principal, ev: LiveEvent) -> dict | None:
    """The payload this principal may receive for an event, or None."""
    if ev.agency_ids == [-1]:  # broadcast
        return ev.payload if p.clearance >= ev.min_clearance else None
    involved = (
        p.has(ROLE_NATIONAL)
        or (p.desk_id is not None and p.desk_id in (ev.desk_ids or []))
        or (
            p.agency_id is not None
            and p.agency_id in ev.agency_ids
            and p.has(ROLE_DISPATCHER, ROLE_SUPERVISOR, ROLE_ANALYST)
        )
    )
    cleared = p.clearance >= ev.min_clearance
    if not involved and str(p.user_id) in [str(u) for u in (ev.field_user_ids or [])]:
        involved = True
        cleared = cleared and (ev.min_clearance < 2 or p.field_unit)
    if involved:
        return ev.payload if cleared else ev.redacted_payload
    if p.desk_id is not None and p.desk_id in (ev.redacted_desk_ids or []):
        return ev.redacted_payload
    return None


def _message(ev: LiveEvent, payload: dict) -> dict:
    return {"type": "event", "seq": ev.seq, "kind": ev.kind, "at": ev.at.isoformat(), "payload": payload}


@dataclass(eq=False)
class Client:
    ws: WebSocket
    principal: Principal
    queue: asyncio.Queue = field(default_factory=lambda: asyncio.Queue(maxsize=1000))


POLL_INTERVAL = 0.5
LOOKBACK = 200  # seqs re-checked behind the newest one (late commits)


class Hub:
    def __init__(self) -> None:
        self.clients: set[Client] = set()
        self._task: asyncio.Task | None = None
        self._delivered: set[int] = set()
        self._high = 0

    async def start(self) -> None:
        async with sessionmaker()() as s:
            self._high = (await s.execute(text("SELECT COALESCE(MAX(seq), 0) FROM live_event"))).scalar_one()
        self._task = asyncio.create_task(self._poll_forever())

    async def stop(self) -> None:
        if self._task:
            self._task.cancel()
            with contextlib.suppress(asyncio.CancelledError):
                await self._task

    async def _poll_forever(self) -> None:
        while True:
            try:
                await self.poll_once()
            except asyncio.CancelledError:
                raise
            except Exception as e:
                log.warning("live poll failed: %s", e)
            await asyncio.sleep(POLL_INTERVAL)

    async def poll_once(self) -> None:
        async with sessionmaker()() as s:
            rows = (
                (
                    await s.execute(
                        select(LiveEvent)
                        .where(LiveEvent.seq > self._high - LOOKBACK)
                        .order_by(LiveEvent.seq)
                        .limit(2000)
                    )
                )
                .scalars()
                .all()
            )
        for ev in rows:
            if ev.seq in self._delivered:
                continue
            self._delivered.add(ev.seq)
            self._high = max(self._high, ev.seq)
            self._fan_out(ev)
        # Keep the de-duplication set bounded to the look-back window.
        self._delivered = {q for q in self._delivered if q > self._high - LOOKBACK * 2}

    def _fan_out(self, ev: LiveEvent) -> None:
        for c in list(self.clients):
            payload = view_for(c.principal, ev)
            if payload is None:
                continue
            try:
                c.queue.put_nowait(_message(ev, payload))
            except asyncio.QueueFull:
                # Slow consumer: tell it to reload instead of buffering forever.
                with contextlib.suppress(Exception):
                    c.queue.get_nowait()
                    c.queue.put_nowait({"type": "resync_required"})

    async def replay(self, c: Client, last_seq: int) -> None:
        async with sessionmaker()() as s:
            newest = (await s.execute(text("SELECT coalesce(max(seq), 0) FROM live_event"))).scalar_one()
            if newest - last_seq > MAX_REPLAY:
                await c.ws.send_json({"type": "resync_required", "seq": newest})
                return
            rows = (
                await s.execute(
                    select(LiveEvent)
                    .where(or_(LiveEvent.seq > last_seq, LiveEvent.at > datetime.now(UTC) - timedelta(seconds=30)))
                    .order_by(LiveEvent.seq)
                    .limit(MAX_REPLAY)
                )
            ).scalars()
            for ev in rows:
                payload = view_for(c.principal, ev)
                if payload is not None:
                    await c.ws.send_json(_message(ev, payload))


hub = Hub()
