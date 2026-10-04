import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_core/uavr_core.dart';
import 'package:uavr_maps/uavr_maps.dart';
import 'package:uavr_ui/uavr_ui.dart';

import '../common/console_map.dart';
import '../common/l10n.dart';
import '../common/labels.dart';
import '../common/run_action.dart';
import '../live/queue_controller.dart';
import 'queue_table.dart';

/// Split view: sortable queue table + case map. Keys: A acknowledge, ↑/↓ move, Enter open.
class QueuePage extends ConsumerStatefulWidget {
  const QueuePage({super.key});
  @override
  ConsumerState<QueuePage> createState() => _QueuePageState();
}

class _QueuePageState extends ConsumerState<QueuePage> {
  final _focus = FocusNode(debugLabel: 'queue');

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final q = ref.read(queueProvider.notifier);
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.arrowDown) {
      q.moveSelection(1);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.arrowUp) {
      q.moveSelection(-1);
      return KeyEventResult.handled;
    }
    final sel = ref.read(queueProvider).selected;
    if (k == LogicalKeyboardKey.keyA && sel != null) {
      if (sel.canAct && sel.state == CaseState.newCase) {
        runAction(context, () => q.acknowledge(sel.id), success: context.l.acknowledged(sel.caseNumber));
      }
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.enter && sel != null) {
      context.go('/cases/${sel.id}');
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(queueProvider);
    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _onKey,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _focus.requestFocus,
        child: Column(children: [
          const QueueFilters(),
          const Divider(height: 1),
          Expanded(
            child: LayoutBuilder(builder: (context, c) {
              final tableW = (c.maxWidth * 0.62).clamp(queueTableMinWidth, double.infinity).toDouble();
              final showMap = c.maxWidth - tableW >= 220;
              return Row(children: [
                SizedBox(width: showMap ? tableW : c.maxWidth, child: _body(s)),
                if (showMap) ...[
                  const VerticalDivider(width: 1),
                  const Expanded(child: QueueMap()),
                ],
              ]);
            }),
          ),
        ]),
      ),
    );
  }

  Widget _body(QueueState s) {
    if (s.error != null && s.cases.isEmpty) {
      return ErrorView(errorText(s.error!), onRetry: () => ref.read(queueProvider.notifier).reload());
    }
    if (s.loading && s.cases.isEmpty) return const LoadingView();
    return QueueTable(state: s);
  }
}

class QueueFilters extends ConsumerWidget {
  const QueueFilters({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final s = ref.watch(queueProvider);
    final q = ref.read(queueProvider.notifier);
    final me = ref.watch(meProvider).value!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(children: [
        SegmentedButton<String>(
          showSelectedIcon: false,
          segments: [
            if (me.desk != null) ButtonSegment(value: 'desk', label: Text(l.scopeDesk)),
            ButtonSegment(value: 'agency', label: Text(l.scopeAgency)),
            if (me.has('national')) ButtonSegment(value: 'all', label: Text(l.scopeAll)),
          ],
          selected: {s.scope},
          onSelectionChanged: (v) => q.setScope(v.first),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final st in CaseState.values.where((x) => x != CaseState.merged))
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(stateLabel(l, st)),
                    selected: s.states.contains(st),
                    onSelected: (_) => q.toggleState(st),
                  ),
                ),
            ]),
          ),
        ),
        Text(l.caseCount(s.cases.length)),
        IconButton(
          tooltip: l.refresh,
          onPressed: s.loading ? null : q.reload,
          icon: s.loading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.refresh),
        ),
        Tooltip(message: l.keyboardHelp, child: const Icon(Icons.keyboard_outlined, size: 20)),
      ]),
    );
  }
}

class QueueMap extends ConsumerStatefulWidget {
  const QueueMap({super.key});
  @override
  ConsumerState<QueueMap> createState() => _QueueMapState();
}

class _QueueMapState extends ConsumerState<QueueMap> {
  final _map = MapController();
  bool _fitted = false;

  void _fit(List<CaseSummary> cases) {
    try {
      fitTo(_map, [for (final c in cases) ?c.position], maxZoom: 13);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(queueProvider);
    if (!_fitted && s.cases.isNotEmpty) {
      _fitted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _fit(s.cases));
    }
    ref.listen(queueProvider.select((x) => x.selectedId), (_, id) {
      final c = ref.read(queueProvider).selected;
      if (c?.position != null) {
        try {
          _map.move(ll(c!.position!), _map.camera.zoom < 12 ? 12 : _map.camera.zoom);
        } catch (_) {}
      }
    });
    return Stack(children: [
      ConsoleMap(
        controller: _map,
        children: [
          CaseMarkersLayer(
            s.cases,
            selectedId: s.selectedId,
            onTap: (c) => ref.read(queueProvider.notifier).select(c.id),
          ),
        ],
      ),
      Positioned(
        right: 8,
        top: 8,
        child: Row(children: [
          MapZoomButtons(_map, heroTag: 'queue'),
          const SizedBox(width: 8),
          FloatingActionButton.small(
            heroTag: 'fit-queue',
            tooltip: context.l.fitAll,
            onPressed: () => _fit(s.cases),
            child: const Icon(Icons.fit_screen),
          ),
        ]),
      ),
    ]);
  }
}
