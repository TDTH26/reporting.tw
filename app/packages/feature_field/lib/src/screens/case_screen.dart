import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_core/uavr_core.dart';
import 'package:uavr_maps/uavr_maps.dart';
import 'package:uavr_ui/uavr_ui.dart';

import '../geo_math.dart';
import '../l10n/field_localizations.dart';
import '../services/live.dart';
import '../services/offline_cache.dart';
import '../services/position_sharing.dart';
import '../services/sensors.dart';
import '../widgets/common.dart';
import '../json_util.dart';

const operatorColor = Color(0xFF6A1B9A);
const meColor = Color(0xFF1565C0);

/// Operator (pilot) position: the incident's fused value, else the newest Remote ID System message.
LatLon? operatorPositionOf(CaseDetail d) {
  final fused = d.incident?.operatorPosition ?? LatLon.fromJson(d.summary.raw['operator_position']);
  if (fused != null) return fused;
  final obs = [...d.observations.where((o) => o.operatorPosition != null)]
    ..sort((a, b) => b.observedAt.compareTo(a.observedAt));
  return obs.isEmpty ? null : obs.first.operatorPosition;
}

/// Toggle for sharing the officer's position with the desk.
class PositionShareButton extends ConsumerWidget {
  const PositionShareButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.f;
    final s = ref.watch(positionSharingProvider);
    return IconButton(
      tooltip: s.enabled ? l.positionSharingOn : l.positionSharingOff,
      isSelected: s.enabled,
      onPressed: () => ref.read(positionSharingProvider.notifier).toggle(),
      icon: const Icon(Icons.location_disabled),
      selectedIcon: const Icon(Icons.share_location, color: UavrColors.low),
    );
  }
}

class CaseScreen extends ConsumerStatefulWidget {
  const CaseScreen({super.key, required this.caseId, this.initial});
  final String caseId;
  final CaseSummary? initial;

  static const refreshInterval = Duration(seconds: 5);

  @override
  ConsumerState<CaseScreen> createState() => _CaseScreenState();
}

class _CaseScreenState extends ConsumerState<CaseScreen> {
  CaseDetail? _d;
  bool _offline = false;
  bool _gone = false;
  bool _loading = false;
  DateTime? _updatedAt;
  Object? _error;
  Timer? _timer;
  StreamSubscription<LiveMessage>? _live;
  final _map = MapController();
  final _note = TextEditingController();
  bool _sendingNote = false;
  late final PositionSharing _sharing;

  @override
  void initState() {
    super.initState();
    _sharing = ref.read(positionSharingProvider.notifier);
    Future.microtask(_sharing.caseOpened);
    _load();
    _timer = Timer.periodic(CaseScreen.refreshInterval, (_) => _load());
    _live = ref.read(fieldLiveProvider).events.listen((m) {
      if (m.type == 'resync_required' || liveCaseId(m) == widget.caseId) _load();
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    _live?.cancel();
    _note.dispose();
    final s = _sharing;
    Future.microtask(s.caseClosed);
    super.dispose();
  }

  Future<void> _load() async {
    if (_loading || _gone) return;
    _loading = true;
    final api = ref.read(staffApiProvider);
    final cache = ref.read(offlineCacheProvider);
    try {
      final d = await api.fieldCase(widget.caseId);
      await cache.writeCase(d);
      if (mounted) {
        setState(() {
          _d = d;
          _offline = false;
          _error = null;
          _updatedAt = DateTime.now();
        });
      }
    } on ApiException catch (e) {
      if (e.status == 404 || e.status == 403) {
        if (mounted) setState(() => _gone = true);
      } else {
        await _fallback(e);
      }
    } catch (e) {
      await _fallback(e);
    } finally {
      _loading = false;
    }
  }

  Future<void> _fallback(Object e) async {
    if (_d == null) {
      final c = await ref.read(offlineCacheProvider).readCase(widget.caseId);
      if (!mounted) return;
      setState(() {
        _d = c?.value;
        _updatedAt = c?.savedAt;
        _offline = true;
        _error = e;
      });
    } else if (mounted) {
      setState(() {
        _offline = true;
        _error = e;
      });
    }
  }

  Future<void> _sendNote() async {
    final text = _note.text.trim();
    if (text.isEmpty) return;
    setState(() => _sendingNote = true);
    final l = context.f;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(staffApiProvider).addNote(widget.caseId, text);
      _note.clear();
      messenger.showSnackBar(SnackBar(content: Text(l.noteAdded)));
      await _load();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l.noteFailed)));
    } finally {
      if (mounted) setState(() => _sendingNote = false);
    }
  }

  void _fit(List<LatLon> pts) {
    try {
      fitTo(_map, pts);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l = context.f;
    final d = _d;
    final summary = d?.summary ?? widget.initial;
    final fix = ref.watch(myFixProvider);
    final me = fix?.position;

    Widget body;
    if (_gone) {
      body = EmptyView(l.caseUnavailable, icon: Icons.assignment_late_outlined);
    } else if (summary == null) {
      body = _error == null ? const LoadingView() : ErrorView(_error!, onRetry: _load);
    } else {
      final redacted = summary.redacted;
      final op = d == null || redacted ? null : operatorPositionOf(d);
      final drone = summary.position;
      final pts = [?drone, ?op, ?me];
      body = ListView(padding: EdgeInsets.zero, children: [
        if (_offline) OfflineBanner(updatedAt: _updatedAt),
        _Header(summary),
        SizedBox(
          height: 300,
          child: pts.isEmpty
              ? Center(child: Text(l.positionUnknown))
              : Stack(children: [
                  UavrMap(
                    controller: _map,
                    tileUrlTemplate: ref.watch(configProvider).tileUrlTemplate,
                    attribution: ref.watch(configProvider).tileAttribution,
                    initialCenter: ll(pts.first),
                    initialZoom: 15,
                    children: [
                      if (d != null && !redacted) BearingLinesLayer(d.observations),
                      if (!redacted) TrackLayer(summary.track),
                      if (drone != null)
                        EstimateLayer(position: drone, errorM: summary.estErrorM, severity: summary.severity),
                      if (op != null) ...[
                        CircleLayer(circles: [
                          CircleMarker(
                            point: ll(op),
                            radius: 22,
                            color: operatorColor.withValues(alpha: 0.18),
                            borderColor: operatorColor,
                            borderStrokeWidth: 2.5,
                          ),
                        ]),
                        PointsLayer([op], icon: Icons.person_pin_circle, color: operatorColor, labels: [l.operator]),
                      ],
                      if (me != null) PointsLayer([me], icon: Icons.my_location, color: meColor, labels: [l.me]),
                    ],
                  ),
                  Positioned(
                    right: 8,
                    bottom: 28,
                    child: FloatingActionButton.small(
                      heroTag: 'fit',
                      tooltip: l.fitMap,
                      onPressed: () => _fit(pts),
                      child: const Icon(Icons.center_focus_strong),
                    ),
                  ),
                ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Row(children: [
            Expanded(
              child: RangeReadout(
                label: l.toDrone,
                icon: Icons.flight,
                color: UavrColors.severity(summary.severity),
                from: me,
                to: drone,
              ),
            ),
            if (!redacted) ...[
              const SizedBox(width: 8),
              Expanded(
                child: RangeReadout(label: l.toOperator, icon: Icons.person_pin_circle, color: operatorColor, from: me, to: op),
              ),
            ],
          ]),
        ),
        if (fix?.accuracyM != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(l.gpsAccuracy(fix!.accuracyM!.round()), style: Theme.of(context).textTheme.bodySmall),
          ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: redacted ? _RedactedBody(summary) : (d == null ? const LoadingView() : _FullBody(d, this)),
        ),
      ]);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(summary?.caseNumber ?? l.caseTitle),
        actions: [
          const PositionShareButton(),
          IconButton(tooltip: UavrL10n.of(context).retry, onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: body,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.c);
  final CaseSummary c;

  @override
  Widget build(BuildContext context) {
    final l = context.f;
    final u = UavrL10n.of(context);
    final t = Theme.of(context).textTheme;
    final last = c.lastSeen ?? c.createdAt;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
        SeverityChip(c.severity),
        Pill(caseStateLabel(l, c.state)),
        if (c.redacted) Pill(l.redactedShort, icon: Icons.lock, color: UavrColors.redacted),
        if (!c.redacted)
          Pill(authorizationLabel(l, c.authorization), color: authorizationColor(c.authorization)),
        if (c.sensorConfirmed) Pill(l.sensorConfirmed, icon: Icons.sensors, color: UavrColors.brand),
        if (last != null) Text(l.lastSeen(relativeTime(u, last)), style: t.bodyMedium),
      ]),
    );
  }
}

class _RedactedBody extends StatelessWidget {
  const _RedactedBody(this.c);
  final CaseSummary c;

  @override
  Widget build(BuildContext context) {
    final l = context.f;
    final u = UavrL10n.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Card(
        color: UavrColors.redacted.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.lock, color: UavrColors.redacted),
            const SizedBox(width: 10),
            Expanded(child: Text(l.redactedExplanation)),
          ]),
        ),
      ),
      const SizedBox(height: 12),
      Section(
        title: l.basicInfo,
        child: Column(children: [
          KeyValue(l.severity, severityLabel(u, c.severity)),
          KeyValue(l.location, c.position?.toString()),
          KeyValue(l.firstSeenLabel, c.firstSeen == null ? null : dateTime(c.firstSeen!)),
          KeyValue(l.lastSeenLabel, c.lastSeen == null ? null : dateTime(c.lastSeen!)),
        ]),
      ),
    ]);
  }
}

class _FullBody extends StatelessWidget {
  const _FullBody(this.d, this.s);
  final CaseDetail d;
  final _CaseScreenState s;

  @override
  Widget build(BuildContext context) {
    final l = context.f;
    final u = UavrL10n.of(context);
    final c = d.summary;
    final inc = d.incident;
    final lang = Localizations.localeOf(context).languageCode;
    final open = c.state.isOpen;
    final q = 'n=${Uri.encodeQueryComponent(c.caseNumber)}';
    final notes = d.events.where((e) => e.action == 'note' && e.reason != null).toList().reversed.toList();
    const gap = SizedBox(height: 12);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: open ? () => context.push('/case/${c.id}/scan?$q') : null,
            icon: const Icon(Icons.wifi_tethering),
            label: Text(l.remoteIdScan),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: open ? () => context.push('/case/${c.id}/evidence?$q') : null,
            icon: const Icon(Icons.photo_camera),
            label: Text(l.captureEvidence),
          ),
        ),
      ]),
      gap,
      Section(
        title: l.incidentFacts,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          KeyValue(l.location, c.position?.toString()),
          KeyValue(l.positionSource, positionSourceLabel(l, c.positionSource)),
          KeyValue(l.estError, c.estErrorM == null ? null : '± ${c.estErrorM!.round()} m'),
          KeyValue(l.estAltitude, c.estAltitudeM == null ? null : '${c.estAltitudeM!.round()} m'),
          KeyValue(l.firstSeenLabel, c.firstSeen == null ? null : dateTime(c.firstSeen!)),
          KeyValue(l.lastSeenLabel, c.lastSeen == null ? null : dateTime(c.lastSeen!)),
          KeyValue(l.reports, '${c.observationCount} / ${l.distinctInformants(c.distinctInformants)}'),
          KeyValue(l.authorization, authorizationLabel(l, c.authorization)),
          KeyValue(l.craft, [c.craftDomain, if (c.craftType != null) c.craftType!].join(' · ')),
          if (c.vesselMatch?['mmsi'] != null)
            KeyValue('AIS', '${c.vesselMatch!['name'] ?? ''} MMSI ${c.vesselMatch!['mmsi']}')
          else if (c.isDarkVessel)
            Pill(l.darkVessel, color: UavrColors.critical, icon: Icons.portable_wifi_off),
          if (c.aiAssessment != null)
            KeyValue(l.aiAssessment, '${c.aiAssessment!['craft_type'] ?? '—'} · ${c.aiAssessment!['silhouette'] ?? ''}'),
          KeyValue(
            l.zones,
            (inc?.zones ?? const []).isEmpty
                ? l.none
                : inc!.zones
                    .map((z) => '${zoneTypeLabel(u, '${z['zone_type']}')}: ${lang == 'zh' ? z['name_zh'] : z['name']}')
                    .join('\n'),
          ),
        ]),
      ),
      if (inc?.permit != null) ...[
        gap,
        Section(
          title: l.permit,
          child: Column(children: [
            KeyValue(l.permitNo, '${inc!.permit!['permit_no']}'),
            KeyValue(l.operatorName, inc.permit!['operator_name'] as String?),
            KeyValue(l.validity, '${_d(inc.permit!['valid_from'])} – ${_d(inc.permit!['valid_to'])}'),
            KeyValue(l.maxAltitude, inc.permit!['max_alt_m'] == null ? null : '${inc.permit!['max_alt_m']} m'),
          ]),
        ),
      ],
      gap,
      Section(
        title: l.remoteIdSerials,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (inc?.registryMatch != null)
            KeyValue(
              l.registryMatch,
              '${inc!.registryMatch!['serial']} · ${inc.registryMatch!['manufacturer'] ?? ''} '
              '${inc.registryMatch!['model'] ?? ''} (${inc.registryMatch!['status'] ?? ''})',
            ),
          if (c.remoteIdSerials.isEmpty) Text(l.noRemoteId),
          for (final serial in c.remoteIdSerials)
            Row(children: [
              Expanded(child: SelectableText(serial, style: const TextStyle(fontFamily: 'monospace'))),
              TextButton.icon(
                onPressed: () => showRegistry(context, s.ref, serial),
                icon: const Icon(Icons.manage_search),
                label: Text(l.registryLookup),
              ),
            ]),
        ]),
      ),
      gap,
      Section(
        title: l.adsbNearby,
        child: (inc?.adsbNearby ?? const []).isEmpty
            ? Text(l.none)
            : Column(children: [
                for (final a in inc!.adsbNearby)
                  KeyValue(
                    '${a['callsign'] ?? a['icao24']}',
                    [
                      if (a['alt_m'] != null) '${(a['alt_m'] as num).round()} m',
                      if (a['distance_m'] != null) formatDistance((a['distance_m'] as num).toDouble()),
                    ].join(' · '),
                  ),
              ]),
      ),
      if (inc?.weather != null) ...[
        gap,
        Section(
          title: l.weather,
          child: Column(children: [
            KeyValue(l.weatherStation, '${inc!.weather!['station_id'] ?? '—'}'),
            KeyValue(l.visibility,
                inc.weather!['visibility_m'] == null ? null : formatDistance((inc.weather!['visibility_m'] as num).toDouble())),
            KeyValue(
              l.wind,
              inc.weather!['wind_speed_mps'] == null
                  ? null
                  : '${inc.weather!['wind_speed_mps']} m/s'
                      '${inc.weather!['wind_dir_deg'] == null ? '' : ' · ${inc.weather!['wind_dir_deg']}°'}',
            ),
          ]),
        ),
      ],
      gap,
      Section(
        title: l.observationsCount(d.observations.length),
        child: d.observations.isEmpty
            ? Text(l.none)
            : Column(children: [
                for (final o in d.observations.reversed.take(8))
                  KeyValue(clockTime(o.observedAt), [
                    sourceTypeLabel(l, o.sourceType),
                    if (o.remoteIdSerial != null) o.remoteIdSerial!,
                    if (o.bearingDeg != null) formatBearing(o.bearingDeg!),
                  ].join(' · ')),
              ]),
      ),
      if (d.fieldOfficers.isNotEmpty) ...[
        gap,
        Section(
          title: l.fieldOfficers,
          child: Column(children: [
            for (final f in d.fieldOfficers)
              KeyValue(f.displayName, f.at == null ? null : l.lastSeen(relativeTime(u, f.at!))),
          ]),
        ),
      ],
      gap,
      Section(
        title: l.notes,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (final n in notes)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(dateTime(n.at), style: Theme.of(context).textTheme.bodySmall),
                Text(n.reason!),
              ]),
            ),
          TextField(
            controller: s._note,
            minLines: 1,
            maxLines: 4,
            maxLength: 4000,
            decoration: InputDecoration(hintText: l.noteHint),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: s._sendingNote ? null : s._sendNote,
              icon: const Icon(Icons.send),
              label: Text(l.addNote),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 24),
    ]);
  }

  static String _d(Object? v) {
    final t = parseDate(v);
    return t == null ? '—' : dateTime(t);
  }
}

String sourceTypeLabel(FieldL10n l, String s) => switch (s) {
      'field_officer' => l.srcFieldOfficer,
      'remote_id' => l.srcRemoteId,
      'rf_sensor' => l.srcRfSensor,
      'mda_sensor' => l.srcMdaSensor,
      'radar' => l.srcRadar,
      _ when s.startsWith('informant') => l.srcInformant,
      _ => s,
    };

/// Registry lookup dialog for a Remote ID serial (audited server-side).
Future<void> showRegistry(BuildContext context, WidgetRef ref, String serial) {
  final future = ref.read(staffApiProvider).registry(serial);
  return showDialog<void>(
    context: context,
    builder: (c) {
      final l = c.f;
      return AlertDialog(
        title: Text(l.registryTitle(serial)),
        content: FutureBuilder<RegistryLookup>(
          future: future,
          builder: (c, snap) {
            if (snap.hasError) return Text(l.registryFailed);
            if (!snap.hasData) return const SizedBox(height: 80, child: LoadingView());
            final r = snap.data!;
            final e = r.entry;
            return SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Pill(r.registered ? l.registered : l.notRegistered,
                    color: r.registered ? UavrColors.low : UavrColors.critical),
                const SizedBox(height: 8),
                if (e != null) ...[
                  KeyValue(l.registrationNo, e['registration_no'] as String?),
                  KeyValue(l.owner, e['owner_name'] as String?),
                  KeyValue(l.model, '${e['manufacturer'] ?? ''} ${e['model'] ?? ''}'.trim()),
                  KeyValue(l.mtow, e['mtow_g'] == null ? null : '${e['mtow_g']} g'),
                  KeyValue(l.registryStatus, e['status'] as String?),
                ],
                const SizedBox(height: 8),
                Text(l.permits, style: Theme.of(c).textTheme.titleSmall),
                if (r.permits.isEmpty) Text(l.none),
                for (final p in r.permits)
                  KeyValue('${p['permit_no']}',
                      '${p['operator_name'] ?? ''}\n${_FullBody._d(p['valid_from'])} – ${_FullBody._d(p['valid_to'])}'),
              ]),
            );
          },
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: Text(UavrL10n.of(c).close))],
      );
    },
  );
}
