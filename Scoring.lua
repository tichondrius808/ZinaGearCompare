-- Scoring.lua — ZinaGearCompare
-- Motor de scoring independiente. No depende de Pawn.
-- Usa C_Item.GetItemStats() (reemplaza al global GetItemStats eliminado en 11.0.2).

local EQUIP_SLOTS = {1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17}
-- Head(1), Neck(2), Shoulder(3), Chest(5), Waist(6), Legs(7),
-- Feet(8), Wrist(9), Hands(10), Finger1(11), Finger2(12),
-- Trinket1(13), Trinket2(14), Back(15), MainHand(16), OffHand(17)
ZGC_EQUIP_SLOT_COUNT = #EQUIP_SLOTS

-- ── Weapon slots ──────────────────────────────────────────────────────────────
local WEAPON_SLOTS = { [16] = true, [17] = true }

-- Weapon ilvl bonus: scales so a 289-ilvl weapon gets ~723 points
-- (comparable to primary stat contribution of a good armor piece)
local WEAPON_ILVL_FACTOR = 2.5

-- ── Diminishing Returns constants (Midnight 12.0.1) ──────────────────────────
-- Rating required for 1% at level 80
local RATING_PER_PCT = {
    crit        = 46,
    haste       = 44,
    mastery     = 46,
    versatility = 54,
}

-- DR brackets: each entry = {max_pct_in_bracket, multiplier}
local DR_BRACKETS = {
    { 30,  1.00 },  -- 0-30%: no penalty
    { 39,  0.90 },  -- 30-39%: 10% penalty
    { 47,  0.80 },  -- 39-47%: 20% penalty
    { 54,  0.70 },  -- 47-54%: 30% penalty
    { 66,  0.60 },  -- 54-66%: 40% penalty
    { 126, 0.50 },  -- 66-126%: 50% penalty
    -- 126%+: hard cap (0%)
}

-- Returns effective rating after applying WoW's DR curve
local function ApplyDR(rawRating, statKey)
    local rpp = RATING_PER_PCT[statKey]
    if not rpp or rpp <= 0 then return rawRating end

    local rawPct = rawRating / rpp
    local effectivePct = 0
    local remaining = rawPct
    local prevCap = 0

    for _, bracket in ipairs(DR_BRACKETS) do
        local band = math.min(remaining, bracket[1] - prevCap)
        if band <= 0 then break end
        effectivePct = effectivePct + band * bracket[2]
        remaining = remaining - band
        prevCap = bracket[1]
    end

    return effectivePct * rpp
end

-- ── Mapa de stats → claves de pesos ─────────────────────────────────────────
-- C_Item.GetItemStats() devuelve claves string tipo "ITEM_MOD_*_SHORT".
local STAT_MAP = {
    ITEM_MOD_STRENGTH_SHORT          = "primary",
    ITEM_MOD_AGILITY_SHORT           = "primary",
    ITEM_MOD_INTELLECT_SHORT         = "primary",
    ITEM_MOD_AGILITY_STRENGTH_SHORT  = "primary",  -- hybrid AGI+STR
    ITEM_MOD_AGI_STR_INT_SHORT       = "primary",  -- tri-stat
    ITEM_MOD_CRIT_RATING_SHORT       = "crit",
    ITEM_MOD_HASTE_RATING_SHORT      = "haste",
    ITEM_MOD_MASTERY_RATING_SHORT    = "mastery",
    ITEM_MOD_VERSATILITY             = "versatility",
    ITEM_MOD_VERSATILITY_SHORT       = "versatility",
}

-- Claves que representan una primary stat (STR/AGI/INT/hybrids)
local PRIMARY_STAT_TOKENS = {
    ["ITEM_MOD_STRENGTH_SHORT"]         = true,
    ["ITEM_MOD_AGILITY_SHORT"]          = true,
    ["ITEM_MOD_INTELLECT_SHORT"]        = true,
    ["ITEM_MOD_AGILITY_STRENGTH_SHORT"] = true,
    ["ITEM_MOD_AGI_STR_INT_SHORT"]      = true,
}

-- ── Scan tooltip oculto (fuerza carga de datos de item en caché) ─────────────
-- C_Item.GetItemStats devuelve nil si el item no está en la caché del cliente.
-- Los items del propio jugador siempre están en caché; los de jugadores inspeccionados
-- a veces no. Renderizar el item en un tooltip oculto fuerza la carga completa.
-- Técnica estándar usada por Pawn y otros addons de gear scoring.
local ZGCScanTooltip = nil

local function GetScanTooltip()
    if ZGCScanTooltip then return ZGCScanTooltip end
    ZGCScanTooltip = CreateFrame("GameTooltip", "ZGCScanTooltip", nil, "GameTooltipTemplate")
    ZGCScanTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
    return ZGCScanTooltip
end

-- Obtiene la tabla de stats para un itemLink.
-- Intenta C_Item.GetItemStats directo; si falla o devuelve vacío, usa el scan
-- tooltip para forzar el cacheo y reintenta.
local function GetStatsForLink(itemLink)
    if not itemLink then return nil end
    if not C_Item or not C_Item.GetItemStats then return nil end

    local stats = C_Item.GetItemStats(itemLink)
    if stats and next(stats) then return stats end

    -- Fallback: forzar carga del item via tooltip oculto y reintentar
    local tt = GetScanTooltip()
    if tt then
        pcall(function()
            tt:SetHyperlink(itemLink)
            tt:Hide()
        end)
        stats = C_Item.GetItemStats(itemLink)
    end

    return (stats and next(stats)) and stats or nil
end

-- ── Diagnóstico ───────────────────────────────────────────────────────────────

function ZGC_DiagnoseStatKeys(itemLink)
    if not C_Item or not C_Item.GetItemStats then
        return "C_Item.GetItemStats DOES NOT EXIST"
    end
    local stats = C_Item.GetItemStats(itemLink)
    if not stats then
        return "direct=NIL — trying scan tooltip..."
    end
    local count = 0
    local sample = {}
    for k, v in pairs(stats) do
        count = count + 1
        if count <= 6 then
            sample[#sample + 1] = string.format("%s=%s", tostring(k), tostring(v))
        end
    end
    if count == 0 then return "table EMPTY" end
    return string.format("OK · %d stats · %s", count, table.concat(sample, ", "))
end

-- ── Obtener specID / nombre de spec ──────────────────────────────────────────

function ZGC_GetSpecIDForUnit(unit)
    if UnitIsUnit(unit, "player") then
        local specIndex = GetSpecialization and GetSpecialization()
        if specIndex and GetSpecializationInfo then
            return select(1, GetSpecializationInfo(specIndex))
        end
        return nil
    else
        local specID = GetInspectSpecialization and GetInspectSpecialization(unit)
        if specID and specID > 0 then return specID end
        return nil
    end
end

function ZGC_GetSpecNameForUnit(unit)
    if UnitIsUnit(unit, "player") then
        local specIndex = GetSpecialization and GetSpecialization()
        if specIndex and GetSpecializationInfo then
            return select(2, GetSpecializationInfo(specIndex))
        end
    else
        local specID = GetInspectSpecialization and GetInspectSpecialization(unit)
        if specID and specID > 0 and GetSpecializationInfoByID then
            return select(2, GetSpecializationInfoByID(specID))
        end
    end
    return nil
end

-- ── Score de un item individual ──────────────────────────────────────────────

-- Calcula el score de un itemLink para los pesos dados.
-- primaryStatToken: token ITEM_MOD_*_SHORT esperado para la spec (e.g. "ITEM_MOD_AGILITY_SHORT").
--
-- Problema con jugadores inspeccionados cross-class:
-- WoW determina la primary stat mostrada según la spec del VIEWER, no la del inspeccionado.
-- Si el viewer es INT y el inspeccionado es STR, C_Item.GetItemStats puede devolver INT
-- en vez de STR. Ambas tienen el mismo presupuesto de stat por ilvl, así que si la primary
-- esperada no aparece, se acepta CUALQUIER primary stat presente (misma magnitud).
--
-- Retorna número > 0, o nil si GetStatsForLink falla.
-- drFactors: optional table {crit=0.97, haste=0.85, ...} — DR efficiency per stat.
-- When nil, no DR penalty is applied (backward-compatible for diag/standalone calls).
function ZGC_ScoreItem(itemLink, weights, primaryStatToken, drFactors)
    if not itemLink or not weights then return nil end

    local statsTable = GetStatsForLink(itemLink)
    if not statsTable then return nil end

    local score = 0
    local primaryScored = false

    for statToken, statAmount in pairs(statsTable) do
        if statAmount and statAmount > 0 then
            local weightKey = STAT_MAP[statToken]
            if weightKey == "primary" then
                if statToken == primaryStatToken
                   or statToken == "ITEM_MOD_AGILITY_STRENGTH_SHORT"
                   or statToken == "ITEM_MOD_AGI_STR_INT_SHORT" then
                    score = score + statAmount * (weights.primary or 1.0)
                    primaryScored = true
                end
            elseif weightKey and weights[weightKey] then
                local dr = (drFactors and drFactors[weightKey]) or 1.0
                score = score + statAmount * dr * weights[weightKey]
            end
        end
    end

    -- Fallback cross-class: accept any primary stat if the expected one wasn't found
    if not primaryScored then
        for statToken, statAmount in pairs(statsTable) do
            if statAmount and statAmount > 0 and PRIMARY_STAT_TOKENS[statToken] then
                score = score + statAmount * (weights.primary or 1.0)
                break
            end
        end
    end

    return score > 0 and score or nil
end

-- ── Score completo de equipo para una unit ───────────────────────────────────

-- Retorna: totalScore (number), slotsScored (number), avgScore (number|nil), drFactors (table|nil)
function ZGC_GetWeightedScore(unit, specID, contentType)
    if not specID then return 0, 0, nil, nil end

    local specWeights = ZGC_StatWeights and ZGC_StatWeights[specID]
    if not specWeights then return 0, 0, nil, nil end

    local ct = contentType or ZGC_GetContentType()
    local weights = specWeights[ct] or specWeights.dungeon
    local primaryToken = specWeights.primaryStat or "ITEM_MOD_AGILITY_SHORT"

    -- ── Pass 1: collect item links and sum total secondary ratings ──────
    local slotLinks = {}
    local totalRatings = { crit = 0, haste = 0, mastery = 0, versatility = 0 }

    for _, slotID in ipairs(EQUIP_SLOTS) do
        local itemLink = GetInventoryItemLink(unit, slotID)
        if itemLink then
            slotLinks[slotID] = itemLink
            local statsTable = GetStatsForLink(itemLink)
            if statsTable then
                for statToken, statAmount in pairs(statsTable) do
                    if statAmount and statAmount > 0 then
                        local weightKey = STAT_MAP[statToken]
                        if weightKey and weightKey ~= "primary" then
                            totalRatings[weightKey] = (totalRatings[weightKey] or 0) + statAmount
                        end
                    end
                end
            end
        end
    end

    -- ── Compute DR efficiency factors ──────────────────────────────────
    local drFactors = {}
    for stat, total in pairs(totalRatings) do
        if total > 0 then
            drFactors[stat] = ApplyDR(total, stat) / total
        else
            drFactors[stat] = 1.0
        end
    end

    -- ── Pass 2: score each item with DR factors + weapon ilvl bonus ────
    local totalScore = 0
    local slotsScored = 0

    for _, slotID in ipairs(EQUIP_SLOTS) do
        local itemLink = slotLinks[slotID]
        if itemLink then
            local score = ZGC_ScoreItem(itemLink, weights, primaryToken, drFactors)
            if score and score > 0 then
                -- Weapon ilvl bonus
                if WEAPON_SLOTS[slotID] then
                    local ilvl = GetDetailedItemLevelInfo and GetDetailedItemLevelInfo(itemLink) or 0
                    if ilvl and ilvl > 0 then
                        score = score + (ilvl * WEAPON_ILVL_FACTOR)
                    end
                end
                totalScore = totalScore + score
                slotsScored = slotsScored + 1
            end
        end
    end

    -- Aplicar multiplicador de tier set
    if slotsScored > 0 then
        local tierMult = ZGC_GetTierMultiplier(unit, specID)
        totalScore = totalScore * tierMult
    end

    local avgScore = (slotsScored > 0) and (totalScore / slotsScored) or nil
    return totalScore, slotsScored, avgScore, drFactors
end
