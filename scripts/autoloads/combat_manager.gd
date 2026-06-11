extends Node
# CombatManager — turn-based combat state machine
#
# Usage:
#   CombatManager.start_combat([player, enemy1, enemy2])
#   CombatManager.spend_ap(cost)   → bool (false = not enough AP)
#   CombatManager.spend_mp(cost)   → bool (false = not enough MP)
#   CombatManager.end_turn()
#
# Signals (via EventBus):
#   combat_started(participants)
#   combat_ended(victor_side)
#   turn_started(entity)
#   turn_ended(entity)

# ── State ──────────────────────────────────────────────────────────────────────
var active: bool = false
var participants: Array = []           # all living combatants, sorted by initiative
var turn_index: int = 0
var round: int = 0
var turn_state: Dictionary = {}        # entity → {ap, mp, cooldowns, weapon_states}
var pending_weapon: Dictionary = {}    # weapon queued for target selection (empty = none)
var sneak_attack_pending: bool = false # player's first attack this combat has 2× crit
var tactical_mode: bool = false        # turn-based movement without combat

# Smoke bomb deploy state
var pending_smoke_deploy: bool = false
var _pending_smoke_item: Dictionary = {}
var _pending_smoke_inv_idx: int = -1

# Blast tag state
var pending_blast_tag_deploy: bool = false
var _pending_blast_tag_item: Dictionary = {}
var _pending_blast_tag_inv_idx: int = -1
var blast_tag_armed: bool = false
var blast_tag_cell: Vector2i = Vector2i(-1, -1)

# ── Public API ─────────────────────────────────────────────────────────────────

# ── Tactical mode (turn-based movement without combat) ───────────────────────

func start_tactical() -> void:
	if active:
		return
	active = true
	tactical_mode = true
	GameManager.tactical_mode = true
	round = 1
	turn_index = 0
	turn_state.clear()
	sneak_attack_pending = false

	# Player first, then all living enemies in the zone
	var zone := GameManager.current_zone
	participants = [GameManager.player]
	if zone != null:
		for entity in zone.get_all_entities():
			var e := entity as Enemy
			if e != null and not e._dead:
				participants.append(e)

	for e in participants:
		turn_state[e] = _make_turn_state(e)

	EventBus.tactical_started.emit(participants)
	EventBus.combat_log.emit("── Tactical Mode ──\n  Turn-based movement active. [T] or button to exit.")
	_begin_turn()

func end_tactical() -> void:
	if not tactical_mode:
		return
	active = false
	tactical_mode = false
	GameManager.tactical_mode = false
	participants.clear()
	turn_state.clear()
	turn_index = 0
	pending_weapon = {}
	sneak_attack_pending = false
	EventBus.tactical_ended.emit()

# Transitions out of tactical mode (if active) then starts combat normally.
func force_start_combat(combatants: Array, stealth_info: Dictionary = {}, sneak_attack: bool = false) -> void:
	if tactical_mode:
		active = false
		tactical_mode = false
		GameManager.tactical_mode = false
		participants.clear()
		turn_state.clear()
		turn_index = 0
		pending_weapon = {}
		sneak_attack_pending = false
		EventBus.tactical_ended.emit()
	start_combat(combatants, stealth_info, sneak_attack)

func start_combat(combatants: Array, stealth_info: Dictionary = {}, sneak_attack: bool = false) -> void:
	if active:
		return
	active = true
	GameManager.combat_mode = true
	GameManager.exit_sneak()
	round = 1
	turn_index = 0
	participants = combatants.duplicate()
	turn_state.clear()

	# Roll initiative: 1d10 + DEX modifier + AGI modifier, sort descending
	var scored: Array = []
	for e in participants:
		var dex_mod: int  = Entity.modifier(e.stat_dexterity)
		var agi_mod: int  = Entity.modifier(e.stat_agility)
		var die_roll: int = randi_range(1, 10)
		var total: int    = die_roll + dex_mod + agi_mod
		scored.append({"entity": e, "init": total, "die": die_roll, "dex": dex_mod, "agi": agi_mod})
	scored.sort_custom(func(a, b): return a["init"] > b["init"])

	# Sneak attack: guarantee player goes first and mark first attack for 2× crit
	if sneak_attack and GameManager.player != null:
		var top_init: int = scored[0]["init"] if not scored.is_empty() else 10
		for s in scored:
			if s["entity"] == GameManager.player:
				s["init"] = top_init + 1
				break
		scored.sort_custom(func(a, b): return a["init"] > b["init"])
		sneak_attack_pending = true

	participants = scored.map(func(x): return x["entity"])

	# Initialise per-entity turn state
	for e in participants:
		turn_state[e] = _make_turn_state(e)

	EventBus.combat_started.emit(participants)

	# Sneak attack header is logged inline with the auto-fired first attack in resolve_attack

	# Log stealth detection if the player was sneaking when caught
	if not stealth_info.is_empty():
		var snk: PackedStringArray = ["── Stealth Broken ──"]
		var det: String  = stealth_info["detector"]
		var sk: int      = stealth_info["sneak_skill"]
		var dx: int      = stealth_info["dex_mod"]
		var es: float    = stealth_info["eff_sneak"]
		var per: int     = stealth_info["enemy_per"]
		var pm: int      = stealth_info["enemy_per_mod"]
		var lv: int      = stealth_info["enemy_level"]
		var ep: float    = stealth_info["eff_per"]
		var dc: int      = stealth_info["detect_chance"]
		var dice: Array  = stealth_info.get("dice", [stealth_info.get("die", 0)])
		var is_bump: bool = stealth_info.get("is_bump", false)
		var dex_str: String = (" %+d DEX mod" % dx) if dx != 0 else ""
		snk.append("  %s detected you while sneaking." % det)
		snk.append("  Eff. Sneak:  %.1f  [Sneak %d%s × (1 + %.1f)]" % [es, sk, dex_str, dx * 0.1])
		snk.append("  Eff. PER:    %.1f  [(1 + %d) × 5 × Lv.%d]" % [ep, pm, lv])
		snk.append("  Detection chance: %d%%  [50 + (%.1f − %.1f) × 2]" % [dc, ep, es])
		if is_bump:
			snk.append("  (Close contact — %d detection rolls)" % dice.size())
		for i in range(dice.size()):
			var d: int = int(dice[i])
			var outcome: String = "DETECTED" if d <= dc else "evaded"
			snk.append("  Roll %d: %d → %s" % [i + 1, d, outcome])
		EventBus.combat_log.emit("\n".join(snk))

	# Log initiative order
	var init_lines: PackedStringArray = ["── Initiative ──"]
	for s in scored:
		var name: String = s["entity"].get("entity_name") if s["entity"].get("entity_name") != null else "?"
		var mods: String = ""
		if s["dex"] != 0 or s["agi"] != 0:
			mods = " (%+d DEX, %+d AGI)" % [s["dex"], s["agi"]]
		init_lines.append("  %s: %d  [1d10=%d%s]" % [name, s["init"], s["die"], mods])
	EventBus.combat_log.emit("\n".join(init_lines))

	_begin_turn()

func end_turn() -> void:
	if not active:
		return
	clear_pending_weapon()
	var _ending_entity = current_entity()
	EventBus.turn_ended.emit(_ending_entity)
	_tick_cooldowns(_ending_entity)
	# Clear dazed at the end of the turn it was active on
	if _ending_entity != null and is_instance_valid(_ending_entity):
		var _ts_end = turn_state.get(_ending_entity, {})
		if _ts_end.get("dazed_clearing", false):
			_ts_end.erase("dazed_clearing")
			if _ending_entity.has_method("get") and _ending_entity.get("status_effects") != null:
				_ending_entity.status_effects.erase("dazed")
				EventBus.status_cleared.emit(_ending_entity, "dazed")

	# In tactical mode there is no combat — skip win/lose check
	if not tactical_mode:
		var player_alive = _any_alive("player")
		var enemy_alive  = _any_alive("enemy")
		if not player_alive or not enemy_alive:
			_end_combat("player" if player_alive else "enemy")
			return

	# Advance to next living combatant
	var attempts = 0
	while attempts < participants.size():
		turn_index = (turn_index + 1) % participants.size()
		if turn_index == 0:
			round += 1
		if _is_alive(participants[turn_index]):
			break
		attempts += 1

	_begin_turn()

func spend_ap(cost: int) -> bool:
	var e = current_entity()
	if e == null:
		return false
	var ts = turn_state.get(e, {})
	if ts.get("ap", 0) < cost:
		return false
	ts["ap"] -= cost
	EventBus.resources_changed.emit(e)
	return true

func spend_mp(cost: int) -> bool:
	var e = current_entity()
	if e == null:
		return false
	var ts = turn_state.get(e, {})
	if ts.get("mp", 0) < cost:
		return false
	ts["mp"] -= cost
	EventBus.resources_changed.emit(e)
	return true

# Spends 1 movement point: uses MP first, then falls back to AP.
# Returns false only when both pools are empty.
# Runner feat: spending 1 AP for movement grants 2 tiles instead of 1.
func spend_move() -> bool:
	if spend_mp(1):
		return true
	var e = current_entity()
	var ts = turn_state.get(e, {})
	if ts.get("runner_bonus_mp", 0) > 0:
		ts["runner_bonus_mp"] -= 1
		EventBus.resources_changed.emit(e)
		return true
	if spend_ap(1):
		if e == GameManager.player and GameManager.has_feat("runner"):
			ts["runner_bonus_mp"] = ts.get("runner_bonus_mp", 0) + 1
		return true
	return false

func current_ap() -> int:
	var ts = turn_state.get(current_entity(), {})
	return ts.get("ap", 0)

func current_mp() -> int:
	var ts = turn_state.get(current_entity(), {})
	return ts.get("mp", 0)

func max_ap_for(entity: Node) -> int:
	return entity.stat_agility

func max_mp_for(entity: Node) -> int:
	return entity.stat_agility * 2

func current_entity() -> Node:
	if participants.is_empty():
		return null
	return participants[turn_index]

func is_player_turn() -> bool:
	return current_entity() == GameManager.player

# Called when the player flees by transitioning zones.
func abandon_combat() -> void:
	if not active:
		return
	_end_combat("fled")

func add_participant(entity: Node) -> void:
	if not active or entity in participants:
		return
	participants.append(entity)
	turn_state[entity] = _make_turn_state(entity)
	EventBus.combat_participant_added.emit(entity)

func remove_participant(entity: Node) -> void:
	var idx := participants.find(entity)
	if idx < 0:
		return
	participants.remove_at(idx)
	turn_state.erase(entity)
	if not participants.is_empty() and turn_index >= participants.size():
		turn_index = participants.size() - 1

# ── Pending weapon (target-selection mode) ────────────────────────────────────

func set_pending_weapon(weapon: Dictionary) -> void:
	pending_weapon = weapon

func clear_pending_weapon() -> void:
	pending_weapon = {}

func has_pending_weapon() -> bool:
	return not pending_weapon.is_empty()

func consume_pending_weapon() -> Dictionary:
	var w: Dictionary = pending_weapon
	pending_weapon = {}
	return w

# ── Weapon / ability state helpers ────────────────────────────────────────────

func is_weapon_loaded(entity: Node, weapon_name: String) -> bool:
	var ts = turn_state.get(entity, {})
	return ts.get("weapon_loaded", {}).get(weapon_name, true)

func set_weapon_loaded(entity: Node, weapon_name: String, loaded: bool) -> void:
	if not turn_state.has(entity):
		return
	if not turn_state[entity].has("weapon_loaded"):
		turn_state[entity]["weapon_loaded"] = {}
	turn_state[entity]["weapon_loaded"][weapon_name] = loaded

func get_cooldown(entity: Node, ability_id: String) -> int:
	var ts = turn_state.get(entity, {})
	return ts.get("cooldowns", {}).get(ability_id, 0)

func set_cooldown(entity: Node, ability_id: String, turns: int) -> void:
	if not turn_state.has(entity):
		return
	if not turn_state[entity].has("cooldowns"):
		turn_state[entity]["cooldowns"] = {}
	turn_state[entity]["cooldowns"][ability_id] = turns

# ── Hit chance calculation ─────────────────────────────────────────────────────
# Returns an integer percentage in [5, 95].

func calc_hit_chance(attacker: Node, defender: Node, skill_name: String, extra_mod: int = 0, attacker_mod_adj: int = 0) -> int:
	var atk_skill: float = _get_skill_total(attacker, skill_name, attacker_mod_adj)
	var def_dodge: float = _get_skill_total(defender, "dodge")
	# 50% base at equal skills; each skill point difference shifts by 2%.
	var raw: int = 50 + int((atk_skill - def_dodge) * 2.0) + extra_mod
	if attacker == GameManager.player:
		var meal: Dictionary = GameManager.player_data.get("active_meal_buff", {})
		raw += meal.get("hit_flat", 0)
	return clampi(raw, 5, 95)

func roll_hit(attacker: Node, defender: Node, skill_name: String, extra_mod: int = 0, attacker_mod_adj: int = 0) -> bool:
	var chance: int = calc_hit_chance(attacker, defender, skill_name, extra_mod, attacker_mod_adj)
	return randi_range(1, 100) <= chance

# ── Private helpers ────────────────────────────────────────────────────────────

func _make_turn_state(entity: Node) -> Dictionary:
	var ex: int  = _exhaustion_for(entity)
	var base_mp: int = maxi(0, entity.stat_agility * 2 - ex * 2)
	var mp: int  = floori(base_mp * 0.2) if entity.is_overburdened() else base_mp
	return {
		"ap":           maxi(1, entity.stat_agility - ex),
		"mp":           mp,
		"cooldowns":    {},
		"weapon_loaded": {},
	}

func begin_smoke_deploy(item: Dictionary, inv_idx: int) -> void:
	pending_smoke_deploy = true
	_pending_smoke_item  = item
	_pending_smoke_inv_idx = inv_idx
	if GameManager.player != null:
		var pc: Vector2i = GameManager.player.get("grid_cell") if GameManager.player.get("grid_cell") != null else Vector2i(40, 40)
		EventBus.show_range_ring.emit(pc, item.get("throw_range", 12))

func cancel_smoke_deploy() -> void:
	pending_smoke_deploy = false
	_pending_smoke_item  = {}
	_pending_smoke_inv_idx = -1
	EventBus.hide_range_ring.emit()

func execute_smoke_deploy(target_cell: Vector2i, thrower: Node) -> void:
	var item: Dictionary = _pending_smoke_item
	if active and not spend_ap(item.get("ap_cost", 2)):
		return

	# Accuracy: miss chance decreases with ranged skill. High chance to land on target.
	var ranged_skill: float = _get_skill_total(thrower, "ranged")
	var miss_chance: float = maxf(0.0, 0.30 - ranged_skill * 0.006)
	var final_target: Vector2i = target_cell
	if randf() < miss_chance:
		var dirs: Array[Vector2i] = [
			Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1),
			Vector2i(1,1), Vector2i(-1,1), Vector2i(1,-1), Vector2i(-1,-1),
		]
		final_target = target_cell + dirs[randi() % dirs.size()]
		EventBus.combat_log.emit("Smoke bomb lands 1 tile off target.")

	GameManager.add_smoke_zone(final_target, item.get("smoke_radius", 2), item.get("smoke_turns", 3))

	var inv: Array = GameManager.player_data.get("inventory", [])
	var idx: int = _pending_smoke_inv_idx
	if idx >= 0 and idx < inv.size():
		inv.remove_at(idx)
		GameManager.player_data["inventory"] = inv

	EventBus.combat_log.emit("Smoke bomb deployed — cloud lasts %d rounds." % item.get("smoke_turns", 3))
	pending_smoke_deploy  = false
	_pending_smoke_item   = {}
	_pending_smoke_inv_idx = -1
	EventBus.hide_range_ring.emit()
	if active:
		EventBus.resources_changed.emit(thrower)

func begin_blast_tag_deploy(item: Dictionary, inv_idx: int) -> void:
	pending_blast_tag_deploy = true
	_pending_blast_tag_item  = item
	_pending_blast_tag_inv_idx = inv_idx
	if GameManager.player != null:
		var pc: Vector2i = GameManager.player.get("grid_cell") if GameManager.player.get("grid_cell") != null else Vector2i(40, 40)
		EventBus.show_range_ring.emit(pc, item.get("throw_range", 12))

func cancel_blast_tag_deploy() -> void:
	pending_blast_tag_deploy   = false
	_pending_blast_tag_item    = {}
	_pending_blast_tag_inv_idx = -1
	EventBus.hide_range_ring.emit()

# ── Zone-transition safety net ────────────────────────────────────────────────
# Wipes every "armed" targeting/throw/deploy mode in one shot. This autoload's
# state survives zone transitions (unlike the Player instance, which is freed
# and recreated), so any of these flags left set after crossing a zone boundary
# will silently swallow every left-click in the new zone — routing clicks into
# a deploy/throw handler instead of normal movement. That looks exactly like
# "stuck after transitioning zones" to the player. Call this on EVERY zone exit,
# no matter which entry point triggered it (walking off an edge, ladders,
# tunnels, ...) — main.gd's _on_zone_exit is the single funnel all of those
# go through, so that's where this belongs.
func reset_pending_actions() -> void:
	pending_weapon = {}
	sneak_attack_pending = false
	pending_smoke_deploy = false
	_pending_smoke_item = {}
	_pending_smoke_inv_idx = -1
	pending_blast_tag_deploy   = false
	_pending_blast_tag_item    = {}
	_pending_blast_tag_inv_idx = -1
	blast_tag_armed = false
	blast_tag_cell  = Vector2i(-1, -1)
	EventBus.hide_range_ring.emit()
	EventBus.hide_attack_range_overlay.emit()

func execute_blast_tag_throw(target_cell: Vector2i, thrower: Node, target_entity = null) -> void:
	var item: Dictionary = _pending_blast_tag_item
	if active and not spend_ap(item.get("ap_cost", 2)):
		return
	var final_cell: Vector2i = target_cell
	if target_entity != null and is_instance_valid(target_entity):
		var ranged_skill: float = _get_skill_total(thrower, "ranged")
		var dodge_val: float    = _get_skill_total(target_entity, "dodge")
		var hit_chance: int     = clampi(50 + int((ranged_skill - dodge_val) * 2.0), 5, 95)
		if randi_range(1, 100) <= hit_chance:
			var e_cell = target_entity.get("grid_cell")
			if e_cell != null:
				final_cell = e_cell
			var t_name: String = target_entity.get("entity_name") if target_entity.get("entity_name") != null else "target"
			EventBus.combat_log.emit("Blast Tag sticks to %s!" % t_name)
		else:
			var dirs: Array[Vector2i] = [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1),
				Vector2i(1,1),Vector2i(-1,1),Vector2i(1,-1),Vector2i(-1,-1)]
			final_cell = target_cell + dirs[randi() % dirs.size()] * randi_range(1, 2)
			EventBus.combat_log.emit("Blast Tag misses — lands off target.")
	else:
		var ranged_skill: float = _get_skill_total(thrower, "ranged")
		var miss_chance: float  = maxf(0.0, 0.30 - ranged_skill * 0.006)
		if randf() < miss_chance:
			var dirs: Array[Vector2i] = [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1),
				Vector2i(1,1),Vector2i(-1,1),Vector2i(1,-1),Vector2i(-1,-1)]
			final_cell = target_cell + dirs[randi() % dirs.size()]
			EventBus.combat_log.emit("Blast Tag lands 1 tile off target.")
	blast_tag_armed = true
	blast_tag_cell  = final_cell
	pending_blast_tag_deploy   = false
	_pending_blast_tag_item    = {}
	_pending_blast_tag_inv_idx = -1
	EventBus.hide_range_ring.emit()
	EventBus.combat_log.emit("Blast Tag planted — ready to detonate.")
	var zone: TileScene = GameManager.current_zone as TileScene
	if zone != null:
		zone.queue_redraw()
	if active:
		EventBus.resources_changed.emit(thrower)

func execute_blast_tag_detonate(thrower: Node) -> void:
	if not blast_tag_armed:
		return
	# SP cost check
	var sp_cost: int = 2
	if thrower == GameManager.player and GameManager.player != null:
		if GameManager.player.current_spirit < sp_cost:
			EventBus.combat_log.emit("Not enough Spirit to detonate the Blast Tag — requires %d SP." % sp_cost)
			return
	if active and not spend_ap(2):
		return
	if thrower == GameManager.player and GameManager.player != null:
		GameManager.player.current_spirit -= sp_cost
		EventBus.resources_changed.emit(thrower)
	var center: Vector2i = blast_tag_cell
	var radius: int = 4
	# Willpower modifier
	var wil_val: int = 5
	if thrower == GameManager.player:
		wil_val = GameManager.player_data.get("stats", {}).get("willpower", 5)
	else:
		var wv = thrower.get("stat_willpower")
		if wv != null: wil_val = int(wv)
	var wil_mod: int = Entity.modifier(wil_val)
	var log_lines: PackedStringArray = ["── Blast Tag detonates at [%d,%d]! ──" % [center.x, center.y]]
	var zone: TileScene = GameManager.current_zone as TileScene
	if zone != null:
		for entity in zone.get_all_entities():
			if entity == thrower:
				continue
			var e_cell = entity.get("grid_cell")
			if e_cell == null:
				continue
			var dx: int = center.x - (e_cell as Vector2i).x
			var dy: int = center.y - (e_cell as Vector2i).y
			if float(dx*dx + dy*dy) > float(radius * radius):
				continue
			var ent_name: String = entity.get("entity_name") if entity.get("entity_name") != null else "?"
			var phys_raw: int = max(1, Entity.roll_dice("2d6") + wil_mod)
			var phys_final: float = entity.calc_damage_received(phys_raw, {"damage_type":"physical"}) \
					if entity.has_method("calc_damage_received") else float(phys_raw)
			entity.current_hp -= phys_final
			EventBus.damage_dealt.emit(entity, phys_final, "attack")
			EventBus.damage_floater.emit(entity, "-%.1f" % phys_final, Color(0.90, 0.90, 0.90))
			var fire_raw: int = max(1, Entity.roll_dice("2d6") + wil_mod)
			var fire_final: float = entity.calc_damage_received(fire_raw, {"damage_type":"fire"}) \
					if entity.has_method("calc_damage_received") else float(fire_raw)
			entity.current_hp -= fire_final
			EventBus.damage_dealt.emit(entity, fire_final, "attack")
			EventBus.damage_floater.emit(entity, "-%.1f fire" % fire_final, Color(1.0, 0.50, 0.05))
			log_lines.append("  %s — %.1f physical + %.1f fire" % [ent_name, phys_final, fire_final])
	EventBus.combat_log.emit("\n".join(log_lines))
	# Remove one blast_tag from inventory
	var inv: Array = GameManager.player_data.get("inventory", [])
	for i in range(inv.size() - 1, -1, -1):
		if inv[i].get("id", "") == "blast_tag":
			inv.remove_at(i)
			break
	GameManager.player_data["inventory"] = inv
	EventBus.inventory_changed.emit()
	EventBus.blast_tag_detonation.emit(center, radius)
	blast_tag_armed = false
	blast_tag_cell  = Vector2i(-1, -1)
	zone = GameManager.current_zone as TileScene
	if zone != null:
		zone.queue_redraw()
	_check_combat_end()
	if active:
		EventBus.resources_changed.emit(thrower)

func _begin_turn() -> void:
	var e = current_entity()
	if e == null or not is_instance_valid(e):
		return
	# Don't tick status effects (bleed, etc.) in tactical mode — no combat is happening
	if not tactical_mode:
		_process_status_effects(e)
	# Decrement smoke zones at the start of each player turn
	if e == GameManager.player:
		GameManager.tick_smoke_zones()
	if not active:   # entity died from status effects, combat already ended
		return
	# Entity died from status effects but other combatants remain — skip to next turn
	if not _is_alive(e):
		var attempts := 0
		while attempts < participants.size():
			turn_index = (turn_index + 1) % participants.size()
			if turn_index == 0:
				round += 1
			if _is_alive(participants[turn_index]):
				break
			attempts += 1
		_begin_turn()
		return
	var ts = turn_state.get(e)
	if ts == null:
		return
	var ex: int = _exhaustion_for(e)
	var base_mp: int = maxi(0, e.stat_agility * 2 - ex * 2)
	ts["ap"] = maxi(1, e.stat_agility - ex)
	ts["mp"] = floori(base_mp * 0.2) if e.is_overburdened() else base_mp
	ts["runner_bonus_mp"] = 0
	e.current_ap = ts["ap"]
	e.current_mp = ts["mp"]

	# Dazed: halve AP and MP, schedule clearing at end of this turn
	if e.has_method("get") and e.get("status_effects") != null \
			and not e.status_effects.get("dazed", []).is_empty():
		ts["ap"] = maxi(1, ts["ap"] / 2)
		ts["mp"] = ts["mp"] / 2
		e.current_ap = ts["ap"]
		e.current_mp = ts["mp"]
		ts["dazed_clearing"] = true
		var dazed_name: String = e.get("entity_name") if e.get("entity_name") != null else "?"
		EventBus.combat_log.emit("%s is Dazed — AP and MP halved this turn!" % dazed_name)
		EventBus.damage_floater.emit(e, "dazed!", Color(0.85, 0.65, 0.10))
		EventBus.resources_changed.emit(e)

	EventBus.turn_started.emit(e)

func _exhaustion_for(entity: Node) -> int:
	if entity != GameManager.player:
		return 0
	return GameManager.player_data.get("exhaustion_stacks", 0)

func _tick_cooldowns(entity: Node) -> void:
	var ts = turn_state.get(entity, {})
	var cds: Dictionary = ts.get("cooldowns", {})
	for key in cds.keys():
		if cds[key] > 0:
			cds[key] -= 1

func _end_combat(victor_side: String) -> void:
	active = false
	GameManager.combat_mode = false
	tactical_mode = false
	GameManager.tactical_mode = false
	participants.clear()
	turn_state.clear()
	turn_index = 0
	pending_weapon = {}
	sneak_attack_pending = false
	pending_blast_tag_deploy   = false
	_pending_blast_tag_item    = {}
	_pending_blast_tag_inv_idx = -1
	EventBus.combat_ended.emit(victor_side)

func _check_combat_end() -> void:
	if not active or tactical_mode:
		return
	var player_alive := _any_alive("player")
	var enemy_alive  := _any_alive("enemy")
	if not player_alive or not enemy_alive:
		_end_combat("player" if player_alive else "enemy")

func _is_alive(entity) -> bool:
	if not is_instance_valid(entity):
		return false
	if entity.has_method("get") and entity.get("current_hp") != null:
		return entity.current_hp > 0
	return true

func _any_alive(side: String) -> bool:
	for e in participants:
		if not is_instance_valid(e) or not _is_alive(e):
			continue
		var is_player_entity = (e == GameManager.player)
		if side == "player" and is_player_entity:
			return true
		if side == "enemy" and not is_player_entity:
			return true
	return false

# ── Attack resolution ─────────────────────────────────────────────────────────
# weapon: item dictionary from DataManager. Pass DataManager.get_item("unarmed") for unarmed.
func resolve_attack(attacker: Node, defender: Node, weapon: Dictionary) -> void:
	# Point-blank check: only applies when the attack is ranged (target not adjacent)
	var pb_rule: String = weapon.get("point_blank", "")
	if pb_rule != "" and _chebyshev(attacker, defender) > 1 and attacker_at_point_blank(attacker):
		if pb_rule == "blocked":
			var atk_name: String = attacker.get("entity_name") if attacker.get("entity_name") != null else "?"
			EventBus.combat_log.emit("%s can't fire %s — an enemy is too close!" % [atk_name, weapon.get("name", "weapon")])
			return
		# "disadvantage" falls through — handled in the roll below

	# Line-of-sight, cover, and smoke check for ranged attacks
	var cover_penalty: int = 0
	var cover_log: String  = ""
	var smoke_penalty: int = 0
	var smoke_log: String  = ""
	if weapon.get("range", 1) > 1 and _chebyshev(attacker, defender) > 1:
		var zone: TileScene = GameManager.current_zone as TileScene
		if zone != null:
			var atk_cell = attacker.get("grid_cell")
			var def_cell = defender.get("grid_cell")
			if atk_cell != null and def_cell != null:
				if not zone.has_line_of_sight(atk_cell as Vector2i, def_cell as Vector2i):
					var atk_name_los: String = attacker.get("entity_name") if attacker.get("entity_name") != null else "?"
					var def_name_los: String = defender.get("entity_name") if defender.get("entity_name") != null else "?"
					EventBus.combat_log.emit("%s → %s  [%s]\n  No line of sight — attack blocked by cover!" % [
						atk_name_los, def_name_los, weapon.get("name", "weapon")])
					return
				var cover_result := _calc_cover_penalty(zone, atk_cell as Vector2i, def_cell as Vector2i)
				cover_penalty = cover_result[0]
				cover_log     = cover_result[1]
				# Smoke zone check
				if GameManager.is_in_smoke(atk_cell as Vector2i) \
						or GameManager.is_in_smoke(def_cell as Vector2i) \
						or GameManager.path_crosses_smoke(atk_cell as Vector2i, def_cell as Vector2i):
					smoke_penalty = -40
					smoke_log = "smoke (−40 to hit)"

	# Spirit cost check for spells (must pass before spending AP)
	var spirit_cost: int = weapon.get("spirit_cost", 0)
	if spirit_cost > 0 and attacker == GameManager.player:
		var p_node = GameManager.player
		if p_node == null or p_node.current_spirit < spirit_cost:
			EventBus.combat_log.emit("Not enough Spirit — %s requires %d SP." % [weapon.get("name", "spell"), spirit_cost])
			return

	var props: Array       = weapon.get("properties", [])
	var effective_ap: int = weapon.get("ap_cost", 1)
	if "unarmed_type" in props and attacker == GameManager.player and GameManager.has_feat("fast_hands"):
		effective_ap = maxi(1, effective_ap - 1)
	if not spend_ap(effective_ap):
		return

	# Deduct spirit after AP is confirmed spent
	if spirit_cost > 0 and attacker == GameManager.player:
		GameManager.player.current_spirit -= spirit_cost
		EventBus.resources_changed.emit(attacker)

	EventBus.attack_started.emit(attacker, defender)
	var skill_name: String = weapon.get("skill", "melee")
	var mod_adj: int       = -1 if "clumsy" in props else 0

	# Capture full roll detail for the log
	var atk_skill: float  = _get_skill_total(attacker, skill_name, mod_adj)
	var resist_stat: String = weapon.get("resistance", "")
	var def_value: float
	var def_label: String
	if resist_stat != "":
		def_value = _get_stat_resist(defender, resist_stat)
		def_label = resist_stat.capitalize() + " Resist"
	else:
		def_value = _get_skill_total(defender, "dodge")
		def_label = "Dodge"
	var base_hit: int     = clampi(50 + int((atk_skill - def_value) * 2.0), 5, 95)
	var hit_chance: int   = clampi(base_hit + cover_penalty + smoke_penalty, 5, 95)
	var long_range_log: String = ""
	if attacker == GameManager.player and GameManager.has_feat("long_ranged"):
		var weapon_range: int = weapon.get("range", 1)
		if weapon_range > 1:
			var actual_dist: float = _euclidean(attacker, defender)
			if actual_dist > float(weapon_range):
				var fraction: float = clampf((actual_dist - float(weapon_range)) / float(weapon_range), 0.0, 1.0)
				var mult: float = 1.0 - fraction * 0.5
				hit_chance = clampi(int(float(hit_chance) * mult), 5, 95)
				long_range_log = "long range ×%.2f  (%.1f of %d tiles past normal)" % [mult, actual_dist - float(weapon_range), weapon_range]
	var roll: int         = randi_range(1, 100)
	# Disadvantage at point blank: roll twice, take the worse (higher number)
	var pb_disadvantage: bool = pb_rule == "disadvantage" and _chebyshev(attacker, defender) > 1 and attacker_at_point_blank(attacker)
	if pb_disadvantage:
		roll = maxi(roll, randi_range(1, 100))
	var hit: bool         = roll <= hit_chance
	# Graze: a miss that landed within GRAZE_MARGIN points of hitting — a glancing
	# blow that still does partial damage and has a reduced chance to apply effects.
	const GRAZE_MARGIN: int           = 10
	const GRAZE_DAMAGE_MULT: float    = 0.25
	const GRAZE_EFFECT_CHANCE_MULT: float = 0.5
	# Stat-resisted effects (e.g. Heat vs. Constitution) are an internal save, not
	# a physical attack roll — there's no "glancing blow" version of resisting magic,
	# so grazes only apply to ordinary accuracy-vs-Dodge attacks.
	var graze: bool       = resist_stat == "" and not hit and roll - hit_chance <= GRAZE_MARGIN
	var dmg_mult: float   = 1.0 if hit else GRAZE_DAMAGE_MULT

	var atk_name: String = attacker.get("entity_name") if attacker.get("entity_name") != null else "?"
	var def_name: String = defender.get("entity_name") if defender.get("entity_name") != null else "?"
	var wpn_name: String = weapon.get("name", "?")
	var result_str: String = "HIT" if hit else ("GRAZE" if graze else "MISS")
	var is_sneak_atk: bool = sneak_attack_pending and attacker == GameManager.player
	var log_lines: PackedStringArray = []
	if is_sneak_atk:
		log_lines.append("── Sneak Attack ──")
	log_lines.append_array(PackedStringArray([
		"%s → %s  [%s]" % [atk_name, def_name, wpn_name],
		"  %s %.1f vs %s %.1f → %d%% | roll %d — %s" % [
			skill_name.capitalize(), atk_skill, def_label, def_value, hit_chance, roll, result_str],
	]))
	if cover_log != "":
		log_lines.append("  (%s)" % cover_log)
	if long_range_log != "":
		log_lines.append("  (%s)" % long_range_log)
	if smoke_log != "":
		log_lines.append("  (%s)" % smoke_log)
	if pb_disadvantage:
		log_lines.append("  (point blank disadvantage — rolled twice, took worse)")

	if hit or graze:
		if graze:
			log_lines.append("  (graze — glancing blow: %d%% damage, %d%% effect chance)" \
					% [int(GRAZE_DAMAGE_MULT * 100.0), int(GRAZE_EFFECT_CHANCE_MULT * 100.0)])
		var effect_only: bool = "effect_only" in props
		if not effect_only:
			# ── Crit roll (a graze is already a glancing blow — it can't crit) ──────
			var crit_chance: float = _calc_crit_chance(attacker) if hit else 0.0
			var crit_roll: float   = randf() * 100.0
			var is_crit: bool      = crit_chance > 0.0 and crit_roll < crit_chance

			var weapon_immune: bool = defender.has_method("is_immune_to_weapon") \
					and defender.is_immune_to_weapon(weapon)
			if weapon_immune:
				log_lines.append("  Immune!")
				EventBus.damage_floater.emit(defender, "immune  0", Color(0.30, 0.50, 1.0))
			elif "use_melee_weapon_damage" in props:
				# ── Burning Palm: physical melee hit + bonus fire ───────────────────
				if is_crit:
					log_lines.append("  CRITICAL HIT!  [crit roll: %.0f%% < %.1f%%]" % [crit_roll, crit_chance])
				elif crit_chance > 0.0:
					log_lines.append("  Crit roll: %.0f%% vs %.1f%% — no crit" % [crit_roll, crit_chance])

				var melee_weapon: Dictionary = DataManager.get_item("unarmed")
				var melee_raw: int = Entity.roll_dice(str(melee_weapon.get("damage", "1d3")))
				var melee_gov: Dictionary = _get_weapon_governing_info(attacker, melee_weapon)
				var melee_mod: int    = melee_gov["mod"]
				var melee_stat: String = melee_gov["stat"]
				melee_raw = max(1, melee_raw + melee_mod)
				if is_crit:
					melee_raw *= 2
				var shield_block: Dictionary = _resolve_shield_block(defender, atk_skill, skill_name)
				if shield_block["log"] != "":
					log_lines.append(shield_block["log"])
				melee_raw = maxi(0, melee_raw - int(shield_block["flat"]))
				var melee_final: float = defender.calc_damage_received(melee_raw, melee_weapon) \
						if defender.has_method("calc_damage_received") else float(melee_raw)
				melee_final *= dmg_mult
				if melee_final != float(melee_raw):
					log_lines.append("  Melee:  %.1f  (%d raw, %.1f absorbed)" % [melee_final, melee_raw, float(melee_raw) - melee_final])
				else:
					log_lines.append("  Melee:  %.1f" % melee_final)
				if melee_mod != 0 and melee_stat != "":
					log_lines.append("  (melee mod: %+d from %s)" % [melee_mod, melee_stat.capitalize()])
				defender.current_hp -= melee_final
				EventBus.damage_dealt.emit(defender, melee_final, "attack")
				if is_crit:
					EventBus.damage_floater.emit(defender, "CRIT! -%.1f" % melee_final, Color(1.0, 0.85, 0.15))
				else:
					EventBus.damage_floater.emit(defender, "-%.1f" % melee_final, _damage_color(melee_final))

				var bonus_fire: String = weapon.get("bonus_fire_damage", "")
				if bonus_fire != "":
					var wil_val: int = 5
					if attacker == GameManager.player:
						wil_val = GameManager.player_data.get("stats", {}).get("willpower", 5)
					else:
						var wv = attacker.get("stat_willpower")
						if wv != null: wil_val = int(wv)
					var wil_mod: int = Entity.modifier(wil_val)
					var fire_raw: int = max(1, Entity.roll_dice(bonus_fire) + wil_mod)
					var fire_dummy: Dictionary = {"damage_type": "fire"}
					var fire_final: float = defender.calc_damage_received(fire_raw, fire_dummy) \
							if defender.has_method("calc_damage_received") else float(fire_raw)
					fire_final *= dmg_mult
					if fire_final != float(fire_raw):
						log_lines.append("  Fire:   %.1f  (%d raw, %.1f absorbed)  [fire]" % [fire_final, fire_raw, float(fire_raw) - fire_final])
					else:
						log_lines.append("  Fire:   %.1f  [fire]" % fire_final)
					if wil_mod != 0:
						log_lines.append("  (fire mod: %+d from Willpower)" % wil_mod)
					defender.current_hp -= fire_final
					EventBus.damage_dealt.emit(defender, fire_final, "attack")
					EventBus.damage_floater.emit(defender, "-%.0f fire" % fire_final, Color(1.0, 0.55, 0.10))
			else:
				var raw: int = Entity.roll_dice(str(weapon.get("damage", "1")))
				var gov_info: Dictionary = _get_weapon_governing_info(attacker, weapon)
				var gov_mod: int         = gov_info["mod"]
				var gov_stat: String     = gov_info["stat"]
				raw += gov_mod
				raw  = max(1, raw)
				if is_crit:
					raw *= 2
				if weapon.get("damage_type", "physical") == "physical":
					var shield_block: Dictionary = _resolve_shield_block(defender, atk_skill, skill_name)
					if shield_block["log"] != "":
						log_lines.append(shield_block["log"])
					raw = maxi(0, raw - int(shield_block["flat"]))
				var dmg_weapon: Dictionary = weapon
				if attacker == GameManager.player and GameManager.has_feat("brutal"):
					var wprops: Array = weapon.get("properties", [])
					if "armor_pierce" in wprops or "armor_pierce_light" in wprops:
						dmg_weapon = weapon.duplicate()
						dmg_weapon["pierce_multiplier"] = 1.3
				if weapon.get("armor_ignore_pct", 0.0) > 0.0:
					if dmg_weapon == weapon:
						dmg_weapon = weapon.duplicate()
					dmg_weapon["armor_ignore_pct"] = weapon.get("armor_ignore_pct", 0.0)
				var final_dmg: float
				if defender.has_method("calc_damage_received"):
					final_dmg = defender.calc_damage_received(raw, dmg_weapon)
				else:
					final_dmg = float(raw)
				final_dmg *= dmg_mult
				if is_crit:
					log_lines.append("  CRITICAL HIT!  [crit roll: %.0f%% < %.1f%%]" % [crit_roll, crit_chance])
				elif crit_chance > 0.0:
					log_lines.append("  Crit roll: %.0f%% vs %.1f%% — no crit" % [crit_roll, crit_chance])
				var dtype: String = weapon.get("damage_type", "physical")
				var dtype_tag: String = ""  if dtype == "physical" else "  [%s]" % dtype
				if final_dmg != float(raw):
					log_lines.append("  Damage: %.1f%s  (%d raw, %.1f absorbed)" % [final_dmg, dtype_tag, raw, float(raw) - final_dmg])
				else:
					log_lines.append("  Damage: %.1f%s" % [final_dmg, dtype_tag])
				if gov_mod != 0 and gov_stat != "":
					log_lines.append("  (dmg mod: %+d from %s)" % [gov_mod, gov_stat.capitalize()])
				defender.current_hp -= final_dmg
				EventBus.damage_dealt.emit(defender, final_dmg, "attack")
				if is_crit:
					EventBus.damage_floater.emit(defender, "CRIT! -%.1f" % final_dmg, Color(1.0, 0.85, 0.15))
				else:
					EventBus.damage_floater.emit(defender, "-%.1f" % final_dmg, _damage_color(final_dmg))

				# Bonus scripture damage (enchanted wraps: +1d6+WIL physical)
				var bonus_scripture: String = weapon.get("bonus_scripture_damage", "")
				if bonus_scripture != "":
					var sc_wil: int = 5
					if attacker == GameManager.player:
						sc_wil = GameManager.player_data.get("stats", {}).get("willpower", 5)
					else:
						var wv2 = attacker.get("stat_willpower")
						if wv2 != null: sc_wil = int(wv2)
					var sc_mod: int = Entity.modifier(sc_wil)
					var sc_raw: int = max(1, Entity.roll_dice(bonus_scripture) + sc_mod)
					if is_crit: sc_raw *= 2
					var sc_final: float = defender.calc_damage_received(sc_raw, {"damage_type":"physical"}) \
							if defender.has_method("calc_damage_received") else float(sc_raw)
					sc_final *= dmg_mult
					if sc_final != float(sc_raw):
						log_lines.append("  Scripture: %.1f  (%d raw, %.1f absorbed)" % [sc_final, sc_raw, float(sc_raw) - sc_final])
					else:
						log_lines.append("  Scripture: %.1f" % sc_final)
					if sc_mod != 0:
						log_lines.append("  (scripture mod: %+d from Willpower)" % sc_mod)
					defender.current_hp -= sc_final
					EventBus.damage_dealt.emit(defender, sc_final, "attack")
					EventBus.damage_floater.emit(defender, "-%.1f scripture" % sc_final, Color(0.60, 0.85, 1.0))

		var effect_chance_mult: float = 1.0 if hit else GRAZE_EFFECT_CHANCE_MULT
		var on_hit_lines: PackedStringArray = _apply_on_hit_properties(attacker, defender, weapon, effect_chance_mult)
		log_lines.append_array(on_hit_lines)
	else:
		EventBus.damage_floater.emit(defender, "miss", Color(0.65, 0.65, 0.70))

	if "reload" in props:
		set_weapon_loaded(attacker, weapon.get("name", ""), false)

	if is_sneak_atk:
		sneak_attack_pending = false
	EventBus.combat_log.emit("\n".join(log_lines))
	EventBus.attack_resolved.emit(attacker, hit)
	_check_combat_end()

# Spends AP and marks weapon as loaded again.
func reload_weapon(entity: Node, weapon: Dictionary) -> void:
	var cost: int = weapon.get("reload_cost", 2)
	if not spend_ap(cost):
		return
	set_weapon_loaded(entity, weapon.get("name", ""), true)

# Disarm action: costs same AP as a normal attack, uses melee(DEX) roll.
func resolve_disarm(attacker: Node, defender: Node) -> void:
	if not spend_ap(2):
		return
	if get_cooldown(attacker, "disarm") > 0:
		return
	# Use melee skill for the hit roll but force DEX governing
	var atk_skill := _get_skill_total(attacker, "melee")
	var def_dodge := _get_skill_total(defender, "dodge")
	var chance: int = clampi(int(atk_skill * 1.5 - def_dodge), 5, 95)
	if randi_range(1, 100) <= chance:
		# Knock the first found weapon out of a hand slot
		for slot in ["hand_1", "hand_2"]:
			var item = defender.equipment.get(slot, null) if defender.has_method("get") else null
			if item != null and item.get("type", "") == "weapon":
				defender.equipment[slot] = null
				defender.inventory.append(item)
				break
	set_cooldown(attacker, "disarm", 3)

# ── Status effect processing ──────────────────────────────────────────────────

# Called from outside combat (e.g. player.gd every 10 seconds) to tick one
# combat-turn's worth of status effects on an entity.
func tick_status_effects(entity: Node) -> void:
	_process_status_effects(entity)
	EventBus.resources_changed.emit(entity)

func _process_status_effects(entity: Node) -> void:
	if not entity.has_method("get") or entity.get("status_effects") == null:
		return

	# ── Bleed ─────────────────────────────────────────────────────────────────────
	var bleed_stacks: Array = entity.status_effects.get("bleed", [])
	if not bleed_stacks.is_empty():
		var to_remove: Array = []
		var total_dmg := 0
		for i in range(bleed_stacks.size()):
			total_dmg        += Entity.roll_dice("1d3")
			bleed_stacks[i]  -= 1
			if bleed_stacks[i] <= 0:
				to_remove.append(i)
		to_remove.reverse()
		for i in to_remove:
			bleed_stacks.remove_at(i)
		if bleed_stacks.is_empty():
			entity.status_effects.erase("bleed")
		else:
			entity.status_effects["bleed"] = bleed_stacks
		if total_dmg > 0:
			entity.current_hp -= total_dmg
			var stacks_left: int = bleed_stacks.size()
			var ent_name: String = entity.get("entity_name") if entity.get("entity_name") != null else "?"
			EventBus.combat_log.emit("%s bleeds — %.1f dmg  (%d stack%s remaining)" % [
				ent_name, float(total_dmg), stacks_left, "s" if stacks_left != 1 else ""])
			EventBus.damage_dealt.emit(entity, total_dmg, "bleed")
			EventBus.damage_floater.emit(entity, "-%d bleed" % total_dmg, Color(0.75, 0.10, 0.10))
			_check_combat_end()
		if bleed_stacks.is_empty():
			EventBus.status_cleared.emit(entity, "bleed")

	# ── Poison ticking ──────────────────────────────────────────────────────────
	var poison_stacks: Array = entity.status_effects.get("poison", [])
	if not poison_stacks.is_empty():
		var to_remove_p: Array = []
		var total_pdmg := 0
		for i in range(poison_stacks.size()):
			total_pdmg         += Entity.roll_dice("1d6")
			poison_stacks[i]   -= 1
			if poison_stacks[i] <= 0:
				to_remove_p.append(i)
		to_remove_p.reverse()
		for i in to_remove_p:
			poison_stacks.remove_at(i)
		if poison_stacks.is_empty():
			entity.status_effects.erase("poison")
		else:
			entity.status_effects["poison"] = poison_stacks

		if total_pdmg > 0:
			entity.current_hp -= total_pdmg
			var p_stacks_left: int = poison_stacks.size()
			var ent_name_p: String = entity.get("entity_name") if entity.get("entity_name") != null else "?"
			EventBus.combat_log.emit("%s is poisoned — %.1f dmg  (%d stack%s remaining)" % [
				ent_name_p, float(total_pdmg), p_stacks_left, "s" if p_stacks_left != 1 else ""])
			EventBus.damage_dealt.emit(entity, total_pdmg, "poison")
			EventBus.damage_floater.emit(entity, "-%d poison" % total_pdmg, Color(0.25, 0.82, 0.25))
			_check_combat_end()
		if poison_stacks.is_empty():
			EventBus.status_cleared.emit(entity, "poison")

	# ── Burning ──────────────────────────────────────────────────────────────────
	var burning_stacks: Array = entity.status_effects.get("burning", [])
	if not burning_stacks.is_empty():
		burning_stacks[0] -= 1
		var burn_dmg: int = Entity.roll_dice("1d4")
		var fire_weapon: Dictionary = {"damage_type": "fire"}
		var final_burn: float = entity.calc_damage_received(burn_dmg, fire_weapon) if entity.has_method("calc_damage_received") else float(burn_dmg)
		if burning_stacks[0] <= 0:
			entity.status_effects.erase("burning")
		else:
			entity.status_effects["burning"] = burning_stacks
		entity.current_hp -= final_burn
		var ent_name_b: String = entity.get("entity_name") if entity.get("entity_name") != null else "?"
		EventBus.combat_log.emit("%s is burning — %.1f fire dmg  (%d turn%s remaining)" % [
			ent_name_b, final_burn,
			burning_stacks[0] if not burning_stacks.is_empty() else 0,
			"s" if (not burning_stacks.is_empty() and burning_stacks[0] != 1) else ""])
		EventBus.damage_dealt.emit(entity, final_burn, "burning")
		EventBus.damage_floater.emit(entity, "-%.0f fire" % final_burn, Color(1.0, 0.50, 0.10))
		_check_combat_end()
		if burning_stacks.is_empty():
			EventBus.status_cleared.emit(entity, "burning")

	# ── Heated ───────────────────────────────────────────────────────────────────
	var heated_stacks: Array = entity.status_effects.get("heated", [])
	if not heated_stacks.is_empty():
		var wil_m: int = entity.get("heated_wil_mod") if entity.get("heated_wil_mod") != null else 0
		var to_remove_h: Array = []
		var total_hdmg: int = 0
		var num_stacks: int = heated_stacks.size()
		for i in range(num_stacks):
			total_hdmg += Entity.roll_dice("1d2")
			heated_stacks[i] -= 1
			if heated_stacks[i] <= 0:
				to_remove_h.append(i)
		total_hdmg = maxi(1, total_hdmg + wil_m)
		to_remove_h.reverse()
		for i in to_remove_h:
			heated_stacks.remove_at(i)
		if heated_stacks.is_empty():
			entity.status_effects.erase("heated")
		else:
			entity.status_effects["heated"] = heated_stacks
		# 40% fire resistance bypass for heated ticks
		var resist: float = entity.get("fire_resistance") if entity.get("fire_resistance") != null else 0.0
		var eff_resist: float = resist * 0.6
		var final_hdmg: float = maxf(1.0, float(total_hdmg) * (1.0 - eff_resist))
		entity.current_hp -= final_hdmg
		var stacks_left_h: int = heated_stacks.size()
		var ent_name_h: String = entity.get("entity_name") if entity.get("entity_name") != null else "?"
		EventBus.combat_log.emit("%s takes heat damage — %.1f fire dmg  (%d stack%s)" % [
			ent_name_h, final_hdmg, stacks_left_h, "s" if stacks_left_h != 1 else ""])
		EventBus.damage_dealt.emit(entity, final_hdmg, "heated")
		EventBus.damage_floater.emit(entity, "-%.0f heat" % final_hdmg, Color(1.0, 0.55, 0.10))
		_check_combat_end()
		if heated_stacks.is_empty():
			EventBus.status_cleared.emit(entity, "heated")
		# Per-stack burning chance (12% per stack that ticked)
		for _i in range(num_stacks):
			if randf() < 0.12:
				_try_apply_burning_direct(entity)
				break   # apply at most once per tick

func _apply_on_hit_properties(attacker: Node, defender: Node, weapon: Dictionary, chance_mult: float = 1.0) -> PackedStringArray:
	var lines: PackedStringArray = []
	var props: Array = weapon.get("properties", [])
	if "bleed" in props:
		lines.append_array(_try_apply_bleed(defender, attacker, chance_mult))
	if "burning" in props:
		lines.append_array(_try_apply_burning(defender, chance_mult))
	if "heated" in props:
		var wil_mod: int = _get_weapon_governing_mod(attacker, weapon)
		lines.append_array(_try_apply_heated(defender, wil_mod, chance_mult))
	if weapon.get("poisoned", false):
		lines.append_array(_try_apply_poison(defender, chance_mult))
	return lines

func _check_shrug_off(entity: Node) -> bool:
	return entity == GameManager.player and GameManager.has_feat("shrug_off") and randf() < 0.10

func _try_apply_bleed(defender: Node, attacker: Node = null, chance_mult: float = 1.0) -> PackedStringArray:
	if not defender.has_method("get") or defender.get("status_effects") == null:
		return PackedStringArray()
	if defender.has_method("is_immune_to_status") and defender.is_immune_to_status("bleed"):
		var def_name: String = defender.get("entity_name") if defender.get("entity_name") != null else "Target"
		return PackedStringArray(["  %s is immune to bleed." % def_name])
	var con_mod := Entity.modifier(defender.stat_constitution)
	var chance: float
	if con_mod >= 0:
		chance = 0.60 * pow(0.85, float(con_mod))
	else:
		chance = min(0.95, 0.60 + abs(con_mod) * 0.08)
	if attacker == GameManager.player and GameManager.has_feat("bloodletting"):
		chance = minf(0.95, chance * 1.3)
	chance *= chance_mult

	var roll: float = randf()
	var pct: int    = int(chance * 100)
	var roll_pct: int = int(roll * 100)
	if roll < chance:
		if _check_shrug_off(defender):
			return PackedStringArray(["  Bleed: roll %d%% vs %d%% — shrugged off" % [roll_pct, pct]])
		if not defender.status_effects.has("bleed"):
			defender.status_effects["bleed"] = []
		defender.status_effects["bleed"].append(3)
		EventBus.status_applied.emit(defender, "bleed")
		EventBus.damage_floater.emit(defender, "bleed", Color(0.85, 0.12, 0.12))
		return PackedStringArray(["  Bleed: roll %d%% vs %d%% — APPLIED" % [roll_pct, pct]])
	else:
		return PackedStringArray(["  Bleed: roll %d%% vs %d%% — resisted" % [roll_pct, pct]])

func _try_apply_poison(defender: Node, chance_mult: float = 1.0) -> PackedStringArray:
	if not defender.has_method("get") or defender.get("status_effects") == null:
		return PackedStringArray()
	if defender.has_method("is_immune_to_status") and defender.is_immune_to_status("poison"):
		var def_name: String = defender.get("entity_name") if defender.get("entity_name") != null else "Target"
		return PackedStringArray(["  %s is immune to poison." % def_name])
	# Higher base proc chance than bleed (75%), less reduced by CON
	var con_val: int = defender.get("stat_constitution") if defender.get("stat_constitution") != null else 5
	var con_mod := Entity.modifier(con_val)
	var chance: float
	if con_mod >= 0:
		chance = 0.75 * pow(0.90, float(con_mod))
	else:
		chance = minf(0.98, 0.75 + float(abs(con_mod)) * 0.05)
	chance *= chance_mult
	var roll: float   = randf()
	var pct: int      = int(chance * 100.0)
	var roll_pct: int = int(roll * 100.0)
	if roll < chance:
		if _check_shrug_off(defender):
			return PackedStringArray(["  Poison: roll %d%% vs %d%% — shrugged off" % [roll_pct, pct]])
		if not defender.status_effects.has("poison"):
			defender.status_effects["poison"] = []
		defender.status_effects["poison"].append(3)
		EventBus.status_applied.emit(defender, "poison")
		EventBus.damage_floater.emit(defender, "poisoned", Color(0.25, 0.82, 0.25))
		return PackedStringArray(["  Poison: roll %d%% vs %d%% — APPLIED" % [roll_pct, pct]])
	else:
		return PackedStringArray(["  Poison: roll %d%% vs %d%% — resisted" % [roll_pct, pct]])

func _try_apply_burning(defender: Node, chance_mult: float = 1.0) -> PackedStringArray:
	if not defender.has_method("get") or defender.get("status_effects") == null:
		return PackedStringArray()
	if defender.has_method("is_immune_to_status") and defender.is_immune_to_status("burning"):
		var n: String = defender.get("entity_name") if defender.get("entity_name") != null else "Target"
		return PackedStringArray(["  %s is immune to burning." % n])
	var con_mod := Entity.modifier(defender.stat_constitution)
	var chance: float
	if con_mod >= 0:
		chance = 0.30 * pow(0.85, float(con_mod))
	else:
		chance = minf(0.60, 0.30 + abs(con_mod) * 0.06)
	chance *= chance_mult
	var roll: float = randf()
	var pct: int    = int(chance * 100)
	if roll < chance:
		if _check_shrug_off(defender):
			return PackedStringArray(["  Burning: %d%% — shrugged off" % pct])
		defender.status_effects["burning"] = [4]   # can't stack — always refreshes to 4
		EventBus.status_applied.emit(defender, "burning")
		EventBus.damage_floater.emit(defender, "burning!", Color(1.0, 0.45, 0.10))
		return PackedStringArray(["  Burning: %d%% — APPLIED" % pct])
	return PackedStringArray(["  Burning: %d%% — resisted" % pct])

func _try_apply_burning_direct(defender: Node) -> void:
	if not defender.has_method("get") or defender.get("status_effects") == null:
		return
	if defender.has_method("is_immune_to_status") and defender.is_immune_to_status("burning"):
		return
	if _check_shrug_off(defender):
		return
	defender.status_effects["burning"] = [4]
	EventBus.status_applied.emit(defender, "burning")
	EventBus.damage_floater.emit(defender, "burning!", Color(1.0, 0.45, 0.10))

func _try_apply_heated(defender: Node, wil_mod: int, chance_mult: float = 1.0) -> PackedStringArray:
	if not defender.has_method("get") or defender.get("status_effects") == null:
		return PackedStringArray()
	const MAX_STACKS: int = 6
	if not defender.status_effects.has("heated"):
		defender.status_effects["heated"] = []
	var stacks: Array = defender.status_effects["heated"]
	if stacks.size() >= MAX_STACKS:
		return PackedStringArray(["  Heated: max stacks (%d) — no effect" % MAX_STACKS])
	# Heated normally always applies on a hit — a graze only has a reduced chance to.
	if chance_mult < 1.0 and randf() >= chance_mult:
		return PackedStringArray(["  Heated: glancing — no stack applied"])
	if _check_shrug_off(defender):
		return PackedStringArray(["  Heated: shrugged off"])
	stacks.append(4)
	defender.heated_wil_mod = wil_mod
	EventBus.status_applied.emit(defender, "heated")
	EventBus.damage_floater.emit(defender, "heated", Color(1.0, 0.65, 0.20))
	return PackedStringArray(["  Heated: stack applied (%d/%d)" % [stacks.size(), MAX_STACKS]])

# ── Damage floater color ─────────────────────────────────────────────────────
# Interpolates grey → dark crimson based on damage, capping at 100.
func _damage_color(dmg: int) -> Color:
	var t: float = clampf(dmg / 100.0, 0.0, 1.0)
	return Color(0.65, 0.65, 0.65).lerp(Color(0.55, 0.04, 0.04), t)

# ── Point-blank helpers ───────────────────────────────────────────────────────

# Returns true if any living enemy combatant is within 1 tile (Chebyshev) of attacker.
func attacker_at_point_blank(attacker: Node) -> bool:
	var atk_cell = attacker.get("grid_cell")
	if atk_cell == null:
		return false
	var atk_is_player: bool = (attacker == GameManager.player)
	for e in participants:
		if not is_instance_valid(e) or e == attacker or not _is_alive(e):
			continue
		if (e == GameManager.player) == atk_is_player:
			continue  # same side
		var e_cell = e.get("grid_cell")
		if e_cell == null:
			continue
		if maxi(abs(e_cell.x - atk_cell.x), abs(e_cell.y - atk_cell.y)) <= 1:
			return true
	return false

func _chebyshev(a: Node, b: Node) -> int:
	var ac = a.get("grid_cell")
	var bc = b.get("grid_cell")
	if ac == null or bc == null:
		return 0
	return maxi(abs(ac.x - bc.x), abs(ac.y - bc.y))

func _euclidean(a: Node, b: Node) -> float:
	var ac = a.get("grid_cell")
	var bc = b.get("grid_cell")
	if ac == null or bc == null:
		return 0.0
	var dx: int = ac.x - bc.x
	var dy: int = ac.y - bc.y
	return sqrt(float(dx * dx + dy * dy))

# Returns [penalty: int, description: String].
# Checks all cells adjacent to the defender for cover objects that partially
# block the attack angle. Requires defender to be adjacent to the cover cell.
func _calc_cover_penalty(zone: TileScene, atk_cell: Vector2i, def_cell: Vector2i) -> Array:
	var atk_dir := Vector2(float(atk_cell.x - def_cell.x), float(atk_cell.y - def_cell.y)).normalized()
	var best_coverage: float = 0.0
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			if dx == 0 and dy == 0:
				continue
			var cv := Vector2i(def_cell.x + dx, def_cell.y + dy)
			if not zone.cover_cells.has(cv):
				continue
			var cover_size: float = zone.cover_cells[cv]
			var cover_dir := Vector2(float(dx), float(dy)).normalized()
			var alignment := maxf(0.0, atk_dir.dot(cover_dir))
			var coverage  := cover_size * alignment
			if coverage > best_coverage:
				best_coverage = coverage
	if best_coverage >= 0.75:
		return [-40, "heavy cover (−40 to hit)"]
	elif best_coverage >= 0.50:
		return [-25, "partial cover (−25 to hit)"]
	elif best_coverage >= 0.25:
		return [-10, "light cover (−10 to hit)"]
	return [0, ""]

# ── Weapon governing modifier ─────────────────────────────────────────────────

func _get_weapon_governing_mod(entity: Node, weapon: Dictionary) -> int:
	return _get_weapon_governing_info(entity, weapon)["mod"]

# Returns {"mod": int, "stat": String} so the caller can show the correct stat in logs.
func _get_weapon_governing_info(entity: Node, weapon: Dictionary) -> Dictionary:
	var governing: Array  = weapon.get("governing", [])
	var half_dex: bool    = weapon.get("half_dex_damage", false)
	var best := 0
	var best_stat: String = ""
	for stat in governing:
		var val: int = entity.get("stat_" + stat) if entity.get("stat_" + stat) != null else 5
		var m: int   = val - 5
		if m > best:
			best = m
			best_stat = stat
	if half_dex and best_stat == "dexterity":
		best = best / 2
	return {"mod": best, "stat": best_stat}

# ── Shield blocking ────────────────────────────────────────────────────────────
# Shields (slot "hand", "block_flat" > 0) reduce incoming physical damage by a
# flat amount, but only on a successful block roll. The block is an opposed
# check, mirroring calc_hit_chance: the defender's melee skill — scaled by
# whichever of the shield's "governing" stats is best (hide/wooden: STR or DEX;
# heavier shields: DEX only) — versus whatever skill total the attacker used
# for their to-hit roll (melee or ranged). Higher melee than the attacker's
# skill used = blocked.
func _get_equipped_shield(defender: Node) -> Dictionary:
	var equip: Dictionary
	if defender == GameManager.player:
		equip = GameManager.player_data.get("equipment", {})
	else:
		var raw = defender.get("equipment")
		if raw == null:
			return {}
		equip = raw
	for slot in ["hand_1", "hand_2"]:
		var item = equip.get(slot, null)
		if item != null and item.get("block_flat", 0.0) > 0.0:
			return item
	return {}

# Returns {"flat": float, "log": String}. "flat" is the extra physical damage
# reduction to apply this hit (0.0 if no shield equipped or the block roll failed).
# atk_skill_used / atk_skill_name: the attacker's skill total/name from the to-hit roll.
func _resolve_shield_block(defender: Node, atk_skill_used: float, atk_skill_name: String) -> Dictionary:
	var shield: Dictionary = _get_equipped_shield(defender)
	if shield.is_empty():
		return {"flat": 0.0, "log": ""}

	var governing: Array  = shield.get("governing", ["strength", "dexterity"])
	var stat_mod: int     = -999
	var stat_used: String = ""
	for stat in governing:
		var val: int
		if defender == GameManager.player:
			val = GameManager.player_data.get("stats", {}).get(stat, 5)
		else:
			var raw = defender.get("stat_" + stat)
			val = int(raw) if raw != null else 5
		var m: int = Entity.modifier(val)
		if m > stat_mod:
			stat_mod = m
			stat_used = stat

	var melee_invested: int
	if defender == GameManager.player:
		melee_invested = GameManager.player_data.get("skills", {}).get("melee", 0)
	else:
		var sk = defender.get("skills")
		melee_invested = int(sk.get("melee", 0)) if sk != null else 0

	var block_flat: float = shield.get("block_flat", 0.0)
	# Defender's melee total, scaled by the shield's own governing stat(s)
	# rather than melee's usual best-of-STR/DEX.
	var def_skill_total: float = maxf(0.0, float(melee_invested) * (1.0 + float(stat_mod) * 0.1))
	var block_chance: int = clampi(50 + int((def_skill_total - atk_skill_used) * 2.0), 5, 95)
	var roll: int     = randi_range(1, 100)
	var blocked: bool = roll <= block_chance
	var stat_label: String = stat_used.capitalize() if stat_used != "" else "Strength"
	var result: String = ("BLOCKED — %d dmg absorbed" % int(block_flat)) if blocked else "failed"
	var line: String = "  %s Block: %s-melee %.1f vs %s %.1f → %d%% | roll %d — %s" \
			% [shield.get("name", "Shield"), stat_label, def_skill_total,
			   atk_skill_name.capitalize(), atk_skill_used, block_chance, roll, result]
	return {"flat": (block_flat if blocked else 0.0), "log": line}

# Stat-based resistance used by spells with "resistance": "<stat_name>".
# Formula mirrors sneak detection: (1 + mod) * 5 * level, minimum 0.
func _get_stat_resist(entity: Node, stat_name: String) -> float:
	var stat_val: int
	var lv: int
	if entity == GameManager.player:
		var stats: Dictionary = GameManager.player_data.get("stats", {})
		stat_val = stats.get(stat_name, 5)
		lv = GameManager.player_data.get("level", 1)
	else:
		var raw = entity.get("stat_" + stat_name)
		stat_val = int(raw) if raw != null else 5
		var lv_raw = entity.get("level")
		lv = int(lv_raw) if lv_raw != null else 1
	var mod: int = stat_val - 5
	return maxf(0.0, float((1 + mod) * 5 * lv))

func _get_skill_total(entity: Node, skill_name: String, mod_adj: int = 0) -> float:
	# For the player, skill data lives in player_data; for NPCs, use humanoid.get_skill_total()
	if entity == GameManager.player:
		var skills: Dictionary = GameManager.player_data.get("skills", {})
		var invested: int = skills.get(skill_name, 0)
		var stats: Dictionary = GameManager.player_data.get("stats", {})
		var gov_bonus: int = entity.get_equipment_governing_bonus(skill_name) if entity.has_method("get_equipment_governing_bonus") else 0
		var equip_skill: int = entity.get_equipment_skill_bonus(skill_name) if entity.has_method("get_equipment_skill_bonus") else 0
		var mod: float = _player_governing_mod(skill_name, stats) + gov_bonus + mod_adj
		return maxf(0.0, invested * (1.0 + mod * 0.1) + equip_skill)
	elif entity.has_method("get_skill_total"):
		return entity.get_skill_total(skill_name)
	return 0.0

# Returns the governing modifier for a skill as a float (ranged uses weighted PER+STR/DEX).
func _player_governing_mod(skill_name: String, stats: Dictionary) -> float:
	# Ranged: 70% perception + 30% best(STR, DEX) for to-hit
	if skill_name == "ranged":
		var per_mod: float  = float(stats.get("perception", 5) - 5)
		var str_mod: float  = float(stats.get("strength",   5) - 5)
		var dex_mod: float  = float(stats.get("dexterity",  5) - 5)
		return per_mod * 0.7 + maxf(str_mod, dex_mod) * 0.3

	const GOV = {
		"melee":            ["strength", "dexterity"],
		"dodge":            ["dexterity", "agility"],
		"convince":         ["willpower"],
		"intimidate":       ["strength", "willpower"],
		"sneak":            ["dexterity"],
		"sleight_of_hand":  ["dexterity"],
		"alchemy":          ["intelligence"],
		"occultism":        ["intelligence", "willpower"],
		"smithing":         ["intelligence", "strength"],
		"survival":         ["constitution", "willpower", "perception"],
		"cooking":          ["intelligence"],
	}
	var governing = GOV.get(skill_name, [])
	var best := 0
	for stat in governing:
		var val: int = stats.get(stat, 5)
		var m := val - 5
		if m > best:
			best = m
	return float(best)

# ── Crit chance ───────────────────────────────────────────────────────────────
# 70% PER modifier + 30% DEX modifier, scaled to a percentage. Never reaches 100%.
func _calc_crit_chance(entity: Node) -> float:
	var per_val: int
	var dex_val: int
	if entity == GameManager.player:
		var s: Dictionary = GameManager.player_data.get("stats", {})
		per_val = s.get("perception", 5)
		dex_val = s.get("dexterity",  5)
	else:
		per_val = entity.get("stat_perception") if entity.get("stat_perception") != null else 5
		dex_val = entity.get("stat_dexterity")  if entity.get("stat_dexterity")  != null else 5
	var per_mod: float = float(per_val - 5)
	var dex_mod: float = float(dex_val - 5)
	var chance: float  = (per_mod * 0.7 + dex_mod * 0.3) * 3.0
	if sneak_attack_pending and entity == GameManager.player:
		chance *= 2.0
	return clampf(chance, 0.0, 95.0)
