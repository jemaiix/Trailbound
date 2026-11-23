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

## 1.8.72
- A round minimap is no longer touched unless it was made square first.
- The client's own reagent bag window is closed on Shift+B; only the addon's reagent drawer is used.
- Rogue poison reminder (click to apply from your bags).
- Automatic repair at vendors (Bags, banks & vendors): own gold, optionally guild funds; Shift skips it.
- Hunter ammo reminder when fewer than 200 arrows or bullets are left.
- Item tooltips also count items waiting in each character's mailbox (saved when the mailbox is opened).
- Adds a sort button to the combined bag on characters where the client's cleanup button is missing.

## 1.8.76
- Vendors: shift-click an item and choose any quantity; it is bought as several stacks.
- Mail: Ctrl+right-click an item in your bags with the Send tab open attaches every stack of it.
- Junk manager shows the combined value of everything listed; level times hide at level 60.
- Auction house: Search mats also searches the crafted item. Train all shows the total cost on hover.
- Camp item tooltips show the buff they give. Lockbox tooltips no longer repeat the skill requirement.

## 1.8.77
- Fix: bags could refuse to open in combat. The addon no longer calls the client's own bag anchoring code (which can taint it); the reagent drawer lift and bag reset now move the bag's own anchor instead.
- The fallback sort button now sits next to the bag's search bar.
- Fallback sort button: fixed spot inside the frame, right of the search bar.

## 1.8.80
- Sleeping bag reminder stops at level 60.
- Gossip auto-select ignores guards and information NPCs (only vendors, banks and trainers with few options).
- Fallback sort button: no tooltip, created at login and shown as soon as the bag opens.

## 1.8.81
- Hunter ammo reminder: ammo type read from the weapon class and type name (guns use bullets), with a fallback to the equipped ammo. `/tb ammo` shows what it detects.
- Bank window gets the same fallback sort button when the client's cleanup button is missing.

## 1.8.83
- Other characters' bags, banks and tooltips show first and second name; realms show as PvP / PvE / RP / RP-PvP.
- Junk manager: delete works in combat; selling sends items in batches (much faster).
- Level times window handles Shift/drag in combat; sort buttons are rechecked when combat ends.

## 1.8.84
- Fix: shift-click vendor quantity prompt errored on clients without GetMerchantItemInfo (now uses C_MerchantFrame.GetItemInfo).

## 1.8.85
- Banker auto-open restored: bankers are matched by option text; the old icon match was actually the flight master icon (it also caused guard/flight master auto-picks).

## 1.8.86
- Square minimap: the stray round blob-ring circle is switched off while the map is square (restored when it is not).

## 1.8.87
- Flight masters auto-open the flight map again (own option, `/tb taxi`).
- The reagent drawer is sized to the equipped reagent bag.

## 1.8.88
- Innkeepers no longer auto-open their vendor window (other vendors still do).
- Settings now explain that holding Shift while talking to an NPC overrides the auto-open options.

## 1.8.89
- Space-bar fishing (Fishing page in settings, `/tb fish`): with a fishing pole equipped, Space applies a lure from the bags if needed, casts, and reels in; other weapons leave Space alone.

## 1.8.90
- Fishing: louder sound mix while a fishing pole is equipped (restored afterwards).
- Options search finds individual settings and notes with synonyms and typo tolerance, shows results, and highlights the setting it jumps to.

## 1.8.92
- Fix: gathering scanner no longer runs in instances/battlegrounds and can no longer error every tick (protected speed value, restricted nameplate tables).
- Profession recipe list shows only the better of vendor profit or AH net per recipe (tagged V or AH).

## 1.8.92
- Arenas and battlegrounds: Tab targets enemy players only (zone-based, normal Tab in PvE). `/tb pvptab` toggles.
- Optional automatic spirit release in battlegrounds (`/tb release`; Shift skips; never with a Soulstone).
- Character window: item levels on equipped items, average item level, enchants shown / "No enchant" flagged at max level.
- Druid: Thorns reminder is hidden while a warlock's Fire Shield is on you.

## 1.8.93
- Battlegrounds/arenas: the node scanner's nameplate events and sparkles do nothing inside instances; the reminder ticker and gameplay ticker pause for 30s after repeated errors instead of spamming.

## 1.8.94
- Battlegrounds/arenas: the minimap compaction, square-map and blob-ring code no longer touches Blizzard's minimap layout inside PvP instances (suspected source of the tainted "iterate a table" error loop).

## 1.8.95
- Battlegrounds/arenas: chat message hooks and the sender filter are removed inside PvP instances (fixes "string conversion on a secret string"); restored on leaving.
- Options window: navigation no longer overlaps (heading and entries re-spaced, taller window), window is drawn above other panels.
- Character names: first + second name detected from more sources; `/tb names` prints what the client reports. Alts need one login to save their full name.
- Reagent drawer is built when bags open in combat; only the bag lift waits for combat to end.

## 1.8.96
- Settings that need a UI reload (square minimap, minimap spacing/mail icon, minimap addon icons, stance bar, draggable bags) now pop up a "Reload UI" prompt when changed.

## 1.8.97
- Buff reminders read "does not stack with ..." from the buffs already on you (camp buffs such as Enchanted Lute vs Mark of the Wild, Mana Well vs Blessing of Wisdom, Fish Bowl vs Blessing of Kings, Fire Shield vs Thorns) and stop nagging for the covered buff; Paladin blessing suggestions respect them too.
- Character window: neck enchants are checked; the average item level now sits on its own frame above the 3D model so it is visible.

## 1.8.98
- Character window: average item level moved next to "Level 60 Priest" in a frame above everything else; weapon-slot enchant text sits under the weapon slots instead of overlapping. `/tb ilvl` prints diagnostics.

## 1.8.99
- Rogue poison reminder: right-click it (or `/tb poisons`) to list every poison in your bags and apply any to main hand or off hand.
- Saved-character labels now read "Name (60 Priest) - Server" with class colour; server name read from more sources (`/tb names` prints them).
- Profession windows: new "All crafts" button opens a list of every craft sorted by profit (vendor and AH net), priced from TSM market values when TSM is loaded.

## 1.9.0
- Saved bank view: free slots are shown (this tab and whole bank, plus a count on each tab button), every slot is drawn as a bordered slot with quality-coloured borders, and the grid sits in an inset panel like the real bank.

## 1.9.1
- Saved bank view: header shows only whole-bank free slots; free slots now show a visible empty-slot icon on a lighter slot.

## 1.9.2
- Saved bank view: new "All tabs" view (default) shows every bank tab in one grid; individual tabs still available.

## 1.9.3
- Battlegrounds: the buff tracker looped over aura-change event payloads that the client marks as inaccessible to tainted code (every aura update in a battleground raised "attempted to iterate a table that cannot be accessed while tainted"). All such loops now use a proper accessibility check (canaccesstable) and are protected.

## 1.9.4
- Reverted the battleground workarounds that did not help: the square minimap, minimap layout and chat hooks work normally inside battlegrounds/arenas again.

## 1.9.10

- Removed the "Hide stance / shapeshift bar" option. Hiding that Blizzard frame caused a flood of Lua errors in battlegrounds. If you had it on, the bar returns to normal after the reload.
- Reverted the 1.9.6-1.9.9 battleground workarounds (they did not address the cause).

## 1.9.5
- Buff reminders now update in combat: a reminder fades as soon as you cast its spell (or the buff shows up), instead of waiting until combat ends. The full re-layout still happens out of combat.
