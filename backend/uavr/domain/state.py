"""Case lifecycle: New -> Acknowledged -> Investigating -> Resolved -> Closed.

Side paths: Re-routed (to a backup desk as New) and Transferred (to another desk as New).
Merged is terminal for the absorbed case.
"""

from .enums import CaseAction, CaseState

_ALLOWED: dict[CaseAction, tuple[set[CaseState], CaseState]] = {
    CaseAction.acknowledged: ({CaseState.new}, CaseState.acknowledged),
    CaseAction.investigating: ({CaseState.acknowledged}, CaseState.investigating),
    CaseAction.resolved: ({CaseState.acknowledged, CaseState.investigating}, CaseState.resolved),
    CaseAction.closed: ({CaseState.resolved}, CaseState.closed),
    CaseAction.rerouted: ({CaseState.new}, CaseState.new),
    CaseAction.transferred: (
        {CaseState.new, CaseState.acknowledged, CaseState.investigating},
        CaseState.new,
    ),
    CaseAction.merged: (
        {CaseState.new, CaseState.acknowledged, CaseState.investigating},
        CaseState.merged,
    ),
}

OPEN_STATES = {CaseState.new, CaseState.acknowledged, CaseState.investigating}


class InvalidTransition(Exception):
    def __init__(self, action: CaseAction, state: CaseState):
        super().__init__(f"cannot {action.value} a case in state {state.value}")
        self.action = action
        self.state = state


def next_state(state: CaseState, action: CaseAction) -> CaseState:
    allowed, target = _ALLOWED[action]
    if state not in allowed:
        raise InvalidTransition(action, state)
    return target


def informant_status(state: CaseState) -> str:
    """Coarse status shown to anonymous informants."""
    return {
        CaseState.new: "received",
        CaseState.acknowledged: "in_review",
        CaseState.investigating: "in_progress",
        CaseState.resolved: "completed",
        CaseState.closed: "completed",
        CaseState.merged: "in_progress",
    }[state]
