extends NPC

func _ready() -> void:
	grid_cell             = Vector2i(67, 24)
	stat_strength         = 5
	stat_dexterity        = 5
	stat_agility          = 5
	stat_constitution     = 5
	stat_willpower        = 5
	stat_perception       = 5
	skills["melee"]       = 3
	skills["dodge"]       = 2
	equipment["torso"]    = DataManager.get_item("tunic")
	pocket_items          = [DataManager.get_item("coin"), DataManager.get_item("coin"),
							DataManager.get_item("coin"), DataManager.get_item("coin"),
							DataManager.get_item("coin")]
	drops_loot            = true
	super._ready()
	entity_name = "Merchant"   # [TBD] proper name
	_update_dialogue()

func get_interaction_options() -> Array:
	_update_dialogue()
	return super.get_interaction_options()

func _update_dialogue() -> void:
	var pd: Dictionary = GameManager.player_data
	var has_quest: bool = GameManager.has_quest_thread("scribe_delivery", "deliver_scripture")
	var delivered: bool = pd.get("scripture_delivered", false)
	var has_scripture: bool = _has_item("transcribed_scripture")

	dialogue_text = "[TBD]"

	if has_quest and not delivered and has_scripture:
		var deliver := func():
			_remove_item("transcribed_scripture")
			pd["scripture_delivered"] = true
			GameManager.complete_quest_thread("scribe_delivery", "deliver_scripture")
			GameManager.complete_quest("scribe_delivery")
			var inv: Array = pd.get("inventory", [])
			for _i in range(10):
				inv.append(DataManager.get_item("coin"))
			pd["inventory"] = inv
			EventBus.inventory_changed.emit()

		dialogue_options = [
			{
				"label":    "I have a delivery from the Scribe.",
				"response": "[TBD]",
				"closes":   true,
				"action":   deliver,
			},
			{"label": "Goodbye.", "response": "[TBD]", "closes": true},
		]
	else:
		dialogue_options = [
			{"label": "Goodbye.", "response": "[TBD]", "closes": true},
		]

func _reopen_dialogue() -> void:
	_update_dialogue()
	EventBus.interaction_triggered.emit(self, "talk")

func _has_item(item_id: String) -> bool:
	for item in GameManager.player_data.get("inventory", []):
		if item.get("id", "") == item_id:
			return true
	return false

func _remove_item(item_id: String) -> void:
	var inv: Array = GameManager.player_data.get("inventory", [])
	for i in range(inv.size()):
		if inv[i].get("id", "") == item_id:
			inv.remove_at(i)
			break
	GameManager.player_data["inventory"] = inv
