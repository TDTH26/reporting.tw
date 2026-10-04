"""Severity rules (design doc, 'Routing, severity and escalation')."""

from dataclasses import dataclass, field

from ..domain.enums import Authorization, Severity, ZoneType

ZONE_SEVERITY = {
    ZoneType.airport: Severity.critical,
    ZoneType.military: Severity.critical,
    ZoneType.critical_infrastructure: Severity.critical,
    ZoneType.outlying_islands_strict: Severity.critical,
    ZoneType.red: Severity.medium,  # critical only when sensor-confirmed
    ZoneType.yellow: Severity.medium,
    ZoneType.residential: Severity.medium,
    ZoneType.open: Severity.low,
    ZoneType.jurisdiction: Severity.low,
}

CONTROLLED_AIRSPACE = {ZoneType.airport, ZoneType.red, ZoneType.yellow, ZoneType.military}


@dataclass
class SeverityInput:
    zone_types: set[str]
    authorization: Authorization
    sensor_confirmed: bool
    has_remote_id: bool
    adsb_nearby: bool
    only_web_reports: bool
    single_report: bool
    hovering: bool = False
    # Maritime
    domain: str = "aerial"
    unmanned_surface: bool = False
    dark_vessel: bool = False  # no AIS transmitter near a surface contact (with AIS coverage)
    ais_identified: bool = False
    shore_landing: bool = False
    people_unloading: bool = False
    approaching_shore: bool = False
    # Advisory AI assessment: may only raise severity.
    ai_threat: int = 0


@dataclass
class SeverityResult:
    severity: Severity
    reasons: list[str] = field(default_factory=list)


def compute(inp: SeverityInput) -> SeverityResult:
    reasons: list[str] = []
    sev = Severity.low

    def bump(level: Severity, reason: str):
        nonlocal sev
        reasons.append(reason)
        sev = max(sev, level)

    if inp.adsb_nearby:
        bump(Severity.critical, "near_manned_aircraft")
    zt = {ZoneType(z) for z in inp.zone_types if z in ZoneType.__members__}
    # Aerial-only zone rules (airports etc.) are pre-filtered by zone.domains in fusion.
    # Aerial: being in a critical zone is itself the threat. Maritime zones are busy with legitimate
    # traffic (Kinmen fishing fleets, harbours), so _maritime() decides from what the craft is.
    for z in zt if inp.domain == "aerial" else ():
        base = ZONE_SEVERITY.get(z, Severity.low)
        if base == Severity.critical:
            bump(base, f"zone_{z.value}")
    if ZoneType.red in zt and inp.sensor_confirmed:
        bump(Severity.critical, "sensor_confirmed_red_zone")

    permitted = inp.authorization == Authorization.likely_authorized
    if not permitted and inp.domain == "aerial":
        if zt & {ZoneType.red, ZoneType.yellow}:
            bump(Severity.medium, "restricted_zone_no_permit")
        if not inp.has_remote_id and zt & CONTROLLED_AIRSPACE:
            bump(Severity.medium, "no_remote_id_controlled_airspace")
        if ZoneType.residential in zt and inp.hovering:
            bump(Severity.medium, "hovering_over_residences")
    else:
        reasons.append("valid_permit")
        # A matching permit lowers everything except the manned-aircraft trigger.
        if not inp.adsb_nearby:
            sev = Severity.low

    if inp.domain != "aerial":
        _maritime(inp, zt, bump)

    if inp.ai_threat > sev:
        bump(Severity(inp.ai_threat), "ai_assessment")

    if inp.single_report and inp.only_web_reports and not inp.adsb_nearby:
        reasons.append("single_unverified_web_report")
        sev = min(sev, Severity.medium)

    return SeverityResult(sev, reasons)


PROTECTED_WATERS = {
    ZoneType.restricted_waters,
    ZoneType.harbor,
    ZoneType.coastal_defense,
    ZoneType.outlying_islands_strict,
    ZoneType.military,
    ZoneType.critical_infrastructure,
}


def _maritime(inp: SeverityInput, zt: set, bump) -> None:
    protected = bool(zt & PROTECTED_WATERS)
    if inp.domain == "subsurface":
        bump(Severity.critical, "subsurface_contact")
    if inp.people_unloading:
        bump(Severity.critical, "people_unloading_ashore")
    elif inp.shore_landing:
        bump(Severity.critical if protected else Severity.medium, "craft_landed_ashore")
    if inp.unmanned_surface:
        bump(Severity.medium, "unmanned_surface_vessel")
        if protected:
            bump(Severity.critical, "usv_in_protected_waters")
        if inp.approaching_shore:
            bump(Severity.critical, "usv_approaching_shore")
    if inp.dark_vessel:
        if protected:
            bump(Severity.critical, "dark_vessel_protected_waters")
        elif ZoneType.territorial_sea in zt:
            bump(Severity.medium, "dark_vessel_territorial_sea")
    elif ZoneType.restricted_waters in zt and not inp.ais_identified:
        bump(Severity.critical, "unidentified_in_restricted_waters")
    elif ZoneType.restricted_waters in zt:
        bump(Severity.medium, "vessel_in_restricted_waters")
    elif protected and not inp.ais_identified:
        bump(Severity.medium, "unidentified_craft_protected_waters")
