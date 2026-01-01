-- CattosShuffle Localization System
local addonName, CattosShuffle = ...
_G.CattosCasino = CattosShuffle  -- Keep backwards compatibility

-- Create localization table
CattosShuffle.L = {}
local L = CattosShuffle.L

-- Get client locale
local locale = GetLocale()

-- Default English strings
local strings = {
    -- Slot names
    ["HEAD"] = "Head",
    ["NECK"] = "Neck",
    ["SHOULDER"] = "Shoulder",
    ["BACK"] = "Back",
    ["CHEST"] = "Chest",
    ["SHIRT"] = "Shirt",
    ["TABARD"] = "Tabard",
    ["WRIST"] = "Wrists",
    ["HANDS"] = "Hands",
    ["WAIST"] = "Waist",
    ["LEGS"] = "Legs",
    ["FEET"] = "Feet",
    ["RING1"] = "Ring 1",
    ["RING2"] = "Ring 2",
    ["TRINKET1"] = "Trinket 1",
    ["TRINKET2"] = "Trinket 2",
    ["MAINHAND"] = "Main Hand",
    ["OFFHAND"] = "Off Hand",
    ["RANGED"] = "Ranged",

    -- Bag names
    ["BACKPACK"] = "Backpack",
    ["BAG1"] = "Bag 1",
    ["BAG2"] = "Bag 2",
    ["BAG3"] = "Bag 3",
    ["BAG4"] = "Bag 4",

    -- Actions
    ["ACTION_BAG_EMPTY"] = "Empty random bag",
    ["ACTION_SHEET_RNG"] = "Delete random item",
    ["ACTION_BAG_DELETE"] = "Delete bag + contents",
    ["ACTION_CHOICE"] = "Free choice (no RNG)",

    -- UI Elements
    ["EQUIPMENT"] = "Equipment",
    ["BAGS"] = "Bags",
    ["EMPTY_BAG"] = "Empty Bag\n69 Gold",
    ["DELETE_ITEM"] = "Delete Item\n100 Gold",
    ["DELETE_BAG"] = "Delete Bag\n150 Gold",
    ["FREE_CHOICE"] = "Free Choice\n200 Gold",

    -- Messages
    ["ADDON_LOADED"] = "|cff00ff00CattosShuffle|r loaded! Use |cffffcc00/cattos|r or |cffffcc00/cc|r for help.",
    ["SPIN_ALREADY_RUNNING"] = "|cffff0000Spin already running!|r",
    ["COMBAT_ERROR"] = "|cffff0000You cannot shuffle during combat!|r",
    ["NO_EQUIPMENT_SLOTS"] = "|cffff0000No equipment slots with items found!|r",
    ["NO_BAGS_WITH_ITEMS"] = "|cffff0000No bags with items found!|r",
    ["NO_VALID_BAGS"] = "|cffff0000No valid bags found!|r",
    ["RESULT"] = "|cff00ff00Result:|r %s for |cffffcc00%d Gold|r - Selected: |cffff00ff%s|r",
    ["CHOICE_MODE_ACTIVE"] = "|cff00ff00Free choice mode activated!|r Click on a slot.",
    ["SPIN_CANCELLED"] = "|cffff0000Spin cancelled!|r",
    ["WINDOW_CLOSED_COMBAT"] = "|cffff0000CattosShuffle: Window auto-closed - combat started!|r",
    ["WINDOW_REOPENED"] = "|cff00ff00CattosShuffle: Combat ended - window reopened!|r",
    ["UNKNOWN"] = "Unknown",
    ["BAG_WAS_EMPTY"] = "Bag was empty",
    ["BAG_EMPTIED"] = "|cffffcc00BAG EMPTIED!|r",
    ["TOTAL_ITEMS_LOST"] = "|cffffcc00Total: %d items lost!|r",
    ["ITEM_LOST"] = "|cffffcc00ITEM LOST!|r",
    ["LOST_STATS"] = "Lost Stats:",
    ["NO_STATS"] = "This item had no stats",
    ["ARMOR"] = "Armor",
    ["DAMAGE"] = "Damage",

    -- Options Panel
    ["OPTIONS_TITLE"] = "CattosShuffle Settings",
    ["CREATED_BY"] = "Created by Catto",
    ["SUPPORT_DEVELOPMENT"] = "Support development:",
    ["SOUND_THEME"] = "Sound Theme",
    ["SOUND_THEME_DESC"] = "Choose the sound theme for shuffle actions:",
    ["SOUND_THEME_TRUTE"] = "Trute (Custom Sounds)",
    ["SOUND_THEME_DEFAULT"] = "WoW Default Sounds",
    ["SOUND_ENABLED"] = "Sounds enabled",
    ["AUTO_MODE"] = "Auto mode enabled",
    ["COMMANDS"] = "Commands:",
    ["CMD_OPEN"] = "|cffffcc00/cattos|r or |cffffcc00/cc|r - Open UI",
    ["CMD_BAGS"] = "|cffffcc00/cattos bags|r - Bags spin (69 Gold)",
    ["CMD_SHEET"] = "|cffffcc00/cattos sheet|r - Equipment spin (100 Gold)",
    ["CMD_DELETE"] = "|cffffcc00/cattos delete|r - Delete bag (150 Gold)",
    ["CMD_CHOICE"] = "|cffffcc00/cattos choice|r - Free choice (200 Gold)",

    -- Sound messages
    ["SOUND_THEME_CHANGED"] = "|cff00ff00CattosShuffle:|r Sound theme changed to: |cffffcc00%s|r",
    ["AVAILABLE_THEMES"] = "|cff00ff00CattosShuffle:|r Available themes: |cffffcc00%s|r",
    ["CURRENT_THEME"] = "|cff00ff00CattosShuffle:|r Current theme: |cffffcc00%s|r",
    ["USE_SOUND_COMMAND"] = "  Use |cffffcc00/cattos sound [theme]|r to change",
    ["THEMES_LIST"] = "  Themes: %s",

    -- Help
    ["HELP_COMMANDS"] = "|cff00ff00CattosShuffle|r Commands:",
    ["HELP_STOP"] = "|cffffcc00/cattos stop|r - Stop current spin",
    ["HELP_SOUND"] = "|cffffcc00/cattos sound [theme]|r - Change sound theme",

    -- Debug
    ["DEBUG_SLOTS"] = "|cff888888[Debug] Slots: %d | Selected: Index %d (Slot %d)|r",
    ["ERROR_BAG_INDEX"] = "|cffff0000Error: No bag selected!|r",
    ["ERROR_BAG_EMPTY"] = "|cffff0000Error: Bag %d is empty or doesn't exist!|r",

    -- Backpack protection
    ["BACKPACK_MUST_EMPTY"] = "Must be emptied!",
    ["SECOND_SPIN_FOR_DELETE"] = "Selecting bag to delete...",
    ["NO_OTHER_BAGS"] = "No other bags equipped to delete!",
    ["BAG_WILL_BE_DELETED"] = "Will be deleted!",
}

-- German localization
if locale == "deDE" then
    strings["HEAD"] = "Kopf"
    strings["NECK"] = "Hals"
    strings["SHOULDER"] = "Schulter"
    strings["BACK"] = "Rücken"
    strings["CHEST"] = "Brust"
    strings["SHIRT"] = "Hemd"
    strings["TABARD"] = "Wappenrock"
    strings["WRIST"] = "Handgelenke"
    strings["HANDS"] = "Hände"
    strings["WAIST"] = "Taille"
    strings["LEGS"] = "Beine"
    strings["FEET"] = "Füße"
    strings["RING1"] = "Ring 1"
    strings["RING2"] = "Ring 2"
    strings["TRINKET1"] = "Schmuckstück 1"
    strings["TRINKET2"] = "Schmuckstück 2"
    strings["MAINHAND"] = "Waffenhand"
    strings["OFFHAND"] = "Schildhand"
    strings["RANGED"] = "Distanz"

    strings["BACKPACK"] = "Rucksack"
    strings["BAG1"] = "Tasche 1"
    strings["BAG2"] = "Tasche 2"
    strings["BAG3"] = "Tasche 3"
    strings["BAG4"] = "Tasche 4"

    strings["ACTION_BAG_EMPTY"] = "Zufällige Tasche leeren"
    strings["ACTION_SHEET_RNG"] = "Zufälliges Item löschen"
    strings["ACTION_BAG_DELETE"] = "Tasche + Inhalt löschen"
    strings["ACTION_CHOICE"] = "Freie Auswahl (kein RNG)"

    strings["EQUIPMENT"] = "Ausrüstung"
    strings["BAGS"] = "Taschen"
    strings["EMPTY_BAG"] = "Tasche leeren\n69 Gold"
    strings["DELETE_ITEM"] = "Item löschen\n100 Gold"
    strings["DELETE_BAG"] = "Tasche löschen\n150 Gold"
    strings["FREE_CHOICE"] = "Freie Wahl\n200 Gold"

    strings["ADDON_LOADED"] = "|cff00ff00CattosShuffle|r geladen! Nutze |cffffcc00/cattos|r oder |cffffcc00/cc|r für Hilfe."
    strings["SPIN_ALREADY_RUNNING"] = "|cffff0000Spin läuft bereits!|r"
    strings["COMBAT_ERROR"] = "|cffff0000Du kannst nicht während des Kampfes mischen!|r"
    strings["NO_EQUIPMENT_SLOTS"] = "|cffff0000Keine Ausrüstungsplätze mit Items gefunden!|r"
    strings["NO_BAGS_WITH_ITEMS"] = "|cffff0000Keine Taschen mit Items gefunden!|r"
    strings["NO_VALID_BAGS"] = "|cffff0000Keine gültigen Taschen gefunden!|r"
    strings["RESULT"] = "|cff00ff00Ergebnis:|r %s für |cffffcc00%d Gold|r - Gewählt: |cffff00ff%s|r"
    strings["CHOICE_MODE_ACTIVE"] = "|cff00ff00Freie Auswahl Modus aktiviert!|r Klicke auf einen Slot."
    strings["SPIN_CANCELLED"] = "|cffff0000Spin abgebrochen!|r"
    strings["WINDOW_CLOSED_COMBAT"] = "|cffff0000CattosShuffle: Fenster automatisch geschlossen - Kampf begonnen!|r"
    strings["WINDOW_REOPENED"] = "|cff00ff00CattosShuffle: Kampf beendet - Fenster wieder geöffnet!|r"
    strings["UNKNOWN"] = "Unbekannt"
    strings["BAG_WAS_EMPTY"] = "Tasche war leer"
    strings["BAG_EMPTIED"] = "|cffffcc00TASCHE GELEERT!|r"
    strings["TOTAL_ITEMS_LOST"] = "|cffffcc00Gesamt: %d Items verloren!|r"
    strings["ITEM_LOST"] = "|cffffcc00ITEM VERLOREN!|r"
    strings["LOST_STATS"] = "Verlorene Stats:"
    strings["NO_STATS"] = "Dieses Item hatte keine Stats"
    strings["ARMOR"] = "Rüstung"
    strings["DAMAGE"] = "Schaden"

    strings["OPTIONS_TITLE"] = "CattosShuffle Einstellungen"
    strings["CREATED_BY"] = "Erstellt von Catto"
    strings["SUPPORT_DEVELOPMENT"] = "Unterstütze die Entwicklung:"
    strings["SOUND_THEME"] = "Sound Theme"
    strings["SOUND_THEME_DESC"] = "Wähle das Sound-Theme für Shuffle-Aktionen:"
    strings["SOUND_ENABLED"] = "Sounds aktiviert"
    strings["AUTO_MODE"] = "Auto-Modus aktiviert"
    strings["COMMANDS"] = "Befehle:"
    strings["CMD_OPEN"] = "|cffffcc00/cattos|r oder |cffffcc00/cc|r - UI öffnen"
    strings["CMD_BAGS"] = "|cffffcc00/cattos bags|r - Taschen-Spin (69 Gold)"
    strings["CMD_SHEET"] = "|cffffcc00/cattos sheet|r - Ausrüstung-Spin (100 Gold)"
    strings["CMD_DELETE"] = "|cffffcc00/cattos delete|r - Tasche löschen (150 Gold)"
    strings["CMD_CHOICE"] = "|cffffcc00/cattos choice|r - Freie Wahl (200 Gold)"

    strings["SOUND_THEME_CHANGED"] = "|cff00ff00CattosShuffle:|r Sound-Theme geändert zu: |cffffcc00%s|r"
    strings["AVAILABLE_THEMES"] = "|cff00ff00CattosShuffle:|r Verfügbare Themes: |cffffcc00%s|r"
    strings["CURRENT_THEME"] = "|cff00ff00CattosShuffle:|r Aktuelles Theme: |cffffcc00%s|r"
    strings["USE_SOUND_COMMAND"] = "  Nutze |cffffcc00/cattos sound [theme]|r zum Wechseln"
    strings["THEMES_LIST"] = "  Themes: %s"

    strings["HELP_COMMANDS"] = "|cff00ff00CattosShuffle|r Befehle:"
    strings["HELP_STOP"] = "|cffffcc00/cattos stop|r - Laufenden Spin stoppen"
    strings["HELP_SOUND"] = "|cffffcc00/cattos sound [theme]|r - Sound-Theme wechseln"

    strings["DEBUG_SLOTS"] = "|cff888888[Debug] Slots: %d | Gewählt: Index %d (Slot %d)|r"
    strings["ERROR_BAG_INDEX"] = "|cffff0000Fehler: Keine Tasche ausgewählt!|r"
    strings["ERROR_BAG_EMPTY"] = "|cffff0000Fehler: Tasche %d ist leer oder existiert nicht!|r"

    strings["BACKPACK_MUST_EMPTY"] = "Muss geleert werden!"
    strings["SECOND_SPIN_FOR_DELETE"] = "Wähle Tasche zum Löschen..."
    strings["NO_OTHER_BAGS"] = "Keine anderen Taschen zum Löschen ausgerüstet!"
    strings["BAG_WILL_BE_DELETED"] = "Wird gelöscht!"
end

-- Create metatable for easy access
setmetatable(L, {
    __index = function(t, k)
        return strings[k] or k
    end
})