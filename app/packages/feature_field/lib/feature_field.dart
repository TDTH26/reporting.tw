/// Field officer app: assigned cases, live drone track, operator position, on-scene Remote ID
/// scan, officer evidence capture with an offline outbox, and offline cache.
library;

export 'src/app.dart' show FieldApp, FieldGate, buildFieldRouter, fieldLocalizationsDelegates;
export 'src/geo_math.dart';
export 'src/l10n/field_localizations.dart';
export 'src/services/live.dart';
export 'src/services/offline_cache.dart';
export 'src/services/outbox.dart';
export 'src/services/sensors.dart';
