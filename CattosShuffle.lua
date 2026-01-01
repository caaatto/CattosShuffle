-- CattosShuffle - Core Module
-- Author: Amke
-- Version: 1.0.0

local addonName, CattosShuffle = ...
_G.CattosShuffle = CattosShuffle
_G.CattosShuffle = CattosShuffle  -- Keep backwards compatibility

-- Get localization
local L = CattosShuffle.L

-- Slot definitions with localized names
CattosShuffle.SHEET_SLOTS = {
    [0]  = { name = L["HEAD"],        slotId = "HeadSlot" },
    [1]  = { name = L["NECK"],        slotId = "NeckSlot" },
    [2]  = { name = L["SHOULDER"],    slotId = "ShoulderSlot" },
    [3]  = { name = L["BACK"],        slotId = "BackSlot" },
    [4]  = { name = L["CHEST"],       slotId = "ChestSlot" },
    [5]  = { name = L["SHIRT"],       slotId = "ShirtSlot" },
    [6]  = { name = L["TABARD"],      slotId = "TabardSlot" },
    [7]  = { name = L["WRIST"],       slotId = "WristSlot" },
    [8]  = { name = L["HANDS"],       slotId = "HandsSlot" },
    [9]  = { name = L["WAIST"],       slotId = "WaistSlot" },
    [10] = { name = L["LEGS"],        slotId = "LegsSlot" },
    [11] = { name = L["FEET"],        slotId = "FeetSlot" },
    [12] = { name = L["RING1"],       slotId = "Finger0Slot" },
    [13] = { name = L["RING2"],       slotId = "Finger1Slot" },
    [14] = { name = L["TRINKET1"],    slotId = "Trinket0Slot" },
    [15] = { name = L["TRINKET2"],    slotId = "Trinket1Slot" },
    [16] = { name = L["MAINHAND"],    slotId = "MainHandSlot" },
    [17] = { name = L["OFFHAND"],     slotId = "SecondaryHandSlot" },
    [18] = { name = L["RANGED"],      slotId = "RangedSlot" },
}

CattosShuffle.BAG_SLOTS = {
    [0] = L["BACKPACK"],  -- Backpack (Container 0)
    [1] = L["BAG1"],      -- ContainerFrame 1
    [2] = L["BAG2"],      -- ContainerFrame 2
    [3] = L["BAG3"],      -- ContainerFrame 3
    [4] = L["BAG4"],      -- ContainerFrame 4
}

-- Casino actions with localized descriptions
CattosShuffle.ACTIONS = {
    ["bag-empty"] = { price = 69, target = "bags", description = L["ACTION_BAG_EMPTY"] },
    ["sheet-rng"] = { price = 100, target = "sheet", description = L["ACTION_SHEET_RNG"] },
    ["bag-delete"] = { price = 150, target = "bags", description = L["ACTION_BAG_DELETE"] },
    ["choice"] = { price = 200, target = "both", description = L["ACTION_CHOICE"] },
}

-- Quality Colors
CattosShuffle.QUALITY_COLORS = {
    [0] = { r = 0.62, g = 0.62, b = 0.62 }, -- Poor (grau)
    [1] = { r = 1.00, g = 1.00, b = 1.00 }, -- Common (weiß)
    [2] = { r = 0.12, g = 1.00, b = 0.00 }, -- Uncommon (grün)
    [3] = { r = 0.00, g = 0.44, b = 0.87 }, -- Rare (blau)
    [4] = { r = 0.64, g = 0.21, b = 0.93 }, -- Epic (lila)
    [5] = { r = 1.00, g = 0.50, b = 0.00 }, -- Legendary (orange)
    [6] = { r = 0.90, g = 0.80, b = 0.50 }, -- Artifact (gold)
    [7] = { r = 0.00, g = 0.80, b = 1.00 }, -- Heirloom (hellblau)
}

-- State
CattosShuffle.isSpinning = false
CattosShuffle.currentAction = nil
CattosShuffle.currentTarget = nil
CattosShuffle.winnerSlot = nil
CattosShuffle.history = {}
CattosShuffle.choiceMode = false
CattosShuffle.wasVisibleBeforeCombat = false

-- Initialize
function CattosShuffle:Initialize()
    -- In Classic Era gibt es kein math.randomseed
    -- Warm up random number generator für bessere Zufälligkeit
    local warmupCount = math.floor(GetTime()) % 20 + 10
    for i = 1, warmupCount do
        math.random()
    end

    -- Load saved variables
    if not CattosShuffleDB then
        CattosShuffleDB = {
            history = {},
            enabledSheetSlots = {},
            enabledBagSlots = {},
            autoMode = true,
            soundEnabled = true,
            soundTheme = "trute",  -- Default sound theme
            position = { x = 0, y = 0 },
        }
    end

    -- Ensure soundTheme exists for older saved vars
    if not CattosShuffleDB.soundTheme then
        CattosShuffleDB.soundTheme = "trute"
    end

    -- Ensure soundEnabled is true by default
    if CattosShuffleDB.soundEnabled == nil then
        CattosShuffleDB.soundEnabled = true
    end

    self.history = CattosShuffleDB.history or {}

    -- Initialize UI if needed
    if self.InitializeUI then
        self:InitializeUI()
    end

    print(L["ADDON_LOADED"])
end

-- Equipment-Funktionen
function CattosShuffle:GetEquippedSlots()
    local equipped = {}
    for idx, slot in pairs(self.SHEET_SLOTS) do
        local slotId = GetInventorySlotInfo(slot.slotId)
        local itemId = GetInventoryItemID("player", slotId)
        if itemId then
            local name, _, quality, _, _, _, _, _, _, icon = GetItemInfo(itemId)
            equipped[idx] = {
                id = itemId,
                name = name or L["UNKNOWN"],
                quality = quality or 1,
                icon = icon,
                slotId = slotId,
                slotName = slot.name,
            }
        end
    end
    return equipped
end

function CattosShuffle:SlotHasItem(slotIndex)
    local slot = self.SHEET_SLOTS[slotIndex]
    if not slot then return false end
    local slotId = GetInventorySlotInfo(slot.slotId)
    return GetInventoryItemID("player", slotId) ~= nil
end

function CattosShuffle:GetValidSheetSlots()
    local valid = {}
    for idx, slot in pairs(self.SHEET_SLOTS) do
        if self:SlotHasItem(idx) then
            table.insert(valid, idx)
        end
    end
    return valid
end

-- Taschen-Funktionen
function CattosShuffle:GetAvailableBags()
    local bags = {}
    for i = 0, 4 do
        -- Try both APIs for compatibility
        local numSlots = 0
        if C_Container and C_Container.GetContainerNumSlots then
            numSlots = C_Container.GetContainerNumSlots(i)
        else
            -- Fallback to old API
            numSlots = GetContainerNumSlots(i)
        end

        if numSlots and numSlots > 0 then
            local itemCount = 0
            for slot = 1, numSlots do
                local itemInfo = nil
                if C_Container and C_Container.GetContainerItemInfo then
                    itemInfo = C_Container.GetContainerItemInfo(i, slot)
                else
                    -- Fallback to old API
                    local texture, count = GetContainerItemInfo(i, slot)
                    if texture then
                        itemInfo = { iconFileID = texture, stackCount = count }
                    end
                end

                if itemInfo then
                    itemCount = itemCount + 1
                end
            end
            bags[i] = {
                name = self.BAG_SLOTS[i],
                slots = numSlots,
                items = itemCount,
                isEmpty = itemCount == 0,
                bagId = i,
            }
        end
    end
    return bags
end

function CattosShuffle:GetBagItemCount(bagIndex)
    local count = 0
    local numSlots = 0

    -- Try both APIs for compatibility
    if C_Container and C_Container.GetContainerNumSlots then
        numSlots = C_Container.GetContainerNumSlots(bagIndex)
    else
        numSlots = GetContainerNumSlots(bagIndex)
    end

    for slot = 1, numSlots do
        local hasItem = false
        if C_Container and C_Container.GetContainerItemInfo then
            hasItem = C_Container.GetContainerItemInfo(bagIndex, slot) ~= nil
        else
            local texture = GetContainerItemInfo(bagIndex, slot)
            hasItem = texture ~= nil
        end

        if hasItem then
            count = count + 1
        end
    end
    return count
end

function CattosShuffle:GetValidBagSlots(action)
    local valid = {}
    local bags = self:GetAvailableBags()

    for bagId, bagInfo in pairs(bags) do
        if action == "bag-empty" then
            -- Nur Taschen mit Items
            if bagInfo.items > 0 then
                table.insert(valid, bagId)
            end
        elseif action == "bag-delete" then
            -- Include ALL bags (including backpack) for first spin
            table.insert(valid, bagId)
        end
    end

    return valid
end

-- Spin-Funktionen
function CattosShuffle:StartSpin(target, action)
    if self.isSpinning then
        print(L["SPIN_ALREADY_RUNNING"])
        return
    end

    -- Check if player is in combat
    if UnitAffectingCombat("player") then
        print(L["COMBAT_ERROR"])
        return
    end

    self.currentTarget = target
    self.currentAction = action

    -- Validate available slots
    local validSlots = {}
    if target == "sheet" then
        validSlots = self:GetValidSheetSlots()
        if #validSlots == 0 then
            print(L["NO_EQUIPMENT_SLOTS"])
            return
        end
    elseif target == "bags" then
        validSlots = self:GetValidBagSlots(action)
        if #validSlots == 0 then
            if action == "bag-empty" then
                print(L["NO_BAGS_WITH_ITEMS"])
            else
                print(L["NO_VALID_BAGS"])
            end
            return
        end
    end

    -- Pick winner mit verbesserter Zufälligkeit
    -- In Classic Era gibt es kein math.randomseed, daher alternative Methode
    -- Mehrere random calls für bessere Verteilung
    local randomCalls = math.floor(GetTime()) % 10 + 1
    for i = 1, randomCalls do
        math.random()
    end

    local randomIndex = math.random(1, #validSlots)
    self.winnerSlot = validSlots[randomIndex]

    -- No special handling here - let the animation handle bag-delete logic

    -- Debug output removed

    -- Start animation
    self.isSpinning = true

    -- Clear any previous highlights (green/red) from bags
    if self.ClearBagHighlights then
        self:ClearBagHighlights()
    end

    -- Play start sound
    if self.PlaySound then
        self:PlaySound("START")
    end

    -- Add delay before starting the spin animation (let the start sound play)
    C_Timer.After(0.5, function()
        -- Get spin algorithm
        if self.RunSpinAnimation then
            self:RunSpinAnimation(target, validSlots, self.winnerSlot)
        else
            -- Fallback if no animation
            self:OnSpinComplete()
        end
    end)
end

function CattosShuffle:OnSpinComplete()
    -- Special handling for bag-delete action
    if self.currentAction == "bag-delete" and self.currentTarget == "bags" and not self.secondSpinForDelete then
        -- First spin - a bag was selected for potential deletion

        if self.winnerSlot == 0 then
            -- Backpack was selected - mark it GREEN for emptying
            print("|cff00ff00" .. L["BACKPACK"] .. " - " .. L["BACKPACK_MUST_EMPTY"] .. "|r")

            -- Show backpack contents (what will be emptied)
            if self.ShowBagContentsPopup then
                self:ShowBagContentsPopup(0)  -- Show backpack contents
            end

            -- Show backpack with green highlight
            if self.HighlightBagGreen then
                self:HighlightBagGreen(0)  -- Highlight backpack green
            end

            -- Store backpack as the "empty" winner
            self.emptyWinner = 0

            -- Now do second spin for actual deletion (excluding backpack)
            C_Timer.After(3.0, function()  -- Increased delay to allow viewing contents
                print("|cffffcc00" .. L["SECOND_SPIN_FOR_DELETE"] .. "|r")

                -- Get only equipped non-backpack bags
                local nonBackpackSlots = {}
                local availableBags = self:GetAvailableBags()
                for bagId, bagInfo in pairs(availableBags) do
                    if bagId > 0 then  -- Exclude backpack (bagId 0)
                        table.insert(nonBackpackSlots, bagId)
                    end
                end

                -- Check if there are any non-backpack bags equipped
                if #nonBackpackSlots == 0 then
                    print("|cffff0000" .. L["NO_OTHER_BAGS"] .. "|r")
                    return
                end

                -- Pick a random non-backpack bag for deletion
                local deleteIndex = math.random(1, #nonBackpackSlots)
                self.winnerSlot = nonBackpackSlots[deleteIndex]
                self.secondSpinForDelete = true

                -- Run second animation for the delete target
                if self.RunSpinAnimation then
                    self:RunSpinAnimation("bags", nonBackpackSlots, self.winnerSlot)
                else
                    self:OnSpinComplete()  -- Call recursively for second spin
                end
            end)
        else
            -- Regular bag (1-4) was selected - it will be deleted directly
            print("|cffff0000" .. self.BAG_SLOTS[self.winnerSlot] .. " - " .. L["BAG_WILL_BE_DELETED"] .. "|r")

            -- Show bag contents (what will be deleted)
            if self.ShowBagContentsPopup then
                self:ShowBagContentsPopup(self.winnerSlot)  -- Show contents of the bag that will be deleted
            end

            -- Show the bag with red highlight (will be deleted)
            if self.HighlightBagRed then
                self:HighlightBagRed(self.winnerSlot)
            end

            -- No second spin needed - regular bag will be deleted
            self.isSpinning = false
        end
        return
    end

    -- Second spin for delete - mark RED (DON'T show contents)
    if self.secondSpinForDelete then
        self.secondSpinForDelete = false
        print("|cffff0000" .. self.BAG_SLOTS[self.winnerSlot] .. " - " .. L["BAG_WILL_BE_DELETED"] .. "|r")

        -- Show the delete target with red highlight
        if self.HighlightBagRed then
            self:HighlightBagRed(self.winnerSlot)
        end

        -- DON'T show bag contents for the deletion target (only show red highlight)

        -- Keep spinning state false after second spin
        self.isSpinning = false
        return
    end

    self.isSpinning = false

    local result = {
        timestamp = time(),
        action = self.currentAction,
        target = self.currentTarget,
        winner = self.winnerSlot,
    }

    -- Get winner info for display
    local winnerName = L["UNKNOWN"]
    if self.currentTarget == "sheet" then
        local slot = self.SHEET_SLOTS[self.winnerSlot]
        if slot then
            winnerName = slot.name
            local slotId = GetInventorySlotInfo(slot.slotId)
            local itemId = GetInventoryItemID("player", slotId)
            if itemId then
                local itemName = GetItemInfo(itemId)
                if itemName then
                    winnerName = winnerName .. " (" .. itemName .. ")"
                end
            end
        end
    elseif self.currentTarget == "bags" then
        winnerName = self.BAG_SLOTS[self.winnerSlot] or "Tasche " .. self.winnerSlot
    end

    result.winnerName = winnerName

    -- Add to history
    table.insert(self.history, 1, result)
    if #self.history > 20 then
        table.remove(self.history)
    end

    -- Save
    CattosShuffleDB.history = self.history

    -- Print result
    local actionInfo = self.ACTIONS[self.currentAction]
    if actionInfo then
        print(string.format(L["RESULT"],
            actionInfo.description, actionInfo.price, winnerName))
    end

    -- Update UI if exists
    if self.UpdateResultDisplay then
        self:UpdateResultDisplay(result)
    end
end

function CattosShuffle:HandleFreeChoice()
    if self.isSpinning then
        print(L["SPIN_ALREADY_RUNNING"])
        return
    end

    self.choiceMode = true
    print(L["CHOICE_MODE_ACTIVE"])

    -- Enable click handlers if UI exists
    if self.EnableChoiceMode then
        self:EnableChoiceMode()
    end
end

function CattosShuffle:StopSpin()
    if not self.isSpinning then
        return
    end

    self.isSpinning = false
    if self.animationTimer then
        self.animationTimer:Cancel()
        self.animationTimer = nil
    end

    print(L["SPIN_CANCELLED"])
end

-- History
-- History-Funktionen entfernt

function CattosShuffle:Toggle()
    if self.frame and self.frame.Toggle then
        self.frame:Toggle()
    else
        -- Falls UI noch nicht initialisiert, jetzt machen
        if self.InitializeUI then
            self:InitializeUI()
        end
        if self.frame then
            self.frame:Show()
            self:RefreshUI()
        end
    end
end

-- Event Handler
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
eventFrame:RegisterEvent("BAG_UPDATE")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED") -- Entering combat
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED") -- Leaving combat

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        CattosShuffle:Initialize()
    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        if CattosShuffle.RefreshEquipment then
            CattosShuffle:RefreshEquipment()
        end
    elseif event == "BAG_UPDATE" then
        if CattosShuffle.RefreshBags then
            CattosShuffle:RefreshBags()
        end
    elseif event == "PLAYER_REGEN_DISABLED" then
        -- Entering combat - hide the UI if it's visible
        if CattosShuffle.frame and CattosShuffle.frame:IsShown() then
            CattosShuffle.wasVisibleBeforeCombat = true
            CattosShuffle.frame:Hide()
            print(L["WINDOW_CLOSED_COMBAT"])
        else
            CattosShuffle.wasVisibleBeforeCombat = false
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Leaving combat - show the UI if it was visible before
        if CattosShuffle.wasVisibleBeforeCombat and CattosShuffle.frame then
            CattosShuffle.frame:Show()
            CattosShuffle:RefreshUI()
            print(L["WINDOW_REOPENED"])
            CattosShuffle.wasVisibleBeforeCombat = false
        end
    end
end)

-- Slash Commands
SLASH_CATTOS1 = "/cattos"
SLASH_CATTOS2 = "/casino"
SLASH_CATTOS3 = "/cc"

SlashCmdList["CATTOS"] = function(msg)
    local cmd = msg:lower():trim()

    if cmd == "" then
        CattosShuffle:Toggle()
    elseif cmd == "bags" or cmd == "bag" then
        CattosShuffle:StartSpin("bags", "bag-empty")
    elseif cmd == "sheet" or cmd == "equip" then
        CattosShuffle:StartSpin("sheet", "sheet-rng")
    elseif cmd == "delete" then
        CattosShuffle:StartSpin("bags", "bag-delete")
    elseif cmd == "choice" or cmd == "free" then
        CattosShuffle:HandleFreeChoice()
    elseif cmd == "stop" then
        CattosShuffle:StopSpin()
    elseif cmd:match("^sound") then
        local theme = cmd:match("^sound%s+(%S+)")
        if theme then
            local validThemes = { "trute", "default" }
            local isValid = false
            for _, v in pairs(validThemes) do
                if v == theme:lower() then
                    isValid = true
                    CattosShuffleDB.soundTheme = theme:lower()
                    print(string.format(L["SOUND_THEME_CHANGED"], theme))
                    break
                end
            end
            if not isValid then
                print(string.format(L["AVAILABLE_THEMES"], "trute, default"))
            end
        else
            print(string.format(L["CURRENT_THEME"], CattosShuffleDB.soundTheme or "default"))
            print(L["USE_SOUND_COMMAND"])
            print(string.format(L["THEMES_LIST"], "trute, default"))
        end
    else
        print(L["HELP_COMMANDS"])
        print("  " .. L["CMD_OPEN"])
        print("  " .. L["CMD_BAGS"])
        print("  " .. L["CMD_SHEET"])
        print("  " .. L["CMD_DELETE"])
        print("  " .. L["CMD_CHOICE"])
        print("  " .. L["HELP_STOP"])
        print("  " .. L["HELP_SOUND"])
    end
end