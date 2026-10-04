import 'json.dart';

/// A message on the live WebSocket channel (/v1/ws).
class LiveMessage {
  LiveMessage({required this.type, this.seq, this.kind, this.at, this.payload = const {}});

  /// hello | event | resync_required | pong
  final String type;
  final int? seq;

  /// case.created, case.updated, case.severity, case.rerouted, case.realert, case.transferred,
  /// case.acknowledged, case.resolved, case.closed, case.merged, case.evidence, case.field_assigned,
  /// zones.changed
  final String? kind;
  final DateTime? at;
  final Json payload;

  bool get isAlert =>
      const {'case.created', 'case.severity', 'case.rerouted', 'case.realert', 'case.transferred'}.contains(kind);

  factory LiveMessage.fromJson(Json j) => LiveMessage(
    type: '${j['type']}',
    seq: toInt(j['seq']),
    kind: j['kind'] as String?,
    at: parseDate(j['at']),
    payload: obj(j['payload']) ?? const {},
  );
}
