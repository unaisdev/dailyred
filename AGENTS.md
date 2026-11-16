# Notas para agentes

## Obligatorio: Novedades antes de push a main

Este repo **publica un Release en cada push a `main`** (content pack de Daily Red
para Hortelano's Daily). Quien haga el cambio debe rellenar las notas
**automáticamente** al acabar el trabajo, sin esperar a que se lo pidan.

### Checklist

1. Mira qué cambió en esta sesión que el **jugador** note.
2. Escribe bullets en `content/NOVEDADES.md` (solo líneas `- …`).
3. Commit de esos bullets junto al resto del trabajo (o justo antes del push).
4. Push a `main`.

**Público:** un usuario normal. Habla claro, sin jerga de desarrollo.
Nada de tags (`content-v*`), SHA, firmas, CI, nombres de zip técnicos ni docs internas.

Ejemplos buenos:

```text
- Arreglado: el combate se reiniciaba si cerrabas a medias.
- RED pelea un poco distinto con Pikachu.
```

Si no hay nada visible al jugar:

```text
- Sin cambios que notes al jugar.
```

Sin bullets en `content/NOVEDADES.md`, el workflow de Release **falla a propósito**.

## La ROM se compila en local

El workflow no compila: empaqueta `web/game/dailyred.gba.gz`, que se sube al repo.
Para cambiar el juego:

```sh
rm -rf pokefirered && scripts/get-pokefirered.sh   # pret + patches/ + locale/es
scripts/build-rom.sh                                # → web/game/dailyred.gba.gz
scripts/verify-content.sh                           # comprueba ROM, mapa y textos ES
```

`get-pokefirered.sh` normaliza el parche antes de aplicarlo: sin eso, el mapa de
la cima (`data/layouts/DailyRed_Summit/map.bin`) sale vacío y en el juego se ve
con los tiles revueltos. `make` no detecta cambios en los `.bin`; si tocas el
mapa, borra `pokefirered/pokefirered_modern.gba` antes de `build-rom.sh`.
