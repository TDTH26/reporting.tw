import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'uavr_localizations_de.dart';
import 'uavr_localizations_en.dart';
import 'uavr_localizations_fil.dart';
import 'uavr_localizations_fr.dart';
import 'uavr_localizations_id.dart';
import 'uavr_localizations_th.dart';
import 'uavr_localizations_vi.dart';
import 'uavr_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of UavrL10n
/// returned by `UavrL10n.of(context)`.
///
/// Applications need to include `UavrL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/uavr_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: UavrL10n.localizationsDelegates,
///   supportedLocales: UavrL10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the UavrL10n.supportedLocales
/// property.
abstract class UavrL10n {
  UavrL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static UavrL10n of(BuildContext context) {
    return Localizations.of<UavrL10n>(context, UavrL10n)!;
  }

  static const LocalizationsDelegate<UavrL10n> delegate = _UavrL10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('fil'),
    Locale('fr'),
    Locale('id'),
    Locale('th'),
    Locale('vi'),
    Locale('zh'),
    Locale('zh', 'TW'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Suspicious Craft Report'**
  String get appName;

  /// Red banner: this deployment is a hackathon demo.
  ///
  /// In en, this message translates to:
  /// **'Demo for the “Taiwan Defense Tech Hackathon 2026”. Not an official government service.'**
  String get demoDisclaimer;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get errorGeneric;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No connection to the server.'**
  String get errorNetwork;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'You are offline'**
  String get offline;

  /// No description provided for @severityCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get severityCritical;

  /// No description provided for @severityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get severityMedium;

  /// No description provided for @severityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get severityLow;

  /// No description provided for @statusReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get statusReceived;

  /// No description provided for @statusInReview.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get statusInReview;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'Being handled'**
  String get statusInProgress;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @zoneAirport.
  ///
  /// In en, this message translates to:
  /// **'Airport'**
  String get zoneAirport;

  /// No description provided for @zoneRed.
  ///
  /// In en, this message translates to:
  /// **'No-fly zone (red)'**
  String get zoneRed;

  /// No description provided for @zoneYellow.
  ///
  /// In en, this message translates to:
  /// **'Restricted zone (yellow)'**
  String get zoneYellow;

  /// No description provided for @zoneMilitary.
  ///
  /// In en, this message translates to:
  /// **'Military area'**
  String get zoneMilitary;

  /// No description provided for @zoneCriticalInfrastructure.
  ///
  /// In en, this message translates to:
  /// **'Critical infrastructure'**
  String get zoneCriticalInfrastructure;

  /// No description provided for @zoneOutlyingStrict.
  ///
  /// In en, this message translates to:
  /// **'Outlying island restricted area'**
  String get zoneOutlyingStrict;

  /// No description provided for @zoneResidential.
  ///
  /// In en, this message translates to:
  /// **'Residential area'**
  String get zoneResidential;

  /// No description provided for @zoneOpen.
  ///
  /// In en, this message translates to:
  /// **'Open area'**
  String get zoneOpen;

  /// No description provided for @zoneJurisdiction.
  ///
  /// In en, this message translates to:
  /// **'Jurisdiction'**
  String get zoneJurisdiction;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @languageSelfName.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageSelfName;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get justNow;

  /// No description provided for @emergency110.
  ///
  /// In en, this message translates to:
  /// **'If anyone is in danger, call 110 now.'**
  String get emergency110;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute ago} other{{count} minutes ago}}'**
  String minutesAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour ago} other{{count} hours ago}}'**
  String hoursAgo(int count);
}

class _UavrL10nDelegate extends LocalizationsDelegate<UavrL10n> {
  const _UavrL10nDelegate();

  @override
  Future<UavrL10n> load(Locale locale) {
    return SynchronousFuture<UavrL10n>(lookupUavrL10n(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'fil',
    'fr',
    'id',
    'th',
    'vi',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_UavrL10nDelegate old) => false;
}

UavrL10n lookupUavrL10n(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'TW':
            return UavrL10nZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return UavrL10nDe();
    case 'en':
      return UavrL10nEn();
    case 'fil':
      return UavrL10nFil();
    case 'fr':
      return UavrL10nFr();
    case 'id':
      return UavrL10nId();
    case 'th':
      return UavrL10nTh();
    case 'vi':
      return UavrL10nVi();
    case 'zh':
      return UavrL10nZh();
  }

  throw FlutterError(
    'UavrL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
