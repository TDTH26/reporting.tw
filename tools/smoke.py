"""End-to-end smoke test against the running dev stack (make up && make seed).

    cd backend && uv run python ../tools/smoke.py [--base http://localhost:8480]
"""

import argparse
import base64
import hashlib
import os
import sys
import time
import uuid
from datetime import UTC, datetime

import httpx


def b64(s: str) -> str:
    return base64.b64encode(s.encode()).decode()


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--base", default="http://localhost:8480")
    ap.add_argument("--password", default="dev-password-123", help="password of the dev staff accounts (make seed)")
    a = ap.parse_args()
    api = f"{a.base}/api"
    c = httpx.Client(timeout=20)

    photo = os.urandom(200_000)
    sha = hashlib.sha256(photo).hexdigest()
    body = {
        "client_report_id": str(uuid.uuid4()),
        "platform": "android",
        "app_version": "smoke",
        "language": "en",
        "device_id": f"smoke-{uuid.uuid4().hex}",
        "observed_at": datetime.now(UTC).isoformat(),
        "observer": {"lat": 25.0655, "lon": 121.5480, "accuracy_m": 6},
        "bearing_deg": 70.0,
        "elevation_deg": 15.0,
        "media": [{"slot": "p1", "kind": "photo", "mime_type": "image/jpeg", "sha256": sha,
                   "size_bytes": len(photo), "captured_at": datetime.now(UTC).isoformat()}],
        "attestation_token": "dev-pass",
    }
    r = c.post(f"{api}/v1/reports", json=body)
    r.raise_for_status()
    rep = r.json()
    print("report:", rep["case_number"], rep["status"], rep["fidelity"])

    t = rep["uploads"][0]
    r = c.post(t["upload_url"], headers={
        "Tus-Resumable": "1.0.0", "Upload-Length": str(len(photo)), "Upload-Token": t["upload_token"],
        "Upload-Metadata": f"filename {b64('p1.jpg')},filetype {b64('image/jpeg')}",
    })
    assert r.status_code == 201, (r.status_code, r.text)
    loc = r.headers["Location"]
    # Upload in two chunks to exercise resumption.
    half = len(photo) // 2
    for off, chunk in ((0, photo[:half]), (half, photo[half:])):
        r = c.patch(loc, content=chunk, headers={"Tus-Resumable": "1.0.0", "Upload-Offset": str(off),
                                                  "Content-Type": "application/offset+octet-stream"})
        assert r.status_code == 204, (r.status_code, r.text)
    print("upload: done", loc)

    def login(user: str) -> dict:
        r = c.post(f"{api}/v1/auth/login", json={"username": user, "password": a.password})
        r.raise_for_status()
        return {"Authorization": f"Bearer {r.json()['access_token']}"}

    h = login("admin")  # national role: can read every agency's cases
    d = c.get(f"{api}/v1/agency/cases/by-number/{rep['case_number']}", headers=h).raise_for_status().json()
    desk_users = {"APB-OPS": "apb.dispatcher", "TCPD-DISPATCH": "tpe.dispatcher"}
    desks = {x["id"]: x["code"] for x in c.get(f"{api}/v1/agency/desks", headers=h).json()}
    h = login(desk_users[desks[d["desk_id"]]])

    def my_evidence() -> dict:
        d = c.get(f"{api}/v1/agency/cases/by-number/{rep['case_number']}", headers=h).raise_for_status().json()
        return d, next(e for o in d["observations"] for e in o["evidence"] if e["sha256"] == sha)

    d, ev = my_evidence()
    for _ in range(20):
        if ev["status"] != "pending":
            break
        time.sleep(0.5)
        d, ev = my_evidence()
    print("console: desk", desks[d["desk_id"]], "severity", d["severity"], "zones",
          [z["code"] for z in d["incident"]["zones"]])
    print("evidence:", ev["status"])
    assert ev["status"] == "verified"
    url = c.get(f"{api}/v1/agency/evidence/{ev['id']}/url", headers=h).json()["url"]
    got = c.get(url)
    got.raise_for_status()
    assert hashlib.sha256(got.content).hexdigest() == sha
    print("download: hash matches")
    if d["state"] == "new":
        c.post(f"{api}/v1/agency/cases/{d['id']}/acknowledge", headers=h).raise_for_status()
    st = c.get(f"{api}/v1/informant/cases", headers={"X-Report-Token": rep["token"]}).json()[0]
    print("informant sees:", st["status"])
    assert st["status"] == "in_review"
    print("SMOKE OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
