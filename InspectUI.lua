-- InspectUI.lua — ZinaGearCompare
-- Panel de Gear Quality en el InspectFrame. Motor independiente (sin Pawn).

local PANEL_NAME = "ZGCInspectPanel"

-- ── Elementos de UI ──────────────────────────────────────────────────────────
local zgcPanel          -- Frame contenedor
local zgcScoreText      -- FontString: score principal + ratio
local zgcStatusText     -- FontString: spec / content / tier
local zgcContentBtn     -- Button: "[Auto: M+]" / "[Raid]" — click alterna override

-- Unit inspeccionada actualmente
local inspectedUnit = nil

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function FormatRatio(ratio)
    if not ratio then return "" end
    local color
    if ratio >= 95 then
        color = "|cff00ff00"
    elseif ratio >= 80 then
        color = "|cffffff00"
    else
        color = "|cffff4444"
    end
    return string.format("  %s[%.0f%% vs you]|r", color, ratio)
end

local function FormatTierInfo(unit, specID)
    if not ZGC_CountTierPieces then return "" end
    local count = ZGC_CountTierPieces(unit)
    if count == 0 then return "|cffaaaaaa(no tier)|r" end
    local specWeights = ZGC_StatWeights and ZGC_StatWeights[specID]
    local bonusPct
    if count >= 4 then
        local b = specWeights and specWeights.tierBonus4pc or 1.12
        bonusPct = (b - 1.0) * 100
        return string.format("|cffFFD700Tier: 4pc (+%.0f%%)|r", bonusPct)
    else
        local b = specWeights and specWeights.tierBonus2pc or 1.05
        bonusPct = (b - 1.0) * 100
        return string.format("|cffaad4ffTier: 2pc (+%.0f%%)|r", bonusPct)
    end
end

-- ── Actualización del panel ──────────────────────────────────────────────────

function ZGC_UpdatePanel()
    if not zgcPanel or not zgcPanel:IsShown() then return end

    if not inspectedUnit then
        zgcScoreText:SetText("")
        zgcStatusText:SetText("|cffaaaaaaLoading inspect data...|r")
        if zgcContentBtn then zgcContentBtn:Hide() end
        return
    end

    local specID    = ZGC_GetSpecIDForUnit(inspectedUnit)
    local specName  = ZGC_GetSpecNameForUnit(inspectedUnit) or "?"
    local contentType = ZGC_GetContentType()

    -- Inspected unit's score
    local inspTotal, inspSlots, inspAvg = ZGC_GetWeightedScore(inspectedUnit, specID, contentType)

    -- Player's own score (same spec/content for robust cross-comparison)
    local mySpecID   = ZGC_GetSpecIDForUnit("player")
    local myCType    = contentType
    local myTotal, mySlots, myAvg = ZGC_GetWeightedScore("player", mySpecID, myCType)

    local ratio = nil
    if inspAvg and myAvg and myAvg > 0 then
        ratio = (inspAvg / myAvg) * 100
    end

    -- Main line
    if inspAvg then
        local line = string.format("|cffaad4ffGear Quality:|r  |cffffd700%.0f|r%s",
            inspTotal, FormatRatio(ratio))
        zgcScoreText:SetText(line)
    elseif not specID then
        zgcScoreText:SetText("|cffaad4ffGear Quality:|r  |cffaaaaaa(unknown spec)|r")
    else
        zgcScoreText:SetText("|cffaad4ffGear Quality:|r  |cffaaaaaan/a|r")
    end

    -- Detail line: spec | content | tier | slots
    local contentLabel = ZGC_GetContentTypeLabel()
    local tierInfo     = (specID and FormatTierInfo(inspectedUnit, specID)) or ""
    local slotsStr     = string.format("|cffaaaaaa%d/%d slots|r", inspSlots, ZGC_EQUIP_SLOT_COUNT)
    zgcStatusText:SetText(string.format("|cffaaaaaa%s|r  %s  %s  %s",
        specName, contentLabel, tierInfo, slotsStr))

    -- Botón de content override
    if zgcContentBtn then
        zgcContentBtn:Show()
        local override = ZinaGearCompareDB and ZinaGearCompareDB.contentOverride
        if override then
            zgcContentBtn:SetText(string.format("|cffffd700[%s ×]|r",
                override == "raid" and "Raid" or "M+"))
        else
            zgcContentBtn:SetText("|cffaaaaaa[auto]|r")
        end
    end
end

-- ── Creación del panel ────────────────────────────────────────────────────────

local function CreatePanel()
    if zgcPanel then return end
    local ok, err = pcall(function()

    zgcPanel = CreateFrame("Frame", PANEL_NAME, InspectFrame)
    zgcPanel:SetSize(310, 78)
    zgcPanel:SetPoint("TOPLEFT", InspectFrame, "TOPLEFT", 10, -230)

    -- Línea principal: score + ratio
    zgcScoreText = zgcPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    zgcScoreText:SetPoint("TOPLEFT", zgcPanel, "TOPLEFT", 0, 0)
    zgcScoreText:SetWidth(310)
    zgcScoreText:SetJustifyH("LEFT")
    zgcScoreText:SetText("")

    -- Línea de estado: spec / content / tier / slots
    zgcStatusText = zgcPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    zgcStatusText:SetPoint("TOPLEFT", zgcScoreText, "BOTTOMLEFT", 0, -3)
    zgcStatusText:SetWidth(310)
    zgcStatusText:SetJustifyH("LEFT")
    zgcStatusText:SetText("")

    -- Botón de content override (click alterna dungeon ↔ raid ↔ auto)
    zgcContentBtn = CreateFrame("Button", PANEL_NAME .. "ContentBtn", zgcPanel)
    zgcContentBtn:SetSize(100, 18)
    zgcContentBtn:SetPoint("TOPLEFT", zgcStatusText, "BOTTOMLEFT", 0, -4)
    zgcContentBtn:SetNormalFontObject("GameFontNormalSmall")
    zgcContentBtn:SetHighlightFontObject("GameFontHighlightSmall")
    zgcContentBtn:SetText("|cffaaaaaa[auto]|r")
    zgcContentBtn:SetScript("OnClick", function()
        if not ZinaGearCompareDB then return end
        local cur = ZinaGearCompareDB.contentOverride
        if not cur then
            ZinaGearCompareDB.contentOverride = "dungeon"
        elseif cur == "dungeon" then
            ZinaGearCompareDB.contentOverride = "raid"
        else
            ZinaGearCompareDB.contentOverride = nil
        end
        ZGC_UpdatePanel()
    end)
    zgcContentBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Content override\nClick to cycle: Auto > M+ > Raid > Auto", nil, nil, nil, nil, true)
        GameTooltip:Show()
    end)
    zgcContentBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    zgcContentBtn:Hide()

    end)  -- pcall
    if not ok then
        print("|cffff8800[ZinaGearCompare]|r Error creando panel:", err)
        zgcPanel = nil
    end
end

-- ── Hooks al InspectFrame ─────────────────────────────────────────────────────

local function OnInspectFrameShow()
    if not zgcPanel then CreatePanel() end
    if not zgcPanel then return end
    zgcPanel:Show()
    inspectedUnit = nil
    zgcScoreText:SetText("")
    zgcStatusText:SetText("|cffaaaaaaLoading inspect data...|r")
    if zgcContentBtn then zgcContentBtn:Hide() end
end

local function OnInspectFrameHide()
    if zgcPanel then zgcPanel:Hide() end
    inspectedUnit = nil
end

local function HookInspectFrame()
    if not InspectFrame then return end
    hooksecurefunc(InspectFrame, "Show", OnInspectFrameShow)
    hooksecurefunc(InspectFrame, "Hide", OnInspectFrameHide)
end

-- ── API pública ───────────────────────────────────────────────────────────────

function ZGC_OnInspectReady(unit)
    inspectedUnit = unit
    ZGC_UpdatePanel()
end

function ZGC_InitUI()
    HookInspectFrame()
end
