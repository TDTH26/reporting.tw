import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:uavr_api/uavr_api.dart' hide TimeOfDay;
import 'package:uavr_core/uavr_core.dart';
import 'package:uavr_maps/uavr_maps.dart';
import 'package:uavr_ui/uavr_ui.dart';

import '../common/console_map.dart';
import '../common/l10n.dart';
import '../common/providers.dart';

typedef AtreidesFilter = ({int? batchId, String? role, bool routesOnly, bool highConfidence});

final atreidesBatchesProvider = FutureProvider.autoDispose<List<AtreidesBatch>>(
  (ref) => ref.watch(staffApiProvider).atreidesBatches(),
  retry: (_, _) => null,
);

final atreidesSummaryProvider = FutureProvider.autoDispose.family<AtreidesSummary, int?>(
  (ref, batchId) => ref.watch(staffApiProvider).atreidesSummary(batchId: batchId),
  retry: (_, _) => null,
);

final atreidesTracksProvider = FutureProvider.autoDispose.family<List<AtreidesTrack>, AtreidesFilter>(
  (ref, f) => ref
      .watch(staffApiProvider)
      .atreidesTracks(
        batchId: f.batchId,
        role: f.role,
        minPoints: f.routesOnly ? 2 : 1,
        highConfidence: f.highConfidence,
      ),
  retry: (_, _) => null,
);

const atreidesRoles = ['mobile_asset', 'fixed_site', 'ambiguous'];

Color atreidesRoleColor(String role) => switch (role) {
  'mobile_asset' => const Color(0xFFEF6C00),
  'fixed_site' => const Color(0xFF6D4C41),
  _ => const Color(0xFF78909C),
};

String atreidesConfidenceLabel(AgencyL10n l, String? c) => switch (c) {
      'high' => l.atreidesConfHigh,
      'low' => l.atreidesConfLow,
      _ => c ?? '?',
    };

String atreidesRoleLabel(AgencyL10n l, String? role) => switch (role) {
  'mobile_asset' => l.atreidesRoleMobile,
  'fixed_site' => l.atreidesRoleFixed,
  _ => l.atreidesRoleAmbiguous,
};

/// Atreides maritime sensor (MDA) section: imports, summary, map of routes and contacts, track list.
class AtreidesPage extends ConsumerStatefulWidget {
  const AtreidesPage({super.key});
  @override
  ConsumerState<AtreidesPage> createState() => _AtreidesPageState();
}

class _AtreidesPageState extends ConsumerState<AtreidesPage> {
  static const _listLimit = 400;
  final _map = MapController();
  AtreidesFilter _f = (batchId: null, role: null, routesOnly: false, highConfidence: false);
  String? _selected;

  void _set(AtreidesFilter f) => setState(() {
    _f = f;
    _selected = null;
  });

  void _select(AtreidesTrack t) {
    setState(() => _selected = t.trackId);
    if (!ref.read(consoleMapsEnabledProvider)) return;
    if (t.path.length > 1) {
      _map.fitCamera(
        CameraFit.coordinates(
          coordinates: [for (final p in t.path) ll(p)],
          padding: const EdgeInsets.all(48),
          maxZoom: 11,
        ),
      );
    } else {
      _map.move(ll(t.last), 10);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final summary = ref.watch(atreidesSummaryProvider(_f.batchId));
    final tracks = ref.watch(atreidesTracksProvider(_f));
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Header(),
          _Toolbar(filter: _f, onFilter: _set, summary: summary.value),
          const Divider(height: 1),
          switch (summary) {
            AsyncData(:final value) when value.detections == 0 => Expanded(child: Center(child: Text(l.atreidesEmpty))),
            AsyncData(:final value) => Expanded(child: _body(context, value, tracks)),
            AsyncError(:final error) => Expanded(
              child: ErrorView(error, onRetry: () => ref.invalidate(atreidesSummaryProvider(_f.batchId))),
            ),
            _ => const Expanded(child: LoadingView()),
          },
        ],
      ),
    );
  }

  Widget _body(BuildContext context, AtreidesSummary s, AsyncValue<List<AtreidesTrack>> tracks) {
    final all = tracks.value ?? const <AtreidesTrack>[];
    // The map opens on the median position: a few far outliers would push a bounding-box centre off the data.
    final Widget map = tracks is AsyncData
        ? _TracksMap(controller: _map, tracks: all, selected: _selected, center: _median(all))
        : const LoadingView();
    final list = switch (tracks) {
      AsyncError(:final error) => ErrorView(error, onRetry: () => ref.invalidate(atreidesTracksProvider(_f))),
      AsyncData() => _TrackList(
        tracks: all.take(_listLimit).toList(),
        total: all.length,
        selected: _selected,
        onTap: _select,
      ),
      _ => const LoadingView(),
    };
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 900) {
          return Column(
            children: [
              SizedBox(height: c.maxHeight * 0.55, child: map),
              const Divider(height: 1),
              Expanded(child: list),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 3, child: map),
            const VerticalDivider(width: 1),
            SizedBox(width: 420, child: list),
          ],
        );
      },
    );
  }
}

LatLng? _median(List<AtreidesTrack> tracks) {
  if (tracks.isEmpty) return null;
  final lats = [for (final t in tracks) t.last.lat]..sort();
  final lons = [for (final t in tracks) t.last.lon]..sort();
  return LatLng(lats[lats.length ~/ 2], lons[lons.length ~/ 2]);
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    const fg = Colors.white;
    return Container(
      color: const Color(0xFF141820),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'packages/feature_agency/assets/atreides_logo_light.png',
            height: 56,
            semanticLabel: 'Atreides',
            errorBuilder: (_, _, _) => const SizedBox(width: 56),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.atreidesTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: fg, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(l.atreidesSubtitle, style: const TextStyle(color: Color(0xFFB8C2CC), fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One row: role (single choice, with counts), routes / confidence toggles, import, and the totals.
class _Toolbar extends ConsumerWidget {
  const _Toolbar({required this.filter, required this.onFilter, required this.summary});
  final AtreidesFilter filter;
  final void Function(AtreidesFilter) onFilter;
  final AtreidesSummary? summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final t = Theme.of(context);
    final batches = ref.watch(atreidesBatchesProvider).value ?? const <AtreidesBatch>[];
    final n = NumberFormat.decimalPattern(Localizations.localeOf(context).toLanguageTag());
    final loc = MaterialLocalizations.of(context);
    String day(DateTime? d) => d == null ? '–' : loc.formatShortDate(d.toLocal());
    AtreidesFilter f({Object? batchId = _keep, Object? role = _keep, bool? routesOnly, bool? highConfidence}) => (
      batchId: identical(batchId, _keep) ? filter.batchId : batchId as int?,
      role: identical(role, _keep) ? filter.role : role as String?,
      routesOnly: routesOnly ?? filter.routesOnly,
      highConfidence: highConfidence ?? filter.highConfidence,
    );
    final s = summary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SegmentedButton<String>(
            key: const Key('atreides-role'),
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            segments: [
              ButtonSegment(value: '', label: Text(l.atreidesAllRoles)),
              for (final r in atreidesRoles)
                ButtonSegment(
                  value: r,
                  icon: CircleAvatar(backgroundColor: atreidesRoleColor(r), radius: 5),
                  label: Text(s == null
                      ? atreidesRoleLabel(l, r)
                      : '${atreidesRoleLabel(l, r)} ${n.format(s.byRole[r] ?? 0)}'),
                ),
            ],
            selected: {filter.role ?? ''},
            onSelectionChanged: (v) => onFilter(f(role: v.first.isEmpty ? null : v.first)),
          ),
          FilterChip(
            label: Text(l.atreidesRoutesOnly),
            selected: filter.routesOnly,
            visualDensity: VisualDensity.compact,
            onSelected: (on) => onFilter(f(routesOnly: on)),
          ),
          FilterChip(
            label: Text(l.atreidesHighConfidence),
            selected: filter.highConfidence,
            visualDensity: VisualDensity.compact,
            onSelected: (on) => onFilter(f(highConfidence: on)),
          ),
          if (batches.length > 1)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: DropdownButton<int?>(
                isDense: true,
                isExpanded: true,
                value: batches.any((b) => b.id == filter.batchId) ? filter.batchId : null,
                underline: const SizedBox.shrink(),
                items: [
                  DropdownMenuItem(value: null, child: Text(l.atreidesAllBatches)),
                  for (final b in batches)
                    DropdownMenuItem(
                      value: b.id,
                      child: Text('#${b.id} · ${b.filename}', overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (v) => onFilter(f(batchId: v)),
              ),
            ),
          if (s != null)
            Text(
              '${l.atreidesDetections} ${n.format(s.detections)} · ${l.atreidesTracks} ${n.format(s.tracks)} '
              '(${l.atreidesTrackSplit(s.routes, s.singleContacts)}) · ${day(s.firstAt)} – ${day(s.lastAt)}',
              style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}

const _keep = Object();

class _TracksMap extends StatelessWidget {
  const _TracksMap({required this.controller, required this.tracks, required this.selected, this.center});
  final MapController controller;
  final List<AtreidesTrack> tracks;
  final String? selected;
  final LatLng? center;

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      _mapView(),
      Positioned(right: 8, top: 8, child: MapZoomButtons(controller, heroTag: 'atreides')),
    ]);
  }

  Widget _mapView() {
    final sel = tracks.where((t) => t.trackId == selected).firstOrNull;
    return ConsoleMap(
      controller: controller,
      initialCenter: center,
      initialZoom: 4.6,
      children: [
        PolylineLayer(
          polylines: [
            for (final t in tracks)
              if (t.path.length > 1)
                Polyline(
                  points: [for (final p in t.path) ll(p)],
                  strokeWidth: 1.6,
                  color: atreidesRoleColor(t.role).withValues(alpha: t.confidence == 'high' ? 0.75 : 0.4),
                ),
          ],
        ),
        CircleLayer(
          circles: [
            for (final t in tracks)
              CircleMarker(
                point: ll(t.last),
                radius: t.isRoute ? 3.5 : 2.5,
                color: atreidesRoleColor(t.role).withValues(alpha: t.confidence == 'high' ? 0.9 : 0.5),
              ),
          ],
        ),
        if (sel != null) ...[
          if (sel.path.length > 1)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: [for (final p in sel.path) ll(p)],
                  strokeWidth: 4,
                  color: const Color(0xFF1565C0),
                  borderStrokeWidth: 1.5,
                  borderColor: Colors.white,
                ),
              ],
            ),
          CircleLayer(
            circles: [
              CircleMarker(
                point: ll(sel.last),
                radius: 7,
                color: const Color(0xFF1565C0),
                borderColor: Colors.white,
                borderStrokeWidth: 2,
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _TrackList extends StatelessWidget {
  const _TrackList({required this.tracks, required this.total, required this.selected, required this.onTap});
  final List<AtreidesTrack> tracks;
  final int total;
  final String? selected;
  final void Function(AtreidesTrack) onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final loc = MaterialLocalizations.of(context);
    String when(DateTime? t) => t == null
        ? '–'
        : '${loc.formatShortDate(t.toLocal())} ${loc.formatTimeOfDay(TimeOfDay.fromDateTime(t.toLocal()))}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Text(l.atreidesShowing(tracks.length, total), style: Theme.of(context).textTheme.labelMedium),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: tracks.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final t = tracks[i];
              final facts = t.isRoute
                  ? l.atreidesTrackFacts(t.points, (t.spanKm ?? 0).toStringAsFixed(1))
                  : l.atreidesSingleContact;
              return ListTile(
                selected: t.trackId == selected,
                dense: true,
                leading: CircleAvatar(backgroundColor: atreidesRoleColor(t.role), radius: 7),
                title: Text('${atreidesRoleLabel(l, t.role)} · $facts'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (t.reasoning != null) Text('${t.reasoning} (${l.atreidesConfidence(atreidesConfidenceLabel(l, t.confidence))})'),
                    if (t.sourceRole != null && t.sourceReasoning != null)
                      Text(
                        l.atreidesSourceView(
                          atreidesRoleLabel(l, t.sourceRole),
                          atreidesConfidenceLabel(l, t.sourceConfidence),
                          t.sourceReasoning!,
                        ),
                      ),
                    Text(t.isRoute ? '${when(t.firstAt)} → ${when(t.lastAt)}' : when(t.lastAt)),
                    Text(t.trackId, style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
                  ],
                ),
                isThreeLine: true,
                onTap: () => onTap(t),
              );
            },
          ),
        ),
      ],
    );
  }
}
