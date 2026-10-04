import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_ui/uavr_ui.dart';

import '../common/l10n.dart';
import '../common/labels.dart';
import '../live/queue_controller.dart';

const queueTableMinWidth = 820.0;

class _Col {
  const _Col(this.width, this.sort);
  final double width;
  final QueueSort? sort;
}

const _cols = [
  _Col(84, QueueSort.severity),
  _Col(168, QueueSort.caseNumber),
  _Col(96, QueueSort.state),
  _Col(72, null), // ack countdown
  _Col(56, QueueSort.age),
  _Col(72, QueueSort.observations),
  _Col(56, QueueSort.confidence),
  _Col(56, null), // icons
];

class QueueTable extends ConsumerWidget {
  const QueueTable({super.key, required this.state});
  final QueueState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final rows = state.sorted;
    final headers = [
      l.colSeverity,
      l.colCase,
      l.colState,
      l.colAck,
      l.colAge,
      l.colObservations,
      l.colConfidence,
      l.colSignals,
    ];
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth < queueTableMinWidth ? queueTableMinWidth : c.maxWidth;
      final table = SizedBox(
        width: w,
        child: Column(children: [
          _Header(headers: headers, state: state),
          const Divider(height: 1),
          Expanded(
            child: rows.isEmpty
                ? EmptyView(l.queueEmpty)
                : ListView.builder(
                    itemCount: rows.length,
                    itemExtent: 48,
                    itemBuilder: (_, i) => QueueRow(
                      key: ValueKey(rows[i].id),
                      c: rows[i],
                      selected: rows[i].id == state.selectedId,
                      highlighted: state.highlighted.contains(rows[i].id),
                    ),
                  ),
          ),
        ]),
      );
      if (c.maxWidth >= queueTableMinWidth) return table;
      return SingleChildScrollView(scrollDirection: Axis.horizontal, child: table);
    });
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.headers, required this.state});
  final List<String> headers;
  final QueueState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700);
    Widget cell(int i) {
      final col = _cols[i];
      final active = col.sort != null && state.sort == col.sort;
      return SizedBox(
        width: col.width,
        child: InkWell(
          onTap: col.sort == null ? null : () => ref.read(queueProvider.notifier).setSort(col.sort!),
          child: Row(children: [
            Flexible(child: Text(headers[i], style: t, overflow: TextOverflow.ellipsis)),
            if (active) Icon(state.ascending ? Icons.arrow_upward : Icons.arrow_downward, size: 14),
          ]),
        ),
      );
    }

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Row(children: [
        for (var i = 0; i < _cols.length; i++) cell(i),
        Expanded(child: Text(context.l.colAuthorization, style: t)),
      ]),
    );
  }
}

class QueueRow extends ConsumerWidget {
  const QueueRow({super.key, required this.c, required this.selected, required this.highlighted});
  final CaseSummary c;
  final bool selected, highlighted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final scheme = Theme.of(context).colorScheme;
    final muted = TextStyle(color: scheme.onSurfaceVariant);
    final bg = selected
        ? scheme.primaryContainer
        : highlighted
            ? UavrColors.severity(c.severity).withValues(alpha: 0.16)
            : null;
    Widget cell(int i, Widget child) => SizedBox(width: _cols[i].width, child: Align(alignment: Alignment.centerLeft, child: child));
    final row = Row(children: [
      cell(0, SeverityChip(c.severity, compact: true)),
      cell(
        1,
        Row(children: [
          if (c.redacted) ...[const Icon(Icons.lock_outline, size: 14), const SizedBox(width: 4)],
          if (highlighted) ...[
            Icon(Icons.notifications_active, size: 14, color: UavrColors.severity(c.severity)),
            const SizedBox(width: 4),
          ],
          if (c.craftDomain != 'aerial') ...[
            Tooltip(message: domainLabel(l, c.craftDomain), child: Icon(domainIcon(c.craftDomain), size: 14)),
            const SizedBox(width: 4),
          ],
          if (c.isDarkVessel) ...[
            Tooltip(message: l.darkVessel, child: const Icon(Icons.portable_wifi_off, size: 14, color: UavrColors.critical)),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(c.caseNumber,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600, fontFeatures: [FontFeature.tabularFigures()])),
          ),
        ]),
      ),
      cell(2, Text(stateLabel(l, c.state), style: TextStyle(color: stateColor(c.state), fontWeight: FontWeight.w600))),
      cell(3, c.state == CaseState.newCase && c.ackDeadline != null ? Countdown(c.ackDeadline!) : Text('—', style: muted)),
      cell(4, Text(ageLabel(c.createdAt ?? c.firstSeen), style: muted)),
      cell(5, Text(c.redacted ? '—' : '${c.observationCount} / ${c.distinctInformants}')),
      cell(6, Text(c.redacted ? '—' : '${(c.confidence * 100).round()}%')),
      cell(
        7,
        c.redacted
            ? Tooltip(message: l.redactedRow, child: const Icon(Icons.lock, size: 16, color: UavrColors.redacted))
            : Row(children: [
                if (c.sensorConfirmed)
                  Tooltip(message: l.sensorConfirmed, child: const Icon(Icons.sensors, size: 16, color: UavrColors.brand)),
                if (c.remoteIdSerials.isNotEmpty)
                  Tooltip(
                    message: '${l.remoteId}: ${c.remoteIdSerials.join(', ')}',
                    child: const Icon(Icons.settings_input_antenna, size: 16, color: UavrColors.zoneInfra),
                  ),
              ]),
      ),
      Expanded(
        child: c.redacted
            ? Text(l.redactedShort, style: muted, overflow: TextOverflow.ellipsis)
            : Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Pill(authorizationLabel(l, c.authorization), color: authorizationColor(c.authorization)),
                ),
              ),
      ),
      if (!c.canAct && !c.redacted)
        Tooltip(message: l.readOnly, child: Icon(Icons.visibility_outlined, size: 16, color: scheme.outline)),
      IconButton(
        tooltip: l.open,
        visualDensity: VisualDensity.compact,
        icon: const Icon(Icons.chevron_right),
        onPressed: () => context.go('/cases/${c.id}'),
      ),
    ]);
    return Material(
      color: bg ?? Colors.transparent,
      child: InkWell(
        onTap: () => ref.read(queueProvider.notifier).select(c.id),
        onDoubleTap: () => context.go('/cases/${c.id}'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: scheme.outlineVariant, width: 0.5))),
          child: Opacity(opacity: c.redacted ? 0.55 : 1, child: row),
        ),
      ),
    );
  }
}
