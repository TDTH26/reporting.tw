import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uavr_api/uavr_api.dart';

void main() {
  test('canonical request hash string matches the backend format', () {
    final r = ReportRequest(
      clientReportId: '00000000-0000-0000-0000-000000000001',
      platform: 'android',
      appVersion: '1',
      language: 'en',
      deviceId: 'device-12345',
      observedAt: DateTime.utc(2026, 10, 2, 8, 0, 0, 123),
      observer: const LatLon(25.0330001, 121.5654),
      media: [
        MediaDeclaration(slot: 'b', kind: MediaKind.photo, mimeType: 'image/jpeg', sha256: 'b' * 64, sizeBytes: 1,
            capturedAt: DateTime.utc(2026)),
        MediaDeclaration(slot: 'a', kind: MediaKind.audio, mimeType: 'audio/aac', sha256: 'a' * 64, sizeBytes: 1,
            capturedAt: DateTime.utc(2026)),
      ],
    );
    expect(r.canonicalForHash(),
        'uavr-report-v1|00000000-0000-0000-0000-000000000001|1790928000123|25.033000|121.565400|${'a' * 64},${'b' * 64}');
    final round = ReportRequest.fromJson(jsonDecode(jsonEncode(r.toJson())) as Map<String, dynamic>);
    expect(round.canonicalForHash(), r.canonicalForHash());
  });

  test('errors carry status and detail', () async {
    final api = UavrApi('http://x', httpClient: MockClient((req) async {
      expect(req.headers['X-Report-Token'], 't');
      return http.Response(jsonEncode({'detail': 'invalid token'}), 401);
    }));
    expect(
      () => api.informantCases('t'),
      throwsA(isA<ApiException>().having((e) => e.status, 'status', 401).having((e) => e.message, 'msg', 'invalid token')),
    );
  });

  test('case summary parses queue rows and redacted rows', () {
    final full = CaseSummary.fromJson({
      'id': 'c1', 'case_number': 'UAV-1', 'state': 'new', 'severity': 3, 'classification': 0, 'agency_id': 1,
      'desk_id': 2, 'position': {'lat': 25.0, 'lon': 121.0}, 'can_act': true, 'redacted': false,
      'track': {'type': 'LineString', 'coordinates': [[121.0, 25.0], [121.1, 25.1]]},
    });
    expect(full.state, CaseState.newCase);
    expect(full.track.length, 2);
    expect(full.track.last.lat, 25.1);
    final red = CaseSummary.fromJson({'id': 'c2', 'case_number': 'UAV-2', 'state': 'acknowledged', 'severity': 2,
      'classification': 2, 'agency_id': 13, 'desk_id': 2, 'redacted': true});
    expect(red.redacted, isTrue);
    expect(red.state.isOpen, isTrue);
  });

  test('zones parse from GeoJSON feature collections', () {
    final zones = Zone.fromFeatureCollection({
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'properties': {'code': 'APT', 'name': 'Airport', 'name_zh': '機場', 'zone_type': 'airport'},
          'geometry': {
            'type': 'MultiPolygon',
            'coordinates': [
              [[[121.0, 25.0], [121.1, 25.0], [121.1, 25.1], [121.0, 25.0]]],
            ],
          },
        },
      ],
    });
    expect(zones.single.rings.single.length, 4);
  });

  test('destination and distance agree', () {
    const a = LatLon(25.03, 121.56);
    final b = a.destination(45, 1000);
    expect(a.distanceTo(b), closeTo(1000, 2));
  });

  test('interview branching and pruning', () {
    final iv = Interview.fromJson({
      'version': '1',
      'questions': [
        {'id': 'domain', 'label': 'Where?', 'options': [{'value': 'aerial', 'label': 'Air'}, {'value': 'surface', 'label': 'Water'}]},
        {'id': 'surface_type', 'label': 'Type?', 'when': {'domain': ['surface']},
          'options': [{'value': 'unmanned', 'label': 'USV'}]},
        {'id': 'count', 'label': 'How many?', 'options': [{'value': '1', 'label': '1'}]},
      ],
    });
    expect(iv.visible({}).map((q) => q.id), ['domain', 'count']);
    expect(iv.visible({'domain': 'surface'}).map((q) => q.id), ['domain', 'surface_type', 'count']);
    expect(iv.prune({'domain': 'aerial', 'surface_type': 'unmanned', 'count': '1'}), {'domain': 'aerial', 'count': '1'});
    final r = ReportRequest(clientReportId: 'x', platform: 'web', appVersion: '1', language: 'en', deviceId: 'device-123',
        observedAt: DateTime.utc(2026), observer: const LatLon(25, 121), interviewVersion: '1',
        interview: {'domain': 'surface'});
    expect(r.toJson()['interview'], {'domain': 'surface'});
    expect(ReportRequest.fromJson(r.toJson()).interview, {'domain': 'surface'});
  });

  test('maritime case fields', () {
    final c = CaseSummary.fromJson({'id': 'c', 'case_number': 'n', 'state': 'new', 'severity': 2, 'classification': 0,
      'agency_id': 1, 'desk_id': 1, 'craft_domain': 'surface', 'craft_type': 'usv',
      'vessel_match': {'dark': true, 'mda_track': {'track_id': 'MDA-1'}}, 'ai_assessment': {'threat_level': 3}});
    expect(c.isMaritime, isTrue);
    expect(c.isDarkVessel, isTrue);
    expect(c.aiAssessment!['threat_level'], 3);
  });
}
