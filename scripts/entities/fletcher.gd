extends NPC
# The Fletcher — runs an open stall in the Market District.
# Sells primitive/natural weapons and light armor: bows, stone knife, wooden
# spear, whip, quiver, hide/leather/cloth gear.
# Also buys pelts/skins off the player, up to PELT_DAILY_LIMIT combined per day.

const PELT_DAILY_LIMIT: int = 3
const PELT_DAILY_KEY: String = "fletcher_pelts_bought_today"

const PELT_BUY_LIST: Array = [
	{"id": "coyote_pelt",            "price": 2},
	{"id": "lizard_skin",            "price": 2},
	{"id": "adolescent_coyote_pelt", "price": 3},
]

const SHOP_ITEMS: Array = [
	{"id": "knife",             "price": 2},
	{"id": "sling",             "price": 4},
	{"id": "stone_axe",         "price": 5},
	{"id": "spear",             "price": 6},
	{"id": "whip",              "price": 7},
	{"id": "shortbow",          "price": 22},
	{"id": "longbow",           "price": 35},
	{"id": "quiver",            "price": 5},
	{"id": "fishing_rod",       "price": 6},
	{"id": "torch",             "price": 2},
	{"id": "hide_shield",       "price": 4},
	{"id": "wooden_shield",     "price": 8},
	{"id": "leather_vest",      "price": 6},
	{"id": "padded_cloth_armor", "price": 8},
]

func _ready() -> void:
	grid_cell             = Vector2i(69, 47)
	interaction_reach     = 2
	stat_strength         = 5
	stat_dexterity        = 8
	stat_agility          = 6
	stat_constitution     = 5
	stat_willpower        = 5
	stat_perception       = 8
	level                 = 3
	skills["melee"]       = 20
	skills["ranged"]      = 30
	skills["dodge"]       = 16
	equipment["hand_1"]   = DataManager.get_item("knife")
	equipment["hand_2"]   = DataManager.get_item("shortbow")
	equipment["back"]     = DataManager.get_item("quiver")
	equipment["torso"]    = DataManager.get_item("leather_vest")
	# AI uses knife for melee; bow available for future ranged NPC AI
	_attack_weapon        = DataManager.get_item("knife")
	pocket_items          = [DataManager.get_item("coin"), DataManager.get_item("coin")]
	drops_loot            = true
	super._ready()
	entity_name = "Fletcher"
	_update_dialogue()
	EventBus.player_rested.connect(func(): GameManager.player_data.erase(PELT_DAILY_KEY))

func get_interaction_options() -> Array:
	_update_dialogue()
	return super.get_interaction_options()

func _update_dialogue() -> void:
	var pd: Dictionary = GameManager.player_data
	var open_trade := func():
		var remaining: int = PELT_DAILY_LIMIT - pd.get(PELT_DAILY_KEY, 0)
		var buy_list: Array = []
		for base_entry in PELT_BUY_LIST:
			var entry: Dictionary = base_entry.duplicate()
			entry["remaining"]      = remaining
			entry["quality_scaled"] = true
			buy_list.append(entry)
		var on_sale := func(_item: Dictionary):
			pd[PELT_DAILY_KEY] = pd.get(PELT_DAILY_KEY, 0) + 1
			var new_remaining: int = PELT_DAILY_LIMIT - pd.get(PELT_DAILY_KEY, 0)
			for e in buy_list:
				e["remaining"] = new_remaining
		EventBus.dialogue_closed.connect(
			func(_e): EventBus.open_shop_ui.emit(self, SHOP_ITEMS, buy_list, on_sale),
			CONNECT_ONE_SHOT)

	dialogue_text = "A wiry person sits behind a low counter strung with hanging bows. They look up expectantly."

	dialogue_options = [
		{
			"label":    "What do you sell?",
			"response": "Bows, spears, knives. Stone and wood, all of it. And if you've got pelts or skins on you, I'll buy those too — up to three a day.",
			"next_options": [
				{"label": "Show me.",            "closes": true, "action": open_trade},
				{"label": "Maybe another time.", "closes": true},
			],
		},
	]

	if not pd.get("fletcher_asked_spirit", false):
		dialogue_options.append({
			"label":    "Do you sell spiritual protection?",
			"response": "Nothing like that here. Try the smith or the scribes, or if you're a hunter, go find [old hunter placeholder name]. I spoke to him earlier today so he should still be in town, he likes to camp outside the walls, just outside the western drainage pipe in the ditch.",
			"next_options": [{"label": "Thanks.", "closes": true, "action": func():
				GameManager.player_data["fletcher_asked_spirit"] = true}],
		})

	dialogue_options.append({"label": "Goodbye.", "closes": true})

func _convince_skill() -> float:
	var pd: Dictionary  = GameManager.player_data
	var invested: float = float(pd.get("skills", {}).get("convince", 0))
	var wil_mod: int    = pd.get("stats", {}).get("willpower", 5) - 5
	return invested * (1.0 + wil_mod * 0.1)

func _reopen_dialogue() -> void:
	_update_dialogue()
	EventBus.interaction_triggered.emit(self, "talk")
