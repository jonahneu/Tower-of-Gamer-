# Act 1 / Vertical Slice — Open Decisions

> Status snapshot, not an audit. Only lists things that need your creative/design call — anything Claude can just build once a decision is made isn't tracked here.

## Vendor content (stubs blocking "all vendors done")
- ~~**Meat Hawker**~~ — done. Sells raw/sun-dried/salt-cured/smoked coyote, lizard, and sand beetle meat; teaches all three preservation recipes.
- **Pawn Shopkeeper** (`zone_ditch`, across from the inn) — name, personality, and what he buys/sells are all still TBD.

## The Toad
~~Resolution paths~~, ~~tone/identity~~, and ~~kill-path requirement~~ — decided: it's a toad, not a frog; no name, not unique, ordinary animal only monstrous by surface standards; kill/appease converge on the same gate outcome; killing it isn't taught by anyone — the player just needs to be strong enough on their own (rough target ~level 5), via the leveling arc below. Still TBD:
- Combat method/preparation specifics for the kill path (beyond "be ~level 5").
- Apothecary brew ingredients and the scribe-symbol method's specifics.
- Currently nothing exists in-world yet except a flavor note/quest from the Adventurer NPC — still needs to actually be built (the encounter, the passage gate, the resolution triggers).

## Leveling arc (pre-Toad questing)
Two parallel quest chains to get a fresh character to ~level 5, using existing-but-orphaned content where possible:
- ~~**Bandit camp**~~ — built and stats settled. Two tiles north + one west of the borderlands ambush, at surface coords (8,8), with two new transitional desert tiles in between. Layout: campfire at the center, `BanditLeader` (level 4, dex 10/agi 8/con 5, Scimitar with the poisoned flag set, Brutal + Bloodletting feats) plus 2 `Bandit` and 3 `BanditArcher` sitting close around it, 4 simple `Tent` props ringed further out, and rock/ruin-block cover for stealth approach lanes and arrow cover. As part of this pass, also rebalanced bronze melee weapons (AP costs up, Shortsword/Sword damage +3, Axe to 4 AP with a new `heavy_weapon` property), added the Scimitar, and removed Brass Knuckles/Blunderbuss as anachronistic leftovers. Wooden Spear/Bronze Spear stay separate cheap/upgrade tiers, unbalanced for now.
- **Mercenary Captain** (new NPC, not yet created) — combat-path quest chain: send the player to clear the bandit camp above, then once stronger, send them to clear the cannibal camp (`zone_undercity_east_camp.tscn`, 7 enemies incl. a leader — already built, no quest attached, too hard for a level-1 character). **Note:** the design doc already has a fully-written character for exactly this role — `[The Mercenary Fixer]`, Market District — first-contact/audition/quest-giver for the mercenary path, whose very first job for the player is literally "a group of bandits has made camp on a route near the city." Need your confirmation on whether "Mercenary Captain" is meant to be this same character before any dialogue gets written.
- **Young Hunter** (`scripts/entities/young_hunter.gd` — placeholder NPC sitting at a fire on the north riverbank, currently `is_interactable = false`, no dialogue) — survival-path quest chain: needs real dialogue/personality, then a quest sending the player to kill something specific in the desert and/or clear the undercity animal den (see below).
- **Undercity Animal Den** (`zone_undercity_west_den.tscn`, labeled "Undercity — Animal Den") — completely empty right now (walls/water only). Open question (carried over): reused enemies themed as undercity squatters/strays, or something new and undercity-specific (e.g. weak cursed-dead/spirit enemies)?
- (Already done, no action needed: the Distraught Merchant's "Lost Cargo" quest is fully implemented.)

## Post-dream dialogue (pointing the player underground)
Fire Cult Elder and Old Hunter already have real "I had a dream" responses pointing the player underground toward the Toad. Smith (`smith.gd:80`), Scribe (`scribe.gd:181`), and Apothecary (`apothecary.gd:91`) still have literal `"[DIALOGUE TBD]"` placeholder stubs for the same hook — need real lines in each NPC's voice doing the same job.

## Trainer reactions once the player reports the toad
Smith, Scribe, Apothecary, and the Fire Cult (member/elder) each need a new dialogue branch reacting to the toad, in their established voice, once the resolution-path specifics above are filled in. (Confirmed: Old Hunter gets none, per your note.) Note: this is a separate, later conversation from the post-dream dialogue above — this one happens after the player has been turned back by the encounter.

## New NPCs wanted
- **Fisher** — docks district. Likely the source of the fishing rod (design doc leaves this TBD: vendor, fisher NPC, or craftable). Needs personality, exact location/stall, and what he sells/teaches beyond the rod itself.
- **Mercenary Captain** — see Leveling arc above. Needs location, personality, and what role he plays (recruiter, quest-giver, trainer?).
