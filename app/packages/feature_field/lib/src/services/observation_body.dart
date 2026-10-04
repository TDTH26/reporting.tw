import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_capture/uavr_capture.dart';
import 'package:uavr_native/uavr_native.dart';
import 'package:uuid/uuid.dart';

import 'sensors.dart';
import '../json_util.dart';

/// JSON body matching the backend's FieldObservationIn.
Json fieldObservationBody({
  required GpsFix observer,
  DateTime? observedAt,
  double? bearingDeg,
  double? elevationDeg,
  Json? dronePosition,
  List<RemoteIdMessage> remoteId = const [],
  List<CapturedMedia> media = const [],
  String? note,
  String? clientReportId,
}) {
  final n = note?.trim();
  // Server bounds: 0 <= bearing < 360, -10 <= elevation <= 90.
  final b = bearingDeg == null || (bearingDeg >= 0 && bearingDeg < 360) ? bearingDeg : bearingDeg % 360;
  final e = elevationDeg == null || elevationDeg < -10 || elevationDeg > 90 ? null : elevationDeg;
  return compact({
    'client_report_id': clientReportId ?? const Uuid().v4(),
    'observed_at': (observedAt ?? DateTime.now()).toUtc().toIso8601String(),
    'observer': observer.toObserverJson(),
    'bearing_deg': b == null || b >= 360 ? null : b,
    'elevation_deg': e,
    'drone_position': dronePosition,
    'remote_id': [for (final m in remoteId) m.toJson()],
    'media': [for (final m in media) m.toDeclaration().toJson()],
    'note': n == null || n.isEmpty ? null : n,
  });
}

/// The API message for a drone heard on scene (validated through the shared model).
RemoteIdMessage remoteIdMessageOf(RemoteIdDrone d) => RemoteIdMessage.fromJson(d.toApiJson());

/// `drone_position` from the drone's own Location message, if it sent one.
Json? dronePositionOf(RemoteIdDrone d) => d.lat == null || d.lon == null
    ? null
    : compact({'lat': d.lat, 'lon': d.lon, 'alt_m': d.heightM ?? d.altGeoM});
