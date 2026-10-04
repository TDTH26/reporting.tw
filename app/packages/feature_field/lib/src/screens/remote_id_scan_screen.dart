import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_native/uavr_native.dart';
import 'package:uavr_ui/uavr_ui.dart';

import '../l10n/field_localizations.dart';
import '../services/observation_body.dart';
import '../services/outbox.dart';
import '../services/sensors.dart';
import '../widgets/common.dart';

/// On-scene Remote ID receiver: lists drones heard by this phone and attaches them to the case.
class RemoteIdScanScreen extends ConsumerStatefulWidget {
  const RemoteIdScanScreen({super.key, required this.caseId, required this.caseNumber});
  final String caseId, caseNumber;

  @override
  ConsumerState<RemoteIdScanScreen> createState() => _RemoteIdScanScreenState();
}

class _RemoteIdScanScreenState extends ConsumerState<RemoteIdScanScreen> {
  RemoteIdCapabilities? _caps;
  ScanPermissions? _perms;
  bool _permissionError = false;
  Object? _error;
  StreamSubscription<RemoteIdDrone>? _sub;
  final _drones = <String, RemoteIdDrone>{};
  final _attached = <String>{};
  final _busy = <String>{};
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _start();
    // Re-render "last seen" ages.
    _tick = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    final sensors = ref.read(fieldSensorsProvider);
    await _sub?.cancel();
    setState(() {
      _permissionError = false;
      _error = null;
    });
    final caps = await sensors.remoteIdCapabilities();
    final perms = await sensors.requestScanPermissions();
    if (!mounted) return;
    setState(() {
      _caps = caps;
      _perms = perms;
    });
    _sub = sensors.remoteIdDrones().listen(
      (d) {
        if (mounted) setState(() => _drones[d.sourceAddress] = d);
      },
      onError: (Object e) {
        if (!mounted) return;
        setState(() {
          if (e is PlatformException && e.code == 'permission') {
            _permissionError = true;
          } else {
            _error = e;
          }
        });
      },
    );
  }

  Future<void> _attach(RemoteIdDrone d) async {
    final l = context.f;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy.add(d.sourceAddress));
    try {
      final fix = await ref.read(myFixProvider.notifier).current();
      if (fix == null) {
        messenger.showSnackBar(SnackBar(content: Text(l.noGpsFix)));
        return;
      }
      final body = fieldObservationBody(
        observer: fix,
        observedAt: d.lastSeen,
        dronePosition: dronePositionOf(d),
        remoteId: [remoteIdMessageOf(d)],
      );
      final r = await ref.read(outboxProvider.notifier).submit(OutboxEntry(
            caseId: widget.caseId,
            caseNumber: widget.caseNumber,
            kind: OutboxKind.remoteId,
            body: body,
            createdAt: DateTime.now().toUtc(),
          ));
      if (r != SubmitResult.rejected) _attached.add(d.sourceAddress);
      messenger.showSnackBar(SnackBar(content: Text(submitResultText(l, r))));
    } finally {
      if (mounted) setState(() => _busy.remove(d.sourceAddress));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.f;
    final me = ref.watch(myFixProvider)?.position;
    final drones = _drones.values.toList()..sort((a, b) => b.lastSeen.compareTo(a.lastSeen));
    final caps = _caps;
    final perms = _perms;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.remoteIdScan),
        actions: [IconButton(tooltip: l.restartScan, onPressed: _start, icon: const Icon(Icons.restart_alt))],
      ),
      body: ListView(padding: const EdgeInsets.all(12), children: [
        Text(l.scanFor(widget.caseNumber), style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, children: [
          _CapChip(l.capBt4, caps?.bluetoothLegacy),
          _CapChip(l.capBt5, caps?.bluetoothLongRange),
          _CapChip(l.capWifiBeacon, caps?.wifiBeacon),
          _CapChip(l.capWifiNan, caps?.wifiNan),
        ]),
        if (caps != null && !caps.any) ...[
          const SizedBox(height: 8),
          _Notice(icon: Icons.info_outline, text: l.noRemoteIdHardware),
        ],
        if (_permissionError || (perms != null && !perms.all && (caps?.any ?? false))) ...[
          const SizedBox(height: 8),
          _Notice(
            icon: Icons.privacy_tip_outlined,
            color: UavrColors.medium,
            text: _permissionError ? l.scanPermissionError : l.scanPermissionPartial,
            actions: [
              TextButton(onPressed: _start, child: Text(l.grantPermission)),
              TextButton(onPressed: () => ref.read(fieldSensorsProvider).openSettings(), child: Text(l.openSettings)),
            ],
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 8),
          _Notice(icon: Icons.error_outline, color: UavrColors.critical, text: l.scanError('$_error')),
        ],
        const SizedBox(height: 12),
        if (drones.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(children: [
              if (caps?.any ?? false) const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text(l.scanningNoDrones, textAlign: TextAlign.center),
            ]),
          ),
        for (final d in drones)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: DroneCard(
              d,
              me: me,
              attached: _attached.contains(d.sourceAddress),
              busy: _busy.contains(d.sourceAddress),
              onAttach: () => _attach(d),
            ),
          ),
      ]),
    );
  }
}

String submitResultText(FieldL10n l, SubmitResult r) => switch (r) {
      SubmitResult.sent => l.observationSent,
      SubmitResult.queued => l.observationQueued,
      SubmitResult.duplicate => l.observationDuplicate,
      SubmitResult.rejected => l.observationRejected,
    };

class _CapChip extends StatelessWidget {
  const _CapChip(this.label, this.on);
  final String label;
  final bool? on;

  @override
  Widget build(BuildContext context) => Pill(
        label,
        icon: on == null ? Icons.hourglass_empty : (on! ? Icons.check_circle : Icons.cancel_outlined),
        color: on == true ? UavrColors.low : UavrColors.redacted,
      );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text, this.color, this.actions = const []});
  final IconData icon;
  final String text;
  final Color? color;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Card(
      color: c.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: c),
            const SizedBox(width: 8),
            Expanded(child: Text(text)),
          ]),
          if (actions.isNotEmpty) Wrap(alignment: WrapAlignment.end, children: actions),
        ]),
      ),
    );
  }
}

String idTypeLabel(FieldL10n l, String? t) => switch (t) {
      'serial' => l.idTypeSerial,
      'caa_registration' => l.idTypeCaa,
      'utm_assigned' => l.idTypeUtm,
      'specific_session' => l.idTypeSession,
      null => '—',
      _ => t,
    };

String transportLabel(FieldL10n l, String t) => switch (t) {
      'bt4' => l.capBt4,
      'bt5' => l.capBt5,
      'wifi_beacon' => l.capWifiBeacon,
      'wifi_nan' => l.capWifiNan,
      _ => t,
    };

class DroneCard extends StatelessWidget {
  const DroneCard(this.d,
      {super.key, this.me, required this.attached, required this.busy, required this.onAttach});
  final RemoteIdDrone d;
  final LatLon? me;
  final bool attached, busy;
  final VoidCallback onAttach;

  @override
  Widget build(BuildContext context) {
    final l = context.f;
    final t = Theme.of(context).textTheme;
    final pos = d.lat != null && d.lon != null ? LatLon(d.lat!, d.lon!) : null;
    final op = d.operatorLat != null && d.operatorLon != null ? LatLon(d.operatorLat!, d.operatorLon!) : null;
    final age = DateTime.now().toUtc().difference(d.lastSeen).inSeconds;
    String? num(double? v, String unit, [int digits = 0]) => v == null ? null : '${v.toStringAsFixed(digits)} $unit';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            const Icon(Icons.flight, color: UavrColors.brand),
            const SizedBox(width: 8),
            Expanded(
              child: SelectableText(d.uasId ?? l.unknownSerial,
                  style: t.titleMedium?.copyWith(fontFamily: 'monospace', fontWeight: FontWeight.w700)),
            ),
            Pill(age < 5 ? l.live : l.secondsAgo(age), color: age < 5 ? UavrColors.low : UavrColors.medium),
          ]),
          const SizedBox(height: 6),
          KeyValue(l.idType, idTypeLabel(l, d.idType)),
          KeyValue(l.uaType, d.uaType),
          KeyValue(l.dronePosition, pos?.toString()),
          if (pos != null && me != null) KeyValue(l.fromMe, rangeText(l, me!, pos)),
          KeyValue(l.height, [num(d.heightM, 'm'), if (d.altGeoM != null) '${l.altGeo} ${num(d.altGeoM, 'm')}']
              .whereType<String>()
              .join(' · ')),
          KeyValue(l.speedDirection,
              [num(d.speedMps, 'm/s', 1), if (d.directionDeg != null) '${d.directionDeg!.round()}°'].whereType<String>().join(' · ')),
          KeyValue(l.operatorPosition, op?.toString()),
          if (op != null && me != null) KeyValue(l.operatorFromMe, rangeText(l, me!, op)),
          if (d.operatorId != null) KeyValue(l.operatorId, d.operatorId),
          if (d.selfIdText != null) KeyValue(l.selfId, d.selfIdText),
          KeyValue(l.transport, transportLabel(l, d.transport)),
          KeyValue(l.rssi, d.rssi == null ? null : '${d.rssi} dBm'),
          KeyValue(l.lastSeenLabel, clockTime(d.lastSeen)),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: busy ? null : onAttach,
            icon: busy
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(attached ? Icons.check : Icons.attach_file),
            label: Text(attached ? l.attachAgain : l.attachToCase),
          ),
        ]),
      ),
    );
  }
}
