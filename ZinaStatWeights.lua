-- ZinaStatWeights.lua — ZinaGearCompare
-- Pesos de stats por spec (specID global) y tipo de contenido.
-- primary=1.0 es la referencia; los secondaries son fracciones relativas.
--
-- Generado automáticamente por tools/simc_to_lua.py — 2026-03-23
-- Fuente: SimulationCraft nightly, perfiles MID1 (Midnight 12.0.1), gear_ilevel=240
-- Fight styles: Patchwerk (raid) · DungeonSlice (dungeon/M+)
-- Specs sin perfil MID1 marcadas como 'estimado'.
--
-- Para actualizar: corre tools/run_simc_all.bat y luego tools/simc_to_lua.py

ZGC_StatWeights = {

    -- ── Death Knight ────────────────────────────────────────────────
    [250] = { -- Blood (Tank) — Haste > Vers > Crit > Mastery | SimC MID1 · 2026-03-23
        primaryStat  = "ITEM_MOD_STRENGTH_SHORT",
        source       = "SimC MID1",
        dungeon      = { primary=1.00, crit=0.496, haste=0.594, mastery=0.472, versatility=0.516 },
        raid         = { primary=1.00, crit=0.537, haste=0.455, mastery=0.503, versatility=0.502 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.1,
    },
    [251] = { -- Frost — Mastery > Crit > Haste > Vers | SimC MID1 · 2026-03-23
        primaryStat  = "ITEM_MOD_STRENGTH_SHORT",
        source       = "SimC MID1",
        dungeon      = { primary=1.00, crit=0.514, haste=0.421, mastery=0.539, versatility=0.400 },
        raid         = { primary=1.00, crit=0.479, haste=0.404, mastery=0.503, versatility=0.350 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [252] = { -- Unholy — Crit > Haste > Mastery > Vers | SimC MID1 · 2026-03-23
        primaryStat  = "ITEM_MOD_STRENGTH_SHORT",
        source       = "SimC MID1",
        dungeon      = { primary=1.00, crit=0.580, haste=0.575, mastery=0.489, versatility=0.389 },
        raid         = { primary=1.00, crit=0.608, haste=0.477, mastery=0.474, versatility=0.355 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },

    -- ── Demon Hunter ────────────────────────────────────────────────
    [577] = { -- Havoc — Mastery > Crit > Vers > Haste | SimC MID1 · 2026-03-23
        primaryStat  = "ITEM_MOD_AGILITY_SHORT",
        source       = "SimC MID1",
        dungeon      = { primary=1.00, crit=0.526, haste=0.157, mastery=0.531, versatility=0.359 },
        raid         = { primary=1.00, crit=0.488, haste=0.305, mastery=0.487, versatility=0.328 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [581] = { -- Vengeance (Tank) — Crit > Mastery > Vers > Haste | SimC MID1 · 2026-03-23
        primaryStat  = "ITEM_MOD_AGILITY_SHORT",
        source       = "SimC MID1",
        dungeon      = { primary=1.00, crit=0.485, haste=0.343, mastery=0.479, versatility=0.452 },
        raid         = { primary=1.00, crit=0.491, haste=0.465, mastery=0.428, versatility=0.456 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.1,
    },
    [1480] = { -- Devourer — Haste > Mastery > Crit > Vers | SimC MID1 · 2026-03-23
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        source       = "SimC MID1",
        dungeon      = { primary=1.00, crit=0.507, haste=0.807, mastery=0.688, versatility=0.464 },
        raid         = { primary=1.00, crit=0.546, haste=0.720, mastery=0.581, versatility=0.365 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },

    -- ── Druid ───────────────────────────────────────────────────────
    [102] = { -- Balance — Haste > Mastery > Crit > Vers | estimado — sin perfil MID1
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        source       = "Estimated",
        dungeon      = { primary=1.00, crit=0.440, haste=0.520, mastery=0.500, versatility=0.260 },
        raid         = { primary=1.00, crit=0.440, haste=0.420, mastery=0.580, versatility=0.260 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [103] = { -- Feral — Haste > Vers > Mastery > Crit | SimC MID1 · 2026-03-23
        primaryStat  = "ITEM_MOD_AGILITY_SHORT",
        source       = "SimC MID1",
        dungeon      = { primary=1.00, crit=0.477, haste=0.555, mastery=0.487, versatility=0.504 },
        raid         = { primary=1.00, crit=0.476, haste=0.478, mastery=0.459, versatility=0.484 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [104] = { -- Guardian (Tank) — Haste > Vers > Crit > Mastery | estimado — sin perfil MID1
        primaryStat  = "ITEM_MOD_AGILITY_SHORT",
        source       = "Estimated",
        dungeon      = { primary=1.00, crit=0.400, haste=0.520, mastery=0.300, versatility=0.440 },
        raid         = { primary=1.00, crit=0.400, haste=0.430, mastery=0.380, versatility=0.440 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [105] = { -- Restoration (Healer) — Haste > Mastery > Vers > Crit | estimado — sin perfil MID1
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        source       = "Estimated",
        dungeon      = { primary=1.00, crit=0.200, haste=0.960, mastery=0.660, versatility=0.480 },
        raid         = { primary=1.00, crit=0.200, haste=0.820, mastery=0.740, versatility=0.480 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.1,
    },

    -- ── Evoker ──────────────────────────────────────────────────────
    [1467] = { -- Devastation — Crit > Vers > Haste > Mastery | SimC MID1 · 2026-03-23
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        source       = "SimC MID1",
        dungeon      = { primary=1.00, crit=0.569, haste=0.441, mastery=0.403, versatility=0.450 },
        raid         = { primary=1.00, crit=0.566, haste=0.415, mastery=0.393, versatility=0.424 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [1468] = { -- Preservation (Healer) — Mastery > Haste > Crit > Vers | estimado — sin perfil MID1
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        source       = "Estimated",
        dungeon      = { primary=1.00, crit=0.380, haste=0.600, mastery=0.740, versatility=0.280 },
        raid         = { primary=1.00, crit=0.380, haste=0.480, mastery=0.820, versatility=0.280 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.1,
    },
    [1473] = { -- Augmentation (Support) — Haste > Mastery > Crit > Vers | estimado — sin perfil MID1
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        source       = "Estimated",
        dungeon      = { primary=1.00, crit=0.380, haste=0.560, mastery=0.420, versatility=0.320 },
        raid         = { primary=1.00, crit=0.360, haste=0.460, mastery=0.500, versatility=0.300 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },

    -- ── Hunter ──────────────────────────────────────────────────────
    [253] = { -- Beast Mastery — Mastery > Haste > Crit > Vers | SimC MID1 · 2026-03-23
        primaryStat  = "ITEM_MOD_AGILITY_SHORT",
        source       = "SimC MID1",
        dungeon      = { primary=1.00, crit=0.479, haste=0.490, mastery=0.507, versatility=0.472 },
        raid         = { primary=1.00, crit=0.495, haste=0.452, mastery=0.477, versatility=0.489 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [254] = { -- Marksmanship — Vers > Mastery > Crit > Haste | SimC MID1 · 2026-03-23
        primaryStat  = "ITEM_MOD_AGILITY_SHORT",
        source       = "SimC MID1",
        dungeon      = { primary=1.00, crit=0.441, haste=0.319, mastery=0.475, versatility=0.487 },
        raid         = { primary=1.00, crit=0.497, haste=0.429, mastery=0.522, versatility=0.489 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [255] = { -- Survival — Mastery > Crit > Haste > Vers | SimC MID1 · 2026-03-23
        primaryStat  = "ITEM_MOD_AGILITY_SHORT",
        source       = "SimC MID1",
        dungeon      = { primary=1.00, crit=0.543, haste=0.526, mastery=0.620, versatility=0.516 },
        raid         = { primary=1.00, crit=0.540, haste=0.542, mastery=0.579, versatility=0.493 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },

    -- ── Mage ────────────────────────────────────────────────────────
    [62] = { -- Arcane — Mastery > Vers > Crit > Haste | SimC MID1 · 2026-03-23
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        source       = "SimC MID1",
        dungeon      = { primary=1.00, crit=0.385, haste=-0.032, mastery=0.431, versatility=0.424 },
        raid         = { primary=1.00, crit=0.473, haste=0.351, mastery=0.416, versatility=0.445 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [63] = { -- Fire — Mastery > Vers > Haste > Crit | SimC MID1 · 2026-03-23
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        source       = "SimC MID1",
        dungeon      = { primary=1.00, crit=0.199, haste=0.481, mastery=0.522, versatility=0.496 },
        raid         = { primary=1.00, crit=0.208, haste=0.529, mastery=0.433, versatility=0.488 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [64] = { -- Frost — Mastery > Crit > Haste > Vers | SimC MID1 · 2026-03-23
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        source       = "SimC MID1",
        dungeon      = { primary=1.00, crit=0.490, haste=0.425, mastery=0.539, versatility=0.359 },
        raid         = { primary=1.00, crit=0.495, haste=0.425, mastery=0.497, versatility=0.352 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },

    -- ── Monk ────────────────────────────────────────────────────────
    [268] = { -- Brewmaster (Tank) — Crit > Vers > Mastery > Haste | SimC MID1 · 2026-03-23
        primaryStat  = "ITEM_MOD_AGILITY_SHORT",
        source       = "SimC MID1",
        dungeon      = { primary=1.00, crit=0.507, haste=0.104, mastery=0.453, versatility=0.501 },
        raid         = { primary=1.00, crit=0.481, haste=0.082, mastery=0.453, versatility=0.460 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.1,
    },
    [269] = { -- Windwalker — Crit > Haste > Mastery > Vers | SimC MID1 · 2026-03-23
        primaryStat  = "ITEM_MOD_AGILITY_SHORT",
        source       = "SimC MID1",
        dungeon      = { primary=1.00, crit=0.657, haste=0.640, mastery=0.509, versatility=0.355 },
        raid         = { primary=1.00, crit=0.535, haste=0.477, mastery=0.484, versatility=0.329 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [270] = { -- Mistweaver (Healer) — Haste > Vers > Crit > Mastery | estimado — sin perfil MID1
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        source       = "Estimated",
        dungeon      = { primary=1.00, crit=0.440, haste=0.640, mastery=0.220, versatility=0.480 },
        raid         = { primary=1.00, crit=0.480, haste=0.520, mastery=0.300, versatility=0.400 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.1,
    },

    -- ── Paladin ─────────────────────────────────────────────────────
    [65] = { -- Holy (Healer) — Haste > Mastery > Crit > Vers | estimado — sin perfil MID1
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        source       = "Estimated",
        dungeon      = { primary=1.00, crit=0.450, haste=0.500, mastery=0.500, versatility=0.300 },
        raid         = { primary=1.00, crit=0.450, haste=0.400, mastery=0.580, versatility=0.300 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.1,
    },
    [66] = { -- Protection (Tank) — Vers > Mastery > Crit > Haste | SimC MID1 · 2026-03-23
        primaryStat  = "ITEM_MOD_STRENGTH_SHORT",
        source       = "SimC MID1",
        dungeon      = { primary=1.00, crit=0.449, haste=0.362, mastery=0.492, versatility=0.559 },
        raid         = { primary=1.00, crit=0.505, haste=0.406, mastery=0.462, versatility=0.529 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.1,
    },
    [70] = { -- Retribution — Crit > Mastery > Vers > Haste | SimC MID1 · 2026-03-23
        primaryStat  = "ITEM_MOD_STRENGTH_SHORT",
        source       = "SimC MID1",
        dungeon      = { primary=1.00, crit=0.576, haste=0.324, mastery=0.553, versatility=0.533 },
        raid         = { primary=1.00, crit=0.562, haste=0.465, mastery=0.518, versatility=0.509 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },

    -- ── Priest ──────────────────────────────────────────────────────
    [256] = { -- Discipline (Healer) — Haste > Crit > Vers > Mastery | estimado — sin perfil MID1
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        source       = "Estimated",
        dungeon      = { primary=1.00, crit=0.480, haste=0.620, mastery=0.240, versatility=0.360 },
        raid         = { primary=1.00, crit=0.480, haste=0.500, mastery=0.360, versatility=0.280 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.1,
    },
    [257] = { -- Holy (Healer) — Vers > Crit > Haste > Mastery | estimado — sin perfil MID1
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        source       = "Estimated",
        dungeon      = { primary=1.00, crit=0.500, haste=0.400, mastery=0.220, versatility=0.560 },
        raid         = { primary=1.00, crit=0.560, haste=0.300, mastery=0.360, versatility=0.460 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.1,
    },
    [258] = { -- Shadow — Mastery > Crit > Vers > Haste | SimC MID1 · 2026-03-23
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        source       = "SimC MID1",
        dungeon      = { primary=1.00, crit=0.545, haste=0.474, mastery=0.552, versatility=0.498 },
        raid         = { primary=1.00, crit=0.552, haste=0.471, mastery=0.575, versatility=0.498 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },

    -- ── Rogue ───────────────────────────────────────────────────────
    [259] = { -- Assassination — Crit > Haste > Mastery > Vers | estimado — sin perfil MID1
        primaryStat  = "ITEM_MOD_AGILITY_SHORT",
        source       = "Estimated",
        dungeon      = { primary=1.00, crit=0.550, haste=0.510, mastery=0.300, versatility=0.220 },
        raid         = { primary=1.00, crit=0.550, haste=0.420, mastery=0.380, versatility=0.220 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [260] = { -- Outlaw — Crit > Vers > Haste > Mastery | SimC MID1 · 2026-03-23
        primaryStat  = "ITEM_MOD_AGILITY_SHORT",
        source       = "SimC MID1",
        dungeon      = { primary=1.00, crit=0.464, haste=0.343, mastery=0.332, versatility=0.453 },
        raid         = { primary=1.00, crit=0.459, haste=0.381, mastery=0.286, versatility=0.447 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [261] = { -- Subtlety — Haste > Mastery > Vers > Crit | SimC MID1 · 2026-03-23
        primaryStat  = "ITEM_MOD_AGILITY_SHORT",
        source       = "SimC MID1",
        dungeon      = { primary=1.00, crit=0.431, haste=0.544, mastery=0.468, versatility=0.467 },
        raid         = { primary=1.00, crit=0.424, haste=0.384, mastery=0.432, versatility=0.484 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },

    -- ── Shaman ──────────────────────────────────────────────────────
    [262] = { -- Elemental — Haste > Crit > Mastery > Vers | SimC MID1 · 2026-03-23
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        source       = "SimC MID1",
        dungeon      = { primary=1.00, crit=0.617, haste=0.622, mastery=0.558, versatility=0.494 },
        raid         = { primary=1.00, crit=0.549, haste=0.456, mastery=0.529, versatility=0.451 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [263] = { -- Enhancement — Haste > Mastery > Crit > Vers | SimC MID1 · 2026-03-23
        primaryStat  = "ITEM_MOD_AGILITY_SHORT",
        source       = "SimC MID1",
        dungeon      = { primary=1.00, crit=0.525, haste=0.566, mastery=0.561, versatility=0.508 },
        raid         = { primary=1.00, crit=0.528, haste=0.567, mastery=0.474, versatility=0.493 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [264] = { -- Restoration (Healer) — Crit > Haste > Vers > Mastery | estimado — sin perfil MID1
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        source       = "Estimated",
        dungeon      = { primary=1.00, crit=0.620, haste=0.420, mastery=0.340, versatility=0.380 },
        raid         = { primary=1.00, crit=0.620, haste=0.340, mastery=0.420, versatility=0.380 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.1,
    },

    -- ── Warlock ─────────────────────────────────────────────────────
    [265] = { -- Affliction — Crit > Haste > Vers > Mastery | SimC MID1 · 2026-03-23
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        source       = "SimC MID1",
        dungeon      = { primary=1.00, crit=0.500, haste=0.487, mastery=0.294, versatility=0.486 },
        raid         = { primary=1.00, crit=0.518, haste=0.466, mastery=0.338, versatility=0.482 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [266] = { -- Demonology — Crit > Vers > Mastery > Haste | SimC MID1 · 2026-03-23
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        source       = "SimC MID1",
        dungeon      = { primary=1.00, crit=0.555, haste=0.487, mastery=0.489, versatility=0.508 },
        raid         = { primary=1.00, crit=0.569, haste=0.321, mastery=0.504, versatility=0.488 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [267] = { -- Destruction — Haste > Crit > Mastery > Vers | SimC MID1 · 2026-03-23
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        source       = "SimC MID1",
        dungeon      = { primary=1.00, crit=0.558, haste=0.590, mastery=0.503, versatility=0.479 },
        raid         = { primary=1.00, crit=0.543, haste=0.532, mastery=0.535, versatility=0.482 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },

    -- ── Warrior ─────────────────────────────────────────────────────
    [71] = { -- Arms — Mastery > Haste > Crit > Vers | SimC MID1 · 2026-03-23
        primaryStat  = "ITEM_MOD_STRENGTH_SHORT",
        source       = "SimC MID1",
        dungeon      = { primary=1.00, crit=0.518, haste=0.522, mastery=0.591, versatility=0.420 },
        raid         = { primary=1.00, crit=0.528, haste=0.606, mastery=0.567, versatility=0.416 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [72] = { -- Fury — Haste > Crit > Mastery > Vers | SimC MID1 · 2026-03-23
        primaryStat  = "ITEM_MOD_STRENGTH_SHORT",
        source       = "SimC MID1",
        dungeon      = { primary=1.00, crit=0.608, haste=0.912, mastery=0.523, versatility=0.484 },
        raid         = { primary=1.00, crit=0.567, haste=0.554, mastery=0.515, versatility=0.432 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [73] = { -- Protection (Tank) — Haste > Mastery > Crit > Vers | SimC MID1 · 2026-03-23
        primaryStat  = "ITEM_MOD_STRENGTH_SHORT",
        source       = "SimC MID1",
        dungeon      = { primary=1.00, crit=0.470, haste=0.491, mastery=0.477, versatility=0.417 },
        raid         = { primary=1.00, crit=0.470, haste=0.429, mastery=0.436, versatility=0.388 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.1,
    },

}
