import uuid

from sqlalchemy import select

from uavr.db.models import AppUser, CaseEvent, CaseFieldAssignment, CctvCamera
from uavr.db.session import sessionmaker

from .helpers import SONGSHAN, report


async def test_recommendations_accept_reject_modify(client, desks, staff):
    officer = uuid.uuid4()
    async with sessionmaker()() as s:
        s.add(CctvCamera(id="CAM-SSN-1", name="Minquan E. Rd camera", lat=SONGSHAN[0] + 0.004, lon=SONGSHAN[1]))
        s.add(
            AppUser(
                id=officer,
                username="apb.field1",
                display_name="APB Unit 1",
                roles=["field_officer"],
                agency_id=desks["APB-OPS"].agency_id,
                field_unit=False,
                on_duty=True,
                last_lat=SONGSHAN[0] + 0.03,
                last_lon=SONGSHAN[1],
                clearance=1,
            )
        )
        await s.commit()

    r = await client.post("/v1/reports", json=report(SONGSHAN))
    assert r.status_code == 201, r.text
    apb = staff(desks["APB-OPS"])
    [c] = (await client.get("/v1/agency/queue", headers=apb)).json()["cases"]

    data = (await client.get(f"/v1/agency/cases/{c['id']}/recommendations", headers=apb)).json()
    assert data["can_act"] is True
    recs = {x["kind"]: x for x in data["recommendations"]}
    assert {"tower", "camera", "field", "warn"} <= set(recs)
    assert "Minquan" in recs["camera"]["text"] and recs["camera"]["reason"].endswith(" m from the estimated position")
    assert "APB Unit 1" in recs["field"]["text"]
    assert [x["priority"] for x in data["recommendations"]] == sorted(x["priority"] for x in data["recommendations"])

    url = f"/v1/agency/cases/{c['id']}/recommendations"
    # Modify needs new text; accept on the field unit assigns that officer.
    assert (
        await client.post(f"{url}/{recs['warn']['id']}", headers=apb, json={"decision": "modify"})
    ).status_code == 422
    r = await client.post(
        f"{url}/{recs['warn']['id']}",
        headers=apb,
        json={"decision": "modify", "text": "Loudspeaker warning at the park only", "note": "school nearby"},
    )
    assert (
        r.status_code == 200 and r.json()["status"] == "modified" and r.json()["final_text"].startswith("Loudspeaker")
    )
    assert (await client.post(f"{url}/{recs['camera']['id']}", headers=apb, json={"decision": "reject"})).json()[
        "status"
    ] == "rejected"
    assert (await client.post(f"{url}/{recs['field']['id']}", headers=apb, json={"decision": "accept"})).json()[
        "status"
    ] == "accepted"

    async with sessionmaker()() as s:
        assigned = (
            (await s.execute(select(CaseFieldAssignment.user_id).where(CaseFieldAssignment.active))).scalars().all()
        )
        assert officer in assigned
        acts = (
            await s.execute(select(CaseEvent.action, CaseEvent.data).where(CaseEvent.action == "recommendation"))
        ).all()
        assert sorted(d["decision"] for _a, d in acts) == ["accepted", "modified", "rejected"]

    # Decisions survive a refresh; read-only roles and other agencies cannot decide.
    again = {x["kind"]: x["status"] for x in (await client.get(url, headers=apb)).json()["recommendations"]}
    assert again["warn"] == "modified" and again["camera"] == "rejected" and again["tower"] == "proposed"
    analyst = staff(desks["APB-OPS"], roles=("analyst",))
    assert (await client.get(url, headers=analyst)).status_code == 200
    assert (
        await client.post(f"{url}/{recs['tower']['id']}", headers=analyst, json={"decision": "accept"})
    ).status_code == 403
    other = staff(desks["KCPD-DISPATCH"])
    assert (await client.get(url, headers=other)).status_code == 404
