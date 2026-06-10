extends NPC
# Thug — guards the gate into the Residential District.
# Positioned just inside the gate at row 63 (cols 37 and 43), flanking the opening.
# Detection range 8: triggers at row 71, giving the player ~4 tiles from entry (row 75)
# to toggle sneak before the LoS check through the gate fires.
# Goes hostile if dialogue ends without resolution.
#
# Stats (both instances):
#   STR 7 (+2)  DEX 5 (±0)  AGI 6 (+1)  CON 6 (+1)  WIL 5 (±0)  PER 7 (+2)
#   Level 1 — max HP 60
#   Melee 13 (effective 15.6)  Intimidate 8 (effective 9.6)  Dodge 3
#   Weapon: shortsword (1d6, AP 2, bleed)
#   Armor: leather vest + work trousers + work boots (~7% pct reduction)
#   Inventory: 3 coins

const DETECTION_RANGE: int = 8

var _dialogue_triggered: bool = false
var _dialogue_resolved: bool  = false
var _left_area: bool          = false

func _ready() -> void:
	stat_strength     = 7
	stat_dexterity    = 5
	stat_agility      = 6
	stat_constitution = 6
	stat_willpower    = 5
	stat_perception   = 7
	level             = 1
	skills["melee"]      = 13
	skills["intimidate"] = 8
	skills["dodge"]      = 3
	sight_range          = DETECTION_RANGE
	# Equipment — contributes to armor during combat
	equipment["hand_1"] = DataManager.get_item("shortsword")
	equipment["torso"]  = DataManager.get_item("leather_vest")
	equipment["legs"]   = DataManager.get_item("work_trousers")
	equipment["feet"]   = DataManager.get_item("work_boots")
	_attack_weapon = DataManager.get_item("shortsword")
	# Coins collected from previous tolls
	inventory.append(DataManager.get_item("coin"))
	inventory.append(DataManager.get_item("coin"))
	inventory.append(DataManager.get_item("coin"))
	drops_loot = true
	super._ready()
	entity_name = "Thug"
	_update_dialogue()

func _process(delta: float) -> void:
	super._process(delta)
	if _dead or is_hostile:
		return
	# Shared outcome flags keep both thugs in sync from a single dialogue result
	# gate_toll_hostile checked before combat_mode so the second thug joins even after combat starts
	if GameManager.player_data.get("gate_toll_hostile", false):
		go_hostile()
		return
	if GameManager.combat_mode:
		return
	if GameManager.player_data.get("gate_toll_resolved", false):
		return
	if GameManager.player_data.get("gate_toll_backed_off", false):
		var player := GameManager.player as Player
		if player == null:
			return
		var dx: int = abs(grid_cell.x - player.grid_cell.x)
		var dy: int = abs(grid_cell.y - player.grid_cell.y)
		var dist: int = maxi(dx, dy)
		if not _left_area and dist > DETECTION_RANGE:
			_left_area = true
		elif _left_area and dist <= DETECTION_RANGE:
			GameManager.player_data["gate_toll_hostile"] = true
			go_hostile()
		return
	if _dialogue_triggered or GameManager.player_data.get("gate_toll_triggered", false):
		return
	var player := GameManager.player as Player
	if player == null:
		return
	var dx: int = abs(grid_cell.x - player.grid_cell.x)
	var dy: int = abs(grid_cell.y - player.grid_cell.y)
	if maxi(dx, dy) > DETECTION_RANGE:
		return
	if _tile_scene == null or not _tile_scene.has_line_of_sight(grid_cell, player.grid_cell):
		return
	# Sneak detection roll — effective PER scales with level
	if GameManager.is_sneaking:
		var player_skills: Dictionary = GameManager.player_data.get("skills", {})
		var sneak_skill: int  = int(player_skills.get("sneak", 0))
		var dex_mod: int      = Entity.modifier(GameManager.player.stat_dexterity)
		var eff_sneak: float  = sneak_skill * (1.0 + dex_mod * 0.1)
		var per_mod: int      = Entity.modifier(stat_perception)
		var eff_per: float    = (1.0 + per_mod) * 5.0 * float(level)
		var detect_chance: int = clampi(50 + int((eff_per - eff_sneak) * 2.0), 5, 95)
		if randi_range(1, 100) > detect_chance:
			return  # slipped past undetected
	# Trigger the shakedown dialogue
	_dialogue_triggered = true
	GameManager.player_data["gate_toll_triggered"] = true
	_update_dialogue()
	call_deferred("_open_dialogue")

func _open_dialogue() -> void:
	var player := GameManager.player as Player
	if player != null:
		player.move_path.clear()
	EventBus.dialogue_closed.connect(_on_thug_dialogue_closed, CONNECT_ONE_SHOT)
	EventBus.interaction_triggered.emit(self, "talk")

func _on_thug_dialogue_closed(_entity: Node) -> void:
	if _dialogue_resolved or is_hostile or _dead:
		return
	# Player left without resolving — both thugs go hostile
	GameManager.player_data["gate_toll_hostile"] = true
	go_hostile()

func _update_dialogue() -> void:
	var pd: Dictionary       = GameManager.player_data
	var p_skills: Dictionary = pd.get("skills", {})
	var p_stats:  Dictionary = pd.get("stats",  {})

	dialogue_text = "Two hard-looking men step out from the gate and plant themselves in your path. The taller one looks you up and down, then addresses you.\n\n\"Hey. Godless don't belong in this neighborhood. Pay us to look the other way or we'll show you your place.\""

	var str_mod: int = p_stats.get("strength",  5) - 5
	var wil_mod: int = p_stats.get("willpower", 5) - 5
	var eff_intimidate: float = float(p_skills.get("intimidate", 0)) * (1.0 + maxi(str_mod, wil_mod) * 0.1)
	var eff_convince:   float = float(p_skills.get("convince",   0)) * (1.0 + wil_mod * 0.1)

	var coin_count: int = 0
	for item in pd.get("inventory", []):
		if item.get("id", "") == "coin":
			coin_count += 1

	var can_pay:       bool = coin_count >= 5
	var intimidate_ok: bool = eff_intimidate >= 10.0
	var convince_ok:   bool = eff_convince   >= 15.0

	var resolve_leave := func():
		_dialogue_resolved = true
		pd["gate_toll_backed_off"] = true

	var resolve_pay := func():
		_dialogue_resolved = true
		pd["gate_toll_resolved"] = true
		var inv: Array = pd.get("inventory", [])
		var removed := 0
		var i := inv.size() - 1
		while i >= 0 and removed < 5:
			if inv[i].get("id", "") == "coin":
				inv.remove_at(i)
				removed += 1
			i -= 1
		pd["inventory"] = inv

	var resolve_intimidate := func():
		_dialogue_resolved = true
		pd["gate_toll_resolved"] = true

	var resolve_convince := func():
		_dialogue_resolved = true
		pd["gate_toll_resolved"] = true

	var go_hostile_action := func():
		GameManager.player_data["gate_toll_hostile"] = true
		go_hostile()

	dialogue_options = [
		{
			"label":    "Fine. *[Hand over the coins.]*" if can_pay else "Fine. *[Hand over the coins.]* [Need 5 coins]",
			"disabled": not can_pay,
			"response": "Smart. *They step aside.*",
			"closes":   true,
			"action":   resolve_pay,
		},
		{
			"label":    "[Intimidate 10] Try it. See what happens.",
			"disabled": not intimidate_ok,
			"response": "*The tall one holds your gaze, jaw tight, then steps back.* Not worth it today.",
			"closes":   true,
			"action":   resolve_intimidate,
		},
		{
			"label":    "[Convince 15] Just passing through for work.",
			"disabled": not convince_ok,
			"response": "*He looks you over.* The Scribe's errand boy, huh. Fine. Don't make a habit of it.",
			"closes":   true,
			"action":   resolve_convince,
		},
		{
			"label":    "*Draw your weapon.*",
			"response": "*Both men reach for their blades.*",
			"closes":   true,
			"action":   go_hostile_action,
		},
		{
			"label":    "I'm leaving.",
			"response": "*The tall one watches you go, arms crossed.* \"Smart.\"",
			"closes":   true,
			"action":   resolve_leave,
		},
	]
