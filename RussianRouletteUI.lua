-- CattosShuffle - Russian Roulette Slot Machine UI
-- Author: Amke & Assistant
-- Version: 1.0.0

local addonName, CattosShuffle = ...
local L = CattosShuffle.L
local RR = CattosShuffle.RussianRoulette

-- Create the main slot machine frame
function RR:CreateSlotMachineFrame()
    if self.slotFrame then return self.slotFrame end

    -- Main frame
    local frame = CreateFrame("Frame", "CattosRussianRouletteFrame", UIParent, "BasicFrameTemplate")
    frame:SetSize(400, 300)
    frame:SetPoint("CENTER", 0, 100)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("HIGH")
    frame:Hide()

    -- Title
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("TOP", frame, "TOP", 0, -35)
    frame.title:SetText("|cffff0000Russian Roulette Slots|r")

    -- Background
    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints(frame)
    frame.bg:SetColorTexture(0, 0, 0, 0.8)

    -- Create slot reels
    frame.slots = {}
    local slotWidth = 100
    local slotHeight = 120
    local slotSpacing = 20

    for i = 1, 3 do
        local slot = CreateFrame("Frame", nil, frame)
        slot:SetSize(slotWidth, slotHeight)

        local xOffset = (i - 2) * (slotWidth + slotSpacing)
        slot:SetPoint("CENTER", frame, "CENTER", xOffset, 20)

        -- Slot background
        slot.bg = slot:CreateTexture(nil, "BACKGROUND")
        slot.bg:SetAllPoints(slot)
        slot.bg:SetColorTexture(0.1, 0.1, 0.1, 0.9)

        -- Slot border
        slot.border = CreateFrame("Frame", nil, slot, "BackdropTemplate")
        slot.border:SetAllPoints(slot)
        slot.border:SetBackdrop({
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 2,
        })
        slot.border:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

        -- Quality display (3 rows for spinning effect)
        slot.qualities = {}
        for j = 1, 3 do
            local qualityFrame = CreateFrame("Frame", nil, slot)
            qualityFrame:SetSize(slotWidth - 10, 35)
            qualityFrame:SetPoint("TOP", slot, "TOP", 0, -5 - ((j-1) * 40))

            qualityFrame.text = qualityFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            qualityFrame.text:SetAllPoints(qualityFrame)
            qualityFrame.text:SetText("")

            qualityFrame.icon = qualityFrame:CreateTexture(nil, "ARTWORK")
            qualityFrame.icon:SetSize(30, 30)
            qualityFrame.icon:SetPoint("CENTER", qualityFrame, "CENTER", 0, 0)
            qualityFrame.icon:Hide()

            slot.qualities[j] = qualityFrame
        end

        -- Main display (center)
        slot.mainDisplay = slot.qualities[2]

        frame.slots[i] = slot
    end

    -- Spin button
    frame.spinButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    frame.spinButton:SetSize(120, 40)
    frame.spinButton:SetPoint("BOTTOM", frame, "BOTTOM", 0, 40)
    frame.spinButton:SetText("SPIN!")
    frame.spinButton:SetScript("OnClick", function()
        RR:StartSpin()
    end)

    -- Info text
    frame.infoText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.infoText:SetPoint("BOTTOM", frame, "BOTTOM", 0, 15)
    frame.infoText:SetText("|cffccccccThree matching qualities = Delete random item!|r")

    -- Back button to return to main UI
    frame.backButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    frame.backButton:SetSize(80, 25)
    frame.backButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -35, -35)
    frame.backButton:SetText("Back")
    frame.backButton:SetScript("OnClick", function()
        frame:Hide()
        if CattosShuffle.frame then
            CattosShuffle.frame:Show()
            CattosShuffle:RefreshUI()
        end
    end)

    -- Statistics
    frame.statsText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.statsText:SetPoint("TOP", frame, "TOP", 0, -55)
    frame.statsText:SetText("")

    -- Probability display
    frame.probText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.probText:SetPoint("TOP", frame.statsText, "BOTTOM", 0, -5)
    frame.probText:SetText("")

    -- Pity counter display
    frame.pityText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.pityText:SetPoint("BOTTOM", frame.spinButton, "TOP", 0, 5)
    frame.pityText:SetText("")

    self.slotFrame = frame
    self.UpdateUI = function() self:UpdateSlotUI() end

    return frame
end

-- Update the slot UI display
function RR:UpdateSlotUI()
    if not self.slotFrame then return end

    local qualityColors = {
        [0] = {name = "POOR", r = 0.62, g = 0.62, b = 0.62},
        [1] = {name = "COMMON", r = 1.00, g = 1.00, b = 1.00},
        [2] = {name = "UNCOMMON", r = 0.12, g = 1.00, b = 0.00},
        [3] = {name = "RARE", r = 0.00, g = 0.44, b = 0.87},
        [4] = {name = "EPIC", r = 0.64, g = 0.21, b = 0.93},
        [5] = {name = "LEGENDARY", r = 1.00, g = 0.50, b = 0.00},
    }

    -- Update each slot
    for i = 1, 3 do
        local slot = self.slotFrame.slots[i]
        local slotData = self:GetSlotDisplay(i)

        if slotData.spinning then
            -- Spinning animation - cycle through different qualities
            for j = 1, 3 do
                local randomQuality = math.random(0, 5)
                local color = qualityColors[randomQuality]
                slot.qualities[j].text:SetText(color.name)
                slot.qualities[j].text:SetTextColor(color.r, color.g, color.b)
            end

            -- Highlight border while spinning
            slot.border:SetBackdropBorderColor(1, 1, 0, 1)
        else
            -- Static display - show the result
            local color = qualityColors[slotData.quality]

            -- Clear other rows
            slot.qualities[1].text:SetText("")
            slot.qualities[3].text:SetText("")

            -- Show main result in center
            slot.qualities[2].text:SetText(color.name)
            slot.qualities[2].text:SetTextColor(color.r, color.g, color.b)

            -- Update border color based on result
            if self.slots[1].current == self.slots[2].current and
               self.slots[2].current == self.slots[3].current and
               not self.isSpinning then
                -- Three of a kind - red border for danger!
                slot.border:SetBackdropBorderColor(1, 0, 0, 1)
            else
                -- Normal border
                slot.border:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
            end
        end
    end

    -- Update button state
    self.slotFrame.spinButton:SetEnabled(not self.isSpinning)
    self.slotFrame.spinButton:SetText(self.isSpinning and "SPINNING..." or "SPIN!")

    -- Update pity counter
    if RR.safeSpins > 0 then
        if RR.safeSpins >= 10 then
            self.slotFrame.pityText:SetText(string.format("|cffffcc00Safe Streak: %d (PITY ACTIVE!)|r", RR.safeSpins))
        elseif RR.safeSpins >= 5 then
            self.slotFrame.pityText:SetText(string.format("|cff00ff00Safe Streak: %d|r", RR.safeSpins))
        else
            self.slotFrame.pityText:SetText("")
        end
    else
        self.slotFrame.pityText:SetText("")
    end

    -- Update statistics
    self:UpdateStatistics()
end

-- Update statistics display
function RR:UpdateStatistics()
    if not self.slotFrame then return end

    -- Count items by quality
    local counts = {}
    local total = 0
    for quality = 0, 5 do
        counts[quality] = #(self.inventory[quality] or {})
        total = total + counts[quality]
    end

    local statsText = string.format("Items: |cff9d9d9d%d|r |cffffffff%d|r |cff1eff00%d|r |cff0070dd%d|r |cffa335ee%d|r |cffff8000%d|r (Total: %d)",
        counts[0], counts[1], counts[2], counts[3], counts[4], counts[5], total)

    self.slotFrame.statsText:SetText(statsText)

    -- Update probability display
    if self.availableQualities and self.totalWeight > 0 then
        local probabilities = {}
        local qualityColors = {
            [0] = "ff9d9d9d",
            [1] = "ffffffff",
            [2] = "ff1eff00",
            [3] = "ff0070dd",
            [4] = "ffa335ee",
            [5] = "ffff8000"
        }

        -- Only show probabilities for qualities with items
        for _, info in ipairs(self.availableQualities) do
            if info.hasItems then
                local chance = (info.weight / self.totalWeight) * 100
                local color = qualityColors[info.quality]

                -- Special indicator for rare items
                local indicator = ""
                if info.count <= 2 and info.quality >= 3 then
                    indicator = "!"  -- Danger indicator for very rare items
                elseif chance < 1 then
                    indicator = "*"  -- Ultra rare indicator
                end

                table.insert(probabilities, string.format("|c%s%.1f%%%s|r", color, chance, indicator))
            end
        end

        local probText = "Chances: " .. table.concat(probabilities, " ")
        self.slotFrame.probText:SetText(probText)

        -- Add warning if player has very valuable items at risk
        local hasValuableAtRisk = false
        for quality = 3, 5 do  -- Rare, Epic, Legendary
            if counts[quality] > 0 and counts[quality] <= 3 then
                hasValuableAtRisk = true
                break
            end
        end

        if hasValuableAtRisk then
            self.slotFrame.probText:SetText(probText .. " |cffff0000[!]|r")
        end
    else
        self.slotFrame.probText:SetText("")
    end
end

-- Toggle the slot machine window
function RR:Toggle()
    if not self.slotFrame then
        self:CreateSlotMachineFrame()
    end

    if self.slotFrame:IsShown() then
        self.slotFrame:Hide()
    else
        self:ScanInventory()
        self:UpdateSlotUI()
        self.slotFrame:Show()
    end
end

-- Add to main UI tabs
function CattosShuffle:AddRussianRouletteTab()
    if not self.frame then return end

    -- Create tab button
    local tabButton = CreateFrame("Button", nil, self.frame, "GameMenuButtonTemplate")
    tabButton:SetSize(100, 25)
    tabButton:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -10, -35)
    tabButton:SetText("Roulette")
    tabButton:SetScript("OnClick", function()
        -- Hide main window
        self.frame:Hide()
        -- Show roulette window
        RR:Toggle()
    end)

    -- Add return button to roulette frame
    if RR.slotFrame then
        local returnButton = CreateFrame("Button", nil, RR.slotFrame, "GameMenuButtonTemplate")
        returnButton:SetSize(80, 25)
        returnButton:SetPoint("TOPRIGHT", RR.slotFrame, "TOPRIGHT", -30, -35)
        returnButton:SetText("Back")
        returnButton:SetScript("OnClick", function()
            RR.slotFrame:Hide()
            self.frame:Show()
            self:RefreshUI()
        end)
    end
end