import 'geo.dart';
import 'json.dart';

enum CaseState { newCase, acknowledged, investigating, resolved, closed, merged }

CaseState caseStateOf(String s) => switch (s) {
  'new' => CaseState.newCase,
  'acknowledged' => CaseState.acknowledged,
  'investigating' => CaseState.investigating,
  'resolved' => CaseState.resolved,
  'closed' => CaseState.closed,
  _ => CaseState.merged,
};

extension CaseStateX on CaseState {
  String get wire => this == CaseState.newCase ? 'new' : name;
  bool get isOpen => this == CaseState.newCase || this == CaseState.acknowledged || this == CaseState.investigating;
}

class NamedRef {
  NamedRef({required this.id, required this.code, required this.name, required this.nameZh, this.kind});
  final int id;
  final String code;
  final String name;
  final String nameZh;
  final String? kind;

  static NamedRef? fromJson(Object? v) {
    final j = obj(v);
    if (j == null) return null;
    return NamedRef(
      id: toInt(j['id'])!,
      code: '${j['code']}',
      name: '${j['name']}',
      nameZh: '${j['name_zh']}',
      kind: j['kind'] as String?,
    );
  }

  String label(String lang) => lang.startsWith('zh') ? nameZh : name;
}

class Me {
  Me({
    required this.id,
    required this.username,
    required this.displayName,
    required this.roles,
    required this.clearance,
    required this.fieldUnit,
    required this.onDuty,
    this.desk,
    this.agency,
  });

  final String id;
  final String username;
  final String displayName;
  final Set<String> roles;
  final int clearance;
  final bool fieldUnit;
  final bool onDuty;
  final NamedRef? desk;
  final NamedRef? agency;

  bool has(String role) => roles.contains(role);
  bool get isDispatcher => has('dispatcher') || has('supervisor') || has('national');
  bool get isAnalyst => has('analyst') || has('supervisor') || has('national');
  bool get isAdmin => has('admin');

  factory Me.fromJson(Json j) => Me(
    id: '${j['id']}',
    username: '${j['username']}',
    displayName: '${j['display_name'] ?? ''}',
    roles: strings(j['roles']).toSet(),
    clearance: toInt(j['clearance']) ?? 0,
    fieldUnit: j['field_unit'] == true,
    onDuty: j['on_duty'] == true,
    desk: NamedRef.fromJson(j['desk']),
    agency: NamedRef.fromJson(j['agency']),
  );
}

class Desk {
  Desk({
    required this.id,
    required this.code,
    required this.name,
    required this.nameZh,
    required this.agencyId,
    required this.agencyCode,
    required this.clearance,
    required this.isCatchAll,
    required this.alwaysStaffed,
  });

  final int id;
  final String code, name, nameZh;
  final int agencyId;
  final String agencyCode;
  final int clearance;
  final bool isCatchAll, alwaysStaffed;

  String label(String lang) => lang.startsWith('zh') ? nameZh : name;

  factory Desk.fromJson(Json j) => Desk(
    id: toInt(j['id'])!,
    code: '${j['code']}',
    name: '${j['name']}',
    nameZh: '${j['name_zh']}',
    agencyId: toInt(j['agency_id'])!,
    agencyCode: '${j['agency_code']}',
    clearance: toInt(j['clearance']) ?? 0,
    isCatchAll: j['is_catch_all'] == true,
    alwaysStaffed: j['always_staffed'] == true,
  );
}

/// Queue row / live-update payload. When [redacted] only id, number, state, severity,
/// classification, agency/desk, time and position are present.
class CaseSummary {
  CaseSummary({
    required this.id,
    required this.caseNumber,
    required this.state,
    required this.severity,
    required this.classification,
    required this.agencyId,
    required this.deskId,
    required this.redacted,
    this.canAct = false,
    this.assigneeId,
    this.ackDeadline,
    this.createdAt,
    this.updatedAt,
    this.position,
    this.positionSource,
    this.estErrorM,
    this.estAltitudeM,
    this.firstSeen,
    this.lastSeen,
    this.observationCount = 0,
    this.distinctInformants = 0,
    this.confidence = 0,
    this.authorization = 'unknown',
    this.severityReasons = const [],
    this.sensorConfirmed = false,
    this.remoteIdSerials = const [],
    this.track = const [],
    this.operatorPosition,
    this.craftDomain = 'aerial',
    this.craftType,
    this.aiAssessment,
    this.vesselMatch,
    this.raw = const {},
  });

  final String id;
  final String caseNumber;
  final CaseState state;
  final int severity;
  final int classification;
  final int agencyId;
  final int deskId;
  final bool redacted;
  final bool canAct;
  final String? assigneeId;
  final DateTime? ackDeadline, createdAt, updatedAt, firstSeen, lastSeen;
  final LatLon? position;
  final String? positionSource;
  final double? estErrorM, estAltitudeM;
  final int observationCount, distinctInformants;
  final double confidence;
  final String authorization;
  final List<String> severityReasons;
  final bool sensorConfirmed;
  final List<String> remoteIdSerials;
  final List<LatLon> track;

  /// Remote ID operator position; only in field-app assignment rows.
  final LatLon? operatorPosition;

  /// aerial | surface | subsurface | shore | unknown
  final String craftDomain;
  final String? craftType;

  /// Advisory AI triage (highest-threat assessment of the incident's photos/frames).
  final Json? aiAssessment;

  /// Surface incidents: AIS vessel ({mmsi, name, ...}) or {dark: true}; may carry `mda_track`.
  final Json? vesselMatch;

  bool get isMaritime => craftDomain == 'surface' || craftDomain == 'subsurface' || craftDomain == 'shore';
  bool get isDarkVessel => vesselMatch?['dark'] == true;
  final Json raw;

  factory CaseSummary.fromJson(Json j) => CaseSummary(
    id: '${j['id']}',
    caseNumber: '${j['case_number']}',
    state: caseStateOf('${j['state']}'),
    severity: toInt(j['severity']) ?? 1,
    classification: toInt(j['classification']) ?? 0,
    agencyId: toInt(j['agency_id']) ?? 0,
    deskId: toInt(j['desk_id']) ?? 0,
    redacted: j['redacted'] == true,
    canAct: j['can_act'] == true,
    assigneeId: j['assignee_id'] as String?,
    ackDeadline: parseDate(j['ack_deadline']),
    createdAt: parseDate(j['created_at']),
    updatedAt: parseDate(j['updated_at']),
    position: LatLon.fromJson(j['position']),
    positionSource: j['position_source'] as String?,
    estErrorM: toDouble(j['est_error_m']),
    estAltitudeM: toDouble(j['est_altitude_m']),
    firstSeen: parseDate(j['first_seen']),
    lastSeen: parseDate(j['last_seen']),
    observationCount: toInt(j['observation_count']) ?? 0,
    distinctInformants: toInt(j['distinct_informants']) ?? 0,
    confidence: toDouble(j['confidence']) ?? 0,
    authorization: '${j['authorization'] ?? 'unknown'}',
    severityReasons: strings(j['severity_reasons']),
    sensorConfirmed: j['sensor_confirmed'] == true,
    remoteIdSerials: strings(j['remote_id_serials']),
    track: GeoJson.line(j['track']),
    operatorPosition: LatLon.fromJson(j['operator_position']),
    craftDomain: '${j['craft_domain'] ?? 'aerial'}',
    craftType: j['craft_type'] as String?,
    aiAssessment: obj(j['ai_assessment']),
    vesselMatch: obj(j['vessel_match']),
    raw: j,
  );

  /// Live events never carry the viewer-specific can_act flag; keep the one we had.
  CaseSummary withCanAct(bool v) => CaseSummary.fromJson({...raw, 'can_act': v});
}

class EvidenceInfo {
  EvidenceInfo({
    required this.id,
    required this.kind,
    required this.status,
    required this.sha256,
    required this.capturedAt,
    this.mimeType,
    this.sha256Verified,
    this.sizeBytes,
    this.uploadedAt,
    this.evidenceRequestId,
  });

  final String id, kind, status, sha256;
  final String? mimeType, sha256Verified, evidenceRequestId;
  final int? sizeBytes;
  final DateTime capturedAt;
  final DateTime? uploadedAt;

  factory EvidenceInfo.fromJson(Json j) => EvidenceInfo(
    id: '${j['id']}',
    kind: '${j['kind']}',
    status: '${j['status']}',
    sha256: '${j['sha256']}',
    mimeType: j['mime_type'] as String?,
    sha256Verified: j['sha256_verified'] as String?,
    sizeBytes: toInt(j['size_bytes']),
    capturedAt: parseDate(j['captured_at'])!,
    uploadedAt: parseDate(j['uploaded_at']),
    evidenceRequestId: j['evidence_request_id'] as String?,
  );
}

class ObservationView {
  ObservationView({
    required this.id,
    required this.sourceType,
    required this.observedAt,
    required this.evidence,
    this.sourceId,
    this.observerPosition,
    this.observerAccuracyM,
    this.dronePosition,
    this.bearingDeg,
    this.bearingAccuracyDeg,
    this.elevationDeg,
    this.bearingLine = const [],
    this.altitudeM,
    this.altitudeSource,
    this.remoteIdSerial,
    this.remoteId,
    this.operatorPosition,
    this.confidence = 0,
    this.spamScore = 0,
    this.fidelity,
    this.attestation,
    this.description,
    this.descriptionLang,
    this.descriptionTranslated,
    this.craftDomain = 'aerial',
    this.craftType,
    this.interview,
    this.aiAssessment,
  });

  final String id;
  final String sourceType;
  final String craftDomain;
  final String? craftType;

  /// {version, answers: {question id: option value}}
  final Json? interview;
  final Json? aiAssessment;
  final String? sourceId;
  final DateTime observedAt;
  final LatLon? observerPosition, dronePosition, operatorPosition;
  final double? observerAccuracyM, bearingDeg, bearingAccuracyDeg, elevationDeg, altitudeM;
  final List<LatLon> bearingLine;
  final String? altitudeSource, remoteIdSerial, fidelity, attestation, description, descriptionLang;
  final String? descriptionTranslated;
  final Json? remoteId;
  final double confidence, spamScore;
  final List<EvidenceInfo> evidence;

  bool get isInformant => sourceType.startsWith('informant');
  bool get isSensor =>
      sourceType == 'rf_sensor' ||
      sourceType == 'radar' ||
      sourceType == 'remote_id' ||
      sourceType == 'video_ai' ||
      sourceType == 'mda_sensor';

  factory ObservationView.fromJson(Json j) => ObservationView(
    id: '${j['id']}',
    sourceType: '${j['source_type']}',
    sourceId: j['source_id'] as String?,
    observedAt: parseDate(j['observed_at'])!,
    observerPosition: LatLon.fromJson(j['observer_position']),
    observerAccuracyM: toDouble(j['observer_accuracy_m']),
    dronePosition: LatLon.fromJson(j['drone_position']),
    bearingDeg: toDouble(j['bearing_deg']),
    bearingAccuracyDeg: toDouble(j['bearing_accuracy_deg']),
    elevationDeg: toDouble(j['elevation_deg']),
    bearingLine: GeoJson.line(j['bearing_line']),
    altitudeM: toDouble(j['altitude_m']),
    altitudeSource: j['altitude_source'] as String?,
    remoteIdSerial: j['remote_id_serial'] as String?,
    remoteId: obj(j['remote_id']),
    operatorPosition: LatLon.fromJson(j['operator_position']),
    confidence: toDouble(j['confidence']) ?? 0,
    spamScore: toDouble(j['spam_score']) ?? 0,
    fidelity: j['fidelity'] as String?,
    attestation: j['attestation'] as String?,
    description: j['description'] as String?,
    descriptionLang: j['description_lang'] as String?,
    descriptionTranslated: j['description_translated'] as String?,
    craftDomain: '${j['craft_domain'] ?? 'aerial'}',
    craftType: j['craft_type'] as String?,
    interview: obj(j['interview']),
    aiAssessment: obj(j['ai_assessment']),
    evidence: listOf(j['evidence'], EvidenceInfo.fromJson),
  );
}

class CaseEventView {
  CaseEventView({
    required this.id,
    required this.at,
    required this.actorType,
    required this.action,
    this.actorId,
    this.fromState,
    this.toState,
    this.fromDeskId,
    this.toDeskId,
    this.reason,
    this.data = const {},
  });

  final int id;
  final DateTime at;
  final String actorType, action;
  final String? actorId, fromState, toState, reason;
  final int? fromDeskId, toDeskId;
  final Json data;

  factory CaseEventView.fromJson(Json j) => CaseEventView(
    id: toInt(j['id'])!,
    at: parseDate(j['at'])!,
    actorType: '${j['actor_type']}',
    action: '${j['action']}',
    actorId: j['actor_id'] as String?,
    fromState: j['from_state'] as String?,
    toState: j['to_state'] as String?,
    fromDeskId: toInt(j['from_desk_id']),
    toDeskId: toInt(j['to_desk_id']),
    reason: j['reason'] as String?,
    data: obj(j['data']) ?? const {},
  );
}

class FieldOfficerRef {
  FieldOfficerRef({required this.id, required this.username, required this.displayName, this.lastPosition, this.at});
  final String id, username, displayName;
  final LatLon? lastPosition;
  final DateTime? at;

  factory FieldOfficerRef.fromJson(Json j) => FieldOfficerRef(
    id: '${j['id']}',
    username: '${j['username'] ?? ''}',
    displayName: '${j['display_name'] ?? j['username'] ?? ''}',
    lastPosition: LatLon.fromJson(j['last_position'] ?? j['position']),
    at: parseDate(j['last_position_at'] ?? j['at']),
  );
}

class IncidentInfo {
  IncidentInfo({
    required this.id,
    required this.zones,
    required this.adsbNearby,
    this.operatorPosition,
    this.weather,
    this.permit,
    this.registryMatch,
  });

  final String id;
  final List<Json> zones;
  final List<Json> adsbNearby;
  final LatLon? operatorPosition;
  final Json? weather, permit, registryMatch;

  factory IncidentInfo.fromJson(Json j) => IncidentInfo(
    id: '${j['id']}',
    zones: listOf(j['zones'], (z) => z),
    adsbNearby: listOf(j['adsb_nearby'], (a) => a),
    operatorPosition: LatLon.fromJson(j['operator_position']),
    weather: obj(j['weather']),
    permit: obj(j['permit']),
    registryMatch: obj(j['registry_match']),
  );
}

class CaseDetail {
  CaseDetail({
    required this.summary,
    required this.canAct,
    this.incident,
    this.observations = const [],
    this.events = const [],
    this.fieldOfficers = const [],
    this.evidenceRequests = const [],
    this.outcomeCode,
    this.outcomeNote,
    this.defenseNotes,
    this.routeChain = const [],
    this.routeIndex = 0,
    this.readAgencyIds = const [],
    this.mergedIntoId,
  });

  final CaseSummary summary;
  final bool canAct;
  final IncidentInfo? incident;
  final List<ObservationView> observations;
  final List<CaseEventView> events;
  final List<FieldOfficerRef> fieldOfficers;
  final List<Json> evidenceRequests;
  final String? outcomeCode, outcomeNote, defenseNotes, mergedIntoId;
  final List<int> routeChain;
  final int routeIndex;
  final List<int> readAgencyIds;

  bool get redacted => summary.redacted;

  factory CaseDetail.fromJson(Json j) => CaseDetail(
    summary: CaseSummary.fromJson(j),
    canAct: j['can_act'] == true,
    incident: obj(j['incident']) == null ? null : IncidentInfo.fromJson(obj(j['incident'])!),
    observations: listOf(j['observations'], ObservationView.fromJson),
    events: listOf(j['events'], CaseEventView.fromJson),
    fieldOfficers: listOf(j['field_officers'], FieldOfficerRef.fromJson),
    evidenceRequests: listOf(j['evidence_requests'], (e) => e),
    outcomeCode: j['outcome_code'] as String?,
    outcomeNote: j['outcome_note'] as String?,
    defenseNotes: j['defense_notes'] as String?,
    routeChain: (j['route_chain'] as List? ?? const []).map((e) => toInt(e)!).toList(),
    routeIndex: toInt(j['route_index']) ?? 0,
    readAgencyIds: (j['read_agency_ids'] as List? ?? const []).map((e) => toInt(e)!).toList(),
    mergedIntoId: j['merged_into_id'] as String?,
  );
}

class Template {
  Template({
    required this.code,
    required this.kind,
    required this.texts,
    required this.requestedKinds,
    required this.countsAsFalseReport,
  });

  final String code, kind;
  final Map<String, String> texts;
  final List<String> requestedKinds;
  final bool countsAsFalseReport;

  bool get isOutcome => kind == 'outcome';
  String text(String lang) => texts[lang] ?? texts['en'] ?? code;

  factory Template.fromJson(Json j) => Template(
    code: '${j['code']}',
    kind: '${j['kind']}',
    texts: (obj(j['texts']) ?? const {}).map((k, v) => MapEntry(k, '$v')),
    requestedKinds: strings(j['requested_kinds']),
    countsAsFalseReport: j['counts_as_false_report'] == true,
  );

  Json toJson() => {
    'code': code,
    'kind': kind,
    'texts': texts,
    'requested_kinds': requestedKinds,
    'counts_as_false_report': countsAsFalseReport,
  };
}

class Aircraft {
  Aircraft({required this.icao24, required this.position, this.callsign, this.altM, this.trackDeg, this.at});
  final String icao24;
  final String? callsign;
  final LatLon position;
  final double? altM, trackDeg;
  final DateTime? at;

  factory Aircraft.fromJson(Json j) => Aircraft(
    icao24: '${j['icao24']}',
    callsign: j['callsign'] as String?,
    position: LatLon.fromJson(j['position'])!,
    altM: toDouble(j['alt_m']),
    trackDeg: toDouble(j['track_deg']),
    at: parseDate(j['at']),
  );
}

/// Maritime picture: AIS vessels (identified by MMSI) and non-cooperative MDA sensor tracks.
class VesselContact {
  VesselContact({
    required this.sourceKind,
    required this.position,
    this.mmsi,
    this.trackId,
    this.name,
    this.shipType,
    this.role,
    this.roleConfidence,
    this.sogKn,
    this.cogDeg,
    this.at,
  });
  final String sourceKind; // ais | mda
  final LatLon position;
  final String? mmsi, trackId, name, role, roleConfidence;
  final int? shipType;
  final double? sogKn, cogDeg;
  final DateTime? at;

  bool get isAis => sourceKind == 'ais';
  String get label => name ?? mmsi ?? trackId ?? '?';

  factory VesselContact.fromJson(Json j) => VesselContact(
    sourceKind: '${j['source_kind']}',
    position: LatLon.fromJson(j['position'])!,
    mmsi: j['mmsi'] as String?,
    trackId: j['track_id'] as String?,
    name: j['name'] as String?,
    shipType: toInt(j['ship_type']),
    role: j['role'] as String?,
    roleConfidence: j['role_confidence'] as String?,
    sogKn: toDouble(j['sog_kn']),
    cogDeg: toDouble(j['cog_deg']),
    at: parseDate(j['at']),
  );
}

class VideoFeedInfo {
  VideoFeedInfo({
    required this.id,
    required this.name,
    required this.position,
    required this.domains,
    required this.active,
    this.owner,
    this.bearingDeg,
    this.fovDeg,
    this.lastSampledAt,
    this.lastError,
  });
  final String id, name;
  final String? owner, lastError;
  final LatLon position;
  final double? bearingDeg, fovDeg;
  final List<String> domains;
  final bool active;
  final DateTime? lastSampledAt;

  factory VideoFeedInfo.fromJson(Json j) => VideoFeedInfo(
    id: '${j['id']}',
    name: '${j['name']}',
    owner: j['owner'] as String?,
    position: LatLon.fromJson(j['position'])!,
    bearingDeg: toDouble(j['bearing_deg']),
    fovDeg: toDouble(j['fov_deg']),
    domains: strings(j['domains']),
    active: j['active'] == true,
    lastSampledAt: parseDate(j['last_sampled_at']),
    lastError: j['last_error'] as String?,
  );
}

class LiveMap {
  LiveMap({required this.cases, required this.aircraft, required this.fieldOfficers, this.vessels = const []});
  final List<CaseSummary> cases;
  final List<Aircraft> aircraft;
  final List<VesselContact> vessels;
  final List<FieldOfficerRef> fieldOfficers;

  factory LiveMap.fromJson(Json j) => LiveMap(
    cases: listOf(j['cases'], CaseSummary.fromJson),
    aircraft: listOf(j['aircraft'], Aircraft.fromJson),
    fieldOfficers: listOf(j['field_officers'], FieldOfficerRef.fromJson),
    vessels: listOf(j['vessels'], VesselContact.fromJson),
  );
}

class RosterEntry {
  RosterEntry({
    required this.id,
    required this.username,
    required this.displayName,
    required this.roles,
    required this.onDuty,
    required this.fieldUnit,
    this.deskId,
    this.lastPosition,
    this.lastPositionAt,
  });

  final String id, username, displayName;
  final List<String> roles;
  final bool onDuty, fieldUnit;
  final int? deskId;
  final LatLon? lastPosition;
  final DateTime? lastPositionAt;

  bool get isFieldOfficer => roles.contains('field_officer');

  factory RosterEntry.fromJson(Json j) => RosterEntry(
    id: '${j['id']}',
    username: '${j['username']}',
    displayName: '${j['display_name'] ?? ''}',
    roles: strings(j['roles']),
    onDuty: j['on_duty'] == true,
    fieldUnit: j['field_unit'] == true,
    deskId: toInt(j['desk_id']),
    lastPosition: LatLon.fromJson(j['last_position']),
    lastPositionAt: parseDate(j['last_position_at']),
  );
}

class RegistryLookup {
  RegistryLookup({required this.serial, required this.registered, this.entry, this.permits = const []});
  final String serial;
  final bool registered;
  final Json? entry;
  final List<Json> permits;

  factory RegistryLookup.fromJson(Json j) => RegistryLookup(
    serial: '${j['serial']}',
    registered: j['registered'] == true,
    entry: obj(j['entry']),
    permits: listOf(j['permits'], (p) => p),
  );
}

class CctvCamera {
  CctvCamera({required this.id, required this.name, required this.position, this.owner, this.distanceM});
  final String id, name;
  final String? owner;
  final LatLon position;
  final int? distanceM;

  factory CctvCamera.fromJson(Json j) => CctvCamera(
    id: '${j['id']}',
    name: '${j['name']}',
    owner: j['owner'] as String?,
    position: LatLon.fromJson(j['position'])!,
    distanceM: toInt(j['distance_m']),
  );
}

class AuditEntry {
  AuditEntry({
    required this.id,
    required this.at,
    required this.action,
    this.username,
    this.objectType,
    this.objectId,
    this.ip,
    this.details = const {},
  });
  final int id;
  final DateTime at;
  final String action;
  final String? username, objectType, objectId, ip;
  final Json details;

  factory AuditEntry.fromJson(Json j) => AuditEntry(
    id: toInt(j['id'])!,
    at: parseDate(j['at'])!,
    action: '${j['action']}',
    username: j['username'] as String?,
    objectType: j['object_type'] as String?,
    objectId: j['object_id'] as String?,
    ip: j['ip'] as String?,
    details: obj(j['details']) ?? const {},
  );
}

class StaffTokens {
  StaffTokens({required this.accessToken, required this.refreshToken, required this.expiresIn});
  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  factory StaffTokens.fromJson(Json j) => StaffTokens(
    accessToken: '${j['access_token']}',
    refreshToken: '${j['refresh_token']}',
    expiresIn: toInt(j['expires_in']) ?? 900,
  );
}

/// Staff account as managed by admins (console -> Admin -> Users).
class StaffAccount {
  StaffAccount({
    required this.id,
    required this.username,
    this.displayName = '',
    this.active = true,
    this.roles = const [],
    this.agencyId,
    this.deskId,
    this.clearance = 0,
    this.fieldUnit = false,
    this.language = 'zh-TW',
    this.locked = false,
    this.lastSeen,
    this.hasPassword = true,
  });

  final String id, username, displayName, language;
  final bool active, fieldUnit, locked, hasPassword;
  final List<String> roles;
  final int? agencyId, deskId;
  final int clearance;
  final DateTime? lastSeen;

  factory StaffAccount.fromJson(Json j) => StaffAccount(
    id: '${j['id']}',
    username: '${j['username']}',
    displayName: '${j['display_name'] ?? ''}',
    active: j['active'] != false,
    roles: strings(j['roles']),
    agencyId: toInt(j['agency_id']),
    deskId: toInt(j['desk_id']),
    clearance: toInt(j['clearance']) ?? 0,
    fieldUnit: j['field_unit'] == true,
    language: '${j['language'] ?? 'zh-TW'}',
    locked: j['locked'] == true,
    lastSeen: parseDate(j['last_seen']),
    hasPassword: j['has_password'] != false,
  );

  StaffAccount copyWith({
    String? username,
    String? displayName,
    List<String>? roles,
    int? deskId,
    bool clearDesk = false,
    int? clearance,
    bool? fieldUnit,
    String? language,
  }) => StaffAccount(
    id: id,
    username: username ?? this.username,
    displayName: displayName ?? this.displayName,
    active: active,
    roles: roles ?? this.roles,
    agencyId: agencyId,
    deskId: clearDesk ? null : (deskId ?? this.deskId),
    clearance: clearance ?? this.clearance,
    fieldUnit: fieldUnit ?? this.fieldUnit,
    language: language ?? this.language,
    locked: locked,
    lastSeen: lastSeen,
    hasPassword: hasPassword,
  );

  Json toEditJson() => {
    'display_name': displayName,
    'roles': roles,
    'agency_id': agencyId,
    'desk_id': deskId,
    'clearance': clearance,
    'field_unit': fieldUnit,
    'language': language,
  };
}

const staffRoles = ['dispatcher', 'supervisor', 'analyst', 'field_officer', 'admin', 'national'];

/// Suggested response for a case (decision support only); the operator accepts, rejects or modifies it.
class Recommendation {
  Recommendation({required this.id, required this.kind, required this.priority, required this.text,
      required this.reason, required this.status, this.finalText, this.note, this.decidedBy, this.decidedAt});
  final int id, priority;
  final String kind, text, reason, status;
  final String? finalText, note, decidedBy;
  final DateTime? decidedAt;

  bool get isOpen => status == 'proposed';
  String get shownText => finalText ?? text;

  factory Recommendation.fromJson(Json j) => Recommendation(
        id: toInt(j['id'])!,
        kind: '${j['kind']}',
        priority: toInt(j['priority']) ?? 9,
        text: '${j['text']}',
        reason: '${j['reason']}',
        status: '${j['status']}',
        finalText: j['final_text'] as String?,
        note: j['note'] as String?,
        decidedBy: j['decided_by'] as String?,
        decidedAt: parseDate(j['decided_at']),
      );
}
