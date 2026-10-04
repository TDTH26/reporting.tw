# 4. Hand-written Dart API client with an OpenAPI contract check

**Decision.** `app/packages/uavr_api` is a small hand-written client with typed models instead of a
generated `dart-dio` client. `app/tool/check_api.dart` fails CI when the client calls a path/method that the
backend's generated OpenAPI spec (`backend/openapi.json`) does not have. Request-hash canonicalisation is
pinned by the same test vector on both sides.

**Why.** The generated client needs `build_runner`/`built_value` in every package and many staff endpoints
return documents assembled per viewer (redaction), which generate poorly. The plain models are easier to
read and review.

**Consequences.** Adding an endpoint means adding a method + model by hand; the contract check catches drift
in paths, not in field names (covered by widget/API tests).
