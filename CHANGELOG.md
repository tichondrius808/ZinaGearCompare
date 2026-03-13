# Changelog

All notable changes to ZinaGearCompare will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.1.0] - 2026-03-13

### Added
- `tools/run_simc_all.bat` — runs SimulationCraft on all available MID1 profiles
  (Patchwerk + DungeonSlice) and outputs JSON scale factors per spec.
- `tools/simc_to_lua.py` — reads SimC JSONs, normalizes scale factors to `primary=1.0`,
  and regenerates `ZinaStatWeights.lua` automatically.

### Changed
- **Stat weights**: 20 specs updated with real SimulationCraft data (MID1 profiles,
  10 000 iterations). Several specs had significantly wrong secondary weights, most
  notably Vers for specs like Feral Druid, Fire Mage, and Outlaw Rogue.
- **SkillParity exponent**: changed from 2.0 to 1.2, giving more realistic parity
  targets (e.g. 20% gear gap → 85.1% required DPS instead of the previous 69.4%).
- **`/zgc compare` output**: condensed from 7 lines to 3–4 lines. Prefix shortened
  from `[ZinaGearCompare]` to `[ZGC]` in this command.

## [2.0.1] - 2026-03-12

### Added
- Independent scoring engine (`Scoring.lua`) — no longer depends on Pawn.
- `ZinaStatWeights.lua` — built-in stat weights for all specs, separated by
  M+ (DungeonSlice) and Raid (Patchwerk) content types.
- `ZinaTierSets.lua` — tier set score bonuses (2pc/4pc multipliers) per spec.
- `ZinaContentDetector.lua` — auto-detects whether the player is in a dungeon or raid.
- Spec name display (replaces Pawn scale name) in all UI elements.

### Fixed
- Taint error on `INSPECT_READY` caused by GUID comparison in combat.

### Removed
- Pawn dependency. The addon now ships its own weights and works standalone.

## [1.0.0] - 2026-03-12

### Added
- Gear quality score display in the Character frame (PaperDoll).
- Tooltip integration using `TooltipDataProcessor` (Dragonflight+ API).
- Inspect frame panel with gear score, comparison percentage, and custom scale selector.
- Mouseover inspection cache with 0.1 s debounce and tooltip score + Skill Parity indicator.
- `/zgc compare` slash command with Details! DPS integration.
- `/zgc score`, `/zgc scales`, `/zgc debug`, `/zgc reset` slash commands.
- Auto-detection of best Pawn scale for all 13 WoW classes and their specializations.
- Compatibility with WoW Retail 11.0.5 and Midnight 12.0.1.
