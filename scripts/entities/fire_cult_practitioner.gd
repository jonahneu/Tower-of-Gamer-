extends NPC
# Fire Cult Elder — lives in the small hut on the east side of the Lower Ditch.
# Name and cult name TBD.
# Shows as "Old Man" until the player is referred by the fire cult member, then "Fire Cult Elder".

func _ready() -> void:
	grid_cell             = Vector2i(68, 44)
	stat_strength         = 5
	stat_dexterity        = 6
	stat_agility          = 5
	stat_constitution     = 6
	stat_willpower        = 8
	stat_perception       = 8
	level                 = 2
	skills["melee"]       = 9
	skills["dodge"]       = 8
	equipment["torso"]    = DataManager.get_item("tunic")
	# pocket_items empty — ascetic elder, carries nothing material
	drops_loot            = true
	super._ready()
	_update_name()
	_update_dialogue()

func get_interaction_options() -> Array:
	_update_name()
	_update_dialogue()
	return super.get_interaction_options()

func _update_name() -> void:
	if GameManager.player_data.get("fire_cult_referred_to_elder", false):
		entity_name = "Fire Cult Elder"
	else:
		entity_name = "Old Man"

# ── Skill helpers ──────────────────────────────────────────────────────────────
func _occultism_skill() -> float:
	var pd: Dictionary = GameManager.player_data
	var invested: float = float(pd.get("skills", {}).get("occultism", 0))
	var stats: Dictionary = pd.get("stats", {})
	var int_mod: int = stats.get("intelligence", 5) - 5
	var wil_mod: int = stats.get("willpower", 5) - 5
	return invested * (1.0 + max(int_mod, wil_mod) * 0.1)

# ── Dialogue ──────────────────────────────────────────────────────────────────
func _update_dialogue() -> void:
	var pd: Dictionary = GameManager.player_data
	var referred: bool     = pd.get("fire_cult_referred_to_elder", false)
	var met: bool          = pd.get("elder_met", false)
	var sat: bool          = pd.get("elder_sat_with_fire", false)
	var burned: bool       = pd.get("elder_burning_done", false)
	var dream_asked: bool  = pd.get("elder_dream_asked", false)
	var magic_learned: bool = pd.get("elder_magic_learned", false)

	dialogue_text = "*You see a grey-haired old man sitting on the dirt floor in front of a fire. Sticking out of his simple robes, you notice his left hand is a charred husk.*"

	var options: Array = []

	if not referred:
		# ── Cold approach: player was not sent here ───────────────────────────
		options.append({
			"label":    "Who are you?",
			"response": "Just an old man.",
			"closes":   true,
		})
	else:
		# ── Referred path ─────────────────────────────────────────────────────
		if not met:
			options.append({
				"label":  "I'm looking to learn about stoking my inner flame.",
				"action": func():
					pd["elder_met"] = true
					GameManager.update_quest_thread("find_spiritual_protection", "inner_flame_path",
						"I found the elder. He asked me to sit with him and gaze into his fire."),
				"response": "*The old man smiles.* Ahhh, yes I see. You are Godless. Then you have come to the right place. In our beliefs, this is not strictly a bad thing like many would tell you. Losing one's ties to the Gods of The City is just as much an opportunity for a beginning as it is an end. Now, sit with me and look into the fire.",
				"next_options": _fire_gazing_options(),
			})
		elif not sat:
			options.append({
				"label":    "...",
				"response": "Sit with me and look into the fire.",
				"next_options": _fire_gazing_options(),
			})
		elif not burned:
			options.append({
				"label":    "...",
				"response": "Would you like me to pass a piece of my flame onto you? *He reaches out with his burnt hand*",
				"next_options": _burning_options(),
			})
		elif not magic_learned:
			if not pd.get("elder_rested_once", false):
				options.append({
					"label":    "...",
					"response": "I sparked the flame inside of you, now it is up to you to stoke it. I can teach you more of the basics, but you must seek out and overcome adversity for your flame to grow. For today, you can rest around my fire. I have food you can eat.",
					"next_options": [
						{
							"label":  "Rest here.",
							"action": func():
								pd["elder_rested_once"] = true
								EventBus.dialogue_closed.connect(
									func(_e): EventBus.open_elder_rest_ui.emit(), CONNECT_ONE_SHOT),
							"closes": true,
						},
						{"label": "Thank you.", "closes": true},
					],
				})
			elif not pd.get("dream_seen", false):
				# Rested but dream not yet played — auto-save was taken before the dream
				# sequence ran. Re-trigger it from here so the player isn't stuck.
				options.append({
					"label":    "...",
					"action":   func():
						EventBus.dialogue_closed.connect(
							func(_e): EventBus.open_dream_scene.emit(), CONNECT_ONE_SHOT),
					"closes":   true,
				})
			if GameManager.has_quest_thread("the_dream", "dream_ask_fire_cult_elder") and not dream_asked:
				options.append(_dream_question_option())
		else:
			options.append({
				"label":    "...",
				"response": "Go seek out the temple. Be careful.",
				"closes":   true,
			})

	options.append({"label": "Goodbye.", "closes": true})
	dialogue_options = options

func _fire_gazing_options() -> Array:
	var pd: Dictionary = GameManager.player_data
	var can_gaze: bool = _occultism_skill() >= 15.0

	var after_gaze: Array = [
		{
			"label":    "Continue",
			"action":   func():
				pd["elder_sat_with_fire"] = true
				GameManager.update_quest_thread("find_spiritual_protection", "inner_flame_path",
					"I saw something in the fire. The elder wants me to experience the flame directly — let him burn me with an ember."),
			"response": "Good good, remember what you see there, and visualize it inside yourself. Next is the hard part, you must experience the flame to gain true understanding of it.",
			"next_options": [
				{
					"label":    "Continue",
					"response": "Would you like me to pass a piece of my flame onto you? *He reaches out with his burnt hand*",
					"next_options": _burning_options(),
				},
			],
		},
	]

	return [
		{
			"label":    "[Occultism 15] *Gaze into the fire.*",
			"disabled": not can_gaze,
			"action":   func(): pd["elder_sat_with_fire"] = true,
			"response": "*You focus on the flames. Shapes shift and writhe.*",
			"next_options": after_gaze,
		},
		{
			"label":    "I don't see anything.",
			"response": "*The old man nods slowly, unsurprised.* That is alright. Most don't, at first. Sit a while longer. Come back when you are ready.",
			"closes":   true,
		},
	]

func _burning_options() -> Array:
	var pd: Dictionary = GameManager.player_data
	return [
		{
			"label":  "Ok.",
			"action": func():
				pd["elder_burning_done"] = true
				_apply_burn()
				GameManager.add_note({
					"id":    "inner_flame",
					"title": "The Inner Flame",
					"body":  "The Fire Cult Elder teaches that godlessness is not a curse but a beginning. Through fire gazing and enduring the touch of a burning ember, one can carry an inner flame — a permanent protection against the spirits of the night that requires no talisman or external god. The mark does not leave you.",
				}, 10)
				GameManager.add_faction_contact("fire_cult_elder")
				GameManager.add_feat({
					"id":          "inner_flame",
					"name":        "Inner Flame",
					"description": "You have experienced the flame and carry it within you now. Grants permanent Level 0 spirit protection — the spirits of the night cannot take you unaware.",
					"source":      "story",
				})
				GameManager.update_quest_thread("find_spiritual_protection", "inner_flame_path",
					"I allowed the elder to burn me with an ember. I carry an inner flame now — the spirits of the night cannot take me unaware.")
				GameManager.complete_quest_thread("find_spiritual_protection", "inner_flame_path")
				GameManager.complete_quest("find_spiritual_protection")
				GameManager.add_xp(75),
			"response": "*He presses his thumb against your palm*\n\n[You gained the feat: Inner Flame]\n\nSee, not so bad. Do you feel any different?",
			"next_options": [
				{
					"label":    "...I think I do, actually.",
					"response": "I sparked the flame inside of you, now it is up to you to stoke it. I can teach you more of the basics, but you must seek out and overcome adversity for your flame to grow. For today, you can rest around my fire. I have food you can eat.",
					"next_options": [
						{
							"label":  "Rest here.",
							"action": func():
								pd["elder_rested_once"] = true
								EventBus.dialogue_closed.connect(
									func(_e): EventBus.open_elder_rest_ui.emit(), CONNECT_ONE_SHOT),
							"closes": true,
						},
						{"label": "Thank you.", "closes": true},
					],
				},
			],
		},
		{
			"label":    "No way, you're crazy.",
			"response": "*He lowers his hand, still smiling.* When you are ready.",
			"closes":   true,
		},
	]

func _dream_question_option() -> Dictionary:
	var pd: Dictionary = GameManager.player_data
	return {
		"label":  "I had a dream I wanted to ask you about.",
		"action": func():
			pd["elder_dream_asked"] = true
			GameManager.update_quest_thread("the_dream", "dream_ask_fire_cult_elder",
				"The elder directed me to the Fire Cult temple in the undercity.")
			GameManager.complete_quest_thread("the_dream", "dream_ask_fire_cult_elder")
			GameManager.add_note({
				"id":    "scribes_shun_the_flame",
				"title": "Marked by the Flame",
				"body":  "The Fire Cult Elder warned that the scribes can sense the flame in those who carry it, and will shun them — refusing them entry to their libraries.",
			}, 5),
		"response": "Hmm, I have heard a little of Godless having such dreams. Many of us practitioners were Godless as well. The strength of the flame is very appealing to one who's lost the protection of the City's gods. Unfortunately, I do not know the meaning of your dream. It seems to be connected to the Undercity ruins, and the spirits that curse this land. If you want to learn more, you will have to venture below. Seek out our temple as your first stop, the masters there will know more.",
		"next_options": [
			{
				"label":    "Continue",
				"response": "The journey to the temple is not an easy one. I can teach you to use the flame to defend yourself, but it will expand that burn on your hand. We are not widely accepted in the city, and are detested by the scribes, who will not want you in their libraries if they can tell you carry the flame inside you. Would you like to proceed?",
				"next_options": _magic_teaching_options(),
			},
		],
	}

func _magic_teaching_options() -> Array:
	var pd: Dictionary = GameManager.player_data
	return [
		{
			"label":  "Yes.",
			"action": func():
				pd["elder_magic_learned"] = true
				pd["pyromancy_visible"] = true
				_apply_second_burn()
				EventBus.dialogue_closed.connect(
					func(_e): EventBus.open_spell_pick_ui.emit(["burning_palm", "heat"]), CONNECT_ONE_SHOT),
			"response": "*He reaches out with his burned hand again, and presses his thumb into your burned palm once more. The burning sensation is much worse this time, and you start to wonder how long he has been holding your hand. Finally he releases it, and you can see your palm now has a charred circle in the center of it. Looking closely in the cracks of your burned hand, you can catch a glimpse of sparks flickering. When you look up he gives you a knowing smile, and nods you towards the door.*\n\nGo get the hang of it in the desert before heading to the temple, and try not to die!",
			"closes":  true,
		},
		{
			"label":    "No.",
			"response": "Return if you change your mind.",
			"closes":   true,
		},
	]

func _apply_second_burn() -> void:
	var player = GameManager.player
	if player == null or not is_instance_valid(player):
		return
	var dmg: int = randi_range(4, 8)
	player.current_hp = maxi(1, player.current_hp - dmg)
	EventBus.damage_floater.emit(player, "-%d" % dmg, Color(1.0, 0.45, 0.10))

func _apply_burn() -> void:
	var player = GameManager.player
	if player == null or not is_instance_valid(player):
		return
	var dmg: int = randi_range(1, 4)
	player.current_hp = maxi(1, player.current_hp - dmg)
	EventBus.damage_floater.emit(player, "-%d" % dmg, Color(1.0, 0.45, 0.10))

func _reopen_dialogue() -> void:
	_update_name()
	_update_dialogue()
	EventBus.interaction_triggered.emit(self, "talk")
