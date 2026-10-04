import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:uavr_api/uavr_api.dart' hide TimeOfDay;
import 'package:uavr_core/uavr_core.dart';
import 'package:uavr_maps/uavr_maps.dart';
import 'package:uavr_ui/uavr_ui.dart';

import '../common/access.dart';
import '../common/console_map.dart';
import '../common/l10n.dart';
import '../common/run_action.dart';

typedef AlertFilter = ({bool closed, String? kind});

final maritimeAlertsProvider = FutureProvider.autoDispose
    .family<({List<MaritimeAlert> alerts, Map<String, int> counts}), AlertFilter>(
      (ref, f) =>
          ref.watch(staffApiProvider).maritimeAlerts(status: f.closed ? 'all' : 'open,acknowledged', kind: f.kind),
      retry: (_, _) => null,
    );
final maritimeAlertProvider = FutureProvider.autoDispose.family<MaritimeAlertDetail, int>(
  (ref, id) => ref.watch(staffApiProvider).maritimeAlert(id),
  retry: (_, _) => null,
);
final maritimeSettingsProvider = FutureProvider.autoDispose<List<AnomalySettingItem>>(
  (ref) => ref.watch(staffApiProvider).maritimeSettings(),
  retry: (_, _) => null,
);
final maritimeEvaluationProvider = FutureProvider.autoDispose<AnomalyEvaluation?>(
  (ref) => ref.watch(staffApiProvider).maritimeEvaluation(),
  retry: (_, _) => null,
);

const alertKinds = ['zone_entry', 'gap', 'cluster', 'stop', 'deviation', 'approach', 'statistical'];

String kindLabel(AgencyL10n l, String k) => switch (k) {
  'stop' => l.kindStop,
  'deviation' => l.kindDeviation,
  'cluster' => l.kindCluster,
  'zone_entry' => l.kindZoneEntry,
  'approach' => l.kindApproach,
  'gap' => l.kindGap,
  'statistical' => l.kindStatistical,
  _ => k,
};

String methodLabel(AgencyL10n l, String m) => switch (m) {
  'rules' => l.methodRules,
  'stat' || 'statistical' => l.methodStat,
  'both' => l.methodBoth,
  'combined' => l.evalCombined,
  _ => m,
};

String statusLabel(AgencyL10n l, String s) => switch (s) {
  'open' || 'reopened' => s == 'open' ? l.maritimeStatusOpen : l.maritimeStatusReopened,
  'acknowledged' => l.maritimeStatusAcknowledged,
  'false_alarm' => l.maritimeStatusFalseAlarm,
  'dismissed' => l.maritimeStatusDismissed,
  'escalated' => l.maritimeStatusEscalated,
  'detected' => l.eventDetected,
  'updated' => l.eventUpdated,
  'note' => l.eventNote,
  _ => s,
};

String sourceLabel(AgencyL10n l, String s) => switch (s) {
  'sim' => l.maritimeSourceSim,
  'atreides' => l.maritimeSourceAtreides,
  _ => s,
};

Color scoreColor(int score) => score >= 70
    ? UavrColors.critical
    : score >= 50
    ? const Color(0xFFEF6C00)
    : const Color(0xFFB28704);

String fmtTime(BuildContext context, DateTime? t) {
  if (t == null) return '–';
  final loc = MaterialLocalizations.of(context);
  final lt = t.toLocal();
  return '${loc.formatShortMonthDay(lt)} ${loc.formatTimeOfDay(TimeOfDay.fromDateTime(lt), alwaysUse24HourFormat: true)}';
}

/// Maritime behaviour alerts: review queue, thresholds, and the rules-vs-statistics comparison.
class MaritimePage extends ConsumerWidget {
  const MaritimePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final t = Theme.of(context);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.maritimeTitle, style: t.textTheme.titleLarge),
                  const SizedBox(height: 2),
                  Text(
                    l.maritimeSubtitle,
                    style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(text: l.tabAlerts),
                Tab(text: l.tabThresholds),
                Tab(text: l.tabEvaluation),
              ],
            ),
            const Divider(height: 1),
            const Expanded(
              child: TabBarView(
                physics: NeverScrollableScrollPhysics(),
                children: [_AlertsTab(), _ThresholdsTab(), _EvaluationTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ alerts

class _AlertsTab extends ConsumerStatefulWidget {
  const _AlertsTab();
  @override
  ConsumerState<_AlertsTab> createState() => _AlertsTabState();
}

class _AlertsTabState extends ConsumerState<_AlertsTab> {
  AlertFilter _f = (closed: false, kind: null);
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final data = ref.watch(maritimeAlertsProvider(_f));
    final list = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 240,
                child: DropdownButton<String?>(
                  value: _f.kind,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l.maritimeAllKinds, overflow: TextOverflow.ellipsis)),
                    for (final k in alertKinds)
                      DropdownMenuItem(value: k, child: Text(kindLabel(l, k), overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (v) => setState(() => _f = (closed: _f.closed, kind: v)),
                ),
              ),
              FilterChip(
                label: Text(l.maritimeShowClosed),
                selected: _f.closed,
                onSelected: (v) => setState(() => _f = (closed: v, kind: _f.kind)),
              ),
              IconButton(
                tooltip: l.refresh,
                icon: const Icon(Icons.refresh),
                onPressed: () => ref.invalidate(maritimeAlertsProvider(_f)),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: switch (data) {
            AsyncData(:final value) when value.alerts.isEmpty => Center(child: Text(l.maritimeNone)),
            AsyncData(:final value) => ListView.separated(
              itemCount: value.alerts.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) => _AlertTile(
                value.alerts[i],
                selected: value.alerts[i].id == _selected,
                onTap: () => setState(() => _selected = value.alerts[i].id),
              ),
            ),
            AsyncError(:final error) => ErrorView(error, onRetry: () => ref.invalidate(maritimeAlertsProvider(_f))),
            _ => const LoadingView(),
          },
        ),
      ],
    );
    final detail = _selected == null
        ? Center(child: Text(l.maritimeSelect))
        : _AlertDetail(_selected!, onChanged: () => ref.invalidate(maritimeAlertsProvider(_f)));
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 1000) {
          return _selected == null
              ? list
              : Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => setState(() => _selected = null),
                        icon: const Icon(Icons.arrow_back),
                        label: Text(l.tabAlerts),
                      ),
                    ),
                    Expanded(child: detail),
                  ],
                );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: 440, child: list),
            const VerticalDivider(width: 1),
            Expanded(child: detail),
          ],
        );
      },
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile(this.a, {required this.selected, required this.onTap});
  final MaritimeAlert a;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return ListTile(
      selected: selected,
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: scoreColor(a.score),
        foregroundColor: Colors.white,
        child: Text('${a.score}', style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      title: Text(a.kinds.map((k) => kindLabel(l, k)).join(' · '), maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${sourceLabel(l, a.sourceId)} · ${a.trackId} · ${fmtTime(context, a.lastAt)} · ${methodLabel(l, a.method)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: a.status == 'open' ? null : Pill(statusLabel(l, a.status)),
    );
  }
}

class _AlertDetail extends ConsumerWidget {
  const _AlertDetail(this.id, {required this.onChanged});
  final int id;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final d = ref.watch(maritimeAlertProvider(id));
    final me = ref.watch(meProvider).value;
    return switch (d) {
      AsyncData(:final value) => _body(context, ref, l, value, me),
      AsyncError(:final error) => ErrorView(error, onRetry: () => ref.invalidate(maritimeAlertProvider(id))),
      _ => const LoadingView(),
    };
  }

  Widget _body(BuildContext context, WidgetRef ref, AgencyL10n l, MaritimeAlertDetail d, Me? me) {
    final a = d.alert;
    final t = Theme.of(context);
    final api = ref.read(staffApiProvider);
    final canDecide = me != null && canDecideMaritime(me);

    Future<void> act(Future<void> Function() f) async {
      await runAction(context, f);
      ref.invalidate(maritimeAlertProvider(id));
      onChanged();
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(d.vesselName ?? a.trackId, style: t.textTheme.titleLarge),
            Pill(l.maritimeRisk(a.score), color: scoreColor(a.score)),
            Pill(methodLabel(l, a.method)),
            Pill(l.maritimeQuality((a.confidence * 100).round())),
            Pill(statusLabel(l, a.status)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          [
            sourceLabel(l, a.sourceId),
            if (d.mmsi != null) 'MMSI ${d.mmsi}' else a.trackId,
            '${fmtTime(context, a.firstAt)} → ${fmtTime(context, a.lastAt)}',
          ].join(' · '),
          style: t.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 340,
          child: ClipRRect(borderRadius: BorderRadius.circular(12), child: _AlertMap(d)),
        ),
        const SizedBox(height: 16),
        Section(
          title: l.maritimeWhy,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, r) in a.reasons.indexed)
                ListTile(
                  dense: true,
                  leading: CircleAvatar(radius: 13, child: Text('${i + 1}', style: const TextStyle(fontSize: 12))),
                  title: Text('${kindLabel(l, r.code)}: ${r.text}'),
                  subtitle: Text(
                    [
                      if (r.at != null) fmtTime(context, r.at),
                      if (r.value != null && r.threshold != null) l.maritimeValue(_num(r.value!), _num(r.threshold!)),
                    ].join(' · '),
                  ),
                ),
            ],
          ),
        ),
        if (a.uncertainty.isNotEmpty)
          Section(
            title: l.maritimeUncertainty,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final u in a.uncertainty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.help_outline, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(u)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        if (canDecide)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (a.status == 'open')
                  FilledButton.icon(
                    onPressed: () => act(() => api.maritimeDecide(a.id, 'acknowledged')),
                    icon: const Icon(Icons.check),
                    label: Text(l.maritimeAck),
                  ),
                if (a.isOpen) ...[
                  OutlinedButton.icon(
                    onPressed: () async {
                      final r = await _falseAlarmDialog(context, l);
                      if (r != null) {
                        await act(() => api.maritimeDecide(a.id, 'false_alarm', note: r.note, suppressHours: r.hours));
                      }
                    },
                    icon: const Icon(Icons.block),
                    label: Text(l.maritimeFalseAlarm),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => act(() => api.maritimeDecide(a.id, 'dismissed')),
                    icon: const Icon(Icons.close),
                    label: Text(l.maritimeDismiss),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => act(() => api.maritimeEscalate(a.id)),
                    icon: const Icon(Icons.assignment_late_outlined),
                    label: Text(l.maritimeEscalate),
                  ),
                ],
                if (a.status == 'false_alarm' || a.status == 'dismissed')
                  OutlinedButton.icon(
                    onPressed: () => act(() => api.maritimeDecide(a.id, 'open')),
                    icon: const Icon(Icons.undo),
                    label: Text(l.maritimeReopen),
                  ),
                if (a.caseId != null)
                  FilledButton.icon(
                    onPressed: () => context.go('/cases/${a.caseId}'),
                    icon: const Icon(Icons.open_in_new),
                    label: Text(l.maritimeOpenCase),
                  ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final text = await _noteDialog(context, l);
                    if (text != null && text.trim().isNotEmpty) await act(() => api.maritimeNote(a.id, text.trim()));
                  },
                  icon: const Icon(Icons.note_add_outlined),
                  label: Text(l.maritimeAddNote),
                ),
              ],
            ),
          ),
        Section(
          title: l.maritimeTimeline,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final e in d.events)
                ListTile(
                  dense: true,
                  leading: Icon(switch (e.action) {
                    'detected' => Icons.radar,
                    'updated' => Icons.trending_up,
                    'note' => Icons.sticky_note_2_outlined,
                    'escalated' => Icons.assignment_late_outlined,
                    'false_alarm' => Icons.block,
                    _ => Icons.check_circle_outline,
                  }),
                  title: Text(
                    [
                      statusLabel(l, e.action),
                      if (e.actor != null) e.actor!,
                      if (e.detail['score'] != null) l.maritimeRisk(toInt(e.detail['score']) ?? 0),
                    ].join(' · '),
                  ),
                  subtitle: Text(
                    [
                      fmtTime(context, e.at),
                      if (e.detail['note'] != null) '${e.detail['note']}',
                      if (e.detail['text'] != null) '${e.detail['text']}',
                    ].join(' · '),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  static String _num(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}

int? toInt(Object? v) => v is num ? v.toInt() : null;

class _AlertMap extends StatefulWidget {
  const _AlertMap(this.d);
  final MaritimeAlertDetail d;

  @override
  State<_AlertMap> createState() => _AlertMapState();
}

class _AlertMapState extends State<_AlertMap> {
  final _map = MapController();

  @override
  Widget build(BuildContext context) {
    final d = widget.d;
    final a = d.alert;
    final pts = [for (final p in d.track) ll(p.p)];
    return Stack(children: [
      _mapView(context, d, a, pts),
      Positioned(right: 8, top: 8, child: MapZoomButtons(_map, heroTag: 'maritime')),
    ]);
  }

  Widget _mapView(BuildContext context, MaritimeAlertDetail d, MaritimeAlert a, List<LatLng> pts) {
    return ConsoleMap(
      controller: _map,
      initialCenter: ll(a.position),
      initialZoom: 9,
      children: [
        PolygonLayer(
          polygons: [
            for (final z in d.zones)
              for (final ring in z.rings)
                Polygon(
                  points: ring.map(ll).toList(),
                  color: UavrColors.zone(z.zoneType).withValues(alpha: 0.25),
                  borderColor: UavrColors.zone(z.zoneType),
                  borderStrokeWidth: 2,
                ),
          ],
        ),
        if (pts.length > 1)
          PolylineLayer(
            polylines: [
              Polyline(
                points: pts,
                strokeWidth: 3,
                color: const Color(0xFF1565C0),
                borderStrokeWidth: 1,
                borderColor: Colors.white,
              ),
            ],
          ),
        CircleLayer(
          circles: [for (final p in pts) CircleMarker(point: p, radius: 2.5, color: const Color(0xFF1565C0))],
        ),
        MarkerLayer(
          markers: [
            for (final (i, r) in a.reasons.indexed)
              if (r.position != null)
                Marker(
                  point: ll(r.position!),
                  width: 26,
                  height: 26,
                  child: CircleAvatar(
                    backgroundColor: scoreColor(a.score),
                    foregroundColor: Colors.white,
                    child: Text('${i + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
          ],
        ),
      ],
    );
  }
}

Future<({String? note, double? hours})?> _falseAlarmDialog(BuildContext context, AgencyL10n l) {
  final note = TextEditingController();
  final hours = TextEditingController(text: '24');
  return showDialog<({String? note, double? hours})>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.maritimeFalseAlarmTitle),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: note,
              maxLines: 3,
              decoration: InputDecoration(labelText: l.maritimeNoteHint),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: hours,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l.maritimeSuppressHours),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel)),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, (
            note: note.text.trim().isEmpty ? null : note.text.trim(),
            hours: double.tryParse(hours.text.trim()),
          )),
          child: Text(l.maritimeFalseAlarm),
        ),
      ],
    ),
  );
}

Future<String?> _noteDialog(BuildContext context, AgencyL10n l) {
  final c = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.maritimeAddNote),
      content: SizedBox(
        width: 420,
        child: TextField(
          controller: c,
          maxLines: 4,
          autofocus: true,
          decoration: InputDecoration(labelText: l.maritimeNoteHint),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel)),
        FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: Text(l.maritimeAddNote)),
      ],
    ),
  );
}

// ------------------------------------------------------------------ thresholds

class _ThresholdsTab extends ConsumerStatefulWidget {
  const _ThresholdsTab();
  @override
  ConsumerState<_ThresholdsTab> createState() => _ThresholdsTabState();
}

class _ThresholdsTabState extends ConsumerState<_ThresholdsTab> {
  final _edits = <String, TextEditingController>{};

  @override
  void dispose() {
    for (final c in _edits.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final me = ref.watch(meProvider).value;
    final canTune = me != null && canTuneMaritime(me);
    final zh = context.lang == 'zh-TW';
    return switch (ref.watch(maritimeSettingsProvider)) {
      AsyncData(:final value) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (!canTune) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(l.maritimeReadOnly)),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: [
                for (final s in value)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(child: Text(zh ? s.labelZh : s.labelEn)),
                        SizedBox(
                          width: 140,
                          child: TextField(
                            enabled: canTune,
                            controller: _edits.putIfAbsent(s.key, () => TextEditingController(text: _fmt(s.value))),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              isDense: true,
                              suffixText: s.unit,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 120,
                          child: Text(
                            l.maritimeDefault(_fmt(s.defaultValue)),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                if (canTune)
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.save_outlined),
                      label: Text(l.maritimeSave),
                      onPressed: () async {
                        final changed = <String, double>{};
                        for (final s in value) {
                          final v = double.tryParse(_edits[s.key]?.text.trim() ?? '');
                          if (v != null && v != s.value) changed[s.key] = v;
                        }
                        if (changed.isEmpty) return;
                        final r = await runAction(
                          context,
                          () => ref.read(staffApiProvider).saveMaritimeSettings(changed),
                          success: l.maritimeSaved,
                        );
                        if (r != null) {
                          for (final c in _edits.values) {
                            c.dispose();
                          }
                          _edits.clear();
                          ref.invalidate(maritimeSettingsProvider);
                          ref.invalidate(maritimeAlertsProvider);
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      AsyncError(:final error) => ErrorView(error, onRetry: () => ref.invalidate(maritimeSettingsProvider)),
      _ => const LoadingView(),
    };
  }

  static String _fmt(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : '$v';
}

// ------------------------------------------------------------------ evaluation

class _EvaluationTab extends ConsumerWidget {
  const _EvaluationTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final me = ref.watch(meProvider).value;
    final canTune = me != null && canTuneMaritime(me);
    final ev = ref.watch(maritimeEvaluationProvider);
    final actions = canTune
        ? Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh),
                label: Text(l.evalRun),
                onPressed: () async {
                  await runAction(context, () => ref.read(staffApiProvider).runMaritimeEvaluation());
                  ref.invalidate(maritimeEvaluationProvider);
                },
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.auto_awesome_motion_outlined),
                label: Text(l.evalResimulate),
                onPressed: () async {
                  await runAction(context, () => ref.read(staffApiProvider).runMaritimeEvaluation(resimulate: true));
                  ref.invalidate(maritimeEvaluationProvider);
                  ref.invalidate(maritimeAlertsProvider);
                },
              ),
            ],
          )
        : const SizedBox.shrink();
    return switch (ev) {
      AsyncData(value: null) => ListView(
        padding: const EdgeInsets.all(20),
        children: [Text(l.evalNone), const SizedBox(height: 12), actions],
      ),
      AsyncData(:final value?) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(l.evalIntro(value.tracks, value.anomalous)),
          const SizedBox(height: 4),
          Text(l.evalRanAt(fmtTime(context, value.createdAt)), style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          _MetricsTable(value),
          const SizedBox(height: 24),
          Text(l.evalByKind, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _ByKindTable(value),
          const SizedBox(height: 20),
          actions,
        ],
      ),
      AsyncError(:final error) => ErrorView(error, onRetry: () => ref.invalidate(maritimeEvaluationProvider)),
      _ => const LoadingView(),
    };
  }
}

const _methods = ['rules', 'statistical', 'combined'];

class _MetricsTable extends StatelessWidget {
  const _MetricsTable(this.ev);
  final AnomalyEvaluation ev;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    String pct(double v) => '${(v * 100).round()}%';
    final best = _methods
        .where(ev.results.containsKey)
        .reduce((a, b) => ev.results[a]!.f1 >= ev.results[b]!.f1 ? a : b);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text(l.evalMethod)),
          DataColumn(label: Text(l.evalPrecision), numeric: true),
          DataColumn(label: Text(l.evalRecall), numeric: true),
          DataColumn(label: Text(l.evalF1), numeric: true),
          DataColumn(label: Text(l.evalFalseAlarms), numeric: true),
        ],
        rows: [
          for (final m in _methods)
            if (ev.results[m] case final r?)
              DataRow(
                selected: m == best,
                cells: [
                  DataCell(Text(methodLabel(l, m), style: TextStyle(fontWeight: m == best ? FontWeight.w700 : null))),
                  DataCell(Text(pct(r.precision))),
                  DataCell(Text(pct(r.recall))),
                  DataCell(Text(r.f1.toStringAsFixed(2))),
                  DataCell(Text(r.falseAlarmsPer100.toStringAsFixed(1))),
                ],
              ),
        ],
      ),
    );
  }
}

class _ByKindTable extends StatelessWidget {
  const _ByKindTable(this.ev);
  final AnomalyEvaluation ev;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final kinds = {for (final r in ev.results.values) ...r.byKind.keys}.toList()..sort();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text(l.evalMethod)),
          for (final k in kinds) DataColumn(label: Text(kindLabel(l, k)), numeric: true),
        ],
        rows: [
          for (final m in _methods)
            if (ev.results[m] case final r?)
              DataRow(
                cells: [
                  DataCell(Text(methodLabel(l, m))),
                  for (final k in kinds)
                    DataCell(Text(r.byKind[k] == null ? '–' : '${r.byKind[k]!.found}/${r.byKind[k]!.tracks}')),
                ],
              ),
        ],
      ),
    );
  }
}
