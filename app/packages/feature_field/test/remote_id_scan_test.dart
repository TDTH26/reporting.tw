import 'package:feature_field/src/screens/remote_id_scan_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uavr_native/uavr_native.dart';

import 'assignments_test.dart' show settle;
import 'helpers.dart';

void main() {
  testWidgets('attaching a scanned drone posts a field observation with Remote ID, drone and observer position',
      (t) async {
    final server = FakeServer((r) async {
      if (r.method == 'POST' && r.url.path == '/api/v1/field/cases/case-1/observations') {
        return jsonResponse({'observation_id': 'o1', 'uploads': []}, 201);
      }
      return jsonResponse({'detail': 'nope'}, 404);
    });
    final deps = TestDeps(server);
    await t.pumpWidget(deps.wrap(const RemoteIdScanScreen(caseId: 'case-1', caseNumber: 'TPE-20261002-0007')));
    await settle(t);

    // Capability chips.
    expect(find.text('Bluetooth 5 long range'), findsOneWidget);
    expect(find.text('Wi-Fi NAN'), findsOneWidget);

    deps.sensors.drones.add(RemoteIdDrone(
      sourceAddress: 'AA:BB:CC:DD:EE:FF',
      transport: 'bt5',
      lastSeen: DateTime.now().toUtc(),
      rssi: -71,
      uasId: '1581F5FKD229400B',
      idType: 'serial',
      uaType: 'helicopter_or_multirotor',
      lat: 25.0400,
      lon: 121.5730,
      altGeoM: 140,
      heightM: 85,
      speedMps: 4.5,
      directionDeg: 270,
      operatorLat: 25.0390,
      operatorLon: 121.5700,
      operatorId: 'TWN-OP-1234',
    ));
    await settle(t);

    expect(find.text('1581F5FKD229400B'), findsOneWidget);
    expect(find.text('Serial number'), findsOneWidget);
    expect(find.text('-71 dBm'), findsOneWidget);

    final attach = find.text('Attach to case');
    await t.scrollUntilVisible(attach, 200, scrollable: find.byType(Scrollable).first);
    await t.ensureVisible(attach);
    await t.pump();
    await t.tap(attach);
    await settle(t);

    final posts = server.calls.where((c) => c.method == 'POST').toList();
    expect(posts, hasLength(1));
    expect(posts.single.path, '/api/v1/field/cases/case-1/observations');
    final body = posts.single.body as Map<String, dynamic>;
    expect(body['client_report_id'], isA<String>());
    expect(body['observer'], {'lat': myPosition.lat, 'lon': myPosition.lon, 'accuracy_m': 6.0});
    expect(body['drone_position'], {'lat': 25.04, 'lon': 121.573, 'alt_m': 85.0});
    final rid = (body['remote_id'] as List).single as Map<String, dynamic>;
    expect(rid['uas_id'], '1581F5FKD229400B');
    expect(rid['id_type'], 'serial');
    expect(rid['transport'], 'bt5');
    expect(rid['operator_lat'], 25.039);
    expect(rid['height_m'], 85.0);
    expect(rid['received_at'], isA<String>());
    expect(body['media'], isEmpty);
    expect(find.text('Sent to the case.'), findsOneWidget);
    expect(deps.outboxStore.saved, isEmpty);

    await t.pumpWidget(const SizedBox());
  });

  testWidgets('a permission stream error shows the permission message', (t) async {
    final deps = TestDeps(FakeServer((r) async => jsonResponse({})));
    await t.pumpWidget(deps.wrap(const RemoteIdScanScreen(caseId: 'case-1', caseNumber: 'X')));
    await settle(t);
    deps.sensors.drones.addError(PlatformException(code: 'permission', message: 'BLUETOOTH_SCAN'));
    await settle(t);
    expect(find.textContaining('Nearby devices'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('no Remote ID hardware is explained', (t) async {
    final deps = TestDeps(FakeServer((r) async => jsonResponse({})));
    deps.sensors.caps = RemoteIdCapabilities.none;
    await t.pumpWidget(deps.wrap(const RemoteIdScanScreen(caseId: 'case-1', caseNumber: 'X')));
    await settle(t);
    expect(find.textContaining('cannot receive Remote ID'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await t.pumpWidget(const SizedBox());
  });
}
