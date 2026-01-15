# CattosShuffle Changelog - January 2024

## Version 2.4.0 - Bonus Roll System & Major Improvements

### New Features

#### 🎯 Bonus Roll System for Projectiles
- Added separate bonus roll system for arrows, bullets, and thrown weapons
- Projectiles are now excluded from main gacha pool
- Bonus rolls trigger with accumulating chance (5% per pull, 50% per x10)
- Maximum 20 pulls until guaranteed bonus roll (100% chance)
- Supports both English and German WoW clients

#### 🎮 Bonus Roll Window
- New animated window showing projectile deletion
- Live counter animation showing amount to delete (3 second animation)
- Color-coded display based on deletion severity:
  - Green (1-24%): Low deletion
  - Yellow (25-49%): Medium deletion
  - Orange (50-74%): High deletion
  - Red (75-100%): Critical deletion
- Fully opaque black background with red danger border
- Window appears above x10 pull windows (highest frame priority)

### Improvements

#### x10 Pull System
- Fixed duplicate items appearing in same x10 pull
- Items marked for deletion cannot appear again in same x10 session
- Properly tracks and excludes already-pulled items
- Added cleanup for temporary deletion flags after x10 completion

#### Combat Handling
- Bonus roll window now hides during combat
- Animation continues running in background during combat
- Window automatically reopens after combat ends
- Consistent with other gacha windows behavior

#### UI/UX Improvements
- Bonus roll window shows only deletion amount (no percentages)
- Removed unnecessary confirmation popups
- Added solid background textures to prevent transparency
- Better frame strata management for window layering

### Bug Fixes
- Fixed bonus roll not triggering on animated x10 pulls
- Fixed projectiles not being detected in inventory
- Fixed deleted items reappearing in later pulls of same x10
- Fixed transparency issues with bonus roll window
- Fixed bonus roll chance not incrementing properly in x10 pulls

### Commands
- `/ccbonus` - Show bonus roll status
- `/ccbonus scan` - Debug scan for projectiles
- `/ccbonus reset` - Reset bonus roll window
- `/ccbonus force` - Force trigger bonus roll
- `/ccbonus set <0-100>` - Set bonus chance manually

### Technical Changes
- Separated projectile detection into dedicated pool
- Added `isDeleted` flag system for x10 pull tracking
- Implemented proper cleanup for temporary flags
- Added debug output for bonus roll system
- Improved item type detection for multiple languages

### Balance Changes
- Bonus roll chance increased from 2% to 5% per pull
- Guaranteed bonus roll reduced from 50 to 20 pulls
- x10 pulls now add 50% bonus chance (was 20%)

---
*Note: Projectiles/ammunition are now handled as "bonus" (penalty) rolls separate from the main gacha system. Players must manually delete the indicated amount when bonus roll triggers.*