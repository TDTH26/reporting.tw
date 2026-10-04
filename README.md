# reporting.tw — UAV Sighting Reporting System

Anyone in Taiwan can report an illegal or suspicious drone, unmanned surface vessel or other questionable craft (in the air, at sea or on the coast) in minutes, anonymously. Reports are fused with
sensor tracks, Remote ID, CAA registry/permits, ADS-B, AIS/MDA tracks, agency camera feeds and weather into incidents, and each incident is routed
automatically to the right agency desk (police, CAA, defense) with escalation to backup desks.
The full design is in [`docs/design-document.md`](docs/design-document.md).

```
informant app (Android, web) ─┐                      ┌─ agency console (web, gov network)
field app (Android) ────────┤   FastAPI services   ├─ field app
RF/radar, Remote ID ────────┤  public · agency ·   │
CAA, ADS-B, weather, CCTV ──┘  ingest · analytics  │
                                   │  fusion · routing · worker (timeouts, re-routing, push)
                    PostgreSQL+PostGIS (hub) · MinIO (evidence, via tusd) · Keycloak (staff)
```

## Repository

| Path | What |
| --- | --- |
| `backend/` | Python 3.12 / FastAPI (`uavr`): APIs, fusion, routing, worker, migrations, tests |
| `schemas/feeds/v1/` | Versioned JSON Schemas for external feeds + examples (vendor contract) |
| `app/` | Flutter workspace (Melos): `apps/uavr` with `main_informant.dart`, `main_agency.dart`, `main_field.dart` |
| `app/packages/` | `uavr_api` (client + models), `uavr_core` (config, OIDC, live channel), `uavr_ui` (design system, 6-language strings, Noto fonts), `uavr_maps`, `uavr_capture` (capture, SHA-256, tus, background uploads), `uavr_native` (Kotlin: OpenDroneID, compass, Play Integrity), `feature_informant`, `feature_agency`, `feature_field` |
| `web/site/` | Static landing site for reporting.tw (six languages) |
| `deploy/` | `docker-compose.yml` (dev), Keycloak realm, nginx, Helm chart, production web images |
| `tools/` | Simulators for every external feed and public surges/spam, Locust load tests, smoke test |
| `docs/` | Design doc, feed integration guide, ADRs |

## Quick start (dev)

```sh
make up                      # db, minio, tusd, keycloak, api, worker, nginx
make seed                    # demo agencies, desks, zones, templates, dev feed key
make test                    # backend tests (uses the compose db)
cd backend && uv run python ../tools/smoke.py      # report -> tus upload -> verify -> console -> ack
make sim                     # simulated sensors, ADS-B escalation, CAA data, surge and spam
cd backend && uv run python -m uavr.atreides import "../hackathon/MDA Sensor Mini Sample_APRIL_26.csv" --shift-to-now
export FEATHERLESS_API_KEY=...  # before `make up`: enables AI triage of photos and camera frames
make build-informant-web build-agency-web            # then open http://localhost:8480/app/ and /console/
make build-android           # informant + field APKs (flavors)
```

| URL | |
| --- | --- |
| http://localhost:8480/ | landing site; `/app/` public web; `/console/` agency console; `/api/` API; `/files/` tus |
| http://localhost:8100/docs | API (OpenAPI UI) |
| http://localhost:8280 | Keycloak (admin/admin). Dev staff users, password `dev-password`: `tpe.dispatcher`, `apb.dispatcher`, `npa.command`, `mnd.joc`, `mnd.airbase`, `caa.officer`, `analyst`, `tpe.analyst`, `admin`, `tpe.field`, `mnd.field` |
| http://localhost:9101 | MinIO console |

Android emulator builds reach the dev stack at `http://10.0.2.2:8480/api`; override with
`--dart-define=UAVR_API=...`. Other build-time settings: `UAVR_OIDC_ISSUER`, `UAVR_TILES` (self-hosted tile
server; default NLSC EMAP), `UAVR_PLAY_PROJECT` (Play Integrity cloud project number), `UAVR_FIREBASE_*`.

## Report collection flow

1. App opens → GPS fix, time, Remote ID scan (Android: BT4, BT5 long range, Wi-Fi Beacon, Wi-Fi NAN).
2. Aim at the drone → true bearing + elevation from the rotation-vector sensor; a photo is taken at lock.
3. **Metadata packet first** (`POST /v1/reports`): position, bearing, elevation, Remote ID, file SHA-256s,
   Play Integrity token bound to a request hash. Fusion + routing + dispatcher alert happen in this request.
4. Response: case number + secret token; media uploads follow via tus (WorkManager keeps going in background);
   the server re-hashes every file.
5. Informant follows status, templated outcome and templated evidence requests with the token only.

## Deliberate deviations / additions to the design doc
See `docs/adr/`. In short: hand-written Dart client with an OpenAPI contract check (ADR 4); a single
unverified web report caps at Medium (ADR 5); dev uses `chainguard/minio` because upstream MinIO images are no
longer published (ADR 3); staff UIs ship in zh-TW + en, the public informant app in all eight languages.

## AI triage
Verified photos and sampled camera frames are assessed by Qwen3-VL-30B-A3B on Featherless (`backend/uavr/ai/`).
Advisory and raise-only, see `docs/adr/0006-ai-triage.md`. Without `FEATHERLESS_API_KEY` the feature is off.

## Not connected yet (stubbed behind interfaces)
Play Integrity and FCM need Google Cloud/Firebase projects; CAA registry/permits, ADS-B, RF/radar vendors and
CCTV need agreements (simulators stand in); the defense KMS (local dev key now); the self-hosted tile server
and machine translation run under `docker compose --profile full`. Open questions from the design doc remain open.
