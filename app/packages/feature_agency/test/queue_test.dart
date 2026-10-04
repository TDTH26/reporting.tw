import 'package:feature_agency/feature_agency.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uavr_api/uavr_api.dart';

import 'helpers.dart';

void main() {
  testWidgets('queue sorts by severity and inserts live case.created with an alert', (tester) async {
    SharedPreferences.setMockInitialValues({'agency.locale': 'en'});
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final backend = FakeBackend({
      'GET /v1/agency/queue': (_) => {
            'seq': 42,
            'cases': [
              caseJson('a', 'UAV-LOW-1', severity: 1),
              caseJson('b', 'UAV-CRIT-1', severity: 3),
              caseJson('c', 'UAV-MED-1', severity: 2, state: 'acknowledged'),
            ],
          },
      'GET /v1/agency/desks': (_) => desksJson,
      'GET /v1/agency/zones': (_) => {'type': 'FeatureCollection', 'features': []},
    });
    final live = FakeLiveChannel(backend.api);
    final sound = FakeSound();
    await tester.pumpWidget(ProviderScope(
      overrides: overridesFor(backend, dispatcher(), live, sound: sound).cast(),
      retry: (_, _) => null,
      child: const AgencyApp(),
    ));
    await settle(tester, 20);

    // Live channel starts from the REST seq.
    expect(live.startedFrom, 42);
    double y(String t) => tester.getTopLeft(find.text(t)).dy;
    expect(find.text('UAV-CRIT-1'), findsOneWidget);
    expect(y('UAV-CRIT-1'), lessThan(y('UAV-MED-1')));
    expect(y('UAV-MED-1'), lessThan(y('UAV-LOW-1')));
    expect(find.byKey(const Key('alert-banner')), findsNothing);

    final payload = Map<String, dynamic>.from(caseJson('d', 'UAV-NEW-9', severity: 3))..remove('can_act');
    live.emit(LiveMessage(type: 'event', seq: 43, kind: 'case.created', payload: {'case': payload}));
    await settle(tester);

    expect(find.byKey(const Key('alert-banner')), findsOneWidget);
    // Row + banner both show the number.
    expect(find.text('UAV-NEW-9'), findsOneWidget); // queue row
    expect(find.textContaining('UAV-NEW-9'), findsNWidgets(2)); // + banner line
    expect(sound.plays, [true]);
    // Critical: new row sorts above the medium one.
    expect(y('UAV-NEW-9'), lessThan(y('UAV-MED-1')));

    // A merged event removes the row.
    live.emit(LiveMessage(type: 'event', seq: 44, kind: 'case.merged', payload: {'case': caseJson('a', 'UAV-LOW-1', state: 'merged')}));
    await settle(tester);
    expect(find.text('UAV-LOW-1'), findsNothing);

    // Dismiss the alert.
    await tester.tap(find.byTooltip('Dismiss'));
    await settle(tester);
    expect(find.byKey(const Key('alert-banner')), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });
}
