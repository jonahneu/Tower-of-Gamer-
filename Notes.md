Writing ideas here:

Mercenary Guildhall: 
Fighting trainer offers - Sword or spear + shield
Archery trainer offers - Longbow + Quiver (bottomless for now)

Explorer's Guildhall:
Survivalism trainer offers - Knife or Whip + Desert Shawl or Backpack

Thieves Den (criminal background building):
Thief trainer offers - Knife or Brass Knuckles + Lockpicking Kit
Assassin trainer offers - Shortsword and Shortbow

Academy Outpost:
Archaeology Trainer offers - Whip + Archaeology Kit
Technology Trainer offers - Blunderbuss (reload required, infinite ammo) + Tinkering Tools
Alchemy Trainer offers - Knife + Brewers Kit

Local Tavern (Location for Local Worker):
Physical Labor Trainer (needs a better name) offers - Axe or Spear + Shovel + Rope

Equipment slots: hand_1, hand_2, head, body, legs, feet, hands (gloves), back.
Quiver and Desert Shawl equip to back slot.
No concept of handedness — any weapon can go in either hand slot.
Non-weapon items (tools, kits) sit in inventory unless they have a designated slot.

---

## Weapon Stats

| Weapon       | Damage | AP | Range | Governing | Notes                                              |
|---|---|---|---|---|---|
| Unarmed      | 1d3    | 1  | 1     | STR/DEX   |                                                    |
| Brass Knuckles | 1d4  | 1  | 1     | STR       |                                                    |
| Knife        | 1d4    | 1  | 1     | DEX       | Thrown: range 8, right-click from inventory        |
| Shortsword   | 1d6    | 2  | 1     | STR/DEX   | Bleed                                              |
| Spear        | 1d6    | 3  | 2     | STR/DEX   |                                                    |
| Whip         | 1d3    | 2  | 3     | DEX       | Disarm ability                                     |
| Sword        | 1d8    | 2  | 1     | STR/DEX   | Bleed                                              |
| Axe          | 1d10   | 3  | 1     | STR       | Armor Pierce                                       |
| Shortbow     | 1d6    | 2  | 12    | DEX       | Ammo: quiver                                       |
| Longbow      | 1d8    | 3  | 16    | DEX       | Ammo: quiver                                       |
| Blunderbuss  | 2d6    | 4  | 8     | DEX       | Reload (3 AP), Scatter                             |

Governing stat modifier adds to damage roll on top of weapon base damage.
STR/DEX = use whichever modifier is higher.

---

## Weapon Properties

**Bleed** (Knife, Sword, Shortsword)
- On hit: bleed_chance = 60% × (0.85 ^ defender_CON_mod) for positive CON mod
- Negative CON mod: 60% + (|CON_mod| × 8%), capped at 95%
- Applies 1 bleed stack on proc
- Each stack deals 1d3 damage at start of affected entity's turn
- Each stack has its own 3-turn counter; fades after dealing damage 3 times
- Stacks are independent (multiple stacks = multiple 1d3 rolls per turn)
- No stack cap for now
- Can be cleared by items (bandages etc., to be designed)

**Armor Pierce** (Axe)
- Ignores 10% of target's flat armor and 10% of target's percentage armor
- Flat: treat target's flat armor as flat × 0.9
- Percentage: treat target's percentage armor as armor_pct × 0.9
  (e.g. 10% armor becomes 9%, not 10% - 10% = 0%)

**Disarm** (Whip — granted as ability while equipped)
- Range: 3, AP cost: 2, no damage
- Uses melee (DEX) hit roll
- On hit: knocks weapon from target's hand
- 3-turn cooldown

**Thrown** (Knife)
- Right-click knife in inventory to throw without equipping
- Range: 8, damage: 1d4, governing: DEX
- Item lands at target tile after thrown

**Reload** (Blunderbuss)
- Must spend 3 AP to reload after firing
- Infinite ammo for now

**Scatter** (Blunderbuss)
- On miss: still deals 1d3-1 damage (0–2)

---

## Armor System

Two armor layers, applied in order:
1. Flat reduction: max(1, damage - flat_armor)
2. Percentage reduction: result × (1 - armor_pct)

**Clothing** — percentage resistance only (no flat value)
**Armor** — both flat and percentage resistance
**Exotic materials** (e.g. insect carapace, ceramics) — may have high flat and no percentage, handled case by case

Percentage armor stacks multiplicatively across slots:
- Two pieces of 20% = 1 - (0.8 × 0.8) = 36% total (never approaches 100%)

Axe armor pierce applies to both layers independently (see Weapon Properties above).

---

## Starting Outfits by Background

**Mercenary**
- Head:  Uniform Cap — cloth, 2%
- Body:  Gambeson — armor, +1 flat / +6%
- Legs:  Uniform Trousers — cloth, 3%
- Feet:  Military Boots — cloth, 2%
- Hands: Leather Gloves — cloth, 2%
- Back:  empty
- Total: +1 flat, ~14% (multiplicative)

**Criminal**
- Head:  Hood — cloth, 1%
- Body:  Leather Vest — cloth, 3%
- Legs:  Dark Trousers — cloth, 2%
- Feet:  Soft Boots — cloth, 2%, +3 Sneak
- Hands: empty
- Back:  empty
- Total: +0 flat, ~8%

**Explorer** (PARKED — revisit after desert heat/sandstorm mechanics)
- Head:  Wide-Brim Hat — cloth, 1%
- Body:  Explorer's Coat — cloth, 4% (bonus TBD pending desert mechanics)
- Legs:  Sturdy Trousers — cloth, 2%
- Feet:  Hiking Boots — cloth, 2%
- Hands: empty
- Back:  empty

**Academic**
- Head:  Scholar's Cap — cloth, 1%
- Body:  Scholar's Robes — cloth, 2%, +carry weight (amount TBD pending weight system)
- Legs:  empty
- Feet:  Scholar's Shoes — cloth, 1%
- Hands: empty
- Back:  empty
- Total: +0 flat, ~4%

**Local Worker**
- Head:  empty
- Body:  Work Shirt — cloth, 2%
- Legs:  Work Trousers — cloth, 2%
- Feet:  Work Boots — cloth, 2%
- Hands: Work Gloves — cloth, 1%
- Back:  empty
- Total: +0 flat, ~7%
- Note: gets a discount at the local store — can buy more gear early than other backgrounds
