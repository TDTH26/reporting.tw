# Deployment

## Hostnames

| Host | Serves | Exposure |
| --- | --- | --- |
| `reporting.tw` | Static landing page (8 languages, Play Store link, QR target) and the informant web app at `/app/` | Public |
| `api.reporting.tw` | Informant API (`/v1/reports`, `/v1/informant/*`, `/v1/public/*`), tus uploads (`/files/`), feed ingestion (`/v1/ingest/*`, mTLS in production) | Public; staff paths return 404 |
| `login.reporting.tw` | Keycloak (staff login only; admin console blocked at the proxy) | Public, because field officers log in over mobile networks |
| `console.reporting.internal` | Agency console | Government network / VPN only |
| `api.console.reporting.internal` | Staff API (`/v1/agency`, `/v1/field`, `/v1/analytics`, `/v1/admin`, `/v1/ws`) | Government network, plus the field app through an MDM per-app VPN |

The root domain stays a lightweight static page rather than the Flutter app: it loads instantly on slow
phones and in every language, can be indexed and linked from QR codes, and sends people either to the Play
Store or to `/app/` for web reporting. `app.reporting.tw` is not used, so nobody confuses "the app" with the API.

## Pilot (single VM, Taiwan region)

Ready-to-use files for a Google Cloud VM with Apache2 are in [`deploy/prod/`](../deploy/prod/README.md):
production compose file, one Apache config (`apache/reporting.conf`) for `reporting.tw`, `api.`, `login.`, `console.` and `media.reporting.tw`,
the production Keycloak realm (no dev users), and build / install / backup scripts.
In the pilot the console is `console.reporting.tw` (IP allowlist) and the field app talks to `api.reporting.tw`.

The generic steps below are superseded by that README.

For a pilot, one VM is enough, e.g. Google Cloud `asia-east1` (Changhua County) or Chunghwa Telecom HiCloud:
4 vCPU, 16 GB RAM, 200 GB SSD, Ubuntu 24.04, Docker.

1. DNS: `A` records for `reporting.tw`, `api.reporting.tw` and `login.reporting.tw` pointing at the VM.
2. Copy the repo, then create `deploy/.env` from `deploy/.env.example` with real secrets
   (`POSTGRES_PASSWORD`, `MINIO_ROOT_*`, `KEYCLOAK_ADMIN_PASSWORD`, `UAVR_PEPPER`, `UAVR_DEV_KEY`,
   `FEATHERLESS_API_KEY`). Set `UAVR_ENV=prod`, which disables locally issued dev tokens.
3. Build the web apps with production URLs:
   `flutter build web -t lib/main_informant.dart --base-href /app/ --dart-define=UAVR_API=https://api.reporting.tw`
4. Put a TLS reverse proxy in front (Caddy gets Let's Encrypt certificates automatically) that maps the
   hosts above onto the compose services (`web`, `api`, `tusd`, `keycloak`), denies `/v1/uploads/hooks`, and
   only serves the staff paths on a VPN or allowlisted address.
5. `make up && make seed`, then create real staff users in Keycloak and remove the dev users.

## Production (government cloud / on-premise)

Use the Helm chart in `deploy/helm/uavr` on Kubernetes, with PostgreSQL+PostGIS (CloudNativePG), the MinIO
operator and the Keycloak operator. The chart already separates the public and internal ingresses, runs migrations
as a pre-upgrade job and scales the API.

## Mobile builds

Release builds read the backend location from `--dart-define`:

```sh
cd app/apps/uavr
flutter build appbundle --release --flavor informant -t lib/main_informant.dart \
  --dart-define=UAVR_API=https://api.reporting.tw --dart-define=UAVR_OIDC_ISSUER=https://login.reporting.tw/realms/uavr
flutter build apk --release --flavor field -t lib/main_field.dart \
  --dart-define=UAVR_API=https://api.console.reporting.internal --dart-define=UAVR_OIDC_ISSUER=https://login.reporting.tw/realms/uavr
```

Signing uses `hackathon/android-key.properties` at the repo root (git-ignored; `android/key.properties` also works), which points at the upload keystore kept outside the repo.
Back that key up: it is needed for every Play Store update, unless Play App Signing key reset is requested.
