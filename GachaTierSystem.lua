-- CattosShuffle - Gacha Tier System
-- Author: Amke & Assistant
-- Version: 2.0.0

local addonName, CattosShuffle = ...
local L = CattosShuffle.L

-- Initialize Gacha Module
CattosShuffle.Gacha = {}
local Gacha = CattosShuffle.Gacha

-- Tier Definitions (like Gacha games)
local TIER_INFO = {
    ["C"] = {
        name = "C Tier",
        color = {r=0.5, g=0.5, b=0.5},
        hex = "ff808080",
        weight = 70,  -- 70% base chance
        description = "Junk & Non-Equipable Items"
    },
    ["B"] = {
        name = "B Tier",
        color = {r=0.6, g=0.8, b=1.0},
        hex = "ff99ccff",
        weight = 20,  -- 20% base chance
        description = "Quest Items & Consumables"
    },
    ["A"] = {
        name = "A Tier",
        color = {r=0.6, g=0.2, b=0.8},
        hex = "ff9933cc",
        weight = 8,   -- 8% base chance
        description = "Equipable Gear (Not Worn)"
    },
    ["S"] = {
        name = "S Tier",
        color = {r=1.0, g=0.84, b=0},
        hex = "ffffd700",
        weight = 2,   -- 2% base chance
        description = "Currently Equipped Items"
    },
    ["SS"] = {
        name = "SS Tier",
        color = {r=1.0, g=0.5, b=0},
        hex = "ffff8000",
        weight = 0.5, -- 0.5% base chance (ULTRA RARE)
        description = "Epic/Legendary Equipped"
    }
}

-- Rarity multipliers for tier upgrades
local RARITY_UPGRADE = {
    [3] = 1,  -- Rare: upgrades tier by 1
    [4] = 2,  -- Epic: upgrades tier by 2
    [5] = 3,  -- Legendary: upgrades tier by 3
}

-- State
Gacha.itemPool = {}
Gacha.tierPools = {
    ["C"] = {},
    ["B"] = {},
    ["A"] = {},
    ["S"] = {},
    ["SS"] = {}
}
Gacha.totalItems = 0
Gacha.isSpinning = false
Gacha.slots = {
    [1] = { current = nil, item = nil },
    [2] = { current = nil, item = nil },
    [3] = { current = nil, item = nil }
}

-- Pity System State
Gacha.shards = 0
Gacha.maxShards = 3

-- Second Pity System (50 spins guarantee)
Gacha.spinCount = 0
Gacha.pityThreshold = 50

-- Third Pity System (B-Tier every 10 rolls)
Gacha.bTierPityCount = 0
Gacha.bTierPityThreshold = 10

-- Check if item is quest item
local function IsQuestItem(itemId)
    if not itemId then return false end

    -- Use tooltip scanning to detect quest items
    local tooltipName = "CattosGachaScanTooltip"
    local tooltip = _G[tooltipName] or CreateFrame("GameTooltip", tooltipName, nil, "GameTooltipTemplate")
    tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")

    -- Set the item
    tooltip:ClearLines()
    tooltip:SetItemByID(itemId)

    -- Scan tooltip lines for "Quest Item"
    for i = 1, tooltip:NumLines() do
        local text = _G[tooltipName.."TextLeft"..i]:GetText()
        if text and (text:find("Quest Item") or text:find("Questgegenstand")) then
            return true
        end
    end

    return false
end

-- Determine item tier
function Gacha:GetItemTier(item)
    local baseType = item.itemType or ""
    local subType = item.itemSubType or ""
    local quality = item.quality or 0
    local isEquipped = item.isEquipped or false

    -- Start with base tier
    local tier = "C"

    -- Quest items are B tier
    if item.isQuest or IsQuestItem(item.itemId) then
        tier = "B"
    -- Consumables are B tier
    elseif baseType == "Consumable" then
        tier = "B"
    -- Equipable items (Armor/Weapon) are A tier
    elseif baseType == "Armor" or baseType == "Weapon" then
        tier = "A"

        -- If currently equipped, upgrade to S tier
        if isEquipped then
            tier = "S"

            -- If Epic/Legendary equipped, upgrade to SS tier
            if quality >= 4 then
                tier = "SS"
            end
        end
    -- Trade goods, reagents etc are C tier
    else
        tier = "C"
    end

    -- Apply rarity upgrade for non-equipped items
    if not isEquipped and quality >= 3 then
        local upgrade = RARITY_UPGRADE[quality] or 0

        -- Upgrade tier based on rarity
        if tier == "C" and upgrade >= 1 then
            tier = "B"
        elseif tier == "B" and upgrade >= 1 then
            tier = "A"
        elseif tier == "A" and upgrade >= 2 then
            tier = "S"
        end
    end

    return tier
end

-- Scan entire inventory and build item pool
function Gacha:BuildItemPool()
    self.itemPool = {}
    self.tierPools = {
        ["C"] = {},
        ["B"] = {},
        ["A"] = {},
        ["S"] = {},
        ["SS"] = {}
    }
    self.totalItems = 0

    -- Scan equipped items (S/SS Tier potential)
    for slotIdx, slotInfo in pairs(CattosShuffle.SHEET_SLOTS) do
        local slotId = GetInventorySlotInfo(slotInfo.slotId)
        local itemId = GetInventoryItemID("player", slotId)
        if itemId then
            local name, link, quality, iLevel, reqLevel, itemType, itemSubType, maxStack, equipSlot, texture = GetItemInfo(itemId)
            if name then
                local item = {
                    itemId = itemId,
                    name = name,
                    link = link,
                    quality = quality,
                    icon = texture,
                    itemType = itemType,
                    itemSubType = itemSubType,
                    location = "equipped",
                    slotId = slotId,
                    slotName = slotInfo.name,
                    isEquipped = true,
                    iLevel = iLevel or 0
                }

                local tier = self:GetItemTier(item)
                item.tier = tier

                table.insert(self.itemPool, item)
                table.insert(self.tierPools[tier], item)
                self.totalItems = self.totalItems + 1
            end
        end
    end

    -- Scan bags (all tiers possible)
    for bag = 0, 4 do
        local numSlots = 0
        if C_Container and C_Container.GetContainerNumSlots then
            numSlots = C_Container.GetContainerNumSlots(bag)
        else
            numSlots = GetContainerNumSlots(bag)
        end

        for slot = 1, numSlots do
            local itemInfo = nil
            local itemId = nil
            local itemLink = nil

            if C_Container and C_Container.GetContainerItemInfo then
                itemInfo = C_Container.GetContainerItemInfo(bag, slot)
                if itemInfo then
                    itemId = itemInfo.itemID
                    itemLink = itemInfo.hyperlink
                end
            else
                -- Old API
                local _, count, _, _, _, _, link, _, _, id = GetContainerItemInfo(bag, slot)
                if id then
                    itemId = id
                    itemLink = link
                    itemInfo = { stackCount = count }
                end
            end

            if itemId then
                local name, link, quality, iLevel, reqLevel, itemType, itemSubType, maxStack, equipSlot, texture = GetItemInfo(itemId)
                if name then
                    local item = {
                        itemId = itemId,
                        name = name,
                        link = link or itemLink,
                        quality = quality,
                        icon = texture,
                        itemType = itemType,
                        itemSubType = itemSubType,
                        location = "bag",
                        bag = bag,
                        slot = slot,
                        stackCount = itemInfo.stackCount or 1,
                        isEquipped = false,
                        iLevel = iLevel or 0,
                        isQuest = itemInfo.isQuestItem or IsQuestItem(itemId)
                    }

                    local tier = self:GetItemTier(item)
                    item.tier = tier

                    table.insert(self.itemPool, item)
                    table.insert(self.tierPools[tier], item)
                    self.totalItems = self.totalItems + 1
                end
            end
        end
    end

    -- Calculate tier weights based on actual distribution
    self:UpdateTierWeights()
end

-- Update tier weights based on pool distribution
function Gacha:UpdateTierWeights()
    self.tierWeights = {}
    self.totalWeight = 0

    for tier, info in pairs(TIER_INFO) do
        local count = #self.tierPools[tier]
        local baseWeight = info.weight

        -- Adjust weight based on pool size
        local weight = baseWeight
        if count == 0 then
            weight = 0  -- No items = no chance
        elseif count <= 3 then
            weight = baseWeight * 0.3  -- Very few items = lower chance
        elseif count <= 10 then
            weight = baseWeight * 0.7  -- Few items = slightly lower chance
        end

        -- Special boost for SS tier if only 1-2 items (make it special!)
        if tier == "SS" and count > 0 and count <= 2 then
            weight = 1  -- Slightly higher for ultra rare
        end

        self.tierWeights[tier] = weight
        self.totalWeight = self.totalWeight + weight
    end
end

-- Get random tier based on weights
function Gacha:GetRandomTier()
    if self.totalWeight == 0 then return "C" end

    local random = math.random() * self.totalWeight
    local current = 0

    for tier, weight in pairs(self.tierWeights) do
        current = current + weight
        if random <= current then
            return tier
        end
    end

    return "C"  -- Fallback
end

-- Get random item from tier
function Gacha:GetRandomItemFromTier(tier)
    local pool = self.tierPools[tier]
    if not pool or #pool == 0 then
        -- If tier is empty, downgrade to next tier
        if tier == "SS" then return self:GetRandomItemFromTier("S")
        elseif tier == "S" then return self:GetRandomItemFromTier("A")
        elseif tier == "A" then return self:GetRandomItemFromTier("B")
        elseif tier == "B" then return self:GetRandomItemFromTier("C")
        else return nil end
    end

    return pool[math.random(1, #pool)]
end

-- Start the gacha pull
function Gacha:Pull(pullCount)
    pullCount = pullCount or 1  -- Default to 1 pull

    if self.isSpinning then
        print("|cffff0000Already pulling!|r")
        return
    end

    if self.selectionTimer then
        print("|cffff0000Selection in progress!|r")
        return
    end

    if self.countAnimTimer then
        print("|cffff0000Stack count animation in progress!|r")
        return
    end

    if InCombatLockdown() or UnitAffectingCombat("player") then
        print("|cffff0000Cannot pull during combat!|r")
        return
    end

    -- Store pull count for later use
    self.currentPullCount = pullCount
    self.currentPullIndex = 1

    -- Start the first pull
    self:DoPull()
end

-- Do a single pull
function Gacha:DoPull()
    -- Build fresh item pool
    self:BuildItemPool()

    if self.totalItems == 0 then
        print("|cffff0000No items found in inventory!|r")
        return
    end

    self.isSpinning = true

    -- Clear any existing count displays from previous pulls
    if self.frame and self.frame.slots then
        for i = 1, 3 do
            local slot = self.frame.slots[i]
            if slot and slot.countDisplay then
                slot.countDisplay:SetText("")
                slot.countDisplay:SetPoint("CENTER", slot, "CENTER", 0, 0)  -- Reset position
                slot.deleteCount = nil
            end
        end
    end

    -- Increment spin counter
    self.spinCount = self.spinCount + 1
    CattosShuffleDB.gachaSpinCount = self.spinCount

    -- Increment B-Tier pity counter
    self.bTierPityCount = self.bTierPityCount + 1
    CattosShuffleDB.gachaBTierPityCount = self.bTierPityCount

    -- Check pity systems (50-spin has priority over B-Tier)
    local forcedPityTier = nil

    -- Check if we hit the 50 spin pity FIRST (higher priority)
    if self.spinCount >= self.pityThreshold then
        -- 50/50 between S and A tier
        if math.random() < 0.5 then
            forcedPityTier = "S"
            print("|cffffcc00>>> 50-SPIN PITY: S TIER GUARANTEED! <<<|r")
        else
            forcedPityTier = "A"
            print("|cff9933cc>>> 50-SPIN PITY: A TIER GUARANTEED! <<<|r")
        end

        -- Reset spin counter
        self.spinCount = 0
        CattosShuffleDB.gachaSpinCount = 0

        -- NOTE: B-Tier pity continues counting independently!

    -- Check for B-Tier pity (every 10 rolls) - only if 50-spin didn't trigger
    elseif self.bTierPityCount >= self.bTierPityThreshold then
        forcedPityTier = "B"
        print("|cff99ccff>>> 10-ROLL PITY: B TIER TRIPLE GUARANTEED! <<<|r")

        -- Reset B-Tier pity counter
        self.bTierPityCount = 0
        CattosShuffleDB.gachaBTierPityCount = 0

        -- NOTE: 50-spin pity continues counting independently!
    end

    -- Determine results for 3 slots
    -- Track used items to show variety (optional)
    local usedItems = {}

    for i = 1, 3 do
        local tier
        local item

        -- If pity is active, force all 3 slots to the pity tier
        if forcedPityTier then
            tier = forcedPityTier
            item = self:GetRandomItemFromTier(tier)
        else
            tier = self:GetRandomTier()
            item = self:GetRandomItemFromTier(tier)
        end

        self.slots[i] = {
            tier = tier,
            item = item,
            isSpinning = true,
            spinTimer = 0
        }

        -- Track if same item appears multiple times
        if item then
            usedItems[item.itemId] = (usedItems[item.itemId] or 0) + 1
        end
    end

    -- Debug: Show if duplicates were pulled
    for itemId, count in pairs(usedItems) do
        if count > 1 then
            print(string.format("|cffffcc00Note: Same item pulled %dx|r", count))
            break
        end
    end

    -- Play multiple sounds for dramatic effect
    PlaySound(168, "SFX")  -- Chest opening sound
    C_Timer.After(0.2, function()
        PlaySound(63, "SFX")  -- Lever pull sound
    end)

    print("|cffffcc00>>> GACHA PULL <<<|r")
    print("|cffccccccSpinning the slots...|r")

    -- Start animation
    self:AnimatePull()
end

-- Animate the gacha pull (Slot Machine Style)
function Gacha:AnimatePull()
    -- Each slot has different spin duration (like real slot machines)
    local slot1Duration = 3.5   -- First slot stops first
    local slot2Duration = 5.0   -- Second slot stops later
    local slot3Duration = 6.5   -- Third slot stops last

    -- Animation speed
    local spinSpeed = 0.05  -- Update every 50ms for smoother animation

    -- Initialize all slots as spinning
    for i = 1, 3 do
        self.slots[i].isSpinning = true
        self.slots[i].displayTier = nil
        self.slots[i].displayItem = nil
        self.slots[i].spinTimer = 0
    end

    -- Start the spinning animation
    self.animationTimer = C_Timer.NewTicker(spinSpeed, function()
        local allStopped = true

        for i = 1, 3 do
            local slot = self.slots[i]

            if slot.isSpinning then
                allStopped = false
                slot.spinTimer = slot.spinTimer + spinSpeed

                -- Determine when to stop this slot
                local stopTime = 0
                if i == 1 then stopTime = slot1Duration
                elseif i == 2 then stopTime = slot2Duration
                elseif i == 3 then stopTime = slot3Duration end

                if slot.spinTimer >= stopTime then
                    -- STOP! Show final result with dramatic effect
                    slot.isSpinning = false
                    slot.displayTier = slot.tier
                    slot.displayItem = slot.item

                    -- Play slot stop sound
                    PlaySound(3175, "SFX")  -- Slot machine stop sound

                    -- Print which slot stopped
                    print(string.format("|cffffcc00[Slot %d]|r stopped at |c%s%s Tier|r",
                        i,
                        TIER_INFO[slot.tier].hex,
                        slot.tier))

                    -- Add a brief flash effect when stopping
                    if self.FlashSlot then
                        self:FlashSlot(i)
                    end

                    -- Check if this creates a potential match
                    if i == 2 then
                        -- Second slot stopped, check if it matches first
                        if self.slots[1].tier == self.slots[2].tier then
                            print("|cffff8800>>> Two matching! Will the third match? <<<|r")
                        end
                    end
                else
                    -- Keep spinning - show random items quickly
                    local progress = slot.spinTimer / stopTime

                    -- Slow down as we approach the stop time (deceleration)
                    local changeChance = 1.0
                    if progress > 0.5 then
                        changeChance = 0.8  -- Start slowing
                    end
                    if progress > 0.65 then
                        changeChance = 0.6  -- Slower
                    end
                    if progress > 0.75 then
                        changeChance = 0.4  -- Much slower
                    end
                    if progress > 0.85 then
                        changeChance = 0.25  -- Very slow
                    end
                    if progress > 0.92 then
                        changeChance = 0.15  -- Crawling
                    end
                    if progress > 0.96 then
                        changeChance = 0.08  -- Almost stopped
                    end

                    if math.random() < changeChance then
                        -- Pick random tier and item to display
                        local randomTier = self:GetRandomTier()
                        local randomItem = self:GetRandomItemFromTier(randomTier)

                        slot.displayTier = randomTier
                        slot.displayItem = randomItem
                    end
                end
            end
        end

        -- Update display
        if self.UpdateUI then
            self:UpdateUI()
        end

        -- All slots stopped - show results
        if allStopped then
            self.animationTimer:Cancel()
            self.animationTimer = nil

            -- Mark animation as complete IMMEDIATELY
            self.isSpinning = false

            -- Update UI to re-enable button
            if self.UpdateUI then
                self:UpdateUI()
            end

            -- Small delay before showing results
            C_Timer.After(0.5, function()
                self:OnPullComplete()
            end)
        end
    end)
end

-- Handle pull completion
function Gacha:OnPullComplete()
    -- isSpinning already set to false in AnimatePull

    -- Check for matches
    local tier1 = self.slots[1].tier
    local tier2 = self.slots[2].tier
    local tier3 = self.slots[3].tier

    -- Display results
    print("-------------------------")
    for i = 1, 3 do
        local slot = self.slots[i]
        local tierInfo = TIER_INFO[slot.tier]
        local item = slot.item

        if item then
            print(string.format("  [%d] |c%s%s|r: %s",
                i,
                tierInfo.hex,
                tierInfo.name,
                item.link or item.name))
        end
    end
    print("-------------------------")

    -- Check for triple match
    if tier1 == tier2 and tier2 == tier3 then
        local tierInfo = TIER_INFO[tier1]
        print(string.format("|c%s>>> TRIPLE %s! <<<|r", tierInfo.hex, tierInfo.name))

        -- Reset appropriate pity counters based on tier
        if tier1 == "B" then
            -- Reset B-Tier pity on B triple
            self.bTierPityCount = 0
            CattosShuffleDB.gachaBTierPityCount = 0
            print("|cff99ccffB-Tier pity counter reset!|r")
        end

        -- Reset main pity only on S or A triple (independent from B-Tier)
        if tier1 == "S" or tier1 == "A" then
            self.spinCount = 0
            CattosShuffleDB.gachaSpinCount = 0
            print("|cffffcc0050-Spin pity counter reset!|r")
        end

        -- Animate the selection process
        print("|cffffcc00Selecting random item to delete...|r")
        self:AnimateVictimSelection()
    else
        -- Check if at least one S or SS tier was rolled for Pity System
        local hasHighTier = false
        for i = 1, 3 do
            if self.slots[i].tier == "S" or self.slots[i].tier == "SS" then
                hasHighTier = true
                break
            end
        end

        if hasHighTier then
            -- Award a shard for rolling high tier but not matching
            self.shards = math.min(self.shards + 1, self.maxShards)

            -- Save shards to DB
            if not CattosShuffleDB then CattosShuffleDB = {} end
            CattosShuffleDB.gachaShards = self.shards

            print(string.format("|cffffcc00You earned a Pity Shard! (%d/%d)|r", self.shards, self.maxShards))

            if self.shards >= self.maxShards then
                print("|cff00ff00You have 3 shards! Click the shard icon to switch to Shuffle mode!|r")
            end
        else
            print("|cff00ff00No match - items are safe!|r")
        end

        PlaySound(3332, "SFX")  -- Quest complete sound
    end

    -- Update UI to show shard count
    if self.UpdateUI then
        self:UpdateUI()
    end

    -- Check if we have more pulls to do
    if self.currentPullCount and self.currentPullIndex then
        if self.currentPullIndex < self.currentPullCount then
            -- More pulls to do
            self.currentPullIndex = self.currentPullIndex + 1

            -- Show pull progress
            print(string.format("|cffffcc00Pull %d/%d complete. Starting next pull...|r",
                self.currentPullIndex - 1, self.currentPullCount))

            -- Wait a moment before next pull
            C_Timer.After(1.5, function()
                -- Only continue if no match (no deletion pending)
                if not self.pendingDelete then
                    self:DoPull()
                else
                    -- If there's a pending delete, stop the multi-pull
                    print("|cffff0000Multi-pull stopped due to match! Handle deletion first.|r")
                    self.currentPullCount = nil
                    self.currentPullIndex = nil
                end
            end)
        else
            -- All pulls complete
            print(string.format("|cff00ff00All %d pulls complete!|r", self.currentPullCount))
            self.currentPullCount = nil
            self.currentPullIndex = nil
        end
    end
end

-- Auto-delete item with Delete confirmation
function Gacha:AutoDeleteItem(item)
    if InCombatLockdown() then
        print("|cffff0000Cannot delete during combat!|r")
        return
    end

    -- Check if item is stackable and has multiple
    local deleteCount = 1
    if item.stackCount and item.stackCount > 1 then
        -- Random amount between 1 and stack size
        deleteCount = math.random(1, item.stackCount)
        print(string.format("|cffffcc00Stack of %d detected! Will delete %d...|r", item.stackCount, deleteCount))
    end

    -- Store deletion info for the dialog
    self.pendingDelete = {
        item = item,
        count = deleteCount
    }

    -- Create input dialog
    StaticPopupDialogs["CATTOS_GACHA_DELETE_CONFIRM"] = {
        text = string.format("Type |cffff0000Delete|r to confirm:\n\n%s%s\n\n|cffff0000This cannot be undone!|r",
            deleteCount > 1 and string.format("%dx ", deleteCount) or "",
            item.link or item.name),
        button1 = "Confirm",
        button2 = "Cancel",
        hasEditBox = true,
        editBoxWidth = 100,
        OnShow = function(self)
            self.editBox:SetText("")
            self.editBox:SetFocus()
        end,
        OnAccept = function(self)
            local text = self.editBox:GetText()
            if text:lower() == "delete" then
                Gacha:PerformDeletion()
            else
                print("|cffffcc00You must type 'Delete' to confirm!|r")
            end
        end,
        OnCancel = function()
            print("|cff00ff00Item saved! Deletion cancelled.|r")
            Gacha.pendingDelete = nil
        end,
        EditBoxOnEnterPressed = function(self)
            local text = self:GetText()
            if text:lower() == "delete" then
                Gacha:PerformDeletion()
                self:GetParent():Hide()
            else
                print("|cffffcc00You must type 'Delete' to confirm!|r")
            end
        end,
        EditBoxOnEscapePressed = function(self)
            self:GetParent():Hide()
            print("|cff00ff00Item saved! Deletion cancelled.|r")
            Gacha.pendingDelete = nil
        end,
        timeout = 15,
        whileDead = false,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    StaticPopup_Show("CATTOS_GACHA_DELETE_CONFIRM")
end

-- Perform the actual deletion
function Gacha:PerformDeletion()
    if not self.pendingDelete then return end

    local item = self.pendingDelete.item
    local deleteCount = self.pendingDelete.count

    -- Clear pending delete
    self.pendingDelete = nil

    -- Perform the deletion
    if item.location == "bag" then
        -- If it's a stack and we're not deleting all, split first
        if item.stackCount and item.stackCount > 1 and deleteCount < item.stackCount then
            -- Split the stack
            if C_Container and C_Container.SplitContainerItem then
                C_Container.SplitContainerItem(item.bag, item.slot, deleteCount)
            else
                SplitContainerItem(item.bag, item.slot, deleteCount)
            end

            -- Wait a moment for the split to register
            C_Timer.After(0.1, function()
                if CursorHasItem() then
                    DeleteCursorItem()
                    print(string.format("|cffff0000DELETED: %d x %s|r", deleteCount, item.link or item.name))
                    PlaySound(3334, "SFX")  -- Item destroy sound
                end
            end)
        else
            -- Delete entire stack or single item
            if C_Container and C_Container.PickupContainerItem then
                C_Container.PickupContainerItem(item.bag, item.slot)
            else
                PickupContainerItem(item.bag, item.slot)
            end

            if CursorHasItem() then
                DeleteCursorItem()
                print(string.format("|cffff0000DELETED: %s (entire stack)|r", item.link or item.name))
                PlaySound(3334, "SFX")  -- Item destroy sound
            else
                print("|cffff0000Failed to pick up item for deletion!|r")
            end
        end

    elseif item.location == "equipped" then
        -- For equipped items, pick up and delete
        PickupInventoryItem(item.slotId)

        if CursorHasItem() then
            DeleteCursorItem()
            print(string.format("|cffff0000DELETED: %s (Equipped)|r", item.link or item.name))
            PlaySound(3334, "SFX")  -- Item destroy sound
        else
            print("|cffff0000Failed to pick up equipped item!|r")
        end
    end

    -- Clear multi-pull if it was active (stop after deletion)
    if self.currentPullCount and self.currentPullCount > 1 then
        print("|cffff0000Multi-pull cancelled after deletion.|r")
        self.currentPullCount = nil
        self.currentPullIndex = nil
    end
end

-- Delete the item (ALWAYS manual confirmation)
function Gacha:DeleteItem(item)
    if InCombatLockdown() then
        print("|cffff0000Cannot delete during combat!|r")
        return
    end

    -- ALWAYS show confirmation dialog - no auto-delete
    StaticPopupDialogs["CATTOS_GACHA_DELETE"] = {
        text = string.format("GACHA MATCH! Delete this item?\n\n%s\n|c%s[%s Tier]|r\n\n|cffff0000This cannot be undone!|r",
            item.link or item.name,
            TIER_INFO[item.tier].hex,
            TIER_INFO[item.tier].name),
        button1 = "DELETE",
        button2 = "SAVE",
        OnAccept = function()
            self:ManualDelete(item)
        end,
        OnCancel = function()
            print("|cff00ff00Item saved! You chose mercy.|r")
        end,
        timeout = 20,  -- More time to decide
        whileDead = false,
        hideOnEscape = true,  -- Allow ESC to save item
        preferredIndex = 3,
    }
    StaticPopup_Show("CATTOS_GACHA_DELETE")
end

-- Manual delete with instructions
function Gacha:ManualDelete(item)
    -- Check for combat lockdown
    if InCombatLockdown() then
        print("|cffff0000Cannot delete items during combat!|r")
        return
    end

    print("|cffffcc00>>> MANUAL DELETE MODE <<<|r")
    print("|cffff8800To delete the item, follow these steps:|r")

    if item.location == "bag" then
        print(string.format("1. Open bag %d", item.bag))
        print(string.format("2. Find: %s", item.link or item.name))
        print("3. Click the item while holding SHIFT+ALT")
        print("4. Click 'Delete' in the confirmation dialog")

        -- Put item on cursor for easy identification
        if C_Container and C_Container.PickupContainerItem then
            C_Container.PickupContainerItem(item.bag, item.slot)
        else
            PickupContainerItem(item.bag, item.slot)
        end

        -- Put it back after a moment
        C_Timer.After(0.5, function()
            if CursorHasItem() then
                if C_Container and C_Container.PickupContainerItem then
                    C_Container.PickupContainerItem(item.bag, item.slot)
                else
                    PickupContainerItem(item.bag, item.slot)
                end
            end
        end)

        print("|cff00ff00The item briefly appeared on your cursor for identification.|r")
    elseif item.location == "equipped" then
        print(string.format("1. Open your character panel (C key)"))
        print(string.format("2. Find: %s in slot: %s", item.link or item.name, item.slotName))
        print("3. Click the item while holding SHIFT+ALT")
        print("4. Click 'Delete' in the confirmation dialog")

        -- Highlight the equipped item
        PickupInventoryItem(item.slotId)

        -- Put it back after a moment
        C_Timer.After(0.5, function()
            if CursorHasItem() then
                PickupInventoryItem(item.slotId)
            end
        end)

        print("|cff00ff00The item briefly appeared on your cursor for identification.|r")
    end

    print("|cffccccccOr type /reload to cancel the deletion.|r")
end

-- Get display info for UI
function Gacha:GetSlotDisplay(slotNum)
    local slot = self.slots[slotNum]
    if not slot then return nil end

    -- During spinning, show displayTier/displayItem
    local tier = slot.displayTier or slot.tier or "C"
    local tierInfo = TIER_INFO[tier]
    local item = slot.displayItem or slot.item

    return {
        tier = tier,
        tierInfo = tierInfo,
        item = item,
        spinning = slot.isSpinning or false,
        stopped = not slot.isSpinning and self.isSpinning  -- Stopped while others still spin
    }
end

-- Animate victim selection for triple match
function Gacha:AnimateVictimSelection()
    if not self.frame or not self.frame.slots then return end

    -- Animation settings (faster version)
    local highlightSpeed = 0.08  -- Faster switching
    local totalDuration = 1.5    -- Shorter total time
    local slowdownStart = 0.8    -- Start slowing earlier

    local currentSlot = 1
    local elapsedTime = 0
    local nextSwitch = highlightSpeed
    local victimSlot = math.random(1, 3)  -- Pre-determine the victim
    local switchCount = 0
    local maxSwitches = math.random(8, 12)  -- Fewer switches for faster completion

    -- Clear all highlights first
    for i = 1, 3 do
        if self.frame.slots[i] then
            self.frame.slots[i]:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
            self.frame.slots[i]:SetBackdropColor(0.08, 0.08, 0.15, 0.95)  -- Reset to normal dark background

            -- Reset tier banner if exists
            if self.frame.slots[i].tierBanner then
                local tier = self.slots[i].tier
                if tier and TIER_INFO[tier] then
                    local color = TIER_INFO[tier].color
                    self.frame.slots[i].tierBanner:SetBackdropColor(color.r, color.g, color.b, 0.9)
                end
            end
        end
    end

    -- Play sound for dramatic effect
    PlaySound(3337, "SFX")  -- Roulette tick sound

    -- Start the animation timer
    self.selectionTimer = C_Timer.NewTicker(0.05, function(timer)  -- Back to smooth animation
        elapsedTime = elapsedTime + 0.05

        -- Check if it's time to switch highlight
        if elapsedTime >= nextSwitch then
            -- Move to next slot
            local previousSlot = currentSlot
            currentSlot = currentSlot % 3 + 1
            switchCount = switchCount + 1

            -- Update visuals
            if self.frame.slots[previousSlot] then
                self.frame.slots[previousSlot]:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)  -- Normal
                self.frame.slots[previousSlot]:SetBackdropColor(0.08, 0.08, 0.15, 0.95)  -- Reset background
            end

            if self.frame.slots[currentSlot] then
                -- Intense golden glow
                self.frame.slots[currentSlot]:SetBackdropBorderColor(1, 0.9, 0, 1)  -- Bright gold border
                self.frame.slots[currentSlot]:SetBackdropColor(0.4, 0.3, 0, 0.6)  -- Golden background tint

                -- Keep tier banner original color - don't change it
                PlaySound(862, "SFX")  -- Tick sound for each switch
            end

            -- Calculate next switch time (slowing down effect)
            if elapsedTime > slowdownStart then
                -- Exponentially slow down
                local progress = (elapsedTime - slowdownStart) / (totalDuration - slowdownStart)
                highlightSpeed = 0.08 + (progress * progress * 0.4)  -- Gets slower but not as much
            end

            -- Check if we should stop
            if switchCount >= maxSwitches and currentSlot == victimSlot then
                -- STOP! Final selection
                timer:Cancel()
                self.selectionTimer = nil  -- Clear the timer reference!

                -- Flash the final selection
                self:FlashVictimSlot(victimSlot)

                -- After flash, animate stack count if stackable with multiple
                C_Timer.After(0.5, function()
                    local victim = self.slots[victimSlot].item
                    local slot = self.frame and self.frame.slots and self.frame.slots[victimSlot]

                    if victim then
                        -- Check if stackable AND has more than 1
                        if victim.stackCount and victim.stackCount > 1 then
                            -- Animate the stack count selection
                            self:AnimateStackCount(victimSlot, victim)
                        else
                            -- Single item (or stackable with only 1), show "1" badge
                            print(string.format("|cffff0000SELECTED FOR DELETION: %s|r", victim.link or victim.name))

                            -- Show "1" as a badge for consistency
                            if slot then
                                local parent = slot.iconButton or slot
                                if not slot.countDisplay then
                                    slot.countDisplay = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
                                    slot.countDisplay:SetDrawLayer("OVERLAY", 7)
                                end

                                slot.countDisplay:SetText("1")
                                slot.countDisplay:SetFont("Fonts\\FRIZQT__.TTF", 48, "THICKOUTLINE")  -- Same size as animated numbers
                                slot.countDisplay:SetTextColor(1, 0.2, 0.2)  -- Dark red
                                slot.countDisplay:SetPoint("CENTER", parent, "CENTER", 0, 0)  -- Centered on icon
                                slot.deleteCount = 1
                            end

                            self:ShowManualDeleteInstructions(victim, 1)

                            -- Clear the selection timer so button updates properly
                            self.selectionTimer = nil
                            if self.UpdateUI then
                                self:UpdateUI()
                            end
                        end
                    end
                end)
            end

            nextSwitch = elapsedTime + highlightSpeed
        end
    end)
end

-- Flash the final victim slot dramatically
function Gacha:FlashVictimSlot(slotNum)
    if not self.frame or not self.frame.slots[slotNum] then return end

    local slot = self.frame.slots[slotNum]
    local flashCount = 0
    local maxFlashes = 5

    -- Play dramatic sound
    PlaySound(888, "SFX")  -- PVP warning sound

    C_Timer.NewTicker(0.1, function(timer)
        flashCount = flashCount + 1

        if flashCount % 2 == 0 then
            -- Flash intense red for danger
            slot:SetBackdropBorderColor(1, 0, 0, 1)  -- Bright red
            slot:SetBackdropColor(0.5, 0, 0, 1)       -- Strong red tint
            -- Don't change tier banner color
        else
            -- Flash bright white/gold
            slot:SetBackdropBorderColor(1, 1, 0.8, 1)  -- Bright white-gold
            slot:SetBackdropColor(0.3, 0.3, 0.2, 0.95)  -- Light gold tint
            -- Don't change tier banner color
        end

        if flashCount >= maxFlashes * 2 then
            timer:Cancel()
            -- Final danger state - intense red
            slot:SetBackdropBorderColor(1, 0, 0, 1)  -- Stay bright red
            slot:SetBackdropColor(0.4, 0, 0, 1)      -- Strong red tinted
            -- Keep tier banner original color
        end
    end)
end

-- Animate stack count selection
function Gacha:AnimateStackCount(slotNum, item)
    if not self.frame or not self.frame.slots[slotNum] then return end

    local slot = self.frame.slots[slotNum]
    local maxCount = item.stackCount
    local finalCount = math.random(1, maxCount)  -- Pre-determine the final count

    -- Create count display on higher layer (on iconButton if it exists, otherwise on slot)
    local parent = slot.iconButton or slot
    if not slot.countDisplay then
        slot.countDisplay = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
        slot.countDisplay:SetPoint("CENTER", parent, "CENTER", 0, 0)  -- Center on the icon during animation
        slot.countDisplay:SetTextColor(1, 1, 0)  -- Yellow
        slot.countDisplay:SetFont("Fonts\\FRIZQT__.TTF", 48, "THICKOUTLINE")  -- Bigger font
        slot.countDisplay:SetDrawLayer("OVERLAY", 7)  -- Highest sublayer
    end

    -- Make slot darker for better contrast
    slot:SetBackdropColor(0.05, 0.05, 0.1, 0.98)

    -- Animation settings
    local animationTime = 0
    local animationDuration = 2  -- 2 seconds total
    local switchSpeed = 0.05  -- Start fast
    local nextSwitch = 0
    local currentCount = 1
    local direction = 1

    print(string.format("|cffffcc00Rolling for stack count (1-%d)...|r", maxCount))

    -- Start the count animation
    self.countAnimTimer = C_Timer.NewTicker(0.03, function(timer)
        animationTime = animationTime + 0.03

        if animationTime >= nextSwitch then
            -- Update count
            currentCount = currentCount + direction

            -- Bounce between 1 and max
            if currentCount >= maxCount then
                currentCount = maxCount
                direction = -1
            elseif currentCount <= 1 then
                currentCount = 1
                direction = 1
            end

            -- Display current count
            slot.countDisplay:SetText(tostring(currentCount))

            -- Flash effect
            if animationTime < animationDuration - 0.5 then
                -- Still rolling - flash between yellow and white
                if math.random() > 0.5 then
                    slot.countDisplay:SetTextColor(1, 1, 0)  -- Yellow
                else
                    slot.countDisplay:SetTextColor(1, 1, 1)  -- White
                end
            end

            -- Play tick sound
            if animationTime < animationDuration - 0.5 then
                PlaySound(1210, "SFX")  -- Money sound for each number change
            end

            -- Calculate next switch (slowing down)
            local progress = animationTime / animationDuration
            switchSpeed = 0.05 + (progress * progress * 0.3)
            nextSwitch = animationTime + switchSpeed
        end

        -- Check if we should stop
        if animationTime >= animationDuration then
            timer:Cancel()
            self.countAnimTimer = nil

            -- Set final count with dramatic effect
            slot.countDisplay:SetText(tostring(finalCount))
            slot.countDisplay:SetTextColor(1, 0, 0)  -- Red for danger
            slot.countDisplay:SetFont("Fonts\\FRIZQT__.TTF", 48, "THICKOUTLINE")  -- Keep consistent size

            -- Play final sound
            PlaySound(888, "SFX")  -- Warning sound

            print(string.format("|cffff0000FINAL COUNT: %d of %d|r", finalCount, maxCount))

            -- After a moment, show instructions but KEEP the count visible
            C_Timer.After(2, function()
                -- Keep the count visible with same size
                if slot.countDisplay then
                    local parent = slot.iconButton or slot
                    slot.countDisplay:SetFont("Fonts\\FRIZQT__.TTF", 48, "THICKOUTLINE")  -- Keep same size as during animation
                    slot.countDisplay:SetTextColor(1, 0.2, 0.2)  -- Dark red
                    slot.countDisplay:SetPoint("CENTER", parent, "CENTER", 0, 0)  -- Keep centered on icon
                end

                -- Reset slot background color
                slot:SetBackdropColor(0.08, 0.08, 0.15, 0.95)

                -- Store the count for display
                slot.deleteCount = finalCount

                -- Show delete instructions
                self:ShowManualDeleteInstructions(item, finalCount)

                -- Clear animation timers for UI update
                if self.UpdateUI then
                    self:UpdateUI()
                end
            end)
        end
    end)
end

-- Show manual delete instructions
function Gacha:ShowManualDeleteInstructions(item, count)
    -- Create the instruction dialog
    StaticPopupDialogs["CATTOS_GACHA_MANUAL_DELETE"] = {
        text = string.format("|cffffcc00MANUAL DELETION REQUIRED|r\n\n" ..
            "Please delete the following:\n\n" ..
            "%s%s\n\n" ..
            "|cffff0000Instructions:|r\n" ..
            "1. Open your bags\n" ..
            "2. Find the item\n" ..
            "3. Drag it out of your bag to destroy\n\n" ..
            "%s",
            count > 1 and string.format("|cffff8800%dx|r ", count) or "",
            item.link or item.name,
            count > 1 and item.stackCount > 1 and
                string.format("|cffccccccNote: Split stack to %d first (Shift + Right-Click)|r\n", count) or ""),
        button1 = "I deleted it",
        button2 = "Cancel",
        OnAccept = function()
            print("|cff00ff00Thank you for deleting the item!|r")
            PlaySound(3332, "SFX")  -- Quest complete
        end,
        OnCancel = function()
            print("|cffffcc00Remember: You lost the Gacha! Please delete the item manually.|r")
        end,
        timeout = 0,
        whileDead = false,
        hideOnEscape = true,  -- Allow ESC to close the dialog
        preferredIndex = 3,
    }
    StaticPopup_Show("CATTOS_GACHA_MANUAL_DELETE")
end

-- Flash effect when slot stops
function Gacha:FlashSlot(slotNum)
    if not self.UpdateUI then return end

    -- Create a flash effect by briefly highlighting the slot
    local flashCount = 0
    local maxFlashes = 3

    C_Timer.NewTicker(0.1, function(timer)
        flashCount = flashCount + 1

        if self.frame and self.frame.slots and self.frame.slots[slotNum] then
            local slot = self.frame.slots[slotNum]

            if flashCount % 2 == 0 then
                -- Flash on
                slot:SetBackdropBorderColor(1, 1, 0, 1)  -- Yellow flash
            else
                -- Flash off
                slot:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)  -- Normal
            end
        end

        if flashCount >= maxFlashes * 2 then
            timer:Cancel()
        end
    end)
end

-- Redeem shards to switch to shuffle mode
function Gacha:RedeemShards()
    if self.shards < self.maxShards then
        print(string.format("|cffff0000Need %d more shards! (%d/%d)|r",
            self.maxShards - self.shards, self.shards, self.maxShards))
        return false
    end

    -- Consume shards
    self.shards = 0
    CattosShuffleDB.gachaShards = 0

    -- Hide Gacha window
    if self.frame and self.frame:IsShown() then
        self.frame:Hide()
    end

    -- Switch to Shuffle mode
    print("|cff00ff00Shards redeemed! Switching to Shuffle mode!|r")
    PlaySound(3175, "SFX")  -- Success sound

    -- Open Shuffle UI
    if CattosShuffle and CattosShuffle.frame then
        CattosShuffle.frame:Show()
        CattosShuffle:RefreshUI()
    end

    return true
end

-- Initialize
function Gacha:Initialize()
    -- Load saved shards
    if CattosShuffleDB and CattosShuffleDB.gachaShards then
        self.shards = CattosShuffleDB.gachaShards
    else
        self.shards = 0
    end

    -- Load saved spin count
    if CattosShuffleDB and CattosShuffleDB.gachaSpinCount then
        self.spinCount = CattosShuffleDB.gachaSpinCount
    else
        self.spinCount = 0
    end

    -- Register combat events
    local combatFrame = CreateFrame("Frame")
    combatFrame:RegisterEvent("PLAYER_REGEN_DISABLED")  -- Entering combat
    combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")   -- Leaving combat

    combatFrame:SetScript("OnEvent", function(self, event)
        if event == "PLAYER_REGEN_DISABLED" then
            -- Entering combat - close gacha window if open
            if Gacha.frame and Gacha.frame:IsShown() then
                Gacha.wasVisibleBeforeCombat = true
                Gacha.frame:Hide()
                print("|cffff0000Gacha closed - entering combat!|r")
            else
                Gacha.wasVisibleBeforeCombat = false
            end

            -- Also close item list if open
            if Gacha.itemListFrame and Gacha.itemListFrame:IsShown() then
                Gacha.itemListFrame:Hide()
            end
        elseif event == "PLAYER_REGEN_ENABLED" then
            -- Leaving combat - reopen if it was visible
            if Gacha.wasVisibleBeforeCombat and Gacha.frame then
                Gacha.frame:Show()
                Gacha:BuildItemPool()  -- Rebuild pool after combat
                Gacha:UpdateGachaUI()
                print("|cff00ff00Combat ended - Gacha reopened!|r")
                Gacha.wasVisibleBeforeCombat = false
            end
        end
    end)

    print("|cffffcc00Gacha System Loaded! Pull for items!|r")
end