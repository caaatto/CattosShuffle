-- CattosShuffle - Stack Handler Module
-- Handles deletion of stacked items with variable amounts

local addonName, CattosShuffle = ...
local L = CattosShuffle.L

-- Get detailed stack information for any item
function CattosShuffle:GetStackInfo(bagID, slotID)
    local itemInfo = C_Container.GetContainerItemInfo(bagID, slotID)

    if not itemInfo or not itemInfo.hyperlink then
        return nil
    end

    -- Get item details including max stack size
    local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, maxStackSize = GetItemInfo(itemInfo.hyperlink)

    -- Check if item is actually stackable
    if not maxStackSize or maxStackSize <= 1 then
        return nil -- Not a stackable item
    end

    return {
        name = itemName,
        link = itemLink,
        currentStack = itemInfo.stackCount or 1,
        maxStack = maxStackSize,
        texture = itemInfo.iconFileID,
        quality = itemRarity,
        bagID = bagID,
        slotID = slotID,
        itemType = itemType,
        itemSubType = itemSubType,
        isLocked = itemInfo.isLocked,
        -- Calculate percentage of max stack
        stackPercent = ((itemInfo.stackCount or 1) / maxStackSize) * 100,
        -- Special categories
        isAmmo = itemType == "Projectile",
        isConsumable = itemType == "Consumable",
        isTradeskill = itemType == "Trade Goods" or itemType == "Recipe",
    }
end

-- Delete a specific amount from a stack
function CattosShuffle:DeleteFromStack(bagID, slotID, amount)
    local stackInfo = self:GetStackInfo(bagID, slotID)

    if not stackInfo then
        -- Not stackable, delete entire item
        PickupContainerItem(bagID, slotID)
        DeleteCursorItem()
        return 1 -- Deleted 1 item
    end

    -- Ensure we don't try to delete more than exists
    amount = math.min(amount, stackInfo.currentStack)

    if amount >= stackInfo.currentStack then
        -- Delete entire stack
        PickupContainerItem(bagID, slotID)
        DeleteCursorItem()
        return stackInfo.currentStack
    else
        -- Split and delete partial stack
        SplitContainerItem(bagID, slotID, amount)
        DeleteCursorItem()
        return amount
    end
end

-- Enhanced bag empty that considers stack sizes
function CattosShuffle:SmartBagEmpty(bagIndex)
    local totalDeleted = 0
    local deletedItems = {}

    -- Get all items in the bag
    local numSlots = C_Container.GetContainerNumSlots(bagIndex)
    local items = {}

    for slot = 1, numSlots do
        local itemInfo = C_Container.GetContainerItemInfo(bagIndex, slot)
        if itemInfo then
            local stackInfo = self:GetStackInfo(bagIndex, slot)
            if stackInfo then
                -- It's a stackable item
                table.insert(items, {
                    type = "stack",
                    info = stackInfo,
                    slot = slot
                })
            else
                -- Regular single item
                table.insert(items, {
                    type = "single",
                    info = itemInfo,
                    slot = slot
                })
            end
        end
    end

    -- Randomly select what to delete
    if #items > 0 then
        local victim = items[math.random(#items)]

        if victim.type == "stack" then
            -- For stacked items, delete random amount (10-100% of stack)
            local deletePercent = math.random(10, 100)
            local deleteAmount = math.max(1, math.floor(victim.info.currentStack * deletePercent / 100))

            -- Silent operation

            local deleted = self:DeleteFromStack(bagIndex, victim.slot, deleteAmount)
            totalDeleted = totalDeleted + deleted

            table.insert(deletedItems, {
                name = victim.info.name,
                link = victim.info.link,
                amount = deleted,
                wasStack = true,
                originalStack = victim.info.currentStack
            })
        else
            -- Single item, delete it
            PickupContainerItem(bagIndex, victim.slot)
            DeleteCursorItem()
            totalDeleted = totalDeleted + 1

            table.insert(deletedItems, {
                name = GetItemInfo(victim.info.hyperlink),
                link = victim.info.hyperlink,
                amount = 1,
                wasStack = false
            })
        end
    end

    return totalDeleted, deletedItems
end

-- Stack-aware random item deletion
function CattosShuffle:StackAwareDelete()
    local allStacks = {}

    -- Scan all bags for stackable items
    for bag = 0, 4 do
        local numSlots = C_Container.GetContainerNumSlots(bag)

        for slot = 1, numSlots do
            local stackInfo = self:GetStackInfo(bag, slot)
            if stackInfo then
                table.insert(allStacks, stackInfo)
            end
        end
    end

    if #allStacks == 0 then
        return
    end

    -- Pick random stack
    local victim = allStacks[math.random(#allStacks)]

    -- Determine deletion amount based on item type
    local deleteAmount

    if victim.isAmmo then
        -- Ammo: Can lose 1-100% (brutal for hunters!)
        deleteAmount = math.random(1, victim.currentStack)
    elseif victim.isConsumable then
        -- Consumables: Lose 1-50% (potions, food, etc.)
        deleteAmount = math.random(1, math.max(1, math.floor(victim.currentStack / 2)))
    elseif victim.isTradeskill then
        -- Trade goods: Lose 5-75% (crafting materials)
        local minDelete = math.max(1, math.floor(victim.currentStack * 0.05))
        local maxDelete = math.max(1, math.floor(victim.currentStack * 0.75))
        deleteAmount = math.random(minDelete, maxDelete)
    else
        -- Other stackables: Lose 1-33%
        deleteAmount = math.random(1, math.max(1, math.floor(victim.currentStack / 3)))
    end

    -- Show dramatic message
    local deletePercent = math.floor((deleteAmount / victim.currentStack) * 100)

    self:ShowStackDeleteAnimation(victim, deleteAmount, deletePercent)

    -- Actually delete after animation
    C_Timer.After(2.0, function()
        local actualDeleted = self:DeleteFromStack(victim.bagID, victim.slotID, deleteAmount)

        if CattosShuffleDB.soundEnabled then
            if victim.isAmmo then
                PlaySound(3175, "Master") -- Gunshot
            elseif victim.isConsumable then
                PlaySound(1202, "Master") -- Drinking sound
            else
                PlaySound(3365, "Master") -- Generic delete
            end
        end

        -- Silent operation
    end)
end

-- Visual effect for stack deletion
function CattosShuffle:ShowStackDeleteAnimation(stackInfo, deleteAmount, deletePercent)
    if not self.stackFrame then
        self.stackFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
        self.stackFrame:SetSize(350, 250)
        self.stackFrame:SetPoint("CENTER", 0, 150)
        self.stackFrame:SetFrameStrata("TOOLTIP")

        self.stackFrame:SetBackdrop({
            bgFile = "Interface/DialogFrame/UI-DialogBox-Background-Dark",
            edgeFile = "Interface/DialogFrame/UI-DialogBox-Gold-Border",
            edgeSize = 32,
            insets = { left = 11, right = 11, top = 11, bottom = 11 }
        })
        self.stackFrame:SetBackdropColor(0.1, 0, 0, 0.95)

        -- Item icon
        self.stackFrame.icon = self.stackFrame:CreateTexture(nil, "ARTWORK")
        self.stackFrame.icon:SetSize(64, 64)
        self.stackFrame.icon:SetPoint("TOP", self.stackFrame, "TOP", 0, -30)

        -- Item name
        self.stackFrame.itemName = self.stackFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        self.stackFrame.itemName:SetPoint("TOP", self.stackFrame.icon, "BOTTOM", 0, -10)

        -- Stack info
        self.stackFrame.stackText = self.stackFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        self.stackFrame.stackText:SetPoint("TOP", self.stackFrame.itemName, "BOTTOM", 0, -10)

        -- Delete amount (big red text)
        self.stackFrame.deleteText = self.stackFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        self.stackFrame.deleteText:SetPoint("TOP", self.stackFrame.stackText, "BOTTOM", 0, -10)
        self.stackFrame.deleteText:SetFont("Fonts\\FRIZQT__.TTF", 24, "OUTLINE")

        -- Progress bar
        self.stackFrame.bar = CreateFrame("StatusBar", nil, self.stackFrame)
        self.stackFrame.bar:SetSize(300, 25)
        self.stackFrame.bar:SetPoint("TOP", self.stackFrame.deleteText, "BOTTOM", 0, -15)
        self.stackFrame.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        self.stackFrame.bar:SetMinMaxValues(0, 100)

        -- Bar background
        self.stackFrame.bar.bg = self.stackFrame.bar:CreateTexture(nil, "BACKGROUND")
        self.stackFrame.bar.bg:SetAllPoints()
        self.stackFrame.bar.bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)

        -- Bar text
        self.stackFrame.bar.text = self.stackFrame.bar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        self.stackFrame.bar.text:SetPoint("CENTER")
    end

    -- Update content
    self.stackFrame.icon:SetTexture(stackInfo.texture)
    self.stackFrame.itemName:SetText(stackInfo.link)
    self.stackFrame.stackText:SetText(string.format("Stack: %d / %d", stackInfo.currentStack, stackInfo.maxStack))
    self.stackFrame.deleteText:SetText(string.format("|cffff0000-%d|r", deleteAmount))
    self.stackFrame.deleteText:SetTextColor(1, 0, 0, 1)

    -- Special color based on item type
    local barColor = {1, 0, 0} -- Default red
    if stackInfo.isAmmo then
        barColor = {1, 0.5, 0} -- Orange for ammo
    elseif stackInfo.isConsumable then
        barColor = {0.5, 0, 1} -- Purple for consumables
    elseif stackInfo.isTradeskill then
        barColor = {1, 1, 0} -- Yellow for trade goods
    end

    self.stackFrame.bar:SetStatusBarColor(barColor[1], barColor[2], barColor[3], 1)
    self.stackFrame.bar:SetValue(0)
    self.stackFrame.bar.text:SetText(string.format("%d%%", 0))
    self.stackFrame:Show()

    -- Animate bar
    local animTime = 1.5
    local startTime = GetTime()
    self.stackFrame:SetScript("OnUpdate", function(self)
        local elapsed = GetTime() - startTime
        local progress = math.min(elapsed / animTime, 1)
        local currentPercent = math.floor(deletePercent * progress)

        self.bar:SetValue(currentPercent)
        self.bar.text:SetText(string.format("%d%%", currentPercent))

        -- Pulse effect at certain thresholds
        if currentPercent == 25 or currentPercent == 50 or currentPercent == 75 then
            self.deleteText:SetTextColor(2, 0, 0, 1)
            C_Timer.After(0.1, function()
                self.deleteText:SetTextColor(1, 0, 0, 1)
            end)
        end

        if progress >= 1 then
            self:SetScript("OnUpdate", nil)
            -- Flash and fade
            self.deleteText:SetText(string.format("|cffff0000-%d DELETED!|r", deleteAmount))
            C_Timer.After(0.5, function()
                self:Hide()
            end)
        end
    end)
end

-- Integration with main shuffle system
function CattosShuffle:GetStackAwareItemCount()
    local totalItems = 0
    local totalStacks = 0

    for bag = 0, 4 do
        local numSlots = C_Container.GetContainerNumSlots(bag)

        for slot = 1, numSlots do
            local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
            if itemInfo then
                totalItems = totalItems + (itemInfo.stackCount or 1)
                totalStacks = totalStacks + 1
            end
        end
    end

    return totalItems, totalStacks
end

-- Module loaded silently