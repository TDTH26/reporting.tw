import 'package:flutter/widgets.dart';

import 'l10n/uavr_localizations.dart';

extension UavrL10nX on BuildContext {
  UavrL10n get u => UavrL10n.of(this);
}

String severityLabel(UavrL10n l, int s) => switch (s) {
      3 => l.severityCritical,
      2 => l.severityMedium,
      _ => l.severityLow,
    };

/// Informant-facing status (received, in_review, in_progress, completed).
String informantStatusLabel(UavrL10n l, String s) => switch (s) {
      'received' => l.statusReceived,
      'in_review' => l.statusInReview,
      'in_progress' => l.statusInProgress,
      'completed' => l.statusCompleted,
      _ => s,
    };

String zoneTypeLabel(UavrL10n l, String t) => switch (t) {
      'airport' => l.zoneAirport,
      'red' => l.zoneRed,
      'yellow' => l.zoneYellow,
      'military' => l.zoneMilitary,
      'critical_infrastructure' => l.zoneCriticalInfrastructure,
      'outlying_islands_strict' => l.zoneOutlyingStrict,
      'residential' => l.zoneResidential,
      'open' => l.zoneOpen,
      _ => l.zoneJurisdiction,
    };

String relativeTime(UavrL10n l, DateTime t, {DateTime? now}) {
  final d = (now ?? DateTime.now()).difference(t);
  if (d.inMinutes < 1) return l.justNow;
  if (d.inMinutes < 60) return l.minutesAgo(d.inMinutes);
  if (d.inHours < 48) return l.hoursAgo(d.inHours);
  final lt = t.toLocal();
  return '${lt.year}-${_pad(lt.month)}-${_pad(lt.day)}';
}

String clockTime(DateTime t) {
  final lt = t.toLocal();
  return '${_pad(lt.hour)}:${_pad(lt.minute)}:${_pad(lt.second)}';
}

String dateTime(DateTime t) {
  final lt = t.toLocal();
  return '${lt.year}-${_pad(lt.month)}-${_pad(lt.day)} ${_pad(lt.hour)}:${_pad(lt.minute)}';
}

String _pad(int v) => v.toString().padLeft(2, '0');
