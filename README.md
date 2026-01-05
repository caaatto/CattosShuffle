# CattosShuffle

A high-stakes RNG addon for World of Warcraft Classic Era (1.15.3) that adds excitement and risk to your hardcore adventures through various gambling mechanics.

## WARNING
This addon will **PERMANENTLY DELETE** items from your inventory! There is **NO UNDO**! Use at your own risk!

## Features

### Main Shuffle System
- **Equipment Roulette**: Risk your equipped items with various animation styles
- **Bag Roulette**: Empty random bags or delete them entirely
- **Free Choice Mode**: Select specific items to gamble
- **Multiple Animation Styles**: Normal, reverse, fakeout, yoyo, kitt, and more
- **Sound Themes**: Custom casino-style sound effects (Trute theme)

### Gacha System (NEW!)
A three-reel slot machine where matching all three tiers forces item deletion:

#### Tier System
- **SS Tier** (Ultra Rare): Epic/Legendary equipped items
- **S Tier** (Super Rare): Currently equipped items
- **A Tier** (Rare): Equipment in bags
- **B Tier** (Uncommon): Quest items & consumables
- **C Tier** (Common): Junk & miscellaneous items

#### Triple Pity Systems
1. **Shard System**: Earn shards on S/SS rolls without matches (3 shards = switch to Shuffle)
2. **B-Tier Pity**: Guaranteed B-Tier triple every 10 rolls
3. **50-Spin Pity**: Guaranteed S or A tier triple after 50 spins

### Russian Roulette Slots
- Three-slot machine matching item qualities (Poor, Common, Uncommon, Rare, Epic, Legendary)
- Match three qualities = delete one random item of that quality
- Visual spinning animation with dramatic reveals

## Commands

### Basic Commands
- `/cattos` or `/cc` - Open main UI
- `/cattos bags` - Spin for bag items
- `/cattos sheet` - Spin for equipped items
- `/cattos delete` - Delete entire bag
- `/cattos choice` - Free choice mode
- `/cattos stop` - Stop current spin

### Gacha Commands
- `/ccg` - Open Gacha system directly
- `/cattos gacha` - Alternative Gacha command

### Russian Roulette
- `/cattos roulette` or `/cattos rr` - Open Russian Roulette slots

### Settings
- `/cattos sound [theme]` - Change sound theme (trute/default)
- Access full settings via: ESC → Interface → AddOns → CattosShuffle

## Localization
Fully localized in:
- **English** (default)
- **German** (deDE)

The addon automatically detects your game client language.

## Installation

### Method 1: Direct Download
1. Download the latest release from [GitHub Releases](https://github.com/caaatto/CattosShuffle/releases)
2. Extract the ZIP file
3. **IMPORTANT**: Rename the folder from `CattosShuffle-main` or `CattosShuffle-2.1.0` to just `CattosShuffle`
4. Move the `CattosShuffle` folder to: `World of Warcraft\_classic_era_\Interface\AddOns\`
5. Final path should be: `..\AddOns\CattosShuffle\CattosShuffle.toc`
6. Restart WoW or type `/reload`

### Method 2: Git Clone
```bash
cd "World of Warcraft\_classic_era_\Interface\AddOns"
git clone https://github.com/caaatto/CattosShuffle.git
```

## Usage

### Gacha System
1. Open with `/ccg` or through main menu
2. Click **[ PULL x3 ]** to spin
3. Watch the reels spin and stop
4. If all 3 match: Follow deletion instructions
5. Check your pity counters for guaranteed matches

### Russian Roulette
1. Open with `/cattos roulette`
2. Click **SPIN** to start
3. Three slots spin showing item qualities
4. Matching three = one item of that quality deleted
5. No items of matched quality = Lucky escape!

### Tips
- Use **Items** button in Gacha to preview your item pool
- Check pity counters - B-Tier every 10, main pity at 50
- Items with fewer pieces have lower chances
- ESC key closes all addon windows
- Windows auto-close during combat

## Settings
Access through **Interface → AddOns → CattosShuffle**:
- Sound theme selection
- Auto-mode toggle
- Minimap button visibility
- Gacha pity counter reset
- Quick access buttons

## Support & Feedback

### Bug Reports
Please report issues at: [GitHub Issues](https://github.com/caaatto/CattosShuffle/issues)

### Support Development
If you enjoy the addon, consider supporting:
- Ko-fi: [ko-fi.com/kay_catto](https://ko-fi.com/kay_catto)
- Access link through addon settings

## Requirements
- World of Warcraft Classic Era (1.15.3)
- No additional libraries required

## Safety Features
- Cannot be used in combat
- Manual deletion confirmation required
- Visual indicators for items to delete
- ESC key panic close
- Protected items cannot be auto-deleted

## License
This addon is provided as-is for entertainment purposes. Use at your own risk. The author is not responsible for any lost items or progress.

## Version History

### v2.1.0 (Current)
- x10 pull system with instant results display
- Improved pity system (B-tier every 10, main at 50)
- Fixed equipped items tier detection
- Multi-language support for item types
- Balanced S/SS tier rates (75 pulls for 3 shards)
- Better UI layout and tooltips
- Bug fixes and performance improvements

### v2.0.0
- Added complete Gacha system with tier mechanics
- Implemented Russian Roulette slot machine
- Triple pity system for fair gameplay
- Full German localization
- Improved UI with better z-index handling
- Ko-fi support dialog
- Settings panel integration
- Manual deletion system with visual feedback
- New `/ccg` command for direct Gacha access

### v1.0.0
- Initial release
- Basic shuffle mechanics
- Equipment and bag roulette
- Sound theme support
- Minimap button

---

**Remember**: This addon is designed for hardcore/challenge runs where permanent loss adds excitement. Always think twice before pulling!

*Created by Catto for the hardcore WoW Classic Era community*