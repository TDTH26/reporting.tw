# UAV Sighting Reporting System — Design Document

Oct 2, 2026 · @Thomas K

## Overview

The system lets anyone in Taiwan report an illegal or suspicious drone, unmanned surface vessel (USV) or other questionable craft in the air, at sea or on the coast in minutes, and routes each report to the right agency automatically. It adapts the model of Taiwan's police violation reporting portals: the informant submits evidence with time and location, receives a case number, and later sees the outcome.

It differs from those portals in three ways. Informants may stay anonymous. Reports are fused with sensor, registry and aircraft data into a single picture of each drone event. Cases are routed across several agencies (police, Civil Aviation Administration and defense), not one.

The system has three Flutter clients (public Android and web app, agency web console, field officer Android app) and an on-premise Python backend built to absorb further data sources into its analytics.

## Key decisions

Every decision below was made during the design Q\&A; later sections explain the consequences.

| Area | Decision |
| --- | --- |
| What is reported | Public sightings of illegal or suspicious UAVs, USVs and other questionable aerial, maritime or coastal craft |
| Receiving agencies | Multi-agency routing: police, CAA, Coast Guard, defense |
| Informant identity | Anonymous allowed |
| Evidence | Photo/video, GPS + compass bearing + estimated altitude, rotor audio, Remote ID / OpenDroneID scan |
| Routing | Automatic, with dispatcher override |
| Response target | Near real-time (minutes) |
| External data | CAA registry and permits, ADS-B, AIS and MDA sensor tracks, RF/radar sensors, weather, CCTV, agency live video feeds, city data |
| Hosting | Government cloud / on-premise in Taiwan |
| Analytics users | Agency dashboards and hotspot maps |
| Clients | Flutter: public Android + web, agency web console, field officer Android |
| Informant feedback | Status + templated final outcome; templated evidence requests only |
| Scope | Full system from day one, nationwide launch |
| Defense cases | Same console, role-restricted |
| Languages | Traditional Chinese, English, Vietnamese, Indonesian, Thai, Filipino |
| First pickup | Each agency's own dispatch desk |
| Unacknowledged cases | Re-routed to a backup agency |
| Severity | 3 levels; auto upgrade, downgrade by dispatcher |
| Staff login | Username + password |
| Retention | Everything kept indefinitely |
| Public visibility | Nothing public |
| APIs | REST + WebSocket |
| Backend language | Python |
| External feeds | Own JSON schema; vendors must deliver in it |
| Report intake | Structured interview (server-defined, versioned, six languages) branching by craft domain |
| AI triage | Open-weight vision model (Qwen3-VL-30B-A3B) via Featherless; advisory, may only raise severity |
| Video feeds | Agency camera frames sampled periodically for AI detection; detections become low-confidence observations |

## Reporting flow and evidence capture

A report reaches a dispatcher within seconds because metadata travels first and media follows separately.

1. The informant opens the app and taps Report. The app records GPS position, time and device attestation (Play Integrity) immediately.
2. The informant points the phone at the drone. Compass heading gives a bearing line; phone tilt gives an elevation angle for estimating altitude.
3. In parallel, the app scans for Remote ID broadcasts via OpenDroneID and starts optional photo, video and audio capture.
4. A small metadata packet (position, bearing, elevation, Remote ID data, timestamps, file hashes) is sent at once. This triggers fusion, routing and the dispatcher alert.
5. Media uploads afterwards through resumable uploads (tus), continuing in the background via workmanager if the app closes.
6. The informant receives a case number and a secret token.

Evidence capture details:

- **OpenDroneID:** a native Kotlin plugin wrapping the open-source OpenDroneID receiver library. The app detects which transports the phone supports (Bluetooth 4 legacy, Bluetooth 5 Long Range, Wi-Fi Beacon, Wi-Fi NAN) and tells the user. Whether Taiwan currently mandates Remote ID for the relevant drone classes needs confirming with the CAA.
- **Bearing and triangulation:** each report is a bearing line; two or more independent lines let the backend estimate the drone's real position.
- **Audio:** rotor recordings are stored from day one to train a future classifier for drone type and false-report detection.
- **Integrity:** files are hashed (SHA-256) on the device at capture, timestamped and stored unmodified, giving a chain of custody for prosecution.
- **Web reporting:** browsers cannot scan Remote ID and have unreliable compass data, so web reports are tagged lower-fidelity and the UI suggests the Android app for live sightings.

## Anonymity, feedback and evidence requests

Informants stay anonymous; credibility comes from corroboration and abuse controls, not identity.

- **Case token:** each report returns a case number plus a secret token. The token, stored hashed on the server, lets the informant check status and answer evidence requests without an account.
- **Abuse controls:** device attestation, rate limiting per device and network, and spam scoring. Independent corroborating reports raise an incident's confidence; isolated reports from flagged devices lower it.
- **Status and outcome:** informants see each status change and a final outcome chosen by the dispatcher from fixed templates, for example Authorized flight, Operator identified and penalty issued, Unable to locate, or Referred to another agency. Defense cases always show the generic outcome Handled by the relevant authority.
- **Evidence requests:** dispatchers can only send templated requests, such as asking for a video or another photo of the flight direction. No template ever asks a informant to approach or follow an operator.
- **Notifications:** push via an FCM token linked to the case, never to a person. Notifications carry no case details, only a prompt to open the app.
- **Translation:** because outcomes and requests are templated, they are pre-translated into all six supported languages.

## Data sources and sensor fusion

Every input becomes an Observation; the fusion engine groups observations into Incidents (one drone event); each incident becomes a Case routed to an agency.

| Source | Role in the system | Confidence weight |
| --- | --- | --- |
| Public report (Android) | Bearing line, Remote ID, media | Medium; rises with corroboration |
| Public report (web) | Location and media only | Low |
| Remote ID / OpenDroneID | Serial number, drone and operator position | High when present |
| RF / radar sensors | Continuous machine-generated tracks | High |
| CAA registry and permits | Matches serial to owner; marks authorized flights | Lookup, not an observation |
| ADS-B | Manned aircraft positions for proximity checks | Lookup, drives escalation |
| Weather | Visibility and wind, to weigh sighting reliability | Context |
| CCTV and city data | Dispatcher verification | Context |

Fusion rules:

- Observations close in space and time are clustered into one incident. A surge of hundreds of reports about one drone appears to dispatchers as one incident.
- Two or more bearing lines are triangulated into an estimated position; sensor tracks and Remote ID positions override estimates.
- A Remote ID serial with a valid permit for that zone and time marks the incident Likely authorized.
- ADS-B proximity to manned aircraft escalates the incident to Critical.
- Concurrent reports about the same drone are serialized with a row lock on the incident, so a surge never creates duplicate incidents.

All external feeds must arrive in the platform's own versioned JSON schema. Vendors are contractually required to deliver it, so the schema and its conformance tests must be ready before procurement. Feeds from government partners (such as ADS-B or CAA data) are not vendors and may still need a translator owned by one side.

## Routing, severity and escalation&#32;

Cases route automatically by zone to an agency desk, re-route to a backup if not acknowledged in time, and only humans can lower severity.

&#91;embedded content: case lifecycle · 5 states, 2 side paths\]

Every transition is written as a CaseEvent. Incidents found to be the same drone are merged, keeping one surviving case.

**Routing.** Each Zone (geofence) defines its primary agency desk and a backup chain. Zone polygons for non-public sensitive sites exist only on the server; the informant app shows only published CAA zones. Dispatchers can override routing by transferring a case.

**Severity.**

| Level | Example triggers | Suggested ack timeout |
| --- | --- | --- |
| Critical | Near manned aircraft (ADS-B) or an airport approach; military or critical infrastructure zone; Kinmen/Matsu restricted areas; sensor-confirmed track in a red zone | 2 min |
| Medium | Restricted or yellow zone without a matching permit; no Remote ID in controlled airspace; hovering over residences | 10 min |
| Low | Open area; registry match with valid permit; single unverified web report | 60 min |

Severity is recalculated as observations arrive. An upgrade re-alerts the assigned dispatcher and restarts the acknowledgement timer at the new, shorter timeout. A downgrade requires a dispatcher and records who and why.

**Escalation.**

- Routing checks a desk's on-duty roster first, so cases are not sent to unstaffed desks.
- An unacknowledged case moves to the next desk in the zone's backup chain; the original agency is notified and keeps read access.
- Every chain ends at a 24-hour national catch-all desk, such as the National Police Agency command center.
- Classified cases escalate only to cleared desks; any other backup receives a redacted case (location, time, severity).

## Client applications

One Flutter monorepo (managed with Melos) produces three separate builds that share code but never ship each other's screens.

| Build | Platforms | Distribution | Main features |
| --- | --- | --- | --- |
| Informant app (`main_informant.dart`) | Android, web | Public Play Store, public website | Report flow, OpenDroneID scan (Android), case status by token, evidence requests |
| Agency console (`main_agency.dart`) | Web | Government network only | Desk queues, case actions, live map, CCTV and registry lookups, dashboards |
| Field app (`main_field.dart`) | Android | Agency MDM / managed Google Play | Assigned cases, live drone track, operator position, on-scene Remote ID scan, officer evidence capture, offline cache |

Shared packages:

- Generated Dart API client (from the OpenAPI spec) and data models.
- Map widgets on flutter\_map with a self-hosted tile server (OpenStreetMap or NLSC basemaps), plus zone overlays.
- Evidence capture module (camera, audio, hashing, resumable upload), reused by the informant and field apps.
- OpenDroneID native plugin (Kotlin, platform channels).
- Design system and localization: ARB files in Traditional Chinese, English, Vietnamese, Indonesian, Thai and Filipino, with bundled Noto fonts.

Defense case details appear in the field app only for defense field units; all other field users see the redacted view.

## Backend architecture

The backend runs entirely on self-hostable components in government cloud or on-premise data centers in Taiwan, with PostgreSQL as the single hub: the API services read and write it directly, with no message bus.

&#91;embedded content: backend architecture · inputs to cases\]

All inputs enter through validated APIs; fusion turns them into incidents in PostgreSQL, and the case service drives the console and field app.

| Layer | Technology | Purpose |
| --- | --- | --- |
| API services | Python, FastAPI, Pydantic | Public reporting, agency, ingestion and analytics APIs; OpenAPI spec generated from code |
| Live updates | WebSocket (FastAPI) | Console queues, severity changes, live tracks; sequence numbers for resync; PostgreSQL LISTEN/NOTIFY to reach every API instance |
| Background worker | Python process, same codebase | Ack timeouts, re-routing to backup desks, scheduled jobs |
| Fusion engine | Python module called by the API, PostGIS queries, NumPy, Shapely | Clustering, triangulation, registry and ADS-B checks, severity |
| Database | PostgreSQL + PostGIS (GeoAlchemy2) | Incidents, cases, zones, users, analytics tables |
| Media storage | MinIO | Photos, video, audio; resumable uploads via tus |
| Identity | Keycloak | Agency users, roles, clearance attributes |
| Translation | Self-hosted machine translation | Free-text descriptions for dispatchers |
| Maps | Self-hosted tile server | Base maps for all clients |
| Platform | Kubernetes | Deployment and scaling |

The fusion engine is a separate module with a narrow interface, so it can move into its own service later if load ever requires it.

## Data model and APIs

Nine core entities carry the Observation, Incident, Case chain plus the organization and lookup data around it.

| Entity | Purpose | Key fields |
| --- | --- | --- |
| Observation | One input from any source | source type, source ID, timestamp, position or bearing line, altitude, confidence, raw payload (JSONB), schema\_version |
| Evidence | Media attached to an observation | SHA-256 hash, media type, MinIO URI, capture time, attestation result |
| Incident | One fused drone event | fused track (PostGIS linestring), severity, matched zones, registry/permit match, linked observations |
| Case | Incident assigned to an agency | incident ID, agency, desk, state, assignee, outcome template, classification label |
| CaseEvent | Append-only audit trail | case ID, actor, action, reason, timestamp |
| InformantToken | Anonymous follow-up | hashed secret, linked cases, push token, pending evidence requests |
| Zone | Geofence and routing rules | polygon, zone type, classification, backup chain, timeouts per severity |
| Agency / Desk / User / Role | Organization and access | roster, on-duty status, clearance attributes |
| AircraftTrack | Manned traffic from ADS-B | ICAO address, track, timestamp |

Observations keep both a normalized core and the source's raw payload, so stored data can be re-processed when fusion improves. CaseEvent is never edited, only appended; it serves as both audit log and source of response-time metrics.

API groups (REST, described in one OpenAPI spec):

- **Public API:** submit observation metadata, resumable media upload, status by token, respond to evidence requests.
- **Agency API:** desk queues, case actions (acknowledge, transfer, merge, downgrade, resolve), registry and CCTV lookups, plus a WebSocket channel for live updates.
- **Ingestion API:** authenticated endpoints per external source, validated against the JSON schema, written to PostgreSQL.
- **Analytics API:** aggregate queries for dashboards and hotspot maps.

## Security and accepted risks

Access is controlled by agency, role and clearance on every request, and two higher-risk choices are recorded here as accepted risks.

Access control:

- Attribute-based checks combine role, agency and clearance with each case's classification label.
- Field-level restriction hides sensitive fields (sensor positions, defense notes) from uncleared users, who see only a redacted case.
- Defense case data can be encrypted with keys held by the defense agency.
- Every view, export, registry lookup and CCTV access is written to an audit log.
- Lost field devices are wiped remotely through MDM.

Accepted risks:

| Decision | Risk | Mitigation kept available |
| --- | --- | --- |
| Staff log in with username and password only | One phished or reused password can expose defense data; security reviews under the Information Security Management Act (資通安全管理法) may reject it | Keycloak can enable TOTP or FIDO2 per role without code changes |
| AI triage on Featherless (outside Taiwan) | Photos from the public (bystanders' faces, plates) and agency camera frames are processed by a foreign provider; conflicts with the on-premise hosting decision; possible PDPA / Information Security Management Act issues. Featherless states that API prompts, completions and images are not logged or stored, but does not say where they are processed | The client is OpenAI-compatible: the same open-weight model can be self-hosted in Taiwan by changing the base URL; AI can be switched off per deployment (`UAVR_AI_ENABLED=false`) |
| All data kept indefinitely | Raw media holds bystanders' faces, plates and voices plus owner identities; may conflict with the Personal Data Protection Act's purpose limits; a future breach exposes all history | Storage is split into an analytics tier and an evidence tier, so a retention rule can be added to the evidence tier later |

The shared console for defense cases should be reviewed by the defense side's information security officers early, before build.

## Analytics and dashboards

Analytics serves agency staff only, through dashboards and hotspot maps in the agency console; nothing is published.

- **Hotspot maps:** incident heatmaps by zone, time of day and day of week, built on PostGIS.
- **Repeat offenders:** incidents grouped by Remote ID serial and by registered owner.
- **Response performance:** time to acknowledge, time to resolve, and re-route rates per agency and desk, computed from CaseEvent.
- **Source quality:** share of incidents confirmed by sensors, false-report rates by source type, Remote ID coverage.
- **Authorized versus unauthorized:** share of incidents matched to valid permits, by zone.

New data sources join analytics through the same path as live data: an ingestion endpoint, the JSON schema, and PostgreSQL. No changes to the core services are needed.

## Maritime scope, AI triage and video feeds (added Oct 3, 2026)

The system covers maritime and coastal craft as well as drones: unmanned surface vessels, small boats, unexplained subsurface contacts and craft landing on beaches.

- **Craft domain.** Every observation and incident has a domain: aerial, surface, subsurface or shore. Aerial and maritime contacts are never fused into one incident. Maritime contacts use a wider clustering radius and a longer time window, because boats are slow and visible from far away.
- **Structured interview.** The app guides the observer through questions served by the backend (versioned, pre-translated into all six languages). The first question is where the craft is; later questions depend on the answer (craft type, crew visible, size, heading, distance offshore, what was seen ashore). Answers set the craft type and feed the severity rules. Photo/video prompts and automatic GPS stay as before.
- **Zones and routing.** Zones declare which domains they apply to, so airport rules never apply to boats. New zone types are territorial sea, harbour, restricted waters and coastal defense; maritime cases route to the Coast Guard (CGA) desks, with defense desks for restricted waters.
- **Maritime severity.** Critical: a subsurface contact, people unloading ashore, a USV in protected waters or approaching the shore, a dark vessel in protected waters, or an unidentified craft in restricted waters. Medium: any USV, a dark vessel in the territorial sea, or an unidentified craft in protected waters. Ordinary traffic in busy waters (e.g. Kinmen fishing fleets) is not escalated just for being there.
- **AIS and MDA tracks.** AIS positions identify vessels by MMSI. A surface contact with AIS coverage nearby but no transmitter is flagged as a dark vessel. Non-cooperative MDA sensor tracks (no identity, role mobile_asset / fixed_site / ambiguous) are kept as part of the maritime picture and attached to nearby contacts, but they never count as identification.
- **AI triage.** Verified photos and sampled camera frames are assessed asynchronously by Qwen3-VL-30B-A3B-Instruct via Featherless (OpenAI-compatible API). The assessment covers silhouette, craft type, unmanned likelihood, threat level, consistency with the report and spam likelihood. The output is untrusted: it is schema-validated, and instructions inside images are ignored. The AI may only raise severity, by at most one level, and to Critical only with corroboration (two or more independent informants, or a non-public source such as a sensor, camera or field officer). It never lowers severity or closes a case. A shared queue keeps model calls within the provider's concurrency budget, retries busy/rate-limited calls with backoff, and serves public evidence before video frames.
- **Video feeds.** Agencies register cameras (position, viewing direction, field of view, snapshot or stream URL). The worker samples frames on each feed's interval (skipping unchanged frames and backing off when the AI queue is busy) and stores each frame as hashed evidence. Detections at confidence 0.5 or above become observations with a bearing derived from the camera direction.

## Rollout, operations and open questions

The full system launches nationwide, with each external adapter built and tested against simulated data and switched on when its agreement or hardware arrives.

Operational requirements:

- Coverage includes Taiwan, Penghu, Kinmen and Matsu; Kinmen and Matsu get the strictest severity rules.
- Every receiving agency staffs its desk 24/7, or relies on the backup chain to the national catch-all desk.
- Load tests cover genuine report surges (hundreds of reports in minutes) and spam floods disguised as surges.
- A public awareness campaign in all six languages accompanies launch.

Open questions:

- [ ] Data-sharing agreement with the CAA for registry and permit lookups
- [ ] Source of the ADS-B feed and who translates it into the platform schema
- [ ] Current Remote ID requirements in Taiwan for the relevant drone classes
- [ ] Defense information security approval for the shared console
- [ ] Which agency hosts and operates the national catch-all desk
- [ ] Legal review of indefinite retention and password-only login
- [ ] Final ack timeouts per severity, agreed with each agency
- [ ] Legal/security sign-off for sending media to Featherless, and its data-processing location
- [ ] AIS source (CGA / commercial / satellite) and agreement for MDA sensor data
- [ ] Coast Guard and MND zone polygons (territorial sea, restricted waters, protected coastline)
- [ ] Which agencies provide camera feeds, and the GPU or provider capacity for frame analysis
