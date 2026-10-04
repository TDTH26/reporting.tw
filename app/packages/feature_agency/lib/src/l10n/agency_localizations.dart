import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'agency_localizations_en.dart';
import 'agency_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AgencyL10n
/// returned by `AgencyL10n.of(context)`.
///
/// Applications need to include `AgencyL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/agency_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AgencyL10n.localizationsDelegates,
///   supportedLocales: AgencyL10n.supportedLocales,
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
/// be consistent with the languages listed in the AgencyL10n.supportedLocales
/// property.
abstract class AgencyL10n {
  AgencyL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AgencyL10n of(BuildContext context) {
    return Localizations.of<AgencyL10n>(context, AgencyL10n)!;
  }

  static const LocalizationsDelegate<AgencyL10n> delegate =
      _AgencyL10nDelegate();

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

  /// No description provided for @consoleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Dispatch console for police, CAA and defense desks. Government network only.'**
  String get consoleSubtitle;

  /// No description provided for @signInAgency.
  ///
  /// In en, this message translates to:
  /// **'Sign in with agency account'**
  String get signInAgency;

  /// No description provided for @signInHint.
  ///
  /// In en, this message translates to:
  /// **'Accounts are created by your agency\'s administrator. All access is logged.'**
  String get signInHint;

  /// No description provided for @requestAccount.
  ///
  /// In en, this message translates to:
  /// **'Request an account by email to tdth@inxsoft.net'**
  String get requestAccount;

  /// No description provided for @fileReportVia.
  ///
  /// In en, this message translates to:
  /// **'Filling a report is done via https://reporting.tw/'**
  String get fileReportVia;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @noAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'No access to the console'**
  String get noAccessTitle;

  /// No description provided for @noAccessBody.
  ///
  /// In en, this message translates to:
  /// **'Your account has no dispatcher, supervisor, national command, analyst or administrator role. Ask your agency administrator for access.'**
  String get noAccessBody;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light theme'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark theme'**
  String get themeDark;

  /// No description provided for @liveConnected.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get liveConnected;

  /// No description provided for @liveConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get liveConnecting;

  /// No description provided for @liveDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get liveDisconnected;

  /// No description provided for @liveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Live update channel. When offline the queue reloads automatically after reconnecting.'**
  String get liveTooltip;

  /// No description provided for @onDuty.
  ///
  /// In en, this message translates to:
  /// **'On duty'**
  String get onDuty;

  /// No description provided for @offDuty.
  ///
  /// In en, this message translates to:
  /// **'Off duty'**
  String get offDuty;

  /// No description provided for @onDutyTooltip.
  ///
  /// In en, this message translates to:
  /// **'Routing skips desks with nobody on duty. Turn this on while you staff the desk.'**
  String get onDutyTooltip;

  /// No description provided for @roles.
  ///
  /// In en, this message translates to:
  /// **'Roles'**
  String get roles;

  /// No description provided for @clearance.
  ///
  /// In en, this message translates to:
  /// **'Clearance'**
  String get clearance;

  /// No description provided for @noDesk.
  ///
  /// In en, this message translates to:
  /// **'No desk'**
  String get noDesk;

  /// No description provided for @navQueue.
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get navQueue;

  /// No description provided for @navLiveMap.
  ///
  /// In en, this message translates to:
  /// **'Live map'**
  String get navLiveMap;

  /// No description provided for @navDashboards.
  ///
  /// In en, this message translates to:
  /// **'Dashboards'**
  String get navDashboards;

  /// No description provided for @navAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get navAdmin;

  /// No description provided for @navAudit.
  ///
  /// In en, this message translates to:
  /// **'Audit'**
  String get navAudit;

  /// No description provided for @actionFailed.
  ///
  /// In en, this message translates to:
  /// **'Action failed'**
  String get actionFailed;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @dismissAll.
  ///
  /// In en, this message translates to:
  /// **'Dismiss all'**
  String get dismissAll;

  /// No description provided for @moreAlerts.
  ///
  /// In en, this message translates to:
  /// **'{count} more alerts'**
  String moreAlerts(int count);

  /// No description provided for @alertCreated.
  ///
  /// In en, this message translates to:
  /// **'New case'**
  String get alertCreated;

  /// No description provided for @alertSeverity.
  ///
  /// In en, this message translates to:
  /// **'Severity raised'**
  String get alertSeverity;

  /// No description provided for @alertRerouted.
  ///
  /// In en, this message translates to:
  /// **'Rerouted to this desk'**
  String get alertRerouted;

  /// No description provided for @alertRealert.
  ///
  /// In en, this message translates to:
  /// **'Still not acknowledged'**
  String get alertRealert;

  /// No description provided for @alertTransferred.
  ///
  /// In en, this message translates to:
  /// **'Transferred to this desk'**
  String get alertTransferred;

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
  /// **'Unknown'**
  String get authUnknown;

  /// No description provided for @classUnclassified.
  ///
  /// In en, this message translates to:
  /// **'Unclassified'**
  String get classUnclassified;

  /// No description provided for @classRestricted.
  ///
  /// In en, this message translates to:
  /// **'Restricted'**
  String get classRestricted;

  /// No description provided for @classDefense.
  ///
  /// In en, this message translates to:
  /// **'Defense'**
  String get classDefense;

  /// No description provided for @srcInformantAndroid.
  ///
  /// In en, this message translates to:
  /// **'Public (Android app)'**
  String get srcInformantAndroid;

  /// No description provided for @srcInformantWeb.
  ///
  /// In en, this message translates to:
  /// **'Public (web)'**
  String get srcInformantWeb;

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

  /// No description provided for @reasonNearMannedAircraft.
  ///
  /// In en, this message translates to:
  /// **'Near manned aircraft (ADS-B)'**
  String get reasonNearMannedAircraft;

  /// No description provided for @reasonZoneAirport.
  ///
  /// In en, this message translates to:
  /// **'Airport zone'**
  String get reasonZoneAirport;

  /// No description provided for @reasonZoneMilitary.
  ///
  /// In en, this message translates to:
  /// **'Military area'**
  String get reasonZoneMilitary;

  /// No description provided for @reasonZoneInfrastructure.
  ///
  /// In en, this message translates to:
  /// **'Critical infrastructure zone'**
  String get reasonZoneInfrastructure;

  /// No description provided for @reasonZoneOutlying.
  ///
  /// In en, this message translates to:
  /// **'Kinmen/Matsu restricted area'**
  String get reasonZoneOutlying;

  /// No description provided for @reasonSensorRedZone.
  ///
  /// In en, this message translates to:
  /// **'Sensor-confirmed track in a red zone'**
  String get reasonSensorRedZone;

  /// No description provided for @reasonRestrictedNoPermit.
  ///
  /// In en, this message translates to:
  /// **'Restricted or yellow zone without a matching permit'**
  String get reasonRestrictedNoPermit;

  /// No description provided for @reasonNoRemoteId.
  ///
  /// In en, this message translates to:
  /// **'No Remote ID in controlled airspace'**
  String get reasonNoRemoteId;

  /// No description provided for @reasonHovering.
  ///
  /// In en, this message translates to:
  /// **'Hovering over residences'**
  String get reasonHovering;

  /// No description provided for @reasonValidPermit.
  ///
  /// In en, this message translates to:
  /// **'Registry match with a valid permit'**
  String get reasonValidPermit;

  /// No description provided for @reasonSingleWebReport.
  ///
  /// In en, this message translates to:
  /// **'Single unverified web report'**
  String get reasonSingleWebReport;

  /// No description provided for @evCreated.
  ///
  /// In en, this message translates to:
  /// **'Case created'**
  String get evCreated;

  /// No description provided for @evAcknowledged.
  ///
  /// In en, this message translates to:
  /// **'Acknowledged'**
  String get evAcknowledged;

  /// No description provided for @evInvestigating.
  ///
  /// In en, this message translates to:
  /// **'Investigation started'**
  String get evInvestigating;

  /// No description provided for @evResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get evResolved;

  /// No description provided for @evClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get evClosed;

  /// No description provided for @evRerouted.
  ///
  /// In en, this message translates to:
  /// **'Rerouted (not acknowledged in time)'**
  String get evRerouted;

  /// No description provided for @evTransferred.
  ///
  /// In en, this message translates to:
  /// **'Transferred'**
  String get evTransferred;

  /// No description provided for @evMerged.
  ///
  /// In en, this message translates to:
  /// **'Merged into another case'**
  String get evMerged;

  /// No description provided for @evMergedFrom.
  ///
  /// In en, this message translates to:
  /// **'Another case merged in'**
  String get evMergedFrom;

  /// No description provided for @evSeverityUpgraded.
  ///
  /// In en, this message translates to:
  /// **'Severity raised'**
  String get evSeverityUpgraded;

  /// No description provided for @evSeverityDowngraded.
  ///
  /// In en, this message translates to:
  /// **'Severity lowered'**
  String get evSeverityDowngraded;

  /// No description provided for @evAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assignee changed'**
  String get evAssigned;

  /// No description provided for @evFieldAssigned.
  ///
  /// In en, this message translates to:
  /// **'Field officers assigned'**
  String get evFieldAssigned;

  /// No description provided for @evEvidenceRequested.
  ///
  /// In en, this message translates to:
  /// **'Evidence requested from informants'**
  String get evEvidenceRequested;

  /// No description provided for @evEvidenceReceived.
  ///
  /// In en, this message translates to:
  /// **'Evidence received'**
  String get evEvidenceReceived;

  /// No description provided for @evObservationAdded.
  ///
  /// In en, this message translates to:
  /// **'Observation added'**
  String get evObservationAdded;

  /// No description provided for @evNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get evNote;

  /// No description provided for @evRedactedCopySent.
  ///
  /// In en, this message translates to:
  /// **'Redacted copy sent'**
  String get evRedactedCopySent;

  /// No description provided for @hashVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get hashVerified;

  /// No description provided for @hashMismatch.
  ///
  /// In en, this message translates to:
  /// **'Hash mismatch'**
  String get hashMismatch;

  /// No description provided for @hashPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get hashPending;

  /// No description provided for @scopeDesk.
  ///
  /// In en, this message translates to:
  /// **'My desk'**
  String get scopeDesk;

  /// No description provided for @scopeAgency.
  ///
  /// In en, this message translates to:
  /// **'My agency'**
  String get scopeAgency;

  /// No description provided for @scopeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get scopeAll;

  /// No description provided for @caseCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 case} other{{count} cases}}'**
  String caseCount(int count);

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @keyboardHelp.
  ///
  /// In en, this message translates to:
  /// **'Keyboard: ↑/↓ select, A acknowledge, Enter open'**
  String get keyboardHelp;

  /// No description provided for @acknowledged.
  ///
  /// In en, this message translates to:
  /// **'{number} acknowledged'**
  String acknowledged(String number);

  /// No description provided for @fitAll.
  ///
  /// In en, this message translates to:
  /// **'Fit all'**
  String get fitAll;

  /// No description provided for @zoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get zoomIn;

  /// No description provided for @zoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get zoomOut;

  /// No description provided for @queueEmpty.
  ///
  /// In en, this message translates to:
  /// **'No cases match the filter.'**
  String get queueEmpty;

  /// No description provided for @colSeverity.
  ///
  /// In en, this message translates to:
  /// **'Severity'**
  String get colSeverity;

  /// No description provided for @colCase.
  ///
  /// In en, this message translates to:
  /// **'Case'**
  String get colCase;

  /// No description provided for @colState.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get colState;

  /// No description provided for @colAck.
  ///
  /// In en, this message translates to:
  /// **'Ack due'**
  String get colAck;

  /// No description provided for @colAge.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get colAge;

  /// No description provided for @colObservations.
  ///
  /// In en, this message translates to:
  /// **'Obs/rep.'**
  String get colObservations;

  /// No description provided for @colConfidence.
  ///
  /// In en, this message translates to:
  /// **'Conf.'**
  String get colConfidence;

  /// No description provided for @colSignals.
  ///
  /// In en, this message translates to:
  /// **'Signals'**
  String get colSignals;

  /// No description provided for @colAuthorization.
  ///
  /// In en, this message translates to:
  /// **'Authorization'**
  String get colAuthorization;

  /// No description provided for @redactedRow.
  ///
  /// In en, this message translates to:
  /// **'Redacted: your desk is not cleared for this case'**
  String get redactedRow;

  /// No description provided for @redactedShort.
  ///
  /// In en, this message translates to:
  /// **'Redacted'**
  String get redactedShort;

  /// No description provided for @sensorConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Sensor confirmed'**
  String get sensorConfirmed;

  /// No description provided for @remoteId.
  ///
  /// In en, this message translates to:
  /// **'Remote ID'**
  String get remoteId;

  /// No description provided for @readOnly.
  ///
  /// In en, this message translates to:
  /// **'Read-only'**
  String get readOnly;

  /// No description provided for @actAcknowledge.
  ///
  /// In en, this message translates to:
  /// **'Acknowledge'**
  String get actAcknowledge;

  /// No description provided for @actInvestigate.
  ///
  /// In en, this message translates to:
  /// **'Start investigation'**
  String get actInvestigate;

  /// No description provided for @actTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get actTransfer;

  /// No description provided for @actMerge.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get actMerge;

  /// No description provided for @actSeverity.
  ///
  /// In en, this message translates to:
  /// **'Change severity'**
  String get actSeverity;

  /// No description provided for @actRequestEvidence.
  ///
  /// In en, this message translates to:
  /// **'Request evidence'**
  String get actRequestEvidence;

  /// No description provided for @actAssignField.
  ///
  /// In en, this message translates to:
  /// **'Assign field officers'**
  String get actAssignField;

  /// No description provided for @actResolve.
  ///
  /// In en, this message translates to:
  /// **'Resolve'**
  String get actResolve;

  /// No description provided for @actClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actClose;

  /// No description provided for @actNote.
  ///
  /// In en, this message translates to:
  /// **'Add note'**
  String get actNote;

  /// No description provided for @transferred.
  ///
  /// In en, this message translates to:
  /// **'Case transferred'**
  String get transferred;

  /// No description provided for @merged.
  ///
  /// In en, this message translates to:
  /// **'Cases merged'**
  String get merged;

  /// No description provided for @resolved.
  ///
  /// In en, this message translates to:
  /// **'Case resolved'**
  String get resolved;

  /// No description provided for @fieldAssigned.
  ///
  /// In en, this message translates to:
  /// **'Field officers updated'**
  String get fieldAssigned;

  /// No description provided for @noteAdded.
  ///
  /// In en, this message translates to:
  /// **'Note added'**
  String get noteAdded;

  /// No description provided for @evidenceRequested.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No linked informants to ask} =1{Request sent to 1 informant} other{Request sent to {count} informants}}'**
  String evidenceRequested(int count);

  /// No description provided for @closeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Close case {number}? Closed cases can no longer be changed.'**
  String closeConfirm(String number);

  /// No description provided for @targetDesk.
  ///
  /// In en, this message translates to:
  /// **'Target desk'**
  String get targetDesk;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @reasonRequired.
  ///
  /// In en, this message translates to:
  /// **'A reason is required'**
  String get reasonRequired;

  /// No description provided for @transferHint.
  ///
  /// In en, this message translates to:
  /// **'Only desks cleared for this case ({classification}) are listed. The case arrives there as New with a fresh acknowledgement timer; your agency keeps read access.'**
  String transferHint(String classification);

  /// No description provided for @mergeHint.
  ///
  /// In en, this message translates to:
  /// **'Choose the case to fold into {number}. Its observations and informants move over; it is then closed as merged.'**
  String mergeHint(String number);

  /// No description provided for @mergeNoCandidates.
  ///
  /// In en, this message translates to:
  /// **'No other open cases in your queue.'**
  String get mergeNoCandidates;

  /// No description provided for @nearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get nearby;

  /// No description provided for @mergeChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose a case'**
  String get mergeChoose;

  /// No description provided for @mergeReasonHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. same drone'**
  String get mergeReasonHint;

  /// No description provided for @currentSeverity.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get currentSeverity;

  /// No description provided for @severityUnchanged.
  ///
  /// In en, this message translates to:
  /// **'Choose a different level'**
  String get severityUnchanged;

  /// No description provided for @downgradeReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Lowering severity requires a reason'**
  String get downgradeReasonRequired;

  /// No description provided for @reasonMandatory.
  ///
  /// In en, this message translates to:
  /// **'Reason (required)'**
  String get reasonMandatory;

  /// No description provided for @reasonOptional.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get reasonOptional;

  /// No description provided for @downgradeExplain.
  ///
  /// In en, this message translates to:
  /// **'The system only ever raises severity. Lowering it is a human decision and is recorded with your name and reason.'**
  String get downgradeExplain;

  /// No description provided for @upgradeExplain.
  ///
  /// In en, this message translates to:
  /// **'Raising severity re-alerts the desk and restarts the acknowledgement timer at the shorter timeout.'**
  String get upgradeExplain;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @noTemplates.
  ///
  /// In en, this message translates to:
  /// **'No templates available.'**
  String get noTemplates;

  /// No description provided for @evidenceRequestHint.
  ///
  /// In en, this message translates to:
  /// **'Informants receive only this templated message in their own language. Free text to informants is not possible.'**
  String get evidenceRequestHint;

  /// No description provided for @noFieldOfficers.
  ///
  /// In en, this message translates to:
  /// **'No field officers in your agency.'**
  String get noFieldOfficers;

  /// No description provided for @lastPosition.
  ///
  /// In en, this message translates to:
  /// **'Last position'**
  String get lastPosition;

  /// No description provided for @outcome.
  ///
  /// In en, this message translates to:
  /// **'Outcome'**
  String get outcome;

  /// No description provided for @countsAsFalseReport.
  ///
  /// In en, this message translates to:
  /// **'Counts as false report'**
  String get countsAsFalseReport;

  /// No description provided for @internalNote.
  ///
  /// In en, this message translates to:
  /// **'Internal note'**
  String get internalNote;

  /// No description provided for @internalNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Never shown to informants'**
  String get internalNoteHint;

  /// No description provided for @resolveInformantHint.
  ///
  /// In en, this message translates to:
  /// **'Informants see only the outcome template text.'**
  String get resolveInformantHint;

  /// No description provided for @defenseOutcomeHint.
  ///
  /// In en, this message translates to:
  /// **'Defense case: informants always see “Handled by the relevant authority”, whatever outcome you choose.'**
  String get defenseOutcomeHint;

  /// No description provided for @noteText.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get noteText;

  /// No description provided for @noteInternalHint.
  ///
  /// In en, this message translates to:
  /// **'Internal; visible to staff who can see this case'**
  String get noteInternalHint;

  /// No description provided for @defenseNote.
  ///
  /// In en, this message translates to:
  /// **'Defense note (encrypted)'**
  String get defenseNote;

  /// No description provided for @defenseNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Stored encrypted; readable only with defense clearance'**
  String get defenseNoteHint;

  /// No description provided for @panelMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get panelMap;

  /// No description provided for @operator.
  ///
  /// In en, this message translates to:
  /// **'Operator'**
  String get operator;

  /// No description provided for @estError.
  ///
  /// In en, this message translates to:
  /// **'Position error'**
  String get estError;

  /// No description provided for @altitude.
  ///
  /// In en, this message translates to:
  /// **'Altitude'**
  String get altitude;

  /// No description provided for @positionSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get positionSource;

  /// No description provided for @panelIncident.
  ///
  /// In en, this message translates to:
  /// **'Incident'**
  String get panelIncident;

  /// No description provided for @severityReasons.
  ///
  /// In en, this message translates to:
  /// **'Severity reasons'**
  String get severityReasons;

  /// No description provided for @firstSeen.
  ///
  /// In en, this message translates to:
  /// **'First seen'**
  String get firstSeen;

  /// No description provided for @lastSeen.
  ///
  /// In en, this message translates to:
  /// **'Last seen'**
  String get lastSeen;

  /// No description provided for @informantsObservations.
  ///
  /// In en, this message translates to:
  /// **'Informants / observations'**
  String get informantsObservations;

  /// No description provided for @confidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get confidence;

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

  /// No description provided for @noPermitMatched.
  ///
  /// In en, this message translates to:
  /// **'No matching permit'**
  String get noPermitMatched;

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
  /// **'Max altitude'**
  String get maxAltitude;

  /// No description provided for @registryMatch.
  ///
  /// In en, this message translates to:
  /// **'Registry match'**
  String get registryMatch;

  /// No description provided for @noRegistryMatch.
  ///
  /// In en, this message translates to:
  /// **'No registry match'**
  String get noRegistryMatch;

  /// No description provided for @serial.
  ///
  /// In en, this message translates to:
  /// **'Serial'**
  String get serial;

  /// No description provided for @model.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get model;

  /// No description provided for @registryStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get registryStatus;

  /// No description provided for @lookUpRegistry.
  ///
  /// In en, this message translates to:
  /// **'Look up registry'**
  String get lookUpRegistry;

  /// No description provided for @auditedNotice.
  ///
  /// In en, this message translates to:
  /// **'Registry lookups show owner data and are recorded in the audit log.'**
  String get auditedNotice;

  /// No description provided for @weather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get weather;

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

  /// No description provided for @station.
  ///
  /// In en, this message translates to:
  /// **'Station'**
  String get station;

  /// No description provided for @adsbNearby.
  ///
  /// In en, this message translates to:
  /// **'ADS-B aircraft nearby'**
  String get adsbNearby;

  /// No description provided for @registryLookup.
  ///
  /// In en, this message translates to:
  /// **'Registry'**
  String get registryLookup;

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

  /// No description provided for @ownerRef.
  ///
  /// In en, this message translates to:
  /// **'Owner ref.'**
  String get ownerRef;

  /// No description provided for @mtow.
  ///
  /// In en, this message translates to:
  /// **'Max take-off weight'**
  String get mtow;

  /// No description provided for @permits.
  ///
  /// In en, this message translates to:
  /// **'Permits'**
  String get permits;

  /// No description provided for @noStream.
  ///
  /// In en, this message translates to:
  /// **'This camera has no stream or snapshot URL.'**
  String get noStream;

  /// No description provided for @panelCctv.
  ///
  /// In en, this message translates to:
  /// **'CCTV'**
  String get panelCctv;

  /// No description provided for @findCameras.
  ///
  /// In en, this message translates to:
  /// **'Find nearby cameras'**
  String get findCameras;

  /// No description provided for @cctvHint.
  ///
  /// In en, this message translates to:
  /// **'Search cameras within 3 km of the estimated position.'**
  String get cctvHint;

  /// No description provided for @noCameras.
  ///
  /// In en, this message translates to:
  /// **'No cameras nearby.'**
  String get noCameras;

  /// No description provided for @openStream.
  ///
  /// In en, this message translates to:
  /// **'Open stream'**
  String get openStream;

  /// No description provided for @cctvAudited.
  ///
  /// In en, this message translates to:
  /// **'Every camera access is recorded in the audit log with this case.'**
  String get cctvAudited;

  /// No description provided for @panelObservations.
  ///
  /// In en, this message translates to:
  /// **'Observations'**
  String get panelObservations;

  /// No description provided for @bearing.
  ///
  /// In en, this message translates to:
  /// **'Bearing'**
  String get bearing;

  /// No description provided for @elevation.
  ///
  /// In en, this message translates to:
  /// **'Elevation'**
  String get elevation;

  /// No description provided for @gpsAccuracy.
  ///
  /// In en, this message translates to:
  /// **'GPS'**
  String get gpsAccuracy;

  /// No description provided for @spamScore.
  ///
  /// In en, this message translates to:
  /// **'Spam'**
  String get spamScore;

  /// No description provided for @fidelity.
  ///
  /// In en, this message translates to:
  /// **'Fidelity'**
  String get fidelity;

  /// No description provided for @attestation.
  ///
  /// In en, this message translates to:
  /// **'Attestation'**
  String get attestation;

  /// No description provided for @machineTranslation.
  ///
  /// In en, this message translates to:
  /// **'Machine translation'**
  String get machineTranslation;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @notUploaded.
  ///
  /// In en, this message translates to:
  /// **'Not uploaded'**
  String get notUploaded;

  /// No description provided for @captured.
  ///
  /// In en, this message translates to:
  /// **'Captured'**
  String get captured;

  /// No description provided for @imageFailed.
  ///
  /// In en, this message translates to:
  /// **'Image could not be loaded'**
  String get imageFailed;

  /// No description provided for @panelTimeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get panelTimeline;

  /// No description provided for @mergedInto.
  ///
  /// In en, this message translates to:
  /// **'into {number}'**
  String mergedInto(String number);

  /// No description provided for @mergedFrom.
  ///
  /// In en, this message translates to:
  /// **'from {number}'**
  String mergedFrom(String number);

  /// No description provided for @template.
  ///
  /// In en, this message translates to:
  /// **'Template'**
  String get template;

  /// No description provided for @officersCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 officer} other{{count} officers}}'**
  String officersCount(int count);

  /// No description provided for @defenseNoteAdded.
  ///
  /// In en, this message translates to:
  /// **'Defense note (encrypted)'**
  String get defenseNoteAdded;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get user;

  /// No description provided for @defenseNotes.
  ///
  /// In en, this message translates to:
  /// **'Defense notes'**
  String get defenseNotes;

  /// No description provided for @ackDue.
  ///
  /// In en, this message translates to:
  /// **'Acknowledge within'**
  String get ackDue;

  /// No description provided for @desk.
  ///
  /// In en, this message translates to:
  /// **'Desk'**
  String get desk;

  /// No description provided for @mergedNotice.
  ///
  /// In en, this message translates to:
  /// **'This case was merged into another case.'**
  String get mergedNotice;

  /// No description provided for @openSurvivor.
  ///
  /// In en, this message translates to:
  /// **'Open surviving case'**
  String get openSurvivor;

  /// No description provided for @redactedNotice.
  ///
  /// In en, this message translates to:
  /// **'Redacted: your clearance does not cover this case. Only location, time and severity are shown.'**
  String get redactedNotice;

  /// No description provided for @readOnlyNotice.
  ///
  /// In en, this message translates to:
  /// **'Read-only: this case is held by {desk}. Only that desk or its agency\'s supervisors can act on it.'**
  String readOnlyNotice(String desk);

  /// No description provided for @assignedOfficers.
  ///
  /// In en, this message translates to:
  /// **'Assigned field officers'**
  String get assignedOfficers;

  /// No description provided for @noPosition.
  ///
  /// In en, this message translates to:
  /// **'No position yet'**
  String get noPosition;

  /// No description provided for @redactedTitle.
  ///
  /// In en, this message translates to:
  /// **'Redacted case'**
  String get redactedTitle;

  /// No description provided for @redactedExplain.
  ///
  /// In en, this message translates to:
  /// **'This case carries a classification above your clearance. It was routed to your desk as a redacted copy so you know something is happening at this location; the cleared desk is handling it. Observations, evidence and informant data are withheld.'**
  String get redactedExplain;

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

  /// No description provided for @layerZones.
  ///
  /// In en, this message translates to:
  /// **'Zones'**
  String get layerZones;

  /// No description provided for @layerAircraft.
  ///
  /// In en, this message translates to:
  /// **'Aircraft'**
  String get layerAircraft;

  /// No description provided for @layerOfficers.
  ///
  /// In en, this message translates to:
  /// **'Field officers'**
  String get layerOfficers;

  /// No description provided for @layerRecentClosed.
  ///
  /// In en, this message translates to:
  /// **'Recent closed'**
  String get layerRecentClosed;

  /// No description provided for @liveMapCounts.
  ///
  /// In en, this message translates to:
  /// **'{cases} cases · {aircraft} aircraft · {officers} officers'**
  String liveMapCounts(int cases, int aircraft, int officers);

  /// No description provided for @openCase.
  ///
  /// In en, this message translates to:
  /// **'Open case'**
  String get openCase;

  /// No description provided for @lastNDays.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String lastNDays(int days);

  /// No description provided for @customRange.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get customRange;

  /// No description provided for @kpiIncidents.
  ///
  /// In en, this message translates to:
  /// **'Incidents'**
  String get kpiIncidents;

  /// No description provided for @kpiObservations.
  ///
  /// In en, this message translates to:
  /// **'{count} observations'**
  String kpiObservations(int count);

  /// No description provided for @kpiAuthorizedShare.
  ///
  /// In en, this message translates to:
  /// **'Authorized share'**
  String get kpiAuthorizedShare;

  /// No description provided for @kpiRemoteIdCoverage.
  ///
  /// In en, this message translates to:
  /// **'Remote ID coverage'**
  String get kpiRemoteIdCoverage;

  /// No description provided for @kpiSensorConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Sensor confirmed'**
  String get kpiSensorConfirmed;

  /// No description provided for @kpiFalseReports.
  ///
  /// In en, this message translates to:
  /// **'False reports'**
  String get kpiFalseReports;

  /// No description provided for @kpiAckP50.
  ///
  /// In en, this message translates to:
  /// **'Time to ack (p50)'**
  String get kpiAckP50;

  /// No description provided for @kpiAckP90.
  ///
  /// In en, this message translates to:
  /// **'Time to ack (p90)'**
  String get kpiAckP90;

  /// No description provided for @minSec.
  ///
  /// In en, this message translates to:
  /// **'min:sec'**
  String get minSec;

  /// No description provided for @hotspots.
  ///
  /// In en, this message translates to:
  /// **'Hotspots'**
  String get hotspots;

  /// No description provided for @allSeverities.
  ///
  /// In en, this message translates to:
  /// **'All severities'**
  String get allSeverities;

  /// No description provided for @allHours.
  ///
  /// In en, this message translates to:
  /// **'All hours'**
  String get allHours;

  /// No description provided for @allDays.
  ///
  /// In en, this message translates to:
  /// **'All days'**
  String get allDays;

  /// No description provided for @hotspotLegend.
  ///
  /// In en, this message translates to:
  /// **'{cells} cells · {incidents} incidents. Larger and redder = more incidents.'**
  String hotspotLegend(int cells, int incidents);

  /// No description provided for @dowMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get dowMon;

  /// No description provided for @dowTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get dowTue;

  /// No description provided for @dowWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get dowWed;

  /// No description provided for @dowThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get dowThu;

  /// No description provided for @dowFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get dowFri;

  /// No description provided for @dowSat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get dowSat;

  /// No description provided for @dowSun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get dowSun;

  /// No description provided for @timeOfDay.
  ///
  /// In en, this message translates to:
  /// **'Time of day (Taipei time)'**
  String get timeOfDay;

  /// No description provided for @timeOfDayHint.
  ///
  /// In en, this message translates to:
  /// **'Darker = more incidents (max {max} per hour slot). Hover a cell for the count.'**
  String timeOfDayHint(int max);

  /// No description provided for @incidentsN.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 incident} other{{count} incidents}}'**
  String incidentsN(int count);

  /// No description provided for @zonesAuthorization.
  ///
  /// In en, this message translates to:
  /// **'Zones: authorized vs. unauthorized'**
  String get zonesAuthorization;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data for this period.'**
  String get noData;

  /// No description provided for @zone.
  ///
  /// In en, this message translates to:
  /// **'Zone'**
  String get zone;

  /// No description provided for @zoneType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get zoneType;

  /// No description provided for @responsePerformance.
  ///
  /// In en, this message translates to:
  /// **'Response performance'**
  String get responsePerformance;

  /// No description provided for @byAgency.
  ///
  /// In en, this message translates to:
  /// **'By agency'**
  String get byAgency;

  /// No description provided for @byDesk.
  ///
  /// In en, this message translates to:
  /// **'By desk'**
  String get byDesk;

  /// No description provided for @ackP50Minutes.
  ///
  /// In en, this message translates to:
  /// **'Ack p50 (minutes)'**
  String get ackP50Minutes;

  /// No description provided for @ackP90Minutes.
  ///
  /// In en, this message translates to:
  /// **'Ack p90 (minutes)'**
  String get ackP90Minutes;

  /// No description provided for @agency.
  ///
  /// In en, this message translates to:
  /// **'Agency'**
  String get agency;

  /// No description provided for @cases.
  ///
  /// In en, this message translates to:
  /// **'Cases'**
  String get cases;

  /// No description provided for @ackP50.
  ///
  /// In en, this message translates to:
  /// **'Ack p50'**
  String get ackP50;

  /// No description provided for @ackP90.
  ///
  /// In en, this message translates to:
  /// **'Ack p90'**
  String get ackP90;

  /// No description provided for @resolveP50.
  ///
  /// In en, this message translates to:
  /// **'Resolve p50'**
  String get resolveP50;

  /// No description provided for @rerouteRate.
  ///
  /// In en, this message translates to:
  /// **'Reroute rate'**
  String get rerouteRate;

  /// No description provided for @unackedRate.
  ///
  /// In en, this message translates to:
  /// **'Unacknowledged'**
  String get unackedRate;

  /// No description provided for @sourceQuality.
  ///
  /// In en, this message translates to:
  /// **'Source quality'**
  String get sourceQuality;

  /// No description provided for @source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// No description provided for @sensorConfirmedShare.
  ///
  /// In en, this message translates to:
  /// **'Sensor confirmed'**
  String get sensorConfirmedShare;

  /// No description provided for @falseReportRate.
  ///
  /// In en, this message translates to:
  /// **'False-report rate'**
  String get falseReportRate;

  /// No description provided for @repeatOffenders.
  ///
  /// In en, this message translates to:
  /// **'Repeat offenders'**
  String get repeatOffenders;

  /// No description provided for @bySerial.
  ///
  /// In en, this message translates to:
  /// **'By Remote ID serial'**
  String get bySerial;

  /// No description provided for @byOwner.
  ///
  /// In en, this message translates to:
  /// **'By registered owner'**
  String get byOwner;

  /// No description provided for @unauthorized.
  ///
  /// In en, this message translates to:
  /// **'Unauthorized'**
  String get unauthorized;

  /// No description provided for @caseNumbers.
  ///
  /// In en, this message translates to:
  /// **'Cases'**
  String get caseNumbers;

  /// No description provided for @drones.
  ///
  /// In en, this message translates to:
  /// **'Drones'**
  String get drones;

  /// No description provided for @repeatOffendersAudited.
  ///
  /// In en, this message translates to:
  /// **'Viewing repeat offenders is recorded in the audit log.'**
  String get repeatOffendersAudited;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @newZone.
  ///
  /// In en, this message translates to:
  /// **'New zone'**
  String get newZone;

  /// No description provided for @editZone.
  ///
  /// In en, this message translates to:
  /// **'Edit zone'**
  String get editZone;

  /// No description provided for @published.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get published;

  /// No description provided for @publishedHint.
  ///
  /// In en, this message translates to:
  /// **'Shown to the public in the informant app (CAA zones only)'**
  String get publishedHint;

  /// No description provided for @selectZone.
  ///
  /// In en, this message translates to:
  /// **'Select a zone or create a new one.'**
  String get selectZone;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @zoneFieldsRequired.
  ///
  /// In en, this message translates to:
  /// **'Code, English and Chinese names are required'**
  String get zoneFieldsRequired;

  /// No description provided for @zoneNeedsPolygon.
  ///
  /// In en, this message translates to:
  /// **'Draw at least three points on the map'**
  String get zoneNeedsPolygon;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @vertexHelp.
  ///
  /// In en, this message translates to:
  /// **'{count} points · click map to add, drag to move, long-press to delete'**
  String vertexHelp(int count);

  /// No description provided for @code.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get code;

  /// No description provided for @nameEn.
  ///
  /// In en, this message translates to:
  /// **'Name (English)'**
  String get nameEn;

  /// No description provided for @nameZh.
  ///
  /// In en, this message translates to:
  /// **'Name (Chinese)'**
  String get nameZh;

  /// No description provided for @classification.
  ///
  /// In en, this message translates to:
  /// **'Classification'**
  String get classification;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @primaryDesk.
  ///
  /// In en, this message translates to:
  /// **'Primary desk'**
  String get primaryDesk;

  /// No description provided for @backupChain.
  ///
  /// In en, this message translates to:
  /// **'Backup chain (in order)'**
  String get backupChain;

  /// No description provided for @addBackupDesk.
  ///
  /// In en, this message translates to:
  /// **'Add backup desk'**
  String get addBackupDesk;

  /// No description provided for @backupChainHint.
  ///
  /// In en, this message translates to:
  /// **'Unacknowledged cases move down this chain; every chain ends at the national catch-all desk.'**
  String get backupChainHint;

  /// No description provided for @ackTimeouts.
  ///
  /// In en, this message translates to:
  /// **'Acknowledgement timeouts (seconds, blank = default)'**
  String get ackTimeouts;

  /// No description provided for @defaultValue.
  ///
  /// In en, this message translates to:
  /// **'default'**
  String get defaultValue;

  /// No description provided for @tabZones.
  ///
  /// In en, this message translates to:
  /// **'Zones & routing'**
  String get tabZones;

  /// No description provided for @tabTemplates.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get tabTemplates;

  /// No description provided for @tabFeedClients.
  ///
  /// In en, this message translates to:
  /// **'Feed clients'**
  String get tabFeedClients;

  /// No description provided for @templatesHint.
  ///
  /// In en, this message translates to:
  /// **'Templates are the only messages informants ever receive. Every template needs all six languages.'**
  String get templatesHint;

  /// No description provided for @newTemplate.
  ///
  /// In en, this message translates to:
  /// **'New template'**
  String get newTemplate;

  /// No description provided for @editTemplate.
  ///
  /// In en, this message translates to:
  /// **'Edit template'**
  String get editTemplate;

  /// No description provided for @outcomeTemplates.
  ///
  /// In en, this message translates to:
  /// **'Outcome'**
  String get outcomeTemplates;

  /// No description provided for @evidenceTemplates.
  ///
  /// In en, this message translates to:
  /// **'Evidence request'**
  String get evidenceTemplates;

  /// No description provided for @languages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get languages;

  /// No description provided for @allLanguagesRequired.
  ///
  /// In en, this message translates to:
  /// **'All six languages are required.'**
  String get allLanguagesRequired;

  /// No description provided for @feedClientsHint.
  ///
  /// In en, this message translates to:
  /// **'Credentials for sensor, Remote ID, ADS-B, weather, registry, permit and CCTV feeds.'**
  String get feedClientsHint;

  /// No description provided for @newFeedClient.
  ///
  /// In en, this message translates to:
  /// **'New feed client'**
  String get newFeedClient;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @sources.
  ///
  /// In en, this message translates to:
  /// **'Feeds'**
  String get sources;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @lastUsed.
  ///
  /// In en, this message translates to:
  /// **'Last used'**
  String get lastUsed;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @revoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get revoke;

  /// No description provided for @revoked.
  ///
  /// In en, this message translates to:
  /// **'Revoked'**
  String get revoked;

  /// No description provided for @revokeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Revoke the key of {name}? The feed stops immediately.'**
  String revokeConfirm(String name);

  /// No description provided for @feedKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Feed key'**
  String get feedKeyTitle;

  /// No description provided for @feedKeyOnce.
  ///
  /// In en, this message translates to:
  /// **'This key is shown only once. Store it in the feed system\'s secret store now.'**
  String get feedKeyOnce;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @keyStored.
  ///
  /// In en, this message translates to:
  /// **'I have stored the key'**
  String get keyStored;

  /// No description provided for @auditUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get auditUser;

  /// No description provided for @auditActionPrefix.
  ///
  /// In en, this message translates to:
  /// **'Action (prefix)'**
  String get auditActionPrefix;

  /// No description provided for @auditObjectId.
  ///
  /// In en, this message translates to:
  /// **'Object ID'**
  String get auditObjectId;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @auditViewAudited.
  ///
  /// In en, this message translates to:
  /// **'Viewing the audit log is itself audited.'**
  String get auditViewAudited;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @auditAction.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get auditAction;

  /// No description provided for @auditObject.
  ///
  /// In en, this message translates to:
  /// **'Object'**
  String get auditObject;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @domainAerial.
  ///
  /// In en, this message translates to:
  /// **'Aerial'**
  String get domainAerial;

  /// No description provided for @domainSurface.
  ///
  /// In en, this message translates to:
  /// **'Surface'**
  String get domainSurface;

  /// No description provided for @domainSubsurface.
  ///
  /// In en, this message translates to:
  /// **'Subsurface'**
  String get domainSubsurface;

  /// No description provided for @domainShore.
  ///
  /// In en, this message translates to:
  /// **'Shore'**
  String get domainShore;

  /// No description provided for @domainUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown domain'**
  String get domainUnknown;

  /// No description provided for @craftUavMultirotor.
  ///
  /// In en, this message translates to:
  /// **'Multirotor UAV'**
  String get craftUavMultirotor;

  /// No description provided for @craftUavFixedWing.
  ///
  /// In en, this message translates to:
  /// **'Fixed-wing UAV'**
  String get craftUavFixedWing;

  /// No description provided for @craftUav.
  ///
  /// In en, this message translates to:
  /// **'UAV'**
  String get craftUav;

  /// No description provided for @craftBalloon.
  ///
  /// In en, this message translates to:
  /// **'Balloon / airship'**
  String get craftBalloon;

  /// No description provided for @craftUsv.
  ///
  /// In en, this message translates to:
  /// **'Unmanned surface vessel (USV)'**
  String get craftUsv;

  /// No description provided for @craftSmallBoat.
  ///
  /// In en, this message translates to:
  /// **'Small boat'**
  String get craftSmallBoat;

  /// No description provided for @craftFishingVessel.
  ///
  /// In en, this message translates to:
  /// **'Fishing vessel'**
  String get craftFishingVessel;

  /// No description provided for @craftShip.
  ///
  /// In en, this message translates to:
  /// **'Ship'**
  String get craftShip;

  /// No description provided for @craftVessel.
  ///
  /// In en, this message translates to:
  /// **'Vessel'**
  String get craftVessel;

  /// No description provided for @craftSubmarine.
  ///
  /// In en, this message translates to:
  /// **'Submarine (periscope/mast)'**
  String get craftSubmarine;

  /// No description provided for @craftUuv.
  ///
  /// In en, this message translates to:
  /// **'Unmanned underwater vehicle'**
  String get craftUuv;

  /// No description provided for @craftLandedBoat.
  ///
  /// In en, this message translates to:
  /// **'Boat landed ashore'**
  String get craftLandedBoat;

  /// No description provided for @craftObjectAshore.
  ///
  /// In en, this message translates to:
  /// **'Object washed ashore'**
  String get craftObjectAshore;

  /// No description provided for @craftUnknownSubsurface.
  ///
  /// In en, this message translates to:
  /// **'Unknown subsurface contact'**
  String get craftUnknownSubsurface;

  /// No description provided for @panelAi.
  ///
  /// In en, this message translates to:
  /// **'AI triage (advisory)'**
  String get panelAi;

  /// No description provided for @aiAdvisoryNote.
  ///
  /// In en, this message translates to:
  /// **'Advisory only. The model can raise severity by at most one level, reaches Critical only with corroboration, and never lowers severity or closes a case.'**
  String get aiAdvisoryNote;

  /// No description provided for @aiThreat.
  ///
  /// In en, this message translates to:
  /// **'Threat assessment'**
  String get aiThreat;

  /// No description provided for @aiCraft.
  ///
  /// In en, this message translates to:
  /// **'Identified as'**
  String get aiCraft;

  /// No description provided for @aiSilhouette.
  ///
  /// In en, this message translates to:
  /// **'Silhouette'**
  String get aiSilhouette;

  /// No description provided for @aiUnmanned.
  ///
  /// In en, this message translates to:
  /// **'Unmanned likelihood'**
  String get aiUnmanned;

  /// No description provided for @aiSpam.
  ///
  /// In en, this message translates to:
  /// **'Unrelated-image likelihood'**
  String get aiSpam;

  /// No description provided for @aiConfidence.
  ///
  /// In en, this message translates to:
  /// **'Model confidence'**
  String get aiConfidence;

  /// No description provided for @aiMatchesReport.
  ///
  /// In en, this message translates to:
  /// **'Consistent with report'**
  String get aiMatchesReport;

  /// No description provided for @aiModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get aiModel;

  /// No description provided for @aiNone.
  ///
  /// In en, this message translates to:
  /// **'No AI assessment yet (photos are assessed after upload).'**
  String get aiNone;

  /// No description provided for @panelMaritime.
  ///
  /// In en, this message translates to:
  /// **'Maritime picture'**
  String get panelMaritime;

  /// No description provided for @vesselAis.
  ///
  /// In en, this message translates to:
  /// **'AIS vessel'**
  String get vesselAis;

  /// No description provided for @darkVessel.
  ///
  /// In en, this message translates to:
  /// **'Dark vessel: AIS coverage here, but nothing transmits near the contact'**
  String get darkVessel;

  /// No description provided for @noAisCoverage.
  ///
  /// In en, this message translates to:
  /// **'No AIS coverage in this area'**
  String get noAisCoverage;

  /// No description provided for @mdaTrack.
  ///
  /// In en, this message translates to:
  /// **'MDA sensor track (unidentified)'**
  String get mdaTrack;

  /// No description provided for @interviewAnswers.
  ///
  /// In en, this message translates to:
  /// **'Informant interview'**
  String get interviewAnswers;

  /// No description provided for @craftDomain.
  ///
  /// In en, this message translates to:
  /// **'Domain'**
  String get craftDomain;

  /// No description provided for @layerVessels.
  ///
  /// In en, this message translates to:
  /// **'Vessels (AIS / MDA)'**
  String get layerVessels;

  /// No description provided for @layerCameras.
  ///
  /// In en, this message translates to:
  /// **'Video feeds'**
  String get layerCameras;

  /// No description provided for @videoFeeds.
  ///
  /// In en, this message translates to:
  /// **'Video feeds'**
  String get videoFeeds;

  /// No description provided for @reasonSubsurface.
  ///
  /// In en, this message translates to:
  /// **'Subsurface contact'**
  String get reasonSubsurface;

  /// No description provided for @reasonPeopleUnloading.
  ///
  /// In en, this message translates to:
  /// **'People unloading ashore'**
  String get reasonPeopleUnloading;

  /// No description provided for @reasonCraftLanded.
  ///
  /// In en, this message translates to:
  /// **'Craft landed ashore'**
  String get reasonCraftLanded;

  /// No description provided for @reasonUsv.
  ///
  /// In en, this message translates to:
  /// **'Unmanned surface vessel'**
  String get reasonUsv;

  /// No description provided for @reasonUsvProtected.
  ///
  /// In en, this message translates to:
  /// **'USV in protected waters'**
  String get reasonUsvProtected;

  /// No description provided for @reasonUsvApproaching.
  ///
  /// In en, this message translates to:
  /// **'USV approaching the shore'**
  String get reasonUsvApproaching;

  /// No description provided for @reasonDarkProtected.
  ///
  /// In en, this message translates to:
  /// **'Dark vessel in protected waters'**
  String get reasonDarkProtected;

  /// No description provided for @reasonDarkTerritorial.
  ///
  /// In en, this message translates to:
  /// **'Dark vessel in territorial sea'**
  String get reasonDarkTerritorial;

  /// No description provided for @reasonUnidentifiedRestricted.
  ///
  /// In en, this message translates to:
  /// **'Unidentified craft in restricted waters'**
  String get reasonUnidentifiedRestricted;

  /// No description provided for @reasonVesselRestricted.
  ///
  /// In en, this message translates to:
  /// **'Vessel in restricted waters'**
  String get reasonVesselRestricted;

  /// No description provided for @reasonUnidentifiedProtected.
  ///
  /// In en, this message translates to:
  /// **'Unidentified craft in protected waters'**
  String get reasonUnidentifiedProtected;

  /// No description provided for @reasonAi.
  ///
  /// In en, this message translates to:
  /// **'AI assessment (advisory)'**
  String get reasonAi;

  /// No description provided for @zoneDomains.
  ///
  /// In en, this message translates to:
  /// **'Applies to'**
  String get zoneDomains;

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

  /// No description provided for @tabUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get tabUsers;

  /// No description provided for @newUser.
  ///
  /// In en, this message translates to:
  /// **'New user'**
  String get newUser;

  /// No description provided for @editUser.
  ///
  /// In en, this message translates to:
  /// **'Edit user'**
  String get editUser;

  /// No description provided for @usersHint.
  ///
  /// In en, this message translates to:
  /// **'Staff accounts for the console and the field app. Passwords need at least 12 characters.'**
  String get usersHint;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayName;

  /// No description provided for @fieldUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'Defense field unit'**
  String get fieldUnitLabel;

  /// No description provided for @initialPassword.
  ///
  /// In en, this message translates to:
  /// **'Initial password'**
  String get initialPassword;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'New password (leave empty to keep)'**
  String get resetPassword;

  /// No description provided for @deactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get deactivate;

  /// No description provided for @reactivate.
  ///
  /// In en, this message translates to:
  /// **'Reactivate'**
  String get reactivate;

  /// No description provided for @deactivated.
  ///
  /// In en, this message translates to:
  /// **'Deactivated'**
  String get deactivated;

  /// No description provided for @lockedLabel.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get lockedLabel;

  /// No description provided for @lastSeenLabel.
  ///
  /// In en, this message translates to:
  /// **'Last seen'**
  String get lastSeenLabel;

  /// No description provided for @userSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get userSaved;

  /// No description provided for @navAtreides.
  ///
  /// In en, this message translates to:
  /// **'Atreides'**
  String get navAtreides;

  /// No description provided for @atreidesTitle.
  ///
  /// In en, this message translates to:
  /// **'Atreides maritime sensor'**
  String get atreidesTitle;

  /// No description provided for @atreidesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Non-cooperative maritime detections (MDA) from Atreides. Not AIS: there is no vessel identity, speed or course. Each detection is classified as a mobile asset, a fixed site or ambiguous.'**
  String get atreidesSubtitle;

  /// No description provided for @atreidesAllBatches.
  ///
  /// In en, this message translates to:
  /// **'All imports'**
  String get atreidesAllBatches;

  /// No description provided for @atreidesDetections.
  ///
  /// In en, this message translates to:
  /// **'Detections'**
  String get atreidesDetections;

  /// No description provided for @atreidesTracks.
  ///
  /// In en, this message translates to:
  /// **'Tracks'**
  String get atreidesTracks;

  /// No description provided for @atreidesTrackSplit.
  ///
  /// In en, this message translates to:
  /// **'{routes} routes · {singles} single contacts'**
  String atreidesTrackSplit(int routes, int singles);

  /// No description provided for @atreidesRoleMobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile asset'**
  String get atreidesRoleMobile;

  /// No description provided for @atreidesRoleFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed site'**
  String get atreidesRoleFixed;

  /// No description provided for @atreidesRoleAmbiguous.
  ///
  /// In en, this message translates to:
  /// **'Ambiguous'**
  String get atreidesRoleAmbiguous;

  /// No description provided for @atreidesPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get atreidesPeriod;

  /// No description provided for @atreidesHighConfidence.
  ///
  /// In en, this message translates to:
  /// **'High confidence only'**
  String get atreidesHighConfidence;

  /// No description provided for @atreidesRoutesOnly.
  ///
  /// In en, this message translates to:
  /// **'Routes only'**
  String get atreidesRoutesOnly;

  /// No description provided for @atreidesTrackFacts.
  ///
  /// In en, this message translates to:
  /// **'{count} detections · {km} km'**
  String atreidesTrackFacts(int count, String km);

  /// No description provided for @atreidesSingleContact.
  ///
  /// In en, this message translates to:
  /// **'Single contact'**
  String get atreidesSingleContact;

  /// No description provided for @atreidesSourceView.
  ///
  /// In en, this message translates to:
  /// **'Source sensor: {role} ({confidence}) — {reasoning}'**
  String atreidesSourceView(String role, String confidence, String reasoning);

  /// No description provided for @atreidesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No Atreides data has been imported yet.'**
  String get atreidesEmpty;

  /// No description provided for @atreidesShowing.
  ///
  /// In en, this message translates to:
  /// **'Showing {shown} of {total}'**
  String atreidesShowing(int shown, int total);

  /// No description provided for @atreidesConfidence.
  ///
  /// In en, this message translates to:
  /// **'{level} confidence'**
  String atreidesConfidence(String level);

  /// No description provided for @atreidesConfHigh.
  ///
  /// In en, this message translates to:
  /// **'high'**
  String get atreidesConfHigh;

  /// No description provided for @atreidesConfLow.
  ///
  /// In en, this message translates to:
  /// **'low'**
  String get atreidesConfLow;

  /// No description provided for @consoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Reporting.tw: Monitoring suspicious aerial and water activity reports.'**
  String get consoleTitle;

  /// No description provided for @navMaritime.
  ///
  /// In en, this message translates to:
  /// **'Maritime'**
  String get navMaritime;

  /// No description provided for @maritimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Maritime behaviour alerts'**
  String get maritimeTitle;

  /// No description provided for @maritimeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unusual stops, detours, meetings at sea, reporting gaps and entries into protected waters, from AIS, Atreides and simulated tracks. For human review: an alert is not a verdict.'**
  String get maritimeSubtitle;

  /// No description provided for @tabAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get tabAlerts;

  /// No description provided for @tabThresholds.
  ///
  /// In en, this message translates to:
  /// **'Thresholds'**
  String get tabThresholds;

  /// No description provided for @tabEvaluation.
  ///
  /// In en, this message translates to:
  /// **'Rules vs statistics'**
  String get tabEvaluation;

  /// No description provided for @maritimeStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get maritimeStatusOpen;

  /// No description provided for @maritimeStatusAcknowledged.
  ///
  /// In en, this message translates to:
  /// **'Acknowledged'**
  String get maritimeStatusAcknowledged;

  /// No description provided for @maritimeStatusFalseAlarm.
  ///
  /// In en, this message translates to:
  /// **'False alarm'**
  String get maritimeStatusFalseAlarm;

  /// No description provided for @maritimeStatusDismissed.
  ///
  /// In en, this message translates to:
  /// **'Dismissed'**
  String get maritimeStatusDismissed;

  /// No description provided for @maritimeStatusEscalated.
  ///
  /// In en, this message translates to:
  /// **'Escalated to case'**
  String get maritimeStatusEscalated;

  /// No description provided for @maritimeStatusReopened.
  ///
  /// In en, this message translates to:
  /// **'Reopened'**
  String get maritimeStatusReopened;

  /// No description provided for @maritimeShowClosed.
  ///
  /// In en, this message translates to:
  /// **'Show closed'**
  String get maritimeShowClosed;

  /// No description provided for @maritimeAllKinds.
  ///
  /// In en, this message translates to:
  /// **'All behaviours'**
  String get maritimeAllKinds;

  /// No description provided for @kindStop.
  ///
  /// In en, this message translates to:
  /// **'Stop / loitering'**
  String get kindStop;

  /// No description provided for @kindDeviation.
  ///
  /// In en, this message translates to:
  /// **'Off usual lanes'**
  String get kindDeviation;

  /// No description provided for @kindCluster.
  ///
  /// In en, this message translates to:
  /// **'Vessels meeting'**
  String get kindCluster;

  /// No description provided for @kindZoneEntry.
  ///
  /// In en, this message translates to:
  /// **'Entered protected waters'**
  String get kindZoneEntry;

  /// No description provided for @kindApproach.
  ///
  /// In en, this message translates to:
  /// **'Approached protected waters'**
  String get kindApproach;

  /// No description provided for @kindGap.
  ///
  /// In en, this message translates to:
  /// **'Reporting gap'**
  String get kindGap;

  /// No description provided for @kindStatistical.
  ///
  /// In en, this message translates to:
  /// **'Statistically unusual'**
  String get kindStatistical;

  /// No description provided for @methodRules.
  ///
  /// In en, this message translates to:
  /// **'Rules'**
  String get methodRules;

  /// No description provided for @methodStat.
  ///
  /// In en, this message translates to:
  /// **'Statistical'**
  String get methodStat;

  /// No description provided for @methodBoth.
  ///
  /// In en, this message translates to:
  /// **'Rules + statistics'**
  String get methodBoth;

  /// No description provided for @maritimeRisk.
  ///
  /// In en, this message translates to:
  /// **'Risk {score}'**
  String maritimeRisk(int score);

  /// No description provided for @maritimeQuality.
  ///
  /// In en, this message translates to:
  /// **'Data quality {pct}%'**
  String maritimeQuality(int pct);

  /// No description provided for @maritimeWhy.
  ///
  /// In en, this message translates to:
  /// **'Why this alert'**
  String get maritimeWhy;

  /// No description provided for @maritimeUncertainty.
  ///
  /// In en, this message translates to:
  /// **'Uncertainty'**
  String get maritimeUncertainty;

  /// No description provided for @maritimeTimeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get maritimeTimeline;

  /// No description provided for @maritimeValue.
  ///
  /// In en, this message translates to:
  /// **'measured {value} · threshold {threshold}'**
  String maritimeValue(String value, String threshold);

  /// No description provided for @maritimeAck.
  ///
  /// In en, this message translates to:
  /// **'Acknowledge'**
  String get maritimeAck;

  /// No description provided for @maritimeFalseAlarm.
  ///
  /// In en, this message translates to:
  /// **'False alarm'**
  String get maritimeFalseAlarm;

  /// No description provided for @maritimeDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get maritimeDismiss;

  /// No description provided for @maritimeReopen.
  ///
  /// In en, this message translates to:
  /// **'Reopen'**
  String get maritimeReopen;

  /// No description provided for @maritimeEscalate.
  ///
  /// In en, this message translates to:
  /// **'Escalate to case'**
  String get maritimeEscalate;

  /// No description provided for @maritimeOpenCase.
  ///
  /// In en, this message translates to:
  /// **'Open case'**
  String get maritimeOpenCase;

  /// No description provided for @maritimeAddNote.
  ///
  /// In en, this message translates to:
  /// **'Add note'**
  String get maritimeAddNote;

  /// No description provided for @maritimeNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Note for the timeline'**
  String get maritimeNoteHint;

  /// No description provided for @maritimeSuppressHours.
  ///
  /// In en, this message translates to:
  /// **'Stay quiet for (hours)'**
  String get maritimeSuppressHours;

  /// No description provided for @maritimeFalseAlarmTitle.
  ///
  /// In en, this message translates to:
  /// **'Mark as false alarm'**
  String get maritimeFalseAlarmTitle;

  /// No description provided for @maritimeNone.
  ///
  /// In en, this message translates to:
  /// **'No alerts match.'**
  String get maritimeNone;

  /// No description provided for @maritimeSelect.
  ///
  /// In en, this message translates to:
  /// **'Select an alert to see why it was raised.'**
  String get maritimeSelect;

  /// No description provided for @maritimeSave.
  ///
  /// In en, this message translates to:
  /// **'Save and re-run'**
  String get maritimeSave;

  /// No description provided for @maritimeSaved.
  ///
  /// In en, this message translates to:
  /// **'Thresholds saved; detection re-run.'**
  String get maritimeSaved;

  /// No description provided for @maritimeDefault.
  ///
  /// In en, this message translates to:
  /// **'Default {value}'**
  String maritimeDefault(String value);

  /// No description provided for @maritimeReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Only supervisors and admins can change thresholds.'**
  String get maritimeReadOnly;

  /// No description provided for @evalIntro.
  ///
  /// In en, this message translates to:
  /// **'Simulated traffic around Taiwan with labelled behaviours: {tracks} tracks checked, {anomalous} of them anomalous. Precision: share of alerts that were real. Recall: share of real anomalies found.'**
  String evalIntro(int tracks, int anomalous);

  /// No description provided for @evalMethod.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get evalMethod;

  /// No description provided for @evalPrecision.
  ///
  /// In en, this message translates to:
  /// **'Precision'**
  String get evalPrecision;

  /// No description provided for @evalRecall.
  ///
  /// In en, this message translates to:
  /// **'Recall'**
  String get evalRecall;

  /// No description provided for @evalF1.
  ///
  /// In en, this message translates to:
  /// **'F1'**
  String get evalF1;

  /// No description provided for @evalFalseAlarms.
  ///
  /// In en, this message translates to:
  /// **'False alarms per 100 normal tracks'**
  String get evalFalseAlarms;

  /// No description provided for @evalCombined.
  ///
  /// In en, this message translates to:
  /// **'Combined risk score (what operators see)'**
  String get evalCombined;

  /// No description provided for @evalByKind.
  ///
  /// In en, this message translates to:
  /// **'Found per injected behaviour'**
  String get evalByKind;

  /// No description provided for @evalRun.
  ///
  /// In en, this message translates to:
  /// **'Re-run comparison'**
  String get evalRun;

  /// No description provided for @evalResimulate.
  ///
  /// In en, this message translates to:
  /// **'New simulated traffic'**
  String get evalResimulate;

  /// No description provided for @evalNone.
  ///
  /// In en, this message translates to:
  /// **'No comparison yet.'**
  String get evalNone;

  /// No description provided for @evalRanAt.
  ///
  /// In en, this message translates to:
  /// **'Run {when}'**
  String evalRanAt(String when);

  /// No description provided for @eventDetected.
  ///
  /// In en, this message translates to:
  /// **'Detected'**
  String get eventDetected;

  /// No description provided for @eventUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get eventUpdated;

  /// No description provided for @eventNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get eventNote;

  /// No description provided for @maritimeSourceSim.
  ///
  /// In en, this message translates to:
  /// **'Simulation'**
  String get maritimeSourceSim;

  /// No description provided for @maritimeSourceAtreides.
  ///
  /// In en, this message translates to:
  /// **'Atreides'**
  String get maritimeSourceAtreides;

  /// No description provided for @evRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Recommendation decided'**
  String get evRecommendation;

  /// No description provided for @recTitle.
  ///
  /// In en, this message translates to:
  /// **'Recommended actions'**
  String get recTitle;

  /// No description provided for @recIntro.
  ///
  /// In en, this message translates to:
  /// **'Decision support only: nothing here controls a device. Accepting a field unit assigns that officer; other actions are simulated and recorded.'**
  String get recIntro;

  /// No description provided for @recAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get recAccept;

  /// No description provided for @recReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get recReject;

  /// No description provided for @recModify.
  ///
  /// In en, this message translates to:
  /// **'Modify'**
  String get recModify;

  /// No description provided for @recModifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Modify recommendation'**
  String get recModifyTitle;

  /// No description provided for @recNewText.
  ///
  /// In en, this message translates to:
  /// **'What will be done'**
  String get recNewText;

  /// No description provided for @recNote.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get recNote;

  /// No description provided for @recAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get recAccepted;

  /// No description provided for @recRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get recRejected;

  /// No description provided for @recModified.
  ///
  /// In en, this message translates to:
  /// **'Modified'**
  String get recModified;

  /// No description provided for @recBy.
  ///
  /// In en, this message translates to:
  /// **'{who}, {when}'**
  String recBy(String who, String when);

  /// No description provided for @recNone.
  ///
  /// In en, this message translates to:
  /// **'No recommendations for this case.'**
  String get recNone;

  /// No description provided for @recReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Only the desk holding this case can decide.'**
  String get recReadOnly;
}

class _AgencyL10nDelegate extends LocalizationsDelegate<AgencyL10n> {
  const _AgencyL10nDelegate();

  @override
  Future<AgencyL10n> load(Locale locale) {
    return SynchronousFuture<AgencyL10n>(lookupAgencyL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AgencyL10nDelegate old) => false;
}

AgencyL10n lookupAgencyL10n(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'TW':
            return AgencyL10nZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AgencyL10nEn();
    case 'zh':
      return AgencyL10nZh();
  }

  throw FlutterError(
    'AgencyL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
