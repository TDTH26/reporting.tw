import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:uavr_native/src/orientation_math.dart';
import 'package:uavr_native/uavr_native.dart';

/// Test-only ASTM F3411 encoder.
class Enc {
  final ByteData d = ByteData(25);
  Enc(int type, {int version = 2}) {
    d.setUint8(0, (type << 4) | version);
  }
  void u8(int o, int v) => d.setUint8(o, v);
  void i8(int o, int v) => d.setInt8(o, v);
  void u16(int o, int v) => d.setUint16(o, v, Endian.little);
  void i32(int o, int v) => d.setInt32(o, v, Endian.little);
  void u32(int o, int v) => d.setUint32(o, v, Endian.little);
  void deg(int o, double v) => i32(o, (v * 1e7).round());
  void alt(int o, double m) => u16(o, ((m + 1000) / 0.5).round());
  void ascii(int o, String s) {
    for (var i = 0; i < s.length; i++) {
      d.setUint8(o + i, s.codeUnitAt(i));
    }
  }

  Uint8List get bytes => d.buffer.asUint8List();
}

Uint8List basicId({int idType = 1, int uaType = 2, String id = '1581F5FKD229400B2S7V'}) =>
    (Enc(0x0)
          ..u8(1, (idType << 4) | uaType)
          ..ascii(2, id))
        .bytes;

Uint8List location({
  int status = 2,
  bool agl = false,
  int direction = 90,
  int speedRaw = 40,
  bool speedMult = false,
  int vSpeedRaw = 6,
  double lat = 25.0339639,
  double lon = 121.5644722,
  double baro = 120.5,
  double geo = 135.0,
  double height = 100.0,
  int ts = 12345,
}) {
  final ew = direction >= 180;
  return (Enc(0x1)
        ..u8(1, (status << 4) | (agl ? 4 : 0) | (ew ? 2 : 0) | (speedMult ? 1 : 0))
        ..u8(2, ew ? direction - 180 : direction)
        ..u8(3, speedRaw)
        ..i8(4, vSpeedRaw)
        ..deg(5, lat)
        ..deg(9, lon)
        ..alt(13, baro)
        ..alt(15, geo)
        ..alt(17, height)
        ..u8(19, (4 << 4) | 10)
        ..u8(20, (3 << 4) | 2)
        ..u16(21, ts)
        ..u8(23, 5))
      .bytes;
}

Uint8List auth({int page = 3}) => (Enc(0x2)..u8(1, (1 << 4) | page)).bytes;

Uint8List selfId(String text) =>
    (Enc(0x3)
          ..u8(1, 0)
          ..ascii(2, text))
        .bytes;

Uint8List system({double lat = 25.03, double lon = 121.56, int ts = 200000000}) =>
    (Enc(0x4)
          ..u8(1, (1 << 2) | 1)
          ..deg(2, lat)
          ..deg(6, lon)
          ..u16(10, 3)
          ..u8(12, 15)
          ..alt(13, 300)
          ..alt(15, 0)
          ..u8(17, (1 << 4) | 2)
          ..alt(18, 20)
          ..u32(20, ts))
        .bytes;

Uint8List operatorId(String id) =>
    (Enc(0x5)
          ..u8(1, 0)
          ..ascii(2, id))
        .bytes;

Uint8List pack(List<Uint8List> msgs, {int size = 25, int? count}) {
  final b = BytesBuilder()..add([0xF2, size, count ?? msgs.length]);
  for (final m in msgs) {
    b.add(m);
  }
  return b.toBytes();
}

RemoteIdFrame frame(
  Uint8List payload, {
  String addr = 'AA:BB:CC:DD:EE:FF',
  DateTime? at,
  int? rssi = -70,
}) => RemoteIdFrame(
  transport: 'bt4',
  sourceAddress: addr,
  rssi: rssi,
  receivedAt: at ?? DateTime.utc(2026, 10, 2, 8),
  payload: payload,
);

void main() {
  group('decodeAstm', () {
    test('basic ID', () {
      final m = decodeAstm(basicId()).single as BasicIdMessage;
      expect(m.protocolVersion, 2);
      expect(m.idTypeName, 'serial');
      expect(m.uaTypeName, 'helicopter_or_multirotor');
      expect(m.uasId, '1581F5FKD229400B2S7V');
    });

    test('basic ID types and NUL padding', () {
      final m = decodeAstm(basicId(idType: 2, uaType: 15, id: 'TW-123')).single as BasicIdMessage;
      expect(m.idTypeName, 'caa_registration');
      expect(m.uaTypeName, 'other');
      expect(m.uasId, 'TW-123');
      expect((decodeAstm(basicId(idType: 9)).single as BasicIdMessage).idTypeName, isNull);
    });

    test('location / vector', () {
      final m = decodeAstm(location()).single as LocationMessage;
      expect(m.statusName, 'airborne');
      expect(m.heightType, 0);
      expect(m.directionDeg, 90);
      expect(m.speedMps, 10.0);
      expect(m.verticalSpeedMps, 3.0);
      expect(m.lat, closeTo(25.0339639, 1e-7));
      expect(m.lon, closeTo(121.5644722, 1e-7));
      expect(m.altBaroM, 120.5);
      expect(m.altGeoM, 135.0);
      expect(m.heightM, 100.0);
      expect(m.verticalAccuracy, 4);
      expect(m.horizontalAccuracy, 10);
      expect(m.baroAccuracy, 3);
      expect(m.speedAccuracy, 2);
      expect(m.timestampTenths, 12345);
      expect(m.timestampSeconds, 1234.5);
      expect(m.timestampAccuracyS, closeTo(0.5, 1e-9));
    });

    test('location E/W bit, speed multiplier, negative values, AGL', () {
      final m =
          decodeAstm(
                location(
                  direction: 270,
                  speedRaw: 100,
                  speedMult: true,
                  vSpeedRaw: -10,
                  lat: -33.8688197,
                  lon: -151.2092955,
                  geo: -50.5,
                  agl: true,
                  status: 3,
                ),
              ).single
              as LocationMessage;
      expect(m.directionDeg, 270);
      expect(m.speedMps, 100 * 0.75 + 63.75);
      expect(m.verticalSpeedMps, -5.0);
      expect(m.lat, closeTo(-33.8688197, 1e-7));
      expect(m.lon, closeTo(-151.2092955, 1e-7));
      expect(m.altGeoM, -50.5);
      expect(m.heightType, 1);
      expect(m.statusName, 'emergency');
    });

    test('location unknown sentinels', () {
      final b = location(direction: 361, speedRaw: 255, vSpeedRaw: 126, lat: 0, lon: 0, ts: 0xFFFF);
      b.buffer.asByteData()
        ..setUint16(13, 0, Endian.little)
        ..setUint16(15, 0, Endian.little)
        ..setUint16(17, 0, Endian.little)
        ..setUint8(23, 0);
      final m = decodeAstm(b).single as LocationMessage;
      expect(m.directionDeg, isNull);
      expect(m.speedMps, isNull);
      expect(m.verticalSpeedMps, isNull);
      expect(m.lat, isNull);
      expect(m.lon, isNull);
      expect(m.altBaroM, isNull);
      expect(m.altGeoM, isNull);
      expect(m.heightM, isNull);
      expect(m.timestampTenths, isNull);
      expect(m.timestampAccuracyS, isNull);
    });

    test('authentication page is recorded', () {
      final m = decodeAstm(auth(page: 3)).single as AuthMessage;
      expect(m.authType, 1);
      expect(m.pageNumber, 3);
    });

    test('self ID uses all 23 text bytes', () {
      final m = decodeAstm(selfId('Bridge inspection 2026X')).single as SelfIdMessage;
      expect(m.text, 'Bridge inspection 2026X');
    });

    test('system', () {
      final m = decodeAstm(system()).single as SystemMessage;
      expect(m.operatorLocationType, 1);
      expect(m.classificationType, 1);
      expect(m.operatorLat, closeTo(25.03, 1e-7));
      expect(m.operatorLon, closeTo(121.56, 1e-7));
      expect(m.areaCount, 3);
      expect(m.areaRadiusM, 150);
      expect(m.areaCeilingM, 300);
      expect(m.areaFloorM, 0);
      expect(m.uaCategory, 1);
      expect(m.uaClass, 2);
      expect(m.operatorAltGeoM, 20);
      expect(m.timestamp, DateTime.utc(2019).add(const Duration(seconds: 200000000)));
    });

    test('operator ID', () {
      final m = decodeAstm(operatorId('TWN-OP-0042')).single as OperatorIdMessage;
      expect(m.operatorId, 'TWN-OP-0042');
    });

    test('message pack', () {
      final msgs = decodeAstm(pack([basicId(), location(), system(), operatorId('OP1')]));
      expect(msgs.map((m) => m.runtimeType).toList(), [
        BasicIdMessage,
        LocationMessage,
        SystemMessage,
        OperatorIdMessage,
      ]);
    });

    test('malformed input does not throw', () {
      expect(decodeAstm(Uint8List(0)), isEmpty);
      expect(decodeAstm(Uint8List.sublistView(basicId(), 0, 10)), isEmpty);
      expect(decodeAstm((Enc(0x7)..u8(1, 1)).bytes), isEmpty); // reserved type
      expect(decodeAstm(pack([basicId()], size: 24)), isEmpty);
      expect(decodeAstm(pack(List.filled(10, basicId()))), isEmpty); // > 9 messages
      // Pack claims 3 messages but the last is truncated: the first two decode.
      final truncated = pack([basicId(), location(), system()]);
      expect(decodeAstm(Uint8List.sublistView(truncated, 0, truncated.length - 5)), hasLength(2));
      // Unknown and nested-pack entries inside a pack are skipped.
      final nested = Uint8List(25)..[0] = 0xF2;
      expect(
        decodeAstm(pack([(Enc(0x9)).bytes, nested, location()])).single,
        isA<LocationMessage>(),
      );
    });
  });

  group('RemoteIdDrone', () {
    test('merges frames and serializes for the API', () {
      final t0 = DateTime.utc(2026, 10, 2, 8);
      var d = RemoteIdDrone.fromFrame(frame(basicId(), at: t0));
      d = d.merge(
        frame(
          pack([location(), system(lat: 25.1, lon: 121.6)]),
          at: t0.add(const Duration(seconds: 1)),
          rssi: -60,
        ),
      );
      d = d.merge(frame(selfId('Survey'), rssi: null));
      d = d.merge(frame(operatorId('OP-7')));
      d = d.merge(frame(auth()));

      expect(d.uasId, '1581F5FKD229400B2S7V');
      expect(d.idType, 'serial');
      expect(d.uaType, 'helicopter_or_multirotor');
      expect(d.status, 'airborne');
      expect(d.lastSeen, t0.add(const Duration(seconds: 1))); // never goes backwards

      final json = d.toApiJson();
      expect(json.keys.toSet(), {
        'transport',
        'received_at',
        'rssi',
        'uas_id',
        'id_type',
        'ua_type',
        'lat',
        'lon',
        'alt_geo_m',
        'alt_baro_m',
        'height_m',
        'speed_mps',
        'direction_deg',
        'operator_lat',
        'operator_lon',
        'operator_id',
        'self_id_text',
      });
      expect(json['transport'], 'bt4');
      expect(json['received_at'], '2026-10-02T08:00:01.000Z');
      expect(json['rssi'], -70);
      expect(json['lat'], closeTo(25.0339639, 1e-7));
      expect(json['alt_geo_m'], 135.0);
      expect(json['operator_lat'], closeTo(25.1, 1e-7));
      expect(json['operator_id'], 'OP-7');
      expect(json['self_id_text'], 'Survey');
    });

    test('omits nulls and keeps a serial over a session ID', () {
      var d = RemoteIdDrone.fromFrame(frame(basicId(), rssi: null));
      d = d.merge(frame(basicId(idType: 4, id: 'SESSION1')));
      expect(d.uasId, '1581F5FKD229400B2S7V');
      final json = RemoteIdDrone.fromFrame(frame(basicId(), rssi: null)).toApiJson();
      expect(json.keys.toSet(), {'transport', 'received_at', 'uas_id', 'id_type', 'ua_type'});
    });

    test('sameStateAs ignores rssi and time', () {
      final a = RemoteIdDrone.fromFrame(frame(location()));
      final b = a.merge(frame(location(), rssi: -40, at: DateTime.utc(2026, 10, 2, 9)));
      expect(a.sameStateAs(b), isTrue);
      expect(a.sameStateAs(a.merge(frame(location(lat: 25.1)))), isFalse);
    });
  });

  test('RemoteIdTracker drops drones after 30 s', () {
    var now = DateTime.utc(2026, 10, 2, 8);
    final tracker = RemoteIdTracker(clock: () => now);
    tracker.add(frame(basicId(), addr: 'A', at: now));
    now = now.add(const Duration(seconds: 20));
    tracker.add(frame(basicId(), addr: 'B', at: now));
    expect(tracker.drones.keys, unorderedEquals(['A', 'B']));
    now = now.add(const Duration(seconds: 15)); // A is 35 s old, B 15 s
    expect(tracker.drones.keys, ['B']);
    tracker.add(frame(location(), addr: 'B', at: now));
    now = now.add(const Duration(seconds: 29));
    expect(tracker.drones['B']?.lat, closeTo(25.0339639, 1e-7));
    now = now.add(const Duration(seconds: 2));
    expect(tracker.drones, isEmpty);
  });

  group('web camera axis', () {
    double az(({double x, double y, double z}) w) => (math.atan2(w.x, w.y) * degPerRad + 360) % 360;
    double el(({double x, double y, double z}) w) => math.asin(w.z) * degPerRad;

    test('flat face up points down', () {
      expect(el(cameraAxis(0, 0, 0)), closeTo(-90, 1e-9));
    });

    test('upright portrait: heading is 360 - alpha', () {
      expect(az(cameraAxis(0, 90, 0)), closeTo(0, 1e-9));
      expect(az(cameraAxis(90, 90, 0)), closeTo(270, 1e-9));
      expect(az(cameraAxis(270, 90, 0)), closeTo(90, 1e-9));
      expect(el(cameraAxis(0, 90, 0)), closeTo(0, 1e-9));
    });

    test('tilted back 30 degrees looks 30 degrees up', () {
      expect(el(cameraAxis(0, 120, 0)), closeTo(30, 1e-9));
      expect(az(cameraAxis(0, 120, 0)), closeTo(0, 1e-9));
    });
  });
}
