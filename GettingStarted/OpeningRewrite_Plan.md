# Opening Hook Rewrite — Planning Doc

> Status: pre-decision planning, not yet canon. Nothing here should be implemented until the open questions below are resolved and it gets folded into `DesignDoc_BronzeAge.md`. Implementation happens on its own branch once that's done.

## The problem with the current opening

Current opening (`DesignDoc_BronzeAge.md` §13, [The Taskmaster]): the player is a slave who is simply released — dismissed, handed nothing, told offhand that they've lost their god's protection. It's exposition delivered through condescension. It works as a *lore-delivery* mechanism (godlessness, spirits) but gives the player nothing to want. Nobody did anything to you. Nothing is at stake. The premonition dream that follows is the only hook, and it's abstract and uninterpretable by design — good as a slow-burn mystery, bad as an opening beat.

## The rewrite

Instead of being released from slavery, the player is about to be **sacrificed** — brought to the king's ritual as one of its victims. They get close enough to glimpse what the ritual actually is (or part of it), and in that moment become entangled in it rather than just adjacent to it. They escape — mechanism TBD (see open questions) — but escape marked: physically or spiritually tied to the ritual now, not merely a witness who got away clean.

This changes the throughline from "learn about a threat" to "you are already inside the threat and trying to get free of it." Early game is survival and staying hidden. As the player learns more about what the king is actually doing, the same knowledge that endangers them becomes leverage — options open up to stop the ritual or usurp it, not just avoid it.

**Why this is a small rewrite, not a big one:** the lore already supports it almost exactly as-is. §3 "The King's God" already states: *"Slaves are sacrificed at the shrine. This is accepted, known, and unremarkable. It is the cost of living in a protected city."* That's already in the doc. The rewrite doesn't invent a new fact about the world — it just moves the player from *offscreen statistic* to *the one who was on the altar.*

## What this changes downstream

**Taskmaster NPC / opening scene (§13).** The whole scene as written — dismissive release, condescending dialogue about lost protection — no longer fits. Either this character is repurposed (the priest/handler prepping the player for the shrine, someone whose job is logistics not cruelty, an accomplice who looks away) or replaced outright. The godlessness/spirit exposition it currently delivers still needs to land somewhere — probably still works, just needs a new frame (why is a sacrifice victim being told this at all? Maybe it's *why* they were chosen — an unprotected, godless slave is a "clean" or low-cost sacrifice, nobody's asset).

**Starting geography (§6, §11 zone plan).** Currently the player starts at the taskmaster's back door in the lower city, and the upper city (temple/castle/crafters districts) is sealed off by a class-based guard checkpoint for all of Act 1. Sacrificing at "the shrine, the highest point of the city" (§3) means the opening scene now has to *start* in the upper city — and the player's first playable action becomes escaping downward, through districts they're not normally allowed to see, ending up back in the Ditch where Act 1 was always designed to happen. That's a strong structural rhyme with the game's whole vertical-descent conceit (first thing you do is fall from the top of the city to the bottom of it) and it's basically free thematically.

Practically, this needs some new zone geography that doesn't exist in the plan yet: the sacrifice site itself, and an escape route connecting it down to the Ditch / lower Ditch / undercity threshold. Doesn't need to be fully fleshed-out explorable districts — see recommendation below.

Decided: the escape route does *not* reuse the existing Node 1 (Taskmaster's manor wall) — that's tied to the outer wall in the lower city, and the palace is going on the city's east side instead (see "The ritual site" below). So this is new geography end-to-end: sacrifice room → a route across/down from the east side → into the Ditch somewhere. Where exactly it joins the Ditch — near the existing Upper Ditch hub, at the Fork, or further south toward the undercity threshold — is still open (see below), since each lands the player in a different starting position relative to the Ditch's existing NPCs.

**The upper-city gate's "reason" (§6, line ~350).** Currently the gate is purely a class boundary: no money, no patron, no god, no business up there. That still holds, but now there's a second, sharper reason layered on top: the player is a fugitive from a botched sacrifice. Whether that means an active manhunt, a quiet story hushed up because the king's people don't want the ritual talked about, or something else, is an open question below — but either way it gives the gate teeth beyond "guards with spears and a class attitude."

**The premonition dream (§4).** The dream mechanism itself (godless = no household god routing spiritual signal = unfiltered premonition) still works unchanged — the player is still godless, still gets the dream on first protected sleep. What changes is that the dream is no longer the *only* piece of forbidden knowledge the player is carrying. There's now also something concretely *witnessed* — an event that happened, that other people can (skeptically) be told about, as opposed to a dream that exists in no one else's frame of reference. Worth deciding whether these two stay as separate, reinforcing signals (one uninterpretable/mystical, one concrete/deniable) or whether the witnessed event absorbs some of the dream's narrative job. Leaning toward keeping both — they do different work — but flagging it since it changes the weight the dream needs to carry.

**Starting trainers / protection paths (§3 "Paths to restoring divine protection", §13 Market Scribe/Market Smith/Fire Cult Member+Elder).** The trainers themselves stay as-is — they're still where the player goes to seek spiritual protection, still teach what they teach. What has to change is the dialogue that currently fires after the premonition dream (the "morning storyboard" beats in §13, already partly implemented per `TODO_Act1.md`'s "Post-dream dialogue" section for the Fire Cult Elder, Old Hunter, and Scribe, with Smith/Apothecary stubs still TBD). Right now those lines interpret an abstract, uninterpretable vision and vaguely point the player underground. They need to be rewritten to be *about* the curse/ritual specifically — reacting to a player who is marked and hunted, not just someone who had a strange dream. The underlying job (send the player deeper) stays the same; the content and stakes of what's being reacted to changes.

**Backgrounds (§8, slave roles).** Probably unaffected. Any background can plausibly end up chosen for sacrifice — doesn't require a rewrite of the 7 slave-role system, just means "how you got selected for the altar" sits on top of "what labor you did" rather than replacing it.

## The ritual site

Decided: a secret room deep beneath/within the palace — not the public shrine at the top (§3 describes the shrine itself as "the highest point of the city"; this room is separate, hidden, lower down within the palace structure). Small, rectangular. A slab at the center for human sacrifice. A hearth. Torches around the walls.

**Exit/route note:** Won't reuse the Taskmaster's building as the escape route's exit point — that door sits against the *outer* city wall in the lower city (§11, Node 1). The palace will sit somewhere in the **north-to-northeast** stretch of the city — exact placement not pinned down yet, just narrowed away from due-east, since that whole quadrant is still empty/unbuilt space to work with. So the escape route is new geography connecting that area down to the Ditch, rather than plugging into the existing Node 1 door as floated earlier.

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

## Remaining open questions (yours to decide, unblocked from structural work)

- **Content of the "legible fragment"** — what specifically the player sees/hears/glimpses of the machine.
- **Specific form of the mark** — what the physical mark looks like, what the spiritual/mechanical component actually does in systems terms.
- **New home for the godlessness/spirit exposition** now that the Taskmaster is cut — likely candidates: fold into the post-dream trainer dialogue (already partly implemented per `TODO_Act1.md`), fold into the ritual/escape scene itself, or a new brief NPC beat. Not urgent to resolve before zone/geography work starts.
- **Escape route waypoints** between the palace (north/northeast, exact placement still TBD) and the Lower Ditch landing point, and exact palace placement itself.

## Confirmed approach

The escape sequence stays small: a short, mostly-linear string of stub zones (sacrifice room → a corridor or two → wall/gate → drop into the Lower Ditch near the Apothecary) rather than fully realized, explorable upper-city districts. Consistent with the small/contained ritual-scale decision above — the escape is a scripted bookend, not a new open area to fill with NPCs and quests, matching hobby-project scope.

## Roadmap to implementation

All structural questions are now resolved; what's left before code work starts is folding this into canon and then building. Order matters — each phase below unblocks the next.

**No dialogue gets written by Claude, at any phase.** Every phase below that touches a scene, trigger, or NPC beat gets structural/mechanical description only (what the beat needs to accomplish, what state it sets, what it's reacting to) — never sample lines or draft text. Dialogue slots stay blank or marked with an explicit placeholder for the user to fill in personally. See [[feedback_dont_decide_placement]].

**Phase 0 — Fold into canon (`DesignDoc_BronzeAge.md`).** Claude can execute this without further input, working from the decisions above:
- §13: remove the Taskmaster entry; write the new opening scene (sacrifice room, small/contained rite, interruption via apparatus shudder, one legible fragment, escape) as a scripted sequence, not an NPC-driven scene. Structural/staging description only — no dialogue.
- §13: decide-by-folding where the godlessness/spirit exposition *slot* lands (default to the post-dream trainer dialogue per `TODO_Act1.md`, unless you want it flagged for your call instead — see open question above). This places *where* the exposition beat happens, not what it says.
- §6/§11: add the palace (north/northeast, exact tile placement TBD) and the new escape-route geography as a stub node chain, ending at the existing `zone_ditch_lower.tscn` Apothecary location. Fix the stale "Apothecary is in the market district" and "no NPCs past the fork" lines while touching this section.
- §3: note the mark (physical + spiritual/mechanical, forms TBD) and the suppressed/hushed-up aftermath as new player-state facts.

**Phase 1 — Remaining content decisions (yours).** Doesn't block Phase 0 or early geometry work, but blocks writing final scene dialogue/text:
- The legible fragment's content.
- The mark's specific physical form and spiritual/mechanical effect.
- Exact escape-route waypoints and palace tile placement.

**Phase 2 — Build geometry.** New scenes for the sacrifice room and escape corridor(s), connective tissue into `zone_ditch_lower.tscn`. Claude-executable once Phase 0/1 placement decisions land.

**Phase 3 — Scripted sequence logic.** The ritual-interrupted cutscene/trigger (apparatus shudder → opening → escape), replacing the old Taskmaster dismissal trigger. Godot scene/script work.

**Phase 4 — Downstream dialogue passes (yours to write).** Post-dream trainer dialogue (Fire Cult Elder, Old Hunter, Scribe, Smith, Apothecary — per `TODO_Act1.md`'s existing punch list) needs to react to a marked, hunted escaped-sacrifice player instead of a vaguely-dreaming ex-slave, and the upper-city gate needs logic reflecting the suppressed-manhunt angle (quiet risk, not overt "wanted" signage). Claude's part here is identifying which dialogue slots need rewriting and flagging them with placeholders describing what the new line needs to convey — not drafting the lines.

Implementation happens on its own branch, per the doc's original status note. Ready to start Phase 0 whenever you want to move — say so and I'll write the doc updates.

---
*Document started: 2026-07-10. Design by user; compiled by Claude.*
