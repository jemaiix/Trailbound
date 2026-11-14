# Trailbound

**Quality-of-life tools for World of Warcraft: Forever. Made by Jemai.**

Trailbound brings everyday helpers into one addon: manage junk, check your alts' gold and inventory, plan training and crafts, track your progress, and arrange the displays you use. A shared brown-and-gold interface keeps the options and addon windows consistent.

Open **`/tb`** or **`/trailbound`** to choose the features you want. The settings are grouped by what you are doing, with a search field to help you find individual options.

## Features

### Bags, vendors and characters

- Account gold totals and saved views of your characters' bags and banks.
- Junk lists, vendor selling and manual removal of items from the junk list.
- Bag movement from the header and a reagent drawer flush under the combined backpack. Both can be switched off under **Bags, banks & vendors**.
- Remembered full-name mail recipients.

### Quests, training and professions

- Configurable quest acceptance, turn-in and vendor helpers.
- Class spell and profession recipe catalogues, including level or skill requirements and trainer costs when recorded.
- Compact crafting profit estimates inside supported profession windows: material costs, vendor returns and estimated auction proceeds after fees.
- Material searches with the quantities needed for a craft.
- Gathering reminders, minimap node icons and additional highlights where the client exposes the required information.

### Combat and recovery

- Customizable weapon and wand swing timers with smooth progress.
- Mana recovery and food/drink timers, with an on-screen reminder when Well Fed has under two minutes left.
- Buff and class reminders, plus timed notices for supported important buffs received from other players.
- Configurable action rings with character-specific bindings and macros you can place on action bars.

### Experience, travel and interface

- A compact experience display with rested XP and completed-quest XP estimates.
- A movable level-times window showing recorded milestones in total `/played` time.
- Flight-path timing that learns routes as you fly them.
- Edit mode for arranging Trailbound displays, plus movement for supported game windows.
- Chat appearance options, shorter channel labels, class/race icons and copyable URLs.
- Saved addon profiles, minimap options and other interface conveniences.

## Installation

Trailbound targets **WoW: Forever**, interface **16001**. Compatibility with other WoW editions is not established.

1. Download a Trailbound release ZIP and extract it.
2. Place the `Trailbound` folder inside your game's `Interface/AddOns` directory.
3. Confirm the layout is `Interface/AddOns/Trailbound/Trailbound.toc` rather than an extra nested folder.
4. Restart the game if this is a new installation, enable Trailbound in the addon list, and open `/tb`.

For an existing installation, replace the addon files and use `/rl` or `/reload`.

**Upgrading from ForeverAssist:** keep the small, metadata-only `ForeverAssist` folder enabled while migrating old characters. It imports their existing saved data; it does not run the old addon. Log into each old character and log out normally before removing that migration folder. Do not run the old full ForeverAssist addon alongside Trailbound.

## Useful commands

| Command | Opens or performs |
| --- | --- |
| `/tb` or `/trailbound` | Main options |
| `/tb edit` | Toggle display edit mode |
| `/tb rings` | Action ring editor |
| `/tb levels` | Toggle the level-times window |
| `/tb gold` | Gold report |
| `/tb bags` | Saved account inventory |
| `/tb bank` | Bank window |
| `/tb professions` | Profession catalogue |
| `/tb junk` | Junk manager |
| `/tb profiles` | Addon profiles |
| `/tb version` | Installed version information |

The `/rl` shortcut reloads the interface when that command has not already been claimed by another addon or the client.

## Prices and saved information

Auctionator and TradeSkillMaster are **optional** price sources. Trailbound can also use prices it remembers from auction-house observations and vendor reagent costs learned at merchants. Unknown prices remain unknown; profit figures are estimates, not guaranteed sale results.

Account inventory and gold displays use saved character records. Log into each character to update its information; offline bags and banks are snapshots rather than live views. Visit trainers to record prices and requirements. Level history starts with milestones Trailbound can actually observe, and flight estimates improve after completed trips.

Your settings, character records and remembered prices are saved by WoW under **`WTF`**, separately from the addon files. The release ZIP does **not** include the author's character saves or personal settings. Back up your `WTF` folder before manually changing saved data.

## Beta status and feedback

Trailbound is being developed against the Forever beta. Client updates and other addons can affect individual features.

When reporting a problem, include your Trailbound version (`/tb version`), the steps to reproduce it, any Lua error text, and a screenshot when the issue is visual. Mention other addons that modify the same window.

## 1.8.61 additions
- Lockboxes: right-click to pick in bags and trade; tooltips show the required Lockpicking skill.
- Mage scrolls: right-click an untranslated "Scroll: ..." in your bags to decipher it with Comprehend Scroll.
- Mage mana gem reminder (click to conjure) and a leveling Well Fed reminder (hidden at 60).
- Junk manager opens when bags are full while looting, with a delete-lowest-value-and-loot button.
- Warning at 3 free bag slots; five-second rule only for spells that cost mana.
- Node icons: far cheaper scanning, placed where the client reports each node.
- Chat defaults, click-through swing timer, external buff notices off by default.
- Optional Trailbound bag window (off by default, Bags settings): search, sort and the reagent bag inside one window.

## 1.8.68 additions
- Flight times: reference times for most routes, exact learned times still win; estimates on the flight map tooltips.
- Completed-quest XP in the XP tooltip is sorted highest first.
- Profession catalogue no longer opens at class trainers; level times window shows days and is click-through unless Shift or edit mode.

## 1.8.71
- Item tooltips list bag and bank counts for this character and every other character on the account.
- Auto-accept stops retrying quests the game refuses (e.g. full quest log).
