extends Enemy
class_name BanditSkirmisher

# Level 3 shield-and-shortsword bandit. Mobile and hard to pin down — good
# melee and dodge, Runner feat to keep moving once MP runs dry.

func _ready() -> void:
	entity_name       = "Bandit Skirmisher"
	beast_type        = "human"
	is_human          = true
	aggro_range       = 16
	wander_radius     = 2
	respawns          = false
	xp_value          = 45
	enemy_level       = 3
	level             = 3

	stat_strength     = 7
	stat_dexterity    = 7
	stat_agility      = 8
	stat_constitution = 6
	stat_intelligence = 5
	stat_willpower    = 6
	stat_perception   = 12

	skills["melee"] = 28
	skills["dodge"] = 26

	sprite_w     = 26
	sprite_h     = 44
	sprite_color = Color(0.32, 0.24, 0.20)

	equipment["hand_1"]   = DataManager.get_item("shortsword")
	equipment["hand_2"]   = DataManager.get_item("hide_shield")
	_attack_weapon        = DataManager.get_item("shortsword")
	feats.append("runner")

	super._ready()
