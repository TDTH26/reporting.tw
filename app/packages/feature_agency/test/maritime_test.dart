import 'package:feature_agency/feature_agency.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

Map<String, dynamic> alert(int id, int score, List<String> kinds, {String status = 'open'}) => {
  'id': id,
  'source_id': 'sim',
  'source_kind': 'ais',
  'track_id': '416000$id',
  'kinds': kinds,
  'method': 'both',
  'score': score,
  'rule_score': 45,
  'stat_score': 13.2,
  'confidence': 0.85,
  'reasons': [
    {
      'code': 'zone_entry',
      'text': 'Entered DEMO restricted waters (Zuoying)',
      'lat': 22.7,
      'lon': 120.25,
      'at': '2026-10-03T08:00:00Z',
    },
    {'code': 'gap', 'text': 'No reports for 2.3 h; reappeared 41.2 km away', 'value': 138.0, 'threshold': 45.0},
  ],
  'uncertainty': ['Sparse track: a position every 1.5 h on average.'],
  'status': status,
  'first_at': '2026-10-03T06:00:00Z',
  'last_at': '2026-10-03T09:00:00Z',
  'position': {'lat': 22.7, 'lon': 120.25},
  'zone_ids': [1],
};

void main() {
  testWidgets('maritime alerts: list, explanation, timeline, decisions and evaluation', (tester) async {
    SharedPreferences.setMockInitialValues({'agency.locale': 'en'});
    tester.view.physicalSize = const Size(1600, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final backend = FakeBackend({
      'GET /v1/agency/queue': (_) => {'seq': 1, 'cases': []},
      'GET /v1/agency/desks': (_) => desksJson,
      'GET /v1/agency/zones': (_) => {'type': 'FeatureCollection', 'features': []},
      'GET /v1/maritime/alerts': (_) => {
        'alerts': [
          alert(7, 82, ['zone_entry', 'gap', 'statistical']),
        ],
        'counts': {'open': 1},
      },
      'GET /v1/maritime/alerts/7': (_) => {
        ...alert(7, 82, ['zone_entry', 'gap', 'statistical']),
        'track': [
          {'t': '2026-10-03T06:00:00Z', 'lat': 22.5, 'lon': 120.0},
          {'t': '2026-10-03T09:00:00Z', 'lat': 22.7, 'lon': 120.25},
        ],
        'vessel': {'name': 'SIM VESSEL 7', 'mmsi': '416000007'},
        'zones': [],
        'events': [
          {
            'at': '2026-10-03T09:01:00Z',
            'actor': null,
            'action': 'detected',
            'detail': {'score': 82},
          },
        ],
      },
      'POST /v1/maritime/alerts/7/status': (_) => alert(7, 82, ['zone_entry'], status: 'acknowledged'),
      'GET /v1/maritime/evaluation': (_) => {
        'id': 3,
        'tracks': 189,
        'anomalous': 17,
        'created_at': '2026-10-03T09:00:00Z',
        'results': {
          for (final (m, p, r, f, fa) in [
            ('rules', 0.46, 1.0, 0.63, 11.6),
            ('statistical', 0.47, 0.82, 0.60, 9.3),
            ('combined', 0.71, 1.0, 0.83, 4.1),
          ])
            m: {
              'precision': p,
              'recall': r,
              'f1': f,
              'false_alarms_per_100_normal': fa,
              'tp': 17,
              'fp': 7,
              'fn': 0,
              'by_kind': {
                'gap': {'tracks': 3, 'found': 3},
              },
            },
        },
      },
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(backend, dispatcher(), FakeLiveChannel(backend.api), sound: FakeSound()).cast(),
        retry: (_, _) => null,
        child: const AgencyApp(),
      ),
    );
    await settle(tester, 20);
    await tester.tap(find.text('Maritime').first);
    await settle(tester, 20);

    expect(find.text('Entered protected waters · Reporting gap · Statistically unusual'), findsOneWidget);
    await tester.tap(find.text('82'));
    await settle(tester, 20);
    expect(find.text('SIM VESSEL 7'), findsOneWidget);
    expect(find.text('Risk 82'), findsWidgets);
    expect(find.textContaining('No reports for 2.3 h'), findsOneWidget);
    expect(find.textContaining('measured 138 · threshold 45'), findsOneWidget);
    expect(find.textContaining('Sparse track'), findsOneWidget);
    expect(find.textContaining('Detected'), findsOneWidget);

    await tester.tap(find.text('Acknowledge'));
    await settle(tester, 10);
    final post = backend.requests.lastWhere((r) => r.url.path.endsWith('/v1/maritime/alerts/7/status'));
    expect(post.body, contains('"acknowledged"'));

    await tester.tap(find.text('Rules vs statistics'));
    await settle(tester, 20);
    expect(find.text('Combined risk score (what operators see)'), findsWidgets);
    expect(find.text('71%'), findsOneWidget);
    expect(find.text('4.1'), findsOneWidget);
  });
}
