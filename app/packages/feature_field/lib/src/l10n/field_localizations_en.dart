// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'field_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class FieldL10nEn extends FieldL10n {
  FieldL10nEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Suspicious Craft Report – Field';

  @override
  String get loginSubtitle =>
      'Field officer app. Sign in with your agency account.';

  @override
  String get signIn => 'Sign in';

  @override
  String get signInFailed =>
      'Sign-in failed. Check your connection and try again.';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutConfirm => 'Sign out of the field app?';

  @override
  String signOutPendingWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unsent observations will be deleted.',
      one: '1 unsent observation will be deleted.',
    );
    return '$_temp0 Sign out anyway?';
  }

  @override
  String get mdmNote =>
      'This device is managed by your agency. If it is lost or stolen, report it immediately: it will be wiped remotely (MDM).';

  @override
  String get noAccessTitle => 'No field officer access';

  @override
  String get noAccessBody =>
      'Your account does not have the field officer role. Contact your unit administrator.';

  @override
  String get assignmentsTitle => 'My assignments';

  @override
  String get noAssignments => 'No cases are assigned to you right now.';

  @override
  String get outboxTitle => 'Outbox';

  @override
  String get outboxEmpty => 'Everything has been sent.';

  @override
  String get outboxExplanation =>
      'Observations saved on this device that have not reached the server yet. They are retried automatically when the connection returns.';

  @override
  String get retryNow => 'Retry now';

  @override
  String get discard => 'Delete';

  @override
  String get discardConfirm =>
      'Delete this unsent observation? This cannot be undone.';

  @override
  String attempts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count attempts',
      one: '1 attempt',
    );
    return '$_temp0';
  }

  @override
  String mediaCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
    );
    return '$_temp0';
  }

  @override
  String get rejected => 'Rejected by server';

  @override
  String offlineBanner(String when) {
    return 'Offline — last updated $when';
  }

  @override
  String get defenseFieldUnit => 'Defense field unit';

  @override
  String get caseTitle => 'Case';

  @override
  String get caseUnavailable =>
      'This case is no longer assigned to you or is not available.';

  @override
  String get stateNew => 'New';

  @override
  String get stateAcknowledged => 'Acknowledged';

  @override
  String get stateInvestigating => 'Investigating';

  @override
  String get stateResolved => 'Resolved';

  @override
  String get stateClosed => 'Closed';

  @override
  String get stateMerged => 'Merged';

  @override
  String get authLikelyAuthorized => 'Likely authorized';

  @override
  String get authNoPermit => 'No permit';

  @override
  String get authUnknown => 'Authorization unknown';

  @override
  String get sourceRemoteId => 'Remote ID';

  @override
  String get sourceTriangulated => 'Triangulated';

  @override
  String get sourceSensor => 'Sensor';

  @override
  String get sourceInformant => 'Informant estimate';

  @override
  String get compassPoints => 'N|NE|E|SE|S|SW|W|NW';

  @override
  String get positionUnknown => 'Position unknown';

  @override
  String get waitingForGps => 'Waiting for GPS…';

  @override
  String gpsAccuracy(int meters) {
    return 'GPS ±$meters m';
  }

  @override
  String lastSeen(String when) {
    return 'Last seen $when';
  }

  @override
  String get redactedShort => 'Restricted';

  @override
  String get redactedExplanation =>
      'This is a classified defense case. Only defense field units can see its details; you see the location, time and severity only. Follow your dispatcher\'s instructions.';

  @override
  String get sensorConfirmed => 'Sensor confirmed';

  @override
  String get operator => 'Operator';

  @override
  String get me => 'Me';

  @override
  String get fitMap => 'Show all';

  @override
  String get toDrone => 'Drone';

  @override
  String get toOperator => 'Operator position';

  @override
  String get positionSharingOn =>
      'Sharing my position with the dispatcher (tap to stop)';

  @override
  String get positionSharingOff => 'Position sharing off (tap to share)';

  @override
  String get basicInfo => 'Basic information';

  @override
  String get severity => 'Severity';

  @override
  String get location => 'Location';

  @override
  String get firstSeenLabel => 'First seen';

  @override
  String get lastSeenLabel => 'Last seen';

  @override
  String get remoteIdScan => 'Remote ID scan';

  @override
  String get captureEvidence => 'Capture evidence';

  @override
  String get incidentFacts => 'Incident';

  @override
  String get positionSource => 'Position from';

  @override
  String get estError => 'Position error';

  @override
  String get estAltitude => 'Estimated altitude';

  @override
  String get reports => 'Observations';

  @override
  String distinctInformants(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count informants',
      one: '1 informant',
    );
    return '$_temp0';
  }

  @override
  String get authorization => 'Authorization';

  @override
  String get zones => 'Zones';

  @override
  String get none => 'None';

  @override
  String get permit => 'Permit';

  @override
  String get permitNo => 'Permit no.';

  @override
  String get operatorName => 'Operator';

  @override
  String get validity => 'Valid';

  @override
  String get maxAltitude => 'Max. altitude';

  @override
  String get remoteIdSerials => 'Remote ID';

  @override
  String get registryMatch => 'Registry match';

  @override
  String get noRemoteId => 'No Remote ID received for this case.';

  @override
  String get registryLookup => 'Registry';

  @override
  String registryTitle(String serial) {
    return 'Registry: $serial';
  }

  @override
  String get registryFailed => 'Registry lookup failed.';

  @override
  String get registered => 'Registered';

  @override
  String get notRegistered => 'Not registered';

  @override
  String get registrationNo => 'Registration no.';

  @override
  String get owner => 'Owner';

  @override
  String get model => 'Model';

  @override
  String get mtow => 'Max. take-off weight';

  @override
  String get registryStatus => 'Status';

  @override
  String get permits => 'Permits';

  @override
  String get adsbNearby => 'Manned aircraft nearby (ADS-B)';

  @override
  String get weather => 'Weather';

  @override
  String get weatherStation => 'Station';

  @override
  String get visibility => 'Visibility';

  @override
  String get wind => 'Wind';

  @override
  String observationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count observations',
      one: '1 observation',
    );
    return '$_temp0';
  }

  @override
  String get srcFieldOfficer => 'Field officer';

  @override
  String get srcRemoteId => 'Remote ID receiver';

  @override
  String get srcRfSensor => 'RF sensor';

  @override
  String get srcMdaSensor => 'Maritime sensor (MDA)';

  @override
  String get srcRadar => 'Radar';

  @override
  String get srcInformant => 'Public report';

  @override
  String get fieldOfficers => 'Assigned officers';

  @override
  String get notes => 'Notes';

  @override
  String get noteHint => 'Add a note for the desk…';

  @override
  String get addNote => 'Add note';

  @override
  String get noteAdded => 'Note added.';

  @override
  String get noteFailed => 'Could not add the note (offline?).';

  @override
  String get restartScan => 'Restart scan';

  @override
  String scanFor(String caseNumber) {
    return 'Drones received by this phone. Attach one to case $caseNumber to add its Remote ID and position as on-scene evidence.';
  }

  @override
  String get capBt4 => 'Bluetooth 4';

  @override
  String get capBt5 => 'Bluetooth 5 long range';

  @override
  String get capWifiBeacon => 'Wi-Fi Beacon';

  @override
  String get capWifiNan => 'Wi-Fi NAN';

  @override
  String get noRemoteIdHardware =>
      'This device cannot receive Remote ID (no supported Bluetooth / Wi-Fi receiver).';

  @override
  String get scanPermissionError =>
      'Remote ID scanning needs the Nearby devices (Bluetooth / Wi-Fi) and Location permissions. Grant them, or enable them in Settings.';

  @override
  String get scanPermissionPartial =>
      'Some permissions are missing; only some transports are being scanned.';

  @override
  String get grantPermission => 'Grant';

  @override
  String get openSettings => 'Settings';

  @override
  String scanError(String error) {
    return 'Scan error: $error';
  }

  @override
  String get scanningNoDrones =>
      'Scanning… no Remote ID broadcasts received yet.';

  @override
  String get unknownSerial => 'Unknown ID';

  @override
  String get live => 'Live';

  @override
  String secondsAgo(int seconds) {
    return '$seconds s ago';
  }

  @override
  String get idType => 'ID type';

  @override
  String get idTypeSerial => 'Serial number';

  @override
  String get idTypeCaa => 'CAA registration';

  @override
  String get idTypeUtm => 'UTM assigned';

  @override
  String get idTypeSession => 'Session ID';

  @override
  String get uaType => 'Aircraft type';

  @override
  String get dronePosition => 'Drone position';

  @override
  String get fromMe => 'From me';

  @override
  String get height => 'Height';

  @override
  String get altGeo => 'geo.';

  @override
  String get speedDirection => 'Speed / direction';

  @override
  String get operatorPosition => 'Operator position';

  @override
  String get operatorFromMe => 'Operator from me';

  @override
  String get operatorId => 'Operator ID';

  @override
  String get selfId => 'Self ID';

  @override
  String get transport => 'Received via';

  @override
  String get rssi => 'Signal';

  @override
  String get attachToCase => 'Attach to case';

  @override
  String get attachAgain => 'Attached – attach again';

  @override
  String get noGpsFix => 'No GPS fix yet. Move to open sky and try again.';

  @override
  String get observationSent => 'Sent to the case.';

  @override
  String get observationQueued =>
      'Saved to the outbox; it will be sent when the connection returns.';

  @override
  String get observationDuplicate => 'The server already has this observation.';

  @override
  String get observationRejected =>
      'The server rejected this observation. See the outbox.';

  @override
  String evidenceFor(String caseNumber) {
    return 'Evidence for case $caseNumber. Files are hashed on capture and uploaded in the background.';
  }

  @override
  String get media => 'Photo / video / audio';

  @override
  String get photo => 'Photo';

  @override
  String get video => 'Video';

  @override
  String get audio => 'Rotor audio';

  @override
  String get stopAudio => 'Stop recording';

  @override
  String get remove => 'Remove';

  @override
  String get captureFailed => 'Capture failed.';

  @override
  String get micPermission =>
      'Microphone permission is needed to record audio.';

  @override
  String get bearing => 'Bearing to the drone';

  @override
  String get bearingHint =>
      'Optional: switch on, point the back of the phone at the drone and lock the bearing.';

  @override
  String get waitingForCompass => 'Waiting for compass…';

  @override
  String elevation(int degrees) {
    return 'Elevation $degrees°';
  }

  @override
  String get compassLowAccuracy =>
      'Compass accuracy is low: move the phone in a figure 8 to calibrate.';

  @override
  String get lockBearing => 'Lock bearing';

  @override
  String lockedBearing(String bearing, int elevation) {
    return 'Locked: $bearing, elevation $elevation°';
  }

  @override
  String get note => 'Note';

  @override
  String get evidenceNoteHint =>
      'What do you see? (drone type, operator, activity)';

  @override
  String get submitEvidence => 'Submit';

  @override
  String get craft => 'Craft';

  @override
  String get darkVessel => 'Dark vessel: no AIS transmitter nearby';

  @override
  String get aiAssessment => 'AI assessment (advisory)';

  @override
  String get loginUsername => 'Username';

  @override
  String get loginPassword => 'Password';

  @override
  String get loginWrongCredentials => 'Wrong username or password.';

  @override
  String get loginLocked =>
      'Too many failed attempts. The account is locked for 15 minutes.';

  @override
  String get loginTooMany =>
      'Too many login attempts from this network. Try again later.';
}
