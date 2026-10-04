"""Staff accounts from the command line (first admin, emergencies).

    python -m uavr.users create admin --roles admin --agency NPA --clearance 2
    python -m uavr.users create tpe.dispatcher --roles dispatcher --desk TCPD-DISPATCH --clearance 1
    python -m uavr.users passwd admin
    python -m uavr.users list
Passwords are read interactively (or from UAVR_NEW_PASSWORD for scripted setups).
"""

import argparse
import asyncio
import getpass
import os
import sys
import uuid

from sqlalchemy import select, update

from .db.models import Agency, AppUser, Desk, StaffSession
from .db.session import dispose, sessionmaker
from .security.passwords import hash_password, policy_error
from .security.principal import STAFF_ROLES


def _password(username: str) -> str:
    pw = os.environ.get("UAVR_NEW_PASSWORD") or getpass.getpass(f"Password for {username}: ")
    if not os.environ.get("UAVR_NEW_PASSWORD") and pw != getpass.getpass("Repeat: "):
        sys.exit("passwords differ")
    if err := policy_error(pw, username):
        sys.exit(err)
    return pw


async def main(a) -> None:
    async with sessionmaker()() as s:
        if a.cmd == "list":
            for u in (await s.execute(select(AppUser).order_by(AppUser.username))).scalars():
                print(
                    f"{u.username:24} {'active' if u.active else 'DISABLED':8} roles={','.join(u.roles or [])} "
                    f"agency={u.agency_id} desk={u.desk_id} clearance={u.clearance} field_unit={u.field_unit}"
                )
            return
        u = (await s.execute(select(AppUser).where(AppUser.username == a.username))).scalar_one_or_none()
        if a.cmd == "passwd":
            if u is None:
                sys.exit("no such user")
            u.password_hash = hash_password(_password(a.username))
            u.failed_logins, u.locked_until = 0, None
            await s.execute(update(StaffSession).where(StaffSession.user_id == u.id).values(revoked=True))
            await s.commit()
            print("password changed; existing sessions signed out")
            return
        if u is not None:
            sys.exit("user exists")
        roles = [r.strip() for r in a.roles.split(",") if r.strip()]
        if bad := [r for r in roles if r not in STAFF_ROLES]:
            sys.exit(f"unknown roles {bad}; choose from {sorted(STAFF_ROLES)}")
        desk = (
            (await s.execute(select(Desk).where(Desk.code == a.desk))).unique().scalar_one_or_none() if a.desk else None
        )
        agency = (
            (await s.execute(select(Agency).where(Agency.code == a.agency))).scalar_one_or_none() if a.agency else None
        )
        if a.desk and desk is None or a.agency and agency is None:
            sys.exit("unknown agency/desk code")
        s.add(
            AppUser(
                id=uuid.uuid4(),
                username=a.username,
                display_name=a.name or a.username,
                password_hash=hash_password(_password(a.username)),
                roles=roles,
                clearance=a.clearance,
                field_unit=a.field_unit,
                desk_id=desk.id if desk else None,
                agency_id=desk.agency_id if desk else (agency.id if agency else None),
                active=True,
            )
        )
        await s.commit()
        print(f"created {a.username}")
    await dispose()


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    c = sub.add_parser("create")
    c.add_argument("username")
    c.add_argument("--name")
    c.add_argument("--roles", required=True, help="comma-separated: " + ",".join(sorted(STAFF_ROLES)))
    c.add_argument("--agency", help="agency code, e.g. NPA")
    c.add_argument("--desk", help="desk code, e.g. TCPD-DISPATCH (sets the agency too)")
    c.add_argument("--clearance", type=int, default=0, choices=[0, 1, 2])
    c.add_argument("--field-unit", action="store_true")
    p = sub.add_parser("passwd")
    p.add_argument("username")
    sub.add_parser("list")
    asyncio.run(main(ap.parse_args()))
