-- Scoring.lua — ZinaGearCompare
-- Motor de scoring independiente. No depende de Pawn.
-- Usa C_Item.GetItemStats() (reemplaza al global GetItemStats eliminado en 11.0.2).

local EQUIP_SLOTS = {1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17}
-- Head(1), Neck(2), Shoulder(3), Chest(5), Waist(6), Legs(7),
-- Feet(8), Wrist(9), Hands(10), Finger1(11), Finger2(12),
-- Trinket1(13), Trinket2(14), Back(15), MainHand(16), OffHand(17)
ZGC_EQUIP_SLOT_COUNT = #EQUIP_SLOTS

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
        return "C_Item.GetItemStats NO EXISTE"
    end
    local stats = C_Item.GetItemStats(itemLink)
    if not stats then
        return "directo=NIL — intentando scan tooltip…"
    end
    local count = 0
    local sample = {}
    for k, v in pairs(stats) do
        count = count + 1
        if count <= 6 then
            sample[#sample + 1] = string.format("%s=%s", tostring(k), tostring(v))
        end
    end
    if count == 0 then return "tabla VACÍA" end
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
function ZGC_ScoreItem(itemLink, weights, primaryStatToken)
    if not itemLink or not weights then return nil end

    local statsTable = GetStatsForLink(itemLink)
    if not statsTable then return nil end

    local score = 0
    local primaryScored = false

    for statToken, statAmount in pairs(statsTable) do
        if statAmount and statAmount > 0 then
            local weightKey = STAT_MAP[statToken]
            if weightKey == "primary" then
                -- Puntuar si es exactamente la primary esperada, o un hybrid (AGI+STR, tri-stat)
                if statToken == primaryStatToken
                   or statToken == "ITEM_MOD_AGILITY_STRENGTH_SHORT"
                   or statToken == "ITEM_MOD_AGI_STR_INT_SHORT" then
                    score = score + statAmount * (weights.primary or 1.0)
                    primaryScored = true
                end
            elseif weightKey and weights[weightKey] then
                score = score + statAmount * weights[weightKey]
            end
        end
    end

    -- Fallback cross-class: si la primary esperada no apareció (la API devolvió la del
    -- viewer en vez de la del inspeccionado), aceptar cualquier primary stat presente.
    -- El presupuesto de stat es idéntico para STR/AGI/INT al mismo ilvl.
    if not primaryScored then
        for statToken, statAmount in pairs(statsTable) do
            if statAmount and statAmount > 0 and PRIMARY_STAT_TOKENS[statToken] then
                score = score + statAmount * (weights.primary or 1.0)
                break  -- solo una primary stat por item
            end
        end
    end

    return score > 0 and score or nil
end

-- ── Score completo de equipo para una unit ───────────────────────────────────

-- Retorna: totalScore (number), slotsScored (number), avgScore (number|nil)
function ZGC_GetWeightedScore(unit, specID, contentType)
    if not specID then return 0, 0, nil end

    local specWeights = ZGC_StatWeights and ZGC_StatWeights[specID]
    if not specWeights then return 0, 0, nil end

    local ct = contentType or ZGC_GetContentType()
    local weights = specWeights[ct] or specWeights.dungeon
    local primaryToken = specWeights.primaryStat or "ITEM_MOD_AGILITY_SHORT"

    local totalScore = 0
    local slotsScored = 0

    for _, slotID in ipairs(EQUIP_SLOTS) do
        local itemLink = GetInventoryItemLink(unit, slotID)
        if itemLink then
            local score = ZGC_ScoreItem(itemLink, weights, primaryToken)
            if score and score > 0 then
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
    return totalScore, slotsScored, avgScore
end
