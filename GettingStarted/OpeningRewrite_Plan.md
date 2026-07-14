# Opening Hook Rewrite — Planning Doc

> Status: structural decisions made, Phase 0 (fold into `DesignDoc_BronzeAge.md`) complete as of 2026-07-13. Remaining content decisions (Phase 1) and all build work (Phase 2+) still ahead — see roadmap below. A snapshot of the pre-rewrite game state is preserved on the `pre-opening-rewrite-snapshot` branch (local + pushed to origin) in case this doesn't pan out.

## The problem with the current opening

Current opening (`DesignDoc_BronzeAge.md` §13, [The Taskmaster]): the player is a slave who is simply released — dismissed, handed nothing, told offhand that they've lost their god's protection. It's exposition delivered through condescension. It works as a *lore-delivery* mechanism (godlessness, spirits) but gives the player nothing to want. Nobody did anything to you. Nothing is at stake. The premonition dream that follows is the only hook, and it's abstract and uninterpretable by design — good as a slow-burn mystery, bad as an opening beat.

## The rewrite

Instead of being released from slavery, the player is about to be **sacrificed** — brought to the king's ritual as one of its victims. They get close enough to glimpse what the ritual actually is (or part of it), and in that moment become entangled in it rather than just adjacent to it. They escape — mechanism TBD (see open questions) — but escape marked: physically or spiritually tied to the ritual now, not merely a witness who got away clean.

This changes the throughline from "learn about a threat" to "you are already inside the threat and trying to get free of it." Early game is survival and staying hidden. As the player learns more about what the king is actually doing, the same knowledge that endangers them becomes leverage — options open up to stop the ritual or usurp it, not just avoid it.

**Why this is a small rewrite, not a big one:** the lore already supports it almost exactly as-is. §3 "The King's God" already states: *"Slaves are sacrificed at the shrine. This is accepted, known, and unremarkable. It is the cost of living in a protected city."* That's already in the doc. The rewrite doesn't invent a new fact about the world — it just moves the player from *offscreen statistic* to *the one who was on the altar.*

## What this changes downstream

**Taskmaster NPC / opening scene (§13).** The whole scene as written — dismissive release, condescending dialogue about lost protection — no longer fits. Either this character is repurposed (the priest/handler prepping the player for the shrine, someone whose job is logistics not cruelty, an accomplice who looks away) or replaced outright. The godlessness/spirit exposition it currently delivers still needs to land somewhere — probably still works, just needs a new frame (why is a sacrifice victim being told this at all? Maybe it's *why* they were chosen — an unprotected, godless slave is a "clean" or low-cost sacrifice, nobody's asset).

**Starting geography (§6, §16 zone plan).** Currently the player starts at the taskmaster's back door in the lower city, and the upper city (temple/castle/crafters districts) is sealed off by a class-based guard checkpoint for all of Act 1. Sacrificing at "the shrine, the highest point of the city" (§3) means the opening scene now has to *start* in the upper city — and the player's first playable action becomes escaping downward, through districts they're not normally allowed to see, ending up back in the Ditch where Act 1 was always designed to happen. That's a strong structural rhyme with the game's whole vertical-descent conceit (first thing you do is fall from the top of the city to the bottom of it) and it's basically free thematically.

Practically, this needs some new zone geography that doesn't exist in the plan yet: the sacrifice site itself, and an escape route connecting it down to the Ditch / lower Ditch / undercity threshold. Doesn't need to be fully fleshed-out explorable districts — see recommendation below.

Decided: the escape route does *not* reuse the existing Node 1 (Taskmaster's manor wall) — that's tied to the outer wall in the lower city, and the palace is going on the city's east side instead (see "The ritual site" below). So this is new geography end-to-end: sacrifice room → a route across/down from the east side → into the Ditch somewhere. Where exactly it joins the Ditch — near the existing Upper Ditch hub, at the Fork, or further south toward the undercity threshold — is still open (see below), since each lands the player in a different starting position relative to the Ditch's existing NPCs.

**The upper-city gate's "reason" (§6, line ~350).** Currently the gate is purely a class boundary: no money, no patron, no god, no business up there. That still holds, but now there's a second, sharper reason layered on top: the player is a fugitive from a botched sacrifice. Whether that means an active manhunt, a quiet story hushed up because the king's people don't want the ritual talked about, or something else, is an open question below — but either way it gives the gate teeth beyond "guards with spears and a class attitude."

**The premonition dream (§4).** The dream mechanism itself (godless = no household god routing spiritual signal = unfiltered premonition) still works unchanged — the player is still godless, still gets the dream on first protected sleep. What changes is that the dream is no longer the *only* piece of forbidden knowledge the player is carrying. There's now also something concretely *witnessed* — an event that happened, that other people can (skeptically) be told about, as opposed to a dream that exists in no one else's frame of reference. Worth deciding whether these two stay as separate, reinforcing signals (one uninterpretable/mystical, one concrete/deniable) or whether the witnessed event absorbs some of the dream's narrative job. Leaning toward keeping both — they do different work — but flagging it since it changes the weight the dream needs to carry.

**Starting trainers / protection paths (§3 "Paths to restoring divine protection", §13 Market Scribe/Market Smith/Fire Cult Member+Elder).** The trainers themselves stay as-is — they're still where the player goes to seek spiritual protection, still teach what they teach. What has to change is the dialogue that currently fires after the premonition dream (the "morning storyboard" beats in §13, already partly implemented per `TODO_Act1.md`'s "Post-dream dialogue" section for the Fire Cult Elder, Old Hunter, and Scribe, with Smith/Apothecary stubs still TBD). Right now those lines interpret an abstract, uninterpretable vision and vaguely point the player underground. They need to be rewritten to be *about* the curse/ritual specifically — reacting to a player who is marked and hunted, not just someone who had a strange dream. The underlying job (send the player deeper) stays the same; the content and stakes of what's being reacted to changes.

**Backgrounds (§8, slave roles).** Probably unaffected. Any background can plausibly end up chosen for sacrifice — doesn't require a rewrite of the 7 slave-role system, just means "how you got selected for the altar" sits on top of "what labor you did" rather than replacing it.

## The ritual site

Decided: a secret room deep beneath/within the palace — not the public shrine at the top (§3 describes the shrine itself as "the highest point of the city"; this room is separate, hidden, lower down within the palace structure). Small, rectangular. A slab at the center for human sacrifice. A hearth. Torches around the walls.

**Exit/route note:** Won't reuse the Taskmaster's building as the escape route's exit point — that door sits against the *outer* city wall in the lower city (§16, Node 1). The palace will sit somewhere in the **north-to-northeast** stretch of the city — exact placement not pinned down yet, just narrowed away from due-east, since that whole quadrant is still empty/unbuilt space to work with. So the escape route is new geography connecting that area down to the Ditch, rather than plugging into the existing Node 1 door as floated earlier.

**Flag for later reconciliation:** §6's current "City Cardinal Orientation" already lists **North** as the castle/nobles/temple direction and **East** as "desert edge, residential, the less interesting direction" — so a north/northeast palace placement is actually consistent with north, and only edges into new (northeast) territory if it ends up leaning that way. Worth confirming exact placement once the route itself is worked out, but this is less of a conflict with the existing doc than a due-east placement would have been.

## The interruption

Decided (2026-07-13): the sacrifice is about to happen and gets **interrupted mid-ritual**. The ritual apparatus/machine itself shudders — felt as a citywide tremor or omen — and that's what cracks open the player's chance to escape. This settles the broad shape of "how the player escapes" below: it's a malfunction/backfire in the ritual mechanism itself, not third-party sabotage, not a fellow victim's intervention, not crowd chaos. Specifics of *why* the apparatus shudders (mechanical failure vs. something reacting to it vs. an omen with no mechanical explanation at all) are still open — worth noting the apparatus reaching down toward something vast (the Godfall, per lore) is a thematically obvious well to draw from if the machine's power source ever needs an explanation, but that connection isn't decided, just flagged.

## Decisions (2026-07-13 session)

- **Scale/tone of the ritual scene: small, contained rite.** A handful of priests, no crowd, one or two rooms — not an Apocalypto-scale spectacle. The apparatus shudder (see "The interruption") is what makes the *effect* citywide-felt; the scene generating it stays small. Lower production scope: no crowd art, no procession route.
- **Where the escape route ends: the Lower Ditch, at the Apothecary.** Concretely `zone_ditch_lower.tscn`, near the existing Apothecary NPC (`scripts/entities/apothecary.gd`). **Doc/implementation drift note:** §13's Apothecary write-up currently says "market district," but she's actually already built into the Lower Ditch zone — the doc text is stale here regardless of this rewrite, worth fixing opportunistically per the design-doc-drift memory. This also means Node 5 ("Descending Path," §11, currently documented as having "no NPCs past the fork") is stale too — the Apothecary already lives past that point. The escape route's exact waypoints between the palace and this landing point are still open, but the endpoint is fixed.
- **The mark: both.** Physical (visible, something other NPCs can react to) and spiritual/mechanical (could double as another explanation for unfiltered dream signal, alongside godlessness). Specific form of each is unwritten — that's content, not a structural decision.
- **Public vs. secret aftermath: suppressed.** The people running the ritual hush it up rather than let word spread that a sacrifice escaped. Publicity is worse for them than losing one victim. The player has to actively hide who they are and what happened — early NPCs don't already know or gossip about it.
- **What the player glimpses: one legible fragment.** Not full opacity, not a full reveal — one concrete, specific detail the player catches during the interruption that doesn't explain the machine but gives them something real to chase later. The fragment's actual content is unwritten.
- **The Taskmaster: cut entirely.** The dismissive-release scene is gone. The godlessness/spirit exposition it used to carry needs a new home — see roadmap below.

## Phase 1 decisions (2026-07-13 session)

- **Palace placement:** doesn't need to be built — the ritual takes place in an **underground chamber**, northeast. No surface palace structure required for this content.
- **The mark:** a **brand** (physical) that **also curses** the player (spiritual/mechanical — a curse, not just generic "spirit exposure"). Exact curse mechanics (what it does in systems terms) still TBD — see open items below.
- **What the player learns / exposition content:** the king is performing a ritual involving human sacrifice, and the player was **not the only victim** — there were others. This is the fact the post-dream dialogue rewrite (Phase 4) needs to land, and/or the content behind the "legible fragment." Confirms the exposition-slot default (post-dream trainer dialogue) from Phase 0.
- **Escape route:** fully designed as a tutorial dungeon — see "The escape route as tutorial dungeon" below.

## Still open (small, not blocking)

- Exact curse mechanics — what the spiritual/mechanical side of the mark actually does in game-system terms (status effect? interaction with the godless/dream mechanic? something else?).
- Exact palace/chamber tile placement within the northeast quadrant.

## The escape route as tutorial dungeon (decided, 2026-07-13; enemy specifics 2026-07-13)

Confirms the tutorial-dungeon idea flagged earlier — now fully scoped. A narrow, winding corridor, four beats, ending at a smaller drainage pipe that opens into the Lower Ditch (near the Apothecary, per the existing decision). **Autosaves at the start** (i.e., at the top of the escape route, right after the interruption/mark beat).

1. **Combat tutorial.** 4× **Roach** — HP 4, dodge skill 0, melee skill 8, damage 1d2, agility 4. Any character can beat them unarmed. They drop nothing except one roach with a guaranteed single meat drop. Player can carve roaches for meat (existing cooking/food system, via `corpse.gd`'s carve flow). Aggro range left at the engine default (26) — this beat is meant to be a forced/guaranteed fight, not avoidable.
2. **Stealth tutorial.** 3× **Rat** — 2 on the main path, 1 gating the side path to the key. Combat stats (HP/dodge/melee/damage/agility) still TBD. Rocks placed for cover. A popup here teaches sneaking and explains enemy aggro ranges. **Mechanism (per codebase survey):** while the player is in sneak mode (existing `GameManager.is_sneaking` toggle), enemy detection requires line-of-sight — *large* rocks (2×2, via the existing `rock.gd`) block LOS entirely and guarantee no detection roll happens, while small rocks only give combat cover, not concealment. Plan is to use large rocks at chokepoints so a 0-sneak-skill player can reliably (not just by chance) get past by routing behind them, matching "walking around their ranges using the rocks." Rat aggro ranges will be tuned short enough for this to work once rat stats and corridor layout are set.
3. **Optional side path.** A key, reachable only by sneaking past the 3rd rat. A chest ("**Rusty Key**" opens it) sits on the main path, not gated behind the extra rat — openable either with the key or a Sleight of Hand check of 5 (flat threshold, matching the existing `jammed_door.gd`/`stat_checks.gd` pattern). Contains 4 coins (placeholder value, may change later).
4. **Exit.** A tutorial message tells the player to find spiritual protection and food/shelter for the night. `[message text: placeholder — yours to write]`. Leads out the smaller drainage pipe into the Lower Ditch.

## Roadmap to implementation

All structural questions are now resolved; what's left before code work starts is folding this into canon and then building. Order matters — each phase below unblocks the next.

**No dialogue gets written by Claude, at any phase.** Every phase below that touches a scene, trigger, or NPC beat gets structural/mechanical description only (what the beat needs to accomplish, what state it sets, what it's reacting to) — never sample lines or draft text. Dialogue slots stay blank or marked with an explicit placeholder for the user to fill in personally. See [[feedback_dont_decide_placement]].

**Phase 0 — Fold into canon (`DesignDoc_BronzeAge.md`). Done, 2026-07-13.**
- §13: Taskmaster entry replaced with "The Interrupted Sacrifice" — structural/staging description of the new opening scene (sacrifice room, small/contained rite, apparatus-shudder interruption, one legible fragment, escape to the Apothecary), placeholders left everywhere dialogue would go.
- §13: exposition-slot default recorded (post-dream trainer dialogue), flagged as still the user's call if they want it elsewhere.
- §6: added the suppressed-manhunt reason to the Upper City Gate section, alongside the existing class-boundary reason.
- §16 (was mislabeled §11 above — corrected): added the ritual room + escape route to the district-chain and Ditch-layout diagrams; flagged Node 1 as orphaned by the Taskmaster's removal (not reassigned); fixed the stale "no NPCs past the fork" line and flagged (didn't rewrite) the stale Apothecary "market district" characterization, since that's a pre-existing, unrelated drift.
- §3: added the mark + suppressed-aftermath facts under "The King's God."
- **Found during Phase 0, not just a doc issue:** the Taskmaster is a real implemented feature — `scripts/entities/taskmaster.gd`, present in `zone_ditch.tscn`, with state tracking in `game_manager.gd` (`taskmaster_left`). Cutting it is real Phase 3 code work, not only a text change.

**Phase 1 — Content decisions. Mostly done, 2026-07-13** — see "Phase 1 decisions" and "The escape route as tutorial dungeon" above. Remaining small items are listed under "Still open" above (curse mechanics, exact chamber placement, insect/enemy stats).

**Phase 2 — Build geometry. Done, 2026-07-14.**
- `zone_escape_route.tscn` — full 4-beat corridor (roach combat tutorial with a guaranteed `giant_roach` meat drop, rat/rock sneak tutorial, rusty-key/locked-chest side path, exit tutorial trigger), new `rat.gd`/`roach.gd`/`locked_chest.gd`/`tutorial_trigger.gd` entity scripts, new `data_manager.gd` entries (`giant_roach` carve table, `giant_roach_meat`, `rusty_key`), autosave trigger at the corridor start. East exit connects into `zone_ditch_lower.tscn` via a new door punched in its west wall at `(5,32)`, landing near the Apothecary per the decided endpoint.
- `zone_ritual_chamber.tscn` — the sacrifice chamber, built as a genuine small interior room rather than a full-size district (this is the first use of `DesignDoc_BronzeAge.md`'s "Type A — Separate interior zone" building-interior tier, previously specified but never implemented). A single `building.gd` box (11×9, one door gap on the west side) holds a `ritual_slab.gd` (the sacrifice slab, center, examine text placeholder), a `campfire.gd` hearth, and four `wall_torch.gd` torches. New `interior_door.gd` entity handles the transition itself — mechanically identical to how `ladder.gd` already does non-edge, interact-triggered zone transitions (both just emit `EventBus.zone_exit_requested`), so no new engine plumbing was needed. The chamber sits in `game_manager.gd`'s world map at the off-grid coordinate `Vector2i(-1, 15)` — outside `hud.gd`'s 20×20 map-screen grid, so it can never render there, satisfying "does not appear on the world map" with no new UI code. Its one exit (`direction = "east"`, a lookup key, not a literal compass heading) leads to the escape route, entering through a new door gap punched in that corridor's west wall at `(10, 37)`.
- **Bug caught and fixed, 2026-07-14:** the escape route had been sitting at world-map coordinate `Vector2i(9, 15)` since the previous session — this silently collided with a pre-existing `zone_desert_south` tile already registered at that same coordinate (a duplicate dictionary key), which would have crashed `GameManager`'s autoload on any real launch. Caught via a headless `godot --check-only` run (a Godot executable happened to be available in this environment) — not something either session had actually launched the game to verify. Moved the escape route to the unclaimed `Vector2i(9, 18)` instead. Worth running that same check again before assuming any future world-map edit is safe; nothing had exercised this path until now.
- Not yet wired: the chamber isn't yet the actual new-game start location, and there's no scripted trigger that puts the player there in the first place — both are Phase 3 (the ritual-interruption cutscene + cutting the Taskmaster).

**Phase 3 — Scripted sequence logic.** The ritual-interrupted cutscene/trigger (apparatus shudder → opening → escape), replacing the old Taskmaster dismissal trigger. Godot scene/script work.

**Phase 4 — Downstream dialogue passes (yours to write).** Post-dream trainer dialogue (Fire Cult Elder, Old Hunter, Scribe, Smith, Apothecary — per `TODO_Act1.md`'s existing punch list) needs to react to a marked, hunted escaped-sacrifice player instead of a vaguely-dreaming ex-slave, and the upper-city gate needs logic reflecting the suppressed-manhunt angle (quiet risk, not overt "wanted" signage). Claude's part here is identifying which dialogue slots need rewriting and flagging them with placeholders describing what the new line needs to convey — not drafting the lines.

Implementation happens on its own branch, per the doc's original status note. Ready to start Phase 0 whenever you want to move — say so and I'll write the doc updates.

---
*Document started: 2026-07-10. Design by user; compiled by Claude.*
