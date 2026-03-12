-- ZinaTierSets.lua — ZinaGearCompare
-- Detección de tier set para WoW Midnight Season 1 (The Voidspire, patch 12.0.1).
--
-- Solo se incluyen IDs de dificultad Normal. Para Heroic, Mythic, LFR y Catalyst,
-- añadir los IDs correspondientes a la tabla ZGC_TIER_SET_ITEMS.
-- Fuente: Wowhead.com patch 12.0.1 — verificar en juego si algún ID no se detecta.
--
-- Set IDs de clase para GetItemSetInfo (referencia):
--   Warrior=1990, Paladin=1985, DK=1978, DH=1979, Druid=1980,
--   Evoker=1986, Hunter=1982, Mage=1983, Monk=1984, Priest=1986(*),
--   Rogue=1987, Shaman=1988, Warlock=1989
-- (*) Evoker y Priest comparten el ID 1986 en los datos conocidos;
--     uno de los dos puede tener un ID distinto — verificar en juego.

-- Slots de tier (invSlotID de WoW):
-- 1=Head, 3=Shoulder, 5=Chest, 10=Hands, 7=Legs
ZGC_TIER_SLOTS = {1, 3, 5, 10, 7}

-- ── The Voidspire — Midnight Season 1 tier set item IDs (Normal) ─────────────
ZGC_TIER_SET_ITEMS = {

    -- ── Warrior — Rage of the Night Ender ────────────────────────────────
    -- Night Ender's Tusks (Head), Pauldrons, Breastplate, Fists, Chausses
    [249952] = true,  -- Head
    [249950] = true,  -- Shoulders
    [249955] = true,  -- Chest
    [249953] = true,  -- Hands
    [249951] = true,  -- Legs

    -- ── Paladin — Luminant Verdict's Vestments ────────────────────────────
    -- Unwavering Gaze, Providence Watch, Divine Warplate, Gauntlets, Greaves
    [249961] = true,  -- Head
    [249959] = true,  -- Shoulders
    [249964] = true,  -- Chest
    [249962] = true,  -- Hands
    [249960] = true,  -- Legs

    -- ── Death Knight — Relentless Rider's Lament ──────────────────────────
    -- Crown, Dreadthorns, Cuirass, Bonegrasps, Legguards
    [249970] = true,  -- Head
    [249968] = true,  -- Shoulders
    [249973] = true,  -- Chest
    [249971] = true,  -- Hands
    [249969] = true,  -- Legs

    -- ── Hunter — Primal Sentry's Camouflage ──────────────────────────────
    -- Maw, Trophies, Scaleplate, Talonguards, Legguards
    [249988] = true,  -- Head
    [249986] = true,  -- Shoulders
    [249991] = true,  -- Chest
    [249989] = true,  -- Hands
    [249987] = true,  -- Legs

    -- ── Shaman — Mantle of the Primal Core ───────────────────────────────
    -- Locus, Tempests, Embrace, Earthgrips, Leggings
    [249979] = true,  -- Head
    [249977] = true,  -- Shoulders
    [249982] = true,  -- Chest
    [249980] = true,  -- Hands
    [249978] = true,  -- Legs

    -- ── Evoker — Livery of the Black Talon ───────────────────────────────
    -- Hornhelm, Beacons, Frenzyward, Enforcer's Grips, Greaves
    [249997] = true,  -- Head
    [249995] = true,  -- Shoulders
    [250000] = true,  -- Chest
    [249998] = true,  -- Hands
    [249996] = true,  -- Legs

    -- ── Rogue — Motley of the Grim Jest ──────────────────────────────────
    -- Masquerade, Venom Casks, Fantastic Finery, Sleight of Hand, Blade Holsters
    [250006] = true,  -- Head
    [250004] = true,  -- Shoulders
    [250009] = true,  -- Chest
    [250007] = true,  -- Hands
    [250005] = true,  -- Legs

    -- ── Monk — Way of Ra-den's Chosen ─────────────────────────────────────
    -- Fearsome Visage, Aurastones, Battle Garb, Thunderfists, Swiftsweepers
    [250015] = true,  -- Head
    [250013] = true,  -- Shoulders
    [250018] = true,  -- Chest
    [250016] = true,  -- Hands
    [250014] = true,  -- Legs

    -- ── Druid — Sprouts of the Luminous Bloom ────────────────────────────
    -- Branches, Seedpods, Trunk, Arbortenders, Phloemwraps
    [250024] = true,  -- Head
    [250022] = true,  -- Shoulders
    [250027] = true,  -- Chest
    [250025] = true,  -- Hands
    [250023] = true,  -- Legs

    -- ── Demon Hunter — Devouring Reaver's Sheathe ────────────────────────
    -- Intake, Exhaustplates, Engine, Essence Grips, Pistons
    [250033] = true,  -- Head
    [250031] = true,  -- Shoulders
    [250036] = true,  -- Chest
    [250034] = true,  -- Hands
    [250032] = true,  -- Legs

    -- ── Warlock — Reign of the Abyssal Immolator ──────────────────────────
    -- Smoldering Flames, Fury, Dreadrobe, Grasps, Pillars
    [250042] = true,  -- Head
    [250040] = true,  -- Shoulders
    [250045] = true,  -- Chest
    [250043] = true,  -- Hands
    [250041] = true,  -- Legs

    -- ── Priest — Blind Oath's Burden ──────────────────────────────────────
    -- Winged Crest, Seraphguards, Raiment, Touch, Leggings
    [250051] = true,  -- Head
    [250049] = true,  -- Shoulders
    [250054] = true,  -- Chest
    [250052] = true,  -- Hands
    [250050] = true,  -- Legs

    -- ── Mage — Voidbreaker's Accordance ───────────────────────────────────
    -- Veil, Leyline Nexi, Robe, Gloves, Britches
    [250060] = true,  -- Head
    [250058] = true,  -- Shoulders
    [250063] = true,  -- Chest
    [250061] = true,  -- Hands
    [250059] = true,  -- Legs

    -- ── Heroic / Mythic / LFR / Catalyst ─────────────────────────────────
    -- TODO: Añadir IDs de otras dificultades cuando estén disponibles en Wowhead.
    -- Patrón típico: IDs consecutivos en bloques separados por clase.
}

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function GetItemIDFromLink(itemLink)
    if not itemLink then return nil end
    return tonumber(itemLink:match("item:(%d+)"))
end

-- Cuenta cuántas piezas de tier tiene equipadas una unit (0-5).
function ZGC_CountTierPieces(unit)
    local count = 0
    for _, slotID in ipairs(ZGC_TIER_SLOTS) do
        local itemLink = GetInventoryItemLink(unit, slotID)
        if itemLink then
            local itemID = GetItemIDFromLink(itemLink)
            if itemID and ZGC_TIER_SET_ITEMS[itemID] then
                count = count + 1
            end
        end
    end
    return count
end

-- Devuelve el multiplicador de score según piezas tier equipadas.
function ZGC_GetTierMultiplier(unit, specID)
    local tierCount = ZGC_CountTierPieces(unit)
    if tierCount < 2 then return 1.0 end

    local weights = specID and ZGC_StatWeights and ZGC_StatWeights[specID]
    local bonus2pc = (weights and weights.tierBonus2pc) or 1.05
    local bonus4pc = (weights and weights.tierBonus4pc) or 1.12

    if tierCount >= 4 then
        return bonus4pc
    else
        return bonus2pc
    end
end
