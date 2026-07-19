extends Enemy
class_name Rat

# ── Baseline rat stats — 60% of Coyote (coyote.gd), rounded ───────────────────
# Coyote: max_hp 20 (CON 5, hp_flat_bonus -30), AGI 6, melee 20, dodge 20,
#         damage 1d3, aggro_range 16, innate_defense_flat 1, innate_defense_pct 0.10,
#         xp_value 40, "Bite" governed by strength with a "bleed" property.
#
# Rat (60%), rounding shown per stat:
#   max_hp:      20 * 0.6 = 12        → CON stays default 5, hp_flat_bonus = 12 - 50 = -38
#   agility:     6  * 0.6 = 3.6       → rounded up to 4
#   melee:       20 * 0.6 = 12
#   dodge:       20 * 0.6 = 12
#   damage:      1d3 (avg 2) * 0.6 = avg 1.2 → closest simple die is 1d2 (avg 1.5, an
#                approximation — flagged, exact 60% isn't expressible as a clean die)
#   aggro_range: cut well below the 60%-of-Coyote formula (9.6→10) — a rat is
#                supposed to be a tight, sneakable-around tutorial encounter,
#                not something that spots the player from across the room
#   xp_value:    40 * 0.6 = 24
#   innate_defense_flat/pct: dropped to 0 (default) rather than carrying a fractional
#                armor value — a "weaker, unarmored" tutorial mob reads cleaner than
#                0.6 flat / 0.06 pct. Judgment call, flagged for review.
#   "bleed" property: dropped — not part of the requested stat scaling, and unnecessary
#                complexity for a basic early mob. Judgment call, flagged for review.

func _ready() -> void:
	entity_name       = "Rat"
	beast_type        = "rat"
	aggro_range       = 5
	respawns          = false
	xp_value          = 24
	enemy_level       = 1
	stat_strength     = 5
	stat_dexterity    = 5
	stat_agility      = 4
	stat_constitution = 5
	hp_flat_bonus     = -38  # → max_hp = 12
	stat_intelligence = 4

	skills["melee"] = 12
	skills["dodge"] = 12

	wander_radius = 4

	sprite_w     = 34
	sprite_h     = 16
	sprite_color = Color(0.34, 0.30, 0.27)

	_attack_weapon = {
		"name":        "Bite",
		"type":        "weapon",
		"damage":      "1d2",
		"ap_cost":     1,
		"skill":       "melee",
		"governing":   ["strength"],
		"damage_type": "physical",
		"properties":  [],
	}

	super._ready()
