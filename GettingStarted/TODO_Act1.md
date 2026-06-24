# Act 1 / Vertical Slice — Open Decisions

> Status snapshot, not an audit. Only lists things that need your creative/design call — anything Claude can just build once a decision is made isn't tracked here.

## Vendor content (stubs blocking "all vendors done")
- ~~**Meat Hawker**~~ — done. Sells raw/sun-dried/salt-cured/smoked coyote, lizard, and sand beetle meat; teaches all three preservation recipes.
- **Pawn Shopkeeper** (`zone_ditch`, across from the inn) — name, personality, and what he buys/sells are all still TBD.

## The Toad
~~Resolution paths~~, ~~tone/identity~~, and ~~kill-path requirement~~ — decided: it's a toad, not a frog; no name, not unique, ordinary animal only monstrous by surface standards; kill/appease converge on the same gate outcome; killing it isn't taught by anyone — the player just needs to be strong enough on their own (rough target ~level 5), via the leveling arc below. Also decided: it has a **Swallow** ability (damage over time, but it becomes more vulnerable while you're inside) using the small-interior-room building block discussed long ago but never built — this is also how the poison cult's appeasement actually works mechanically (douse yourself beforehand, or feed it to the toad once swallowed), and may double as a shortcut to an alternate Act 2 starting location. Still TBD:
- What the player actually douses themselves in / feeds the toad, exact Swallow damage numbers, and how much more vulnerable it becomes.
- Whether the alternate-starting-location shortcut applies to kill, appease, or both.
- Combat method/preparation specifics for the kill path (beyond "be ~level 5" and Swallow above).
- The scribe-symbol appeasement method's specifics (separate from the now-decided poison cult method).
- Currently nothing exists in-world yet except a flavor note/quest from the Adventurer NPC — still needs to actually be built (the encounter, the passage gate, the resolution triggers).

## Leveling arc (pre-Toad questing)
Two parallel quest chains to get a fresh character to ~level 5, using existing-but-orphaned content where possible:
- ~~**Bandit camp**~~ — built and stats settled. Two tiles north + one west of the borderlands ambush, at surface coords (8,8), with two new transitional desert tiles in between. Layout: campfire at the center, `BanditLeader` (level 4, dex 10/agi 8/con 5, Scimitar with the poisoned flag set, Brutal + Bloodletting feats) plus 2 `Bandit` and 3 `BanditArcher` sitting close around it, 4 simple `Tent` props ringed further out, and rock/ruin-block cover for stealth approach lanes and arrow cover. As part of this pass, also rebalanced bronze melee weapons (AP costs up, Shortsword/Sword damage +3, Axe to 4 AP with a new `heavy_weapon` property), added the Scimitar, and removed Brass Knuckles/Blunderbuss as anachronistic leftovers. Wooden Spear/Bronze Spear stay separate cheap/upgrade tiers, unbalanced for now.
- ~~**Mercenary Captain**~~ — built (`scripts/entities/mercenary_captain.gd`), confirmed as the design doc's "[The Mercenary Fixer]" character under a new name. Stall on the SE side of `zone_market.tscn` (counter + 2 crates). Both jobs wired up: (1) "The Bandit Leader's Head" — 30 coins for turning in `bandit_leader_head` (drops off the Bandit Leader's corpse via a new general human-corpse-loot mechanism — `Enemy.loot_item_ids` -> `Corpse` -> the "Search" action, which previously always found nothing); turning it in chains straight into (2) "Cannibals in the Undercity" — 50 coins, completion checked by confirming all 8 cannibal-camp enemies are in `dead_permanent` (no item proof for this one, just the camp being cleared). All of the actual conversational lines (greeting, both job offers, the "made it back alive" turn-in reaction) are real, user-written dialogue now; only the two "still working on it" stubs and both post-payment lines remain `[DIALOGUE TBD]` placeholders.
- **Young Hunter** (`scripts/entities/young_hunter.gd` — placeholder NPC sitting at a fire on the north riverbank, currently `is_interactable = false`, no dialogue) — survival-path quest chain: needs real dialogue/personality, then a quest sending the player to kill something specific in the desert and/or clear the undercity animal den (see below).
- **Undercity Animal Den** (`zone_undercity_west_den.tscn`, labeled "Undercity — Animal Den") — completely empty right now (walls/water only). Open question (carried over): reused enemies themed as undercity squatters/strays, or something new and undercity-specific (e.g. weak cursed-dead/spirit enemies)?
- (Already done, no action needed: the Distraught Merchant's "Lost Cargo" quest is fully implemented.)

## Post-dream dialogue (pointing the player underground)
Fire Cult Elder, Old Hunter, and the Scribe already have real "I had a dream" responses pointing the player underground toward the Toad. The Scribe's response also surfaces a new lead: an older Library in the Undercity ruins (predating the Upper City one, from "when the Undercity was just the City") — the Upper City Library is explicitly out of reach for the player. Smith (`smith.gd:80`) and Apothecary (`apothecary.gd:91`) still have literal `"[DIALOGUE TBD]"` placeholder stubs for the same hook — need real lines in each NPC's voice doing the same job.

## Trainer reactions once the player reports the toad
Smith, Scribe, Apothecary, and the Fire Cult (member/elder) each need a new dialogue branch reacting to the toad, in their established voice, once the resolution-path specifics above are filled in. (Confirmed: Old Hunter gets none, per your note.) Note: this is a separate, later conversation from the post-dream dialogue above — this one happens after the player has been turned back by the encounter.

## New NPCs wanted
- **Fisher** — docks district. Likely the source of the fishing rod (design doc leaves this TBD: vendor, fisher NPC, or craftable). Needs personality, exact location/stall, and what he sells/teaches beyond the rod itself.

## Full city layout (bigger-picture, not Act-1-blocking)
Right now the map is really just a thin corridor of built districts (Market, Market Gate, Residential + East, the Ditch chain) plus the desert/river sprawl to the west — there's no actual outline yet of the city as a whole (where the wall is, what other districts/neighborhoods exist, where it ends). Needs at least a rough outline pass. Tied to this: the city needs farmland marked somewhere outside it to make sense — west is already claimed by the riverbank/desert content built so far, so it should go **northeast or south** of the city instead. Both are still totally open — no decision made yet on which, or what's actually out there.

## Weapon stat requirements & sword scaling (combat design idea, not Act-1-blocking)
Two related ideas to revisit later: (1) give weapons actual strength/dexterity requirements rather than just a governing-stat bonus, so picking a weapon is a real character-build choice; (2) make swords specifically scale off **both** strength and dexterity (rather than "best of the two," which is how `governing` currently works for every dual-stat weapon) so there's an actual reason to invest in both stats on one character. The goal is to push back on the default tendency for players to just pick swords/the most "normal" weapon regardless of build, and make off-sword choices (axes, spears, bows, etc.) feel like real, distinct builds rather than sidegrades. No numbers or mechanics decided yet.
