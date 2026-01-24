# CattosShuffle Changelog

## Version 2.5.0

### New Features

#### Special Items Classification
- **Light of Elune** (English/German "Licht von Elune") now classified as SS-Tier (Ultra Rare)
- Added special handling for unique ultra-rare items

#### Mount Speed Classification System
- Mounts now classified by speed instead of quality:
  - **Normal mounts (60% speed)** → A-Tier
  - **Epic mounts (100% speed)** → SS-Tier
- Improved mount detection with name pattern matching:
  - Detects "Reins of", "Zügel", "Horn of", "Bridle", "Whistle"
  - Works with both English and German client
- Epic mount keywords: "Swift", "Schnell", "Great Kodo", "Black War", "Deathcharger", raid mounts

#### Enhanced Pity Display
- Both pity systems now always visible simultaneously
- **B-Tier Pity**: Shows pulls remaining until guaranteed B-Tier triple
- **S-Tier Pity**: Shows pulls remaining until guaranteed S/A-Tier triple
- Color-coded based on proximity:
  - Red: Very close (B ≤2, S ≤5)
  - Yellow: Close (B ≤5, S ≤10)
  - Blue/Gray: Normal distance
- Bonus roll chance included when active

#### UI Improvements
- Tier display now sorted consistently: **C → B → A → S → SS** (left to right)
- Applies to both "Rates" and "Pool" displays
- Item Pool text made more compact: "Pool: X (tiers)" instead of "Item Pool: X items (tiers)"
- Smaller font for Item Pool to prevent text overflow
- All tier displays follow ascending rarity order

### Bug Fixes
- **Fixed SS-Tier rate bug**: Was incorrectly showing 1.0% instead of 0.3%
  - Removed special boost that artificially inflated SS-Tier chance with few items
  - SS-Tier now correctly stays ultra-rare at 0.3% base (or 0.09% with 1-2 items)
- Fixed mounts being incorrectly upgraded to S-Tier based on quality
- Mounts and pets now exempt from rarity-based tier upgrades

### Balance Changes
- SS-Tier baseline: 0.3% (unchanged)
- SS-Tier with 1-3 items: 0.09% (correctly applied, was 1.0%)
- Mounts no longer affected by Epic quality upgrades

---

## Version 2.4.0 (from 2.3.2)

### New Features

#### Bonus Roll System for Projectiles
- Added separate bonus roll system for arrows, bullets, and thrown weapons
- Projectiles (ammo) are now excluded from main gacha pool and handled as bonus rolls
- Accumulating chance: 5% per pull, maximum 20 pulls until guaranteed (100%)
- x10 pulls add 50% bonus chance total

#### Bonus Roll Deletion Window
- New animated window specifically for projectile/ammo deletion
- Shows amount to delete with 3-second counter animation
- Color-coded display (green/yellow/orange/red based on severity)
- Combat-aware: hides during combat, resumes after

### Bug Fixes
- Fixed duplicate items appearing in same x10 pull session
- Fixed bonus roll not triggering on animated x10 pulls
- Fixed transparency issues with bonus roll window

### Commands Added
- `/ccbonus` - Show bonus roll status and chance
- `/ccbonus scan` - Debug scan for projectiles
- `/ccbonus reset` - Reset bonus roll window
- `/ccbonus force` - Force trigger bonus roll
- `/ccbonus set <0-100>` - Set bonus chance manually

---

## Version 2.3.2

- Fix German pet detection
- Add version display in UI

## Version 2.3.0

- Add x10 pull animation with compact 10-slot display

## Version 2.2.0

- Gacha spins interrupted by combat no longer count towards pity

## Previous Versions

See git history for earlier changes.