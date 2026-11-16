#!/usr/bin/env bash
# Verifica el content pack de Daily Red (manifest + ROM + magics + idioma).
# Uso: scripts/verify-content.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST="$ROOT/content/game.manifest.json"

if [[ ! -f "$MANIFEST" ]]; then
  echo "Missing manifest: $MANIFEST" >&2
  exit 1
fi

python3 - "$MANIFEST" "$ROOT" <<'PY'
import gzip, json, sys
from pathlib import Path

manifest_path = Path(sys.argv[1])
root = Path(sys.argv[2])
m = json.loads(manifest_path.read_text())

required = ["id", "name", "contentVersion", "protocolId", "rom", "compat"]
missing = [k for k in required if k not in m]
if missing:
    raise SystemExit(f"manifest missing keys: {missing}")

if m["id"] != "dailyred":
    raise SystemExit(f'expected id "dailyred", got {m["id"]!r}')

rom_rel = m["rom"]["path"]
magic = m["rom"]["configMagic"].encode()
# Staging layout used by package-content.sh, or the build output.
candidates = [
    root / "dist" / "content" / "staging" / rom_rel,
    root / "web" / "game" / Path(rom_rel).name,
]
rom = next((p for p in candidates if p.is_file()), None)
if rom is None:
    raise SystemExit(f"ROM not found (looked for {Path(rom_rel).name} under web/game/)")

raw = rom.read_bytes()
if raw[:2] == b"\x1f\x8b":
    raw = gzip.decompress(raw)
if len(raw) != 16 * 1024 * 1024:
    raise SystemExit(f"unexpected ROM size {len(raw)} (expected 16 MiB)")
if magic not in raw:
    raise SystemExit(f"config magic {magic!r} not found in {rom}")
print(f"OK id={m['id']} version={m['contentVersion']} protocol={m['protocolId']}")
print(f"OK config magic {magic.decode()} in {rom.relative_to(root)}")

# The summit map must be the real one (an empty map.bin scrambles it in game).
summit = root / "pokefirered" / "data" / "layouts" / "DailyRed_Summit" / "map.bin"
if summit.is_file():
    data = summit.read_bytes()
    if len(data) != 950 or data not in raw:
        raise SystemExit("summit map.bin missing from the ROM (rebuild with scripts/get-pokefirered.sh)")
    print("OK summit map inside ROM")

# Spanish text check: "DESTRUCTOR" (Pound) in the game's charmap.
# A-Z are 0xBB..0xD4 in the FireRed charmap.
def enc(s):
    return bytes(0xBB + ord(c) - ord("A") for c in s)
if enc("DESTRUCTOR") not in raw:
    raise SystemExit("Spanish move names not found in the ROM (is locale/es applied?)")
print("OK Spanish text present")
print(f"OK minLauncherVersion={m['compat']['minLauncherVersion']}")
PY
