#!/usr/bin/env bash
# Recreates pokefirered/ from a clean checkout: fetches pret/pokefirered at the
# pinned commit, applies the Daily Red changes from patches/ and the Spanish
# (es-ES) text from locale/es.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GAME="$ROOT/pokefirered"
PATCH="$ROOT/patches/pokefirered-dailyred.patch"
PRET_URL="https://github.com/pret/pokefirered.git"
PRET_COMMIT="037335f4c725d7c9aecdac87066f2002b4bd7e14"

if [ -e "$GAME" ]; then
  echo "pokefirered/ already exists. Delete it first to start from a fresh copy."
  exit 1
fi

git init -q "$GAME"
git -C "$GAME" remote add origin "$PRET_URL"
# Keep LF line endings even on Windows: the build tools reject CRLF.
git -C "$GAME" config core.autocrlf false
echo ">> Fetching pret/pokefirered @ ${PRET_COMMIT:0:10}"
git -C "$GAME" fetch -q --depth 1 origin "$PRET_COMMIT"
git -C "$GAME" checkout -q FETCH_HEAD

echo ">> Applying $(basename "$PATCH")"
# The patch adds binary files (the summit map) as "GIT binary patch" hunks.
# Without explicit ---/+++ headers some git versions create them empty, which
# leaves the summit map scrambled in game. Normalize the patch first.
NORMALIZED_PATCH="$(mktemp)"
trap 'rm -f "$NORMALIZED_PATCH"' EXIT
PYTHON="$(command -v python3 || command -v python)"
tr -d '\r' < "$PATCH" | "$PYTHON" "$ROOT/scripts/normalize-binary-patch.py" > "$NORMALIZED_PATCH"
git -C "$GAME" apply --binary --whitespace=nowarn "$NORMALIZED_PATCH"

# Fail loudly if the summit map still came out wrong.
for f in map.bin:950 border.bin:8; do
  path="$GAME/data/layouts/DailyRed_Summit/${f%%:*}"
  size="$(wc -c < "$path" | tr -d ' ')"
  if [ "$size" != "${f##*:}" ]; then
    echo "ERROR: $path is $size bytes (expected ${f##*:}). The binary patch was not applied." >&2
    exit 1
  fi
done

"$ROOT/scripts/apply-locale.sh"
echo "Done. Build with: scripts/build-rom.sh"
