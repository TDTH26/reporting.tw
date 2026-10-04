import 'dart:async';
import 'dart:convert';

import 'package:feature_agency/feature_agency.dart';
import 'package:feature_agency/src/common/l10n.dart';
import 'package:feature_agency/src/live/alert_sound.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_core/uavr_core.dart';
import 'package:uavr_ui/uavr_ui.dart';

const deskId = 3;
const agencyId = 2;

Me dispatcher({int clearance = 1, Set<String> roles = const {'dispatcher'}}) => Me(
      id: 'u-1',
      username: 'tpe.dispatcher',
      displayName: 'Taipei dispatcher',
      roles: roles,
      clearance: clearance,
      fieldUnit: false,
      onDuty: true,
      desk: NamedRef(id: deskId, code: 'TCPD-DISPATCH', name: 'Taipei Police dispatch', nameZh: '臺北市警察局勤務指揮中心'),
      agency: NamedRef(id: agencyId, code: 'TCPD', name: 'Taipei City Police Department', nameZh: '臺北市政府警察局'),
    );

Json caseJson(
  String id,
  String number, {
  int severity = 1,
  String state = 'new',
  int desk = deskId,
  int agency = agencyId,
  int classification = 0,
  bool canAct = true,
  bool redacted = false,
}) =>
    {
      'id': id,
      'case_number': number,
      'state': state,
      'severity': severity,
      'classification': classification,
      'agency_id': agency,
      'desk_id': desk,
      'ack_deadline': state == 'new' ? DateTime.now().add(const Duration(minutes: 5)).toUtc().toIso8601String() : null,
      'created_at': DateTime.now().subtract(const Duration(minutes: 3)).toUtc().toIso8601String(),
      'position': {'lat': 25.033, 'lon': 121.5654},
      'first_seen': DateTime.now().subtract(const Duration(minutes: 3)).toUtc().toIso8601String(),
      'last_seen': DateTime.now().toUtc().toIso8601String(),
      if (!redacted) ...{
        'observation_count': 2,
        'distinct_informants': 2,
        'confidence': 0.8,
        'authorization': 'unknown',
        'severity_reasons': ['hovering_over_residences'],
        'sensor_confirmed': false,
        'remote_id_serials': <String>[],
        'est_error_m': 120.0,
      },
      'redacted': redacted,
      'can_act': canAct,
    };

Json detailJson(Json summary, {List<Json> observations = const []}) => {
      ...summary,
      'incident': {
        'id': 'inc-1',
        'zones': [
          {'id': 1, 'code': 'RES-XINYI', 'name': 'Xinyi', 'name_zh': '信義', 'zone_type': 'residential', 'classification': 0},
        ],
        'adsb_nearby': <Json>[],
      },
      'observations': observations,
      'events': [
        {'id': 1, 'at': DateTime.now().toUtc().toIso8601String(), 'actor_type': 'system', 'action': 'created'},
      ],
      'field_officers': <Json>[],
      'evidence_requests': <Json>[],
      'route_chain': [deskId],
      'route_index': 0,
      'read_agency_ids': <int>[],
    };

final desksJson = [
  {'id': deskId, 'code': 'TCPD-DISPATCH', 'name': 'Taipei Police dispatch', 'name_zh': '臺北市警察局勤務指揮中心', 'agency_id': agencyId, 'agency_code': 'TCPD', 'clearance': 1, 'is_catch_all': false, 'always_staffed': true},
  {'id': 11, 'code': 'APB-OPS', 'name': 'Aviation Police operations', 'name_zh': '航空警察局勤務指揮中心', 'agency_id': 10, 'agency_code': 'APB', 'clearance': 1, 'is_catch_all': false, 'always_staffed': true},
  {'id': 14, 'code': 'MND-KINMEN', 'name': 'Kinmen Defense ops', 'name_zh': '金門防衛指揮部作戰中心', 'agency_id': 13, 'agency_code': 'MND', 'clearance': 2, 'is_catch_all': false, 'always_staffed': false},
];

Json template(String code, String kind, String zh, String en) => {
      'code': code,
      'kind': kind,
      'texts': {'zh-TW': zh, 'en': en, 'vi': en, 'id': en, 'th': en, 'fil': en, 'de': en, 'fr': en},
      'requested_kinds': kind == 'evidence_request' ? ['photo'] : <String>[],
      'counts_as_false_report': false,
    };

final templatesJson = [
  template('authorized_flight', 'outcome', '經查為合法核准之飛行。', 'This was an authorized flight.'),
  template('unable_to_locate', 'outcome', '未能找到無人機或操作人。', 'We were unable to locate the drone.'),
  template('need_photo', 'evidence_request', '請提供照片。', 'Please send a photo.'),
];

/// Records requests and answers from a route table: 'GET /v1/agency/queue' -> body (or function).
class FakeBackend {
  FakeBackend(this.routes);
  final Map<String, Object? Function(http.Request)> routes;
  final requests = <http.Request>[];

  late final client = MockClient((req) async {
    requests.add(req);
    final key = '${req.method} ${req.url.path.replaceFirst('/api', '')}';
    final h = routes[key];
    if (h == null) return http.Response(jsonEncode({'detail': 'no route $key'}), 404);
    return http.Response.bytes(utf8.encode(jsonEncode(h(req))), 200, headers: {'content-type': 'application/json'});
  });

  late final api = UavrApi('http://test/api', accessToken: () async => 'tok', httpClient: client);

  List<http.Request> where(String method, String pathSuffix) =>
      requests.where((r) => r.method == method && r.url.path.endsWith(pathSuffix)).toList();
}

class FakeLiveChannel extends LiveChannel {
  FakeLiveChannel(UavrApi api) : super(api, () async => 'tok');
  final _ctrl = StreamController<LiveMessage>.broadcast();
  final _st = StreamController<LiveState>.broadcast();
  int? startedFrom;

  @override
  Stream<LiveMessage> get events => _ctrl.stream;
  @override
  Stream<LiveState> get states => _st.stream;

  @override
  void start({int fromSeq = 0}) {
    startedFrom = fromSeq;
    state = LiveState.connected;
    _st.add(LiveState.connected);
  }

  @override
  Future<void> close() async {}

  void emit(LiveMessage m) => _ctrl.add(m);
}

class FakeSound implements AlertSound {
  final plays = <bool>[];
  @override
  void play({bool critical = false}) => plays.add(critical);
}

const testConfig = AppConfig(
  flavor: AppFlavor.agency,
  apiBaseUrl: 'http://test/api',
  tileUrlTemplate: 'http://test/{z}/{x}/{y}',
  tileAttribution: 'test',
);

List overridesFor(FakeBackend b, Me me, FakeLiveChannel live, {FakeSound? sound}) => [
      configProvider.overrideWithValue(testConfig),
      staffApiProvider.overrideWithValue(b.api),
      meProvider.overrideWith((ref) => me),
      liveChannelProvider.overrideWithValue(live),
      consoleMapsEnabledProvider.overrideWithValue(false),
      if (sound != null) alertSoundProvider.overrideWithValue(sound),
    ];

/// Pumps [child] in a localized MaterialApp (English) with the given overrides.
Future<void> pumpLocalized(WidgetTester tester, Widget child, {List overrides = const []}) async {
  tester.view.physicalSize = const Size(1440, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: overrides.cast(),
    retry: (_, _) => null,
    child: MaterialApp(
      locale: const Locale('en'),
      supportedLocales: staffLocales,
      localizationsDelegates: const [
        AgencyL10n.delegate,
        UavrL10n.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: child),
    ),
  ));
}

/// Pump a few frames (the queue has ticking countdowns, so pumpAndSettle may spin).
Future<void> settle(WidgetTester tester, [int frames = 10]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}
