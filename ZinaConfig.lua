-- ZinaConfig.lua — ZinaGearCompare
-- Minimap icon (LibDBIcon) + config panel.

local ADDON_NAME = "ZinaGearCompare"
local ICON_TEXTURE = 132089  -- INV_Chest_Plate16

-- ── DB defaults for config ──────────────────────────────────────────────────
local CONFIG_DEFAULTS = {
    mouseoverIlvl  = true,
    mouseoverPct   = true,
    minimap        = { hide = false },
}

-- ── Initialize config DB ──────────────────────────────────────────────────
local function InitConfigDB()
    if not ZinaGearCompareDB then ZinaGearCompareDB = {} end
    for k, v in pairs(CONFIG_DEFAULTS) do
        if ZinaGearCompareDB[k] == nil then
            if type(v) == "table" then
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
local configCategory = nil

local function CreateConfigPanel()
    if configPanel then return configPanel end

    configPanel = CreateFrame("Frame", "ZGCConfigPanel")
    configPanel.name = ADDON_NAME

    local title = configPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("|cff00aaffZinaGearCompare|r Settings")

    local yOffset = -50

    -- ── Active Mode ───────────────────────────────────────────────────
    local modeLabel = configPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    modeLabel:SetPoint("TOPLEFT", 16, yOffset)
    modeLabel:SetText("Active Mode")

    yOffset = yOffset - 20

    local modeDesc = configPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    modeDesc:SetPoint("TOPLEFT", 16, yOffset)
    modeDesc:SetWidth(400)
    modeDesc:SetJustifyH("LEFT")
    modeDesc:SetText("|cffaaaaaaDetermines which Raidbots sim profile is highlighted in tooltips.\n" ..
        "Auto detects M+ dungeons vs raid instances.|r")

    yOffset = yOffset - 35

    local modeAuto = CreateFrame("CheckButton", "ZGCConfigModeAuto", configPanel, "UIRadioButtonTemplate")
    modeAuto:SetPoint("TOPLEFT", 30, yOffset)
    modeAuto.Text = modeAuto:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    modeAuto.Text:SetPoint("LEFT", modeAuto, "RIGHT", 4, 0)
    modeAuto.Text:SetText("Auto (detect dungeon/raid)")

    local modeDungeon = CreateFrame("CheckButton", "ZGCConfigModeDungeon", configPanel, "UIRadioButtonTemplate")
    modeDungeon:SetPoint("TOPLEFT", 30, yOffset - 22)
    modeDungeon.Text = modeDungeon:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    modeDungeon.Text:SetPoint("LEFT", modeDungeon, "RIGHT", 4, 0)
    modeDungeon.Text:SetText("M+ / AoE")

    local modeRaid = CreateFrame("CheckButton", "ZGCConfigModeRaid", configPanel, "UIRadioButtonTemplate")
    modeRaid:SetPoint("TOPLEFT", 30, yOffset - 44)
    modeRaid.Text = modeRaid:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    modeRaid.Text:SetPoint("LEFT", modeRaid, "RIGHT", 4, 0)
    modeRaid.Text:SetText("Raid / Single Target")

    local function UpdateModeRadios()
        local override = ZinaGearCompareDB.contentOverride
        modeAuto:SetChecked(not override)
        modeDungeon:SetChecked(override == "dungeon")
        modeRaid:SetChecked(override == "raid")
    end

    modeAuto:SetScript("OnClick", function()
        ZinaGearCompareDB.contentOverride = nil
        UpdateModeRadios()
    end)
    modeDungeon:SetScript("OnClick", function()
        ZinaGearCompareDB.contentOverride = "dungeon"
        UpdateModeRadios()
    end)
    modeRaid:SetScript("OnClick", function()
        ZinaGearCompareDB.contentOverride = "raid"
        UpdateModeRadios()
    end)

    yOffset = yOffset - 80

    -- ── Player Tooltip (mouseover ilvl + tier) ────────────────────────
    local moHeader = configPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    moHeader:SetPoint("TOPLEFT", 16, yOffset)
    moHeader:SetText("Player Tooltip (Mouseover)")

    yOffset = yOffset - 22

    local moCheck = CreateFrame("CheckButton", "ZGCConfigMouseoverIlvl", configPanel, "InterfaceOptionsCheckButtonTemplate")
    moCheck:SetPoint("TOPLEFT", 16, yOffset)
    moCheck.Text:SetText("Show average ilvl and tier set on player tooltips")

    yOffset = yOffset - 25

    local pctCheck = CreateFrame("CheckButton", "ZGCConfigMouseoverPct", configPanel, "InterfaceOptionsCheckButtonTemplate")
    pctCheck:SetPoint("TOPLEFT", 30, yOffset)
    pctCheck.Text:SetText("Show ilvl difference as percentage")

    yOffset = yOffset - 25

    local moDesc = configPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    moDesc:SetPoint("TOPLEFT", 40, yOffset)
    moDesc:SetWidth(400)
    moDesc:SetJustifyH("LEFT")
    moDesc:SetText("|cffaaaaaaWhen hovering over another player, shows their average item\n" ..
        "level compared to yours, plus tier set pieces for both.|r")

    yOffset = yOffset - 45

    -- ── Sim Performance Panel ───────────────────────────────────────
    local simHeader = configPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    simHeader:SetPoint("TOPLEFT", 16, yOffset)
    simHeader:SetText("Sim Performance Panel")

    yOffset = yOffset - 22

    local simCheck = CreateFrame("CheckButton", "ZGCConfigSimPanel", configPanel, "InterfaceOptionsCheckButtonTemplate")
    simCheck:SetPoint("TOPLEFT", 16, yOffset)
    simCheck.Text:SetText("Show Sim Performance panel (actual DPS vs sim)")

    yOffset = yOffset - 22

    local simDesc = configPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    simDesc:SetPoint("TOPLEFT", 40, yOffset)
    simDesc:SetWidth(400)
    simDesc:SetJustifyH("LEFT")
    simDesc:SetText("|cffaaaaaaSmall floating panel showing your actual DPS (from Details!) vs\n" ..
        "your sim DPS (from Raidbots). Toggle with /zgc sim.|r")

    yOffset = yOffset - 40

    -- ── Raidbots Status ───────────────────────────────────────────────
    local rbHeader = configPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    rbHeader:SetPoint("TOPLEFT", 16, yOffset)
    rbHeader:SetText("Raidbots Import Status")

    yOffset = yOffset - 20

    local rbStatus = configPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    rbStatus:SetPoint("TOPLEFT", 16, yOffset)
    rbStatus:SetWidth(450)
    rbStatus:SetJustifyH("LEFT")

    yOffset = yOffset - 20

    local rbDetails = configPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    rbDetails:SetPoint("TOPLEFT", 16, yOffset)
    rbDetails:SetWidth(450)
    rbDetails:SetJustifyH("LEFT")

    yOffset = yOffset - 60

    local rbHelp = configPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    rbHelp:SetPoint("TOPLEFT", 16, yOffset)
    rbHelp:SetWidth(450)
    rbHelp:SetJustifyH("LEFT")
    rbHelp:SetText("|cffaaaaaaTo import Raidbots data:|r\n" ..
        "|cffffd7001.|r Run your Top Gear sim on raidbots.com\n" ..
        "|cffffd7002.|r Double-click tools\\raidbots_import.bat\n" ..
        "|cffffd7003.|r Paste the report URL and choose 'st' or 'aoe'\n" ..
        "|cffffd7004.|r /reload in game")

    -- ── Refresh: update dynamic content ─────────────────────────────
    local function RefreshConfigPanel()
        UpdateModeRadios()
        moCheck:SetChecked(ZinaGearCompareDB.mouseoverIlvl ~= false)
        pctCheck:SetChecked(ZinaGearCompareDB.mouseoverPct ~= false)
        local simVis = ZinaGearCompareDB.simPanel and ZinaGearCompareDB.simPanel.visible or false
        simCheck:SetChecked(simVis)

        -- Raidbots status
        local rbInfo = ZGC_GetRaidbotsTooltipInfo and ZGC_GetRaidbotsTooltipInfo()
        if rbInfo then
            local lines = {}
            for _, info in ipairs(rbInfo) do
                table.insert(lines, string.format(
                    "|cffffd700%s:|r  %s  —  %.1fk DPS baseline  —  %d items simmed",
                    info.label, info.date, info.dps / 1000, info.items))
            end
            rbStatus:SetText("|cff00ff00Data loaded|r")
            rbDetails:SetText(table.concat(lines, "\n"))
        else
            rbStatus:SetText("|cffff4444No Raidbots data imported|r")
            rbDetails:SetText("")
        end
    end

    -- Set initial state at creation time
    RefreshConfigPanel()

    -- HookScript so Settings API cannot overwrite our handler
    configPanel:HookScript("OnShow", RefreshConfigPanel)

    moCheck:SetScript("OnClick", function(self)
        local v = not ZinaGearCompareDB.mouseoverIlvl
        ZinaGearCompareDB.mouseoverIlvl = v
        self:SetChecked(v)
    end)
    pctCheck:SetScript("OnClick", function(self)
        local v = not ZinaGearCompareDB.mouseoverPct
        ZinaGearCompareDB.mouseoverPct = v
        self:SetChecked(v)
    end)
    simCheck:SetScript("OnClick", function(self)
        local show = not (ZinaGearCompareDB.simPanel and ZinaGearCompareDB.simPanel.visible)
        self:SetChecked(show)
        if ZGC_ToggleSimPanel then ZGC_ToggleSimPanel(show) end
    end)

    -- Register with Settings API
    configCategory = Settings.RegisterCanvasLayoutCategory(configPanel, ADDON_NAME)
    Settings.RegisterAddOnCategory(configCategory)

    -- Create Appearance sub-category
    CreateAppearancePanel(configCategory)

    return configPanel
end

-- ── Appearance sub-panel ────────────────────────────────────────────────────
local APPEARANCE_DEFAULTS = {
    showBagGlow     = true,
    bagGlowScale    = 1.6,
    showTooltipST   = true,
    showTooltipAoE  = true,
    showTooltipDate = true,
}

local function InitAppearanceDB()
    if not ZinaGearCompareDB.appearance then
        ZinaGearCompareDB.appearance = {}
    end
    for k, v in pairs(APPEARANCE_DEFAULTS) do
        if ZinaGearCompareDB.appearance[k] == nil then
            ZinaGearCompareDB.appearance[k] = v
        end
    end
end

function ZGC_GetAppearance(key)
    if ZinaGearCompareDB and ZinaGearCompareDB.appearance then
        local v = ZinaGearCompareDB.appearance[key]
        if v ~= nil then return v end
    end
    return APPEARANCE_DEFAULTS[key]
end

function CreateAppearancePanel(parentCategory)
    local panel = CreateFrame("Frame", "ZGCAppearancePanel")
    panel.name = "Appearance"

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("|cff00aaffAppearance|r")

    local yOffset = -50

    -- ── Bag Glow ──────────────────────────────────────────────────────
    local glowHeader = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    glowHeader:SetPoint("TOPLEFT", 16, yOffset)
    glowHeader:SetText("Bag Item Glow")
    yOffset = yOffset - 22

    local glowCheck = CreateFrame("CheckButton", "ZGCAppGlow", panel, "InterfaceOptionsCheckButtonTemplate")
    glowCheck:SetPoint("TOPLEFT", 16, yOffset)
    glowCheck.Text:SetText("Show green glow on BIS items in bags")
    yOffset = yOffset - 25

    local glowDesc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    glowDesc:SetPoint("TOPLEFT", 40, yOffset)
    glowDesc:SetWidth(400)
    glowDesc:SetJustifyH("LEFT")
    glowDesc:SetText("|cffaaaaaaHighlights items in your bags that are Best-in-Slot according\n" ..
        "to your Raidbots sim for the currently active mode (ST or AoE).\n" ..
        "Only shows when your current spec matches the imported sim.|r")
    yOffset = yOffset - 55

    -- ── Tooltip Lines ─────────────────────────────────────────────────
    local ttHeader = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ttHeader:SetPoint("TOPLEFT", 16, yOffset)
    ttHeader:SetText("Item Tooltip")
    yOffset = yOffset - 22

    local ttST = CreateFrame("CheckButton", "ZGCAppTTST", panel, "InterfaceOptionsCheckButtonTemplate")
    ttST:SetPoint("TOPLEFT", 16, yOffset)
    ttST.Text:SetText("Show Raidbots ST line")
    yOffset = yOffset - 24

    local ttAoE = CreateFrame("CheckButton", "ZGCAppTTAoE", panel, "InterfaceOptionsCheckButtonTemplate")
    ttAoE:SetPoint("TOPLEFT", 16, yOffset)
    ttAoE.Text:SetText("Show Raidbots AoE line")
    yOffset = yOffset - 24

    local ttDate = CreateFrame("CheckButton", "ZGCAppTTDate", panel, "InterfaceOptionsCheckButtonTemplate")
    ttDate:SetPoint("TOPLEFT", 16, yOffset)
    ttDate.Text:SetText("Show sim date in tooltip")
    yOffset = yOffset - 30

    local ttDesc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ttDesc:SetPoint("TOPLEFT", 40, yOffset)
    ttDesc:SetWidth(400)
    ttDesc:SetJustifyH("LEFT")
    ttDesc:SetText("|cffaaaaaaControl which lines appear when hovering over items.\n" ..
        "The active mode line is always highlighted; the other is dimmed.|r")

    -- ── Refresh checkbox state ───────────────────────────────────────
    local function RefreshAppearancePanel()
        InitAppearanceDB()
        local a = ZinaGearCompareDB.appearance
        glowCheck:SetChecked(a.showBagGlow)
        ttST:SetChecked(a.showTooltipST)
        ttAoE:SetChecked(a.showTooltipAoE)
        ttDate:SetChecked(a.showTooltipDate)
    end

    -- Set initial state at creation time
    RefreshAppearancePanel()

    -- HookScript so Settings API cannot overwrite our handler
    panel:HookScript("OnShow", RefreshAppearancePanel)

    glowCheck:SetScript("OnClick", function(self)
        InitAppearanceDB()
        local v = not ZinaGearCompareDB.appearance.showBagGlow
        ZinaGearCompareDB.appearance.showBagGlow = v
        self:SetChecked(v)
    end)
    ttST:SetScript("OnClick", function(self)
        InitAppearanceDB()
        local v = not ZinaGearCompareDB.appearance.showTooltipST
        ZinaGearCompareDB.appearance.showTooltipST = v
        self:SetChecked(v)
    end)
    ttAoE:SetScript("OnClick", function(self)
        InitAppearanceDB()
        local v = not ZinaGearCompareDB.appearance.showTooltipAoE
        ZinaGearCompareDB.appearance.showTooltipAoE = v
        self:SetChecked(v)
    end)
    ttDate:SetScript("OnClick", function(self)
        InitAppearanceDB()
        local v = not ZinaGearCompareDB.appearance.showTooltipDate
        ZinaGearCompareDB.appearance.showTooltipDate = v
        self:SetChecked(v)
    end)

    -- Register sub-category
    pcall(function()
        Settings.RegisterCanvasLayoutSubcategory(parentCategory, panel, "Appearance")
    end)
end

-- ── Public: expose configCategory ───────────────────────────────────────────
function ZGC_GetConfigCategory()
    return configCategory
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
                if configCategory then
                    Settings.OpenToCategory(configCategory:GetID())
                end
            elseif button == "RightButton" then
                -- Cycle mode: auto → dungeon → raid → auto
                local cur = ZinaGearCompareDB.contentOverride
                if not cur then
                    ZinaGearCompareDB.contentOverride = "dungeon"
                    print("|cff00aaff[ZGC]|r Mode: |cffaad4ffM+ (AoE)|r")
                elseif cur == "dungeon" then
                    ZinaGearCompareDB.contentOverride = "raid"
                    print("|cff00aaff[ZGC]|r Mode: |cffFFD700Raid (ST)|r")
                else
                    ZinaGearCompareDB.contentOverride = nil
                    print("|cff00aaff[ZGC]|r Mode: |cffaaaaaaAuto|r")
                end
            end
        end,

        OnTooltipShow = function(tooltip)
            tooltip:AddLine("|cff00aaffZinaGearCompare|r")
            tooltip:AddLine(" ")

            -- Active mode
            local cType = ZGC_GetContentType and ZGC_GetContentType() or "?"
            local modeLabel = cType == "raid" and "|cffFFD700Raid (ST)|r" or "|cffaad4ffM+ (AoE)|r"
            local override = ZinaGearCompareDB and ZinaGearCompareDB.contentOverride
            if not override then
                modeLabel = modeLabel .. " |cffaaaaaa(auto)|r"
            end
            tooltip:AddDoubleLine("Active mode:", modeLabel, 1, 1, 1)

            -- Raidbots sim dates + spec match
            local rbInfo = ZGC_GetRaidbotsTooltipInfo and ZGC_GetRaidbotsTooltipInfo()
            if rbInfo then
                tooltip:AddLine(" ")
                for _, info in ipairs(rbInfo) do
                    local specTag = info.active
                        and string.format("|cff00ff00%s|r", info.specName)
                        or  string.format("|cff666666%s|r", info.specName)
                    tooltip:AddDoubleLine(
                        string.format("Raidbots %s:", info.label),
                        string.format("%s  %s  |cffaaaaaa(%.1fk · %d items)|r",
                            info.date, specTag, info.dps / 1000, info.items),
                        0, 0.67, 1, 0.7, 0.7, 0.7)
                end

                -- Slot coverage for the active sim type
                if ZGC_GetSlotCoverage then
                    local simmed, equipped, unsimmed = ZGC_GetSlotCoverage()
                    if equipped > 0 then
                        tooltip:AddLine(" ")
                        local covCol = simmed == equipped and "|cff00ff00" or "|cffFFD700"
                        tooltip:AddLine(string.format(
                            "Slot coverage: %s%d/%d|r equipped slots simulated",
                            covCol, simmed, equipped))
                        if #unsimmed > 0 then
                            for _, slot in ipairs(unsimmed) do
                                tooltip:AddLine(string.format(
                                    "  |cffff8800!|r %s: |cffffffff%s|r |cffaaaaaa(%d)|r",
                                    slot.label, slot.name, slot.ilvl))
                            end
                        end
                    end
                end
            end

            tooltip:AddLine(" ")
            tooltip:AddLine("|cffaaaaaaLeft-click:|r Open settings", 1, 1, 1)
            tooltip:AddLine("|cffaaaaaaRight-click:|r Cycle mode (Auto/M+/Raid)", 1, 1, 1)
            tooltip:AddLine("|cffaaaaaa/zgc sim:|r Toggle DPS performance panel", 1, 1, 1)
        end,
    })

    LDBIcon:Register(ADDON_NAME, dataObj, ZinaGearCompareDB.minimap)
end

-- ── Public init (called from ZinaGearCompare.lua ADDON_LOADED) ──────────────
function ZGC_InitConfig()
    InitConfigDB()
    InitAppearanceDB()
    CreateConfigPanel()
    local ok, err = pcall(InitMinimapIcon)
    if not ok then
        print("|cffff8800[ZGC]|r Minimap icon failed:", err)
    end
end
