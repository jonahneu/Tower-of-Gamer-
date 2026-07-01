extends NPC
# The Meat-Hawker — runs a stall in front of the smoke house in the Lower Market District, near the Fletcher.
# Sells coyote, lizard, and sand beetle meat, each raw or preserved (sun-dried/
# salt-cured/smoked), and teaches meat-preservation and meat-cooking recipes.

const SHOP_ITEMS: Array = [
	{"id": "coyote_meat",            "price": 1},
	{"id": "sun_dried_coyote_meat",  "price": 2},
	{"id": "salt_cured_coyote_meat", "price": 3},
	{"id": "smoked_coyote_meat",     "price": 4},

	{"id": "lizard_meat",            "price": 1},
	{"id": "sun_dried_lizard_meat",  "price": 2},
	{"id": "salt_cured_lizard_meat", "price": 3},
	{"id": "smoked_lizard_meat",     "price": 4},

	{"id": "sand_beetle_meat",            "price": 2},
	{"id": "sun_dried_sand_beetle_meat",  "price": 3},
	{"id": "salt_cured_sand_beetle_meat", "price": 4},
	{"id": "smoked_sand_beetle_meat",     "price": 5},
]

# Recipes for preserving meat to carry while travelling.
const PRESERVE_RECIPE_ORDER: Array = ["sun_dry", "cure_meat", "smoke_meat"]
const PRESERVE_RECIPE_PRICES: Dictionary = {
	"sun_dry":    2,
	"cure_meat":  3,
	"smoke_meat": 4,
}

# Recipes for cooking the meat he sells.
const MEAT_COOK_RECIPE_ORDER: Array = ["stick_roast", "ash_bake"]
const MEAT_COOK_RECIPE_PRICES: Dictionary = {
	"stick_roast": 1,
	"ash_bake":    3,
}

func _ready() -> void:
	grid_cell             = Vector2i(62, 41)
	interaction_reach     = 2
	stat_strength         = 8
	stat_dexterity        = 6
	stat_agility          = 5
	stat_constitution     = 7
	stat_willpower        = 5
	stat_perception       = 6
	level                 = 2
	skills["melee"]       = 8
	skills["dodge"]       = 5
	equipment["hand_1"]   = DataManager.get_item("knife")
	equipment["torso"]    = DataManager.get_item("tunic")
	equipment["legs"]     = DataManager.get_item("work_trousers")
	_attack_weapon        = DataManager.get_item("knife")
	pocket_items          = [DataManager.get_item("coin"), DataManager.get_item("coin"), DataManager.get_item("coin")]
	drops_loot            = true
	super._ready()
	entity_name           = "Meat-Hawker"
	_update_dialogue()

func get_interaction_options() -> Array:
	_update_dialogue()
	return super.get_interaction_options()

func _reopen_dialogue() -> void:
	_update_dialogue()
	EventBus.interaction_triggered.emit(self, "talk")

func _update_dialogue() -> void:
	var pd: Dictionary = GameManager.player_data
	var reopen := func():
		EventBus.dialogue_closed.connect(func(_e): _reopen_dialogue(), CONNECT_ONE_SHOT)

	var open_shop := func():
		EventBus.dialogue_closed.connect(
			func(_e): EventBus.open_shop_ui.emit(self, SHOP_ITEMS, [], Callable()),
			CONNECT_ONE_SHOT)

	dialogue_text = "You see a large sweaty man in a bloodstained hide apron. He addresses you loudly. \"Hello! You look hungry! Looking to buy some meats? Raw? Smoked? Cured?\""

	dialogue_options = [
		{
			"label":  "Yes please.",
			"closes": true,
			"action": open_shop,
		},
		{
			"label":    "Can you teach me about preserving meat on my travels?",
			"response": "Smoke it, salt it, dry it in the sun — keeps for ages! Costs you a coin or two, but worth every bite on the road.",
			"next_options": _build_recipe_options(pd, reopen, PRESERVE_RECIPE_ORDER, PRESERVE_RECIPE_PRICES),
		},
		{
			"label":    "Can you teach me how to cook the meat you sell?",
			"response": "Sure thing! Stick it over the fire, or bury it in the coals — can't go wrong either way.",
			"next_options": _build_recipe_options(pd, reopen, MEAT_COOK_RECIPE_ORDER, MEAT_COOK_RECIPE_PRICES),
		},
		{"label": "Goodbye.", "closes": true},
	]

# ── Recipe teaching ───────────────────────────────────────────────────────────
func _build_recipe_options(pd: Dictionary, reopen: Callable, order: Array, prices: Dictionary) -> Array:
	var known: Array = pd.get("known_cooking_recipes", [])
	var your_cooking: int = _eff_cooking(pd)
	var options: Array = []

	for recipe_id in order:
		if recipe_id in known:
			options.append({
				"label":    "%s  (already learned)" % DataManager.get_cooking_recipe(recipe_id).get("name", recipe_id),
				"disabled": true,
				"closes":   true,
			})
			continue

		var recipe: Dictionary = DataManager.get_cooking_recipe(recipe_id)
		var price: int = prices.get(recipe_id, 0)
		var can_afford: bool = _coin_count() >= price
		var price_str: String = "1 coin" if price == 1 else "%d coins" % price
		var req: int = recipe.get("cooking_level", 0)

		var label: String = "%s — %s" % [recipe.get("name", recipe_id), price_str]
		if req > 0:
			label += "  (Cooking %d | yours: %d)" % [req, your_cooking]
		if not can_afford:
			label += "  [not enough coin]"

		var captured_id: String = recipe_id
		var captured_price: int = price
		options.append({
			"label":    label,
			"disabled": not can_afford,
			"response": recipe.get("lore", ""),
			"action":   func():
				_spend_coins(captured_price)
				var kc: Array = pd.get("known_cooking_recipes", [])
				kc.append(captured_id)
				pd["known_cooking_recipes"] = kc,
			"next_options": [{"label": "Continue", "closes": true, "action": reopen}],
		})

	options.append({"label": "Maybe another time.", "closes": true, "action": reopen})
	return options

func _eff_cooking(pd: Dictionary) -> int:
	var invested: int = int(pd.get("skills", {}).get("cooking", 0))
	var int_stat: int = pd.get("stats", {}).get("intelligence", 5)
	return int(invested * (1.0 + float(int_stat - 5) * 0.1))

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

func _coin_count() -> int:
	var count: int = 0
	for item in GameManager.player_data.get("inventory", []):
		if item.get("type", "") == "currency":
			count += 1
	return count
