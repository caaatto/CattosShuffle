-- CattosShuffle - x10 Pull Animation System (Compact Version)
-- Author: Amke & Assistant
-- Version: 2.0.0
-- This module handles the animated x10 pull with 10 single slots (showing best/match result)

local addonName, CattosShuffle = ...
local L = CattosShuffle.L
local Gacha = CattosShuffle.Gacha

-- Constants for animation
local SLOT_WIDTH = 120
local SLOT_HEIGHT = 160
local SLOT_SPACING = 35  -- Increased spacing between individual pulls
local PULLS_PER_ROW = 5

-- Tier info reference
local TIER_INFO = {
    ["C"] = { name = "C", color = {r = 0.5, g = 0.5, b = 0.5}, hex = "ff808080" },
    ["B"] = { name = "B", color = {r = 0.6, g = 0.8, b = 1.0}, hex = "ff99ccff" },
    ["A"] = { name = "A", color = {r = 0.6, g = 0.2, b = 0.8}, hex = "ff9933cc" },
    ["S"] = { name = "S", color = {r = 1.0, g = 0.84, b = 0}, hex = "ffffd700" },
    ["SS"] = { name = "SS", color = {r = 1.0, g = 0.5, b = 0}, hex = "ffff8000" }
}

-- Create the animated x10 frame (compact version with 10 slots)
function Gacha:CreateCompactX10Frame()
    if self.x10CompactFrame then
        return self.x10CompactFrame
    end

    local frame = CreateFrame("Frame", "CattosGachaX10Compact", UIParent, "BasicFrameTemplate")
    frame:SetSize(760, 550)  -- Wider frame to accommodate increased spacing
    frame:SetPoint("CENTER", 0, 0)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:Hide()

    -- OnHide cleanup to ensure animations stop
    frame:SetScript("OnHide", function(self)
        -- Stop all animations when frame is hidden
        Gacha:StopAllEpicAnimations()
        -- Also clear the active animations list
        if Gacha.activeAnimations then
            Gacha.activeAnimations = {}
        end
    end)

    -- Add to ESC close list
    tinsert(UISpecialFrames, "CattosGachaX10Compact")

    -- Dark background
    if frame.Bg then
        frame.Bg:SetColorTexture(0.02, 0.05, 0.15, 0.9)
    end

    -- Title
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("TOP", frame, "TOP", 0, -35)
    frame.title:SetText("|cffffcc00>>> x10 MEGA PULL <<<|r")
    frame.title:SetFont("Fonts\\FRIZQT__.TTF", 24, "OUTLINE")

    -- Create 10 slots (2 rows of 5)
    frame.slots = {}

    for pullNum = 1, 10 do
        local slot = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        slot:SetSize(SLOT_WIDTH, SLOT_HEIGHT)

        -- Calculate position (2 rows of 5)
        local row = math.floor((pullNum - 1) / PULLS_PER_ROW)
        local col = (pullNum - 1) % PULLS_PER_ROW

        local startX = -((PULLS_PER_ROW * SLOT_WIDTH + (PULLS_PER_ROW - 1) * SLOT_SPACING) / 2) + (SLOT_WIDTH / 2)
        local startY = 100  -- Moved up for more bottom space

        slot:SetPoint("CENTER", frame, "CENTER",
            startX + col * (SLOT_WIDTH + SLOT_SPACING),
            startY - row * (SLOT_HEIGHT + 50))  -- More vertical spacing between rows

        slot:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
            tile = false,
            edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 }
        })
        slot:SetBackdropColor(0.08, 0.08, 0.15, 0.95)

        -- Pull number label
        slot.label = slot:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        slot.label:SetPoint("TOP", slot, "TOP", 0, -5)
        slot.label:SetText("#" .. pullNum)
        slot.label:SetTextColor(0.7, 0.7, 0.7)

        -- Tier banner
        slot.tierBanner = CreateFrame("Frame", nil, slot, "BackdropTemplate")
        slot.tierBanner:SetHeight(25)
        slot.tierBanner:SetPoint("TOP", slot, "TOP", 0, -20)
        slot.tierBanner:SetPoint("LEFT", slot, "LEFT", 5, 0)
        slot.tierBanner:SetPoint("RIGHT", slot, "RIGHT", -5, 0)
        slot.tierBanner:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1
        })

        slot.tierText = slot.tierBanner:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        slot.tierText:SetPoint("CENTER", slot.tierBanner, "CENTER", 0, 0)
        slot.tierText:SetText("?")

        -- Item icon button
        slot.iconButton = CreateFrame("Button", nil, slot)
        slot.iconButton:SetSize(56, 56)
        slot.iconButton:SetPoint("CENTER", slot, "CENTER", 0, -5)

        slot.icon = slot.iconButton:CreateTexture(nil, "ARTWORK")
        slot.icon:SetAllPoints(slot.iconButton)
        slot.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

        -- Item name
        slot.itemText = slot:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        slot.itemText:SetPoint("BOTTOM", slot, "BOTTOM", 0, 5)  -- Closer to bottom
        slot.itemText:SetWidth(SLOT_WIDTH - 10)
        slot.itemText:SetHeight(40)  -- More height for text
        slot.itemText:SetWordWrap(true)
        slot.itemText:SetText("")

        -- Match indicator (shows if 3x match)
        slot.matchIndicator = slot:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        slot.matchIndicator:SetPoint("BOTTOM", slot, "TOP", 0, 2)
        slot.matchIndicator:SetText("")

        -- DELETE marker (shows on icon)
        slot.deleteMarker = slot.iconButton:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        slot.deleteMarker:SetPoint("CENTER", slot.iconButton, "CENTER", 0, 0)
        slot.deleteMarker:SetText("X")
        slot.deleteMarker:SetTextColor(1, 0, 0)
        slot.deleteMarker:SetFont("Fonts\\FRIZQT__.TTF", 32, "THICKOUTLINE")
        slot.deleteMarker:Hide()

        -- Hidden tier display (for debugging)
        slot.hiddenTiers = slot:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        slot.hiddenTiers:SetPoint("TOP", slot, "BOTTOM", 0, -2)
        slot.hiddenTiers:SetTextColor(0.5, 0.5, 0.5, 0.7)
        slot.hiddenTiers:SetText("")
        slot.hiddenTiers:Hide()  -- Hidden by default

        -- Tooltip
        slot.iconButton:SetScript("OnEnter", function(self)
            if self.itemData then
                GameTooltip:SetOwner(self, "ANCHOR_LEFT")
                if self.itemData.link then
                    GameTooltip:SetHyperlink(self.itemData.link)
                else
                    GameTooltip:SetText(self.itemData.name or "Unknown Item", 1, 1, 1)
                end
                GameTooltip:Show()
            end
        end)

        slot.iconButton:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        frame.slots[pullNum] = slot
    end

    -- Summary text
    frame.summaryText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.summaryText:SetPoint("BOTTOM", frame, "BOTTOM", 0, 100)  -- Much higher to avoid overlap
    frame.summaryText:SetText("")

    -- Instructions
    frame.instructText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.instructText:SetPoint("BOTTOM", frame, "BOTTOM", 0, 75)  -- Also higher
    frame.instructText:SetText("")

    -- Close button (disabled during animation)
    frame.closeButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    frame.closeButton:SetSize(100, 30)
    frame.closeButton:SetPoint("BOTTOM", frame, "BOTTOM", 0, 20)  -- Slightly higher
    frame.closeButton:SetText("Close")
    frame.closeButton:SetScript("OnClick", function()
        if not Gacha.x10AnimationRunning then
            PlaySound(855, "SFX")

            -- Stop all active animations
            Gacha:StopAllEpicAnimations()

            frame:Hide()
            -- Show main gacha frame again
            if Gacha.frame then
                Gacha.frame:Show()
            end
        else
            -- Animation still running - just hide the window but keep animation state
            print("|cffffcc00Animation still running - window hidden. Click x10 Pull to reopen!|r")
            frame:Hide()
        end
    end)

    self.x10CompactFrame = frame
    return frame
end

-- Calculate all x10 results (copied from Pull10Fast logic)
function Gacha:CalculateCompactX10Results()
    local results = {}

    for pullNum = 1, 10 do
        -- Pre-calculate counters for pity
        local nextSpinCount = self.spinCount + 1
        local nextBTierCount = self.bTierPityCount + 1

        -- Check pity systems
        local forcedPityTier = nil

        if nextSpinCount >= self.pityThreshold then
            forcedPityTier = math.random() < 0.5 and "S" or "A"
            print(string.format("|cffffcc00Pull %d: 50-SPIN PITY! Forcing %s triple!|r",
                pullNum, forcedPityTier))
        elseif nextBTierCount >= self.bTierPityThreshold then
            forcedPityTier = "B"
            print(string.format("|cff99ccffPull %d: B-TIER PITY! Forcing B triple!|r", pullNum))
        end

        -- Increment counters
        self.spinCount = self.spinCount + 1
        self.bTierPityCount = self.bTierPityCount + 1
        CattosShuffleDB.gachaSpinCount = self.spinCount
        CattosShuffleDB.gachaBTierPityCount = self.bTierPityCount

        -- Generate 3 slots for this pull
        local pullResult = {
            tiers = {},
            items = {},
            hasMatch = false,
            victim = nil,
            victimSlot = nil,
            deleteCount = nil
        }

        for slot = 1, 3 do
            local tier = forcedPityTier or self:GetRandomTier()
            local item = self:GetRandomItemFromTier(tier)

            pullResult.tiers[slot] = tier
            pullResult.items[slot] = item
        end

        -- Check for match
        local tier1 = pullResult.tiers[1]
        local tier2 = pullResult.tiers[2]
        local tier3 = pullResult.tiers[3]

        if tier1 == tier2 and tier2 == tier3 then
            pullResult.hasMatch = true

            -- Reset pity counters
            if tier1 == "B" then
                self.bTierPityCount = 0
                CattosShuffleDB.gachaBTierPityCount = 0
            end
            if tier1 == "S" or tier1 == "A" then
                self.spinCount = 0
                CattosShuffleDB.gachaSpinCount = 0
            end

            -- Pick random victim from the 3
            local victimSlot = math.random(1, 3)
            pullResult.victimSlot = victimSlot
            pullResult.victim = pullResult.items[victimSlot]

            -- Calculate delete count for stacks
            if pullResult.victim and pullResult.victim.stackCount and pullResult.victim.stackCount > 1 then
                pullResult.deleteCount = math.random(1, pullResult.victim.stackCount)
            else
                pullResult.deleteCount = 1
            end
        else
            -- Check for shards (S/SS without match)
            for slot = 1, 3 do
                if pullResult.tiers[slot] == "S" or pullResult.tiers[slot] == "SS" then
                    self.shards = math.min((self.shards or 0) + 1, self.maxShards)
                    CattosShuffleDB.gachaShards = self.shards
                    break  -- Only one shard per pull
                end
            end
        end

        results[pullNum] = pullResult
    end

    return results
end

-- New compact animated x10 pull function
function Gacha:Pull10CompactAnimated()
    -- Check if animation is already running and frame is hidden - reopen it
    if self.x10AnimationRunning and self.x10CompactFrame and not self.x10CompactFrame:IsShown() then
        self.x10CompactFrame:Show()
        print("|cff00ff00Reopening x10 animation window!|r")
        return
    end

    if self.isSpinning or self.x10AnimationRunning then
        print("|cffff0000Animation already in progress!|r")
        return
    end

    if InCombatLockdown() or UnitAffectingCombat("player") then
        print("|cffff0000Cannot pull during combat!|r")
        return
    end

    -- Build fresh item pool
    self:BuildItemPool()

    if self.totalItems == 0 then
        print("|cffff0000No items found in inventory!|r")
        return
    end

    print("|cffffcc00>>> STARTING x10 ANIMATED PULL <<<|r")

    -- Pre-calculate all results (same as Pull10Fast)
    local results = self:CalculateCompactX10Results()

    -- Process results to get display items (best tier or random on match)
    local displayResults = self:ProcessX10ForDisplay(results)

    -- Create/show animation frame
    if not self.x10CompactFrame then
        self:CreateCompactX10Frame()
    end

    local frame = self.x10CompactFrame
    frame:Show()

    -- Hide main gacha frame during animation
    if self.frame then
        self.frame:Hide()
    end

    -- Stop any existing animations before starting new ones
    self:StopAllEpicAnimations()

    -- Reset all slots to spinning state
    for pullNum = 1, 10 do
        local slot = frame.slots[pullNum]
        slot.tierBanner:SetBackdropColor(0.3, 0.3, 0.3, 0.5)
        slot.tierText:SetText("?")
        slot.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        slot.icon:SetAlpha(0.5)
        slot.itemText:SetText("")
        slot.deleteMarker:Hide()
        slot.matchIndicator:SetText("")
        slot.hiddenTiers:SetText("")
        slot:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    end

    -- Clear summary - no text during animation
    frame.summaryText:SetText("")
    frame.instructText:SetText("")

    -- Disable close button during animation
    frame.closeButton:SetEnabled(false)
    self.x10AnimationRunning = true

    -- Play epic sound
    PlaySound(168, "SFX")  -- Chest opening
    C_Timer.After(0.3, function()
        PlaySound(63, "SFX")  -- Lever pull
    end)

    -- Start the parallel animations for 10 slots
    self:RunCompactParallelSpins(displayResults)
end

-- Process x10 results to determine what to display in each slot
function Gacha:ProcessX10ForDisplay(results)
    local displayResults = {}

    for pullNum = 1, 10 do
        local result = results[pullNum]
        local displayItem = {}

        -- Check for match
        local tier1 = result.tiers[1]
        local tier2 = result.tiers[2]
        local tier3 = result.tiers[3]
        local hasMatch = (tier1 == tier2 and tier2 == tier3)

        if hasMatch then
            -- Match! Show the matched tier and victim item
            displayItem.tier = tier1
            displayItem.item = result.victim or result.items[result.victimSlot or math.random(1,3)]
            displayItem.hasMatch = true
            displayItem.matchText = string.format("|cffff0000%s TRIPLE!|r", tier1)
            displayItem.deleteCount = result.deleteCount
            displayItem.allTiers = string.format("%s-%s-%s", tier1, tier2, tier3)
        else
            -- No match - show best tier
            local tierOrder = { SS = 5, S = 4, A = 3, B = 2, C = 1 }
            local bestTier = tier1
            local bestItem = result.items[1]
            local bestValue = tierOrder[tier1] or 0

            for i = 2, 3 do
                local currentTier = result.tiers[i]
                local currentValue = tierOrder[currentTier] or 0
                if currentValue > bestValue then
                    bestTier = currentTier
                    bestItem = result.items[i]
                    bestValue = currentValue
                end
            end

            displayItem.tier = bestTier
            displayItem.item = bestItem
            displayItem.hasMatch = false
            displayItem.allTiers = string.format("%s-%s-%s", tier1, tier2, tier3)
        end

        displayResults[pullNum] = displayItem
    end

    return displayResults
end

-- Run parallel spin animation for 10 slots
function Gacha:RunCompactParallelSpins(displayResults)
    local frame = self.x10CompactFrame
    local animationData = {}

    -- Initialize animation data for each slot
    for pullNum = 1, 10 do
        animationData[pullNum] = {
            isSpinning = true,
            -- Staggered stop times - each pull stops 1 second after the previous
            -- First stops at 3 seconds, last at ~12 seconds
            stopTime = 3.0 + (pullNum - 1) * 1.0,
            displayResult = displayResults[pullNum]
        }
    end

    -- Store animation state for resume after combat
    self.x10AnimationData = animationData
    self.x10DisplayResults = displayResults
    self.x10AnimationElapsed = 0
    self.x10AnimationPaused = false

    local elapsed = 0
    local animSpeed = 0.05
    local allStopped = false

    -- Main animation ticker
    self.x10CompactTicker = C_Timer.NewTicker(animSpeed, function()
        elapsed = elapsed + animSpeed
        self.x10AnimationElapsed = elapsed  -- Store for resume
        local stillSpinning = false

        for pullNum = 1, 10 do
            local slotData = animationData[pullNum]
            local slot = frame.slots[pullNum]

            if slotData.isSpinning then
                stillSpinning = true

                -- Check if time to stop
                if elapsed >= slotData.stopTime then
                    slotData.isSpinning = false

                    -- Show final result
                    self:ShowCompactSlotResult(slot, slotData.displayResult, pullNum)

                    -- Play stop sound
                    PlaySound(3175, "SFX")

                    -- Extra effects for matches
                    if slotData.displayResult.hasMatch then
                        PlaySound(888, "SFX")  -- Warning sound for match
                    end
                else
                    -- Keep spinning - show random tiers/items
                    local progress = elapsed / slotData.stopTime

                    -- Slow down as we approach stop time (more gradual slowdown)
                    local changeChance = 0.4
                    if progress > 0.5 then
                        changeChance = 0.3
                    end
                    if progress > 0.65 then
                        changeChance = 0.2
                    end
                    if progress > 0.75 then
                        changeChance = 0.15
                    end
                    if progress > 0.85 then
                        changeChance = 0.08
                    end
                    if progress > 0.92 then
                        changeChance = 0.04
                    end
                    if progress > 0.96 then
                        changeChance = 0.02
                    end

                    if math.random() < changeChance then
                        -- Random visual changes during spin
                        local randomTier = self:GetRandomTier()
                        local color = TIER_INFO[randomTier].color

                        slot.tierBanner:SetBackdropColor(color.r, color.g, color.b, 0.3)
                        slot.tierText:SetText(randomTier)
                        slot.tierText:SetTextColor(1, 1, 1, 0.5)

                        -- Random icon (change more frequently)
                        if math.random() < 0.6 then
                            local randomItem = self:GetRandomItemFromTier(randomTier)
                            if randomItem and randomItem.icon then
                                slot.icon:SetTexture(randomItem.icon)
                                slot.icon:SetAlpha(0.4)
                            end
                        end
                    end
                end
            end
        end

        -- All animations complete
        if not stillSpinning and not allStopped then
            allStopped = true
            self:OnCompactX10AnimationComplete(displayResults)
        end
    end)
end

-- Show final result in a compact slot
function Gacha:ShowCompactSlotResult(slot, result, pullNum)
    local tierInfo = TIER_INFO[result.tier]

    -- Set tier banner
    slot.tierBanner:SetBackdropColor(tierInfo.color.r, tierInfo.color.g, tierInfo.color.b, 0.9)
    slot.tierText:SetText(result.tier)
    slot.tierText:SetTextColor(1, 1, 1, 1)

    -- Set item
    if result.item then
        slot.icon:SetTexture(result.item.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        slot.icon:SetAlpha(1.0)
        slot.iconButton.itemData = result.item

        -- Item name
        local itemName = result.item.name or "Unknown"
        if string.len(itemName) > 20 then
            itemName = string.sub(itemName, 1, 17) .. "..."
        end

        local qualityColor = ITEM_QUALITY_COLORS[result.item.quality or 1] or {r=1, g=1, b=1}
        slot.itemText:SetTextColor(qualityColor.r, qualityColor.g, qualityColor.b)
        slot.itemText:SetText(itemName)
    end

    -- Special animation for S and SS tier always, A tier only on match
    if result.tier == "S" or result.tier == "SS" or (result.tier == "A" and result.hasMatch) then
        self:CreateEpicPullAnimation(slot, result.tier)
    end

    -- Show match indicator
    if result.hasMatch then
        slot.matchIndicator:SetText(result.matchText)
        slot:SetBackdropBorderColor(1, 0, 0, 1)  -- Red border for matches

        -- Show delete marker
        slot.deleteMarker:Show()
        if result.deleteCount and result.deleteCount > 1 then
            slot.deleteMarker:SetText(tostring(result.deleteCount))
            slot.deleteMarker:SetFont("Fonts\\FRIZQT__.TTF", 24, "THICKOUTLINE")
        else
            slot.deleteMarker:SetText("X")
            slot.deleteMarker:SetFont("Fonts\\FRIZQT__.TTF", 32, "THICKOUTLINE")
        end
    else
        -- Color border based on tier rarity
        if result.tier == "SS" then
            slot:SetBackdropBorderColor(1, 0.5, 0, 1)  -- Orange
        elseif result.tier == "S" then
            slot:SetBackdropBorderColor(1, 0.84, 0, 1)  -- Gold
        elseif result.tier == "A" then
            slot:SetBackdropBorderColor(0.6, 0.2, 0.8, 1)  -- Purple
        elseif result.tier == "B" then
            slot:SetBackdropBorderColor(0.6, 0.8, 1.0, 1)  -- Blue
        else
            slot:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)  -- Gray
        end
    end

    -- Optional: Show hidden tiers for debugging (uncomment to see all 3 rolls)
    -- slot.hiddenTiers:SetText(result.allTiers)
    -- slot.hiddenTiers:Show()
end

-- Stop all epic animations (cleanup when closing frame)
function Gacha:StopAllEpicAnimations()
    -- Clean up x10 frame slots if they exist
    if self.x10CompactFrame and self.x10CompactFrame.slots then
        for i = 1, 10 do
            local slot = self.x10CompactFrame.slots[i]
            if slot then
                -- Cancel any active tickers
                if slot.animTicker then
                    slot.animTicker:Cancel()
                    slot.animTicker = nil
                end
                if slot.fadeOutTicker then
                    slot.fadeOutTicker:Cancel()
                    slot.fadeOutTicker = nil
                end
                -- Hide all glow elements
                if slot.glowBg then
                    slot.glowBg:SetAlpha(0)
                end
                if slot.borderGlow then
                    slot.borderGlow:SetAlpha(0)
                end
                -- Reset to default state
                slot:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
                slot:SetBackdropColor(0.08, 0.08, 0.15, 0.95)
            end
        end
    end

    -- Also clean the tracked animations list
    if self.activeAnimations then
        for _, slot in ipairs(self.activeAnimations) do
            if slot.animTicker then
                slot.animTicker:Cancel()
                slot.animTicker = nil
            end
            if slot.fadeOutTicker then
                slot.fadeOutTicker:Cancel()
                slot.fadeOutTicker = nil
            end
            -- Hide glow elements
            if slot.glowBg then
                slot.glowBg:SetAlpha(0)
            end
            if slot.borderGlow then
                slot.borderGlow:SetAlpha(0)
            end
        end
        self.activeAnimations = {}
    end
end

-- Create epic animation for S/SS tier pulls
function Gacha:CreateEpicPullAnimation(slot, tier)
    -- Create glow frame if not exists
    if not slot.glowFrame then
        slot.glowFrame = CreateFrame("Frame", nil, slot)
        slot.glowFrame:SetAllPoints(slot)
        slot.glowFrame:SetFrameLevel(slot:GetFrameLevel() + 1)

        -- Background glow texture
        slot.glowBg = slot.glowFrame:CreateTexture(nil, "BACKGROUND")
        slot.glowBg:SetPoint("CENTER", slot, "CENTER", 0, 0)
        slot.glowBg:SetSize(SLOT_WIDTH * 1.5, SLOT_HEIGHT * 1.5)
        slot.glowBg:SetTexture("Interface\\Cooldown\\star4")
        slot.glowBg:SetBlendMode("ADD")

        -- Moving border glow
        slot.borderGlow = slot.glowFrame:CreateTexture(nil, "OVERLAY")
        slot.borderGlow:SetAllPoints(slot)
        slot.borderGlow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        slot.borderGlow:SetBlendMode("ADD")
    end

    -- Set colors based on tier
    local r, g, b = 1, 0.84, 0  -- Gold for S
    if tier == "SS" then
        r, g, b = 1, 0.5, 0.2  -- Legendary orange-red for SS (WoW Legendary color)
    elseif tier == "A" then
        r, g, b = 0.6, 0.2, 0.8  -- Purple for A
    end

    -- Initial flash
    slot.glowBg:SetVertexColor(r, g, b, 1)
    slot.borderGlow:SetVertexColor(r, g, b, 1)

    -- Play sound based on tier
    if tier == "SS" then
        PlaySound(31578, "SFX")  -- Epic loot sound
    elseif tier == "S" then
        PlaySound(31579, "SFX")  -- Rare loot sound
    elseif tier == "A" then
        PlaySound(124, "SFX")  -- Good item sound
    end

    -- Animation variables
    local elapsed = 0
    local pulseSpeed = 0.5
    local rotateSpeed = 2
    local fadeInTime = 0.3

    -- Start the animation (INFINITE - no duration limit)
    if slot.animTicker then
        slot.animTicker:Cancel()
    end

    -- Store ticker reference for cleanup
    if not self.activeAnimations then
        self.activeAnimations = {}
    end

    slot.animTicker = C_Timer.NewTicker(0.02, function(ticker)
        elapsed = elapsed + 0.02

        -- Fade in
        local fadeAlpha = 1
        if elapsed < fadeInTime then
            fadeAlpha = elapsed / fadeInTime
        end

        -- Pulsing effect (continuous)
        local pulse = (math.sin(elapsed / pulseSpeed * math.pi) + 1) / 2
        local bgAlpha = fadeAlpha * (0.3 + pulse * 0.7)
        slot.glowBg:SetAlpha(bgAlpha)

        -- Rotate the background glow (continuous)
        local rotation = elapsed * rotateSpeed
        slot.glowBg:SetRotation(rotation)

        -- Border shimmer effect (continuous)
        local shimmer = (math.sin(elapsed * 4) + 1) / 2
        slot.borderGlow:SetAlpha(fadeAlpha * (0.5 + shimmer * 0.5))

        -- Moving light effect on border (continuous)
        local progress = (elapsed % 1.5) / 1.5
        local borderHighlight = math.sin(progress * math.pi * 2)

        if borderHighlight > 0 then
            slot:SetBackdropBorderColor(
                r + (1 - r) * borderHighlight * 0.5,
                g + (1 - g) * borderHighlight * 0.5,
                b + (1 - b) * borderHighlight * 0.5,
                1
            )
        else
            -- Keep the base glow color
            slot:SetBackdropBorderColor(r, g, b, 1)
        end

        -- NO STOP CONDITION - runs forever until frame closes
    end)

    -- Add to active animations list
    table.insert(self.activeAnimations, slot)
    slot.lastTier = tier  -- Store tier for cleanup
end

-- Handle completion of compact animation
function Gacha:OnCompactX10AnimationComplete(displayResults)
    local frame = self.x10CompactFrame

    -- Cancel ticker
    if self.x10CompactTicker then
        self.x10CompactTicker:Cancel()
        self.x10CompactTicker = nil
    end

    -- Count total matches and deletions
    local totalMatches = 0
    local deleteList = {}

    for pullNum, result in ipairs(displayResults) do
        if result.hasMatch then
            totalMatches = totalMatches + 1
            table.insert(deleteList, {
                pullNum = pullNum,
                item = result.item,
                count = result.deleteCount or 1
            })
        end
    end

    -- Update summary
    if totalMatches > 0 then
        -- Clear the text since we show popup instead
        frame.summaryText:SetText("")
        frame.instructText:SetText("")

        -- Show deletion popup instead of text
        self:ShowX10DeletePopup(deleteList, totalMatches)
    else
        frame.summaryText:SetText("|cff00ff00All safe! No matches!|r")
        frame.instructText:SetText("")
    end

    -- Re-enable close button
    frame.closeButton:SetEnabled(true)
    self.x10AnimationRunning = false

    -- Play completion sound
    PlaySound(3332, "SFX")

    -- Update main UI
    if self.UpdateUI then
        self:UpdateUI()
    end
end

-- Show deletion popup for x10 matches
function Gacha:ShowX10DeletePopup(deleteList, totalMatches)
    if #deleteList == 0 then return end

    -- Build the item list text
    local itemListText = ""
    for i, entry in ipairs(deleteList) do
        if i > 1 then
            itemListText = itemListText .. "\n"
        end

        if entry.count > 1 then
            itemListText = itemListText .. string.format("|cffffcc00Pull #%d:|r %dx %s",
                entry.pullNum, entry.count, entry.item.link or entry.item.name)
        else
            itemListText = itemListText .. string.format("|cffffcc00Pull #%d:|r %s",
                entry.pullNum, entry.item.link or entry.item.name)
        end
    end

    -- Create the popup dialog
    StaticPopupDialogs["CATTOS_X10_DELETE_MATCHES"] = {
        text = string.format("|cffff0000%d MATCHES FOUND!|r\n\n" ..
            "You must manually delete these items:\n\n" ..
            "%s\n\n" ..
            "|cffff0000DELETE THEM NOW FROM YOUR BAGS!|r",
            totalMatches, itemListText),
        button1 = "I will delete them",
        button2 = "Show in chat",
        OnAccept = function()
            print("|cffff0000Remember to delete the matched items from your bags!|r")
        end,
        OnCancel = function()
            -- Also show in chat when they click "Show in chat"
            Gacha:ShowCompactDeleteInstructions(deleteList)
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = false,  -- Force them to acknowledge
        preferredIndex = 10,  -- Much higher index for absolute top priority
        hasEditBox = false,
        showAlert = true,  -- Flash the screen
    }

    -- Temporarily lower the x10 frame to ensure popup is on top
    if self.x10CompactFrame then
        self.x10CompactFrame:SetFrameStrata("DIALOG")
        self.x10CompactFrame:SetFrameLevel(1)
    end

    -- Show the popup
    local popup = StaticPopup_Show("CATTOS_X10_DELETE_MATCHES")

    -- Force popup to highest level
    if popup then
        popup:SetFrameStrata("TOOLTIP")
        popup:SetFrameLevel(999)
    end

    -- Restore frame strata after popup is shown
    C_Timer.After(0.2, function()
        if self.x10CompactFrame then
            self.x10CompactFrame:SetFrameStrata("FULLSCREEN_DIALOG")
            self.x10CompactFrame:SetFrameLevel(10)
        end
    end)

    -- Also play alert sound
    PlaySound(8959, "Master")  -- Raid warning sound
end

-- Show deletion instructions for compact version (fallback for chat)
function Gacha:ShowCompactDeleteInstructions(deleteList)
    if #deleteList == 0 then return end

    print("|cffff0000=== x10 PULL DELETIONS REQUIRED ===|r")
    print(string.format("|cffffcc00You must delete %d items:|r", #deleteList))

    for i, entry in ipairs(deleteList) do
        if entry.count > 1 then
            print(string.format("  Pull #%d: %dx %s",
                entry.pullNum, entry.count, entry.item.link or entry.item.name))
        else
            print(string.format("  Pull #%d: %s",
                entry.pullNum, entry.item.link or entry.item.name))
        end
    end

    print("|cffff0000Delete these items manually from your bags!|r")
end

-- Resume x10 animation after combat
function Gacha:ResumeX10Animation()
    if not self.x10AnimationData or not self.x10DisplayResults then
        print("|cffff0000Cannot resume - animation data lost|r")
        return
    end

    local animationData = self.x10AnimationData
    local displayResults = self.x10DisplayResults
    local elapsed = self.x10AnimationElapsed or 0
    local frame = self.x10CompactFrame
    local animSpeed = 0.05
    local allStopped = false

    -- Reset pause flag
    self.x10AnimationPaused = false
    self.x10AnimationRunning = true

    -- Disable close button during animation
    frame.closeButton:SetEnabled(false)

    print(string.format("|cffffcc00Resuming animation from %.1f seconds...|r", elapsed))

    -- Resume the animation ticker
    self.x10CompactTicker = C_Timer.NewTicker(animSpeed, function()
        elapsed = elapsed + animSpeed
        self.x10AnimationElapsed = elapsed
        local stillSpinning = false

        for pullNum = 1, 10 do
            local slotData = animationData[pullNum]
            local slot = frame.slots[pullNum]

            if slotData.isSpinning then
                stillSpinning = true

                -- Check if time to stop
                if elapsed >= slotData.stopTime then
                    slotData.isSpinning = false

                    -- Show final result
                    self:ShowCompactSlotResult(slot, slotData.displayResult, pullNum)

                    -- Play stop sound
                    PlaySound(3175, "SFX")

                    -- Extra effects for matches
                    if slotData.displayResult.hasMatch then
                        PlaySound(888, "SFX")  -- Warning sound for match
                    end
                else
                    -- Keep spinning - show random tiers/items
                    local progress = elapsed / slotData.stopTime

                    -- Slow down as we approach stop time (more gradual slowdown)
                    local changeChance = 0.4
                    if progress > 0.5 then
                        changeChance = 0.3
                    end
                    if progress > 0.65 then
                        changeChance = 0.2
                    end
                    if progress > 0.75 then
                        changeChance = 0.15
                    end
                    if progress > 0.85 then
                        changeChance = 0.08
                    end
                    if progress > 0.92 then
                        changeChance = 0.04
                    end
                    if progress > 0.96 then
                        changeChance = 0.02
                    end

                    if math.random() < changeChance then
                        -- Random visual changes during spin
                        local randomTier = self:GetRandomTier()
                        local color = TIER_INFO[randomTier].color

                        slot.tierBanner:SetBackdropColor(color.r, color.g, color.b, 0.3)
                        slot.tierText:SetText(randomTier)
                        slot.tierText:SetTextColor(1, 1, 1, 0.5)

                        -- Random icon (change more frequently)
                        if math.random() < 0.6 then
                            local randomItem = self:GetRandomItemFromTier(randomTier)
                            if randomItem and randomItem.icon then
                                slot.icon:SetTexture(randomItem.icon)
                                slot.icon:SetAlpha(0.4)
                            end
                        end
                    end
                end
            end
        end

        -- All animations complete
        if not stillSpinning and not allStopped then
            allStopped = true
            self:OnCompactX10AnimationComplete(displayResults)
        end
    end)
end

-- Override the setup to use compact version
function Gacha:SetupX10Animation()
    -- Don't try if frame doesn't exist yet
    if not self.frame or not self.frame.pull10Button then
        return false
    end

    -- Successfully found the button - set up the COMPACT animation
    self.frame.pull10Button:SetScript("OnClick", function()
        PlaySound(856, "SFX")
        Gacha:Pull10CompactAnimated()  -- Use COMPACT animated version
    end)

    -- Silent success (no spam in chat)
    return true
end