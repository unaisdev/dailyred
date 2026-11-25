#!/usr/bin/env python3
"""Translate Daily Red's custom summit messages while preserving its game logic."""
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
replacements = {
    '.string "You defeated RED!$"': '.string "¡Has derrotado a RED!$"',
    '.string "Your team was wiped out…$"': '.string "¡Tu equipo ha caído!$"',
    '.string "Record: {STR_VAR_1} win(s) in\\n"': '.string "Récord de victorias:\\n"',
    '.string "{STR_VAR_2} battle(s).\\p"': '.string "{STR_VAR_1} de {STR_VAR_2}.\\p"',
    '.string "Play again tomorrow!$"': '.string "¡Vuelve mañana!$"',
    '.string "Try again tomorrow.$"': '.string "Vuelve a intentarlo mañana.$"',
    '.string "A new team of six is ready.\\n"': '.string "Ya tienes seis nuevos Pokémon.\\n"',
    '.string "Climb back up and face RED!$"': '.string "¡Sube de nuevo y reta a RED!$"',
    '.string "You got a Champion\'s License!$"': '.string "Has obtenido una\\n"\n    .string "Licencia de Campeón.$"',
}

for source, target in replacements.items():
    count = text.count(source)
    expected = 3 if source.startswith('.string "Record:') or source.startswith('.string "{STR_VAR_2}') else 1
    if count == expected:
        text = text.replace(source, target)
    elif count == 0 and text.count(target) == expected:
        continue
    else:
        raise SystemExit(f"Expected {expected} source or translated strings for {source!r}; found {count}")

path.write_text(text, encoding="utf-8", newline="")
print(f"Translated Daily Red summit text in {path}")
