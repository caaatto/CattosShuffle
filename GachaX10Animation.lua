-- CattosShuffle - x10 Pull Animation System
-- Author: Amke & Assistant
-- Version: 1.0.0
-- This module handles the animated x10 pull with 10 parallel 3-slot spins

local addonName, CattosShuffle = ...
local L = CattosShuffle.L
local Gacha = CattosShuffle.Gacha

-- Constants for animation
local SLOT_WIDTH = 100
local SLOT_HEIGHT = 120
local SLOT_SPACING = 10
local GROUP_SPACING = 20
local PULLS_PER_ROW = 5

-- Tier info reference
local TIER_INFO = {
    ["C"] = { name = "C", color = {r = 0.5, g = 0.5, b = 0.5}, hex = "ff808080" },
    ["B"] = { name = "B", color = {r = 0.6, g = 0.8, b = 1.0}, hex = "ff99ccff" },
    ["A"] = { name = "A", color = {r = 0.6, g = 0.2, b = 0.8}, hex = "ff9933cc" },
    ["S"] = { name = "S", color = {r = 1.0, g = 0.84, b = 0}, hex = "ffffd700" },
    ["SS"] = { name = "SS", color = {r = 1.0, g = 0.5, b = 0}, hex = "ffff8000" }
}

-- Create the animated x10 frame
function Gacha:CreateAnimatedX10Frame()
    if self.x10AnimFrame then
        return self.x10AnimFrame
    end

    local frame = CreateFrame("Frame", "CattosGachaX10Animated", UIParent, "BasicFrameTemplate")
    frame:SetSize(800, 600)  -- Larger to fit 10 groups of 3 slots
    frame:SetPoint("CENTER", 0, 0)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:Hide()

    -- Add to ESC close list
    tinsert(UISpecialFrames, "CattosGachaX10Animated")

    -- Title
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("TOP", frame, "TOP", 0, -35)
    frame.title:SetText("|cffffcc00>>> x10 MEGA PULL <<<|r")
    frame.title:SetFont("Fonts\\FRIZQT__.TTF", 24, "OUTLINE")

    -- Create 10 pull groups (each with 3 slots)
    frame.pullGroups = {}

    for pullNum = 1, 10 do
        local group = CreateFrame("Frame", nil, frame)
        group.slots = {}

        -- Calculate position (2 rows of 5)
        local row = math.floor((pullNum - 1) / PULLS_PER_ROW)
        local col = (pullNum - 1) % PULLS_PER_ROW

        local groupWidth = SLOT_WIDTH * 3 + SLOT_SPACING * 2
        local groupHeight = SLOT_HEIGHT

        local startX = -((PULLS_PER_ROW * groupWidth + (PULLS_PER_ROW - 1) * GROUP_SPACING) / 2) + (groupWidth / 2)
        local startY = 120

        group:SetSize(groupWidth, groupHeight)
        group:SetPoint("CENTER", frame, "CENTER",
            startX + col * (groupWidth + GROUP_SPACING),
            startY - row * (groupHeight + 60))

        -- Pull number label
        group.label = group:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        group.label:SetPoint("TOP", group, "TOP", 0, 15)
        group.label:SetText("Pull #" .. pullNum)
        group.label:SetTextColor(0.7, 0.7, 0.7)

        -- Create 3 slots for this pull
        for slotNum = 1, 3 do
            local slot = CreateFrame("Frame", nil, group, "BackdropTemplate")
            slot:SetSize(SLOT_WIDTH, SLOT_HEIGHT)
            slot:SetPoint("LEFT", group, "LEFT", (slotNum - 1) * (SLOT_WIDTH + SLOT_SPACING), 0)

            slot:SetBackdrop({
                bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
                tile = false,
                edgeSize = 8,
                insets = { left = 2, right = 2, top = 2, bottom = 2 }
            })
            slot:SetBackdropColor(0.05, 0.05, 0.1, 0.9)

            -- Tier banner
            slot.tierBanner = CreateFrame("Frame", nil, slot, "BackdropTemplate")
            slot.tierBanner:SetHeight(20)
            slot.tierBanner:SetPoint("TOP", slot, "TOP", 0, -5)
            slot.tierBanner:SetPoint("LEFT", slot, "LEFT", 3, 0)
            slot.tierBanner:SetPoint("RIGHT", slot, "RIGHT", -3, 0)
            slot.tierBanner:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1
            })

            slot.tierText = slot.tierBanner:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            slot.tierText:SetPoint("CENTER", slot.tierBanner, "CENTER", 0, 0)
            slot.tierText:SetText("?")

            -- Item icon
            slot.icon = slot:CreateTexture(nil, "ARTWORK")
            slot.icon:SetSize(48, 48)
            slot.icon:SetPoint("CENTER", slot, "CENTER", 0, -5)
            slot.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

            -- Item name (shortened for space)
            slot.itemText = slot:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            slot.itemText:SetPoint("BOTTOM", slot, "BOTTOM", 0, 5)
            slot.itemText:SetWidth(SLOT_WIDTH - 6)
            slot.itemText:SetHeight(20)
            slot.itemText:SetWordWrap(false)
            slot.itemText:SetText("")

            -- DELETE marker
            slot.deleteMarker = slot:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            slot.deleteMarker:SetPoint("CENTER", slot, "CENTER", 0, 0)
            slot.deleteMarker:SetText("X")
            slot.deleteMarker:SetTextColor(1, 0, 0)
            slot.deleteMarker:SetFont("Fonts\\FRIZQT__.TTF", 32, "THICKOUTLINE")
            slot.deleteMarker:Hide()

            -- Store reference
            group.slots[slotNum] = slot
        end

        -- Match indicator
        group.matchIndicator = group:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        group.matchIndicator:SetPoint("BOTTOM", group, "BOTTOM", 0, -20)
        group.matchIndicator:SetText("")

        frame.pullGroups[pullNum] = group
    end

    -- Summary text
    frame.summaryText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.summaryText:SetPoint("BOTTOM", frame, "BOTTOM", 0, 80)
    frame.summaryText:SetText("")

    -- Close button (disabled during animation)
    frame.closeButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    frame.closeButton:SetSize(100, 30)
    frame.closeButton:SetPoint("BOTTOM", frame, "BOTTOM", 0, 20)
    frame.closeButton:SetText("Close")
    frame.closeButton:SetScript("OnClick", function()
        if not Gacha.x10AnimationRunning then
            PlaySound(855, "SFX")
            frame:Hide()
        end
    end)

    self.x10AnimFrame = frame
    return frame
end

-- New animated x10 pull function
function Gacha:Pull10Animated()
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
    local results = self:CalculateX10Results()

    -- Create/show animation frame
    if not self.x10AnimFrame then
        self:CreateAnimatedX10Frame()
    end

    local frame = self.x10AnimFrame
    frame:Show()

    -- Hide main gacha frame during animation
    if self.frame then
        self.frame:Hide()
    end

    -- Reset all slots to spinning state
    for pullNum = 1, 10 do
        local group = frame.pullGroups[pullNum]
        for slotNum = 1, 3 do
            local slot = group.slots[slotNum]
            slot.tierBanner:SetBackdropColor(0.3, 0.3, 0.3, 0.5)
            slot.tierText:SetText("?")
            slot.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            slot.icon:SetAlpha(0.5)
            slot.itemText:SetText("")
            slot.deleteMarker:Hide()
            slot:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
        end
        group.matchIndicator:SetText("|cffccccccSpinning...|r")
    end

    -- Disable buttons
    frame.closeButton:SetEnabled(false)
    self.x10AnimationRunning = true

    -- Play epic sound
    PlaySound(168, "SFX")  -- Chest opening
    C_Timer.After(0.3, function()
        PlaySound(63, "SFX")  -- Lever pull
    end)

    -- Start the parallel animations
    self:RunParallelSpins(results)
end

-- Run all 10 spins in parallel with staggered stops
function Gacha:RunParallelSpins(results)
    local frame = self.x10AnimFrame
    local animationData = {}

    -- Initialize animation data for each pull
    for pullNum = 1, 10 do
        animationData[pullNum] = {
            slots = {
                { isSpinning = true, stopTime = 2.0 + (pullNum - 1) * 0.3 + 0 },     -- First slot
                { isSpinning = true, stopTime = 2.0 + (pullNum - 1) * 0.3 + 0.5 },   -- Second slot
                { isSpinning = true, stopTime = 2.0 + (pullNum - 1) * 0.3 + 1.0 }    -- Third slot
            },
            result = results[pullNum]
        }
    end

    local elapsed = 0
    local animSpeed = 0.05
    local allStopped = false

    -- Main animation ticker
    self.x10AnimTicker = C_Timer.NewTicker(animSpeed, function()
        elapsed = elapsed + animSpeed
        local stillSpinning = false

        for pullNum = 1, 10 do
            local pullData = animationData[pullNum]
            local group = frame.pullGroups[pullNum]

            for slotNum = 1, 3 do
                local slotData = pullData.slots[slotNum]
                local slot = group.slots[slotNum]

                if slotData.isSpinning then
                    stillSpinning = true

                    -- Check if time to stop
                    if elapsed >= slotData.stopTime then
                        slotData.isSpinning = false

                        -- Show final result
                        local tier = pullData.result.tiers[slotNum]
                        local item = pullData.result.items[slotNum]

                        self:ShowSlotResult(slot, tier, item)

                        -- Play stop sound
                        PlaySound(3175, "SFX")

                        -- Check if all 3 slots of this pull stopped
                        local allThreeStopped = true
                        for i = 1, 3 do
                            if pullData.slots[i].isSpinning then
                                allThreeStopped = false
                                break
                            end
                        end

                        -- If all 3 stopped, check for match
                        if allThreeStopped then
                            self:CheckAndShowMatch(pullNum, pullData.result, group)
                        end
                    else
                        -- Keep spinning - show random tiers
                        if math.random() < 0.3 then  -- Change 30% of the time
                            local randomTier = self:GetRandomTier()
                            local color = TIER_INFO[randomTier].color

                            slot.tierBanner:SetBackdropColor(color.r, color.g, color.b, 0.3)
                            slot.tierText:SetText(randomTier)
                            slot.tierText:SetTextColor(1, 1, 1, 0.5)

                            -- Random icon
                            if math.random() < 0.5 then
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
        end

        -- All animations complete
        if not stillSpinning and not allStopped then
            allStopped = true
            self:OnX10AnimationComplete(results)
        end
    end)
end

-- Show final result in a slot
function Gacha:ShowSlotResult(slot, tier, item)
    local tierInfo = TIER_INFO[tier]

    -- Set tier banner
    slot.tierBanner:SetBackdropColor(tierInfo.color.r, tierInfo.color.g, tierInfo.color.b, 0.9)
    slot.tierText:SetText(tier)
    slot.tierText:SetTextColor(1, 1, 1, 1)

    -- Set item
    if item then
        slot.icon:SetTexture(item.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        slot.icon:SetAlpha(1.0)

        -- Shortened name for space
        local itemName = item.name or "Unknown"
        if string.len(itemName) > 12 then
            itemName = string.sub(itemName, 1, 10) .. ".."
        end

        local qualityColor = ITEM_QUALITY_COLORS[item.quality or 1] or {r=1, g=1, b=1}
        slot.itemText:SetTextColor(qualityColor.r, qualityColor.g, qualityColor.b)
        slot.itemText:SetText(itemName)
    end

    -- Highlight based on tier rarity
    if tier == "SS" then
        slot:SetBackdropBorderColor(1, 0.5, 0, 1)  -- Orange
    elseif tier == "S" then
        slot:SetBackdropBorderColor(1, 0.84, 0, 1)  -- Gold
    elseif tier == "A" then
        slot:SetBackdropBorderColor(0.6, 0.2, 0.8, 1)  -- Purple
    else
        slot:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)  -- Normal
    end
end

-- Check and show match for a single pull
function Gacha:CheckAndShowMatch(pullNum, result, group)
    local tier1 = result.tiers[1]
    local tier2 = result.tiers[2]
    local tier3 = result.tiers[3]

    if tier1 == tier2 and tier2 == tier3 then
        -- MATCH!
        group.matchIndicator:SetText(string.format("|cffff0000MATCH! %s TRIPLE!|r", tier1))

        -- Flash the group
        for i = 1, 3 do
            group.slots[i]:SetBackdropBorderColor(1, 0, 0, 1)
        end

        -- Mark the victim slot
        if result.victim then
            local victimSlot = result.victimSlot or math.random(1, 3)
            group.slots[victimSlot].deleteMarker:Show()

            if result.deleteCount and result.deleteCount > 1 then
                group.slots[victimSlot].deleteMarker:SetText(tostring(result.deleteCount))
            else
                group.slots[victimSlot].deleteMarker:SetText("X")
            end
        end

        -- Play match sound
        PlaySound(888, "SFX")
    else
        group.matchIndicator:SetText("|cff00ff00Safe|r")
    end
end

-- Handle completion of all animations
function Gacha:OnX10AnimationComplete(results)
    local frame = self.x10AnimFrame

    -- Cancel ticker
    if self.x10AnimTicker then
        self.x10AnimTicker:Cancel()
        self.x10AnimTicker = nil
    end

    -- Count total matches and deletions
    local totalMatches = 0
    local totalDeletions = 0

    for _, result in ipairs(results) do
        if result.hasMatch then
            totalMatches = totalMatches + 1
            totalDeletions = totalDeletions + (result.deleteCount or 1)
        end
    end

    -- Update summary
    if totalMatches > 0 then
        frame.summaryText:SetText(string.format(
            "|cffff0000%d MATCHES! %d items to delete!|r",
            totalMatches, totalDeletions
        ))

        -- Show deletion instructions
        self:ShowX10DeleteInstructions(results)
    else
        frame.summaryText:SetText("|cff00ff00All items safe! No matches!|r")
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

-- Calculate all x10 results (reuse existing logic)
function Gacha:CalculateX10Results()
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
            -- Check for shards
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

-- Show deletion instructions for animated x10
function Gacha:ShowX10DeleteInstructions(results)
    -- Handle both old and new calling conventions
    if not results then
        -- Called from old code - use x10DeleteList if available
        if self.x10DeleteList and #self.x10DeleteList > 0 then
            print("|cffff0000=== x10 PULL DELETIONS REQUIRED ===|r")
            print(string.format("|cffffcc00You must delete %d items:|r", #self.x10DeleteList))

            for i, entry in ipairs(self.x10DeleteList) do
                local item = entry.item
                local count = entry.count or 1
                if count > 1 then
                    print(string.format("  %d. %dx %s", i, count, item.link or item.name))
                else
                    print(string.format("  %d. %s", i, item.link or item.name))
                end
            end

            print("|cffff0000Delete these items manually from your bags!|r")
        end
        return
    end

    -- New animated version with results parameter
    print("|cffff0000=== x10 PULL DELETIONS REQUIRED ===|r")

    local deleteList = {}

    for pullNum, result in ipairs(results) do
        if result.hasMatch and result.victim then
            table.insert(deleteList, {
                pullNum = pullNum,
                item = result.victim,
                count = result.deleteCount or 1
            })
        end
    end

    if #deleteList > 0 then
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
end

-- Hook the x10 button to use animated version
function Gacha:SetupX10Animation()
    -- Try multiple times to ensure UI is ready
    local attempts = 0
    local maxAttempts = 10

    local function TrySetup()
        attempts = attempts + 1

        if self.frame and self.frame.pull10Button then
            -- Successfully found the button - set up the animation
            self.frame.pull10Button:SetScript("OnClick", function()
                PlaySound(856, "SFX")
                print("|cffffcc00Starting x10 ANIMATED pull!|r")  -- Debug message
                Gacha:Pull10Animated()  -- Use animated version
            end)
            print("|cff00ff00x10 Animation hooked successfully!|r")
            return true
        elseif attempts < maxAttempts then
            -- Try again in 0.5 seconds
            C_Timer.After(0.5, TrySetup)
            return false
        else
            print("|cffff0000Failed to hook x10 animation - using default|r")
            return false
        end
    end

    TrySetup()
end