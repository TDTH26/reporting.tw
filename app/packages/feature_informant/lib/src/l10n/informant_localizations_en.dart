// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'informant_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class InformantL10nEn extends InformantL10n {
  InformantL10nEn([String locale = 'en']) : super(locale);

  @override
  String get skip => 'Skip';

  @override
  String get notSure => 'Not sure';

  @override
  String get onboardingLanguageTitle => 'Choose your language';

  @override
  String get onboardingLanguageBody =>
      'You can change this at any time in Settings.';

  @override
  String get onboardingWhatTitle =>
      'Report suspicious drones, unmanned boats and other craft';

  @override
  String get onboardingWhatBody =>
      'Seen a drone near an airport or military site, an unmanned boat off the coast, or a craft landing on a beach? Report it in under a minute. Your report goes straight to the agency responsible: police, civil aviation, Coast Guard or defense.';

  @override
  String get onboardingSafetyTitle => 'Your safety comes first';

  @override
  String get onboardingSafetyApproach =>
      'Never approach or follow the drone operator.';

  @override
  String get onboardingSafetyDistance =>
      'Keep your distance from the drone and watch out for traffic around you.';

  @override
  String get onboardingSafetyDanger =>
      'If anyone is in danger, call 110 first.';

  @override
  String get onboardingPrivacyTitle => 'Anonymous by design';

  @override
  String get onboardingPrivacyNoAccount =>
      'We never ask for your name, phone number or an account.';

  @override
  String get onboardingPrivacyCollected =>
      'A report contains your location, the direction you point the phone, any photos, video or sound you add, and a random ID created when you installed the app.';

  @override
  String get onboardingPrivacyUse =>
      'Reports are used only by Taiwan government authorities to deal with drone and maritime incidents.';

  @override
  String get onboardingPermissionsTitle => 'Permissions';

  @override
  String get onboardingPermissionsBody =>
      'Each permission makes your reports more useful. You can say no to any of them and still send reports.';

  @override
  String get onboardingStart => 'Start';

  @override
  String get permLocationTitle => 'Location';

  @override
  String get permLocationBody =>
      'Puts your report on the map, so officers know where to look.';

  @override
  String get permCameraTitle => 'Camera';

  @override
  String get permCameraBody =>
      'Lets you aim at the drone and take photos or video.';

  @override
  String get permMicrophoneTitle => 'Microphone';

  @override
  String get permMicrophoneBody =>
      'Records the sound of the rotors, which helps identify the type of drone.';

  @override
  String get permNearbyTitle => 'Nearby devices (Bluetooth and Wi-Fi)';

  @override
  String get permNearbyBody =>
      'Picks up the drone\'s Remote ID broadcast: its serial number, position and sometimes the operator\'s position.';

  @override
  String get permNotificationsTitle => 'Notifications';

  @override
  String get permNotificationsBody =>
      'Tells you when your case is updated. Notifications never contain case details.';

  @override
  String get permAllow => 'Allow';

  @override
  String get permGranted => 'Allowed';

  @override
  String get permOpenSettings => 'Open settings';

  @override
  String get homeReportButton => 'Report a sighting';

  @override
  String get homeReportHint => 'Takes less than a minute. No sign-up needed.';

  @override
  String get homeMyReports => 'My reports';

  @override
  String get homeNoReports =>
      'You haven\'t sent any reports from this device yet.';

  @override
  String get homeZonesMap => 'No-fly zones map';

  @override
  String get homeSettings => 'Settings';

  @override
  String get homeWebBanner =>
      'For live sightings, the Android app sends more accurate reports: it measures the direction to the drone and picks up its Remote ID broadcast.';

  @override
  String get homeGetAndroidApp => 'Get the Android app';

  @override
  String get homeEvidenceRequested => 'Evidence requested';

  @override
  String get homePendingSend => 'Waiting to send';

  @override
  String get homeStatusOffline => 'Last known status';

  @override
  String get caseNumberLabel => 'Case number';

  @override
  String get reportTitle => 'Report a sighting';

  @override
  String get stepAim => 'Aim';

  @override
  String get stepDetails => 'Details';

  @override
  String get stepEvidence => 'Evidence';

  @override
  String get locationWaiting => 'Finding your location…';

  @override
  String locationAccuracy(int meters) {
    return 'Location ±$meters m';
  }

  @override
  String get locationUnavailable =>
      'Location is off or not allowed. Turn it on, or set your position on the map.';

  @override
  String get locationPickOnMap => 'Set on map';

  @override
  String get locationManual => 'Location set on the map';

  @override
  String get mapPickTitle => 'Tap where you are';

  @override
  String get mapPickConfirm => 'Use this location';

  @override
  String get remoteIdTitle => 'Remote ID';

  @override
  String remoteIdReceives(String transports) {
    return 'Listening on: $transports';
  }

  @override
  String remoteIdCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count drones broadcasting Remote ID',
      one: '1 drone broadcasting Remote ID',
      zero: 'No drone broadcasting Remote ID nearby yet',
    );
    return '$_temp0';
  }

  @override
  String get remoteIdUnsupported =>
      'This phone can\'t receive Remote ID broadcasts.';

  @override
  String get remoteIdPermission =>
      'Allow \"Nearby devices\" so the app can pick up Remote ID.';

  @override
  String get remoteIdUnknownSerial => 'Serial number not received';

  @override
  String remoteIdDistance(int meters) {
    return '$meters m away';
  }

  @override
  String remoteIdHeight(int meters) {
    return '$meters m high';
  }

  @override
  String get transportBt4 => 'Bluetooth';

  @override
  String get transportBt5 => 'Bluetooth long range';

  @override
  String get transportWifiBeacon => 'Wi-Fi beacon';

  @override
  String get transportWifiNan => 'Wi-Fi Aware';

  @override
  String get aimInstruction =>
      'Point the phone at the drone or vessel and tap \"Lock direction\".';

  @override
  String get aimBearing => 'Direction';

  @override
  String get aimElevation => 'Angle up';

  @override
  String get aimCalibrate =>
      'The compass needs calibrating: move the phone in a figure 8 a few times.';

  @override
  String get aimNoCompass =>
      'No compass reading on this device. You can skip this step.';

  @override
  String get aimNoCamera => 'Camera not available';

  @override
  String get aimLock => 'Lock direction';

  @override
  String get aimTakePhoto => 'Also take a photo';

  @override
  String get aimSkip => 'Skip aiming';

  @override
  String aimLocked(int bearing, int elevation) {
    return 'Direction locked: $bearing°, $elevation° up';
  }

  @override
  String get aimAgain => 'Aim again';

  @override
  String get detailsTitle => 'What did you see?';

  @override
  String get detailsOptional =>
      'Everything here is optional. Skip it if you\'re in a hurry.';

  @override
  String get detailsHeight => 'How high was it?';

  @override
  String get detailsHeightHint => 'A 10-storey building is about 30 m tall.';

  @override
  String get heightBelow30 => 'Below 30 m';

  @override
  String get height30to60 => '30–60 m';

  @override
  String get height60to120 => '60–120 m';

  @override
  String get heightAbove120 => 'Above 120 m';

  @override
  String get detailsMovement => 'Was it moving?';

  @override
  String get movementHovering => 'Hovering';

  @override
  String get movementMoving => 'Moving';

  @override
  String get detailsCount => 'How many drones?';

  @override
  String get countOne => '1';

  @override
  String get countTwo => '2';

  @override
  String get countThreePlus => '3 or more';

  @override
  String get detailsDescription => 'Anything else? (optional)';

  @override
  String get detailsDescriptionHint =>
      'For example: flying over the school yard, red lights, loud buzzing';

  @override
  String get evidenceTitle => 'Photos, video and sound';

  @override
  String get evidenceSpeedNote =>
      'Sending quickly matters more than perfect evidence. You can send now; files upload in the background.';

  @override
  String get mediaPhoto => 'Photo';

  @override
  String get mediaVideo => 'Video';

  @override
  String get mediaAudio => 'Sound recording';

  @override
  String get evidenceRecordSound => 'Record sound';

  @override
  String get evidenceStopRecording => 'Stop recording';

  @override
  String evidenceRecording(int seconds) {
    return 'Recording rotor sound… $seconds s';
  }

  @override
  String get evidenceNone => 'No files added yet.';

  @override
  String get evidenceRemove => 'Remove file';

  @override
  String get evidenceAimPhoto => 'Photo taken when locking direction';

  @override
  String get evidenceCaptureFailed =>
      'Couldn\'t capture the file. Please try again.';

  @override
  String get sendNow => 'Send report now';

  @override
  String get sending => 'Sending…';

  @override
  String get sendQueuedTitle => 'Report saved';

  @override
  String get sendQueuedBody =>
      'There\'s no connection right now. Your report is saved on this phone and will be sent automatically as soon as you\'re back online.';

  @override
  String get sendRateLimited =>
      'Too many reports have been sent from this device or network recently. Please wait a few minutes and try again. If anyone is in danger, call 110.';

  @override
  String sendRejected(String message) {
    return 'The report could not be accepted: $message';
  }

  @override
  String get sendFailedTitle => 'Report not sent';

  @override
  String get discardTitle => 'Discard this report?';

  @override
  String get discardBody => 'Nothing has been sent yet.';

  @override
  String get discard => 'Discard';

  @override
  String get sentTitle => 'Report sent';

  @override
  String get sentBody =>
      'Thank you. Your report has been passed to the responsible agency.';

  @override
  String sentUploading(int done, int total) {
    return 'Uploading files: $done of $total';
  }

  @override
  String get sentUploadsDone => 'All files uploaded.';

  @override
  String get sentUploadsBackground =>
      'Uploads continue in the background, even if you close the app.';

  @override
  String get sentUploadsKeepOpen =>
      'Keep this page open until the files have finished uploading.';

  @override
  String get sentKeyNote =>
      'Only this phone holds the private key for following this report. If you uninstall the app or clear its data, you will no longer see updates.';

  @override
  String get sentKeyNoteWeb =>
      'Only this browser holds the private key for following this report. If you clear your browser data, you will no longer see updates.';

  @override
  String get sentAndroidHint =>
      'Next time, the Android app can measure the drone\'s direction and pick up its Remote ID, which makes your report more useful.';

  @override
  String get sentViewStatus => 'View status';

  @override
  String get sentBackHome => 'Back to home';

  @override
  String caseTitle(String caseNumber) {
    return 'Case $caseNumber';
  }

  @override
  String get caseProgress => 'Progress';

  @override
  String get caseOutcome => 'Outcome';

  @override
  String get caseEvidenceRequests => 'Requests for more evidence';

  @override
  String get caseEvidenceSafety =>
      'Only send what you can capture safely from where you are.';

  @override
  String get caseEvidenceAnswered => 'Answered — thank you.';

  @override
  String caseEvidenceSend(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Send $count files',
      one: 'Send 1 file',
    );
    return '$_temp0';
  }

  @override
  String get caseEvidenceSent => 'Thank you. Your files are uploading.';

  @override
  String get caseEvidenceClosed => 'This request is no longer open.';

  @override
  String get caseNotOnDevice => 'This report is not stored on this device.';

  @override
  String caseUpdated(String time) {
    return 'Updated $time';
  }

  @override
  String get zonesTitle => 'No-fly zones';

  @override
  String get zonesLegend => 'Legend';

  @override
  String get zonesMyLocation => 'My location';

  @override
  String get zonesNote =>
      'Shows published CAA drone zones only. Some restricted areas are not shown on public maps.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsPrivacy => 'Privacy and about';

  @override
  String get settingsPrivacyBody =>
      'reporting.tw is a Taiwan government service for reporting suspicious drones, unmanned boats and other questionable craft in the air, at sea or on the coast. Reports are anonymous: we never ask for your name, phone number or an account. A report contains your location, the direction you pointed the phone, your answers to the questions, any photos, video or sound you add, Remote ID broadcasts your phone picked up, and a random ID created when the app was installed. Photos may be analysed automatically by an AI model to help officers assess the report. This information is used only by Taiwan authorities to deal with these incidents.';

  @override
  String get settingsClearHistory => 'Clear report history';

  @override
  String get settingsClearHistoryBody =>
      'This removes your reports and their private follow-up keys from this device. You will no longer see updates or be able to answer requests for these reports. Reports already sent are not withdrawn.';

  @override
  String get settingsClear => 'Clear';

  @override
  String get settingsHistoryCleared => 'Report history cleared.';

  @override
  String get settingsShowIntro => 'Show the introduction again';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }
}
