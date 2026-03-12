-- ZinaGearCompare.lua — Entry point del addon
-- Motor independiente de Pawn. Requiere ZinaStatWeights, ZinaTierSets, ZinaContentDetector.

local ADDON_NAME = "ZinaGearCompare"

-- ── SavedVariables por defecto ───────────────────────────────────────────────
local DB_DEFAULTS = {
    version         = 2,
    contentOverride = nil,  -- nil = auto-detect | "dungeon" | "raid"
}

-- ── Frame de eventos ─────────────────────────────────────────────────────────
local eventFrame = CreateFrame("Frame", ADDON_NAME .. "EventFrame")

-- ── PaperDoll score text ──────────────────────────────────────────────────────
local zgcPaperDollText = nil

local function GetPlayerScore()
    local specID      = ZGC_GetSpecIDForUnit("player")
    local specName    = ZGC_GetSpecNameForUnit("player")
    local contentType = ZGC_GetContentType()
    local total, slots = ZGC_GetWeightedScore("player", specID, contentType)
    return specID, specName, total, slots, contentType
end

local function UpdatePaperDollScore()
    if not zgcPaperDollText then return end
    local specID, specName, total, slots, contentType = GetPlayerScore()
    if not specID then
        zgcPaperDollText:SetText("|cffaaaaaa[ZGC] spec desconocida|r")
        return
    end
    if total and total > 0 then
        local label = contentType == "raid" and "Raid" or "M+"
        zgcPaperDollText:SetText(string.format(
            "|cff00aaffZGC Score:|r |cffffd700%.0f|r  |cffaaaaaa[%s · %s · %d slots]|r",
            total, specName or "?", label, slots))
    else
        zgcPaperDollText:SetText("|cffaaaaaaZGC: calculando…|r")
    end
end

local function InitPaperDoll()
    if zgcPaperDollText then return end
    if not CharacterFrame then return end
    local ok, err = pcall(function()
        zgcPaperDollText = CharacterFrame:CreateFontString(
            "ZGCPaperDollText", "OVERLAY", "GameFontNormalSmall")
        zgcPaperDollText:SetPoint("BOTTOM", CharacterFrame, "BOTTOM", 0, 28)
        zgcPaperDollText:SetWidth(300)
        zgcPaperDollText:SetJustifyH("CENTER")
        zgcPaperDollText:SetText("")
        hooksecurefunc(CharacterFrame, "Show", UpdatePaperDollScore)
    end)
    if not ok then
        print("|cffff8800[ZinaGearCompare]|r PaperDoll hook falló:", err)
        zgcPaperDollText = nil
    end
end

-- ── Fórmula de paridad de skill ───────────────────────────────────────────────
-- gearRatio = score_ellos / score_yo
-- Devuelve el % de su daño que debes hacer tú para ser igual de hábil.
local function ZGC_SkillParity(gearRatio)
    if not gearRatio or gearRatio <= 0 then return nil end
    return ((1 / gearRatio) ^ 2.0) * 100
end

-- ── Mouseover inspection cache ────────────────────────────────────────────────
local zgcMouseoverName      = nil
local zgcMouseoverRealm     = nil
local zgcMouseoverScore     = nil
local zgcMouseoverSpecName  = nil   -- nombre de spec para display (reemplaza scale name)
local zgcMouseoverGearRatio = nil
local zgcMouseoverReady     = false
local zgcMouseoverPending   = false
local zgcMouseoverWaiting   = false
local zgcPrintPending       = false

local function ZGC_GetMouseoverNameRealm()
    local n, r = UnitName("mouseover")
    if not r or r == "" then r = GetRealmName() end
    return n, r
end

-- ── Helper: inyectar score ZGC en GameTooltip ─────────────────────────────────
local function ZGC_InjectMouseoverTooltip()
    if not GameTooltip:IsVisible() then return end
    if not UnitIsPlayer("mouseover") then return end
    local tn, tr = ZGC_GetMouseoverNameRealm()
    if tn ~= zgcMouseoverName or tr ~= zgcMouseoverRealm then return end
    if GameTooltip.zgcScoreAdded then return end
    GameTooltip.zgcScoreAdded = true
    if zgcMouseoverScore and zgcMouseoverSpecName then
        local parityStr = ""
        local parity = ZGC_SkillParity(zgcMouseoverGearRatio)
        if parity then
            local col = parity <= 80 and "|cffff4444" or parity <= 100 and "|cffffd700" or "|cff00ff00"
            parityStr = string.format("  %sskill≥%.0f%%|r", col, parity)
        end
        GameTooltip:AddLine(string.format("|cff00aaffZGC:|r |cffffd700%.0f|r |cffaaaaaa(%s)|r%s",
            zgcMouseoverScore, zgcMouseoverSpecName, parityStr))
        GameTooltip:Show()
    end
end

local function ZGC_TryMouseoverInspect()
    zgcMouseoverWaiting = false
    if not UnitIsPlayer("mouseover") then return end
    if InspectFrame and InspectFrame:IsShown() then return end
    if zgcMouseoverPending then return end
    local n, r = ZGC_GetMouseoverNameRealm()
    if n == zgcMouseoverName and r == zgcMouseoverRealm then return end
    zgcMouseoverName      = nil
    zgcMouseoverRealm     = nil
    zgcMouseoverScore     = nil
    zgcMouseoverSpecName  = nil
    zgcMouseoverGearRatio = nil
    zgcMouseoverReady     = false
    zgcMouseoverPending   = true
    NotifyInspect("mouseover")
    C_Timer.After(5, function()
        if zgcMouseoverPending then
            zgcMouseoverPending = false
        end
    end)
end

local function ZGC_CheckMouseover()
    if zgcMouseoverWaiting or zgcMouseoverPending then return end
    if not UnitIsPlayer("mouseover") then return end
    local n, r = ZGC_GetMouseoverNameRealm()
    if n == zgcMouseoverName and r == zgcMouseoverRealm then return end
    zgcMouseoverReady     = false
    zgcMouseoverScore     = nil
    zgcMouseoverSpecName  = nil
    zgcMouseoverGearRatio = nil
    zgcMouseoverWaiting   = true
    C_Timer.After(0.1, ZGC_TryMouseoverInspect)
end

-- ── GameTooltip hook ──────────────────────────────────────────────────────────
local function HookGameTooltip()
    if not TooltipDataProcessor then return end
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip, data)
        if not data or not data.guid then return end

        -- Propio jugador
        if data.guid == UnitGUID("player") then
            local _, specName, total, _, contentType = GetPlayerScore()
            if specName and total and total > 0 then
                local label = contentType == "raid" and "Raid" or "M+"
                tooltip:AddLine(string.format("|cff00aaffZGC:|r |cffffd700%.0f|r |cffaaaaaa(%s · %s)|r",
                    total, specName, label))
            end
            tooltip:Show()
            return
        end

        -- Otro jugador: mostrar score cacheado
        if not UnitIsPlayer("mouseover") then return end
        if not zgcMouseoverReady then return end
        local n, r = ZGC_GetMouseoverNameRealm()
        if n ~= zgcMouseoverName or r ~= zgcMouseoverRealm then return end
        tooltip.zgcScoreAdded = true
        if zgcMouseoverScore and zgcMouseoverSpecName then
            local parityStr = ""
            local parity = ZGC_SkillParity(zgcMouseoverGearRatio)
            if parity then
                local col = parity <= 80 and "|cffff4444" or parity <= 100 and "|cffffd700" or "|cff00ff00"
                parityStr = string.format("  %sskill≥%.0f%%|r", col, parity)
            end
            tooltip:AddLine(string.format("|cff00aaffZGC:|r |cffffd700%.0f|r |cffaaaaaa(%s)|r%s",
                zgcMouseoverScore, zgcMouseoverSpecName, parityStr))
            tooltip:Show()
        end
    end)
end
GameTooltip:HookScript("OnTooltipCleared", function(self)
    self.zgcScoreAdded = false
end)
GameTooltip:HookScript("OnHide", function(self)
    self.zgcScoreAdded = false
end)

-- ── Integración con Details! ──────────────────────────────────────────────────
local function ZGC_GetDetailsComparison(myName, targetName)
    if not _G.Details then return nil end

    local function findBothInCombat(combat)
        if not combat then return nil end
        local myActor    = combat:GetActor(DETAILS_ATTRIBUTE_DAMAGE, myName)
        local theirActor = combat:GetActor(DETAILS_ATTRIBUTE_DAMAGE, targetName)
        if not myActor or not theirActor then
            local container = combat:GetContainer(DETAILS_ATTRIBUTE_DAMAGE)
            if not container then return nil end
            for _, actor in container:ListActors() do
                if actor:IsPlayer() then
                    local n = actor:GetOnlyName()
                    if not myActor    and n == myName    then myActor    = actor end
                    if not theirActor and n == targetName then theirActor = actor end
                end
            end
        end
        if not myActor or not theirActor then return nil end
        local combatTime = combat:GetCombatTime()
        if not combatTime or combatTime <= 0 then return nil end
        return {
            myDmg      = myActor.total    or 0,
            theirDmg   = theirActor.total or 0,
            combatTime = combatTime,
            segName    = combat:GetCombatName(true) or "segmento desconocido",
        }
    end

    return findBothInCombat(Details:GetCombat(0))
        or findBothInCombat(Details:GetCombat(1))
end

-- ── ADDON_LOADED ─────────────────────────────────────────────────────────────
local function OnAddonLoaded(addonName)
    if addonName ~= ADDON_NAME then return end

    if not ZinaGearCompareDB then
        ZinaGearCompareDB = {}
    end
    for k, v in pairs(DB_DEFAULTS) do
        if ZinaGearCompareDB[k] == nil then
            ZinaGearCompareDB[k] = v
        end
    end

    ZGC_InitUI()
    InitPaperDoll()
    pcall(HookGameTooltip)

    local specID   = ZGC_GetSpecIDForUnit("player")
    local specName = ZGC_GetSpecNameForUnit("player") or "desconocida"
    if specID and ZGC_StatWeights and ZGC_StatWeights[specID] then
        print(string.format("|cff00aaff[ZinaGearCompare]|r cargado. Spec: %s. " ..
              "Abre el personaje o inspecciona a alguien para ver Gear Quality.",
              specName))
    else
        print("|cff00aaff[ZinaGearCompare]|r cargado. " ..
              "(Spec no detectada aún — abre el panel de personaje para actualizar.)")
    end
end

-- ── INSPECT_READY ─────────────────────────────────────────────────────────────
local pendingUnit = nil

local function OnInspectReady(unit)
    local target = unit or pendingUnit
    if not target then return end
    if InspectFrame and InspectFrame:IsShown() then
        ZGC_OnInspectReady(target)
    end
end

-- ── PLAYER_EQUIPMENT_CHANGED ─────────────────────────────────────────────────
local function OnPlayerEquipmentChanged()
    if InspectFrame and InspectFrame:IsShown() then
        ZGC_UpdatePanel()
    end
    UpdatePaperDollScore()
end

-- ── Dispatcher de eventos ─────────────────────────────────────────────────────
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        OnAddonLoaded(...)

    elseif event == "INSPECT_READY" then
        local guid = ...
        local unit = nil
        for _, u in ipairs({"target", "mouseover", "focus", "party1", "party2", "party3", "party4"}) do
            if UnitGUID(u) == guid then
                unit = u
                break
            end
        end
        pendingUnit = unit or pendingUnit
        OnInspectReady(unit or pendingUnit)

        -- Path de mouseover
        if zgcMouseoverPending then
            zgcMouseoverPending = false
            if UnitIsPlayer("mouseover") and UnitGUID("mouseover") == guid then
                local n, r = ZGC_GetMouseoverNameRealm()
                zgcMouseoverName  = n
                zgcMouseoverRealm = r
                local specID      = ZGC_GetSpecIDForUnit("mouseover")
                local specName    = ZGC_GetSpecNameForUnit("mouseover")
                local contentType = ZGC_GetContentType()
                if specID then
                    local total, slotsScored = ZGC_GetWeightedScore("mouseover", specID, contentType)
                    if total and total > 0 then
                        zgcMouseoverScore    = total
                        zgcMouseoverSpecName = specName
                        -- Ratio: comparar con misma spec/contentType del jugador local
                        local mySpecID   = ZGC_GetSpecIDForUnit("player")
                        local myTotal    = ZGC_GetWeightedScore("player", mySpecID, contentType)
                        if myTotal and myTotal > 0 then
                            zgcMouseoverGearRatio = total / myTotal
                        end
                    end
                    -- Retry si pocos slots
                    if slotsScored < 8 then
                        C_Timer.After(1.5, function()
                            if zgcMouseoverName ~= n then return end
                            if not UnitIsPlayer("mouseover") then return end
                            local retryTotal, retrySlotsScored = ZGC_GetWeightedScore("mouseover", specID, contentType)
                            if retryTotal and retryTotal > 0 and retrySlotsScored > slotsScored then
                                zgcMouseoverScore = retryTotal
                                local mySpecID2 = ZGC_GetSpecIDForUnit("player")
                                local myTotal2  = ZGC_GetWeightedScore("player", mySpecID2, contentType)
                                if myTotal2 and myTotal2 > 0 then
                                    zgcMouseoverGearRatio = retryTotal / myTotal2
                                end
                                ZGC_InjectMouseoverTooltip()
                            end
                        end)
                    end
                end
                zgcMouseoverReady = true
                ZGC_InjectMouseoverTooltip()
            end
        end

        -- Path de /zgc compare
        if zgcPrintPending then
            zgcPrintPending = false
            local cmpUnit = nil
            for _, u in ipairs({"target", "mouseover", "focus"}) do
                if UnitGUID(u) == guid then cmpUnit = u; break end
            end
            if cmpUnit then
                local name       = UnitName(cmpUnit) or "?"
                local specID     = ZGC_GetSpecIDForUnit(cmpUnit)
                local specName   = ZGC_GetSpecNameForUnit(cmpUnit)
                local cType      = ZGC_GetContentType()
                if not specID then
                    print(string.format("|cff00aaff[ZinaGearCompare]|r %s — |cffaaaaaa(spec desconocida, datos incompletos)|r", name))
                else
                    local total, slots = ZGC_GetWeightedScore(cmpUnit, specID, cType)
                    local mySpecID     = ZGC_GetSpecIDForUnit("player")
                    local mySpecName   = ZGC_GetSpecNameForUnit("player")
                    local myTotal, mySlots = ZGC_GetWeightedScore("player", mySpecID, cType)
                    if total and total > 0 then
                        local label = cType == "raid" and "Raid" or "M+"
                        print(string.format("|cff00aaff[ZinaGearCompare]|r %s — ZGC: |cffffd700%.0f|r |cffaaaaaa(%s · %s)|r",
                            name, total, specName or "?", label))
                        if myTotal and myTotal > 0 then
                            local gearRatio = total / myTotal
                            local parity    = ZGC_SkillParity(gearRatio)
                            print(string.format("  |cffaaaaaa  Mi score: %.0f (%s · %s)   Gear ratio: %.0f%%|r",
                                myTotal, mySpecName or "?", label, gearRatio * 100))
                            if parity then
                                local parityCol = gearRatio > 1 and "|cffffd700" or "|cff00ff00"
                                if gearRatio ~= 1 then
                                    print(string.format("  → Debes hacer el %s%.1f%%|r de su daño para igualar en skill.",
                                        parityCol, parity))
                                    if gearRatio > 1 then
                                        print(string.format("  |cffaaaaaa  (ellos tienen |r|cffffd700%.0f%%|r|cffaaaaaa más equipo que tú)|r",
                                            (gearRatio - 1) * 100))
                                    else
                                        print(string.format("  |cffaaaaaa  (tú tienes |r|cff00ff00%.0f%%|r|cffaaaaaa más equipo que ellos)|r",
                                            (1/gearRatio - 1) * 100))
                                    end
                                else
                                    print("  |cffaaaaaa→ Equipo equivalente. La diferencia es pura habilidad.|r")
                                end

                                local myPlayerName = UnitName("player")
                                local det = ZGC_GetDetailsComparison(myPlayerName, name)
                                if det and det.theirDmg > 0 then
                                    local actualRatio = (det.myDmg / det.theirDmg) * 100
                                    local delta_pp    = actualRatio - parity
                                    local relDelta    = (actualRatio / parity - 1) * 100
                                    local sign        = delta_pp >= 0 and "+" or ""
                                    local col         = delta_pp >= 0 and "|cff00ff00" or "|cffff4444"
                                    local arrow       = delta_pp >= 0 and "↑" or "↓"
                                    print(string.format("  |cffaaaaaa[Details! · %s]|r", det.segName))
                                    print(string.format("  |cffaaaaaa  Tu daño: %.0f   Su daño: %.0f|r",
                                        det.myDmg, det.theirDmg))
                                    print(string.format("  |cffaaaaaa  Ratio actual: %.1f%% de su daño   Esperado: %.1f%%|r",
                                        actualRatio, parity))
                                    print(string.format("  %s→ %s%.1fpp %s (%.1f%% %s lo esperado por equipo)|r",
                                        col, sign, delta_pp, arrow,
                                        math.abs(relDelta),
                                        delta_pp >= 0 and "sobre" or "bajo"))
                                elseif _G.Details then
                                    print("  |cffaaaaaa[Details!] No se encontraron datos de ambos jugadores en los segmentos recientes.|r")
                                end
                            end
                        end
                    else
                        print(string.format("|cff00aaff[ZinaGearCompare]|r %s — sin datos de equipo aún, vuelve a intentarlo.", name))
                    end
                end
            end
        end

    elseif event == "UPDATE_MOUSEOVER_UNIT" then
        ZGC_CheckMouseover()

    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        OnPlayerEquipmentChanged()

    elseif event == "PLAYER_TARGET_CHANGED" then
        if UnitExists("target") and UnitIsPlayer("target") then
            pendingUnit = "target"
        else
            pendingUnit = nil
        end

    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        UpdatePaperDollScore()
    end
end)

-- ── Registro de eventos ───────────────────────────────────────────────────────
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("INSPECT_READY")
eventFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

-- ── Slash commands ────────────────────────────────────────────────────────────
SLASH_ZINAGEARCOMPARE1 = "/zgc"
SlashCmdList["ZINAGEARCOMPARE"] = function(msg)
    msg = msg:lower():match("^%s*(.-)%s*$")

    if msg == "reset" then
        ZinaGearCompareDB = {}
        for k, v in pairs(DB_DEFAULTS) do ZinaGearCompareDB[k] = v end
        print("|cff00aaff[ZinaGearCompare]|r Base de datos reseteada.")

    elseif msg == "compare" then
        if not UnitIsPlayer("target") then
            print("|cffff8800[ZinaGearCompare]|r Necesitas tener seleccionado a un jugador.")
            return
        end
        local targetName = UnitName("target") or "?"
        print(string.format("|cff00aaff[ZinaGearCompare]|r Inspeccionando a %s…", targetName))
        zgcPrintPending = true
        NotifyInspect("target")

    elseif msg == "score" or msg == "myscore" then
        local specID, specName, total, slots, cType = GetPlayerScore()
        if not specID then
            print("|cffff8800[ZinaGearCompare]|r Spec no detectada. Abre el panel de personaje.")
            return
        end
        local label = cType == "raid" and "Raid" or "M+"
        local tierCount = ZGC_CountTierPieces and ZGC_CountTierPieces("player") or 0
        print(string.format(
            "|cff00aaff[ZinaGearCompare]|r Mi score: |cffffd700%.0f|r | %d slots | %s | %s | Tier: %dpc",
            total, slots, specName or "?", label, tierCount))

    elseif msg:match("^mode%s+") then
        local mode = msg:match("^mode%s+(%S+)")
        if mode == "auto" then
            ZinaGearCompareDB.contentOverride = nil
            print("|cff00aaff[ZinaGearCompare]|r Modo: |cffaaaaaaauto-detección|r")
        elseif mode == "dungeon" or mode == "m+" then
            ZinaGearCompareDB.contentOverride = "dungeon"
            print("|cff00aaff[ZinaGearCompare]|r Modo forzado: |cffaad4ffM+|r")
        elseif mode == "raid" then
            ZinaGearCompareDB.contentOverride = "raid"
            print("|cff00aaff[ZinaGearCompare]|r Modo forzado: |cffFFD700Raid|r")
        else
            print("|cffff8800[ZinaGearCompare]|r Uso: /zgc mode auto|dungeon|raid")
        end
        UpdatePaperDollScore()
        if InspectFrame and InspectFrame:IsShown() then ZGC_UpdatePanel() end

    elseif msg == "debug" then
        print("|cff00aaff[ZinaGearCompare]|r === DEBUG ===")
        local ok, err = pcall(function()
            -- Content type
            local detected = ZGC_DetectContentType()
            local override = ZinaGearCompareDB and ZinaGearCompareDB.contentOverride
            print(string.format("  Tipo de contenido: %s  (detectado: %s, override: %s)",
                ZGC_GetContentType(), detected, tostring(override)))

            -- Spec
            local specID   = ZGC_GetSpecIDForUnit("player")
            local specName = ZGC_GetSpecNameForUnit("player")
            print(string.format("  SpecID: %s  Spec: %s", tostring(specID), tostring(specName)))

            -- Pesos disponibles
            local hasWeights = specID and ZGC_StatWeights and ZGC_StatWeights[specID]
            print("  Pesos en ZGC_StatWeights:", hasWeights and "OK" or "NO ENCONTRADOS")

            -- Tier
            local tierCount = ZGC_CountTierPieces and ZGC_CountTierPieces("player") or 0
            local tierMult  = specID and ZGC_GetTierMultiplier and ZGC_GetTierMultiplier("player", specID) or 1.0
            print(string.format("  Tier pieces: %d   Multiplicador: %.2fx", tierCount, tierMult))

            -- Score
            local total, slots = ZGC_GetWeightedScore("player", specID, ZGC_GetContentType())
            print(string.format("  Score: %.0f  Slots valorados: %d/%d", total, slots, ZGC_EQUIP_SLOT_COUNT))

            -- Test C_Item.GetItemStats API
            local apiOk = C_Item and C_Item.GetItemStats ~= nil
            print("  C_Item.GetItemStats existe:", apiOk and "SI" or "NO")
            local testLink = GetInventoryItemLink("player", 1)
                          or GetInventoryItemLink("player", 5)
            if testLink then
                print("  Item de prueba (slot 1/5):", testLink)
                if ZGC_DiagnoseStatKeys then
                    print("  Diagnóstico stats:", ZGC_DiagnoseStatKeys(testLink))
                end
                if specID and ZGC_StatWeights and ZGC_StatWeights[specID] then
                    local w  = ZGC_StatWeights[specID]
                    local ct = ZGC_GetContentType()
                    local itemScore = ZGC_ScoreItem(testLink, w[ct] or w.dungeon, w.primaryStat)
                    print("  Score del item:", itemScore and string.format("%.1f", itemScore) or "nil")
                end
            else
                print("  Slots 1 y 5 vacíos")
            end
        end)
        if not ok then
            print("  |cffff4444ERROR en debug:|r", err)
        end

    else
        print("|cff00aaff[ZinaGearCompare]|r Comandos disponibles:")
        print("  /zgc compare        — compara el equipo de tu target contra el tuyo")
        print("  /zgc score          — muestra tu score actual")
        print("  /zgc mode auto      — auto-detectar tipo de contenido")
        print("  /zgc mode dungeon   — forzar pesos de M+")
        print("  /zgc mode raid      — forzar pesos de Raid")
        print("  /zgc debug          — diagnóstico completo")
        print("  /zgc reset          — resetea la base de datos del addon")
    end
end
