extends Enemy
class_name Coyote

# ── Baseline coyote stats ─────────────────────────────────────────────────────
# CON 5  → base max_hp = 50, hp_flat_bonus = -30 → max_hp = 20
# CON 5 (mod 0) keeps bleed chance at 60% base (vs 84% with CON 2)
# AGI 6  → max_ap = 6, max_mp = 12 (mp = agility * 2)
# STR/DEX all 5 (mod 0); AGI no longer governs dodge (DEX does)
# Melee 20 → effective 20.0; Dodge 20 → effective 20.0 (DEX mod 0)
# Innate armor: 1 flat + 5% physical damage reduction

func _ready() -> void:
	# ── Set stats before super._ready() calls init_hp() ──────────────────────
	entity_name       = "Coyote"
	beast_type        = "coyote"
	aggro_range       = 16
	respawns          = true
	xp_value          = 40
	enemy_level       = 1
	stat_strength     = 5
	stat_dexterity    = 5
	stat_agility      = 6   # AP and MP = 6
	stat_constitution = 5   # base 50 HP
	hp_flat_bonus     = -30 # → max_hp = 20
	stat_intelligence = 5

	skills["melee"] = 20
	skills["dodge"] = 20

	innate_defense_flat = 1
	innate_defense_pct  = 0.10

	# ── Sprite ────────────────────────────────────────────────────────────────
	sprite_w     = 40
	sprite_h     = 20
	sprite_color = Color(0.76, 0.66, 0.47)   # sandy tan

	# ── Bite weapon ───────────────────────────────────────────────────────────
	# 1d3 damage, costs 1 AP, governed by STR (modifier 0),
	# has bleed chance on hit.
	_attack_weapon = {
		"name":        "Bite",
		"type":        "weapon",
		"damage":      "1d3",
		"ap_cost":     1,
		"skill":       "melee",
		"governing":   ["strength"],
		"damage_type": "physical",
		"properties":  ["bleed"],
	}

	super._ready()
