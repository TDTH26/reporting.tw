import 'dart:async';

import 'package:flutter/material.dart';
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
import '../common/providers.dart';
import '../common/run_action.dart';

/// Live map state: REST snapshot every 10 s, case updates applied from live events in between.
class LiveMapController extends Notifier<AsyncValue<LiveMap>> {
  Timer? _timer, _debounce;
  StreamSubscription<LiveMessage>? _sub;

  @override
  AsyncValue<LiveMap> build() {
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => refresh());
    _sub = ref.read(liveChannelProvider).events.listen(_onLive);
    ref.onDispose(() {
      _timer?.cancel();
      _debounce?.cancel();
      _sub?.cancel();
    });
    Future.microtask(refresh);
    return const AsyncLoading();
  }

  Future<void> refresh() async {
    try {
      final m = await ref.read(staffApiProvider).liveMap();
      if (ref.mounted) state = AsyncData(m);
    } catch (e, st) {
      if (ref.mounted && state.value == null) state = AsyncError(e, st);
    }
  }

  void _onLive(LiveMessage m) {
    final raw = m.payload['case'];
    final cur = state.value;
    if (m.type == 'resync_required') {
      refresh();
      return;
    }
    if (raw is! Map || cur == null) return;
    final c = CaseSummary.fromJson(Map<String, dynamic>.from(raw));
    final cases = [...cur.cases.where((x) => x.id != c.id), if (m.kind != 'case.merged') c];
    state = AsyncData(LiveMap(cases: cases, aircraft: cur.aircraft, fieldOfficers: cur.fieldOfficers));
  }
}

final videoFeedsProvider = FutureProvider.autoDispose<List<VideoFeedInfo>>((ref) => ref.watch(staffApiProvider).videoFeeds());

final liveMapProvider = NotifierProvider.autoDispose<LiveMapController, AsyncValue<LiveMap>>(LiveMapController.new);

class LiveMapPage extends ConsumerStatefulWidget {
  const LiveMapPage({super.key});
  @override
  ConsumerState<LiveMapPage> createState() => _LiveMapPageState();
}

class _LiveMapPageState extends ConsumerState<LiveMapPage> {
  final _map = MapController();
  bool _zones = true, _aircraft = true, _officers = true, _closed = false, _vessels = true, _cameras = true;
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final s = ref.watch(liveMapProvider);
    final zones = _zones ? (ref.watch(staffZonesProvider).value ?? const <Zone>[]) : const <Zone>[];
    final m = s.value;
    final cases = (m?.cases ?? const <CaseSummary>[]).where((c) => _closed || c.state.isOpen).toList();
    final sel = cases.where((c) => c.id == _selected).firstOrNull;
    final officers = (m?.fieldOfficers ?? const <FieldOfficerRef>[]).where((o) => o.lastPosition != null).toList();
    return Row(children: [
      Expanded(
        child: Stack(children: [
          ConsoleMap(
            controller: _map,
            onTap: (_) => setState(() => _selected = null),
            children: [
              if (_zones) ZonesLayer(zones),
              if (_vessels) VesselsLayer(m?.vessels ?? const []),
              if (_cameras) CamerasLayer(ref.watch(videoFeedsProvider).value ?? const []),
              if (_aircraft) AircraftLayer(m?.aircraft ?? const []),
              if (_officers && officers.isNotEmpty)
                PointsLayer([for (final o in officers) o.lastPosition!],
                    icon: Icons.local_police, color: UavrColors.brand, labels: [for (final o in officers) o.displayName]),
              CaseMarkersLayer(cases, selectedId: _selected, onTap: (c) => setState(() => _selected = c.id)),
            ],
          ),
          Positioned(
            left: 12,
            top: 12,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Wrap(spacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  FilterChip(label: Text(l.layerZones), selected: _zones, onSelected: (v) => setState(() => _zones = v)),
                  FilterChip(label: Text(l.layerAircraft), selected: _aircraft, onSelected: (v) => setState(() => _aircraft = v)),
                  FilterChip(label: Text(l.layerOfficers), selected: _officers, onSelected: (v) => setState(() => _officers = v)),
                  FilterChip(label: Text(l.layerVessels), selected: _vessels, onSelected: (v) => setState(() => _vessels = v)),
                  FilterChip(label: Text(l.layerCameras), selected: _cameras, onSelected: (v) => setState(() => _cameras = v)),
                  FilterChip(label: Text(l.layerRecentClosed), selected: _closed, onSelected: (v) => setState(() => _closed = v)),
                  Text(l.liveMapCounts(cases.length, m?.aircraft.length ?? 0, officers.length)),
                  if (s.hasError) Tooltip(message: errorText(s.error!), child: const Icon(Icons.error_outline, color: UavrColors.critical)),
                  IconButton(
                    tooltip: l.fitAll,
                    icon: const Icon(Icons.fit_screen),
                    onPressed: () {
                      try {
                        fitTo(_map, [for (final c in cases) ?c.position], maxZoom: 13);
                      } catch (_) {}
                    },
                  ),
                  IconButton(key: const Key('zoom-in'), tooltip: l.zoomIn, icon: const Icon(Icons.zoom_in), onPressed: () => zoomMap(_map, 1)),
                  IconButton(key: const Key('zoom-out'), tooltip: l.zoomOut, icon: const Icon(Icons.zoom_out), onPressed: () => zoomMap(_map, -1)),
                ]),
              ),
            ),
          ),
          if (s.isLoading && m == null) const Center(child: CircularProgressIndicator()),
        ]),
      ),
      if (sel != null) ...[
        const VerticalDivider(width: 1),
        SizedBox(width: 320, child: _SidePanel(c: sel, onClose: () => setState(() => _selected = null))),
      ],
    ]);
  }
}

class _SidePanel extends ConsumerWidget {
  const _SidePanel({required this.c, required this.onClose});
  final CaseSummary c;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final desk = ref.watch(desksByIdProvider)[c.deskId];
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(children: [
        Expanded(child: Text(c.caseNumber, style: Theme.of(context).textTheme.titleMedium)),
        IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
      ]),
      Wrap(spacing: 6, runSpacing: 6, children: [
        SeverityChip(c.severity),
        Pill(stateLabel(l, c.state), color: stateColor(c.state)),
        if (c.redacted) Pill(l.redactedShort, color: UavrColors.redacted, icon: Icons.lock),
        if (!c.redacted) Pill(authorizationLabel(l, c.authorization), color: authorizationColor(c.authorization)),
      ]),
      const SizedBox(height: 12),
      KeyValue(l.desk, desk?.label(context.lang) ?? '#${c.deskId}'),
      KeyValue(l.firstSeen, c.firstSeen == null ? null : dateTime(c.firstSeen!)),
      KeyValue(l.lastSeen, c.lastSeen == null ? null : dateTime(c.lastSeen!)),
      if (!c.redacted) ...[
        KeyValue(l.informantsObservations, '${c.distinctInformants} / ${c.observationCount}'),
        KeyValue(l.confidence, '${(c.confidence * 100).round()}%'),
        if (c.remoteIdSerials.isNotEmpty) KeyValue(l.remoteId, c.remoteIdSerials.join(', ')),
        for (final r in c.severityReasons) Text('• ${severityReasonLabel(l, r)}'),
      ],
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: () => context.go('/cases/${c.id}'),
        icon: const Icon(Icons.open_in_full),
        label: Text(l.openCase),
      ),
    ]);
  }
}
