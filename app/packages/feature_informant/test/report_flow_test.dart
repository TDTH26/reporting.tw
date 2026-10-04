import 'package:feature_informant/feature_informant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_core/uavr_core.dart';
import 'package:uavr_native/uavr_native.dart';

import 'fakes.dart';

const caseNumber = 'UAV-20261002-0042';

Map<String, dynamic> reportResponse(List<String> slots) => {
      'case_number': caseNumber,
      'token': '3f0c8f5e-1111-4222-8333-444455556666.secret',
      'status': 'received',
      'fidelity': 'high',
      'uploads': [
        for (final s in slots)
          {
            'slot': s,
            'evidence_id': '00000000-0000-4000-8000-00000000000${slots.indexOf(s)}',
            'upload_url': 'http://test/files/',
            'upload_token': 'tok-$s',
          },
      ],
      'suggest_android_app': false,
    };

Future<void> settle(WidgetTester tester, [int frames = 10]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> tapInList(WidgetTester tester, Finder f) async {
  await tester.scrollUntilVisible(f, 100, scrollable: find.byType(Scrollable).last);
  await tester.tap(f);
  await tester.pump();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'uavr.informant.onboarded': true, 'uavr.informant.locale': 'en'});
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('full report flow posts the metadata packet and shows the case number', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final sensors = FakeSensors();
    final uploads = FakeUploads();
    final backend = FakeBackend((r) async {
      if (r.method == 'POST' && r.url.path.endsWith('/v1/reports')) {
        return jsonResponse(reportResponse(['aim1', 'photo1']), 201);
      }
      return jsonResponse([]);
    });

    await tester.pumpWidget(ProviderScope(
      overrides: overridesFor(backend: backend, sensors: sensors, uploads: uploads),
      child: const InformantApp(),
    ));
    await settle(tester);

    expect(find.text('My reports'), findsOneWidget);
    await tester.tap(find.text('Report a sighting'));
    await settle(tester);

    // Sensors come alive: GPS fix, compass and one Remote ID drone.
    sensors.fixes.add(fixAt(25.0330, 121.5654));
    sensors.orientations.add(sample());
    sensors.drones.add(RemoteIdDrone(
      sourceAddress: 'AA:BB:CC:DD:EE:FF',
      transport: 'bt5',
      lastSeen: DateTime.now().toUtc(),
      uasId: '1581F5BKD223M00A',
      idType: 'serial',
      lat: 25.0340,
      lon: 121.5660,
      heightM: 85,
      operatorLat: 25.0320,
      operatorLon: 121.5640,
    ));
    await settle(tester);

    expect(find.text('Location ±6 m'), findsOneWidget);
    expect(find.text('1 drone broadcasting Remote ID'), findsOneWidget);
    expect(find.text('123°'), findsOneWidget);

    await tester.tap(find.text('Lock direction'));
    await settle(tester);

    // Details step.
    expect(find.text('What did you see?'), findsOneWidget);
    await tapInList(tester, find.text('Below 30 m'));
    await tapInList(tester, find.text('Hovering'));
    await tapInList(tester, find.text('2'));
    await tester.scrollUntilVisible(find.byType(TextField), 100, scrollable: find.byType(Scrollable).last);
    await tester.enterText(find.byType(TextField), 'Over the school yard');
    await settle(tester, 2);
    await tester.tap(find.text('Next'));
    await settle(tester);

    // Evidence step: the aim photo is already there; add one more.
    expect(find.text('Photo taken when locking direction'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Photo'));
    await settle(tester);

    await tester.tap(find.text('Send report now'));
    await settle(tester, 20);

    final bodies = backend.bodiesFor('POST', '/v1/reports');
    expect(bodies, hasLength(1));
    final body = bodies.single;
    expect(body['platform'], 'android');
    expect(body['language'], 'en');
    expect(body['bearing_deg'], closeTo(123.4, 1e-9));
    expect(body['elevation_deg'], closeTo(25.0, 1e-9));
    expect(body['bearing_accuracy_deg'], 12);
    expect(body['compass_calibrated'], isTrue);
    expect(body['est_altitude_m'], 20);
    expect(body['movement'], 'hovering');
    expect(body['drone_count'], 2);
    expect(body['description'], 'Over the school yard');
    expect(body['observer'], {'lat': 25.0330, 'lon': 121.5654, 'accuracy_m': 6});
    expect(body['token_secret'], isA<String>());
    expect((body['token_secret'] as String).length, greaterThanOrEqualTo(32));
    expect(body['device_id'], isNotEmpty);
    expect(body['remote_id_transports'], ['bt4', 'bt5']);
    final rid = (body['remote_id'] as List).single as Map;
    expect(rid['uas_id'], '1581F5BKD223M00A');
    expect(rid['transport'], 'bt5');
    expect(rid['height_m'], 85);
    expect(rid['operator_lat'], 25.0320);
    final media = (body['media'] as List).cast<Map>();
    expect(media.map((m) => m['slot']).toSet(), {'aim1', 'photo1'});
    expect(media.every((m) => RegExp(r'^[0-9a-f]{64}$').hasMatch(m['sha256'] as String)), isTrue);

    // Play Integrity is bound to this exact packet.
    expect(body['attestation_token'], 'integrity-token');
    expect(sensors.integrityHashes.single, sha256Hex(ReportRequest.fromJson(body).canonicalForHash()));

    // Sent screen, stored follow-up key, uploads queued against the returned tickets.
    expect(find.text('Report sent'), findsOneWidget);
    expect(find.text(caseNumber), findsOneWidget);
    final stored = await InformantStore().reports();
    expect(stored.single.caseNumber, caseNumber);
    expect(uploads.enqueued.single.caseNumber, caseNumber);
    expect(uploads.enqueued.single.tickets.map((t) => t.slot), ['aim1', 'photo1']);
    expect(await SecureOutbox().all(), isEmpty);

    // Dispose the app so its timers stop.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('send is unavailable until there is a location fix', (tester) async {
    final sensors = FakeSensors()..withCamera = false;
    final backend = FakeBackend((_) async => jsonResponse([]));
    await tester.pumpWidget(ProviderScope(
      overrides: overridesFor(backend: backend, sensors: sensors),
      child: const InformantApp(),
    ));
    await settle(tester);
    await tester.tap(find.text('Report a sighting'));
    await settle(tester);

    FilledButton sendButton() =>
        tester.widget<FilledButton>(find.ancestor(of: find.text('Send report now'), matching: find.byWidgetPredicate((w) => w is FilledButton)));
    expect(sendButton().onPressed, isNull);
    expect(find.text('Finding your location…'), findsOneWidget);

    sensors.fixes.add(fixAt(25.0, 121.5));
    await settle(tester);
    expect(sendButton().onPressed, isNotNull);

    // Aiming can be skipped (no camera / compass).
    await tester.tap(find.text('Skip aiming'));
    await settle(tester);
    expect(find.text('What did you see?'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('maritime sighting through the server interview', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final sensors = FakeSensors();
    final backend = FakeBackend((r) async {
      if (r.url.path.endsWith('/v1/public/interview')) {
        return jsonResponse({
          'version': '1',
          'questions': [
            {'id': 'domain', 'label': 'Where is it?', 'options': [
              {'value': 'aerial', 'label': 'In the air'}, {'value': 'surface', 'label': 'On the water'}]},
            {'id': 'surface_type', 'label': 'What kind of craft?', 'when': {'domain': ['surface']}, 'options': [
              {'value': 'unmanned', 'label': 'Small boat with nobody on board'}, {'value': 'ship', 'label': 'Large ship'}]},
          ],
        });
      }
      if (r.method == 'POST' && r.url.path.endsWith('/v1/reports')) {
        return jsonResponse(reportResponse(['aim1']), 201);
      }
      return jsonResponse([]);
    });

    await tester.pumpWidget(ProviderScope(
      overrides: overridesFor(backend: backend, sensors: sensors, uploads: FakeUploads()),
      child: const InformantApp(),
    ));
    await settle(tester);
    await tester.tap(find.text('Report a sighting'));
    await settle(tester);
    sensors.fixes.add(fixAt(22.585, 120.285));
    sensors.orientations.add(sample());
    await settle(tester);
    await tester.tap(find.text('Lock direction'));
    await settle(tester);

    expect(find.text('What kind of craft?'), findsNothing); // branch hidden until the domain is known
    await tapInList(tester, find.text('On the water'));
    await tapInList(tester, find.text('Small boat with nobody on board'));

    await tester.tap(find.text('Send report now'));
    await settle(tester, 20);
    final body = backend.bodiesFor('POST', '/v1/reports').single;
    expect(body['craft_domain'], 'surface');
    expect(body['interview_version'], '1');
    expect(body['interview'], {'domain': 'surface', 'surface_type': 'unmanned'});
    expect(body.containsKey('est_altitude_m'), isFalse);
  });
}
