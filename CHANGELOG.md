# CattosShuffle Changelog

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