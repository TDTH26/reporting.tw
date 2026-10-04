// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'uavr_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class UavrL10nEn extends UavrL10n {
  UavrL10nEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Suspicious Craft Report';

  @override
  String get demoDisclaimer =>
      'Demo for the “Taiwan Defense Tech Hackathon 2026”. Not an official government service.';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get retry => 'Try again';

  @override
  String get close => 'Close';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get done => 'Done';

  @override
  String get save => 'Save';

  @override
  String get send => 'Send';

  @override
  String get loading => 'Loading…';

  @override
  String get errorGeneric => 'Something went wrong.';

  @override
  String get errorNetwork => 'No connection to the server.';

  @override
  String get offline => 'You are offline';

  @override
  String get severityCritical => 'Critical';

  @override
  String get severityMedium => 'Medium';

  @override
  String get severityLow => 'Low';

  @override
  String get statusReceived => 'Received';

  @override
  String get statusInReview => 'Under review';

  @override
  String get statusInProgress => 'Being handled';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get zoneAirport => 'Airport';

  @override
  String get zoneRed => 'No-fly zone (red)';

  @override
  String get zoneYellow => 'Restricted zone (yellow)';

  @override
  String get zoneMilitary => 'Military area';

  @override
  String get zoneCriticalInfrastructure => 'Critical infrastructure';

  @override
  String get zoneOutlyingStrict => 'Outlying island restricted area';

  @override
  String get zoneResidential => 'Residential area';

  @override
  String get zoneOpen => 'Open area';

  @override
  String get zoneJurisdiction => 'Jurisdiction';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageSelfName => 'English';

  @override
  String get justNow => 'just now';

  @override
  String get emergency110 => 'If anyone is in danger, call 110 now.';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }
}
