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

    -- Ko-fi Button (opens a dialog)
    local kofiButton = CreateFrame("Button", nil, panel, "GameMenuButtonTemplate")
    kofiButton:SetSize(150, 25)
    kofiButton:SetPoint("TOPLEFT", supportText, "BOTTOMLEFT", 0, -5)
    kofiButton:SetText("|cff00ff00Support on Ko-fi|r")
    kofiButton:SetScript("OnClick", function()
        CattosShuffle:ShowKofiDialog()
    end)

    -- Sound Theme Section
    local soundThemeLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    soundThemeLabel:SetPoint("TOPLEFT", kofiButton, "BOTTOMLEFT", 0, -30)
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

    -- Gacha Settings Section
    local gachaLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    gachaLabel:SetPoint("TOPLEFT", minimapCheckbox, "BOTTOMLEFT", 0, -30)
    gachaLabel:SetText("|cffffcc00Gacha Settings|r")

    -- Gacha Reset Button
    local gachaResetButton = CreateFrame("Button", nil, panel, "GameMenuButtonTemplate")
    gachaResetButton:SetSize(150, 25)
    gachaResetButton:SetPoint("TOPLEFT", gachaLabel, "BOTTOMLEFT", 0, -10)
    gachaResetButton:SetText("Reset Pity Counters")
    gachaResetButton:SetScript("OnClick", function()
        -- Reset all pity counters
        if CattosShuffle.Gacha then
            CattosShuffle.Gacha.spinCount = 0
            CattosShuffle.Gacha.bTierPityCount = 0
            CattosShuffle.Gacha.shards = 0
            CattosShuffleDB.gachaSpinCount = 0
            CattosShuffleDB.gachaBTierPityCount = 0
            CattosShuffleDB.gachaShards = 0
            print("|cff00ff00All Gacha pity counters have been reset!|r")
        end
    end)

    -- Gacha Quick Access
    local gachaOpenButton = CreateFrame("Button", nil, panel, "GameMenuButtonTemplate")
    gachaOpenButton:SetSize(150, 25)
    gachaOpenButton:SetPoint("LEFT", gachaResetButton, "RIGHT", 10, 0)
    gachaOpenButton:SetText("Open Gacha")
    gachaOpenButton:SetScript("OnClick", function()
        if CattosShuffle.Gacha then
            -- Close the options frame (try different frame names for compatibility)
            if InterfaceOptionsFrame then
                InterfaceOptionsFrame:Hide()
            elseif SettingsPanel then
                SettingsPanel:Hide()
            elseif InterfaceAddOnsList then
                InterfaceAddOnsList:Hide()
                InterfaceAddOnsList:GetParent():Hide()
            end
            CattosShuffle.Gacha:Toggle()
        end
    end)

    -- Instructions
    local instructions = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    instructions:SetPoint("TOPLEFT", gachaResetButton, "BOTTOMLEFT", 0, -30)
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

-- Ko-fi Link Dialog
function CattosShuffle:ShowKofiDialog()
    -- Create the dialog if it doesn't exist
    if not self.kofiDialog then
        local dialog = CreateFrame("Frame", "CattosKofiDialog", UIParent, "BasicFrameTemplate")
        dialog:SetSize(400, 200)
        dialog:SetPoint("CENTER")
        dialog:SetMovable(true)
        dialog:EnableMouse(true)
        dialog:RegisterForDrag("LeftButton")
        dialog:SetScript("OnDragStart", dialog.StartMoving)
        dialog:SetScript("OnDragStop", dialog.StopMovingOrSizing)
        dialog:SetFrameStrata("DIALOG")
        dialog:Hide()

        -- Add to ESC close list
        tinsert(UISpecialFrames, "CattosKofiDialog")

        -- Title
        local title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", dialog, "TOP", 0, -35)
        title:SetText("|cff00ff00Support CattosShuffle|r")

        -- Warning text
        local warning = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        warning:SetPoint("TOP", title, "BOTTOM", 0, -15)
        warning:SetWidth(350)
        warning:SetText("|cffff8800This will open a page outside of World of Warcraft.|r\n|cffccccccCopy the link below and paste it in your browser:|r")
        warning:SetJustifyH("CENTER")

        -- Create copyable link box
        local linkBG = CreateFrame("Frame", nil, dialog, "BackdropTemplate")
        linkBG:SetSize(350, 30)
        linkBG:SetPoint("CENTER", dialog, "CENTER", 0, -10)
        linkBG:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
            tile = false, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        linkBG:SetBackdropColor(0, 0.1, 0, 0.8)
        linkBG:SetBackdropBorderColor(0, 1, 0, 1)

        -- EditBox for the link
        local linkBox = CreateFrame("EditBox", nil, linkBG)
        linkBox:SetFontObject("GameFontHighlightLarge")
        linkBox:SetText("https://ko-fi.com/kay_catto")
        linkBox:SetTextColor(0, 1, 0, 1)
        linkBox:SetWidth(340)
        linkBox:SetHeight(30)
        linkBox:SetPoint("CENTER", linkBG, "CENTER", 0, 0)
        linkBox:SetAutoFocus(false)
        linkBox:EnableMouse(true)

        linkBox:SetScript("OnMouseUp", function(self)
            self:SetFocus()
            self:HighlightText()
        end)

        linkBox:SetScript("OnEditFocusGained", function(self)
            self:HighlightText()
        end)

        linkBox:SetScript("OnEditFocusLost", function(self)
            self:HighlightText(0, 0)
        end)

        linkBox:SetScript("OnEscapePressed", function(self)
            self:ClearFocus()
            dialog:Hide()
        end)

        -- Prevent editing
        linkBox:SetScript("OnTextChanged", function(self, userInput)
            if userInput then
                self:SetText("https://ko-fi.com/kay_catto")
                self:HighlightText()
            end
        end)

        -- Instructions
        local instructions = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        instructions:SetPoint("BOTTOM", dialog, "BOTTOM", 0, 40)
        instructions:SetText("|cffccccccClick the link above to select it, then Ctrl+C to copy|r")

        self.kofiDialog = dialog
    end

    self.kofiDialog:Show()
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