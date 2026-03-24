-- ZinaGearCompare.lua — Addon entry point
-- Independent engine (no Pawn dependency). Requires ZinaStatWeights, ZinaTierSets, ZinaContentDetector.
--
-- STATUS: PAUSED / UNDER DEVELOPMENT — all functionality disabled.

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
local zgcMouseoverScore     = nil
local zgcMouseoverSpecName  = nil
local zgcMouseoverGearRatio = nil
local zgcMouseoverTierCount = nil
local zgcMouseoverGUID      = nil
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
    if not zgcMouseoverScore or not zgcMouseoverSpecName then return end
    local ratioStr = ""
    if zgcMouseoverGearRatio then
        local pct = zgcMouseoverGearRatio * 100
        local col = pct < 80 and "|cffff4444" or pct <= 100 and "|cffffd700" or "|cff00ff00"
        ratioStr = string.format(" · %s%.0f%%|r", col, pct)
    end
    local tierStr = ""
    if zgcMouseoverTierCount and zgcMouseoverTierCount >= 4 then
        tierStr = " |cffFFD7004pc|r"
    elseif zgcMouseoverTierCount and zgcMouseoverTierCount >= 2 then
        tierStr = " |cffaad4ff2pc|r"
    end
    tooltip:AddLine(string.format("|cff00aaffZGC:|r |cffffd700%.0f|r |cffaaaaaa(%s%s)|r%s",
        zgcMouseoverScore, zgcMouseoverSpecName, ratioStr, tierStr))

    -- Simple gear comparison: avg ilvl + tier (rudimentary)
    if ZinaGearCompareDB and ZinaGearCompareDB.gearCompare ~= false
       and zgcMouseoverGearRatio then
        -- Get tier info for both
        local myTier  = ZGC_CountTierPieces and ZGC_CountTierPieces("player") or 0
        local thTier  = zgcMouseoverTierCount or 0
        local pct = zgcMouseoverGearRatio * 100
        local tierDiff = ""
        if myTier ~= thTier then
            local col = myTier > thTier and "|cff00ff00" or "|cffff4444"
            tierDiff = string.format("  %sTier %d vs %d|r", col, myTier, thTier)
        end
        tooltip:AddLine(string.format("  |cff888888Gear: %.0f%% of theirs%s|r", pct, tierDiff))
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
    zgcMouseoverScore     = nil
    zgcMouseoverSpecName  = nil
    zgcMouseoverGearRatio = nil
    zgcMouseoverTierCount = nil
    zgcMouseoverGUID      = nil
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
    zgcMouseoverScore     = nil
    zgcMouseoverSpecName  = nil
    zgcMouseoverGearRatio = nil
    zgcMouseoverTierCount = nil
    zgcMouseoverGUID      = nil
    zgcMouseoverFallback  = nil
    zgcMouseoverWaiting   = true
    C_Timer.After(0.1, ZGC_TryMouseoverInspect)
end

-- ── GameTooltip hook ────────────────────────────────────────────────────────
local function HookGameTooltip()
    if not TooltipDataProcessor then return end
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip, data)
        if not data then return end

        -- Own player (don't compare guid — it's secret/tainted in 12.0+)
        if UnitExists("mouseover") and UnitIsUnit("mouseover", "player") then
            local specID, specName, total, _, contentType = GetPlayerScore()
            if specName and total and total > 0 then
                local label = contentType == "raid" and "Raid" or "M+"
                local tierTag = ZGC_TierTag("player")
                tooltip:AddLine(string.format("|cff00aaffZGC:|r |cffffd700%.0f|r |cffaaaaaa(%s · %s%s)|r",
                    total, specName, label, tierTag))
            elseif specID and (not ZGC_StatWeights or not ZGC_StatWeights[specID]) then
                tooltip:AddLine(string.format("|cff00aaffZGC:|r |cffaaaaaa%s — no stat weights|r", specName or "?"))
            elseif not specID then
                tooltip:AddLine("|cff00aaffZGC:|r |cffaaaaaaspec not detected|r")
            end
            tooltip:Show()
            return
        end

        -- Other player: show cached score or loading
        if not UnitIsPlayer("mouseover") then return end
        if not zgcMouseoverReady then
            if zgcMouseoverPending or zgcMouseoverWaiting then
                tooltip:AddLine("|cff00aaffZGC:|r |cffaaaaaaloading...|r")
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

        -- Mouseover path
        if zgcMouseoverPending then
            zgcMouseoverPending = false
            if UnitIsPlayer("mouseover") then
                local n, r = ZGC_GetMouseoverNameRealm()
                zgcMouseoverName  = n
                zgcMouseoverRealm = r
                zgcMouseoverGUID  = UnitGUID("mouseover")
                local specID      = ZGC_GetSpecIDForUnit("mouseover")
                local specName    = ZGC_GetSpecNameForUnit("mouseover")
                local contentType = ZGC_GetContentType()
                if specID then
                    if not ZGC_StatWeights or not ZGC_StatWeights[specID] then
                        zgcMouseoverFallback = (specName or "?") .. " — no stat weights"
                        zgcMouseoverSpecName = specName
                    else
                        local total, slotsScored = ZGC_GetWeightedScore("mouseover", specID, contentType)
                        zgcMouseoverTierCount = ZGC_CountTierPieces("mouseover")
                        if total and total > 0 then
                            zgcMouseoverScore    = total
                            zgcMouseoverSpecName = specName
                            local mySpecID   = ZGC_GetSpecIDForUnit("player")
                            local myTotal    = ZGC_GetWeightedScore("player", mySpecID, contentType)
                            if myTotal and myTotal > 0 then
                                zgcMouseoverGearRatio = total / myTotal
                            end
                        else
                            zgcMouseoverFallback = (specName or "?") .. " — no gear data"
                            zgcMouseoverSpecName = specName
                        end
                        -- Retry if few slots scored
                        if slotsScored < 8 then
                            C_Timer.After(1.5, function()
                                if zgcMouseoverName ~= n then return end
                                if not UnitIsPlayer("mouseover") then return end
                                local retryTotal, retrySlotsScored = ZGC_GetWeightedScore("mouseover", specID, contentType)
                                if retryTotal and retryTotal > 0 and retrySlotsScored > slotsScored then
                                    zgcMouseoverScore = retryTotal
                                    zgcMouseoverFallback = nil
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
                else
                    zgcMouseoverFallback = "spec not detected"
                end
                zgcMouseoverReady = true
                ZGC_InjectMouseoverTooltip()
            end
        end

        -- /zgc compare path
        if zgcPrintPending then
            zgcPrintPending = false
            local cmpUnit = pendingUnit or "target"
            if cmpUnit then
                local name       = UnitName(cmpUnit) or "?"
                local specID     = ZGC_GetSpecIDForUnit(cmpUnit)
                local specName   = ZGC_GetSpecNameForUnit(cmpUnit)
                local cType      = ZGC_GetContentType()
                if not specID then
                    print(string.format("|cff00aaff[ZinaGearCompare]|r %s — |cffaaaaaa(spec not detected, incomplete data)|r", name))
                else
                    local total, slots = ZGC_GetWeightedScore(cmpUnit, specID, cType)
                    local mySpecID     = ZGC_GetSpecIDForUnit("player")
                    local mySpecName   = ZGC_GetSpecNameForUnit("player")
                    local myTotal, mySlots = ZGC_GetWeightedScore("player", mySpecID, cType)
                    if total and total > 0 then
                        local label = cType == "raid" and "Raid" or "M+"
                        local tierCount = ZGC_CountTierPieces(cmpUnit)
                        local tierStr = tierCount >= 4 and " · 4pc" or tierCount >= 2 and " · 2pc" or ""
                        -- Line 1: name, spec, both scores and label
                        if myTotal and myTotal > 0 then
                            local gearRatio = total / myTotal
                            local pct = gearRatio * 100
                            local col = pct < 80 and "|cffff4444" or pct <= 100 and "|cffffd700" or "|cff00ff00"
                            print(string.format("|cff00aaff[ZGC]|r %s |cffaaaaaa(%s)|r — Score: |cffffd700%.0f|r vs |cffaaaaaa%.0f yours|r  %s%.0f%%|r |cffaaaaaa(%s%s)|r",
                                name, specName or "?", total, myTotal, col, pct, label, tierStr))
                        else
                            print(string.format("|cff00aaff[ZGC]|r %s |cffaaaaaa(%s)|r — Score: |cffffd700%.0f|r |cffaaaaaa(%s%s)|r",
                                name, specName or "?", total, label, tierStr))
                        end
                        -- Line 2: Tier comparison
                        if myTotal and myTotal > 0 then
                            local myTier = ZGC_CountTierPieces and ZGC_CountTierPieces("player") or 0
                            if myTier ~= tierCount then
                                local col = myTier > tierCount and "|cff00ff00" or "|cffff4444"
                                print(string.format("  %sTier: you %d vs them %d|r", col, myTier, tierCount))
                            end
                        end
                    else
                        print(string.format("|cff00aaff[ZinaGearCompare]|r %s — no gear data yet, try again.", name))
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
        local specID, specName, total, slots, cType = GetPlayerScore()
        if not specID then
            print("|cffff8800[ZinaGearCompare]|r Spec not detected. Open the character panel.")
            return
        end
        local label = cType == "raid" and "Raid" or "M+"
        local tierCount = ZGC_CountTierPieces and ZGC_CountTierPieces("player") or 0
        print(string.format(
            "|cff00aaff[ZinaGearCompare]|r My score: |cffffd700%.0f|r | %d slots | %s | %s | Tier: %dpc",
            total, slots, specName or "?", label, tierCount))

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
        print("  /zgc raidbots       — show Raidbots import status")
        print("  /zgc config         — open settings panel")
        print("  /zgc debug          — full diagnostic")
        print("  /zgc reset          — reset addon database")
    end
end
