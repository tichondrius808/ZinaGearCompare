-- ZinaContentDetector.lua — ZinaGearCompare
-- Auto-detección del tipo de contenido (dungeon vs raid) para elegir pesos de stats.

-- ── Auto-detección ────────────────────────────────────────────────────────────

-- Detecta el tipo de contenido actual sin tener en cuenta overrides.
-- Retorna "dungeon" o "raid".
function ZGC_DetectContentType()
    -- 1. M+ activa
    if C_ChallengeMode and C_ChallengeMode.GetActiveChallengeMapID then
        if (C_ChallengeMode.GetActiveChallengeMapID() or 0) > 0 then
            return "dungeon"
        end
    end

    -- 2. Dentro de instancia
    local inInstance, instanceType = IsInInstance()
    if inInstance then
        if instanceType == "raid" then
            return "raid"
        end
        -- party, scenario, arena, pvp → dungeon
        return "dungeon"
    end

    -- 3. En grupo de raid (LFR, raid normal, etc.)
    if IsInRaid and IsInRaid() then
        return "raid"
    end

    -- 4. En grupo pequeño
    if IsInGroup and IsInGroup() then
        local groupSize = 0
        for i = 1, 4 do
            if UnitExists("party" .. i) then
                groupSize = groupSize + 1
            end
        end
        if groupSize <= 4 then
            return "dungeon"
        end
        return "raid"
    end

    -- 5. Default
    return "dungeon"
end

-- Devuelve el tipo de contenido efectivo.
-- Si el usuario ha configurado un override manual en ZinaGearCompareDB.contentOverride,
-- lo respeta. Si no, auto-detecta.
function ZGC_GetContentType()
    if ZinaGearCompareDB and ZinaGearCompareDB.contentOverride then
        return ZinaGearCompareDB.contentOverride
    end
    return ZGC_DetectContentType()
end

-- Devuelve una cadena legible del tipo de contenido para mostrar en UI.
-- auto=true indica que es auto-detectado (no override manual).
function ZGC_GetContentTypeLabel()
    local override = ZinaGearCompareDB and ZinaGearCompareDB.contentOverride
    local contentType = ZGC_GetContentType()
    local label = contentType == "raid" and "Raid" or "M+"
    if override then
        return "[" .. label .. "]"
    else
        return "[Auto: " .. label .. "]"
    end
end
