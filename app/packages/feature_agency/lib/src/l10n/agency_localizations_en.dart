// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'agency_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AgencyL10nEn extends AgencyL10n {
  AgencyL10nEn([String locale = 'en']) : super(locale);

  @override
  String get consoleSubtitle =>
      'Dispatch console for police, CAA and defense desks. Government network only.';

  @override
  String get signInAgency => 'Sign in with agency account';

  @override
  String get signInHint =>
      'Accounts are created by your agency\'s administrator. All access is logged.';

  @override
  String get requestAccount =>
      'Request an account by email to tdth@inxsoft.net';

  @override
  String get fileReportVia =>
      'Filling a report is done via https://reporting.tw/';

  @override
  String get signOut => 'Sign out';

  @override
  String get noAccessTitle => 'No access to the console';

  @override
  String get noAccessBody =>
      'Your account has no dispatcher, supervisor, national command, analyst or administrator role. Ask your agency administrator for access.';

  @override
  String get language => 'Language';

  @override
  String get themeLight => 'Light theme';

  @override
  String get themeDark => 'Dark theme';

  @override
  String get liveConnected => 'Live';

  @override
  String get liveConnecting => 'Connecting…';

  @override
  String get liveDisconnected => 'Offline';

  @override
  String get liveTooltip =>
      'Live update channel. When offline the queue reloads automatically after reconnecting.';

  @override
  String get onDuty => 'On duty';

  @override
  String get offDuty => 'Off duty';

  @override
  String get onDutyTooltip =>
      'Routing skips desks with nobody on duty. Turn this on while you staff the desk.';

  @override
  String get roles => 'Roles';

  @override
  String get clearance => 'Clearance';

  @override
  String get noDesk => 'No desk';

  @override
  String get navQueue => 'Queue';

  @override
  String get navLiveMap => 'Live map';

  @override
  String get navDashboards => 'Dashboards';

  @override
  String get navAdmin => 'Admin';

  @override
  String get navAudit => 'Audit';

  @override
  String get actionFailed => 'Action failed';

  @override
  String get open => 'Open';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get dismissAll => 'Dismiss all';

  @override
  String moreAlerts(int count) {
    return '$count more alerts';
  }

  @override
  String get alertCreated => 'New case';

  @override
  String get alertSeverity => 'Severity raised';

  @override
  String get alertRerouted => 'Rerouted to this desk';

  @override
  String get alertRealert => 'Still not acknowledged';

  @override
  String get alertTransferred => 'Transferred to this desk';

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
  String get authUnknown => 'Unknown';

  @override
  String get classUnclassified => 'Unclassified';

  @override
  String get classRestricted => 'Restricted';

  @override
  String get classDefense => 'Defense';

  @override
  String get srcInformantAndroid => 'Public (Android app)';

  @override
  String get srcInformantWeb => 'Public (web)';

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
  String get reasonNearMannedAircraft => 'Near manned aircraft (ADS-B)';

  @override
  String get reasonZoneAirport => 'Airport zone';

  @override
  String get reasonZoneMilitary => 'Military area';

  @override
  String get reasonZoneInfrastructure => 'Critical infrastructure zone';

  @override
  String get reasonZoneOutlying => 'Kinmen/Matsu restricted area';

  @override
  String get reasonSensorRedZone => 'Sensor-confirmed track in a red zone';

  @override
  String get reasonRestrictedNoPermit =>
      'Restricted or yellow zone without a matching permit';

  @override
  String get reasonNoRemoteId => 'No Remote ID in controlled airspace';

  @override
  String get reasonHovering => 'Hovering over residences';

  @override
  String get reasonValidPermit => 'Registry match with a valid permit';

  @override
  String get reasonSingleWebReport => 'Single unverified web report';

  @override
  String get evCreated => 'Case created';

  @override
  String get evAcknowledged => 'Acknowledged';

  @override
  String get evInvestigating => 'Investigation started';

  @override
  String get evResolved => 'Resolved';

  @override
  String get evClosed => 'Closed';

  @override
  String get evRerouted => 'Rerouted (not acknowledged in time)';

  @override
  String get evTransferred => 'Transferred';

  @override
  String get evMerged => 'Merged into another case';

  @override
  String get evMergedFrom => 'Another case merged in';

  @override
  String get evSeverityUpgraded => 'Severity raised';

  @override
  String get evSeverityDowngraded => 'Severity lowered';

  @override
  String get evAssigned => 'Assignee changed';

  @override
  String get evFieldAssigned => 'Field officers assigned';

  @override
  String get evEvidenceRequested => 'Evidence requested from informants';

  @override
  String get evEvidenceReceived => 'Evidence received';

  @override
  String get evObservationAdded => 'Observation added';

  @override
  String get evNote => 'Note';

  @override
  String get evRedactedCopySent => 'Redacted copy sent';

  @override
  String get hashVerified => 'Verified';

  @override
  String get hashMismatch => 'Hash mismatch';

  @override
  String get hashPending => 'Pending';

  @override
  String get scopeDesk => 'My desk';

  @override
  String get scopeAgency => 'My agency';

  @override
  String get scopeAll => 'All';

  @override
  String caseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cases',
      one: '1 case',
    );
    return '$_temp0';
  }

  @override
  String get refresh => 'Refresh';

  @override
  String get keyboardHelp => 'Keyboard: ↑/↓ select, A acknowledge, Enter open';

  @override
  String acknowledged(String number) {
    return '$number acknowledged';
  }

  @override
  String get fitAll => 'Fit all';

  @override
  String get zoomIn => 'Zoom in';

  @override
  String get zoomOut => 'Zoom out';

  @override
  String get queueEmpty => 'No cases match the filter.';

  @override
  String get colSeverity => 'Severity';

  @override
  String get colCase => 'Case';

  @override
  String get colState => 'State';

  @override
  String get colAck => 'Ack due';

  @override
  String get colAge => 'Age';

  @override
  String get colObservations => 'Obs/rep.';

  @override
  String get colConfidence => 'Conf.';

  @override
  String get colSignals => 'Signals';

  @override
  String get colAuthorization => 'Authorization';

  @override
  String get redactedRow => 'Redacted: your desk is not cleared for this case';

  @override
  String get redactedShort => 'Redacted';

  @override
  String get sensorConfirmed => 'Sensor confirmed';

  @override
  String get remoteId => 'Remote ID';

  @override
  String get readOnly => 'Read-only';

  @override
  String get actAcknowledge => 'Acknowledge';

  @override
  String get actInvestigate => 'Start investigation';

  @override
  String get actTransfer => 'Transfer';

  @override
  String get actMerge => 'Merge';

  @override
  String get actSeverity => 'Change severity';

  @override
  String get actRequestEvidence => 'Request evidence';

  @override
  String get actAssignField => 'Assign field officers';

  @override
  String get actResolve => 'Resolve';

  @override
  String get actClose => 'Close';

  @override
  String get actNote => 'Add note';

  @override
  String get transferred => 'Case transferred';

  @override
  String get merged => 'Cases merged';

  @override
  String get resolved => 'Case resolved';

  @override
  String get fieldAssigned => 'Field officers updated';

  @override
  String get noteAdded => 'Note added';

  @override
  String evidenceRequested(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Request sent to $count informants',
      one: 'Request sent to 1 informant',
      zero: 'No linked informants to ask',
    );
    return '$_temp0';
  }

  @override
  String closeConfirm(String number) {
    return 'Close case $number? Closed cases can no longer be changed.';
  }

  @override
  String get targetDesk => 'Target desk';

  @override
  String get required => 'Required';

  @override
  String get reason => 'Reason';

  @override
  String get reasonRequired => 'A reason is required';

  @override
  String transferHint(String classification) {
    return 'Only desks cleared for this case ($classification) are listed. The case arrives there as New with a fresh acknowledgement timer; your agency keeps read access.';
  }

  @override
  String mergeHint(String number) {
    return 'Choose the case to fold into $number. Its observations and informants move over; it is then closed as merged.';
  }

  @override
  String get mergeNoCandidates => 'No other open cases in your queue.';

  @override
  String get nearby => 'Nearby';

  @override
  String get mergeChoose => 'Choose a case';

  @override
  String get mergeReasonHint => 'e.g. same drone';

  @override
  String get currentSeverity => 'Current';

  @override
  String get severityUnchanged => 'Choose a different level';

  @override
  String get downgradeReasonRequired => 'Lowering severity requires a reason';

  @override
  String get reasonMandatory => 'Reason (required)';

  @override
  String get reasonOptional => 'Reason (optional)';

  @override
  String get downgradeExplain =>
      'The system only ever raises severity. Lowering it is a human decision and is recorded with your name and reason.';

  @override
  String get upgradeExplain =>
      'Raising severity re-alerts the desk and restarts the acknowledgement timer at the shorter timeout.';

  @override
  String get send => 'Send';

  @override
  String get noTemplates => 'No templates available.';

  @override
  String get evidenceRequestHint =>
      'Informants receive only this templated message in their own language. Free text to informants is not possible.';

  @override
  String get noFieldOfficers => 'No field officers in your agency.';

  @override
  String get lastPosition => 'Last position';

  @override
  String get outcome => 'Outcome';

  @override
  String get countsAsFalseReport => 'Counts as false report';

  @override
  String get internalNote => 'Internal note';

  @override
  String get internalNoteHint => 'Never shown to informants';

  @override
  String get resolveInformantHint =>
      'Informants see only the outcome template text.';

  @override
  String get defenseOutcomeHint =>
      'Defense case: informants always see “Handled by the relevant authority”, whatever outcome you choose.';

  @override
  String get noteText => 'Note';

  @override
  String get noteInternalHint =>
      'Internal; visible to staff who can see this case';

  @override
  String get defenseNote => 'Defense note (encrypted)';

  @override
  String get defenseNoteHint =>
      'Stored encrypted; readable only with defense clearance';

  @override
  String get panelMap => 'Map';

  @override
  String get operator => 'Operator';

  @override
  String get estError => 'Position error';

  @override
  String get altitude => 'Altitude';

  @override
  String get positionSource => 'Source';

  @override
  String get panelIncident => 'Incident';

  @override
  String get severityReasons => 'Severity reasons';

  @override
  String get firstSeen => 'First seen';

  @override
  String get lastSeen => 'Last seen';

  @override
  String get informantsObservations => 'Informants / observations';

  @override
  String get confidence => 'Confidence';

  @override
  String get none => 'None';

  @override
  String get permit => 'Permit';

  @override
  String get noPermitMatched => 'No matching permit';

  @override
  String get permitNo => 'Permit no.';

  @override
  String get operatorName => 'Operator';

  @override
  String get validity => 'Valid';

  @override
  String get maxAltitude => 'Max altitude';

  @override
  String get registryMatch => 'Registry match';

  @override
  String get noRegistryMatch => 'No registry match';

  @override
  String get serial => 'Serial';

  @override
  String get model => 'Model';

  @override
  String get registryStatus => 'Status';

  @override
  String get lookUpRegistry => 'Look up registry';

  @override
  String get auditedNotice =>
      'Registry lookups show owner data and are recorded in the audit log.';

  @override
  String get weather => 'Weather';

  @override
  String get visibility => 'Visibility';

  @override
  String get wind => 'Wind';

  @override
  String get station => 'Station';

  @override
  String get adsbNearby => 'ADS-B aircraft nearby';

  @override
  String get registryLookup => 'Registry';

  @override
  String get registered => 'Registered';

  @override
  String get notRegistered => 'Not registered';

  @override
  String get registrationNo => 'Registration no.';

  @override
  String get owner => 'Owner';

  @override
  String get ownerRef => 'Owner ref.';

  @override
  String get mtow => 'Max take-off weight';

  @override
  String get permits => 'Permits';

  @override
  String get noStream => 'This camera has no stream or snapshot URL.';

  @override
  String get panelCctv => 'CCTV';

  @override
  String get findCameras => 'Find nearby cameras';

  @override
  String get cctvHint =>
      'Search cameras within 3 km of the estimated position.';

  @override
  String get noCameras => 'No cameras nearby.';

  @override
  String get openStream => 'Open stream';

  @override
  String get cctvAudited =>
      'Every camera access is recorded in the audit log with this case.';

  @override
  String get panelObservations => 'Observations';

  @override
  String get bearing => 'Bearing';

  @override
  String get elevation => 'Elevation';

  @override
  String get gpsAccuracy => 'GPS';

  @override
  String get spamScore => 'Spam';

  @override
  String get fidelity => 'Fidelity';

  @override
  String get attestation => 'Attestation';

  @override
  String get machineTranslation => 'Machine translation';

  @override
  String get view => 'View';

  @override
  String get notUploaded => 'Not uploaded';

  @override
  String get captured => 'Captured';

  @override
  String get imageFailed => 'Image could not be loaded';

  @override
  String get panelTimeline => 'Timeline';

  @override
  String mergedInto(String number) {
    return 'into $number';
  }

  @override
  String mergedFrom(String number) {
    return 'from $number';
  }

  @override
  String get template => 'Template';

  @override
  String officersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count officers',
      one: '1 officer',
    );
    return '$_temp0';
  }

  @override
  String get defenseNoteAdded => 'Defense note (encrypted)';

  @override
  String get system => 'System';

  @override
  String get user => 'Staff';

  @override
  String get defenseNotes => 'Defense notes';

  @override
  String get ackDue => 'Acknowledge within';

  @override
  String get desk => 'Desk';

  @override
  String get mergedNotice => 'This case was merged into another case.';

  @override
  String get openSurvivor => 'Open surviving case';

  @override
  String get redactedNotice =>
      'Redacted: your clearance does not cover this case. Only location, time and severity are shown.';

  @override
  String readOnlyNotice(String desk) {
    return 'Read-only: this case is held by $desk. Only that desk or its agency\'s supervisors can act on it.';
  }

  @override
  String get assignedOfficers => 'Assigned field officers';

  @override
  String get noPosition => 'No position yet';

  @override
  String get redactedTitle => 'Redacted case';

  @override
  String get redactedExplain =>
      'This case carries a classification above your clearance. It was routed to your desk as a redacted copy so you know something is happening at this location; the cleared desk is handling it. Observations, evidence and informant data are withheld.';

  @override
  String get severity => 'Severity';

  @override
  String get location => 'Location';

  @override
  String get layerZones => 'Zones';

  @override
  String get layerAircraft => 'Aircraft';

  @override
  String get layerOfficers => 'Field officers';

  @override
  String get layerRecentClosed => 'Recent closed';

  @override
  String liveMapCounts(int cases, int aircraft, int officers) {
    return '$cases cases · $aircraft aircraft · $officers officers';
  }

  @override
  String get openCase => 'Open case';

  @override
  String lastNDays(int days) {
    return '$days days';
  }

  @override
  String get customRange => 'Custom';

  @override
  String get kpiIncidents => 'Incidents';

  @override
  String kpiObservations(int count) {
    return '$count observations';
  }

  @override
  String get kpiAuthorizedShare => 'Authorized share';

  @override
  String get kpiRemoteIdCoverage => 'Remote ID coverage';

  @override
  String get kpiSensorConfirmed => 'Sensor confirmed';

  @override
  String get kpiFalseReports => 'False reports';

  @override
  String get kpiAckP50 => 'Time to ack (p50)';

  @override
  String get kpiAckP90 => 'Time to ack (p90)';

  @override
  String get minSec => 'min:sec';

  @override
  String get hotspots => 'Hotspots';

  @override
  String get allSeverities => 'All severities';

  @override
  String get allHours => 'All hours';

  @override
  String get allDays => 'All days';

  @override
  String hotspotLegend(int cells, int incidents) {
    return '$cells cells · $incidents incidents. Larger and redder = more incidents.';
  }

  @override
  String get dowMon => 'Mon';

  @override
  String get dowTue => 'Tue';

  @override
  String get dowWed => 'Wed';

  @override
  String get dowThu => 'Thu';

  @override
  String get dowFri => 'Fri';

  @override
  String get dowSat => 'Sat';

  @override
  String get dowSun => 'Sun';

  @override
  String get timeOfDay => 'Time of day (Taipei time)';

  @override
  String timeOfDayHint(int max) {
    return 'Darker = more incidents (max $max per hour slot). Hover a cell for the count.';
  }

  @override
  String incidentsN(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count incidents',
      one: '1 incident',
    );
    return '$_temp0';
  }

  @override
  String get zonesAuthorization => 'Zones: authorized vs. unauthorized';

  @override
  String get noData => 'No data for this period.';

  @override
  String get zone => 'Zone';

  @override
  String get zoneType => 'Type';

  @override
  String get responsePerformance => 'Response performance';

  @override
  String get byAgency => 'By agency';

  @override
  String get byDesk => 'By desk';

  @override
  String get ackP50Minutes => 'Ack p50 (minutes)';

  @override
  String get ackP90Minutes => 'Ack p90 (minutes)';

  @override
  String get agency => 'Agency';

  @override
  String get cases => 'Cases';

  @override
  String get ackP50 => 'Ack p50';

  @override
  String get ackP90 => 'Ack p90';

  @override
  String get resolveP50 => 'Resolve p50';

  @override
  String get rerouteRate => 'Reroute rate';

  @override
  String get unackedRate => 'Unacknowledged';

  @override
  String get sourceQuality => 'Source quality';

  @override
  String get source => 'Source';

  @override
  String get sensorConfirmedShare => 'Sensor confirmed';

  @override
  String get falseReportRate => 'False-report rate';

  @override
  String get repeatOffenders => 'Repeat offenders';

  @override
  String get bySerial => 'By Remote ID serial';

  @override
  String get byOwner => 'By registered owner';

  @override
  String get unauthorized => 'Unauthorized';

  @override
  String get caseNumbers => 'Cases';

  @override
  String get drones => 'Drones';

  @override
  String get repeatOffendersAudited =>
      'Viewing repeat offenders is recorded in the audit log.';

  @override
  String get search => 'Search';

  @override
  String get newZone => 'New zone';

  @override
  String get editZone => 'Edit zone';

  @override
  String get published => 'Published';

  @override
  String get publishedHint =>
      'Shown to the public in the informant app (CAA zones only)';

  @override
  String get selectZone => 'Select a zone or create a new one.';

  @override
  String get saved => 'Saved';

  @override
  String get zoneFieldsRequired =>
      'Code, English and Chinese names are required';

  @override
  String get zoneNeedsPolygon => 'Draw at least three points on the map';

  @override
  String get undo => 'Undo';

  @override
  String get clear => 'Clear';

  @override
  String vertexHelp(int count) {
    return '$count points · click map to add, drag to move, long-press to delete';
  }

  @override
  String get code => 'Code';

  @override
  String get nameEn => 'Name (English)';

  @override
  String get nameZh => 'Name (Chinese)';

  @override
  String get classification => 'Classification';

  @override
  String get priority => 'Priority';

  @override
  String get primaryDesk => 'Primary desk';

  @override
  String get backupChain => 'Backup chain (in order)';

  @override
  String get addBackupDesk => 'Add backup desk';

  @override
  String get backupChainHint =>
      'Unacknowledged cases move down this chain; every chain ends at the national catch-all desk.';

  @override
  String get ackTimeouts =>
      'Acknowledgement timeouts (seconds, blank = default)';

  @override
  String get defaultValue => 'default';

  @override
  String get tabZones => 'Zones & routing';

  @override
  String get tabTemplates => 'Templates';

  @override
  String get tabFeedClients => 'Feed clients';

  @override
  String get templatesHint =>
      'Templates are the only messages informants ever receive. Every template needs all six languages.';

  @override
  String get newTemplate => 'New template';

  @override
  String get editTemplate => 'Edit template';

  @override
  String get outcomeTemplates => 'Outcome';

  @override
  String get evidenceTemplates => 'Evidence request';

  @override
  String get languages => 'Languages';

  @override
  String get allLanguagesRequired => 'All six languages are required.';

  @override
  String get feedClientsHint =>
      'Credentials for sensor, Remote ID, ADS-B, weather, registry, permit and CCTV feeds.';

  @override
  String get newFeedClient => 'New feed client';

  @override
  String get name => 'Name';

  @override
  String get sources => 'Feeds';

  @override
  String get status => 'Status';

  @override
  String get lastUsed => 'Last used';

  @override
  String get active => 'Active';

  @override
  String get revoke => 'Revoke';

  @override
  String get revoked => 'Revoked';

  @override
  String revokeConfirm(String name) {
    return 'Revoke the key of $name? The feed stops immediately.';
  }

  @override
  String get feedKeyTitle => 'Feed key';

  @override
  String get feedKeyOnce =>
      'This key is shown only once. Store it in the feed system\'s secret store now.';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied';

  @override
  String get keyStored => 'I have stored the key';

  @override
  String get auditUser => 'User';

  @override
  String get auditActionPrefix => 'Action (prefix)';

  @override
  String get auditObjectId => 'Object ID';

  @override
  String get apply => 'Apply';

  @override
  String get auditViewAudited => 'Viewing the audit log is itself audited.';

  @override
  String get time => 'Time';

  @override
  String get auditAction => 'Action';

  @override
  String get auditObject => 'Object';

  @override
  String get details => 'Details';

  @override
  String get domainAerial => 'Aerial';

  @override
  String get domainSurface => 'Surface';

  @override
  String get domainSubsurface => 'Subsurface';

  @override
  String get domainShore => 'Shore';

  @override
  String get domainUnknown => 'Unknown domain';

  @override
  String get craftUavMultirotor => 'Multirotor UAV';

  @override
  String get craftUavFixedWing => 'Fixed-wing UAV';

  @override
  String get craftUav => 'UAV';

  @override
  String get craftBalloon => 'Balloon / airship';

  @override
  String get craftUsv => 'Unmanned surface vessel (USV)';

  @override
  String get craftSmallBoat => 'Small boat';

  @override
  String get craftFishingVessel => 'Fishing vessel';

  @override
  String get craftShip => 'Ship';

  @override
  String get craftVessel => 'Vessel';

  @override
  String get craftSubmarine => 'Submarine (periscope/mast)';

  @override
  String get craftUuv => 'Unmanned underwater vehicle';

  @override
  String get craftLandedBoat => 'Boat landed ashore';

  @override
  String get craftObjectAshore => 'Object washed ashore';

  @override
  String get craftUnknownSubsurface => 'Unknown subsurface contact';

  @override
  String get panelAi => 'AI triage (advisory)';

  @override
  String get aiAdvisoryNote =>
      'Advisory only. The model can raise severity by at most one level, reaches Critical only with corroboration, and never lowers severity or closes a case.';

  @override
  String get aiThreat => 'Threat assessment';

  @override
  String get aiCraft => 'Identified as';

  @override
  String get aiSilhouette => 'Silhouette';

  @override
  String get aiUnmanned => 'Unmanned likelihood';

  @override
  String get aiSpam => 'Unrelated-image likelihood';

  @override
  String get aiConfidence => 'Model confidence';

  @override
  String get aiMatchesReport => 'Consistent with report';

  @override
  String get aiModel => 'Model';

  @override
  String get aiNone =>
      'No AI assessment yet (photos are assessed after upload).';

  @override
  String get panelMaritime => 'Maritime picture';

  @override
  String get vesselAis => 'AIS vessel';

  @override
  String get darkVessel =>
      'Dark vessel: AIS coverage here, but nothing transmits near the contact';

  @override
  String get noAisCoverage => 'No AIS coverage in this area';

  @override
  String get mdaTrack => 'MDA sensor track (unidentified)';

  @override
  String get interviewAnswers => 'Informant interview';

  @override
  String get craftDomain => 'Domain';

  @override
  String get layerVessels => 'Vessels (AIS / MDA)';

  @override
  String get layerCameras => 'Video feeds';

  @override
  String get videoFeeds => 'Video feeds';

  @override
  String get reasonSubsurface => 'Subsurface contact';

  @override
  String get reasonPeopleUnloading => 'People unloading ashore';

  @override
  String get reasonCraftLanded => 'Craft landed ashore';

  @override
  String get reasonUsv => 'Unmanned surface vessel';

  @override
  String get reasonUsvProtected => 'USV in protected waters';

  @override
  String get reasonUsvApproaching => 'USV approaching the shore';

  @override
  String get reasonDarkProtected => 'Dark vessel in protected waters';

  @override
  String get reasonDarkTerritorial => 'Dark vessel in territorial sea';

  @override
  String get reasonUnidentifiedRestricted =>
      'Unidentified craft in restricted waters';

  @override
  String get reasonVesselRestricted => 'Vessel in restricted waters';

  @override
  String get reasonUnidentifiedProtected =>
      'Unidentified craft in protected waters';

  @override
  String get reasonAi => 'AI assessment (advisory)';

  @override
  String get zoneDomains => 'Applies to';

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

  @override
  String get tabUsers => 'Users';

  @override
  String get newUser => 'New user';

  @override
  String get editUser => 'Edit user';

  @override
  String get usersHint =>
      'Staff accounts for the console and the field app. Passwords need at least 12 characters.';

  @override
  String get displayName => 'Display name';

  @override
  String get fieldUnitLabel => 'Defense field unit';

  @override
  String get initialPassword => 'Initial password';

  @override
  String get resetPassword => 'New password (leave empty to keep)';

  @override
  String get deactivate => 'Deactivate';

  @override
  String get reactivate => 'Reactivate';

  @override
  String get deactivated => 'Deactivated';

  @override
  String get lockedLabel => 'Locked';

  @override
  String get lastSeenLabel => 'Last seen';

  @override
  String get userSaved => 'Saved';

  @override
  String get navAtreides => 'Atreides';

  @override
  String get atreidesTitle => 'Atreides maritime sensor';

  @override
  String get atreidesSubtitle =>
      'Non-cooperative maritime detections (MDA) from Atreides. Not AIS: there is no vessel identity, speed or course. Each detection is classified as a mobile asset, a fixed site or ambiguous.';

  @override
  String get atreidesAllBatches => 'All imports';

  @override
  String get atreidesAllRoles => 'All';

  @override
  String get atreidesDetections => 'Detections';

  @override
  String get atreidesTracks => 'Tracks';

  @override
  String atreidesTrackSplit(int routes, int singles) {
    final intl.NumberFormat routesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String routesString = routesNumberFormat.format(routes);
    final intl.NumberFormat singlesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String singlesString = singlesNumberFormat.format(singles);

    return '$routesString routes · $singlesString single contacts';
  }

  @override
  String get atreidesRoleMobile => 'Mobile asset';

  @override
  String get atreidesRoleFixed => 'Fixed site';

  @override
  String get atreidesRoleAmbiguous => 'Ambiguous';

  @override
  String get atreidesPeriod => 'Period';

  @override
  String get atreidesHighConfidence => 'High confidence only';

  @override
  String get atreidesRoutesOnly => 'Routes only';

  @override
  String atreidesTrackFacts(int count, String km) {
    return '$count detections · $km km';
  }

  @override
  String get atreidesSingleContact => 'Single contact';

  @override
  String atreidesSourceView(String role, String confidence, String reasoning) {
    return 'Source sensor: $role ($confidence) — $reasoning';
  }

  @override
  String get atreidesEmpty => 'No Atreides data has been imported yet.';

  @override
  String atreidesShowing(int shown, int total) {
    return 'Showing $shown of $total';
  }

  @override
  String atreidesConfidence(String level) {
    return '$level confidence';
  }

  @override
  String get atreidesConfHigh => 'high';

  @override
  String get atreidesConfLow => 'low';

  @override
  String get consoleTitle =>
      'Reporting.tw: Monitoring suspicious aerial and water activity reports.';

  @override
  String get navMaritime => 'Maritime';

  @override
  String get maritimeTitle => 'Maritime behaviour alerts';

  @override
  String get maritimeSubtitle =>
      'Unusual stops, detours, meetings at sea, reporting gaps and entries into protected waters, from AIS, Atreides and simulated tracks. For human review: an alert is not a verdict.';

  @override
  String get tabAlerts => 'Alerts';

  @override
  String get tabThresholds => 'Thresholds';

  @override
  String get tabEvaluation => 'Rules vs statistics';

  @override
  String get maritimeStatusOpen => 'Open';

  @override
  String get maritimeStatusAcknowledged => 'Acknowledged';

  @override
  String get maritimeStatusFalseAlarm => 'False alarm';

  @override
  String get maritimeStatusDismissed => 'Dismissed';

  @override
  String get maritimeStatusEscalated => 'Escalated to case';

  @override
  String get maritimeStatusReopened => 'Reopened';

  @override
  String get maritimeShowClosed => 'Show closed';

  @override
  String get maritimeAllKinds => 'All behaviours';

  @override
  String get kindStop => 'Stop / loitering';

  @override
  String get kindDeviation => 'Off usual lanes';

  @override
  String get kindCluster => 'Vessels meeting';

  @override
  String get kindZoneEntry => 'Entered protected waters';

  @override
  String get kindApproach => 'Approached protected waters';

  @override
  String get kindGap => 'Reporting gap';

  @override
  String get kindStatistical => 'Statistically unusual';

  @override
  String get methodRules => 'Rules';

  @override
  String get methodStat => 'Statistical';

  @override
  String get methodBoth => 'Rules + statistics';

  @override
  String maritimeRisk(int score) {
    return 'Risk $score';
  }

  @override
  String maritimeQuality(int pct) {
    return 'Data quality $pct%';
  }

  @override
  String get maritimeWhy => 'Why this alert';

  @override
  String get maritimeUncertainty => 'Uncertainty';

  @override
  String get maritimeTimeline => 'Timeline';

  @override
  String maritimeValue(String value, String threshold) {
    return 'measured $value · threshold $threshold';
  }

  @override
  String get maritimeAck => 'Acknowledge';

  @override
  String get maritimeFalseAlarm => 'False alarm';

  @override
  String get maritimeDismiss => 'Dismiss';

  @override
  String get maritimeReopen => 'Reopen';

  @override
  String get maritimeEscalate => 'Escalate to case';

  @override
  String get maritimeOpenCase => 'Open case';

  @override
  String get maritimeAddNote => 'Add note';

  @override
  String get maritimeNoteHint => 'Note for the timeline';

  @override
  String get maritimeSuppressHours => 'Stay quiet for (hours)';

  @override
  String get maritimeFalseAlarmTitle => 'Mark as false alarm';

  @override
  String get maritimeNone => 'No alerts match.';

  @override
  String get maritimeSelect => 'Select an alert to see why it was raised.';

  @override
  String get maritimeSave => 'Save and re-run';

  @override
  String get maritimeSaved => 'Thresholds saved; detection re-run.';

  @override
  String maritimeDefault(String value) {
    return 'Default $value';
  }

  @override
  String get maritimeReadOnly =>
      'Only supervisors and admins can change thresholds.';

  @override
  String evalIntro(int tracks, int anomalous) {
    return 'Simulated traffic around Taiwan with labelled behaviours: $tracks tracks checked, $anomalous of them anomalous. Precision: share of alerts that were real. Recall: share of real anomalies found.';
  }

  @override
  String get evalMethod => 'Method';

  @override
  String get evalPrecision => 'Precision';

  @override
  String get evalRecall => 'Recall';

  @override
  String get evalF1 => 'F1';

  @override
  String get evalFalseAlarms => 'False alarms per 100 normal tracks';

  @override
  String get evalCombined => 'Combined risk score (what operators see)';

  @override
  String get evalByKind => 'Found per injected behaviour';

  @override
  String get evalRun => 'Re-run comparison';

  @override
  String get evalResimulate => 'New simulated traffic';

  @override
  String get evalNone => 'No comparison yet.';

  @override
  String evalRanAt(String when) {
    return 'Run $when';
  }

  @override
  String get eventDetected => 'Detected';

  @override
  String get eventUpdated => 'Updated';

  @override
  String get eventNote => 'Note';

  @override
  String get maritimeSourceSim => 'Simulation';

  @override
  String get maritimeSourceAtreides => 'Atreides';

  @override
  String get evRecommendation => 'Recommendation decided';

  @override
  String get recTitle => 'Recommended actions';

  @override
  String get recIntro =>
      'Decision support only: nothing here controls a device. Accepting a field unit assigns that officer; other actions are simulated and recorded.';

  @override
  String get recAccept => 'Accept';

  @override
  String get recReject => 'Reject';

  @override
  String get recModify => 'Modify';

  @override
  String get recModifyTitle => 'Modify recommendation';

  @override
  String get recNewText => 'What will be done';

  @override
  String get recNote => 'Note (optional)';

  @override
  String get recAccepted => 'Accepted';

  @override
  String get recRejected => 'Rejected';

  @override
  String get recModified => 'Modified';

  @override
  String recBy(String who, String when) {
    return '$who, $when';
  }

  @override
  String get recNone => 'No recommendations for this case.';

  @override
  String get recReadOnly => 'Only the desk holding this case can decide.';

  @override
  String get navCctv => 'CCTV';

  @override
  String get cctvTitle => 'CCTV camera tracks';

  @override
  String get cctvSubtitle =>
      'Drones and vessels followed across camera frames by AI image analysis (Featherless AI). Advisory only: a person reviews every track.';

  @override
  String get cctvCameras => 'Cameras';

  @override
  String get cctvTracks => 'Tracks';

  @override
  String get cctvNoTracks => 'No suspicious activity detected.';

  @override
  String get cctvNoCameras => 'No cameras are connected.';

  @override
  String get cctvInactive => 'Inactive';

  @override
  String cctvLastSample(String time) {
    return 'Last frame $time';
  }

  @override
  String cctvTrackFacts(int hits, String from, String to) {
    String _temp0 = intl.Intl.pluralLogic(
      hits,
      locale: localeName,
      other: '$hits frames',
      one: '1 frame',
    );
    return '$_temp0 · $from – $to';
  }

  @override
  String get cctvFrameLegend =>
      'Last frame: track (orange), detection box and watch area (red)';

  @override
  String get cctvNoFrame => 'No frame stored for this track.';

  @override
  String cctvOpenCase(String number) {
    return 'Open case $number';
  }

  @override
  String get cctvTrackActive => 'Active';

  @override
  String get cctvTrackLost => 'Lost';

  @override
  String get cctvBehLoiter => 'Loitering';

  @override
  String get cctvBehApproaching => 'Approaching';

  @override
  String get cctvBehFast => 'Fast';

  @override
  String get cctvBehZone => 'Watch area';

  @override
  String cctvOpenCases(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count open cases',
      one: '1 open case',
    );
    return '$_temp0';
  }
}
