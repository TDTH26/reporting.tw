# reporting.tw — Suspicious Craft Report (可疑載具通報)

Public reporting of suspicious drones (UAV) and maritime/coastal craft (USV, boats) in Taiwan, fused into incidents
and routed to agency desks. Internal code names stay `uavr`.

## Naming
- The public person is the **Informant** (never "citizen" or "reporter"; foreign residents report too).
- Display name: "Suspicious Craft Report" / 可疑載具通報; field app: 可疑載具勤務.
- Domain: `reporting.tw` (landing + informant web app at `/app/`), `api.reporting.tw`, `console.reporting.tw`.
- Informant languages: zh-TW, en, vi, id, th, fil, de, fr. Staff apps: zh-TW, en.
- German: "Verdächtige Luft/See-Objekte melden"; never "Fahrzeug" (use Objekt/Drohne/Boot). If in doubt ask.
- zh-TW: Taiwan terms only, no Mainland usage (checked with OpenCC s2twp; a plain character check gives false positives).

## Layout
- `backend/` Python 3.12 FastAPI, package `uavr`, uv. SQLAlchemy 2 async + **asyncmy** (aiomysql is broken), MySQL 8, Alembic.
- `app/` Flutter 3.41 pub workspace. Entry points `apps/uavr/lib/main_{informant,agency,field}.dart`;
  Android flavors `informant` (`tw.reporting.app`) and `field` (`tw.reporting.field`).
- `schemas/feeds/v1/` feed JSON Schemas + conformance kit (`python -m uavr.feeds.conformance`).
- `web/` landing site. `deploy/prod/` everything for production. `deploy/docker-compose.yml` is dev only.
- `hackathon/` (git-ignored): challenge brief `Hackathon.md`, EDTH onboarding guide (PDF), Atreides sample CSV,
  `credentials.md`, `android-key.properties`, Coast Guard photos, screenshots (`app-NN-*.png`, `console-NN-*.png`),
  PDF drafts of the deck (`draft-slides-YYYYMMDD-HHMM.pdf`). Deck source + render script: `hackathon/deck/`, how-to in
  `hackathon/slides.md`; demo video plan: `hackathon/video-build.md`.
- Atreides sample: MDA tracks (not AIS; ingested as `source_kind=mda`, never identifies a vessel).

## Decisions (do not revisit)
- MySQL 8 (server's 8.0.46), no PostgreSQL/PostGIS. Lat/lon DOUBLE + bbox prefilter + Python geometry (`uavr/geoutil.py`).
- Built-in staff auth (scrypt, HS256 15-min access tokens, rotating refresh in `staff_session`). No Keycloak.
- Evidence as plain local files in `UAVR_DATA_DIR/uploads`, sealed 0440 after hash check; signed `/v1/media` URLs. No S3/MinIO.
- No Docker in production. systemd units, all running as the single user `reportingtw`.
- AI triage: Featherless, model `Qwen/Qwen3-VL-30B-A3B-Instruct`, **raise-only, advisory** (+1 severity max; Critical needs
  corroboration). Video feeds: sampled frames. Key from a local creds file outside the repo (path in `hackathon/credentials.md`, `FEATHERLESS_API_KEY`) — never print it.
- Domain families (aerial vs maritime) never cluster together.

## Production server
- Host, SSH access, logins and where every secret lives: `hackathon/credentials.md` (git-ignored; this repo goes public,
  so no hostnames, ports, passwords or keys in tracked files). Ubuntu 22.04, Apache 2.4.52, MySQL 8.0.46, ~8 GB free disk.
- `/sites/reporting.tw/{site,app,console,src,bin/tusd,data,reporting.env}`.
- Cloudflare: `@` and `*` proxied, SSL "Full", self-signed origin cert `/etc/ssl/certs/static.crt` + `/etc/ssl/private/static.key`
 . No IP allowlist (Cloudflare handles it). No mail records needed.
- Apache: one file per project (`deploy/prod/apache/reporting.conf`); modules ssl proxy proxy_http headers remoteip only
  (no macro/tunnel). `RemoteIPHeader CF-Connecting-IP`; Apache sets `X-Real-IP`, backend reads `UAVR_CLIENT_IP_HEADER=X-Real-IP`.
- Services: `reporting-api` (127.0.0.1:8100, runs migrations on start), `reporting-worker`, `reporting-tusd` (127.0.0.1:8180).
- Install/update steps: `deploy/prod/README.md`. The user runs root commands; I only copy files (rsync to `src/` and the web dirs).
- Deploy workflow (SSH target in `hackathon/credentials.md`): rsync backend to `src/backend/` (exclude .venv), web builds to
  `site/ app/ console/`, then `sudo -n systemctl restart reporting-api reporting-worker` (sudoers allows exactly
  restart/status of reporting-api/-worker/-tusd; anything else needs the user). Migrations run on API start.
  reportingtw is in systemd-journal: `journalctl -u reporting-api`.
- Caching: Flutter web and site files are not content-hashed. Apache sends `Cache-Control: no-cache` for site/app/console;
  Cloudflare must have Browser Cache TTL = "Respect Existing Headers" or it rewrites that to max-age=14400 (4 h of
  stale apps). site.css/theme.js links carry ?v=YYYYMMDDHHMM: bump it when they change. Verify deploys WITHOUT a
  cache-busting query (check cf-cache-status).
- Atreides (hackathon partner, maritime MDA sensor, NOT AIS): `uavr/atreides.py` + `api/atreides.py`, console section
  `/atreides` with their logo. Server data imported with `--shift-to-now` (re-run to refresh the demo window).
  Never copy `.env`, `key.properties`, `*.jks`, creds, or `hackathon/` secrets to the server or into tracked files.

## Dev
- MySQL dev/test: `docker compose -f deploy/docker-compose.yml up -d db` (port 33306, user/pass uavr/uavr, test DB `uavr_test`).
- Backend tests: `cd backend && uv run pytest` (79 tests, ~8 min). Lint: `uv run ruff check`.
- Flutter: `cd app && flutter analyze && flutter test` per package; `dart run tool/check_api.dart` checks the client against OpenAPI.
- Release builds: `deploy/prod/build.sh` → `dist/` (web + APK/AAB with `UAVR_API=https://api.reporting.tw`).
  Signing: `hackathon/android-key.properties` (git-ignored) points at the upload keystore outside the repo.
- Staff users: `python -m uavr.users create|passwd|list`.
- CAA zones: `python -m uavr.caa_zones` imports layer UAV_fs_ryg from dronegis.caa.gov.tw (needs a browser User-Agent) as zones `CAA-<objectid>`; military sites -> MND-JOC, Coast Guard -> CGA-OPS, airports -> APB-OPS, rest by jurisdiction. Not published to informants (the app links to the CAA map).

## Features (state 2026-10-03, all deployed to reporting.tw)
- Informant app (Android + web, 8 languages): report with aim/compass, structured interview (air/water/under water/shore),
  Remote ID scan, photo/video/audio via tus, case number + private follow-up key, status and outcome, demo banner,
  "No-fly zones map" opens the CAA DroneGIS site. Landing page with walkthrough (`guide.html`), privacy policy
  (`privacy.html`, EN + zh-TW, INXSOFT Ltd., dpo@inxsoft.net), light/dark switch.
- Console: queue, case detail, live map, dashboards, admin, audit; title "Reporting.tw: Monitoring suspicious aerial and
  water activity reports." (zh: 監控可疑空中及水域活動通報) with user · desk · agency under it; app icon in the rail and login.
- Fusion/routing/severity, Featherless AI triage (raise-only), CAA zones import (`uavr/caa_zones.py`), ack-timeout re-routing.
- Atreides section (`/atreides`): MDA detections, reconstructed routes, filters; CLI `python -m uavr.atreides`.
- Maritime anomaly engine (`uavr/anomaly/`, console `/maritime`): rules (stop, deviation vs learned lanes, vessels
  meeting, protected-water entry/approach, reporting gap per source) + statistical baseline (per 0.1° cell speed×heading
  likelihood, percentile threshold) → risk score × data quality, reasons with value/threshold, uncertainty notes,
  event timeline, false alarm + suppress, notes, escalate to case (source `mda_sensor`), thresholds in `anomaly_setting`
  (supervisor/admin), worker runs every 5 min. Simulator `python -m uavr.anomaly simulate` (labelled traffic around
  Taiwan, source `sim`) + evaluation: combined F1 0.83, recall 1.00, 4.1 false alarms/100 normal tracks
  (rules alone 11.6, statistics alone 9.3). Protected waters = restricted_waters/coastal_defense only (drone zones
  cover fishing grounds).
- Camera tracking (`uavr/ai/video_tracker.py`): Featherless frame detections with boxes (prompt frame-2, 0-1000 coords)
  → persistent per-camera tracks (`video_track`), behaviours loiter/approaching/fast/watch area (`video_feed.alert_zone`),
  observations `feed:<id>:<track>` with bearing from the box centre; frames of one camera are processed in order.
  API: PUT /v1/admin/video-feeds/{id}, POST .../frames (admin), GET /v1/agency/video-feeds/{id}/tracks.
  Replay a video: `tools/video_replay.py` (ffmpeg locally). Console `/cctv` (above Admin): cameras "Name (ID)" (red while a case from its tracks is open), tracks, last frame
  with box/trail/watch area, linked case.
  Demo cameras: Yilan Coast (0AXD) with track 0AXD-T3 → case UAV-261003-000010; 8 more (1VD1, 2KX9, 3TQ7, 4PM8, 5RS2,
  6ZY3, 7HL4, 9KM5) without an image source, so no tracks.
- Android: version 1.0.1, build numbers 1-7 used (7 = 1.0.1; 5 = adaptive icon + localized launcher names in src/<flavor>/res/values-*/strings.xml,
  6 = German wording fix; APKs in dist/); icons from `tools/make_icon.py`.
  Homepage offers the APK directly (`web/site/download/reporting-informant-<ver>.apk`, git-ignored, rsync by hand;
  update the link in index.html per version); the Google Play button is greyed out (internal testers only).
- Drone response recommendations (`uavr/recommend.py`, case page panel): tower/ATC, nearest camera, nearest on-duty
  field unit (accepting assigns the officer), operator position, registry lookup, area warning, CGA boat/sensor for
  vessels; accept/reject/modify logged as case events. Decision support only, no device control.
- Demo accounts (password in `hackathon/credentials.md`): admin (admin+national+supervisor), mnd-admin, cga-admin, caa-admin,
  field (field_officer on TCPD-DISPATCH, for the field app; not a defense field unit).

## Hackathon (Taiwan Defense Tech Hackathon 2026, EDTH format)
- Challenges in `hackathon/Hackathon.md` (official numbers: 06 maritime, 04 drones): maritime track anomaly alerting (Atreides data) and low-cost drone detection
  and response. Deck: Claude artifact "Reporting.tw Hackathon Pitch" (links in `hackathon/slides.md`),
  15 slides in EDTH order; must credit Atreides (MDA sample data) and Featherless AI (image analysis).
- Submission: PDF/PPTX by Sunday noon, filename starts with the team number, demo video link in the deck; 3-minute pitch.
- Decks (Claude artifacts, links in `hackathon/slides.md`): v1 and v2 (kept), v3 (current, 14 slides: cover, the problem, duty officer,
  drones, end-to-end, demo, humans in control, detection, results, Atreides, deploy, business, status, team; market
  figures sourced: Grand View Research, MarketsandMarkets). New decks copy assets from the previous one (from_url +
  asset_ids). PDF drafts rendered with headless Chrome into `hackathon/draft-slides-YYYYMMDD-HHMM.pdf`
  (latest: 20261004-0053). EDTH: no slide limit, strict 3-minute pitch.
- Deck wording the user fixed: "Hackathon resources used:" (not "partners"); test set "189 tracks over 2 days";
  detection columns "Drones reported via the App", "Drones and vessels on CCTV", "Vessels from tracks"; desks
  "(CGA, NPA, CAA, MND)"; Atreides card "Data Reasoning"; Remote ID bullet "the drone broadcasted Remote ID ...
  via Bluetooth by the App"; slide 11 "Demo on console.reporting.tw"; agencies abbreviated (NPA, not "National Police").
- Team number 02: submission `hackathon/02_UAV-USV-Threat-Reporter.pdf` (render.py with that path). Demo video link on the
  last slide: https://reporting.tw/demovideo (`web/site/demovideo/`, deployed); it plays the file named in `const VIDEO` (now `demo-video-20261004-0815-kokoro-heart-zh.mp4`, uploaded straight from
  `hackathon/demo-videos/`). To replace it: rsync the new MP4 into `/sites/reporting.tw/site/demovideo/` and change VIDEO;
  everything there is served `no-cache`, so nothing stale.
- Open (2026-10-04): latest deck edits are in
  `hackathon/deck/` + PDF but not published to the v3 artifact (this account can't see it; new images have local ids
  in blobs.json). Camera tracks are shown in the video (no console page needed).
- Public repo: https://github.com/TDTH26/reporting.tw (push over SSH; repo-local git email tdth@inxsoft.net).
  `reporting.tw/sources` redirects there (`web/site/sources/index.html`). Keep secrets in `hackathon/`.
  Public contact address: tdth@inxsoft.net.

## MySQL gotchas
- Named locks (`GET_LOCK`) must be released **before** commit/rollback (`LockingSession`): the connection returns to the pool on commit.
- `NOW()` is second precision vs DATETIME(6) columns: compare with Python `now()`.
- `JSON_TABLE` fails on view columns: join base tables. No `NULLS LAST`: order by `col.is_(None)` first.
- Rate counters commit immediately in the caller's session (holding the row lock across fusion starves the pool).

## Preferences
- Focus on what runs in production; don't spend time on unused extras (docs rewrites, dev tooling polish).
- Commit only when asked.
