-- CattosShuffle - Gacha UI
-- Author: Amke & Assistant
-- Version: 2.0.0
local addonName, CattosShuffle = ...
local L = CattosShuffle.L
local Gacha = CattosShuffle.Gacha

-- Create the main gacha frame
function Gacha:CreateGachaFrame()
    if self.frame then
        return self.frame
    end

    -- Main frame (wider for better text display)
    local frame = CreateFrame("Frame", "CattosGachaFrame", UIParent, "BasicFrameTemplate")
    frame:SetSize(500, 450) -- Taller frame for more space
    frame:SetPoint("CENTER", 0, 100)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("HIGH")
    frame:Hide()

    -- Add to ESC close list so ESC key closes the window
    tinsert(UISpecialFrames, "CattosGachaFrame")

    -- Play close sound when window is hidden
    frame:SetScript("OnHide", function()
        PlaySound(855, "SFX") -- Close sound
        -- Cancel any ongoing animation
        if Gacha.animationTimer then
            Gacha.animationTimer:Cancel()
            Gacha.animationTimer = nil
            Gacha.isSpinning = false
        end
    end)

    -- Play open sound when shown
    frame:SetScript("OnShow", function()
        PlaySound(839, "SFX") -- Open sound
    end)

    -- Title with gacha styling
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("TOP", frame, "TOP", 0, -35)
    frame.title:SetText("|cffffcc00>>> GACHA PULL <<<|r")
    frame.title:SetFont("Fonts\\FRIZQT__.TTF", 22, "OUTLINE")

    -- Override the BasicFrameTemplate background
    if frame.Bg then
        frame.Bg:SetColorTexture(0.02, 0.05, 0.15, 0.85) -- Dark blue background with transparency
    end

    -- Create solid background that covers everything
    frame.bgMain = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
    frame.bgMain:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -25)
    frame.bgMain:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 4)
    frame.bgMain:SetColorTexture(0.02, 0.05, 0.15, 0.85) -- Dark blue with 85% opacity

    -- Create gradient overlays for visual appeal
    -- Top gradient (darker blue fade)
    frame.bgTop = frame:CreateTexture(nil, "BORDER")
    frame.bgTop:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -25)
    frame.bgTop:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -25)
    frame.bgTop:SetHeight(150)
    frame.bgTop:SetGradient("VERTICAL", CreateColor(0.01, 0.02, 0.08, 1), -- Even darker blue at top
    CreateColor(0.02, 0.05, 0.15, 0)) -- Fade to base color

    -- Middle accent (cyan glow around slots)
    frame.bgMid = frame:CreateTexture(nil, "BORDER")
    frame.bgMid:SetPoint("CENTER", frame, "CENTER", 0, 0) -- Adjusted to match slot position
    frame.bgMid:SetSize(400, 180)
    frame.bgMid:SetGradient("HORIZONTAL", CreateColor(0.02, 0.05, 0.15, 0), -- Transparent edges matching base
    CreateColor(0.1, 0.3, 0.5, 0.6)) -- Lighter blue center glow

    -- Bottom gradient (golden shine for luck)
    frame.bgBottom = frame:CreateTexture(nil, "BORDER")
    frame.bgBottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 4, 4)
    frame.bgBottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 4)
    frame.bgBottom:SetHeight(100)
    frame.bgBottom:SetGradient("VERTICAL", CreateColor(0.02, 0.05, 0.15, 0), -- Base color at top
    CreateColor(0.4, 0.3, 0.1, 0.8)) -- Golden glow at bottom

    -- Item pool counter
    frame.poolText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.poolText:SetPoint("TOP", frame.title, "BOTTOM", 0, -10)
    frame.poolText:SetText("")

    -- Shard Display (clickable when full) - moved to not clip with slots
    frame.shardButton = CreateFrame("Button", nil, frame, "BackdropTemplate")
    frame.shardButton:SetSize(120, 28) -- Slightly taller for border
    frame.shardButton:SetPoint("TOP", frame.poolText, "BOTTOM", 0, -5) -- Less spacing

    -- Add beautiful backdrop with border
    frame.shardButton:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        tile = false,
        edgeSize = 12,
        insets = {
            left = 3,
            right = 3,
            top = 3,
            bottom = 3
        }
    })
    frame.shardButton:SetBackdropColor(0.15, 0.05, 0.25, 0.9) -- Purple background
    frame.shardButton:SetBackdropBorderColor(0.6, 0.5, 0.8, 0.8) -- Light purple border

    -- Shard icon (BACKGROUND layer so border appears on top)
    frame.shardButton.icon = frame.shardButton:CreateTexture(nil, "BACKGROUND", nil, 1)
    frame.shardButton.icon:SetSize(20, 20) -- Smaller icon for smaller button
    frame.shardButton.icon:SetPoint("LEFT", frame.shardButton, "LEFT", 5, 0)
    frame.shardButton.icon:SetTexture("Interface\\Icons\\INV_Misc_Gem_Pearl_04") -- Crystal icon

    -- Shard text
    frame.shardButton.text = frame.shardButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.shardButton.text:SetPoint("LEFT", frame.shardButton.icon, "RIGHT", 5, 0)
    frame.shardButton.text:SetText("Shards: 0/3")

    -- Make it glow when full (much larger horizontally to fully surround the button)
    frame.shardButton.glow = frame.shardButton:CreateTexture(nil, "OVERLAY")
    frame.shardButton.glow:SetPoint("TOPLEFT", -45, 15) -- Much more horizontal space
    frame.shardButton.glow:SetPoint("BOTTOMRIGHT", 50, -15) -- Much more horizontal space
    frame.shardButton.glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    frame.shardButton.glow:SetBlendMode("ADD")
    frame.shardButton.glow:SetAlpha(0)

    -- Highlight on hover
    frame.shardButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")

    -- Click handler
    frame.shardButton:SetScript("OnClick", function()
        if Gacha.shards >= Gacha.maxShards then
            PlaySound(856, "SFX") -- Button click
            Gacha:RedeemShards()
        else
            print(string.format("|cffff0000Need %d more shards! (%d/%d)|r", Gacha.maxShards - Gacha.shards,
                Gacha.shards, Gacha.maxShards))
        end
    end)

    -- Tooltip
    frame.shardButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("|cffffcc00Pity Shards|r", 1, 1, 0)
        GameTooltip:AddLine("Earn shards when you roll S or SS tier but don't match 3.", 1, 1, 1, true)
        GameTooltip:AddLine(" ", 1, 1, 1)

        if Gacha.shards >= Gacha.maxShards then
            GameTooltip:AddLine("|cff00ff00Click to redeem and switch to Shuffle mode!|r", 0, 1, 0, true)
        else
            GameTooltip:AddLine(string.format("Collect %d more shards to unlock Shuffle mode.",
                Gacha.maxShards - Gacha.shards), 0.7, 0.7, 0.7, true)
        end

        GameTooltip:Show()
    end)

    frame.shardButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Create gacha result slots (3 cards)
    frame.slots = {}
    local slotWidth = 120
    local slotHeight = 160
    local slotSpacing = 30

    for i = 1, 3 do
        local slot = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        slot:SetSize(slotWidth, slotHeight)

        local xOffset = (i - 2) * (slotWidth + slotSpacing)
        slot:SetPoint("CENTER", frame, "CENTER", xOffset, 0) -- Moved down more

        -- Card background with enhanced visuals
        slot:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
            tile = false,
            edgeSize = 16,
            insets = {
                left = 4,
                right = 4,
                top = 4,
                bottom = 4
            }
        })
        slot:SetBackdropColor(0.08, 0.08, 0.15, 0.95) -- Darker cards for contrast

        -- Tier display (top of card)
        slot.tierBanner = CreateFrame("Frame", nil, slot, "BackdropTemplate")
        slot.tierBanner:SetHeight(30)
        slot.tierBanner:SetPoint("TOP", slot, "TOP", 0, -5)
        slot.tierBanner:SetPoint("LEFT", slot, "LEFT", 5, 0)
        slot.tierBanner:SetPoint("RIGHT", slot, "RIGHT", -5, 0)

        slot.tierBanner:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1
        })

        slot.tierText = slot.tierBanner:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        slot.tierText:SetPoint("CENTER", slot.tierBanner, "CENTER", 0, 0)
        slot.tierText:SetText("")

        -- Item icon (make it a button for tooltips)
        slot.iconButton = CreateFrame("Button", nil, slot)
        slot.iconButton:SetSize(64, 64)
        slot.iconButton:SetPoint("CENTER", slot, "CENTER", 0, 10)

        slot.icon = slot.iconButton:CreateTexture(nil, "ARTWORK")
        slot.icon:SetAllPoints(slot.iconButton)
        slot.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

        -- Store item data for tooltip
        slot.iconButton.currentItem = nil

        -- Add tooltip on hover
        slot.iconButton:SetScript("OnEnter", function(self)
            if self.currentItem then
                GameTooltip:SetOwner(self, "ANCHOR_LEFT")
                if self.currentItem.link then
                    GameTooltip:SetHyperlink(self.currentItem.link)
                elseif self.currentItem.itemId then
                    GameTooltip:SetItemByID(self.currentItem.itemId)
                else
                    GameTooltip:SetText(self.currentItem.name or "Unknown Item", 1, 1, 1)
                    if self.currentItem.tier then
                        local tierInfo = TIER_INFO[self.currentItem.tier]
                        if tierInfo then
                            GameTooltip:AddLine(string.format("%s Tier", self.currentItem.tier),
                                tierInfo.color.r, tierInfo.color.g, tierInfo.color.b)
                        end
                    end
                end
                GameTooltip:Show()
            end
        end)

        slot.iconButton:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)

        -- Item name (with word wrap)
        slot.itemText = slot:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        slot.itemText:SetPoint("TOP", slot.icon, "BOTTOM", 0, -5)
        slot.itemText:SetPoint("LEFT", slot, "LEFT", 5, 0)
        slot.itemText:SetPoint("RIGHT", slot, "RIGHT", -5, 0)
        slot.itemText:SetHeight(40)
        slot.itemText:SetJustifyH("CENTER")
        slot.itemText:SetJustifyV("TOP")
        slot.itemText:SetWordWrap(true)
        slot.itemText:SetText("")

        -- Stars for rarity
        slot.stars = slot:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        slot.stars:SetPoint("BOTTOM", slot, "BOTTOM", 0, 10)
        slot.stars:SetText("")

        frame.slots[i] = slot
    end

    -- PULL x1 button (gacha style)
    frame.pullButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    frame.pullButton:SetSize(120, 45)
    frame.pullButton:SetPoint("BOTTOM", frame, "BOTTOM", -70, 75) -- Moved left to make room for x10
    frame.pullButton:SetText("[ PULL x1 ]")
    frame.pullButton:SetNormalFontObject("GameFontNormalLarge")
    frame.pullButton:SetHighlightFontObject("GameFontHighlightLarge")
    frame.pullButton:SetScript("OnClick", function()
        PlaySound(856, "SFX") -- Interface button click sound
        Gacha:Pull(1)  -- Pull once
    end)

    -- PULL x10 button (bulk pull)
    frame.pull10Button = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    frame.pull10Button:SetSize(120, 45)
    frame.pull10Button:SetPoint("BOTTOM", frame, "BOTTOM", 70, 75) -- Right side
    frame.pull10Button:SetText("[ PULL x10 ]")
    frame.pull10Button:SetNormalFontObject("GameFontNormalLarge")
    frame.pull10Button:SetHighlightFontObject("GameFontHighlightLarge")
    frame.pull10Button:SetScript("OnClick", function()
        PlaySound(856, "SFX") -- Interface button click sound
        Gacha:Pull10Fast()  -- Fast x10 pull
    end)

    -- Spin status text (shows during animation) - UNDER the pull button
    frame.statusText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.statusText:SetPoint("TOP", frame.pullButton, "BOTTOM", 0, -5) -- Under the pull button
    frame.statusText:SetText("")

    -- Info text at the very bottom
    frame.infoText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.infoText:SetPoint("BOTTOM", frame, "BOTTOM", 0, 10) -- At the bottom
    frame.infoText:SetText("|cffcccccc3x Match = Delete one random item from the match!|r")

    -- Tier distribution display - above info text
    frame.tierInfo = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.tierInfo:SetPoint("BOTTOM", frame.infoText, "TOP", 0, 5) -- Above info text
    frame.tierInfo:SetText("")

    -- Spin counter (shows progress to pity) - above tier rates
    frame.spinCounter = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.spinCounter:SetPoint("BOTTOM", frame.tierInfo, "TOP", 0, 5) -- Above tier rates
    frame.spinCounter:SetText("")

    -- Back button
    frame.backButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    frame.backButton:SetSize(80, 25)
    frame.backButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -35, -35)
    frame.backButton:SetText("Back")
    frame.backButton:SetScript("OnClick", function()
        PlaySound(855, "SFX") -- Interface close/back sound
        frame:Hide()
        if CattosShuffle.frame then
            CattosShuffle.frame:Show()
            CattosShuffle:RefreshUI()
        end
    end)

    -- Help button (under Back)
    frame.helpButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    frame.helpButton:SetSize(80, 25)
    frame.helpButton:SetPoint("TOP", frame.backButton, "BOTTOM", 0, -5)
    frame.helpButton:SetText("Help")
    frame.helpButton:SetScript("OnClick", function()
        PlaySound(856, "SFX") -- Button click
        self:ShowHelpWindow()
    end)

    -- Legend button (shows tier info)
    frame.legendButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    frame.legendButton:SetSize(80, 25)
    frame.legendButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 35, -35)
    frame.legendButton:SetText("Legend")
    frame.legendButton:SetScript("OnClick", function()
        PlaySound(856, "SFX") -- Button click
        self:ShowTierLegend()
    end)

    -- Item Preview button (shows items in each tier)
    frame.previewButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    frame.previewButton:SetSize(80, 25)
    frame.previewButton:SetPoint("TOP", frame.legendButton, "BOTTOM", 0, -5)
    frame.previewButton:SetText("Items")
    frame.previewButton:SetScript("OnClick", function()
        PlaySound(856, "SFX") -- Button click
        self:ShowTierItems()
    end)

    self.frame = frame
    self.UpdateUI = function()
        self:UpdateGachaUI()
    end

    return frame
end

-- Update the gacha UI
function Gacha:UpdateGachaUI()
    if not self.frame then
        return
    end

    -- Update shard display
    if self.frame.shardButton then
        self.frame.shardButton.text:SetText(string.format("Shards: %d/%d", self.shards or 0, self.maxShards or 3))

        -- Glow effect when full
        if self.shards >= self.maxShards then
            self.frame.shardButton.glow:SetAlpha(0.8)
            -- Pulsing animation
            if not self.shardPulseTimer then
                self.shardPulseTimer = C_Timer.NewTicker(0.05, function()
                    local alpha = self.frame.shardButton.glow:GetAlpha()
                    if alpha >= 0.8 then
                        self.shardPulseDirection = -0.02
                    elseif alpha <= 0.3 then
                        self.shardPulseDirection = 0.02
                    end
                    self.frame.shardButton.glow:SetAlpha(alpha + (self.shardPulseDirection or -0.02))
                end)
            end
            -- Make it glow golden when ready
            self.frame.shardButton:SetBackdropColor(0.3, 0.15, 0.5, 1) -- Brighter purple
            self.frame.shardButton:SetBackdropBorderColor(1, 0.84, 0, 1) -- Gold border when ready
        else
            if self.shardPulseTimer then
                self.shardPulseTimer:Cancel()
                self.shardPulseTimer = nil
            end
            self.frame.shardButton.glow:SetAlpha(0)
            -- Normal state
            self.frame.shardButton:SetBackdropColor(0.15, 0.05, 0.25, 0.9) -- Purple background
            self.frame.shardButton:SetBackdropBorderColor(0.6, 0.5, 0.8, 0.8) -- Light purple border
        end
    end

    -- Update pool counter
    if self.totalItems then
        local tierCounts = {}
        local warnings = {}

        for tier, pool in pairs(self.tierPools or {}) do
            local count = #pool
            if count > 0 then
                -- Add count
                table.insert(tierCounts, string.format("|c%s%s:%d|r", TIER_INFO[tier].hex, tier, count))

                -- Warning if very few items in high tiers
                if (tier == "S" or tier == "SS") and count <= 2 then
                    table.insert(warnings, string.format("|cffff0000(!)|r"))
                end
            end
        end

        local poolText = string.format("Item Pool: %d items (%s)", self.totalItems, table.concat(tierCounts, " "))

        if #warnings > 0 then
            poolText = poolText .. " " .. table.concat(warnings, "")
        end

        self.frame.poolText:SetText(poolText)
    end

    -- Update slots
    for i = 1, 3 do
        local slot = self.frame.slots[i]
        local display = self:GetSlotDisplay(i)

        if display and display.tierInfo then
            -- Update tier banner
            local color = display.tierInfo.color

            -- Animate tier banner while spinning
            if display.spinning then
                -- Pulsing effect while spinning
                local alpha = 0.3 + (math.sin(GetTime() * 5) * 0.2)
                slot.tierBanner:SetBackdropColor(color.r, color.g, color.b, alpha)
                slot.tierBanner:SetBackdropBorderColor(color.r, color.g, color.b, 0.5)
                slot.tierText:SetText("?")
                slot.tierText:SetTextColor(1, 1, 1, 0.7)
            else
                -- Solid color when stopped
                slot.tierBanner:SetBackdropColor(color.r, color.g, color.b, 0.9)
                slot.tierBanner:SetBackdropBorderColor(color.r, color.g, color.b, 1)
                slot.tierText:SetText(display.tierInfo.name)
                slot.tierText:SetTextColor(1, 1, 1, 1)
            end

            -- Update item display
            if display.spinning then
                -- SPINNING - Show blurred/changing items
                if display.item then
                    -- Show rapidly changing items
                    slot.icon:SetTexture(display.item.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
                    slot.icon:SetAlpha(0.6) -- Semi-transparent while spinning

                    -- Update current item for tooltip (even while spinning)
                    slot.iconButton.currentItem = display.item

                    -- Quick flash of item names
                    local itemName = display.item.name or "???"
                    if string.len(itemName) > 20 then
                        itemName = string.sub(itemName, 1, 17) .. "..."
                    end
                    slot.itemText:SetText(itemName)
                    slot.itemText:SetTextColor(0.7, 0.7, 0.7) -- Gray while spinning
                else
                    slot.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                    slot.icon:SetAlpha(0.5)
                    slot.iconButton.currentItem = nil
                    slot.itemText:SetText("...")
                    slot.itemText:SetTextColor(0.5, 0.5, 0.5)
                end

                slot.stars:SetText("???")
                slot.stars:SetTextColor(0.5, 0.5, 0.5)

                -- Spinning border effect
                slot:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
            elseif display.item then
                -- STOPPED - Show final item clearly
                slot.icon:SetTexture(display.item.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
                slot.icon:SetAlpha(1.0) -- Full opacity when stopped

                -- Update current item for tooltip
                slot.iconButton.currentItem = display.item
                slot.iconButton.currentItem.tier = display.tier  -- Add tier info

                -- Set item name with quality color
                local qualityColor = ITEM_QUALITY_COLORS[display.item.quality or 1]
                local itemName = display.item.name or "Unknown"

                -- Truncate if too long
                if string.len(itemName) > 30 then
                    itemName = string.sub(itemName, 1, 27) .. "..."
                end

                slot.itemText:SetTextColor(qualityColor.r, qualityColor.g, qualityColor.b)
                slot.itemText:SetText(itemName)

                -- Set stars based on tier
                local stars = ""
                if display.tier == "C" then
                    stars = "*"
                elseif display.tier == "B" then
                    stars = "**"
                elseif display.tier == "A" then
                    stars = "***"
                elseif display.tier == "S" then
                    stars = "****"
                elseif display.tier == "SS" then
                    stars = "*****"
                end
                slot.stars:SetText(stars)
                slot.stars:SetTextColor(color.r, color.g, color.b)

                -- Highlight if stopped while others spin
                if display.stopped then
                    slot:SetBackdropBorderColor(0.8, 0.8, 0.2, 1) -- Gold border when stopped
                end
            else
                -- Empty/waiting
                slot.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                slot.icon:SetAlpha(0.3)
                slot.iconButton.currentItem = nil
                slot.itemText:SetText("")
                slot.stars:SetText("")
            end

            -- Don't highlight triple matches here - animation handles it
            if not (display.stopped or display.spinning) then
                slot:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
            end
        end
    end

    -- Update button based on animation state
    if Gacha.isSpinning or Gacha.selectionTimer or Gacha.countAnimTimer then
        -- Count how many slots are still spinning
        local stillSpinning = 0
        for i = 1, 3 do
            if Gacha.slots[i] and Gacha.slots[i].isSpinning then
                stillSpinning = stillSpinning + 1
            end
        end

        -- Check which animation is running
        if Gacha.countAnimTimer then
            self.frame.pullButton:SetText(">>> COUNTING <<<")
            self.frame.statusText:SetText("|cffff8800Rolling stack amount...|r")
        elseif Gacha.selectionTimer then
            self.frame.pullButton:SetText(">>> SELECTING <<<")
            self.frame.statusText:SetText("|cffffcc00Choosing victim...|r")
        elseif stillSpinning == 3 then
            self.frame.pullButton:SetText(">>> SPINNING <<<")
            self.frame.statusText:SetText("|cffccccccAll slots spinning...|r")
        elseif stillSpinning == 2 then
            self.frame.pullButton:SetText(">> SLOWING <<")
            self.frame.statusText:SetText("|cffffcc00Slot 1 locked!|r")
        elseif stillSpinning == 1 then
            self.frame.pullButton:SetText("> STOPPING <")
            self.frame.statusText:SetText("|cffff8800Slots 1-2 locked! Final slot...|r")
        else
            self.frame.pullButton:SetText("[ READY ]")
            self.frame.statusText:SetText("|cff00ff00All slots stopped!|r")
        end
        self.frame.pullButton:SetEnabled(false)
        self.frame.pull10Button:SetEnabled(false)
    else
        self.frame.pullButton:SetText("[ PULL x1 ]")
        self.frame.pullButton:SetEnabled(true)
        self.frame.pull10Button:SetText("[ PULL x10 ]")
        self.frame.pull10Button:SetEnabled(true)

        -- Clear status text when not spinning
        if self.frame.statusText then
            self.frame.statusText:SetText("")
        end
    end

    -- Update tier distribution
    self:UpdateTierDisplay()

    -- Update spin counter (hide during spinning to avoid clipping)
    if self.frame.spinCounter then
        if Gacha.isSpinning then
            -- Hide spin counter during animation to avoid text overlap
            self.frame.spinCounter:SetText("")
        else
            -- Check for B-Tier pity (every 10 rolls)
            local bTierRemaining = Gacha.bTierPityThreshold - Gacha.bTierPityCount
            local remaining = Gacha.pityThreshold - Gacha.spinCount

            -- Show B-Tier pity if it's closer than the main pity
            if bTierRemaining <= 3 then
                -- B-Tier pity is very close
                self.frame.spinCounter:SetText(string.format("|cff99ccffB-Tier Triple in %d spins!|r", bTierRemaining))
            elseif remaining <= 10 then
                -- Show warning when close to main pity
                self.frame.spinCounter:SetText(string.format("|cffff8800Pity in %d spins!|r", remaining))
            elseif remaining <= 20 then
                -- Show when getting closer to main pity
                self.frame.spinCounter:SetText(string.format("|cffffcc00Spins until pity: %d|r", remaining))
            else
                -- Normal display - show both counters
                self.frame.spinCounter:SetText(string.format("|cffccccccB-Tier: %d/%d | Main: %d/%d|r",
                    Gacha.bTierPityCount, Gacha.bTierPityThreshold,
                    Gacha.spinCount, Gacha.pityThreshold))
            end
        end
    end
end

-- Update tier distribution display
function Gacha:UpdateTierDisplay()
    if not self.frame or not self.tierWeights then
        return
    end

    local tierChances = {}
    for tier, weight in pairs(self.tierWeights) do
        if weight > 0 then
            local chance = (weight / self.totalWeight) * 100
            table.insert(tierChances, string.format("|c%s%s:%.1f%%|r", TIER_INFO[tier].hex, tier, chance))
        end
    end

    self.frame.tierInfo:SetText("Rates: " .. table.concat(tierChances, " "))
end

-- Show help window with explanations
function Gacha:ShowHelpWindow()
    if not self.helpFrame then
        self:CreateHelpFrame()
    end
    self.helpFrame:Show()
end

-- Create help frame
function Gacha:CreateHelpFrame()
    local frame = CreateFrame("Frame", "CattosGachaHelp", UIParent, "BasicFrameTemplate")
    frame:SetSize(450, 500)
    frame:SetPoint("CENTER", 50, 0)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        self:StartMoving()
        self:SetFrameStrata("TOOLTIP")  -- Bring to front when dragging
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        self:SetFrameStrata("HIGH")  -- Return to normal level
    end)
    frame:SetFrameStrata("HIGH")
    frame:SetFrameLevel(10)
    frame:Hide()

    -- Add to ESC close list
    tinsert(UISpecialFrames, "CattosGachaHelp")

    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -35)
    title:SetText(L["GACHA_HELP_TITLE"])

    -- Create scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -60)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -35, 15)

    -- Create scroll child
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(400, 800)
    scrollFrame:SetScrollChild(content)

    -- Help text content
    local helpText = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    helpText:SetPoint("TOPLEFT", content, "TOPLEFT", 5, -5)
    helpText:SetWidth(390)
    helpText:SetJustifyH("LEFT")
    helpText:SetSpacing(3)

    -- Build the localized help text
    local text = L["GACHA_WHAT_IS"] .. "\n\n" ..
                 L["GACHA_WHAT_IS_DESC"] .. "\n\n" ..
                 L["GACHA_HOW_WORKS"] .. "\n\n" ..
                 L["GACHA_HOW_WORKS_DESC"] .. "\n\n" ..
                 L["GACHA_TIERS"] .. "\n\n" ..
                 L["GACHA_TIER_SS"] .. "\n" ..
                 L["GACHA_TIER_S"] .. "\n" ..
                 L["GACHA_TIER_A"] .. "\n" ..
                 L["GACHA_TIER_B"] .. "\n" ..
                 L["GACHA_TIER_C"] .. "\n\n" ..
                 L["GACHA_RULES"] .. "\n\n" ..
                 L["GACHA_RULES_DESC"] .. "\n\n" ..
                 L["GACHA_EXAMPLE"] .. "\n\n" ..
                 L["GACHA_EXAMPLE_DESC"] .. "\n\n" ..
                 L["GACHA_PITY_TITLE"] .. "\n\n" ..
                 L["GACHA_PITY_SHARDS"] .. "\n\n" ..
                 L["GACHA_PITY_BTIER"] .. "\n\n" ..
                 L["GACHA_PITY_MAIN"] .. "\n\n" ..
                 L["GACHA_DELETION"] .. "\n\n" ..
                 L["GACHA_DELETION_DESC"] .. "\n\n" ..
                 L["GACHA_COMMANDS"] .. "\n\n" ..
                 L["GACHA_CMD_OPEN"] .. "\n" ..
                 L["GACHA_CMD_HELP"] .. "\n" ..
                 L["GACHA_CMD_LEGEND"] .. "\n" ..
                 L["GACHA_CMD_ITEMS"] .. "\n\n" ..
                 L["GACHA_TIPS"] .. "\n\n" ..
                 L["GACHA_TIPS_DESC"] .. "\n\n" ..
                 L["GACHA_WARNING"] .. "\n" ..
                 L["GACHA_WARNING_DESC"] .. "\n\n" ..
                 L["GACHA_GOOD_LUCK"]

    helpText:SetText(text)

    -- Calculate actual text height
    local textHeight = helpText:GetStringHeight()
    content:SetHeight(textHeight + 20)

    -- Play sound on show
    frame:SetScript("OnShow", function()
        PlaySound(839, "SFX") -- Open sound
    end)

    frame:SetScript("OnHide", function()
        PlaySound(855, "SFX") -- Close sound
    end)

    self.helpFrame = frame
end

-- Show tier legend popup
function Gacha:ShowTierLegend()
    StaticPopupDialogs["CATTOS_GACHA_LEGEND"] = {
        text = "|cffffcc00GACHA TIER SYSTEM|r\n\n" .. "|cffff8000SS Tier (Ultra Rare):|r Epic/Legendary Equipped\n" ..
            "|cffffd700S Tier (Super Rare):|r Currently Equipped Items\n" ..
            "|cff9933ccA Tier (Rare):|r Equipable Gear (Not Worn)\n" ..
            "|cff99ccffB Tier (Uncommon):|r Quest Items & Consumables\n" ..
            "|cff808080C Tier (Common):|r Junk & Non-Equipable Items\n\n" .. "Epic/Legendary items upgrade their tier!",
        button1 = "Got it!",
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3
    }
    StaticPopup_Show("CATTOS_GACHA_LEGEND")
end

-- Show items in each tier
function Gacha:ShowTierItems()
    -- Build item pool if not already done
    if not self.tierPools or not self.totalItems then
        self:BuildItemPool()
    end

    -- Create scrollable frame for item list
    if not self.itemListFrame then
        self:CreateItemListFrame()
    end

    -- Clear previous content
    for _, child in ipairs(self.itemListFrame.scrollChild.items or {}) do
        child:Hide()
    end
    self.itemListFrame.scrollChild.items = {}

    -- Add items by tier
    local yOffset = -10
    local tierOrder = {"SS", "S", "A", "B", "C"}

    for _, tier in ipairs(tierOrder) do
        local pool = self.tierPools[tier] or {}

        if #pool > 0 then
            -- Create tier header
            local header = self.itemListFrame.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            header:SetPoint("TOPLEFT", 10, yOffset)
            header:SetText(string.format("|c%s%s Tier (%d items)|r", TIER_INFO[tier].hex, tier, #pool))
            table.insert(self.itemListFrame.scrollChild.items, header)
            yOffset = yOffset - 25

            -- Sort items by name
            table.sort(pool, function(a, b)
                return (a.name or "") < (b.name or "")
            end)

            -- Add each item (max 10 per tier for readability)
            local count = 0
            for _, item in ipairs(pool) do
                if count >= 10 then
                    -- Add "and X more..." text
                    local moreText = self.itemListFrame.scrollChild:CreateFontString(nil, "OVERLAY",
                        "GameFontNormalSmall")
                    moreText:SetPoint("TOPLEFT", 20, yOffset)
                    moreText:SetText(string.format("|cffcccccc...and %d more|r", #pool - 10))
                    table.insert(self.itemListFrame.scrollChild.items, moreText)
                    yOffset = yOffset - 18
                    break
                end

                -- Create clickable item button
                local itemButton = CreateFrame("Button", nil, self.itemListFrame.scrollChild)
                itemButton:SetPoint("TOPLEFT", 15, yOffset)
                itemButton:SetSize(330, 20)

                -- Create text for the button
                local itemText = itemButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                itemText:SetPoint("LEFT", itemButton, "LEFT", 0, 0)
                itemText:SetJustifyH("LEFT")

                -- Format: Name (Location)
                local location = item.isEquipped and "|cff00ff00[Equipped]|r" or item.location == "bag" and
                                     string.format("|cffcccccc[Bag %d]|r", item.bag) or ""

                -- Use item link for colored name
                itemText:SetText(string.format("%s %s", item.link or item.name, location))

                -- Make button highlight on hover
                itemButton:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")

                -- Set up tooltip on hover
                itemButton:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
                    if item.link then
                        GameTooltip:SetHyperlink(item.link)
                    elseif item.itemId then
                        GameTooltip:SetItemByID(item.itemId)
                    else
                        GameTooltip:SetText(item.name or "Unknown Item", 1, 1, 1)
                        if item.tier then
                            GameTooltip:AddLine(string.format("%s Tier", item.tier), TIER_INFO[item.tier].color.r,
                                TIER_INFO[item.tier].color.g, TIER_INFO[item.tier].color.b)
                        end
                    end
                    GameTooltip:Show()
                end)

                itemButton:SetScript("OnLeave", function(self)
                    GameTooltip:Hide()
                end)

                -- Allow shift-click to link in chat
                itemButton:SetScript("OnClick", function(self, button)
                    if button == "LeftButton" and IsShiftKeyDown() and item.link then
                        if ChatEdit_GetActiveWindow() then
                            ChatEdit_InsertLink(item.link)
                        else
                            ChatFrame_OpenChat(item.link)
                        end
                    end
                end)

                itemButton.text = itemText
                itemButton.item = item
                table.insert(self.itemListFrame.scrollChild.items, itemButton)
                yOffset = yOffset - 20 -- Slightly more space for buttons
                count = count + 1
            end

            yOffset = yOffset - 10 -- Extra space between tiers
        end
    end

    -- Set scroll child height
    self.itemListFrame.scrollChild:SetHeight(math.abs(yOffset) + 20)

    -- Show the frame
    self.itemListFrame:Show()
end

-- Create item list frame
function Gacha:CreateItemListFrame()
    local frame = CreateFrame("Frame", "CattosGachaItemList", UIParent, "BasicFrameTemplate")
    frame:SetSize(400, 500)
    frame:SetPoint("CENTER", 100, 0)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        self:StartMoving()
        self:SetFrameStrata("TOOLTIP")  -- Bring to front when dragging
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        self:SetFrameStrata("FULLSCREEN")  -- Return to high level
    end)
    frame:SetFrameStrata("FULLSCREEN")
    frame:SetFrameLevel(20)
    frame:Hide()

    -- Add to ESC close list
    tinsert(UISpecialFrames, "CattosGachaItemList")

    -- Play sound when closing
    frame:SetScript("OnHide", function()
        PlaySound(855, "SFX") -- Close sound
    end)

    -- Title
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("TOP", frame, "TOP", 0, -35)
    frame.title:SetText("|cffffcc00GACHA ITEM POOL|r")

    -- Create scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -60)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 40)

    -- Create scroll child
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(350, 1000) -- Height will be adjusted
    scrollFrame:SetScrollChild(scrollChild)
    scrollChild.items = {}

    frame.scrollFrame = scrollFrame
    frame.scrollChild = scrollChild

    -- Close button is already added by BasicFrameTemplate

    -- Info text
    local infoText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    infoText:SetPoint("BOTTOM", frame, "BOTTOM", 0, 15)
    infoText:SetText("|cffccccccHover for tooltip - Shift+Click to link in chat|r")

    self.itemListFrame = frame
end

-- Toggle the gacha window
function Gacha:Toggle()
    if not self.frame then
        self:CreateGachaFrame()
    end

    if self.frame:IsShown() then
        self.frame:Hide() -- OnHide will play close sound
    else
        -- Load saved shards
        if CattosShuffleDB and CattosShuffleDB.gachaShards then
            self.shards = CattosShuffleDB.gachaShards
        else
            self.shards = 0
        end

        -- Load saved spin count
        if CattosShuffleDB and CattosShuffleDB.gachaSpinCount then
            Gacha.spinCount = CattosShuffleDB.gachaSpinCount
        else
            Gacha.spinCount = 0
        end

        -- Load saved B-Tier pity count
        if CattosShuffleDB and CattosShuffleDB.gachaBTierPityCount then
            Gacha.bTierPityCount = CattosShuffleDB.gachaBTierPityCount
        else
            Gacha.bTierPityCount = 0
        end

        self:BuildItemPool()
        self:UpdateGachaUI()
        self.frame:Show() -- OnShow will play open sound
    end
end

-- Add necessary tier info
TIER_INFO = {
    ["C"] = {
        name = "C",
        color = {
            r = 0.5,
            g = 0.5,
            b = 0.5
        },
        hex = "ff808080"
    },
    ["B"] = {
        name = "B",
        color = {
            r = 0.6,
            g = 0.8,
            b = 1.0
        },
        hex = "ff99ccff"
    },
    ["A"] = {
        name = "A",
        color = {
            r = 0.6,
            g = 0.2,
            b = 0.8
        },
        hex = "ff9933cc"
    },
    ["S"] = {
        name = "S",
        color = {
            r = 1.0,
            g = 0.84,
            b = 0
        },
        hex = "ffffd700"
    },
    ["SS"] = {
        name = "SS",
        color = {
            r = 1.0,
            g = 0.5,
            b = 0
        },
        hex = "ffff8000"
    }
}

-- Create x10 results window
function Gacha:CreateX10ResultsFrame()
    if self.x10Frame then
        return self.x10Frame
    end

    local frame = CreateFrame("Frame", "CattosGachaX10Results", UIParent, "BasicFrameTemplate")
    frame:SetSize(600, 550)  -- Made taller for more space
    frame:SetPoint("CENTER", 0, 0)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:Hide()

    -- Add to ESC close list
    tinsert(UISpecialFrames, "CattosGachaX10Results")

    -- Title
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("TOP", frame, "TOP", 0, -40)  -- More space from top edge
    frame.title:SetText("|cffffcc00>>> x10 PULL RESULTS <<<|r")
    frame.title:SetFont("Fonts\\FRIZQT__.TTF", 20, "OUTLINE")

    -- Create 10 result slots (2 rows of 5)
    frame.results = {}
    local slotSize = 100
    local spacing = 10
    local startX = -((5 * slotSize + 4 * spacing) / 2) + (slotSize / 2)
    local startY = 80  -- Moved down to give more space from title

    for i = 1, 10 do
        local row = math.floor((i - 1) / 5)
        local col = (i - 1) % 5

        local slot = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        slot:SetSize(slotSize, slotSize + 40)
        slot:SetPoint("CENTER", frame, "CENTER", startX + col * (slotSize + spacing), startY - row * (slotSize + 60))

        slot:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
            tile = false,
            edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 }
        })
        slot:SetBackdropColor(0.08, 0.08, 0.15, 0.95)

        -- Pull number
        slot.pullNum = slot:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        slot.pullNum:SetPoint("TOP", slot, "TOP", 0, -5)
        slot.pullNum:SetText("#" .. i)
        slot.pullNum:SetTextColor(0.7, 0.7, 0.7)

        -- Tier banner
        slot.tierBanner = CreateFrame("Frame", nil, slot, "BackdropTemplate")
        slot.tierBanner:SetHeight(20)
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

        -- Item icon button
        slot.iconButton = CreateFrame("Button", nil, slot)
        slot.iconButton:SetSize(48, 48)
        slot.iconButton:SetPoint("CENTER", slot, "CENTER", 0, -5)

        slot.icon = slot.iconButton:CreateTexture(nil, "ARTWORK")
        slot.icon:SetAllPoints(slot.iconButton)
        slot.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

        -- Item name
        slot.itemText = slot:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        slot.itemText:SetPoint("BOTTOM", slot, "BOTTOM", 0, 5)
        slot.itemText:SetWidth(slotSize - 10)
        slot.itemText:SetWordWrap(true)
        slot.itemText:SetHeight(30)

        -- DELETE marker for matches (on the iconButton so it's above the icon)
        slot.deleteMarker = slot.iconButton:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        slot.deleteMarker:SetPoint("CENTER", slot.iconButton, "CENTER", 0, 0)
        slot.deleteMarker:SetText("|cffff0000DELETE|r")
        slot.deleteMarker:SetFont("Fonts\\FRIZQT__.TTF", 14, "THICKOUTLINE")
        slot.deleteMarker:SetDrawLayer("OVERLAY", 7)  -- Highest layer
        slot.deleteMarker:Hide()

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

        frame.results[i] = slot
    end

    -- Summary text
    frame.summaryText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.summaryText:SetPoint("BOTTOM", frame, "BOTTOM", 0, 80)
    frame.summaryText:SetText("")

    -- Instructions
    frame.instructText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.instructText:SetPoint("BOTTOM", frame, "BOTTOM", 0, 50)
    frame.instructText:SetText("")
    frame.instructText:SetTextColor(1, 0.2, 0.2)

    -- Close button
    frame.closeButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    frame.closeButton:SetSize(100, 30)
    frame.closeButton:SetPoint("BOTTOM", frame, "BOTTOM", 0, 15)
    frame.closeButton:SetText("Close")
    frame.closeButton:SetScript("OnClick", function()
        PlaySound(855, "SFX")
        frame:Hide()
    end)

    self.x10Frame = frame
    return frame
end

-- Show x10 results
function Gacha:ShowX10Results(results)
    if not self.x10Frame then
        self:CreateX10ResultsFrame()
    end

    local frame = self.x10Frame
    local toDelete = {}
    local deleteCount = 0

    -- Display all 10 results
    for i = 1, 10 do
        local result = results[i]
        local slot = frame.results[i]

        if result then
            -- Set tier color
            local tierInfo = TIER_INFO[result.tier]
            slot.tierBanner:SetBackdropColor(tierInfo.color.r, tierInfo.color.g, tierInfo.color.b, 0.9)
            slot.tierBanner:SetBackdropBorderColor(tierInfo.color.r, tierInfo.color.g, tierInfo.color.b, 1)
            slot.tierText:SetText(result.tier)

            -- Set item info
            if result.item then
                slot.icon:SetTexture(result.item.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
                slot.iconButton.itemData = result.item

                local itemName = result.item.name or "Unknown"
                if string.len(itemName) > 15 then
                    itemName = string.sub(itemName, 1, 12) .. "..."
                end

                local qualityColor = ITEM_QUALITY_COLORS[result.item.quality or 1]
                slot.itemText:SetTextColor(qualityColor.r, qualityColor.g, qualityColor.b)
                slot.itemText:SetText(itemName)
            end

            -- Mark if it's part of a match
            if result.shouldDelete then
                slot:SetBackdropBorderColor(1, 0, 0, 1)
                slot.deleteMarker:Show()
                table.insert(toDelete, result.item)
                deleteCount = deleteCount + 1
            else
                slot:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
                slot.deleteMarker:Hide()
            end
        end
    end

    -- Update summary
    if deleteCount > 0 then
        frame.summaryText:SetText(string.format("|cffff0000%d MATCHES FOUND! %d items marked for deletion!|r",
            #results.matches, deleteCount))
        frame.instructText:SetText("|cffff0000Manually delete ALL marked items!|r")

        -- Store items to delete
        self.x10DeleteList = toDelete

        -- Show manual delete instructions after a moment
        C_Timer.After(2, function()
            if self.x10DeleteList and #self.x10DeleteList > 0 then
                self:ShowX10DeleteInstructions()
            end
        end)
    else
        frame.summaryText:SetText("|cff00ff00No matches! All items are safe!|r")
        frame.instructText:SetText("")
        self.x10DeleteList = nil
    end

    frame:Show()
    PlaySound(3332, "SFX")
end

-- Show deletion instructions for x10
function Gacha:ShowX10DeleteInstructions()
    if not self.x10DeleteList or #self.x10DeleteList == 0 then return end

    print("|cffff0000=== x10 PULL DELETIONS REQUIRED ===|r")
    print(string.format("|cffffcc00You must delete %d items:|r", #self.x10DeleteList))

    for i, item in ipairs(self.x10DeleteList) do
        print(string.format("  %d. %s", i, item.link or item.name))
    end

    print("|cffff0000Delete these items manually from your bags!|r")
end
