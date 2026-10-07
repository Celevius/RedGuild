--==================================================================
-- ATTENDANCE TAB (editors only)
--==================================================================
-- Kept off the DKP tab on purpose: these are lifetime counters, not
-- part of the running DKP session, and mixing them into that table
-- made it noisy. Both counters move only when a new DKP session is
-- started (RedGuild_BumpAttendance / RedGuild_BumpBenched, from the
-- New Week popup), so everything here is hand-editable too - an
-- editor still needs to correct a miscount or backfill somebody.
--==================================================================

local ATTEND_ROW_HEIGHT = 18

-- field = the RedGuild_Data key, kind = how the value is edited.
local ATTEND_COLS = {
    { text = "Name",          width = 120, field = "name",           kind = "name" },
    { text = "Raids",         width = 55,  field = "raidsAttended",  kind = "count" },
    { text = "Last Raid",     width = 100, field = "lastAttendance", kind = "date" },
    { text = "Benched",       width = 65,  field = "benched",        kind = "count" },
    { text = "Last Benched",  width = 100, field = "lastBenched",    kind = "date" },
    { text = "Status",        width = 70,  field = "archived",       kind = "status" },
}

-- Row width follows the columns (5px gap between each).
ATTEND_ROW_WIDTH = 0
for i, c in ipairs(ATTEND_COLS) do
    ATTEND_ROW_WIDTH = ATTEND_ROW_WIDTH + c.width + (i > 1 and 5 or 0)
end

local attendanceRows = {}
local attendContent
local attendInlineEdit
local attendStatusText

-- Dates are shown and typed as DD.MM.YYYY but stored as YYYY-MM-DD.
-- The stored form is what the day-based de-duplication in
-- RedGuild_BumpAttendance compares against (it builds today's stamp
-- with date("%Y-%m-%d")), what the attendance sync puts on the wire,
-- and what sorts correctly as a plain string - so the display format
-- stops at the edge, and nothing downstream has to care.
function RedGuild_Attendance_FormatDate(stored)
    if type(stored) ~= "string" then return "Never" end

    local y, m, dd = stored:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
    if not y then return stored end   -- unrecognised: show it as-is

    return string.format("%s.%s.%s", dd, m, y)
end

-- Blank, "never" or "-" all clear the field; anything else has to be
-- a full date, so a typo cannot quietly become the value that the
-- day-based de-duplication then compares against. Returns the
-- canonical YYYY-MM-DD form.
--
-- DD.MM.YYYY is what the table shows, so it is what an editor will
-- type back. YYYY-MM-DD is still accepted: it is what the field held
-- before this and what an editor used to typing it will reach for.
local function ParseDateInput(text)
    text = tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "")

    if text == "" or text:lower() == "never" or text == "-" then
        return true, nil
    end

    local y, m, dd

    local dd2, m2, y4 = text:match("^(%d%d)%.(%d%d)%.(%d%d%d%d)$")
    if dd2 then
        y, m, dd = y4, m2, dd2
    else
        y, m, dd = text:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
    end
    if not y then return false end

    if tonumber(m) < 1 or tonumber(m) > 12
    or tonumber(dd) < 1 or tonumber(dd) > 31 then
        return false
    end

    return true, string.format("%s-%s-%s", y, m, dd)
end

-- kind is "count" (a whole number, floored at 0) or "date"
-- (YYYY-MM-DD, or empty/never/- to clear). Rejects anything else
-- rather than writing a value the automatic counters would then
-- compare against.
function RedGuild_Attendance_SetValue(playerName, field, kind, raw)
    local d = playerName and RedGuild_Data[playerName]
    if not d then return end

    local old = d[field]
    local new

    if kind == "count" then
        new = tonumber(raw)
        if not new then
            Print("|cffff5555Enter a number.|r")
            return
        end
        new = math.max(0, math.floor(new))
    else
        local ok, parsed = ParseDateInput(raw)
        if not ok then
            Print("|cffff5555Dates must be DD.MM.YYYY (or empty to clear).|r")
            return
        end
        new = parsed
    end

    if old == new then return end

    d[field] = new
    LogAudit(playerName, field, old == nil and "none" or tostring(old),
        new == nil and "none" or tostring(new))
    BumpDKPVersion()
    RedGuild_RefreshAttendanceTable()
end


--------------------------------------------------------------------
-- SORTING
--------------------------------------------------------------------
-- Click a header to sort by it, click it again to flip. Dates and
-- counters start newest/highest first, Name starts A-Z. "Never" counts
-- as the oldest date there is, so it sinks to the bottom of a newest
-- first sort. Ties always fall back to the name.
local attendSortField = "name"
local attendSortAsc   = true
local attendHeaderFS  = {}

local function SortValue(d, c)
    if c.kind == "count" then
        return tonumber(d[c.field]) or 0
    elseif c.kind == "date" then
        local v = d[c.field]
        return type(v) == "string" and v or ""
    elseif c.kind == "status" then
        return (d.archived == true) and 1 or 0
    end
    return 0
end

local function ColumnByField(field)
    for _, c in ipairs(ATTEND_COLS) do
        if c.field == field then return c end
    end
end

-- Exposed for the stub tests. Returns the names in display order.
function RedGuild_Attendance_SortedNames()
    local names = {}
    for name in pairs(RedGuild_Data) do
        if type(name) == "string" and strtrim(name) ~= "" then
            table.insert(names, name)
        end
    end

    local c = ColumnByField(attendSortField)

    if not c or c.kind == "name" then
        table.sort(names, function(a, b)
            if attendSortAsc then return a < b end
            return a > b
        end)
        return names
    end

    table.sort(names, function(a, b)
        local va = SortValue(RedGuild_Data[a] or {}, c)
        local vb = SortValue(RedGuild_Data[b] or {}, c)
        if va ~= vb then
            if attendSortAsc then return va < vb end
            return va > vb
        end
        return a < b
    end)

    return names
end

local function UpdateAttendHeaderColours()
    for i, c in ipairs(ATTEND_COLS) do
        local fs = attendHeaderFS[i]
        if fs then
            local arrow = ""
            if c.field == attendSortField then
                arrow = attendSortAsc and " ^" or " v"
            end
            local colour = (c.field == attendSortField) and SORT_COLOR or "|cffffd100"
            fs:SetText(colour .. c.text .. arrow .. "|r")
        end
    end
end

function RedGuild_Attendance_SetSort(field, ascending)
    local c = ColumnByField(field)
    if not c then return end

    if ascending == nil then
        if attendSortField == field then
            ascending = not attendSortAsc
        else
            ascending = (c.kind == "name")
        end
    end

    attendSortField = field
    attendSortAsc   = ascending and true or false

    UpdateAttendHeaderColours()
    RedGuild_RefreshAttendanceTable()
end

--------------------------------------------------------------------
-- ROWS
--------------------------------------------------------------------
local function StatusText(d)
    if d and d.archived == true then
        return "|cff888888Archived|r"
    end
    return "|cff40ff40Active|r"
end

local function CreateAttendanceRow(index)
    local row = CreateFrame("Frame", nil, attendContent)
    row:SetSize(ATTEND_ROW_WIDTH, ATTEND_ROW_HEIGHT)
    row:SetPoint("TOPLEFT", 0, -(index - 1) * ATTEND_ROW_HEIGHT)

    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.15)
    row.bg = bg

    row.cols = {}
    local x = 0

    for i, c in ipairs(ATTEND_COLS) do
        local col

        if c.kind == "name" then
            col = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            col:SetPoint("LEFT", row, "LEFT", x, 0)
            col:SetWidth(c.width)
            col:SetJustifyH("LEFT")
        else
            -- A button rather than a bare font string so the value can
            -- be clicked to edit, the same way the DKP table works.
            col = CreateFrame("Button", nil, row)
            col:SetPoint("LEFT", row, "LEFT", x, 0)
            col:SetSize(c.width, ATTEND_ROW_HEIGHT)

            local fs = col:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            fs:SetAllPoints(col)
            fs:SetJustifyH("LEFT")
            col:SetFontString(fs)

            col:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
            col:GetHighlightTexture():SetAlpha(0.3)

            col:SetScript("OnClick", function(self)
                if not IsAuthorized() then
                    Print("Only editors can modify attendance.")
                    return
                end

                local playerName = row.name
                if not playerName then return end

                attendInlineEdit:Hide()

                -- Status is a toggle, not a typed value.
                if c.kind == "status" then
                    local archive = not RedGuild_IsArchived(playerName)
                    if RedGuild_SetArchived(playerName, archive) then
                        BumpDKPVersion()
                        Print(string.format("%s %s.", playerName,
                            archive and "archived" or "is active again"))
                        RedGuild_RefreshAttendanceTable()
                        if UpdateTable and dkpScroll then UpdateTable() end
                    end
                    return
                end

                attendInlineEdit.currentBtn = self
                attendInlineEdit:ClearAllPoints()
                attendInlineEdit:SetPoint("LEFT", self, "LEFT", 0, 0)
                attendInlineEdit:SetWidth(c.width - 4)

                local d = RedGuild_Data[playerName]
                local value = d and d[c.field]
                if c.kind == "count" then
                    attendInlineEdit:SetText(tostring(tonumber(value) or 0))
                else
                    -- Pre-filled in the format the cell shows, so the
                    -- editor edits what they were looking at.
                    attendInlineEdit:SetText(
                        value and RedGuild_Attendance_FormatDate(value) or "")
                end

                attendInlineEdit.saveFunc = function(text)
                    RedGuild_Attendance_SetValue(playerName, c.field, c.kind, text)
                end

                attendInlineEdit:Show()
                attendInlineEdit:HighlightText()
            end)

            if c.kind == "status" then
                col:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:AddLine("Click to archive or reactivate")
                    GameTooltip:AddLine("Archived players keep their DKP and are hidden on the DKP tab while \"Hide archived\" is ticked.", 1, 1, 1, true)
                    GameTooltip:Show()
                end)
                col:SetScript("OnLeave", function() GameTooltip:Hide() end)
            end
        end

        row.cols[i] = col
        x = x + c.width + 5
    end

    return row
end

function RedGuild_RefreshAttendanceStatus()
    if not attendStatusText then return end

    local when = RedGuild_Config.lastAttendSync
    if not when then
        attendStatusText:SetText("|cff888888Last sync: never|r")
        return
    end

    attendStatusText:SetText(string.format("|cff888888Last sync: %s from %s|r",
        when, RedGuild_Config.lastAttendSyncFrom or "?"))
end

function RedGuild_RefreshAttendanceTable()
    RedGuild_RefreshAttendanceStatus()

    if not attendContent then return end

    local names = RedGuild_Attendance_SortedNames()

    for i, name in ipairs(names) do
        local row = attendanceRows[i]
        if not row then
            row = CreateAttendanceRow(i)
            attendanceRows[i] = row
        end

        local d = RedGuild_Data[name] or {}
        row.name = name

        local classColor = "|cffffffff"
        local c = d.class and RAID_CLASS_COLORS[d.class]
        if c then
            classColor = string.format("|cff%02x%02x%02x", c.r * 255, c.g * 255, c.b * 255)
        end
        if d.archived == true then
            classColor = "|cff808080"
        end

        for j, col in ipairs(ATTEND_COLS) do
            local text
            if col.kind == "name" then
                text = classColor .. name .. "|r"
            elseif col.kind == "count" then
                text = tostring(tonumber(d[col.field]) or 0)
            elseif col.kind == "date" then
                text = RedGuild_Attendance_FormatDate(d[col.field])
            elseif col.kind == "status" then
                text = StatusText(d)
            end
            row.cols[j]:SetText(text or "")
        end

        row:Show()
    end

    for i = #names + 1, #attendanceRows do
        attendanceRows[i]:Hide()
        attendanceRows[i].name = nil
    end

    attendContent:SetHeight(math.max(1, #names * ATTEND_ROW_HEIGHT))
end

--------------------------------------------------------------------
-- ARCHIVE INACTIVE (editors only, manual, always confirmed)
--------------------------------------------------------------------
-- Lists everyone with no raid and no bench in the last
-- REDGUILD_ARCHIVE_DAYS days (or none ever), all ticked, so the editor
-- can untick anyone who should stay before anything is archived.
local ARCHIVE_ROW_HEIGHT = 20
local archiveFrame

local function DescribeLastSeen(entry)
    if not entry.lastSeen then
        return "|cffff8080never attended|r"
    end
    return string.format("last seen %s (%d days)",
        RedGuild_Attendance_FormatDate(entry.lastSeen), entry.days or 0)
end

local function ArchiveFrame_UpdateCount(f)
    local n = 0
    for _, e in ipairs(f.entries or {}) do
        if e.selected then n = n + 1 end
    end
    f.archiveBtn:SetText(string.format("Archive %d", n))
    if n > 0 then f.archiveBtn:Enable() else f.archiveBtn:Disable() end
end

local function CreateArchiveFrame()
    local f = CreateFrame("Frame", "RedGuildArchiveFrame", UIParent, "BasicFrameTemplateWithInset")
    f:SetSize(360, 420)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:Hide()
    table.insert(UISpecialFrames, "RedGuildArchiveFrame")

    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.title:SetPoint("CENTER", f.TitleBg, "CENTER", 0, 0)
    f.title:SetText("Archive inactive players")

    f.info = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.info:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -32)
    f.info:SetPoint("TOPRIGHT", f, "TOPRIGHT", -16, -32)
    f.info:SetJustifyH("LEFT")

    local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -70)
    scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -34, 46)

    f.content = CreateFrame("Frame", nil, scroll)
    f.content:SetSize(300, 1)
    scroll:SetScrollChild(f.content)
    f.rows = {}

    f.archiveBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.archiveBtn:SetSize(110, 22)
    f.archiveBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -14, 14)
    f.archiveBtn:SetScript("OnClick", function()
        local names = {}
        for _, e in ipairs(f.entries or {}) do
            if e.selected then table.insert(names, e.name) end
        end
        RedGuild_ArchivePlayers(names)
        f:Hide()
    end)

    local cancelBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    cancelBtn:SetSize(80, 22)
    cancelBtn:SetPoint("RIGHT", f.archiveBtn, "LEFT", -8, 0)
    cancelBtn:SetText("Cancel")
    cancelBtn:SetScript("OnClick", function() f:Hide() end)

    f.toggleBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.toggleBtn:SetSize(90, 22)
    f.toggleBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 14, 14)
    f.toggleBtn:SetText("Select none")
    f.toggleBtn:SetScript("OnClick", function()
        local anySelected = false
        for _, e in ipairs(f.entries or {}) do
            if e.selected then anySelected = true break end
        end
        for _, e in ipairs(f.entries or {}) do
            e.selected = not anySelected
        end
        f.toggleBtn:SetText(anySelected and "Select all" or "Select none")
        RedGuild_ArchiveFrame_Refresh()
    end)

    return f
end

local function CreateArchiveRow(f, index)
    local row = CreateFrame("Frame", nil, f.content)
    row:SetSize(300, ARCHIVE_ROW_HEIGHT)
    row:SetPoint("TOPLEFT", 0, -(index - 1) * ARCHIVE_ROW_HEIGHT)

    row.chk = CreateFrame("CheckButton", nil, row, "ChatConfigCheckButtonTemplate")
    row.chk:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.chk:SetSize(18, 18)
    row.chk:SetScript("OnClick", function(self)
        if row.entry then
            row.entry.selected = self:GetChecked() and true or false
            ArchiveFrame_UpdateCount(f)
        end
    end)

    row.nameFS = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.nameFS:SetPoint("LEFT", row.chk, "RIGHT", 4, 0)
    row.nameFS:SetWidth(100)
    row.nameFS:SetJustifyH("LEFT")

    row.seenFS = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    row.seenFS:SetPoint("LEFT", row.nameFS, "RIGHT", 4, 0)
    row.seenFS:SetWidth(170)
    row.seenFS:SetJustifyH("LEFT")

    return row
end

function RedGuild_ArchiveFrame_Refresh()
    local f = archiveFrame
    if not f then return end

    local entries = f.entries or {}

    for i, e in ipairs(entries) do
        local row = f.rows[i]
        if not row then
            row = CreateArchiveRow(f, i)
            f.rows[i] = row
        end

        row.entry = e

        local d = RedGuild_Data[e.name] or {}
        local cc = d.class and RAID_CLASS_COLORS[d.class]
        local colour = cc and string.format("|cff%02x%02x%02x", cc.r * 255, cc.g * 255, cc.b * 255)
            or "|cffffffff"

        row.nameFS:SetText(colour .. e.name .. "|r")
        row.seenFS:SetText(DescribeLastSeen(e))
        row.chk:SetChecked(e.selected)
        row:Show()
    end

    for i = #entries + 1, #f.rows do
        f.rows[i]:Hide()
        f.rows[i].entry = nil
    end

    f.content:SetHeight(math.max(1, #entries * ARCHIVE_ROW_HEIGHT))
    ArchiveFrame_UpdateCount(f)
end

function RedGuild_OpenArchiveInactive()
    if not IsAuthorized() then
        Print("|cffff5555Only editors can archive players.|r")
        return
    end

    local entries = RedGuild_GetArchiveCandidates(REDGUILD_ARCHIVE_DAYS)

    if #entries == 0 then
        Print(string.format("Nobody to archive: every active main attended or "
            .. "was benched in the last %d days.", REDGUILD_ARCHIVE_DAYS))
        return
    end

    for _, e in ipairs(entries) do e.selected = true end

    archiveFrame = archiveFrame or CreateArchiveFrame()
    archiveFrame.entries = entries
    archiveFrame.toggleBtn:SetText("Select none")
    archiveFrame.info:SetText(string.format(
        "%d player(s) without a raid or bench in the last %d days. "
        .. "Untick anyone who should stay. Archiving keeps their DKP; "
        .. "alts are not listed.", #entries, REDGUILD_ARCHIVE_DAYS))

    RedGuild_ArchiveFrame_Refresh()
    archiveFrame:Show()
end

--------------------------------------------------------------------
-- TAB
--------------------------------------------------------------------
function CreateAttendanceTab()
    local title = attendancePanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", attendancePanel, "TOPLEFT", 30, -30)
    title:SetText("Raid Attendance")

    local note = attendancePanel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    note:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    note:SetText("Click a header to sort. Click any value to correct it. Dates are DD.MM.YYYY.")

    ----------------------------------------------------------------
    -- SYNC (editors only, and deliberately manual)
    ----------------------------------------------------------------
    -- These numbers ride on their own channel rather than the DKP
    -- sync, so they need pushing by hand once an editor is happy with
    -- them - see RedGuild_SendAttendanceSync.
    local syncBtn = CreateFrame("Button", nil, attendancePanel, "UIPanelButtonTemplate")
    syncBtn:SetSize(140, 22)
    syncBtn:SetPoint("TOPRIGHT", attendancePanel, "TOPRIGHT", -40, -32)
    syncBtn:SetText("Sync Attendance")
    syncBtn:SetScript("OnClick", function()
        RedGuild_SendAttendanceSync()
        RedGuild_RefreshAttendanceStatus()
    end)
    syncBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Sync Attendance")
        GameTooltip:AddLine("Sends these counters to the other editors.", 1, 1, 1)
        GameTooltip:AddLine("Attendance is not part of the DKP sync, so", 0.6, 0.6, 0.6)
        GameTooltip:AddLine("it only moves when you press this.", 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end)
    syncBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    attendStatusText = attendancePanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    attendStatusText:SetPoint("TOPRIGHT", syncBtn, "BOTTOMRIGHT", 0, -4)
    attendStatusText:SetJustifyH("RIGHT")

    ----------------------------------------------------------------
    -- ARCHIVE INACTIVE
    ----------------------------------------------------------------
    local archiveBtn = CreateFrame("Button", nil, attendancePanel, "UIPanelButtonTemplate")
    archiveBtn:SetSize(140, 22)
    archiveBtn:SetPoint("RIGHT", syncBtn, "LEFT", -8, 0)
    archiveBtn:SetText("Archive Inactive")
    archiveBtn:SetScript("OnClick", RedGuild_OpenArchiveInactive)
    archiveBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Archive Inactive")
        GameTooltip:AddLine(string.format(
            "Lists everyone with no raid or bench in the last %d days so you can archive them.",
            REDGUILD_ARCHIVE_DAYS), 1, 1, 1, true)
        GameTooltip:AddLine("Nothing happens until you confirm. Archived players keep their DKP "
            .. "and become active again automatically when they next attend.", 0.6, 0.6, 0.6, true)
        GameTooltip:Show()
    end)
    archiveBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    ----------------------------------------------------------------
    -- HEADERS (clickable, sort the list)
    ----------------------------------------------------------------
    local headerY = -70
    local x = 30

    for i, c in ipairs(ATTEND_COLS) do
        local btn = CreateFrame("Button", nil, attendancePanel)
        btn:SetPoint("TOPLEFT", attendancePanel, "TOPLEFT", x, headerY)
        btn:SetSize(c.width, 16)

        local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetAllPoints()
        fs:SetJustifyH("LEFT")
        attendHeaderFS[i] = fs

        btn:SetScript("OnClick", function()
            if attendInlineEdit then attendInlineEdit:Hide() end
            RedGuild_Attendance_SetSort(c.field)
        end)

        x = x + c.width + 5
    end

    UpdateAttendHeaderColours()

    ----------------------------------------------------------------
    -- SCROLLING LIST
    ----------------------------------------------------------------
    local scroll = CreateFrame("ScrollFrame", nil, attendancePanel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", attendancePanel, "TOPLEFT", 30, headerY - 20)
    scroll:SetPoint("BOTTOMRIGHT", attendancePanel, "BOTTOMRIGHT", -40, 30)

    attendContent = CreateFrame("Frame", nil, scroll)
    attendContent:SetSize(ATTEND_ROW_WIDTH, 1)
    scroll:SetScrollChild(attendContent)

    ----------------------------------------------------------------
    -- INLINE EDIT BOX
    ----------------------------------------------------------------
    attendInlineEdit = CreateFrame("EditBox", nil, attendContent, "InputBoxTemplate")
    attendInlineEdit:SetAutoFocus(true)
    attendInlineEdit:SetHeight(ATTEND_ROW_HEIGHT)
    attendInlineEdit:SetFrameStrata("HIGH")
    attendInlineEdit:Hide()

    attendInlineEdit:SetScript("OnEscapePressed", function(self)
        self.saveFunc = nil
        self:Hide()
    end)

    attendInlineEdit:SetScript("OnEnterPressed", function(self)
        local save = self.saveFunc
        self.saveFunc = nil
        self:Hide()
        if save then save(self:GetText()) end
    end)

    -- Clicking away is a cancel, not a save: a half-typed date left
    -- behind by a stray click should not overwrite a real one.
    attendInlineEdit:SetScript("OnEditFocusLost", function(self)
        self.saveFunc = nil
        self:Hide()
    end)

    attendancePanel:SetScript("OnShow", RedGuild_RefreshAttendanceTable)
end
