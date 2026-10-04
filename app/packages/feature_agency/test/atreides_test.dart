import 'package:feature_agency/feature_agency.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

void main() {
  testWidgets('Atreides section shows summary, tracks and filters by role', (tester) async {
    SharedPreferences.setMockInitialValues({'agency.locale': 'en'});
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final backend = FakeBackend({
      'GET /v1/agency/queue': (_) => {'seq': 1, 'cases': []},
      'GET /v1/agency/desks': (_) => desksJson,
      'GET /v1/agency/zones': (_) => {'type': 'FeatureCollection', 'features': []},
      'GET /v1/atreides/batches': (_) => [
        {
          'id': 1,
          'filename': 'MDA Sensor Mini Sample_APRIL_26.csv',
          'accepted': 3,
          'dropped': 0,
          'tracks': 2,
          'received_via': 'cli',
          'shifted_s': 0,
        },
      ],
      'GET /v1/atreides/summary': (_) => {
        'detections': 3,
        'tracks': 2,
        'routes': 1,
        'single_contacts': 1,
        'first_at': '2026-04-02T09:00:00Z',
        'last_at': '2026-04-02T11:00:00Z',
        'bbox': {'min_lat': 24.1, 'min_lon': 120.1, 'max_lat': 25.0, 'max_lon': 121.9},
        'by_role': {'mobile_asset': 2, 'fixed_site': 1, 'ambiguous': 0},
        'by_confidence': {'high': 3, 'low': 0},
      },
      'GET /v1/atreides/tracks': (req) => [
        if (req.url.queryParameters['role'] != 'fixed_site')
          {
            'track_id': 'ATR1-R2-12.0',
            'role': 'mobile_asset',
            'points': 2,
            'span_km': 12.0,
            'confidence': 'high',
            'reasoning': 'moves across 12.0 km with plausible max speed 9.1 km/h',
            'first_at': '2026-04-02T09:00:00Z',
            'last_at': '2026-04-02T11:00:00Z',
            'last': {'lat': 24.2, 'lon': 120.2},
            'path': [
              [24.1, 120.1],
              [24.2, 120.2],
            ],
          },
        {
          'track_id': 'ATR1-Pabc',
          'role': 'fixed_site',
          'points': 1,
          'span_km': 0,
          'confidence': 'low',
          'reasoning': 'insufficient or mixed evidence',
          'source_role': 'fixed_site',
          'source_confidence': 'high',
          'source_reasoning': 'stays within 0.13 km and looks stationary',
          'last_at': '2026-04-02T09:30:00Z',
          'last': {'lat': 25.0, 'lon': 121.9},
          'path': [],
        },
      ],
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(backend, dispatcher(), FakeLiveChannel(backend.api), sound: FakeSound()).cast(),
        retry: (_, _) => null,
        child: const AgencyApp(),
      ),
    );
    await settle(tester, 20);

    await tester.tap(find.text('Atreides').first);
    await settle(tester, 20);

    expect(find.text('Atreides maritime sensor'), findsOneWidget);
    expect(find.textContaining('Detections 3 · Tracks 2 (1 routes · 1 single contacts)'), findsOneWidget);
    expect(find.text('Fixed site 1'), findsOneWidget); // role filter shows the count
    expect(find.text('Mobile asset · 2 detections · 12.0 km'), findsOneWidget);
    expect(find.textContaining('stays within 0.13 km'), findsOneWidget);
    expect(find.text('Showing 2 of 2'), findsOneWidget);

    await tester.tap(find.text('Fixed site 1'));
    await settle(tester, 20);
    expect(find.text('Showing 1 of 1'), findsOneWidget);
    expect(
      backend.requests.any(
        (r) => r.url.path.endsWith('/v1/atreides/tracks') && r.url.queryParameters['role'] == 'fixed_site',
      ),
      isTrue,
    );
  });
}
