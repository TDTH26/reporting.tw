# 1. PostgreSQL is the only hub (no message bus)

**Decision.** API, worker and live updates communicate only through PostgreSQL + PostGIS:
fusion runs inside the request transaction, the worker claims timers with `FOR UPDATE SKIP LOCKED`,
WebSocket fan-out uses `LISTEN/NOTIFY` on `live_event` inserts, rate limits are counters in a table.

**Why.** Matches the design doc; one stateful component to operate, back up and accredit on-premise.
Load (hundreds of reports per minute in a surge) is well within one primary.

**Consequences.** Concurrency is handled with locks: advisory locks on the 3×3 grid cells around a new
observation (cells are larger than the clustering radius) plus row locks on incidents, so a surge never
creates duplicate incidents (`tests/test_flow.py::test_surge_of_reports_becomes_one_incident`).
Live events carry a `seq`; because NOTIFY is delivered at commit, clients de-duplicate and resume
replays the last 30 s. The fusion module has a narrow interface (`fuse`, `recompute`) if it must move out.
