import 'geo.dart';
import 'json.dart';

/// Why an alert was raised: one detector finding with its measured value and the threshold it crossed.
class AlertReason {
  AlertReason({required this.code, required this.text, this.value, this.threshold, this.at, this.position});
  final String code, text;
  final double? value, threshold;
  final DateTime? at;
  final LatLon? position;

  factory AlertReason.fromJson(Json j) => AlertReason(
    code: '${j['code']}',
    text: '${j['text']}',
    value: toDouble(j['value']),
    threshold: toDouble(j['threshold']),
    at: parseDate(j['at']),
    position: j['lat'] == null ? null : LatLon(toDouble(j['lat'])!, toDouble(j['lon'])!),
  );
}

/// Maritime behaviour alert on one vessel track, for human review.
class MaritimeAlert {
  MaritimeAlert({
    required this.id,
    required this.sourceId,
    required this.sourceKind,
    required this.trackId,
    required this.kinds,
    required this.method,
    required this.score,
    required this.ruleScore,
    required this.confidence,
    required this.reasons,
    required this.uncertainty,
    required this.status,
    required this.position,
    this.statScore,
    this.firstAt,
    this.lastAt,
    this.caseId,
    this.suppressUntil,
    this.updatedBy,
  });
  final int id, score, ruleScore;
  final String sourceId, sourceKind, trackId, method, status;
  final List<String> kinds, uncertainty;
  final double confidence;
  final double? statScore;
  final List<AlertReason> reasons;
  final LatLon position;
  final DateTime? firstAt, lastAt, suppressUntil;
  final String? caseId, updatedBy;

  bool get isOpen => status == 'open' || status == 'acknowledged';

  factory MaritimeAlert.fromJson(Json j) => MaritimeAlert(
    id: toInt(j['id'])!,
    sourceId: '${j['source_id']}',
    sourceKind: '${j['source_kind']}',
    trackId: '${j['track_id']}',
    kinds: strings(j['kinds']),
    method: '${j['method']}',
    score: toInt(j['score']) ?? 0,
    ruleScore: toInt(j['rule_score']) ?? 0,
    statScore: toDouble(j['stat_score']),
    confidence: toDouble(j['confidence']) ?? 1,
    reasons: listOf(j['reasons'], AlertReason.fromJson),
    uncertainty: strings(j['uncertainty']),
    status: '${j['status']}',
    position: LatLon.fromJson(j['position'])!,
    firstAt: parseDate(j['first_at']),
    lastAt: parseDate(j['last_at']),
    caseId: j['case_id'] as String?,
    suppressUntil: parseDate(j['suppress_until']),
    updatedBy: j['updated_by'] as String?,
  );
}

class AlertEvent {
  AlertEvent({required this.action, required this.detail, this.at, this.actor});
  final String action;
  final Json detail;
  final DateTime? at;
  final String? actor;

  factory AlertEvent.fromJson(Json j) => AlertEvent(
    action: '${j['action']}',
    detail: obj(j['detail']) ?? const {},
    at: parseDate(j['at']),
    actor: j['actor'] as String?,
  );
}

class MaritimeAlertDetail {
  MaritimeAlertDetail({
    required this.alert,
    required this.track,
    required this.events,
    required this.zones,
    this.vesselName,
    this.mmsi,
  });
  final MaritimeAlert alert;
  final List<({DateTime? t, LatLon p, double? sog})> track;
  final List<AlertEvent> events;
  final List<({String name, String nameZh, String zoneType, List<List<LatLon>> rings})> zones;
  final String? vesselName, mmsi;

  factory MaritimeAlertDetail.fromJson(Json j) {
    final v = obj(j['vessel']);
    return MaritimeAlertDetail(
      alert: MaritimeAlert.fromJson(j),
      track: [
        for (final p in (j['track'] as List? ?? const []))
          (
            t: parseDate((p as Map)['t']),
            p: LatLon(toDouble(p['lat'])!, toDouble(p['lon'])!),
            sog: toDouble(p['sog_kn']),
          ),
      ],
      events: listOf(j['events'], AlertEvent.fromJson),
      zones: [
        for (final z in (j['zones'] as List? ?? const []))
          (
            name: '${(z as Map)['name']}',
            nameZh: '${z['name_zh'] ?? z['name']}',
            zoneType: '${z['zone_type']}',
            rings: GeoJson.rings(z['geometry']),
          ),
      ],
      vesselName: v?['name'] as String?,
      mmsi: v?['mmsi'] as String?,
    );
  }
}

/// One adjustable detector threshold.
class AnomalySettingItem {
  AnomalySettingItem({
    required this.key,
    required this.value,
    required this.defaultValue,
    required this.min,
    required this.max,
    required this.unit,
    required this.labelEn,
    required this.labelZh,
  });
  final String key, unit, labelEn, labelZh;
  final double value, defaultValue, min, max;

  factory AnomalySettingItem.fromJson(Json j) => AnomalySettingItem(
    key: '${j['key']}',
    value: toDouble(j['value']) ?? 0,
    defaultValue: toDouble(j['default']) ?? 0,
    min: toDouble(j['min']) ?? 0,
    max: toDouble(j['max']) ?? 0,
    unit: '${j['unit'] ?? ''}',
    labelEn: '${j['label_en']}',
    labelZh: '${j['label_zh']}',
  );
}

class MethodResult {
  MethodResult({
    required this.precision,
    required this.recall,
    required this.f1,
    required this.falseAlarmsPer100,
    required this.tp,
    required this.fp,
    required this.fn,
    required this.byKind,
  });
  final double precision, recall, f1, falseAlarmsPer100;
  final int tp, fp, fn;
  final Map<String, ({int tracks, int found})> byKind;

  factory MethodResult.fromJson(Json j) => MethodResult(
    precision: toDouble(j['precision']) ?? 0,
    recall: toDouble(j['recall']) ?? 0,
    f1: toDouble(j['f1']) ?? 0,
    falseAlarmsPer100: toDouble(j['false_alarms_per_100_normal']) ?? 0,
    tp: toInt(j['tp']) ?? 0,
    fp: toInt(j['fp']) ?? 0,
    fn: toInt(j['fn']) ?? 0,
    byKind: {
      for (final e in (obj(j['by_kind']) ?? const {}).entries)
        e.key: (tracks: toInt((e.value as Map)['tracks']) ?? 0, found: toInt(e.value['found']) ?? 0),
    },
  );
}

/// Rules vs statistical baseline vs combined score on labelled (simulated) tracks.
class AnomalyEvaluation {
  AnomalyEvaluation({
    required this.id,
    required this.tracks,
    required this.anomalous,
    required this.results,
    this.createdAt,
  });
  final int id, tracks, anomalous;
  final Map<String, MethodResult> results;
  final DateTime? createdAt;

  factory AnomalyEvaluation.fromJson(Json j) => AnomalyEvaluation(
    id: toInt(j['id'])!,
    tracks: toInt(j['tracks']) ?? 0,
    anomalous: toInt(j['anomalous']) ?? 0,
    results: {for (final e in (obj(j['results']) ?? const {}).entries) e.key: MethodResult.fromJson(e.value as Json)},
    createdAt: parseDate(j['created_at']),
  );
}
