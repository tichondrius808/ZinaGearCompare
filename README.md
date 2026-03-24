# ZinaGearCompare

A World of Warcraft addon that compares gear quality between players using **built-in SimulationCraft-derived stat weights** and integrates **Raidbots Top Gear** sim data directly into item tooltips.

## Features

- **Raidbots Top Gear integration** — import your sim results and see per-item DPS deltas in item tooltips (both ST and AoE). BIS items glow green in your bags.
- **Sim Performance panel** — small floating panel showing your actual DPS vs sim DPS as a percentage bar. Uses Blizzard's native Damage Meter (12.0+) or Details! as fallback. Navigate between combat segments with `<` `>` buttons.
- **Gear score in your character sheet** — displayed at the bottom of the Character frame.
- **Inspect panel** — adds a "Gear Quality" section to the Inspect frame with colour-coded comparison.
- **Mouseover tooltips** — inspects players on hover, shows ilvl comparison and **Skill Parity** indicator.
- **`/zgc compare`** — chat comparison with optional Details!/native meter DPS integration.
- Supports all 13 WoW classes, separated M+/Raid weights, and Tier Set score bonuses.

## Requirements

- WoW Retail Midnight 12.0.1+.
- No addon dependencies. Pawn is **not** required.
- **Python 3.8+** required only for the Raidbots import tool (one-time setup).

## Installation

### Sharing with a friend (zip)

1. Extract the `ZinaGearCompare` folder into `<WoW>/_retail_/Interface/AddOns/`.
2. `/reload` in game — the addon works immediately (gear scores, tooltips, etc.).
3. To enable Raidbots data in tooltips, see **Importing Your Sim Data** below.

### Manual (from GitHub)

1. Download the latest release from [GitHub Releases](../../releases).
2. Extract into `<WoW>/_retail_/Interface/AddOns/`.
3. Restart WoW or `/reload`.

## Importing Your Sim Data

This is what gives you per-item DPS deltas in tooltips and the Sim Performance panel.

1. Run your **Top Gear** sim on [raidbots.com](https://www.raidbots.com).
2. Copy the report URL (e.g. `https://www.raidbots.com/simbot/report/abc123`).
3. Double-click `tools\raidbots_import.bat` inside the addon folder.
4. Paste the URL when prompted — the script auto-detects ST vs AoE.
5. `/reload` in game.

Repeat for both ST and AoE if you want both lines in tooltips:
- Run a **Patchwerk** sim → imports as ST (Raid).
- Run a **DungeonSlice** sim → imports as AoE (M+).

> **Note:** Python 3.8+ must be installed and available as `py` in your PATH.
> Download from [python.org](https://www.python.org/downloads/) — check "Add to PATH" during install.

## Slash Commands

| Command | Description |
|---|---|
| `/zgc sim` | Toggle the Sim Performance panel (actual DPS vs sim DPS). |
| `/zgc compare` | Compare your gear against your target (prints to chat). |
| `/zgc score` | Show your current gear score. |
| `/zgc mode auto\|dungeon\|raid` | Force content mode or auto-detect. |
| `/zgc raidbots` | Show Raidbots import status. |
| `/zgc config` | Open settings panel. |
| `/zgc simdiag` | Diagnostic for Sim Performance panel. |
| `/zgc debug` | Full diagnostic (spec, weights, slots). |
| `/zgc reset` | Reset the addon saved data. |

## Skill Parity

The skill parity formula answers: *"What percentage of their damage do I need to deal to be equally skilled, given our gear difference?"*

```
parity% = (1 / gearRatio)^1.2 × 100
```

- **< 100%** — they have better gear; you need to outperform proportionally.
- **= 100%** — equivalent gear; any difference is pure skill.
- **> 100%** — you have better gear; you should naturally out-DPS them.

## Stat Weights

Weights in `ZinaStatWeights.lua` are sourced from **SimulationCraft** (MID1 profiles, Midnight Season 1). 20+ specs have real SimC data. The rest use curated estimates.

## License

[MIT](LICENSE)
