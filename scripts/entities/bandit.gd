extends Enemy
class_name Bandit

# Level 3 melee bandit leader. High melee and dodge, shortsword, and the
# Brutal feat (ignores 20% of the target's armor) — meant to be the closest
# of the ambush group to the player's expected approach path.

func _ready() -> void:
	entity_name       = "Bandit"
	beast_type        = "human"
	is_human          = true
	aggro_range       = 16
	wander_radius     = 2
	respawns          = false
	xp_value          = 45
	enemy_level       = 3
	level             = 3

	stat_strength     = 8
	stat_dexterity    = 7
	stat_agility      = 6
	stat_constitution = 6
	stat_intelligence = 5
	stat_willpower    = 6
	stat_perception   = 6

	skills["melee"] = 28
	skills["dodge"] = 22

	sprite_w     = 26
	sprite_h     = 44
	sprite_color = Color(0.32, 0.24, 0.20)   # dark worn leather

	_attack_weapon = DataManager.get_item("shortsword")
	feats.append("brutal")

	super._ready()
