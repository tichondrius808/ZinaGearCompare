# Changelog

All notable changes to ZinaGearCompare will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
