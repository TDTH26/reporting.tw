import 'dart:convert';

import 'package:feature_agency/src/case/case_detail_page.dart';
import 'package:feature_agency/src/case/observations_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'helpers.dart';

FakeBackend backendFor(Map<String, dynamic> detail) {
  final id = detail['id'];
  Object? summary(http.Request _) => detail;
  return FakeBackend({
    'GET /v1/agency/cases/$id': (_) => detail,
    'GET /v1/agency/desks': (_) => desksJson,
    'GET /v1/agency/templates': (_) => templatesJson,
    'GET /v1/agency/zones': (_) => {'type': 'FeatureCollection', 'features': []},
    'GET /v1/agency/queue': (_) => {'seq': 1, 'cases': []},
    'POST /v1/agency/cases/$id/acknowledge': summary,
    'POST /v1/agency/cases/$id/transfer': summary,
    'POST /v1/agency/cases/$id/resolve': summary,
  });
}

Future<FakeBackend> pumpCase(WidgetTester tester, Map<String, dynamic> detail) async {
  final b = backendFor(detail);
  await pumpLocalized(tester, CaseDetailPage(caseId: detail['id'] as String),
      overrides: overridesFor(b, dispatcher(), FakeLiveChannel(b.api)));
  await settle(tester, 20);
  return b;
}

bool enabled(WidgetTester tester, String action) =>
    tester.widget<ButtonStyleButton>(find.byKey(Key('action-$action'))).onPressed != null;

void main() {
  testWidgets('acknowledge and transfer call the right endpoints', (tester) async {
    final b = await pumpCase(tester, detailJson(caseJson('c1', 'UAV-1', severity: 2)));
    expect(find.text('UAV-1'), findsOneWidget);
    expect(enabled(tester, 'acknowledge'), isTrue);
    expect(enabled(tester, 'resolve'), isFalse); // New cases must be acknowledged first

    await tester.tap(find.byKey(const Key('action-acknowledge')));
    await settle(tester);
    expect(b.where('POST', '/cases/c1/acknowledge'), hasLength(1));

    await tester.tap(find.byKey(const Key('action-transfer')));
    await settle(tester);
    // Defense desk (clearance 2) is fine for an unclassified case; own desk is excluded.
    await tester.tap(find.byKey(const Key('transfer-desk')));
    await settle(tester);
    await tester.tap(find.textContaining('Aviation Police operations').last);
    await settle(tester);
    // Empty reason is refused.
    await tester.tap(find.byKey(const Key('dialog-confirm')));
    await settle(tester);
    expect(b.where('POST', '/transfer'), isEmpty);
    expect(find.text('A reason is required'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('transfer-reason')), 'Airport approach, APB jurisdiction');
    await tester.tap(find.byKey(const Key('dialog-confirm')));
    await settle(tester);
    final t = b.where('POST', '/cases/c1/transfer');
    expect(t, hasLength(1));
    expect(jsonDecode(t.single.body), {'desk_id': 11, 'reason': 'Airport approach, APB jurisdiction'});
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('resolve sends the chosen outcome code', (tester) async {
    final b = await pumpCase(tester, detailJson(caseJson('c2', 'UAV-2', state: 'acknowledged')));
    expect(enabled(tester, 'acknowledge'), isFalse);
    expect(enabled(tester, 'resolve'), isTrue);

    await tester.tap(find.byKey(const Key('action-resolve')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('outcome-unable_to_locate')));
    await settle(tester);
    await tester.enterText(find.byKey(const Key('resolve-note')), 'Patrol found nothing');
    await tester.tap(find.byKey(const Key('dialog-confirm')));
    await settle(tester);
    final r = b.where('POST', '/cases/c2/resolve');
    expect(r, hasLength(1));
    expect(jsonDecode(r.single.body), {'outcome_code': 'unable_to_locate', 'note': 'Patrol found nothing'});
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('actions are disabled when can_act is false', (tester) async {
    await pumpCase(tester, detailJson(caseJson('c3', 'UAV-3', desk: 11, agency: 10, canAct: false)));
    for (final a in ['acknowledge', 'investigate', 'transfer', 'merge', 'severity', 'evidence', 'field', 'resolve', 'close']) {
      expect(enabled(tester, a), isFalse, reason: a);
    }
    expect(find.byKey(const Key('readonly-notice')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('redacted case shows only the redacted notice, no observations', (tester) async {
    final redacted = caseJson('c4', 'UAV-4', severity: 3, classification: 2, redacted: true, canAct: false);
    await pumpCase(tester, redacted);
    expect(find.byKey(const Key('redacted-notice')), findsOneWidget);
    expect(find.text('Redacted case'), findsOneWidget);
    expect(find.byType(ObservationTile), findsNothing);
    expect(find.textContaining('Observations ('), findsNothing);
    expect(find.byKey(const Key('action-acknowledge')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('observations render for a full case', (tester) async {
    final obs = {
      'id': 'o1',
      'source_type': 'informant_android',
      'observed_at': DateTime.now().toUtc().toIso8601String(),
      'confidence': 0.6,
      'spam_score': 0.1,
      'bearing_deg': 45.0,
      'description': '很低在盤旋',
      'description_lang': 'zh-TW',
      'description_translated': 'Hovering very low',
      'evidence': [
        {'id': 'e1', 'kind': 'photo', 'status': 'verified', 'sha256': 'abcdef0123456789', 'captured_at': DateTime.now().toUtc().toIso8601String(), 'uploaded_at': DateTime.now().toUtc().toIso8601String()},
      ],
    };
    await pumpCase(tester, detailJson(caseJson('c5', 'UAV-5'), observations: [obs]));
    expect(find.byType(ObservationTile), findsOneWidget);
    expect(find.textContaining('Hovering very low'), findsOneWidget);
    expect(find.text('Verified'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
