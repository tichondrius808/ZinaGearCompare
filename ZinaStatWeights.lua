-- ZinaStatWeights.lua — ZinaGearCompare
-- Pesos de stats por spec (specID global) y tipo de contenido.
-- primary=1.0 es la referencia; los secondaries son fracciones relativas.
-- tierBonus2pc/4pc son multiplicadores de score (e.g. 1.05 = +5%).
--
-- Fuente: Wowhead guides, Midnight 12.0.1 (guías actualizadas ~2026-02-26)
-- Los ÓRDENES de prioridad están verificados contra las guías oficiales.
-- Los MAGNITUDES son estimaciones razonables basadas en el énfasis de cada guía
-- (e.g. "by far the best stat" → peso alto; "all stats roughly equal" → valores planos).
--
-- PENDIENTE / TODO:
--   - La mayoría de specs usa los mismos valores para dungeon y raid porque las guías
--     no dan datos numéricos diferenciados. Solo se distinguen explícitamente donde la
--     guía lo especifica (Mistweaver, Disc Priest, Holy Priest, BM Hunter).
--     Se necesita trabajo adicional con datos de simulación reales (Raidbots/SimC)
--     para afinar la separación dungeon vs. raid en el resto de specs.
--   - Augmentation [1480] no tiene guía actualizada en Wowhead aún; mantiene
--     valores estimados de la versión anterior.
--   - Recomendado: revisar esta tabla por lo menos una vez por temporada con datos
--     de SimC actualizados.

ZGC_StatWeights = {

    -- ── Death Knight ────────────────────────────────────────────────────────
    [250] = { -- Blood (Tank) — STR > Haste >> Mastery≈Crit≈Vers (build San'layn)
        primaryStat  = "ITEM_MOD_STRENGTH_SHORT",
        dungeon      = { primary=1.0, crit=0.42, haste=0.54, mastery=0.40, versatility=0.38 },
        raid         = { primary=1.0, crit=0.42, haste=0.54, mastery=0.40, versatility=0.38 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [251] = { -- Frost — Crit > Mastery > Haste > Vers
        primaryStat  = "ITEM_MOD_STRENGTH_SHORT",
        dungeon      = { primary=1.0, crit=0.55, haste=0.30, mastery=0.44, versatility=0.22 },
        raid         = { primary=1.0, crit=0.55, haste=0.30, mastery=0.44, versatility=0.22 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [252] = { -- Unholy — Mastery > Crit > Haste > Vers
        primaryStat  = "ITEM_MOD_STRENGTH_SHORT",
        dungeon      = { primary=1.0, crit=0.44, haste=0.32, mastery=0.55, versatility=0.22 },
        raid         = { primary=1.0, crit=0.44, haste=0.32, mastery=0.55, versatility=0.22 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },

    -- ── Demon Hunter ────────────────────────────────────────────────────────
    [577] = { -- Havoc — Crit > Mastery > Haste > Vers
        primaryStat  = "ITEM_MOD_AGILITY_SHORT",
        dungeon      = { primary=1.0, crit=0.55, haste=0.30, mastery=0.44, versatility=0.22 },
        raid         = { primary=1.0, crit=0.55, haste=0.30, mastery=0.44, versatility=0.22 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [581] = { -- Vengeance (Tank) — Haste > Crit > Vers > Mastery (todos muy cercanos)
        primaryStat  = "ITEM_MOD_AGILITY_SHORT",
        dungeon      = { primary=1.0, crit=0.44, haste=0.48, mastery=0.36, versatility=0.40 },
        raid         = { primary=1.0, crit=0.44, haste=0.48, mastery=0.36, versatility=0.40 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [1480] = { -- Devourer — PENDIENTE: sin guía en Wowhead aún; valores estimados
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        dungeon      = { primary=1.0, crit=0.43, haste=0.70, mastery=0.61, versatility=0.37 },
        raid         = { primary=1.0, crit=0.42, haste=0.72, mastery=0.62, versatility=0.35 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },

    -- ── Druid ───────────────────────────────────────────────────────────────
    [102] = { -- Balance — Mastery > Haste≈Crit > Vers
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        dungeon      = { primary=1.0, crit=0.44, haste=0.46, mastery=0.54, versatility=0.26 },
        raid         = { primary=1.0, crit=0.44, haste=0.46, mastery=0.54, versatility=0.26 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [103] = { -- Feral — Mastery > Crit≈Haste > Vers
        primaryStat  = "ITEM_MOD_AGILITY_SHORT",
        dungeon      = { primary=1.0, crit=0.46, haste=0.44, mastery=0.56, versatility=0.24 },
        raid         = { primary=1.0, crit=0.46, haste=0.44, mastery=0.56, versatility=0.24 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [104] = { -- Guardian (Tank) — Haste > Vers > Crit > Mastery (todos muy cercanos)
        primaryStat  = "ITEM_MOD_AGILITY_SHORT",
        dungeon      = { primary=1.0, crit=0.40, haste=0.47, mastery=0.34, versatility=0.44 },
        raid         = { primary=1.0, crit=0.40, haste=0.47, mastery=0.34, versatility=0.44 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [105] = { -- Restoration (Healer) — Haste > Mastery > Vers >> Crit
        -- Nota: la guía lista Haste por encima del primary stat en la prioridad
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        dungeon      = { primary=1.0, crit=0.20, haste=0.88, mastery=0.70, versatility=0.48 },
        raid         = { primary=1.0, crit=0.20, haste=0.88, mastery=0.70, versatility=0.48 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.10,
    },

    -- ── Evoker ──────────────────────────────────────────────────────────────
    [1467] = { -- Devastation — Crit > Haste > Mastery > Vers
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        dungeon      = { primary=1.0, crit=0.54, haste=0.44, mastery=0.30, versatility=0.20 },
        raid         = { primary=1.0, crit=0.54, haste=0.44, mastery=0.30, versatility=0.20 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [1468] = { -- Preservation (Healer) — Mastery >> Haste > Crit > Vers ("by far the best")
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        dungeon      = { primary=1.0, crit=0.38, haste=0.54, mastery=0.78, versatility=0.28 },
        raid         = { primary=1.0, crit=0.38, haste=0.54, mastery=0.78, versatility=0.28 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.10,
    },
    [1473] = { -- Augmentation (Support) — PENDIENTE: sin guía actualizada; valores estimados
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        dungeon      = { primary=1.0, crit=0.38, haste=0.50, mastery=0.45, versatility=0.32 },
        raid         = { primary=1.0, crit=0.36, haste=0.52, mastery=0.48, versatility=0.30 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },

    -- ── Hunter ──────────────────────────────────────────────────────────────
    [253] = { -- Beast Mastery — Mastery > Haste > Crit > Vers (ST/raid)
        --                        Mastery > Crit > Vers > Haste (AoE/M+)
        primaryStat  = "ITEM_MOD_AGILITY_SHORT",
        dungeon      = { primary=1.0, crit=0.44, haste=0.38, mastery=0.54, versatility=0.36 },
        raid         = { primary=1.0, crit=0.38, haste=0.48, mastery=0.56, versatility=0.30 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [254] = { -- Marksmanship — Crit > Mastery > Haste > Vers
        primaryStat  = "ITEM_MOD_AGILITY_SHORT",
        dungeon      = { primary=1.0, crit=0.54, haste=0.32, mastery=0.44, versatility=0.22 },
        raid         = { primary=1.0, crit=0.54, haste=0.32, mastery=0.44, versatility=0.22 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [255] = { -- Survival — Mastery > Crit≈Haste > Vers
        primaryStat  = "ITEM_MOD_AGILITY_SHORT",
        dungeon      = { primary=1.0, crit=0.44, haste=0.46, mastery=0.56, versatility=0.26 },
        raid         = { primary=1.0, crit=0.44, haste=0.46, mastery=0.56, versatility=0.26 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },

    -- ── Mage ────────────────────────────────────────────────────────────────
    [62] = { -- Arcane — Mastery > Haste > Crit > Vers
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        dungeon      = { primary=1.0, crit=0.36, haste=0.46, mastery=0.54, versatility=0.24 },
        raid         = { primary=1.0, crit=0.36, haste=0.46, mastery=0.54, versatility=0.24 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [63] = { -- Fire — Haste > Mastery > Vers > Crit (Crit es el stat de menor valor)
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        dungeon      = { primary=1.0, crit=0.18, haste=0.55, mastery=0.44, versatility=0.32 },
        raid         = { primary=1.0, crit=0.18, haste=0.55, mastery=0.44, versatility=0.32 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [64] = { -- Frost — Mastery > Crit > Haste > Vers
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        dungeon      = { primary=1.0, crit=0.46, haste=0.35, mastery=0.56, versatility=0.24 },
        raid         = { primary=1.0, crit=0.46, haste=0.35, mastery=0.56, versatility=0.24 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },

    -- ── Monk ────────────────────────────────────────────────────────────────
    [268] = { -- Brewmaster (Tank) — Crit≈Mastery≈Vers > Haste
        primaryStat  = "ITEM_MOD_AGILITY_SHORT",
        dungeon      = { primary=1.0, crit=0.44, haste=0.28, mastery=0.42, versatility=0.42 },
        raid         = { primary=1.0, crit=0.44, haste=0.28, mastery=0.42, versatility=0.42 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [269] = { -- Windwalker — Haste > Crit≈Mastery > Vers
        primaryStat  = "ITEM_MOD_AGILITY_SHORT",
        dungeon      = { primary=1.0, crit=0.45, haste=0.54, mastery=0.44, versatility=0.26 },
        raid         = { primary=1.0, crit=0.45, haste=0.54, mastery=0.44, versatility=0.26 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [270] = { -- Mistweaver (Healer) — Raid: Haste>Crit>Vers>Mastery
        --                              M+:  Haste>Vers>Crit>Mastery
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        dungeon      = { primary=1.0, crit=0.44, haste=0.58, mastery=0.26, versatility=0.48 },
        raid         = { primary=1.0, crit=0.48, haste=0.58, mastery=0.26, versatility=0.40 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.10,
    },

    -- ── Paladin ─────────────────────────────────────────────────────────────
    [65] = { -- Holy (Healer) — Mastery > Haste=Crit > Vers
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        dungeon      = { primary=1.0, crit=0.45, haste=0.45, mastery=0.54, versatility=0.30 },
        raid         = { primary=1.0, crit=0.45, haste=0.45, mastery=0.54, versatility=0.30 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.10,
    },
    [66] = { -- Protection (Tank) — Haste > Vers > Mastery > Crit
        primaryStat  = "ITEM_MOD_STRENGTH_SHORT",
        dungeon      = { primary=1.0, crit=0.34, haste=0.54, mastery=0.38, versatility=0.46 },
        raid         = { primary=1.0, crit=0.34, haste=0.54, mastery=0.40, versatility=0.44 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [70] = { -- Retribution — Mastery > Haste > Crit > Vers
        primaryStat  = "ITEM_MOD_STRENGTH_SHORT",
        dungeon      = { primary=1.0, crit=0.36, haste=0.46, mastery=0.54, versatility=0.24 },
        raid         = { primary=1.0, crit=0.36, haste=0.46, mastery=0.54, versatility=0.24 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },

    -- ── Priest ──────────────────────────────────────────────────────────────
    [256] = { -- Discipline (Healer) — Raid: Haste>Crit>Mastery>Vers
        --                              M+:  Haste>Crit>Vers>Mastery
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        dungeon      = { primary=1.0, crit=0.48, haste=0.56, mastery=0.28, versatility=0.36 },
        raid         = { primary=1.0, crit=0.48, haste=0.56, mastery=0.36, versatility=0.28 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.10,
    },
    [257] = { -- Holy (Healer) — Raid: Crit>Vers=Mastery>Haste
        --                        M+:  Vers>Crit>Haste>Mastery
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        dungeon      = { primary=1.0, crit=0.50, haste=0.36, mastery=0.26, versatility=0.56 },
        raid         = { primary=1.0, crit=0.56, haste=0.30, mastery=0.46, versatility=0.46 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.10,
    },
    [258] = { -- Shadow — Haste > Mastery > Crit > Vers
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        dungeon      = { primary=1.0, crit=0.36, haste=0.56, mastery=0.46, versatility=0.24 },
        raid         = { primary=1.0, crit=0.36, haste=0.56, mastery=0.46, versatility=0.24 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },

    -- ── Rogue ───────────────────────────────────────────────────────────────
    [259] = { -- Assassination — Crit > Haste > Mastery > Vers
        primaryStat  = "ITEM_MOD_AGILITY_SHORT",
        dungeon      = { primary=1.0, crit=0.55, haste=0.46, mastery=0.34, versatility=0.22 },
        raid         = { primary=1.0, crit=0.55, haste=0.46, mastery=0.34, versatility=0.22 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [260] = { -- Outlaw — Haste > Crit > Vers > Mastery
        primaryStat  = "ITEM_MOD_AGILITY_SHORT",
        dungeon      = { primary=1.0, crit=0.46, haste=0.54, mastery=0.22, versatility=0.36 },
        raid         = { primary=1.0, crit=0.46, haste=0.54, mastery=0.22, versatility=0.36 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [261] = { -- Subtlety — Mastery > Haste > Crit > Vers
        primaryStat  = "ITEM_MOD_AGILITY_SHORT",
        dungeon      = { primary=1.0, crit=0.36, haste=0.48, mastery=0.56, versatility=0.22 },
        raid         = { primary=1.0, crit=0.36, haste=0.48, mastery=0.56, versatility=0.22 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },

    -- ── Shaman ──────────────────────────────────────────────────────────────
    [262] = { -- Elemental — Mastery domina (objetivo ~72%) >> Haste=Crit > Vers (evitar)
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        dungeon      = { primary=1.0, crit=0.46, haste=0.46, mastery=0.72, versatility=0.20 },
        raid         = { primary=1.0, crit=0.46, haste=0.46, mastery=0.72, versatility=0.20 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [263] = { -- Enhancement — Haste≈Mastery > Crit > Vers (varía entre builds)
        primaryStat  = "ITEM_MOD_AGILITY_SHORT",
        dungeon      = { primary=1.0, crit=0.40, haste=0.50, mastery=0.50, versatility=0.28 },
        raid         = { primary=1.0, crit=0.40, haste=0.50, mastery=0.50, versatility=0.28 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [264] = { -- Restoration (Healer) — Crit >> Haste=Mastery=Vers (build Farseer recomendado)
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        dungeon      = { primary=1.0, crit=0.62, haste=0.38, mastery=0.38, versatility=0.38 },
        raid         = { primary=1.0, crit=0.62, haste=0.38, mastery=0.38, versatility=0.38 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.10,
    },

    -- ── Warlock ─────────────────────────────────────────────────────────────
    [265] = { -- Affliction — Mastery=Crit > Haste > Vers
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        dungeon      = { primary=1.0, crit=0.50, haste=0.38, mastery=0.50, versatility=0.24 },
        raid         = { primary=1.0, crit=0.50, haste=0.38, mastery=0.50, versatility=0.24 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [266] = { -- Demonology — Haste=Crit > Mastery > Vers
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        dungeon      = { primary=1.0, crit=0.50, haste=0.50, mastery=0.38, versatility=0.24 },
        raid         = { primary=1.0, crit=0.50, haste=0.50, mastery=0.38, versatility=0.24 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [267] = { -- Destruction — Haste > Mastery≥Crit > Vers
        primaryStat  = "ITEM_MOD_INTELLECT_SHORT",
        dungeon      = { primary=1.0, crit=0.43, haste=0.54, mastery=0.44, versatility=0.26 },
        raid         = { primary=1.0, crit=0.43, haste=0.54, mastery=0.44, versatility=0.26 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },

    -- ── Warrior ─────────────────────────────────────────────────────────────
    [71] = { -- Arms — Crit≈Haste > Mastery > Vers ("frecuentemente se intercambian")
        primaryStat  = "ITEM_MOD_STRENGTH_SHORT",
        dungeon      = { primary=1.0, crit=0.52, haste=0.50, mastery=0.38, versatility=0.24 },
        raid         = { primary=1.0, crit=0.52, haste=0.50, mastery=0.38, versatility=0.24 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [72] = { -- Fury — Haste > Mastery > Crit > Vers
        primaryStat  = "ITEM_MOD_STRENGTH_SHORT",
        dungeon      = { primary=1.0, crit=0.36, haste=0.54, mastery=0.46, versatility=0.26 },
        raid         = { primary=1.0, crit=0.36, haste=0.54, mastery=0.46, versatility=0.26 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
    [73] = { -- Protection (Tank) — Haste > Crit > Vers > Mastery
        primaryStat  = "ITEM_MOD_STRENGTH_SHORT",
        dungeon      = { primary=1.0, crit=0.45, haste=0.54, mastery=0.28, versatility=0.40 },
        raid         = { primary=1.0, crit=0.45, haste=0.54, mastery=0.28, versatility=0.40 },
        tierBonus2pc = 1.05,
        tierBonus4pc = 1.12,
    },
}
