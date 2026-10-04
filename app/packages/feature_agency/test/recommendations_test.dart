import 'package:feature_agency/src/case/case_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

Map<String, dynamic> rec(int id, String kind, String text, {String status = 'proposed'}) => {
  'id': id,
  'kind': kind,
  'code': kind,
  'priority': id,
  'text': text,
  'reason': 'Because $kind',
  'detail': {},
  'status': status,
};

void main() {
  testWidgets('recommended actions: accept and modify go to the API', (tester) async {
    final detail = detailJson(caseJson('c9', 'UAV-9', severity: 3));
    final b = FakeBackend({
      'GET /v1/agency/cases/c9': (_) => detail,
      'GET /v1/agency/desks': (_) => desksJson,
      'GET /v1/agency/templates': (_) => templatesJson,
      'GET /v1/agency/zones': (_) => {'type': 'FeatureCollection', 'features': []},
      'GET /v1/agency/queue': (_) => {'seq': 1, 'cases': []},
      'GET /v1/agency/cases/c9/recommendations': (_) => {
        'can_act': true,
        'recommendations': [
          rec(1, 'tower', 'Notify the tower'),
          rec(2, 'camera', 'Point camera A at the drone'),
          rec(3, 'warn', 'Area warning', status: 'rejected'),
        ],
      },
      'POST /v1/agency/cases/c9/recommendations/1': (_) => rec(1, 'tower', 'Notify the tower', status: 'accepted'),
      'POST /v1/agency/cases/c9/recommendations/2': (_) => rec(2, 'camera', 'Point camera A', status: 'modified'),
    });
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpLocalized(
      tester,
      const CaseDetailPage(caseId: 'c9'),
      overrides: overridesFor(b, dispatcher(), FakeLiveChannel(b.api)),
    );
    await settle(tester, 20);

    expect(find.text('Recommended actions'), findsOneWidget);
    expect(find.text('Notify the tower'), findsOneWidget);
    expect(find.text('Rejected'), findsOneWidget);
    expect(find.text('Accept'), findsNWidgets(2)); // the rejected one has no buttons

    await tester.tap(find.text('Accept').first);
    await settle(tester);
    expect(b.where('POST', '/recommendations/1').single.body, contains('"accept"'));

    await tester.tap(find.text('Modify').last);
    await settle(tester);
    await tester.enterText(find.byType(TextField).first, 'Point camera A at the park');
    await tester.tap(find.widgetWithText(FilledButton, 'Modify'));
    await settle(tester);
    final body = b.where('POST', '/recommendations/2').single.body;
    expect(body, contains('"modify"'));
    expect(body, contains('Point camera A at the park'));
  });
}
