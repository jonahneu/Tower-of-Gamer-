extends NPC
# The Taskmaster — releases the player; fires the opening scene automatically.

func _ready() -> void:
	if GameManager.player_data.get("taskmaster_left", false):
		queue_free()
		return
	grid_cell             = Vector2i(18, 7)
	stat_strength         = 8
	stat_dexterity        = 5
	stat_agility          = 5
	stat_constitution     = 6
	stat_willpower        = 8
	stat_perception       = 7
	level                 = 3
	skills["melee"]       = 24
	skills["dodge"]       = 10
	skills["intimidate"]  = 16
	equipment["hand_1"]   = DataManager.get_item("whip")
	equipment["torso"]    = DataManager.get_item("tunic")
	equipment["legs"]     = DataManager.get_item("work_trousers")
	_attack_weapon        = DataManager.get_item("whip")
	pocket_items          = [DataManager.get_item("coin"), DataManager.get_item("coin")]
	drops_loot            = true
	super._ready()
	entity_name = "The Taskmaster"
	var player_name: String = GameManager.player_data.get("name", "stranger")
	dialogue_text = "Well %s, you're finally free. We've worked you long enough. Go make something of your life." % player_name
	dialogue_options = [
		{
			"label": "[Say nothing]",
			"response": "Now that you're no longer our slave, you've lost your protection from our household deity. I guess you probably lost your own family's god sometime around when you became a slave. Did you even have a family? Don't actually answer that. Well, good luck getting to sleep tonight — the spirits are especially aggressive here around the ditch.",
			"next_options": [
				{
					"label": "[Leave]", "response": "", "closes": true,
					"action": func(): GameManager.add_note({
						"id":    "spirits_and_gods",
						"title": "Spirits and the Gods of the City",
						"body":  "Household gods protect those who serve them — a family's god shelters its members, and a slaveholder's deity extends that protection to those they own. Without a god, the spirits can sense it before you do. In the Ditch, they are especially dangerous after dark.",
					}, 5),
				},
			],
		},
	]
	EventBus.player_rested.connect(_on_player_rested)
	call_deferred("_open_intro_dialogue")

func _open_intro_dialogue() -> void:
	if GameManager.player_data.get("taskmaster_intro_done", false):
		return
	GameManager.player_data["taskmaster_intro_done"] = true
	EventBus.interaction_triggered.emit(self, "talk")

func _on_player_rested() -> void:
	GameManager.player_data["taskmaster_left"] = true
	GameManager.remove_encounter(GameManager.world_layer, GameManager.world_pos, entity_name)
	queue_free()
