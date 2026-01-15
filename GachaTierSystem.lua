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
        weight = 71.6,  -- 71.6% base chance (balanced for shard system)
        description = "Crafting Materials, Junk & Misc"
    },
    ["B"] = {
        name = "B Tier",
        color = {r=0.6, g=0.8, b=1.0},
        hex = "ff99ccff",
        weight = 20,  -- 20% base chance (unchanged)
        description = "Consumables & Quest Items"
    },
    ["A"] = {
        name = "A Tier",
        color = {r=0.6, g=0.2, b=0.8},
        hex = "ff9933cc",
        weight = 7,   -- 7% base chance (slightly decreased)
        description = "Weapons, Armor & Bags (Not Equipped)"
    },
    ["S"] = {
        name = "S Tier",
        color = {r=1.0, g=0.84, b=0},
        hex = "ffffd700",
        weight = 1.1,   -- 1.1% base chance (tuned for ~75 pulls per 3 shards)
        description = "Currently Equipped Items"
    },
    ["SS"] = {
        name = "SS Tier",
        color = {r=1.0, g=0.5, b=0},
        hex = "ffff8000",
        weight = 0.3, -- 0.3% base chance (ULTRA RARE, tuned for shard balance)
        description = "Epic/Legendary Equipped Items"
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
Gacha.pendingOpenAfterCombat = false

-- Pity System State
Gacha.shards = 0
Gacha.maxShards = 3

-- Second Pity System (50 spins guarantee)
Gacha.spinCount = 0
Gacha.pityThreshold = 50

-- Third Pity System (B-Tier every 10 rolls)
Gacha.bTierPityCount = 0
Gacha.bTierPityThreshold = 10

-- Bonus Roll System (for Projectiles/Throwables)
Gacha.bonusRollChance = 0  -- Starts at 0%, accumulates 5% per roll
Gacha.bonusRollBaseIncrement = 5  -- 5% per roll
Gacha.projectilePool = {}  -- Separate pool for projectiles/throwables

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
    local equipSlot = item.equipSlot or ""

    -- Start with base tier
    local tier = "C"

    -- PRIORITY 1: Check if equipped first (highest priority)
    if isEquipped then
        -- Equipped items are always at least S tier
        tier = "S"

        -- If Epic/Legendary equipped, upgrade to SS tier
        if quality >= 4 then
            tier = "SS"
        end

        -- Return immediately for equipped items
        return tier
    end

    -- PRIORITY 2: Non-equipped items categorization

    -- B TIER: Quest Items & Consumables
    -- Quest items
    if item.isQuest or IsQuestItem(item.itemId) then
        tier = "B"
    -- Consumables (Food, Potions, Elixirs, Flasks, Bandages, etc.)
    elseif baseType == "Consumable" or baseType == "Verbrauchbar" or -- EN/DE base
           baseType == "Verbrauchsgüter" or -- DE alternative
           subType == "Food & Drink" or subType == "Essen & Trinken" or
           subType == "Potion" or subType == "Trank" or
           subType == "Elixir" or subType == "Elixier" or
           subType == "Flask" or subType == "Fläschchen" or
           subType == "Bandage" or subType == "Verband" or
           subType == "Scroll" or subType == "Rolle" or
           subType == "Schriftrolle" or
           subType == "Other" and baseType == "Consumable" or
           subType == "Explosives" or subType == "Sprengstoffe" or
           subType == "Devices" or subType == "Geräte" then
        tier = "B"

    -- A TIER: Equipable items, Pets, Mounts (Not currently worn)
    -- Companion Pets - Check by name FIRST (most reliable for WoW Classic and different language clients)
    -- In WoW Classic, pets might just be "Miscellaneous" items without proper subtype
    elseif item.name and (
               -- English pet names (Classic WoW complete list)
               string.find(item.name:lower(), "cat carrier") or  -- Multiple cat variants
               string.find(item.name:lower(), "parrot cage") or  -- Multiple parrot variants
               string.find(item.name:lower(), "rabbit crate") or
               string.find(item.name:lower(), "turtle box") or
               string.find(item.name:lower(), "rat cage") or
               string.find(item.name:lower(), "prairie dog whistle") or
               string.find(item.name:lower(), "cockroach") or
               string.find(item.name:lower(), "ancona chicken") or
               string.find(item.name:lower(), "worg pup") or
               string.find(item.name:lower(), "worg carrier") or
               string.find(item.name:lower(), "smolderweb carrier") or
               string.find(item.name:lower(), "piglet's collar") or  -- Mr. Wiggles
               string.find(item.name:lower(), "great horned owl") or
               string.find(item.name:lower(), "hawk owl") or
               string.find(item.name:lower(), "crimson snake") or
               string.find(item.name:lower(), "black kingsnake") or
               string.find(item.name:lower(), "brown snake") or
               string.find(item.name:lower(), "wood frog box") or
               string.find(item.name:lower(), "tree frog box") or
               string.find(item.name:lower(), "sprite darter egg") or
               string.find(item.name:lower(), "chicken egg") or
               string.find(item.name:lower(), "westfall chicken") or
               string.find(item.name:lower(), "pet bombling") or
               string.find(item.name:lower(), "lil' smoky") or
               string.find(item.name:lower(), "lifelike mechanical toad") or
               string.find(item.name:lower(), "mechanical squirrel") or
               string.find(item.name:lower(), "mechanical chicken") or
               string.find(item.name:lower(), "dark whelpling") or
               string.find(item.name:lower(), "tiny crimson whelpling") or
               string.find(item.name:lower(), "tiny emerald whelpling") or
               string.find(item.name:lower(), "azure whelpling") or
               string.find(item.name:lower(), "disgusting oozeling") or
               string.find(item.name:lower(), "red helper box") or  -- Winter's Little Helper
               string.find(item.name:lower(), "green helper box") or  -- Winter Reindeer
               string.find(item.name:lower(), "snowman kit") or
               string.find(item.name:lower(), "jingling bell") or  -- Winter Reindeer
               string.find(item.name:lower(), "captured flame") or
               string.find(item.name:lower(), "truesilver shafted arrow") or  -- Peddlefeet
               string.find(item.name:lower(), "silver shafted arrow") or  -- Peddlefeet
               string.find(item.name:lower(), "blood parrot") or
               string.find(item.name:lower(), "mini diablo") or  -- Collector's Edition
               string.find(item.name:lower(), "panda cub") or  -- Collector's Edition
               string.find(item.name:lower(), "panda collar") or  -- Collector's Edition
               string.find(item.name:lower(), "zergling leash") or  -- Collector's Edition
               string.find(item.name:lower(), "diablo stone") or  -- Collector's Edition
               string.find(item.name:lower(), "banana charm") or  -- Collector's Edition
               string.find(item.name:lower(), "pet") and string.find(item.name:lower(), "carrier") or
               -- German pet names (Classic WoW vollständige Liste)
               string.find(item.name:lower(), "katzenträger") or
               string.find(item.name:lower(), "katzentransportkorb") or
               string.find(item.name:lower(), "papageienkäfig") or
               string.find(item.name:lower(), "schlangenkäfig") or
               string.find(item.name:lower(), "kaninchenkiste") or
               string.find(item.name:lower(), "hasenkiste") or
               string.find(item.name:lower(), "schildkrötenbox") or
               string.find(item.name:lower(), "schildkrötenkiste") or
               string.find(item.name:lower(), "eulenpfeife") or
               string.find(item.name:lower(), "hornuhu") or  -- Great Horned Owl
               string.find(item.name:lower(), "habichtseule") or  -- Hawk Owl
               string.find(item.name:lower(), "sperbereule") or  -- Hawk Owl alternative
               string.find(item.name:lower(), "rattenkäfig") or
               string.find(item.name:lower(), "präriehundpfeife") or
               string.find(item.name:lower(), "kakerlake") or
               string.find(item.name:lower(), "schabe") or
               string.find(item.name:lower(), "ancona") or
               string.find(item.name:lower(), "worgwelpe") or
               string.find(item.name:lower(), "worgträger") or
               string.find(item.name:lower(), "schwelnetztransporter") or
               string.find(item.name:lower(), "ferkelhalsband") or  -- Piglet's Collar
               string.find(item.name:lower(), "purpurrote schlange") or  -- Crimson Snake
               string.find(item.name:lower(), "schwarze königsnatter") or  -- Black Kingsnake
               string.find(item.name:lower(), "braune schlange") or  -- Brown Snake
               string.find(item.name:lower(), "waldlaubfroschkiste") or  -- Wood Frog Box
               string.find(item.name:lower(), "baumfroschkiste") or  -- Tree Frog Box
               string.find(item.name:lower(), "feendrachen") or  -- Sprite Darter
               string.find(item.name:lower(), "hühnerei") or  -- Chicken Egg
               string.find(item.name:lower(), "westfall-huhn") or  -- Westfall Chicken
               string.find(item.name:lower(), "haustierbömbling") or  -- Pet Bombling
               string.find(item.name:lower(), "kleine rauchmaschine") or  -- Lil' Smoky
               string.find(item.name:lower(), "lebensechte mechanische kröte") or  -- Lifelike Mechanical Toad
               string.find(item.name:lower(), "mechanisches eichhörnchen") or  -- Mechanical Squirrel
               string.find(item.name:lower(), "mechanisches huhn") or  -- Mechanical Chicken
               string.find(item.name:lower(), "dunkler welpling") or  -- Dark Whelpling
               string.find(item.name:lower(), "winziger purpurroter welpling") or  -- Tiny Crimson Whelpling
               string.find(item.name:lower(), "winziger smaragdgrüner welpling") or  -- Tiny Emerald Whelpling
               string.find(item.name:lower(), "azurblauer welpling") or  -- Azure Whelpling
               string.find(item.name:lower(), "ekelhaftes schleimchen") or  -- Disgusting Oozeling
               string.find(item.name:lower(), "roter helferkasten") or  -- Red Helper Box
               string.find(item.name:lower(), "grüner helferkasten") or  -- Green Helper Box
               string.find(item.name:lower(), "schneemannbausatz") or  -- Snowman Kit
               string.find(item.name:lower(), "schellenglocke") or  -- Jingling Bell
               string.find(item.name:lower(), "eingefangene flamme") or  -- Captured Flame
               string.find(item.name:lower(), "wahrer silberpfeil") or  -- Truesilver Shafted Arrow
               string.find(item.name:lower(), "silberpfeil") or  -- Silver Shafted Arrow
               string.find(item.name:lower(), "blutpapagei") or  -- Blood Parrot
               string.find(item.name:lower(), "mini-diablo") or  -- Collector's Edition
               string.find(item.name:lower(), "pandajunges") or  -- Collector's Edition
               string.find(item.name:lower(), "pandahalsband") or  -- Collector's Edition
               string.find(item.name:lower(), "zergling-leine") or  -- Collector's Edition
               string.find(item.name:lower(), "diablostein") or  -- Collector's Edition
               string.find(item.name:lower(), "bananenanhänger") or  -- Collector's Edition
               string.find(item.name:lower(), "haustierträger") or
               string.find(item.name:lower(), "haustiertransportbox") or
               -- More specific German pet names
               string.find(item.name:lower(), "siamkatze") or
               string.find(item.name:lower(), "bombaykatze") or
               string.find(item.name:lower(), "orangefarbene tigerkatze") or
               string.find(item.name:lower(), "silbergetigerte katze") or
               string.find(item.name:lower(), "maine coon") or
               string.find(item.name:lower(), "schneeschuh") or
               string.find(item.name:lower(), "ara") or  -- Macaw parrots
               string.find(item.name:lower(), "hyazinthara") or
               string.find(item.name:lower(), "grüner flügelara") or
               string.find(item.name:lower(), "scharlachara") or
               string.find(item.name:lower(), "fledermausküken") or
               string.find(item.name:lower(), "mechanisches huhn") or
               string.find(item.name:lower(), "winziger wanderdrache") or
               string.find(item.name:lower(), "drachenfalke") or
               string.find(item.name:lower(), "sprite") or
               string.find(item.name:lower(), "welpling") or
               string.find(item.name:lower(), "raptorküken") or
               -- Generic German pet terms
               string.find(item.name:lower(), "träger") and (string.find(item.name:lower(), "katze") or string.find(item.name:lower(), "tier")) or
               string.find(item.name:lower(), "käfig") and string.find(item.name:lower(), "tier") or
               string.find(item.name:lower(), "ei") and string.find(item.name:lower(), "haustier")
           ) then
        tier = "A"
    -- Also check by type/subtype (fallback for items not in name list)
    elseif baseType == "Miscellaneous" and subType == "Companion Pets" or
           baseType == "Diverses" and subType == "Haustiere" or
           baseType == "Verschiedenes" and subType == "Haustiere" or
           subType == "Companion Pets" or subType == "Haustiere" then
        tier = "A"
    -- Mounts (Any quality - will be upgraded by rarity system)
    elseif subType == "Mount" or subType == "Reittier" then
        tier = "A"  -- Base tier A, Epic mounts will auto-upgrade to S
    -- Armor
    elseif baseType == "Armor" or baseType == "Rüstung" or
           -- Check by equipment slot (more reliable)
           (equipSlot ~= "" and equipSlot ~= "INVTYPE_NON_EQUIP_IGNORE" and
            (equipSlot:find("INVTYPE_") or equipSlot ~= "")) then
        tier = "A"
    -- Weapons
    elseif baseType == "Weapon" or baseType == "Waffe" then
        tier = "A"
    -- Containers (Bags, Quivers, Ammo Pouches)
    elseif baseType == "Container" or baseType == "Behälter" or
           baseType == "Quiver" or baseType == "Köcher" or
           subType == "Bag" or subType == "Tasche" or
           subType == "Soul Bag" or subType == "Seelentasche" or
           subType == "Herb Bag" or subType == "Kräutertasche" or
           subType == "Enchanting Bag" or subType == "Verzauberertasche" or
           subType == "Engineering Bag" or subType == "Ingenieurstasche" or
           subType == "Mining Bag" or subType == "Bergbautasche" or
           subType == "Leatherworking Bag" or subType == "Lederertasche" or
           subType == "Ammo Pouch" or subType == "Munitionsbeutel" then
        tier = "A"
    -- Projectiles (Arrows, Bullets) - EXCLUDED from main pool (bonus loot only)
    elseif baseType == "Projectile" or baseType == "Projektil" or
           subType == "Arrow" or subType == "Pfeil" or
           subType == "Bullet" or subType == "Geschoss" or
           subType == "Thrown" or subType == "Wurfwaffe" then
        tier = "PROJECTILE"  -- Special tier to exclude from main gacha

    -- C TIER: Everything else (Junk, Trade Goods, Reagents, Misc)
    -- Trade Goods
    elseif baseType == "Trade Goods" or baseType == "Handwerkswaren" or
           baseType == "Tradeskill" then
        tier = "C"
    -- Reagents
    elseif baseType == "Reagent" or baseType == "Reagenz" then
        tier = "C"
    -- Recipe/Patterns
    elseif baseType == "Recipe" or baseType == "Rezept" or
           subType == "Book" or subType == "Buch" or
           subType == "Pattern" or subType == "Muster" or
           subType == "Schematic" or subType == "Bauplan" or
           subType == "Design" or subType == "Entwurf" or
           subType == "Formula" or subType == "Formel" or
           subType == "Plans" or subType == "Pläne" then
        tier = "C"
    -- Miscellaneous
    elseif baseType == "Miscellaneous" or baseType == "Diverses" or
           baseType == "Verschiedenes" then
        tier = "C"
    -- Junk
    elseif baseType == "Junk" or baseType == "Plunder" or
           baseType == "Schrott" or quality == 0 then -- Gray quality items
        tier = "C"
    -- Keys
    elseif baseType == "Key" or baseType == "Schlüssel" then
        tier = "C"
    -- Gems
    elseif baseType == "Gem" or baseType == "Edelstein" or
           subType == "Simple" or subType == "Einfach" or
           subType == "Prismatic" or subType == "Prismatisch" then
        tier = "C"
    -- Default fallback
    else
        tier = "C"
    end

    -- Apply rarity upgrade for non-equipped items
    -- This can upgrade items based on their quality (Rare/Epic/Legendary)
    if not isEquipped and quality >= 3 then
        local upgrade = RARITY_UPGRADE[quality] or 0

        -- Upgrade tier based on rarity
        if tier == "C" and upgrade >= 1 then
            tier = "B"
        elseif tier == "B" and upgrade >= 1 then
            tier = "A"
        elseif tier == "A" and upgrade >= 2 then
            tier = "S"  -- Very rare unequipped items can become S tier
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
    self.projectilePool = {}  -- Separate pool for projectiles
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

                -- Separate projectiles into their own pool
                if tier == "PROJECTILE" then
                    table.insert(self.projectilePool, item)
                else
                    table.insert(self.itemPool, item)
                    if self.tierPools[tier] then
                        table.insert(self.tierPools[tier], item)
                    end
                    self.totalItems = self.totalItems + 1
                end
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

                    -- Separate projectiles into their own pool
                    if tier == "PROJECTILE" then
                        table.insert(self.projectilePool, item)
                    else
                        table.insert(self.itemPool, item)
                        if self.tierPools[tier] then
                            table.insert(self.tierPools[tier], item)
                        end
                        self.totalItems = self.totalItems + 1
                    end
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
function Gacha:GetRandomItemFromTier(tier, excludeList)
    local pool = self.tierPools[tier]
    if not pool or #pool == 0 then
        -- If tier is empty, downgrade to next tier
        if tier == "SS" then return self:GetRandomItemFromTier("S", excludeList)
        elseif tier == "S" then return self:GetRandomItemFromTier("A", excludeList)
        elseif tier == "A" then return self:GetRandomItemFromTier("B", excludeList)
        elseif tier == "B" then return self:GetRandomItemFromTier("C", excludeList)
        else return nil end
    end

    -- If we have an exclude list, filter the pool
    if excludeList and next(excludeList) then
        local availablePool = {}
        for _, item in ipairs(pool) do
            local isExcluded = false
            for _, excluded in pairs(excludeList) do
                if excluded and item and excluded.itemId == item.itemId and
                   excluded.bag == item.bag and excluded.slot == item.slot then
                    isExcluded = true
                    break
                end
            end
            if not isExcluded and not item.isDeleted then
                table.insert(availablePool, item)
            end
        end

        -- If all items are excluded, just return a random one anyway
        if #availablePool == 0 then
            return pool[math.random(1, #pool)]
        end

        return availablePool[math.random(1, #availablePool)]
    end

    return pool[math.random(1, #pool)]
end

-- Fast x10 pull - calculate all results instantly
function Gacha:Pull10Fast()
    if self.isSpinning then
        print("|cffff0000Already pulling!|r")
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

    print("|cffffcc00Processing x10 pull...|r")
    print(string.format("|cffccccccStarting counters - Spins: %d/%d, B-Tier: %d/%d|r",
        self.spinCount, self.pityThreshold, self.bTierPityCount, self.bTierPityThreshold))

    local results = {
        matches = {},  -- Store which pulls had matches
        deletedItems = {},  -- Track items already marked for deletion
        pulledItems = {}  -- Track ALL items that have been pulled (to prevent duplicates)
    }

    -- Helper function to check if item was already pulled
    local function wasItemAlreadyPulled(item, pulledList)
        for _, pulled in ipairs(pulledList) do
            -- Check if same item (by ID and location)
            if pulled.itemId == item.itemId and
               pulled.bag == item.bag and
               pulled.slot == item.slot then
                return true
            end
        end
        return false
    end

    -- Process all 10 pulls at once
    for pullNum = 1, 10 do
        -- Pre-calculate what the counter WOULD be after increment
        local nextSpinCount = self.spinCount + 1
        local nextBTierCount = self.bTierPityCount + 1

        -- Check pity systems for this pull (using pre-calculated values)
        local forcedPityTier = nil

        -- Check if we've passed the 50-spin threshold (not just equal)
        if nextSpinCount >= self.pityThreshold then
            forcedPityTier = math.random() < 0.5 and "S" or "A"
            print(string.format("|cffffcc00Pull %d: 50-SPIN PITY ACTIVE! (Spin %d) Forcing %s tier triple!|r",
                pullNum, nextSpinCount, forcedPityTier))
        -- Check B-tier pity (only if main pity isn't active)
        elseif nextBTierCount >= self.bTierPityThreshold then
            forcedPityTier = "B"
            print(string.format("|cff99ccffPull %d: B-TIER PITY! (Count %d) Forcing B tier triple!|r",
                pullNum, nextBTierCount))
        end

        -- NOW increment counters (after pity check, so it's consistent with single pulls)
        self.spinCount = self.spinCount + 1
        CattosShuffleDB.gachaSpinCount = self.spinCount
        self.bTierPityCount = self.bTierPityCount + 1
        CattosShuffleDB.gachaBTierPityCount = self.bTierPityCount

        -- Increment bonus roll chance for EACH pull (5% per pull)
        self.bonusRollChance = (self.bonusRollChance or 0) + self.bonusRollBaseIncrement
        CattosShuffleDB.gachaBonusRollChance = self.bonusRollChance

        -- Get 3 random tiers/items for this pull
        local pullResult = {
            tiers = {},
            items = {}
        }

        for slot = 1, 3 do
            local tier = forcedPityTier or self:GetRandomTier()

            -- Create combined exclude list (deleted items + already pulled items)
            local excludeList = {}

            -- Add deleted items
            for _, item in ipairs(results.deletedItems) do
                table.insert(excludeList, item)
            end

            -- Add already pulled items (to prevent duplicates of single items)
            for _, item in ipairs(results.pulledItems) do
                table.insert(excludeList, item)
            end

            -- Get random item excluding already used ones
            local item = self:GetRandomItemFromTier(tier, excludeList)

            pullResult.tiers[slot] = tier
            pullResult.items[slot] = item

            -- Track this item as pulled (but don't add to pulledItems yet, do it after all 3 slots)
        end

        -- Now add all 3 items from this pull to the pulledItems list
        for _, item in ipairs(pullResult.items) do
            if item and not wasItemAlreadyPulled(item, results.pulledItems) and not item.isDeleted then
                table.insert(results.pulledItems, item)
            end
        end

        -- Check for match
        local tier1 = pullResult.tiers[1]
        local tier2 = pullResult.tiers[2]
        local tier3 = pullResult.tiers[3]

        local hasMatch = (tier1 == tier2 and tier2 == tier3)

        -- Find the best tier rolled (SS > S > A > B > C)
        local bestTier = tier1
        local bestItem = pullResult.items[1]
        local tierOrder = { SS = 5, S = 4, A = 3, B = 2, C = 1 }

        for i = 1, 3 do
            local currentTier = pullResult.tiers[i]
            if tierOrder[currentTier] > tierOrder[bestTier] then
                bestTier = currentTier
                bestItem = pullResult.items[i]
            end
        end

        -- Prepare result data - show the best tier/item from this pull
        results[pullNum] = {
            tier = bestTier,  -- Show the best tier rolled
            item = bestItem,  -- Show the item from best tier
            shouldDelete = false,
            allTiers = string.format("%s-%s-%s", tier1, tier2, tier3)  -- Store all tiers for debug
        }

        if hasMatch then
            -- Mark all 3 slots from this pull for deletion
            table.insert(results.matches, pullNum)

            -- Reset appropriate pity counter
            if tier1 == "B" then
                self.bTierPityCount = 0
                CattosShuffleDB.gachaBTierPityCount = 0
            end
            if tier1 == "S" or tier1 == "A" then
                self.spinCount = 0
                CattosShuffleDB.gachaSpinCount = 0
            end

            -- Choose random item from the matched tier for deletion
            -- But make sure we don't choose an already deleted item
            local availableVictims = {}
            for _, item in ipairs(pullResult.items) do
                if item then
                    local alreadyDeleted = false
                    for _, deleted in pairs(results.deletedItems) do
                        if deleted and deleted.itemId == item.itemId and
                           deleted.bag == item.bag and deleted.slot == item.slot then
                            alreadyDeleted = true
                            break
                        end
                    end
                    if not alreadyDeleted then
                        table.insert(availableVictims, item)
                    end
                end
            end

            local victim
            if #availableVictims > 0 then
                victim = availableVictims[math.random(1, #availableVictims)]
            else
                -- Fallback if somehow all are deleted (shouldn't happen)
                victim = pullResult.items[math.random(1, 3)]
            end

            -- Determine delete count for stackable items
            local deleteCount = 1
            if victim and victim.stackCount and victim.stackCount > 1 then
                deleteCount = math.random(1, victim.stackCount)
            end

            -- Add to deleted items list IMMEDIATELY
            if victim then
                table.insert(results.deletedItems, victim)

                -- Also mark this specific item as "used" so it can't appear again
                victim.isDeleted = true
            end

            -- Override the result to mark it for deletion
            results[pullNum] = {
                tier = tier1,  -- All 3 match, so tier1 = tier2 = tier3
                item = victim,
                shouldDelete = true,
                deleteCount = deleteCount,  -- Add the delete count
                allTiers = string.format("%s-%s-%s", tier1, tier2, tier3)
            }

            print(string.format("|cffff0000Pull %d: MATCH! %s-%s-%s|r", pullNum, tier1, tier2, tier3))
        else
            -- Debug output for non-matches showing best tier
            if bestTier == "S" or bestTier == "SS" then
                print(string.format("|cffffd700Pull %d: %s-%s-%s (Best: %s)|r", pullNum, tier1, tier2, tier3, bestTier))
            end
            -- Handle shards for S/SS without match
            if (tier1 == "S" or tier1 == "SS") or
               (tier2 == "S" or tier2 == "SS") or
               (tier3 == "S" or tier3 == "SS") then
                self.shards = math.min((self.shards or 0) + 1, self.maxShards)
                CattosShuffleDB.gachaShards = self.shards
            end
        end
    end

    -- Check for bonus rolls after x10 pull
    -- Each pull increments bonus chance by 5%, so x10 = 50% added
    print(string.format("|cff888888DEBUG: Bonus chance after x10: %d%% | Projectiles: %d|r",
        self.bonusRollChance or 0,
        self.projectilePool and #self.projectilePool or 0))

    self:CheckBonusRoll()

    -- Clean up temporary isDeleted flags from all items in the pool
    -- This prevents items from being permanently marked as deleted
    for _, tierPool in pairs(self.tierPools) do
        if tierPool then
            for _, item in ipairs(tierPool) do
                if item and item.isDeleted then
                    item.isDeleted = nil  -- Remove the temporary flag
                end
            end
        end
    end

    -- Also clean up from the main item pool
    for _, item in ipairs(self.itemPool) do
        if item and item.isDeleted then
            item.isDeleted = nil
        end
    end

    -- Update UI
    if self.UpdateUI then
        self:UpdateUI()
    end

    -- Show results window
    self:ShowX10Results(results)
end

-- Start the gacha pull (single pull only now)
function Gacha:Pull()
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

    -- Do a single pull
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

    -- Stop all animations from previous pull (clears glow)
    self:StopAllSingleAnimations()

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

    -- NOTE: Pity counters moved to OnPullComplete() to avoid counting interrupted spins
    -- We still need to check current pity state for forced tiers

    -- Check pity systems (50-spin has priority over B-Tier)
    local forcedPityTier = nil

    -- Check if NEXT spin would hit the 50 spin pity (check current count + 1)
    if (self.spinCount + 1) >= self.pityThreshold then
        -- 50/50 between S and A tier
        if math.random() < 0.5 then
            forcedPityTier = "S"
            print("|cffffcc00>>> 50-SPIN PITY: S TIER GUARANTEED! <<<|r")
        else
            forcedPityTier = "A"
            print("|cff9933cc>>> 50-SPIN PITY: A TIER GUARANTEED! <<<|r")
        end

        -- Mark that we should reset main pity after completion
        self.pendingMainPityReset = true

    -- Check for B-Tier pity (every 10 rolls) - only if 50-spin didn't trigger
    elseif (self.bTierPityCount + 1) >= self.bTierPityThreshold then
        forcedPityTier = "B"
        print("|cff99ccff>>> 10-ROLL PITY: B TIER TRIPLE GUARANTEED! <<<|r")

        -- Mark that we should reset B-tier pity after completion
        self.pendingBTierPityReset = true
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

    -- Increment pity counters NOW (after successful completion)
    self.spinCount = self.spinCount + 1
    CattosShuffleDB.gachaSpinCount = self.spinCount

    self.bTierPityCount = self.bTierPityCount + 1
    CattosShuffleDB.gachaBTierPityCount = self.bTierPityCount

    -- Increment bonus roll chance (5% per roll, accumulates)
    self.bonusRollChance = (self.bonusRollChance or 0) + self.bonusRollBaseIncrement
    CattosShuffleDB.gachaBonusRollChance = self.bonusRollChance

    -- Check for pending pity resets from DoPull
    if self.pendingMainPityReset then
        self.spinCount = 0
        CattosShuffleDB.gachaSpinCount = 0
        self.pendingMainPityReset = false
    end

    if self.pendingBTierPityReset then
        self.bTierPityCount = 0
        CattosShuffleDB.gachaBTierPityCount = 0
        self.pendingBTierPityReset = false
    end

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

        -- Reset appropriate pity counters based on tier (in addition to pity resets)
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

            -- Create pulsing animation for S/SS tier slots that awarded the shard
            for i = 1, 3 do
                local slot = self.slots[i]
                if (slot.tier == "S" or slot.tier == "SS") and self.frame and self.frame.slots[i] then
                    self:CreateShardPulseAnimation(self.frame.slots[i], slot.tier)
                end
            end

            if self.shards >= self.maxShards then
                print("|cff00ff00You have 3 shards! Click the shard icon to switch to Shuffle mode!|r")
            end
        else
            print("|cff00ff00No match - items are safe!|r")
        end

        PlaySound(3332, "SFX")  -- Quest complete sound
    end

    -- Check for BONUS ROLL (projectiles/throwables)
    self:CheckBonusRoll()

    -- Update UI to show shard count
    if self.UpdateUI then
        self:UpdateUI()
    end
end

-- Show bonus roll window with percentage animation
function Gacha:ShowBonusRollWindow(item)
    -- Create frame if it doesn't exist
    if not self.bonusRollFrame then
        local frame = CreateFrame("Frame", "CattosGachaBonusRoll", UIParent, "BackdropTemplate")
        frame:SetSize(350, 250)
        frame:SetPoint("CENTER", 0, 150)  -- Slightly higher
        frame:SetFrameStrata("FULLSCREEN_DIALOG")  -- Highest strata
        frame:SetFrameLevel(200)  -- Very high frame level to be above x10 window
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", frame.StartMoving)
        frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

        -- Backdrop
        frame:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",  -- Solid black texture
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = false,
            edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 }
        })
        frame:SetBackdropColor(0, 0, 0, 1)  -- Fully opaque black background
        frame:SetBackdropBorderColor(1, 0, 0, 1)  -- Red border for danger

        -- Add an extra solid background texture to ensure no transparency
        local bg = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
        bg:SetAllPoints(frame)
        bg:SetColorTexture(0, 0, 0, 1)  -- Solid black
        frame.solidBg = bg

        -- Title
        frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        frame.title:SetPoint("TOP", frame, "TOP", 0, -20)
        frame.title:SetText("|cffff0000BONUS ROLL - PROJECTILE DELETION|r")

        -- Item icon
        frame.icon = frame:CreateTexture(nil, "ARTWORK")
        frame.icon:SetSize(64, 64)
        frame.icon:SetPoint("TOP", frame.title, "BOTTOM", 0, -15)

        -- Item name
        frame.itemName = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        frame.itemName:SetPoint("TOP", frame.icon, "BOTTOM", 0, -10)

        -- Stack info
        frame.stackInfo = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame.stackInfo:SetPoint("TOP", frame.itemName, "BOTTOM", 0, -5)

        -- Percentage display (big)
        frame.percentDisplay = frame:CreateFontString(nil, "OVERLAY", "NumberFontNormalHuge")
        frame.percentDisplay:SetPoint("TOP", frame.stackInfo, "BOTTOM", 0, -15)
        frame.percentDisplay:SetFont("Fonts\\FRIZQT__.TTF", 48, "THICKOUTLINE")
        frame.percentDisplay:SetTextColor(1, 1, 0)  -- Yellow

        -- Result text
        frame.resultText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        frame.resultText:SetPoint("TOP", frame.percentDisplay, "BOTTOM", 0, -10)
        frame.resultText:SetText("")

        -- Close button (appears after animation)
        frame.closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
        frame.closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
        frame.closeButton:Hide()  -- Hidden during animation

        self.bonusRollFrame = frame
    end

    local frame = self.bonusRollFrame

    -- Force non-transparent background every time we show the window
    frame:SetBackdropColor(0, 0, 0, 1)  -- Fully opaque black
    frame:SetBackdropBorderColor(1, 0, 0, 1)  -- Red border

    -- Ensure solid background is visible
    if frame.solidBg then
        frame.solidBg:SetColorTexture(0, 0, 0, 1)
        frame.solidBg:Show()
    end

    -- Set item info
    frame.icon:SetTexture(item.icon)
    frame.itemName:SetText(item.link or item.name)

    local stackText = ""
    if item.stackCount and item.stackCount > 1 then
        stackText = string.format("|cffccccccStack of %d|r", item.stackCount)
    else
        stackText = "|cffccccccSingle item|r"
    end
    frame.stackInfo:SetText(stackText)

    -- Reset displays
    frame.percentDisplay:SetText("0")
    frame.resultText:SetText("")
    frame.closeButton:Hide()

    -- Show frame
    frame:Show()

    -- Start percentage animation
    self:AnimateBonusRollPercentage(item)
end

-- Animate the percentage roll for bonus deletion
function Gacha:AnimateBonusRollPercentage(item)
    local frame = self.bonusRollFrame
    if not frame then return end

    -- Determine final percentage (1-100%)
    local finalPercent = math.random(1, 100)

    -- Animation variables
    local currentPercent = 0
    local animationTime = 0
    local animationDuration = 3  -- 3 seconds total
    local tickSpeed = 0.03
    local nextSound = 0
    local soundInterval = 0.1

    -- Cancel any existing animation
    if self.bonusRollTicker then
        self.bonusRollTicker:Cancel()
    end

    -- Start the animation
    self.bonusRollTicker = C_Timer.NewTicker(tickSpeed, function(ticker)
        animationTime = animationTime + tickSpeed

        -- Calculate progress (with easing)
        local progress = animationTime / animationDuration
        if progress >= 1 then
            progress = 1
        end

        -- Easing function (slow down at end)
        local easedProgress = 1 - math.pow(1 - progress, 3)

        -- Calculate current displayed percentage
        currentPercent = math.floor(easedProgress * finalPercent)

        -- Calculate current deletion amount based on current percentage
        local currentDeleteAmount = 1
        if item.stackCount and item.stackCount > 1 then
            currentDeleteAmount = math.max(1, math.floor(item.stackCount * currentPercent / 100))
        end

        -- Update display with color based on percentage
        local r, g, b = 0, 1, 0  -- Green
        if currentPercent >= 75 then
            r, g, b = 1, 0, 0  -- Red for high percentage
        elseif currentPercent >= 50 then
            r, g, b = 1, 0.5, 0  -- Orange for medium
        elseif currentPercent >= 25 then
            r, g, b = 1, 1, 0  -- Yellow for low-medium
        end

        frame.percentDisplay:SetTextColor(r, g, b)

        -- Show only the amount, no percentage
        frame.percentDisplay:SetText(tostring(currentDeleteAmount))

        -- Play tick sound
        if animationTime >= nextSound and progress < 0.9 then
            PlaySound(1210, "SFX")  -- Money sound
            nextSound = animationTime + soundInterval * (1 + progress * 2)  -- Slow down sounds
        end

        -- Check if animation is complete
        if progress >= 1 then
            ticker:Cancel()
            self.bonusRollTicker = nil

            -- Final display
            frame.percentDisplay:SetText(finalPercent .. "%")

            -- Calculate actual deletion amount
            local deleteAmount = 1
            if item.stackCount and item.stackCount > 1 then
                deleteAmount = math.max(1, math.floor(item.stackCount * finalPercent / 100))
            end

            -- Show result with both percentage and amount
            local resultColor = "|cffff0000"  -- Red
            if finalPercent <= 25 then
                resultColor = "|cff00ff00"  -- Green for low
            elseif finalPercent <= 50 then
                resultColor = "|cffffcc00"  -- Yellow for medium
            end

            -- Show only the final amount
            frame.percentDisplay:SetText(tostring(deleteAmount))
            frame.resultText:SetText(string.format("%sDELETING: %d of %d|r",
                resultColor, deleteAmount, item.stackCount or 1))

            -- Play final sound based on percentage
            if finalPercent >= 75 then
                PlaySound(888, "SFX")  -- Warning sound for high deletion
            elseif finalPercent >= 50 then
                PlaySound(3334, "SFX")  -- Item destroy sound
            else
                PlaySound(3332, "SFX")  -- Quest complete sound for low deletion
            end

            -- Show close button
            frame.closeButton:Show()

            -- Store deletion info
            self.pendingProjectileDeletion = {
                item = item,
                percentage = finalPercent,
                amount = deleteAmount
            }

            -- Actually perform the deletion
            self:PerformProjectileDeletion(item, deleteAmount)
        end
    end)
end

-- Perform the actual projectile deletion
function Gacha:PerformProjectileDeletion(item, deleteAmount)
    if InCombatLockdown() then
        print("|cffff0000Cannot delete during combat!|r")
        return
    end

    -- Just show the deletion message in chat, no popup
    print("|cffff0000========================================|r")
    print("|cffffcc00BONUS ROLL PROJECTILE DELETION!|r")
    print(string.format("|cffff0000DELETE: %d x %s|r", deleteAmount, item.link or item.name))
    print("|cffff0000Please delete the items manually now!|r")
    print("|cffff0000========================================|r")

    -- Play warning sound
    PlaySound(3334, "SFX")  -- Item destroy sound
end

-- Check and handle bonus roll for projectiles
function Gacha:CheckBonusRoll()
    print("|cff888888DEBUG: CheckBonusRoll called|r")

    -- Check if we have any projectiles
    if not self.projectilePool or #self.projectilePool == 0 then
        -- No projectiles = no bonus roll triggered
        print("|cff888888DEBUG: No projectiles in pool, skipping bonus roll|r")
        return
    end

    -- Roll for bonus (accumulated chance)
    local roll = math.random(1, 100)
    local currentChance = self.bonusRollChance or 0

    print(string.format("|cff888888Bonus Roll: %d vs %d%% chance (Pool: %d projectiles)|r",
        roll, currentChance, #self.projectilePool))

    if roll <= currentChance then
        -- BONUS ROLL HIT!
        print("|cffffcc00>>> BONUS ROLL TRIGGERED! <<<|r")
        print("|cffff0000Projectile/Throwable deletion incoming!|r")

        -- Reset bonus chance to 0
        self.bonusRollChance = 0
        CattosShuffleDB.gachaBonusRollChance = 0

        -- Pick a random projectile from the pool
        local bonusItem = self.projectilePool[math.random(1, #self.projectilePool)]

        if bonusItem then
            -- Play special sound for bonus
            PlaySound(888, "SFX")  -- Warning sound

            -- Show the bonus roll window with animation
            self:ShowBonusRollWindow(bonusItem)
        end
    else
        -- No bonus this time, chance continues to accumulate
        print(string.format("|cff888888Bonus roll failed. Chance increases to %d%% for next roll|r",
            currentChance + self.bonusRollBaseIncrement))
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
    local tier = self.slots[slotNum] and self.slots[slotNum].tier

    -- If it's A, S or SS tier, just show the glow animation
    if tier == "A" or tier == "S" or tier == "SS" then
        -- First stop any existing animation and clear the glow
        self:StopSingleSlotAnimation(slot)

        -- Show the epic glow animation for the tier
        self:CreateSingleSlotEpicAnimation(slot, tier)

        -- Play dramatic sound
        if tier == "SS" then
            PlaySound(31578, "SFX")  -- Epic loot sound
        elseif tier == "S" then
            PlaySound(888, "SFX")  -- PVP warning sound
        else
            PlaySound(3332, "SFX")  -- Quest complete sound
        end
    else
        -- For non-epic tiers, just mark with a simple red border
        slot:SetBackdropBorderColor(1, 0, 0, 1)  -- Red border for deletion
        slot:SetBackdropColor(0.3, 0, 0, 1)      -- Slight red tint

        -- Play warning sound
        PlaySound(888, "SFX")  -- PVP warning sound
    end
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

    -- Get the tier for special effects
    local tier = self.slots[slotNum] and self.slots[slotNum].tier

    -- Only SS tier gets automatic epic animation (legendary is special)
    -- S tier only gets it when selected for deletion (like A tier)
    if tier == "SS" and self.frame and self.frame.slots[slotNum] then
        self:CreateSingleSlotEpicAnimation(self.frame.slots[slotNum], tier)
    else
        -- Normal flash for all other tiers including S
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
end

-- Stop single slot animation and clean up
function Gacha:StopSingleSlotAnimation(slot)
    if not slot then return end

    -- Cancel any running animation
    if slot.animTicker then
        slot.animTicker:Cancel()
        slot.animTicker = nil
    end

    -- Cancel shard pulse ticker
    if slot.shardPulseTicker then
        slot.shardPulseTicker:Cancel()
        slot.shardPulseTicker = nil
    end

    -- Reset slot colors
    slot:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    slot:SetBackdropColor(0, 0, 0, 1)

    -- Hide glow elements
    if slot.glowBg then
        slot.glowBg:SetAlpha(0)
    end
    if slot.borderGlow then
        slot.borderGlow:SetAlpha(0)
    end
    -- Hide shard pulse
    if slot.shardPulse then
        slot.shardPulse:SetAlpha(0)
    end

    -- Reset backdrop
    slot:SetBackdropColor(0.08, 0.08, 0.15, 0.95)
    slot:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
end

-- Stop all single slot animations (when new pull starts)
function Gacha:StopAllSingleAnimations()
    if self.activeSingleAnimations then
        for _, slot in ipairs(self.activeSingleAnimations) do
            self:StopSingleSlotAnimation(slot)
        end
        self.activeSingleAnimations = {}
    end
end

-- Create pulsing animation for S/SS tier that awards shard
function Gacha:CreateShardPulseAnimation(slot, tier)
    -- Create glow frame if not exists
    if not slot.shardGlow then
        slot.shardGlow = CreateFrame("Frame", nil, slot)
        slot.shardGlow:SetAllPoints(slot)
        slot.shardGlow:SetFrameLevel(slot:GetFrameLevel() + 1)

        -- Create a soft pulsing glow
        slot.shardPulse = slot.shardGlow:CreateTexture(nil, "BACKGROUND")
        slot.shardPulse:SetPoint("CENTER", slot, "CENTER", 0, 0)
        slot.shardPulse:SetSize(130 * 1.2, 160 * 1.2)
        slot.shardPulse:SetTexture("Interface\\Cooldown\\star4")
        slot.shardPulse:SetBlendMode("ADD")
    end

    -- Set color based on tier
    local r, g, b = 1, 0.84, 0  -- Gold for S
    if tier == "SS" then
        r, g, b = 1, 0.5, 0.2  -- Legendary orange for SS
    end

    slot.shardPulse:SetVertexColor(r, g, b, 0.3)

    -- Create gentle pulsing effect
    local pulseAlpha = 0.3
    local pulseDirection = 1
    local pulseSpeed = 0.02  -- Slightly faster for more noticeable pulse

    -- Store the ticker so we can stop it later
    if slot.shardPulseTicker then
        slot.shardPulseTicker:Cancel()
    end

    slot.shardPulseTicker = C_Timer.NewTicker(0.03, function()
        pulseAlpha = pulseAlpha + (pulseDirection * pulseSpeed)

        if pulseAlpha >= 0.7 then  -- Brighter max
            pulseAlpha = 0.7
            pulseDirection = -1
        elseif pulseAlpha <= 0.15 then  -- Dimmer min for more contrast
            pulseAlpha = 0.15
            pulseDirection = 1
        end

        if slot.shardPulse then
            slot.shardPulse:SetAlpha(pulseAlpha)
        end
    end)

    -- Add to active animations list for cleanup
    if not self.activeSingleAnimations then
        self.activeSingleAnimations = {}
    end
    table.insert(self.activeSingleAnimations, slot)

    -- Stop after 7 seconds (longer duration for better visibility)
    C_Timer.After(7, function()
        if slot.shardPulseTicker then
            slot.shardPulseTicker:Cancel()
            slot.shardPulseTicker = nil
        end
        if slot.shardPulse then
            slot.shardPulse:SetAlpha(0)
        end
    end)
end

-- Create epic animation for single slot (3-pull)
function Gacha:CreateSingleSlotEpicAnimation(slot, tier)
    -- Create glow frame if not exists
    if not slot.glowFrame then
        slot.glowFrame = CreateFrame("Frame", nil, slot)
        slot.glowFrame:SetAllPoints(slot)
        slot.glowFrame:SetFrameLevel(slot:GetFrameLevel() + 1)

        -- Background glow texture
        slot.glowBg = slot.glowFrame:CreateTexture(nil, "BACKGROUND")
        slot.glowBg:SetPoint("CENTER", slot, "CENTER", 0, 0)
        slot.glowBg:SetSize(130 * 1.5, 160 * 1.5)  -- Adjusted for single slot size
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
        r, g, b = 1, 0.5, 0.2  -- Legendary orange-red for SS
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

    -- Store in active animations for cleanup
    if not self.activeSingleAnimations then
        self.activeSingleAnimations = {}
    end

    -- Animation variables
    local elapsed = 0
    local pulseSpeed = 0.5
    local rotateSpeed = 2
    local fadeInTime = 0.3

    -- Start the animation (INFINITE until window closes)
    if slot.animTicker then
        slot.animTicker:Cancel()
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
    end)

    -- Add to active animations list
    table.insert(self.activeSingleAnimations, slot)
    slot.lastTier = tier
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

    -- Load saved B-Tier pity count
    if CattosShuffleDB and CattosShuffleDB.gachaBTierPityCount then
        self.bTierPityCount = CattosShuffleDB.gachaBTierPityCount
    else
        self.bTierPityCount = 0
    end

    -- Load saved bonus roll chance
    if CattosShuffleDB and CattosShuffleDB.gachaBonusRollChance then
        self.bonusRollChance = CattosShuffleDB.gachaBonusRollChance
    else
        self.bonusRollChance = 0
    end

    -- Don't setup x10 animation here - it will be setup when the Gacha window is opened

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

            -- Also close x10 animation frame if open
            if Gacha.x10CompactFrame and Gacha.x10CompactFrame:IsShown() then
                Gacha.wasX10VisibleBeforeCombat = true
                Gacha.x10CompactFrame:Hide()
                -- Pause animation but don't clear it
                if Gacha.x10CompactTicker then
                    Gacha.x10CompactTicker:Cancel()
                    -- Don't nil it, we'll resume later
                    Gacha.x10AnimationPaused = true
                end
                print("|cffff0000x10 Animation paused - entering combat!|r")
            else
                Gacha.wasX10VisibleBeforeCombat = false
            end

            -- Also close item list if open
            if Gacha.itemListFrame and Gacha.itemListFrame:IsShown() then
                Gacha.itemListFrame:Hide()
            end

            -- Also hide bonus roll window if open (but keep animation running)
            if Gacha.bonusRollFrame and Gacha.bonusRollFrame:IsShown() then
                Gacha.wasBonusRollVisibleBeforeCombat = true
                Gacha.bonusRollFrame:Hide()
                -- Don't cancel the animation ticker, let it continue in background
                print("|cffff0000Bonus Roll window hidden - entering combat!|r")
            else
                Gacha.wasBonusRollVisibleBeforeCombat = false
            end
        elseif event == "PLAYER_REGEN_ENABLED" then
            -- Leaving combat - handle both reopening and pending opens

            -- First check if window should reopen (was visible before combat)
            local shouldReopen = Gacha.wasVisibleBeforeCombat
            local shouldReopenX10 = Gacha.wasX10VisibleBeforeCombat
            local shouldReopenBonusRoll = Gacha.wasBonusRollVisibleBeforeCombat
            Gacha.wasVisibleBeforeCombat = false
            Gacha.wasX10VisibleBeforeCombat = false
            Gacha.wasBonusRollVisibleBeforeCombat = false

            if shouldReopen and Gacha.frame then
                Gacha.frame:Show()
                Gacha:BuildItemPool()  -- Rebuild pool after combat
                Gacha:UpdateGachaUI()
                print("|cff00ff00Combat ended - Gacha reopened!|r")
            end

            -- Reopen x10 animation if it was open
            if shouldReopenX10 and Gacha.x10CompactFrame then
                Gacha.x10CompactFrame:Show()

                -- Resume animation if it was paused
                if Gacha.x10AnimationPaused and Gacha.x10AnimationData then
                    print("|cff00ff00Combat ended - Resuming x10 Animation!|r")
                    Gacha:ResumeX10Animation()
                else
                    print("|cff00ff00Combat ended - x10 Animation reopened!|r")
                end
            end

            -- Reopen bonus roll window if it was open
            if shouldReopenBonusRoll and Gacha.bonusRollFrame then
                Gacha.bonusRollFrame:Show()
                print("|cff00ff00Combat ended - Bonus Roll window reopened!|r")
                -- Animation should still be running if it wasn't finished
                -- Check if animation completed while hidden
                if not Gacha.bonusRollTicker then
                    -- Animation completed while window was hidden
                    print("|cffffcc00Bonus Roll animation completed during combat|r")
                end
            end

            -- Then check if there's a pending open request from during combat
            if Gacha.pendingOpenAfterCombat then
                Gacha.pendingOpenAfterCombat = false
                -- Small delay to ensure combat flag is cleared
                C_Timer.After(0.1, function()
                    print("|cff00ff00Combat ended - opening Gacha as requested!|r")
                    Gacha:Toggle()
                end)
            end
        end
    end)

    print("|cffffcc00Gacha System Loaded! Pull for items!|r")
end