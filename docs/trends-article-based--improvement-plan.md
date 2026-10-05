# Reporting.tw — 10 improvements derived from the article "Reconnaissance-Strike Integrated UAVs and Future Operational Trends"

## Context
The paper (Air Force Officer Bimonthly No. 250, Lin Wei & Luo Dejun) argues that recon-strike UAVs win through
(a) persistent recon that cues strikes ("two-layer" TB2 scout + Harop strike), (b) swarms that saturate defences,
(c) cheap one-way attackers (Shahed-136) used at night against **energy infrastructure**, (d) electronic warfare
(GPS / link jamming), and it recommends for Taiwan: layered defence fusing ground/air/maritime networks, a
**national UAV data centre**, strict enforcement against violators in restricted zones, and **public awareness and
drills**. Reporting.tw is the civilian sensor and routing layer of that picture. Checked against the code:

- The interview already asks `count` (1/2/3+) (`backend/uavr/interview.py:352,448`), but severity never uses it
  (`backend/uavr/fusion/severity.py` has no count/swarm input).
- `aerial_type` only has multirotor / fixed_wing / balloon / unsure: no delta-wing / one-way attack class, no sound question.
- No time-pattern logic: each incident is judged alone, so repeated recon passes over one site are invisible.
- No GNSS/jamming signal anywhere; informant app has idempotent retry but no offline outbox.
- `recommend.py` suggests tower, camera, field unit, CGA, but knows no counter-UAS sites.
- Zones: CAA import + military/airport; power plants, substations, LNG terminals, undersea-cable landings are not explicit.

## The 10 recommendations

| # | Recommendation (paper link) | What to build | Impact | Feasibility |
|---|---|---|---|---|
| 1 | **Swarm / multi-craft detection** (swarm tactics, saturation) | Use interview `count`; in fusion, flag ≥3 craft in one report or ≥3 concurrent aerial incidents within ~5 km/10 min as a *coordinated activity* group; severity reason `multiple_craft` (+1, Critical near critical zones); console badge + map grouping | 5 | 5 |
| 2 | **Recon-before-strike pattern alert** (TB2 scouts cueing Harop) | Pattern-of-life per protected zone: N sightings over the same military/infrastructure zone in X days → "repeat reconnaissance" alert on the zone, links prior cases; reuse anomaly engine style (reasons with value/threshold) | 5 | 4 |
| 3 | **One-way-attack drone class + sound question** (Shahed-136 at night, moped-like engine) | Add `aerial_type` options *delta/triangle wing* and *large fixed wing*; new question `aerial_sound` (buzz/whine, loud engine like a moped, jet, silent); severity: delta/loud-engine → Critical, bypassing the single-web-report cap; extend Featherless prompt with these classes; 8 languages | 5 | 5 |
| 4 | **Energy & critical infrastructure zones** (Shahed vs power stations, transport hubs) | Importer (like `caa_zones.py`) for power plants, substations, LNG/oil terminals, cable landing stations, major bridges/ports from open data (Taipower list / OSM) as `critical_infrastructure`, routed to the owning desk; not published to informants | 5 | 4 |
| 5 | **Counter-UAS hand-off** (Army's 26 C-UAS sets, jamming guns, layered defence) | `cuas_site` registry (position, range, owner desk, on-duty) + map layer; `recommend.py` adds "nearest C-UAS unit in range" suggestion with accept/reject logging. Decision support only, no device control (same rule as today) | 5 | 4 |
| 6 | **GNSS jamming / spoofing indicator** (EW, GPS jamming of navigation) | Informant app sends location accuracy + (Android) satellite count / mock-location flag with each report; backend aggregates degraded-GNSS reports per cell and time → "possible jamming" layer on live map and a severity reason; also guards against spoofed informant positions | 4 | 3 |
| 7 | **Outbound common operating picture feed** (national data centre, data links, information sharing) | Read-only signed feed of open incidents (positions, domain, severity, craft class) in Cursor-on-Target XML + JSON schema in `schemas/feeds/v1/` with conformance test, per-agency API keys; lets MND/NCSIST C2 consume our tracks | 4 | 4 |
| 8 | **Resilient reporting under comms disruption** (jamming of communications, infrastructure strikes) | Offline outbox in informant app (store report + media, send on reconnect with original timestamp/idempotency key); SMS fallback text with case data to a short code shown when offline; service-worker caching for web | 4 | 3 |
| 9 | **Enforcement evidence package** (strict enforcement against violators in restricted zones, legal/ethical controls) | One-click export per case: signed ZIP with evidence files, SHA-256 manifest, case events/audit trail, zone + permit check, AI-advisory labelling; for CAA fines/prosecution; keeps the human-decision trail the paper asks for | 3 | 5 |
| 10 | **Drill / exercise mode** (public awareness, all-out defence drills) | `exercise` flag on cases and reports; supervisor injects scripted scenarios (swarm, USV landing) into the queue, never mixed with real stats; measures ack/assign/close times per desk; public "practice report" in the app for civil-defence days | 4 | 3 |

Scores 1–5 (Impact = contribution to detection/response of the threats in the paper; Feasibility = effort/risk in
this codebase, data availability, no new infrastructure).

## Impact / Feasibility matrix

```
Impact
  5 |                         [2 Recon pattern]   [1 Swarm]
    |                         [4 Infra zones]     [3 Shahed class + sound]
    |                         [5 C-UAS hand-off]
  4 |   [6 GNSS jamming]      [7 COP feed]
    |   [8 Offline/SMS]
    |   [10 Drills]
  3 |                                             [9 Evidence package]
    +---------------------------------------------------------------
          3 (harder)              4                   5 (easy)      Feasibility
```

- **Quick wins (do first):** 3, 1, 9 — small changes in `interview.py`, `fusion/severity.py`, fusion grouping, one export endpoint.
- **Strategic (next):** 2, 4, 5, 7 — new tables/importers but follow existing patterns (`caa_zones.py`, `anomaly/`, `recommend.py`, feed schemas).
- **Investments (later):** 6, 8, 10 — touch the Flutter app on Android + web, native permissions, or process/organisation work.

## Suggested order and touch points (if implementation is approved later)
1. #3 + #1: `backend/uavr/interview.py` (new options/question, 8 languages incl. de/fr dict), `fusion/severity.py`
   (`SeverityInput.craft_count`, `attack_profile`), `fusion/engine.py` (pass facts, group concurrent incidents),
   `ai/triage.py` prompt, console badge; tests in `backend/tests/` for severity rules.
2. #9: endpoint in `api/agency.py` reusing `storage/` sealed files + `cases/service.py` events.
3. #4: `uavr/infra_zones.py` modelled on `caa_zones.py`; #5: `cuas_site` model + Alembic migration + `recommend.py`.
4. #2: rule in `anomaly/` style for aerial zone recurrence, worker job every 5 min (`worker.py`).
5. #7: `schemas/feeds/v1/cop.json` + conformance kit; #6/#8/#10 afterwards.

## Verification
- Backend: `cd backend && uv run pytest` (new severity/grouping tests), `uv run ruff check`.
- Flutter: `flutter analyze && flutter test`, `dart run tool/check_api.dart` after API changes.
- Demo: file 3 reports within 5 min near a military zone on the dev stack → one coordinated-activity group, Critical,
  reason `multiple_craft`; report "delta wing + moped sound" from web → Critical despite single web report.
