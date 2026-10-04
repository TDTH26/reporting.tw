import 'package:feature_agency/feature_agency.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

void main() {
  testWidgets('CCTV section lists cameras and their tracks with behaviours and the linked case', (tester) async {
    SharedPreferences.setMockInitialValues({'agency.locale': 'en'});
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    Map<String, dynamic> pt(String t, double x, List<double> box) => {'t': t, 'x': x, 'y': 0.4, 'box': box};
    final backend = FakeBackend({
      'GET /v1/agency/queue': (_) => {'seq': 1, 'cases': []},
      'GET /v1/agency/video-feeds': (_) => [
        {
          'id': '0AXD',
          'name': 'Yilan Coast',
          'owner': 'CGA',
          'position': {'lat': 24.85, 'lon': 120.92},
          'bearing_deg': 90,
          'fov_deg': 60,
          'domains': ['aerial', 'surface'],
          'active': true,
          'open_cases': 1,
        },
      ],
      'GET /v1/agency/video-feeds/0AXD/tracks': (_) => {
        'feed': {
          'id': '0AXD',
          'alert_zone': [
            [0.35, 0.25],
            [0.65, 0.25],
            [0.65, 0.75],
            [0.35, 0.75],
          ],
        },
        'tracks': [
          {
            'key': '0AXD-T3',
            'status': 'active',
            'craft_domain': 'aerial',
            'craft_type': 'uav_fixed_wing',
            'first_at': '2026-10-03T16:30:07Z',
            'last_at': '2026-10-03T16:30:27Z',
            'hits': 5,
            'path': [
              pt('2026-10-03T16:30:07Z', 0.71, [0.62, 0.29, 0.8, 0.41]),
              pt('2026-10-03T16:30:27Z', 0.54, [0.38, 0.3, 0.71, 0.51]),
            ],
            'behaviours': [
              {'code': 'approaching', 'text': 'Getting closer to the camera: 3.4x larger'},
              {'code': 'zone', 'text': "Inside the camera's watch area"},
            ],
            'last_frame_url': null,
            'case': {'id': 'c-1', 'case_number': 'UAV-261003-000010', 'severity': 4},
          },
          {
            'key': '0AXD-T2',
            'status': 'lost',
            'craft_domain': 'aerial',
            'craft_type': 'uav_multirotor',
            'first_at': '2026-10-03T16:20:00Z',
            'last_at': '2026-10-03T16:20:05Z',
            'hits': 1,
            'path': [pt('2026-10-03T16:20:00Z', 0.2, [0.15, 0.3, 0.25, 0.4])],
            'behaviours': [],
            'last_frame_url': null,
            'case': null,
          },
        ],
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

    await tester.tap(find.text('CCTV').first);
    await settle(tester, 20);

    expect(find.text('CCTV camera tracks'), findsOneWidget);
    expect(find.text('Yilan Coast (0AXD)'), findsOneWidget);
    expect(find.text('1 open case · CGA · Aerial · Surface'), findsOneWidget); // camera marked as needing attention
    expect(find.byKey(const Key('cctv-track-0AXD-T3')), findsOneWidget);
    expect(find.byKey(const Key('cctv-track-0AXD-T2')), findsOneWidget);
    // The track with the most frames is shown first, with its behaviours and the case it created.
    expect(find.text('Getting closer to the camera: 3.4x larger'), findsOneWidget);
    expect(find.text('Open case UAV-261003-000010'), findsOneWidget);
    expect(find.text('Watch area'), findsWidgets);

    await tester.tap(find.byKey(const Key('cctv-track-0AXD-T2')));
    await settle(tester, 20);
    expect(find.byKey(const Key('cctv-open-case')), findsNothing);
    expect(
      backend.requests.any((r) => r.url.path.endsWith('/video-feeds/0AXD/tracks')),
      isTrue,
    );
  });
}
