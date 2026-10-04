import asyncio
from datetime import UTC, datetime, timedelta

from sqlalchemy import func, select, text, update

from uavr.db.models import Case, CaseEvent, Incident, Observation
from uavr.db.session import sessionmaker

from .helpers import HSINCHU_MIL, KINMEN, SONGSHAN, XINYI, report


async def submit(client, body, status=201):
    r = await client.post("/v1/reports", json=body)
    assert r.status_code == status, r.text
    return r.json()


async def test_report_creates_routed_case_and_informant_sees_outcome(client, desks, staff):
    out = await submit(client, report(SONGSHAN, language="vi"))
    assert out["case_number"].startswith("UAV-")
    assert out["fidelity"] == "high"
    tok = {"X-Report-Token": out["token"]}

    mine = (await client.get("/v1/informant/cases", headers=tok)).json()
    assert mine[0]["status"] == "received"

    apb = staff(desks["APB-OPS"])
    q = (await client.get("/v1/agency/queue", headers=apb)).json()
    [c] = q["cases"]
    assert c["case_number"] == out["case_number"]
    assert c["severity"] == 3  # airport zone
    assert c["can_act"] is True

    # Another agency's dispatcher cannot see it.
    other = staff(desks["KCPD-DISPATCH"])
    assert (await client.get("/v1/agency/queue", headers=other)).json()["cases"] == []
    assert (await client.get(f"/v1/agency/cases/{c['id']}", headers=other)).status_code == 404

    r = await client.post(f"/v1/agency/cases/{c['id']}/acknowledge", headers=apb)
    assert r.status_code == 200 and r.json()["state"] == "acknowledged"
    assert (await client.get("/v1/informant/cases", headers=tok)).json()[0]["status"] == "in_review"

    r = await client.post(
        f"/v1/agency/cases/{c['id']}/resolve",
        headers=apb,
        json={"outcome_code": "operator_penalized", "note": "internal"},
    )
    assert r.status_code == 200, r.text
    mine = (await client.get("/v1/informant/cases", headers=tok)).json()[0]
    assert mine["status"] == "completed"
    assert mine["outcome_code"] == "operator_penalized"
    assert "xử phạt" in mine["outcome_text"]
    assert [t["status"] for t in mine["timeline"]] == ["received", "in_review", "completed"]
    assert "internal" not in str(mine)

    detail = (await client.get(f"/v1/agency/cases/{c['id']}", headers=apb)).json()
    assert [e["action"] for e in detail["events"]][:2] == ["created", "acknowledged"]
    async with sessionmaker()() as s:
        n = (await s.execute(text("SELECT count(*) FROM audit_log WHERE action = 'case.view'"))).scalar_one()
        assert n == 1


async def test_bad_token_rejected(client):
    out = await submit(client, report(XINYI))
    bad = out["token"].split(".")[0] + ".nope"
    assert (await client.get("/v1/informant/cases", headers={"X-Report-Token": bad})).status_code == 401


async def test_surge_of_reports_becomes_one_incident(client):
    bodies = [report(XINYI, observer_dist=300 + (i % 7) * 60, observer_bearing=i * 7.3, jitter=4) for i in range(150)]
    results = await asyncio.gather(*(client.post("/v1/reports", json=b) for b in bodies))
    assert all(r.status_code == 201 for r in results), [r.text for r in results if r.status_code != 201][:2]
    numbers = {r.json()["case_number"] for r in results}
    assert len(numbers) == 1
    async with sessionmaker()() as s:
        assert (await s.execute(select(func.count()).select_from(Incident))).scalar_one() == 1
        inc = (await s.execute(select(Incident))).scalar_one()
        assert inc.position_source == "triangulated"
        assert inc.observation_count == 150
        assert inc.distinct_informants == 150
        assert inc.confidence > 0.99
        from uavr.domain.geo import distance_m

        assert distance_m(inc.est_lat, inc.est_lon, *XINYI) < 50


async def test_separate_drones_make_separate_incidents(client):
    a = await submit(client, report(XINYI))
    b = await submit(client, report(SONGSHAN))
    c = await submit(client, report(KINMEN))
    assert len({a["case_number"], b["case_number"], c["case_number"]}) == 3


async def test_remote_id_serial_links_reports_far_apart(client):
    rid = lambda lat, lon: [
        {
            "transport": "bt5",
            "received_at": datetime.now(UTC).isoformat(),  # noqa: E731
            "uas_id": "1581F5FKD229400B",
            "id_type": "serial",
            "lat": lat,
            "lon": lon,
            "height_m": 90,
            "operator_lat": 25.031,
            "operator_lon": 121.56,
        }
    ]
    a = await submit(client, report(XINYI, remote_id=rid(*XINYI)))
    moved = (XINYI[0] + 0.03, XINYI[1])  # ~3.3 km away, beyond the clustering radius
    b = await submit(client, report(moved, remote_id=rid(*moved)))
    assert a["case_number"] == b["case_number"]


async def test_unacknowledged_case_reroutes_to_backup(client, desks, staff):
    from uavr.worker import escalate_overdue

    out = await submit(client, report(SONGSHAN))
    async with sessionmaker()() as s:
        await s.execute(update(Case).values(ack_deadline=datetime.now(UTC) - timedelta(seconds=1)))
        await s.commit()
    assert await escalate_overdue() == 1
    async with sessionmaker()() as s:
        c = (await s.execute(select(Case))).unique().scalar_one()
        assert c.desk_id == desks["TCPD-DISPATCH"].id  # APT-TSA backup chain: TCPD next
        assert c.state == "new"
        assert desks["APB-OPS"].agency_id in c.read_agency_ids
        actions = [e.action for e in (await s.execute(select(CaseEvent).order_by(CaseEvent.id))).scalars()]
        assert actions[-1] == "rerouted"
    # The original agency keeps read access but cannot act.
    apb = staff(desks["APB-OPS"])
    q = (await client.get("/v1/agency/queue?scope=agency", headers=apb)).json()["cases"]
    assert q and q[0]["can_act"] is False
    tc = staff(desks["TCPD-DISPATCH"])
    q = (await client.get("/v1/agency/queue", headers=tc)).json()["cases"]
    assert q[0]["case_number"] == out["case_number"] and q[0]["can_act"]


async def test_unstaffed_desk_is_skipped(client, desks, staff):
    # MND-AIRBASE is not always staffed and nobody is on duty: the military case goes to MND-JOC.
    await submit(client, report(HSINCHU_MIL))
    async with sessionmaker()() as s:
        c = (await s.execute(select(Case))).unique().scalar_one()
        assert c.classification == 2 and c.severity == 3
        assert c.desk_id == desks["MND-JOC"].id
        # The uncleared national police desk only gets the redacted case.
        assert desks["NPA-CMD"].id in c.redacted_desk_ids

    # Put an airbase dispatcher on duty: the next military case goes there.
    airbase = staff(desks["MND-AIRBASE"])
    assert (await client.put("/v1/agency/me/duty", headers=airbase, json={"on_duty": True})).status_code == 200
    async with sessionmaker()() as s:
        await s.execute(update(Incident).values(active=False))
        await s.commit()
    await submit(client, report(HSINCHU_MIL))
    async with sessionmaker()() as s:
        newest = (await s.execute(select(Case).order_by(Case.created_at.desc()).limit(1))).unique().scalar_one()
        assert newest.desk_id == desks["MND-AIRBASE"].id


async def test_defense_case_redaction_and_generic_outcome(client, desks, staff):
    out = await submit(client, report(HSINCHU_MIL, description="看到一台無人機在基地上空"))
    npa = staff(desks["NPA-CMD"])
    [c] = (await client.get("/v1/agency/queue", headers=npa)).json()["cases"]
    assert c["redacted"] is True and "observation_count" not in c
    d = (await client.get(f"/v1/agency/cases/{c['id']}", headers=npa)).json()
    assert d["redacted"] and "observations" not in d and d["position"]

    joc = staff(desks["MND-JOC"])
    d = (await client.get(f"/v1/agency/cases/{c['id']}", headers=joc)).json()
    assert d["redacted"] is False and d["observations"][0]["description"].startswith("看到")
    for path, body in (("acknowledge", None), ("notes", {"text": "intercept team dispatched", "defense": True})):
        r = await client.post(f"/v1/agency/cases/{c['id']}/{path}", headers=joc, json=body)
        assert r.status_code == 200, r.text
    d = (await client.get(f"/v1/agency/cases/{c['id']}", headers=joc)).json()
    assert "intercept team" in d["defense_notes"]
    async with sessionmaker()() as s:
        raw = (await s.execute(select(Case.defense_notes_enc))).scalar_one()
        assert b"intercept" not in raw

    r = await client.post(
        f"/v1/agency/cases/{c['id']}/resolve", headers=joc, json={"outcome_code": "operator_penalized"}
    )
    assert r.status_code == 200
    mine = (await client.get("/v1/informant/cases?lang=en", headers={"X-Report-Token": out["token"]})).json()[0]
    assert mine["outcome_code"] == "handled_by_authority"
    assert mine["outcome_text"] == "Handled by the relevant authority."


async def test_severity_downgrade_needs_reason_and_upgrade_restarts_timer(client, desks, staff):
    await submit(client, report(XINYI))  # residential -> low (not hovering)
    tc = staff(desks["TCPD-DISPATCH"])
    [c] = (await client.get("/v1/agency/queue", headers=tc)).json()["cases"]
    r = await client.post(f"/v1/agency/cases/{c['id']}/severity", headers=tc, json={"severity": 3, "reason": "crowd"})
    assert r.status_code == 200 and r.json()["severity"] == 3
    deadline = datetime.fromisoformat(r.json()["ack_deadline"])
    assert deadline - datetime.now(UTC) < timedelta(seconds=125)
    r = await client.post(f"/v1/agency/cases/{c['id']}/severity", headers=tc, json={"severity": 1, "reason": " "})
    assert r.status_code == 422
    r = await client.post(
        f"/v1/agency/cases/{c['id']}/severity", headers=tc, json={"severity": 1, "reason": "toy drone in a park"}
    )
    assert r.status_code == 200 and r.json()["severity"] == 1


async def test_transfer_and_merge(client, desks, staff):
    a = await submit(client, report(XINYI))
    b = await submit(client, report(SONGSHAN))
    tc = staff(desks["TCPD-DISPATCH"])
    apb = staff(desks["APB-OPS"])
    ca = (await client.get(f"/v1/agency/cases/by-number/{a['case_number']}", headers=tc)).json()
    cb = (await client.get(f"/v1/agency/cases/by-number/{b['case_number']}", headers=apb)).json()
    # Transfer B from aviation police to Taipei police.
    r = await client.post(
        f"/v1/agency/cases/{cb['id']}/transfer",
        headers=apb,
        json={"desk_id": desks["TCPD-DISPATCH"].id, "reason": "outside airport perimeter"},
    )
    assert r.status_code == 200 and r.json()["desk_id"] == desks["TCPD-DISPATCH"].id
    # Taipei police merges B into A.
    r = await client.post(
        f"/v1/agency/cases/{ca['id']}/merge", headers=tc, json={"other_case_id": cb["id"], "reason": "same drone"}
    )
    assert r.status_code == 200, r.text
    assert r.json()["observation_count"] == 2
    # Informant of B follows the surviving case.
    mine = (await client.get("/v1/informant/cases", headers={"X-Report-Token": b["token"]})).json()
    assert {m["case_number"] for m in mine} >= {b["case_number"]}
    async with sessionmaker()() as s:
        states = dict((await s.execute(select(Case.case_number, Case.state))).all())
        assert states[b["case_number"]] == "merged"


async def test_evidence_request_roundtrip(client, desks, staff):
    out = await submit(client, report(XINYI, language="th"))
    tok = {"X-Report-Token": out["token"]}
    tc = staff(desks["TCPD-DISPATCH"])
    [c] = (await client.get("/v1/agency/queue", headers=tc)).json()["cases"]
    r = await client.post(
        f"/v1/agency/cases/{c['id']}/evidence-requests", headers=tc, json={"template_code": "video_flight_direction"}
    )
    assert r.json() == {"informants": 1}
    r = await client.post(
        f"/v1/agency/cases/{c['id']}/evidence-requests", headers=tc, json={"template_code": "free text is not allowed"}
    )
    assert r.status_code == 422
    [mine] = (await client.get("/v1/informant/cases", headers=tok)).json()
    [req] = mine["evidence_requests"]
    assert req["requested_kinds"] == ["video"] and "วิดีโอ" in req["text"]
    media = [
        {
            "slot": "v1",
            "kind": "video",
            "mime_type": "video/mp4",
            "sha256": "a" * 64,
            "size_bytes": 1000,
            "captured_at": datetime.now(UTC).isoformat(),
        }
    ]
    r = await client.post(f"/v1/informant/evidence-requests/{req['id']}/responses", headers=tok, json={"media": media})
    assert r.status_code == 200 and r.json()[0]["slot"] == "v1"
    r = await client.post(f"/v1/informant/evidence-requests/{req['id']}/responses", headers=tok, json={"media": media})
    assert r.status_code == 409


async def test_web_reports_are_low_fidelity(client):
    out = await submit(client, report(SONGSHAN, platform="web"))
    assert out["fidelity"] == "low" and out["suggest_android_app"] is True
    async with sessionmaker()() as s:
        c = (await s.execute(select(Case))).unique().scalar_one()
        assert c.severity == 2  # a single unverified web report never pages a desk as Critical
        o = (await s.execute(select(Observation))).scalar_one()
        assert o.source_type == "informant_web" and o.attestation == "skipped"


async def test_idempotent_retry(client):
    body = report(XINYI, token_secret="s" * 40)
    a = await submit(client, body)
    b = await client.post("/v1/reports", json=body)
    assert b.status_code == 201 and b.json()["case_number"] == a["case_number"] and b.json()["token"] == a["token"]
    body2 = dict(body, token_secret="t" * 40)
    assert (await client.post("/v1/reports", json=body2)).status_code == 409


async def test_device_rate_limit_and_attestation(client):
    for _ in range(10):
        await submit(client, report(XINYI, device="same-device-123"))
    await submit(client, report(XINYI, device="same-device-123"), status=429)
    await submit(client, report(SONGSHAN, attestation="dev-fail"))
    async with sessionmaker()() as s:
        o = (await s.execute(select(Observation).where(Observation.attestation == "failed"))).scalar_one()
        assert o.spam_score >= 0.4


async def test_case_event_is_append_only(client):
    await submit(client, report(XINYI))
    async with sessionmaker()() as s:
        try:
            await s.execute(text("UPDATE case_event SET reason = 'tamper'"))
            await s.commit()
            raise AssertionError("update should fail")
        except Exception as e:
            assert "append-only" in str(e)


async def test_published_zones_exclude_sensitive(client):
    fc = (await client.get("/v1/public/zones")).json()
    codes = {f["properties"]["code"] for f in fc["features"]}
    assert {"APT-TPE", "KNH-STRICT", "RED-PRES"} <= codes
    assert not any(c.startswith(("MIL-", "CI-", "JUR-")) for c in codes)
