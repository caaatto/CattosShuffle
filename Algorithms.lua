-- CattosShuffle - Spin Algorithms Module
-- Author: Amke
-- Version: 1.0.0

local addonName, CattosShuffle = ...

-- Character panel slot order (left column, then weapons, then right column)
CattosShuffle.CHARACTER_PANEL_ORDER = {
    -- Left column (top to bottom)
    0,  -- Head
    1,  -- Neck
    2,  -- Shoulder
    3,  -- Back
    4,  -- Chest
    5,  -- Shirt
    6,  -- Tabard
    7,  -- Wrist
    -- Bottom weapons (left to right) - after Wrist
    16, -- Main Hand
    17, -- Off Hand
    18, -- Ranged/Distance
    -- Right column (top to bottom) - after weapons
    8,  -- Hands
    9,  -- Waist
    10, -- Legs
    11, -- Feet
    12, -- Ring 1
    13, -- Ring 2
    14, -- Trinket 1
    15, -- Trinket 2
}

-- Spin algorithm types
CattosShuffle.SPIN_ALGORITHMS = {
    "normal",      -- Standard, wird langsamer am Ende
    "normal",      -- (doppelte Chance für normal)
    "reverse",     -- Läuft rückwärts durch die Slots
    "fakeout",     -- Tut so als stoppt es, dann weiter
    "doublefake",  -- Zwei Fake-Stops bevor es wirklich stoppt
    "yoyo",        -- Vor und zurück (hin-her-hin)
    "stutter",     -- Zufällige Pausen während des Spins
    "speedup",     -- Langsam → Schnell → Langsam
    "kitt",        -- Knight Rider Bounce (0-1-2-3-4-3-2-1-0...)
}

function CattosShuffle:RunSpinAnimation(target, validSlots, winnerSlot)
    -- Sort validSlots in character panel order for equipment
    if target == "sheet" then
        local sortedSlots = {}
        -- Add slots in the character panel order
        for _, orderSlot in ipairs(self.CHARACTER_PANEL_ORDER) do
            for _, validSlot in ipairs(validSlots) do
                if validSlot == orderSlot then
                    table.insert(sortedSlots, validSlot)
                    break
                end
            end
        end
        validSlots = sortedSlots

        -- Debug output removed
    end

    -- Pick random algorithm
    local algorithm = self.SPIN_ALGORITHMS[math.random(#self.SPIN_ALGORITHMS)]


    -- Map algorithm to function
    local algorithmFunctions = {
        normal = function() self:SpinNormal(target, validSlots, winnerSlot) end,
        reverse = function() self:SpinReverse(target, validSlots, winnerSlot) end,
        fakeout = function() self:SpinFakeout(target, validSlots, winnerSlot) end,
        doublefake = function() self:SpinDoublefake(target, validSlots, winnerSlot) end,
        yoyo = function() self:SpinYoyo(target, validSlots, winnerSlot) end,
        stutter = function() self:SpinStutter(target, validSlots, winnerSlot) end,
        speedup = function() self:SpinSpeedup(target, validSlots, winnerSlot) end,
        kitt = function() self:SpinKitt(target, validSlots, winnerSlot) end,
    }

    local func = algorithmFunctions[algorithm]
    if func then
        func()
    else
        -- Fallback to normal
        self:SpinNormal(target, validSlots, winnerSlot)
    end
end

-- Normal Spin: 3-4 complete rotations, slows down at end
function CattosShuffle:SpinNormal(target, validSlots, winnerSlot)
    local totalRotations = math.random(3, 4)
    local totalSteps = totalRotations * #validSlots + table.find(validSlots, winnerSlot)
    local currentStep = 0
    local baseDelay = 0.15  -- Faster by 0.1 (was 0.25)
    local maxDelay = 1.1   -- Faster end (was 1.2)

    self.animationTimer = C_Timer.NewTicker(baseDelay, function()
        currentStep = currentStep + 1

        local slotIndex = validSlots[(currentStep - 1) % #validSlots + 1]
        self:ShowSpinHighlight(target, slotIndex)

        -- Calculate progress and delay first
        local progress = currentStep / totalSteps
        local currentDelay = baseDelay

        -- Exponential slowdown in last 30%
        if progress > 0.7 then
            local slowProgress = (progress - 0.7) / 0.3
            currentDelay = baseDelay + (maxDelay - baseDelay) * (slowProgress * slowProgress)
        end

        -- Play tick sound with current delay
        if self.PlaySound then
            self:PlaySound("TICK", currentDelay)
        end

        -- Handle timer update
        if progress > 0.7 then
            self.animationTimer:Cancel()

            if currentStep < totalSteps then
                self.animationTimer = C_Timer.NewTimer(currentDelay, function()
                    self:ContinueNormalSpin(target, validSlots, winnerSlot, currentStep, totalSteps, baseDelay, maxDelay)
                end)
            else
                self:CompleteSpinAnimation(target, winnerSlot)
            end
        end
    end)
end

function CattosShuffle:ContinueNormalSpin(target, validSlots, winnerSlot, currentStep, totalSteps, baseDelay, maxDelay)
    local function tick()
        currentStep = currentStep + 1

        local slotIndex = validSlots[(currentStep - 1) % #validSlots + 1]
        self:ShowSpinHighlight(target, slotIndex)

        if currentStep >= totalSteps then
            self:CompleteSpinAnimation(target, winnerSlot)
        else
            local progress = currentStep / totalSteps
            local delay = baseDelay

            if progress > 0.7 then
                local slowProgress = (progress - 0.7) / 0.3
                delay = baseDelay + (maxDelay - baseDelay) * (slowProgress * slowProgress)
            end

            -- Play sound with delay info
            if self.PlaySound then
                self:PlaySound("TICK", delay)
            end

            self.animationTimer = C_Timer.NewTimer(delay, tick)
        end
    end

    tick()
end

-- Reverse Spin: Runs backwards through slots
function CattosShuffle:SpinReverse(target, validSlots, winnerSlot)
    -- Create reverse order of validSlots
    local reverseSlots = {}
    for i = #validSlots, 1, -1 do
        table.insert(reverseSlots, validSlots[i])
    end

    local totalRotations = math.random(4, 6)
    local winnerIndex = table.find(reverseSlots, winnerSlot)
    local totalSteps = totalRotations * #reverseSlots + winnerIndex
    local currentStep = 0
    local baseDelay = 0.15  -- Faster by 0.1

    local function tick()
        currentStep = currentStep + 1

        -- Use reversed slots array
        local slotIndex = reverseSlots[(currentStep - 1) % #reverseSlots + 1]

        self:ShowSpinHighlight(target, slotIndex)

        if currentStep >= totalSteps then
            self:CompleteSpinAnimation(target, winnerSlot)
        else
            local progress = currentStep / totalSteps
            local delay = baseDelay

            if progress > 0.7 then
                local slowProgress = (progress - 0.7) / 0.3
                delay = baseDelay + 0.7 * (slowProgress * slowProgress)  -- 0.1 faster slowdown
            end

            -- Play sound with delay info
            if self.PlaySound then
                self:PlaySound("TICK", delay)
            end

            self.animationTimer = C_Timer.NewTimer(delay, tick)
        end
    end

    tick()
end

-- Fakeout: Pretends to stop, then continues
function CattosShuffle:SpinFakeout(target, validSlots, winnerSlot)
    local totalRotations = math.random(5, 7)
    local winnerIndex = table.find(validSlots, winnerSlot)
    local totalSteps = totalRotations * #validSlots + winnerIndex
    local currentStep = 0
    local fakeoutAt = math.floor(totalSteps * 0.55)
    local baseDelay = 0.15  -- Faster by 0.1

    local function tick()
        currentStep = currentStep + 1

        local slotIndex = validSlots[(currentStep - 1) % #validSlots + 1]
        self:ShowSpinHighlight(target, slotIndex)

        -- Calculate delay first
        local delay = baseDelay
        if currentStep < totalSteps then
            -- Fakeout slowdown
            if currentStep > fakeoutAt and currentStep < fakeoutAt + 10 then
                local fakeProgress = (currentStep - fakeoutAt) / 10
                delay = baseDelay + 0.4 * fakeProgress
            elseif currentStep == fakeoutAt + 10 then
                -- Speed back up
                delay = baseDelay
            elseif currentStep > totalSteps * 0.8 then
                -- Final slowdown
                local progress = (currentStep - totalSteps * 0.8) / (totalSteps * 0.2)
                delay = baseDelay + 0.8 * progress
            end
        end

        -- Play sound with delay info
        if self.PlaySound then
            self:PlaySound("TICK", delay)
        end

        if currentStep >= totalSteps then
            self:CompleteSpinAnimation(target, winnerSlot)
        else
            self.animationTimer = C_Timer.NewTimer(delay, tick)
        end
    end

    tick()
end

-- Doublefake: Two fake stops
function CattosShuffle:SpinDoublefake(target, validSlots, winnerSlot)
    local totalRotations = math.random(6, 8)
    local winnerIndex = table.find(validSlots, winnerSlot)
    local totalSteps = totalRotations * #validSlots + winnerIndex
    local currentStep = 0
    local fakeout1 = math.floor(totalSteps * 0.25)
    local fakeout2 = math.floor(totalSteps * 0.55)
    local baseDelay = 0.15  -- Faster by 0.1

    local function tick()
        currentStep = currentStep + 1

        local slotIndex = validSlots[(currentStep - 1) % #validSlots + 1]
        self:ShowSpinHighlight(target, slotIndex)

        -- Calculate delay first
        local delay = baseDelay
        if currentStep < totalSteps then
            -- First fakeout
            if currentStep > fakeout1 and currentStep < fakeout1 + 8 then
                local fakeProgress = (currentStep - fakeout1) / 8
                delay = baseDelay + 0.4  -- 0.1 faster * fakeProgress
            -- Second fakeout
            elseif currentStep > fakeout2 and currentStep < fakeout2 + 10 then
                local fakeProgress = (currentStep - fakeout2) / 10
                delay = baseDelay + 0.4 * fakeProgress
            -- Final slowdown
            elseif currentStep > totalSteps * 0.8 then
                local progress = (currentStep - totalSteps * 0.8) / (totalSteps * 0.2)
                delay = baseDelay + 0.8 * progress
            end
        end

        -- Play sound with delay info
        if self.PlaySound then
            self:PlaySound("TICK", delay)
        end

        if currentStep >= totalSteps then
            self:CompleteSpinAnimation(target, winnerSlot)
        else
            self.animationTimer = C_Timer.NewTimer(delay, tick)
        end
    end

    tick()
end

-- Yoyo: Forward-backward-forward
function CattosShuffle:SpinYoyo(target, validSlots, winnerSlot)
    local phase1Rotations = math.random(2, 3)
    local winnerIndex = table.find(validSlots, winnerSlot)
    local currentIndex = 1
    local direction = 1  -- 1 = forward, -1 = backward
    local phase = 1
    local baseDelay = 0.15  -- Faster by 0.1
    local stepsSincePhaseStart = 0

    local function tick()
        -- Show current slot
        local slotIndex = validSlots[currentIndex]
        self:ShowSpinHighlight(target, slotIndex)

        -- Play sound with delay (will be calculated below)
        if self.PlaySound then
            local nextDelay = baseDelay  -- Default delay for sound timing
            self:PlaySound("TICK", nextDelay)
        end

        -- Update position
        currentIndex = currentIndex + direction
        stepsSincePhaseStart = stepsSincePhaseStart + 1

        local shouldStop = false
        local shouldChangePhase = false

        -- Phase 1: Forward (go through slots multiple times)
        if phase == 1 then
            if currentIndex > #validSlots then
                currentIndex = 1  -- Wrap around
            end
            if stepsSincePhaseStart >= phase1Rotations * #validSlots then
                shouldChangePhase = true
                phase = 2
                direction = -1
                stepsSincePhaseStart = 0
                currentIndex = #validSlots  -- Start from end for backward
            end

        -- Phase 2: Backward (go back through slots)
        elseif phase == 2 then
            if currentIndex < 1 then
                currentIndex = #validSlots  -- Wrap around
            end
            if stepsSincePhaseStart >= #validSlots * 2 then  -- Go back 2 rotations
                shouldChangePhase = true
                phase = 3
                direction = 1
                stepsSincePhaseStart = 0
                currentIndex = 1  -- Start from beginning for final phase
            end

        -- Phase 3: Forward to winner
        elseif phase == 3 then
            if currentIndex > #validSlots then
                currentIndex = 1  -- Wrap around
            end
            if currentIndex == winnerIndex then
                -- Add some extra steps to make it feel more natural
                if stepsSincePhaseStart >= #validSlots then
                    shouldStop = true
                end
            end
        end

        if shouldStop then
            self:CompleteSpinAnimation(target, winnerSlot)
        else
            local delay = baseDelay

            -- Slow down in final phase
            if phase == 3 then
                local progress = stepsSincePhaseStart / #validSlots
                delay = baseDelay + 0.7 * progress
            end

            self.animationTimer = C_Timer.NewTimer(delay, tick)
        end
    end

    tick()
end

-- Stutter: Random pauses during spin
function CattosShuffle:SpinStutter(target, validSlots, winnerSlot)
    local totalRotations = math.random(5, 7)
    local winnerIndex = table.find(validSlots, winnerSlot)
    local totalSteps = totalRotations * #validSlots + winnerIndex
    local currentStep = 0
    local baseDelay = 0.15  -- Faster by 0.1

    local function tick()
        currentStep = currentStep + 1

        local slotIndex = validSlots[(currentStep - 1) % #validSlots + 1]
        self:ShowSpinHighlight(target, slotIndex)

        -- Calculate delay first
        local delay = baseDelay
        if currentStep < totalSteps then
            -- 10% chance for stutter (but make it shorter)
            if math.random() < 0.1 and currentStep < totalSteps * 0.75 then
                delay = math.random(600, 1000) / 1000  -- Longer stutters for visibility
            -- Final slowdown
            elseif currentStep > totalSteps * 0.75 then
                local progress = (currentStep - totalSteps * 0.75) / (totalSteps * 0.25)
                delay = baseDelay + 0.8 * progress
            end
        end

        -- Play sound with delay info
        if self.PlaySound then
            self:PlaySound("TICK", delay)
        end

        if currentStep >= totalSteps then
            self:CompleteSpinAnimation(target, winnerSlot)
        else
            self.animationTimer = C_Timer.NewTimer(delay, tick)
        end
    end

    tick()
end

-- Speedup: Slow → Fast → Slow
function CattosShuffle:SpinSpeedup(target, validSlots, winnerSlot)
    local totalRotations = math.random(5, 7)
    local winnerIndex = table.find(validSlots, winnerSlot)
    local totalSteps = totalRotations * #validSlots + winnerIndex
    local currentStep = 0

    local function tick()
        currentStep = currentStep + 1

        local slotIndex = validSlots[(currentStep - 1) % #validSlots + 1]
        self:ShowSpinHighlight(target, slotIndex)

        -- Calculate delay first
        local progress = currentStep / totalSteps
        local delay

        if progress < 0.3 then
            -- Start slow
            delay = 0.7 - 0.5 * (progress / 0.3)  -- 0.1 faster
        elseif progress < 0.7 then
            -- Fast middle (but not too fast)
            delay = 0.05 + math.random(0, 50) / 1000  -- 0.1 faster
        else
            -- Slow end
            local slowProgress = (progress - 0.7) / 0.3
            delay = 0.2 + 0.9 * slowProgress  -- 0.1 faster
        end

        -- Play sound with delay info
        if self.PlaySound then
            self:PlaySound("TICK", delay)
        end

        if currentStep >= totalSteps then
            self:CompleteSpinAnimation(target, winnerSlot)
        else
            self.animationTimer = C_Timer.NewTimer(delay, tick)
        end
    end

    tick()
end

-- Kitt: Knight Rider bounce pattern
function CattosShuffle:SpinKitt(target, validSlots, winnerSlot)
    local bounces = math.random(3, 5)
    local winnerIndex = table.find(validSlots, winnerSlot)
    local currentIndex = 1
    local direction = 1
    local currentBounce = 0
    local baseDelay = 0.12  -- Faster by 0.1
    local finalPhase = false

    local function tick()
        local slotIndex = validSlots[currentIndex]
        self:ShowSpinHighlight(target, slotIndex)

        -- Play sound with base delay for KITT
        if self.PlaySound then
            self:PlaySound("TICK", baseDelay)
        end

        -- Check if we're at the winner and have done enough bounces
        if finalPhase and currentIndex == winnerIndex then
            self:CompleteSpinAnimation(target, winnerSlot)
            return
        end

        -- Update position
        currentIndex = currentIndex + direction

        -- Bounce at edges (without repeating the edge slot)
        if currentIndex > #validSlots then
            currentIndex = #validSlots - 1  -- Skip back one to avoid repeating last slot
            direction = -1
            currentBounce = currentBounce + 1
        elseif currentIndex < 1 then
            currentIndex = 2  -- Skip forward one to avoid repeating first slot
            direction = 1
            currentBounce = currentBounce + 1
        end

        -- Enter final phase after enough bounces
        if currentBounce >= bounces * 2 and not finalPhase then
            finalPhase = true
            -- Make sure we're moving towards the winner
            if winnerIndex < currentIndex then
                direction = -1
            elseif winnerIndex > currentIndex then
                direction = 1
            end
        end

        local delay = baseDelay

        -- Slow down in final phase
        if finalPhase then
            delay = baseDelay + 0.3
        end

        self.animationTimer = C_Timer.NewTimer(delay, tick)
    end

    tick()
end

-- Flash: Extremely fast spin
function CattosShuffle:SpinFlash(target, validSlots, winnerSlot)
    local totalRotations = math.random(8, 12)
    local winnerIndex = table.find(validSlots, winnerSlot)
    local totalSteps = totalRotations * #validSlots + winnerIndex
    local currentStep = 0

    -- Flash effect at start

    local function tick()
        currentStep = currentStep + 1

        local slotIndex = validSlots[(currentStep - 1) % #validSlots + 1]
        self:ShowSpinHighlight(target, slotIndex)

        -- Calculate delay first
        local progress = currentStep / totalSteps
        local delay

        if progress < 0.7 then
            -- Fast but not too fast
            delay = math.random(30, 70) / 1000  -- 0.05 faster on average
        else
            -- Dramatic slowdown
            local slowProgress = (progress - 0.7) / 0.3
            delay = 0.1 + 1.0 * (slowProgress * slowProgress)  -- 0.1 faster
        end

        -- Play sound on every tick with delay info
        if self.PlaySound then
            self:PlaySound("TICK", delay)
        end

        if currentStep >= totalSteps then
            self:CompleteSpinAnimation(target, winnerSlot)
        else
            self.animationTimer = C_Timer.NewTimer(delay, tick)
        end
    end

    tick()
end

function CattosShuffle:CompleteSpinAnimation(target, winnerSlot)
    -- Clear animation timer
    self.animationTimer = nil

    -- Stop all tick sounds to prevent overlap
    if self.tickSoundHandles then
        for _, handle in pairs(self.tickSoundHandles) do
            StopSound(handle, 0)
        end
        self.tickSoundHandles = {}
    end
    if self.lastTickSound then
        StopSound(self.lastTickSound, 0)
        self.lastTickSound = nil
    end

    -- Reset sound index for next spin
    self.currentLoopIndex = nil

    -- Play win sound
    if self.PlaySound then
        self:PlaySound("WIN")
    end

    -- Highlight winner
    self:HighlightWinner(target, winnerSlot)

    -- Call completion handler
    self:OnSpinComplete()
end

-- Sound system with custom sound support
function CattosShuffle:PlaySound(soundType, delay)
    if not CattosShuffleDB.soundEnabled then return end

    -- Determine selected theme (default to "trute" for now)
    local soundTheme = CattosShuffleDB.soundTheme or "trute"

    -- Use custom sounds if available
    if soundTheme and soundTheme ~= "default" then
        local customSounds = {
            TICK = {
                "Interface\\AddOns\\CattosShuffle\\" .. soundTheme .. "\\loop\\loop1.ogg",
                "Interface\\AddOns\\CattosShuffle\\" .. soundTheme .. "\\loop\\loop2.ogg",
                "Interface\\AddOns\\CattosShuffle\\" .. soundTheme .. "\\loop\\loop3.ogg",
                "Interface\\AddOns\\CattosShuffle\\" .. soundTheme .. "\\loop\\loop4.ogg",
            },
            START = "Interface\\AddOns\\CattosShuffle\\" .. soundTheme .. "\\start\\start.ogg",
            WIN = "Interface\\AddOns\\CattosShuffle\\" .. soundTheme .. "\\win\\win2.ogg",
        }

        local soundFile = nil
        if soundType == "TICK" then
            -- Alternate between all 4 loop sounds (1→2→3→4→1→2→3→4...)
            if not self.currentLoopIndex then
                self.currentLoopIndex = 1
            else
                self.currentLoopIndex = self.currentLoopIndex + 1
                if self.currentLoopIndex > 4 then
                    self.currentLoopIndex = 1
                end
            end
            soundFile = customSounds.TICK[self.currentLoopIndex]
        else
            soundFile = customSounds[soundType]
        end

        if soundFile then
            -- Stop ALL previous tick sounds to prevent overlap
            if soundType == "TICK" then
                -- Stop the last played sound
                if self.lastTickSound then
                    StopSound(self.lastTickSound, 0)
                end
                -- Also stop any sounds that might still be playing
                if self.tickSoundHandles then
                    for _, handle in pairs(self.tickSoundHandles) do
                        StopSound(handle, 0)
                    end
                    self.tickSoundHandles = {}
                end
            end

            -- Only play new sound if we have enough time before next tick
            -- Reduced minimum delay to 0.08 seconds for faster animations
            if soundType ~= "TICK" or not delay or delay >= 0.08 then
                -- PlaySoundFile for custom OGG files
                local willPlay, soundHandle = PlaySoundFile(soundFile, "Master")

                -- Store handle for tick sounds to stop them next time
                if soundType == "TICK" and soundHandle then
                    self.lastTickSound = soundHandle
                    -- Also keep track of all tick sounds
                    if not self.tickSoundHandles then
                        self.tickSoundHandles = {}
                    end
                    table.insert(self.tickSoundHandles, soundHandle)
                    -- Keep only last 5 handles to avoid memory issues
                    if #self.tickSoundHandles > 5 then
                        table.remove(self.tickSoundHandles, 1)
                    end
                end
            end

            return
        end
    end

    -- Fallback to default WoW sounds - optimierte Auswahl für Classic Era!
    local sounds = {
        -- Tick: Rotate Character - mechanischer Dreh-Sound!
        TICK = 862,  -- igInventoryRotateCharacter - Perfekter mechanischer Loop!

        -- Win: Epischer Erfolgs-Sound!
        WIN = 878,  -- QUESTCOMPLETED - Jeder kennt und liebt diesen Sound!

        -- Start: Auktionshaus/Handel Sound - passt zum Gambling
        START = 5274,  -- Auction House Open Sound

        -- Loss: Item zerstört - dramatisch
        LOSS = 3334,  -- Item Break/Destroy Sound
    }

    local soundId = sounds[soundType]
    if soundId then
        -- Stop previous tick sound to prevent overlap
        if soundType == "TICK" and self.lastWowTickSound then
            StopSound(self.lastWowTickSound)
            self.lastWowTickSound = nil
        end

        local channel = (soundType == "WIN") and "Master" or "SFX"
        local willPlay, soundHandle = PlaySound(soundId, channel)

        -- Store handle for tick sounds to stop them next time
        if soundType == "TICK" and soundHandle then
            self.lastWowTickSound = soundHandle
        end
    end
end

-- Utility: Find value in table
function table.find(t, value)
    for i, v in ipairs(t) do
        if v == value then
            return i
        end
    end
    return nil
end