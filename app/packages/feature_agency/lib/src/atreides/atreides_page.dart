import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
          _Header(filter: _f, onFilter: _set),
          switch (summary) {
            AsyncData(:final value) when value.detections == 0 => Expanded(child: Center(child: Text(l.atreidesEmpty))),
            AsyncData(:final value) => Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SummaryCards(value),
                  Expanded(child: _body(context, value, tracks)),
                ],
              ),
            ),
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

class _Header extends ConsumerWidget {
  const _Header({required this.filter, required this.onFilter});
  final AtreidesFilter filter;
  final void Function(AtreidesFilter) onFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final batches = ref.watch(atreidesBatchesProvider).value ?? const <AtreidesBatch>[];
    const fg = Colors.white;
    return Container(
      color: const Color(0xFF141820),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
          const SizedBox(height: 12),
          Theme(
            data: ThemeData(brightness: Brightness.dark, colorSchemeSeed: const Color(0xFFEF6C00), useMaterial3: true),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                DropdownButton<int?>(
                  value: batches.any((b) => b.id == filter.batchId) ? filter.batchId : null,
                  dropdownColor: const Color(0xFF1E2430),
                  underline: const SizedBox.shrink(),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l.atreidesAllBatches)),
                    for (final b in batches) DropdownMenuItem(value: b.id, child: Text('#${b.id} · ${b.filename}')),
                  ],
                  onChanged: (v) => onFilter((
                    batchId: v,
                    role: filter.role,
                    routesOnly: filter.routesOnly,
                    highConfidence: filter.highConfidence,
                  )),
                ),
                const SizedBox(width: 8),
                for (final r in atreidesRoles)
                  FilterChip(
                    avatar: CircleAvatar(backgroundColor: atreidesRoleColor(r), radius: 6),
                    label: Text(atreidesRoleLabel(l, r)),
                    selected: filter.role == r,
                    onSelected: (on) => onFilter((
                      batchId: filter.batchId,
                      role: on ? r : null,
                      routesOnly: filter.routesOnly,
                      highConfidence: filter.highConfidence,
                    )),
                  ),
                FilterChip(
                  label: Text(l.atreidesRoutesOnly),
                  selected: filter.routesOnly,
                  onSelected: (on) => onFilter((
                    batchId: filter.batchId,
                    role: filter.role,
                    routesOnly: on,
                    highConfidence: filter.highConfidence,
                  )),
                ),
                FilterChip(
                  label: Text(l.atreidesHighConfidence),
                  selected: filter.highConfidence,
                  onSelected: (on) => onFilter((
                    batchId: filter.batchId,
                    role: filter.role,
                    routesOnly: filter.routesOnly,
                    highConfidence: on,
                  )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards(this.s);
  final AtreidesSummary s;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final loc = MaterialLocalizations.of(context);
    String day(DateTime? t) => t == null ? '–' : loc.formatShortDate(t.toLocal());
    Widget card(String title, String value, {String? sub, Color? dot}) => Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (dot != null) ...[CircleAvatar(backgroundColor: dot, radius: 5), const SizedBox(width: 6)],
                Text(title, style: Theme.of(context).textTheme.labelMedium),
              ],
            ),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            if (sub != null) Text(sub, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          card(l.atreidesDetections, '${s.detections}'),
          card(l.atreidesTracks, '${s.tracks}', sub: l.atreidesTrackSplit(s.routes, s.singleContacts)),
          for (final r in atreidesRoles)
            card(atreidesRoleLabel(l, r), '${s.byRole[r] ?? 0}', dot: atreidesRoleColor(r)),
          card(l.atreidesPeriod, '${day(s.firstAt)} – ${day(s.lastAt)}'),
        ],
      ),
    );
  }
}

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
