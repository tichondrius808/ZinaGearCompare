-- ZinaGearCompare.lua — Entry point del addon
-- Gestiona eventos globales y orquesta Scoring.lua + InspectUI.lua

local ADDON_NAME = "ZinaGearCompare"

-- ── SavedVariables por defecto ───────────────────────────────────────────────
local DB_DEFAULTS = {
    version = 1,
}

-- ── Frame de eventos ─────────────────────────────────────────────────────────
local eventFrame = CreateFrame("Frame", ADDON_NAME .. "EventFrame")

-- ── PaperDoll score text ──────────────────────────────────────────────────────
local zgcPaperDollText = nil

local function GetPlayerScaleAndScore()
    local scale = ZGC_GetBestScaleForUnit("player")
    if not scale then
        -- Solo scales custom; si no hay ninguno, retorna nil
        scale = next(ZGC_GetCustomScales())
    end
    if not scale then return nil, nil, nil end
    local total, slots = ZGC_GetMyScore(scale)
    return scale, total, slots
end

local function UpdatePaperDollScore()
    if not zgcPaperDollText then return end
    if not PawnGetSingleValueFromItem then
        zgcPaperDollText:SetText("")
        return
    end
    local scale, total, slots = GetPlayerScaleAndScore()
    if not scale then
        zgcPaperDollText:SetText("|cffff8800ZGC: sin scales de Pawn|r")
        return
    end
    if total and total > 0 then
        zgcPaperDollText:SetText(string.format(
            "|cff00aaffZGC Score:|r |cffffd700%.0f|r  |cffaaaaaa[%s  %d slots]|r",
            total, scale, slots))
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

-- ── Fórmula de paridad de skill (WoW Midnight) ───────────────────────────────
-- gearRatio = su_score / mi_score
-- Devuelve el % de su daño que debes hacer tú para ser igual de hábil.
-- < 100% → ellos tienen más equipo, tú debes compensar con skill.
-- > 100% → tú tienes más equipo, deberías hacer más daño.
local function ZGC_SkillParity(gearRatio)
    if not gearRatio or gearRatio <= 0 then return nil end
    return ((1 / gearRatio) ^ 2.0) * 100
end

-- ── Mouseover inspection cache (score de otros jugadores en tooltip) ─────────
local zgcMouseoverName    = nil
local zgcMouseoverRealm   = nil
local zgcMouseoverScore   = nil   -- nil = sin scale custom para esa spec
local zgcMouseoverScale   = nil
local zgcMouseoverGearRatio = nil  -- score_inspeccionado / mi_score (ratio crudo, no × 100)
local zgcMouseoverReady   = false -- true cuando INSPECT_READY completó para el jugador actual
local zgcMouseoverPending = false
local zgcMouseoverWaiting = false
local zgcPrintPending     = false -- true cuando /zgc compare espera INSPECT_READY

local function ZGC_GetMouseoverNameRealm()
    local n, r = UnitName("mouseover")
    if not r or r == "" then r = GetRealmName() end
    return n, r
end

local function ZGC_TryMouseoverInspect()
    zgcMouseoverWaiting = false
    if not UnitIsPlayer("mouseover") then return end
    if InspectFrame and InspectFrame:IsShown() then return end
    if zgcMouseoverPending then return end
    local n, r = ZGC_GetMouseoverNameRealm()
    if n == zgcMouseoverName and r == zgcMouseoverRealm then return end
    -- Nuevo jugador: limpiar caché y pedir inspect
    zgcMouseoverName  = nil
    zgcMouseoverRealm = nil
    zgcMouseoverScore     = nil
    zgcMouseoverScale     = nil
    zgcMouseoverGearRatio = nil
    zgcMouseoverReady     = false
    zgcMouseoverPending   = true
    NotifyInspect("mouseover")
end

-- ── Integración con Details! ──────────────────────────────────────────────────
-- Devuelve { myDmg, theirDmg, combatTime, segName } si ambos están en el mismo
-- segmento, o nil si Details no está instalado o no hay datos comunes.
local function ZGC_GetDetailsComparison(myName, targetName)
    if not _G.Details then return nil end

    local function findBothInCombat(combat)
        if not combat then return nil end
        local myActor    = combat:GetActor(DETAILS_ATTRIBUTE_DAMAGE, myName)
        local theirActor = combat:GetActor(DETAILS_ATTRIBUTE_DAMAGE, targetName)
        -- Fallback: iterar por GetOnlyName() por si el nombre incluye realm
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

local function ZGC_CheckMouseover()
    if zgcMouseoverWaiting or zgcMouseoverPending then return end
    if not UnitIsPlayer("mouseover") then return end
    local n, r = ZGC_GetMouseoverNameRealm()
    if n == zgcMouseoverName and r == zgcMouseoverRealm then return end
    -- Debounce 0.1s para evitar inspeccionar al "pasar el cursor"
    zgcMouseoverWaiting = true
    C_Timer.After(0.1, ZGC_TryMouseoverInspect)
end

-- ── GameTooltip hook (score del propio jugador) ───────────────────────────────
-- OnTooltipSetUnit fue eliminado en Dragonflight+; usar TooltipDataProcessor.
local function HookGameTooltip()
    if not TooltipDataProcessor then return end
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip, data)
        if not data or not data.guid then return end
        if data.guid ~= UnitGUID("player") then return end
        if not PawnGetSingleValueFromItem then return end
        local scale, total = GetPlayerScaleAndScore()
        if scale and total and total > 0 then
            tooltip:AddLine(string.format("|cff00aaffZGC:|r |cffffd700%.0f|r |cffaaaaaa(%s)|r",
                total, scale))
        else
            tooltip:AddLine("|cff00aaffZGC:|r |cffaaaaaa(pendiente)|r")
        end
        tooltip:Show()
    end)
end

-- Hook OnUpdate: añadir score ZGC al tooltip del jugador bajo el cursor
GameTooltip:HookScript("OnUpdate", function(self)
    if self.zgcScoreAdded then return end          -- primera barrera: boolean local, ~ns
    if not UnitIsPlayer("mouseover") then return end
    if not zgcMouseoverReady then return end
    local n, r = ZGC_GetMouseoverNameRealm()
    if n ~= zgcMouseoverName or r ~= zgcMouseoverRealm then return end
    self.zgcScoreAdded = true
    if zgcMouseoverScore and zgcMouseoverScale then
        local parityStr = ""
        local parity = ZGC_SkillParity(zgcMouseoverGearRatio)
        if parity then
            -- < 100%: ellos tienen más equipo (debes compensar con skill)
            -- > 100%: tú tienes más equipo (deberías hacer más daño)
            local col = parity <= 80 and "|cffff4444" or parity <= 100 and "|cffffd700" or "|cff00ff00"
            parityStr = string.format("  %sskill≥%.0f%%|r", col, parity)
        end
        self:AddLine(string.format("|cff00aaffZGC:|r |cffffd700%.0f|r |cffaaaaaa(%s)|r%s",
            zgcMouseoverScore, zgcMouseoverScale, parityStr))
    else
        self:AddLine("|cff00aaffZGC:|r |cffaaaaaa(pendiente)|r")
    end
    self:Show()
end)
GameTooltip:HookScript("OnTooltipCleared", function(self)
    self.zgcScoreAdded = false
end)
GameTooltip:HookScript("OnHide", function(self)
    self.zgcScoreAdded = false
end)

-- ── ADDON_LOADED ─────────────────────────────────────────────────────────────
local function OnAddonLoaded(addonName)
    if addonName ~= ADDON_NAME then return end

    -- Inicializar SavedVariables
    if not ZinaGearCompareDB then
        ZinaGearCompareDB = {}
    end
    for k, v in pairs(DB_DEFAULTS) do
        if ZinaGearCompareDB[k] == nil then
            ZinaGearCompareDB[k] = v
        end
    end

    -- Inicializar módulo de UI (hooks al InspectFrame)
    ZGC_InitUI()

    -- Inicializar score en character frame
    InitPaperDoll()

    -- Hook de tooltip del propio jugador
    pcall(HookGameTooltip)

    -- Avisar en chat si Pawn no está instalado
    if not PawnGetSingleValueFromItem then
        print("|cffff8800[ZinaGearCompare]|r Pawn no está instalado. " ..
              "El score de calidad de equipo no estará disponible.")
    else
        print("|cff00aaff[ZinaGearCompare]|r cargado. Pawn detectado. " ..
              "Inspecciona a un jugador para ver su Gear Quality.")
    end
end

-- ── INSPECT_READY / UNIT_INSPECTED ───────────────────────────────────────────
-- En Retail se usa INSPECT_READY; se registra también UNIT_INSPECTED como fallback.
local pendingUnit = nil

local function OnInspectReady(unit)
    -- 'unit' puede ser nil en algunos builds; usar pendingUnit como fallback
    local target = unit or pendingUnit
    if not target then return end
    if not InspectFrame or not InspectFrame:IsShown() then return end
    ZGC_OnInspectReady(target)
end

-- ── PLAYER_EQUIPMENT_CHANGED ─────────────────────────────────────────────────
-- Recalcular el score propio cuando el jugador cambia de equipo.
local function OnPlayerEquipmentChanged()
    if InspectFrame and InspectFrame:IsShown() then
        ZGC_UpdatePanel()
    end
    UpdatePaperDollScore()
end

-- ── Dispatcher de eventos ────────────────────────────────────────────────────
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        OnAddonLoaded(...)

    elseif event == "INSPECT_READY" then
        -- INSPECT_READY ahora pasa un GUID en Midnight; resolver a unit token.
        local guid = ...
        local unit = nil
        for _, u in ipairs({"target", "mouseover", "focus", "party1", "party2", "party3", "party4"}) do
            if UnitGUID(u) == guid then
                unit = u
                break
            end
        end
        pendingUnit = unit or pendingUnit
        OnInspectReady(unit or pendingUnit)  -- no-op si InspectFrame no está abierto

        -- Path de mouseover: calcular score con scale custom del jugador bajo el cursor
        if zgcMouseoverPending then
            zgcMouseoverPending = false
            if UnitIsPlayer("mouseover") and UnitGUID("mouseover") == guid then
                local n, r = ZGC_GetMouseoverNameRealm()
                zgcMouseoverName  = n
                zgcMouseoverRealm = r
                zgcMouseoverScore     = nil
                zgcMouseoverScale     = nil
                zgcMouseoverGearRatio = nil
                zgcMouseoverReady     = true
                -- Calcular score solo si hay un scale custom para su spec
                if PawnGetSingleValueFromItem then
                    local scale = ZGC_GetBestScaleForUnit("mouseover")
                    if scale then
                        local total = ZGC_GetWeightedScore("mouseover", scale)
                        if total and total > 0 then
                            zgcMouseoverScore = total
                            zgcMouseoverScale = scale
                            -- gearRatio crudo: su_score / mi_score (con mi propio scale)
                            local _, myTotal = GetPlayerScaleAndScore()
                            if myTotal and myTotal > 0 then
                                zgcMouseoverGearRatio = total / myTotal
                            end
                        end
                    end
                end
            end
        end

        -- Path de /zgc compare: imprimir en chat el resultado del inspect del target
        if zgcPrintPending then
            zgcPrintPending = false
            local unit = nil
            for _, u in ipairs({"target", "mouseover", "focus"}) do
                if UnitGUID(u) == guid then unit = u; break end
            end
            if unit then
                local name = UnitName(unit) or "?"
                local scale = PawnGetSingleValueFromItem and ZGC_GetBestScaleForUnit(unit)
                if not scale then
                    print(string.format("|cff00aaff[ZinaGearCompare]|r %s — |cffaaaaaa(pendiente: sin scale custom para esta spec)|r", name))
                else
                    local total = ZGC_GetWeightedScore(unit, scale)
                    local myScale, myTotal = GetPlayerScaleAndScore()
                    if total and total > 0 then
                        print(string.format("|cff00aaff[ZinaGearCompare]|r %s — ZGC: |cffffd700%.0f|r |cffaaaaaa(%s)|r",
                            name, total, scale))
                        if myScale and myTotal and myTotal > 0 then
                            local gearRatio = total / myTotal
                            local parity    = ZGC_SkillParity(gearRatio)
                            print(string.format("  |cffaaaaaa  Mi score: %.0f (%s)   Su equipo vs el mío: %.0f%%|r",
                                myTotal, myScale, gearRatio * 100))
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

                                -- Integración con Details! (si está instalado y hay datos)
                                local myPlayerName = UnitName("player")
                                local det = ZGC_GetDetailsComparison(myPlayerName, name)
                                if det and det.theirDmg > 0 then
                                    local actualRatio = (det.myDmg / det.theirDmg) * 100
                                    local delta_pp    = actualRatio - parity
                                    local relDelta    = (actualRatio / parity - 1) * 100
                                    local sign        = delta_pp >= 0 and "+" or ""
                                    local col         = delta_pp >= 0 and "|cff00ff00" or "|cffff4444"
                                    local arrow       = delta_pp >= 0 and "↑" or "↓"
                                    print(string.format(
                                        "  |cffaaaaaa[Details! · %s]|r", det.segName))
                                    print(string.format(
                                        "  |cffaaaaaa  Tu daño: %.0f   Su daño: %.0f|r",
                                        det.myDmg, det.theirDmg))
                                    print(string.format(
                                        "  |cffaaaaaa  Ratio actual: %.1f%% de su daño   Esperado por gear: %.1f%%|r",
                                        actualRatio, parity))
                                    print(string.format(
                                        "  %s→ %s%.1fpp %s (%.1f%% %s lo esperado por equipo)|r",
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
        -- Guardar la unit objetivo para usarla en INSPECT_READY si es necesario
        if UnitExists("target") and UnitIsPlayer("target") then
            pendingUnit = "target"
        else
            pendingUnit = nil
        end
    end
end)

-- ── Registro de eventos ──────────────────────────────────────────────────────
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("INSPECT_READY")
eventFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")

-- ── Slash command ─────────────────────────────────────────────────────────────
SLASH_ZINAGEARCOMPARE1 = "/zgc"
SlashCmdList["ZINAGEARCOMPARE"] = function(msg)
    msg = msg:lower():match("^%s*(.-)%s*$")  -- trim

    if msg == "reset" then
        ZinaGearCompareDB = {}
        for k, v in pairs(DB_DEFAULTS) do ZinaGearCompareDB[k] = v end
        print("|cff00aaff[ZinaGearCompare]|r Base de datos reseteada.")

    elseif msg == "scales" then
        local scales = ZGC_GetAvailableScales()
        local count = 0
        print("|cff00aaff[ZinaGearCompare]|r Scales de Pawn disponibles:")
        for name in pairs(scales) do
            print("  -", name)
            count = count + 1
        end
        if count == 0 then
            print("  (ninguno — ¿Pawn está instalado?)")
        end

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
        -- Usar el scale de la spec actual del jugador; fallback al primero disponible
        local scale, total, slots = GetPlayerScaleAndScore()
        if not scale then
            print("|cffff8800[ZinaGearCompare]|r Sin scales de Pawn disponibles.")
            return
        end
        print(string.format(
            "|cff00aaff[ZinaGearCompare]|r Mi score: |cffffd700%.0f|r total | %d slots | Scale: %s",
            total, slots, scale))

    elseif msg == "debug" then
        print("|cff00aaff[ZinaGearCompare]|r === DEBUG ===")
        print("  Addon version: 1 | Interface: Midnight 12.x")
        local ok, err = pcall(function()
            -- Pawn disponible?
            print("  PawnGetSingleValueFromItem:", PawnGetSingleValueFromItem ~= nil and "OK" or "NO EXISTE")
            print("  PawnGetItemData:", PawnGetItemData ~= nil and "OK" or "NO EXISTE")
            print("  PawnCommon:", PawnCommon ~= nil and "OK" or "NO EXISTE")
            -- Scales
            local scales = ZGC_GetAvailableScales()
            local count = 0
            for _ in pairs(scales) do count = count + 1 end
            print("  Scales disponibles:", count)
            if count > 0 and count <= 5 then
                for n in pairs(scales) do print("    -", n) end
            end
            -- Spec
            local specID = GetSpecialization and GetSpecialization()
            local classID = select(3, UnitClass("player"))
            print("  SpecID:", specID, "  ClassID:", classID)
            local bestScale = ZGC_GetBestScaleForUnit("player")
            print("  Scale autodetectado:", bestScale or "(ninguno)")
            -- Test de item
            local testLink = GetInventoryItemLink("player", 1)  -- Head slot
            if testLink then
                print("  Item de prueba (slot 1):", testLink)
                local itemData = PawnGetItemData and PawnGetItemData(testLink)
                print("  PawnGetItemData result:", itemData ~= nil and "OK (table)" or "nil")
                if itemData and bestScale then
                    local v = PawnGetSingleValueFromItem(itemData, bestScale)
                    print("  PawnGetSingleValueFromItem:", v)
                end
            else
                print("  Slot 1 (cabeza): vacío")
            end
        end)
        if not ok then
            print("  |cffff4444ERROR en debug:|r", err)
        end

    else
        print("|cff00aaff[ZinaGearCompare]|r Comandos disponibles:")
        print("  /zgc compare  — compara el equipo de tu target contra el tuyo (imprime en chat)")
        print("  /zgc scales   — lista los scales de Pawn disponibles")
        print("  /zgc score    — muestra tu score actual")
        print("  /zgc myscore  — alias de /zgc score")
        print("  /zgc debug    — diagnóstico (qué ve el addon)")
        print("  /zgc reset    — resetea la base de datos del addon")
    end
end
