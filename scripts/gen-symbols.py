#!/usr/bin/env python3
"""Writes web/game/symbols.json: the RAM addresses the launcher's historical
archive reads the generated team from, taken from the ELF of this exact build.

These addresses move whenever the code or the compiler changes, so they ship
inside the content pack next to the ROM (manifest "archive.symbols").
romSha256 ties the file to the ROM it was generated from.

usage: gen-symbols.py <nm> <elf> <rom.gba> <out.json>
"""
import hashlib
import json
import subprocess
import sys

NEEDED = ("gPlayerParty", "gPlayerPartyCount")

nm, elf, rom, out = sys.argv[1:5]
symbols = {}
for line in subprocess.run([nm, elf], capture_output=True, text=True, check=True).stdout.splitlines():
    parts = line.split()
    if len(parts) == 3 and parts[2] in NEEDED:
        symbols[parts[2]] = int(parts[0], 16)

missing = [n for n in NEEDED if n not in symbols]
if missing:
    sys.exit(f"symbols not found in {elf}: {missing}")

data = {name: symbols[name] for name in NEEDED}
with open(rom, "rb") as f:
    data["romSha256"] = hashlib.sha256(f.read()).hexdigest()

with open(out, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
print(f"Wrote {out}: " + ", ".join(f"{n}=0x{symbols[n]:x}" for n in NEEDED))
