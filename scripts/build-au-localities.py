#!/usr/bin/env python3
"""Builds au_localities.json, the suburb list behind the address form's City picker.

Usage: scripts/build-au-localities.py path/to/australian_postcodes.csv

Takes a CSV in the matthewproctor/australianpostcodes layout (postcode, locality, state, type),
as republished by the Queensland Government at data.qld.gov.au/dataset/locality-lookup.
Keeps delivery areas only (no PO boxes or large-volume receivers) and writes the same file
to the iOS bundle and the Android assets, shaped {"NSW": [["Sydney", "2000"], ...], ...}.
"""
import csv
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUTPUTS = [
    ROOT / "TrinhsGroup/Resources/au_localities.json",
    ROOT / "kmp/androidApp/src/main/assets/au_localities.json",
]
STATES = ["ACT", "NSW", "NT", "QLD", "SA", "TAS", "VIC", "WA"]


def title(name):
    """SOUTH HURSTVILLE -> South Hurstville, MCMAHONS POINT -> McMahons Point, O'CONNOR -> O'Connor."""
    words = name.strip().title()
    return re.sub(r"\bMc([a-z])", lambda m: "Mc" + m.group(1).upper(), words)


def main(path):
    places = {state: set() for state in STATES}
    with open(path, encoding="utf-8-sig", newline="") as f:
        for row in csv.DictReader(f):
            if row["type"] != "Delivery Area" or row["state"] not in places:
                continue
            postcode = row["postcode"].strip().zfill(4)
            places[row["state"]].add((title(row["locality"]), postcode))

    data = {state: sorted(map(list, places[state])) for state in STATES}
    text = json.dumps(data, ensure_ascii=False, separators=(",", ":"))
    for out in OUTPUTS:
        out.write_text(text, encoding="utf-8")
        print(f"{out.relative_to(ROOT)}: {sum(map(len, data.values()))} suburbs, {len(text) // 1024} KB")


if __name__ == "__main__":
    main(sys.argv[1])
