function CreateEditorsTab()
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


end
