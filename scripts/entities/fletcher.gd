extends NPC
# The Fletcher — runs an open stall in the Market District.
# Sells primitive/natural weapons: bows, stone knife, wooden spear, whip, quiver.
# Also buys hides: regular (coyote pelt, lizard skin) <Fine=1c, Fine+=2c; adolescent coyote <Fine=2c, Fine+=3c.

const DAILY_BUY_LIMIT: int = 3
const DAILY_KEY: String    = "fletcher_hides_sold_today"

const SHOP_ITEMS: Array = [
	{"id": "knife",        "price": 2},
	{"id": "sling",        "price": 4},
	{"id": "stone_axe",    "price": 5},
	{"id": "spear",        "price": 6},
	{"id": "whip",         "price": 7},
	{"id": "shortbow",     "price": 22},
	{"id": "longbow",      "price": 35},
	{"id": "quiver",       "price": 5},
	{"id": "fishing_rod",  "price": 6},
	{"id": "hide_shield",  "price": 4},
	{"id": "wooden_shield","price": 8},
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
	EventBus.player_rested.connect(func(): GameManager.player_data.erase(DAILY_KEY))

func get_interaction_options() -> Array:
	_update_dialogue()
	return super.get_interaction_options()

func _update_dialogue() -> void:
	var pd: Dictionary = GameManager.player_data
	var open_trade := func():
		var sellable: Array = _build_sellable_hides()
		var rem: int        = DAILY_BUY_LIMIT - GameManager.player_data.get(DAILY_KEY, 0)
		var on_sale := func(_item: Dictionary):
			GameManager.player_data[DAILY_KEY] = GameManager.player_data.get(DAILY_KEY, 0) + 1
		EventBus.dialogue_closed.connect(
			func(_e): EventBus.open_shop_ui.emit(self, SHOP_ITEMS, sellable, rem, on_sale),
			CONNECT_ONE_SHOT)

	dialogue_text = "A wiry person sits behind a low counter strung with hanging bows. They look up expectantly."

	dialogue_options = [
		{
			"label":    "What do you sell?",
			"response": "Bows, spears, knives. Stone and wood, all of it. I also buy hides — up to three a day.",
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

func _has_sellable_hides() -> bool:
	for item in GameManager.player_data.get("inventory", []):
		if item.get("material_type", "") in ["pelt", "skin"]:
			return true
	return false

func _build_sellable_hides() -> Array:
	var sellable: Array = []
	for item in GameManager.player_data.get("inventory", []):
		var mat: String   = item.get("material_type", "")
		if mat not in ["pelt", "skin"]:
			continue
		var quality: int  = item.get("quality", 0)
		var beast: String = item.get("beast_source", "")
		var price: int
		if beast == "adolescent_coyote":
			price = 3 if quality >= 4 else 2
		else:
			price = 2 if quality >= 4 else 1
		sellable.append({"item": item.duplicate(), "price": price})
	return sellable
