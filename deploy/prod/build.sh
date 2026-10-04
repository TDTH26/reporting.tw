#!/usr/bin/env bash
# Build everything that is deployed as files, with production URLs. Run locally (needs Flutter).
# Output: dist/web/{site,app,console} and dist/*.apk|aab
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
APP="$ROOT/app/apps/uavr"
OUT="$ROOT/dist"
DEFINES=(--dart-define=UAVR_API=https://api.reporting.tw
         --dart-define=UAVR_VERSION="${VERSION:-1.0.1}")
mkdir -p "$OUT/web"
cd "$APP"
flutter build web -t lib/main_informant.dart --base-href /app/ -o "$OUT/web/app" "${DEFINES[@]}"
flutter build web -t lib/main_agency.dart --base-href / -o "$OUT/web/console" "${DEFINES[@]}"
rm -rf "$OUT/web/site" && cp -r "$ROOT/web/site" "$OUT/web/site"
if [[ "${WEB_ONLY:-0}" != 1 ]]; then
  flutter build appbundle --release --flavor informant -t lib/main_informant.dart "${DEFINES[@]}"
  flutter build apk --release --flavor informant -t lib/main_informant.dart "${DEFINES[@]}"
  # Pilot: the field app uses the public API host (no MDM VPN yet).
  flutter build apk --release --flavor field -t lib/main_field.dart "${DEFINES[@]}"
  V="${VERSION:-1.0.1}"
  cp build/app/outputs/bundle/informantRelease/app-informant-release.aab "$OUT/reporting-informant-$V.aab"
  cp build/app/outputs/flutter-apk/app-informant-release.apk "$OUT/reporting-informant-$V.apk"
  cp build/app/outputs/flutter-apk/app-field-release.apk "$OUT/reporting-field-$V.apk"
fi
echo "built into $OUT"
