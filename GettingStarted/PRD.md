# Product Requirements Document
## Frontier Fantasy CRPG — Working Title: *[TBD]*

---

## 1. Vision & Concept

A top-down isometric 2D CRPG set in a frontier-fantasy world. The player arrives at (or was born in) a small settler town at the edge of a vast, hostile desert — the furthest outpost of their civilization. The town is less than a generation old and has recently been thrown into upheaval by the discovery of ancient ruins: a glowing metal door buried in a sandstorm, and a slate that lights up at human touch.

The game is about exploration, discovery, and transformation. Power is not freely available — it must be found, earned through relationships, and grown through experience. The world holds secrets that will reshape who the player's character is, literally and figuratively.

---

## 2. Core Design Pillars

- **Discovery over menus:** Abilities, paths, and powers are found in the world, not chosen from a list at level-up.
- **Character as journey:** Stats and skills reflect lived experience. Trainers require relationship-building; paths require commitment.
- **World density over world size:** Each tile should feel authored and purposeful. Quality over quantity.
- **Interactivity through interaction:** The world is navigated primarily through dialogue, object interaction, and turn-based combat.

---

## 3. Setting

**The Frontier Town** (name TBD): A young settlement on the western edge of a massive, inhospitable desert. The town has:
- A military garrison (connected to the discovering explorer's report)
- An early presence of explorers, academics, and opportunists drawn by rumors
- Local workers and residents who have built lives here
- A criminal underbelly forming as the town grows

**The Discovery:** A sandstorm revealed a metal door in the desert and a glowing slate that responds to human touch. The slate is under military control. No explorer has been able to relocate the door. The only clue is a distant canyon (days away, monster-inhabited).

**Beyond the town:** Desert tribes, ancient underground ruins, an underground mushroom swamp civilization, and more to be designed.

---

## 4. World Map & Tile System

### 4.1 World Map Structure
- The world is a **3D grid of tiles** — essentially a layered cube viewed one layer at a time.
- The player views and navigates the map layer by layer using **up/down navigation buttons** in the UI corner.
- Each world map tile represents one distinct area (a town district, a canyon section, an underground chamber, etc.).
- Lower layers represent underground areas, accessed via in-world passages (stairs, ladders, cave entrances, lifts), **not** by walking off the edge of a tile.
- Edge-walking between tiles on the same layer is the primary horizontal navigation method.

### 4.2 Tile Exploration & Map Reveal
- All tiles begin **blank/unexplored** on the world map.
- When the player **visits** a tile, it becomes visible on the world map using a small authored thumbnail image (created separately by the designer).
- As the player discovers **NPCs, important locations, and tile exits**, these are saved as **notes** on that tile, viewable by hovering it on the map.
- Notes are accumulated over time and serve as the player's in-game journal of their exploration.

### 4.3 Tile Navigation
- A player moves between horizontally adjacent tiles by **walking to the corresponding edge** of the current tile.
- An edge can be **blocked** (impassable) or **unblocked** (leads to adjacent tile).
- Tiles must know which of their four edges connect to other tiles and which are walls/dead ends.

---

## 5. Area/Scene System (Individual Tile View)

### 5.1 Layout
- Each tile, when entered, is rendered as a **full scene**.
- The scene has a **static background image** (pixel art, authored by the designer).
- Layered on top of the background are:
  - **Move-blocking objects** (buildings, rocks, trees, closed doors, large furniture, etc.)
  - **Interactable objects** (doors, containers, computers, bookshelves, beds, food, etc.)
  - **NPCs and enemies**
  - **The player character**

### 5.2 Grid & Isometric Perspective
- The scene is **grid-based** underneath.
- The grid is **offset 45 degrees** to create an isometric feel.
- The player character is a **grey rectangle** placeholder. Its "feet" are centered in its current grid tile; the top portion extends above the tile boundary to create the illusion of vertical presence.
- Buildings are **non-interactable** and simply block movement.

### 5.3 Move-Blocking Tag
- Every object and entity has an internal **`blocks_movement`** boolean tag.
- This tag can be **toggled at runtime** (e.g., when a door is opened, it flips from `true` to `false`).
- The pathfinding system reads this tag to determine valid movement paths.

### 5.4 Interactable Highlighting (Alt Key)
- Pressing or holding **Alt** causes all interactable objects in the current scene to highlight visually.
- This is critical for the player to distinguish interactables from the background art, especially during early placeholder stages.
- Interactability is determined by an internal **`is_interactable`** boolean tag on each object.

### 5.5 Movement
- The player moves by **right-clicking** a location on the screen.
- The character pathfinds to that location using **shortest path**, routing around `blocks_movement` objects.
- Movement is grid-tile-based.

---

## 6. Entity System

### 6.1 Entity Superclass
All characters, NPCs, and enemies inherit from a common **Entity** superclass. This superclass holds:
- Identity fields (name, ID, entity type)
- The `blocks_movement` tag
- Position data
- Base stat block (see Section 7)
- Skill list (see Section 8)
- Inventory (see Section 9)
- Equipment slots (see Section 9)
- Ability/feat list (see Section 10)
- Current HP / status effects

### 6.2 Humanoid Subclass
- Inherits all Entity fields.
- Used for: the player character, humanoid NPCs, humanoid enemies.
- Fully implements all stat, skill, inventory, and ability systems.

### 6.3 Non-Human Subclass (Future)
- Will have a modified version of the stat/skill block appropriate to creatures.
- Design deferred to a later planning phase.

---

## 7. Character Stats

### 7.1 Base Stats
| Stat | Abbreviation |
|---|---|
| Strength | STR |
| Dexterity | DEX |
| Agility | AGI |
| Constitution | CON |
| Intelligence | INT |
| Willpower | WIL |
| Charisma | CHA |

### 7.2 Stat Scoring
- All stats begin at **5** (= **+0 modifier**).
- Every point **above or below 5** = **+1 or -1 modifier** respectively.
- At Level 1 character creation, the player has **4 additional points** to distribute.
- A stat may be **reduced to 4** to refund 1 point.
- **Maximum of 3 points above 5** in any single stat at Level 1 (i.e., max 8 at creation).
- Modifiers apply to relevant skill checks and rolls.

### 7.3 Stat Growth
- Every **4th level** (levels 4, 8, 12, …), the player gains **2 stat points** to distribute freely across any stats.

---

## 8. Skills System

### 8.1 Overview
- Skills represent specific learned competencies.
- All skills begin at **0**.
- At character creation, the player receives **80 skill points** to distribute.
- At each level-up, the player receives **30 skill points**.
- Both figures are modified by **INT modifier × 5** (e.g., INT mod +2 → +10 points; INT mod -1 → -5 points).
- These numbers are provisional and subject to balance tuning.
- Each skill is associated with one or two stats that provide a **modifier** to that skill.
- Where two stats are listed, the **higher modifier** of the two applies.

### 8.2 Starting Skills
| Skill | Governing Stat(s) | Notes |
|---|---|---|
| Melee | STR / DEX | If unarmed, uses higher of STR or DEX |
| Ranged | STR / DEX | Weapon type may dictate which applies |
| Dodge | DEX | |
| Deceive | CHA | |
| Convince | CHA | |
| Intimidate | STR / CHA | |
| Sneak | DEX | |
| Lockpick | DEX | |
| Science | INT | |
| Technology | INT | |
| Tailoring | INT / DEX | |
| Physical Labor | INT / STR | |

### 8.3 Effective Skill Formula
Skill checks use an **effective skill level**, not raw invested points:

`Effective Skill = Invested Points × (1.0 + Governing Modifier × 0.1)`

e.g. 10 invested with a +3 modifier → 10 × 1.3 = **13.0**

- Negative modifiers reduce effective skill below invested points
- Cap on invested points at level 1: **20**
- Skill points at level 1: **50 + (INT mod × 5)**

*More skills will be added, particularly as trainer paths and ability paths are designed.*

### 8.3 Path-Added Skills
- Unlocking a trainer path or transhumanist path can:
  - Add **entirely new skills** to the character's sheet.
  - Apply **bonuses or modifiers** to existing skills.

---

## 9. Inventory & Equipment

### 9.1 Inventory
- Characters have a general inventory (container of items).
- Items have properties: name, description, weight (TBD), type, any special tags.

### 9.2 Equipment Slots (Initial Set)
| Slot | Description |
|---|---|
| Left Hand | One-handed weapon, shield, offhand item |
| Right Hand | One-handed weapon, tool |
| Body | Shirt, armor, clothing |

*More slots to be added later (head, legs, feet, accessory, etc.).*

---

## 10. Abilities, Feats & Power Systems

### 10.1 Feats
- Selected at **character creation** and at **certain level thresholds**.
- Feats are general-purpose enhancements available to any character.
- Feats **never reference world-found powers or paths by name** — but are designed to synergize with them when discovered.
- Players receive **1 feat at level 1**, then **1 feat every other level** thereafter (levels 1, 3, 5, 7, 9, …).
- Some feats are **story-granted** (not choosable from the list); they appear on the character sheet but cannot be selected at level-up.

#### Level-Up Feat List (Initial Set)

| Feat | Effect | Requirements |
|---|---|---|
| **Long Ranged** | Ranged attacks allowed at up to double normal range; hit chance scales linearly from full at normal range to 50% at double range | PER 8, Ranged 20 |
| **Runner** | Each AP spent on movement after MP is exhausted moves you 2 tiles instead of 1 | AGI 8 |
| **Brutal** | Armor penetration increased by 30% (multiplicative) on any attack that already has pierce | STR 8 |
| **Bloodletting** | Bleed application chance increased by 30% (multiplicative) | DEX 8 |
| **Fast Hands** | Unarmed attacks cost 1 AP instead of 2 | DEX 8, Melee 15 |
| **Iron Belly** | Take half damage from anything consumed (poisons, caustic draughts, etc.) | CON 8, Alchemy 15 |
| **Shrug Off** | When a status effect is successfully applied to you, 10% chance your mind refuses it entirely | WIL 8 |

#### Story-Granted Feats
These cannot be selected at level-up. They are earned through specific in-world events.

| Feat | Effect | Source |
|---|---|---|
| **Inner Flame** | Permanent Level 0 spirit protection — night spirits cannot take you unaware | Fire Cult Elder ritual |

### 10.2 Two Categories of Acquired Ability

#### Category A: Trainer Paths (Non-Exclusive)
- Found through NPCs in the world.
- No body modification; no mutual exclusivity.
- Powers are somewhat weaker than Category B due to lack of trade-offs.
- Examples:
  - **Combat Skills** — from working with the local military.
  - **Desert Survival** — from desert tribes.
  - Many more to be designed.
- Most trainer paths require relationship investment (quests, faction standing, minimum stat requirements).
- **Progression:** Meeting a trainer unlocks a skill tree. Marking it *active* causes related activities and XP to grow that tree organically. The player does not simply purchase skills immediately.
- **Exception:** A trainer may teach a single specific skill as a one-time quest reward, granted immediately.

#### Category B: Transhumanist Paths (Exclusive / Trade-Off)
These paths physically alter the character. Mixing paths is either **mutually exclusive** or limited with significant trade-offs.

| Path | Source | Mechanic |
|---|---|---|
| **Poison Alchemy** | Underground mushroom swamp society | Religion of gradual immunization to increasingly powerful poisons; the ultimate poison built within the self. Progression through meeting society members and completing objectives on the path. |
| **Cybernetic Enhancement** | Ancient ruins | Mechanical implants installed at discovered machines. Progression through acquiring specific items and accessing ruin sites. |
| *More to be designed* | | |

- **Progression:** Unlocked by finding the initiating NPC or location. Progress through acquiring specific items, reaching locations, or completing path-specific objectives — not XP grinding.

### 10.3 Mutual Exclusivity Rules (Draft)
- Two transhumanist paths may not be fully combined; attempting to mix produces diminishing returns or explicit conflicts.
- Trainer paths (Category A) have no exclusivity restrictions.
- A character may be on one transhumanist path and multiple trainer paths simultaneously.

---

## 11. Background System (Character Creation)

Choosing a background provides:
- **Stat bonuses** specific to the background.
- **Minimum stat requirements** that must be met.
- **Starting trainer access** — an initial NPC trainer in the frontier town who will begin teaching the character.

| Background | Starting Trainer Access | Flavor |
|---|---|---|
| Mercenary | Fighting or Archery trainer (military) | Enlisted with the frontier garrison |
| Explorer's Guild Member | Survivalism or TBD | Came seeking the ruins |
| Local Criminal | Thieving / Fence, Assassination trainer | Grew up or settled into the town's underworld |
| University Academic | History/Archeology, Technology (gadgets/guns), or Alchemy trainer | Sent by or traveled from the capital university |
| Local Worker | Community contacts, Mundane Physical Skills trainer | Born here or arrived early; knows the town |
| *More to be added* | | |

**Cross-faction trainer access:** Any trainer from any background can eventually be accessed by any player, provided they invest in the relevant faction relationship and meet minimum stat requirements.

---

## 12. Interaction Systems

### 12.1 Dialogue
- Humanoid NPCs are interacted with via a **dialogue system**.
- Dialogue supports: narrative text, branching player choices, skill checks, and relationship flags.
- Specifics of dialogue UI TBD.

### 12.2 Object Interaction
- Clicking an interactable object opens an **interaction panel** showing:
  - A text-based description of what the character perceives up close.
  - Available options (e.g., "Pick the lock," "Force it open," "Leave it").
  - **Skill checks** where applicable, showing difficulty and relevant skill.
- Examples: opening a container, reading a terminal, examining a bookshelf, sleeping in a bed.

---

## 13. Combat System

### 13.1 Trigger
- Turn-based combat activates when a **hostile entity detects the player**.
- Detection logic TBD (line of sight, hearing, proximity).

### 13.2 Structure
- **Turn-based** with initiative order (TBD — stat-based, e.g., AGI modifier).
- Each turn: the active entity performs actions.
- Action types:
  - **Move** (within a range determined by stats/abilities)
  - **Melee Attack** (adjacent tile) — uses equipped weapon or unarmed; scales off STR or DEX
  - **Ranged Attack** (at range) — uses equipped ranged weapon; scales off STR or DEX
  - **Use Ability**
  - **Use Item**
  - **End Turn**

### 13.3 Attack Resolution
- Attacker rolls relevant skill check (modified by governing stat) vs. target's defense (TBD formula).
- Damage determined by weapon/ability + modifiers.
- Unarmed attacks use the higher of STR or DEX modifier.

---

## 14. UI Requirements

| UI Element | Description |
|---|---|
| **Main Scene View** | Isometric grid scene, character movement, object highlighting |
| **Character Sheet** | Stats, modifiers, active paths, feats |
| **Skills Panel** | All skills with current values and governing stats |
| **Inventory / Equipment** | Grid inventory + equipment slot view |
| **World Map** | Layered tile map, explored/unexplored tiles, hover notes, up/down layer navigation |
| **Interaction Panel** | Object/dialogue interaction window |
| **Combat HUD** | Initiative order, action buttons, HP bars (active during combat) |

---

## 15. MVP Scope (Phase 1 Build Target)

The first build milestone is a **technical framework only** — no authored content, no story, no specific items or characters beyond placeholder data.

### MVP Deliverables:
- [ ] **Character Creation screen**: choose stats (with point-buy rules), choose background (basic selection), see starting skills calculated
- [ ] **Single tile scene**: isometric grid (45° offset), black grid lines, navigable by right-click with shortest-path routing
- [ ] **Player character placeholder**: grey rectangle, feet centered in tile, top half extends above tile
- [ ] **Alt-key highlight**: highlights all objects tagged `is_interactable`
- [ ] **`blocks_movement` tag**: respected by pathfinding; at least one toggleable example (a "door")
- [ ] **Character Sheet menu**: displays all 7 stats with modifiers, skill list with values
- [ ] **Inventory/Equipment menu**: left hand, right hand, body slots; empty inventory grid
- [ ] **World Map menu**: layered grid, blank unexplored tiles, up/down layer navigation; no content yet

### Out of Scope for MVP:
- Dialogue system
- Combat system
- NPC/enemy AI
- Any authored content (areas, characters, items, story)
- Trainer path progression
- Transhumanist paths
- Feats system (UI shell only)

---

## 16. Open Questions (To Resolve in Planning)

- [x] ~~What technology/engine will be used?~~ **Godot 4** (GDScript)
- [x] ~~How many skill points does the player start with and gain per level?~~ **80 at creation, 30 per level. Both figures adjusted by ±(INT modifier × 5). Numbers are provisional.**
- [x] ~~Exact stat growth per level?~~ **+2 stat points every 4th level (levels 4, 8, 12, …)**
- [x] ~~Which levels grant feat choices?~~ **Level 1, then every other level (1, 3, 5, 7, 9, …)**
- [ ] Tile size in pixels; character size in pixels
- [ ] How does the world map thumbnail get loaded/displayed?
- [ ] Full feat list (initial set)
- [ ] Initiative / action economy specifics for combat
- [ ] More backgrounds, trainer paths, transhumanist paths
- [ ] Working title / world name / town name

---

*PRD Version 0.1 — Initial draft from design session. All systems subject to revision.*
