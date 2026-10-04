import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_core/uavr_core.dart';
import 'package:uavr_ui/uavr_ui.dart';

import '../common/l10n.dart';
import '../common/labels.dart';
import '../common/run_action.dart';

/// Zones, authorization, permit, registry, weather, ADS-B, Remote ID, severity reasons.
class IncidentPanel extends ConsumerWidget {
  const IncidentPanel({super.key, required this.detail});
  final CaseDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final u = context.u;
    final lang = context.lang;
    final c = detail.summary;
    final inc = detail.incident;
    final permit = inc?.permit;
    final reg = inc?.registryMatch;
    final wx = inc?.weather;
    final serials = {...c.remoteIdSerials, if (reg?['serial'] != null) '${reg!['serial']}'};
    return Section(
      title: l.panelIncident,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 6, runSpacing: 6, children: [
          Pill(authorizationLabel(l, c.authorization), color: authorizationColor(c.authorization), icon: Icons.verified_outlined),
          if (c.sensorConfirmed) Pill(l.sensorConfirmed, color: UavrColors.brand, icon: Icons.sensors),
          for (final z in inc?.zones ?? const <Json>[])
            Pill(
              '${zoneTypeLabel(u, '${z['zone_type']}')}: ${lang == 'zh-TW' ? z['name_zh'] : z['name']}',
              color: UavrColors.zone('${z['zone_type']}'),
              icon: Icons.layers_outlined,
            ),
        ]),
        if (c.severityReasons.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(l.severityReasons, style: Theme.of(context).textTheme.labelLarge),
          for (final r in c.severityReasons)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(children: [const Icon(Icons.chevron_right, size: 16), Expanded(child: Text(severityReasonLabel(l, r)))]),
            ),
        ],
        const Divider(height: 20),
        KeyValue(l.firstSeen, c.firstSeen == null ? null : dateTime(c.firstSeen!)),
        KeyValue(l.lastSeen, c.lastSeen == null ? null : dateTime(c.lastSeen!)),
        KeyValue(l.informantsObservations, '${c.distinctInformants} / ${c.observationCount}'),
        KeyValue(l.confidence, '${(c.confidence * 100).round()}%'),
        KeyValue(l.remoteId, serials.isEmpty ? l.none : serials.join(', '), mono: true),
        const Divider(height: 20),
        Text(l.permit, style: Theme.of(context).textTheme.labelLarge),
        if (permit == null)
          Text(l.noPermitMatched)
        else ...[
          KeyValue(l.permitNo, '${permit['permit_no']}', mono: true),
          KeyValue(l.operatorName, '${permit['operator_name'] ?? '—'}'),
          KeyValue(l.validity, '${_d(permit['valid_from'])} – ${_d(permit['valid_to'])}'),
          KeyValue(l.maxAltitude, permit['max_alt_m'] == null ? null : '${permit['max_alt_m']} m'),
        ],
        const SizedBox(height: 10),
        Text(l.registryMatch, style: Theme.of(context).textTheme.labelLarge),
        if (reg == null)
          Text(l.noRegistryMatch)
        else ...[
          KeyValue(l.serial, '${reg['serial']}', mono: true),
          KeyValue(l.model, '${reg['manufacturer'] ?? ''} ${reg['model'] ?? ''}'.trim()),
          KeyValue(l.registryStatus, '${reg['status'] ?? '—'}'),
        ],
        if (serials.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(spacing: 8, runSpacing: 4, children: [
              for (final s in serials)
                OutlinedButton.icon(
                  key: Key('registry-$s'),
                  onPressed: () => _lookup(context, ref, s),
                  icon: const Icon(Icons.manage_search, size: 18),
                  label: Text('${l.lookUpRegistry}: $s'),
                ),
            ]),
          ),
        if (serials.isNotEmpty) Text(l.auditedNotice, style: Theme.of(context).textTheme.bodySmall),
        const Divider(height: 20),
        Text(l.weather, style: Theme.of(context).textTheme.labelLarge),
        if (wx == null)
          Text(l.none)
        else
          Wrap(spacing: 16, children: [
            if (wx['visibility_m'] != null) Text('${l.visibility}: ${wx['visibility_m']} m'),
            if (wx['wind_speed_mps'] != null) Text('${l.wind}: ${wx['wind_speed_mps']} m/s ${wx['wind_dir_deg'] ?? ''}°'),
            if (wx['station_id'] != null) Text('${l.station}: ${wx['station_id']}'),
          ]),
        const SizedBox(height: 10),
        Text(l.adsbNearby, style: Theme.of(context).textTheme.labelLarge),
        if ((inc?.adsbNearby ?? const []).isEmpty)
          Text(l.none)
        else
          for (final a in inc!.adsbNearby)
            Row(children: [
              const Icon(Icons.airplanemode_active, size: 16, color: Color(0xFF0D47A1)),
              const SizedBox(width: 6),
              Text('${a['callsign'] ?? a['icao24']} · ${a['alt_m'] ?? '—'} m · ${a['distance_m'] != null ? distanceLabel(a['distance_m'] as num) : '—'}'),
            ]),
      ]),
    );
  }

  static String _d(Object? v) {
    final t = v is String ? DateTime.tryParse(v) : null;
    return t == null ? '—' : dateTime(t);
  }

  Future<void> _lookup(BuildContext context, WidgetRef ref, String serial) async {
    final r = await runAction(context, () => ref.read(staffApiProvider).registry(serial));
    if (r == null || !context.mounted) return;
    await showDialog<void>(context: context, builder: (_) => RegistryDialog(r));
  }
}

class RegistryDialog extends StatelessWidget {
  const RegistryDialog(this.r, {super.key});
  final RegistryLookup r;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final e = r.entry;
    return AlertDialog(
      title: Text('${l.registryLookup}: ${r.serial}'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Pill(r.registered ? l.registered : l.notRegistered, color: r.registered ? UavrColors.low : UavrColors.critical),
            const SizedBox(height: 8),
            if (e != null) ...[
              KeyValue(l.registrationNo, '${e['registration_no'] ?? '—'}', mono: true),
              KeyValue(l.owner, '${e['owner_name'] ?? '—'}'),
              KeyValue(l.ownerRef, '${e['owner_ref'] ?? '—'}', mono: true),
              KeyValue(l.model, '${e['manufacturer'] ?? ''} ${e['model'] ?? ''}'.trim()),
              KeyValue(l.mtow, e['mtow_g'] == null ? null : '${e['mtow_g']} g'),
              KeyValue(l.registryStatus, '${e['status'] ?? '—'}'),
            ],
            const Divider(),
            Text(l.permits, style: Theme.of(context).textTheme.labelLarge),
            if (r.permits.isEmpty) Text(l.none),
            for (final p in r.permits)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.assignment_outlined),
                title: Text('${p['permit_no']} · ${p['operator_name'] ?? ''}'),
                subtitle: Text(
                    '${IncidentPanel._d(p['valid_from'])} – ${IncidentPanel._d(p['valid_to'])}${p['max_alt_m'] != null ? ' · ≤${p['max_alt_m']} m' : ''}'),
              ),
            const SizedBox(height: 8),
            Text(l.auditedNotice, style: Theme.of(context).textTheme.bodySmall),
          ]),
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(context.u.close))],
    );
  }
}
