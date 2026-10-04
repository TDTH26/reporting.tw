import 'package:feature_field/feature_field.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uavr_api/uavr_api.dart';

void main() {
  group('initialBearing', () {
    test('cardinal directions', () {
      const o = LatLon(0, 0);
      expect(initialBearing(o, const LatLon(1, 0)), closeTo(0, 1e-9));
      expect(initialBearing(o, const LatLon(0, 1)), closeTo(90, 1e-9));
      expect(initialBearing(o, const LatLon(-1, 0)), closeTo(180, 1e-9));
      expect(initialBearing(o, const LatLon(0, -1)), closeTo(270, 1e-9));
    });

    test('Taipei 101 to Taipei Main Station is west-north-west', () {
      const t101 = LatLon(25.0339, 121.5645);
      const station = LatLon(25.0478, 121.5170);
      final rb = rangeAndBearing(t101, station);
      expect(rb.distanceM, closeTo(5040, 60)); // ~5.0 km
      expect(rb.bearingDeg, closeTo(287.9, 0.1));
      expect(compassIndex(rb.bearingDeg), 6); // W
    });

    test('always within [0, 360)', () {
      final b = initialBearing(const LatLon(25, 121.5), const LatLon(25.0001, 121.4999));
      expect(b, inInclusiveRange(0, 360));
      expect(b, closeTo(317.8, 0.5));
    });

    test('round trip with LatLon.destination', () {
      const from = LatLon(24.15, 120.67); // Taichung
      for (final bearing in [10.0, 95.0, 200.0, 300.0]) {
        final to = from.destination(bearing, 2000);
        final rb = rangeAndBearing(from, to);
        expect(rb.distanceM, closeTo(2000, 5));
        expect(rb.bearingDeg, closeTo(bearing, 0.2));
      }
    });
  });

  test('compassIndex wraps', () {
    expect(compassIndex(0), 0);
    expect(compassIndex(22.4), 0);
    expect(compassIndex(22.6), 1);
    expect(compassIndex(359), 0);
    expect(compassIndex(-45), 7);
    expect(compassIndex(180), 4);
  });

  test('formatting', () {
    expect(formatDistance(84.6), '85 m');
    expect(formatDistance(1240), '1.24 km');
    expect(formatDistance(12345), '12.3 km');
    expect(formatBearing(359.7), '0°');
    expect(formatBearing(-10), '350°');
    expect(formatBearing(47.6), '48°');
  });

  test('one degree of latitude is ~111.2 km', () {
    expect(const LatLon(23, 121).distanceTo(const LatLon(24, 121)), closeTo(111195, 10));
  });
}
