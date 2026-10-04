import 'package:feature_field/feature_field.dart';
import 'package:feature_field/src/screens/evidence_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uavr_native/uavr_native.dart';

import 'assignments_test.dart' show settle;
import 'helpers.dart';

void main() {
  testWidgets('evidence submitted offline lands in the outbox; retry re-sends the same client_report_id', (t) async {
    var online = false;
    final server = FakeServer((r) async {
      if (!online) return offline(r);
      return jsonResponse({'observation_id': 'o1', 'uploads': []}, 201);
    });
    final deps = TestDeps(server);
    await t.pumpWidget(deps.wrap(const EvidenceScreen(caseId: 'case-1', caseNumber: 'TPE-20261002-0007')));
    await settle(t);

    // Lock a bearing from the compass.
    await t.tap(find.byType(Switch));
    await settle(t);
    deps.sensors.orientations.add(OrientationSample(
      azimuthDeg: 47.6,
      magneticAzimuthDeg: 52.1,
      elevationDeg: 18.2,
      declinationDeg: -4.5,
      accuracy: 3,
      at: DateTime.utc(2026, 10, 2, 8, 1),
    ));
    await settle(t);
    expect(find.text('48° NE'), findsOneWidget);
    await t.tap(find.text('Lock bearing'));
    await settle(t);

    await t.scrollUntilVisible(find.byType(TextField), 200, scrollable: find.byType(Scrollable).first);
    await t.enterText(find.byType(TextField), 'DJI quadcopter hovering over the river park');
    await settle(t);
    final submit = find.text('Submit');
    await t.scrollUntilVisible(submit, 200, scrollable: find.byType(Scrollable).first);
    await t.ensureVisible(submit);
    await t.pump();
    await t.tap(submit);
    await settle(t);

    expect(find.textContaining('Saved to the outbox'), findsOneWidget);
    final container = ProviderScope.containerOf(t.element(find.byType(EvidenceScreen)));
    final pending = container.read(outboxProvider);
    expect(pending, hasLength(1));
    expect(pending.single.lastError, 'network');
    expect(deps.outboxStore.saved, hasLength(1)); // persisted

    final first = server.calls.single.body as Map<String, dynamic>;
    expect(first['bearing_deg'], 47.6);
    expect(first['elevation_deg'], 18.2);
    expect(first['note'], 'DJI quadcopter hovering over the river park');
    expect(first['observer'], {'lat': myPosition.lat, 'lon': myPosition.lon, 'accuracy_m': 6.0});
    expect(first['observed_at'], '2026-10-02T08:01:00.000Z');
    expect(first['remote_id'], isEmpty);

    // Back online: the retry sends the identical request.
    online = true;
    await container.read(outboxProvider.notifier).retryAll();
    await settle(t);
    expect(server.calls, hasLength(2));
    final second = server.calls.last.body as Map<String, dynamic>;
    expect(second['client_report_id'], first['client_report_id']);
    expect(second, first);
    expect(container.read(outboxProvider), isEmpty);
    expect(deps.outboxStore.saved, isEmpty);

    await t.pumpWidget(const SizedBox());
  });

  testWidgets('outbox survives a restart and 409 (already received) drops the entry', (t) async {
    final server = FakeServer((r) async => jsonResponse({'detail': 'observation already received'}, 409));
    final deps = TestDeps(server);
    deps.outboxStore.saved = [
      OutboxEntry(
        caseId: 'case-1',
        caseNumber: 'TPE-1',
        kind: OutboxKind.remoteId,
        body: {'client_report_id': '11111111-2222-4333-8444-555555555555', 'observed_at': '2026-10-02T08:00:00Z'},
        createdAt: DateTime.utc(2026, 10, 2, 8),
      ).toJson(),
    ];
    await t.pumpWidget(deps.wrap(const Scaffold()));
    final container = ProviderScope.containerOf(t.element(find.byType(Scaffold)));
    container.read(outboxProvider);
    await settle(t);
    expect(container.read(outboxProvider), hasLength(1));
    await container.read(outboxProvider.notifier).retryAll();
    await settle(t);
    expect(server.calls.single.body, containsPair('client_report_id', '11111111-2222-4333-8444-555555555555'));
    expect(container.read(outboxProvider), isEmpty);
    expect(deps.outboxStore.saved, isEmpty);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('a 422 marks the entry rejected and keeps it', (t) async {
    final server = FakeServer((r) async => jsonResponse({'detail': 'invalid'}, 422));
    final deps = TestDeps(server);
    await t.pumpWidget(deps.wrap(const Scaffold()));
    final container = ProviderScope.containerOf(t.element(find.byType(Scaffold)));
    final r = await container.read(outboxProvider.notifier).submit(OutboxEntry(
          caseId: 'case-1',
          caseNumber: 'TPE-1',
          kind: OutboxKind.evidence,
          body: {'client_report_id': 'x'},
          createdAt: DateTime.now().toUtc(),
        ));
    expect(r, SubmitResult.rejected);
    expect(container.read(outboxProvider).single.rejected, isTrue);
    await container.read(outboxProvider.notifier).retryAll();
    expect(server.calls, hasLength(1)); // rejected entries are not retried automatically
    await t.pumpWidget(const SizedBox());
  });
}
