extends NPC
# The Old Hunter — sits outside the city pipe, skinning a kill far too large for him.
# First available quest giver and crafting teacher.
# Dialogue branches based on player quest/loot/craft/talisman/camp state.

const PARENT_QUEST := "find_spiritual_protection"
const THREAD_ID    := "hunter_animal_kill"

func _ready() -> void:
	if GameManager.player_data.get("hunter_left", false):
		queue_free()
		return
	grid_cell             = Vector2i(51, 28)
	stat_strength         = 10
	stat_dexterity        = 10
	stat_agility          = 7
	stat_constitution     = 12
	stat_willpower        = 8
	stat_perception       = 15
	level                 = 20
	hp_flat_bonus         = 600.0
	skills["melee"]       = 158
	skills["ranged"]      = 126
	skills["dodge"]       = 84
	skills["survival"]    = 126
	equipment["hand_1"]   = DataManager.get_item("knife")
	equipment["torso"]    = DataManager.get_item("leather_vest")
	equipment["legs"]     = DataManager.get_item("work_trousers")
	_attack_weapon        = DataManager.get_item("knife")
	# pocket_items empty — carries tools and trophies, never coins
	drops_loot            = true
	super._ready()
	entity_name = "Old Hunter"
	EventBus.crafting_ui_closed.connect(_on_crafting_ui_closed)
	EventBus.player_rested.connect(_on_player_rested)
	_set_intro_dialogue()

# ── Override interaction so dialogue updates on every click ────────────────────
func get_interaction_options() -> Array:
	_update_dialogue()
	return super.get_interaction_options()

# ── State machine ──────────────────────────────────────────────────────────────
func _update_dialogue() -> void:
	var craft_taught: bool = GameManager.player_data.get("hunter_craft_taught", false)
	if GameManager.has_quest_thread("the_dream", "dream_ask_hunter") \
			and not GameManager.player_data.get("hunter_dream_asked", false):
		_set_dream_question_dialogue()
	elif not _has_thread():
		_set_intro_dialogue()
	elif not craft_taught and not _has_animal_loot():
		_set_go_hunt_dialogue()
	elif not craft_taught:
		_set_craft_teaching_dialogue()
	elif not _has_crafted_trophy():
		_set_craft_failed_dialogue()
	elif not _has_talisman_equipped():
		_set_wear_talisman_dialogue()
	elif not _thread_complete():
		if GameManager.player_data.get("hunter_camp_questions_started", false):
			_set_camp_questions_dialogue()
		else:
			_set_camp_dialogue()
	else:
		_set_goodbye_dialogue()

# ── Helper checks ──────────────────────────────────────────────────────────────
func _has_thread() -> bool:
	return GameManager.has_quest_thread(PARENT_QUEST, THREAD_ID)

func _thread_complete() -> bool:
	for q in GameManager.player_data.get("quests", []):
		if q.get("id") == PARENT_QUEST:
			for t in q.get("threads", []):
				if t.get("id") == THREAD_ID:
					return t.get("completed", false)
	return false

func _has_animal_loot() -> bool:
	for item in GameManager.player_data.get("inventory", []):
		if item.get("material_type", "") != "":
			return true
	return false

func _has_crafted_trophy() -> bool:
	for item in GameManager.player_data.get("inventory", []):
		if item.get("type", "") == "trinket":
			return true
	var equip: Dictionary = GameManager.player_data.get("equipment", {})
	for slot in equip.values():
		if slot != null and slot.get("type", "") == "trinket":
			return true
	return false

func _has_talisman_equipped() -> bool:
	var equip: Dictionary = GameManager.player_data.get("equipment", {})
	for slot in equip.values():
		if slot != null and slot.get("type", "") == "trinket" and slot.get("spirit_ward", false):
			return true
	return false

func _has_weapon() -> bool:
	var equip: Dictionary = GameManager.player_data.get("equipment", {})
	for slot in ["hand_1", "hand_2"]:
		var item = equip.get(slot)
		if item != null and item.get("type", "") == "weapon" and item.get("id", "") != "unarmed":
			return true
	for item in GameManager.player_data.get("inventory", []):
		if item.get("type", "") == "weapon" and item.get("id", "") != "unarmed":
			return true
	return false

# ── Dialogue states ────────────────────────────────────────────────────────────
func _set_intro_dialogue() -> void:
	var accept_quest := func():
		GameManager.add_quest_thread(PARENT_QUEST, {
			"id":          THREAD_ID,
			"title":       "The Old Hunter",
			"description": "The old hunter outside the exit drain wants proof you can hunt. Kill any animal and bring back a part of it.",
			"updates":     [],
			"completed":   false,
		})
		GameManager.add_xp(15)
		GameManager.add_faction_contact("old_hunter")
		GameManager.add_note({
			"id":    "way_of_beasts",
			"title": "The Way of Beasts",
			"body":  "There is power in a life that can be claimed through death. Kill an animal yourself, take a trophy from its corpse, and wear it — you carry the strength of what you have slain. True practitioners are found in the deep desert and the Undercity where great beasts roam. Their trophies rival the talismans sold by the Scribes and the Smiths.",
		}, 10)

	var quest_hook_options: Array = [
		{
			"label":    "But I don't have any weapon.",
			"disabled": _has_weapon(),
			"response": "Sounds like you'll have a fun time then! HA HA HA",
			"closes":   true,
		},
		{
			"label":    "Thank you.",
			"response": "Good hunting.",
			"closes":   true,
		},
	]

	var claim_powers_option: Dictionary = {
		"label":        "Tell me how I would claim these powers.",
		"response":     "HA, a hunter then? Leave the city, and kill something! Take a trophy from it's corpse and come back to me!",
		"action":       accept_quest,
		"next_options": quest_hook_options,
	}

	var spirits_branch: Array = [
		claim_powers_option,
		{"label": "Thank you, goodbye.", "closes": true},
	]

	var explain_options: Array = [
		{
			"label":    "Can this power protect me from the spirits tonight? I am without a god.",
			"response": "Protect you from the spirits in these parts? Hah, of course. The spirits in the city are meek in comparison to those in the desert or undercity.",
			"next_options": spirits_branch,
		},
		claim_powers_option,
		{"label": "Thank you, goodbye.", "closes": true},
	]

	var main_options: Array = [
		{
			"label": "You kill that yourself?",
			"response": "'course I killed it myself. And I'll wear it myself too. Add it to my collection. *He rattles some of the bones hanging off himself to draw your attention to them.* And I'll add it to my strength.",
			"next_options": [
				{
					"label":    "What do you mean, 'add it to your strength'?",
					"response": "Heh. You see, there's power in a life, and it can be claimed through death. If you take the life of a great beast yourself, and take a trophy from it, there is power in that. Adorn yourself with these trophies and you will know the strengths of those you have slain.",
					"next_options": explain_options,
				},
				{"label": "Gross...", "closes": true},
			],
		},
		{"label": "Farewell.", "response": "Watch where you walk.", "closes": true},
	]

	dialogue_text    = "An old man sits in the sand carefully skinning a giant lizard with a well used knife. He does not wear a single piece of fabric, instead he is wrapped in various furs, and ornamented with bones. A large skull hangs on his back like an unworn hood. When he notices you watching he finishes the last cut he was making and turns to face you, cracking a wry smile."
	dialogue_options = [
		{
			"label":        "Continue",
			"response":     "Heh. I see you eyin' my hunt. You ever kill anything like this? Doesn't look like it.",
			"next_options": main_options,
		},
	]

func _set_dream_question_dialogue() -> void:
	var pd: Dictionary = GameManager.player_data
	dialogue_text = "The old man looks up from his work as you approach."
	dialogue_options = [
		{
			"label":  "I had a dream I wanted to ask you about.",
			"action": func():
				pd["hunter_dream_asked"] = true
				GameManager.complete_quest_thread("the_dream", "dream_ask_hunter"),
			"response": "Hmm, yes. I have heard something has been disturbing the beasts in the caves below the undercity. I don't think you'll make it that deep though, weak as you are, but start heading in that direction. The journey will toughen you up.",
			"closes":   true,
		},
	]

func _set_go_hunt_dialogue() -> void:
	dialogue_text    = "The old man barely looks up from his work."
	dialogue_options = [
		{
			"label":    "...",
			"response": "Why are you back already?! Go hunt!",
			"closes":   true,
		},
	]

func _set_craft_teaching_dialogue() -> void:
	var give_knife_and_teach := func():
		if not _has_weapon():
			var knife: Dictionary = DataManager.get_item("knife")
			var inv: Array        = GameManager.player_data.get("inventory", [])
			inv.append(knife)
			GameManager.player_data["inventory"] = inv
		var known: Array = GameManager.player_data.get("known_recipes", [])
		for rid in ["basic_hide_trophy_armband", "basic_fang_trophy_necklace",
					"basic_skull_trophy_headdress", "basic_bone_ring"]:
			if rid not in known:
				known.append(rid)
		GameManager.player_data["known_recipes"] = known
		GameManager.player_data["hunter_craft_taught"] = true
		GameManager.add_xp(50)
		GameManager.update_quest_thread(PARENT_QUEST, THREAD_ID,
			"Craft a protective talisman out of your trophy.")
		EventBus.dialogue_closed.connect(func(_e): _do_open_crafting(), CONNECT_ONE_SHOT)

	if not _has_weapon():
		dialogue_text = "The old man looks up. He sees the blood on your hands. His eyes gleam."
		dialogue_options = [
			{
				"label":    "...",
				"response": "And you return! Hands soaked with blood. That's what I like to see. *He pulls out a knife and tosses it at your feet.* Next time, use that and kill something bigger!",
				"next_options": [
					{
						"label":    "Continue",
						"response": "Now, let me teach you about wearing your trophies.",
						"closes":   true,
						"action":   give_knife_and_teach,
					},
				],
			},
		]
	else:
		dialogue_text = "The old man sees what you're carrying and nods slowly."
		dialogue_options = [
			{
				"label":    "...",
				"response": "Now, let me teach you about wearing your trophies.",
				"closes":   true,
				"action":   give_knife_and_teach,
			},
		]

func _set_craft_failed_dialogue() -> void:
	dialogue_text = "The old man glances at your hands, then back to his work."
	dialogue_options = [
		{
			"label":    "...",
			"response": "Can't follow simple instructions? Come back when you figure it out.",
			"closes":   true,
		},
	]

func _set_wear_talisman_dialogue() -> void:
	dialogue_text = "The old man eyes the trophy in your hands."
	dialogue_options = [
		{
			"label":    "...",
			"response": "Ha, good. It is not as great as any of mine, but it will do for your first. You are now a practitioner of The Way of Beasts.",
			"next_options": [
				{
					"label":    "Continue",
					"response": "Now put it on, and feel its spirit. After you do lets make camp, I see you claimed some meat as well. Rest after your fight, it is well earned.",
					"closes":   true,
				},
			],
		},
	]

func _camp_rest_action() -> Callable:
	return func():
		GameManager.update_quest_thread(PARENT_QUEST, THREAD_ID,
			"Wear your talisman and camp with the Old Hunter.")
		EventBus.dialogue_closed.connect(func(_e): _do_open_rest(), CONNECT_ONE_SHOT)

func _set_camp_dialogue() -> void:
	var enter_questions := func():
		GameManager.player_data["hunter_camp_questions_started"] = true
		GameManager.add_quest({
			"id":          "way_of_beasts",
			"title":       "The Way of Beasts",
			"description": "Kill bigger beasts and take trophies from them, grow strong.",
			"threads":     [],
			"completed":   false,
		})
		EventBus.dialogue_closed.connect(func(_e): _reopen_dialogue(), CONNECT_ONE_SHOT)

	dialogue_text = "The old man looks you over, taking in the trophy you wear, then speaks."
	dialogue_options = [
		{
			"label":    "...",
			"response": "Our trophies make better protective talismans than the paltry trinkets The Scribes or The Smiths will sell you. We don't need their gods of the city. The spirits of the wild will do.",
			"next_options": [
				{
					"label":    "Can you tell me more about this Way of Beasts?",
					"response": "The Way of Beasts is the way any true hunter should lead their life. You've already taken the first steps on the path. I have been walking this road for a long time, I have been far and I have been deep. When you practice The Way of Beasts, you can go where you want, and you will always have food to eat. HA HA ha. And you will have the strength to make the spirits of the night fear you.",
					"next_options": [
						{
							"label":  "Continue",
							"closes": true,
							"action": enter_questions,
						},
					],
				},
				{
					"label":  "Let's go to sleep.",
					"closes": true,
					"action": _camp_rest_action(),
				},
			],
		},
	]

func _set_camp_questions_dialogue() -> void:
	var pd: Dictionary = GameManager.player_data
	var reopen := func():
		EventBus.dialogue_closed.connect(func(_e): _reopen_dialogue(), CONNECT_ONE_SHOT)

	dialogue_text = "The old man sits by his fire."
	var options: Array = []

	if not pd.get("hunter_asked_hunt_location", false):
		options.append({
			"label":    "Where should I hunt?",
			"action":   func(): pd["hunter_asked_hunt_location"] = true,
			"response": "Well you're still pretty weak, so you'll probably die if you go into the deeper desert... or if you go into the undercity. There are animals more your size in the plains surrounding the city, or along the river.",
			"next_options": [{"label": "Continue", "closes": true, "action": reopen}],
		})

	if not pd.get("hunter_asked_faith", false):
		options.append({
			"label":    "Who else practices your faith?",
			"action":   func(): pd["hunter_asked_faith"] = true,
			"response": "Every hunter knows at least a bit of the way, and I have seen warriors of all stripes adorn themselves with trophies of their kills to add to their strength, but true devotees like myself are few and far between. You will find us in the deep desert and the Undercity, anywhere great beasts can be found.",
			"next_options": [{"label": "Continue", "closes": true, "action": reopen}],
		})

	if not pd.get("hunter_asked_weapon", false):
		options.append({
			"label":    "What's your weapon of choice?",
			"action":   func(): pd["hunter_asked_weapon"] = true,
			"response": "Just this knife you see here. HA HA HA. Anything bigger and I wouldn't feel close enough to the kill. HA HA HA.",
			"next_options": [{"label": "Continue", "closes": true, "action": reopen}],
		})

	if not pd.get("hunter_asked_biggest_kill", false):
		options.append({
			"label":    "What was your biggest kill?",
			"action":   func(): pd["hunter_asked_biggest_kill"] = true,
			"response": "*He breaks into a story you cannot be sure is true or not. He tells you of venturing deep into the desert, and killing a beetle half the size of the ditch. He continues to elaborate on the gruesome details of taking it down deep into the night. Eventually you fall asleep.*",
			"next_options": [{"label": "Continue", "closes": true, "action": _camp_rest_action()}],
		})

	options.append({
		"label":  "Let's go to sleep.",
		"closes": true,
		"action": _camp_rest_action(),
	})

	dialogue_options = options

func _set_goodbye_dialogue() -> void:
	dialogue_text = "The old man glances up at you."
	dialogue_options = [
		{
			"label":    "...",
			"response": "Get strong enough to go below if you want to meet again, I'm getting bored of the surface.",
			"next_options": [
				{
					"label":  "Ok.",
					"closes": true,
				},
			],
		},
	]

# ── Player rested handler ──────────────────────────────────────────────────────
func _on_player_rested() -> void:
	if not _thread_complete():
		return
	if not GameManager.player_data.get("hunter_can_leave", false):
		# This was the quest-completion rest — arm the departure trigger
		GameManager.player_data["hunter_can_leave"] = true
		return
	# Second rest after quest — hunter is gone
	GameManager.player_data["hunter_left"] = true
	GameManager.remove_encounter(GameManager.world_layer, GameManager.world_pos, entity_name)
	queue_free()

# ── Crafting / rest UI bridges ─────────────────────────────────────────────────
func _do_open_crafting() -> void:
	EventBus.open_crafting_ui.emit(self)

func _do_open_rest() -> void:
	EventBus.open_rest_ui.emit(true)

func _on_crafting_ui_closed(entity: Node) -> void:
	if entity != self:
		return
	if _has_crafted_trophy():
		GameManager.update_quest_thread(PARENT_QUEST, THREAD_ID,
			"Craft a protective talisman out of your trophy.")
		_set_wear_talisman_dialogue()
	else:
		_set_craft_failed_dialogue()
	call_deferred("_reopen_dialogue")

func _reopen_dialogue() -> void:
	_update_dialogue()
	EventBus.interaction_triggered.emit(self, "talk")
