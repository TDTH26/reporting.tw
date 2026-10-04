import 'geo.dart';
import 'json.dart';

/// Atreides maritime sensor (MDA) export as received.
class AtreidesBatch {
  AtreidesBatch({
    required this.id,
    required this.filename,
    required this.accepted,
    required this.dropped,
    required this.tracks,
    required this.receivedVia,
    this.firstAt,
    this.lastAt,
    this.createdAt,
    this.shiftedS = 0,
  });
  final int id, accepted, dropped, tracks, shiftedS;
  final String filename, receivedVia;
  final DateTime? firstAt, lastAt, createdAt;

  factory AtreidesBatch.fromJson(Json j) => AtreidesBatch(
    id: toInt(j['id'])!,
    filename: '${j['filename']}',
    accepted: toInt(j['accepted']) ?? 0,
    dropped: toInt(j['dropped']) ?? 0,
    tracks: toInt(j['tracks']) ?? 0,
    receivedVia: '${j['received_via']}',
    firstAt: parseDate(j['first_at']),
    lastAt: parseDate(j['last_at']),
    createdAt: parseDate(j['created_at']),
    shiftedS: toInt(j['shifted_s']) ?? 0,
  );
}

class AtreidesSummary {
  AtreidesSummary({
    required this.detections,
    required this.tracks,
    required this.routes,
    required this.singleContacts,
    required this.byRole,
    required this.byConfidence,
    this.firstAt,
    this.lastAt,
    this.southWest,
    this.northEast,
  });
  final int detections, tracks, routes, singleContacts;
  final Map<String, int> byRole, byConfidence;
  final DateTime? firstAt, lastAt;
  final LatLon? southWest, northEast;

  factory AtreidesSummary.fromJson(Json j) {
    final b = obj(j['bbox']);
    Map<String, int> counts(Object? v) => {for (final e in (obj(v) ?? const {}).entries) e.key: toInt(e.value) ?? 0};
    return AtreidesSummary(
      detections: toInt(j['detections']) ?? 0,
      tracks: toInt(j['tracks']) ?? 0,
      routes: toInt(j['routes']) ?? 0,
      singleContacts: toInt(j['single_contacts']) ?? 0,
      byRole: counts(j['by_role']),
      byConfidence: counts(j['by_confidence']),
      firstAt: parseDate(j['first_at']),
      lastAt: parseDate(j['last_at']),
      southWest: b == null ? null : LatLon(toDouble(b['min_lat'])!, toDouble(b['min_lon'])!),
      northEast: b == null ? null : LatLon(toDouble(b['max_lat'])!, toDouble(b['max_lon'])!),
    );
  }
}

/// A reconstructed route (several detections) or a single-point contact.
class AtreidesTrack {
  AtreidesTrack({
    required this.trackId,
    required this.role,
    required this.points,
    required this.last,
    required this.path,
    this.confidence,
    this.reasoning,
    this.sourceRole,
    this.sourceConfidence,
    this.sourceReasoning,
    this.spanKm,
    this.firstAt,
    this.lastAt,
  });
  final String trackId, role;
  final int points;
  final LatLon last;
  final List<LatLon> path;
  final String? confidence, reasoning, sourceRole, sourceConfidence, sourceReasoning;
  final double? spanKm;
  final DateTime? firstAt, lastAt;

  bool get isRoute => points > 1;

  factory AtreidesTrack.fromJson(Json j) => AtreidesTrack(
    trackId: '${j['track_id']}',
    role: '${j['role']}',
    points: toInt(j['points']) ?? 1,
    last: LatLon.fromJson(j['last'])!,
    path: [for (final p in (j['path'] as List? ?? const [])) LatLon(toDouble((p as List)[0])!, toDouble(p[1])!)],
    confidence: j['confidence'] as String?,
    reasoning: j['reasoning'] as String?,
    sourceRole: j['source_role'] as String?,
    sourceConfidence: j['source_confidence'] as String?,
    sourceReasoning: j['source_reasoning'] as String?,
    spanKm: toDouble(j['span_km']),
    firstAt: parseDate(j['first_at']),
    lastAt: parseDate(j['last_at']),
  );
}
