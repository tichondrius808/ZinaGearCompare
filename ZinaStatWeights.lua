-- ZinaStatWeights.lua — ZinaGearCompare
-- Pesos de stats por spec (specID global) y tipo de contenido.
-- primary=1.0 es la referencia; los secondaries son fracciones relativas.
-- tierBonus2pc/4pc son multiplicadores de score (e.g. 1.05 = +5%).

ZGC_StatWeights = {

    -- ── Death Knight ────────────────────────────────────────────────────────
    [250] = { -- Blood (Tank)
        primaryStat  = "ITEM_MOD_STRENGTH_SHORT",
        dungeon      = { primary=1.0, crit=0.25, haste=0.38, mastery=0.42, versatility=0.52 },
        raid         = { primary=1.0, crit=0.25, haste=0.35, mastery=0.45, versatility=0.55 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [251] = { -- Frost
        primaryStat  = "ITEM_MOD_STRENGTH_SHORT",
        dungeon      = { primary=1.0, crit=0.42, haste=0.25, mastery=0.43, versatility=0.26 },
        raid         = { primary=1.0, crit=0.42, haste=0.24, mastery=0.44, versatility=0.25 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [252] = { -- Unholy
        primaryStat  = "ITEM_MOD_STRENGTH_SHORT",
        dungeon      = { primary=1.0, crit=0.51, haste=0.40, mastery=0.43, versatility=0.26 },
        raid         = { primary=1.0, crit=0.52, haste=0.38, mastery=0.44, versatility=0.25 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },

    -- ── Demon Hunter ────────────────────────────────────────────────────────
    [577] = { -- Havoc
        primaryStat  = "ITEM_MOD_AGILITY_SHORT",
        dungeon      = { primary=1.0, crit=0.46, haste=0.28, mastery=0.44, versatility=0.34 },
        raid         = { primary=1.0, crit=0.47, haste=0.26, mastery=0.45, versatility=0.32 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [581] = { -- Vengeance (Tank)
        primaryStat  = "ITEM_MOD_AGILITY_SHORT",
        dungeon      = { primary=1.0, crit=0.28, haste=0.42, mastery=0.38, versatility=0.55 },
        raid         = { primary=1.0, crit=0.25, haste=0.38, mastery=0.42, versatility=0.58 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [1480] = { -- Devourer (Dark Ranger / Hero Talents hybrid)
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        dungeon      = { primary=1.0, crit=0.43, haste=0.70, mastery=0.61, versatility=0.37 },
        raid         = { primary=1.0, crit=0.42, haste=0.72, mastery=0.62, versatility=0.35 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },

    -- ── Druid ───────────────────────────────────────────────────────────────
    [102] = { -- Balance
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        dungeon      = { primary=1.0, crit=0.38, haste=0.45, mastery=0.48, versatility=0.30 },
        raid         = { primary=1.0, crit=0.40, haste=0.42, mastery=0.50, versatility=0.28 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [103] = { -- Feral
        primaryStat  = "ITEM_MOD_AGILITY_SHORT",
        dungeon      = { primary=1.0, crit=0.55, haste=0.40, mastery=0.48, versatility=0.30 },
        raid         = { primary=1.0, crit=0.52, haste=0.38, mastery=0.50, versatility=0.28 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [104] = { -- Guardian (Tank)
        primaryStat  = "ITEM_MOD_AGILITY_SHORT",
        dungeon      = { primary=1.0, crit=0.28, haste=0.42, mastery=0.45, versatility=0.52 },
        raid         = { primary=1.0, crit=0.25, haste=0.38, mastery=0.48, versatility=0.55 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [105] = { -- Restoration (Healer)
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        dungeon      = { primary=1.0, crit=0.35, haste=0.58, mastery=0.42, versatility=0.30 },
        raid         = { primary=1.0, crit=0.38, haste=0.55, mastery=0.45, versatility=0.28 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.10,
    },

    -- ── Evoker ──────────────────────────────────────────────────────────────
    [1467] = { -- Devastation
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        dungeon      = { primary=1.0, crit=0.42, haste=0.40, mastery=0.48, versatility=0.30 },
        raid         = { primary=1.0, crit=0.44, haste=0.38, mastery=0.50, versatility=0.28 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [1468] = { -- Preservation (Healer)
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        dungeon      = { primary=1.0, crit=0.40, haste=0.55, mastery=0.42, versatility=0.30 },
        raid         = { primary=1.0, crit=0.38, haste=0.58, mastery=0.44, versatility=0.28 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.10,
    },
    [1473] = { -- Augmentation (Support)
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        dungeon      = { primary=1.0, crit=0.38, haste=0.50, mastery=0.45, versatility=0.32 },
        raid         = { primary=1.0, crit=0.36, haste=0.52, mastery=0.48, versatility=0.30 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },

    -- ── Hunter ──────────────────────────────────────────────────────────────
    [253] = { -- Beast Mastery
        primaryStat  = "ITEM_MOD_AGILITY_SHORT",
        dungeon      = { primary=1.0, crit=0.36, haste=0.46, mastery=0.42, versatility=0.36 },
        raid         = { primary=1.0, crit=0.38, haste=0.44, mastery=0.40, versatility=0.34 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [254] = { -- Marksmanship
        primaryStat  = "ITEM_MOD_AGILITY_SHORT",
        dungeon      = { primary=1.0, crit=0.40, haste=0.32, mastery=0.40, versatility=0.36 },
        raid         = { primary=1.0, crit=0.42, haste=0.30, mastery=0.41, versatility=0.35 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [255] = { -- Survival
        primaryStat  = "ITEM_MOD_AGILITY_SHORT",
        dungeon      = { primary=1.0, crit=0.42, haste=0.62, mastery=0.47, versatility=0.38 },
        raid         = { primary=1.0, crit=0.44, haste=0.60, mastery=0.45, versatility=0.36 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },

    -- ── Mage ────────────────────────────────────────────────────────────────
    [62] = { -- Arcane
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        dungeon      = { primary=1.0, crit=0.36, haste=0.34, mastery=0.35, versatility=0.36 },
        raid         = { primary=1.0, crit=0.38, haste=0.32, mastery=0.36, versatility=0.34 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [63] = { -- Fire
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        dungeon      = { primary=1.0, crit=0.13, haste=0.52, mastery=0.40, versatility=0.36 },
        raid         = { primary=1.0, crit=0.12, haste=0.54, mastery=0.38, versatility=0.34 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [64] = { -- Frost
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        dungeon      = { primary=1.0, crit=0.46, haste=0.38, mastery=0.44, versatility=0.36 },
        raid         = { primary=1.0, crit=0.48, haste=0.36, mastery=0.46, versatility=0.34 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },

    -- ── Monk ────────────────────────────────────────────────────────────────
    [268] = { -- Brewmaster (Tank)
        primaryStat  = "ITEM_MOD_AGILITY_SHORT",
        dungeon      = { primary=1.0, crit=0.30, haste=0.48, mastery=0.42, versatility=0.52 },
        raid         = { primary=1.0, crit=0.28, haste=0.45, mastery=0.45, versatility=0.55 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [269] = { -- Windwalker
        primaryStat  = "ITEM_MOD_AGILITY_SHORT",
        dungeon      = { primary=1.0, crit=0.42, haste=0.42, mastery=0.38, versatility=0.35 },
        raid         = { primary=1.0, crit=0.44, haste=0.40, mastery=0.40, versatility=0.33 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [270] = { -- Mistweaver (Healer)
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        dungeon      = { primary=1.0, crit=0.38, haste=0.60, mastery=0.38, versatility=0.30 },
        raid         = { primary=1.0, crit=0.36, haste=0.62, mastery=0.40, versatility=0.28 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.10,
    },

    -- ── Paladin ─────────────────────────────────────────────────────────────
    [65] = { -- Holy (Healer)
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        dungeon      = { primary=1.0, crit=0.42, haste=0.58, mastery=0.35, versatility=0.32 },
        raid         = { primary=1.0, crit=0.44, haste=0.55, mastery=0.38, versatility=0.30 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.10,
    },
    [66] = { -- Protection (Tank)
        primaryStat  = "ITEM_MOD_STRENGTH_SHORT",
        dungeon      = { primary=1.0, crit=0.30, haste=0.42, mastery=0.38, versatility=0.55 },
        raid         = { primary=1.0, crit=0.28, haste=0.38, mastery=0.42, versatility=0.58 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [70] = { -- Retribution
        primaryStat  = "ITEM_MOD_STRENGTH_SHORT",
        dungeon      = { primary=1.0, crit=0.41, haste=0.37, mastery=0.44, versatility=0.37 },
        raid         = { primary=1.0, crit=0.42, haste=0.35, mastery=0.46, versatility=0.35 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },

    -- ── Priest ──────────────────────────────────────────────────────────────
    [256] = { -- Discipline (Healer)
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        dungeon      = { primary=1.0, crit=0.42, haste=0.52, mastery=0.38, versatility=0.32 },
        raid         = { primary=1.0, crit=0.44, haste=0.50, mastery=0.40, versatility=0.30 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.10,
    },
    [257] = { -- Holy (Healer)
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        dungeon      = { primary=1.0, crit=0.35, haste=0.60, mastery=0.40, versatility=0.30 },
        raid         = { primary=1.0, crit=0.38, haste=0.58, mastery=0.42, versatility=0.28 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.10,
    },
    [258] = { -- Shadow
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        dungeon      = { primary=1.0, crit=0.37, haste=0.34, mastery=0.39, versatility=0.32 },
        raid         = { primary=1.0, crit=0.38, haste=0.32, mastery=0.40, versatility=0.30 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },

    -- ── Rogue ───────────────────────────────────────────────────────────────
    [259] = { -- Assassination
        primaryStat  = "ITEM_MOD_AGILITY_SHORT",
        dungeon      = { primary=1.0, crit=0.48, haste=0.46, mastery=0.33, versatility=0.36 },
        raid         = { primary=1.0, crit=0.50, haste=0.44, mastery=0.32, versatility=0.34 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [260] = { -- Outlaw
        primaryStat  = "ITEM_MOD_AGILITY_SHORT",
        dungeon      = { primary=1.0, crit=0.48, haste=0.45, mastery=0.30, versatility=0.38 },
        raid         = { primary=1.0, crit=0.50, haste=0.42, mastery=0.28, versatility=0.36 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [261] = { -- Subtlety
        primaryStat  = "ITEM_MOD_AGILITY_SHORT",
        dungeon      = { primary=1.0, crit=0.40, haste=0.57, mastery=0.41, versatility=0.36 },
        raid         = { primary=1.0, crit=0.42, haste=0.55, mastery=0.42, versatility=0.34 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },

    -- ── Shaman ──────────────────────────────────────────────────────────────
    [262] = { -- Elemental
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        dungeon      = { primary=1.0, crit=0.41, haste=0.37, mastery=0.45, versatility=0.34 },
        raid         = { primary=1.0, crit=0.43, haste=0.35, mastery=0.47, versatility=0.32 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [263] = { -- Enhancement
        primaryStat  = "ITEM_MOD_AGILITY_SHORT",
        dungeon      = { primary=1.0, crit=0.37, haste=0.46, mastery=0.42, versatility=0.37 },
        raid         = { primary=1.0, crit=0.39, haste=0.44, mastery=0.44, versatility=0.35 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [264] = { -- Restoration (Healer)
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        dungeon      = { primary=1.0, crit=0.38, haste=0.62, mastery=0.42, versatility=0.30 },
        raid         = { primary=1.0, crit=0.40, haste=0.60, mastery=0.44, versatility=0.28 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.10,
    },

    -- ── Warlock ─────────────────────────────────────────────────────────────
    [265] = { -- Affliction
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        dungeon      = { primary=1.0, crit=0.35, haste=0.36, mastery=0.23, versatility=0.33 },
        raid         = { primary=1.0, crit=0.36, haste=0.34, mastery=0.24, versatility=0.31 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [266] = { -- Demonology
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        dungeon      = { primary=1.0, crit=0.33, haste=0.40, mastery=0.34, versatility=0.32 },
        raid         = { primary=1.0, crit=0.34, haste=0.38, mastery=0.35, versatility=0.30 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [267] = { -- Destruction
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        dungeon      = { primary=1.0, crit=0.37, haste=0.27, mastery=0.33, versatility=0.32 },
        raid         = { primary=1.0, crit=0.38, haste=0.25, mastery=0.35, versatility=0.30 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },

    -- ── Warrior ─────────────────────────────────────────────────────────────
    [71] = { -- Arms
        primaryStat  = "ITEM_MOD_STRENGTH_SHORT",
        dungeon      = { primary=1.0, crit=0.45, haste=0.48, mastery=0.42, versatility=0.35 },
        raid         = { primary=1.0, crit=0.47, haste=0.46, mastery=0.44, versatility=0.33 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [72] = { -- Fury
        primaryStat  = "ITEM_MOD_STRENGTH_SHORT",
        dungeon      = { primary=1.0, crit=0.43, haste=0.44, mastery=0.46, versatility=0.38 },
        raid         = { primary=1.0, crit=0.45, haste=0.42, mastery=0.48, versatility=0.36 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [73] = { -- Protection (Tank)
        primaryStat  = "ITEM_MOD_STRENGTH_SHORT",
        dungeon      = { primary=1.0, crit=0.30, haste=0.42, mastery=0.38, versatility=0.55 },
        raid         = { primary=1.0, crit=0.28, haste=0.38, mastery=0.42, versatility=0.58 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
}
