import pytest

PW = "correct horse battery"


@pytest.fixture
async def admin(client, desks, staff):
    return staff(desks["NPA-CMD"], roles=("admin",), clearance=2)


async def make_user(client, admin, desks, username="tpe.officer", roles=("dispatcher",), **kw):
    r = await client.post(
        "/v1/admin/users",
        headers=admin,
        json={
            "username": username,
            "password": PW,
            "display_name": "Officer",
            "roles": list(roles),
            "desk_id": desks["TCPD-DISPATCH"].id,
            "clearance": 1,
            **kw,
        },
    )
    assert r.status_code == 201, r.text
    return r.json()


async def login(client, username="tpe.officer", password=PW, status=200):
    r = await client.post("/v1/auth/login", json={"username": username, "password": password})
    assert r.status_code == status, r.text
    return r.json()


async def test_login_refresh_rotation_and_logout(client, admin, desks):
    u = await make_user(client, admin, desks)
    assert u["agency_id"] == desks["TCPD-DISPATCH"].agency_id and u["has_password"]
    t = await login(client)
    h = {"Authorization": f"Bearer {t['access_token']}"}
    me = (await client.get("/v1/agency/me", headers=h)).json()
    assert me["username"] == "tpe.officer" and me["desk"]["code"] == "TCPD-DISPATCH" and me["clearance"] == 1

    t2 = (await client.post("/v1/auth/refresh", json={"refresh_token": t["refresh_token"]})).json()
    assert t2["refresh_token"] != t["refresh_token"]
    # The old refresh token was rotated out and cannot be reused.
    assert (await client.post("/v1/auth/refresh", json={"refresh_token": t["refresh_token"]})).status_code == 401
    assert (await client.post("/v1/auth/logout", json={"refresh_token": t2["refresh_token"]})).status_code == 204
    assert (await client.post("/v1/auth/refresh", json={"refresh_token": t2["refresh_token"]})).status_code == 401


async def test_wrong_password_and_lockout(client, admin, desks):
    await make_user(client, admin, desks)
    await login(client, password="nope", status=401)
    await login(client, username="nobody", password="nope", status=401)
    for _ in range(4):
        await login(client, password="still wrong", status=401)
    # Locked now (5 failures): even the right password is refused for a while.
    r = await client.post("/v1/auth/login", json={"username": "tpe.officer", "password": PW})
    assert r.status_code == 401 and "locked" in r.json()["detail"]


async def test_deactivation_takes_effect_immediately(client, admin, desks):
    u = await make_user(client, admin, desks)
    t = await login(client)
    h = {"Authorization": f"Bearer {t['access_token']}"}
    assert (await client.get("/v1/agency/me", headers=h)).status_code == 200
    body = {
        "display_name": "Officer",
        "roles": ["dispatcher"],
        "desk_id": desks["TCPD-DISPATCH"].id,
        "clearance": 1,
        "active": False,
    }
    assert (await client.put(f"/v1/admin/users/{u['id']}", headers=admin, json=body)).status_code == 200
    assert (await client.get("/v1/agency/me", headers=h)).status_code == 401
    assert (await client.post("/v1/auth/refresh", json={"refresh_token": t["refresh_token"]})).status_code == 401


async def test_password_policy_and_clearance_ceiling(client, desks, staff):
    limited_admin = staff(desks["TCPD-DISPATCH"], roles=("admin",), clearance=1)
    r = await client.post(
        "/v1/admin/users",
        headers=limited_admin,
        json={"username": "short", "password": "short", "roles": ["dispatcher"]},
    )
    assert r.status_code == 422
    r = await client.post(
        "/v1/admin/users",
        headers=limited_admin,
        json={"username": "defense.user", "password": PW, "roles": ["dispatcher"], "clearance": 2},
    )
    assert r.status_code == 403
    assert (await client.get("/v1/admin/users", headers=staff(desks["TCPD-DISPATCH"]))).status_code == 403


async def test_change_password_signs_out_other_sessions(client, admin, desks):
    await make_user(client, admin, desks)
    t = await login(client)
    h = {"Authorization": f"Bearer {t['access_token']}"}
    r = await client.post(
        "/v1/auth/password", headers=h, json={"current_password": PW, "new_password": "an even longer passphrase"}
    )
    assert r.status_code == 204
    assert (await client.post("/v1/auth/refresh", json={"refresh_token": t["refresh_token"]})).status_code == 401
    await login(client, password="an even longer passphrase")
