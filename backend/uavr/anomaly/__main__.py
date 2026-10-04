"""Maritime anomaly engine from the command line.

python -m uavr.anomaly run [--source atreides]   detect now and update alerts
python -m uavr.anomaly simulate [--seed 7]       replace the labelled simulated traffic, detect, evaluate
python -m uavr.anomaly evaluate                  rules vs statistical baseline on the simulated labels
"""

import argparse
import asyncio
import json

from ..db.session import dispose, sessionmaker
from . import engine
from .simulate import simulate


def _print_eval(ev) -> None:
    if ev is None:
        print("no labelled tracks (run simulate first)")
        return
    print(f"evaluation #{ev.id}: {ev.tracks} tracks, {ev.anomalous} anomalous")
    for m, r in ev.results.items():
        print(
            f"  {m:12} precision {r['precision']:.2f}  recall {r['recall']:.2f}  F1 {r['f1']:.2f}  "
            f"false alarms/100 normal {r['false_alarms_per_100_normal']}"
        )
        print("               " + json.dumps(r["by_kind"]))


async def main(a: argparse.Namespace) -> None:
    try:
        async with sessionmaker()() as s:
            if a.cmd == "simulate":
                print(await simulate(s, a.seed))
                await s.commit()
                print(await engine.run(s, "sim"))
                await s.commit()
                _print_eval(await engine.evaluate(s))
                await s.commit()
            elif a.cmd == "run":
                print(await engine.run(s, a.source))
                await s.commit()
            elif a.cmd == "evaluate":
                _print_eval(await engine.evaluate(s))
                await s.commit()
    finally:
        await dispose()


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    r = sub.add_parser("run")
    r.add_argument("--source")
    sm = sub.add_parser("simulate")
    sm.add_argument("--seed", type=int, default=7)
    sub.add_parser("evaluate")
    asyncio.run(main(ap.parse_args()))
