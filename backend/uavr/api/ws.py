import asyncio
import contextlib

from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from sqlalchemy import text

from ..db.session import sessionmaker
from ..live.hub import Client, hub
from ..security.auth import staff_from_websocket

router = APIRouter()


@router.websocket("/v1/ws")
async def live(ws: WebSocket) -> None:
    """Live channel for console and field app.

    Auth: ?token=<access token>. Client -> server: {"type":"resume","last_seq":N} | {"type":"ping"}.
    Server -> client: hello, event (with seq), resync_required, pong.
    """
    try:
        async with sessionmaker()() as s:
            p = await staff_from_websocket(ws, s)
            seq = (await s.execute(text("SELECT coalesce(max(seq), 0) FROM live_event"))).scalar_one()
    except Exception:
        await ws.close(code=4401)
        return
    await ws.accept()
    client = Client(ws, p)
    hub.clients.add(client)
    await ws.send_json({"type": "hello", "seq": seq, "user": p.username})

    async def pump():
        while True:
            await ws.send_json(await client.queue.get())

    sender = asyncio.create_task(pump())
    try:
        while True:
            msg = await ws.receive_json()
            if msg.get("type") == "resume":
                await hub.replay(client, int(msg.get("last_seq", 0)))
            elif msg.get("type") == "ping":
                await ws.send_json({"type": "pong"})
    except (WebSocketDisconnect, RuntimeError, ValueError):
        pass
    finally:
        hub.clients.discard(client)
        sender.cancel()
        with contextlib.suppress(asyncio.CancelledError):
            await sender
