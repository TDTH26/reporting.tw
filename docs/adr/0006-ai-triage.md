# 6. AI triage: advisory, raise-only, queued

**Decision.** Photos and sampled camera frames are assessed by Qwen3-VL-30B-A3B-Instruct on Featherless
(`uavr/ai/`). Calls run only in the worker, through an `ai_job` table. Jobs are claimed under an advisory lock
so that every worker replica together stays within the plan's concurrency budget (the model costs 2 of 4 units,
so `UAVR_AI_MAX_CONCURRENT=2`). A 429 or 503 response re-queues the job with exponential backoff, at most 6 attempts.
Public and field evidence has priority 3; video frames have priority 8, and sampling pauses while 4 frame jobs wait.

**Safety.** The model output is untrusted. It is parsed into strict Pydantic schemas, unknown craft types are
dropped, text is clipped, and the prompt says to ignore instructions inside images. Its threat level can only
*raise* severity: at most one level above the rule-based result, and to Critical only when the incident is
corroborated (two or more independent informants, or a sensor/field/camera source). It never lowers severity
or closes cases; spam likelihood is shown to dispatchers but changes nothing.

**Measured.** Benchmark in `~/featherless/bench`: median latency 48 s for this model, with intermittent 503s.
A live end-to-end run through the worker took 6.4 s and correctly identified an MQ-9-class fixed-wing UAV.

**Accepted risk.** Media leaves Taiwan (see the design doc's accepted-risk table). The client is
OpenAI-compatible, so self-hosting the same model only needs `UAVR_AI_BASE_URL` changed.
