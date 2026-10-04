# 5. Severity and routing rules as implemented

* Severity is recomputed on every observation (`uavr/fusion/severity.py`). Rules per the design doc, plus:
  a **single unverified web report caps at Medium**, so an unattested browser report can never page a desk
  with a 2-minute Critical timer; a corroborating Android/sensor report lifts the cap.
* Only upgrades are automatic. A dispatcher downgrade needs a reason; afterwards only a *new* trigger raises it again.
* An upgrade on a New case restarts the ack timer at the shorter timeout.
* Routing: highest-priority matched zone → primary desk → backup chain → national catch-all (NPA command
  centre); classified cases end at a cleared catch-all (MND JOC). Unstaffed desks (no on-duty dispatcher and not
  `always_staffed`) are skipped; uncleared desks in the chain get the redacted copy only.
* Raising a case's classification while it sits at an uncleared desk re-routes it immediately.
* Defense cases always show informants the outcome "Handled by the relevant authority".
