function CreateUI()
    --------------------------------------------------------------------
    -- MAIN FRAME
    --------------------------------------------------------------------
    mainFrame = CreateFrame("Frame", "RedGuildFrame", UIParent, "BasicFrameTemplateWithInset")
    mainFrame:SetSize(800, 500)
    mainFrame:SetPoint("CENTER")
    mainFrame:Hide()
	mainFrame:SetFrameLevel(666)
	
	mainFrame:SetMovable(true)
	mainFrame:EnableMouse(true)
	mainFrame:RegisterForDrag("LeftButton")
	mainFrame:SetScript("OnDragStart", function(self)
		self:StartMoving()
	end)
	
	mainFrame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
	end)
	
	table.insert(UISpecialFrames, "RedGuildFrame")

    local headerIcon = mainFrame:CreateTexture(nil, "OVERLAY", nil, 7)
    headerIcon:SetTexture("Interface\\AddOns\\RedGuild\\media\\RedGuild_Icon256.png")
    headerIcon:SetSize(128, 128)
    headerIcon:SetPoint("TOP", mainFrame, "LEFT", 20, 290)

    mainFrame.title = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    mainFrame.title:SetPoint("CENTER", mainFrame.TitleBg, "CENTER", 0, 0)
    mainFrame.title:SetText("Redemption Guild UI - brought to you by two clueless idiots called Lunátic and Celery Guy")

--------------------------------------------------------------------
-- SYNC INDICATOR (TITLE BAR)
--------------------------------------------------------------------
local closeBtn = mainFrame.CloseButton or _G[mainFrame:GetName().."CloseButton"]

local syncButton = CreateFrame("Frame", nil, mainFrame)
syncButton:SetPoint("RIGHT", closeBtn, "LEFT", -10, 0)
syncButton:SetSize(40, 20)
syncButton:EnableMouse(true)

-- "Sync" label
statusText = syncButton:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
statusText:SetPoint("LEFT", syncButton, "LEFT", 0, 0)
statusText:SetText("Sync")

-- coloured status box AFTER the text
statusBox = syncButton:CreateTexture(nil, "OVERLAY")
statusBox:SetPoint("LEFT", statusText, "RIGHT", 4, 0)
statusBox:SetSize(12, 12)

--------------------------------------------------------------------
-- TOOLTIP FOR SYNC INDICATOR
--------------------------------------------------------------------
local addonVersions = RedGuild_Config.AddonVersions or {}

syncButton:SetScript("OnEnter", function()
    GameTooltip:SetOwner(syncButton, "ANCHOR_TOPRIGHT")
    GameTooltip:ClearLines()

    GameTooltip:AddLine("|cffffff00Sync Status|r")
    GameTooltip:AddLine(" ")

local online, total = CountAddonMains()
GameTooltip:AddLine("|cffffffffAddon users: |r" .. online .. " / " .. total)

	--Outdated addon users
	local outdated = CountOutdatedUsers()
	GameTooltip:AddLine("|cffffffffOutdated addon users: |r" .. outdated)

    GameTooltip:AddLine(" ")

    -- Version sync
    GameTooltip:AddLine("|cffffff00Addon Version Sync|r")
    GameTooltip:AddLine("|cffffffffLast: |r" .. ColourForSyncAge(RedGuild_Config.lastVersionSync or "Never"))
    GameTooltip:AddLine("|cffffffffFrom: |r" .. (RedGuild_Config.lastVersionSyncFrom or "?"))
    GameTooltip:AddLine(" ")

-- DKP sync
GameTooltip:AddLine("|cffffff00DKP Data|r")
GameTooltip:AddLine("|cffffffffLast: |r" .. ColourForSyncAge(RedGuild_Config.lastDKPSync or "Never"))
GameTooltip:AddLine("|cffffffffFrom: |r" .. (RedGuild_Config.lastDKPSyncFrom or "?"))
local bestEditor, bestVersion = GetHighestVersionEditor()
	if bestEditor and bestVersion then
		GameTooltip:AddLine("|cffffffffHighest version: |r" .. bestVersion .. " (" .. bestEditor .. ")")
	else
		GameTooltip:AddLine("|cffffffffHighest version: |r?")
	end
GameTooltip:AddLine("|cffffffffYour version: |r" .. (RedGuild_Config.dkpVersion or "?"))
GameTooltip:AddLine(" ")

-- Alt sync
GameTooltip:AddLine("|cffffff00Alt Tracker Sync|r")
GameTooltip:AddLine("|cffffffffLast: |r" .. ColourForSyncAge(RedGuild_Config.lastAltSync or "Never"))
GameTooltip:AddLine("|cffffffffFrom: |r" .. (RedGuild_Config.lastAltSyncFrom or "?"))
GameTooltip:AddLine("|cffffffffVersion: |r" .. (RedGuild_Config.altsVersion or "?"))
GameTooltip:AddLine(" ")

-- Editor sync
GameTooltip:AddLine("|cffffff00Editor Sync|r")
GameTooltip:AddLine("|cffffffffLast: |r" .. ColourForSyncAge(RedGuild_Config.lastEditorSync or "Never"))
GameTooltip:AddLine("|cffffffffFrom: |r" .. (RedGuild_Config.lastEditorSyncFrom or "?"))

    GameTooltip:Show()
end)

syncButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

    --------------------------------------------------------------------
    -- TABS
    --------------------------------------------------------------------
	CreateTab(TAB_DKP,   "DKP")
	CreateTab(TAB_ALT,   "Alt Tracker")
	CreateTab(TAB_GROUP, "Inviter")
	CreateTab(TAB_ML, "ML Scorecard")
	
-- Force refresh when switching to ML tab
-- Force refresh when switching to ML tab
tabs[TAB_ML]:HookScript("OnClick", function()
    C_Timer.After(0.05, RefreshMLTools)
end)
	
	if IsEditor(UnitName("player")) then
    CreateTab(TAB_BIDLOG, "Bid Log")
    CreateTab(TAB_RAID, "RL Tools")
    CreateTab(TAB_EDITORS, "Editors")
    CreateTab(TAB_AUDIT,   "Audit Log")
	end

	RealignTabs()
    --------------------------------------------------------------------
    -- PANELS
    --------------------------------------------------------------------
    dkpPanel     = CreateFrame("Frame", nil, mainFrame); LayoutPanel(dkpPanel)
	
-- DKP LOCK BUTTON (Editors only)
local lockBtn = CreateFrame("Button", nil, dkpPanel, "UIPanelButtonTemplate")
lockBtn:SetSize(60, 20)
lockBtn:SetScale(0.8)
lockBtn:SetPoint("TOPRIGHT", dkpPanel, "TOPRIGHT", -20, -50)
lockBtn:SetFrameStrata("HIGH")
lockBtn:SetFrameLevel(1000)

local function UpdateLockButtonText()
    if dkpLocked then
        lockBtn:SetText("Unlock")
    else
        lockBtn:SetText("Lock")
    end
end

-- Only visible to editors
if not IsEditor(UnitName("player")) then
    lockBtn:Hide()
else
    lockBtn:Show()
end

lockBtn:SetScript("OnClick", function()
    dkpLocked = not dkpLocked
    UpdateLockButtonText()
    UpdateAddControls()
    UpdateTable()
end)

UpdateLockButtonText()
	
	-- Clicking anywhere on the DKP panel commits inline edits
	dkpPanel:EnableMouse(true)
	dkpPanel:SetPropagateMouseClicks(true)
	dkpPanel:SetScript("OnMouseDown", function()
		if dkpInlineEdit and dkpInlineEdit:IsShown() then
			dkpInlineEdit.cancelled = false
			if dkpInlineEdit.saveFunc then
				dkpInlineEdit.saveFunc(dkpInlineEdit:GetText())
			end
			dkpInlineEdit:Hide()
		end
	end)
	
    altPanel = CreateFrame("Frame", nil, mainFrame); LayoutPanel(altPanel)
	groupPanel   = CreateFrame("Frame", nil, mainFrame); LayoutPanel(groupPanel)
	mlPanel      = CreateFrame("Frame", nil, mainFrame); LayoutPanel(mlPanel)
    raidPanel    = CreateFrame("Frame", nil, mainFrame); LayoutPanel(raidPanel)
    editorsPanel = CreateFrame("Frame", nil, mainFrame); LayoutPanel(editorsPanel)
    auditPanel   = CreateFrame("Frame", nil, mainFrame); LayoutPanel(auditPanel)
    bidLogPanel  = CreateFrame("Frame", nil, mainFrame); LayoutPanel(bidLogPanel)
	
--------------------------------------------------------------------
-- ALT TRACKER PANEL
--------------------------------------------------------------------
do
    --------------------------------------------------------------------
    -- CONFIG
    --------------------------------------------------------------------
    local PANEL_WIDTH = 800
    local PANEL_HEIGHT = 450

    local LEFT_WIDTH = 300
    local RIGHT_WIDTH = 300
    local GAP = 50

    local TOPBAR_WIDTH = 400
    local ROW_HEIGHT = 20
	
	local PendingAlt = nil

    ----------------------------------------------------------------
    -- UTILITY: GET PLAYER NAME
    ----------------------------------------------------------------
    local function GetPlayerName()
        local name = UnitName("player")
        return name and Ambiguate(name, "none") or "Unknown"
    end

    ----------------------------------------------------------------
    -- UTILITY: CLASS COLOUR
    ----------------------------------------------------------------
    local function GetClassColor(name)
        local num = GetNumGuildMembers()
        for i = 1, num do
            local gName, _, _, _, _, _, _, _, _, _, class = GetGuildRosterInfo(i)
            if gName and Ambiguate(gName, "none") == name then
                local c = RAID_CLASS_COLORS[class]
                if c then
                    return string.format("|cff%02x%02x%02x", c.r*255, c.g*255, c.b*255)
                end
            end
        end
        return "|cffffffff"
    end

    ----------------------------------------------------------------
    -- UTILITY: GUILD ROSTER SNAPSHOT
    ----------------------------------------------------------------
    local function BuildGuildRosterList()
		--commented out refresh as might be causing lag spikes
        --if C_GuildInfo and C_GuildInfo.GuildRoster then
        --    C_GuildInfo.GuildRoster()
        --end

        local names = {}
        local num = GetNumGuildMembers()

        for i = 1, num do
            local info = GetGuildRosterInfo(i)
            local name = type(info) == "table" and info.name or info
            if name then
                name = Ambiguate(name, "none")
                table.insert(names, name)
            end
        end

        table.sort(names)
        return names
    end

    local GuildRosterCache = BuildGuildRosterList()

    ----------------------------------------------------------------
    -- UTILITY: CHECK IF NAME IS A MAIN
    ----------------------------------------------------------------
    function IsMain(name)
        return RedGuild_Alts[name] ~= nil
    end

    ----------------------------------------------------------------
    -- UTILITY: CHECK IF NAME IS AN ALT
    ----------------------------------------------------------------
    function IsAlt(name)
        return RedGuild_AltParent[name] ~= nil
    end

    ----------------------------------------------------------------
    -- UTILITY: GET MAIN OF ALT
    ----------------------------------------------------------------
    local function GetMainOf(alt)
        return RedGuild_AltParent[alt]
    end

    ----------------------------------------------------------------
    -- UTILITY: SAFE MESSAGE
    ----------------------------------------------------------------
    local function Msg(text)
        print("|cffff5555RedGuild AltTracker:|r " .. text)
    end

    ----------------------------------------------------------------
    -- TOP BAR FRAME (CENTERED)
    ----------------------------------------------------------------
    local topBar = CreateFrame("Frame", nil, altPanel)
    topBar:SetSize(TOPBAR_WIDTH, 40)
    topBar:SetPoint("TOP", altPanel, "TOP", -50, -40)

    topBar.text = topBar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    topBar.text:SetPoint("LEFT", topBar, "LEFT", 0, 0)

----------------------------------------------------------------
-- DROPDOWN 1: MAIN / ALT
----------------------------------------------------------------
local statusDrop = CreateFrame("Frame", nil, topBar, "UIDropDownMenuTemplate")
statusDrop:SetPoint("LEFT", topBar.text, "RIGHT", 10, 0)

----------------------------------------------------------------
-- TEXT BETWEEN DROPDOWNS: "of"
----------------------------------------------------------------
topBar.mainLabel = topBar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
topBar.mainLabel:SetPoint("LEFT", statusDrop, "RIGHT", 0, 0)
topBar.mainLabel:SetText("of")
topBar.mainLabel:Hide()

----------------------------------------------------------------
-- DROPDOWN 2: SELECT MAIN (ONLY WHEN ALT)
----------------------------------------------------------------
local mainSelectDrop = CreateFrame("Frame", nil, topBar, "UIDropDownMenuTemplate")
mainSelectDrop:SetPoint("LEFT", topBar.mainLabel, "RIGHT", 0, 0)
mainSelectDrop:Hide()

    ----------------------------------------------------------------
    -- LEFT PANEL (MAINS LIST)
    ----------------------------------------------------------------
    local leftPanel = CreateFrame("Frame", nil, altPanel, "BackdropTemplate")
    leftPanel:SetSize(LEFT_WIDTH, PANEL_HEIGHT - 80)
    leftPanel:SetPoint("TOPLEFT", altPanel, "TOPLEFT", 75, -80)
    leftPanel:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    leftPanel:SetBackdropColor(0,0,0,0.7)

    ----------------------------------------------------------------
    -- RIGHT PANEL (ALT SUMMARY)
    ----------------------------------------------------------------
    local rightPanel = CreateFrame("Frame", nil, altPanel, "BackdropTemplate")
    rightPanel:SetSize(RIGHT_WIDTH, PANEL_HEIGHT - 80)
    rightPanel:SetPoint("TOPLEFT", leftPanel, "TOPRIGHT", GAP, 0)
    rightPanel:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    rightPanel:SetBackdropColor(0,0,0,0.7)
	
----------------------------------------------------------------
-- ADD MAIN (EDITOR ONLY)
----------------------------------------------------------------
leftPanel.addMainBtn = CreateFrame("Button", nil, leftPanel, "UIPanelButtonTemplate")
leftPanel.addMainBtn:SetSize(100, 22)
leftPanel.addMainBtn:SetPoint("BOTTOMLEFT", 20, -30)
leftPanel.addMainBtn:SetText("Add Main")

leftPanel.addMainInput = CreateFrame("EditBox", nil, leftPanel, "InputBoxTemplate")
leftPanel.addMainInput:SetSize(140, 22)
leftPanel.addMainInput:SetPoint("LEFT", leftPanel.addMainBtn, "RIGHT", 10, 0)
leftPanel.addMainInput:SetAutoFocus(false)
leftPanel.addMainInput:SetMaxLetters(12)

-- Editor visibility
local function UpdateAddMainVisibility()
    if IsEditor(GetPlayerName()) then
        leftPanel.addMainBtn:Show()
        leftPanel.addMainInput:Show()
    else
        leftPanel.addMainBtn:Hide()
        leftPanel.addMainInput:Hide()
    end
end

altPanel:HookScript("OnShow", UpdateAddMainVisibility)
UpdateAddMainVisibility()

leftPanel.addMainBtn:SetScript("OnClick", function()
    local name = leftPanel.addMainInput:GetText()
    if not name or name == "" then
        Msg("Please enter a character name.")
        return
    end

    name = Ambiguate(name, "none")

    -- Validate guild membership
    local valid = false
    for _, gName in ipairs(GuildRosterCache) do
        if NormalizeName(gName) == NormalizeName(name) then
            valid = true
            break
        end
    end

    if not valid then
        Msg(name .. " is not a valid guild member.")
        return
    end

    -- Cannot be an alt
    if IsAlt(name) then
        Msg(name .. " is currently an alt. Remove them from their main first.")
        return
    end

    -- Cannot already be a main
    if IsMain(name) then
        Msg(name .. " is already a main.")
        return
    end

    -- Add as main
    RedGuild_Alts[name] = {}
    RedGuild_AltParent[name] = nil

    -- Version bump
    RedGuild_Config.altsVersion = (RedGuild_Config.altsVersion or 0) + 1

    -- Broadcast
    BroadcastAltFieldUpdate("AltParent", { alt = name, main = nil })
    BroadcastAltFieldUpdate("AddMain",   { main = name })

    leftPanel.addMainInput:SetText("")
    RefreshMainsList()
    rightPanel.update()
    UpdateTopBar()
end)

    ----------------------------------------------------------------
    -- LEFT PANEL: SCROLL LIST OF MAINS
    ----------------------------------------------------------------
    local mainsScroll = CreateFrame("ScrollFrame", nil, leftPanel, "UIPanelScrollFrameTemplate")
    mainsScroll:SetPoint("TOPLEFT", 10, -10)
    mainsScroll:SetPoint("BOTTOMRIGHT", -30, 10)

    local mainsContent = CreateFrame("Frame", nil, mainsScroll)
    mainsContent:SetSize(LEFT_WIDTH - 40, 1)
    mainsScroll:SetScrollChild(mainsContent)

    local mainRows = {}
    local selectedMain = nil
    ----------------------------------------------------------------
    -- BUILD LIST OF CONFIRMED MAINS
    ----------------------------------------------------------------
    local function GetConfirmedMains()
        local mains = {}

        -- Any key in RedGuild_Alts is a main
        for main, _ in pairs(RedGuild_Alts) do
            table.insert(mains, main)
        end

        -- Any character marked as Main in the top bar (no parent)
        for _, name in ipairs(GuildRosterCache) do
            if not RedGuild_AltParent[name] and not RedGuild_Alts[name] then
                -- Only include if explicitly set as main by user
                -- (We track this by ensuring RedGuild_Alts[name] exists)
                -- If not, skip.
            end
        end

        table.sort(mains)
        return mains
    end

    ----------------------------------------------------------------
    -- LEFT PANEL: CREATE A ROW
    ----------------------------------------------------------------
    local function CreateMainRow(i)
        local row = CreateFrame("Button", nil, mainsContent)
        row:SetSize(LEFT_WIDTH - 40, ROW_HEIGHT)
        row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)

        row.nameFS = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.nameFS:SetPoint("LEFT", 4, 0)

        row.countFS = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.countFS:SetPoint("RIGHT", -4, 0)

        row:SetScript("OnClick", function()
            selectedMain = row.name
            rightPanel:Show()
            rightPanel.update()
        end)

        return row
    end

    ----------------------------------------------------------------
    -- LEFT PANEL: REFRESH MAINS LIST
    ----------------------------------------------------------------
    function RefreshMainsList()
        local mains = GetConfirmedMains()
        local needed = #mains
        local current = #mainRows

        if needed > current then
            for i = current + 1, needed do
                mainRows[i] = CreateMainRow(i)
            end
        end

        for i, name in ipairs(mains) do
            local row = mainRows[i]
            row.name = name

		local color = GetClassColor(name)

		local statusText = ""
		if IsPlayerOnline(name) then
			statusText = " |cff55ff55(online)|r"
		else
			-- check if any alt is online
			local alts = RedGuild_Alts[name] or {}
			for _, alt in ipairs(alts) do
				if IsPlayerOnline(alt) then
					statusText = " |cffffff55(on alt)|r"
					break
				end
			end
		end

		row.nameFS:SetText(color .. name .. "|r" .. statusText)

            local count = RedGuild_Alts[name] and #RedGuild_Alts[name] or 0
            row.countFS:SetText(count)

            row:Show()
        end

        for i = needed + 1, #mainRows do
            mainRows[i]:Hide()
        end

        mainsContent:SetHeight(needed * ROW_HEIGHT)
    end

    ----------------------------------------------------------------
    -- RIGHT PANEL: UI ELEMENTS
    ----------------------------------------------------------------
    rightPanel.title = rightPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    rightPanel.title:SetPoint("TOPLEFT", 10, -10)

    rightPanel.altList = CreateFrame("Frame", nil, rightPanel)
    rightPanel.altList:SetPoint("TOPLEFT", 10, -40)
    rightPanel.altList:SetSize(RIGHT_WIDTH - 20, 1)

    rightPanel.altRows = {}

	----------------------------------------------------------------
	-- DELETE MAIN BUTTON (TOP RIGHT)
	----------------------------------------------------------------
	rightPanel.deleteMainBtn = CreateFrame("Button", nil, rightPanel, "UIPanelButtonTemplate")
	rightPanel.deleteMainBtn:SetSize(24, 24)
	rightPanel.deleteMainBtn:SetPoint("TOPRIGHT", -6, -6)
	rightPanel.deleteMainBtn:SetText("X")
	rightPanel.deleteMainBtn:SetNormalFontObject("GameFontHighlightSmall")
	rightPanel.deleteMainBtn:Hide()  -- editor-only

    ----------------------------------------------------------------
    -- RIGHT PANEL: CREATE ALT ROW
    ----------------------------------------------------------------
local function CreateAltRow(i)
    local row = CreateFrame("Frame", nil, rightPanel.altList)
    row:SetSize(RIGHT_WIDTH - 20, ROW_HEIGHT)
    row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)

    row.nameFS = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.nameFS:SetPoint("LEFT", 4, 0)

    -- REMOVE BUTTON FIRST
    row.removeBtn = CreateFrame("Button", nil, row)
    row.removeBtn:SetPoint("RIGHT", -4, 0)
    row.removeBtn:SetSize(60, ROW_HEIGHT)

    row.removeBtn.text = row.removeBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.removeBtn.text:SetPoint("CENTER")
    row.removeBtn.text:SetText("|cffff4444(remove)|r")

    -- NOW SET MAIN BUTTON
    row.setMainBtn = CreateFrame("Button", nil, row)
    row.setMainBtn:SetPoint("RIGHT", row.removeBtn, "LEFT", -5, 0)
    row.setMainBtn:SetSize(80, ROW_HEIGHT)

    row.setMainBtn.text = row.setMainBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.setMainBtn.text:SetPoint("CENTER")
    row.setMainBtn.text:SetText("|cff55ff55(set main)|r")
    row.setMainBtn:Hide()

    return row
end

    ----------------------------------------------------------------
    -- RIGHT PANEL: UPDATE FUNCTION
    ----------------------------------------------------------------
    function rightPanel.update()
        if not selectedMain then
            rightPanel.title:SetText("No main selected")
            for _, r in ipairs(rightPanel.altRows) do r:Hide() end
            return
        end

        local color = GetClassColor(selectedMain)
        rightPanel.title:SetText(color .. selectedMain .. "|r")

        local alts = RedGuild_Alts[selectedMain] or {}
        table.sort(alts)

        local needed = #alts
        local current = #rightPanel.altRows

        if needed > current then
            for i = current + 1, needed do
                rightPanel.altRows[i] = CreateAltRow(i)
            end
        end

        for i, alt in ipairs(alts) do
            local row = rightPanel.altRows[i]
            local c = GetClassColor(alt)
            local onlineText = IsPlayerOnline(alt) and " |cff55ff55(online)|r" or ""
			row.nameFS:SetText(c .. alt .. "|r" .. onlineText)
		
			if IsEditor(GetPlayerName()) then
				row.setMainBtn:Show()
			else
				row.setMainBtn:Hide()
			end

			row.setMainBtn:SetScript("OnClick", function()
				PromoteToMain(alt)
				ResetRightPanel()
				RefreshMainsList()
				UpdateTopBar()
			end)
			
			local viewer = GetPlayerName()
			local parent = RedGuild_AltParent[alt]

			if IsEditor(viewer) or (parent == viewer) then
				row.removeBtn:Show()
			else
				row.removeBtn:Hide()
			end

            row.removeBtn:SetScript("OnClick", function()
                -- Remove alt
                RedGuild_AltParent[alt] = nil
                for idx = #alts, 1, -1 do
                    if alts[idx] == alt then table.remove(alts, idx) end
                end
                rightPanel.update()
                RefreshMainsList()
				RedGuild_Config.altsVersion = (RedGuild_Config.altsVersion or 0) + 1
				BroadcastAltFieldUpdate("AltParent", { alt = alt, main = nil })
				BroadcastAltFieldUpdate("RemoveAltFromMain", { main = selectedMain, alt = alt })
            end)

            row:Show()
        end

        for i = needed + 1, #rightPanel.altRows do
            rightPanel.altRows[i]:Hide()
        end

        rightPanel.altList:SetHeight(needed * ROW_HEIGHT)
    end
	
	----------------------------------------------------------------
	-- RESET RIGHT PANEL (SAFE GLOBAL WRAPPER)
	----------------------------------------------------------------
	local function ResetRightPanel()
		selectedMain = nil
		rightPanel.update()
	end

	_G.ResetRightPanel = ResetRightPanel
	
    ----------------------------------------------------------------
    -- MAIN / ALT SWITCHING LOGIC
    ----------------------------------------------------------------

    -- Promote an alt to main (swap)
function PromoteToMain(alt)
    local oldMain = RedGuild_AltParent[alt]
    if not oldMain then return end

    -- promoted alt becomes a true main
    RedGuild_AltParent[alt] = nil
	
    -- (optional but sane to ensure a list exists)
    RedGuild_Alts[alt] = RedGuild_Alts[alt] or {}

    -- Old main's alt list
    local oldList = RedGuild_Alts[oldMain] or {}

    -- New main's alt list (keep any existing alts on alt)
    local newList = RedGuild_Alts[alt] or {}

    ----------------------------------------------------------------
    -- MOVE ALL ALTS FROM OLD MAIN → NEW MAIN
    ----------------------------------------------------------------
    for i = #oldList, 1, -1 do
        local a = oldList[i]

        if a == alt then
            -- Remove the promoted alt from old main's list
            table.remove(oldList, i)
        else
            -- Move this alt under the new main
            RedGuild_AltParent[a] = alt
            table.insert(newList, a)

            -- Remove from old main
            table.remove(oldList, i)

            -- Broadcast this alt's new parent
            BroadcastAltFieldUpdate("AltParent", { alt = a, main = alt })
            BroadcastAltFieldUpdate("AddAltToMain", { main = alt, alt = a })
        end
    end

    ----------------------------------------------------------------
    -- OLD MAIN BECOMES AN ALT OF THE NEW MAIN
    ----------------------------------------------------------------
    RedGuild_AltParent[oldMain] = alt
    table.insert(newList, oldMain)

    BroadcastAltFieldUpdate("AltParent", { alt = oldMain, main = alt })
    BroadcastAltFieldUpdate("AddAltToMain", { main = alt, alt = oldMain })

    ----------------------------------------------------------------
    -- FINAL TABLE ASSIGNMENTS
    ----------------------------------------------------------------
    RedGuild_Alts[alt] = newList

    if #oldList == 0 then
        RedGuild_Alts[oldMain] = nil
    else
        RedGuild_Alts[oldMain] = oldList
    end

    ----------------------------------------------------------------
    -- VERSION BUMP
    ----------------------------------------------------------------
    RedGuild_Config.altsVersion = (RedGuild_Config.altsVersion or 0) + 1
end

function AssignAlt(alt, main)
    -- If this character is a main, only block if they have alts
    if IsMain(alt) then
        local altCount = RedGuild_Alts[alt] and #RedGuild_Alts[alt] or 0
        if altCount > 0 then
            Msg(alt .. " is designated as a main and has alts. Please reassign those alts first.")
            return false
        end

        -- They are a main with zero alts → allow demotion
        RedGuild_Alts[alt] = nil
    end

    -- Remove from previous parent
    local oldMain = RedGuild_AltParent[alt]
    if oldMain then
        local t = RedGuild_Alts[oldMain]
        if t then
            for i = #t, 1, -1 do
                if t[i] == alt then table.remove(t, i) end
            end
        end
    end

    -- Assign new parent
    RedGuild_AltParent[alt] = main
    RedGuild_Alts[main] = RedGuild_Alts[main] or {}
    table.insert(RedGuild_Alts[main], alt)

    RedGuild_Config.altsVersion = (RedGuild_Config.altsVersion or 0) + 1

    BroadcastAltFieldUpdate("AltParent", { alt = alt, main = main })
    BroadcastAltFieldUpdate("AddAltToMain", { main = main, alt = alt })

    return true
end
	
----------------------------------------------------------------
-- INITIALIZER FOR MAIN-SELECT DROPDOWN
----------------------------------------------------------------
local function InitMainSelectDropdown(self, level)
    local player = GetPlayerName()
    local mains  = GetConfirmedMains()

    for _, name in ipairs(mains) do
        if name ~= player then
            local info = UIDropDownMenu_CreateInfo()
            info.text = name
            info.func = function()
    if AssignAlt(player, name) then
        -- Version bump
        RedGuild_Config.altsVersion = (RedGuild_Config.altsVersion or 0) + 1

        -- Broadcast the change
        BroadcastAltFieldUpdate("AltParent", { alt = player, main = name })
        BroadcastAltFieldUpdate("AddAltToMain", { main = name, alt = player })
    end

    PendingAlt = nil
    RefreshMainsList()
    rightPanel.update()
    UpdateTopBar()
end
            UIDropDownMenu_AddButton(info)
        end
    end
end

UIDropDownMenu_SetWidth(mainSelectDrop, 140)
UIDropDownMenu_Initialize(mainSelectDrop,  InitMainSelectDropdown)

----------------------------------------------------------------
-- TOP BAR UPDATE
----------------------------------------------------------------
function UpdateTopBar()

	-- Prevent early calls before UI is created
	if not statusDrop or not mainSelectDrop or not topBar or not topBar.text then
		return
	end
	
    local player = GetPlayerName()
    local color  = GetClassColor(player)

    local isAlt  = IsAlt(player)
    local parent = GetMainOf(player)
    local isMain = IsMain(player)

    -- Base text: "You are on <name> who is a "
    topBar.text:SetText("You are on " .. color .. player .. "|r who is a")

    ----------------------------------------------------------------
    -- STATUS RESOLUTION: Main / Alt / Select / Pending Alt
    ----------------------------------------------------------------
    local statusText
    local showMainSelect = false

    if PendingAlt == player then
        -- User has chosen "Alt" but not yet picked a main
        statusText = "Alt"
        showMainSelect = true
    elseif isAlt then
        -- Already an alt with a stored parent
        statusText = "Alt"
        showMainSelect = true
    elseif isMain then
        statusText = "Main"
        showMainSelect = false
    else
        statusText = "Select"
        showMainSelect = false
    end

    UIDropDownMenu_SetText(statusDrop, statusText)

    if showMainSelect then
        UIDropDownMenu_SetText(mainSelectDrop, parent or "")
    else
        UIDropDownMenu_SetText(mainSelectDrop, "")
    end
	
    ----------------------------------------------------------------
    -- DROPDOWN 1: MAIN / ALT
    ----------------------------------------------------------------
    UIDropDownMenu_SetWidth(statusDrop, 80)
    UIDropDownMenu_Initialize(statusDrop, function(self, level)
        local info

        -- OPTION: MAIN
        info = UIDropDownMenu_CreateInfo()
        info.text = "Main"
        info.func = function()
            -- Clear any pending alt state
            PendingAlt = nil

            -- If currently an alt, promote to main (swap)
            if IsAlt(player) then
                PromoteToMain(player)
            end

            -- Ensure this character is recorded as a main
            RedGuild_Alts[player] = RedGuild_Alts[player] or {}
            RedGuild_AltParent[player] = nil

            mainSelectDrop:Hide()
            RefreshMainsList()
            rightPanel.update()
            UpdateTopBar()
        end
        UIDropDownMenu_AddButton(info)

        -- OPTION: ALT
		info = UIDropDownMenu_CreateInfo()
		info.text = "Alt"
		info.func = function()
		local altCount = (RedGuild_Alts[player] and #RedGuild_Alts[player]) or 0

		-- Only block if they are a main WITH alts
		if IsMain(player) and altCount > 0 then
			Msg("This character has alts, please first set one of those as your main (You will need to log that toon on).")
			return
		end

		-- Allow demotion if they are a main with zero alts
		PendingAlt = player

    UpdateTopBar()
end
UIDropDownMenu_AddButton(info)
    end)

    UIDropDownMenu_SetText(statusDrop, statusText)

    ----------------------------------------------------------------
    -- DROPDOWN 2: SELECT MAIN (ONLY WHEN ALT OR PENDING ALT)
    ----------------------------------------------------------------
    if showMainSelect then
		topBar.mainLabel:Show()
		mainSelectDrop:Show()
		UIDropDownMenu_SetText(mainSelectDrop, parent or "Select")
	else
		topBar.mainLabel:Hide()
		mainSelectDrop:Hide()
	end
end

    ----------------------------------------------------------------
    -- EDITOR TOOLS (ADD ALT / SET AS MAIN)
    ----------------------------------------------------------------
    rightPanel.addAltBtn = CreateFrame("Button", nil, rightPanel, "UIPanelButtonTemplate")
    rightPanel.addAltBtn:SetSize(100, 22)
    rightPanel.addAltBtn:SetPoint("BOTTOMLEFT", 30, -30)
    rightPanel.addAltBtn:SetText("Add Alt")
	
	rightPanel.addAltInput = CreateFrame("EditBox", nil, rightPanel, "InputBoxTemplate")
	rightPanel.addAltInput:SetSize(120, 22)
	rightPanel.addAltInput:SetPoint("LEFT", rightPanel.addAltBtn, "RIGHT", 10, 0)
	rightPanel.addAltInput:SetAutoFocus(false)
	rightPanel.addAltInput:SetMaxLetters(12)
	
	----------------------------------------------------------------
    -- HIDE EDITOR BUTTONS FOR NON‑EDITORS
    ----------------------------------------------------------------
local function UpdateEditorButtons()
    local isEditor = IsEditor(GetPlayerName())

    if isEditor then
        rightPanel.addAltBtn:Show()
        rightPanel.addAltInput:Show()
		rightPanel.deleteMainBtn:Show()
    else
        rightPanel.addAltBtn:Hide()
        rightPanel.addAltInput:Hide()
		rightPanel.deleteMainBtn:Hide()
    end
end
	
	-- Ensure editor buttons update every time the panel becomes visibleset
	altPanel:HookScript("OnShow", function()
		UpdateEditorButtons()
	end)

	rightPanel.addAltBtn:SetScript("OnClick", function()
		if not selectedMain then return end

		local name = rightPanel.addAltInput:GetText()
		if not name or name == "" then
			Msg("Please enter a character name.")
			return
		end

		name = Ambiguate(name, "none")

		-- Validate against guild roster
		local valid = false
		for _, gName in ipairs(GuildRosterCache) do
			if NormalizeName(gName) == NormalizeName(name) then
				valid = true
				break
			end
		end

		if not valid then
			Msg(name .. " is not a valid guild member.")
			return
		end

		-- Assign alt
		AssignAlt(name, selectedMain)
		rightPanel.addAltInput:SetText("")
		RefreshMainsList()
		rightPanel.update()
	end)
	
	rightPanel.deleteMainBtn:SetScript("OnClick", function()
		if not selectedMain then return end
			StaticPopup_Show("REDGUILD_DELETE_MAIN", selectedMain, nil, selectedMain)
	end)

	UpdateEditorButtons()
    ----------------------------------------------------------------
    -- FULL REFRESH
    ----------------------------------------------------------------
    local function FullRefresh()
        GuildRosterCache = BuildGuildRosterList()
        RefreshMainsList()
        rightPanel.update()
        UpdateTopBar()
    end

    altPanel:SetScript("OnShow", FullRefresh)
    ----------------------------------------------------------------
    -- INITIALISE ON LOAD (if panel is already visible)
    ----------------------------------------------------------------
    if altPanel:IsShown() then
        FullRefresh()
    end
end	
	

--------------------------------------------------------------------
-- GROUP BUILDER PANEL (INVITER)
--------------------------------------------------------------------
selectedState = selectedState or {}
do
    ------------------------------------------------------------
    -- TITLE
    ------------------------------------------------------------
    local title = groupPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 30, -30)
    title:SetText("")
	local RefreshGroupBuilder
	
    ------------------------------------------------------------
    -- LEFT SIDE: SCROLL LIST (HALF WIDTH)
    ------------------------------------------------------------
    local scroll = CreateFrame("ScrollFrame", nil, groupPanel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", groupPanel, "TOPLEFT", 30, -60)
    scroll:SetPoint("BOTTOMLEFT", groupPanel, "BOTTOMLEFT", 30, 50)
    scroll:SetWidth(groupPanel:GetWidth() * 0.40)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(1, 1)
    scroll:SetScrollChild(content)

    local ROW_HEIGHT = 20
    groupRows = {}

    ------------------------------------------------------------
    -- RIGHT SIDE: INFO BOX
    ------------------------------------------------------------
    local infoBox = CreateFrame("Frame", nil, groupPanel, "BackdropTemplate")
    infoBox:SetPoint("TOPRIGHT", groupPanel, "TOPRIGHT", -30, -60)
    infoBox:SetPoint("BOTTOMRIGHT", groupPanel, "BOTTOMRIGHT", -30, 50)
    infoBox:SetWidth(groupPanel:GetWidth() * 0.45)

    infoBox:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    infoBox:SetBackdropColor(0, 0, 0, 0.6)

    local infoText = infoBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    infoText:SetPoint("TOPLEFT", 10, -10)
    infoText:SetJustifyH("LEFT")
    infoText:SetWidth(infoBox:GetWidth() - 20)
    infoText:SetText("No players selected.")

    ------------------------------------------------------------
    -- CLASS COLOUR LOOKUP
    ------------------------------------------------------------
    local CLASS_COLORS = {}
    for class, c in pairs(RAID_CLASS_COLORS) do
        CLASS_COLORS[class] = string.format("|cff%02x%02x%02x", c.r * 255, c.g * 255, c.b * 255)
    end

    ------------------------------------------------------------
    -- INFO BOX UPDATE FUNCTION
    ------------------------------------------------------------
    local function UpdateGroupBuilderInfo()
        local selected = {}
        local classCounts = {}
        local roleCounts = {
            tank = 0,
            melee = 0,
            ranged = 0,
            caster = 0,
            healer = 0,
            unknown = 0,
        }

        for _, row in ipairs(groupRows) do
			if row.checkbox:GetChecked() and row.name then
				table.insert(selected, row.name)

        ------------------------------------------------------------
        -- SAFE LOOKUP (DKP players have data, guild-only do not)
        ------------------------------------------------------------
        local d = RedGuild_Data[row.name]

        ------------------------------------------------------------
        -- CLASS COUNT (only DKP players have class data)
        ------------------------------------------------------------
        local class = d and d.class or nil
        if class then
            classCounts[class] = (classCounts[class] or 0) + 1
        end

        ------------------------------------------------------------
        -- ROLE COUNT (only DKP players have msRole)
        ------------------------------------------------------------
        local spec = d and d.msRole or nil
        local role = SPEC_ROLES[spec]

        if role == "tank" then
            roleCounts.tank = roleCounts.tank + 1
        elseif role == "melee" then
            roleCounts.melee = roleCounts.melee + 1
        elseif role == "ranged" then
            roleCounts.ranged = roleCounts.ranged + 1
        elseif role == "caster" then
            roleCounts.caster = roleCounts.caster + 1
        elseif role == "healer" then
            roleCounts.healer = roleCounts.healer + 1
        else
            roleCounts.unknown = roleCounts.unknown + 1
        end
    end
end

        local lines = {}

        table.insert(lines, string.format("Selected: |cffffff00%d|r", #selected))
        table.insert(lines, "")
        table.insert(lines, "Classes:")

        for class, count in pairs(classCounts) do
            local c = RAID_CLASS_COLORS[class]
            if c then
                local hex = string.format("|cff%02x%02x%02x", c.r*255, c.g*255, c.b*255)
                table.insert(lines, string.format("  %s%s|r: %d", hex, class, count))
            else
                table.insert(lines, string.format("  %s: %d", class, count))
            end
        end

        table.insert(lines, "")
        table.insert(lines, "Roles (Main spec ONLY):")
        table.insert(lines, string.format("  Tanks: %d", roleCounts.tank))
        table.insert(lines, string.format("  Melee DPS: %d", roleCounts.melee))
        table.insert(lines, string.format("  Ranged DPS: %d", roleCounts.ranged))
        table.insert(lines, string.format("  Caster DPS: %d", roleCounts.caster))
        table.insert(lines, string.format("  Healers: %d", roleCounts.healer))
        table.insert(lines, string.format("  Unknown: %d", roleCounts.unknown))
		
		------------------------------------------------------------
		-- MAIN / ALT COUNTS (ALT TRACKER INTEGRATION)
		------------------------------------------------------------
		local mainCount = 0
		local altCount  = 0

		for _, name in ipairs(selected) do
			if IsAlt and IsAlt(name) then
				altCount = altCount + 1
			else
				-- treat unknowns as mains
				mainCount = mainCount + 1
			end
		end

		table.insert(lines, "")
		table.insert(lines, string.format("Mains: |cffffff00%d|r", mainCount))
		table.insert(lines, string.format("Alts:  |cffffff00%d|r", altCount))

        ------------------------------------------------------------
        -- GROUP MEMBERSHIP CHECK
        ------------------------------------------------------------
        local groupMembers = {}
		
		if not IsInRaid() and not IsInGroup() then
			local playerName = UnitName("player")
			if playerName then
				groupMembers[playerName] = true
			end
		end

        if IsInRaid() then
            for i = 1, GetNumGroupMembers() do
                local name = UnitName("raid"..i)
                if name then groupMembers[name] = true end
            end
        elseif IsInGroup() then
            for i = 1, GetNumSubgroupMembers() do
                local name = UnitName("party"..i)
                if name then groupMembers[name] = true end
            end
            groupMembers[UnitName("player")] = true
        end

        local missing = {}
        for _, name in ipairs(selected) do
            if not groupMembers[name] then
                table.insert(missing, name)
            end
        end

        table.insert(lines, "")
        
		------------------------------------------------------------
		-- SOLO MODE FIX: COUNT YOURSELF IF SELECTED
		------------------------------------------------------------
		local groupCount = GetNumGroupMembers()

		if groupCount == 0 then
			-- solo: check if the player is selected
			local playerName = Ambiguate(UnitName("player"), "short")
			for _, name in ipairs(selected) do
				if name == playerName then
					groupCount = 1
					break
				end
			end
		end

		table.insert(lines, string.format("In your group: |cffffff00%d|r", groupCount))
		
        table.insert(lines, "Missing from group:")

        if #missing == 0 then
            table.insert(lines, "  |cff00ff00None|r")
        else
            local row = {}
            for i, name in ipairs(missing) do
                local online = IsPlayerOnline(name)
				local offlineText = online and "" or " |cffaaaaaa(off)|r"

				local colour = online and "|cffff3333" or "|cffaaaaaa"   -- red if online, grey if offline
				local display = colour .. name .. "|r"

				table.insert(row, display)
                if #row == 4 then
                    table.insert(lines, "  " .. table.concat(row, ", "))
                    row = {}
                end
            end
            if #row > 0 then
                table.insert(lines, "  " .. table.concat(row, ", "))
            end
        end

        infoText:SetText(table.concat(lines, "\n"))
        infoText:SetText(infoText:GetText() .. "\n\n|cffaaaaaaGrey names are not online.|r")
    end

    ------------------------------------------------------------
    -- SELECT ALL / DESELECT ALL CHECKBOX
    ------------------------------------------------------------
    local selectAllChk = CreateFrame("CheckButton", nil, groupPanel, "ChatConfigCheckButtonTemplate")
    selectAllChk:SetPoint("TOPLEFT", groupPanel, "TOPLEFT", 70, -35)
    selectAllChk:SetSize(18, 18)
	selectAllChk:SetHitRectInsets(4, 4, 4, 4)

    local selectAllLabel = groupPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    selectAllLabel:SetPoint("LEFT", selectAllChk, "RIGHT", 4, 0)
    selectAllLabel:SetText("Select all")

    selectAllChk:SetScript("OnClick", function(self)
        local checked = self:GetChecked()

        for _, row in ipairs(groupRows) do
            if row:IsShown() then
                row.checkbox:SetChecked(checked)
                selectedState[row.name] = checked
            end
        end

        UpdateGroupBuilderInfo()
    end)
	
	------------------------------------------------------------
	-- ADD ONLINE GUILD MEMBERS CHECKBOX
	------------------------------------------------------------
	local addGuildChk = CreateFrame("CheckButton", nil, groupPanel, "ChatConfigCheckButtonTemplate")
	addGuildChk:SetPoint("LEFT", selectAllLabel, "RIGHT", 40, 0)
	addGuildChk:SetSize(18, 18)
	addGuildChk:SetHitRectInsets(4, 4, 4, 4)

	local addGuildLabel = groupPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	addGuildLabel:SetPoint("LEFT", addGuildChk, "RIGHT", 4, 0)
	addGuildLabel:SetText("Add online guild members")

	addGuildChk:SetScript("OnClick", function()
		RefreshGroupBuilder()
	end)
	
	------------------------------------------------------------
	-- HIDE IN-GROUP MEMBERS CHECKBOX
	------------------------------------------------------------
	local hideGroupChk = CreateFrame("CheckButton", nil, groupPanel, "ChatConfigCheckButtonTemplate")
	hideGroupChk:SetPoint("LEFT", addGuildLabel, "RIGHT", 40, 0)
	hideGroupChk:SetSize(18, 18)
	hideGroupChk:SetHitRectInsets(4, 4, 4, 4)

	local hideGroupLabel = groupPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	hideGroupLabel:SetPoint("LEFT", hideGroupChk, "RIGHT", 4, 0)
	hideGroupLabel:SetText("Hide users already in group")

	hideGroupChk:SetScript("OnClick", function()
		RefreshGroupBuilder()
	end)

    ------------------------------------------------------------
    -- REFRESH LIST
    ------------------------------------------------------------
    RefreshGroupBuilder = function()
        for _, row in ipairs(groupRows) do
            row:Hide()
        end
        wipe(groupRows)

        local names = {}

		-- 1. DKP table names
		for name in pairs(RedGuild_Data) do
			table.insert(names, name)
		end

		-- 2. Add online guild members if checkbox is ticked
		if addGuildChk:GetChecked() then
			local num = GetNumGuildMembers()
			for i = 1, num do
				local gName, _, _, _, _, _, _, _, online = GetGuildRosterInfo(i)
				if gName then
					gName = Ambiguate(gName, "short")
					if online then
						-- Only add if not already in DKP table
						if not RedGuild_Data[gName] then
							table.insert(names, gName)
						end
					end
				end
			end
		end

		table.sort(names)

        local i = 0
        for _, name in ipairs(names) do
            local isInvalid = RuntimeInvalid(name)

				-- NEW: hide users already in group
				local hideThis = false
				if hideGroupChk:GetChecked() then
					if UnitInParty(name) or UnitInRaid(name) then
						hideThis = true
					end
				end

				if not isInvalid and not hideThis then
                i = i + 1
                local row = groupRows[i]

                if not row then
                    row = CreateFrame("Frame", nil, content)
                    row:SetSize(300, ROW_HEIGHT)

                    local cb = CreateFrame("CheckButton", nil, row, "ChatConfigCheckButtonTemplate")
                    cb:SetPoint("LEFT", 0, 0)
                    cb:SetSize(20, 20)
                    row.checkbox = cb

                    local fs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                    fs:SetPoint("LEFT", cb, "RIGHT", 5, 0)
                    row.nameFS = fs

                    cb:SetScript("OnClick", function(self)
                        if row.name then
                            selectedState[row.name] = self:GetChecked() or false
                        end
                        UpdateGroupBuilderInfo()
                    end)

                    groupRows[i] = row
                end

                row:SetPoint("TOPLEFT", 10, -(i - 1) * ROW_HEIGHT)
                row.name = name

                local class = RedGuild_Data[name] and RedGuild_Data[name].class or nil
				local colour = CLASS_COLORS[class] or "|cffaaaaaa"   -- grey if unknown class

                local online = IsPlayerOnline(name)
				local offlineText = online and "" or " |cffaaaaaa(offline)|r"

				------------------------------------------------------------
				-- IN-GROUP CHECK (raid or party)
				------------------------------------------------------------
				local inGroup = false

				if IsInRaid() then
					for i = 1, GetNumGroupMembers() do
						if Ambiguate(UnitName("raid"..i), "short") == name then
							inGroup = true
							break
						end
					end
				elseif IsInGroup() then
					for i = 1, GetNumSubgroupMembers() do
						if Ambiguate(UnitName("party"..i), "short") == name then
							inGroup = true
							break
						end
					end

					-- Include the player themselves
					if Ambiguate(UnitName("player"), "short") == name then
						inGroup = true
					end
				end

				local inGroupText = inGroup and " |cff00ff00(in group)|r" or ""

				------------------------------------------------------------
				-- FINAL NAME STRING
				------------------------------------------------------------
				row.nameFS:SetText(colour .. name .. "|r" .. offlineText .. inGroupText)

                row.checkbox:SetChecked(selectedState[name] or false)

                row:Show()
            end
        end

        content:SetHeight(i * ROW_HEIGHT)
        UpdateGroupBuilderInfo()
    end

    ------------------------------------------------------------
    -- 10-SECOND ONLINE SCAN
    ------------------------------------------------------------
    local scanTicker = nil
    local function StartOnlineScan()
        if not scanTicker then
            scanTicker = C_Timer.NewTicker(10, RefreshGroupBuilder)
        end
    end

    local function StopOnlineScan()
        if scanTicker then
            scanTicker:Cancel()
            scanTicker = nil
        end
    end


    ------------------------------------------------------------
    -- INVITE BUTTON (NO AUTO-UNTICK)
    ------------------------------------------------------------
local inviteBtn = CreateFrame("Button", nil, groupPanel, "UIPanelButtonTemplate")
inviteBtn:SetSize(140, 24)
inviteBtn:SetText("Invite to Group")
inviteBtn:SetPoint("BOTTOMRIGHT", groupPanel, "BOTTOMRIGHT", -10, 10)

inviteBtn:SetScript("OnClick", function()
    local pending = {}
    local playerName = Ambiguate(UnitName("player"), "short")

    -- Build list of players to invite
    for _, row in ipairs(groupRows) do
        if row:IsShown() and row.checkbox:GetChecked() then
            local name = row.name
            if name ~= playerName and not UnitInParty(name) and not UnitInRaid(name) then
                table.insert(pending, name)
            end
        end
    end

    if #pending == 0 then
        Print("No players selected.")
        return
    end

    local function InviteAllOnce()
        for _, name in ipairs(pending) do
            RedGuild_Invite(name)
        end
    end

    -- If not already in a raid, convert first, then invite
    if not IsInRaid() then
        RedGuild_ConvertToRaid()
        C_Timer.After(1.5, InviteAllOnce)
    else
        InviteAllOnce()
    end
end)

    ------------------------------------------------------------
    -- INFO TEXT (BOTTOM LEFT)
    ------------------------------------------------------------
    local info = groupPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    info:SetPoint("BOTTOMLEFT", groupPanel, "BOTTOMLEFT", 10, 10)
    info:SetJustifyH("LEFT")
    info:SetText("|cffaaaaaa*This list is populated from the DKP table and scans every 10 seconds (with the tab open) to check who's online.|r")

    ------------------------------------------------------------
    -- PANEL SHOW/HIDE
    ------------------------------------------------------------
    groupPanel:SetScript("OnShow", function()
        RefreshGroupBuilder()
        StartOnlineScan()
    end)

    groupPanel:SetScript("OnHide", function()
        StopOnlineScan()
	end)
end

--------------------------------------------------------------------
-- ML SCORECARD PANEL
--------------------------------------------------------------------
local mlShowGroupOnly = false
do
    ----------------------------------------------------------------
    -- COLUMN HEADERS
    ----------------------------------------------------------------
    local headerFrame = CreateFrame("Frame", nil, mlPanel)
    headerFrame:SetPoint("TOPLEFT", mlPanel, "TOPLEFT", 60, -40)
    headerFrame:SetSize(600, 20)

local headers = {
    { text = "Name",      width = 140 },
    { text = "Main (MS)", width = 150  },
    { text = "Main (OS)", width = 150  },
    { text = "Notes",     width = 200 },
}

    local x = 0
    for _, h in ipairs(headers) do
        local fs = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetPoint("LEFT", headerFrame, "LEFT", x, 0)
        fs:SetWidth(h.width)
        fs:SetJustifyH("LEFT")
        fs:SetText(h.text)
        x = x + h.width + 5
    end

    ----------------------------------------------------------------
    -- SCROLLING TABLE
    ----------------------------------------------------------------
    local scroll = CreateFrame("ScrollFrame", nil, mlPanel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", mlPanel, "TOPLEFT", 60, -60)
    scroll:SetPoint("BOTTOMRIGHT", mlPanel, "BOTTOMRIGHT", -45, 40)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(1, 1)
    scroll:SetScrollChild(content)
	
	------------------------------------------------------------
	-- FIX: Prevent ScrollFrame from blocking window dragging
	------------------------------------------------------------
	scroll:EnableMouse(false)
	content:EnableMouse(false)

	-- Disable mouse on scrollbar + buttons if they exist
	local sb = scroll.ScrollBar
	if sb then
		sb:EnableMouse(false)
		if sb.ScrollUpButton then sb.ScrollUpButton:EnableMouse(false) end
		if sb.ScrollDownButton then sb.ScrollDownButton:EnableMouse(false) end
	end

	-- Some UIPanelScrollFrameTemplates include a background texture
	if scroll.Background then
		scroll.Background:EnableMouse(false)
	end

local COL_NAME     = 1
local COL_MAIN_MS  = 2
local COL_MAIN_OS  = 3
local COL_NOTES    = 4

local ROW_HEIGHT = 18
mlRows = {}

----------------------------------------------------------------
-- INLINE EDIT FOR NOTES
----------------------------------------------------------------
inlineEditML = CreateFrame("EditBox", nil, content, "InputBoxTemplate")
inlineEditML:SetAutoFocus(false)
inlineEditML:SetSize(200, 18)
inlineEditML:Hide()
inlineEditML.cancelled = false
inlineEditML:SetFrameStrata("HIGH")

inlineEditML:SetScript("OnEscapePressed", function(self)
    self.cancelled = true
    self:Hide()
end)

inlineEditML:SetScript("OnEnterPressed", function(self)
    self.cancelled = false
    if self.saveFunc then self.saveFunc(self:GetText()) end
    self:Hide()
end)

inlineEditML:SetScript("OnEditFocusLost", function(self)
    -- Do NOT save again if Enter already handled it
    if not self.cancelled and self.saveFunc and self:IsVisible() then
        self.saveFunc(self:GetText())
    end
    self:Hide()
end)

inlineEditML:SetScript("OnHide", function(self)
    if self.currentFS then
        self.currentFS:Show()
        self.currentFS = nil
    end
end)

function CreateMLRow(i)
    local row = CreateFrame("Frame", nil, content)
    row:SetSize(1, ROW_HEIGHT)
    row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)

    row.cols = {}

local widths = {
    [COL_NAME]     = 140,
    [COL_MAIN_MS]  = 150,
    [COL_MAIN_OS]  = 150,
    [COL_NOTES]    = 200,
}

    local x = 0
    for col = COL_NAME, COL_NOTES do
        if col == COL_NAME then
            local fs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            fs:SetPoint("LEFT", row, "LEFT", x, 0)
            fs:SetWidth(widths[col])
            fs:SetJustifyH("LEFT")
            row.cols[col] = fs

        elseif col == COL_MAIN_MS or col == COL_MAIN_OS then
            local btn = CreateFrame("Button", nil, row)
            btn:SetPoint("LEFT", row, "LEFT", x, 0)
            btn:SetSize(widths[col], ROW_HEIGHT)

            local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            fs:ClearAllPoints()
			fs:SetPoint("LEFT", btn, "LEFT", 2, 0)
			fs:SetWidth(widths[col] - 4)
			fs:SetJustifyH("LEFT")
			btn:SetFontString(fs)

            btn:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
			local hl = btn:GetHighlightTexture()
			hl:ClearAllPoints()
			hl:SetPoint("LEFT", btn, "LEFT", 0, 0)
			hl:SetPoint("RIGHT", btn, "LEFT", widths[col], 0)
			hl:SetAlpha(0.3)

            row.cols[col] = btn

        elseif col == COL_NOTES then
            local btn = CreateFrame("Button", nil, row)
            btn:SetPoint("LEFT", row, "LEFT", x, 0)
            btn:SetSize(widths[col], ROW_HEIGHT)

            local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            fs:ClearAllPoints()
			fs:SetPoint("LEFT", btn, "LEFT", 2, 0)
			fs:SetWidth(widths[col] - 4)
			fs:SetJustifyH("LEFT")
			btn:SetFontString(fs)

            btn:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
			local hl = btn:GetHighlightTexture()
			hl:ClearAllPoints()
			hl:SetPoint("LEFT", btn, "LEFT", 0, 0)
			hl:SetPoint("RIGHT", btn, "LEFT", widths[col], 0)
			hl:SetAlpha(0.3)

            row.cols[col] = btn
        end

        x = x + widths[col] + 5
    end

    return row
end

    ----------------------------------------------------------------
    -- REFRESH FUNCTION
    ----------------------------------------------------------------

local function CommitInlineML()
    if not inlineEditML then return end
    if not inlineEditML:IsShown() then return end
    if inlineEditML.cancelled then return end
    if not inlineEditML.saveFunc then return end

    local text = inlineEditML:GetText() or ""
    inlineEditML.saveFunc(text)
    inlineEditML:Hide()
end

function RefreshMLTools()
    if not mlRows then return end
	
	-- Ensure ML data exists for all DKP players
	for name in pairs(RedGuild_Data or {}) do
		EnsureML(name)
	end

    ----------------------------------------------------------------
    -- BUILD SORTED LIST OF ML NAMES
    ----------------------------------------------------------------
local CLASS_COLORS = {}
for class, c in pairs(RAID_CLASS_COLORS) do
    CLASS_COLORS[class] = string.format("|cff%02x%02x%02x", c.r * 255, c.g * 255, c.b * 255)
end

local names = {}
for name in pairs(RedGuild_ML or {}) do
    if type(name) == "string" then
        table.insert(names, name)
    end
end

table.sort(names)

local filtered = {}
for _, name in ipairs(names) do
    if IsNameInGuild(name) then

        -- class colour
        local class = RedGuild_Data[name] and RedGuild_Data[name].class
        local colour = CLASS_COLORS[class] or "|cffaaaaaa"

                -- main/alt tag (white)
        local tag = ""
        if IsMain(name) then
            tag = " |cffffffff(main)|r"
        elseif IsAlt(name) then
            tag = " |cffffffff(alt)|r"
		else
			tag = " |cffffffff(unknown)|r"
        end

        -- final display string (FLAT STRING)
        local display = colour .. name .. "|r" .. tag

        table.insert(filtered, display)
    end
end

	names = filtered

----------------------------------------------------------------
-- GROUP FILTER
----------------------------------------------------------------
if mlShowGroupOnly then
    local filtered = {}

    for _, name in ipairs(names) do
        local inGroup = false

        if IsInRaid() then
            for i = 1, GetNumGroupMembers() do
                local rName = UnitName("raid"..i)
                if rName and Ambiguate(rName, "short") == name then
                    inGroup = true
                    break
                end
            end

        elseif IsInGroup() then
            for i = 1, GetNumSubgroupMembers() do
                local pName = UnitName("party"..i)
                if pName and Ambiguate(pName, "short") == name then
                    inGroup = true
                    break
                end
            end

            -- include yourself
            if Ambiguate(UnitName("player"), "short") == name then
                inGroup = true
            end

        else
            -- solo: only show yourself
            if Ambiguate(UnitName("player"), "short") == name then
                inGroup = true
            end
        end

        if inGroup then
            table.insert(filtered, name)
        end
    end

    ----------------------------------------------------------------
    -- 2. ADD missing group/raid members not already in the DKP list
    ----------------------------------------------------------------
    local function addIfMissing(unit)
        local uName = UnitName(unit)
        if uName then
            uName = Ambiguate(uName, "short")
            local found = false

            for _, existing in ipairs(filtered) do
                if existing == uName then
                    found = true
                    break
                end
            end

            if not found then
                table.insert(filtered, uName)
				EnsureML(uName)
            end
        end
    end

    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            addIfMissing("raid"..i)
        end
    elseif IsInGroup() then
        for i = 1, GetNumSubgroupMembers() do
            addIfMissing("party"..i)
        end
        addIfMissing("player")
    else
        addIfMissing("player")
    end

    names = filtered
end

    ----------------------------------------------------------------
    -- ENSURE ROW POOL MATCHES DATA SIZE
    ----------------------------------------------------------------
    local needed = #names
    local current = #mlRows

    if needed > current then
        for i = current + 1, needed do
            if CreateMLRow then
                mlRows[i] = CreateMLRow(i)
            end
        end
    end

----------------------------------------------------------------
-- RENDER ROWS (CLEAN, NO FILTERING HERE)
----------------------------------------------------------------
local visibleCount = #names  -- this MUST already be filtered list

for i = 1, visibleCount do
    local name = names[i]
    local d = RedGuild_Data[name]

    local row = mlRows[i]
    if not row then break end

    row.name = name

    local mlData = EnsureML(name)

    ------------------------------------------------------------
    -- COLUMN REFERENCES
    ------------------------------------------------------------
local nameFS = row.cols[COL_NAME]
local mainMSBtn = row.cols[COL_MAIN_MS]
local mainOSBtn = row.cols[COL_MAIN_OS]
local notesBtn  = row.cols[COL_NOTES]

    ------------------------------------------------------------
    -- NAME (CLASS COLOUR)
    ------------------------------------------------------------
    local class = d and d.class
    local color = class and RAID_CLASS_COLORS[class]
    local hex = "|cffffffff"

    if color then
        hex = string.format("|cff%02x%02x%02x",
            color.r * 255,
            color.g * 255,
            color.b * 255
        )
    end

    nameFS:SetText(hex .. name .. "|r")

    ------------------------------------------------------------
    -- VALUES
    ------------------------------------------------------------
mainMSBtn:SetText(tostring(mlData.mlMainMS or 0))
mainOSBtn:SetText(tostring(mlData.mlMainOS or 0))
    notesBtn:SetText(mlData.mlNotes or "")

    ------------------------------------------------------------
    -- CLICK HANDLERS (unchanged logic, just safer name usage)
    ------------------------------------------------------------
local function makeMLHandler(field)
    return function(self, button)
        local thisName = self:GetParent().name
        if not thisName then return end

        local ml = EnsureML(thisName)
        local old = tonumber(ml[field] or 0) or 0

        if button == "LeftButton" then
            ml[field] = old + 1
        elseif button == "RightButton" then
            ml[field] = math.max(0, old - 1)
        end

        RefreshMLTools()
    end
end

mainMSBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
mainOSBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

mainMSBtn:SetScript("OnClick", makeMLHandler("mlMainMS"))
mainOSBtn:SetScript("OnClick", makeMLHandler("mlMainOS"))

    ------------------------------------------------------------
    -- NOTES EDIT
    ------------------------------------------------------------
    notesBtn:SetScript("OnMouseDown", function(self, button)
        if button ~= "LeftButton" then return end

        CommitInlineML()

        local thisName = self:GetParent().name
        if not thisName then return end

        local ml = EnsureML(thisName)
        local fs = self:GetFontString()
        if not fs then return end

        fs:Hide()

        inlineEditML:ClearAllPoints()
        inlineEditML:SetPoint("LEFT", self, "LEFT", 0, 0)
        inlineEditML:SetWidth(self:GetWidth() - 4)
        inlineEditML:SetText(ml.mlNotes or "")
        inlineEditML:HighlightText()
        C_Timer.After(0, function()
			inlineEditML:SetFocus()
		end)
		inlineEditML:SetCursorPosition(strlen(inlineEditML:GetText()))

        inlineEditML.currentFS = fs
        inlineEditML.cancelled = false

        inlineEditML.saveFunc = function(text)
            ml.mlNotes = text or ""
            fs:SetText(ml.mlNotes)
            fs:Show()
            inlineEditML.currentFS = nil
        end

        inlineEditML:Show()
    end)

    row:Show()
end

----------------------------------------------------------------
-- HIDE UNUSED ROWS
----------------------------------------------------------------
for i = visibleCount + 1, #mlRows do
    local row = mlRows[i]
    if row then
        row.name = nil
        row:Hide()
    end
end
end

    ----------------------------------------------------------------
    -- BOTTOM WARNING
    ----------------------------------------------------------------
    local note = mlPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    note:SetPoint("BOTTOMLEFT", mlPanel, "BOTTOMLEFT", 20, 10)
    note:SetJustifyH("LEFT")
    note:SetText("|cffaaaaaaBroadcast (to raid) button only works if you are a RL or RA.|r")

    ----------------------------------------------------------------
    -- BROADCAST DKP BUTTON
    ----------------------------------------------------------------
    local broadcastBtn = CreateFrame("Button", nil, mlPanel, "UIPanelButtonTemplate")
    broadcastBtn:SetSize(140, 24)
    broadcastBtn:SetText("Broadcast DKP")
    broadcastBtn:SetPoint("BOTTOMRIGHT", mlPanel, "BOTTOMRIGHT", -10, 10)
    mlPanel.broadcastBtn = broadcastBtn

    broadcastBtn:SetScript("OnClick", function()
        if not IsRaidLeaderOrMasterLooter() then
            print("|cffff0000You must be the Raid leader or Assistant to broadcast DKP (to the raid group).|r")
            return
        end
        StaticPopup_Show("REDGUILD_BROADCAST_DKP")
    end)

----------------------------------------------------------------
-- RESET ML VALUES BUTTON
----------------------------------------------------------------
local resetBtn = CreateFrame("Button", nil, mlPanel, "UIPanelButtonTemplate")
resetBtn:SetSize(100, 24)
resetBtn:SetText("Reset")
resetBtn:SetPoint("RIGHT", mlPanel.broadcastBtn, "LEFT", -10, 0)

resetBtn:SetScript("OnClick", function()
    for name, d in pairs(RedGuild_Data or {}) do
        if d and IsNameInGuild(name) then
            local ml = EnsureML(name)

            local oldMainMS  = tonumber(ml.mlMainMS or 0) or 0
			local oldMainOS   = tonumber(ml.mlMainOS or 0) or 0
            local oldNotes = ml.mlNotes or ""

            if oldMainMS ~= 0 then
                ml.mlMainMS = 0
            end
			
            if oldMainOS ~= 0 then
                ml.mlMainOS = 0
            end

            if oldNotes ~= "" then
                ml.mlNotes = ""
                LogAudit(name, "mlNotes", oldNotes, "")
            end
        end
    end

    RefreshMLTools()
    print("|cff00ff00ML values reset for all players.|r")
end)

----------------------------------------------------------------
-- COUNTDOWN STATE
----------------------------------------------------------------
local mlCountdownPaused = false
local mlCountdownActive = false
local mlCountdownTimer = nil
local mlCountdownIndex = 0

---------------------------------------------------------------
-- COUNTDOWN BUTTON
----------------------------------------------------------------
local countdownBtn = CreateFrame("Button", nil, mlPanel, "UIPanelButtonTemplate")
countdownBtn:SetSize(100, 24)
countdownBtn:SetText("Countdown")

countdownBtn:SetPoint("TOPRIGHT", mlPanel, "TOPRIGHT", -10, -30)

----------------------------------------------------------------
-- PAUSE BUTTON
----------------------------------------------------------------
local pauseBtn = CreateFrame("Button", nil, mlPanel, "UIPanelButtonTemplate")
pauseBtn:SetSize(100, 24)
pauseBtn:SetText("Pause Count")

-- Anchor to the left of Countdown
pauseBtn:SetPoint("RIGHT", countdownBtn, "LEFT", -5, 0)


----------------------------------------------------------------
-- COUNTDOWN LOGIC
----------------------------------------------------------------

countdownBtn:SetScript("OnClick", function()
    if not IsInRaid() then
        print("|cffff0000Countdown can only be used while in a raid.|r")
        return
    end
	
	if mlCountdownActive then
        print("|cffff0000Countdown already running.|r")
        return
    end

    mlCountdownActive = true
    mlCountdownPaused = false
	mlCountdownIndex = 0
    pauseBtn:SetText("Pause")

    local a, c = C_Timer.After, SendChatMessage
	local delay = 1
	
    mlCountdownTimer = C_Timer.NewTicker(1, function()
            
            if mlCountdownPaused then
                return
            end

            local remaining = 5 - mlCountdownIndex
			
            if remaining > 0 then
				SendChatMessage(remaining, "RAID_WARNING")
			else
				SendChatMessage("\\o/ SOLD \\o/", "RAID_WARNING")
            mlCountdownActive = false
            mlCountdownTimer:Cancel()
            mlCountdownTimer = nil
			return
        end

        mlCountdownIndex = mlCountdownIndex + 1
    end, 666) -- 6 ticks: 5,4,3,2,1,SOLD
end)

----------------------------------------------------------------
-- PAUSE LOGIC
----------------------------------------------------------------

pauseBtn:SetScript("OnClick", function()
    if not mlCountdownActive then
        print("|cffff0000No countdown is running.|r")
        return
    end

    mlCountdownPaused = not mlCountdownPaused

    if mlCountdownPaused then
        pauseBtn:SetText("Resume")
        print("|cffffff00Countdown paused.|r")
    else
        pauseBtn:SetText("Pause")
        print("|cff00ff00Countdown resumed.|r")
    end
end)

----------------------------------------------------------------
-- SHOW GROUP/RAID ONLY CHECKBOX
----------------------------------------------------------------
local showGroupChk = CreateFrame("CheckButton", nil, mlPanel, "ChatConfigCheckButtonTemplate")

-- Anchor it directly to the LEFT of the Reset button
showGroupChk:SetPoint("RIGHT", resetBtn, "LEFT", -160, 0)
showGroupChk:SetSize(24, 24)
showGroupChk.tooltip = "Show only players currently in your group or raid."

local chkLabel = mlPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
chkLabel:SetPoint("LEFT", showGroupChk, "RIGHT", 2, 0)
chkLabel:SetText("Show group/raid players only")

showGroupChk:SetScript("OnClick", function(self)
    mlShowGroupOnly = self:GetChecked() or false
    RefreshMLTools()
end)

----------------------------------------------------------------
-- PANEL SHOW
----------------------------------------------------------------
mlPanel:SetScript("OnShow", function()
    RefreshMLTools()
end)

----------------------------------------------------------------
-- PANEL HIDE
----------------------------------------------------------------
mlPanel:SetScript("OnHide", function()
    if inlineEditML and inlineEditML:IsShown() then
        inlineEditML.cancelled = true
        inlineEditML:Hide()
    end
end)
end

--------------------------------------------------------------------
-- RL TOOLS PANEL
--------------------------------------------------------------------
RLRows = RLRows or {}
RLSelected = RLSelected or {}
   do
local RLSelectGroupMembers
------------------------------------------------------------
-- RL: SELECT GROUP/RAID MEMBERS CHECKBOX
------------------------------------------------------------
local rlAutoSelectChk = CreateFrame("CheckButton", nil, raidPanel, "ChatConfigCheckButtonTemplate")
rlAutoSelectChk:SetPoint("TOPLEFT", raidPanel, "TOPLEFT", 80, -40)
rlAutoSelectChk:SetSize(18, 18)

local rlAutoSelectLabel = raidPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
rlAutoSelectLabel:SetPoint("LEFT", rlAutoSelectChk, "RIGHT", 4, 0)
rlAutoSelectLabel:SetText("Select group/raid members (10 second refresh)")

rlAutoSelectChk:SetHitRectInsets(4, 4, 4, 4)

rlAutoSelectChk:SetScript("OnClick", function(self)
    if self:GetChecked() then
        -- Turned ON: immediately apply auto-select to current group/raid
        RLSelectGroupMembers()
    else
        -- Turned OFF: ask if we should clear all ticks
        StaticPopup_Show("REDGUILD_CLEAR_RL_TICKS")
    end
end)
	
	----------------------------------------------------------------
-- RL TOOLS: TICKBOX LIST (LEFT HALF)
----------------------------------------------------------------
RLSelected = RLSelected or {}

local rlScroll = CreateFrame("ScrollFrame", nil, raidPanel, "UIPanelScrollFrameTemplate")
rlScroll:SetPoint("TOPLEFT", raidPanel, "TOPLEFT", 50, -60)
rlScroll:SetPoint("BOTTOMLEFT", raidPanel, "BOTTOMLEFT", 30, 30)
rlScroll:SetWidth(raidPanel:GetWidth() * 0.40)

local rlContent = CreateFrame("Frame", nil, rlScroll)
rlContent:SetSize(1, 1)
rlScroll:SetScrollChild(rlContent)

local RL_ROW_HEIGHT = 20
RLRows = {}

------------------------------------------------------------
-- RL: AUTO-SELECT FUNCTION
------------------------------------------------------------
	RLSelectGroupMembers = function()
    if not rlAutoSelectChk:GetChecked() then
        return
    end

    local groupMembers = {}

    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            local name = UnitName("raid"..i)
            if name then
                groupMembers[Ambiguate(name, "short")] = true
            end
        end
    elseif IsInGroup() then
        for i = 1, GetNumSubgroupMembers() do
            local name = UnitName("party"..i)
            if name then
                groupMembers[Ambiguate(name, "short")] = true
            end
        end
        groupMembers[Ambiguate(UnitName("player"), "short")] = true
    end

    for _, row in ipairs(RLRows) do
        if row:IsShown() and groupMembers[row.name] then
            row.checkbox:SetChecked(true)
            RLSelected[row.name] = true
        end
    end
end

----------------------------------------------------------------
-- RL ROW CREATION
----------------------------------------------------------------
local function CreateRLRow(i)
    local row = CreateFrame("Frame", nil, rlContent)
    row:SetSize(300, RL_ROW_HEIGHT)
    row:SetPoint("TOPLEFT", 10, -(i - 1) * RL_ROW_HEIGHT)

    local cb = CreateFrame("CheckButton", nil, row, "ChatConfigCheckButtonTemplate")
    cb:SetPoint("LEFT", 0, 0)
    cb:SetSize(20, 20)
    row.checkbox = cb

    local fs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetPoint("LEFT", cb, "RIGHT", 5, 0)
    row.nameFS = fs

    cb:SetScript("OnClick", function(self)
        if row.name then
            RLSelected[row.name] = self:GetChecked() or false
        end
    end)

    return row
end

----------------------------------------------------------------
-- RL LIST REFRESH
----------------------------------------------------------------
local function RefreshRLList()
    for _, row in ipairs(RLRows) do
        row:Hide()
    end
    wipe(RLRows)

local names = {}
local nameMap = {}

-- 1. Add all ML entries
for name in pairs(RedGuild_ML or {}) do
    names[#names+1] = name
    nameMap[name] = true
end

-- 2. If group-only mode is active, add group/raid members even if missing from ML
if mlShowGroupOnly then
    local function AddIfMissing(unit)
        local raw = UnitName(unit)
        if raw then
            local short = Ambiguate(raw, "short")
            if not nameMap[short] then
                names[#names+1] = short
                nameMap[short] = true
            end
        end
    end

    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            AddIfMissing("raid"..i)
        end
    elseif IsInGroup() then
        for i = 1, GetNumSubgroupMembers() do
            AddIfMissing("party"..i)
        end
        AddIfMissing("player")
    else
        -- solo: include yourself
        AddIfMissing("player")
    end
end

table.sort(names)

    local i = 0
    for _, name in ipairs(names) do
        local d = RedGuild_Data[name]
        if d then
            i = i + 1
            local row = RLRows[i]

            if not row then
                row = CreateRLRow(i)
                RLRows[i] = row
            end

            row.name = name

            local class = d.class
            local c = RAID_CLASS_COLORS[class]
            local hex = "|cffffffff"
            if c then
                hex = string.format("|cff%02x%02x%02x", c.r*255, c.g*255, c.b*255)
            end

            row.nameFS:SetText(hex .. name .. "|r")
            row.checkbox:SetChecked(RLSelected[name] or false)

            row:Show()
        end
    end

    rlContent:SetHeight(i * RL_ROW_HEIGHT)
	RLSelectGroupMembers()
end

------------------------------------------------------------
-- RL: 10-SECOND AUTO-SELECT SCAN
------------------------------------------------------------
local rlTicker = nil

local function StartRLAutoScan()
    if not rlTicker then
        rlTicker = C_Timer.NewTicker(10, function()
            RefreshRLList()
        end)
    end
end

local function StopRLAutoScan()
    if rlTicker then
        rlTicker:Cancel()
        rlTicker = nil
    end
end

----------------------------------------------------------------
-- RL PANEL SHOW/HIDE
----------------------------------------------------------------
raidPanel:SetScript("OnShow", function()
    RefreshRLList()
    StartRLAutoScan()
end)

raidPanel:SetScript("OnHide", function()
    StopRLAutoScan()
end)
	
    local onTimeBtn = CreateFrame("Button", nil, raidPanel, "UIPanelButtonTemplate")
    onTimeBtn:SetSize(200, 30)
    onTimeBtn:SetPoint("TOPRIGHT", raidPanel, "TOPRIGHT", -100, -60)
    onTimeBtn:SetText("Allocate On Time DKP")
onTimeBtn:SetScript("OnClick", function()
    if not IsAuthorized() then
        Print("Only an editor can perform this function.")
        return
    end

    if not RLTools_HasSelections() then
        Print("|cffff0000RedGuild:|r No players selected in RL Tools.")
        return
    end

    local missing = GetMissingDKPGroupMembers()
	if #missing > 0 then
		local list = table.concat(missing, ", ")
		StaticPopup_Show("REDGUILD_MISSING_DKP_WARNING", list, nil, "REDGUILD_ON_TIME_CHECK")
	else
		StaticPopup_Show("REDGUILD_ON_TIME_CHECK")
	end
	end)

    local attendanceBtn = CreateFrame("Button", nil, raidPanel, "UIPanelButtonTemplate")
    attendanceBtn:SetSize(200, 30)
    attendanceBtn:SetPoint("TOP", onTimeBtn, "BOTTOM", 0, -20)
    attendanceBtn:SetText("Allocate Attendance DKP")
	attendanceBtn:SetScript("OnClick", function()
    if not IsAuthorized() then
        Print("Only an editor can perform this function.")
        return
    end

    if not RLTools_HasSelections() then
        Print("|cffff0000RedGuild:|r No players selected in RL Tools.")
        return
    end

	local missing = GetMissingDKPGroupMembers()
	if #missing > 0 then
		local list = table.concat(missing, ", ")
		StaticPopup_Show("REDGUILD_MISSING_DKP_WARNING", list, nil, "REDGUILD_ALLOCATE_ATTENDANCE")
	else
		StaticPopup_Show("REDGUILD_ALLOCATE_ATTENDANCE")
	end
	end)

    local benchBtn = CreateFrame("Button", nil, raidPanel, "UIPanelButtonTemplate")
    benchBtn:SetSize(200, 30)
    benchBtn:SetPoint("TOP", attendanceBtn, "BOTTOM", 0, -20)
    benchBtn:SetText("Allocate Bench")
benchBtn:SetScript("OnClick", function()
    if not IsAuthorized() then
        Print("Only an editor can perform this function.")
        return
    end

    if not RLTools_HasSelections() then
        Print("|cffff0000RedGuild:|r No players selected in RL Tools.")
        return
    end

    StaticPopup_Show("REDGUILD_ALLOCATE_BENCH")
end)

    local newWeekBtn = CreateFrame("Button", nil, raidPanel, "UIPanelButtonTemplate")
    newWeekBtn:SetSize(200, 30)
    newWeekBtn:SetPoint("BOTTOMRIGHT", raidPanel, "BOTTOMRIGHT", -100, 20)
    newWeekBtn:SetText("Start New DKP Session")
    newWeekBtn:SetScript("OnClick", function()
        if not IsAuthorized() then
            Print("Only editors can start a new DKP session.")
            return
        end
        StaticPopup_Show("REDGUILD_NEW_WEEK")
    end)
end

    --------------------------------------------------------------------
    -- EDITORS PANEL
    --------------------------------------------------------------------
	local versionLabel
	local addonOnlineFS
    do
        local title = editorsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", 10, -10)
        title:SetText("")

        local editorScroll = CreateFrame("ScrollFrame", nil, editorsPanel, "UIPanelScrollFrameTemplate")
        editorScroll:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 70, -30)
        editorScroll:SetPoint("BOTTOMLEFT", editorsPanel, "BOTTOMLEFT", 0, 30)
        editorScroll:SetWidth(200)

        local editorContent = CreateFrame("Frame", nil, editorScroll)
        editorContent:SetWidth(200)
        editorScroll:SetScrollChild(editorContent)

        local EDITOR_ROW_HEIGHT = 18
        local MAX_EDITOR_ROWS = 20

        editorRows = {}

        for i = 1, MAX_EDITOR_ROWS do
    local row = CreateFrame("Button", nil, editorContent)
    row:SetSize(200, EDITOR_ROW_HEIGHT)
    row:SetPoint("TOPLEFT", 0, -(i - 1) * EDITOR_ROW_HEIGHT)

    -- Highlight texture
    local hl = row:CreateTexture(nil, "BACKGROUND")
    hl:SetAllPoints()
    hl:SetColorTexture(0.2, 0.4, 1, 0.3)
    hl:Hide()
    row.highlight = hl

    -- Text label
    local fs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetPoint("LEFT", 2, 0)
    fs:SetJustifyH("LEFT")
    row.text = fs

    -- Click handler
    row:SetScript("OnClick", function(self)
        editorsPanel.selectedEditor = self.name

        -- Clear all highlights
        for _, r in ipairs(editorRows) do
            if r.highlight then
                r.highlight:Hide()
            end
        end

        -- Highlight this row if it has a name
        if self.name then
            self.highlight:Show()
        end
    end)

    -- Store row
    editorRows[i] = row
end

        editorContent:SetHeight(MAX_EDITOR_ROWS * EDITOR_ROW_HEIGHT)

        local addBox = CreateFrame("EditBox", nil, editorsPanel, "InputBoxTemplate")
        addBox:SetSize(140, 20)
        addBox:SetPoint("TOPLEFT", editorScroll, "TOPRIGHT", 90, 0)
        addBox:SetAutoFocus(false)

        local addBtn = CreateFrame("Button", nil, editorsPanel, "UIPanelButtonTemplate")
        addBtn:SetSize(80, 22)
        addBtn:SetText("Add")
        addBtn:SetPoint("LEFT", addBox, "RIGHT", 10, 0)

        local removeBtn = CreateFrame("Button", nil, editorsPanel, "UIPanelButtonTemplate")
        removeBtn:SetSize(80, 22)
        removeBtn:SetText("Remove")
        removeBtn:SetPoint("TOPLEFT", addBtn, "BOTTOMLEFT", 0, -8)

        local removeNote = editorsPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        removeNote:SetPoint("TOPLEFT", removeBtn, "BOTTOMLEFT", 0, -4)
        removeNote:SetText("|cffaaaaaa* select name and click to remove|r")

        editorsPanel.selectedEditor = nil

addBtn:SetScript("OnClick", function()
    if not (IsGuildOfficer() or IsEditor(UnitName("player"))) then
        Print("Only guild leader or editors can add to the editor list.")
        return
    end

    local raw = addBox:GetText()
    if not raw or raw == "" then
        Print("|cffff0000RedGuild:|r No name entered.")
        return
    end

    local short = Ambiguate(raw, "short")
    local ok, proper = IsNameInGuild(short)
    if not ok then
        Print("|cffff0000RedGuild:|r Cannot add editor — player is not in your guild.")
        return
    end

    short = proper
    local key = NormalizeName(short)

    EnsureSaved()

    if RedGuild_Config.authorizedEditors[key] then
        Print("|cffffff00RedGuild:|r " .. short .. " is already an editor.")
        return
    end

    RedGuild_Config.authorizedEditors[key] = true
    RedGuild_Config.editorListVersion = (RedGuild_Config.editorListVersion or 0) + 1

    addBox:SetText("")
	UpdateTable()
	RefreshMLTools()
    RefreshEditorList()

    -- Broadcast to all addon users
    local me = NormalizeName(UnitName("player"))
    for name in pairs(RedGuild_Config.addonUsers) do
        if name ~= me and IsPlayerOnline(name) then
            BroadcastEditorListTo(name)
        end
    end
end)

        removeBtn:SetScript("OnClick", function()
            if not IsGuildOfficer() then
                Print("Only guild leader can remove from the editor list.")
                return
            end

            local selected = editorsPanel.selectedEditor
            if not selected or selected == "" then
                Print("|cffff0000RedGuild:|r No editor selected.")
                return
            end

            local key = NormalizeName(selected)
            if not key then
                Print("|cffff0000RedGuild:|r Invalid selected name.")
                return
            end

            EnsureSaved()

            -- Protected editor (guild leader) cannot be removed
            local protected = RedGuild_Config.protectedEditor
            if protected and key == protected then
                Print("|cffff0000RedGuild:|r You cannot remove the protected editor (guild leader).")
                return
            end

            if not RedGuild_Config.authorizedEditors[key] then
                Print("|cffff0000RedGuild:|r That name is not in the editor list.")
                return
            end

            RedGuild_Config.authorizedEditors[key] = nil
            RedGuild_Config.editorListVersion = (RedGuild_Config.editorListVersion or 0) + 1

            editorsPanel.selectedEditor = nil
            RefreshEditorList()

            -- Broadcast updated editor list to all known addon users
            EnsureConfig()
            local me = NormalizeName(UnitName("player"))
            for name in pairs(RedGuild_Config.addonUsers) do
                if name ~= me and IsPlayerOnline(name) then
                    BroadcastEditorListTo(name)
                end
            end
        end)

        editorsPanel:SetScript("OnShow", function()
            C_Timer.After(0.05, RefreshEditorList)
            dkpPanel:SetScript("OnShow", UpdateTable)
			local canEditEditors = IsGuildOfficer() or IsEditor(UnitName("player"))

    if not canEditEditors then
        addBox:Hide()
        addBtn:Hide()
        removeBtn:Hide()
        removeNote:Hide()
    else
        addBox:Show()
        addBtn:Show()
        removeBtn:Show()
        removeNote:Show()
    end	
			
        end)

----------------------------------------------------------------
-- DKP VERSION EDIT BOX
----------------------------------------------------------------
versionLabel = editorsPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
versionLabel:SetPoint("BOTTOMRIGHT", editorsPanel, "BOTTOMRIGHT", -100, 20)
versionLabel:SetText("Your DKP Table Version:")

local versionEdit = CreateFrame("EditBox", nil, editorsPanel, "InputBoxTemplate")
versionEdit:SetAutoFocus(false)
versionEdit:SetSize(60, 20)
versionEdit:SetPoint("LEFT", versionLabel, "RIGHT", 10, 0)

-- Load current version when panel is shown
editorsPanel:HookScript("OnShow", function()
    local online = CountOnlineAddonUsers()
    versionEdit:SetText(tostring(RedGuild_Config.dkpVersion or 0))
end)

-- Save on Enter
versionEdit:SetScript("OnEnterPressed", function(self)
    local newVal = tonumber(self:GetText())
    if newVal then
        RedGuild_Config.dkpVersion = newVal
		local me = NormalizeName(UnitName("player"))
		RedGuild_Config.EditorVersions[me] = newVal
        Print("|cff00ff00DKP version updated to " .. newVal .. ".|r")
        UpdateTable()
    else
        Print("|cffff5555Invalid version number.|r")
    end
    self:ClearFocus()
end)

-- Save on focus lost
versionEdit:SetScript("OnEditFocusLost", function(self)
    local newVal = tonumber(self:GetText())
    if newVal then
        RedGuild_Config.dkpVersion = newVal
		local me = NormalizeName(UnitName("player"))
		RedGuild_Config.EditorVersions[me] = newVal
        UpdateTable()
    end
end)

        local note = editorsPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        note:SetPoint("BOTTOMLEFT", editorsPanel, "BOTTOMLEFT", 10, 10)
        note:SetJustifyH("LEFT")
        note:SetText("|cffaaaaaa* Guild leaders are editors by default.|r")
    end

----------------------------------------------------------------
-- REVERT DKP BACKUP BUTTON (Editors only)
----------------------------------------------------------------
local revertBtn = CreateFrame("Button", nil, editorsPanel, "UIPanelButtonTemplate")
revertBtn:SetSize(140, 22)
revertBtn:SetText("Revert DKP Backup")
revertBtn:SetPoint("BOTTOMRIGHT", editorsPanel, "BOTTOMRIGHT", -20, 50)

revertBtn:SetScript("OnClick", function()
    if not RedGuild_BackupData or not RedGuild_BackupData.data then
        Print("|cffff5555No DKP backup available.|r")
        return
    end

    StaticPopup_Show("REDGUILD_RESTORE_DKP_CONFIRM")
end)

-- Only show button to editors
editorsPanel:HookScript("OnShow", function()
    local canEditEditors = IsGuildOfficer() or IsEditor(UnitName("player"))
    if canEditEditors then
        revertBtn:Show()
    else
        revertBtn:Hide()
    end
end)

------------------------------------------------------------
-- HIDE ME FROM SYNC CHECKBOX
------------------------------------------------------------
local hideSyncChk = CreateFrame("CheckButton", nil, editorsPanel, "ChatConfigCheckButtonTemplate")
hideSyncChk:SetSize(18, 18)
hideSyncChk:ClearAllPoints()
hideSyncChk:SetPoint("RIGHT", versionLabel, "LEFT", -200, 0)


local hideSyncLabel = editorsPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
hideSyncLabel:SetPoint("LEFT", hideSyncChk, "RIGHT", 4, 0)
hideSyncLabel:SetText("Hide me from SYNC")

hideSyncChk:SetHitRectInsets(4, 4, 4, 4)

-- Load saved state
C_Timer.After(0.05, function()
    hideSyncChk:SetChecked(RedGuild_Config.hideMeFromSync)
end)

-- Save state when clicked
hideSyncChk:SetScript("OnClick", function(self)
    RedGuild_Config.hideMeFromSync = self:GetChecked() and true or false
end)


    --------------------------------------------------------------------
    -- AUDIT PANEL
    --------------------------------------------------------------------
    do
        local auditScroll = CreateFrame("ScrollFrame", nil, auditPanel, "UIPanelScrollFrameTemplate")
        auditScroll:SetPoint("TOPLEFT", -40, -40)
        auditScroll:SetPoint("BOTTOMRIGHT", -40, 25)

        local auditContent = CreateFrame("Frame", nil, auditScroll)
        auditContent:SetSize(1, 1)
        auditScroll:SetScrollChild(auditContent)

        local MAX_AUDIT_ROWS = 666
        local AUDIT_ROW_HEIGHT = 18

        auditRows = {}

        for i = 1, MAX_AUDIT_ROWS do
            local row = CreateFrame("Frame", nil, auditContent)
            row:SetSize(1, AUDIT_ROW_HEIGHT)
            row:SetPoint("TOPLEFT", 0, -(i - 1) * AUDIT_ROW_HEIGHT)

            local fs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            local offset = 50

            fs:SetPoint("LEFT", offset + 60, 0)
            fs:SetWidth(740 - offset)
            fs:SetJustifyH("LEFT")
            row.text = fs

            auditRows[i] = row
        end

        auditPanel:SetScript("OnShow", UpdateAuditLog)
    end

------------------------------------------------------------
-- ADDON VERSION FOOTER INFO LINE (small + grey)
------------------------------------------------------------
local dkpFooter = dkpPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
dkpFooter:SetPoint("BOTTOM", dkpPanel, "BOTTOM", 0, 10)

-- Make it half-size and grey
dkpFooter:SetFont(dkpFooter:GetFont(), 8)   -- default is 12, so 8 is ~half
dkpFooter:SetTextColor(0.7, 0.7, 0.7, 1)    -- light grey

dkpFooter:SetText("RedGuild v" .. REDGUILD_VERSION)
RedGuild_DKPFooter = dkpFooter

--------------------------------------------------------------------
-- DKP TABLE
--------------------------------------------------------------------
do
    syncWarning = dkpPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    syncWarning:SetPoint("BOTTOM", dkpPanel, "BOTTOM", 0, 40)
    syncWarning:SetTextColor(1, 0.2, 0.2)
    SafeSetSyncWarning("WARNING — Your DKP data may be outdated until an editor syncs.")

    local headerY = -55
    local x = 60
    dkpHeaderButtons = dkpHeaderButtons or {}

    for i, h in ipairs(headers) do
        local headerBtn = CreateFrame("Button", nil, dkpPanel)
        headerBtn:SetPoint("TOPLEFT", dkpPanel, "TOPLEFT", x, headerY)
        headerBtn:SetSize(h.width, 16)

        local fs = headerBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetAllPoints()
        fs:SetJustifyH("LEFT")
        fs:SetText(NORMAL_COLOR .. h.text .. "|r")
        headerBtn.text = fs

        headerBtn:SetScript("OnClick", function()
            local field = fieldMap[i]
            if not field 
                or field == "whisper"
                or field == "msRole"
                or field == "osRole"
            then 
                return 
            end

            if currentSortField == field then
                currentSortAscending = not currentSortAscending
            else
                currentSortField = field
                currentSortAscending = false
            end

            for j, hh in ipairs(headers) do
                local btn = dkpHeaderButtons[j]
                if j == i then
                    btn.text:SetText(SORT_COLOR .. hh.text .. "|r")
                else
                    btn.text:SetText(NORMAL_COLOR .. hh.text .. "|r")
                end
            end

            UpdateTable()
        end)

        dkpHeaderButtons[i] = headerBtn
        x = x + h.width + 5
    end

    if dkpHeaderButtons[1] then
        dkpHeaderButtons[1].text:SetText(SORT_COLOR .. headers[1].text .. "|r")
    end
	
----------------------------------------------------------------
-- DKP FILTER CHECKBOXES (top-left above table)
----------------------------------------------------------------
--if IsEditor(UnitName("player")) then

----------------------------------------------------------------
-- SHOW GROUP/RAID ONLY (still to the right of Show Only Me)
----------------------------------------------------------------
local showGroupChk = CreateFrame("CheckButton", nil, dkpPanel, "ChatConfigCheckButtonTemplate")
showGroupChk:SetPoint("TOPLEFT", dkpPanel, "TOPLEFT", 200, -30)
showGroupChk:SetSize(18, 18)

local showGroupLabel = dkpPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
showGroupLabel:SetPoint("LEFT", showGroupChk, "RIGHT", 4, 0)
showGroupLabel:SetText("Show group/raid players only")

-- Only editors see it
--if not IsEditor(UnitName("player")) then
--    showGroupChk:Hide()
--    showGroupLabel:Hide()
--end

showGroupChk:SetScript("OnClick", function(self)
    C_Timer.After(0, function()
        dkpShowGroupOnly = self:GetChecked()
        UpdateTable()
    end)
end)

--end

----------------------------------------------------------------
-- SHOW ONLY ME (all users)
----------------------------------------------------------------
local showMeChk = CreateFrame("CheckButton", nil, dkpPanel, "ChatConfigCheckButtonTemplate")

showMeChk:SetPoint("TOPLEFT", dkpPanel, "TOPLEFT", 80, -30)
showMeChk:SetSize(18, 18)

local showMeLabel = dkpPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
showMeLabel:SetPoint("LEFT", showMeChk, "RIGHT", 4, 0)
showMeLabel:SetText("Show only me")

showMeChk:SetScript("OnClick", function(self)
    dkpShowOnlyMe = self:GetChecked() or false
    UpdateTable()
end)

----------------------------------
-- DKP TABLE SCROLL
----------------------------------

dkpScroll = CreateFrame("ScrollFrame", nil, dkpPanel, "UIPanelScrollFrameTemplate")
dkpScroll:SetPoint("TOPLEFT", dkpPanel, "TOPLEFT", 30, headerY - 20)
dkpScroll:SetPoint("BOTTOMRIGHT", dkpPanel, "BOTTOMRIGHT", -30, 60)

dkpScrollChild = CreateFrame("Frame", nil)
dkpScrollChild:SetWidth(dkpScroll:GetWidth())
dkpScroll:SetScrollChild(dkpScrollChild)
dkpScrollChild:SetParent(dkpScroll)
dkpScrollChild:ClearAllPoints()
dkpScrollChild:SetPoint("TOPLEFT", 0, 0)

local sb = dkpScroll.ScrollBar
if sb then
    sb:ClearAllPoints()
    sb:SetPoint("TOPRIGHT", dkpScroll, "TOPRIGHT", -5, -18)
    sb:SetPoint("BOTTOMRIGHT", dkpScroll, "BOTTOMRIGHT", -20, 16)

    sb:SetValueStep(ROW_HEIGHT)

    sb:SetScript("OnValueChanged", function(self, value)
        dkpScroll:SetVerticalScroll(value)
        UpdateTable()
    end)
end

dkpScroll:SetScript("OnVerticalScroll", function(self, offset)

    self:SetVerticalScroll(offset)
    UpdateTable()
end)

UpdateTable()
end


-- GLOBAL CODE BLOCK --

----------------------------------------------------------------
-- INLINE EDIT BOX
----------------------------------------------------------------
    dkpInlineEdit = CreateFrame("EditBox", nil, dkpScrollChild, "InputBoxTemplate")
    dkpInlineEdit._handled = false
    dkpInlineEdit:SetAutoFocus(true)
    dkpInlineEdit:SetSize(80, 18)
    dkpInlineEdit:Hide()
    dkpInlineEdit.cancelled = false
    dkpInlineEdit:SetFrameStrata("HIGH")

dkpInlineEdit:SetScript("OnEscapePressed", function(self)
    self.cancelled = true
    self._submitted = false
    self._handled = true
    self:Hide()
end)

dkpInlineEdit:SetScript("OnEnterPressed", function(self)
    self.cancelled = false
    self._submitted = true
    self._handled = true

    if self.saveFunc then
        self.saveFunc(self:GetText())
    end

    self:Hide()
end)

dkpInlineEdit:SetScript("OnEditFocusLost", function(self)
    if not self.cancelled and not self._submitted and not self._handled then
        if self.saveFunc then
            self.saveFunc(self:GetText())
        end
    end

    self._submitted = false
    self._handled = false
    self:Hide()
end)

dkpInlineEdit:SetScript("OnHide", function(self)
    self._submitted = false
    self._handled = false

    if self.currentFS then
        self.currentFS:Show()
        self.currentFS = nil
    end
end)

--------------------------------------------------------------------
-- ADD PLAYER INPUT
--------------------------------------------------------------------
    do
        dkpPanel.addInput = CreateFrame("EditBox", nil, dkpPanel, "InputBoxTemplate")
		local addInput = dkpPanel.addInput
        addInput:SetSize(140, 20)
        addInput:SetPoint("BOTTOMLEFT", dkpPanel, "BOTTOMLEFT", 20, 10)
        addInput:SetAutoFocus(false)

        if not IsEditor(UnitName("player")) then
            addInput:Hide()
        end

		addInput:HookScript("OnEditFocusGained", function(self)
			if self._clickCatcher then return end

			local catcher = CreateFrame("Frame", nil, UIParent)
			catcher:SetAllPoints(UIParent)
			catcher:EnableMouse(true)
			catcher:SetFrameStrata("TOOLTIP")

			catcher:SetScript("OnMouseDown", function(_, button)
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    x, y = x / scale, y / scale

    local addButton = dkpPanel.addButton
    if addButton and addButton:IsVisible() then
        local left, right = addButton:GetLeft(), addButton:GetRight()
        local top, bottom = addButton:GetTop(), addButton:GetBottom()

        if left and right and top and bottom then
            if x >= left and x <= right and y >= bottom and y <= top then
                -- FIX: allow the click to go through
                self:ClearFocus()
                catcher:Hide()
                return
            end
        end
    end

    -- Click was outside the button → normal behaviour
    self:ClearFocus()
    catcher:Hide()
	end)

		catcher:SetScript("OnHide", function()
			catcher:SetParent(nil)
			self._clickCatcher = nil
		end)

		self._clickCatcher = catcher
	end)

        addInput:SetScript("OnEscapePressed", addInput.ClearFocus)
        addInput:SetScript("OnEnterPressed", addInput.ClearFocus)

        dkpPanel.addButton = CreateFrame("Button", nil, dkpPanel, "UIPanelButtonTemplate")
		local addButton = dkpPanel.addButton
        addButton:SetSize(75, 22)
        addButton:SetPoint("LEFT", addInput, "RIGHT", 10, 0)
        addButton:SetText("Add")

        if not IsEditor(UnitName("player")) then
            addButton:Hide()
        end

-- Fix: prevent first click from being eaten by focus loss
addButton:RegisterForClicks("AnyUp")
addButton:SetScript("OnMouseDown", function() end)

addButton:SetScript("OnClick", function()
    if not IsAuthorized() then
        Print("Only editors can add DKP records.")
		UpdateTable()
        return
    end

    local raw = addInput:GetText()
    if not raw or raw == "" then return end

    local short = Ambiguate(raw, "short")
    if not short or short == "" then return end

    -- Validate guild membership (hard reject)
    local ok, proper = IsNameInGuild(short)
    if not ok then
        Print("|cffff0000RedGuild:|r Cannot add DKP record — player is not in your guild.")
        return
    end

    local name = proper  -- use correct capitalization

    -- Duplicate check (case-insensitive)
    local upper = string.upper(name)
	
	for existingName, dkp in pairs(RedGuild_Data) do
		if type(dkp) == "table" and string.upper(existingName) == upper then
			Print("|cffff0000A DKP record already exists for:|r " .. existingName)
			return
		end
    end

    local d = EnsurePlayer(name)

-- Try UnitClass first (party/raid/target)
local _, class = UnitClass(name)

-- If not found, fall back to guild roster
if not class and IsInGuild() then
    for i = 1, GetNumGuildMembers() do
        local gName, _, _, _, _, _, _, _, _, _, gClass = GetGuildRosterInfo(i)
        if gName and Ambiguate(gName, "short") == name then
            class = gClass
            break
        end
    end
end

-- Assign if found
if class then
    d.class = class
end

    addInput:SetText("")
	BumpDKPVersion()
    UpdateTable()
	RefreshMLTools()
    Print("Added DKP record for " .. name)
end)
    end

    --------------------------------------------------------------------
    -- SYNC BUTTONS
    --------------------------------------------------------------------
    do
        local requestBtn = CreateFrame("Button", nil, dkpPanel, "UIPanelButtonTemplate")
        requestBtn:SetSize(120, 24)
        requestBtn:SetText("Request SYNC")
        requestBtn:SetPoint("BOTTOMRIGHT", dkpPanel, "BOTTOMRIGHT", -10, 10)
requestBtn:SetScript("OnClick", function()
    -- Editors get a confirmation popup
    if IsEditor(UnitName("player")) then
        StaticPopupDialogs["REDGUILD_REQUEST_SYNC_EDITOR_CONFIRM"] = {
            text = "Sync from another editor?",
            button1 = "Yes",
            button2 = "No",
            OnAccept = function()
                ------------------------------------------------------------
                -- ORIGINAL SYNC REQUEST CODE (unchanged)
                ------------------------------------------------------------
                EnsureSaved()
                UpdateOnlineEditors()

                local meReal = Ambiguate(UnitName("player"), "short")
                if not meReal or meReal == "" then
                    Print("Unable to determine your character name for sync.")
                    return
                end

                if RedGuild_SyncLocked then
                    Print("Sync is currently locked. Please wait a few seconds and try again.")
                    return
                end

                if not IsInGuild() then
                    Print("Guild roster not ready — cannot request sync yet.")
                    return
                end

                local num = GetNumGuildMembers()
                if num == 0 then
                    Print("Guild roster not ready — cannot request sync yet.")
                    return
                end

                local bestEditor = GetHighestRankEditor()
                if not bestEditor then
                    Print("No editor online — cannot request sync.")
                    return
                end

                RedGuild_Send("REQUEST", meReal, bestEditor)
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
        }

        StaticPopup_Show("REDGUILD_REQUEST_SYNC_EDITOR_CONFIRM")
        return
    end

    ------------------------------------------------------------
    -- NON‑EDITORS: run original code immediately
    ------------------------------------------------------------
    EnsureSaved()
    UpdateOnlineEditors()

    local meReal = Ambiguate(UnitName("player"), "short")
    if not meReal or meReal == "" then
        Print("Unable to determine your character name for sync.")
        return
    end

    if RedGuild_SyncLocked then
        Print("Sync is currently locked. Please wait a few seconds and try again.")
        return
    end

    if not IsInGuild() then
        Print("Guild roster not ready — cannot request sync yet.")
        return
    end

    local num = GetNumGuildMembers()
    if num == 0 then
        Print("Guild roster not ready — cannot request sync yet.")
        return
    end

    local bestEditor = GetHighestRankEditor()
    if not bestEditor then
        Print("No editor online — cannot request sync.")
        return
    end

    RedGuild_Send("REQUEST", meReal, bestEditor)
end)

        local forceBtn = CreateFrame("Button", nil, dkpPanel, "UIPanelButtonTemplate")
        forceBtn:SetSize(120, 24)
        forceBtn:SetText("FORCE Sync")
        forceBtn:SetPoint("RIGHT", requestBtn, "LEFT", -10, 0)

        if not IsEditor(UnitName("player")) then
            forceBtn:Hide()
        end

        forceBtn:SetScript("OnClick", function()
            if not IsAuthorized() then return end
		    if RedGuild_Config.hideMeFromSync then
				StaticPopup_Show("REDGUILD_FORCE_SYNC_BLOCKED")
				return
			end
			
            StaticPopup_Show("REDGUILD_FORCE_SYNC_CONFIRM")
        end)
    end

    --------------------------------------------------------------------
    -- FINALIZE
    --------------------------------------------------------------------
    RecalculateAllBalances()
	UpdateSyncStatus()
	dkpPanel:SetScript("OnShow", function()
    UpdateTable()
	end)

RedGuild_UIReady = true
ShowTab(TAB_DKP)
end
