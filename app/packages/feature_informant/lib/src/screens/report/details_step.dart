import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uavr_ui/uavr_ui.dart';

import '../../l10n/informant_localizations.dart';
import '../../services/interview.dart';
import '../../widgets/common.dart';
import 'report_controller.dart';

/// Optional structured interview (served by the backend) plus aerial quick facts and a description.
class DetailsStep extends ConsumerStatefulWidget {
  const DetailsStep({super.key});

  @override
  ConsumerState<DetailsStep> createState() => _DetailsStepState();
}

class _DetailsStepState extends ConsumerState<DetailsStep> {
  late final _description = TextEditingController(text: ref.read(reportFlowProvider).description);

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final d = ref.watch(reportFlowProvider);
    final flow = ref.read(reportFlowProvider.notifier);
    final iv = ref.watch(interviewProvider(apiLanguage(Localizations.localeOf(context)))).value;
    final aerial = d.domain == 'aerial';
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text(l.detailsTitle, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 4),
      Text(l.detailsOptional),
      // Server-defined interview (domain first, then branch-specific questions). Without it
      // (first run offline) only the aerial quick facts below are asked.
      if (iv != null)
        for (final q in iv.visible(d.answers))
          _Question(
            q.label,
            child: _Choices<String>(
              options: {for (final o in q.options) o.value: o.label},
              selected: d.answers[q.id],
              onSelected: (v) => flow.answer(iv, q.id, v),
            ),
          ),
      if (aerial)
        _Question(
          l.detailsHeight,
          hint: l.detailsHeightHint,
          child: _Choices<HeightBand>(
            options: {for (final h in HeightBand.values) h: _heightLabel(l, h)},
            selected: d.height,
            onSelected: flow.setHeight,
          ),
        ),
      if (aerial)
        _Question(
          l.detailsMovement,
          child: _Choices<String>(
            options: {'hovering': l.movementHovering, 'moving': l.movementMoving, 'unknown': l.notSure},
            selected: d.movement,
            onSelected: flow.setMovement,
          ),
        ),
      if (iv == null)
        _Question(
          l.detailsCount,
          child: _Choices<int>(
            options: {1: l.countOne, 2: l.countTwo, 3: l.countThreePlus},
            selected: d.droneCount,
            onSelected: flow.setDroneCount,
          ),
        ),
      _Question(
        l.detailsDescription,
        child: TextField(
          controller: _description,
          maxLength: 1000,
          minLines: 2,
          maxLines: 5,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(hintText: l.detailsDescriptionHint),
          onChanged: flow.setDescription,
        ),
      ),
    ]);
  }
}

String _heightLabel(InformantL10n l, HeightBand h) => switch (h) {
      HeightBand.below30 => l.heightBelow30,
      HeightBand.from30to60 => l.height30to60,
      HeightBand.from60to120 => l.height60to120,
      HeightBand.above120 => l.heightAbove120,
      HeightBand.unknown => l.notSure,
    };

class _Question extends StatelessWidget {
  const _Question(this.title, {required this.child, this.hint});
  final String title;
  final String? hint;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          if (hint != null) Text(hint!, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          child,
        ]),
      );
}

/// Large single-choice chips; tapping the selected chip clears it.
class _Choices<T> extends StatelessWidget {
  const _Choices({required this.options, required this.selected, required this.onSelected});
  final Map<T, String> options;
  final T? selected;
  final ValueChanged<T?> onSelected;

  @override
  Widget build(BuildContext context) => Wrap(spacing: 8, runSpacing: 8, children: [
        for (final e in options.entries)
          ChoiceChip(
            label: Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(e.value)),
            selected: selected == e.key,
            onSelected: (on) => onSelected(on ? e.key : null),
          ),
      ]);
}
