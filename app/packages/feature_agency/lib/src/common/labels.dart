import 'package:flutter/material.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_ui/uavr_ui.dart';

import 'l10n.dart';

String stateLabel(AgencyL10n l, CaseState s) => switch (s) {
      CaseState.newCase => l.stateNew,
      CaseState.acknowledged => l.stateAcknowledged,
      CaseState.investigating => l.stateInvestigating,
      CaseState.resolved => l.stateResolved,
      CaseState.closed => l.stateClosed,
      CaseState.merged => l.stateMerged,
    };

Color stateColor(CaseState s) => switch (s) {
      CaseState.newCase => UavrColors.critical,
      CaseState.acknowledged => UavrColors.medium,
      CaseState.investigating => UavrColors.brand,
      CaseState.resolved => UavrColors.low,
      _ => UavrColors.redacted,
    };

String stateWireLabel(AgencyL10n l, String? s) => s == null ? '—' : stateLabel(l, caseStateOf(s));

String authorizationLabel(AgencyL10n l, String a) => switch (a) {
      'likely_authorized' => l.authLikelyAuthorized,
      'no_permit' => l.authNoPermit,
      _ => l.authUnknown,
    };

Color authorizationColor(String a) => switch (a) {
      'likely_authorized' => UavrColors.low,
      'no_permit' => UavrColors.critical,
      _ => UavrColors.redacted,
    };

String classificationLabel(AgencyL10n l, int c) => switch (c) {
      2 => l.classDefense,
      1 => l.classRestricted,
      _ => l.classUnclassified,
    };

Color classificationColor(int c) => switch (c) {
      2 => UavrColors.zoneMilitary,
      1 => UavrColors.zoneInfra,
      _ => UavrColors.zoneOther,
    };

String sourceLabel(AgencyL10n l, String s) => switch (s) {
      'informant_android' => l.srcInformantAndroid,
      'informant_web' => l.srcInformantWeb,
      'field_officer' => l.srcFieldOfficer,
      'remote_id' => l.srcRemoteId,
      'rf_sensor' => l.srcRfSensor,
      'mda_sensor' => l.srcMdaSensor,
      'radar' => l.srcRadar,
      _ => s,
    };

IconData sourceIcon(String s) => switch (s) {
      'informant_android' => Icons.phone_android,
      'informant_web' => Icons.public,
      'field_officer' => Icons.local_police,
      'remote_id' => Icons.settings_input_antenna,
      'rf_sensor' => Icons.sensors,
      'mda_sensor' => Icons.sailing,
      'radar' => Icons.radar,
      _ => Icons.help_outline,
    };

String severityReasonLabel(AgencyL10n l, String r) => switch (r) {
      'near_manned_aircraft' => l.reasonNearMannedAircraft,
      'zone_airport' => l.reasonZoneAirport,
      'zone_military' => l.reasonZoneMilitary,
      'zone_critical_infrastructure' => l.reasonZoneInfrastructure,
      'zone_outlying_islands_strict' => l.reasonZoneOutlying,
      'sensor_confirmed_red_zone' => l.reasonSensorRedZone,
      'restricted_zone_no_permit' => l.reasonRestrictedNoPermit,
      'no_remote_id_controlled_airspace' => l.reasonNoRemoteId,
      'hovering_over_residences' => l.reasonHovering,
      'valid_permit' => l.reasonValidPermit,
      'single_unverified_web_report' => l.reasonSingleWebReport,
      'subsurface_contact' => l.reasonSubsurface,
      'people_unloading_ashore' => l.reasonPeopleUnloading,
      'craft_landed_ashore' => l.reasonCraftLanded,
      'unmanned_surface_vessel' => l.reasonUsv,
      'usv_in_protected_waters' => l.reasonUsvProtected,
      'usv_approaching_shore' => l.reasonUsvApproaching,
      'dark_vessel_protected_waters' => l.reasonDarkProtected,
      'dark_vessel_territorial_sea' => l.reasonDarkTerritorial,
      'unidentified_in_restricted_waters' => l.reasonUnidentifiedRestricted,
      'vessel_in_restricted_waters' => l.reasonVesselRestricted,
      'unidentified_craft_protected_waters' => l.reasonUnidentifiedProtected,
      'ai_assessment' => l.reasonAi,
      _ => r,
    };

String domainLabel(AgencyL10n l, String d) => switch (d) {
      'aerial' => l.domainAerial,
      'surface' => l.domainSurface,
      'subsurface' => l.domainSubsurface,
      'shore' => l.domainShore,
      _ => l.domainUnknown,
    };

IconData domainIcon(String d) => switch (d) {
      'surface' => Icons.directions_boat_filled_outlined,
      'subsurface' => Icons.waves,
      'shore' => Icons.beach_access_outlined,
      'aerial' => Icons.flight,
      _ => Icons.help_outline,
    };

String craftTypeLabel(AgencyL10n l, String? t) => switch (t) {
      'uav_multirotor' => l.craftUavMultirotor,
      'uav_fixed_wing' => l.craftUavFixedWing,
      'uav' => l.craftUav,
      'balloon' => l.craftBalloon,
      'usv' => l.craftUsv,
      'small_boat' => l.craftSmallBoat,
      'fishing_vessel' => l.craftFishingVessel,
      'ship' => l.craftShip,
      'vessel' => l.craftVessel,
      'submarine' => l.craftSubmarine,
      'uuv' => l.craftUuv,
      'landed_boat' => l.craftLandedBoat,
      'object_ashore' => l.craftObjectAshore,
      'unknown_subsurface' => l.craftUnknownSubsurface,
      null => '—',
      _ => t,
    };

String eventLabel(AgencyL10n l, String action) => switch (action) {
      'created' => l.evCreated,
      'acknowledged' => l.evAcknowledged,
      'investigating' => l.evInvestigating,
      'resolved' => l.evResolved,
      'closed' => l.evClosed,
      'rerouted' => l.evRerouted,
      'transferred' => l.evTransferred,
      'merged' => l.evMerged,
      'merged_from' => l.evMergedFrom,
      'severity_upgraded' => l.evSeverityUpgraded,
      'severity_downgraded' => l.evSeverityDowngraded,
      'assigned' => l.evAssigned,
      'field_assigned' => l.evFieldAssigned,
      'evidence_requested' => l.evEvidenceRequested,
      'evidence_received' => l.evEvidenceReceived,
      'observation_added' => l.evObservationAdded,
      'note' => l.evNote,
      'redacted_copy_sent' => l.evRedactedCopySent,
      'recommendation' => l.evRecommendation,
      _ => action,
    };

IconData eventIcon(String action) => switch (action) {
      'created' => Icons.add_alert,
      'acknowledged' => Icons.check_circle_outline,
      'investigating' => Icons.manage_search,
      'resolved' => Icons.task_alt,
      'closed' => Icons.lock_outline,
      'rerouted' => Icons.alt_route,
      'transferred' => Icons.swap_horiz,
      'merged' || 'merged_from' => Icons.merge,
      'severity_upgraded' => Icons.arrow_upward,
      'severity_downgraded' => Icons.arrow_downward,
      'assigned' || 'field_assigned' => Icons.person_add_alt,
      'evidence_requested' => Icons.add_a_photo_outlined,
      'evidence_received' => Icons.photo_library_outlined,
      'observation_added' => Icons.visibility_outlined,
      'note' => Icons.sticky_note_2_outlined,
      'redacted_copy_sent' => Icons.visibility_off_outlined,
      'recommendation' => Icons.rule,
      _ => Icons.circle_outlined,
    };

String evidenceStatusLabel(AgencyL10n l, String s) => switch (s) {
      'verified' => l.hashVerified,
      'hash_mismatch' => l.hashMismatch,
      _ => l.hashPending,
    };

Color evidenceStatusColor(String s) => switch (s) {
      'verified' => UavrColors.low,
      'hash_mismatch' => UavrColors.critical,
      _ => UavrColors.medium,
    };

/// Seconds -> "m:ss" / "h:mm:ss".
String durationLabel(num? seconds) {
  if (seconds == null) return '—';
  final s = seconds.round();
  final h = s ~/ 3600, m = (s % 3600) ~/ 60, sec = s % 60;
  String p(int v) => v.toString().padLeft(2, '0');
  return h > 0 ? '$h:${p(m)}:${p(sec)}' : '$m:${p(sec)}';
}

String percent(num? v) => v == null ? '—' : '${(v * 100).toStringAsFixed(v < 0.1 && v > 0 ? 1 : 0)}%';

String distanceLabel(num m) => m >= 1000 ? '${(m / 1000).toStringAsFixed(1)} km' : '${m.round()} m';

/// Short age label "12m", "3h", "2d".
String ageLabel(DateTime? t, {DateTime? now}) {
  if (t == null) return '—';
  final d = (now ?? DateTime.now()).difference(t);
  if (d.inMinutes < 60) return '${d.inMinutes < 0 ? 0 : d.inMinutes}m';
  if (d.inHours < 48) return '${d.inHours}h';
  return '${d.inDays}d';
}
