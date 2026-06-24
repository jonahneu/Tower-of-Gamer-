extends NPC
# The Scribe — runs a booth in the lower market, west wall.
# Sells inscribed talismans, does courier work, intro to the pictographic religion.

const SHOP_ITEMS: Array = [
	{"id": "cloth_scripture_armband", "price": 8},
	{"id": "ink",            "price": 1},
	{"id": "blank_talisman", "price": 1},
]

func _ready() -> void:
	grid_cell             = Vector2i(9, 45)
	interaction_reach     = 2
	stat_strength         = 4
	stat_dexterity        = 6
	stat_agility          = 5
	stat_constitution     = 4
	stat_willpower        = 6
	stat_perception       = 6
	skills["melee"]       = 3
	skills["dodge"]       = 4
	equipment["torso"]    = DataManager.get_item("tunic")
	pocket_items          = [DataManager.get_item("ink"), DataManager.get_item("coin")]
	drops_loot            = true
	super._ready()
	entity_name = "Scribe"
	EventBus.smithing_pick_made.connect(_on_scripture_pick_made)
	_update_dialogue()

func get_interaction_options() -> Array:
	_update_dialogue()
	return super.get_interaction_options()

func _update_dialogue() -> void:
	var pd: Dictionary = GameManager.player_data
	var reopen := func():
		EventBus.dialogue_closed.connect(func(_e): _reopen_dialogue(), CONNECT_ONE_SHOT)
	var open_shop := func():
		EventBus.dialogue_closed.connect(
			func(_e): EventBus.open_shop_ui.emit(self, SHOP_ITEMS, [], Callable()), CONNECT_ONE_SHOT)

	var has_delivery_quest: bool = GameManager.has_quest_thread("scribe_delivery", "deliver_scripture")
	var already_taught: bool     = pd.get("scribe_taught_basic_talisman", false)
	var post_craft_pending: bool = pd.get("scribe_post_craft_pending", false)
	var asked_protection: bool   = pd.get("scribe_asked_protection", false)

	dialogue_text = "A lean figure sits behind a low counter covered in neat stacks of clay tablets and rolled documents. She looks up from the one she's working on."

	# Post-craft dialogue: fires once after the player closes the crafting menu
	if post_craft_pending:
		pd["scribe_post_craft_pending"] = false
		dialogue_text = "The scribe looks over at the talisman."
		dialogue_options = [
			{
				"label":    "I made one.",
				"response": "Well done. Any scripture you learn to transcribe can be turned into a talisman. Most are worn, and can also be affixed to clothing and armor, providing a constant effect. Others are invoked a single time to produce an effect — though those are less common.",
				"next_options": [
					{
						"label":    "Can you teach me more?",
						"response": "If you were able to do that easily then yes, I think you'll be able to learn more.",
						"closes": true,
						"action": func():
							pd["scribe_pick_pending"] = true
							EventBus.dialogue_closed.connect(func(_e):
								EventBus.open_smithing_pick_ui.emit([
									{
										"id":          "blast_tag",
										"name":        "Blast Tag",
										"description": "A throwable seal inscribed with volatile scripture. Plant it, then spend SP to detonate it — area physical and fire damage.",
										"recipe_id":   "blast_tag_craft",
									},
									{
										"id":          "enchanted_fist_wraps",
										"name":        "Enchanted Fist Wraps",
										"description": "Wraps that project unarmed strikes to range and add bonus physical damage. Uses melee skill and counts as unarmed for all feats.",
										"recipe_id":   "enchanted_fist_wraps_craft",
									},
								])
							, CONNECT_ONE_SHOT),
					},
					{"label": "Understood. Thank you.", "closes": true},
				],
			},
		]
		return

	# ── Teaching branch ───────────────────────────────────────────────────────
	var skills: Dictionary = pd.get("skills", {})
	var occultism: int = int(skills.get("occultism", 0))
	var sleight: int   = int(skills.get("sleight_of_hand", 0))
	var can_learn: bool = occultism >= 10 or sleight >= 20

	var inv: Array = pd.get("inventory", [])
	var coin_count: int = 0
	for item in inv:
		if item.get("id", "") == "coin":
			coin_count += 1
	var can_afford: bool = coin_count >= 4

	var teach_talisman := func():
		var player_inv: Array = pd.get("inventory", [])
		var removed: int = 0
		for i in range(player_inv.size() - 1, -1, -1):
			if player_inv[i].get("id", "") == "coin":
				player_inv.remove_at(i)
				removed += 1
				if removed >= 4:
					break
		player_inv.append(DataManager.get_item("blank_talisman"))
		player_inv.append(DataManager.get_item("ink"))
		var known_scripture: Array = pd.get("known_scripture_recipes", [])
		if "basic_protective_talisman_craft" not in known_scripture:
			known_scripture.append("basic_protective_talisman_craft")
		pd["known_scripture_recipes"] = known_scripture
		pd["inventory"] = player_inv
		pd["scribe_taught_basic_talisman"] = true
		pd["scribe_post_craft_pending"] = false
		EventBus.dialogue_closed.connect(func(_e):
			EventBus.open_crafting_ui.emit(self)
			EventBus.crafting_ui_closed.connect(func(opener):
				if opener == self:
					pd["scribe_post_craft_pending"] = true
					_reopen_dialogue()
			, CONNECT_ONE_SHOT)
		, CONNECT_ONE_SHOT)

	var learn_next_options: Array = [
		{
			"label":    "Yes, teach me.  [4 coins]  [Occultism 10 or Sleight of Hand 20]",
			"disabled": not (can_afford and can_learn),
			"response": "Good. Here — take this blank talisman and ink. Open your crafting menu, find the Scriptures tab, and follow what I have shown you.",
			"closes": true,
			"action": teach_talisman,
		},
		{"label": "Maybe another time.", "closes": true, "action": reopen},
	]

	# ── Delivery quest ────────────────────────────────────────────────────────
	var accept_delivery := func():
		if not has_delivery_quest:
			var player_inv: Array = pd.get("inventory", [])
			player_inv.append(DataManager.get_item("transcribed_scripture"))
			pd["inventory"] = player_inv
			EventBus.inventory_changed.emit()
			GameManager.add_quest({
				"id":      "scribe_delivery",
				"title":   "Scripture Delivery",
				"summary": "Deliver transcribed scripture for the scribe to a customer in the residential district.",
			})
			GameManager.add_quest_thread("scribe_delivery", {
				"id":     "deliver_scripture",
				"title":  "Find the customer in the north east corner of the residential district.",
			})
	var work_next_options: Array = [
		{
			"label":    "I will get it to its recipient.",
			"response": "Ok, he lives in the north east corner of the residential district, his name is [TBD]. He will pay you upon arrival.",
			"closes": true,
			"action": accept_delivery,
		},
		{"label": "Not right now.", "closes": true, "action": reopen},
	]

	# ── Build top-level options ───────────────────────────────────────────────
	dialogue_options = []

	# Shop — always available
	dialogue_options.append({
		"label":    "What do you sell?",
		"response": "I am an apprentice scribe of the [TBD] and I sell simple talismans. I can only know the basics of the [TBD holy scripts], but it is enough to provide aid to people. Take a look.",
		"next_options": [
			{"label": "Show me.",            "closes": true, "action": open_shop},
			{"label": "Maybe another time.", "closes": true, "action": reopen},
		],
	})

	# Dream question — appears once the dream points the player back here
	if GameManager.has_quest_thread("the_dream", "dream_ask_scribe") \
			and not pd.get("scribe_dream_asked", false):
		dialogue_options.append({
			"label":  "I had a dream I wanted to ask you about.",
			"action": func():
				pd["scribe_dream_asked"] = true
				GameManager.update_quest_thread("the_dream", "dream_ask_scribe",
					"The scribe pointed me to an older Library in the Undercity ruins.")
				GameManager.complete_quest_thread("the_dream", "dream_ask_scribe"),
			"response": "Hmm, I only have vague ideas what that could be referring to. You might be able to learn more if you went to the Library in the Upper City, but... *He looks you over* I don't think you'd be allowed in the upper city. It sounds like your vision was related to the Undercity ruins, and the spirits that come from its depths. I have heard, there is another Library down there. It is from the distant past, when The Undercity was just The City. You might be able to find some of the answers you seek there.",
			"next_options": [{"label": "Continue", "closes": true, "action": reopen}],
		})

	# Spiritual protection exposition — first time only, hidden once asked or taught
	if not asked_protection and not already_taught:
		dialogue_options.append({
			"label":    "Do you sell spiritual protection?",
			"action":   func():
				pd["scribe_asked_protection"] = true
				GameManager.add_faction_contact("scribe")
				GameManager.add_note({
					"id":    "the_scribes",
					"title": "The Scribes",
					"body":  "Becoming a scribe is as much a spiritual practice as a craft. Enlightenment and great power can be reached through transcribing the holy scripts. Most talismans are worn continuously for a constant effect; rarer ones are invoked once for a single powerful effect. The apprenticeship is itself a form of devotion.",
				}, 8),
			"response": "Of course, I have been studying the holy texts, and can copy enough of them to inscribe protective talismans.",
			"next_options": [
				{
					"label":    "Holy texts?",
					"response": "Yes, becoming a scribe is as much a spiritual practice as it is one of skill. Enlightenment and great powers can be reached through transcribing the holy scripts. It takes great diligence to reach the understanding of a master, so I practice and in the meantime, make some coin with my skills.",
					"next_options": [
						{
							"label":    "Could you teach me the basics?",
							"response": "Of course, but it is not easy. Pay me 4 coins and I will provide the ink and paper, and show you the scripture for a simple protective talisman.",
							"next_options": learn_next_options,
						},
						{"label": "Interesting.", "closes": true, "action": reopen},
					],
				},
				{"label": "Show me.", "closes": true, "action": open_shop},
				{"label": "Maybe another time.", "closes": true, "action": reopen},
			],
		})

	# Recipe learning — available after exposition, until learned
	if asked_protection and not already_taught:
		dialogue_options.append({
			"label":    "Could you teach me to inscribe a talisman?",
			"response": "Of course, but it is not easy. Pay me 4 coins and I will provide the ink and paper, and show you the scripture for a simple protective talisman.",
			"next_options": learn_next_options,
		})

	# Work — disappears once quest is accepted
	if not has_delivery_quest:
		dialogue_options.append({
			"label":    "Do you have any work?",
			"response": "Yes, I have some transcribed scripture I need carried to a customer in the residential district, can I trust you with it?",
			"next_options": work_next_options,
		})

	dialogue_options.append({"label": "Goodbye.", "response": "Safe travels.", "closes": true})

func _on_scripture_pick_made(pick_id: String) -> void:
	var pd: Dictionary = GameManager.player_data
	if not pd.get("scribe_pick_pending", false):
		return
	pd["scribe_pick_pending"] = false
	var recipe_map: Dictionary = {
		"blast_tag":           "blast_tag_craft",
		"enchanted_fist_wraps": "enchanted_fist_wraps_craft",
	}
	var recipe_id: String = recipe_map.get(pick_id, "")
	if recipe_id == "":
		return
	var known: Array = pd.get("known_scripture_recipes", [])
	if recipe_id not in known:
		known.append(recipe_id)
	pd["known_scripture_recipes"] = known
	# Give materials for the first craft
	var inv: Array = pd.get("inventory", [])
	inv.append(DataManager.get_item("blank_talisman"))
	inv.append(DataManager.get_item("ink"))
	pd["inventory"] = inv
	EventBus.inventory_changed.emit()
	EventBus.dialogue_closed.connect(func(_e): EventBus.open_crafting_ui.emit(self), CONNECT_ONE_SHOT)

func _reopen_dialogue() -> void:
	_update_dialogue()
	EventBus.interaction_triggered.emit(self, "talk")
