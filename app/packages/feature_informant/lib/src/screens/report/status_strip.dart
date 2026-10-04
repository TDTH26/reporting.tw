import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_native/uavr_native.dart';
import 'package:uavr_ui/uavr_ui.dart';

import '../../services/sensors.dart';
import '../../widgets/common.dart';
import 'map_picker.dart';
import 'report_controller.dart';

/// Location fix and Remote ID scan status, shown above every step.
class StatusStrip extends StatelessWidget {
  const StatusStrip({super.key});

  @override
  Widget build(BuildContext context) => Material(
        color: Theme.of(context).colorScheme.surfaceContainer,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Column(mainAxisSize: MainAxisSize.min, children: [_LocationRow(), _RemoteIdRow()]),
        ),
      );
}

class _LocationRow extends ConsumerWidget {
  const _LocationRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final fix = ref.watch(reportFlowProvider.select((d) => d.fix));
    final problem = ref.watch(reportFlowProvider.select((d) => d.locationProblem));
    final flow = ref.read(reportFlowProvider.notifier);

    Future<void> pick() async {
      final p = await pickLocationOnMap(context, initial: fix?.position);
      if (p != null) flow.setManualLocation(p);
    }

    final (IconData icon, Color? color, String text) = switch ((fix, problem)) {
      (LocationFix(manual: true), _) => (Icons.edit_location_alt, UavrColors.low, l.locationManual),
      (LocationFix(:final accuracyM), _) => (
          Icons.my_location,
          UavrColors.low,
          accuracyM == null ? l.locationManual : l.locationAccuracy(accuracyM.round()),
        ),
      (null, LocationProblem()) => (Icons.location_disabled, UavrColors.critical, l.locationUnavailable),
      _ => (Icons.location_searching, null, l.locationWaiting),
    };
    return Row(children: [
      Icon(icon, size: 20, color: color),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
      if (problem != null && fix == null)
        IconButton(icon: const Icon(Icons.refresh), tooltip: context.u.retry, onPressed: flow.retryLocation),
      if (fix == null || fix.manual) TextButton(onPressed: pick, child: Text(l.locationPickOnMap)),
    ]);
  }
}

class _RemoteIdRow extends ConsumerWidget {
  const _RemoteIdRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final d = ref.watch(reportFlowProvider);
    if (!d.remoteIdSupported) return const SizedBox.shrink();
    final text = d.remoteIdPermissionMissing && d.drones.isEmpty ? l.remoteIdPermission : l.remoteIdCount(d.drones.length);
    return InkWell(
      onTap: () => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (_) => const RemoteIdSheet(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Icon(Icons.wifi_tethering, size: 20, color: d.drones.isEmpty ? null : UavrColors.brand),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
          if (d.drones.isNotEmpty) Pill('${d.drones.length}', color: UavrColors.brand),
          const Icon(Icons.expand_more),
        ]),
      ),
    );
  }
}

/// Transports this phone listens on and every drone heard during the report.
class RemoteIdSheet extends ConsumerWidget {
  const RemoteIdSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final d = ref.watch(reportFlowProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.remoteIdTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (d.transports.isEmpty)
            Text(l.remoteIdUnsupported)
          else
            Text(l.remoteIdReceives(d.transports.map((t) => transportLabel(l, t)).join(', '))),
          if (d.remoteIdPermissionMissing) ...[const SizedBox(height: 8), Text(l.remoteIdPermission)],
          const SizedBox(height: 8),
          Text(l.remoteIdCount(d.drones.length), style: Theme.of(context).textTheme.titleSmall),
          for (final drone in d.drones.values) _DroneTile(drone, d.fix?.position),
        ]),
      ),
    );
  }
}

class _DroneTile extends StatelessWidget {
  const _DroneTile(this.drone, this.observer);
  final RemoteIdDrone drone;
  final LatLon? observer;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final pos = drone.lat != null && drone.lon != null ? LatLon(drone.lat!, drone.lon!) : null;
    final height = drone.heightM ?? drone.altGeoM;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.flight),
      title: Text(drone.uasId ?? l.remoteIdUnknownSerial),
      subtitle: Text([
        transportLabel(l, drone.transport),
        if (pos != null && observer != null) l.remoteIdDistance(observer!.distanceTo(pos).round()),
        if (height != null) l.remoteIdHeight(height.round()),
      ].join(' · ')),
    );
  }
}
