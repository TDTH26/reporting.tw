import 'dart:math' as math;

import 'package:uavr_api/uavr_api.dart';

/// Initial great-circle bearing from [from] to [to], degrees clockwise from true north, 0..360.
double initialBearing(LatLon from, LatLon to) {
  const rad = math.pi / 180;
  final p1 = from.lat * rad, p2 = to.lat * rad;
  final dl = (to.lon - from.lon) * rad;
  final y = math.sin(dl) * math.cos(p2);
  final x = math.cos(p1) * math.sin(p2) - math.sin(p1) * math.cos(p2) * math.cos(dl);
  final deg = math.atan2(y, x) / rad;
  return (deg + 360) % 360;
}

/// Distance (m) and bearing (deg) from [from] to [to].
({double distanceM, double bearingDeg}) rangeAndBearing(LatLon from, LatLon to) =>
    (distanceM: from.distanceTo(to), bearingDeg: initialBearing(from, to));

/// Index into the eight compass points N, NE, E, SE, S, SW, W, NW.
int compassIndex(double bearingDeg) => (((bearingDeg % 360) + 360) % 360 / 45).round() % 8;

/// "85 m", "1.24 km", "12.3 km".
String formatDistance(double m) {
  if (m < 1000) return '${m.round()} m';
  if (m < 10000) return '${(m / 1000).toStringAsFixed(2)} km';
  return '${(m / 1000).toStringAsFixed(1)} km';
}

/// "235°".
String formatBearing(double deg) => '${(((deg % 360) + 360) % 360).round() % 360}°';
