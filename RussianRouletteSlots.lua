-- CattosShuffle - Russian Roulette Slot Machine Module
-- Author: Amke & Assistant
-- Version: 1.0.0

local addonName, CattosShuffle = ...
local L = CattosShuffle.L

-- Module initialization
CattosShuffle.RussianRoulette = {}
local RR = CattosShuffle.RussianRoulette

-- Quality definitions matching the main addon
local QUALITY_INFO = {
    [0] = { name = "Poor", color = {r=0.62, g=0.62, b=0.62}, hex = "ff9d9d9d" },
    [1] = { name = "Common", color = {r=1.00, g=1.00, b=1.00}, hex = "ffffffff" },
    [2] = { name = "Uncommon", color = {r=0.12, g=1.00, b=0.00}, hex = "ff1eff00" },
    [3] = { name = "Rare", color = {r=0.00, g=0.44, b=0.87}, hex = "ff0070dd" },
    [4] = { name = "Epic", color = {r=0.64, g=0.21, b=0.93}, hex = "ffa335ee" },
    [5] = { name = "Legendary", color = {r=1.00, g=0.50, b=0.00}, hex = "ffff8000" },
}

-- Slot machine state
RR.slots = {
    [1] = { current = nil, target = nil, spinning = false },
    [2] = { current = nil, target = nil, spinning = false },
    [3] = { current = nil, target = nil, spinning = false }
}
RR.isSpinning = false
RR.spinTimer = nil
RR.inventory = {}

-- Pity System (like in Gacha games)
RR.safeSpins = 0  -- Count of safe spins (no deletion)
RR.lastDeletion = nil  -- Quality of last deleted item
RR.pendingOpenAfterCombat = false  -- Flag for opening after combat

-- Scan inventory for all items and their qualities
function RR:ScanInventory()
    self.inventory = {
        [0] = {}, -- Poor
        [1] = {}, -- Common
        [2] = {}, -- Uncommon
        [3] = {}, -- Rare
        [4] = {}, -- Epic
        [5] = {}, -- Legendary
    }

    -- Scan equipped items
    for slotIdx, slotInfo in pairs(CattosShuffle.SHEET_SLOTS) do
        local slotId = GetInventorySlotInfo(slotInfo.slotId)
        local itemId = GetInventoryItemID("player", slotId)
        if itemId then
            local name, link, quality, _, _, _, _, _, _, icon = GetItemInfo(itemId)
            if quality and quality >= 0 and quality <= 5 then
                table.insert(self.inventory[quality], {
                    itemId = itemId,
                    name = name or "Unknown",
                    link = link,
                    icon = icon,
                    location = "equipped",
                    slotId = slotId,
                    slotName = slotInfo.name
                })
            end
        end
    end

    -- Scan bags
    for bag = 0, 4 do
        local numSlots = 0
        if C_Container and C_Container.GetContainerNumSlots then
            numSlots = C_Container.GetContainerNumSlots(bag)
        else
            numSlots = GetContainerNumSlots(bag)
        end

        for slot = 1, numSlots do
            local itemInfo = nil
            if C_Container and C_Container.GetContainerItemInfo then
                itemInfo = C_Container.GetContainerItemInfo(bag, slot)
                if itemInfo and itemInfo.itemID then
                    local name, link, quality, _, _, _, _, _, _, icon = GetItemInfo(itemInfo.itemID)
                    if quality and quality >= 0 and quality <= 5 then
                        table.insert(self.inventory[quality], {
                            itemId = itemInfo.itemID,
                            name = name or "Unknown",
                            link = link,
                            icon = icon,
                            location = "bag",
                            bag = bag,
                            slot = slot,
                            stackCount = itemInfo.stackCount or 1
                        })
                    end
                end
            else
                -- Fallback for old API
                local icon, count, _, quality, _, _, link, _, _, itemId = GetContainerItemInfo(bag, slot)
                if itemId and quality and quality >= 0 and quality <= 5 then
                    local name = GetItemInfo(itemId)
                    table.insert(self.inventory[quality], {
                        itemId = itemId,
                        name = name or "Unknown",
                        link = link,
                        icon = icon,
                        location = "bag",
                        bag = bag,
                        slot = slot,
                        stackCount = count or 1
                    })
                end
            end
        end
    end

    -- Calculate available qualities for spinning
    self:UpdateAvailableQualities()
end

-- Determine which qualities can appear on the slots (GACHA SYSTEM)
function RR:UpdateAvailableQualities()
    self.availableQualities = {}
    self.totalWeight = 0

    -- Count total items and items per quality
    local totalItems = 0
    local itemCounts = {}
    for quality = 0, 5 do
        itemCounts[quality] = #self.inventory[quality]
        totalItems = totalItems + itemCounts[quality]
    end

    -- If no items at all, use default weights
    if totalItems == 0 then
        local defaultWeights = {[0] = 30, [1] = 25, [2] = 20, [3] = 15, [4] = 8, [5] = 2}
        for quality = 0, 5 do
            table.insert(self.availableQualities, {
                quality = quality,
                weight = defaultWeights[quality],
                hasItems = false
            })
            self.totalWeight = self.totalWeight + defaultWeights[quality]
        end
        return
    end

    -- GACHA LOGIC: More items of a quality = higher chance to appear
    for quality = 0, 5 do
        local weight = 0
        local count = itemCounts[quality]

        if count > 0 then
            -- Base weight is percentage of inventory
            local percentage = (count / totalItems) * 100

            -- Apply rarity modifiers (inverse of normal - more items = more common)
            if percentage >= 40 then
                -- Dominant quality (40%+ of inventory)
                weight = 35 + (percentage / 2)  -- Can go up to 55% chance
            elseif percentage >= 20 then
                -- Common quality (20-40% of inventory)
                weight = 20 + percentage
            elseif percentage >= 10 then
                -- Uncommon quality (10-20% of inventory)
                weight = 10 + percentage
            elseif percentage >= 5 then
                -- Rare quality (5-10% of inventory)
                weight = 5 + (percentage * 1.5)
            elseif percentage >= 1 then
                -- Very rare quality (1-5% of inventory)
                weight = 3 + percentage
            else
                -- Ultra rare (less than 1% of inventory)
                -- SPECIAL: If you only have 1-2 items of this quality, make it VERY RARE
                if count <= 2 then
                    weight = 0.5 * count  -- 0.5% per item (max 1% for 2 items)
                else
                    weight = 2 + (percentage * 2)
                end
            end

            -- Special case: Legendary/Epic bonus rarity
            if quality >= 4 then
                -- If you have very few epic/legendary items, make them extra rare
                if count <= 3 then
                    weight = weight * 0.3  -- 70% reduction for super rare items
                elseif count <= 5 then
                    weight = weight * 0.5  -- 50% reduction
                end
            end

            -- PITY SYSTEM: After many safe spins, increase chance of match
            if self.safeSpins >= 10 then
                -- After 10 safe spins, gradually increase chances
                local pityBonus = 1 + ((self.safeSpins - 10) * 0.1)  -- +10% per spin after 10
                weight = weight * pityBonus

                -- Cap at 3x original weight
                if weight > (count / totalItems * 100) * 3 then
                    weight = (count / totalItems * 100) * 3
                end
            end
        else
            -- No items of this quality - still small chance to appear (for "lucky" spins)
            -- But make it proportional to surrounding qualities
            local lowerQuality = quality > 0 and itemCounts[quality - 1] or 0
            local higherQuality = quality < 5 and itemCounts[quality + 1] or 0

            if lowerQuality > 0 or higherQuality > 0 then
                weight = 2  -- Small chance if adjacent qualities exist
            else
                weight = 0.5  -- Tiny chance otherwise
            end
        end

        table.insert(self.availableQualities, {
            quality = quality,
            weight = weight,
            hasItems = count > 0,
            count = count,
            percentage = totalItems > 0 and (count / totalItems * 100) or 0
        })
        self.totalWeight = self.totalWeight + weight
    end

    -- Debug output (optional - remove for production)
    if false then  -- Set to true for debugging
        print("Russian Roulette Weights:")
        for _, info in ipairs(self.availableQualities) do
            local qualityName = QUALITY_INFO[info.quality].name
            print(string.format("  %s: %.1f%% chance (%d items, %.1f%% of inventory)",
                qualityName, (info.weight / self.totalWeight) * 100, info.count, info.percentage))
        end
    end
end

-- Get random quality based on weights
function RR:GetRandomQuality()
    if self.totalWeight == 0 then return 1 end -- Default to common

    local random = math.random() * self.totalWeight
    local current = 0

    for _, qualityInfo in ipairs(self.availableQualities) do
        current = current + qualityInfo.weight
        if random <= current then
            return qualityInfo.quality
        end
    end

    return 1 -- Fallback to common
end

-- Start the slot machine spin
function RR:StartSpin()
    if self.isSpinning then
        print(L["SPIN_ALREADY_RUNNING"] or "Spin already in progress!")
        return
    end

    if InCombatLockdown() or UnitAffectingCombat("player") then
        print(L["COMBAT_ERROR"] or "Cannot use during combat!")
        return
    end

    -- Scan current inventory
    self:ScanInventory()

    -- Check if player has any items
    local hasAnyItems = false
    for quality = 0, 5 do
        if #self.inventory[quality] > 0 then
            hasAnyItems = true
            break
        end
    end

    if not hasAnyItems then
        print("|cffff0000No items found in inventory or equipment!|r")
        return
    end

    self.isSpinning = true

    -- Determine final results for each slot
    for i = 1, 3 do
        self.slots[i].target = self:GetRandomQuality()
        self.slots[i].spinning = true
        self.slots[i].current = math.random(0, 5)
    end

    -- Play start sound
    PlaySound(63, "SFX")  -- Lever pull sound

    print("|cffffcc00Russian Roulette Slots spinning...|r")

    -- Start spin animation
    self:AnimateSpin()
end

-- Animate the spinning slots
function RR:AnimateSpin()
    local spinDuration = 3.0  -- Total spin time
    local spinSteps = 30  -- Number of animation steps
    local stepDelay = spinDuration / spinSteps
    local currentStep = 0

    -- Slot stop times (slot 1 stops first, then 2, then 3)
    local stopSteps = {
        [1] = spinSteps * 0.6,  -- Stop at 60% through
        [2] = spinSteps * 0.8,  -- Stop at 80% through
        [3] = spinSteps * 1.0,  -- Stop at 100% through
    }

    self.spinTimer = C_Timer.NewTicker(stepDelay, function()
        currentStep = currentStep + 1

        -- Update each slot
        for i = 1, 3 do
            if self.slots[i].spinning then
                if currentStep >= stopSteps[i] then
                    -- Stop this slot at its target
                    self.slots[i].spinning = false
                    self.slots[i].current = self.slots[i].target

                    -- Play slot stop sound
                    PlaySound(3175, "SFX")  -- Slot machine stop sound
                else
                    -- Continue spinning - cycle through qualities
                    self.slots[i].current = (self.slots[i].current + 1) % 6
                end
            end
        end

        -- Update display
        self:UpdateSlotDisplay()

        -- Check if all slots stopped
        if currentStep >= spinSteps then
            self.spinTimer:Cancel()
            self.spinTimer = nil
            self:OnSpinComplete()
        end
    end, spinSteps)
end

-- Check for matching results and execute roulette
function RR:OnSpinComplete()
    self.isSpinning = false

    local result1 = self.slots[1].current
    local result2 = self.slots[2].current
    local result3 = self.slots[3].current

    -- Check for three of a kind
    if result1 == result2 and result2 == result3 then
        local quality = result1
        local qualityInfo = QUALITY_INFO[quality]

        print(string.format("|c%sTHREE %s! JACKPOT!|r",
            qualityInfo.hex,
            string.upper(qualityInfo.name)))

        -- Check if player has items of this quality
        if #self.inventory[quality] > 0 then
            -- DANGER: Delete a random item of this quality!
            self:ExecuteRoulette(quality)

            -- Reset pity counter after deletion
            self.safeSpins = 0
            self.lastDeletion = quality

            -- Save to DB
            if CattosShuffleDB then
                CattosShuffleDB.rrSafeSpins = 0
            end
        else
            print(string.format("|cff00ff00LUCKY! You don't have any %s items!|r", qualityInfo.name))

            -- Play lucky sound
            PlaySound(888, "SFX")  -- Level up sound for luck!

            -- Still counts as safe spin for pity
            self.safeSpins = self.safeSpins + 1

            -- Save to DB
            if CattosShuffleDB then
                CattosShuffleDB.rrSafeSpins = self.safeSpins
            end
        end
    else
        -- No match - player is safe
        self.safeSpins = self.safeSpins + 1

        -- Save to DB
        if CattosShuffleDB then
            CattosShuffleDB.rrSafeSpins = self.safeSpins
        end

        -- Show pity counter after 5 safe spins
        if self.safeSpins >= 5 then
            print(string.format("|cff00ff00SAFE! No matching qualities! (Safe streak: %d)|r", self.safeSpins))

            if self.safeSpins >= 10 then
                print("|cffffcc00Pity system active - chances increasing!|r")
            end
        else
            print("|cff00ff00SAFE! No matching qualities!|r")
        end

        -- Play safe sound
        PlaySound(3332, "SFX")  -- Quest complete sound for safety
    end

    -- Update display one final time
    self:UpdateSlotDisplay()
end

-- Delete a random item of the specified quality
function RR:ExecuteRoulette(quality)
    -- Check if we're in combat or other protected state
    if InCombatLockdown() then
        print("|cffff0000Cannot delete items during combat!|r")
        return
    end

    local items = self.inventory[quality]
    if #items == 0 then return end

    -- Select random item
    local victim = items[math.random(1, #items)]
    local qualityInfo = QUALITY_INFO[quality]

    print(string.format("|cffff0000DELETING: %s|r", victim.link or victim.name))

    -- Store victim for delayed deletion if needed
    self.pendingDeletion = victim

    -- Show confirmation dialog for rare+ items
    if quality >= 3 then  -- Rare or better
        StaticPopupDialogs["CATTOS_RR_DELETE_CONFIRM"] = {
            text = string.format("Russian Roulette will DELETE:\n\n%s\n\n|cffff0000This cannot be undone!|r",
                victim.link or victim.name),
            button1 = "DELETE IT",
            button2 = "CANCEL",
            OnAccept = function()
                if not InCombatLockdown() then
                    self:DeleteItem(victim)
                else
                    print("|cffff0000Cannot delete during combat! Try again after combat.|r")
                end
            end,
            OnCancel = function()
                print("|cff00ff00Russian Roulette cancelled - item saved!|r")
                self.pendingDeletion = nil
            end,
            timeout = 10,
            whileDead = false,
            hideOnEscape = false,
            preferredIndex = 3,
        }
        StaticPopup_Show("CATTOS_RR_DELETE_CONFIRM")
    else
        -- Auto-delete for common/uncommon items (if not in combat)
        if not InCombatLockdown() then
            self:DeleteItem(victim)
        else
            print("|cffff0000Cannot delete during combat! Item saved this time.|r")
        end
    end
end

-- Actually delete the item
function RR:DeleteItem(item)
    -- Final combat check
    if InCombatLockdown() then
        print("|cffff0000Cannot delete items during combat!|r")
        return
    end

    -- Clear cursor first to avoid issues
    ClearCursor()

    if item.location == "bag" then
        -- Delete from bag
        if C_Container and C_Container.PickupContainerItem then
            C_Container.PickupContainerItem(item.bag, item.slot)
        else
            PickupContainerItem(item.bag, item.slot)
        end

        -- Small delay to ensure item is on cursor
        C_Timer.After(0.1, function()
            if CursorHasItem() then
                DeleteCursorItem()
                print(string.format("|cffff0000DELETED %s from bag %d slot %d!|r",
                    item.name, item.bag, item.slot))
            else
                print("|cffff0000Failed to pick up item - deletion cancelled!|r")
            end
        end)
    elseif item.location == "equipped" then
        -- Delete equipped item
        PickupInventoryItem(item.slotId)

        -- Small delay to ensure item is on cursor
        C_Timer.After(0.1, function()
            if CursorHasItem() then
                DeleteCursorItem()
                print(string.format("|cffff0000DELETED %s from %s slot!|r",
                    item.name, item.slotName))
            else
                print("|cffff0000Failed to pick up item - deletion cancelled!|r")
            end
        end)
    end

    -- Play delete sound
    PlaySound(176, "SFX")  -- Item destroyed sound

    -- Add to history
    if CattosShuffle.history then
        local result = {
            timestamp = time(),
            action = "russian-roulette",
            target = "item",
            winner = item.name,
            quality = item.quality
        }
        table.insert(CattosShuffle.history, 1, result)
        if #CattosShuffle.history > 20 then
            table.remove(CattosShuffle.history)
        end
        CattosShuffleDB.history = CattosShuffle.history
    end
end

-- Update slot display (called by UI)
function RR:UpdateSlotDisplay()
    if self.UpdateUI then
        self:UpdateUI()
    end
end

-- Get current slot display info
function RR:GetSlotDisplay(slotNum)
    local quality = self.slots[slotNum].current

    -- Default to Common (1) if not initialized
    if not quality then
        quality = 1
        self.slots[slotNum].current = 1
    end

    local qualityInfo = QUALITY_INFO[quality]

    -- Safety check
    if not qualityInfo then
        qualityInfo = QUALITY_INFO[1]  -- Default to Common
    end

    return {
        quality = quality,
        color = qualityInfo.color,
        hex = qualityInfo.hex,
        name = qualityInfo.name,
        spinning = self.slots[slotNum].spinning or false
    }
end

-- Stop current spin
function RR:StopSpin()
    if self.spinTimer then
        self.spinTimer:Cancel()
        self.spinTimer = nil
    end

    self.isSpinning = false
    for i = 1, 3 do
        self.slots[i].spinning = false
    end

    print("|cffffcc00Russian Roulette stopped!|r")
end

-- Initialize module
function RR:Initialize()
    -- Initialize slots with default values
    for i = 1, 3 do
        self.slots[i] = {
            current = 1,  -- Default to Common
            target = nil,
            spinning = false
        }
    end

    -- Initialize pity system
    self.safeSpins = CattosShuffleDB and CattosShuffleDB.rrSafeSpins or 0

    -- Register combat events
    local combatFrame = CreateFrame("Frame")
    combatFrame:RegisterEvent("PLAYER_REGEN_DISABLED")  -- Entering combat
    combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")  -- Combat ended
    combatFrame:SetScript("OnEvent", function(self, event)
        if event == "PLAYER_REGEN_DISABLED" then
            -- Entering combat - close RR window if open
            if RR.slotFrame and RR.slotFrame:IsShown() then
                RR.wasVisibleBeforeCombat = true
                RR.slotFrame:Hide()
                print("|cffff0000Russian Roulette closed - entering combat!|r")
            else
                RR.wasVisibleBeforeCombat = false
            end
        elseif event == "PLAYER_REGEN_ENABLED" then
            -- Handle pending deletion notification
            if RR.pendingDeletion then
                print("|cffffcc00Combat ended - pending Russian Roulette deletion can now be executed!|r")
                RR.pendingDeletion = nil  -- Clear it so it doesn't persist
            end

            -- Handle window reopening
            local shouldReopen = RR.wasVisibleBeforeCombat
            RR.wasVisibleBeforeCombat = false

            if shouldReopen and RR.slotFrame then
                RR.slotFrame:Show()
                RR:ScanInventory()
                RR:UpdateSlotUI()
                print("|cff00ff00Combat ended - Russian Roulette reopened!|r")
            end

            -- Handle pending open request from during combat
            if RR.pendingOpenAfterCombat then
                RR.pendingOpenAfterCombat = false
                -- Small delay to ensure combat flag is cleared
                C_Timer.After(0.1, function()
                    print("|cff00ff00Combat ended - opening Russian Roulette as requested!|r")
                    RR:Toggle()
                end)
            end
        end
    end)

    print("|cffffcc00Russian Roulette Slots loaded!|r")
end