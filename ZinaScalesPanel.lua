-- ZinaScalesPanel.lua — ZinaGearCompare
-- "All Scales" sub-category under ZinaGearCompare in Settings.
-- Shows a scrollable list of ALL specs grouped by class with M+ and Raid weights.

-- ── Spec info fallback table (for when GetSpecializationInfoByID is unavailable) ──
local SPEC_INFO = {
    [250]  = { class = "Death Knight",  spec = "Blood",          classFile = "DEATHKNIGHT" },
    [251]  = { class = "Death Knight",  spec = "Frost",          classFile = "DEATHKNIGHT" },
    [252]  = { class = "Death Knight",  spec = "Unholy",         classFile = "DEATHKNIGHT" },
    [577]  = { class = "Demon Hunter",  spec = "Havoc",          classFile = "DEMONHUNTER" },
    [581]  = { class = "Demon Hunter",  spec = "Vengeance",      classFile = "DEMONHUNTER" },
    [1480] = { class = "Demon Hunter",  spec = "Devourer",       classFile = "DEMONHUNTER" },
    [102]  = { class = "Druid",         spec = "Balance",        classFile = "DRUID" },
    [103]  = { class = "Druid",         spec = "Feral",          classFile = "DRUID" },
    [104]  = { class = "Druid",         spec = "Guardian",       classFile = "DRUID" },
    [105]  = { class = "Druid",         spec = "Restoration",    classFile = "DRUID" },
    [1467] = { class = "Evoker",        spec = "Devastation",    classFile = "EVOKER" },
    [1468] = { class = "Evoker",        spec = "Preservation",   classFile = "EVOKER" },
    [1473] = { class = "Evoker",        spec = "Augmentation",   classFile = "EVOKER" },
    [253]  = { class = "Hunter",        spec = "Beast Mastery",  classFile = "HUNTER" },
    [254]  = { class = "Hunter",        spec = "Marksmanship",   classFile = "HUNTER" },
    [255]  = { class = "Hunter",        spec = "Survival",       classFile = "HUNTER" },
    [62]   = { class = "Mage",          spec = "Arcane",         classFile = "MAGE" },
    [63]   = { class = "Mage",          spec = "Fire",           classFile = "MAGE" },
    [64]   = { class = "Mage",          spec = "Frost",          classFile = "MAGE" },
    [268]  = { class = "Monk",          spec = "Brewmaster",     classFile = "MONK" },
    [269]  = { class = "Monk",          spec = "Windwalker",     classFile = "MONK" },
    [270]  = { class = "Monk",          spec = "Mistweaver",     classFile = "MONK" },
    [65]   = { class = "Paladin",       spec = "Holy",           classFile = "PALADIN" },
    [66]   = { class = "Paladin",       spec = "Protection",     classFile = "PALADIN" },
    [70]   = { class = "Paladin",       spec = "Retribution",    classFile = "PALADIN" },
    [256]  = { class = "Priest",        spec = "Discipline",     classFile = "PRIEST" },
    [257]  = { class = "Priest",        spec = "Holy",           classFile = "PRIEST" },
    [258]  = { class = "Priest",        spec = "Shadow",         classFile = "PRIEST" },
    [259]  = { class = "Rogue",         spec = "Assassination",  classFile = "ROGUE" },
    [260]  = { class = "Rogue",         spec = "Outlaw",         classFile = "ROGUE" },
    [261]  = { class = "Rogue",         spec = "Subtlety",       classFile = "ROGUE" },
    [262]  = { class = "Shaman",        spec = "Elemental",      classFile = "SHAMAN" },
    [263]  = { class = "Shaman",        spec = "Enhancement",    classFile = "SHAMAN" },
    [264]  = { class = "Shaman",        spec = "Restoration",    classFile = "SHAMAN" },
    [265]  = { class = "Warlock",       spec = "Affliction",     classFile = "WARLOCK" },
    [266]  = { class = "Warlock",       spec = "Demonology",     classFile = "WARLOCK" },
    [267]  = { class = "Warlock",       spec = "Destruction",    classFile = "WARLOCK" },
    [71]   = { class = "Warrior",       spec = "Arms",           classFile = "WARRIOR" },
    [72]   = { class = "Warrior",       spec = "Fury",           classFile = "WARRIOR" },
    [73]   = { class = "Warrior",       spec = "Protection",     classFile = "WARRIOR" },
}

-- Class display order
local CLASS_ORDER = {
    "DEATHKNIGHT", "DEMONHUNTER", "DRUID", "EVOKER",
    "HUNTER", "MAGE", "MONK", "PALADIN", "PRIEST",
    "ROGUE", "SHAMAN", "WARLOCK", "WARRIOR",
}

-- Class file → display name
local CLASS_DISPLAY = {
    DEATHKNIGHT = "Death Knight", DEMONHUNTER = "Demon Hunter",
    DRUID = "Druid", EVOKER = "Evoker", HUNTER = "Hunter",
    MAGE = "Mage", MONK = "Monk", PALADIN = "Paladin",
    PRIEST = "Priest", ROGUE = "Rogue", SHAMAN = "Shaman",
    WARLOCK = "Warlock", WARRIOR = "Warrior",
}

-- ── Helpers ─────────────────────────────────────────────────────────────────

local function GetStatPriority(weights)
    if not weights then return "?" end
    local stats = {
        { name = "Crit",    val = weights.crit or 0 },
        { name = "Haste",   val = weights.haste or 0 },
        { name = "Mastery", val = weights.mastery or 0 },
        { name = "Vers",    val = weights.versatility or 0 },
    }
    table.sort(stats, function(a, b) return a.val > b.val end)
    local parts = {}
    for _, s in ipairs(stats) do
        parts[#parts + 1] = s.name
    end
    return table.concat(parts, " > ")
end

local function GetSpecName(specID)
    -- Try runtime API first
    if GetSpecializationInfoByID then
        local _, name = GetSpecializationInfoByID(specID)
        if name then return name end
    end
    local info = SPEC_INFO[specID]
    return info and info.spec or tostring(specID)
end

local function GetClassColor(classFile)
    if RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile] then
        local c = RAID_CLASS_COLORS[classFile]
        return string.format("|cff%02x%02x%02x", c.r * 255, c.g * 255, c.b * 255)
    end
    return "|cffcccccc"
end

-- ── Panel creation ──────────────────────────────────────────────────────────

local scalesPanel = nil

local function PopulateScalesPanel(scrollChild)
    -- Clear existing children
    local children = { scrollChild:GetChildren() }
    for _, child in ipairs(children) do child:Hide() end

    local yOffset = 0
    local playerSpecID = ZGC_GetSpecIDForUnit and ZGC_GetSpecIDForUnit("player") or nil

    -- Group specs by class
    local byClass = {}
    for specID, info in pairs(SPEC_INFO) do
        if not byClass[info.classFile] then byClass[info.classFile] = {} end
        byClass[info.classFile][#byClass[info.classFile] + 1] = specID
    end
    -- Sort specs within each class by specID
    for _, specs in pairs(byClass) do
        table.sort(specs)
    end

    for _, classFile in ipairs(CLASS_ORDER) do
        local specs = byClass[classFile]
        if specs then
            local classColor = GetClassColor(classFile)
            local className = CLASS_DISPLAY[classFile] or classFile

            -- Class header
            local header = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            header:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 4, yOffset)
            header:SetText(string.format("%s%s|r", classColor, className))
            yOffset = yOffset - 18

            for _, specID in ipairs(specs) do
                local sw = ZGC_StatWeights and ZGC_StatWeights[specID]
                if sw then
                    local specName = GetSpecName(specID)
                    local source = sw.source or "Unknown"
                    local isPlayer = (specID == playerSpecID)
                    local marker = isPlayer and "|cff00ff00>> |r" or "   "

                    -- Spec name + source
                    local specLine = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                    specLine:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 8, yOffset)
                    specLine:SetWidth(500)
                    specLine:SetJustifyH("LEFT")
                    specLine:SetText(string.format("%s%s%s %s|r (%d)  |cffaaaaaa[%s]|r",
                        marker, classColor, specName, className, specID, source))
                    yOffset = yOffset - 14

                    -- M+ weights
                    local dw = sw.dungeon
                    if dw then
                        local mLine = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                        mLine:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 24, yOffset)
                        mLine:SetWidth(500)
                        mLine:SetJustifyH("LEFT")
                        mLine:SetText(string.format("|cffaad4ffM+:|r   crit=%.3f  haste=%.3f  mastery=%.3f  vers=%.3f",
                            dw.crit, dw.haste, dw.mastery, dw.versatility))
                        yOffset = yOffset - 13
                    end

                    -- Raid weights
                    local rw = sw.raid
                    if rw then
                        local rLine = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                        rLine:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 24, yOffset)
                        rLine:SetWidth(500)
                        rLine:SetJustifyH("LEFT")
                        rLine:SetText(string.format("|cffFFD700Raid:|r  crit=%.3f  haste=%.3f  mastery=%.3f  vers=%.3f",
                            rw.crit, rw.haste, rw.mastery, rw.versatility))
                        yOffset = yOffset - 13
                    end

                    -- Priority
                    local priLine = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                    priLine:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 24, yOffset)
                    priLine:SetWidth(500)
                    priLine:SetJustifyH("LEFT")
                    priLine:SetText(string.format("|cffaaaaaaPriority:|r  %s", GetStatPriority(dw or rw)))
                    yOffset = yOffset - 16
                end
            end

            yOffset = yOffset - 6  -- gap between classes
        end
    end

    scrollChild:SetHeight(math.abs(yOffset) + 20)
end

function ZGC_InitScalesPanel(parentCategory)
    if scalesPanel then return end

    scalesPanel = CreateFrame("Frame", "ZGCScalesPanel")
    scalesPanel.name = "All Scales"

    local title = scalesPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("|cff00aaffAll Spec Scales|r")

    local subtitle = scalesPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    subtitle:SetText("|cffaaaaaaAll 29 specs with M+ and Raid stat weights. Your current spec is marked with >>.|r")

    -- ScrollFrame
    local scrollFrame = CreateFrame("ScrollFrame", "ZGCScalesScroll", scalesPanel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -52)
    scrollFrame:SetPoint("BOTTOMRIGHT", -28, 10)

    local scrollChild = CreateFrame("Frame", "ZGCScalesScrollChild")
    scrollChild:SetWidth(scrollFrame:GetWidth() or 540)
    scrollChild:SetHeight(1)  -- will be set dynamically
    scrollFrame:SetScrollChild(scrollChild)

    scalesPanel:SetScript("OnShow", function()
        scrollChild:SetWidth(scrollFrame:GetWidth() or 540)
        PopulateScalesPanel(scrollChild)
    end)

    -- Register as sub-category
    local ok, err = pcall(function()
        local scalesCategory = Settings.RegisterCanvasLayoutSubcategory(
            parentCategory, scalesPanel, "All Scales")
    end)
    if not ok then
        print("|cffff8800[ZGC]|r Failed to register All Scales sub-category:", err)
    end
end
