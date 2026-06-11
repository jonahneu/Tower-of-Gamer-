extends NPC
# The Hearthkeeper — runs the rest house on the west side of the ditch.
# Completes the apothecary delivery quest (small pouch → 3 coins).

const MEAT_DAILY_LIMIT: int = 3
const MEAT_DAILY_KEY: String = "innkeeper_meat_sold_today"

func _ready() -> void:
	grid_cell             = Vector2i(10, 20)   # against the west wall of the rest house
	interaction_reach     = 2                  # player can talk across the bar counter
	stat_strength         = 6
	stat_dexterity        = 5
	stat_agility          = 5
	stat_constitution     = 6
	stat_willpower        = 6
	stat_perception       = 6
	skills["melee"]       = 6
	skills["dodge"]       = 2
	equipment["torso"]    = DataManager.get_item("tunic")
	equipment["legs"]     = DataManager.get_item("work_trousers")
	pocket_items          = [DataManager.get_item("coin"), DataManager.get_item("coin"), DataManager.get_item("coin")]
	drops_loot            = true
	super._ready()
	entity_name = "Hearthkeeper"
	_update_dialogue(false)
	EventBus.player_rested.connect(func(): GameManager.player_data.erase(MEAT_DAILY_KEY))

func get_interaction_options() -> Array:
	_update_dialogue()
	return super.get_interaction_options()

func _reopen_dialogue() -> void:
	_update_dialogue()
	EventBus.interaction_triggered.emit(self, "talk")

# record_visit is false for the _ready() priming call, so it doesn't mark the
# player as "met" before they've actually talked to the keeper of the rest house.
func _update_dialogue(record_visit: bool = true) -> void:
	var pd: Dictionary = GameManager.player_data
	if pd.get("innkeeper_show_hunter_hint", false):
		pd.erase("innkeeper_show_hunter_hint")
		dialogue_text = "You're a real fledgeling hunter! Have you met the Old Hunter? He's often sitting outside the walls skinning animals. He could teach you a lot."
		dialogue_options = [{"label": "Good to know.", "closes": true}]
		return
	if not pd.get("innkeeper_met", false):
		if record_visit:
			pd["innkeeper_met"] = true
		dialogue_text = "Never seen you before. *looks you over* Ah ok, I get it. What're you looking for?"
	else:
		dialogue_text = "Welcome back."
	dialogue_options = _build_options()

func _build_options() -> Array:
	var pd: Dictionary = GameManager.player_data
	var reopen := func():
		EventBus.dialogue_closed.connect(func(_e): _reopen_dialogue(), CONNECT_ONE_SHOT)

	var options: Array = []

	# ── Spiritual protection — disappears once asked ───────────────────────────
	if not pd.get("innkeeper_asked_protection", false):
		options.append({
			"label":    "I'm looking for spiritual protection.",
			"action":   func(): pd["innkeeper_asked_protection"] = true,
			"response": "I've got my own talismans, but none for sale. *you notice he glances towards a cloth armband with runic script on it* Go to the market if you want to buy one from The Scribes or The Smiths.",
			"next_options": [{"label": "Continue", "closes": true, "action": reopen}],
		})

	# ── Meal and bed ── always available ─────────────────────────────────────
	var meal_options := _build_meal_options(pd, reopen)
	options.append({
		"label":    "I'm looking for a meal and a bed.",
		"response": "One coin, I keep a stew going, you can have a bowl and sleep in the straw over there with the others.",
		"next_options": meal_options,
	})

	options.append({
		"label":    "Your stew smells good, can you teach me anything about cooking while I travel?",
		"response": "You'll need to preserve your food if you want to travel with it. I can teach you that, and how to cook it into meals.",
		"next_options": [{"label": "Continue", "closes": true, "action": reopen}],
	})

	# ── Area question — disappears once asked ─────────────────────────────────
	if not pd.get("innkeeper_asked_area", false):
		options.append({
			"label":    "What can you tell me about this area?",
			"action":   func():
				pd["innkeeper_asked_area"] = true
				GameManager.add_note({
					"id":    "the_ditch",
					"title": "The Ditch",
					"body":  "A shantytown built over an ancient drainage pipe. North leads to the Market District; west, the old drain exit opens onto the path out of the city; south, the slope descends deeper into the Ditch and eventually into the Undercity — the keeper of the rest house warns against it. Spirits here are especially aggressive at night.",
				}, 10),
			"response": "The Ditch? Not all too much to know. Its a shantytown, slums. It's home though. I guess its built on top an ancient drainage pipe, thats why it leads out to the beach in one direction, and down to the undercity in the other. Lot of interesting characters here. North of here leads to the market district. South is the lower ditch and beyond it the undercity, don't go there. To the west is the old drainage pipe exit if you want to leave the city.",
			"next_options": [{"label": "Continue", "closes": true, "action": reopen}],
		})

	# ── Work / meat buying — always available ─────────────────────────────────────
	options.append({
		"label":    "Got any work?",
		"response": "Not exactly. But I'll buy fresh meat off you — one coin a piece, up to three a day.",
		"next_options": _build_sell_meat_options(pd, reopen),
	})

	# ── Apothecary delivery — appears when quest accepted and pouch in inventory ─
	if pd.get("apothecary_job_given", false) and not pd.get("innkeeper_delivery_done", false) and _has_small_pouch():
		var do_delivery := func():
			# Remove the small pouch
			var inv: Array = pd.get("inventory", [])
			for i in range(inv.size()):
				if inv[i].get("id", "") == "small_pouch":
					inv.remove_at(i)
					break
			# Give 3 coins
			for _c in range(3):
				inv.append(DataManager.get_item("coin"))
			pd["inventory"] = inv
			pd["innkeeper_delivery_done"] = true
			GameManager.complete_quest("apothecary_delivery")
			GameManager.add_xp(25)

		var after_delivery := _build_after_delivery_options(pd)

		options.append({
			"label":    "I have a delivery for you from the apothecary.",
			"action":   do_delivery,
			"response": "From the apothecary? *takes the pouch* Alright.",
			"next_options": after_delivery,
		})

	# ── Goodbye — always available ────────────────────────────────────────────
	options.append({
		"label":    "Goodbye.",
		"response": "Take care.",
		"closes":   true,
	})

	return options

func _build_meal_options(_pd: Dictionary, reopen: Callable) -> Array:
	var open_rest := func():
		EventBus.dialogue_closed.connect(
			func(_e): EventBus.open_inn_rest_ui.emit(), CONNECT_ONE_SHOT)

	return [
		{
			"label":    "1 coin — rest here.",
			"disabled": _coin_count() < 1,
			"closes":   true,
			"action":   open_rest,
		},
		{
			"label":    "No thanks.",
			"closes":   true,
			"action":   reopen,
		},
	]

func _build_after_delivery_options(pd: Dictionary) -> Array:
	var tip_action := func():
		var inv: Array = pd.get("inventory", [])
		inv.append(DataManager.get_item("coin"))
		pd["inventory"] = inv
		pd["innkeeper_tip_taken"] = true

	var after_tip := [{"label": "Continue", "closes": true}]

	var tip_taken: bool = pd.get("innkeeper_tip_taken", false)
	var convince_ok: bool = _convince_skill() >= 10.0
	var tip_label: String
	if tip_taken:
		tip_label = "[Convince 10] Look at him expectantly for a tip. (done)"
	else:
		tip_label = "[Convince 10] Look at him expectantly for a tip."

	return [
		{
			"label":  "Continue.",
			"closes": true,
		},
		{
			"label":    tip_label,
			"disabled": not convince_ok or tip_taken,
			"response": "*He sighs and fishes a coin out of a drawer.* Fine.",
			"action":   tip_action,
			"next_options": after_tip,
		},
	]

# ── Helpers ───────────────────────────────────────────────────────────────────
func _has_small_pouch() -> bool:
	for item in GameManager.player_data.get("inventory", []):
		if item.get("id", "") == "small_pouch":
			return true
	return false

func _coin_count() -> int:
	var count: int = 0
	for item in GameManager.player_data.get("inventory", []):
		if item.get("type", "") == "currency":
			count += 1
	return count

func _convince_skill() -> float:
	var pd: Dictionary = GameManager.player_data
	var invested: float = float(pd.get("skills", {}).get("convince", 0))
	var wil_mod: int = pd.get("stats", {}).get("willpower", 5) - 5
	return invested * (1.0 + wil_mod * 0.1)

func _build_sell_meat_options(pd: Dictionary, reopen: Callable) -> Array:
	var opts: Array     = []
	var sold_today: int = pd.get(MEAT_DAILY_KEY, 0)
	var remaining: int  = MEAT_DAILY_LIMIT - sold_today

	if remaining <= 0:
		opts.append({"label": "You've bought your three today.", "closes": true, "action": reopen})
		return opts

	var has_meat: bool = false
	for item in pd.get("inventory", []):
		if item.get("material_type", "") == "meat":
			has_meat = true
			break

	if not has_meat:
		opts.append({"label": "I don't have any right now.", "closes": true, "action": reopen})
		return opts

	var sell_one := func():
		var inv: Array = pd.get("inventory", [])
		for i in range(inv.size()):
			if inv[i].get("material_type", "") == "meat":
				inv.remove_at(i)
				break
		inv.append(DataManager.get_item("coin"))
		pd["inventory"] = inv
		pd[MEAT_DAILY_KEY] = pd.get(MEAT_DAILY_KEY, 0) + 1
		_check_hunter_hint(pd)

	opts.append({
		"label":    "Sell a piece of meat. (1 coin)",
		"action":   sell_one,
		"response": "Here.",
		"next_options": [{"label": "Continue", "closes": true, "action": reopen}],
	})
	opts.append({"label": "Maybe another time.", "closes": true, "action": reopen})
	return opts

func _check_hunter_hint(pd: Dictionary) -> void:
	if pd.get(MEAT_DAILY_KEY, 0) < MEAT_DAILY_LIMIT:
		return
	if pd.get("innkeeper_hunter_hint_given", false):
		return
	for slot_item in pd.get("equipment", {}).values():
		if slot_item is Dictionary and slot_item.get("spirit_ward", false):
			return
	pd["innkeeper_hunter_hint_given"] = true
	pd["innkeeper_show_hunter_hint"]  = true
