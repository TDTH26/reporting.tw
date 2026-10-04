import 'package:uavr_api/uavr_api.dart';

const consoleRoles = {'dispatcher', 'supervisor', 'national', 'analyst', 'admin'};

bool hasConsoleAccess(Me me) => me.roles.any(consoleRoles.contains);

/// Roles that may read the queue and the live map (backend READERS).
bool canReadCases(Me me) => me.has('dispatcher') || me.has('supervisor') || me.has('national') || me.has('analyst');

bool canSeeDashboards(Me me) => me.has('analyst') || me.has('supervisor') || me.has('national');

bool canSeeAdmin(Me me) => me.has('admin');

bool canSeeAudit(Me me) => me.has('admin') || me.has('supervisor');

/// Dispatch roles (backend DISPATCH): may add notes on cases they fully see.
bool canDispatch(Me me) => me.has('dispatcher') || me.has('supervisor') || me.has('national');

/// Mirror of backend `abac.can_act`: live payloads do not carry the viewer-specific flag.
bool computeCanAct(Me me, CaseSummary c) {
  if (me.clearance < c.classification) return false;
  if (me.has('dispatcher') && me.desk != null && me.desk!.id == c.deskId) return true;
  if (me.has('supervisor') && me.agency != null && me.agency!.id == c.agencyId) return true;
  return me.has('national') && me.has('supervisor');
}

/// Atreides maritime sensor section (backend: every console role except field officers).
bool canSeeAtreides(Me me) => canReadCases(me) || me.has('admin');

/// Maritime alerts (backend /v1/maritime): readers, operators who decide, supervisors/admins who tune.
bool canSeeMaritime(Me me) => canSeeAtreides(me);
bool canDecideMaritime(Me me) => me.has('dispatcher') || me.has('supervisor') || me.has('national') || me.has('admin');
bool canTuneMaritime(Me me) => me.has('supervisor') || me.has('admin');
