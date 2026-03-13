# ZinaGearCompare

A World of Warcraft addon that compares gear quality between players using **built-in SimulationCraft-derived stat weights**. No external dependencies required.

## Features

- **Gear score in your character sheet** — displayed at the bottom of the Character frame.
- **Tooltip integration** — shows your gear score when hovering over your own portrait.
- **Inspect panel** — adds a "Gear Quality" section to the Inspect frame showing:
  - The inspected player's weighted gear score.
  - A colour-coded comparison (green ≥ 95%, yellow ≥ 80%, red < 80%) vs. your own gear.
  - The spec name and number of equipped slots scored.
- **Mouseover tooltips** — automatically inspects players you hover over and displays their score alongside a **Skill Parity** indicator: the percentage of their damage you need to match in order to be equally skilled given the gear difference.
- **`/zgc compare`** — condensed chat printout (3–4 lines) comparing your gear against a targeted player, with optional **Details!** DPS integration.
- Supports all 13 WoW classes, separated M+/Raid weights, and Tier Set score bonuses.

## Requirements

- WoW Retail Midnight 12.0.1+.
- No addon dependencies. Pawn is **not** required.

## Installation

### Via CurseForge App (recommended)
Search for **ZinaGearCompare** in the CurseForge App and click Install.

### Manual
1. Download the latest release from CurseForge or [GitHub Releases](../../releases).
2. Extract the `ZinaGearCompare` folder into `<WoW>/_retail_/Interface/AddOns/`.
3. Restart WoW or reload the UI (`/reload`).

## Slash Commands

| Command | Description |
|---|---|
| `/zgc compare` | Compare your gear against the currently selected player (prints to chat). |
| `/zgc score` | Show your current gear score. |
| `/zgc debug` | Print diagnostic information (spec, weights, slots scored, etc.). |
| `/zgc reset` | Reset the addon saved data. |

## Skill Parity

The skill parity formula answers: *"What percentage of their damage do I need to deal to be equally skilled, given our gear difference?"*

```
parity% = (1 / gearRatio)^1.2 × 100
```

- **< 100%** — they have better gear; you need to outperform them proportionally to compensate.
- **= 100%** — equivalent gear; any difference is pure skill.
- **> 100%** — you have better gear; you should naturally out-DPS them.

Example: they have 20% more gear (gearRatio = 1.2) → you need to deal ≥ 85.1% of their damage to be considered equally skilled.

## Optional: Details! Integration

When both you and your target appear in a recent Details! combat segment, `/zgc compare` will show your actual DPS ratio vs. the gear-predicted ratio, indicating whether you are over- or under-performing relative to the gear difference.

## Stat Weights

Weights are stored in `ZinaStatWeights.lua` and sourced from **SimulationCraft** (profiles MID1, Midnight Season 1). 20 specs have real SimC data (Patchwerk for Raid, DungeonSlice for M+). The remaining specs without MID1 profiles use curated estimates based on class Discord guides.

See [`tools/README.md`](tools/README.md) for instructions on regenerating weights after a new patch.

## License

[MIT](LICENSE)
