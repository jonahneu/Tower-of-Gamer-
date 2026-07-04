extends Entity
class_name Humanoid

# ── Skills ────────────────────────────────────────────────────────────────────
# Each skill stores its raw invested points. Final value = points + governing modifier.
var skills: Dictionary = {
	"melee":          0,
	"ranged":         0,
	"dodge":          0,
	"convince":       0,
	"intimidate":     0,
	"sneak":          0,
	"sleight_of_hand": 0,
	"alchemy":        0,
	"occultism":      0,
	"smithing":       0,
	"survival":       0,
	"cooking":        0,
}

# Which stats govern each skill. Where two are listed, the higher modifier applies.
const SKILL_GOVERNING_STATS: Dictionary = {
	"melee":            ["strength", "dexterity"],
	"ranged":           ["perception", "dexterity"],
	"convince":         ["willpower"],
	"intimidate":       ["strength", "willpower"],
	"dodge":            ["dexterity"],
	"sneak":            ["dexterity"],
	"sleight_of_hand":  ["dexterity"],
	"alchemy":          ["intelligence"],
	"occultism":        ["intelligence", "willpower"],
	"smithing":         ["intelligence", "strength"],
	"survival":         ["constitution", "willpower"],
	"cooking":          ["intelligence"],
}

# ── Equipment Slots ───────────────────────────────────────────────────────────
var equipment: Dictionary = {
	"hand_1":         null,
	"hand_2":         null,
	"head":           null,
	"torso":          null,
	"feet":           null,
	"back":           null,
	"right_upper_arm": null,
	"left_upper_arm":  null,
	"right_forearm":   null,
	"left_forearm":    null,
	"necklace":        null,
	"ring_right_1":    null,
	"ring_right_2":    null,
	"ring_left_1":     null,
	"ring_left_2":     null,
}

# ── Status Effects ────────────────────────────────────────────────────────────
# Each effect stores a list of per-stack state.
# bleed: Array of ints — each int is the number of triggers remaining for that stack.
var status_effects: Dictionary = {}
var fire_resistance: float = 0.0   # 0.0 = none, 1.0 = full immunity
var heated_wil_mod: int = 0         # WIL modifier stored when Heated is applied

# ── Inventory ─────────────────────────────────────────────────────────────────
var inventory: Array = []  # Array of item resources

# ── Feats & Paths ─────────────────────────────────────────────────────────────
var feats: Array = []
var active_paths: Array = []  # Trainer/transhumanist paths unlocked

# ── Background ────────────────────────────────────────────────────────────────
var background: String = ""

# ── Skill helpers ─────────────────────────────────────────────────────────────
func get_stat_value(stat_name: String) -> int:
	match stat_name:
		"strength":     return stat_strength
		"dexterity":    return stat_dexterity
		"agility":      return stat_agility
		"constitution": return stat_constitution
		"intelligence": return stat_intelligence
		"willpower":    return stat_willpower
		"perception":   return stat_perception
	return 5

func get_governing_modifier(skill_name: String) -> int:
	var governing = SKILL_GOVERNING_STATS.get(skill_name, [])
	var best = -999
	for stat in governing:
		var m = Entity.modifier(get_stat_value(stat))
		if m > best:
			best = m
	return best if best != -999 else 0

# Returns the effective skill value: invested * (1 + modifier * 0.1)
# e.g. 10 invested, +3 mod = 10 * 1.3 = 13.0
func get_skill_total(skill_name: String) -> float:
	var invested = skills.get(skill_name, 0)
	var mod = get_governing_modifier(skill_name) + get_equipment_governing_bonus(skill_name)
	var equip_bonus: int = get_equipment_skill_bonus(skill_name)
	# Bulky feat: carries an innate Weight Penalty (as if always wearing armor).
	if (skill_name == "sneak" or skill_name == "dodge") and self == GameManager.player and GameManager.has_feat("bulky"):
		var bulky_tier: int = DataManager.feats.get("bulky", {}).get("weight_penalty", 0)
		equip_bonus -= DataManager.weight_penalty_skill(bulky_tier)
	return maxf(0.0, invested * (1.0 + mod * 0.1) + equip_bonus)

# ── Innate armor (set by subclasses for enemies with natural hide/fur) ────────
var innate_defense_flat: float = 0.0
var innate_defense_pct:  float = 0.0

# ── Armor & Damage ───────────────────────────────────────────────────────────
# Returns total flat armor and the multiplicative percentage-remaining factor.
# pct_remaining = 1.0 means no reduction; 0.85 means 15% reduced.
func get_total_armor() -> Dictionary:
	var flat: float      = innate_defense_flat
	var pct_remaining: float = 1.0 - innate_defense_pct
	var all_resist: float = 0.0
	for slot in equipment:
		var item = equipment[slot]
		if item == null:
			continue
		var item_type: String = item.get("type", "")
		if item_type == "armor" or item_type == "clothing" or item_type == "trinket":
			flat         += item.get("defense_flat", 0)
			pct_remaining *= (1.0 - item.get("defense_pct", 0.0))
			all_resist   += item.get("all_resist", 0.0)
	return {"flat": flat, "pct_remaining": pct_remaining, "all_resist": clampf(all_resist, 0.0, 0.9)}

# Calculates final damage received after applying armor (and optional weapon pierce).
# attacker_weapon: the weapon dict used for the attack (pass {} for no weapon).
func calc_damage_received(raw_damage: int, attacker_weapon: Dictionary = {}) -> float:
	var dtype: String = attacker_weapon.get("damage_type", "physical")
	var armor    := get_total_armor()
	var all_resist: float = armor.get("all_resist", 0.0)

	# Bulky feat: flat 10% resist to all damage types, applied multiplicatively
	# on top of armor and any other resistances rather than folded into all_resist.
	# Also adds 2 flat resistance to physical damage specifically (see below).
	var feat_resist_mult: float = 1.0
	var is_bulky: bool = self == GameManager.player and GameManager.has_feat("bulky")
	if is_bulky:
		feat_resist_mult = 0.9

	if dtype == "fire":
		var base: float = float(raw_damage) * (1.0 - fire_resistance)
		return base * (1.0 - all_resist) * feat_resist_mult
	if dtype != "physical":
		return float(raw_damage) * (1.0 - all_resist) * feat_resist_mult

	var flat:    float = armor["flat"]
	var pct_rem: float = armor["pct_remaining"]
	if is_bulky:
		flat += 2.0

	# armor_ignore_pct (e.g. from blessed_weapon): directly reduces flat and pct armor
	var ignore: float = attacker_weapon.get("armor_ignore_pct", 0.0)
	if ignore > 0.0:
		flat    = flat * (1.0 - ignore)
		var pct_reduction := 1.0 - pct_rem
		pct_rem = 1.0 - (pct_reduction * (1.0 - ignore))

	var pierce_mult: float = attacker_weapon.get("pierce_multiplier", 1.0)
	if "armor_pierce" in attacker_weapon.get("properties", []):
		var pen: float = 0.10 * pierce_mult
		flat    = flat * (1.0 - pen)
		var pct_reduction := 1.0 - pct_rem
		pct_rem = 1.0 - (pct_reduction * (1.0 - pen))
	elif "armor_pierce_light" in attacker_weapon.get("properties", []):
		var pen: float = 0.07 * pierce_mult
		flat    = flat * (1.0 - pen)
		var pct_reduction := 1.0 - pct_rem
		pct_rem = 1.0 - (pct_reduction * (1.0 - pen))

	# Flat armor can reduce damage to 0 (fully blocked).
	var after_flat: float = maxf(0.0, float(raw_damage) - flat)
	if after_flat == 0.0:
		return 0.0
	var after_pct: float = after_flat * pct_rem
	return after_pct * (1.0 - all_resist) * feat_resist_mult

# Returns total bonus to a skill from all equipped items, including the
# Sneak/Dodge penalty derived from each item's Weight Penalty tier (see
# DataManager.WEIGHT_PENALTY_TIERS).
func get_equipment_skill_bonus(skill_name: String) -> int:
	var total := 0
	for slot in equipment:
		var item = equipment[slot]
		if item == null:
			continue
		total += item.get("skill_bonus", {}).get(skill_name, 0)
		if skill_name == "sneak" or skill_name == "dodge":
			total -= DataManager.weight_penalty_skill(item.get("weight_penalty", 0))
	return total

# Returns total governing modifier bonus for a skill from all equipped items.
# e.g. a skull headpiece with governing_bonus: {"melee": 1} raises the
# governing stat modifier used in effective-skill calculation by 1 for melee.
func get_equipment_governing_bonus(skill_name: String) -> int:
	var total := 0
	for slot in equipment:
		var item = equipment[slot]
		if item == null:
			continue
		total += item.get("governing_bonus", {}).get(skill_name, 0)
	return total

# Total AP/MP penalty from all equipped items (armor, shields, and unwieldy
# weapons like the greataxe), derived from each item's Weight Penalty tier —
# plus the Bulky feat's innate tier, same as get_equipment_skill_bonus() does
# for Sneak/Dodge. Applied in CombatManager._begin_turn(), floored so it can
# never cut a baseline (unspecialized) character's AP/MP below 4 / 8.
func get_equipment_armor_penalty() -> int:
	var total := 0
	for slot in equipment:
		var item = equipment[slot]
		if item == null:
			continue
		total += DataManager.weight_penalty_ap_mp(item.get("weight_penalty", 0))
	if self == GameManager.player and GameManager.has_feat("bulky"):
		var bulky_tier: int = DataManager.feats.get("bulky", {}).get("weight_penalty", 0)
		total += DataManager.weight_penalty_ap_mp(bulky_tier)
	return total

# ── Carry weight ──────────────────────────────────────────────────────────────
# Base 50 + STR mod × 10 + CON mod × 5, plus any carry_weight_bonus on equipped items.
func get_carry_capacity() -> float:
	var cap: float = 50.0
	cap += Entity.modifier(stat_strength) * 10.0
	cap += Entity.modifier(stat_constitution) * 5.0
	for slot in equipment:
		var item = equipment[slot]
		if item == null:
			continue
		cap += item.get("carry_weight_bonus", 0)
	return cap

# Returns total weight of all equipped and inventory items.
func get_current_weight() -> float:
	var total: float = 0.0
	for slot in equipment:
		var item = equipment[slot]
		if item == null:
			continue
		total += item.get("weight", 0.0)
	for item in inventory:
		total += item.get("weight", 0.0)
	return total

func is_overburdened() -> bool:
	return get_current_weight() > get_carry_capacity()

# ── Skill point pool ──────────────────────────────────────────────────────────
func skill_points_for_level(lvl: int) -> int:
	var base = 60 if lvl == 1 else 35
	return base + (mod_int() * 5)

# ── Held weapon visual ────────────────────────────────────────────────────────
# Returns the weapon in the primary hand, or {} if unarmed. Filters out
# "unarmed" and ad-hoc fist/punch attack dicts (e.g. the Cannibal Leader's
# Punch), which have no "slot" since they aren't real items.
# Player overrides this since its equipment dict is only synced at zone load —
# the live source of truth there is GameManager.player_data. NPC and Enemy
# override it to fall back to _attack_weapon when no hand_1 item is equipped.
func get_held_weapon() -> Dictionary:
	var item = equipment.get("hand_1")
	if item is Dictionary and item.get("type", "") == "weapon" and item.get("slot") != null:
		return item
	return {}

# Draws a small icon for the held weapon beside the body rect so the player
# can tell at a glance whether someone is armed at range (a bow) or in melee,
# and roughly how big that melee weapon is — length and thickness scale with
# the weapon's weight, so axes and greatswords read as visibly bigger than knives.
func _draw_health_bar(bar_x: float, bar_y: float, bar_w: float) -> void:
	const BAR_H: float = 4.0
	var hp_pct: float = clampf(current_hp / max_hp, 0.0, 1.0) if max_hp > 0.0 else 0.0
	var bar_color: Color
	if hp_pct > 0.6:
		bar_color = Color(0.20, 0.78, 0.20)
	elif hp_pct > 0.3:
		bar_color = Color(0.88, 0.73, 0.05)
	else:
		bar_color = Color(0.85, 0.15, 0.10)
	draw_rect(Rect2(bar_x - 1.0, bar_y - 1.0, bar_w + 2.0, BAR_H + 2.0), Color(0, 0, 0, 0.70))
	draw_rect(Rect2(bar_x, bar_y, bar_w, BAR_H), Color(0.22, 0.22, 0.22, 0.85))
	if hp_pct > 0.0:
		draw_rect(Rect2(bar_x, bar_y, bar_w * hp_pct, BAR_H), bar_color)

func _draw_held_weapon(rect: Rect2) -> void:
	var weapon: Dictionary = get_held_weapon()
	if weapon.is_empty():
		return
	var weight: float = weapon.get("weight", 2.0)
	var hand: Vector2 = Vector2(rect.position.x + rect.size.x, rect.position.y + rect.size.y * 0.58)

	if weapon.get("skill", "melee") == "ranged":
		# Bow: an outward-bulging curve with a taut string facing the body.
		var radius: float = clampf(7.0 + weight * 0.6, 7.0, 11.0)
		var top: Vector2 = hand + Vector2(0.0, -radius)
		var bot: Vector2 = hand + Vector2(0.0, radius)
		var bulge: Vector2 = hand + Vector2(radius, 0.0)
		var pts := PackedVector2Array()
		var steps := 8
		for i in range(steps + 1):
			var t: float = float(i) / float(steps)
			pts.append(top * (1.0 - t) * (1.0 - t) + bulge * (2.0 * (1.0 - t) * t) + bot * (t * t))
		draw_polyline(pts, Color(0.55, 0.40, 0.22), 1.5)
		draw_line(top, bot, Color(0.85, 0.78, 0.60), 1.0)
		return

	# Melee: a held bar pointing down and away from the body — the "big
	# weapon" tell is purely length/thickness scaling with weight.
	var length: float = clampf(8.0 + weight * 3.0, 8.0, 26.0)
	var width: float  = clampf(2.0 + weight * 0.5, 2.0, 6.0)
	var tip: Vector2  = hand + Vector2(0.6, 0.8).normalized() * length
	draw_line(hand, tip, Color(0.80, 0.82, 0.86), width)
