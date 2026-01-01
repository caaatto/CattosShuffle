-- CattosShuffle Minimap Button
local addonName, CattosShuffle = ...

-- Create the minimap button
local minimapButton = CreateFrame("Button", "CattosShuffleMinimapButton", Minimap)
minimapButton:SetSize(32, 32)
minimapButton:SetFrameStrata("MEDIUM")
minimapButton:SetFrameLevel(8)
minimapButton:RegisterForClicks("AnyUp")
minimapButton:RegisterForDrag("LeftButton")
minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

-- Dark background circle (lowest layer)
local background = minimapButton:CreateTexture(nil, "BACKGROUND")
background:SetSize(28, 28)
background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
background:SetPoint("TOPLEFT", 2, -4)
background:SetVertexColor(0, 0, 0, 0.6)

-- Icon (middle layer)
local icon = minimapButton:CreateTexture(nil, "ARTWORK")
icon:SetSize(20, 20)
icon:SetTexture("Interface\\Icons\\INV_Misc_Coin_01")
icon:SetPoint("TOPLEFT", 7, -8)

-- Border overlay (top layer)
local overlay = minimapButton:CreateTexture(nil, "OVERLAY")
overlay:SetSize(53, 53)
overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
overlay:SetPoint("TOPLEFT")

-- Initialize saved position
local function InitializePosition()
    if not CattosShuffleDB then
        CattosShuffleDB = {}
    end

    if not CattosShuffleDB.minimapPos then
        CattosShuffleDB.minimapPos = 45  -- Default position (45 degrees)
    end
end

-- Update button position
local function UpdatePosition()
    if not minimapButton.isMoving then
        minimapButton:ClearAllPoints()
        local angle = math.rad(CattosShuffleDB.minimapPos or 45)
        local x = math.cos(angle) * 80
        local y = math.sin(angle) * 80
        minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
    end
end

-- Dragging functionality
local function OnDragStart(self)
    self.isMoving = true
    GameTooltip:Hide()
end

local function OnDragStop(self)
    self.isMoving = false

    -- Calculate new angle based on position
    local centerX, centerY = Minimap:GetCenter()
    local x, y = self:GetCenter()
    local angle = math.deg(math.atan2(y - centerY, x - centerX))

    if angle < 0 then
        angle = angle + 360
    end

    CattosShuffleDB.minimapPos = angle

    -- Clear and reset position
    self:ClearAllPoints()
    UpdatePosition()  -- Snap to proper position
end

local function OnUpdate(self)
    if self.isMoving then
        local centerX, centerY = Minimap:GetCenter()
        local x, y = GetCursorPosition()
        x, y = x / self:GetEffectiveScale(), y / self:GetEffectiveScale()

        local angle = math.atan2(y - centerY, x - centerX)
        local distance = 80

        self:ClearAllPoints()
        self:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * distance, math.sin(angle) * distance)
    end
end

-- Click handlers
minimapButton:SetScript("OnClick", function(self, button)
    if button == "LeftButton" then
        CattosShuffle:Toggle()
    elseif button == "RightButton" then
        -- Open Interface Options and navigate to our addon
        -- First, open the game menu if needed
        if not GameMenuFrame or not GameMenuFrame:IsShown() then
            -- Try to open interface options directly
            if InterfaceOptionsFrame_Show then
                InterfaceOptionsFrame_Show()
            else
                -- Open game menu first
                if not GameMenuFrame then
                    ShowUIPanel(GameMenuFrame)
                end
                -- Then click the Interface button
                if GameMenuButtonOptions then
                    GameMenuButtonOptions:Click()
                end
            end
        end

        -- Navigate to AddOns tab and our panel after a short delay
        C_Timer.After(0.2, function()
            -- First, click the AddOns tab (Tab 2 in Classic Era)
            local addonsTab = InterfaceOptionsFrameTab2
            if addonsTab then
                addonsTab:Click()
            end

            -- Then navigate to our addon
            C_Timer.After(0.1, function()
                if InterfaceOptionsFrame_OpenToCategory then
                    InterfaceOptionsFrame_OpenToCategory("CattosShuffle")
                    -- Call twice - known Blizzard bug workaround
                    C_Timer.After(0.1, function()
                        InterfaceOptionsFrame_OpenToCategory("CattosShuffle")
                    end)
                else
                    -- Alternative: Find and click our addon in the list
                    if INTERFACEOPTIONS_ADDONCATEGORIES then
                        for i, panel in ipairs(INTERFACEOPTIONS_ADDONCATEGORIES) do
                            if panel and panel.name == "CattosShuffle" then
                                -- Make the panel visible
                                if InterfaceOptionsFrame_OpenToCategory then
                                    InterfaceOptionsFrame_OpenToCategory(panel)
                                end
                                break
                            end
                        end
                    end
                end
            end)
        end)
    end
end)

-- Tooltip
minimapButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("|cff00ff00CattosShuffle|r", 1, 1, 1)
    GameTooltip:AddLine("|cffffffaaLeft-Click:|r Open Casino", 0.9, 0.9, 0.9)
    GameTooltip:AddLine("|cffffffaaRight-Click:|r Options", 0.9, 0.9, 0.9)
    GameTooltip:AddLine("|cffffffaaDrag:|r Move button", 0.9, 0.9, 0.9)
    GameTooltip:Show()
end)

minimapButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

-- Set up dragging
minimapButton:SetScript("OnDragStart", OnDragStart)
minimapButton:SetScript("OnDragStop", OnDragStop)
minimapButton:SetScript("OnUpdate", OnUpdate)

-- Mousewheel to adjust position (optional fun feature)
minimapButton:EnableMouseWheel(true)
minimapButton:SetScript("OnMouseWheel", function(self, delta)
    CattosShuffleDB.minimapPos = (CattosShuffleDB.minimapPos or 45) + (delta * 5)
    if CattosShuffleDB.minimapPos > 360 then
        CattosShuffleDB.minimapPos = CattosShuffleDB.minimapPos - 360
    elseif CattosShuffleDB.minimapPos < 0 then
        CattosShuffleDB.minimapPos = CattosShuffleDB.minimapPos + 360
    end
    UpdatePosition()
end)

-- Initialize on addon load
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event, addon)
    if event == "ADDON_LOADED" and addon == addonName then
        InitializePosition()
    elseif event == "PLAYER_LOGIN" then
        UpdatePosition()
        minimapButton:Show()
    end
end)

-- Add toggle function to hide/show minimap button
function CattosShuffle:ToggleMinimapButton()
    if minimapButton:IsShown() then
        minimapButton:Hide()
        if not CattosShuffleDB.minimap then
            CattosShuffleDB.minimap = {}
        end
        CattosShuffleDB.minimap.hide = true
    else
        minimapButton:Show()
        if CattosShuffleDB.minimap then
            CattosShuffleDB.minimap.hide = false
        end
    end
end

-- Check if button should be hidden on startup
C_Timer.After(0.5, function()
    if CattosShuffleDB and CattosShuffleDB.minimap and CattosShuffleDB.minimap.hide then
        minimapButton:Hide()
    end
end)