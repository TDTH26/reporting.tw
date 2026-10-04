import 'package:feature_informant/feature_informant.dart';
import 'package:feature_informant/src/screens/report/report_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_core/uavr_core.dart';

import 'fakes.dart';

ReportRequest request() => ReportRequest(
      clientReportId: 'b4c8e0de-5d2a-4a43-9a51-0d6f1c2f7e11',
      tokenSecret: InformantStore.newSecret(),
      platform: 'android',
      appVersion: '1.0.0',
      language: 'zh-TW',
      deviceId: 'device-install-0001',
      observedAt: DateTime.now().toUtc(),
      observer: const LatLon(24.1477, 120.6736),
      observerAccuracyM: 8,
      bearingDeg: 270,
      elevationDeg: 30,
      media: [
        MediaDeclaration(
          slot: 'photo1',
          kind: MediaKind.photo,
          mimeType: 'image/jpeg',
          sha256: 'a' * 64,
          sizeBytes: 1000,
          capturedAt: DateTime.now().toUtc(),
        ),
      ],
    );

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('a network failure keeps the report in the outbox; the retry is idempotent', () async {
    var online = false;
    final backend = FakeBackend((r) async {
      if (!online) throw http.ClientException('connection refused');
      return jsonResponse({
        'case_number': 'UAV-20261002-0007',
        'token': 'b5a1c3d2-0000-4000-8000-000000000001.secret',
        'status': 'received',
        'fidelity': 'high',
        'uploads': [
          {'slot': 'photo1', 'evidence_id': 'e1', 'upload_url': 'http://test/files/', 'upload_token': 't1'},
        ],
      }, 201);
    });
    final uploads = FakeUploads();
    final sensors = FakeSensors();
    final app = ProviderContainer(overrides: overridesFor(backend: backend, sensors: sensors, uploads: uploads));
    addTearDown(app.dispose);

    final req = request();
    final pending = PendingReport(request: req, media: const [], createdAt: DateTime.now().toUtc());
    final outcome = await app.read(reportSenderProvider).submit(pending);

    expect(outcome, isA<SendQueued>());
    final queued = await app.read(outboxProvider).all();
    expect(queued.single.id, req.clientReportId);
    expect(queued.single.request.tokenSecret, req.tokenSecret);
    expect(await InformantStore().reports(), isEmpty);

    // "Restart": a fresh container and outbox read the persisted report back.
    online = true;
    final restarted = ProviderContainer(overrides: overridesFor(backend: backend, sensors: sensors, uploads: uploads));
    addTearDown(restarted.dispose);
    expect(await restarted.read(reportSenderProvider).flushOutbox(), 1);

    final bodies = backend.bodiesFor('POST', '/v1/reports');
    expect(bodies, hasLength(2));
    expect(bodies[1]['client_report_id'], bodies[0]['client_report_id']);
    expect(bodies[1]['token_secret'], bodies[0]['token_secret']);
    expect(bodies[1]['token_secret'], req.tokenSecret);
    expect(bodies[1]['media'], bodies[0]['media']);

    expect(await restarted.read(outboxProvider).all(), isEmpty);
    expect((await InformantStore().reports()).single.caseNumber, 'UAV-20261002-0007');
    expect(uploads.enqueued.single.tickets.single.slot, 'photo1');
  });

  test('rate limiting removes the report from the outbox and reports it', () async {
    final backend = FakeBackend((_) async => jsonResponse({'detail': 'too many reports from this device'}, 429));
    final app = ProviderContainer(overrides: overridesFor(backend: backend));
    addTearDown(app.dispose);

    final outcome = await app
        .read(reportSenderProvider)
        .submit(PendingReport(request: request(), media: const [], createdAt: DateTime.now().toUtc()));
    expect(outcome, isA<SendRateLimited>());
    expect(await app.read(outboxProvider).all(), isEmpty);
  });

  test('compass accuracy maps to bearing uncertainty and the API ranges', () {
    final locks = [3, 2, 1, 0].map((a) => DirectionLock.fromSample(sample(accuracy: a))).toList();
    expect(locks.map((l) => l.bearingAccuracyDeg), [8, 12, 20, 35]);
    expect(locks.map((l) => l.calibrated), [true, true, false, false]);
    final edge = DirectionLock.fromSample(sample(az: 360, el: -40));
    expect(edge.bearingDeg, 0);
    expect(edge.elevationDeg, -10);
  });
}
