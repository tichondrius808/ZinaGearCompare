# tools — ZinaGearCompare stat weight pipeline

Scripts para regenerar `ZinaStatWeights.lua` con datos reales de SimulationCraft.
Hay que ejecutarlos **una vez por temporada** (o tras un parche importante que cambie
mecánicas de clase).

## Requisitos

- [SimulationCraft nightly](https://simulationcraft.org/download.html) para Windows
  (descomprimir con 7-Zip).
- Python 3.8+ (`py` o `python3`).

## Flujo completo

### 1. Edita la ruta de SimC en `run_simc_all.bat`

Abre el fichero y ajusta las dos primeras variables:

```bat
set SIMC_DIR=C:\ruta\a\simc-XXXX-win64
set PROFILES_DIR=%SIMC_DIR%\profiles\MID1
```

### 2. Corre las simulaciones

Ejecuta desde cualquier terminal (cmd o PowerShell):

```bat
tools\run_simc_all.bat
```

Esto lanza SimC en los **20 perfiles base de MID1** con dos fight styles cada uno:
- `Patchwerk` → pesos para Raid (single target)
- `DungeonSlice` → pesos para M+ (AoE mixto)

Los JSONs de salida se guardan en `tools\simc_output\`.
Con 10 000 iteraciones tarda ~3 minutos en total.

### 3. Genera el Lua

```bat
py tools\simc_to_lua.py
```

Lee todos los JSONs, normaliza los scale factors a `primary = 1.0`, y
sobreescribe `ZinaStatWeights.lua` con los datos actualizados.

Las specs **sin perfil MID1** (indicadas con `estimado` en el comentario)
se mantienen con los valores manuales definidos en `simc_to_lua.py`.

## Specs cubiertas por MID1 (datos SimC reales)

| specID | Spec |
|--------|------|
| 250 | Death Knight — Blood |
| 251 | Death Knight — Frost |
| 252 | Death Knight — Unholy |
| 581 | Demon Hunter — Vengeance |
| 1480 | Demon Hunter — Devourer |
| 103 | Druid — Feral |
| 1467 | Evoker — Devastation |
| 62 | Mage — Arcane |
| 63 | Mage — Fire |
| 64 | Mage — Frost |
| 268 | Monk — Brewmaster |
| 269 | Monk — Windwalker |
| 258 | Priest — Shadow |
| 260 | Rogue — Outlaw |
| 261 | Rogue — Subtlety |
| 262 | Shaman — Elemental |
| 263 | Shaman — Enhancement |
| 265 | Warlock — Affliction |
| 267 | Warlock — Destruction |
| 73 | Warrior — Protection |

## Specs sin perfil MID1 (estimadas)

Havoc DH, Balance/Guardian/Resto Druid, Preservation/Augmentation Evoker,
todos los Hunters, Mistweaver Monk, todos los Paladins, Disc/Holy Priest,
Assassination Rogue, Restoration Shaman, Demonology Warlock, Arms/Fury Warrior.

Cuando SimC añada perfiles MID1 para estas specs, agrégalos al dict `SPEC_MAP`
en `simc_to_lua.py` y quítalos de `MANUAL_SPECS`.

## Nota sobre DH DungeonSlice

Los perfiles de Demon Hunter tienen DungeonSlice desactivado por defecto en SimC
(APL incompleta para ese modo). El script `run_simc_all.bat` fuerza
`enable_dungeon_slice=1` para estos dos perfiles. Los resultados son válidos
pero con mayor margen de error estadístico que otras specs.
