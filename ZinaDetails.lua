-- ZinaDetails.lua — ZinaGearCompare
-- Details! Custom Display "ZGC Gear Score" + public API for group scores.
-- Scripts run via loadstring() so all data must flow through globals.

-- ── Public API (global, accessible from Details! scripts) ───────────────────

ZGC_PublicAPI = {}

-- Returns the player's own gear score, or 0 if unavailable.
function ZGC_PublicAPI.GetPlayerScore()
    local specID = ZGC_GetSpecIDForUnit("player")
    if not specID then return 0 end
    local contentType = ZGC_GetContentType()
    local total = ZGC_GetWeightedScore("player", specID, contentType)
    return total or 0
end

-- Returns a table of group member scores:
-- { [playerName] = { score=N, specName=S, ratio=R, tierCount=T, specID=ID } }
function ZGC_PublicAPI.GetGroupScores()
    local results = {}
    local mySpecID = ZGC_GetSpecIDForUnit("player")
    local contentType = ZGC_GetContentType()
    local myTotal = 0
    if mySpecID then
        myTotal = ZGC_GetWeightedScore("player", mySpecID, contentType) or 0
    end

    -- Player
    local playerName = UnitName("player")
    if playerName and myTotal > 0 then
        local specName = ZGC_GetSpecNameForUnit("player") or "?"
        local tierCount = ZGC_CountTierPieces and ZGC_CountTierPieces("player") or 0
        results[playerName] = {
            score = myTotal,
            specName = specName,
            ratio = 100,
            tierCount = tierCount,
            specID = mySpecID,
        }
    end

    -- Group members
    local units = {}
    if IsInRaid and IsInRaid() then
        for i = 1, 40 do units[#units + 1] = "raid" .. i end
    else
        for i = 1, 4 do units[#units + 1] = "party" .. i end
    end

    for _, unit in ipairs(units) do
        if UnitExists(unit) and UnitIsPlayer(unit) and not UnitIsUnit(unit, "player") then
            local name = UnitName(unit)
            if name and not results[name] then
                local specID = ZGC_GetSpecIDForUnit(unit)
                if specID then
                    local total = ZGC_GetWeightedScore(unit, specID, contentType) or 0
                    if total > 0 then
                        local specName = ZGC_GetSpecNameForUnit(unit) or "?"
                        local tierCount = ZGC_CountTierPieces and ZGC_CountTierPieces(unit) or 0
                        local ratio = myTotal > 0 and (total / myTotal * 100) or 0
                        results[name] = {
                            score = total,
                            specName = specName,
                            ratio = ratio,
                            tierCount = tierCount,
                            specID = specID,
                        }
                    end
                end
            end
        end
    end

    return results
end

-- ── Helper: stat priority string for a specID ──────────────────────────────

local function GetStatPriorityStr(specID, contentType)
    local sw = ZGC_StatWeights and ZGC_StatWeights[specID]
    if not sw then return "?" end
    local w = sw[contentType or "dungeon"] or sw.dungeon
    if not w then return "?" end
    local stats = {
        { name = "Crit",    val = w.crit or 0 },
        { name = "Haste",   val = w.haste or 0 },
        { name = "Mastery", val = w.mastery or 0 },
        { name = "Vers",    val = w.versatility or 0 },
    }
    table.sort(stats, function(a, b) return a.val > b.val end)
    local parts = {}
    for _, s in ipairs(stats) do parts[#parts + 1] = s.name end
    return table.concat(parts, " > ")
end

-- ── Details! Custom Display Registration ────────────────────────────────────

local detailsRegistered = false

function ZGC_InitDetails()
    if detailsRegistered then return end
    if not _G.Details then return end

    -- Check if the install method exists
    if not Details.InstallCustomObject then return end

    -- Don't install if it already exists
    if Details.DoesCustomDisplayExists and Details:DoesCustomDisplayExists("ZGC Gear Score") then
        detailsRegistered = true
        return
    end

    local customObj = {
        name = "ZGC Gear Score",
        icon = 132089,
        author = "ZinaGearCompare",
        desc = "Shows gear score for each group member, calculated using SimC stat weights.",
        script_version = 3,

        -- Main script: populates bars with gear scores
        script = [[
            local combat, customContainer, instance = ...
            local scores = ZGC_PublicAPI and ZGC_PublicAPI.GetGroupScores()
            if not scores then return end

            local total = 0
            local top = 0
            local actorContainer = combat:GetContainer(DETAILS_ATTRIBUTE_DAMAGE)
            if not actorContainer then return end

            for _, actor in actorContainer:ListActors() do
                if actor:IsGroupPlayer() then
                    local name = actor:Name()
                    -- strip realm name for matching
                    local shortName = name:match("^([^%-]+)") or name
                    local data = scores[shortName] or scores[name]
                    if data and data.score > 0 then
                        customContainer:AddValue(actor, data.score)
                        total = total + data.score
                        if data.score > top then top = data.score end
                    end
                end
            end

            return total, top
        ]],

        -- Tooltip script: shows stat breakdown
        tooltip = [[
            local actor, combat, instance = ...
            local GameCooltip = GameCooltip
            if not GameCooltip then return end

            local name = actor:Name()
            local shortName = name:match("^([^%-]+)") or name
            local scores = ZGC_PublicAPI and ZGC_PublicAPI.GetGroupScores()
            if not scores then return end
            local data = scores[shortName] or scores[name]
            if not data then return end

            GameCooltip:AddLine("ZGC Gear Score", string.format("%.0f", data.score))
            GameCooltip:AddLine("Spec:", data.specName or "?")
            GameCooltip:AddLine("Ratio vs You:", string.format("%.0f%%", data.ratio))
            if data.tierCount and data.tierCount >= 2 then
                local tierLabel = data.tierCount >= 4 and "4pc" or "2pc"
                GameCooltip:AddLine("Tier Set:", tierLabel)
            end

            -- Stat priority
            if data.specID and ZGC_StatWeights and ZGC_StatWeights[data.specID] then
                local ct = ZGC_GetContentType and ZGC_GetContentType() or "dungeon"
                local sw = ZGC_StatWeights[data.specID]
                local w = sw[ct] or sw.dungeon
                if w then
                    GameCooltip:AddLine(" ", " ")
                    GameCooltip:AddLine("Stat Priority (" .. (ct == "raid" and "Raid" or "M+") .. "):", "")
                    local stats = {
                        { name = "Crit",    val = w.crit or 0 },
                        { name = "Haste",   val = w.haste or 0 },
                        { name = "Mastery", val = w.mastery or 0 },
                        { name = "Vers",    val = w.versatility or 0 },
                    }
                    table.sort(stats, function(a, b) return a.val > b.val end)
                    for _, s in ipairs(stats) do
                        GameCooltip:AddLine("  " .. s.name, string.format("%.3f", s.val))
                    end
                end
                if sw.source then
                    GameCooltip:AddLine("Source:", sw.source)
                end
            end
        ]],

        -- Total script: formats the total value
        total_script = [[
            local value, top, total, combat, instance = ...
            return string.format("%.0f", value)
        ]],

        -- Percent script: shows ratio vs player
        percent_script = [[
            local value, top, total, combat, instance = ...
            local myScore = ZGC_PublicAPI and ZGC_PublicAPI.GetPlayerScore() or 0
            if myScore > 0 then
                return string.format("%.0f%%", (value / myScore) * 100)
            end
            return ""
        ]],
    }

    local ok, err = pcall(function()
        Details:InstallCustomObject(customObj)
    end)

    if ok then
        detailsRegistered = true
    else
        -- Silently fail; Details! may not be fully loaded yet
    end
end
