// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'uavr_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class UavrL10nFr extends UavrL10n {
  UavrL10nFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Signalement d\'engins suspects';

  @override
  String get demoDisclaimer =>
      'Démo pour le « Taiwan Defense Tech Hackathon 2026 ». Ce n’est pas un service officiel du gouvernement.';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Annuler';

  @override
  String get retry => 'Réessayer';

  @override
  String get close => 'Fermer';

  @override
  String get back => 'Retour';

  @override
  String get next => 'Suivant';

  @override
  String get done => 'Terminé';

  @override
  String get save => 'Enregistrer';

  @override
  String get send => 'Envoyer';

  @override
  String get loading => 'Chargement…';

  @override
  String get errorGeneric => 'Une erreur s\'est produite.';

  @override
  String get errorNetwork => 'Pas de connexion au serveur.';

  @override
  String get offline => 'Vous êtes hors ligne';

  @override
  String get severityCritical => 'Critique';

  @override
  String get severityMedium => 'Moyen';

  @override
  String get severityLow => 'Faible';

  @override
  String get statusReceived => 'Reçu';

  @override
  String get statusInReview => 'En cours d\'examen';

  @override
  String get statusInProgress => 'En cours de traitement';

  @override
  String get statusCompleted => 'Terminé';

  @override
  String get zoneAirport => 'Aéroport';

  @override
  String get zoneRed => 'Zone interdite de vol (rouge)';

  @override
  String get zoneYellow => 'Zone réglementée (jaune)';

  @override
  String get zoneMilitary => 'Zone militaire';

  @override
  String get zoneCriticalInfrastructure => 'Infrastructure critique';

  @override
  String get zoneOutlyingStrict => 'Zone réglementée des îles périphériques';

  @override
  String get zoneResidential => 'Zone résidentielle';

  @override
  String get zoneOpen => 'Zone libre';

  @override
  String get zoneJurisdiction => 'Compétence territoriale';

  @override
  String get languageLabel => 'Langue';

  @override
  String get languageSelfName => 'Français';

  @override
  String get justNow => 'à l\'instant';

  @override
  String get emergency110 =>
      'Si quelqu\'un est en danger, appelez immédiatement le 110.';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count minutes',
      one: 'il y a 1 minute',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count heures',
      one: 'il y a 1 heure',
    );
    return '$_temp0';
  }
}
