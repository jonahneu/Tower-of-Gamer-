extends NPC
# The Smith — works the forge in the NW corner of the Market District.
# Sells bronze weapons, bronze armor, and spirit armbands.
# Work quest: fetch flame accelerant from [fire cult member TBD] in the Lower Ditch.
# Teaching sequence: sends player to desert ruins for bronze scrap, then teaches
#   armband crafting → property choice (Blessed Weapon or Barrier Armor) → second item.
# The armband path is a thread under the shared find_spiritual_protection quest,
# same as the hunter, apothecary, and fire-cult paths — not its own top-level quest.

const PARENT_QUEST := "find_spiritual_protection"
const THREAD_ID     := "smith_armband_path"

const SHOP_ITEMS: Array = [
	{"id": "shortsword",             "price": 12},
	{"id": "sword",                  "price": 22},
	{"id": "axe",                    "price": 20},
	{"id": "bronze_spear",           "price": 16},
	{"id": "bronze_scale_hauberk",   "price": 20},
	{"id": "bronze_helm",            "price": 10},
	{"id": "bronze_greaves",         "price": 8},
	{"id": "bronze_shield",          "price": 14},
	{"id": "bronze_spirit_armband",  "price": 12},
]

const BUY_LIST: Array = [
	{"id": "shortsword",             "price": 3, "remaining": 99},
	{"id": "sword",                  "price": 6, "remaining": 99},
	{"id": "axe",                    "price": 5, "remaining": 99},
	{"id": "bronze_spear",           "price": 4, "remaining": 99},
	{"id": "bronze_scale_hauberk",   "price": 5, "remaining": 99},
	{"id": "bronze_helm",            "price": 3, "remaining": 99},
	{"id": "bronze_greaves",         "price": 2, "remaining": 99},
	{"id": "bronze_shield",          "price": 4, "remaining": 99},
	{"id": "bronze_spirit_armband",  "price": 3, "remaining": 99},
]

func _ready() -> void:
	grid_cell             = Vector2i(10, 8)
	interaction_reach     = 2
	stat_strength         = 10
	stat_dexterity        = 6
	stat_agility          = 5
	stat_constitution     = 8
	stat_willpower        = 5
	stat_perception       = 5
	level                 = 4
	skills["melee"]       = 35
	skills["dodge"]       = 8
	equipment["hand_1"]   = DataManager.get_item("axe")
	equipment["torso"]    = DataManager.get_item("bronze_scale_hauberk")
	equipment["legs"]     = DataManager.get_item("work_trousers")
	_attack_weapon        = DataManager.get_item("axe")
	pocket_items          = [DataManager.get_item("coin"), DataManager.get_item("coin")]
	drops_loot            = true
	super._ready()
	entity_name = "Smith"
	EventBus.crafting_ui_closed.connect(_on_crafting_ui_closed)
	EventBus.smithing_pick_made.connect(_on_smithing_pick_made)
	_update_dialogue()

func get_interaction_options() -> Array:
	_update_dialogue()
	return super.get_interaction_options()

# ── Dialogue builder ───────────────────────────────────────────────────────────
func _update_dialogue() -> void:
	var pd: Dictionary = GameManager.player_data
	var reopen := func():
		EventBus.dialogue_closed.connect(func(_e): _reopen_dialogue(), CONNECT_ONE_SHOT)

	var open_shop := func():
		EventBus.dialogue_closed.connect(
			func(_e): EventBus.open_shop_ui.emit(self, SHOP_ITEMS, BUY_LIST.duplicate(true), Callable()), CONNECT_ONE_SHOT)

	dialogue_text = "The man behind the forge barely glances up. His forearms are thick with old burns."

	var options: Array = []

	# ── What do you sell ──────────────────────────────────────────────────────
	options.append({
		"label":    "What do you sell?",
		"response": "Bronze. Weapons, armor. Make em myself.",
		"next_options": [
			{"label": "Show me.",             "closes": true, "action": open_shop},
			{"label": "Maybe another time.",  "closes": true, "action": reopen},
		],
	})

	# ── Dream question — appears once the dream points the player back here ──
	if GameManager.has_quest_thread("the_dream", "dream_ask_smith") \
			and not pd.get("smith_dream_asked", false):
		options.append({
			"label":  "I had a dream I wanted to ask you about.",
			"action": func():
				pd["smith_dream_asked"] = true
				GameManager.complete_quest_thread("the_dream", "dream_ask_smith"),
			"response": "[DIALOGUE TBD — Smith's response when asked about the dream]",
			"next_options": [{"label": "Continue", "closes": true, "action": reopen}],
		})

	# ── Spiritual protection — disappears after first ask ─────────────────────
	if not pd.get("smith_asked_protection", false):
		options.append({
			"label":    "Do you sell spiritual protection?",
			"action":   func():
				pd["smith_asked_protection"]  = true
				pd["smith_heard_forge_master"] = true
				GameManager.add_faction_contact("smith"),
			"response": "I'm no Forge Master, but I can draw a decent amount of power from metal.",
			"next_options": _build_protection_options(open_shop),
		})

	# ── Forge Master — appears after player hears the term ────────────────────
	if pd.get("smith_heard_forge_master", false) and not pd.get("smith_asked_forge_master", false):
		options.append({
			"label":    "What's a Forge Master?",
			"action":   func():
				pd["smith_asked_forge_master"] = true
				GameManager.add_note({
					"id":    "forge_masters",
					"title": "The Forge Masters",
					"body":  "All smiths know some of the secrets of metal. Metal is a manifestation of the power of the earth — it hides ancient wisdom inside itself. The Forge Masters of the Great Forge in the Temple District know all of those secrets and can work metal in ways that draw out all sorts of properties, producing work of legendary quality. Ordinary smiths can still forge basic spirit-ward talismans.",
				}, 8),
			"response": "Those who have learned all the secrets of metal. Metal is a manifestation of the power of the earth. It hides ancient wisdom inside itself. All smiths know some of the secrets, but the Forge Masters of the Great Forge in the Temple District can forge metal in ways to draw out all sorts of properties. I've never seen a true master work before, but the works that come from the Great Forge are of legendary quality.",
			"next_options": [{"label": "I see.", "closes": true, "action": reopen}],
		})

	# ── Night dialogue — after full teaching, before sleep ────────────────────
	if pd.get("smith_teaching_done", false) and not pd.get("smith_night_done", false):
		dialogue_text = "He looks up at you, a hint of satisfaction in his eyes. The forge still glows at his back."
		options.append({
			"label":    "I've put on the armband.",
			"response": "TODO",
			"next_options": [{"label": "Thank you, good night.", "closes": true, "action": func():
				pd["smith_night_done"] = true
				EventBus.dialogue_closed.connect(
					func(_e): EventBus.open_smith_rest_ui.emit(), CONNECT_ONE_SHOT)}],
		})

	# ── Return with bronze scrap ──────────────────────────────────────────────
	elif pd.get("smith_secrets_given", false) and not pd.get("smith_armband_taught", false) \
			and _has_item("ancient_bronze_scrap"):
		options.append({
			"label":    "I found bronze scrap in the ruins.",
			"action":   func():
				pd["smith_armband_taught"] = true
				GameManager.update_quest_thread(PARENT_QUEST, THREAD_ID,
					"I brought the smith bronze scrap. He's teaching me to forge a spirit armband.")
				var known: Array = pd.get("known_smithing_recipes", [])
				if "bronze_spirit_armband" not in known:
					known.append("bronze_spirit_armband")
				pd["known_smithing_recipes"] = known
				EventBus.dialogue_closed.connect(
					func(_e): EventBus.open_crafting_ui.emit(self), CONNECT_ONE_SHOT),
			"response": "TODO",
			"next_options": [{"label": "Alright.", "closes": true}],
		})

	# ── Property pick "Ok now for the more interesting part" ─────────────────
	elif (pd.get("smith_armband_crafted", false) \
			or (pd.get("smith_armband_taught", false) and _has_item("bronze_spirit_armband"))) \
			and not pd.get("smith_property_chosen", false):
		if not pd.get("smith_armband_crafted", false):
			pd["smith_armband_crafted"] = true
		dialogue_text = "He glances at the armband you've made. A nod — small, but there."
		options.append({
			"label":    "What do I learn next?",
			"response": "TODO",
			"next_options": [{
				"label":  "Continue.",
				"closes": true,
				"action": func():
					EventBus.dialogue_closed.connect(func(_e):
						EventBus.open_smithing_pick_ui.emit([
							{
								"id":          "blessed_weapon",
								"name":        "Blessed Weapon",
								"description": "Weapons you smith can harm intangible enemies. They also ignore 20% of the target's armor.",
								"recipe_id":   "bronze_shortsword_blessed",
							},
							{
								"id":          "barrier_armor",
								"name":        "Barrier Armor",
								"description": "Armor you smith gives 5% resistance to all damage types.",
								"recipe_id":   "bronze_helmet_barrier",
							},
						])
					, CONNECT_ONE_SHOT),
			}],
		})

	# ── Teaching quest — appears after asking about protection, before given ──
	if pd.get("smith_asked_protection", false) and not pd.get("smith_secrets_given", false):
		var smithing_ok: bool = GameManager.player_data.get("skills", {}).get("smithing", 0) >= 15
		options.append({
			"label":    "Can you teach me to make my own protection?",
			"disabled": not smithing_ok,
			"action":   func():
				pd["smith_secrets_given"] = true
				GameManager.add_quest_thread(PARENT_QUEST, {
					"id":          THREAD_ID,
					"title":       "The Smith",
					"description": "The smith will teach you to forge your own protection. First, find bronze scrap in the ruins north of the western drainage exit in the Ditch.",
					"updates":     [],
					"completed":   false,
				}),
			"response": "I can guide you. The first thing you will have to do is find some metal. This whole city is built on the ruins of a much older city. Don't know what happened to em', but I do know we can dig up what they left behind and make it useful again.\n\nThe undercity is full of treasure for someone who knows what to do with it. For you — head into the desert. If you take the western drainage exit in the ditch, then head north into the desert, you can find pieces of ruins that stick out from the undercity through the desert. Be careful and don't head out too far.\n\nWhen you return I can teach you how to use what you found to fend off spirits, and more corporeal threats.",
			"next_options": [{"label": "I'll go look.", "closes": true}],
		})

	# ── Return with flame accelerant ──────────────────────────────────────────
	if pd.get("smith_work_given", false) and not pd.get("smith_work_complete", false) \
			and _has_item("flame_accelerant"):
		var tip_taken: bool   = pd.get("smith_tip_taken", false)
		var convince_ok: bool = _convince_skill() >= 10.0
		var tip_label: String = "[Convince 10] That was harder than it sounds. Something extra?" \
								+ (" (done)" if tip_taken else "")
		var tip_action := func():
			pd["smith_tip_taken"] = true
			_give_coins(1)
		options.append({
			"label":    "I have your flame accelerant.",
			"action":   func():
				_remove_item("flame_accelerant")
				_give_coins(3)
				pd["smith_work_complete"] = true
				GameManager.complete_quest_thread("smith_accelerant", "fetch_accelerant")
				GameManager.complete_quest("smith_accelerant"),
			"response": "Good. *takes the jar and sets it by the forge without looking at it.* Three coins.",
			"next_options": [
				{
					"label":    tip_label,
					"disabled": not convince_ok or tip_taken,
					"action":   tip_action,
					"response": "*He doesn't look up, but slides one more coin across the bench.* Don't make a habit of it.",
					"next_options": [{"label": "Thanks.", "closes": true}],
				},
				{"label": "Thanks.", "closes": true},
			],
		})

	# ── Work quest — appears until given ──────────────────────────────────────
	if not pd.get("smith_work_given", false):
		options.append({
			"label":    "Do you have any work?",
			"action":   func():
				pd["smith_work_given"] = true
				var inv: Array = pd.get("inventory", [])
				inv.append(DataManager.get_item("smith_invoice"))
				pd["inventory"] = inv
				GameManager.add_quest({
					"id":      "smith_accelerant",
					"title":   "Flame Accelerant",
					"summary": "The smith needs flame accelerant from a fire cult contact in the Lower Ditch. Bring the invoice and return with a jar.",
				})
				GameManager.add_quest_thread("smith_accelerant", {
					"id":    "fetch_accelerant",
					"title": "Find the fire cult contact in the Lower Ditch and collect the accelerant.",
				}),
			# TODO: replace [Name TBD] and [fire cult name] once finalized
			"response": "Sure. Take this invoice down to the Lower Ditch — there's a [fire cult name] man there, [Name TBD]. He makes flame accelerant. Tell him it's for the smithy. He'll give you a jar; bring it back here.",
			"next_options": [{"label": "Got it.", "closes": true, "action": reopen}],
		})

	options.append({"label": "Goodbye.", "response": "Take care.", "closes": true})
	dialogue_options = options

# ── Crafting / pick callbacks ─────────────────────────────────────────────────
func _on_crafting_ui_closed(entity: Node) -> void:
	if entity != self:
		return
	var pd: Dictionary = GameManager.player_data
	if pd.get("smith_armband_taught", false) and not pd.get("smith_armband_crafted", false):
		if _has_item("bronze_spirit_armband"):
			pd["smith_armband_crafted"] = true
			call_deferred("_reopen_dialogue")
	elif pd.get("smith_property_chosen", false) and not pd.get("smith_second_crafted", false):
		if _has_item("bronze_shortsword_blessed") or _has_item("bronze_helmet_barrier"):
			pd["smith_second_crafted"] = true
			pd["smith_teaching_done"]  = true
			GameManager.complete_quest_thread(PARENT_QUEST, THREAD_ID)
			GameManager.complete_quest(PARENT_QUEST)
			call_deferred("_reopen_dialogue")

func _on_smithing_pick_made(pick_id: String) -> void:
	var pd: Dictionary = GameManager.player_data
	if pd.get("smith_property_chosen", false):
		return
	pd["smith_property_chosen"] = true
	pd["smith_chosen_property"]  = pick_id
	var recipe_id: String
	if pick_id == "blessed_weapon":
		recipe_id = "bronze_shortsword_blessed"
	else:
		recipe_id = "bronze_helmet_barrier"
	var known: Array = pd.get("known_smithing_recipes", [])
	if recipe_id not in known:
		known.append(recipe_id)
	pd["known_smithing_recipes"] = known
	EventBus.open_crafting_ui.emit(self)

# ── Protection sub-options ────────────────────────────────────────────────────
func _build_protection_options(open_shop: Callable) -> Array:
	var pd: Dictionary  = GameManager.player_data
	var smithing_ok: bool = pd.get("skills", {}).get("smithing", 0) >= 15
	var teach_action := func():
		pd["smith_secrets_given"] = true
		GameManager.add_quest_thread(PARENT_QUEST, {
			"id":          THREAD_ID,
			"title":       "The Smith",
			"description": "The smith will teach you to forge your own protection. First, find bronze scrap in the ruins north of the western drainage exit in the Ditch.",
			"updates":     [],
			"completed":   false,
		})
	var options: Array = [
		{
			"label":    "What's a Forge Master?",
			"action":   func():
				pd["smith_heard_forge_master"] = true
				GameManager.add_note({
					"id":    "forge_masters",
					"title": "The Forge Masters",
					"body":  "All smiths know some of the secrets of metal. Metal is a manifestation of the power of the earth — it hides ancient wisdom inside itself. The Forge Masters of the Great Forge in the Temple District know all of those secrets and can work metal in ways that draw out all sorts of properties, producing work of legendary quality. Ordinary smiths can still forge basic spirit-ward talismans.",
				}, 8),
			"response": "Those who have learned all the secrets of metal. Metal is a manifestation of the power of the earth. It hides ancient wisdom inside itself. All smiths know some of the secrets, but the Forge Masters of the Great Forge in the Temple District can forge metal in ways to draw out all sorts of properties. I've never seen a true master work before, but the works that come from the Great Forge are of legendary quality.",
			"next_options": [
				{"label": "Show me your talismans.", "closes": true, "action": open_shop},
				{"label": "Thanks.",                 "closes": true},
			],
		},
		{"label": "Show me your talismans.", "closes": true, "action": open_shop},
	]
	if not pd.get("smith_secrets_given", false):
		options.append({
			"label":    "Can you teach me to make my own?",
			"disabled": not smithing_ok,
			"action":   teach_action,
			"response": "I can guide you. The first thing you will have to do is find some metal. This whole city is built on the ruins of a much older city. Don't know what happened to em', but I do know we can dig up what they left behind and make it useful again.\n\nThe undercity is full of treasure for someone who knows what to do with it. For you — head into the desert. If you take the western drainage exit in the ditch, then head north into the desert, you can find pieces of ruins that stick out from the undercity through the desert. Be careful and don't head out too far.\n\nWhen you return I can teach you how to use what you found to fend off spirits, and more corporeal threats.",
			"next_options": [{"label": "I'll go look.", "closes": true}],
		})
	options.append({"label": "Maybe another time.", "closes": true, "action": func(): EventBus.dialogue_closed.connect(func(_e): _reopen_dialogue(), CONNECT_ONE_SHOT)})
	return options

# ── Helpers ───────────────────────────────────────────────────────────────────
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

func _give_coins(count: int) -> void:
	var inv: Array = GameManager.player_data.get("inventory", [])
	for _i in range(count):
		inv.append(DataManager.get_item("coin"))
	GameManager.player_data["inventory"] = inv

func _convince_skill() -> float:
	var pd: Dictionary  = GameManager.player_data
	var invested: float = float(pd.get("skills", {}).get("convince", 0))
	var wil_mod: int    = pd.get("stats", {}).get("willpower", 5) - 5
	return invested * (1.0 + wil_mod * 0.1)

func _reopen_dialogue() -> void:
	_update_dialogue()
	EventBus.interaction_triggered.emit(self, "talk")
