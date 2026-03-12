-- InspectUI.lua — ZinaGearCompare
-- Añade panel de Gear Quality al InspectFrame de WoW

local PANEL_NAME = "ZGCInspectPanel"

-- ── Elementos de UI ──────────────────────────────────────────────────────────

local zgcPanel        -- Frame contenedor
local zgcScoreText    -- FontString: "Gear Quality (Pawn): XXX  [YY% vs tú]"
local zgcStatusText   -- FontString: estado / errores / avisos
local zgcDropdown     -- Frame selector de scale (custom, sin UIDropDownMenuTemplate)
local zgcScaleLabel   -- FontString dentro del selector: nombre del scale actual

-- Scale actualmente seleccionado para el inspeccionado
local currentScale = nil
-- Unit inspeccionada actualmente
local inspectedUnit = nil
-- Lista ordenada de scales disponibles (caché)
local sortedScales = {}

-- ── Helpers ──────────────────────────────────────────────────────────────────

local function PawnAvailable()
    return PawnGetSingleValueFromItem ~= nil
end

local function FormatRatio(ratio)
    if not ratio then return "" end
    local color
    if ratio >= 95 then
        color = "|cff00ff00"   -- verde
    elseif ratio >= 80 then
        color = "|cffffff00"   -- amarillo
    else
        color = "|cffff4444"   -- rojo
    end
    return string.format("  %s[%.0f%% vs tú]|r", color, ratio)
end

-- ── Custom Scale Selector (reemplaza UIDropDownMenuTemplate deprecado) ────────

local function RebuildScaleList()
    local scales = ZGC_GetCustomScales()
    local autoScale = inspectedUnit and ZGC_GetBestScaleForUnit(inspectedUnit)
    sortedScales = {}
    for name in pairs(scales) do
        sortedScales[#sortedScales + 1] = name
    end
    table.sort(sortedScales)
    -- Mover el scale auto-detectado al frente
    if autoScale then
        for i, name in ipairs(sortedScales) do
            if name == autoScale then
                table.remove(sortedScales, i)
                table.insert(sortedScales, 1, autoScale)
                break
            end
        end
    end
end

local function GetCurrentScaleIndex()
    for i, name in ipairs(sortedScales) do
        if name == currentScale then return i end
    end
    return 1
end

function ZGC_RefreshDropdown()
    RebuildScaleList()
    if not zgcScaleLabel then return end
    if #sortedScales == 0 then
        zgcScaleLabel:SetText("(sin scales)")
        return
    end
    if not currentScale then
        currentScale = sortedScales[1]
    end
    local autoScale = inspectedUnit and ZGC_GetBestScaleForUnit(inspectedUnit)
    local prefix = (currentScale == autoScale) and "[Auto] " or ""
    zgcScaleLabel:SetText(prefix .. (currentScale or "?"))
end

-- ── Actualización del panel ──────────────────────────────────────────────────

function ZGC_UpdatePanel()
    if not zgcPanel or not zgcPanel:IsShown() then return end

    -- Sin Pawn
    if not PawnAvailable() then
        zgcScoreText:SetText("")
        zgcStatusText:SetText("|cffff8800Pawn no está instalado. Instala Pawn para ver Gear Quality.|r")
        zgcDropdown:Hide()
        return
    end

    -- Sin unit inspeccionada todavía
    if not inspectedUnit then
        zgcScoreText:SetText("")
        zgcStatusText:SetText("|cffaaaaaaEsperando datos de inspección…|r")
        return
    end

    -- Sin scale seleccionado
    if not currentScale then
        currentScale = ZGC_GetBestScaleForUnit(inspectedUnit)
    end

    if not currentScale then
        zgcScoreText:SetText("")
        zgcStatusText:SetText("|cffff8800No se detectó un scale de Pawn compatible. Selecciona uno.|r")
        zgcDropdown:Show()
        ZGC_RefreshDropdown()
        return
    end

    -- Calcular scores
    local inspTotal, inspSlots, inspAvg = ZGC_GetWeightedScore(inspectedUnit, currentScale)
    local myTotal,   mySlots,   myAvg   = ZGC_GetMyScore(currentScale)

    local ratio = nil
    if inspAvg and myAvg and myAvg > 0 then
        ratio = (inspAvg / myAvg) * 100
    end

    if inspAvg then
        local line = string.format("|cffaad4ffGear Quality (Pawn):|r  %.0f%s",
            inspTotal, FormatRatio(ratio))
        zgcScoreText:SetText(line)
        local detail = string.format("|cffaaaaaa[Scale: %s   Slots: %d/%d]|r",
            currentScale, inspSlots, #({1,2,3,5,6,7,8,9,10,11,12,13,14,15,16,17}))
        zgcStatusText:SetText(detail)
    else
        zgcScoreText:SetText("|cffaad4ffGear Quality (Pawn):|r  |cffaaaaaan/a|r")
        zgcStatusText:SetText("|cffaaaaaaPawn no valoró ningún slot con el scale seleccionado.|r")
    end

    zgcDropdown:Show()
    ZGC_RefreshDropdown()
end

-- ── Creación del panel ───────────────────────────────────────────────────────

local function CreatePanel()
    if zgcPanel then return end
    local ok, err = pcall(function()

    -- Contenedor pegado al InspectFrame
    zgcPanel = CreateFrame("Frame", PANEL_NAME, InspectFrame)
    zgcPanel:SetSize(310, 90)
    -- Anclar debajo del texto de item level de Blizzard
    zgcPanel:SetPoint("TOPLEFT", InspectFrame, "TOPLEFT", 10, -230)

    -- Línea principal: score + ratio
    zgcScoreText = zgcPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    zgcScoreText:SetPoint("TOPLEFT", zgcPanel, "TOPLEFT", 0, 0)
    zgcScoreText:SetWidth(310)
    zgcScoreText:SetJustifyH("LEFT")
    zgcScoreText:SetText("")

    -- Línea de estado / detalle
    zgcStatusText = zgcPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    zgcStatusText:SetPoint("TOPLEFT", zgcScoreText, "BOTTOMLEFT", 0, -2)
    zgcStatusText:SetWidth(310)
    zgcStatusText:SetJustifyH("LEFT")
    zgcStatusText:SetText("")

    -- Selector de scale custom: [ < ] [nombre del scale] [ > ]
    zgcDropdown = CreateFrame("Frame", PANEL_NAME .. "ScaleSelector", zgcPanel)
    zgcDropdown:SetSize(240, 22)
    zgcDropdown:SetPoint("TOPLEFT", zgcStatusText, "BOTTOMLEFT", 0, -4)

    local leftBtn = CreateFrame("Button", nil, zgcDropdown)
    leftBtn:SetSize(18, 18)
    leftBtn:SetPoint("LEFT", zgcDropdown, "LEFT", 0, 0)
    leftBtn:SetText("<")
    leftBtn:SetNormalFontObject("GameFontNormal")
    leftBtn:SetScript("OnClick", function()
        RebuildScaleList()
        if #sortedScales == 0 then return end
        local idx = GetCurrentScaleIndex() - 1
        if idx < 1 then idx = #sortedScales end
        currentScale = sortedScales[idx]
        ZGC_RefreshDropdown()
        ZGC_UpdatePanel()
    end)

    local rightBtn = CreateFrame("Button", nil, zgcDropdown)
    rightBtn:SetSize(18, 18)
    rightBtn:SetPoint("RIGHT", zgcDropdown, "RIGHT", 0, 0)
    rightBtn:SetText(">")
    rightBtn:SetNormalFontObject("GameFontNormal")
    rightBtn:SetScript("OnClick", function()
        RebuildScaleList()
        if #sortedScales == 0 then return end
        local idx = GetCurrentScaleIndex() + 1
        if idx > #sortedScales then idx = 1 end
        currentScale = sortedScales[idx]
        ZGC_RefreshDropdown()
        ZGC_UpdatePanel()
    end)

    zgcScaleLabel = zgcDropdown:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    zgcScaleLabel:SetPoint("LEFT", leftBtn, "RIGHT", 4, 0)
    zgcScaleLabel:SetPoint("RIGHT", rightBtn, "LEFT", -4, 0)
    zgcScaleLabel:SetJustifyH("CENTER")
    zgcScaleLabel:SetText("Seleccionar scale…")

    zgcDropdown:Hide()
    end)  -- pcall
    if not ok then
        print("|cffff8800[ZinaGearCompare]|r Error creando panel:", err)
        zgcPanel = nil
    end
end

-- ── Hooks al InspectFrame ────────────────────────────────────────────────────

local function OnInspectFrameShow()
    if not zgcPanel then CreatePanel() end
    if not zgcPanel then return end  -- CreatePanel falló
    zgcPanel:Show()
    -- Resetear estado; ZGC_UpdatePanel se llama desde INSPECT_READY
    inspectedUnit = nil
    currentScale  = nil
    zgcScoreText:SetText("")
    zgcStatusText:SetText("|cffaaaaaaCargando datos de inspección…|r")
    zgcDropdown:Hide()
end

local function OnInspectFrameHide()
    if zgcPanel then zgcPanel:Hide() end
    inspectedUnit = nil
    currentScale  = nil
end

-- Hook seguro al InspectFrame (disponible tras ADDON_LOADED del UI de Blizzard)
local function HookInspectFrame()
    if not InspectFrame then return end
    hooksecurefunc(InspectFrame, "Show", OnInspectFrameShow)
    hooksecurefunc(InspectFrame, "Hide", OnInspectFrameHide)
end

-- ── API pública para ZinaGearCompare.lua ────────────────────────────────────

-- Llamado desde el evento INSPECT_READY / UNIT_INSPECTED
function ZGC_OnInspectReady(unit)
    inspectedUnit = unit
    currentScale  = nil   -- forzar re-autodetección con nuevos datos
    ZGC_UpdatePanel()
end

-- Inicialización del módulo de UI (llamado desde ZinaGearCompare.lua)
function ZGC_InitUI()
    HookInspectFrame()
end
