import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'informant_localizations_de.dart';
import 'informant_localizations_en.dart';
import 'informant_localizations_fil.dart';
import 'informant_localizations_fr.dart';
import 'informant_localizations_id.dart';
import 'informant_localizations_th.dart';
import 'informant_localizations_vi.dart';
import 'informant_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of InformantL10n
/// returned by `InformantL10n.of(context)`.
///
/// Applications need to include `InformantL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/informant_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: InformantL10n.localizationsDelegates,
///   supportedLocales: InformantL10n.supportedLocales,
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
/// be consistent with the languages listed in the InformantL10n.supportedLocales
/// property.
abstract class InformantL10n {
  InformantL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static InformantL10n of(BuildContext context) {
    return Localizations.of<InformantL10n>(context, InformantL10n)!;
  }

  static const LocalizationsDelegate<InformantL10n> delegate =
      _InformantL10nDelegate();

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

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @notSure.
  ///
  /// In en, this message translates to:
  /// **'Not sure'**
  String get notSure;

  /// No description provided for @onboardingLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get onboardingLanguageTitle;

  /// No description provided for @onboardingLanguageBody.
  ///
  /// In en, this message translates to:
  /// **'You can change this at any time in Settings.'**
  String get onboardingLanguageBody;

  /// No description provided for @onboardingWhatTitle.
  ///
  /// In en, this message translates to:
  /// **'Report suspicious drones, unmanned boats and other craft'**
  String get onboardingWhatTitle;

  /// No description provided for @onboardingWhatBody.
  ///
  /// In en, this message translates to:
  /// **'Seen a drone near an airport or military site, an unmanned boat off the coast, or a craft landing on a beach? Report it in under a minute. Your report goes straight to the agency responsible: police, civil aviation, Coast Guard or defense.'**
  String get onboardingWhatBody;

  /// No description provided for @onboardingSafetyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your safety comes first'**
  String get onboardingSafetyTitle;

  /// No description provided for @onboardingSafetyApproach.
  ///
  /// In en, this message translates to:
  /// **'Never approach or follow the drone operator.'**
  String get onboardingSafetyApproach;

  /// No description provided for @onboardingSafetyDistance.
  ///
  /// In en, this message translates to:
  /// **'Keep your distance from the drone and watch out for traffic around you.'**
  String get onboardingSafetyDistance;

  /// No description provided for @onboardingSafetyDanger.
  ///
  /// In en, this message translates to:
  /// **'If anyone is in danger, call 110 first.'**
  String get onboardingSafetyDanger;

  /// No description provided for @onboardingPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Anonymous by design'**
  String get onboardingPrivacyTitle;

  /// No description provided for @onboardingPrivacyNoAccount.
  ///
  /// In en, this message translates to:
  /// **'We never ask for your name, phone number or an account.'**
  String get onboardingPrivacyNoAccount;

  /// No description provided for @onboardingPrivacyCollected.
  ///
  /// In en, this message translates to:
  /// **'A report contains your location, the direction you point the phone, any photos, video or sound you add, and a random ID created when you installed the app.'**
  String get onboardingPrivacyCollected;

  /// No description provided for @onboardingPrivacyUse.
  ///
  /// In en, this message translates to:
  /// **'Reports are used only by Taiwan government authorities to deal with drone and maritime incidents.'**
  String get onboardingPrivacyUse;

  /// No description provided for @onboardingPermissionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get onboardingPermissionsTitle;

  /// No description provided for @onboardingPermissionsBody.
  ///
  /// In en, this message translates to:
  /// **'Each permission makes your reports more useful. You can say no to any of them and still send reports.'**
  String get onboardingPermissionsBody;

  /// No description provided for @onboardingStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get onboardingStart;

  /// No description provided for @permLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get permLocationTitle;

  /// No description provided for @permLocationBody.
  ///
  /// In en, this message translates to:
  /// **'Puts your report on the map, so officers know where to look.'**
  String get permLocationBody;

  /// No description provided for @permCameraTitle.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get permCameraTitle;

  /// No description provided for @permCameraBody.
  ///
  /// In en, this message translates to:
  /// **'Lets you aim at the drone and take photos or video.'**
  String get permCameraBody;

  /// No description provided for @permMicrophoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Microphone'**
  String get permMicrophoneTitle;

  /// No description provided for @permMicrophoneBody.
  ///
  /// In en, this message translates to:
  /// **'Records the sound of the rotors, which helps identify the type of drone.'**
  String get permMicrophoneBody;

  /// No description provided for @permNearbyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nearby devices (Bluetooth and Wi-Fi)'**
  String get permNearbyTitle;

  /// No description provided for @permNearbyBody.
  ///
  /// In en, this message translates to:
  /// **'Picks up the drone\'s Remote ID broadcast: its serial number, position and sometimes the operator\'s position.'**
  String get permNearbyBody;

  /// No description provided for @permNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get permNotificationsTitle;

  /// No description provided for @permNotificationsBody.
  ///
  /// In en, this message translates to:
  /// **'Tells you when your case is updated. Notifications never contain case details.'**
  String get permNotificationsBody;

  /// No description provided for @permAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get permAllow;

  /// No description provided for @permGranted.
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get permGranted;

  /// No description provided for @permOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get permOpenSettings;

  /// No description provided for @homeReportButton.
  ///
  /// In en, this message translates to:
  /// **'Report a sighting'**
  String get homeReportButton;

  /// No description provided for @homeReportHint.
  ///
  /// In en, this message translates to:
  /// **'Takes less than a minute. No sign-up needed.'**
  String get homeReportHint;

  /// No description provided for @homeMyReports.
  ///
  /// In en, this message translates to:
  /// **'My reports'**
  String get homeMyReports;

  /// No description provided for @homeNoReports.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t sent any reports from this device yet.'**
  String get homeNoReports;

  /// No description provided for @homeZonesMap.
  ///
  /// In en, this message translates to:
  /// **'No-fly zones map'**
  String get homeZonesMap;

  /// No description provided for @homeSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get homeSettings;

  /// No description provided for @homeWebBanner.
  ///
  /// In en, this message translates to:
  /// **'For live sightings, the Android app sends more accurate reports: it measures the direction to the drone and picks up its Remote ID broadcast.'**
  String get homeWebBanner;

  /// No description provided for @homeGetAndroidApp.
  ///
  /// In en, this message translates to:
  /// **'Get the Android app'**
  String get homeGetAndroidApp;

  /// No description provided for @homeEvidenceRequested.
  ///
  /// In en, this message translates to:
  /// **'Evidence requested'**
  String get homeEvidenceRequested;

  /// No description provided for @homePendingSend.
  ///
  /// In en, this message translates to:
  /// **'Waiting to send'**
  String get homePendingSend;

  /// No description provided for @homeStatusOffline.
  ///
  /// In en, this message translates to:
  /// **'Last known status'**
  String get homeStatusOffline;

  /// No description provided for @caseNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Case number'**
  String get caseNumberLabel;

  /// No description provided for @reportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report a sighting'**
  String get reportTitle;

  /// No description provided for @stepAim.
  ///
  /// In en, this message translates to:
  /// **'Aim'**
  String get stepAim;

  /// No description provided for @stepDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get stepDetails;

  /// No description provided for @stepEvidence.
  ///
  /// In en, this message translates to:
  /// **'Evidence'**
  String get stepEvidence;

  /// No description provided for @locationWaiting.
  ///
  /// In en, this message translates to:
  /// **'Finding your location…'**
  String get locationWaiting;

  /// No description provided for @locationAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Location ±{meters} m'**
  String locationAccuracy(int meters);

  /// No description provided for @locationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Location is off or not allowed. Turn it on, or set your position on the map.'**
  String get locationUnavailable;

  /// No description provided for @locationPickOnMap.
  ///
  /// In en, this message translates to:
  /// **'Set on map'**
  String get locationPickOnMap;

  /// No description provided for @locationManual.
  ///
  /// In en, this message translates to:
  /// **'Location set on the map'**
  String get locationManual;

  /// No description provided for @mapPickTitle.
  ///
  /// In en, this message translates to:
  /// **'Tap where you are'**
  String get mapPickTitle;

  /// No description provided for @mapPickConfirm.
  ///
  /// In en, this message translates to:
  /// **'Use this location'**
  String get mapPickConfirm;

  /// No description provided for @remoteIdTitle.
  ///
  /// In en, this message translates to:
  /// **'Remote ID'**
  String get remoteIdTitle;

  /// No description provided for @remoteIdReceives.
  ///
  /// In en, this message translates to:
  /// **'Listening on: {transports}'**
  String remoteIdReceives(String transports);

  /// No description provided for @remoteIdCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No drone broadcasting Remote ID nearby yet} =1{1 drone broadcasting Remote ID} other{{count} drones broadcasting Remote ID}}'**
  String remoteIdCount(int count);

  /// No description provided for @remoteIdUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This phone can\'t receive Remote ID broadcasts.'**
  String get remoteIdUnsupported;

  /// No description provided for @remoteIdPermission.
  ///
  /// In en, this message translates to:
  /// **'Allow \"Nearby devices\" so the app can pick up Remote ID.'**
  String get remoteIdPermission;

  /// No description provided for @remoteIdUnknownSerial.
  ///
  /// In en, this message translates to:
  /// **'Serial number not received'**
  String get remoteIdUnknownSerial;

  /// No description provided for @remoteIdDistance.
  ///
  /// In en, this message translates to:
  /// **'{meters} m away'**
  String remoteIdDistance(int meters);

  /// No description provided for @remoteIdHeight.
  ///
  /// In en, this message translates to:
  /// **'{meters} m high'**
  String remoteIdHeight(int meters);

  /// No description provided for @transportBt4.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth'**
  String get transportBt4;

  /// No description provided for @transportBt5.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth long range'**
  String get transportBt5;

  /// No description provided for @transportWifiBeacon.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi beacon'**
  String get transportWifiBeacon;

  /// No description provided for @transportWifiNan.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi Aware'**
  String get transportWifiNan;

  /// No description provided for @aimInstruction.
  ///
  /// In en, this message translates to:
  /// **'Point the phone at the drone or vessel and tap \"Lock direction\".'**
  String get aimInstruction;

  /// No description provided for @aimBearing.
  ///
  /// In en, this message translates to:
  /// **'Direction'**
  String get aimBearing;

  /// No description provided for @aimElevation.
  ///
  /// In en, this message translates to:
  /// **'Angle up'**
  String get aimElevation;

  /// No description provided for @aimCalibrate.
  ///
  /// In en, this message translates to:
  /// **'The compass needs calibrating: move the phone in a figure 8 a few times.'**
  String get aimCalibrate;

  /// No description provided for @aimNoCompass.
  ///
  /// In en, this message translates to:
  /// **'No compass reading on this device. You can skip this step.'**
  String get aimNoCompass;

  /// No description provided for @aimNoCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera not available'**
  String get aimNoCamera;

  /// No description provided for @aimLock.
  ///
  /// In en, this message translates to:
  /// **'Lock direction'**
  String get aimLock;

  /// No description provided for @aimTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Also take a photo'**
  String get aimTakePhoto;

  /// No description provided for @aimSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip aiming'**
  String get aimSkip;

  /// No description provided for @aimLocked.
  ///
  /// In en, this message translates to:
  /// **'Direction locked: {bearing}°, {elevation}° up'**
  String aimLocked(int bearing, int elevation);

  /// No description provided for @aimAgain.
  ///
  /// In en, this message translates to:
  /// **'Aim again'**
  String get aimAgain;

  /// No description provided for @detailsTitle.
  ///
  /// In en, this message translates to:
  /// **'What did you see?'**
  String get detailsTitle;

  /// No description provided for @detailsOptional.
  ///
  /// In en, this message translates to:
  /// **'Everything here is optional. Skip it if you\'re in a hurry.'**
  String get detailsOptional;

  /// No description provided for @detailsHeight.
  ///
  /// In en, this message translates to:
  /// **'How high was it?'**
  String get detailsHeight;

  /// No description provided for @detailsHeightHint.
  ///
  /// In en, this message translates to:
  /// **'A 10-storey building is about 30 m tall.'**
  String get detailsHeightHint;

  /// No description provided for @heightBelow30.
  ///
  /// In en, this message translates to:
  /// **'Below 30 m'**
  String get heightBelow30;

  /// No description provided for @height30to60.
  ///
  /// In en, this message translates to:
  /// **'30–60 m'**
  String get height30to60;

  /// No description provided for @height60to120.
  ///
  /// In en, this message translates to:
  /// **'60–120 m'**
  String get height60to120;

  /// No description provided for @heightAbove120.
  ///
  /// In en, this message translates to:
  /// **'Above 120 m'**
  String get heightAbove120;

  /// No description provided for @detailsMovement.
  ///
  /// In en, this message translates to:
  /// **'Was it moving?'**
  String get detailsMovement;

  /// No description provided for @movementHovering.
  ///
  /// In en, this message translates to:
  /// **'Hovering'**
  String get movementHovering;

  /// No description provided for @movementMoving.
  ///
  /// In en, this message translates to:
  /// **'Moving'**
  String get movementMoving;

  /// No description provided for @detailsCount.
  ///
  /// In en, this message translates to:
  /// **'How many drones?'**
  String get detailsCount;

  /// No description provided for @countOne.
  ///
  /// In en, this message translates to:
  /// **'1'**
  String get countOne;

  /// No description provided for @countTwo.
  ///
  /// In en, this message translates to:
  /// **'2'**
  String get countTwo;

  /// No description provided for @countThreePlus.
  ///
  /// In en, this message translates to:
  /// **'3 or more'**
  String get countThreePlus;

  /// No description provided for @detailsDescription.
  ///
  /// In en, this message translates to:
  /// **'Anything else? (optional)'**
  String get detailsDescription;

  /// No description provided for @detailsDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'For example: flying over the school yard, red lights, loud buzzing'**
  String get detailsDescriptionHint;

  /// No description provided for @evidenceTitle.
  ///
  /// In en, this message translates to:
  /// **'Photos, video and sound'**
  String get evidenceTitle;

  /// No description provided for @evidenceSpeedNote.
  ///
  /// In en, this message translates to:
  /// **'Sending quickly matters more than perfect evidence. You can send now; files upload in the background.'**
  String get evidenceSpeedNote;

  /// No description provided for @mediaPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get mediaPhoto;

  /// No description provided for @mediaVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get mediaVideo;

  /// No description provided for @mediaAudio.
  ///
  /// In en, this message translates to:
  /// **'Sound recording'**
  String get mediaAudio;

  /// No description provided for @evidenceRecordSound.
  ///
  /// In en, this message translates to:
  /// **'Record sound'**
  String get evidenceRecordSound;

  /// No description provided for @evidenceStopRecording.
  ///
  /// In en, this message translates to:
  /// **'Stop recording'**
  String get evidenceStopRecording;

  /// No description provided for @evidenceRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording rotor sound… {seconds} s'**
  String evidenceRecording(int seconds);

  /// No description provided for @evidenceNone.
  ///
  /// In en, this message translates to:
  /// **'No files added yet.'**
  String get evidenceNone;

  /// No description provided for @evidenceRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove file'**
  String get evidenceRemove;

  /// No description provided for @evidenceAimPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo taken when locking direction'**
  String get evidenceAimPhoto;

  /// No description provided for @evidenceCaptureFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t capture the file. Please try again.'**
  String get evidenceCaptureFailed;

  /// No description provided for @sendNow.
  ///
  /// In en, this message translates to:
  /// **'Send report now'**
  String get sendNow;

  /// No description provided for @sending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get sending;

  /// No description provided for @sendQueuedTitle.
  ///
  /// In en, this message translates to:
  /// **'Report saved'**
  String get sendQueuedTitle;

  /// No description provided for @sendQueuedBody.
  ///
  /// In en, this message translates to:
  /// **'There\'s no connection right now. Your report is saved on this phone and will be sent automatically as soon as you\'re back online.'**
  String get sendQueuedBody;

  /// No description provided for @sendRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many reports have been sent from this device or network recently. Please wait a few minutes and try again. If anyone is in danger, call 110.'**
  String get sendRateLimited;

  /// No description provided for @sendRejected.
  ///
  /// In en, this message translates to:
  /// **'The report could not be accepted: {message}'**
  String sendRejected(String message);

  /// No description provided for @sendFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Report not sent'**
  String get sendFailedTitle;

  /// No description provided for @discardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard this report?'**
  String get discardTitle;

  /// No description provided for @discardBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing has been sent yet.'**
  String get discardBody;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @sentTitle.
  ///
  /// In en, this message translates to:
  /// **'Report sent'**
  String get sentTitle;

  /// No description provided for @sentBody.
  ///
  /// In en, this message translates to:
  /// **'Thank you. Your report has been passed to the responsible agency.'**
  String get sentBody;

  /// No description provided for @sentUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading files: {done} of {total}'**
  String sentUploading(int done, int total);

  /// No description provided for @sentUploadsDone.
  ///
  /// In en, this message translates to:
  /// **'All files uploaded.'**
  String get sentUploadsDone;

  /// No description provided for @sentUploadsBackground.
  ///
  /// In en, this message translates to:
  /// **'Uploads continue in the background, even if you close the app.'**
  String get sentUploadsBackground;

  /// No description provided for @sentUploadsKeepOpen.
  ///
  /// In en, this message translates to:
  /// **'Keep this page open until the files have finished uploading.'**
  String get sentUploadsKeepOpen;

  /// No description provided for @sentKeyNote.
  ///
  /// In en, this message translates to:
  /// **'Only this phone holds the private key for following this report. If you uninstall the app or clear its data, you will no longer see updates.'**
  String get sentKeyNote;

  /// No description provided for @sentKeyNoteWeb.
  ///
  /// In en, this message translates to:
  /// **'Only this browser holds the private key for following this report. If you clear your browser data, you will no longer see updates.'**
  String get sentKeyNoteWeb;

  /// No description provided for @sentAndroidHint.
  ///
  /// In en, this message translates to:
  /// **'Next time, the Android app can measure the drone\'s direction and pick up its Remote ID, which makes your report more useful.'**
  String get sentAndroidHint;

  /// No description provided for @sentViewStatus.
  ///
  /// In en, this message translates to:
  /// **'View status'**
  String get sentViewStatus;

  /// No description provided for @sentBackHome.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get sentBackHome;

  /// No description provided for @caseTitle.
  ///
  /// In en, this message translates to:
  /// **'Case {caseNumber}'**
  String caseTitle(String caseNumber);

  /// No description provided for @caseProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get caseProgress;

  /// No description provided for @caseOutcome.
  ///
  /// In en, this message translates to:
  /// **'Outcome'**
  String get caseOutcome;

  /// No description provided for @caseEvidenceRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests for more evidence'**
  String get caseEvidenceRequests;

  /// No description provided for @caseEvidenceSafety.
  ///
  /// In en, this message translates to:
  /// **'Only send what you can capture safely from where you are.'**
  String get caseEvidenceSafety;

  /// No description provided for @caseEvidenceAnswered.
  ///
  /// In en, this message translates to:
  /// **'Answered — thank you.'**
  String get caseEvidenceAnswered;

  /// No description provided for @caseEvidenceSend.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Send 1 file} other{Send {count} files}}'**
  String caseEvidenceSend(int count);

  /// No description provided for @caseEvidenceSent.
  ///
  /// In en, this message translates to:
  /// **'Thank you. Your files are uploading.'**
  String get caseEvidenceSent;

  /// No description provided for @caseEvidenceClosed.
  ///
  /// In en, this message translates to:
  /// **'This request is no longer open.'**
  String get caseEvidenceClosed;

  /// No description provided for @caseNotOnDevice.
  ///
  /// In en, this message translates to:
  /// **'This report is not stored on this device.'**
  String get caseNotOnDevice;

  /// No description provided for @caseUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String caseUpdated(String time);

  /// No description provided for @zonesTitle.
  ///
  /// In en, this message translates to:
  /// **'No-fly zones'**
  String get zonesTitle;

  /// No description provided for @zonesLegend.
  ///
  /// In en, this message translates to:
  /// **'Legend'**
  String get zonesLegend;

  /// No description provided for @zonesMyLocation.
  ///
  /// In en, this message translates to:
  /// **'My location'**
  String get zonesMyLocation;

  /// No description provided for @zonesNote.
  ///
  /// In en, this message translates to:
  /// **'Shows published CAA drone zones only. Some restricted areas are not shown on public maps.'**
  String get zonesNote;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy and about'**
  String get settingsPrivacy;

  /// No description provided for @settingsPrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'reporting.tw is a Taiwan government service for reporting suspicious drones, unmanned boats and other questionable craft in the air, at sea or on the coast. Reports are anonymous: we never ask for your name, phone number or an account. A report contains your location, the direction you pointed the phone, your answers to the questions, any photos, video or sound you add, Remote ID broadcasts your phone picked up, and a random ID created when the app was installed. Photos may be analysed automatically by an AI model to help officers assess the report. This information is used only by Taiwan authorities to deal with these incidents.'**
  String get settingsPrivacyBody;

  /// No description provided for @settingsClearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear report history'**
  String get settingsClearHistory;

  /// No description provided for @settingsClearHistoryBody.
  ///
  /// In en, this message translates to:
  /// **'This removes your reports and their private follow-up keys from this device. You will no longer see updates or be able to answer requests for these reports. Reports already sent are not withdrawn.'**
  String get settingsClearHistoryBody;

  /// No description provided for @settingsClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get settingsClear;

  /// No description provided for @settingsHistoryCleared.
  ///
  /// In en, this message translates to:
  /// **'Report history cleared.'**
  String get settingsHistoryCleared;

  /// No description provided for @settingsShowIntro.
  ///
  /// In en, this message translates to:
  /// **'Show the introduction again'**
  String get settingsShowIntro;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String settingsVersion(String version);
}

class _InformantL10nDelegate extends LocalizationsDelegate<InformantL10n> {
  const _InformantL10nDelegate();

  @override
  Future<InformantL10n> load(Locale locale) {
    return SynchronousFuture<InformantL10n>(lookupInformantL10n(locale));
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
  bool shouldReload(_InformantL10nDelegate old) => false;
}

InformantL10n lookupInformantL10n(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'TW':
            return InformantL10nZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return InformantL10nDe();
    case 'en':
      return InformantL10nEn();
    case 'fil':
      return InformantL10nFil();
    case 'fr':
      return InformantL10nFr();
    case 'id':
      return InformantL10nId();
    case 'th':
      return InformantL10nTh();
    case 'vi':
      return InformantL10nVi();
    case 'zh':
      return InformantL10nZh();
  }

  throw FlutterError(
    'InformantL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
