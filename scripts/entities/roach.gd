extends Enemy
class_name Roach

# ── Baseline roach stats (user-specified) ──────────────────────────────────────
# CON 5 (default) → base max_hp = 5*(5+modifier(5))*(level(1)+1) = 50, hp_flat_bonus = -46 → max_hp = 4
# AGI 4  → max_ap = 4, max_mp = 4
# STR 5 (default, modifier 0) → Bite damage is exactly the stated "1d2", no bonus
# Melee 8, Dodge 0 (skills, not modifiers)
# aggro_range cut down from the Enemy base default (26) — still a forced,
# guaranteed fight once the combat tutorial gate opens (tutorial_gate_id in
# the scene file), but the player should have to walk up into the room a
# little first rather than triggering it from clear across the corridor.

# Per-instance override: 3 of the 4 spawned roaches keep beast_type "roach" (no
# CARVE_TABLES entry → carving always yields nothing). The one roach meant to
# guarantee a meat drop is set to "giant_roach" in the scene file, which has its
# own CARVE_TABLES entry (see data_manager.gd) with min_roll 1 (always passes).
@export var beast_type_id: String = "roach"

func _ready() -> void:
	entity_name       = "Giant Roach" if beast_type_id == "giant_roach" else "Roach"
	beast_type        = beast_type_id
	respawns          = false
	xp_value          = 4
	enemy_level       = 1
	stat_strength     = 5
	stat_dexterity    = 5
	stat_agility      = 4
	stat_constitution = 5
	hp_flat_bonus     = -46  # → max_hp = 4
	stat_intelligence = 3
	aggro_range       = 10

	skills["melee"] = 8
	skills["dodge"] = 0

	wander_radius = 3

	sprite_w     = 26
	sprite_h     = 14
	sprite_color = Color(0.30, 0.22, 0.14)

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
