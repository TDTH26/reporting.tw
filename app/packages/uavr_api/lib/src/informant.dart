import 'geo.dart';
import 'json.dart';

enum MediaKind { photo, video, audio }

/// One decoded ASTM F3411 message set received by the phone (or a field device).
class RemoteIdMessage {
  RemoteIdMessage({
    required this.transport,
    required this.receivedAt,
    this.rssi,
    this.uasId,
    this.idType,
    this.uaType,
    this.lat,
    this.lon,
    this.altGeoM,
    this.altBaroM,
    this.heightM,
    this.speedMps,
    this.directionDeg,
    this.operatorLat,
    this.operatorLon,
    this.operatorId,
    this.selfIdText,
  });

  /// bt4 | bt5 | wifi_beacon | wifi_nan | network
  final String transport;
  final DateTime receivedAt;
  final int? rssi;
  final String? uasId;
  final String? idType;
  final String? uaType;
  final double? lat, lon, altGeoM, altBaroM, heightM, speedMps, directionDeg, operatorLat, operatorLon;
  final String? operatorId;
  final String? selfIdText;

  LatLon? get position => lat != null && lon != null ? LatLon(lat!, lon!) : null;
  LatLon? get operatorPosition =>
      operatorLat != null && operatorLon != null ? LatLon(operatorLat!, operatorLon!) : null;

  factory RemoteIdMessage.fromJson(Json j) => RemoteIdMessage(
    transport: '${j['transport']}',
    receivedAt: parseDate(j['received_at']) ?? DateTime.now().toUtc(),
    rssi: toInt(j['rssi']),
    uasId: j['uas_id'] as String?,
    idType: j['id_type'] as String?,
    uaType: j['ua_type'] as String?,
    lat: toDouble(j['lat']),
    lon: toDouble(j['lon']),
    altGeoM: toDouble(j['alt_geo_m']),
    altBaroM: toDouble(j['alt_baro_m']),
    heightM: toDouble(j['height_m']),
    speedMps: toDouble(j['speed_mps']),
    directionDeg: toDouble(j['direction_deg']),
    operatorLat: toDouble(j['operator_lat']),
    operatorLon: toDouble(j['operator_lon']),
    operatorId: j['operator_id'] as String?,
    selfIdText: j['self_id_text'] as String?,
  );

  Json toJson() => compact({
    'transport': transport,
    'received_at': receivedAt.toUtc().toIso8601String(),
    'rssi': rssi,
    'uas_id': uasId,
    'id_type': idType,
    'ua_type': uaType,
    'lat': lat,
    'lon': lon,
    'alt_geo_m': altGeoM,
    'alt_baro_m': altBaroM,
    'height_m': heightM,
    'speed_mps': speedMps,
    'direction_deg': directionDeg,
    'operator_lat': operatorLat,
    'operator_lon': operatorLon,
    'operator_id': operatorId,
    'self_id_text': selfIdText,
  });
}

class MediaDeclaration {
  MediaDeclaration({
    required this.slot,
    required this.kind,
    required this.mimeType,
    required this.sha256,
    required this.sizeBytes,
    required this.capturedAt,
  });

  final String slot;
  final MediaKind kind;
  final String mimeType;
  final String sha256;
  final int sizeBytes;
  final DateTime capturedAt;

  Json toJson() => {
    'slot': slot,
    'kind': kind.name,
    'mime_type': mimeType,
    'sha256': sha256,
    'size_bytes': sizeBytes,
    'captured_at': capturedAt.toUtc().toIso8601String(),
  };

  factory MediaDeclaration.fromJson(Json j) => MediaDeclaration(
    slot: j['slot'] as String,
    kind: MediaKind.values.byName(j['kind'] as String),
    mimeType: j['mime_type'] as String,
    sha256: j['sha256'] as String,
    sizeBytes: toInt(j['size_bytes'])!,
    capturedAt: parseDate(j['captured_at'])!,
  );
}

class ReportRequest {
  ReportRequest({
    required this.clientReportId,
    required this.platform,
    required this.appVersion,
    required this.language,
    required this.deviceId,
    required this.observedAt,
    required this.observer,
    this.observerAccuracyM,
    this.bearingDeg,
    this.bearingAccuracyDeg,
    this.elevationDeg,
    this.estAltitudeM,
    this.estDistanceM,
    this.compassCalibrated,
    this.droneCount,
    this.movement,
    this.remoteId = const [],
    this.remoteIdTransports = const [],
    this.media = const [],
    this.description,
    this.attestationToken,
    this.pushToken,
    this.tokenSecret,
    this.craftDomain,
    this.interviewVersion,
    this.interview,
  });

  final String clientReportId;
  final String platform; // android | web
  final String appVersion;
  final String language;
  final String deviceId;
  final DateTime observedAt;
  final LatLon observer;
  final double? observerAccuracyM;
  final double? bearingDeg, bearingAccuracyDeg, elevationDeg, estAltitudeM, estDistanceM;
  final bool? compassCalibrated;
  final int? droneCount;
  final String? movement; // hovering | moving | unknown
  final List<RemoteIdMessage> remoteId;
  final List<String> remoteIdTransports;
  final List<MediaDeclaration> media;
  final String? description;
  final String? attestationToken;
  final String? pushToken;
  final String? tokenSecret;

  /// aerial | surface | subsurface | shore | unknown; defaults server-side to the interview answer.
  final String? craftDomain;
  final String? interviewVersion;

  /// Structured interview answers: question id -> option value.
  final Map<String, String>? interview;

  /// Must match backend `request_hash` (uavr/api/informant.py): binds Play Integrity to this packet.
  String canonicalForHash() {
    final ms = observedAt.toUtc().millisecondsSinceEpoch;
    final hashes = (media.map((m) => m.sha256).toList()..sort()).join(',');
    return 'uavr-report-v1|$clientReportId|$ms|${observer.lat.toStringAsFixed(6)}|'
        '${observer.lon.toStringAsFixed(6)}|$hashes';
  }

  ReportRequest copyWith({String? attestationToken, String? pushToken}) => ReportRequest(
    clientReportId: clientReportId,
    platform: platform,
    appVersion: appVersion,
    language: language,
    deviceId: deviceId,
    observedAt: observedAt,
    observer: observer,
    observerAccuracyM: observerAccuracyM,
    bearingDeg: bearingDeg,
    bearingAccuracyDeg: bearingAccuracyDeg,
    elevationDeg: elevationDeg,
    estAltitudeM: estAltitudeM,
    estDistanceM: estDistanceM,
    compassCalibrated: compassCalibrated,
    droneCount: droneCount,
    movement: movement,
    remoteId: remoteId,
    remoteIdTransports: remoteIdTransports,
    media: media,
    description: description,
    attestationToken: attestationToken ?? this.attestationToken,
    pushToken: pushToken ?? this.pushToken,
    tokenSecret: tokenSecret,
    craftDomain: craftDomain,
    interviewVersion: interviewVersion,
    interview: interview,
  );

  Json toJson() => compact({
    'client_report_id': clientReportId,
    'platform': platform,
    'app_version': appVersion,
    'language': language,
    'device_id': deviceId,
    'observed_at': observedAt.toUtc().toIso8601String(),
    'observer': compact({'lat': observer.lat, 'lon': observer.lon, 'accuracy_m': observerAccuracyM}),
    'bearing_deg': bearingDeg,
    'bearing_accuracy_deg': bearingAccuracyDeg,
    'elevation_deg': elevationDeg,
    'est_altitude_m': estAltitudeM,
    'est_distance_m': estDistanceM,
    'compass_calibrated': compassCalibrated,
    'drone_count': droneCount,
    'movement': movement,
    'remote_id': remoteId.map((m) => m.toJson()).toList(),
    'remote_id_transports': remoteIdTransports,
    'media': media.map((m) => m.toJson()).toList(),
    'description': description,
    'attestation_token': attestationToken,
    'push_token': pushToken,
    'token_secret': tokenSecret,
    'craft_domain': craftDomain,
    'interview_version': interviewVersion,
    'interview': interview,
  });

  factory ReportRequest.fromJson(Json j) {
    final o = obj(j['observer'])!;
    return ReportRequest(
      clientReportId: j['client_report_id'] as String,
      platform: j['platform'] as String,
      appVersion: j['app_version'] as String,
      language: j['language'] as String,
      deviceId: j['device_id'] as String,
      observedAt: parseDate(j['observed_at'])!,
      observer: LatLon(toDouble(o['lat'])!, toDouble(o['lon'])!),
      observerAccuracyM: toDouble(o['accuracy_m']),
      bearingDeg: toDouble(j['bearing_deg']),
      bearingAccuracyDeg: toDouble(j['bearing_accuracy_deg']),
      elevationDeg: toDouble(j['elevation_deg']),
      estAltitudeM: toDouble(j['est_altitude_m']),
      estDistanceM: toDouble(j['est_distance_m']),
      compassCalibrated: j['compass_calibrated'] as bool?,
      droneCount: toInt(j['drone_count']),
      movement: j['movement'] as String?,
      remoteId: listOf(j['remote_id'], RemoteIdMessage.fromJson),
      remoteIdTransports: strings(j['remote_id_transports']),
      media: listOf(j['media'], MediaDeclaration.fromJson),
      description: j['description'] as String?,
      attestationToken: j['attestation_token'] as String?,
      pushToken: j['push_token'] as String?,
      tokenSecret: j['token_secret'] as String?,
      craftDomain: j['craft_domain'] as String?,
      interviewVersion: j['interview_version'] as String?,
      interview: (obj(j['interview']))?.map((k, v) => MapEntry(k, '$v')),
    );
  }
}

class UploadTicket {
  UploadTicket({required this.slot, required this.evidenceId, required this.uploadUrl, required this.uploadToken});
  final String slot;
  final String evidenceId;
  final String uploadUrl;
  final String uploadToken;

  factory UploadTicket.fromJson(Json j) => UploadTicket(
    slot: '${j['slot']}',
    evidenceId: '${j['evidence_id']}',
    uploadUrl: '${j['upload_url']}',
    uploadToken: '${j['upload_token']}',
  );

  Json toJson() => {'slot': slot, 'evidence_id': evidenceId, 'upload_url': uploadUrl, 'upload_token': uploadToken};
}

class ReportResponse {
  ReportResponse({
    required this.caseNumber,
    required this.token,
    required this.status,
    required this.fidelity,
    required this.uploads,
    required this.suggestAndroidApp,
  });

  final String caseNumber;
  final String token;
  final String status;
  final String fidelity;
  final List<UploadTicket> uploads;
  final bool suggestAndroidApp;

  factory ReportResponse.fromJson(Json j) => ReportResponse(
    caseNumber: j['case_number'] as String,
    token: j['token'] as String,
    status: j['status'] as String,
    fidelity: j['fidelity'] as String,
    uploads: listOf(j['uploads'], UploadTicket.fromJson),
    suggestAndroidApp: j['suggest_android_app'] == true,
  );
}

class EvidenceRequestItem {
  EvidenceRequestItem({
    required this.id,
    required this.templateCode,
    required this.text,
    required this.requestedKinds,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String templateCode;
  final String text;
  final List<String> requestedKinds;
  final String status;
  final DateTime createdAt;

  bool get isOpen => status == 'open';

  factory EvidenceRequestItem.fromJson(Json j) => EvidenceRequestItem(
    id: '${j['id']}',
    templateCode: '${j['template_code']}',
    text: '${j['text']}',
    requestedKinds: strings(j['requested_kinds']),
    status: '${j['status']}',
    createdAt: parseDate(j['created_at'])!,
  );
}

class TimelineEntry {
  TimelineEntry(this.status, this.at);
  final String status;
  final DateTime at;
}

/// What an anonymous informant sees about their case. Status values:
/// received, in_review, in_progress, completed.
class InformantCase {
  InformantCase({
    required this.caseNumber,
    required this.status,
    required this.updatedAt,
    required this.timeline,
    required this.evidenceRequests,
    this.outcomeCode,
    this.outcomeText,
  });

  final String caseNumber;
  final String status;
  final String? outcomeCode;
  final String? outcomeText;
  final DateTime updatedAt;
  final List<TimelineEntry> timeline;
  final List<EvidenceRequestItem> evidenceRequests;

  factory InformantCase.fromJson(Json j) => InformantCase(
    caseNumber: '${j['case_number']}',
    status: '${j['status']}',
    outcomeCode: j['outcome_code'] as String?,
    outcomeText: j['outcome_text'] as String?,
    updatedAt: parseDate(j['updated_at']) ?? DateTime.now(),
    timeline: listOf(j['timeline'], (t) => TimelineEntry('${t['status']}', parseDate(t['at'])!)),
    evidenceRequests: listOf(j['evidence_requests'], EvidenceRequestItem.fromJson),
  );
}

class PublicConfig {
  PublicConfig({required this.tusUrl, required this.languages, required this.minAndroidVersion});
  final String tusUrl;
  final List<String> languages;
  final String minAndroidVersion;

  factory PublicConfig.fromJson(Json j) => PublicConfig(
    tusUrl: '${j['tus_url']}',
    languages: strings(j['languages']),
    minAndroidVersion: '${j['min_android_version']}',
  );
}

/// Server-defined structured interview (GET /v1/public/interview), already in the user's language.
class Interview {
  Interview({required this.version, required this.questions});
  final String version;
  final List<InterviewQuestion> questions;

  /// Questions whose conditions hold for [answers], in order.
  List<InterviewQuestion> visible(Map<String, String> answers) => questions.where((q) => q.appliesTo(answers)).toList();

  /// Drops answers to questions that no longer apply (e.g. after changing the domain).
  Map<String, String> prune(Map<String, String> answers) {
    var out = Map<String, String>.of(answers);
    while (true) {
      final keep = {for (final q in visible(out)) q.id};
      final next = {
        for (final e in out.entries)
          if (keep.contains(e.key)) e.key: e.value,
      };
      if (next.length == out.length) return next;
      out = next;
    }
  }

  factory Interview.fromJson(Json j) =>
      Interview(version: '${j['version']}', questions: listOf(j['questions'], InterviewQuestion.fromJson));

  Json toJson() => {'version': version, 'questions': questions.map((q) => q.toJson()).toList()};
}

class InterviewQuestion {
  InterviewQuestion({required this.id, required this.label, required this.options, this.when = const {}});
  final String id;
  final String label;
  final List<({String value, String label})> options;
  final Map<String, List<String>> when;

  bool appliesTo(Map<String, String> answers) => when.entries.every((c) => c.value.contains(answers[c.key]));

  factory InterviewQuestion.fromJson(Json j) => InterviewQuestion(
    id: '${j['id']}',
    label: '${j['label']}',
    options: listOf(j['options'], (o) => (value: '${o['value']}', label: '${o['label']}')),
    when: (obj(j['when']) ?? const {}).map((k, v) => MapEntry(k, strings(v))),
  );

  Json toJson() => {
    'id': id,
    'label': label,
    'options': [
      for (final o in options) {'value': o.value, 'label': o.label},
    ],
    'when': when.isEmpty ? null : when,
  };
}
