extends Enemy
class_name BanditLeader

# Leader of the bandit camp. Placeholder stats — one level above the rank-and-
# file Bandit/BanditArcher, with notably higher dex/agility per the user's
# direction. Full design (feats, equipment, weapon style) still TBD; stats are
# pending a full review pass once the camp layout is finalized.

func _ready() -> void:
	entity_name       = "Bandit Leader"
	beast_type        = "human"
	is_human          = true
	aggro_range       = 16
	wander_radius     = 2
	respawns          = false
	xp_value          = 70
	enemy_level       = 4
	level             = 4

	stat_strength     = 8
	stat_dexterity    = 10
	stat_agility      = 8
	stat_constitution = 5
	stat_intelligence = 5
	stat_willpower    = 6
	stat_perception   = 7

	skills["melee"] = 32
	skills["dodge"] = 30

	sprite_w     = 28
	sprite_h     = 46
	sprite_color = Color(0.46, 0.20, 0.16)   # marked out from the rank and file

	var poisoned_scimitar: Dictionary = DataManager.get_item("scimitar")
	poisoned_scimitar["poisoned"]     = true   # same flag the player's Basic Lingering Poison item sets
	equipment["hand_1"]               = poisoned_scimitar
	equipment["torso"]                = DataManager.get_item("leather_vest")
	_attack_weapon                    = poisoned_scimitar
	feats.append("brutal")
	feats.append("bloodletting")
	loot_item_ids = ["bandit_leader_head"]

	super._ready()
