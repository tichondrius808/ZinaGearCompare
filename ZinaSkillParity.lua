-- ZinaSkillParity.lua — ZinaGearCompare
-- Motor de Skill Parity usando C_DamageMeter (Blizzard nativo, 12.0+).
-- Calcula qué % del daño de otro jugador deberías hacer tú, ajustado por gear.

ZGC_SkillParity = {}

-- ── Helpers ─────────────────────────────────────────────────────────────────

-- Busca el DPS de un jugador por GUID en una sesión del damage meter.
-- sessionType: Enum.DamageMeterSessionType.Current o .Overall
-- Returns: totalAmount, amountPerSecond, durationSeconds  or nil
local function GetPlayerDpsFromSession(playerGUID, sessionType)
    if not C_DamageMeter or not C_DamageMeter.IsDamageMeterAvailable then return nil end
    local available = C_DamageMeter.IsDamageMeterAvailable()
    if not available then return nil end

    local ok, session = pcall(C_DamageMeter.GetCombatSessionFromType,
        sessionType, Enum.DamageMeterType.DamageDone)
    if not ok or not session or not session.combatSources then return nil end
    local dur = tonumber(session.durationSeconds)
    if not dur or dur <= 0 then return nil end

    for _, source in ipairs(session.combatSources) do
        if source.sourceGUID == tostring(playerGUID) then
            local total = tonumber(source.totalAmount)
            local aps   = tonumber(source.amountPerSecond)
            return total, aps, dur
        end
    end
    return nil
end

-- ── Public API ──────────────────────────────────────────────────────────────

-- Devuelve datos de Skill Parity para un target comparado con el jugador.
-- targetGUID: GUID del otro jugador
-- gearRatio: score_ellos / score_yo (de ZGC_GetWeightedScore)
-- useOverall: si true, usa Overall; si false, usa Current encounter
--
-- Returns: table { parity, actualPct, deltaPP, myDps, theirDps, duration } or nil
function ZGC_SkillParity.Calculate(targetGUID, gearRatio, useOverall)
    if not gearRatio or gearRatio <= 0 then return nil end
    if not targetGUID then return nil end

    local sessionType = useOverall
        and Enum.DamageMeterSessionType.Overall
        or  Enum.DamageMeterSessionType.Current

    local playerGUID = UnitGUID("player")
    if not playerGUID then return nil end

    local myTotal, myDps, duration = GetPlayerDpsFromSession(playerGUID, sessionType)
    if not myTotal or myTotal <= 0 then return nil end

    local theirTotal, theirDps = GetPlayerDpsFromSession(targetGUID, sessionType)
    if not theirTotal or theirTotal <= 0 then return nil end

    -- parity: qué % de su daño deberías hacer, ajustado por gear
    -- Si ellos tienen mejor gear (gearRatio > 1), se espera que hagas menos
    local parity = ((1 / gearRatio) ^ 1.2) * 100

    -- actualPct: qué % de su daño hiciste realmente
    local actualPct = (myTotal / theirTotal) * 100

    -- deltaPP: puntos porcentuales sobre/bajo lo esperado
    local deltaPP = actualPct - parity

    return {
        parity    = parity,
        actualPct = actualPct,
        deltaPP   = deltaPP,
        myDps     = myDps,
        theirDps  = theirDps,
        duration  = duration,
    }
end

-- Verifica si C_DamageMeter está disponible y activo.
function ZGC_SkillParity.IsAvailable()
    if not C_DamageMeter or not C_DamageMeter.IsDamageMeterAvailable then
        return false, "C_DamageMeter not available"
    end
    local available, reason = C_DamageMeter.IsDamageMeterAvailable()
    return available, reason
end
