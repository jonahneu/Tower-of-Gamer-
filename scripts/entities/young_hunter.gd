extends NPC
# Young Hunter — sits by a fire on the northern riverbank.
# No dialogue yet; placeholder until designed.

func _ready() -> void:
	grid_cell             = Vector2i(27, 36)
	stat_strength         = 6
	stat_dexterity        = 6
	stat_agility          = 6
	stat_constitution     = 6
	stat_willpower        = 5
	stat_perception       = 6
	skills["melee"]       = 7
	skills["dodge"]       = 5
	equipment["hand_1"]   = DataManager.get_item("knife")
	equipment["torso"]    = DataManager.get_item("tunic")
	_attack_weapon        = DataManager.get_item("knife")
	drops_loot            = true
	super._ready()
	entity_name = "Young Hunter"
	dialogue_text = ""
	is_interactable = false
	visible = true
