extends NPC
# Pawn shop — across from the inn in the upper ditch.
# Name, dialogue, and shop inventory TBD.

const SHOP_ITEMS: Array = []  # TBD

func _ready() -> void:
	grid_cell             = Vector2i(62, 21)
	interaction_reach     = 2
	stat_strength         = 5
	stat_dexterity        = 6
	stat_agility          = 5
	stat_constitution     = 5
	stat_willpower        = 6
	stat_perception       = 8
	level                 = 2
	skills["melee"]       = 9
	skills["dodge"]       = 8
	equipment["hand_1"]   = DataManager.get_item("knife")
	equipment["torso"]    = DataManager.get_item("leather_vest")
	equipment["legs"]     = DataManager.get_item("work_trousers")
	_attack_weapon        = DataManager.get_item("knife")
	pocket_items          = [DataManager.get_item("coin"), DataManager.get_item("coin"), DataManager.get_item("coin")]
	drops_loot            = true
	super._ready()
	entity_name           = "Shopkeeper"
