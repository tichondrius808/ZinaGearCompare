-- ZinaSimPanel.lua — ZinaGearCompare
-- Small floating panel showing actual DPS vs sim DPS.
-- Data sources: C_DamageMeter (native 12.0+) > Details! addon > fallback message.

local ADDON_NAME = "ZinaGearCompare"
local PANEL_WIDTH  = 210
local PANEL_HEIGHT = 62
local UPDATE_INTERVAL = 2

-- ── State ────────────────────────────────────────────────────────────────────
local panel = nil
local statusBar = nil
local pctText = nil
local dpsText = nil
local segLabel = nil
local ticker = nil
local dpsSource = nil  -- "native" | "details" | nil

-- Segment navigation: list of { type="sessionType"|"id", value=enum|number, name=string }
local segments = {}
local segIndex = 1

-- ── Build segment list ───────────────────────────────────────────────────────

local function RebuildSegments()
    segments = {}
    -- Always add Overall and Current as first two entries
    if C_DamageMeter and Enum and Enum.DamageMeterSessionType then
        table.insert(segments, {
            type = "sessionType",
            value = Enum.DamageMeterSessionType.Overall,
            name = "Overall",
        })
        table.insert(segments, {
            type = "sessionType",
            value = Enum.DamageMeterSessionType.Current,
            name = "Current",
        })
        -- Add individual saved sessions
        if C_DamageMeter.GetAvailableCombatSessions then
            local ok, list = pcall(C_DamageMeter.GetAvailableCombatSessions)
            if ok and list then
                for i, sess in ipairs(list) do
                    local name = sess.name
                    if not name or name == "" then
                        name = "Fight " .. i
                    end
                    -- Append short duration
                    if sess.durationSeconds and sess.durationSeconds > 0 then
                        local dur = sess.durationSeconds
                        if dur >= 60 then
                            name = name .. string.format(" (%dm%ds)", math.floor(dur/60), dur%60)
                        else
                            name = name .. string.format(" (%ds)", dur)
                        end
                    end
                    table.insert(segments, {
                        type = "id",
                        value = sess.sessionID,
                        name = name,
                    })
                end
            end
        end
    end
    -- Details! fallback segments
    if #segments == 0 and _G.Details then
        table.insert(segments, { type = "details", value = 0, name = "Current" })
        table.insert(segments, { type = "details", value = 1, name = "Overall" })
    end
    -- Clamp index
    if segIndex > #segments then segIndex = #segments end
    if segIndex < 1 then segIndex = 1 end
end

local function GetCurrentSegment()
    if #segments == 0 then RebuildSegments() end
    return segments[segIndex]
end

-- ── Sim DPS from Raidbots ────────────────────────────────────────────────────

local function GetSimDPS()
    if not ZGC_RaidbotsData then return nil, nil end
    local ct = ZGC_GetContentType and ZGC_GetContentType() or "dungeon"
    local key = ct == "raid" and "st" or "aoe"
    local d = ZGC_RaidbotsData[key]
    if not d then return nil, nil end
    if d.specID and d.specID ~= 0 then
        local idx = GetSpecialization and GetSpecialization()
        if idx and GetSpecializationInfo then
            local playerSpec = GetSpecializationInfo(idx)
            if playerSpec and playerSpec ~= d.specID then return nil, nil end
        end
    end
    local label = ct == "raid" and "Raid" or "M+"
    return d.bestComboDPS or d.baselineDPS or 0, label
end

-- ── Find player in session ───────────────────────────────────────────────────

local function FindPlayerSource(session)
    if not session or not session.combatSources then return nil end
    for _, source in ipairs(session.combatSources) do
        if source.isLocalPlayer then return source end
    end
    local playerGUID = UnitGUID("player")
    local playerName = UnitName("player")
    for _, source in ipairs(session.combatSources) do
        if source.sourceGUID == playerGUID or source.name == playerName then
            return source
        end
    end
    return nil
end

local function ExtractDPS(session)
    local source = FindPlayerSource(session)
    if not source then return nil end
    if source.amountPerSecond and source.amountPerSecond > 0 then
        return source.amountPerSecond
    end
    if source.totalAmount and source.totalAmount > 0 then
        local dur = session.durationSeconds
        if dur and dur > 0 then return source.totalAmount / dur end
    end
    return nil
end

-- ── Actual DPS: native C_DamageMeter (12.0+) ────────────────────────────────

local function GetActualDPS_Native(seg)
    if not C_DamageMeter then return nil end
    local ok, available = pcall(C_DamageMeter.IsDamageMeterAvailable)
    if not ok or not available then return nil end

    local session
    if seg.type == "sessionType" then
        local sok, s = pcall(C_DamageMeter.GetCombatSessionFromType,
            seg.value, Enum.DamageMeterType.DamageDone)
        if sok then session = s end
    elseif seg.type == "id" then
        local sok, s = pcall(C_DamageMeter.GetCombatSessionFromID,
            seg.value, Enum.DamageMeterType.DamageDone)
        if sok then session = s end
    end

    if not session then return nil end
    return ExtractDPS(session)
end

-- ── Actual DPS: Details! fallback ────────────────────────────────────────────

local function GetActualDPS_Details(seg)
    if not _G.Details then return nil end
    local combatIndex = seg.value or 0
    local combat = Details:GetCombat(combatIndex)
    if not combat then return nil end
    local combatTime = combat:GetCombatTime()
    if not combatTime or combatTime <= 0 then return nil end
    local playerName = UnitName("player")
    local actor = combat:GetActor(DETAILS_ATTRIBUTE_DAMAGE, playerName)
    if not actor then
        local container = combat:GetContainer(DETAILS_ATTRIBUTE_DAMAGE)
        if not container then return nil end
        for _, a in container:ListActors() do
            if a:IsPlayer() and a:GetOnlyName() == playerName then
                actor = a
                break
            end
        end
    end
    if not actor then return nil end
    local total = actor.total or 0
    if total <= 0 then return nil end
    return total / combatTime
end

-- ── Unified DPS getter ──────────────────────────────────────────────────────

local function GetActualDPS()
    local seg = GetCurrentSegment()
    if not seg then return nil end

    if seg.type == "details" then
        local dps = GetActualDPS_Details(seg)
        if dps then dpsSource = "details" end
        return dps
    end

    local dps = GetActualDPS_Native(seg)
    if dps then
        dpsSource = "native"
        return dps
    end

    dpsSource = nil
    return nil
end

local function HasAnyDPSSource()
    if C_DamageMeter and C_DamageMeter.IsDamageMeterAvailable then
        local ok, avail = pcall(C_DamageMeter.IsDamageMeterAvailable)
        if ok and avail then return true end
    end
    if _G.Details then return true end
    return false
end

-- ── Formatting helpers ───────────────────────────────────────────────────────

local function FormatDPS(dps)
    if dps >= 1000000 then
        return string.format("%.1fM", dps / 1000000)
    elseif dps >= 1000 then
        return string.format("%.1fk", dps / 1000)
    else
        return string.format("%.0f", dps)
    end
end

local function GetBarColor(pct)
    if pct < 70 then
        return 0.9, 0.2, 0.2
    elseif pct < 90 then
        local t = (pct - 70) / 20
        return 0.9 - t * 0.5, 0.2 + t * 0.6, 0.2
    else
        return 0.2, 0.8, 0.2
    end
end

-- ── Update ───────────────────────────────────────────────────────────────────

local function UpdateSegmentLabel()
    if not segLabel then return end
    local seg = GetCurrentSegment()
    local name = seg and seg.name or "—"
    local total = #segments
    if total > 0 then
        segLabel:SetText(string.format("|cffaaaaaa%d/%d|r %s", segIndex, total, name))
    else
        segLabel:SetText(name)
    end
end

local function UpdatePanel()
    if not panel or not panel:IsShown() then return end

    UpdateSegmentLabel()

    local simDPS, modeLabel = GetSimDPS()
    if not simDPS or simDPS <= 0 then
        statusBar:SetValue(0)
        pctText:SetText("--")
        dpsText:SetText("|cffaaaaaNo sim data|r")
        statusBar:SetStatusBarColor(0.3, 0.3, 0.3)
        return
    end

    if not HasAnyDPSSource() then
        statusBar:SetValue(0)
        pctText:SetText("--")
        dpsText:SetText("|cffaaaaaaNo DPS source available|r")
        statusBar:SetStatusBarColor(0.3, 0.3, 0.3)
        return
    end

    local actualDPS = GetActualDPS()
    if not actualDPS then
        statusBar:SetValue(0)
        pctText:SetText("--")
        dpsText:SetText(string.format("|cffaaaaaa-- / %s DPS (%s)|r", FormatDPS(simDPS), modeLabel))
        statusBar:SetStatusBarColor(0.3, 0.3, 0.3)
        return
    end

    local pct = (actualDPS / simDPS) * 100
    if pct > 200 then pct = 200 end
    local r, g, b = GetBarColor(pct)
    statusBar:SetMinMaxValues(0, 100)
    statusBar:SetValue(math.min(pct, 100))
    statusBar:SetStatusBarColor(r, g, b)
    pctText:SetText(string.format("%.1f%%", pct))

    local srcTag = dpsSource == "details" and " D!" or ""
    dpsText:SetText(string.format("%s / %s DPS (%s%s)",
        FormatDPS(actualDPS), FormatDPS(simDPS), modeLabel, srcTag))
end

-- ── Segment navigation ──────────────────────────────────────────────────────

local function NextSegment()
    RebuildSegments()
    if #segments == 0 then return end
    segIndex = segIndex + 1
    if segIndex > #segments then segIndex = 1 end
    UpdatePanel()
end

local function PrevSegment()
    RebuildSegments()
    if #segments == 0 then return end
    segIndex = segIndex - 1
    if segIndex < 1 then segIndex = #segments end
    UpdatePanel()
end

-- ── Position persistence ─────────────────────────────────────────────────────

local function SaveLayout()
    if not panel then return end
    local point, _, _, x, y = panel:GetPoint()
    local w, h = panel:GetSize()
    if not ZinaGearCompareDB then ZinaGearCompareDB = {} end
    if not ZinaGearCompareDB.simPanel then ZinaGearCompareDB.simPanel = {} end
    ZinaGearCompareDB.simPanel.pos  = { point = point, x = x, y = y }
    ZinaGearCompareDB.simPanel.size = { w = w, h = h }
end

local function RestoreLayout()
    if not panel then return end
    local sp = ZinaGearCompareDB and ZinaGearCompareDB.simPanel
    -- Position
    local pos = sp and sp.pos
    if pos and pos.point then
        panel:ClearAllPoints()
        panel:SetPoint(pos.point, UIParent, pos.point, pos.x or 0, pos.y or 0)
    else
        panel:ClearAllPoints()
        panel:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
    end
    -- Size
    local size = sp and sp.size
    if size and size.w and size.h then
        panel:SetSize(math.max(size.w, PANEL_WIDTH), math.max(size.h, PANEL_HEIGHT))
    end
end

-- ── Create panel ─────────────────────────────────────────────────────────────

local function CreatePanel()
    if panel then return panel end

    panel = CreateFrame("Frame", "ZGCSimPanel", UIParent, "BackdropTemplate")
    panel:SetSize(PANEL_WIDTH, PANEL_HEIGHT)
    panel:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 16, edgeSize = 12,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    panel:SetBackdropColor(0.05, 0.05, 0.1, 0.9)
    panel:SetBackdropBorderColor(0, 0.4, 0.6, 0.8)
    panel:SetFrameStrata("MEDIUM")
    panel:SetClampedToScreen(true)
    panel:EnableMouse(true)
    panel:SetMovable(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", function(self) self:StartMoving() end)
    panel:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SaveLayout()
    end)

    -- Resizable
    panel:SetResizable(true)
    panel:SetResizeBounds(PANEL_WIDTH, PANEL_HEIGHT, 500, 200)

    -- Resize grip (bottom-right corner)
    local resizeBtn = CreateFrame("Button", nil, panel)
    resizeBtn:SetSize(12, 12)
    resizeBtn:SetPoint("BOTTOMRIGHT", -2, 2)
    resizeBtn:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeBtn:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeBtn:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resizeBtn:SetScript("OnMouseDown", function()
        panel:StartSizing("BOTTOMRIGHT")
    end)
    resizeBtn:SetScript("OnMouseUp", function()
        panel:StopMovingOrSizing()
        SaveLayout()
    end)

    -- Row 1: title + segment nav + close
    local titleText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    titleText:SetPoint("TOPLEFT", 6, -4)
    titleText:SetText("|cff00aaffZGC Sim|r")

    local closeBtn = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    closeBtn:SetSize(16, 16)
    closeBtn:SetPoint("TOPRIGHT", -1, -1)
    closeBtn:SetScript("OnClick", function() ZGC_ToggleSimPanel(false) end)

    -- Prev / Next buttons
    local prevBtn = CreateFrame("Button", nil, panel)
    prevBtn:SetSize(14, 14)
    prevBtn:SetPoint("TOPLEFT", titleText, "TOPRIGHT", 4, 2)
    prevBtn:SetNormalFontObject("GameFontNormalSmall")
    prevBtn:SetText("|cffcccccc<|r")
    prevBtn:SetScript("OnClick", PrevSegment)

    local nextBtn = CreateFrame("Button", nil, panel)
    nextBtn:SetSize(14, 14)
    nextBtn:SetPoint("LEFT", prevBtn, "RIGHT", 0, 0)
    nextBtn:SetNormalFontObject("GameFontNormalSmall")
    nextBtn:SetText("|cffcccccc>|r")
    nextBtn:SetScript("OnClick", NextSegment)

    -- Row 2: status bar + percentage
    statusBar = CreateFrame("StatusBar", nil, panel)
    statusBar:SetPoint("TOPLEFT", 6, -18)
    statusBar:SetPoint("RIGHT", panel, "RIGHT", -38, 0)
    statusBar:SetHeight(12)
    statusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    statusBar:SetMinMaxValues(0, 100)
    statusBar:SetValue(0)
    statusBar:SetStatusBarColor(0.3, 0.3, 0.3)

    local barBG = statusBar:CreateTexture(nil, "BACKGROUND")
    barBG:SetAllPoints()
    barBG:SetColorTexture(0.1, 0.1, 0.1, 0.8)

    pctText = statusBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    pctText:SetPoint("RIGHT", panel, "RIGHT", -6, 0)
    pctText:SetText("--")

    -- Row 3: segment label + DPS text
    segLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    segLabel:SetPoint("BOTTOMLEFT", 6, 16)
    segLabel:SetPoint("BOTTOMRIGHT", -6, 16)
    segLabel:SetJustifyH("CENTER")
    segLabel:SetText("")

    dpsText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    dpsText:SetPoint("BOTTOMLEFT", 6, 4)
    dpsText:SetPoint("BOTTOMRIGHT", -6, 4)
    dpsText:SetJustifyH("CENTER")
    dpsText:SetText("")

    -- Event: auto-refresh on combat session updates
    panel:RegisterEvent("DAMAGE_METER_COMBAT_SESSION_UPDATED")
    panel:RegisterEvent("DAMAGE_METER_CURRENT_SESSION_UPDATED")
    panel:RegisterEvent("DAMAGE_METER_RESET")
    panel:SetScript("OnEvent", function(self, event)
        RebuildSegments()
        UpdatePanel()
    end)

    RestoreLayout()
    panel:Hide()
    return panel
end

-- ── Ticker management ────────────────────────────────────────────────────────

local function StartTicker()
    if ticker then return end
    ticker = C_Timer.NewTicker(UPDATE_INTERVAL, UpdatePanel)
end

local function StopTicker()
    if ticker then
        ticker:Cancel()
        ticker = nil
    end
end

-- ── Public API ───────────────────────────────────────────────────────────────

function ZGC_ToggleSimPanel(show)
    if not panel then CreatePanel() end
    if show == nil then
        show = not panel:IsShown()
    end
    if show then
        RebuildSegments()
        panel:Show()
        UpdatePanel()
        StartTicker()
    else
        panel:Hide()
        StopTicker()
    end
    if ZinaGearCompareDB then
        if not ZinaGearCompareDB.simPanel then ZinaGearCompareDB.simPanel = {} end
        ZinaGearCompareDB.simPanel.visible = show
    end
end

-- ── Diagnostic: /zgc simdiag ─────────────────────────────────────────────────

function ZGC_SimDiag()
    local log = {}
    local P = function(s)
        log[#log+1] = s
        print("|cff00aaff[ZGC SimDiag]|r " .. s)
    end

    P("=== C_DamageMeter ===")
    if not C_DamageMeter then
        P("|cffff4444C_DamageMeter namespace does NOT exist|r")
    else
        P("|cff00ff00C_DamageMeter exists|r")

        local funcs = {}
        for k, v in pairs(C_DamageMeter) do
            table.insert(funcs, k .. " (" .. type(v) .. ")")
        end
        table.sort(funcs)
        P("Functions: " .. (#funcs > 0 and table.concat(funcs, ", ") or "EMPTY"))

        if C_DamageMeter.IsDamageMeterAvailable then
            local ok, avail, reason = pcall(C_DamageMeter.IsDamageMeterAvailable)
            P("IsDamageMeterAvailable: ok=" .. tostring(ok) .. " avail=" .. tostring(avail) .. " reason=" .. tostring(reason))
        end

        if Enum and Enum.DamageMeterSessionType then
            local st = {}
            for k, v in pairs(Enum.DamageMeterSessionType) do table.insert(st, k.."="..tostring(v)) end
            P("DamageMeterSessionType: " .. table.concat(st, ", "))
        end

        if Enum and Enum.DamageMeterType then
            local mt = {}
            for k, v in pairs(Enum.DamageMeterType) do table.insert(mt, k.."="..tostring(v)) end
            table.sort(mt)
            P("DamageMeterType: " .. table.concat(mt, ", "))
        end

        -- Available sessions
        if C_DamageMeter.GetAvailableCombatSessions then
            local ok, list = pcall(C_DamageMeter.GetAvailableCombatSessions)
            if ok and list then
                P("AvailableCombatSessions: " .. #list .. " sessions")
                for i, sess in ipairs(list) do
                    local keys = {}
                    for k, v in pairs(sess) do table.insert(keys, k.."="..tostring(v)) end
                    P("  session["..i.."]: " .. table.concat(keys, ", "))
                end
            else
                P("GetAvailableCombatSessions: error=" .. tostring(list))
            end
        end

        -- Overall + Current
        if C_DamageMeter.GetCombatSessionFromType then
            for _, stName in ipairs({"Overall", "Current"}) do
                local stVal = Enum.DamageMeterSessionType[stName]
                if stVal ~= nil then
                    local ok, session = pcall(C_DamageMeter.GetCombatSessionFromType, stVal, Enum.DamageMeterType.DamageDone)
                    if not ok then
                        P(stName .. ": ERROR — " .. tostring(session))
                    elseif not session then
                        P(stName .. ": nil")
                    else
                        local keys = {}
                        for k, v in pairs(session) do
                            if type(v) == "table" then table.insert(keys, k.."=table(#"..#v..")")
                            else table.insert(keys, k.."="..tostring(v)) end
                        end
                        P(stName .. ": " .. table.concat(keys, ", "))

                        if session.combatSources then
                            for i, s in ipairs(session.combatSources) do
                                if s.isLocalPlayer then
                                    local sk = {}
                                    for k2, v2 in pairs(s) do table.insert(sk, k2.."="..tostring(v2)) end
                                    P(stName .. " PLAYER[" .. i .. "]: " .. table.concat(sk, ", "))
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    P("=== Details! ===")
    P(_G.Details and "|cff00ff00loaded|r" or "|cffaaaaaanot loaded|r")

    P("=== Segments ===")
    RebuildSegments()
    P("Total: " .. #segments .. "  Current index: " .. segIndex)
    for i, seg in ipairs(segments) do
        P(string.format("  [%d] type=%s value=%s name=%s", i, seg.type, tostring(seg.value), seg.name))
    end

    if ZinaGearCompareDB then
        ZinaGearCompareDB.lastSimDiag = table.concat(log, "\n")
    end
    P("Saved to SavedVariables.")
end

function ZGC_InitSimPanel()
    CreatePanel()
    local vis = ZinaGearCompareDB and ZinaGearCompareDB.simPanel and ZinaGearCompareDB.simPanel.visible
    if vis then
        ZGC_ToggleSimPanel(true)
    end
end
