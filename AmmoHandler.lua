-- CattosShuffle - Ammo Handler Module
-- Special handling for ammunition (arrows, bullets, etc.)

local addonName, CattosShuffle = ...
local L = CattosShuffle.L

-- Ammo types in Classic Era
local AMMO_TYPES = {
    ["Projectile"] = true,  -- Arrows and Bullets
}

-- Check if an item is ammo
function CattosShuffle:IsAmmo(itemLink)
    if not itemLink then return false end

    local _, _, _, _, _, itemType, itemSubType = GetItemInfo(itemLink)

    -- In Classic Era, ammo is type "Projectile"
    return itemType == "Projectile" or itemSubType == "Arrow" or itemSubType == "Bullet"
end

-- Get ammo information with stack sizes
function CattosShuffle:GetAmmoInfo(bagID, slotID)
    local itemInfo = C_Container.GetContainerItemInfo(bagID, slotID)

    if not itemInfo or not itemInfo.hyperlink then
        return nil
    end

    -- Get item details
    local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, maxStackSize = GetItemInfo(itemInfo.hyperlink)

    if not self:IsAmmo(itemInfo.hyperlink) then
        return nil
    end

    return {
        name = itemName,
        link = itemLink,
        currentStack = itemInfo.stackCount or 1,
        maxStack = maxStackSize or 200,  -- Ammo usually stacks to 200
        texture = itemInfo.iconFileID,
        quality = itemRarity,
        bagID = bagID,
        slotID = slotID,
        itemType = itemType,
        itemSubType = itemSubType,
        -- Calculate percentage of max stack
        stackPercent = ((itemInfo.stackCount or 1) / (maxStackSize or 200)) * 100,
    }
end

-- Scan all bags for ammo
function CattosShuffle:ScanForAmmo()
    local ammoList = {}

    for bag = 0, 4 do
        local numSlots = C_Container.GetContainerNumSlots(bag)

        for slot = 1, numSlots do
            local ammoInfo = self:GetAmmoInfo(bag, slot)
            if ammoInfo then
                table.insert(ammoList, ammoInfo)
            end
        end
    end

    return ammoList
end

-- Special ammo spin - delete random amount of ammo
function CattosShuffle:AmmoRoulette()
    local ammoList = self:ScanForAmmo()

    if #ammoList == 0 then
        return
    end

    -- Pick random ammo stack
    local target = ammoList[math.random(#ammoList)]

    -- Determine how much to delete (1-100% of stack)
    local deletePercent = math.random(1, 100)
    local deleteAmount = math.floor((target.currentStack * deletePercent) / 100)

    -- Ensure we delete at least 1
    deleteAmount = math.max(1, deleteAmount)

    -- Silent operation - no print

    -- Create dramatic effect
    self:ShowAmmoDeleteAnimation(target, deleteAmount, deletePercent)

    -- Actually delete the ammo after animation
    C_Timer.After(2.5, function()
        if deleteAmount >= target.currentStack then
            -- Delete entire stack
            PickupContainerItem(target.bagID, target.slotID)
            DeleteCursorItem()
        else
            -- Split and delete partial stack
            SplitContainerItem(target.bagID, target.slotID, deleteAmount)
            DeleteCursorItem()
        end

        -- Sound effect
        if CattosShuffleDB.soundEnabled then
            PlaySound(3175, "Master")  -- Gunshot sound
        end

        -- Silent operation
    end)
end

-- Visual effect for ammo deletion
function CattosShuffle:ShowAmmoDeleteAnimation(ammoInfo, deleteAmount, deletePercent)
    -- Create temporary frame for animation
    if not self.ammoFrame then
        self.ammoFrame = CreateFrame("Frame", nil, UIParent)
        self.ammoFrame:SetSize(300, 200)
        self.ammoFrame:SetPoint("CENTER", 0, 100)
        self.ammoFrame:SetFrameStrata("TOOLTIP")

        -- Background
        self.ammoFrame.bg = self.ammoFrame:CreateTexture(nil, "BACKGROUND")
        self.ammoFrame.bg:SetAllPoints()
        self.ammoFrame.bg:SetColorTexture(0, 0, 0, 0.8)

        -- Ammo icon
        self.ammoFrame.icon = self.ammoFrame:CreateTexture(nil, "ARTWORK")
        self.ammoFrame.icon:SetSize(64, 64)
        self.ammoFrame.icon:SetPoint("TOP", self.ammoFrame, "TOP", 0, -20)

        -- Text
        self.ammoFrame.text = self.ammoFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        self.ammoFrame.text:SetPoint("TOP", self.ammoFrame.icon, "BOTTOM", 0, -10)

        -- Delete amount
        self.ammoFrame.deleteText = self.ammoFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        self.ammoFrame.deleteText:SetPoint("TOP", self.ammoFrame.text, "BOTTOM", 0, -10)

        -- Percentage bar
        self.ammoFrame.bar = CreateFrame("StatusBar", nil, self.ammoFrame)
        self.ammoFrame.bar:SetSize(250, 20)
        self.ammoFrame.bar:SetPoint("TOP", self.ammoFrame.deleteText, "BOTTOM", 0, -10)
        self.ammoFrame.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        self.ammoFrame.bar:SetMinMaxValues(0, 100)

        -- Bar background
        self.ammoFrame.bar.bg = self.ammoFrame.bar:CreateTexture(nil, "BACKGROUND")
        self.ammoFrame.bar.bg:SetAllPoints()
        self.ammoFrame.bar.bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
    end

    -- Update content
    self.ammoFrame.icon:SetTexture(ammoInfo.texture)
    self.ammoFrame.text:SetText(ammoInfo.name)
    self.ammoFrame.deleteText:SetText(string.format("|cffff0000-%d|r / %d", deleteAmount, ammoInfo.currentStack))

    -- Animate bar
    self.ammoFrame.bar:SetValue(0)
    self.ammoFrame.bar:SetStatusBarColor(1, 0, 0, 1)
    self.ammoFrame:Show()

    -- Animate the bar filling up
    local animTime = 2.0
    local startTime = GetTime()
    self.ammoFrame:SetScript("OnUpdate", function(self)
        local elapsed = GetTime() - startTime
        local progress = math.min(elapsed / animTime, 1)
        self.bar:SetValue(deletePercent * progress)

        if progress >= 1 then
            self:SetScript("OnUpdate", nil)
            C_Timer.After(0.5, function()
                self:Hide()
            end)
        end
    end)
end

-- Removed slash command as requested

-- Special x10 ammo pull - pulls 10 different ammo stacks
function CattosShuffle:AmmoGachaPull()
    local ammoList = self:ScanForAmmo()

    if #ammoList == 0 then
        return
    end

    -- Pull up to 10 random amounts from random stacks
    local pullCount = math.min(10, #ammoList)
    local totalDeleted = 0

    for i = 1, pullCount do
        local ammo = ammoList[math.random(#ammoList)]
        local deleteAmount = math.random(1, math.min(20, ammo.currentStack))

        -- Silent operation
        totalDeleted = totalDeleted + deleteAmount

        -- Actually delete (simplified for demonstration)
        if deleteAmount >= ammo.currentStack then
            PickupContainerItem(ammo.bagID, ammo.slotID)
            DeleteCursorItem()
        else
            SplitContainerItem(ammo.bagID, ammo.slotID, deleteAmount)
            DeleteCursorItem()
        end

        -- Remove from list if stack is gone
        if deleteAmount >= ammo.currentStack then
            for j, a in ipairs(ammoList) do
                if a == ammo then
                    table.remove(ammoList, j)
                    break
                end
            end
        else
            ammo.currentStack = ammo.currentStack - deleteAmount
        end
    end

    -- Return total deleted for potential use
    return totalDeleted
end

-- Integration with main addon spin system
function CattosShuffle:CheckForAmmoAndModify()
    -- This can be called during regular spins to add extra ammo loss
    local ammoList = self:ScanForAmmo()

    if #ammoList > 0 and math.random(1, 100) <= 25 then  -- 25% chance
        local ammo = ammoList[math.random(#ammoList)]
        local bonusLoss = math.random(5, 50)

        -- Silent operation

        -- Delete the bonus ammo
        if bonusLoss <= ammo.currentStack then
            SplitContainerItem(ammo.bagID, ammo.slotID, bonusLoss)
            DeleteCursorItem()
        end
    end
end

-- Module loaded silently