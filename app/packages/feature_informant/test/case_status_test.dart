import 'package:feature_informant/feature_informant.dart';
import 'package:feature_informant/src/screens/case_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uavr_core/uavr_core.dart';
import 'package:uavr_ui/uavr_ui.dart';

import 'fakes.dart';

const caseNumber = 'UAV-20261002-0100';
const token = '9a7e2c41-0000-4000-8000-000000000abc.s3cret';
const requestId = '5c1d7f00-1111-4222-8333-000000000001';

Map<String, dynamic> caseJson({String requestStatus = 'open'}) => {
      'case_number': caseNumber,
      'status': 'completed',
      'outcome_code': 'operator_penalised',
      'outcome_text': 'Operator identified and penalty issued.',
      'updated_at': '2026-10-02T09:30:00Z',
      'timeline': [
        {'status': 'received', 'at': '2026-10-02T08:00:00Z'},
        {'status': 'in_review', 'at': '2026-10-02T08:02:00Z'},
        {'status': 'in_progress', 'at': '2026-10-02T08:10:00Z'},
        {'status': 'completed', 'at': '2026-10-02T09:30:00Z'},
      ],
      'evidence_requests': [
        {
          'id': requestId,
          'template_code': 'video_flight_direction',
          'text': 'Please send a video showing the direction the drone flew.',
          'requested_kinds': ['video'],
          'status': requestStatus,
          'created_at': '2026-10-02T08:05:00Z',
        },
      ],
    };

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('case status shows the outcome and lets the informant answer an evidence request', (tester) async {
    tester.view.physicalSize = const Size(1200, 2700); // 400 x 900 logical: a phone
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await InformantStore().add(StoredReport(caseNumber: caseNumber, token: token, sentAt: DateTime.utc(2026, 10, 2, 8)));
    final uploads = FakeUploads();
    final backend = FakeBackend((r) async {
      if (r.url.path.endsWith('/v1/informant/cases')) {
        expect(r.headers['X-Report-Token'], token);
        return jsonResponse([caseJson()]);
      }
      if (r.url.path.endsWith('/v1/informant/evidence-requests/$requestId/responses')) {
        return jsonResponse([
          {'slot': 'video1', 'evidence_id': 'e9', 'upload_url': 'http://test/files/', 'upload_token': 't9'},
        ]);
      }
      return jsonResponse({'detail': 'not found'}, 404);
    });

    await tester.pumpWidget(ProviderScope(
      overrides: overridesFor(backend: backend, uploads: uploads),
      child: MaterialApp(
        theme: uavrTheme(),
        locale: const Locale('en'),
        supportedLocales: informantLocales,
        localizationsDelegates: const [
          InformantL10n.delegate,
          UavrL10n.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const CaseStatusScreen(caseNumber),
      ),
    ));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('Case $caseNumber'), findsOneWidget);
    expect(find.text('Operator identified and penalty issued.'), findsOneWidget);
    expect(find.text('Under review'), findsOneWidget);
    expect(find.text('Please send a video showing the direction the drone flew.'), findsOneWidget);
    final videoButton = find.widgetWithText(OutlinedButton, 'Video');
    expect(videoButton, findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Photo'), findsNothing);
    // Nothing on this screen ever asks the informant to approach the operator.
    expect(find.textContaining('operator', findRichText: true), findsNothing);

    await tester.ensureVisible(videoButton);
    await tester.pump();
    await tester.tap(videoButton);
    await tester.pump(const Duration(milliseconds: 100));
    final send = find.text('Send 1 file');
    await tester.ensureVisible(send);
    await tester.pump();
    await tester.tap(send);
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    final answers = backend.bodiesFor('POST', '/v1/informant/evidence-requests/$requestId/responses');
    expect(answers, hasLength(1));
    final media = (answers.single['media'] as List).single as Map;
    expect(media['slot'], 'video1');
    expect(media['kind'], 'video');
    expect(uploads.enqueued.single.caseNumber, caseNumber);
    expect(uploads.enqueued.single.slots, ['video1']);
  });
}
