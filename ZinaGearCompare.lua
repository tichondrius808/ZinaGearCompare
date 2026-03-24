-- ZinaGearCompare.lua — Addon entry point
-- Mouseover tooltip: ilvl comparison + tier set (uses Blizzard API, no stat weights).
-- Item scoring (PaperDoll, InspectUI): uses ZinaStatWeights + Scoring.lua.

local ADDON_NAME = "ZinaGearCompare"
local ZGC_PAUSED = false

-- ── SavedVariables defaults ─────────────────────────────────────────────────
local DB_DEFAULTS = {
    version         = 2,
    contentOverride = nil,  -- nil = auto-detect | "dungeon" | "raid"
}

-- ── Event frame ─────────────────────────────────────────────────────────────
local eventFrame = CreateFrame("Frame", ADDON_NAME .. "EventFrame")

-- ── Tier tag helper ─────────────────────────────────────────────────────────
local function ZGC_TierTag(unit)
    local count = ZGC_CountTierPieces(unit)
    if count >= 4 then return " |cffFFD7004pc|r"
    elseif count >= 2 then return " |cffaad4ff2pc|r"
    else return "" end
end

-- ── PaperDoll score text ────────────────────────────────────────────────────
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
        zgcPaperDollText:SetText("|cffaaaaaa[ZGC] spec not detected|r")
        return
    end
    if total and total > 0 then
        local label = contentType == "raid" and "Raid" or "M+"
        local tierTag = ZGC_TierTag("player")
        zgcPaperDollText:SetText(string.format(
            "|cff00aaffZGC Score:|r |cffffd700%.0f|r  |cffaaaaaa[%s · %s · %d slots%s]|r",
            total, specName or "?", label, slots, tierTag))
    else
        zgcPaperDollText:SetText("|cffaaaaaaZGC: calculating...|r")
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
        print("|cffff8800[ZinaGearCompare]|r PaperDoll hook failed:", err)
        zgcPaperDollText = nil
    end
end

-- ── Mouseover inspection cache ──────────────────────────────────────────────
local zgcMouseoverName      = nil
local zgcMouseoverRealm     = nil
local zgcMouseoverTheirIlvl = nil
local zgcMouseoverMyIlvl    = nil
local zgcMouseoverTheirTier = nil
local zgcMouseoverMyTier    = nil
local zgcMouseoverFallback  = nil
local zgcMouseoverReady     = false
local zgcMouseoverPending   = false
local zgcMouseoverWaiting   = false
local zgcPrintPending       = false

local function ZGC_GetMouseoverNameRealm()
    local n, r = UnitName("mouseover")
    if not r or r == "" then r = GetRealmName() end
    return n, r
end

-- ── Helper: add mouseover line to a tooltip ─────────────────────────────────
local function AddMouseoverTooltipLines(tooltip)
    if zgcMouseoverFallback then
        tooltip:AddLine(string.format("|cff00aaffZGC:|r |cffaaaaaa%s|r", zgcMouseoverFallback))
        tooltip:Show()
        return
    end
    if not zgcMouseoverTheirIlvl then return end

    -- ilvl line: "ZGC: ilvl 623 (you: 618)  +0.8%"
    local ilvlLine
    local theirIlvl = zgcMouseoverTheirIlvl
    if zgcMouseoverMyIlvl and zgcMouseoverMyIlvl > 0 then
        local diff = theirIlvl - zgcMouseoverMyIlvl
        local col = diff > 2 and "|cff00ff00" or diff < -2 and "|cffff4444" or "|cffffd700"
        local pctSuffix = ""
        if ZinaGearCompareDB and ZinaGearCompareDB.mouseoverPct ~= false then
            local pct = (theirIlvl / zgcMouseoverMyIlvl - 1) * 100
            local sign = pct >= 0 and "+" or ""
            pctSuffix = string.format("  %s%s%.1f%%|r", col, sign, pct)
        end
        ilvlLine = string.format("|cff00aaffZGC:|r %silvl %.0f|r |cffaaaaaa(you: %.0f)|r%s",
            col, theirIlvl, zgcMouseoverMyIlvl, pctSuffix)
    else
        ilvlLine = string.format("|cff00aaffZGC:|r |cffffd700ilvl %.0f|r", theirIlvl)
    end

    -- tier line: "Tier 4pc (you: 2pc)"
    local tierLine = ""
    local theirTier = zgcMouseoverTheirTier or 0
    local myTier    = zgcMouseoverMyTier or 0
    if theirTier > 0 or myTier > 0 then
        local theirTag = theirTier >= 4 and "4pc" or theirTier >= 2 and "2pc" or "0pc"
        local myTag    = myTier >= 4 and "4pc" or myTier >= 2 and "2pc" or "0pc"
        local col = theirTier > myTier and "|cff00ff00" or theirTier < myTier and "|cffff4444" or "|cffffd700"
        tierLine = string.format("  %sTier %s|r |cffaaaaaa(you: %s)|r", col, theirTag, myTag)
    end

    tooltip:AddLine(ilvlLine)
    if tierLine ~= "" then
        tooltip:AddLine(tierLine)
    end
    tooltip:Show()
end

local function ZGC_InjectMouseoverTooltip()
    if not GameTooltip:IsVisible() then return end
    if not UnitIsPlayer("mouseover") then return end
    local tn, tr = ZGC_GetMouseoverNameRealm()
    if tn ~= zgcMouseoverName or tr ~= zgcMouseoverRealm then return end
    if GameTooltip.zgcScoreAdded then return end
    GameTooltip.zgcScoreAdded = true
    AddMouseoverTooltipLines(GameTooltip)
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
    zgcMouseoverTheirIlvl = nil
    zgcMouseoverMyIlvl    = nil
    zgcMouseoverTheirTier = nil
    zgcMouseoverMyTier    = nil
    zgcMouseoverFallback  = nil
    zgcMouseoverReady     = false
    zgcMouseoverPending   = true
    pendingInspectUnit    = "mouseover"
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
    zgcMouseoverTheirIlvl = nil
    zgcMouseoverMyIlvl    = nil
    zgcMouseoverTheirTier = nil
    zgcMouseoverMyTier    = nil
    zgcMouseoverFallback  = nil
    zgcMouseoverWaiting   = true
    C_Timer.After(0.1, ZGC_TryMouseoverInspect)
end

-- ── GameTooltip hook ────────────────────────────────────────────────────────
local function HookGameTooltip()
    if not TooltipDataProcessor then return end
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip, data)
        if not data then return end
        if not ZinaGearCompareDB or ZinaGearCompareDB.mouseoverIlvl == false then return end

        -- Own player
        if UnitExists("mouseover") and UnitIsUnit("mouseover", "player") then
            local _, avgEquipped = GetAverageItemLevel()
            if avgEquipped and avgEquipped > 0 then
                local tierCount = ZGC_CountTierPieces and ZGC_CountTierPieces("player") or 0
                local tierTag = tierCount >= 4 and " |cffFFD7004pc|r" or tierCount >= 2 and " |cffaad4ff2pc|r" or ""
                tooltip:AddLine(string.format("|cff00aaffZGC:|r |cffffd700ilvl %.0f|r%s",
                    avgEquipped, tierTag))
            end
            tooltip:Show()
            return
        end

        -- Other player: show cached data or loading/error
        if not UnitIsPlayer("mouseover") then return end
        if not zgcMouseoverReady then
            if zgcMouseoverPending or zgcMouseoverWaiting then
                tooltip:AddLine("|cff00aaffZGC:|r |cffaaaaaainspecting gear...|r")
                tooltip:Show()
            end
            return
        end
        local n, r = ZGC_GetMouseoverNameRealm()
        if n ~= zgcMouseoverName or r ~= zgcMouseoverRealm then return end
        tooltip.zgcScoreAdded = true
        AddMouseoverTooltipLines(tooltip)
    end)
end
if not ZGC_PAUSED then
    GameTooltip:HookScript("OnTooltipCleared", function(self)
        self.zgcScoreAdded = false
    end)
    GameTooltip:HookScript("OnHide", function(self)
        self.zgcScoreAdded = false
    end)
end

-- ── Details! integration ────────────────────────────────────────────────────
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
            segName    = combat:GetCombatName(true) or "unknown segment",
        }
    end

    return findBothInCombat(Details:GetCombat(0))
        or findBothInCombat(Details:GetCombat(1))
end

-- ── Details! deferred init ──────────────────────────────────────────────────
local function TryInitDetails()
    if ZGC_InitDetails then
        pcall(ZGC_InitDetails)
    end
end

-- ── ADDON_LOADED ────────────────────────────────────────────────────────────
local function OnAddonLoaded(addonName)
    if addonName ~= ADDON_NAME then return end

    if ZGC_PAUSED then
        print("|cff00aaff[ZinaGearCompare]|r |cffff8800PAUSED|r — This addon is under development and not functional yet.")
        print("|cff00aaff[ZinaGearCompare]|r Type |cffffd700/zgc|r for info. Stay tuned!")
        return
    end

    if addonName == "Details" then
        -- Details! just loaded, try registering our custom display
        C_Timer.After(1, TryInitDetails)
        return
    end

    if not ZinaGearCompareDB then
        ZinaGearCompareDB = {}
    end
    for k, v in pairs(DB_DEFAULTS) do
        if ZinaGearCompareDB[k] == nil then
            ZinaGearCompareDB[k] = v
        end
    end

    ZGC_InitConfig()
    ZGC_InitUI()
    InitPaperDoll()
    if ZGC_InitSimPanel then ZGC_InitSimPanel() end
    pcall(HookGameTooltip)

    -- Try Details! init immediately if already loaded, otherwise defer
    if _G.Details then
        C_Timer.After(1, TryInitDetails)
    else
        C_Timer.After(3, TryInitDetails)
    end

    local specID   = ZGC_GetSpecIDForUnit("player")
    local specName = ZGC_GetSpecNameForUnit("player") or "unknown"
    if specID and ZGC_StatWeights and ZGC_StatWeights[specID] then
        print(string.format("|cff00aaff[ZinaGearCompare]|r Loaded. Spec: %s. " ..
              "Open your character panel or inspect someone to see Gear Quality.",
              specName))
    else
        print("|cff00aaff[ZinaGearCompare]|r Loaded. " ..
              "(Spec not detected yet — open character panel to update.)")
    end
end

-- ── INSPECT_READY ───────────────────────────────────────────────────────────
local pendingUnit        = nil
local pendingInspectUnit = nil  -- unit passed to NotifyInspect(); avoids comparing tainted guid (12.0+)

local function OnInspectReady(unit)
    local target = unit or pendingUnit
    if not target then return end
    if InspectFrame and InspectFrame:IsShown() then
        ZGC_OnInspectReady(target)
    end
end

-- ── PLAYER_EQUIPMENT_CHANGED ────────────────────────────────────────────────
local function OnPlayerEquipmentChanged()
    if InspectFrame and InspectFrame:IsShown() then
        ZGC_UpdatePanel()
    end
    UpdatePaperDollScore()
end

-- ── Event dispatcher ────────────────────────────────────────────────────────
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        OnAddonLoaded(...)
        if ZGC_PAUSED then return end

    elseif event == "INSPECT_READY" then
        -- Don't read guid from event: in 12.0+ it's a "secret string" (tainted) and comparing
        -- it with UnitGUID() (clean) causes taint. We use pendingInspectUnit saved before
        -- calling NotifyInspect().
        local unit = pendingInspectUnit or pendingUnit
        pendingInspectUnit = nil
        if unit then
            pendingUnit = unit
        end
        OnInspectReady(unit or pendingUnit)

        -- Mouseover path — ilvl + tier comparison
        if zgcMouseoverPending then
            zgcMouseoverPending = false
            if UnitIsPlayer("mouseover") then
                local n, r = ZGC_GetMouseoverNameRealm()
                zgcMouseoverName  = n
                zgcMouseoverRealm = r

                -- Their average ilvl (Blizzard API)
                local theirIlvl = C_PaperDollInfo and C_PaperDollInfo.GetInspectItemLevel("mouseover")
                if theirIlvl and theirIlvl > 0 then
                    zgcMouseoverTheirIlvl = theirIlvl
                    -- Our average ilvl
                    local _, myEquipped = GetAverageItemLevel()
                    zgcMouseoverMyIlvl = myEquipped or 0
                    -- Tier pieces
                    zgcMouseoverTheirTier = ZGC_CountTierPieces and ZGC_CountTierPieces("mouseover") or 0
                    zgcMouseoverMyTier    = ZGC_CountTierPieces and ZGC_CountTierPieces("player") or 0
                else
                    -- ilvl came back as 0 — gear data not ready, retry once
                    zgcMouseoverFallback = "gear data not available"
                    C_Timer.After(1.5, function()
                        if zgcMouseoverName ~= n then return end
                        if not UnitIsPlayer("mouseover") then return end
                        local retryIlvl = C_PaperDollInfo and C_PaperDollInfo.GetInspectItemLevel("mouseover")
                        if retryIlvl and retryIlvl > 0 then
                            zgcMouseoverTheirIlvl = retryIlvl
                            local _, myEq = GetAverageItemLevel()
                            zgcMouseoverMyIlvl = myEq or 0
                            zgcMouseoverTheirTier = ZGC_CountTierPieces and ZGC_CountTierPieces("mouseover") or 0
                            zgcMouseoverMyTier    = ZGC_CountTierPieces and ZGC_CountTierPieces("player") or 0
                            zgcMouseoverFallback  = nil
                            ZGC_InjectMouseoverTooltip()
                        end
                    end)
                end
                zgcMouseoverReady = true
                ZGC_InjectMouseoverTooltip()
            end
        end

        -- /zgc compare path — ilvl + tier
        if zgcPrintPending then
            zgcPrintPending = false
            local cmpUnit = pendingUnit or "target"
            if cmpUnit then
                local name = UnitName(cmpUnit) or "?"
                local theirIlvl = C_PaperDollInfo and C_PaperDollInfo.GetInspectItemLevel(cmpUnit)
                if theirIlvl and theirIlvl > 0 then
                    local _, myEquipped = GetAverageItemLevel()
                    local theirTier = ZGC_CountTierPieces and ZGC_CountTierPieces(cmpUnit) or 0
                    local myTier    = ZGC_CountTierPieces and ZGC_CountTierPieces("player") or 0
                    local diff = theirIlvl - (myEquipped or 0)
                    local col = diff > 2 and "|cff00ff00" or diff < -2 and "|cffff4444" or "|cffffd700"
                    local theirTag = theirTier >= 4 and "4pc" or theirTier >= 2 and "2pc" or "0pc"
                    local myTag    = myTier >= 4 and "4pc" or myTier >= 2 and "2pc" or "0pc"
                    print(string.format("|cff00aaff[ZGC]|r %s — %silvl %.0f|r |cffaaaaaa(you: %.0f)|r  Tier: %s |cffaaaaaa(you: %s)|r",
                        name, col, theirIlvl, myEquipped or 0, theirTag, myTag))
                else
                    print(string.format("|cff00aaff[ZGC]|r %s — gear data not available, try again.", name))
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

-- ── Event registration ──────────────────────────────────────────────────────
eventFrame:RegisterEvent("ADDON_LOADED")
if not ZGC_PAUSED then
    eventFrame:RegisterEvent("INSPECT_READY")
    eventFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
    eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
end

-- ── Slash commands ──────────────────────────────────────────────────────────
SLASH_ZINAGEARCOMPARE1 = "/zgc"
SlashCmdList["ZINAGEARCOMPARE"] = function(msg)
    if ZGC_PAUSED then
        print("|cff00aaff[ZinaGearCompare]|r |cffff8800PAUSED|r — Under development, not functional yet.")
        print("|cff00aaff[ZinaGearCompare]|r The addon is being rebuilt. Stay tuned for updates!")
        return
    end

    msg = msg:lower():match("^%s*(.-)%s*$")

    if msg == "reset" then
        ZinaGearCompareDB = {}
        for k, v in pairs(DB_DEFAULTS) do ZinaGearCompareDB[k] = v end
        print("|cff00aaff[ZinaGearCompare]|r Database reset.")

    elseif msg == "compare" then
        if not UnitIsPlayer("target") then
            print("|cffff8800[ZinaGearCompare]|r You need to have a player selected as your target.")
            return
        end
        local targetName = UnitName("target") or "?"
        print(string.format("|cff00aaff[ZinaGearCompare]|r Inspecting %s...", targetName))
        zgcPrintPending    = true
        pendingInspectUnit = "target"
        NotifyInspect("target")

    elseif msg == "score" or msg == "myscore" then
        local _, avgEquipped = GetAverageItemLevel()
        local tierCount = ZGC_CountTierPieces and ZGC_CountTierPieces("player") or 0
        local specName  = ZGC_GetSpecNameForUnit("player") or "unknown"
        local tierTag   = tierCount >= 4 and "4pc" or tierCount >= 2 and "2pc" or "0pc"
        print(string.format(
            "|cff00aaff[ZGC]|r %s — |cffffd700ilvl %.0f|r  Tier: %s",
            specName, avgEquipped or 0, tierTag))

    elseif msg:match("^mode%s+") then
        local mode = msg:match("^mode%s+(%S+)")
        if mode == "auto" then
            ZinaGearCompareDB.contentOverride = nil
            print("|cff00aaff[ZinaGearCompare]|r Mode: |cffaaaaaaauto-detection|r")
        elseif mode == "dungeon" or mode == "m+" then
            ZinaGearCompareDB.contentOverride = "dungeon"
            print("|cff00aaff[ZinaGearCompare]|r Forced mode: |cffaad4ffM+|r")
        elseif mode == "raid" then
            ZinaGearCompareDB.contentOverride = "raid"
            print("|cff00aaff[ZinaGearCompare]|r Forced mode: |cffFFD700Raid|r")
        else
            print("|cffff8800[ZinaGearCompare]|r Usage: /zgc mode auto|dungeon|raid")
        end
        UpdatePaperDollScore()
        if InspectFrame and InspectFrame:IsShown() then ZGC_UpdatePanel() end

    elseif msg == "debug" then
        print("|cff00aaff[ZinaGearCompare]|r === DEBUG ===")
        local ok, err = pcall(function()
            -- Content type
            local detected = ZGC_DetectContentType()
            local override = ZinaGearCompareDB and ZinaGearCompareDB.contentOverride
            print(string.format("  Content type: %s  (detected: %s, override: %s)",
                ZGC_GetContentType(), detected, tostring(override)))

            -- Spec
            local specID   = ZGC_GetSpecIDForUnit("player")
            local specName = ZGC_GetSpecNameForUnit("player")
            print(string.format("  SpecID: %s  Spec: %s", tostring(specID), tostring(specName)))

            -- Available weights
            local hasWeights = specID and ZGC_StatWeights and ZGC_StatWeights[specID]
            print("  Weights in ZGC_StatWeights:", hasWeights and "OK" or "NOT FOUND")

            -- Tier
            local tierCount = ZGC_CountTierPieces and ZGC_CountTierPieces("player") or 0
            local tierMult  = specID and ZGC_GetTierMultiplier and ZGC_GetTierMultiplier("player", specID) or 1.0
            print(string.format("  Tier pieces: %d   Multiplier: %.2fx", tierCount, tierMult))

            -- Score
            local total, slots = ZGC_GetWeightedScore("player", specID, ZGC_GetContentType())
            print(string.format("  Score: %.0f  Slots scored: %d/%d", total, slots, ZGC_EQUIP_SLOT_COUNT))

            -- Test C_Item.GetItemStats API
            local apiOk = C_Item and C_Item.GetItemStats ~= nil
            print("  C_Item.GetItemStats exists:", apiOk and "YES" or "NO")
            local testLink = GetInventoryItemLink("player", 1)
                          or GetInventoryItemLink("player", 5)
            if testLink then
                print("  Test item (slot 1/5):", testLink)
                if ZGC_DiagnoseStatKeys then
                    print("  Stat diagnosis:", ZGC_DiagnoseStatKeys(testLink))
                end
                if specID and ZGC_StatWeights and ZGC_StatWeights[specID] then
                    local w  = ZGC_StatWeights[specID]
                    local ct = ZGC_GetContentType()
                    local itemScore = ZGC_ScoreItem(testLink, w[ct] or w.dungeon, w.primaryStat)
                    print("  Item score:", itemScore and string.format("%.1f", itemScore) or "nil")
                end
            else
                print("  Slots 1 and 5 empty")
            end
        end)
        if not ok then
            print("  |cffff4444ERROR in debug:|r", err)
        end

    elseif msg == "diag" then
        local log = {}
        local function L(s) log[#log+1] = s; print(s) end
        L("|cff00aaff[ZGC]|r === DETAILED SCORING DIAGNOSTIC ===")
        local ok, err = pcall(function()
            local SLOT_NAMES = {
                [1]="Head",[2]="Neck",[3]="Shoulder",[5]="Chest",[6]="Waist",
                [7]="Legs",[8]="Feet",[9]="Wrist",[10]="Hands",[11]="Ring1",
                [12]="Ring2",[13]="Trinket1",[14]="Trinket2",[15]="Back",
                [16]="MainHand",[17]="OffHand",
            }
            local SLOTS = {1,2,3,5,6,7,8,9,10,11,12,13,14,15,16,17}
            local ct = ZGC_GetContentType()

            -- Player scoring
            local mySpecID = ZGC_GetSpecIDForUnit("player")
            local mySpecName = ZGC_GetSpecNameForUnit("player") or "?"
            L(string.format("  YOU: %s (specID %s) [%s]", mySpecName, tostring(mySpecID), ct))
            if mySpecID and ZGC_StatWeights and ZGC_StatWeights[mySpecID] then
                local sw = ZGC_StatWeights[mySpecID]
                local w = sw[ct] or sw.dungeon
                L(string.format("  Weights: pri=%.2f c=%.3f h=%.3f m=%.3f v=%.3f",
                    w.primary, w.crit, w.haste, w.mastery, w.versatility))

                -- Get score with DR factors
                local myTotalDR, mySlotsDR, _, drFactors = ZGC_GetWeightedScore("player", mySpecID, ct)

                -- Show DR info
                if drFactors then
                    L(string.format("  DR Factors: crit=%.2f  haste=%.2f  mastery=%.2f  vers=%.2f",
                        drFactors.crit or 1, drFactors.haste or 1, drFactors.mastery or 1, drFactors.versatility or 1))
                end

                -- Per-slot breakdown (with DR applied)
                local myTotal = 0
                local mySlots = 0
                for _, sid in ipairs(SLOTS) do
                    local link = GetInventoryItemLink("player", sid)
                    if link then
                        local sc = ZGC_ScoreItem(link, w, sw.primaryStat, drFactors)
                        local name = SLOT_NAMES[sid] or tostring(sid)
                        if sc then
                            -- Add weapon ilvl bonus for display
                            local weaponBonus = 0
                            if sid == 16 or sid == 17 then
                                local ilvl = GetDetailedItemLevelInfo and GetDetailedItemLevelInfo(link) or 0
                                if ilvl and ilvl > 0 then
                                    weaponBonus = ilvl * 2.5
                                    sc = sc + weaponBonus
                                end
                            end
                            myTotal = myTotal + sc
                            mySlots = mySlots + 1
                            local extra = weaponBonus > 0 and string.format(" (wpn+%.0f)", weaponBonus) or ""
                            L(string.format("    %-10s %7.0f%s  %s", name, sc, extra, link:match("%[(.-)%]") or "?"))
                        else
                            L(string.format("    %-10s    nil   %s", name, link:match("%[(.-)%]") or "?"))
                        end
                    else
                        L(string.format("    %-10s  EMPTY", SLOT_NAMES[sid] or tostring(sid)))
                    end
                end
                local tierMult = ZGC_GetTierMultiplier("player", mySpecID)
                L(string.format("  TOTAL: %.0f * %.2f(tier) = %.0f  (%d slots)",
                    myTotal, tierMult, myTotal * tierMult, mySlots))
            end

            -- Target scoring (if target exists)
            if UnitIsPlayer("target") then
                local tSpecID = ZGC_GetSpecIDForUnit("target")
                local tSpecName = ZGC_GetSpecNameForUnit("target") or "?"
                local tName = UnitName("target") or "?"
                L(string.format("  TARGET: %s - %s (specID %s)", tName, tSpecName, tostring(tSpecID)))
                if tSpecID and ZGC_StatWeights and ZGC_StatWeights[tSpecID] then
                    local sw = ZGC_StatWeights[tSpecID]
                    local w = sw[ct] or sw.dungeon
                    L(string.format("  Weights: pri=%.2f c=%.3f h=%.3f m=%.3f v=%.3f",
                        w.primary, w.crit, w.haste, w.mastery, w.versatility))

                    local _, _, _, tDrFactors = ZGC_GetWeightedScore("target", tSpecID, ct)
                    if tDrFactors then
                        L(string.format("  DR Factors: crit=%.2f  haste=%.2f  mastery=%.2f  vers=%.2f",
                            tDrFactors.crit or 1, tDrFactors.haste or 1, tDrFactors.mastery or 1, tDrFactors.versatility or 1))
                    end

                    local tTotal = 0
                    local tSlots = 0
                    for _, sid in ipairs(SLOTS) do
                        local link = GetInventoryItemLink("target", sid)
                        if link then
                            local sc = ZGC_ScoreItem(link, w, sw.primaryStat, tDrFactors)
                            local name = SLOT_NAMES[sid] or tostring(sid)
                            if sc then
                                local weaponBonus = 0
                                if sid == 16 or sid == 17 then
                                    local ilvl = GetDetailedItemLevelInfo and GetDetailedItemLevelInfo(link) or 0
                                    if ilvl and ilvl > 0 then
                                        weaponBonus = ilvl * 2.5
                                        sc = sc + weaponBonus
                                    end
                                end
                                tTotal = tTotal + sc
                                tSlots = tSlots + 1
                                local extra = weaponBonus > 0 and string.format(" (wpn+%.0f)", weaponBonus) or ""
                                L(string.format("    %-10s %7.0f%s  %s", name, sc, extra, link:match("%[(.-)%]") or "?"))
                            else
                                L(string.format("    %-10s    nil   %s", name, link:match("%[(.-)%]") or "?"))
                            end
                        else
                            L(string.format("    %-10s  EMPTY", SLOT_NAMES[sid] or tostring(sid)))
                        end
                    end
                    local tierMult = ZGC_GetTierMultiplier("target", tSpecID)
                    L(string.format("  TOTAL: %.0f * %.2f(tier) = %.0f  (%d slots)",
                        tTotal, tierMult, tTotal * tierMult, tSlots))
                else
                    L("  No weights for target specID or inspect not ready")
                    L("  (Select target and /zgc compare first, then /zgc diag)")
                end
            else
                L("  TARGET: none (select a player target for comparison)")
            end
        end)
        if not ok then L("  ERROR: " .. tostring(err)) end
        -- Save to DB so it can be read from SavedVariables file
        ZinaGearCompareDB.lastDiag = table.concat(log, "\n")
        L("|cff00aaff[ZGC]|r Diag saved. Type /reload, then check SavedVariables.")

    elseif msg == "sim" then
        if ZGC_ToggleSimPanel then
            ZGC_ToggleSimPanel()
        else
            print("|cff00aaff[ZGC]|r Sim panel module not loaded.")
        end

    elseif msg == "simdiag" then
        if ZGC_SimDiag then
            ZGC_SimDiag()
        else
            print("|cff00aaff[ZGC]|r Sim panel module not loaded.")
        end

    elseif msg == "config" or msg == "settings" or msg == "options" then
        Settings.OpenToCategory(ADDON_NAME)

    elseif msg == "raidbots" or msg == "rb" then
        if ZGC_RaidbotsStatus then
            ZGC_RaidbotsStatus()
        else
            print("|cff00aaff[ZGC]|r Raidbots module not loaded.")
        end

    else
        print("|cff00aaff[ZinaGearCompare]|r Available commands:")
        print("  /zgc compare        — compare your target's gear against yours")
        print("  /zgc score          — show your current score")
        print("  /zgc mode auto      — auto-detect content type")
        print("  /zgc mode dungeon   — force M+ / AoE mode")
        print("  /zgc mode raid      — force Raid / ST mode")
        print("  /zgc sim            — toggle Sim Performance panel")
        print("  /zgc raidbots       — show Raidbots import status")
        print("  /zgc config         — open settings panel")
        print("  /zgc debug          — full diagnostic")
        print("  /zgc reset          — reset addon database")
    end
end
