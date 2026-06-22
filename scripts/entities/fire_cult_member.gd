extends NPC
# Fire Cult Member — sits in the Lower Ditch openly practicing a looked-down-upon religion.
# Supplies flame accelerant to the smith on order.
# Name TBD; fire cult name TBD. Replace "Ember" and "[fire cult name]" when finalized.

func _ready() -> void:
	grid_cell             = Vector2i(20, 45)
	stat_strength         = 6
	stat_dexterity        = 6
	stat_agility          = 6
	stat_constitution     = 6
	stat_willpower        = 7
	stat_perception       = 6
	skills["melee"]       = 7
	skills["dodge"]       = 5
	equipment["torso"]    = DataManager.get_item("tunic")
	pocket_items          = [DataManager.get_item("coin"), DataManager.get_item("coin")]
	drops_loot            = true
	super._ready()
	entity_name = "Fire Cultist"   # TODO: replace with final name
	_update_dialogue()

func get_interaction_options() -> Array:
	_update_dialogue()
	return super.get_interaction_options()

func _update_dialogue() -> void:
	var pd: Dictionary = GameManager.player_data
	var reopen := func():
		EventBus.dialogue_closed.connect(func(_e): _reopen_dialogue(), CONNECT_ONE_SHOT)

	dialogue_text = "A lean figure sits cross-legged on the ground beside a small clay brazier. Their hands and forearms carry small deliberate scars in a regular pattern. They look up at you without concern."

	var options: Array = []

	# ── Invoice exchange — core quest mechanic ────────────────────────────────
	if _has_item("smith_invoice") and not pd.get("fire_cult_invoice_paid", false):
		options.append({
			"label":    "I have an invoice from the smith.",
			"action":   func():
				_remove_item("smith_invoice")
				var inv: Array = pd.get("inventory", [])
				inv.append(DataManager.get_item("flame_accelerant"))
				pd["inventory"] = inv
				pd["fire_cult_invoice_paid"] = true,
			"response": "*They glance at the clay tablet and set it aside.* Standard order. Here. *They produce a sealed clay jar from a satchel and hand it over.* Tell him the seal holds better if he warms the jar first.",
			"next_options": [{"label": "I will. Thank you.", "closes": true, "action": reopen}],
		})

	# ── Got any work ──────────────────────────────────────────────────────────
	if not pd.get("fire_cult_member_asked_work", false):
		options.append({
			"label":    "Got any work?",
			"action":   func(): pd["fire_cult_member_asked_work"] = true,
			"response": "No.",
			"closes":   true,
		})

	# ── Spiritual protection ──────────────────────────────────────────────────
	if not pd.get("fire_cult_member_asked_protection", false):
		options.append({
			"label":    "Do you know where I can buy spiritual protection?",
			"action":   func():
				pd["fire_cult_member_asked_protection"] = true
				GameManager.add_faction_contact("fire_cult_member"),
			"response": "Haha, so you're Godless? You know there are ways for a Godless to find protection, and a place in this world, without relying on the Smiths and the Scribes. Others supplicate themselves to Idols, Spirits, and Gods for protection. That is not true power. True power comes from within. Look within and stoke your own spirit until it becomes a great flame. Then you will never need to seek help from another again.",
			"next_options": [
				{
					"label":    "That makes no sense, the King's God protects the city, and personal Gods protect one's home. You can't protect yourself from the spirits out here without help.",
					"closes":   true,
				},
				{
					"label":    "How would I go about stoking this flame? I need protection to sleep tonight.",
					"action":   func():
						pd["fire_cult_referred_to_elder"] = true
						GameManager.add_note({
							"id":    "the_fire_cult",
							"title": "The Fire Cult",
							"body":  "The Fire Cult teaches that godlessness is an opportunity, not only a loss. True power does not come from supplicating yourself to idols or spirits — it comes from within. Stoke your own spirit until it becomes a great flame and you will need no external protection. The cult operates in the Lower Ditch; a cultist there can point you to an elder across the ditch for instruction.",
						}, 8)
						GameManager.add_quest_thread("find_spiritual_protection", {
							"id":          "inner_flame_path",
							"title":       "Inner Flame",
							"description": "A fire cultist in the Lower Ditch told me to seek out an elder whose hut is directly across the ditch. He may be able to show me another way to protect myself.",
							"updates":     [],
							"completed":   false,
						}),
					"response": "Go talk to [Name TBD], his hut is directly across the ditch from here.",
					"next_options": [{"label": "I will.", "closes": true, "action": reopen}],
				},
			],
		})

	options.append({"label": "Goodbye.", "closes": true})
	dialogue_options = options

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

func _reopen_dialogue() -> void:
	_update_dialogue()
	EventBus.interaction_triggered.emit(self, "talk")
