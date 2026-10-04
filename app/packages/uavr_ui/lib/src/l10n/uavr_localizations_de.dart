// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'uavr_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class UavrL10nDe extends UavrL10n {
  UavrL10nDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'Verdächtige Luft/See-Objekte melden';

  @override
  String get demoDisclaimer =>
      'Demo für den „Taiwan Defense Tech Hackathon 2026“. Kein offizieller Behördendienst.';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get close => 'Schließen';

  @override
  String get back => 'Zurück';

  @override
  String get next => 'Weiter';

  @override
  String get done => 'Fertig';

  @override
  String get save => 'Speichern';

  @override
  String get send => 'Senden';

  @override
  String get loading => 'Wird geladen…';

  @override
  String get errorGeneric => 'Etwas ist schiefgelaufen.';

  @override
  String get errorNetwork => 'Keine Verbindung zum Server.';

  @override
  String get offline => 'Sie sind offline';

  @override
  String get severityCritical => 'Kritisch';

  @override
  String get severityMedium => 'Mittel';

  @override
  String get severityLow => 'Niedrig';

  @override
  String get statusReceived => 'Eingegangen';

  @override
  String get statusInReview => 'In Prüfung';

  @override
  String get statusInProgress => 'In Bearbeitung';

  @override
  String get statusCompleted => 'Abgeschlossen';

  @override
  String get zoneAirport => 'Flughafen';

  @override
  String get zoneRed => 'Flugverbotszone (rot)';

  @override
  String get zoneYellow => 'Beschränkte Zone (gelb)';

  @override
  String get zoneMilitary => 'Militärgebiet';

  @override
  String get zoneCriticalInfrastructure => 'Kritische Infrastruktur';

  @override
  String get zoneOutlyingStrict => 'Sperrgebiet auf vorgelagerten Inseln';

  @override
  String get zoneResidential => 'Wohngebiet';

  @override
  String get zoneOpen => 'Freies Gebiet';

  @override
  String get zoneJurisdiction => 'Zuständigkeit';

  @override
  String get languageLabel => 'Sprache';

  @override
  String get languageSelfName => 'Deutsch';

  @override
  String get justNow => 'gerade eben';

  @override
  String get emergency110 =>
      'Wenn jemand in Gefahr ist, rufen Sie sofort 110 an.';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Minuten',
      one: 'vor 1 Minute',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Stunden',
      one: 'vor 1 Stunde',
    );
    return '$_temp0';
  }
}
