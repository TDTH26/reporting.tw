import 'package:feature_field/src/screens/case_screen.dart';
import 'package:feature_field/feature_field.dart';
import 'package:feature_field/src/services/position_sharing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'assignments_test.dart' show caseJson, settle;
import 'helpers.dart';

Map<String, dynamic> detailJson() => {
      ...caseJson('c1', 'TPE-20261002-0007'),
      'can_act': false,
      'est_error_m': 60,
      'position_source': 'remote_id',
      'incident': {
        'id': 'i1',
        'zones': [
          {'id': 1, 'code': 'TPE-101', 'name': 'Taipei 101', 'name_zh': '台北101', 'zone_type': 'red', 'classification': 0},
        ],
        'operator_position': {'lat': 25.0390, 'lon': 121.5700},
        'adsb_nearby': [
          {'icao24': '899123', 'callsign': 'CAL123', 'alt_m': 900, 'distance_m': 4200},
        ],
        'weather': {'station_id': '466920', 'visibility_m': 8000, 'wind_speed_mps': 3.2, 'wind_dir_deg': 40},
        'permit': null,
        'registry_match': null,
      },
      'observations': [],
      'events': [
        {'id': 1, 'at': '2026-10-02T08:00:00Z', 'actor_type': 'user', 'action': 'note', 'reason': 'Unit 12 en route'},
      ],
      'field_officers': [],
    };

void main() {
  testWidgets('case screen shows readouts, facts, registry lookup and notes', (t) async {
    final server = FakeServer((r) async {
      final p = r.url.path;
      if (p == '/api/v1/field/cases/c1') return jsonResponse(detailJson());
      if (p == '/api/v1/agency/registry/1581F5FKD229400B') {
        return jsonResponse({
          'serial': '1581F5FKD229400B',
          'registered': true,
          'entry': {'registration_no': 'TW-UAS-0042', 'owner_name': 'Chen', 'model': 'Mavic 3', 'manufacturer': 'DJI'},
          'permits': [],
        });
      }
      if (p == '/api/v1/agency/cases/c1/notes') return jsonResponse(caseJson('c1', 'TPE-20261002-0007'));
      if (p == '/api/v1/field/position') return jsonResponse(null, 204);
      return jsonResponse({'detail': 'nf'}, 404);
    });
    final deps = TestDeps(server);
    await t.binding.setSurfaceSize(const Size(500, 1400));
    await t.pumpWidget(deps.wrap(const CaseScreen(caseId: 'c1')));
    await settle(t);

    expect(find.text('TPE-20261002-0007'), findsOneWidget);
    expect(find.text('Drone'), findsOneWidget);
    expect(find.text('Operator position'), findsOneWidget);
    expect(find.text('No permit'), findsWidgets);
    expect(find.textContaining('Unit 12 en route'), findsOneWidget);

    // Position sharing is on while the case is open and posts right away.
    final container = ProviderScope.containerOf(t.element(find.byType(CaseScreen)));
    expect(container.read(positionSharingProvider).sharing, isTrue);
    expect(server.calls.where((c) => c.path == '/api/v1/field/position'), hasLength(1));

    // 5 s refresh.
    final before = server.calls.where((c) => c.path == '/api/v1/field/cases/c1').length;
    await t.pump(const Duration(seconds: 5));
    await settle(t);
    expect(server.calls.where((c) => c.path == '/api/v1/field/cases/c1').length, before + 1);

    final reg = find.text('Registry');
    await t.scrollUntilVisible(reg, 200, scrollable: find.byType(Scrollable).first);
    await t.ensureVisible(reg);
    await t.pump();
    await t.tap(reg);
    await settle(t);
    expect(find.text('TW-UAS-0042'), findsOneWidget);
    await t.tap(find.text('Close'));
    await settle(t);

    // Detail was cached for offline use.
    expect((await deps.cache.readCase('c1'))!.value.summary.caseNumber, 'TPE-20261002-0007');

    await t.pumpWidget(const SizedBox());
    await t.binding.setSurfaceSize(null);
  });

  testWidgets('redacted case shows only location, time and severity', (t) async {
    final server = FakeServer((r) async => jsonResponse({...caseJson('c2', 'MND-1', redacted: true), 'can_act': false}));
    final deps = TestDeps(server);
    await t.binding.setSurfaceSize(const Size(500, 1400));
    await t.pumpWidget(deps.wrap(const CaseScreen(caseId: 'c2')));
    await settle(t);
    expect(find.textContaining('classified defense case'), findsOneWidget);
    expect(find.text('Remote ID scan'), findsNothing);
    expect(find.text('Operator position'), findsNothing);
    expect(find.text('Drone'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    await t.binding.setSurfaceSize(null);
  });

  testWidgets('case screen falls back to the cached detail when offline', (t) async {
    final server = FakeServer(offline);
    final deps = TestDeps(server);
    await deps.cache.write('case_c1', detailJson());
    await t.binding.setSurfaceSize(const Size(500, 1400));
    await t.pumpWidget(deps.wrap(const CaseScreen(caseId: 'c1')));
    await settle(t);
    expect(find.textContaining('Offline — last updated'), findsOneWidget);
    expect(find.text('TPE-20261002-0007'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    await t.binding.setSurfaceSize(null);
  });
}
