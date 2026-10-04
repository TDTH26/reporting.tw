import 'package:flutter/material.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_ui/uavr_ui.dart';

import '../geo_math.dart';
import '../l10n/field_localizations.dart';

extension FieldL10nX on BuildContext {
  FieldL10n get f => FieldL10n.of(this);
}

String caseStateLabel(FieldL10n l, CaseState s) => switch (s) {
      CaseState.newCase => l.stateNew,
      CaseState.acknowledged => l.stateAcknowledged,
      CaseState.investigating => l.stateInvestigating,
      CaseState.resolved => l.stateResolved,
      CaseState.closed => l.stateClosed,
      CaseState.merged => l.stateMerged,
    };

String authorizationLabel(FieldL10n l, String a) => switch (a) {
      'likely_authorized' => l.authLikelyAuthorized,
      'no_permit' => l.authNoPermit,
      _ => l.authUnknown,
    };

Color authorizationColor(String a) => switch (a) {
      'likely_authorized' => UavrColors.low,
      'no_permit' => UavrColors.critical,
      _ => UavrColors.redacted,
    };

String positionSourceLabel(FieldL10n l, String? s) => switch (s) {
      'remote_id' => l.sourceRemoteId,
      'triangulated' => l.sourceTriangulated,
      'sensor' => l.sourceSensor,
      'informant_projected' => l.sourceInformant,
      _ => s ?? '—',
    };

String compassLabel(FieldL10n l, double bearingDeg) => l.compassPoints.split('|')[compassIndex(bearingDeg)];

/// "1.24 km · 235° SW"
String rangeText(FieldL10n l, LatLon from, LatLon to) {
  final rb = rangeAndBearing(from, to);
  return '${formatDistance(rb.distanceM)} · ${formatBearing(rb.bearingDeg)} ${compassLabel(l, rb.bearingDeg)}';
}

/// Yellow banner shown while data comes from the offline cache.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, this.updatedAt});
  final DateTime? updatedAt;

  @override
  Widget build(BuildContext context) {
    final l = context.f;
    final when = updatedAt == null ? '—' : relativeTime(UavrL10n.of(context), updatedAt!);
    return Material(
      color: const Color(0xFFFFF3CD),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(children: [
          const Icon(Icons.cloud_off, size: 18, color: Color(0xFF8A6D00)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(l.offlineBanner(when), style: const TextStyle(color: Color(0xFF5C4800))),
          ),
        ]),
      ),
    );
  }
}

/// Large distance / bearing readout card on the case screen.
class RangeReadout extends StatelessWidget {
  const RangeReadout({super.key, required this.label, required this.icon, required this.color, this.from, this.to});
  final String label;
  final IconData icon;
  final Color color;
  final LatLon? from, to;

  @override
  Widget build(BuildContext context) {
    final l = context.f;
    final t = Theme.of(context).textTheme;
    String main, sub;
    if (to == null) {
      main = '—';
      sub = l.positionUnknown;
    } else if (from == null) {
      main = '—';
      sub = l.waitingForGps;
    } else {
      final rb = rangeAndBearing(from!, to!);
      main = formatDistance(rb.distanceM);
      sub = '${formatBearing(rb.bearingDeg)} ${compassLabel(l, rb.bearingDeg)}';
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Expanded(child: Text(label, style: t.labelLarge?.copyWith(color: color))),
          ]),
          const SizedBox(height: 6),
          Text(main,
              style: t.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700, fontFeatures: const [FontFeature.tabularFigures()])),
          Text(sub, style: t.titleMedium),
        ]),
      ),
    );
  }
}
