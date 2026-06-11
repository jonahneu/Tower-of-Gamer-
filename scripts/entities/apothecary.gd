extends NPC
# The Apothecary — operates out of the small building on the west side of the ditch.

func _ready() -> void:
	grid_cell             = Vector2i(9, 33)
	stat_strength         = 4
	stat_dexterity        = 9
	stat_agility          = 6
	stat_constitution     = 8
	stat_willpower        = 6
	stat_perception       = 8
	level                 = 3
	skills["melee"]       = 24
	skills["ranged"]      = 20
	skills["dodge"]       = 12
	var poisoned_knife: Dictionary = DataManager.get_item("knife")
	poisoned_knife["poisoned"]     = true
	poisoned_knife["name"]         = "Apothecary's Knife"
	poisoned_knife["description"]  = "A short blade with a fresh coat of lingering poison on the edge."
	equipment["hand_1"]   = poisoned_knife
	equipment["torso"]    = DataManager.get_item("tunic")
	_attack_weapon        = poisoned_knife
	# Smoke bomb: stealable and usable in combat (NPC combat use pending ranged/item AI)
	var smoke: Dictionary = DataManager.get_item("smoke_bomb")
	pocket_items          = [DataManager.get_item("dusk_flower"), smoke]
	inventory.append(smoke.duplicate())
	drops_loot            = true
	super._ready()
	entity_name = "Apothecary"
	_update_dialogue()

func get_interaction_options() -> Array:
	_update_dialogue()
	return super.get_interaction_options()

func _update_dialogue() -> void:
	var pd: Dictionary = GameManager.player_data
	if not pd.get("apothecary_intro_seen", false):
		dialogue_text = "You see a thin individual wrapped tightly in robes and shawls, only half poking out of the shadows. You can only distinguish her as a woman when you hear her voice as she steps out of the shadows to address you."
		dialogue_options = [
			{
				"label":    "Continue",
				"response": "Looking for anything in particular?",
				"action":   func(): pd["apothecary_intro_seen"] = true,
				"next_options": _build_options(),
			},
		]
	else:
		dialogue_text    = "Looking for anything in particular?"
		dialogue_options = _build_options()

func _build_options() -> Array:
	var pd: Dictionary = GameManager.player_data
	var reopen := func():
		EventBus.dialogue_closed.connect(func(_e): _reopen_dialogue(), CONNECT_ONE_SHOT)

	var offer_vial := func():
		pd["apothecary_vial_offered"] = true
		GameManager.add_faction_contact("apothecary")
		GameManager.add_quest_thread("find_spiritual_protection", {
			"id":          "apothecary_vial_path",
			"title":       "The Apothecary",
			"description": "The apothecary sells something that can protect me for a few nights at a time.",
			"updates":     [],
			"completed":   false,
		})

	var accept_job := func():
		pd["apothecary_job_given"] = true
		var inv: Array = pd.get("inventory", [])
		inv.append(DataManager.get_item("small_pouch"))
		pd["inventory"] = inv
		GameManager.add_quest({
			"id":          "apothecary_delivery",
			"title":       "Deliver the apothecary's package",
			"description": "The apothecary asked you to deliver a small pouch to the innkeeper at the inn next door. Three coins upon delivery.",
			"threads":     [],
			"completed":   false,
		})

	var options: Array = []

	# ── Dream question — appears once the dream points the player back here ──
	if GameManager.has_quest_thread("the_dream", "dream_ask_apothecary") \
			and not pd.get("apothecary_dream_asked", false):
		options.append({
			"label":  "I had a dream I wanted to ask you about.",
			"action": func():
				pd["apothecary_dream_asked"] = true
				GameManager.complete_quest_thread("the_dream", "dream_ask_apothecary"),
			"response": "[DIALOGUE TBD — Apothecary's response when asked about the dream]",
			"next_options": [{"label": "Continue", "closes": true, "action": reopen}],
		})

	# ── Talisman question — disappears once asked ─────────────────────────────
	if not pd.get("apothecary_talisman_asked", false):
		options.append({
			"label":    "Do you sell any protective talismans?",
			"action":   func(): pd["apothecary_talisman_asked"] = true,
			"response": "No, you can go to The Scribes in The Temple District, or The Smiths in The Market for those. Or you could talk to the old hunter — he's sitting just outside the city walls, where the ancient drainage pipe that makes up this here Ditch used to drain out towards the river. All dried up now of course. He's an old timer who comes back to The Ditch in between his hunts in the deep desert and undercity. He could teach you about making talismans from beasts.",
			"next_options": [
				{
					"label":    "Continue",
					"response": "If none of that suits your fancy, I do have something I'd sell you for pretty cheap if you have any money. *she produces a small dark green vial* Its pretty gross though, but it'll be much cheaper than any talisman anyone will sell you.",
					"action":   offer_vial,
					"next_options": [
						{"label": "Continue", "closes": true, "action": reopen},
					],
				},
			],
		})

	# ── What do you sell — always available ───────────────────────────────────
	var open_shop := func():
		EventBus.dialogue_closed.connect(
			func(_e): EventBus.open_shop_ui.emit(self, _build_shop_items(), [], 0, func(_item): pass),
			CONNECT_ONE_SHOT)
	options.append({
		"label":    "What do you sell?",
		"response": "Ingredients and brewed goods. Take a look.",
		"next_options": [
			{"label": "Browse.",             "closes": true, "action": open_shop},
			{"label": "Maybe another time.", "closes": true, "action": reopen},
		],
	})

	# ── Do you have any work — disappears once accepted ───────────────────────
	if not pd.get("apothecary_job_given", false):
		options.append({
			"label":    "Do you have any work?",
			"response": "Yes, I have an errand that needs running. Can you deliver this to the innkeeper at the inn next door? He will give you three coins payment upon arrival.",
			"next_options": [
				{
					"label":  "Ok.",
					"closes": true,
					"action": accept_job,
				},
				{
					"label":  "Not right now.",
					"closes": true,
					"action": reopen,
				},
			],
		})

	# ── Buy vial — once offered; limited to one per rest cycle ────────────────
	if pd.get("apothecary_vial_offered", false) and not pd.get("apothecary_recipe_fully_taught", false):
		var bought_this_cycle: bool = pd.get("apothecary_vial_bought_this_cycle", false)
		var buy_label: String = "Buy vial: 1 coin" if not bought_this_cycle else "Buy vial: 1 coin  (already purchased today)"
		# On the 2nd purchase, flow into the teaching offer
		var is_second_purchase: bool = pd.get("apothecary_vials_bought_count", 0) == 1 \
				and not pd.get("apothecary_teaching_offered", false) \
				and not pd.get("apothecary_recipe_fully_taught", false)
		if is_second_purchase:
			options.append({
				"label":    buy_label,
				"disabled": not _has_coin() or bought_this_cycle,
				"response": "You know, I could teach you to make it yourself.",
				"action":   func():
					_buy_vial()
					pd["apothecary_teaching_offered"] = true,
				"next_options": _build_teaching_offer_options(pd, reopen),
			})
		else:
			options.append({
				"label":    buy_label,
				"disabled": not _has_coin() or bought_this_cycle,
				"closes":   true,
				"action":   func(): _buy_vial(),
			})

	# ── Ingredient gathering — active once player said "sure" ─────────────────
	if pd.get("apothecary_recipe_accepted", false) \
			and not pd.get("apothecary_ingredients_delivered", false) \
			and not pd.get("apothecary_recipe_fully_taught", false):
		if _has_both_ingredients():
			options.append({
				"label":    "I have the ingredients.",
				"response": "Ok, we take extracts from both of these and then mix them under heat until they reduce into a single compound. From there you bottle it.",
				"action":   func():
					pd["apothecary_ingredients_delivered"] = true
					GameManager.add_xp(40),
				"next_options": [
					{
						"label":  "Continue",
						"closes": true,
						"action": func():
							EventBus.dialogue_closed.connect(func(_e):
								EventBus.open_crafting_ui.emit(self)
								EventBus.crafting_ui_closed.connect(func(_opener):
									_reopen_dialogue()
								, CONNECT_ONE_SHOT)
							, CONNECT_ONE_SHOT),
					},
				],
			})
		else:
			options.append({
				"label":    "I'm looking for the ingredients.",
				"response": "Still looking? You need a dusk flower from the river to the west, and a desert succulent from the desert to the south of the drain exit.",
				"next_options": [{"label": "Continue", "closes": true, "action": reopen}],
			})

	# ── Post-crafting check — appears after ingredients delivered ─────────────
	if pd.get("apothecary_ingredients_delivered", false) \
			and not pd.get("apothecary_recipe_fully_taught", false):
		if _has_player_made_vial():
			options.append({
				"label":    "Ok, I did it.",
				"action":   func(): pd["apothecary_recipe_fully_taught"] = true,
				"response": "Well done, not everyone would stomach drinking poison to keep safe. But we are not everyone. *She pokes a little ways out of the shadows and smiles at you, revealing her pale, gaunt face* Ah, right, I never told you what it was. Well it works right? A little bit of poison isn't always a bad thing. Tempers the body and mind. Poison can be lethal yes, but we can use that to our advantage if we can acclimate ourselves to its harm. *she recedes into the darkness after finishing*",
				"next_options": [
					{
						"label":  "Continue",
						"closes": true,
						"action": func():
							pd["apothecary_vial_name_revealed"] = true
							GameManager.add_note({
								"id":    "poison_as_protection",
								"title": "Poison as Protection",
								"body":  "The apothecary brews a dark green vial that acts as a short-term spirit ward — cheap and unconventional. The active ingredient is poison. A small amount is not always harmful; it tempers the body and mind. Acclimation to its harm can be used as protection. Recipe: dusk flower from the river, desert succulent from the plains.",
							}, 8)
							GameManager.add_xp(75)
							if not pd.has("known_alchemy_recipes"):
								pd["known_alchemy_recipes"] = []
							if "dark_vial_brew" not in pd["known_alchemy_recipes"]:
								pd["known_alchemy_recipes"].append("dark_vial_brew")
							GameManager.update_quest_thread("find_spiritual_protection", "apothecary_vial_path",
								"The apothecary taught me to brew the First Poison of Acclimation myself. I now have a permanent way to protect myself.")
							GameManager.complete_quest_thread("find_spiritual_protection", "apothecary_vial_path")
							GameManager.complete_quest("find_spiritual_protection"),
					},
				],
			})
		else:
			options.append({
				"label":    "I tried crafting it.",
				"response": "Hey, follow instructions if you want me to teach you. Come back when you're done.",
				"closes":   true,
			})

	# ── Gathering work — available once delivery is done, before accepted ────────
	if pd.get("innkeeper_delivery_done", false) \
			and not pd.get("apothecary_gathering_accepted", false):
		options.append({
			"label":    "Any more work?",
			"response": "If you're interested, I'd pay for coyote bones and desert succulents — five of each.",
			"next_options": [
				{
					"label":  "I'll keep an eye out.",
					"closes": true,
					"action": func():
						pd["apothecary_gathering_accepted"] = true
						reopen.call(),
				},
				{
					"label":  "Not right now.",
					"closes": true,
					"action": reopen,
				},
			],
		})

	# ── Turn in gathering work (two separate objectives) ─────────────────────
	if pd.get("apothecary_gathering_accepted", false) \
			and not pd.get("apothecary_gathering_completed", false):
		var bones_done: bool = pd.get("apothecary_bones_delivered", false)
		var succ_done:  bool = pd.get("apothecary_succulents_delivered", false)

		if not bones_done:
			if _count_item_by_material("bones", "coyote") >= 5:
				options.append({
					"label":    "I have the coyote bones.",
					"response": "Good. *She takes the bones and sets them aside.* These will keep me busy for a while. Three coins.",
					"action":   func():
						if pd.get("apothecary_bones_delivered", false): return
						_take_items_by_material("bones", "coyote", 5)
						var inv: Array = pd.get("inventory", [])
						for _c in range(3): inv.append(DataManager.get_item("coin"))
						pd["inventory"] = inv
						pd["apothecary_bones_delivered"] = true
						GameManager.add_xp(15)
						if pd.get("apothecary_succulents_delivered", false):
							pd["apothecary_gathering_completed"] = true,
					"next_options": [{"label": "Continue", "closes": true, "action": reopen}],
				})

		if not succ_done:
			if _count_item_by_id("desert_succulent") >= 5:
				options.append({
					"label":    "I have the desert succulents.",
					"response": "Those are useful. *She tucks them away carefully.* Three coins for your trouble.",
					"action":   func():
						if pd.get("apothecary_succulents_delivered", false): return
						_take_items_by_id("desert_succulent", 5)
						var inv: Array = pd.get("inventory", [])
						for _c in range(3): inv.append(DataManager.get_item("coin"))
						pd["inventory"] = inv
						pd["apothecary_succulents_delivered"] = true
						GameManager.add_xp(15)
						if pd.get("apothecary_bones_delivered", false):
							pd["apothecary_gathering_completed"] = true,
					"next_options": [{"label": "Continue", "closes": true, "action": reopen}],
				})

		if not bones_done or not succ_done:
			var bones_count: int = _count_item_by_material("bones", "coyote")
			var succ_count: int  = _count_item_by_id("desert_succulent")
			var parts: PackedStringArray = []
			if not bones_done: parts.append("%d/5 coyote bones" % bones_count)
			if not succ_done:  parts.append("%d/5 desert succulents" % succ_count)
			options.append({
				"label":    "Still gathering.",
				"response": "What do you have so far? %s." % "  |  ".join(parts),
				"next_options": [{"label": "Continue", "closes": true, "action": reopen}],
			})

	# ── Recipe shop — always available ───────────────────────────────────────
	options.append({
		"label":    "Do you sell any recipes?",
		"response": "Yes, for the right price. I can teach you two things.",
		"next_options": _build_extra_recipe_options(pd, reopen),
	})

	# ── Goodbye — always available ─────────────────────────────────────────────
	options.append({
		"label":    "Thank you, goodbye.",
		"response": "Come back if you need anything.",
		"closes":   true,
	})

	return options

func _build_shop_items() -> Array:
	return [
		{"id": "basic_lingering_poison", "price": 3},
		{"id": "smoke_bomb",             "price": 2},
	]

func _build_extra_recipe_options(pd: Dictionary, reopen: Callable) -> Array:
	var known: Array = pd.get("known_alchemy_recipes", [])
	var options: Array = []
	var your_alch: int = _eff_alchemy(pd)

	# Smoke bomb recipe — 3 coins, requires 15 alchemy
	if "smoke_bomb_brew" not in known:
		var can_afford: bool = _count_coins() >= 3
		var smoke_req_str: String = "Alchemy 15  |  yours: %d" % your_alch
		options.append({
			"label":    "Smoke bomb recipe — 3 coins  (%s)" % smoke_req_str if can_afford else "Smoke bomb recipe — 3 coins  [not enough coin]  (%s)" % smoke_req_str,
			"disabled": not can_afford,
			"response": "Dry out succulent fibers, pack them into a clay shell with a slow burn center. When it breaks, the oils smoke thick and low. Good for disappearing or covering a retreat.",
			"action":   func():
				_spend_coins(3)
				if not pd.has("known_alchemy_recipes"):
					pd["known_alchemy_recipes"] = []
				pd["known_alchemy_recipes"].append("smoke_bomb_brew"),
			"next_options": [{"label": "Continue", "closes": true, "action": reopen}],
		})
	else:
		options.append({
			"label":    "Smoke bomb recipe  (already learned)",
			"disabled": true,
			"closes":   true,
		})

	# Poison recipe — 5 coins, requires 20 alchemy
	if "basic_lingering_poison_brew" not in known:
		var can_afford_p: bool = _count_coins() >= 5
		var poison_req_str: String = "Alchemy 20  |  yours: %d" % your_alch
		options.append({
			"label":    "Lingering poison recipe — 5 coins  (%s)" % poison_req_str if can_afford_p else "Lingering poison recipe — 5 coins  [not enough coin]  (%s)" % poison_req_str,
			"disabled": not can_afford_p,
			"response": "Crush dusk flower petals into an intact lizard acid gland and render it down over low heat. Coat the blade and it clings until you wash it off. Good for wearing someone down over a fight.",
			"action":   func():
				_spend_coins(5)
				if not pd.has("known_alchemy_recipes"):
					pd["known_alchemy_recipes"] = []
				pd["known_alchemy_recipes"].append("basic_lingering_poison_brew"),
			"next_options": [{"label": "Continue", "closes": true, "action": reopen}],
		})
	else:
		options.append({
			"label":    "Lingering poison recipe  (already learned)",
			"disabled": true,
			"closes":   true,
		})

	options.append({"label": "Maybe another time.", "closes": true, "action": reopen})
	return options

func _count_coins() -> int:
	var count := 0
	for item in GameManager.player_data.get("inventory", []):
		if item.get("type", "") == "currency":
			count += 1
	return count

func _spend_coins(amount: int) -> void:
	var inv: Array = GameManager.player_data.get("inventory", [])
	var spent := 0
	var i: int = inv.size() - 1
	while i >= 0 and spent < amount:
		if inv[i].get("type", "") == "currency":
			inv.remove_at(i)
			spent += 1
		i -= 1
	GameManager.player_data["inventory"] = inv

func _build_teaching_offer_options(pd: Dictionary, reopen: Callable) -> Array:
	var your_alch: int = _eff_alchemy(pd)
	var can_learn: bool = your_alch >= 15

	var start_ingredient_quest := func():
		pd["apothecary_recipe_accepted"] = true
		GameManager.update_quest_thread("find_spiritual_protection", "apothecary_vial_path",
			"The apothecary will teach me to brew it myself. I need to collect a dusk flower from the river to the west and a desert succulent from the desert to the south of the drain exit.")
		if not pd.has("known_alchemy_recipes"):
			pd["known_alchemy_recipes"] = []
		if "dark_vial_brew" not in pd["known_alchemy_recipes"]:
			pd["known_alchemy_recipes"].append("dark_vial_brew")
		# Pre-mark the nearest desert zone so the succulent location shows on the map
		GameManager.add_encounter(0, Vector2i(9, 15), "Desert Succulent")

	return [
		{
			"label":    "Sure.  [Alchemy 15  |  yours: %d]" % your_alch,
			"disabled": not can_learn,
			"response": "Ok, there are two ingredients you will need. The first is a darkly colored flower you can find growing by the river — we call it a dusk flower. The second is a small succulent you can find growing in the desert surrounding the city. You shouldn't have to go too far for either. Return with both of those and I'll teach you the recipe.",
			"action":   start_ingredient_quest,
			"next_options": [{"label": "Continue", "closes": true, "action": reopen}],
		},
		{
			"label":  "No thanks.",
			"closes": true,
			"action": reopen,
		},
	]

func _eff_alchemy(pd: Dictionary) -> int:
	var invested: int = int(pd.get("skills", {}).get("alchemy", 0))
	var int_stat: int = pd.get("stats", {}).get("intelligence", 5)
	return int(invested * (1.0 + float(int_stat - 5) * 0.1))

func _has_coin() -> bool:
	for item in GameManager.player_data.get("inventory", []):
		if item.get("type", "") == "currency":
			return true
	return false

func _has_both_ingredients() -> bool:
	var inv: Array = GameManager.player_data.get("inventory", [])
	var has_flower: bool = false
	var has_succulent: bool = false
	for item in inv:
		if item.get("id", "") == "dusk_flower":     has_flower    = true
		if item.get("id", "") == "desert_succulent": has_succulent = true
	return has_flower and has_succulent

func _has_player_made_vial() -> bool:
	for item in GameManager.player_data.get("inventory", []):
		if item.get("id", "") == "dark_vial" and item.get("player_made", false):
			return true
	return false

func _count_item_by_material(mat_type: String, beast: String) -> int:
	var count: int = 0
	for item in GameManager.player_data.get("inventory", []):
		if item.get("material_type", "") == mat_type and item.get("beast_source", "") == beast:
			count += 1
	return count

func _count_item_by_id(item_id: String) -> int:
	var count: int = 0
	for item in GameManager.player_data.get("inventory", []):
		if item.get("id", "") == item_id:
			count += 1
	return count

func _take_items_by_material(mat_type: String, beast: String, count: int) -> void:
	var inv: Array = GameManager.player_data.get("inventory", [])
	var taken: int = 0
	var i: int = inv.size() - 1
	while i >= 0 and taken < count:
		var item = inv[i]
		if item.get("material_type", "") == mat_type and item.get("beast_source", "") == beast:
			inv.remove_at(i)
			taken += 1
		i -= 1
	GameManager.player_data["inventory"] = inv

func _take_items_by_id(item_id: String, count: int) -> void:
	var inv: Array = GameManager.player_data.get("inventory", [])
	var taken: int = 0
	var i: int = inv.size() - 1
	while i >= 0 and taken < count:
		if inv[i].get("id", "") == item_id:
			inv.remove_at(i)
			taken += 1
		i -= 1
	GameManager.player_data["inventory"] = inv

func _buy_vial() -> void:
	var inv: Array = GameManager.player_data.get("inventory", [])
	for i in range(inv.size()):
		if inv[i].get("type", "") == "currency":
			inv.remove_at(i)
			break
	inv.append(DataManager.get_item("dark_vial"))
	GameManager.player_data["inventory"] = inv

	var count: int = GameManager.player_data.get("apothecary_vials_bought_count", 0) + 1
	GameManager.player_data["apothecary_vials_bought_count"] = count
	GameManager.player_data["apothecary_vial_bought_this_cycle"] = true
	GameManager.add_xp(15)

	GameManager.update_quest_thread("find_spiritual_protection", "apothecary_vial_path",
		"I bought a dark green vial from the apothecary. She said it would protect me for a few nights at a time.")

func _reopen_dialogue() -> void:
	_update_dialogue()
	EventBus.interaction_triggered.emit(self, "talk")
