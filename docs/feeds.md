# External feed integration guide (v1)

All external data enters through one authenticated endpoint per feed and must conform to the
platform's versioned JSON Schemas in [`schemas/feeds/v1/`](../schemas/feeds/v1). Sensor vendors are
contractually required to deliver in this format; government partners (CAA, ADS-B provider, CWA weather)
may run a small translator on either side.

| Feed | Endpoint | Schema | Who | Cadence |
| --- | --- | --- | --- | --- |
| RF / radar tracks | `POST /v1/ingest/sensor-track` | `sensor-track.json` | Sensor vendors | ≤ 5 s per live track |
| Remote ID receivers | `POST /v1/ingest/remote-id` | `remote-id.json` | Fixed receivers / network RID | ≤ 5 s |
| ADS-B | `POST /v1/ingest/adsb` | `adsb.json` | ANSP / receiver network | 1–5 s |
| AIS + MDA tracks | `POST /v1/ingest/ais` | `ais.json` | CGA / AIS provider / MDA sensor network | 10–60 s |
| Agency video feeds | `POST /v1/ingest/video-feed` | `video-feed.json` | Agencies operating cameras | on change |
| Weather | `POST /v1/ingest/weather` | `weather.json` | CWA | 10 min |
| CAA registry | `POST /v1/ingest/registry` | `registry.json` | CAA | delta sync, hourly |
| CAA permits | `POST /v1/ingest/permit` | `permit.json` | CAA | on change |
| CCTV directory | `POST /v1/ingest/cctv` | `cctv.json` | Cities / police | daily |

## Authentication
Each feed system gets its own key (`X-Feed-Key` header), created by a platform admin in the console
(Admin → Feed clients) and shown once. A key is limited to the feeds it was issued for and carries a
classification label: data from a key labelled *restricted* or *defense* is only visible to cleared staff.
Production deployments additionally require mutual TLS at the ingress.

## Envelope
Every payload has the same envelope:

```json
{ "schema": "uavr.feed.sensor-track/1", "source_id": "vendor-a-taoyuan", "sent_at": "2026-10-02T08:00:05Z", "tracks": [ ... ] }
```

* `schema` pins the feed and major version. Breaking changes ship as `/2` alongside `/1`.
* Times are RFC 3339 UTC. Positions are WGS84 decimal degrees. Altitudes are metres (`alt_ref` says which datum).
* Unknown properties are rejected (`additionalProperties: false`) so typos surface during conformance testing.

## Responses
* `200 {"accepted": true, ...}` — stored; counts of what was created are included.
* `422` — schema violation. `detail.errors` lists JSON pointers and messages (first 50).
* `401` / `403` — unknown key / key not allowed for this feed.

## Conformance kit
Run before connecting, and in the vendor's CI:

```sh
cd backend
uv run python -m uavr.feeds.conformance sensor-track my-sample-1.json my-sample-2.json
uv run python -m uavr.feeds.conformance --all-examples   # bundled valid/invalid examples
```

Exit code 0 means every payload conforms. The same validator runs on the live endpoint.

## What the platform does with each feed
* **sensor-track / remote-id** become Observations, fused into Incidents (clustering, track continuity per
  `track_id`, Remote ID serial linking). Sensor and Remote ID positions override triangulation from public reports.
  Updates of one track are throttled to one stored observation per 5 s.
* **adsb** is stored as manned-traffic context; any active incident within 5 km / 600 m of a fresh aircraft
  position is re-evaluated and escalates to Critical.
* **registry / permit** are lookups: a Remote ID serial with a valid permit covering the position, time and
  altitude marks the incident *Likely authorized*; permit changes re-check live incidents.
* **ais** entries with an `mmsi` are cooperative AIS and identify a nearby surface contact; entries with only a
  `track_id` (`source_kind: mda`) are non-cooperative sensor tracks shown in the maritime picture but never treated
  as identification. A surface contact with AIS coverage but no transmitter nearby is a *dark vessel*.
  `tools/importers/mda_csv.py` converts MDA sensor CSV exports (e.g. the April 2026 sample) into this feed.
* **video-feed** registers cameras; the platform samples `snapshot_url` (or `stream_url` via ffmpeg) every
  `sample_interval_s` for AI detection and stores each analysed frame as evidence.
* `sensor-track` items may set `classification.target_domain: surface` (coastal radar) and `target_type: usv`.
* **weather** lowers the weight of public sightings in poor visibility.
* **cctv** is shown to dispatchers near an incident; every stream access is audited.
