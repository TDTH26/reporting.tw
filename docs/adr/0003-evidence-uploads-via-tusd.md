# 3. Evidence uploads through tusd straight into object storage

**Decision.** Media uploads use the tus protocol via `tusd` with its S3 store (MinIO). The API issues one signed
upload token per declared file; tusd's `pre-create` hook validates it and pins the object id; `post-finish`
re-hashes the object server-side and marks the evidence `verified` or `hash_mismatch`.

**Why.** Resumable uploads on mobile networks without pushing gigabytes through the API; the server-side
hash comparison with the SHA-256 computed at capture gives the chain of custody.

**Consequences.** The hook endpoint must be reachable only from tusd (nginx deny + NetworkPolicy).
The bucket is versioned so objects are never overwritten. Upstream `minio/minio` images are no longer
published; dev uses `chainguard/minio`, production should use the MinIO operator or a source build
(any S3-compatible store works).
