"""Feed conformance kit for vendors and partners.

    python -m uavr.feeds.conformance sensor-track payload.json [more.json ...]
    python -m uavr.feeds.conformance --all-examples

Exit code 0 when every payload conforms. The same checks run on the live ingestion endpoint.
"""

import argparse
import json
import sys
from pathlib import Path

from ..config import get_settings
from .validate import FEEDS, errors


def check(feed: str, path: Path) -> list[dict]:
    try:
        payload = json.loads(path.read_text())
    except json.JSONDecodeError as e:
        return [{"path": "", "message": f"not valid JSON: {e}"}]
    errs = errors(feed, payload)
    if not errs and payload.get("schema") != f"uavr.feed.{feed}/1":
        errs.append({"path": "/schema", "message": "wrong schema id"})
    return errs


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("feed", nargs="?", choices=FEEDS)
    ap.add_argument("files", nargs="*", type=Path)
    ap.add_argument("--all-examples", action="store_true", help="check the bundled examples")
    a = ap.parse_args(argv)

    jobs: list[tuple[str, Path, bool]] = []
    if a.all_examples:
        ex = get_settings().schema_dir / "v1" / "examples"
        for p in sorted(ex.glob("*.json")):
            feed, kind = p.name.split(".")[0], p.name.split(".")[-2]
            jobs.append((feed, p, kind == "valid"))
    elif a.feed and a.files:
        jobs = [(a.feed, f, True) for f in a.files]
    else:
        ap.error("give a feed and files, or --all-examples")

    failed = 0
    for feed, path, expect_ok in jobs:
        errs = check(feed, path)
        ok = not errs
        good = ok == expect_ok
        failed += not good
        mark = "PASS" if good else "FAIL"
        note = "" if expect_ok else " (expected to be rejected)"
        print(f"{mark}  {feed:13} {path}{note}")
        if not ok and expect_ok:
            for e in errs:
                print(f"      {e['path'] or '/'}: {e['message']}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
