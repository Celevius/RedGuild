function D(msg)
    if RedGuild_Debug then
        print("|cff00ff00[RedGuild DEBUG]|r " .. msg)
    end
end

function CountKeys(t)
    local c = 0
    for _ in pairs(t) do c = c + 1 end
    return c
end

function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[RedGuild]|r " .. tostring(msg))
end

function NormalizeName(name)
    if not name then return nil end

    -- Remove realm suffix
    name = Ambiguate(name, "short")
    if not name or name == "" then return nil end

    -- Strip leading/trailing whitespace
    name = name:gsub("^%s*(.-)%s*$", "%1")

    -- Lowercase + remove spaces
    name = name:lower():gsub("%s+", "")

    return name
end

function ColourForSyncAge(timestamp)
    if not timestamp or timestamp == "Never" then
        return "|cffff0000Never|r" -- treat missing as red
    end

    -- Parse "YYYY-MM-DD HH:MM:SS"
    local year, month, day, hour, min, sec =
        timestamp:match("(%d+)%-(%d+)%-(%d+) (%d+):(%d+):(%d+)")

    if not year then
        return "|cffff0000Invalid|r"
    end

    local t = time({
        year = year,
        month = month,
        day = day,
        hour = hour,
        min = min,
        sec = sec,
    })

    local ageDays = (time() - t) / 86400

    if ageDays < 4 then
        return "|cff00ff00" .. timestamp .. "|r" -- green
    elseif ageDays < 7 then
        return "|cffffa500" .. timestamp .. "|r" -- orange
    else
        return "|cffff0000" .. timestamp .. "|r" -- red
    end
end

function GetExactName(name)
    -- Ambiguate("none") returns the full, exact name Blizzard expects
    local exact = Ambiguate(name, "none")
    return exact
end

function ShortName(name)
    if not name then return nil end
    return name:match("^[^-]+")
end

function GenerateAuditID()
    return tostring(time()) .. "-" .. math.random(100000, 999999)
end

function ColorizeBalance(d)
    if not d then
        return "0"
    end

    local balance  = tonumber(d.balance)  or 0
    local lastWeek = tonumber(d.lastWeek) or 0

    -- Hard cap colour: purple for 300
    if balance == 300 then
        return "|cffa335ee" .. balance .. "|r"   -- epic purple
    end

    if balance > lastWeek then
        return "|cff00ff00" .. balance .. "|r"   -- green
    elseif balance < lastWeek then
        return "|cffff0000" .. balance .. "|r"   -- red
    else
        return tostring(balance)                 -- white/neutral
    end
end

function CompareVersions(localVer, remoteVer)
    local function split(v)
        local a, b, c = v:match("(%d+)%.(%d+)%.(%d+)")
        return tonumber(a) or 0, tonumber(b) or 0, tonumber(c) or 0
    end

    local la, lb, lc = split(localVer)
    local ra, rb, rc = split(remoteVer)

    if ra > la then return true end
    if ra < la then return false end
    if rb > lb then return true end
    if rb < lb then return false end
    return rc > lc
end

function ParseAuditTime(t)
    local year, month, day, hour, min, sec = t:match("(%d+)%-(%d+)%-(%d+) (%d+):(%d+):(%d+)")
    return time({
        year = year,
        month = month,
        day = day,
        hour = hour,
        min = min,
        sec = sec,
    })
end

