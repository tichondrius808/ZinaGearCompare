-- Scoring.lua — ZinaGearCompare
-- Calcula WeightedScore de equipo usando Pawn como backend de valoración

local EQUIP_SLOTS = {1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17}
-- Slots: Head(1), Neck(2), Shoulder(3), Chest(5), Waist(6), Legs(7),
--        Feet(8), Wrist(9), Hands(10), Finger1(11), Finger2(12),
--        Trinket1(13), Trinket2(14), Back(15), MainHand(16), OffHand(17)

-- Mapa especID → nombre parcial de scale de Pawn (coincidencia insensible a mayúsculas)
local SPEC_TO_SCALE_HINT = {
    -- Death Knight
    [250] = "Blood",
    [251] = "Frost Death Knight",
    [252] = "Unholy",
    -- Demon Hunter
    [577] = "Havoc",
    [581] = "Vengeance",
    -- Druid
    [102] = "Balance",
    [103] = "Feral",
    [104] = "Guardian",
    [105] = "Restoration Druid",
    -- Evoker
    [1467] = "Devastation",
    [1468] = "Preservation",
    [1473] = "Augmentation",
    -- Hunter
    [253] = "Beast Mastery",
    [254] = "Marksmanship",
    [255] = "Survival",
    -- Mage
    [62]  = "Arcane",
    [63]  = "Fire",
    [64]  = "Frost Mage",
    -- Monk
    [268] = "Brewmaster",
    [270] = "Mistweaver",
    [269] = "Windwalker",
    -- Paladin
    [65]  = "Holy Paladin",
    [66]  = "Protection Paladin",
    [70]  = "Retribution",
    -- Priest
    [256] = "Discipline",
    [257] = "Holy Priest",
    [258] = "Shadow",
    -- Rogue
    [259] = "Assassination",
    [260] = "Outlaw",
    [261] = "Subtlety",
    -- Shaman
    [262] = "Elemental",
    [263] = "Enhancement",
    [264] = "Restoration Shaman",
    -- Warlock
    [265] = "Affliction",
    [266] = "Demonology",
    [267] = "Destruction",
    -- Warrior
    [71]  = "Arms",
    [72]  = "Fury",
    [73]  = "Protection Warrior",
}

-- Devuelve el score Pawn de un itemLink para un scale dado.
-- PawnGetSingleValueFromItem requiere un Item TABLE (parseado con PawnGetItemData),
-- NO un itemLink crudo. Pasarle un string causa error de Lua (string.Stats = nil).
local function GetPawnScore(scaleName, itemLink)
    if not PawnGetSingleValueFromItem or not PawnGetItemData then return nil end
    if not itemLink then return nil end
    local itemData = PawnGetItemData(itemLink)
    if not itemData then return nil end
    local value, _ = PawnGetSingleValueFromItem(itemData, scaleName)
    return (value and value > 0) and value or nil
end

-- Devuelve solo los scales creados manualmente por el usuario (sin Provider).
-- Los scales de addons como Ask Mr. Robot tienen Provider != nil y se excluyen.
function ZGC_GetCustomScales()
    local scales = {}
    if not (PawnCommon and PawnCommon.Scales) then return scales end
    for scaleName, scale in pairs(PawnCommon.Scales) do
        if not scale.Provider then
            scales[scaleName] = true
        end
    end
    return scales
end

-- Devuelve todos los scales activos (custom + providers activos). Usado internamente.
function ZGC_GetAvailableScales()
    local scales = {}
    if not (PawnCommon and PawnCommon.Scales) then return scales end
    for scaleName, scale in pairs(PawnCommon.Scales) do
        if not scale.Provider or scale.ProviderActive then
            scales[scaleName] = true
        end
    end
    return scales
end

-- Autodetecta el scale custom más apropiado para una unit.
-- Busca SOLO entre los scales del usuario (sin Provider).
-- Retorna scaleName (string) o nil si no hay ninguno compatible.
function ZGC_GetBestScaleForUnit(unit)
    local specID, classID

    if UnitIsUnit(unit, "player") then
        -- GetSpecialization() devuelve 1-4 (índice local); necesitamos el specID global
        local specIndex = GetSpecialization and GetSpecialization()
        if specIndex and GetSpecializationInfo then
            specID = select(1, GetSpecializationInfo(specIndex))
        end
        classID = select(3, UnitClass("player"))
    else
        -- GetInspectSpecialization ya devuelve el specID global
        specID  = GetInspectSpecialization and GetInspectSpecialization(unit)
        classID = select(3, UnitClass(unit))
    end

    if not specID or specID == 0 then return nil end

    local custom = ZGC_GetCustomScales()

    -- 1) PawnFindScaleForSpec solo si el resultado es un scale custom del usuario
    if PawnFindScaleForSpec and classID then
        local pawnScale = PawnFindScaleForSpec(classID, specID)
        if pawnScale and custom[pawnScale] then return pawnScale end
    end

    -- 2) Buscar por hint de nombre (substring, case-insensitive) solo en custom scales
    local hint = SPEC_TO_SCALE_HINT[specID]
    if not hint then return nil end

    local hintLower = hint:lower()

    -- Búsqueda exacta primero
    for name in pairs(custom) do
        if name:lower() == hintLower then return name end
    end
    -- El scale contiene el hint (ej. scale="Fire Mage" hint="Fire")
    for name in pairs(custom) do
        if name:lower():find(hintLower, 1, true) then return name end
    end
    -- El hint contiene el nombre del scale (ej. scale="Fire" hint="Frost Mage")
    for name in pairs(custom) do
        if hintLower:find(name:lower(), 1, true) then return name end
    end

    return nil
end

-- Calcula el WeightedScore de una unit para un scale de Pawn dado.
-- Retorna: totalScore (number), slotsScored (number), avgScore (number|nil)
function ZGC_GetWeightedScore(unit, scaleName)
    if not scaleName then return 0, 0, nil end

    local totalScore = 0
    local slotsScored = 0

    for _, slotID in ipairs(EQUIP_SLOTS) do
        local itemLink = GetInventoryItemLink(unit, slotID)
        if itemLink then
            local score = GetPawnScore(scaleName, itemLink)
            if score and score > 0 then
                totalScore = totalScore + score
                slotsScored = slotsScored + 1
            end
        end
    end

    local avgScore = (slotsScored > 0) and (totalScore / slotsScored) or nil
    return totalScore, slotsScored, avgScore
end

-- Calcula el score del propio personaje del jugador.
function ZGC_GetMyScore(scaleName)
    return ZGC_GetWeightedScore("player", scaleName)
end
