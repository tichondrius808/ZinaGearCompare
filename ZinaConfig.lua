-- ZinaConfig.lua — ZinaGearCompare
-- Minimap icon (LibDBIcon) + config panel + Addon Compartment support.

local ADDON_NAME = "ZinaGearCompare"
local ICON_TEXTURE = 132089  -- INV_Chest_Plate16 (plate armor icon)

-- ── DB defaults for config ──────────────────────────────────────────────────
local CONFIG_DEFAULTS = {
    skillParity    = false,   -- SkillParity desactivado por defecto
    paritySegment  = "current", -- "current" o "overall"
    minimap        = { hide = false },
}

-- ── Inicializar DB de config ────────────────────────────────────────────────
local function InitConfigDB()
    if not ZinaGearCompareDB then ZinaGearCompareDB = {} end
    for k, v in pairs(CONFIG_DEFAULTS) do
        if ZinaGearCompareDB[k] == nil then
            if type(v) == "table" then
                ZinaGearCompareDB[k] = {}
                for k2, v2 in pairs(v) do ZinaGearCompareDB[k2] = v2 end
                ZinaGearCompareDB[k] = CopyTable(v)
            else
                ZinaGearCompareDB[k] = v
            end
        end
    end
    if not ZinaGearCompareDB.minimap then
        ZinaGearCompareDB.minimap = { hide = false }
    end
end

-- ── Config panel (Settings API) ─────────────────────────────────────────────
local configPanel = nil

local function CreateConfigPanel()
    if configPanel then return configPanel end

    configPanel = CreateFrame("Frame", "ZGCConfigPanel")
    configPanel.name = ADDON_NAME

    local title = configPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("|cff00aaffZinaGearCompare|r Settings")

    local yOffset = -50

    -- ── Checkbox: Skill Parity ──────────────────────────────────────────
    local spCheck = CreateFrame("CheckButton", "ZGCConfigSkillParity", configPanel, "InterfaceOptionsCheckButtonTemplate")
    spCheck:SetPoint("TOPLEFT", 16, yOffset)
    spCheck.Text:SetText("Enable Skill Parity (tooltip)")
    spCheck:SetChecked(ZinaGearCompareDB.skillParity)
    spCheck:SetScript("OnClick", function(self)
        ZinaGearCompareDB.skillParity = self:GetChecked()
    end)

    yOffset = yOffset - 30

    -- Descripción
    local spDesc = configPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    spDesc:SetPoint("TOPLEFT", 40, yOffset)
    spDesc:SetWidth(400)
    spDesc:SetJustifyH("LEFT")
    spDesc:SetText("|cffaaaaaaCompares your actual DPS vs expected DPS based on gear difference.\n" ..
        "Uses Blizzard's built-in Damage Meter (must be enabled in Options > Gameplay).\n" ..
        "Shows in tooltips and /zgc compare output.|r")

    yOffset = yOffset - 50

    -- ── Dropdown: Segment (Current / Overall) ───────────────────────────
    local segLabel = configPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    segLabel:SetPoint("TOPLEFT", 16, yOffset)
    segLabel:SetText("Damage Meter Segment:")

    yOffset = yOffset - 25

    local segCurrent = CreateFrame("CheckButton", "ZGCConfigSegCurrent", configPanel, "UIRadioButtonTemplate")
    segCurrent:SetPoint("TOPLEFT", 30, yOffset)
    segCurrent.Text = segCurrent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    segCurrent.Text:SetPoint("LEFT", segCurrent, "RIGHT", 4, 0)
    segCurrent.Text:SetText("Current Encounter (default)")

    local segOverall = CreateFrame("CheckButton", "ZGCConfigSegOverall", configPanel, "UIRadioButtonTemplate")
    segOverall:SetPoint("TOPLEFT", 30, yOffset - 22)
    segOverall.Text = segOverall:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    segOverall.Text:SetPoint("LEFT", segOverall, "RIGHT", 4, 0)
    segOverall.Text:SetText("Overall (full instance)")

    local function UpdateRadios()
        local isOverall = ZinaGearCompareDB.paritySegment == "overall"
        segCurrent:SetChecked(not isOverall)
        segOverall:SetChecked(isOverall)
    end
    UpdateRadios()

    segCurrent:SetScript("OnClick", function()
        ZinaGearCompareDB.paritySegment = "current"
        UpdateRadios()
    end)
    segOverall:SetScript("OnClick", function()
        ZinaGearCompareDB.paritySegment = "overall"
        UpdateRadios()
    end)

    yOffset = yOffset - 60

    -- ── Status del Damage Meter ─────────────────────────────────────────
    local dmStatus = configPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    dmStatus:SetPoint("TOPLEFT", 16, yOffset)
    dmStatus:SetWidth(400)
    dmStatus:SetJustifyH("LEFT")

    configPanel:SetScript("OnShow", function()
        spCheck:SetChecked(ZinaGearCompareDB.skillParity)
        UpdateRadios()
        local available, reason = ZGC_SkillParity.IsAvailable()
        if available then
            dmStatus:SetText("|cff00ff00Blizzard Damage Meter: Active|r")
        else
            dmStatus:SetText("|cffff4444Blizzard Damage Meter: Inactive|r\n" ..
                "|cffaaaaaaEnable it in Options > Gameplay Enhancements > Damage Meter|r")
        end
    end)

    -- Register with Settings API
    local category = Settings.RegisterCanvasLayoutCategory(configPanel, ADDON_NAME)
    category.ID = ADDON_NAME
    Settings.RegisterAddOnCategory(category)

    return configPanel
end

-- ── Minimap icon (LibDataBroker + LibDBIcon) ────────────────────────────────
local function InitMinimapIcon()
    local LDB = LibStub("LibDataBroker-1.1")
    local LDBIcon = LibStub("LibDBIcon-1.0")

    local dataObj = LDB:NewDataObject(ADDON_NAME, {
        type = "launcher",
        icon = ICON_TEXTURE,
        label = ADDON_NAME,
        text = "ZGC",

        OnClick = function(self, button)
            if button == "LeftButton" then
                Settings.OpenToCategory(ADDON_NAME)
            elseif button == "RightButton" then
                ZinaGearCompareDB.skillParity = not ZinaGearCompareDB.skillParity
                local state = ZinaGearCompareDB.skillParity and "|cff00ff00ON|r" or "|cffff4444OFF|r"
                print(string.format("|cff00aaff[ZGC]|r Skill Parity: %s", state))
            end
        end,

        OnTooltipShow = function(tooltip)
            tooltip:AddLine("|cff00aaffZinaGearCompare|r")
            tooltip:AddLine(" ")
            local spState = ZinaGearCompareDB.skillParity and "|cff00ff00ON|r" or "|cffff4444OFF|r"
            tooltip:AddDoubleLine("Skill Parity:", spState, 1, 1, 1)
            local seg = ZinaGearCompareDB.paritySegment == "overall" and "Overall" or "Current"
            tooltip:AddDoubleLine("Segment:", seg, 1, 1, 1, 0.7, 0.7, 0.7)
            tooltip:AddLine(" ")
            tooltip:AddLine("|cffaaaaaaLeft-click:|r Open settings", 1, 1, 1)
            tooltip:AddLine("|cffaaaaaaRight-click:|r Toggle Skill Parity", 1, 1, 1)
        end,
    })

    LDBIcon:Register(ADDON_NAME, dataObj, ZinaGearCompareDB.minimap)
end

-- ── Public init (called from ZinaGearCompare.lua ADDON_LOADED) ──────────────
function ZGC_InitConfig()
    InitConfigDB()
    CreateConfigPanel()
    local ok, err = pcall(InitMinimapIcon)
    if not ok then
        print("|cffff8800[ZGC]|r Minimap icon failed:", err)
    end
end
