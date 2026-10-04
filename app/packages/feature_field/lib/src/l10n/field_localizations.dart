import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'field_localizations_en.dart';
import 'field_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of FieldL10n
/// returned by `FieldL10n.of(context)`.
///
/// Applications need to include `FieldL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/field_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: FieldL10n.localizationsDelegates,
///   supportedLocales: FieldL10n.supportedLocales,
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
/// be consistent with the languages listed in the FieldL10n.supportedLocales
/// property.
abstract class FieldL10n {
  FieldL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static FieldL10n of(BuildContext context) {
    return Localizations.of<FieldL10n>(context, FieldL10n)!;
  }

  static const LocalizationsDelegate<FieldL10n> delegate = _FieldL10nDelegate();

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
    Locale('en'),
    Locale('zh'),
    Locale('zh', 'TW'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Suspicious Craft Report – Field'**
  String get appTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Field officer app. Sign in with your agency account.'**
  String get loginSubtitle;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signInFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed. Check your connection and try again.'**
  String get signInFailed;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sign out of the field app?'**
  String get signOutConfirm;

  /// No description provided for @signOutPendingWarning.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 unsent observation will be deleted.} other{{count} unsent observations will be deleted.}} Sign out anyway?'**
  String signOutPendingWarning(int count);

  /// No description provided for @mdmNote.
  ///
  /// In en, this message translates to:
  /// **'This device is managed by your agency. If it is lost or stolen, report it immediately: it will be wiped remotely (MDM).'**
  String get mdmNote;

  /// No description provided for @noAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'No field officer access'**
  String get noAccessTitle;

  /// No description provided for @noAccessBody.
  ///
  /// In en, this message translates to:
  /// **'Your account does not have the field officer role. Contact your unit administrator.'**
  String get noAccessBody;

  /// No description provided for @assignmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'My assignments'**
  String get assignmentsTitle;

  /// No description provided for @noAssignments.
  ///
  /// In en, this message translates to:
  /// **'No cases are assigned to you right now.'**
  String get noAssignments;

  /// No description provided for @outboxTitle.
  ///
  /// In en, this message translates to:
  /// **'Outbox'**
  String get outboxTitle;

  /// No description provided for @outboxEmpty.
  ///
  /// In en, this message translates to:
  /// **'Everything has been sent.'**
  String get outboxEmpty;

  /// No description provided for @outboxExplanation.
  ///
  /// In en, this message translates to:
  /// **'Observations saved on this device that have not reached the server yet. They are retried automatically when the connection returns.'**
  String get outboxExplanation;

  /// No description provided for @retryNow.
  ///
  /// In en, this message translates to:
  /// **'Retry now'**
  String get retryNow;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get discard;

  /// No description provided for @discardConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this unsent observation? This cannot be undone.'**
  String get discardConfirm;

  /// No description provided for @attempts.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 attempt} other{{count} attempts}}'**
  String attempts(int count);

  /// No description provided for @mediaCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file} other{{count} files}}'**
  String mediaCount(int count);

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected by server'**
  String get rejected;

  /// No description provided for @offlineBanner.
  ///
  /// In en, this message translates to:
  /// **'Offline — last updated {when}'**
  String offlineBanner(String when);

  /// No description provided for @defenseFieldUnit.
  ///
  /// In en, this message translates to:
  /// **'Defense field unit'**
  String get defenseFieldUnit;

  /// No description provided for @caseTitle.
  ///
  /// In en, this message translates to:
  /// **'Case'**
  String get caseTitle;

  /// No description provided for @caseUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This case is no longer assigned to you or is not available.'**
  String get caseUnavailable;

  /// No description provided for @stateNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get stateNew;

  /// No description provided for @stateAcknowledged.
  ///
  /// In en, this message translates to:
  /// **'Acknowledged'**
  String get stateAcknowledged;

  /// No description provided for @stateInvestigating.
  ///
  /// In en, this message translates to:
  /// **'Investigating'**
  String get stateInvestigating;

  /// No description provided for @stateResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get stateResolved;

  /// No description provided for @stateClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get stateClosed;

  /// No description provided for @stateMerged.
  ///
  /// In en, this message translates to:
  /// **'Merged'**
  String get stateMerged;

  /// No description provided for @authLikelyAuthorized.
  ///
  /// In en, this message translates to:
  /// **'Likely authorized'**
  String get authLikelyAuthorized;

  /// No description provided for @authNoPermit.
  ///
  /// In en, this message translates to:
  /// **'No permit'**
  String get authNoPermit;

  /// No description provided for @authUnknown.
  ///
  /// In en, this message translates to:
  /// **'Authorization unknown'**
  String get authUnknown;

  /// No description provided for @sourceRemoteId.
  ///
  /// In en, this message translates to:
  /// **'Remote ID'**
  String get sourceRemoteId;

  /// No description provided for @sourceTriangulated.
  ///
  /// In en, this message translates to:
  /// **'Triangulated'**
  String get sourceTriangulated;

  /// No description provided for @sourceSensor.
  ///
  /// In en, this message translates to:
  /// **'Sensor'**
  String get sourceSensor;

  /// No description provided for @sourceInformant.
  ///
  /// In en, this message translates to:
  /// **'Informant estimate'**
  String get sourceInformant;

  /// No description provided for @compassPoints.
  ///
  /// In en, this message translates to:
  /// **'N|NE|E|SE|S|SW|W|NW'**
  String get compassPoints;

  /// No description provided for @positionUnknown.
  ///
  /// In en, this message translates to:
  /// **'Position unknown'**
  String get positionUnknown;

  /// No description provided for @waitingForGps.
  ///
  /// In en, this message translates to:
  /// **'Waiting for GPS…'**
  String get waitingForGps;

  /// No description provided for @gpsAccuracy.
  ///
  /// In en, this message translates to:
  /// **'GPS ±{meters} m'**
  String gpsAccuracy(int meters);

  /// No description provided for @lastSeen.
  ///
  /// In en, this message translates to:
  /// **'Last seen {when}'**
  String lastSeen(String when);

  /// No description provided for @redactedShort.
  ///
  /// In en, this message translates to:
  /// **'Restricted'**
  String get redactedShort;

  /// No description provided for @redactedExplanation.
  ///
  /// In en, this message translates to:
  /// **'This is a classified defense case. Only defense field units can see its details; you see the location, time and severity only. Follow your dispatcher\'s instructions.'**
  String get redactedExplanation;

  /// No description provided for @sensorConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Sensor confirmed'**
  String get sensorConfirmed;

  /// No description provided for @operator.
  ///
  /// In en, this message translates to:
  /// **'Operator'**
  String get operator;

  /// No description provided for @me.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get me;

  /// No description provided for @fitMap.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get fitMap;

  /// No description provided for @toDrone.
  ///
  /// In en, this message translates to:
  /// **'Drone'**
  String get toDrone;

  /// No description provided for @toOperator.
  ///
  /// In en, this message translates to:
  /// **'Operator position'**
  String get toOperator;

  /// No description provided for @positionSharingOn.
  ///
  /// In en, this message translates to:
  /// **'Sharing my position with the dispatcher (tap to stop)'**
  String get positionSharingOn;

  /// No description provided for @positionSharingOff.
  ///
  /// In en, this message translates to:
  /// **'Position sharing off (tap to share)'**
  String get positionSharingOff;

  /// No description provided for @basicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic information'**
  String get basicInfo;

  /// No description provided for @severity.
  ///
  /// In en, this message translates to:
  /// **'Severity'**
  String get severity;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @firstSeenLabel.
  ///
  /// In en, this message translates to:
  /// **'First seen'**
  String get firstSeenLabel;

  /// No description provided for @lastSeenLabel.
  ///
  /// In en, this message translates to:
  /// **'Last seen'**
  String get lastSeenLabel;

  /// No description provided for @remoteIdScan.
  ///
  /// In en, this message translates to:
  /// **'Remote ID scan'**
  String get remoteIdScan;

  /// No description provided for @captureEvidence.
  ///
  /// In en, this message translates to:
  /// **'Capture evidence'**
  String get captureEvidence;

  /// No description provided for @incidentFacts.
  ///
  /// In en, this message translates to:
  /// **'Incident'**
  String get incidentFacts;

  /// No description provided for @positionSource.
  ///
  /// In en, this message translates to:
  /// **'Position from'**
  String get positionSource;

  /// No description provided for @estError.
  ///
  /// In en, this message translates to:
  /// **'Position error'**
  String get estError;

  /// No description provided for @estAltitude.
  ///
  /// In en, this message translates to:
  /// **'Estimated altitude'**
  String get estAltitude;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Observations'**
  String get reports;

  /// No description provided for @distinctInformants.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 informant} other{{count} informants}}'**
  String distinctInformants(int count);

  /// No description provided for @authorization.
  ///
  /// In en, this message translates to:
  /// **'Authorization'**
  String get authorization;

  /// No description provided for @zones.
  ///
  /// In en, this message translates to:
  /// **'Zones'**
  String get zones;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @permit.
  ///
  /// In en, this message translates to:
  /// **'Permit'**
  String get permit;

  /// No description provided for @permitNo.
  ///
  /// In en, this message translates to:
  /// **'Permit no.'**
  String get permitNo;

  /// No description provided for @operatorName.
  ///
  /// In en, this message translates to:
  /// **'Operator'**
  String get operatorName;

  /// No description provided for @validity.
  ///
  /// In en, this message translates to:
  /// **'Valid'**
  String get validity;

  /// No description provided for @maxAltitude.
  ///
  /// In en, this message translates to:
  /// **'Max. altitude'**
  String get maxAltitude;

  /// No description provided for @remoteIdSerials.
  ///
  /// In en, this message translates to:
  /// **'Remote ID'**
  String get remoteIdSerials;

  /// No description provided for @registryMatch.
  ///
  /// In en, this message translates to:
  /// **'Registry match'**
  String get registryMatch;

  /// No description provided for @noRemoteId.
  ///
  /// In en, this message translates to:
  /// **'No Remote ID received for this case.'**
  String get noRemoteId;

  /// No description provided for @registryLookup.
  ///
  /// In en, this message translates to:
  /// **'Registry'**
  String get registryLookup;

  /// No description provided for @registryTitle.
  ///
  /// In en, this message translates to:
  /// **'Registry: {serial}'**
  String registryTitle(String serial);

  /// No description provided for @registryFailed.
  ///
  /// In en, this message translates to:
  /// **'Registry lookup failed.'**
  String get registryFailed;

  /// No description provided for @registered.
  ///
  /// In en, this message translates to:
  /// **'Registered'**
  String get registered;

  /// No description provided for @notRegistered.
  ///
  /// In en, this message translates to:
  /// **'Not registered'**
  String get notRegistered;

  /// No description provided for @registrationNo.
  ///
  /// In en, this message translates to:
  /// **'Registration no.'**
  String get registrationNo;

  /// No description provided for @owner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get owner;

  /// No description provided for @model.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get model;

  /// No description provided for @mtow.
  ///
  /// In en, this message translates to:
  /// **'Max. take-off weight'**
  String get mtow;

  /// No description provided for @registryStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get registryStatus;

  /// No description provided for @permits.
  ///
  /// In en, this message translates to:
  /// **'Permits'**
  String get permits;

  /// No description provided for @adsbNearby.
  ///
  /// In en, this message translates to:
  /// **'Manned aircraft nearby (ADS-B)'**
  String get adsbNearby;

  /// No description provided for @weather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get weather;

  /// No description provided for @weatherStation.
  ///
  /// In en, this message translates to:
  /// **'Station'**
  String get weatherStation;

  /// No description provided for @visibility.
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get visibility;

  /// No description provided for @wind.
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get wind;

  /// No description provided for @observationsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 observation} other{{count} observations}}'**
  String observationsCount(int count);

  /// No description provided for @srcFieldOfficer.
  ///
  /// In en, this message translates to:
  /// **'Field officer'**
  String get srcFieldOfficer;

  /// No description provided for @srcRemoteId.
  ///
  /// In en, this message translates to:
  /// **'Remote ID receiver'**
  String get srcRemoteId;

  /// No description provided for @srcRfSensor.
  ///
  /// In en, this message translates to:
  /// **'RF sensor'**
  String get srcRfSensor;

  /// No description provided for @srcMdaSensor.
  ///
  /// In en, this message translates to:
  /// **'Maritime sensor (MDA)'**
  String get srcMdaSensor;

  /// No description provided for @srcRadar.
  ///
  /// In en, this message translates to:
  /// **'Radar'**
  String get srcRadar;

  /// No description provided for @srcInformant.
  ///
  /// In en, this message translates to:
  /// **'Public report'**
  String get srcInformant;

  /// No description provided for @fieldOfficers.
  ///
  /// In en, this message translates to:
  /// **'Assigned officers'**
  String get fieldOfficers;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @noteHint.
  ///
  /// In en, this message translates to:
  /// **'Add a note for the desk…'**
  String get noteHint;

  /// No description provided for @addNote.
  ///
  /// In en, this message translates to:
  /// **'Add note'**
  String get addNote;

  /// No description provided for @noteAdded.
  ///
  /// In en, this message translates to:
  /// **'Note added.'**
  String get noteAdded;

  /// No description provided for @noteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not add the note (offline?).'**
  String get noteFailed;

  /// No description provided for @restartScan.
  ///
  /// In en, this message translates to:
  /// **'Restart scan'**
  String get restartScan;

  /// No description provided for @scanFor.
  ///
  /// In en, this message translates to:
  /// **'Drones received by this phone. Attach one to case {caseNumber} to add its Remote ID and position as on-scene evidence.'**
  String scanFor(String caseNumber);

  /// No description provided for @capBt4.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth 4'**
  String get capBt4;

  /// No description provided for @capBt5.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth 5 long range'**
  String get capBt5;

  /// No description provided for @capWifiBeacon.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi Beacon'**
  String get capWifiBeacon;

  /// No description provided for @capWifiNan.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi NAN'**
  String get capWifiNan;

  /// No description provided for @noRemoteIdHardware.
  ///
  /// In en, this message translates to:
  /// **'This device cannot receive Remote ID (no supported Bluetooth / Wi-Fi receiver).'**
  String get noRemoteIdHardware;

  /// No description provided for @scanPermissionError.
  ///
  /// In en, this message translates to:
  /// **'Remote ID scanning needs the Nearby devices (Bluetooth / Wi-Fi) and Location permissions. Grant them, or enable them in Settings.'**
  String get scanPermissionError;

  /// No description provided for @scanPermissionPartial.
  ///
  /// In en, this message translates to:
  /// **'Some permissions are missing; only some transports are being scanned.'**
  String get scanPermissionPartial;

  /// No description provided for @grantPermission.
  ///
  /// In en, this message translates to:
  /// **'Grant'**
  String get grantPermission;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get openSettings;

  /// No description provided for @scanError.
  ///
  /// In en, this message translates to:
  /// **'Scan error: {error}'**
  String scanError(String error);

  /// No description provided for @scanningNoDrones.
  ///
  /// In en, this message translates to:
  /// **'Scanning… no Remote ID broadcasts received yet.'**
  String get scanningNoDrones;

  /// No description provided for @unknownSerial.
  ///
  /// In en, this message translates to:
  /// **'Unknown ID'**
  String get unknownSerial;

  /// No description provided for @live.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get live;

  /// No description provided for @secondsAgo.
  ///
  /// In en, this message translates to:
  /// **'{seconds} s ago'**
  String secondsAgo(int seconds);

  /// No description provided for @idType.
  ///
  /// In en, this message translates to:
  /// **'ID type'**
  String get idType;

  /// No description provided for @idTypeSerial.
  ///
  /// In en, this message translates to:
  /// **'Serial number'**
  String get idTypeSerial;

  /// No description provided for @idTypeCaa.
  ///
  /// In en, this message translates to:
  /// **'CAA registration'**
  String get idTypeCaa;

  /// No description provided for @idTypeUtm.
  ///
  /// In en, this message translates to:
  /// **'UTM assigned'**
  String get idTypeUtm;

  /// No description provided for @idTypeSession.
  ///
  /// In en, this message translates to:
  /// **'Session ID'**
  String get idTypeSession;

  /// No description provided for @uaType.
  ///
  /// In en, this message translates to:
  /// **'Aircraft type'**
  String get uaType;

  /// No description provided for @dronePosition.
  ///
  /// In en, this message translates to:
  /// **'Drone position'**
  String get dronePosition;

  /// No description provided for @fromMe.
  ///
  /// In en, this message translates to:
  /// **'From me'**
  String get fromMe;

  /// No description provided for @height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get height;

  /// No description provided for @altGeo.
  ///
  /// In en, this message translates to:
  /// **'geo.'**
  String get altGeo;

  /// No description provided for @speedDirection.
  ///
  /// In en, this message translates to:
  /// **'Speed / direction'**
  String get speedDirection;

  /// No description provided for @operatorPosition.
  ///
  /// In en, this message translates to:
  /// **'Operator position'**
  String get operatorPosition;

  /// No description provided for @operatorFromMe.
  ///
  /// In en, this message translates to:
  /// **'Operator from me'**
  String get operatorFromMe;

  /// No description provided for @operatorId.
  ///
  /// In en, this message translates to:
  /// **'Operator ID'**
  String get operatorId;

  /// No description provided for @selfId.
  ///
  /// In en, this message translates to:
  /// **'Self ID'**
  String get selfId;

  /// No description provided for @transport.
  ///
  /// In en, this message translates to:
  /// **'Received via'**
  String get transport;

  /// No description provided for @rssi.
  ///
  /// In en, this message translates to:
  /// **'Signal'**
  String get rssi;

  /// No description provided for @attachToCase.
  ///
  /// In en, this message translates to:
  /// **'Attach to case'**
  String get attachToCase;

  /// No description provided for @attachAgain.
  ///
  /// In en, this message translates to:
  /// **'Attached – attach again'**
  String get attachAgain;

  /// No description provided for @noGpsFix.
  ///
  /// In en, this message translates to:
  /// **'No GPS fix yet. Move to open sky and try again.'**
  String get noGpsFix;

  /// No description provided for @observationSent.
  ///
  /// In en, this message translates to:
  /// **'Sent to the case.'**
  String get observationSent;

  /// No description provided for @observationQueued.
  ///
  /// In en, this message translates to:
  /// **'Saved to the outbox; it will be sent when the connection returns.'**
  String get observationQueued;

  /// No description provided for @observationDuplicate.
  ///
  /// In en, this message translates to:
  /// **'The server already has this observation.'**
  String get observationDuplicate;

  /// No description provided for @observationRejected.
  ///
  /// In en, this message translates to:
  /// **'The server rejected this observation. See the outbox.'**
  String get observationRejected;

  /// No description provided for @evidenceFor.
  ///
  /// In en, this message translates to:
  /// **'Evidence for case {caseNumber}. Files are hashed on capture and uploaded in the background.'**
  String evidenceFor(String caseNumber);

  /// No description provided for @media.
  ///
  /// In en, this message translates to:
  /// **'Photo / video / audio'**
  String get media;

  /// No description provided for @photo.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photo;

  /// No description provided for @video.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get video;

  /// No description provided for @audio.
  ///
  /// In en, this message translates to:
  /// **'Rotor audio'**
  String get audio;

  /// No description provided for @stopAudio.
  ///
  /// In en, this message translates to:
  /// **'Stop recording'**
  String get stopAudio;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @captureFailed.
  ///
  /// In en, this message translates to:
  /// **'Capture failed.'**
  String get captureFailed;

  /// No description provided for @micPermission.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission is needed to record audio.'**
  String get micPermission;

  /// No description provided for @bearing.
  ///
  /// In en, this message translates to:
  /// **'Bearing to the drone'**
  String get bearing;

  /// No description provided for @bearingHint.
  ///
  /// In en, this message translates to:
  /// **'Optional: switch on, point the back of the phone at the drone and lock the bearing.'**
  String get bearingHint;

  /// No description provided for @waitingForCompass.
  ///
  /// In en, this message translates to:
  /// **'Waiting for compass…'**
  String get waitingForCompass;

  /// No description provided for @elevation.
  ///
  /// In en, this message translates to:
  /// **'Elevation {degrees}°'**
  String elevation(int degrees);

  /// No description provided for @compassLowAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Compass accuracy is low: move the phone in a figure 8 to calibrate.'**
  String get compassLowAccuracy;

  /// No description provided for @lockBearing.
  ///
  /// In en, this message translates to:
  /// **'Lock bearing'**
  String get lockBearing;

  /// No description provided for @lockedBearing.
  ///
  /// In en, this message translates to:
  /// **'Locked: {bearing}, elevation {elevation}°'**
  String lockedBearing(String bearing, int elevation);

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @evidenceNoteHint.
  ///
  /// In en, this message translates to:
  /// **'What do you see? (drone type, operator, activity)'**
  String get evidenceNoteHint;

  /// No description provided for @submitEvidence.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submitEvidence;

  /// No description provided for @craft.
  ///
  /// In en, this message translates to:
  /// **'Craft'**
  String get craft;

  /// No description provided for @darkVessel.
  ///
  /// In en, this message translates to:
  /// **'Dark vessel: no AIS transmitter nearby'**
  String get darkVessel;

  /// No description provided for @aiAssessment.
  ///
  /// In en, this message translates to:
  /// **'AI assessment (advisory)'**
  String get aiAssessment;

  /// No description provided for @loginUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get loginUsername;

  /// No description provided for @loginPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPassword;

  /// No description provided for @loginWrongCredentials.
  ///
  /// In en, this message translates to:
  /// **'Wrong username or password.'**
  String get loginWrongCredentials;

  /// No description provided for @loginLocked.
  ///
  /// In en, this message translates to:
  /// **'Too many failed attempts. The account is locked for 15 minutes.'**
  String get loginLocked;

  /// No description provided for @loginTooMany.
  ///
  /// In en, this message translates to:
  /// **'Too many login attempts from this network. Try again later.'**
  String get loginTooMany;
}

class _FieldL10nDelegate extends LocalizationsDelegate<FieldL10n> {
  const _FieldL10nDelegate();

  @override
  Future<FieldL10n> load(Locale locale) {
    return SynchronousFuture<FieldL10n>(lookupFieldL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_FieldL10nDelegate old) => false;
}

FieldL10n lookupFieldL10n(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'TW':
            return FieldL10nZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return FieldL10nEn();
    case 'zh':
      return FieldL10nZh();
  }

  throw FlutterError(
    'FieldL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
