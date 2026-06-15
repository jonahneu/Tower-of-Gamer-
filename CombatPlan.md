# Combat System Plan

## Overview
Turn-based combat triggered when the player attacks or is attacked.
Uses an **Action Point (AP)** + **Movement Point (MP)** system.

---

## Core Stats

| Resource | Value | Resets |
|---|---|---|
| AP | = Agility stat (not modifier) | Start of own turn |
| MP | = Agility stat (not modifier) | Start of own turn |

- 1 MP = 1 tile of movement.
- Status effects can modify the reset amount.

---

## Turn Order
- Initiative order TBD (likely DEX-based roll at combat start).
- Each combatant gets full AP + MP restored at the start of their turn.
- Player acts on their turn via UI; enemies act via AI on theirs.

---

## Hit Chance Formula (draft)

```
base_hit = attacker_skill * 1.5      # melee or ranged skill (effective value)
dodge_reduction = defender_skill * 1.0   # dodge skill (effective value)
hit_chance = clamp(base_hit - dodge_reduction + situational_modifiers, 5, 95)
```

- Minimum 5%, maximum 95% — always a chance to hit or miss.
- Situational modifiers: darkness (-15), high ground (+10), prone (+20 attacker), etc.
- **Displayed as a % when the player hovers "Confirm Attack".**

---

## Weapon AP Costs (draft)

| Weapon | Attack AP | Notes |
|---|---|---|
| Unarmed fist | 2 | — |
| Knife | 2 | — |
| Shortsword | 3 | — |
| Sword | 4 | — |
| Axe | 4 | — |
| Whip | 3 | Reach (2 tiles) |
| Shortbow | 3 | Ranged |
| Longbow | 5 | Ranged, high damage |
| Blunderbuss | 3 | Fire cost; requires Reload ability before next shot |

### Blunderbuss Abilities
| Ability | AP Cost | Cooldown | Notes |
|---|---|---|---|
| Fire | 3 | Must reload before reusing | Single-shot ranged |
| Reload | 2 | 0 turns | Re-enables Fire |

---

## Item Use in Combat
- Throwable weapons, healing items, etc. all have AP costs.
- Items with cooldowns track remaining turns.
- Items with 0-turn cooldown can be used multiple times per turn (if AP allows).

---

## Abilities
- Abilities appear in a dedicated panel during the player's turn.
- Each ability has: AP cost, cooldown (turns), effect.
- Some abilities are granted by equipped weapons (e.g. Blunderbuss → Reload/Fire).
- Cooldown tracked in `CombatManager` per combatant.

---

## Architecture Plan

### New Files
| File | Purpose |
|---|---|
| `scripts/systems/combat_manager.gd` | Autoload or node managing combat state, turn order, AP/MP tracking |
| `scripts/systems/combat_turn.gd` | Represents one combatant's turn state (AP, MP, cooldowns) |
| `scripts/ui/combat_hud.gd` | In-combat UI: AP bar, MP bar, action buttons, ability list, end-turn |
| `scenes/ui/combat_hud.tscn` | Scene for the combat HUD |

### Modified Files
| File | Change |
|---|---|
| `game_manager.gd` | `combat_mode: bool` already exists; wire to CombatManager |
| `player.gd` | Disable free movement during combat; listen for combat turn |
| `event_bus.gd` | Add `combat_started`, `combat_ended`, `turn_started(entity)`, `turn_ended(entity)` signals (some already exist) |
| `entity.gd` | Add `max_ap`, `max_mp` (derived from agility), `current_ap`, `current_mp` |
| `humanoid.gd` | Add agility-derived AP/MP; add `weapon_abilities: Array` populated from equipment |

### Data Model

**Combat State (CombatManager)**
```
participants: Array[Node]   # all combatants, sorted by initiative
current_turn_index: int
round: int
```

**Per-Combatant Turn State**
```
entity: Node
current_ap: int
current_mp: int
cooldowns: Dictionary  # ability_id -> turns_remaining
is_blunderbuss_loaded: bool  # example weapon-specific state
```

**Weapon Data Extension**
Each weapon in ITEMS gets two new optional keys:
```
"ap_cost": int         # AP to attack with this weapon
"abilities": Array     # [{id, label, ap_cost, cooldown, ...}]
```

---

## Combat Flow

```
1. Combat triggered (player attacks, or enemy initiates)
2. CombatManager.start_combat(participants)
   - Roll initiative for each participant
   - Sort participants by initiative
   - Enter combat mode (GameManager.combat_mode = true)
   - Emit EventBus.combat_started
3. Each turn:
   a. CombatManager advances to next participant
   b. Restore AP + MP for that participant
   c. Tick down cooldowns by 1
   d. Emit EventBus.turn_started(entity)
   e. If player: show combat HUD, wait for input
      If enemy: run AI, then call end_turn()
4. end_turn():
   a. Emit EventBus.turn_ended(entity)
   b. Advance to next participant (wrap around)
   c. Check win/lose condition
5. Combat ends when one side has no living members
   - Emit EventBus.combat_ended
   - GameManager.combat_mode = false
```

---

## UI Plan (Combat HUD)

```
┌─────────────────────────────────────────────────────────┐
│  [AP: ████████░░ 8/10]   [MP: ██████░░░░ 6/10]         │
│                                                          │
│  ACTIONS:                                                │
│  [Attack - Sword (4 AP)]  [Attack - Unarmed (2 AP)]    │
│  [Use Item ▼]             [Abilities ▼]                 │
│                                                          │
│  [End Turn]                                              │
└─────────────────────────────────────────────────────────┘
```

- Attack buttons are generated dynamically from equipped weapons.
- When hovering over an attack target, show hit% tooltip.
- Grayed out if insufficient AP.
- "End Turn" always available.

---

## Implementation Order

1. **Step 1** — Extend data model
   - Add `ap_cost` and `abilities` to weapon entries in `trainer.gd` ITEMS const
   - Add `current_ap`, `current_mp` to `entity.gd` with agility-derived defaults

2. **Step 2** — `CombatManager` autoload
   - Turn order, AP/MP tracking, cooldown ticking
   - `start_combat()`, `end_turn()`, `spend_ap()`, `spend_mp()`

3. **Step 3** — `CombatTurn` state object
   - Per-combatant tracking within a fight

4. **Step 4** — Hit chance calculation
   - `calc_hit_chance(attacker, defender, weapon, modifiers) -> int`
   - Returns 5–95

5. **Step 5** — Combat HUD
   - AP/MP bars, action buttons, end-turn
   - Hit% tooltip on hover

6. **Step 6** — Player combat input
   - Restrict movement to MP spending during combat
   - Attack/ability selection flow

7. **Step 7** — Basic enemy AI
   - Move toward player, attack when in range

---

## Open Questions
- Initiative: pure DEX roll, or DEX + random?
- Does moving consume AP or only MP?
- Can the player pass their turn / wait?
- Area-of-effect abilities planned?
- Death vs. knockout — instant kill or bleed-out mechanic?
