// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'uavr_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Filipino Pilipino (`fil`).
class UavrL10nFil extends UavrL10n {
  UavrL10nFil([String locale = 'fil']) : super(locale);

  @override
  String get appName => 'Ulat sa Kahina-hinalang Sasakyan';

  @override
  String get demoDisclaimer =>
      'Demo para sa “Taiwan Defense Tech Hackathon 2026”. Hindi ito opisyal na serbisyo ng pamahalaan.';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Kanselahin';

  @override
  String get retry => 'Subukan muli';

  @override
  String get close => 'Isara';

  @override
  String get back => 'Bumalik';

  @override
  String get next => 'Susunod';

  @override
  String get done => 'Tapos na';

  @override
  String get save => 'I-save';

  @override
  String get send => 'Ipadala';

  @override
  String get loading => 'Naglo-load…';

  @override
  String get errorGeneric => 'May nangyaring mali.';

  @override
  String get errorNetwork => 'Walang koneksyon sa server.';

  @override
  String get offline => 'Offline ka';

  @override
  String get severityCritical => 'Kritikal';

  @override
  String get severityMedium => 'Katamtaman';

  @override
  String get severityLow => 'Mababa';

  @override
  String get statusReceived => 'Natanggap';

  @override
  String get statusInReview => 'Sinusuri';

  @override
  String get statusInProgress => 'Inaasikaso';

  @override
  String get statusCompleted => 'Tapos na';

  @override
  String get zoneAirport => 'Paliparan';

  @override
  String get zoneRed => 'Bawal lumipad (pula)';

  @override
  String get zoneYellow => 'Limitadong lugar (dilaw)';

  @override
  String get zoneMilitary => 'Lugar militar';

  @override
  String get zoneCriticalInfrastructure => 'Kritikal na imprastraktura';

  @override
  String get zoneOutlyingStrict => 'Restriktadong lugar sa isla';

  @override
  String get zoneResidential => 'Residensyal na lugar';

  @override
  String get zoneOpen => 'Bukas na lugar';

  @override
  String get zoneJurisdiction => 'Hurisdiksyon';

  @override
  String get languageLabel => 'Wika';

  @override
  String get languageSelfName => 'Filipino';

  @override
  String get justNow => 'ngayon lang';

  @override
  String get emergency110 => 'Kung may nasa panganib, tumawag agad sa 110.';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minuto ang nakalipas',
      one: '1 minuto ang nakalipas',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count oras ang nakalipas',
      one: '1 oras ang nakalipas',
    );
    return '$_temp0';
  }
}
