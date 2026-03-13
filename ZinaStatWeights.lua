-- ZinaStatWeights.lua — ZinaGearCompare
-- Pesos de stats por spec (specID global) y tipo de contenido.
-- primary=1.0 es la referencia; los secondaries son fracciones relativas.
--
-- Generado automáticamente por tools/simc_to_lua.py — 2026-03-13
-- Fuente: SimulationCraft nightly, perfiles MID1 (Midnight 12.0.1)
-- Fight styles: Patchwerk (raid) · DungeonSlice (dungeon/M+)
-- Specs sin perfil MID1 marcadas como 'estimado'.
--
-- Para actualizar: corre tools/run_simc_all.bat y luego tools/simc_to_lua.py

ZGC_StatWeights = {

    -- ── Death Knight ────────────────────────────────────────────────
    [250] = { -- Blood (Tank) — Haste > Crit > Vers > Mastery | SimC MID1 · 2026-03-13
        primaryStat  = "ITEM_MOD_STRENGTH_SHORT",
        dungeon      = { primary=1.00, crit=0.522, haste=0.599, mastery=0.488, versatility=0.514 },
        raid         = { primary=1.00, crit=0.524, haste=0.441, mastery=0.529, versatility=0.514 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [251] = { -- Frost — Mastery > Crit > Haste > Vers | SimC MID1 · 2026-03-13
        primaryStat  = "ITEM_MOD_STRENGTH_SHORT",
        dungeon      = { primary=1.00, crit=0.522, haste=0.421, mastery=0.528, versatility=0.402 },
        raid         = { primary=1.00, crit=0.477, haste=0.411, mastery=0.505, versatility=0.349 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [252] = { -- Unholy — Haste > Crit > Mastery > Vers | SimC MID1 · 2026-03-13
        primaryStat  = "ITEM_MOD_STRENGTH_SHORT",
        dungeon      = { primary=1.00, crit=0.610, haste=0.612, mastery=0.507, versatility=0.401 },
        raid         = { primary=1.00, crit=0.625, haste=0.513, mastery=0.499, versatility=0.353 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },

    -- ── Demon Hunter ────────────────────────────────────────────────
    [577] = { -- Havoc — Crit > Mastery > Haste > Vers | estimado — sin perfil MID1
        primaryStat  = "ITEM_MOD_AGILITY_SHORT",
        dungeon      = { primary=1.00, crit=0.550, haste=0.300, mastery=0.440, versatility=0.220 },
        raid         = { primary=1.00, crit=0.550, haste=0.300, mastery=0.440, versatility=0.220 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [581] = { -- Vengeance (Tank) — Crit > Mastery > Vers > Haste | SimC MID1 · 2026-03-13
        primaryStat  = "ITEM_MOD_AGILITY_SHORT",
        dungeon      = { primary=1.00, crit=0.485, haste=0.343, mastery=0.479, versatility=0.452 },
        raid         = { primary=1.00, crit=0.485, haste=0.483, mastery=0.469, versatility=0.459 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [1480] = { -- Devourer — Haste > Mastery > Crit > Vers | SimC MID1 · 2026-03-13
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        dungeon      = { primary=1.00, crit=0.507, haste=0.807, mastery=0.688, versatility=0.464 },
        raid         = { primary=1.00, crit=0.585, haste=0.779, mastery=0.695, versatility=0.499 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },

    -- ── Druid ───────────────────────────────────────────────────────
    [102] = { -- Balance — Mastery > Haste > Crit > Vers | estimado — sin perfil MID1
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        dungeon      = { primary=1.00, crit=0.440, haste=0.460, mastery=0.540, versatility=0.260 },
        raid         = { primary=1.00, crit=0.440, haste=0.460, mastery=0.540, versatility=0.260 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [103] = { -- Feral — Vers > Crit > Mastery > Haste | SimC MID1 · 2026-03-13
        primaryStat  = "ITEM_MOD_AGILITY_SHORT",
        dungeon      = { primary=1.00, crit=0.482, haste=0.437, mastery=0.439, versatility=0.497 },
        raid         = { primary=1.00, crit=0.492, haste=0.480, mastery=0.469, versatility=0.494 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [104] = { -- Guardian (Tank) — Haste > Vers > Crit > Mastery | estimado — sin perfil MID1
        primaryStat  = "ITEM_MOD_AGILITY_SHORT",
        dungeon      = { primary=1.00, crit=0.400, haste=0.470, mastery=0.340, versatility=0.440 },
        raid         = { primary=1.00, crit=0.400, haste=0.470, mastery=0.340, versatility=0.440 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [105] = { -- Restoration (Healer) — Haste > Mastery > Vers > Crit | estimado — sin perfil MID1
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        dungeon      = { primary=1.00, crit=0.200, haste=0.880, mastery=0.700, versatility=0.480 },
        raid         = { primary=1.00, crit=0.200, haste=0.880, mastery=0.700, versatility=0.480 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.1,
    },

    -- ── Evoker ──────────────────────────────────────────────────────
    [1467] = { -- Devastation — Crit > Haste > Mastery > Vers | SimC MID1 · 2026-03-13
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        dungeon      = { primary=1.00, crit=0.467, haste=0.410, mastery=0.392, versatility=0.354 },
        raid         = { primary=1.00, crit=0.463, haste=0.393, mastery=0.373, versatility=0.307 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [1468] = { -- Preservation (Healer) — Mastery > Haste > Crit > Vers | estimado — sin perfil MID1
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        dungeon      = { primary=1.00, crit=0.380, haste=0.540, mastery=0.780, versatility=0.280 },
        raid         = { primary=1.00, crit=0.380, haste=0.540, mastery=0.780, versatility=0.280 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.1,
    },
    [1473] = { -- Augmentation (Support) — Haste > Mastery > Crit > Vers | estimado — sin perfil MID1
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        dungeon      = { primary=1.00, crit=0.380, haste=0.500, mastery=0.450, versatility=0.320 },
        raid         = { primary=1.00, crit=0.360, haste=0.520, mastery=0.480, versatility=0.300 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },

    -- ── Hunter ──────────────────────────────────────────────────────
    [253] = { -- Beast Mastery — Mastery > Crit > Haste > Vers | estimado — sin perfil MID1
        primaryStat  = "ITEM_MOD_AGILITY_SHORT",
        dungeon      = { primary=1.00, crit=0.440, haste=0.380, mastery=0.540, versatility=0.360 },
        raid         = { primary=1.00, crit=0.380, haste=0.480, mastery=0.560, versatility=0.300 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [254] = { -- Marksmanship — Crit > Mastery > Haste > Vers | estimado — sin perfil MID1
        primaryStat  = "ITEM_MOD_AGILITY_SHORT",
        dungeon      = { primary=1.00, crit=0.540, haste=0.320, mastery=0.440, versatility=0.220 },
        raid         = { primary=1.00, crit=0.540, haste=0.320, mastery=0.440, versatility=0.220 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [255] = { -- Survival — Mastery > Haste > Crit > Vers | estimado — sin perfil MID1
        primaryStat  = "ITEM_MOD_AGILITY_SHORT",
        dungeon      = { primary=1.00, crit=0.440, haste=0.460, mastery=0.560, versatility=0.260 },
        raid         = { primary=1.00, crit=0.440, haste=0.460, mastery=0.560, versatility=0.260 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },

    -- ── Mage ────────────────────────────────────────────────────────
    [62] = { -- Arcane — Mastery > Vers > Crit > Haste | SimC MID1 · 2026-03-13
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        dungeon      = { primary=1.00, crit=0.419, haste=0.010, mastery=0.573, versatility=0.435 },
        raid         = { primary=1.00, crit=0.484, haste=0.314, mastery=0.440, versatility=0.463 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [63] = { -- Fire — Haste > Vers > Mastery > Crit | SimC MID1 · 2026-03-13
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        dungeon      = { primary=1.00, crit=0.184, haste=0.531, mastery=0.457, versatility=0.500 },
        raid         = { primary=1.00, crit=0.202, haste=0.562, mastery=0.436, versatility=0.489 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [64] = { -- Frost — Crit > Mastery > Haste > Vers | SimC MID1 · 2026-03-13
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        dungeon      = { primary=1.00, crit=0.525, haste=0.470, mastery=0.519, versatility=0.374 },
        raid         = { primary=1.00, crit=0.512, haste=0.439, mastery=0.529, versatility=0.363 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },

    -- ── Monk ────────────────────────────────────────────────────────
    [268] = { -- Brewmaster (Tank) — Crit > Vers > Mastery > Haste | SimC MID1 · 2026-03-13
        primaryStat  = "ITEM_MOD_AGILITY_SHORT",
        dungeon      = { primary=1.00, crit=0.512, haste=0.232, mastery=0.455, versatility=0.491 },
        raid         = { primary=1.00, crit=0.508, haste=0.157, mastery=0.494, versatility=0.486 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [269] = { -- Windwalker — Crit > Haste > Mastery > Vers | SimC MID1 · 2026-03-13
        primaryStat  = "ITEM_MOD_AGILITY_SHORT",
        dungeon      = { primary=1.00, crit=0.700, haste=0.657, mastery=0.563, versatility=0.380 },
        raid         = { primary=1.00, crit=0.545, haste=0.493, mastery=0.503, versatility=0.317 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [270] = { -- Mistweaver (Healer) — Haste > Vers > Crit > Mastery | estimado — sin perfil MID1
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        dungeon      = { primary=1.00, crit=0.440, haste=0.580, mastery=0.260, versatility=0.480 },
        raid         = { primary=1.00, crit=0.480, haste=0.580, mastery=0.260, versatility=0.400 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.1,
    },

    -- ── Paladin ─────────────────────────────────────────────────────
    [65] = { -- Holy (Healer) — Mastery > Crit > Haste > Vers | estimado — sin perfil MID1
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        dungeon      = { primary=1.00, crit=0.450, haste=0.450, mastery=0.540, versatility=0.300 },
        raid         = { primary=1.00, crit=0.450, haste=0.450, mastery=0.540, versatility=0.300 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.1,
    },
    [66] = { -- Protection (Tank) — Haste > Vers > Mastery > Crit | estimado — sin perfil MID1
        primaryStat  = "ITEM_MOD_STRENGTH_SHORT",
        dungeon      = { primary=1.00, crit=0.340, haste=0.540, mastery=0.380, versatility=0.460 },
        raid         = { primary=1.00, crit=0.340, haste=0.540, mastery=0.400, versatility=0.440 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [70] = { -- Retribution — Mastery > Haste > Crit > Vers | estimado — sin perfil MID1
        primaryStat  = "ITEM_MOD_STRENGTH_SHORT",
        dungeon      = { primary=1.00, crit=0.360, haste=0.460, mastery=0.540, versatility=0.240 },
        raid         = { primary=1.00, crit=0.360, haste=0.460, mastery=0.540, versatility=0.240 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },

    -- ── Priest ──────────────────────────────────────────────────────
    [256] = { -- Discipline (Healer) — Haste > Crit > Vers > Mastery | estimado — sin perfil MID1
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        dungeon      = { primary=1.00, crit=0.480, haste=0.560, mastery=0.280, versatility=0.360 },
        raid         = { primary=1.00, crit=0.480, haste=0.560, mastery=0.360, versatility=0.280 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.1,
    },
    [257] = { -- Holy (Healer) — Vers > Crit > Haste > Mastery | estimado — sin perfil MID1
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        dungeon      = { primary=1.00, crit=0.500, haste=0.360, mastery=0.260, versatility=0.560 },
        raid         = { primary=1.00, crit=0.560, haste=0.300, mastery=0.460, versatility=0.460 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.1,
    },
    [258] = { -- Shadow — Crit > Mastery > Haste > Vers | SimC MID1 · 2026-03-13
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        dungeon      = { primary=1.00, crit=0.587, haste=0.530, mastery=0.543, versatility=0.519 },
        raid         = { primary=1.00, crit=0.567, haste=0.481, mastery=0.579, versatility=0.493 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },

    -- ── Rogue ───────────────────────────────────────────────────────
    [259] = { -- Assassination — Crit > Haste > Mastery > Vers | estimado — sin perfil MID1
        primaryStat  = "ITEM_MOD_AGILITY_SHORT",
        dungeon      = { primary=1.00, crit=0.550, haste=0.460, mastery=0.340, versatility=0.220 },
        raid         = { primary=1.00, crit=0.550, haste=0.460, mastery=0.340, versatility=0.220 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [260] = { -- Outlaw — Crit > Vers > Haste > Mastery | SimC MID1 · 2026-03-13
        primaryStat  = "ITEM_MOD_AGILITY_SHORT",
        dungeon      = { primary=1.00, crit=0.485, haste=0.356, mastery=0.351, versatility=0.458 },
        raid         = { primary=1.00, crit=0.462, haste=0.362, mastery=0.279, versatility=0.444 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [261] = { -- Subtlety — Haste > Mastery > Crit > Vers | SimC MID1 · 2026-03-13
        primaryStat  = "ITEM_MOD_AGILITY_SHORT",
        dungeon      = { primary=1.00, crit=0.497, haste=0.598, mastery=0.550, versatility=0.484 },
        raid         = { primary=1.00, crit=0.513, haste=0.193, mastery=0.492, versatility=0.485 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },

    -- ── Shaman ──────────────────────────────────────────────────────
    [262] = { -- Elemental — Haste > Crit > Mastery > Vers | SimC MID1 · 2026-03-13
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        dungeon      = { primary=1.00, crit=0.585, haste=0.722, mastery=0.497, versatility=0.466 },
        raid         = { primary=1.00, crit=0.532, haste=0.491, mastery=0.435, versatility=0.439 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [263] = { -- Enhancement — Mastery > Haste > Vers > Crit | SimC MID1 · 2026-03-13
        primaryStat  = "ITEM_MOD_AGILITY_SHORT",
        dungeon      = { primary=1.00, crit=0.446, haste=0.494, mastery=0.501, versatility=0.465 },
        raid         = { primary=1.00, crit=0.479, haste=0.533, mastery=0.463, versatility=0.470 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [264] = { -- Restoration (Healer) — Crit > Haste > Mastery > Vers | estimado — sin perfil MID1
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        dungeon      = { primary=1.00, crit=0.620, haste=0.380, mastery=0.380, versatility=0.380 },
        raid         = { primary=1.00, crit=0.620, haste=0.380, mastery=0.380, versatility=0.380 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.1,
    },

    -- ── Warlock ─────────────────────────────────────────────────────
    [265] = { -- Affliction — Crit > Vers > Haste > Mastery | SimC MID1 · 2026-03-13
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        dungeon      = { primary=1.00, crit=0.477, haste=0.419, mastery=0.283, versatility=0.458 },
        raid         = { primary=1.00, crit=0.503, haste=0.436, mastery=0.344, versatility=0.480 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [266] = { -- Demonology — Crit > Haste > Mastery > Vers | estimado — sin perfil MID1
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        dungeon      = { primary=1.00, crit=0.500, haste=0.500, mastery=0.380, versatility=0.240 },
        raid         = { primary=1.00, crit=0.500, haste=0.500, mastery=0.380, versatility=0.240 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [267] = { -- Destruction — Haste > Crit > Mastery > Vers | SimC MID1 · 2026-03-13
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        dungeon      = { primary=1.00, crit=0.552, haste=0.595, mastery=0.514, versatility=0.471 },
        raid         = { primary=1.00, crit=0.545, haste=0.545, mastery=0.546, versatility=0.481 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },

    -- ── Warrior ─────────────────────────────────────────────────────
    [71] = { -- Arms — Crit > Haste > Mastery > Vers | estimado — sin perfil MID1
        primaryStat  = "ITEM_MOD_STRENGTH_SHORT",
        dungeon      = { primary=1.00, crit=0.520, haste=0.500, mastery=0.380, versatility=0.240 },
        raid         = { primary=1.00, crit=0.520, haste=0.500, mastery=0.380, versatility=0.240 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [72] = { -- Fury — Haste > Mastery > Crit > Vers | estimado — sin perfil MID1
        primaryStat  = "ITEM_MOD_STRENGTH_SHORT",
        dungeon      = { primary=1.00, crit=0.360, haste=0.540, mastery=0.460, versatility=0.260 },
        raid         = { primary=1.00, crit=0.360, haste=0.540, mastery=0.460, versatility=0.260 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [73] = { -- Protection (Tank) — Haste > Mastery > Crit > Vers | SimC MID1 · 2026-03-13
        primaryStat  = "ITEM_MOD_STRENGTH_SHORT",
        dungeon      = { primary=1.00, crit=0.479, haste=0.533, mastery=0.497, versatility=0.427 },
        raid         = { primary=1.00, crit=0.491, haste=0.464, mastery=0.454, versatility=0.405 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },

}
