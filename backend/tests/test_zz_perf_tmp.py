import asyncio
import time

from tests.helpers import XINYI, report


async def test_perf(client):
    t = []
    for i in range(20):
        t0 = time.perf_counter()
        r = await client.post("/v1/reports", json=report(XINYI, observer_bearing=i * 17.0, jitter=4))
        assert r.status_code == 201, r.text
        t.append(time.perf_counter() - t0)
    print("\nsequential ms:", [round(x * 1000) for x in t])
    t0 = time.perf_counter()
    rs = await asyncio.gather(
        *(client.post("/v1/reports", json=report(XINYI, observer_bearing=i * 7.0)) for i in range(30))
    )
    print("30 concurrent: %.1fs" % (time.perf_counter() - t0), {r.status_code for r in rs})
