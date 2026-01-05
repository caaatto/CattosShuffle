-- CattosShuffle - UI Module
-- Author: Amke
-- Version: 1.0.0

local addonName, CattosShuffle = ...
local L = CattosShuffle.L

-- UI Constants
local SLOT_SIZE = 40
local SLOT_SPACING = 8
local FRAME_WIDTH = 700
local FRAME_HEIGHT = 580

-- Create main frame
function CattosShuffle:InitializeUI()
    -- Main Frame
    self.frame = CreateFrame("Frame", "CattosShuffleFrame", UIParent, "BackdropTemplate")
    self.frame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    self.frame:SetPoint("CENTER")
    self.frame:SetMovable(true)
    self.frame:EnableMouse(true)
    self.frame:RegisterForDrag("LeftButton")
    self.frame:SetScript("OnDragStart", self.frame.StartMoving)
    self.frame:SetScript("OnDragStop", self.frame.StopMovingOrSizing)

    -- Backdrop with casino theme
    self.frame:SetBackdrop({
        bgFile = "Interface/DialogFrame/UI-DialogBox-Background-Dark",
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Gold-Border",
        edgeSize = 32,
        insets = { left = 11, right = 11, top = 11, bottom = 11 },
    })
    self.frame:SetBackdropColor(0.15, 0.08, 0.25, 0.95)  -- More purple glow
    self.frame:SetBackdropBorderColor(1, 1, 0, 1)  -- Bright golden border

    -- Title with shadow and glow effect
    local title = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", self.frame, "TOP", 0, -15)
    title:SetText("|cffffcc00Catto's|r |cff00ff00Shuffle|r")
    title:SetFont("Fonts\\FRIZQT__.TTF", 20, "OUTLINE")
    title:SetShadowOffset(2, -2)
    title:SetShadowColor(0, 0, 0, 1)

    -- Close Button
    local closeBtn = CreateFrame("Button", nil, self.frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", 0, 0)

    -- Create single unified panel (no tabs)
    self:CreateMainPanel()

    -- Result Display
    self.resultDisplay = self:CreateResultDisplay()

    -- Action Buttons
    self:CreateActionButtons()

    -- Gacha Button (golden gacha style!)
    local gachaButton = CreateFrame("Button", nil, self.frame, "GameMenuButtonTemplate")
    gachaButton:SetSize(140, 35)
    gachaButton:SetPoint("TOP", self.frame, "TOP", 0, -45)
    gachaButton:SetText("|cffffcc00[ GACHA ]|r")
    gachaButton:SetNormalFontObject("GameFontNormalLarge")
    gachaButton:SetHighlightFontObject("GameFontHighlightLarge")
    gachaButton:SetScript("OnClick", function()
        self.frame:Hide()
        if self.Gacha then
            self.Gacha:Toggle()
        end
    end)

    -- Add tooltip
    gachaButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("|cffffcc00GACHA PULL SYSTEM|r", 1, 1, 1)
        GameTooltip:AddLine("Pull 3 items from your inventory!", 1, 0.8, 0.8)
        GameTooltip:AddLine("C > B > A > S > SS Tiers", 0.8, 0.8, 1)
        GameTooltip:AddLine("3x Match = DELETE one item!", 1, 0, 0)
        GameTooltip:Show()
    end)
    gachaButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Initialize visibility
    self.frame:Hide()

    -- Add to ESC close list so ESC key closes the window
    tinsert(UISpecialFrames, "CattosShuffleFrame")

    -- Play close sound when window is hidden (ESC or X button)
    self.frame:SetScript("OnHide", function()
        PlaySound(840, "SFX")  -- Character Info Close sound
    end)

    -- Toggle function
    self.frame.Toggle = function(frame)
        if frame:IsShown() then
            frame:Hide()  -- OnHide will play the close sound
        else
            PlaySound(839, "SFX")  -- Character Info Open sound
            frame:Show()
            CattosShuffle:RefreshUI()
        end
    end
end

function CattosShuffle:CreateMainPanel()
    local panel = CreateFrame("Frame", nil, self.frame)
    panel:SetAllPoints(self.frame)

    -- Background
    panel.bg = panel:CreateTexture(nil, "BACKGROUND")
    panel.bg:SetAllPoints()
    panel.bg:SetColorTexture(0.05, 0.05, 0.1, 0.3)

    -- Store references for both equipment and bag slots
    self.equipmentPanel = panel
    self.bagPanel = panel

    -- Create equipment section on the left
    self:CreateEquipmentSection(panel)

    -- Create bag section on the right
    self:CreateBagSection(panel)

    panel:Show()
end

function CattosShuffle:CreateEquipmentSection(parent)
    -- 3D Character Model (centered between columns)
    local modelFrame = CreateFrame("PlayerModel", nil, parent)
    modelFrame:SetPoint("CENTER", parent, "TOPLEFT", 290, -250)  -- Centered at x=290 (middle of 120 and 460)
    modelFrame:SetSize(280, 350)
    modelFrame:ClearModel()
    modelFrame:SetUnit("player")
    modelFrame:SetFacing(0)
    modelFrame:SetAlpha(1)

    -- Model background
    local modelBG = modelFrame:CreateTexture(nil, "BACKGROUND")
    modelBG:SetAllPoints()
    modelBG:SetColorTexture(0, 0, 0, 0.2)

    -- Make model interactive (rotatable)
    modelFrame:EnableMouse(true)
    modelFrame:EnableMouseWheel(true)
    modelFrame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            self.rotating = true
            self.rotateStartCursorX = GetCursorPosition()
            self.rotateStartFacing = self:GetFacing()
        end
    end)
    modelFrame:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            self.rotating = false
        end
    end)
    modelFrame:SetScript("OnUpdate", function(self)
        if self.rotating then
            local x = GetCursorPosition()
            local diff = (x - self.rotateStartCursorX) * 0.01
            self:SetFacing(self.rotateStartFacing + diff)
        end
    end)

    parent.modelFrame = modelFrame

    -- Equipment Slots (shifted left)
    parent.slots = {}

    local slotPositions = {
        -- Left side (shifted right for centering)
        [0] = {x = 120, y = -90, slot = "HeadSlot"},        -- Head
        [1] = {x = 120, y = -135, slot = "NeckSlot"},       -- Neck
        [2] = {x = 120, y = -180, slot = "ShoulderSlot"},   -- Shoulders
        [3] = {x = 120, y = -225, slot = "BackSlot"},       -- Back
        [4] = {x = 120, y = -270, slot = "ChestSlot"},      -- Chest
        [5] = {x = 120, y = -315, slot = "ShirtSlot"},      -- Shirt
        [6] = {x = 120, y = -360, slot = "TabardSlot"},     -- Tabard
        [7] = {x = 120, y = -405, slot = "WristSlot"},      -- Wrist

        -- Right side (shifted right for centering)
        [8] = {x = 460, y = -90, slot = "HandsSlot"},       -- Hands
        [9] = {x = 460, y = -135, slot = "WaistSlot"},      -- Waist
        [10] = {x = 460, y = -180, slot = "LegsSlot"},      -- Legs
        [11] = {x = 460, y = -225, slot = "FeetSlot"},      -- Feet
        [12] = {x = 460, y = -270, slot = "Finger0Slot"},   -- Ring 1
        [13] = {x = 460, y = -315, slot = "Finger1Slot"},   -- Ring 2
        [14] = {x = 460, y = -360, slot = "Trinket0Slot"},  -- Trinket 1
        [15] = {x = 460, y = -405, slot = "Trinket1Slot"},  -- Trinket 2

        -- Bottom weapons (centered under model)
        [16] = {x = 240, y = -440, slot = "MainHandSlot"},  -- Main Hand
        [17] = {x = 290, y = -440, slot = "SecondaryHandSlot"}, -- Off Hand
        [18] = {x = 340, y = -440, slot = "RangedSlot"},    -- Ranged
    }

    -- Create the equipment slots
    for idx, pos in pairs(slotPositions) do
        local slotData = CattosShuffle.SHEET_SLOTS[idx]
        local button = self:CreateEquipmentSlot(parent, idx, slotData, pos)
        parent.slots[idx] = button
    end
end

function CattosShuffle:CreateBagSection(parent)
    -- Bags on the right side (vertical)
    parent.bags = {}

    local bagStartX = 530  -- Right side position (to the right of equipment)
    local bagStartY = -90   -- Starting Y position
    local bagSpacing = 75   -- Space between bags

    for i = 0, 4 do
        local button = self:CreateBagSlot(parent, i)
        button:SetPoint("TOPLEFT", parent, "TOPLEFT", bagStartX, bagStartY - (i * bagSpacing))
        parent.bags[i] = button
    end
end

function CattosShuffle:CreateEquipmentSlot(parent, slotIndex, slotData, position)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(37, 37)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", position.x, position.y)

    return self:SetupSlotButton(button, slotIndex, slotData)
end

function CattosShuffle:CreateBagSlot(parent, bagIndex)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(64, 64)

    return self:SetupBagButton(button, bagIndex)
end

-- Remove the old CreateTabs function
function CattosShuffle:CreateTabs_REMOVED()
    local tabContainer = CreateFrame("Frame", nil, self.frame)
    tabContainer:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 20, -40)
    tabContainer:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -20, -40)
    tabContainer:SetHeight(30)

    -- Equipment Tab
    local equipTab = CreateFrame("Button", nil, tabContainer)
    equipTab:SetSize(100, 30)
    equipTab:SetPoint("LEFT", tabContainer, "LEFT", 0, 0)
    equipTab:SetNormalFontObject("GameFontNormal")
    equipTab:SetHighlightFontObject("GameFontHighlight")
    equipTab:SetText(L["EQUIPMENT"])
    equipTab:SetScript("OnClick", function()
        if not self.equipmentPanel:IsShown() then
            PlaySound(841, "SFX")  -- Tab Click sound
            self.equipmentPanel:Show()
            self.bagPanel:Hide()
        end
    end)

    -- Bag Tab
    local bagTab = CreateFrame("Button", nil, tabContainer)
    bagTab:SetSize(100, 30)
    bagTab:SetPoint("LEFT", equipTab, "RIGHT", 5, 0)
    bagTab:SetNormalFontObject("GameFontNormal")
    bagTab:SetHighlightFontObject("GameFontHighlight")
    bagTab:SetText(L["BAGS"])
    bagTab:SetScript("OnClick", function()
        if not self.bagPanel:IsShown() then
            PlaySound(841, "SFX")  -- Tab Click sound
            self.equipmentPanel:Hide()
            self.bagPanel:Show()
        end
    end)
end

function CattosShuffle:CreateEquipmentPanel_REMOVED()
    local panel = CreateFrame("Frame", nil, self.frame)
    panel:SetAllPoints(self.frame)

    -- Background für Character Panel Style
    panel.bg = panel:CreateTexture(nil, "BACKGROUND")
    panel.bg:SetAllPoints()
    panel.bg:SetColorTexture(0.05, 0.05, 0.1, 0.3)

    -- 3D Character Model (Mitte)
    local modelFrame = CreateFrame("PlayerModel", nil, panel)
    modelFrame:SetPoint("CENTER", panel, "CENTER", 0, 40)
    modelFrame:SetSize(280, 350)
    modelFrame:ClearModel()
    modelFrame:SetUnit("player")
    modelFrame:SetFacing(0)
    modelFrame:SetAlpha(1)

    -- Model Hintergrund
    local modelBG = modelFrame:CreateTexture(nil, "BACKGROUND")
    modelBG:SetAllPoints()
    modelBG:SetColorTexture(0, 0, 0, 0.2)

    -- Mache das Model interaktiv (drehbar)
    modelFrame:EnableMouse(true)
    modelFrame:EnableMouseWheel(true)
    modelFrame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            self.rotating = true
            self.rotateStartCursorX = GetCursorPosition()
            self.rotateStartFacing = self:GetFacing()
        end
    end)
    modelFrame:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            self.rotating = false
        end
    end)
    modelFrame:SetScript("OnUpdate", function(self)
        if self.rotating then
            local x = GetCursorPosition()
            local diff = (x - self.rotateStartCursorX) * 0.01
            self:SetFacing(self.rotateStartFacing + diff)
        end
    end)

    panel.modelFrame = modelFrame

    -- Equipment Slots im Character Panel Layout
    panel.slots = {}

    -- Slot-Positionen kompakter für kleineres Fenster
    local slotPositions = {
        -- Linke Seite (von oben nach unten) - Use correct slot IDs
        [0] = {x = 50, y = -90, slot = "HeadSlot"},        -- Kopf (Head)
        [1] = {x = 50, y = -135, slot = "NeckSlot"},       -- Hals (Neck)
        [2] = {x = 50, y = -180, slot = "ShoulderSlot"},   -- Schulter (Shoulders)
        [3] = {x = 50, y = -225, slot = "BackSlot"},       -- Rücken (Back)
        [4] = {x = 50, y = -270, slot = "ChestSlot"},      -- Brust (Chest)
        [5] = {x = 50, y = -315, slot = "ShirtSlot"},      -- Hemd (Shirt)
        [6] = {x = 50, y = -360, slot = "TabardSlot"},     -- Wappenrock (Tabard)
        [7] = {x = 50, y = -405, slot = "WristSlot"},      -- Handgelenke (Wrist)

        -- Rechte Seite (von oben nach unten) - Use correct slot IDs
        [8] = {x = 590, y = -90, slot = "HandsSlot"},      -- Hände (Hands)
        [9] = {x = 590, y = -135, slot = "WaistSlot"},     -- Taille (Waist)
        [10] = {x = 590, y = -180, slot = "LegsSlot"},     -- Beine (Legs)
        [11] = {x = 590, y = -225, slot = "FeetSlot"},     -- Füße (Feet)
        [12] = {x = 590, y = -270, slot = "Finger0Slot"},  -- Ring 1
        [13] = {x = 590, y = -315, slot = "Finger1Slot"},  -- Ring 2
        [14] = {x = 590, y = -360, slot = "Trinket0Slot"}, -- Schmuck 1 (Trinket 1)
        [15] = {x = 590, y = -405, slot = "Trinket1Slot"}, -- Schmuck 2 (Trinket 2)

        -- Untere Slots (Waffen) - horizontal nebeneinander, zentriert
        [16] = {x = 260, y = -440, slot = "MainHandSlot"},  -- Haupthand (Main Hand)
        [17] = {x = 310, y = -440, slot = "SecondaryHandSlot"}, -- Nebenhand (Off Hand)
        [18] = {x = 360, y = -440, slot = "RangedSlot"},    -- Fernkampf (Ranged/Distance)
    }

    -- Erstelle die Slots
    for idx, pos in pairs(slotPositions) do
        if self.SHEET_SLOTS[idx] then
            local slot = CreateFrame("Button", nil, panel, "BackdropTemplate")
            slot:SetSize(SLOT_SIZE, SLOT_SIZE)
            self:SetupSlotButton(slot, idx, self.SHEET_SLOTS[idx])
            slot:SetPoint("TOPLEFT", panel, "TOPLEFT", pos.x, pos.y)
            panel.slots[idx] = slot
        end
    end

    return panel
end

function CattosShuffle:CreateBagPanel_REMOVED()
    local panel = CreateFrame("Frame", nil, self.frame)
    panel:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 20, -75)
    panel:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -220, -75)
    panel:SetHeight(200)

    -- Background
    panel.bg = panel:CreateTexture(nil, "BACKGROUND")
    panel.bg:SetAllPoints()
    panel.bg:SetColorTexture(0.1, 0.1, 0.1, 0.5)

    -- Bag Slots
    panel.bags = {}

    for idx = 0, 4 do
        local bag = CreateFrame("Button", nil, panel)
        bag:SetSize(SLOT_SIZE * 2, SLOT_SIZE * 2)
        self:SetupBagButton(bag, idx)
        bag:SetPoint("TOPLEFT", panel, "TOPLEFT",
            idx * (SLOT_SIZE * 2 + SLOT_SPACING) + 5, -5)

        panel.bags[idx] = bag
    end

    return panel
end

function CattosShuffle:SetupSlotButton(button, slotIndex, slotData)
    button.slotIndex = slotIndex
    button.slotData = slotData

    -- Character Panel style slot background
    button:SetBackdrop({
        bgFile = "Interface/Paperdoll/UI-PaperDoll-Slot",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = false,
        tileSize = 32,
        edgeSize = 10,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    button:SetBackdropColor(0.2, 0.2, 0.2, 1)
    button:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

    -- Slot background texture (wie im Character Panel)
    button.slotBG = button:CreateTexture(nil, "BACKGROUND")
    button.slotBG:SetPoint("CENTER")
    button.slotBG:SetSize(SLOT_SIZE-4, SLOT_SIZE-4)

    -- Setze die richtige Slot-Textur basierend auf dem Slot-Typ
    local slotTextures = {
        [1] = "Interface\\Paperdoll\\UI-PaperDoll-Slot-Head",
        [2] = "Interface\\Paperdoll\\UI-PaperDoll-Slot-Neck",
        [3] = "Interface\\Paperdoll\\UI-PaperDoll-Slot-Shoulder",
        [4] = "Interface\\Paperdoll\\UI-PaperDoll-Slot-Shirt",
        [5] = "Interface\\Paperdoll\\UI-PaperDoll-Slot-Chest",
        [6] = "Interface\\Paperdoll\\UI-PaperDoll-Slot-Waist",
        [7] = "Interface\\Paperdoll\\UI-PaperDoll-Slot-Legs",
        [8] = "Interface\\Paperdoll\\UI-PaperDoll-Slot-Feet",
        [9] = "Interface\\Paperdoll\\UI-PaperDoll-Slot-Wrists",
        [10] = "Interface\\Paperdoll\\UI-PaperDoll-Slot-Hands",
        [11] = "Interface\\Paperdoll\\UI-PaperDoll-Slot-Finger",
        [12] = "Interface\\Paperdoll\\UI-PaperDoll-Slot-Finger",
        [13] = "Interface\\Paperdoll\\UI-PaperDoll-Slot-Trinket",
        [14] = "Interface\\Paperdoll\\UI-PaperDoll-Slot-Trinket",
        [15] = "Interface\\Paperdoll\\UI-PaperDoll-Slot-Chest", -- Back uses chest texture
        [16] = "Interface\\Paperdoll\\UI-PaperDoll-Slot-MainHand",
        [17] = "Interface\\Paperdoll\\UI-PaperDoll-Slot-SecondaryHand",
        [18] = "Interface\\Paperdoll\\UI-PaperDoll-Slot-Ranged",
        [19] = "Interface\\Paperdoll\\UI-PaperDoll-Slot-Tabard",
        [0] = "Interface\\Paperdoll\\UI-PaperDoll-Slot-Ammo"
    }

    button.slotBG:SetTexture(slotTextures[slotIndex] or "Interface\\Paperdoll\\UI-Backpack-EmptySlot")
    button.slotBG:SetVertexColor(0.5, 0.5, 0.5, 0.7)

    -- Icon with proper inset
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetPoint("TOPLEFT", 3, -3)
    button.icon:SetPoint("BOTTOMRIGHT", -3, 3)
    button.icon:SetTexture("Interface/ICONS/INV_Misc_QuestionMark")
    button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- Remove icon borders

    -- Quality border (thicker and more visible)
    button.border = button:CreateTexture(nil, "BORDER")  -- Changed to BORDER layer (behind ARTWORK)
    button.border:SetSize(SLOT_SIZE + 16, SLOT_SIZE + 16)  -- Increased size for better visibility
    button.border:SetPoint("CENTER")
    button.border:SetTexture("Interface/Buttons/UI-ActionButton-Border")
    button.border:SetVertexColor(0.5, 0.5, 0.5, 0.5)
    button.border:SetBlendMode("ADD")
    button.border:Hide()  -- Initially hidden

    -- Highlight with glow effect (Character Panel style)
    button.highlight = button:CreateTexture(nil, "OVERLAY")
    button.highlight:SetAllPoints()
    button.highlight:SetTexture("Interface/Paperdoll/UI-Character-Tab-Highlight")
    button.highlight:SetBlendMode("ADD")
    button.highlight:SetAlpha(0)
    button.highlight:Hide()

    -- Winner highlight with sparkle
    button.winner = button:CreateTexture(nil, "OVERLAY")
    button.winner:SetPoint("TOPLEFT", -5, 5)
    button.winner:SetPoint("BOTTOMRIGHT", 5, -5)
    button.winner:SetTexture("Interface/TargetingFrame/UI-TargetingFrame-Stealable")
    button.winner:SetVertexColor(0.3, 1, 0.3, 1)  -- Brighter green glow
    button.winner:SetBlendMode("ADD")
    button.winner:Hide()

    -- Cooldown sweep for visual effect during spin
    button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    button.cooldown:SetAllPoints()
    button.cooldown:SetDrawEdge(false)
    button.cooldown:SetDrawBling(false)
    button.cooldown:Hide()

    -- Tooltip with hover effect
    button:SetScript("OnEnter", function(self)
        -- Character Panel style hover
        if self.highlight then
            self.highlight:SetAlpha(0.3)
            self.highlight:Show()
        end

        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if slotData then
            -- Get item info if equipped
            local slotId = GetInventorySlotInfo(slotData.slotId)
            local itemLink = GetInventoryItemLink("player", slotId)
            if itemLink then
                GameTooltip:SetInventoryItem("player", slotId)
            else
                GameTooltip:SetText(slotData.name, 1, 1, 0)
                GameTooltip:AddLine("Kein Item ausgerüstet", 0.5, 0.5, 0.5)
            end
        end
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function(self)
        -- Reset hover effect
        if self.highlight and not CattosShuffle.isSpinning then
            self.highlight:SetAlpha(0)
            self.highlight:Hide()
        end
        GameTooltip:Hide()
    end)

    -- Click handler for choice mode
    button:SetScript("OnClick", function(self)
        if CattosShuffle.choiceMode then
            CattosShuffle:SelectSlot("sheet", slotIndex, slotData.name)
        end
    end)

    return button
end

function CattosShuffle:SetupBagButton(button, bagIndex)
    button.bagIndex = bagIndex

    -- Background
    button.bg = button:CreateTexture(nil, "BACKGROUND")
    button.bg:SetAllPoints()
    button.bg:SetColorTexture(0.2, 0.2, 0.2, 0.5)

    -- Icon
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetSize(SLOT_SIZE * 1.5, SLOT_SIZE * 1.5)
    button.icon:SetPoint("CENTER")

    -- Get the actual bag texture
    local bagTexture = "Interface/ICONS/INV_Misc_Bag_07"  -- Default bag icon
    if bagIndex == 0 then
        -- Backpack always uses the default backpack icon
        bagTexture = "Interface/ICONS/INV_Misc_Bag_08"  -- Backpack icon
    else
        -- Get the actual equipped bag icon
        local bagSlot = 19 + bagIndex  -- Bag slots are 20-23 (bag1-bag4)
        local itemTexture = GetInventoryItemTexture("player", bagSlot)
        if itemTexture then
            bagTexture = itemTexture
        end
    end
    button.icon:SetTexture(bagTexture)

    -- Text
    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    button.text:SetPoint("BOTTOM", button, "BOTTOM", 0, 5)
    button.text:SetText(self.BAG_SLOTS[bagIndex] or L["BAG" .. bagIndex])

    -- Count
    button.count = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    button.count:SetPoint("TOP", button, "TOP", 0, -5)

    -- Spinning glow effect (like equipment slots)
    button.spinGlow = button:CreateTexture(nil, "OVERLAY")
    button.spinGlow:SetPoint("TOPLEFT", -8, 8)
    button.spinGlow:SetPoint("BOTTOMRIGHT", 8, -8)
    button.spinGlow:SetTexture("Interface/TargetingFrame/UI-TargetingFrame-Stealable")
    button.spinGlow:SetVertexColor(1, 1, 0, 1)  -- Bright yellow
    button.spinGlow:SetBlendMode("ADD")
    button.spinGlow:Hide()

    -- Highlight
    button.highlight = button:CreateTexture(nil, "OVERLAY")
    button.highlight:SetAllPoints()
    button.highlight:SetTexture("Interface/Paperdoll/UI-Character-Tab-Highlight")
    button.highlight:SetBlendMode("ADD")
    button.highlight:SetAlpha(0)
    button.highlight:Hide()

    -- Winner highlight (don't show on backpack)
    if bagIndex ~= 0 then
        button.winner = button:CreateTexture(nil, "OVERLAY")
        button.winner:SetPoint("TOPLEFT", -8, 8)
        button.winner:SetPoint("BOTTOMRIGHT", 8, -8)
        button.winner:SetTexture("Interface/TargetingFrame/UI-TargetingFrame-Stealable")
        button.winner:SetVertexColor(0.3, 1, 0.3, 1)  -- Bright green
        button.winner:SetBlendMode("ADD")
        button.winner:Hide()
    else
        -- Create dummy winner for backpack but never show it
        button.winner = button:CreateTexture(nil, "OVERLAY")
        button.winner:Hide()
    end

    -- Click handler for choice mode
    button:SetScript("OnClick", function(self)
        if CattosShuffle.choiceMode then
            CattosShuffle:SelectSlot("bags", bagIndex, CattosShuffle.BAG_SLOTS[bagIndex])
        end
    end)

    return button
end

function CattosShuffle:CreateResultDisplay()
    local display = CreateFrame("Frame", nil, self.frame)
    display:SetPoint("TOP", self.frame, "TOP", 0, -50)
    display:SetSize(200, 30)

    -- Minimalistisches Design ohne Hintergrund
    -- Result Text only
    display.result = display:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    display.result:SetPoint("CENTER", display, "CENTER", 0, 0)
    display.result:SetText("")
    display.result:SetTextColor(1, 0.85, 0)

    return display
end

function CattosShuffle:CreateActionButtons()
    local buttonContainer = CreateFrame("Frame", nil, self.frame)
    buttonContainer:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", 20, 40)
    buttonContainer:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -20, 40)
    buttonContainer:SetHeight(40)

    local buttons = {
        { cmd = "bag-empty", text = L["EMPTY_BAG"], icon = "Interface\\Icons\\INV_Misc_Bag_07", color = {0.6, 1, 1} },  -- Bright cyan
        { cmd = "sheet-rng", text = L["DELETE_ITEM"], icon = "Interface\\Icons\\INV_Misc_Dice_01", color = {1, 0.7, 0.7} },  -- Bright pink-red
        { cmd = "bag-delete", text = L["DELETE_BAG"], icon = "Interface\\Icons\\Ability_Warrior_SunderArmor", color = {1, 0.3, 0.3} },  -- Intense red
        { cmd = "choice", text = L["FREE_CHOICE"], icon = "Interface\\Icons\\Achievement_BG_winWSG", color = {1, 1, 0.3} },  -- Bright gold
    }

    local buttonWidth = (FRAME_WIDTH - 60) / #buttons - 10

    for i, btnData in ipairs(buttons) do
        local btn = CreateFrame("Button", nil, buttonContainer, "BackdropTemplate")
        btn:SetSize(buttonWidth, 38)
        btn:SetPoint("LEFT", buttonContainer, "LEFT", (i-1) * (buttonWidth + 10), 0)

        -- Backdrop with gradient
        btn:SetBackdrop({
            bgFile = "Interface/Tooltips/UI-Tooltip-Background",
            edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
            edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        btn:SetBackdropColor(btnData.color[1] * 0.3, btnData.color[2] * 0.3, btnData.color[3] * 0.3, 0.9)
        btn:SetBackdropBorderColor(btnData.color[1], btnData.color[2], btnData.color[3], 1)

        -- Text with shadow
        local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("CENTER")
        text:SetText(btnData.text)
        text:SetTextColor(btnData.color[1], btnData.color[2], btnData.color[3])
        text:SetShadowOffset(1, -1)
        text:SetShadowColor(0, 0, 0, 1)

        -- Highlight texture
        btn.highlight = btn:CreateTexture(nil, "HIGHLIGHT")
        btn.highlight:SetAllPoints()
        btn.highlight:SetTexture("Interface/Buttons/UI-Common-MouseHilight")
        btn.highlight:SetBlendMode("ADD")
        btn.highlight:SetAlpha(0.3)

        -- Hover effects
        btn:SetScript("OnEnter", function(self)
            self:SetBackdropBorderColor(1, 1, 0.5, 1)  -- Brighter yellow hover
            text:SetTextColor(1, 1, 1)
        end)

        btn:SetScript("OnLeave", function(self)
            self:SetBackdropBorderColor(btnData.color[1], btnData.color[2], btnData.color[3], 1)
            text:SetTextColor(btnData.color[1], btnData.color[2], btnData.color[3])
        end)

        btn:SetScript("OnClick", function()
            local target = CattosShuffle.ACTIONS[btnData.cmd].target
            if btnData.cmd == "choice" then
                CattosShuffle:HandleFreeChoice()
            elseif target == "sheet" then
                CattosShuffle:StartSpin("sheet", btnData.cmd)
            else
                CattosShuffle:StartSpin("bags", btnData.cmd)
            end
        end)
    end
end

-- History Frame entfernt

function CattosShuffle:RefreshUI()
    self:RefreshEquipment()
    self:RefreshBags()
    self:RefreshBagIcons()  -- Add this to update bag icons
end

function CattosShuffle:RefreshEquipment()
    if not self.equipmentPanel then return end

    local equipped = self:GetEquippedSlots()

    for idx, slot in pairs(self.equipmentPanel.slots) do
        if equipped[idx] then
            local item = equipped[idx]
            -- Zeige das Item-Icon
            slot.icon:SetTexture(item.icon or "Interface/ICONS/INV_Misc_QuestionMark")
            slot.icon:Show()

            -- Verstecke den Slot-Hintergrund wenn ein Item da ist
            if slot.slotBG then
                slot.slotBG:Hide()
            end

            -- Color border by quality
            local color = self.QUALITY_COLORS[item.quality] or self.QUALITY_COLORS[1]
            -- Make colors more vibrant (multiply by 1.5 for glow effect)
            local glowFactor = 1.5
            slot.border:SetVertexColor(math.min(1, color.r * glowFactor), math.min(1, color.g * glowFactor), math.min(1, color.b * glowFactor), 1)
            slot.border:Show()  -- Show the border when item exists
            slot:SetBackdropBorderColor(math.min(1, color.r * glowFactor), math.min(1, color.g * glowFactor), math.min(1, color.b * glowFactor), 1)
        else
            -- Kein Item - zeige Slot-Hintergrund
            slot.icon:Hide()
            if slot.slotBG then
                slot.slotBG:Show()
            end
            slot.border:Hide()  -- Hide border when no item
            slot:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.5)
        end
    end

    -- Update 3D Model
    if self.equipmentPanel.modelFrame then
        self.equipmentPanel.modelFrame:SetUnit("player")
        -- Refresh the model to show equipment changes
        self.equipmentPanel.modelFrame:RefreshUnit()
    end
end

function CattosShuffle:RefreshBagIcons()
    if not self.bagPanel or not self.bagPanel.bags then return end

    for bagIndex = 0, 4 do
        local bag = self.bagPanel.bags[bagIndex]
        if bag then
            local bagTexture = "Interface/ICONS/INV_Misc_Bag_07"  -- Default bag icon
            if bagIndex == 0 then
                -- Backpack always uses the default backpack icon
                bagTexture = "Interface/ICONS/INV_Misc_Bag_08"  -- Backpack icon
            else
                -- Get the actual equipped bag icon
                -- Classic Era: Bag slots are inventory slots 20-23
                -- Bag 1 = slot 20, Bag 2 = slot 21, Bag 3 = slot 22, Bag 4 = slot 23
                local bagSlot = 19 + bagIndex  -- This gives us 20-23 for bags 1-4
                local itemTexture = GetInventoryItemTexture("player", bagSlot)
                if itemTexture then
                    bagTexture = itemTexture
                end
            end
            bag.icon:SetTexture(bagTexture)
        end
    end
end

function CattosShuffle:RefreshBags()
    if not self.bagPanel then return end

    local bags = self:GetAvailableBags()

    for idx, bagBtn in pairs(self.bagPanel.bags) do
        if bags[idx] then
            local bag = bags[idx]
            bagBtn.count:SetText(bag.items .. "/" .. bag.slots)

            if bag.isEmpty then
                bagBtn.icon:SetDesaturated(true)
                bagBtn.count:SetTextColor(0.5, 0.5, 0.5)
            else
                bagBtn.icon:SetDesaturated(false)
                bagBtn.count:SetTextColor(1, 1, 1)
            end
        else
            bagBtn.count:SetText("0/0")
            bagBtn.icon:SetDesaturated(true)
        end
    end
end

function CattosShuffle:UpdateResultDisplay(result)
    -- Zeige Stats Loss Popup für verlorene Items
    if result.target == "sheet" and result.winner then
        self:ShowStatsLossPopup(result.winner, result.winnerName)
    elseif result.target == "bags" and result.action == "bag-empty" and result.winner then
        -- Zeige Tascheninhalt bei "Tasche leeren"
        self:ShowBagContentsPopup(result.winner)
    end
end

function CattosShuffle:ShowStatsLossPopup(slotIndex, itemName)
    -- Erstelle oder aktualisiere das Stats Loss Popup
    if not self.statsLossFrame then
        local frame = CreateFrame("Frame", nil, self.frame, "BackdropTemplate")
        frame:SetSize(280, 250)
        frame:SetPoint("CENTER", self.frame, "CENTER", 0, 100)
        frame:SetBackdrop({
            bgFile = "Interface/DialogFrame/UI-DialogBox-Background-Dark",
            edgeFile = "Interface/DialogFrame/UI-DialogBox-Gold-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 32,
            insets = { left = 11, right = 11, top = 11, bottom = 11 }
        })
        frame:SetBackdropColor(0.2, 0, 0, 0.95)
        frame:SetBackdropBorderColor(1, 0.2, 0.2, 1)
        frame:SetFrameStrata("DIALOG")
        frame:SetFrameLevel(100)

        -- Skull Icon
        frame.skull = frame:CreateTexture(nil, "OVERLAY")
        frame.skull:SetSize(32, 32)
        frame.skull:SetPoint("TOP", frame, "TOP", 0, -15)
        frame.skull:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Skull")

        -- Titel mit Animation
        frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        frame.title:SetPoint("TOP", frame.skull, "BOTTOM", 0, -5)
        frame.title:SetText(CattosShuffle.L["ITEM_LOST"])
        frame.title:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")

        -- Item Name
        frame.itemName = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        frame.itemName:SetPoint("TOP", frame.title, "BOTTOM", 0, -10)

        -- Stats Text
        frame.statsText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame.statsText:SetPoint("TOP", frame.itemName, "BOTTOM", 0, -15)
        frame.statsText:SetPoint("LEFT", frame, "LEFT", 20, 0)
        frame.statsText:SetPoint("RIGHT", frame, "RIGHT", -20, 0)
        frame.statsText:SetJustifyH("CENTER")
        frame.statsText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")

        -- Close Button
        frame.closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
        frame.closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
        frame.closeBtn:SetSize(24, 24)
        frame.closeBtn:SetScript("OnClick", function()
            if self.statsLossTimer then
                self.statsLossTimer:Cancel()
            end
            frame:Hide()
        end)

        -- OK Button zum Bestätigen
        frame.okBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
        frame.okBtn:SetPoint("BOTTOM", frame, "BOTTOM", 0, 20)
        frame.okBtn:SetSize(100, 25)
        frame.okBtn:SetText("OK")
        frame.okBtn:SetScript("OnClick", function()
            if self.statsLossTimer then
                self.statsLossTimer:Cancel()
            end
            frame:Hide()
        end)

        -- Keine Animation mehr - direkt anzeigen

        self.statsLossFrame = frame
    end

    -- Hole Item-Stats
    local slotId = GetInventorySlotInfo(self.SHEET_SLOTS[slotIndex].slotId)
    local itemLink = GetInventoryItemLink("player", slotId)

    if itemLink then
        -- Zeige Item Name mit Icon
        self.statsLossFrame.itemName:SetText(itemLink)

        -- Hole und zeige Stats
        local stats = self:GetItemStats(itemLink)
        local statsString = ""
        local hasStats = false

        -- Sortiere Stats für bessere Anzeige
        local statOrder = {"Rüstung", "Stärke", "Beweglichkeit", "Ausdauer", "Intelligenz", "Willenskraft"}

        for _, statName in ipairs(statOrder) do
            if stats[statName] then
                statsString = statsString .. string.format("|cffff6666- %d %s|r\n", stats[statName], statName)
                hasStats = true
            end
        end

        -- Andere Stats die nicht in der Liste sind
        for stat, value in pairs(stats) do
            local found = false
            for _, orderedStat in ipairs(statOrder) do
                if orderedStat == stat then found = true break end
            end
            if not found then
                statsString = statsString .. string.format("|cffff6666- %d %s|r\n", value, stat)
                hasStats = true
            end
        end

        if not hasStats then
            local L = CattosShuffle.L
            statsString = "|cffffcc00" .. L["NO_STATS"] .. "|r"
        end

        self.statsLossFrame.statsText:SetText(statsString)

        -- Frame zeigen und Animation abspielen
        self.statsLossFrame:SetAlpha(1)  -- Direkt sichtbar machen
        self.statsLossFrame:Show()
        self.statsLossFrame:SetFrameStrata("TOOLTIP")  -- Ganz oben anzeigen
        self.statsLossFrame:Raise()

        -- Sound abspielen für Drama
        PlaySound(SOUNDKIT.RAID_WARNING or 8959, "Master")

        -- KEIN Auto-Hide - Spieler muss manuell schließen
        -- Oder optional sehr lange Zeit (30 Sekunden)
        if self.statsLossTimer then
            self.statsLossTimer:Cancel()
        end

        -- Optional: Auto-Hide nach 30 Sekunden für Cleanup
        self.statsLossTimer = C_Timer.NewTimer(30, function()
            if self.statsLossFrame and self.statsLossFrame:IsShown() then
                self.statsLossFrame:Hide()
            end
        end)
    end
end

function CattosShuffle:ShowBagContentsPopup(bagIndex)
    -- Validate bag index
    if not bagIndex then
        local L = CattosShuffle.L
        print(L["ERROR_BAG_INDEX"])
        return
    end

    -- Erstelle oder aktualisiere das Bag Contents Popup
    if not self.bagContentsFrame then
        local frame = CreateFrame("Frame", nil, self.frame, "BackdropTemplate")
        frame:SetSize(320, 400)
        frame:SetPoint("CENTER", self.frame, "CENTER", 0, 50)
        frame:SetBackdrop({
            bgFile = "Interface/DialogFrame/UI-DialogBox-Background-Dark",
            edgeFile = "Interface/DialogFrame/UI-DialogBox-Gold-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 32,
            insets = { left = 11, right = 11, top = 11, bottom = 11 }
        })
        frame:SetBackdropColor(0.15, 0, 0.15, 0.95)
        frame:SetBackdropBorderColor(1, 0.7, 0, 1)
        frame:SetFrameStrata("TOOLTIP")
        frame:SetFrameLevel(100)

        -- Bag Icon
        frame.bagIcon = frame:CreateTexture(nil, "OVERLAY")
        frame.bagIcon:SetSize(32, 32)
        frame.bagIcon:SetPoint("TOP", frame, "TOP", 0, -15)
        frame.bagIcon:SetTexture("Interface\\Icons\\INV_Misc_Bag_07")  -- Will be updated dynamically

        -- Titel
        frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        frame.title:SetPoint("TOP", frame.bagIcon, "BOTTOM", 0, -5)
        frame.title:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")

        -- Scroll Frame für Items
        local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -100)  -- Increased from -80 to -100 for two-line title
        scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -35, 60)

        local scrollChild = CreateFrame("Frame")
        scrollChild:SetSize(260, 400)
        scrollFrame:SetScrollChild(scrollChild)
        frame.scrollChild = scrollChild

        -- Close Button
        frame.closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
        frame.closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
        frame.closeBtn:SetSize(24, 24)
        frame.closeBtn:SetScript("OnClick", function()
            frame:Hide()
        end)

        -- OK Button
        frame.okBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
        frame.okBtn:SetPoint("BOTTOM", frame, "BOTTOM", 0, 20)
        frame.okBtn:SetSize(100, 25)
        frame.okBtn:SetText("OK")
        frame.okBtn:SetScript("OnClick", function()
            frame:Hide()
        end)

        self.bagContentsFrame = frame
    end

    -- Hole Tascheninhalt
    local L = CattosShuffle.L
    local bagName = self.BAG_SLOTS[bagIndex] or (L["BAG1"]:gsub("1", tostring(bagIndex)))
    self.bagContentsFrame.title:SetText(L["BAG_EMPTIED"] .. "\n" .. bagName)

    -- Update bag icon to show the actual bag
    local bagTexture = "Interface/ICONS/INV_Misc_Bag_07"  -- Default bag icon
    if bagIndex == 0 then
        -- Backpack always uses the default backpack icon
        bagTexture = "Interface/ICONS/INV_Misc_Bag_08"  -- Backpack icon
    else
        -- Get the actual equipped bag icon
        local bagSlot = 19 + bagIndex  -- Bag slots are 20-23 (bag1-bag4)
        local itemTexture = GetInventoryItemTexture("player", bagSlot)
        if itemTexture then
            bagTexture = itemTexture
        end
    end
    self.bagContentsFrame.bagIcon:SetTexture(bagTexture)

    -- Clear old items completely
    local children = {self.bagContentsFrame.scrollChild:GetChildren()}
    for _, child in ipairs(children) do
        child:Hide()
        child:SetParent(nil)
        child = nil
    end

    -- Also clear any FontStrings (text elements)
    local regions = {self.bagContentsFrame.scrollChild:GetRegions()}
    for _, region in ipairs(regions) do
        region:Hide()
        region:SetParent(nil)
        region = nil
    end

    -- Liste Items in der Tasche auf
    local totalItemCount = 0  -- Total count including stacks
    local slotCount = 0       -- Number of occupied slots
    local yOffset = 0

    -- Classic Era verwendet C_Container API
    local numSlots = C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerNumSlots(bagIndex) or 0

    if numSlots == 0 then
        local L = CattosShuffle.L
        print(string.format(L["ERROR_BAG_EMPTY"], bagIndex))
        return
    end

    for slot = 1, numSlots do
        local itemInfo = C_Container.GetContainerItemInfo(bagIndex, slot)

        if itemInfo then
            slotCount = slotCount + 1
            -- Count the actual number of items including stack size
            local stackSize = itemInfo.stackCount or 1
            totalItemCount = totalItemCount + stackSize

            -- Create item frame
            local itemFrame = CreateFrame("Frame", nil, self.bagContentsFrame.scrollChild)
            itemFrame:SetSize(240, 30)
            itemFrame:SetPoint("TOP", self.bagContentsFrame.scrollChild, "TOP", 0, -yOffset)

            -- Item Icon
            local icon = itemFrame:CreateTexture(nil, "ARTWORK")
            icon:SetSize(28, 28)
            icon:SetPoint("LEFT", itemFrame, "LEFT", 0, 0)
            icon:SetTexture(itemInfo.iconFileID)

            -- Item Name and Count
            local text = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            text:SetPoint("LEFT", icon, "RIGHT", 5, 0)

            if itemInfo.hyperlink then
                local itemName = GetItemInfo(itemInfo.hyperlink) or "Unbekanntes Item"
                if itemInfo.stackCount and itemInfo.stackCount > 1 then
                    text:SetText(string.format("|cffff6666%s x%d|r", itemName, itemInfo.stackCount))
                else
                    text:SetText(string.format("|cffff6666%s|r", itemName))
                end
            else
                text:SetText("|cffff6666Unbekanntes Item|r")
            end

            yOffset = yOffset + 32
        end
    end

    -- Zeige Anzahl der Items
    local L = CattosShuffle.L
    if slotCount == 0 then
        -- Create a frame to hold the text so it gets cleaned up properly
        local textFrame = CreateFrame("Frame", nil, self.bagContentsFrame.scrollChild)
        textFrame:SetSize(240, 30)
        textFrame:SetPoint("TOP", self.bagContentsFrame.scrollChild, "TOP", 0, -10)

        local emptyText = textFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        emptyText:SetPoint("CENTER")
        emptyText:SetText("|cff999999" .. L["BAG_WAS_EMPTY"] .. "|r")
    else
        -- Create a frame to hold the total text so it gets cleaned up properly
        local totalFrame = CreateFrame("Frame", nil, self.bagContentsFrame.scrollChild)
        totalFrame:SetSize(240, 30)
        totalFrame:SetPoint("TOP", self.bagContentsFrame.scrollChild, "TOP", 0, -yOffset - 10)

        local totalText = totalFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        totalText:SetPoint("CENTER")
        totalText:SetText(string.format(L["TOTAL_ITEMS_LOST"], totalItemCount))
    end

    self.bagContentsFrame:Show()
    self.bagContentsFrame:Raise()

    -- Sound für Drama
    PlaySound(SOUNDKIT.RAID_WARNING or 8959, "Master")
end

function CattosShuffle:GetItemStats(itemLink)
    local stats = {}

    -- Parse Item Stats aus Tooltip
    local scanner = CreateFrame("GameTooltip", "CattosShuffleScanner", nil, "GameTooltipTemplate")
    scanner:SetOwner(WorldFrame, "ANCHOR_NONE")
    scanner:SetHyperlink(itemLink)

    for i = 1, scanner:NumLines() do
        local text = _G["CattosShuffleScannerTextLeft" .. i]:GetText()
        if text then
            -- Suche nach Stats wie "+15 Stärke", "+20 Ausdauer", etc.
            local value, stat = string.match(text, "%+(%d+) (.+)")
            if value and stat then
                stats[stat] = tonumber(value)
            end

            -- Verschiedene Rüstungs-Patterns für Classic (flexibler)
            -- Kann am Anfang oder irgendwo in der Zeile stehen
            local armor = string.match(text, "(%d+) [Aa]rmor")
            if not armor then
                armor = string.match(text, "(%d+) Rüstung")
            end
            if armor and tonumber(armor) > 0 then
                stats["Rüstung"] = tonumber(armor)
            end

            -- Schaden bei Waffen
            local minDmg, maxDmg = string.match(text, "(%d+) %- (%d+) Schaden")
            if minDmg and maxDmg then
                stats["Schaden"] = minDmg .. "-" .. maxDmg
            end

            -- DPS
            local dps = string.match(text, "%((%d+%.?%d*) Schaden pro Sekunde%)")
            if dps then
                stats["DPS"] = dps
            end
        end
    end

    return stats
end

function CattosShuffle:EnableChoiceMode()
    self.choiceMode = true
    local L = CattosShuffle.L
    print(L["CHOICE_MODE_ACTIVE"])
end

function CattosShuffle:SelectSlot(target, slotIndex, slotName)
    if not self.choiceMode then return end

    self.choiceMode = false

    local result = {
        timestamp = time(),
        action = "choice",
        target = target,
        winner = slotIndex,
        winnerName = slotName,
    }

    -- Add to history
    table.insert(self.history, 1, result)
    if #self.history > 20 then
        table.remove(self.history)
    end

    -- Save
    CattosShuffleDB.history = self.history

    -- Update display
    if result.target == "sheet" and result.winner then
        self:ShowStatsLossPopup(result.winner, result.winnerName)
    end

    local L = CattosShuffle.L
    local actionInfo = CattosShuffle.ACTIONS["choice"]
    print(string.format(L["RESULT"], actionInfo.description, actionInfo.price, slotName))

    -- Highlight winner
    self:HighlightWinner(target, slotIndex)
end

function CattosShuffle:ClearAllHighlights()
    -- Clear all highlights from equipment slots
    if self.equipmentPanel and self.equipmentPanel.slots then
        for _, slot in pairs(self.equipmentPanel.slots) do
            if slot.winner then
                slot.winner:Hide()
            end
            if slot.highlight then
                slot.highlight:Hide()
                slot.highlight:SetAlpha(0)
            end
            -- Reset border color
            slot:SetBackdropBorderColor(0.3, 0.25, 0.35, 1)
        end
    end

    -- Clear all highlights from bags
    if self.bagPanel and self.bagPanel.bags then
        for i = 0, 4 do
            local bag = self.bagPanel.bags[i]
            if bag then
                -- Hide the regular winner glow
                if bag.winner then
                    bag.winner:Hide()
                end

                -- Hide green empty highlight
                if bag.emptyHighlight then
                    bag.emptyHighlight:Hide()
                end
                if bag.greenPulse then
                    bag.greenPulse:Stop()
                end

                -- Hide red delete highlight
                if bag.deleteHighlight then
                    bag.deleteHighlight:Hide()
                end
                if bag.redPulse then
                    bag.redPulse:Stop()
                end

                -- Reset icon color
                if bag.icon then
                    bag.icon:SetVertexColor(1, 1, 1)
                end
            end
        end
    end
end

function CattosShuffle:ClearBagHighlights()
    -- Legacy function - now calls the comprehensive clear function
    self:ClearAllHighlights()
end

function CattosShuffle:HighlightBagGreen(bagIndex)
    -- Mark backpack green for emptying
    if self.bagPanel and self.bagPanel.bags[bagIndex] then
        local bag = self.bagPanel.bags[bagIndex]

        -- Create or show green highlight for "must empty"
        if not bag.emptyHighlight then
            bag.emptyHighlight = bag:CreateTexture(nil, "OVERLAY")
            bag.emptyHighlight:SetPoint("TOPLEFT", -8, 8)
            bag.emptyHighlight:SetPoint("BOTTOMRIGHT", 8, -8)
            bag.emptyHighlight:SetTexture("Interface/TargetingFrame/UI-TargetingFrame-Stealable")
            bag.emptyHighlight:SetVertexColor(0, 1, 0, 1)  -- Bright green
            bag.emptyHighlight:SetBlendMode("ADD")
        end
        bag.emptyHighlight:Show()

        -- Pulse animation
        if not bag.greenPulse then
            bag.greenPulse = bag:CreateAnimationGroup()
            local pulse1 = bag.greenPulse:CreateAnimation("Scale")
            pulse1:SetScale(1.15, 1.15)
            pulse1:SetDuration(0.3)
            pulse1:SetOrder(1)

            local pulse2 = bag.greenPulse:CreateAnimation("Scale")
            pulse2:SetScale(0.87, 0.87)
            pulse2:SetDuration(0.3)
            pulse2:SetOrder(2)

            bag.greenPulse:SetLooping("REPEAT")
        end
        bag.greenPulse:Play()
    end
end

function CattosShuffle:HighlightBagRed(bagIndex)
    -- Mark bag red for deletion
    if self.bagPanel and self.bagPanel.bags[bagIndex] then
        local bag = self.bagPanel.bags[bagIndex]

        -- Create or show red highlight for "will be deleted"
        if not bag.deleteHighlight then
            bag.deleteHighlight = bag:CreateTexture(nil, "OVERLAY")
            bag.deleteHighlight:SetPoint("TOPLEFT", -8, 8)
            bag.deleteHighlight:SetPoint("BOTTOMRIGHT", 8, -8)
            bag.deleteHighlight:SetTexture("Interface/TargetingFrame/UI-TargetingFrame-Stealable")
            bag.deleteHighlight:SetVertexColor(1, 0, 0, 1)  -- Bright red
            bag.deleteHighlight:SetBlendMode("ADD")
        end
        bag.deleteHighlight:Show()

        -- Pulse animation
        if not bag.redPulse then
            bag.redPulse = bag:CreateAnimationGroup()
            local pulse1 = bag.redPulse:CreateAnimation("Scale")
            pulse1:SetScale(1.15, 1.15)
            pulse1:SetDuration(0.3)
            pulse1:SetOrder(1)

            local pulse2 = bag.redPulse:CreateAnimation("Scale")
            pulse2:SetScale(0.87, 0.87)
            pulse2:SetDuration(0.3)
            pulse2:SetOrder(2)

            bag.redPulse:SetLooping("REPEAT")
        end
        bag.redPulse:Play()

        -- Make icon red tinted
        if bag.icon then
            bag.icon:SetVertexColor(2, 0.5, 0.5)  -- Red tint
        end
    end
end

function CattosShuffle:HighlightWinner(target, slotIndex)
    -- Clear all highlights first
    if self.equipmentPanel then
        for _, slot in pairs(self.equipmentPanel.slots) do
            slot.winner:Hide()
            slot.highlight:Hide()
            slot:SetBackdropBorderColor(0.3, 0.25, 0.35, 1)
            if slot.cooldown then
                slot.cooldown:Hide()
            end
        end
    end
    if self.bagPanel then
        for _, bag in pairs(self.bagPanel.bags) do
            bag.winner:Hide()
            bag.highlight:Hide()
        end
    end

    -- Show winner with epic effects
    if target == "sheet" and self.equipmentPanel.slots[slotIndex] then
        local slot = self.equipmentPanel.slots[slotIndex]

        -- Show winner sparkle
        slot.winner:Show()

        -- Pulse Animation für den Gewinner-Slot
        if not slot.pulseAnim then
            slot.pulseAnim = slot:CreateAnimationGroup()
            local pulse1 = slot.pulseAnim:CreateAnimation("Scale")
            pulse1:SetScale(1.15, 1.15)
            pulse1:SetDuration(0.2)
            pulse1:SetOrder(1)

            local pulse2 = slot.pulseAnim:CreateAnimation("Scale")
            pulse2:SetScale(0.87, 0.87)  -- 1/1.15 = 0.87 um zurück zu skalieren
            pulse2:SetDuration(0.2)
            pulse2:SetOrder(2)

            slot.pulseAnim:SetLooping("REPEAT")
        end

        -- Epic bright red glow border für verlorenes Item
        slot:SetBackdropBorderColor(1, 0.2, 0.2, 1)  -- Brighter red

        -- Flash effect mit bright Rot
        slot.icon:SetVertexColor(2, 0.5, 0.5)  -- More intense red glow

        -- Starte Pulse Animation
        slot.pulseAnim:Play()

        -- Stoppe Animation nach 2 Sekunden
        C_Timer.After(2, function()
            if slot.pulseAnim then
                slot.pulseAnim:Stop()
            end
            if slot.icon then
                slot.icon:SetVertexColor(1, 1, 1)
            end
            slot:SetBackdropBorderColor(1, 0, 0, 0.5)
        end)

    elseif target == "bags" and self.bagPanel.bags[slotIndex] then
        self.bagPanel.bags[slotIndex].winner:Show()
    end
end

function CattosShuffle:ShowSpinHighlight(target, slotIndex)
    -- Clear highlights and reset effects
    if self.equipmentPanel then
        for _, slot in pairs(self.equipmentPanel.slots) do
            slot.highlight:Hide()
            slot.highlight:SetAlpha(0)
            -- Hide the green winner texture
            if slot.winner then
                slot.winner:Hide()
            end
            -- Hide the yellow spin glow
            if slot.spinGlow then
                slot.spinGlow:Hide()
            end
            -- Stop pulse animation
            if slot.spinPulse then
                slot.spinPulse:Stop()
            end
            slot:SetBackdropBorderColor(0.3, 0.25, 0.35, 1)
            -- Reset icon color to normal
            if slot.icon then
                slot.icon:SetVertexColor(1, 1, 1)
            end
            if slot.cooldown then
                slot.cooldown:Clear()
                slot.cooldown:Hide()
            end
        end
    end
    if self.bagPanel then
        for _, bag in pairs(self.bagPanel.bags) do
            bag.highlight:Hide()
            bag.highlight:SetAlpha(0)
            -- Hide the yellow spin glow
            if bag.spinGlow then
                bag.spinGlow:Hide()
            end
            -- Stop pulse animation
            if bag.spinPulse then
                bag.spinPulse:Stop()
            end
            -- Reset icon color
            if bag.icon then
                bag.icon:SetVertexColor(1, 1, 1)
            end
        end
    end

    -- Show current highlight with enhanced effects
    if target == "sheet" and self.equipmentPanel.slots[slotIndex] then
        local slot = self.equipmentPanel.slots[slotIndex]

        -- Show yellow sparkle effect like the green winner effect
        if not slot.spinGlow then
            slot.spinGlow = slot:CreateTexture(nil, "OVERLAY")
            slot.spinGlow:SetPoint("TOPLEFT", -5, 5)
            slot.spinGlow:SetPoint("BOTTOMRIGHT", 5, -5)
            slot.spinGlow:SetTexture("Interface/TargetingFrame/UI-TargetingFrame-Stealable")
            slot.spinGlow:SetVertexColor(1, 1, 0, 1)  -- Bright yellow
            slot.spinGlow:SetBlendMode("ADD")
        end
        slot.spinGlow:Show()

        -- Glowing highlight mit Fade
        slot.highlight:Show()
        slot.highlight:SetAlpha(1)

        -- Bright golden border glow während Spin
        slot:SetBackdropBorderColor(1, 1, 0, 1)  -- Full bright yellow

        -- Pulse Animation für den Spin-Slot (like winner)
        if not slot.spinPulse then
            slot.spinPulse = slot:CreateAnimationGroup()
            local pulse1 = slot.spinPulse:CreateAnimation("Scale")
            pulse1:SetScale(1.1, 1.1)
            pulse1:SetDuration(0.1)
            pulse1:SetOrder(1)

            local pulse2 = slot.spinPulse:CreateAnimation("Scale")
            pulse2:SetScale(0.91, 0.91)  -- 1/1.1 = 0.91 to scale back
            pulse2:SetDuration(0.1)
            pulse2:SetOrder(2)
        end
        slot.spinPulse:Play()

        -- Icon bright yellow glow effect
        slot.icon:SetVertexColor(1.8, 1.8, 0.8)  -- Yellow tinted glow

    elseif target == "bags" and self.bagPanel.bags[slotIndex] then
        local bag = self.bagPanel.bags[slotIndex]

        -- Show yellow sparkle effect like equipment
        if bag.spinGlow then
            bag.spinGlow:Show()
        end

        -- Glowing highlight
        bag.highlight:Show()
        bag.highlight:SetAlpha(1)

        -- Pulse animation for bags
        if not bag.spinPulse then
            bag.spinPulse = bag:CreateAnimationGroup()
            local pulse1 = bag.spinPulse:CreateAnimation("Scale")
            pulse1:SetScale(1.1, 1.1)
            pulse1:SetDuration(0.1)
            pulse1:SetOrder(1)

            local pulse2 = bag.spinPulse:CreateAnimation("Scale")
            pulse2:SetScale(0.91, 0.91)
            pulse2:SetDuration(0.1)
            pulse2:SetOrder(2)
        end
        bag.spinPulse:Play()

        -- Make icon glow
        if bag.icon then
            bag.icon:SetVertexColor(1.8, 1.8, 0.8)  -- Yellow tinted glow
        end
    end
end