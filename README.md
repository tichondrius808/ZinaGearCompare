# ZinaGearCompare

A World of Warcraft addon that compares gear quality between players using **Pawn** stat weights.

## Features

- **Gear score in your character sheet** — displayed at the bottom of the Character frame.
- **Tooltip integration** — shows your gear score when hovering over your own portrait.
- **Inspect panel** — adds a "Gear Quality" section to the Inspect frame showing:
  - The inspected player's weighted gear score.
  - A colour-coded comparison (green ≥ 95%, yellow ≥ 80%, red < 80%) vs. your own gear.
  - The Pawn scale and number of equipped slots used.
  - A custom scale selector to cycle through your Pawn scales.
- **Mouseover tooltips** — automatically inspects players you hover over and displays their score alongside a **Skill Parity** indicator: the percentage of their damage you need to match in order to be equally skilled given the gear difference.
- **`/zgc compare`** — detailed chat printout comparing your gear against a targeted player, with optional **Details!** DPS integration.
- Auto-detection of the best Pawn scale for each class/spec combination (all 13 WoW classes supported).

## Requirements

- **Pawn** addon — ZinaGearCompare reads stat weights from Pawn scales. Without it the addon loads but scores are unavailable.
- WoW Retail 11.0.5+ or Midnight 12.0.1+.

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
| `/zgc scales` | List all available Pawn scales. |
| `/zgc debug` | Print diagnostic information (Pawn detection, spec, scale, etc.). |
| `/zgc reset` | Reset the addon saved data. |

## Skill Parity

The skill parity formula answers: *"What percentage of their damage do I need to deal to be equally skilled, given our gear difference?"*

```
parity% = (1 / gearRatio)² × 100
```

- **< 100%** — they have better gear; you need to outplay them to keep up.
- **= 100%** — equivalent gear; any difference is pure skill.
- **> 100%** — you have better gear; you should naturally out-DPS them.

## Optional: Details! Integration

When both you and your target appear in a recent Details! combat segment, `/zgc compare` will show your actual DPS ratio vs. the gear-predicted ratio, indicating whether you are over- or under-performing relative to the gear difference.

## License

[MIT](LICENSE)
