import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_maps/uavr_maps.dart';
import 'package:uavr_ui/uavr_ui.dart';

import '../common/console_map.dart';
import '../common/l10n.dart';
import '../common/providers.dart';

/// Estimate + error circle, bearing lines, track, operator, field officers, incident zones.
class CaseMapPanel extends ConsumerStatefulWidget {
  const CaseMapPanel({super.key, required this.detail, this.height = 380});
  final CaseDetail detail;
  final double height;

  @override
  ConsumerState<CaseMapPanel> createState() => _CaseMapPanelState();
}

class _CaseMapPanelState extends ConsumerState<CaseMapPanel> {
  final _map = MapController();

  List<LatLon> get _points {
    final d = widget.detail;
    return [
      ?d.summary.position,
      for (final o in d.observations) ?o.observerPosition,
      ?d.incident?.operatorPosition,
      ...d.summary.track,
    ];
  }

  void _fit() {
    try {
      fitTo(_map, _points, maxZoom: 16);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.detail;
    final l = context.l;
    final zones = ref.watch(staffZonesProvider).value ?? const <Zone>[];
    final codes = {for (final z in d.incident?.zones ?? const <Json>[]) '${z['code']}'};
    final pos = d.summary.position;
    final officers = d.fieldOfficers.where((o) => o.lastPosition != null).toList();
    final op = d.incident?.operatorPosition;
    return Section(
      title: l.panelMap,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      trailing: IconButton(tooltip: l.fitAll, icon: const Icon(Icons.fit_screen, size: 18), onPressed: _fit),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          height: widget.height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: ConsoleMap(
              controller: _map,
              initialCenter: pos == null ? null : ll(pos),
              initialZoom: 14,
              children: [
                ZonesLayer(zones, highlightCodes: codes),
                BearingLinesLayer(d.observations),
                TrackLayer(d.summary.track),
                if (pos != null) EstimateLayer(position: pos, errorM: d.summary.estErrorM, severity: d.summary.severity),
                if (op != null) PointsLayer([op], icon: Icons.person_pin_circle, color: UavrColors.critical, labels: [l.operator]),
                if (officers.isNotEmpty)
                  PointsLayer([for (final o in officers) o.lastPosition!],
                      icon: Icons.local_police, color: UavrColors.brand, labels: [for (final o in officers) o.displayName]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(spacing: 12, children: [
          if (d.summary.estErrorM != null) Text('${l.estError}: ±${d.summary.estErrorM!.round()} m'),
          if (d.summary.estAltitudeM != null) Text('${l.altitude}: ${d.summary.estAltitudeM!.round()} m'),
          if (d.summary.positionSource != null) Text('${l.positionSource}: ${d.summary.positionSource}'),
          if (pos != null) SelectableText(pos.toString()),
        ]),
      ]),
    );
  }
}
