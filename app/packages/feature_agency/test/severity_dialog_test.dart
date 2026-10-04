import 'package:feature_agency/src/case/dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  testWidgets('downgrade refuses an empty reason', (tester) async {
    ({int level, String reason})? result;
    var closed = false;
    await pumpLocalized(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            result = await showDialog<({int level, String reason})>(
                context: context, builder: (_) => const SeverityDialog(current: 3));
            closed = true;
          },
          child: const Text('go'),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('sev-1')));
    await tester.pumpAndSettle();
    expect(find.textContaining('only ever raises severity'), findsOneWidget);

    await tester.tap(find.byKey(const Key('dialog-confirm')));
    await tester.pumpAndSettle();
    expect(closed, isFalse);
    expect(find.text('Lowering severity requires a reason'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('severity-reason')), '   ');
    await tester.tap(find.byKey(const Key('dialog-confirm')));
    await tester.pumpAndSettle();
    expect(closed, isFalse);

    await tester.enterText(find.byKey(const Key('severity-reason')), 'Toy drone, owner on scene');
    await tester.tap(find.byKey(const Key('dialog-confirm')));
    await tester.pumpAndSettle();
    expect(closed, isTrue);
    expect(result?.level, 1);
    expect(result?.reason, 'Toy drone, owner on scene');
  });

  testWidgets('upgrade needs no reason', (tester) async {
    ({int level, String reason})? result;
    await pumpLocalized(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () async => result = await showDialog<({int level, String reason})>(
              context: context, builder: (_) => const SeverityDialog(current: 1)),
          child: const Text('go'),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sev-3')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dialog-confirm')));
    await tester.pumpAndSettle();
    expect(result?.level, 3);
  });
}
