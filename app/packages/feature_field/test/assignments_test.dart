import 'package:feature_field/feature_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uavr_api/uavr_api.dart';

import 'helpers.dart';

Map<String, dynamic> caseJson(String id, String number, {bool redacted = false, int severity = 3}) => {
      'id': id,
      'case_number': number,
      'state': 'acknowledged',
      'severity': severity,
      'classification': redacted ? 2 : 0,
      'agency_id': 1,
      'desk_id': 1,
      'created_at': DateTime.now().toUtc().subtract(const Duration(minutes: 10)).toIso8601String(),
      'last_seen': DateTime.now().toUtc().subtract(const Duration(minutes: 3)).toIso8601String(),
      // ~1.1 km north-east of Taipei 101
      'position': {'lat': 25.0400, 'lon': 121.5730},
      'redacted': redacted,
      if (!redacted) ...{
        'authorization': 'no_permit',
        'remote_id_serials': ['1581F5FKD229400B'],
        'operator_position': {'lat': 25.0390, 'lon': 121.5700},
      },
    };

Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 10; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets('assignments render online and come from the offline cache when the API is unreachable', (t) async {
    final server = FakeServer((r) async {
      if (r.url.path == '/api/v1/field/assignments') {
        return jsonResponse([
          caseJson('c1', 'TPE-20261002-0007'),
          caseJson('c2', 'MND-20261002-0001', redacted: true, severity: 2),
        ]);
      }
      return jsonResponse({'detail': 'not found'}, 404);
    });
    final deps = TestDeps(server);

    await t.pumpWidget(deps.app());
    await settle(t);

    expect(find.text('My assignments'), findsOneWidget);
    expect(find.text('TPE-20261002-0007'), findsOneWidget);
    expect(find.text('MND-20261002-0001'), findsOneWidget);
    expect(find.byIcon(Icons.lock), findsOneWidget); // redacted defense case
    expect(find.textContaining('km'), findsNWidgets(2)); // distance from me
    expect(find.textContaining('NE'), findsNWidgets(2)); // bearing
    expect(find.textContaining('Offline'), findsNothing);
    expect(deps.live.starts, 1);

    // The list was persisted.
    final cached = await deps.cache.readAssignments();
    expect(cached!.value.map((c) => c.caseNumber), ['TPE-20261002-0007', 'MND-20261002-0001']);

    // "Restart" the app with the server unreachable: same cache, fresh providers.
    await t.pumpWidget(const SizedBox());
    server.handler = offline;
    final deps2 = TestDeps(server);
    await deps2.cache.write('assignments', (await deps.cache.read('assignments'))!.value);
    await t.pumpWidget(deps2.app());
    await settle(t);

    expect(find.text('TPE-20261002-0007'), findsOneWidget);
    expect(find.text('MND-20261002-0001'), findsOneWidget);
    expect(find.textContaining('Offline — last updated'), findsOneWidget);

    await t.pumpWidget(const SizedBox());
  });

  testWidgets('a live event for an assigned case reloads the list', (t) async {
    var n = 0;
    final server = FakeServer((r) async {
      n++;
      return jsonResponse([caseJson('c1', n == 1 ? 'TPE-1' : 'TPE-1-updated')]);
    });
    final deps = TestDeps(server);
    await t.pumpWidget(deps.app());
    await settle(t);
    expect(find.text('TPE-1'), findsOneWidget);

    deps.live.controller.add(LiveMessage(type: 'event', seq: 5, kind: 'case.updated', payload: {
      'case': {'id': 'c1'},
    }));
    await t.pump(const Duration(milliseconds: 500));
    await settle(t);
    expect(find.text('TPE-1-updated'), findsOneWidget);

    await t.pumpWidget(const SizedBox());
  });
}
