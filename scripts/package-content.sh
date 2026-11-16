#!/usr/bin/env bash
# Empaqueta el content pack para Hortelano's Daily / GitHub Releases.
#
# Salida (dist/content/):
#   dailyred-content.zip               ← nombre que espera el catálogo del launcher
#   dailyred-content-vX.Y.Z.zip        ← copia versionada
#   SHA256SUMS                         ← checksums (nombres de asset de Release)
#
# El zip lleva en la raíz: game.manifest.json, rom/dailyred.gba.gz, assets/,
# archive/symbols.json (direcciones de RAM para el archivo histórico).
# Uso: scripts/package-content.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST="$ROOT/content/game.manifest.json"
ROM_SRC="$ROOT/web/game/dailyred.gba.gz"
ASSETS_SRC="$ROOT/content/assets"
SYMBOLS_SRC="$ROOT/web/game/symbols.json"
OUT_DIR="$ROOT/dist/content"
STAGING="$OUT_DIR/staging"

if [[ ! -f "$ROM_SRC" ]]; then
  echo "Missing ROM $ROM_SRC — run scripts/build-rom.sh first." >&2
  exit 1
fi
if [[ ! -f "$SYMBOLS_SRC" ]]; then
  echo "Missing $SYMBOLS_SRC — run scripts/build-rom.sh first." >&2
  exit 1
fi
if [[ ! -f "$ASSETS_SRC/red.png" ]]; then
  echo "Missing $ASSETS_SRC/red.png (title asset in the manifest)." >&2
  exit 1
fi

"$ROOT/scripts/verify-content.sh"

ID=$(python3 -c "import json; print(json.load(open('$MANIFEST'))['id'])")
VER=$(python3 -c "import json; print(json.load(open('$MANIFEST'))['contentVersion'])")

rm -rf "$STAGING"
mkdir -p "$STAGING/rom" "$STAGING/assets" "$STAGING/archive"
cp "$MANIFEST" "$STAGING/game.manifest.json"
cp "$ROM_SRC" "$STAGING/rom/dailyred.gba.gz"
cp "$ASSETS_SRC"/* "$STAGING/assets/"
cp "$SYMBOLS_SRC" "$STAGING/archive/symbols.json"

# Re-verify against the staged copy.
python3 - "$STAGING/rom/dailyred.gba.gz" <<'PY'
import gzip, sys
from pathlib import Path
raw = Path(sys.argv[1]).read_bytes()
if raw[:2] == b'\x1f\x8b':
    raw = gzip.decompress(raw)
assert b'DAILYRED-CONF-V2' in raw, 'config magic missing in staged ROM'
print('OK staged ROM')
PY

UPLOAD_ZIP="$OUT_DIR/${ID}-content.zip"
VERSIONED_ZIP="$OUT_DIR/${ID}-content-v${VER}.zip"
rm -f "$UPLOAD_ZIP" "$VERSIONED_ZIP" "$OUT_DIR/SHA256SUMS"

# Python's zipfile instead of `zip`, so it also works where zip isn't installed.
python3 - "$STAGING" "$UPLOAD_ZIP" <<'PY'
import sys, zipfile
from pathlib import Path
root, out = Path(sys.argv[1]), sys.argv[2]
with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as z:
    for p in sorted(root.rglob('*')):
        if p.is_file() and p.name != '.DS_Store':
            z.write(p, p.relative_to(root).as_posix())
PY
cp "$UPLOAD_ZIP" "$VERSIONED_ZIP"

(
  cd "$OUT_DIR"
  sha256sum "$(basename "$UPLOAD_ZIP")" "$(basename "$VERSIONED_ZIP")" > SHA256SUMS
)

echo "Wrote $UPLOAD_ZIP"
echo "Wrote $VERSIONED_ZIP"
cat "$OUT_DIR/SHA256SUMS"
