-- CattosShuffle Options Panel
-- Adds configuration options to the Interface Options menu

local addonName, CattosShuffle = ...
_G.CattosCasino = CattosShuffle  -- Keep backwards compatibility

-- Create the options panel
function CattosShuffle:CreateOptionsPanel()
    -- Main panel
    local panel = CreateFrame("Frame", "CattosShuffleOptionsPanel", UIParent)
    panel.name = "CattosShuffle"

    -- Get localization
    local L = CattosShuffle.L

    -- Title
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(L["OPTIONS_TITLE"])

    -- Author info with Ko-fi link
    local author = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    author:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    author:SetText(L["CREATED_BY"])

    -- Ko-fi support text
    local supportText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    supportText:SetPoint("TOPLEFT", author, "BOTTOMLEFT", 0, -8)
    supportText:SetText(L["SUPPORT_DEVELOPMENT"])

    -- Ko-fi link (selectable and copyable)
    local kofiLinkBG = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    kofiLinkBG:SetSize(250, 24)
    kofiLinkBG:SetPoint("TOPLEFT", supportText, "BOTTOMLEFT", 0, -5)
    kofiLinkBG:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    kofiLinkBG:SetBackdropColor(0, 0.2, 0, 0.3)
    kofiLinkBG:SetBackdropBorderColor(0, 1, 0, 0.5)

    local kofiLink = CreateFrame("EditBox", nil, kofiLinkBG)
    kofiLink:SetFontObject("GameFontHighlight")
    kofiLink:SetText("https://ko-fi.com/kay_catto")
    kofiLink:SetTextColor(0, 1, 0, 1)
    kofiLink:SetWidth(240)
    kofiLink:SetHeight(20)
    kofiLink:SetPoint("CENTER", kofiLinkBG, "CENTER", 0, 0)
    kofiLink:SetAutoFocus(false)
    kofiLink:EnableMouse(true)
    kofiLink:SetScript("OnMouseUp", function(self)
        self:SetFocus()
        self:HighlightText()
    end)
    kofiLink:SetScript("OnEditFocusLost", function(self)
        self:HighlightText(0, 0)
    end)
    kofiLink:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    kofiLink:SetScript("OnTextChanged", function(self, userInput)
        if userInput then
            -- Reset text if user tries to change it
            self:SetText("https://ko-fi.com/kay_catto")
            self:HighlightText()
        end
    end)
    kofiLink:SetScript("OnChar", function(self, text)
        -- Prevent typing
        self:SetText("https://ko-fi.com/kay_catto")
        self:HighlightText()
    end)

    -- Sound Theme Section
    local soundThemeLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    soundThemeLabel:SetPoint("TOPLEFT", kofiLinkBG, "BOTTOMLEFT", 0, -30)
    soundThemeLabel:SetText(L["SOUND_THEME"])

    local soundThemeDesc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    soundThemeDesc:SetPoint("TOPLEFT", soundThemeLabel, "BOTTOMLEFT", 0, -5)
    soundThemeDesc:SetText(L["SOUND_THEME_DESC"])

    -- Sound Theme Dropdown
    local dropdown = CreateFrame("Frame", "CattosShuffleSoundDropdown", panel, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", soundThemeDesc, "BOTTOMLEFT", -15, -10)

    local themes = {
        { value = "trute", text = L["SOUND_THEME_TRUTE"] },
        { value = "default", text = L["SOUND_THEME_DEFAULT"] }
    }

    local function InitializeDropdown(self, level)
        for _, theme in ipairs(themes) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = theme.text
            info.value = theme.value
            info.func = function()
                CattosShuffleDB.soundTheme = theme.value
                UIDropDownMenu_SetSelectedValue(dropdown, theme.value)
                UIDropDownMenu_SetText(dropdown, theme.text)
                local L = CattosShuffle.L
                print(string.format(L["SOUND_THEME_CHANGED"], theme.text))
            end
            info.checked = (CattosShuffleDB.soundTheme == theme.value)
            UIDropDownMenu_AddButton(info, level)
        end
    end

    UIDropDownMenu_Initialize(dropdown, InitializeDropdown)
    UIDropDownMenu_SetWidth(dropdown, 200)

    -- Set current value
    local function UpdateDropdown()
        local currentTheme = CattosShuffleDB.soundTheme or "trute"
        for _, theme in ipairs(themes) do
            if theme.value == currentTheme then
                UIDropDownMenu_SetSelectedValue(dropdown, currentTheme)
                UIDropDownMenu_SetText(dropdown, theme.text)
                break
            end
        end
    end

    -- Sound Enabled Checkbox
    local soundCheckbox = CreateFrame("CheckButton", "CattosShuffleSoundCheckbox", panel, "InterfaceOptionsCheckButtonTemplate")
    soundCheckbox:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 15, -20)
    soundCheckbox.Text:SetText(L["SOUND_ENABLED"])
    soundCheckbox:SetScript("OnClick", function(self)
        CattosShuffleDB.soundEnabled = self:GetChecked()
    end)

    -- Auto Mode Checkbox
    local autoModeCheckbox = CreateFrame("CheckButton", "CattosShuffleAutoModeCheckbox", panel, "InterfaceOptionsCheckButtonTemplate")
    autoModeCheckbox:SetPoint("TOPLEFT", soundCheckbox, "BOTTOMLEFT", 0, -10)
    autoModeCheckbox.Text:SetText(L["AUTO_MODE"])
    autoModeCheckbox:SetScript("OnClick", function(self)
        CattosShuffleDB.autoMode = self:GetChecked()
    end)

    -- Minimap Button Checkbox
    local minimapCheckbox = CreateFrame("CheckButton", "CattosShuffleMinimapCheckbox", panel, "InterfaceOptionsCheckButtonTemplate")
    minimapCheckbox:SetPoint("TOPLEFT", autoModeCheckbox, "BOTTOMLEFT", 0, -10)
    minimapCheckbox.Text:SetText("Show minimap button")
    minimapCheckbox:SetScript("OnClick", function(self)
        if not CattosShuffleDB.minimap then
            CattosShuffleDB.minimap = {}
        end
        CattosShuffleDB.minimap.hide = not self:GetChecked()
        -- Toggle the button visibility
        if CattosShuffle.ToggleMinimapButton then
            if self:GetChecked() then
                -- Show button if checked
                if CattosShuffleMinimapButton and not CattosShuffleMinimapButton:IsShown() then
                    CattosShuffleMinimapButton:Show()
                end
            else
                -- Hide button if unchecked
                if CattosShuffleMinimapButton and CattosShuffleMinimapButton:IsShown() then
                    CattosShuffleMinimapButton:Hide()
                end
            end
        end
    end)

    -- Instructions
    local instructions = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    instructions:SetPoint("TOPLEFT", minimapCheckbox, "BOTTOMLEFT", 0, -30)
    instructions:SetText(L["COMMANDS"])

    local commandList = {
        L["CMD_OPEN"],
        L["CMD_BAGS"],
        L["CMD_SHEET"],
        L["CMD_DELETE"],
        L["CMD_CHOICE"],
    }

    local lastLabel = instructions
    for _, cmd in ipairs(commandList) do
        local cmdLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        cmdLabel:SetPoint("TOPLEFT", lastLabel, "BOTTOMLEFT", 0, -5)
        cmdLabel:SetText(cmd)
        lastLabel = cmdLabel
    end

    -- Refresh function
    panel.refresh = function()
        UpdateDropdown()
        soundCheckbox:SetChecked(CattosShuffleDB.soundEnabled)
        autoModeCheckbox:SetChecked(CattosShuffleDB.autoMode)
        -- Check minimap button state
        local showMinimap = true
        if CattosShuffleDB.minimap and CattosShuffleDB.minimap.hide then
            showMinimap = false
        end
        minimapCheckbox:SetChecked(showMinimap)
    end

    -- OnShow handler
    panel:SetScript("OnShow", function(self)
        self.refresh()
    end)

    -- Add panel to Interface Options (Classic Era compatible)
    if InterfaceOptions_AddCategory then
        -- Older API
        InterfaceOptions_AddCategory(panel)
    elseif Settings and Settings.RegisterCanvasLayoutCategory then
        -- Newer API (10.0+)
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
    else
        -- Fallback for Classic Era - direct add to InterfaceOptionsFramePanelContainer
        panel.name = "CattosShuffle"
        panel.parent = nil
        panel.okay = function() end
        panel.cancel = function() end
        panel.default = function()
            CattosShuffleDB.soundTheme = "trute"
            CattosShuffleDB.soundEnabled = true
            CattosShuffleDB.autoMode = true
            panel.refresh()
        end

        -- Manual registration for Classic
        if not INTERFACEOPTIONS_ADDONCATEGORIES then
            INTERFACEOPTIONS_ADDONCATEGORIES = {}
        end
        tinsert(INTERFACEOPTIONS_ADDONCATEGORIES, panel)
    end

    -- Store reference
    CattosShuffle.optionsPanel = panel
end

-- Initialize options panel when addon loads
local function InitializeOptions()
    -- Wait for saved variables to load
    if not CattosShuffleDB then
        CattosShuffleDB = {
            soundTheme = "trute",
            soundEnabled = true,
            autoMode = true
        }
    end

    -- Create the options panel
    CattosShuffle:CreateOptionsPanel()
end

-- Register for ADDON_LOADED event
local optionsFrame = CreateFrame("Frame")
optionsFrame:RegisterEvent("ADDON_LOADED")
optionsFrame:SetScript("OnEvent", function(self, event, addon)
    if addon == addonName then
        -- Small delay to ensure saved variables are loaded
        C_Timer.After(0.1, InitializeOptions)
        self:UnregisterEvent("ADDON_LOADED")
    end
end)