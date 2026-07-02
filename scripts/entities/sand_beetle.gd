extends Enemy
class_name SandBeetle

# ── Baseline sand beetle stats ────────────────────────────────────────────────
# STR 7  → +2 governing mod on mandible/ram damage
# AGI 4  → max_ap = 4, max_mp = 8  (slow, deliberate)
# CON 7  → base max_hp = 70, hp_flat_bonus = -30 → max_hp = 40
# DEX 4  → poor dodge, poor initiative
# Innate armor: 2 flat + 30% physical damage reduction (chitinous shell)
# Ram: 4 AP, straight-line charge to adjacent of target, deals 1d6+STR, applies Dazed

const RAM_RANGE:   int   = 23  # 15 * 1.5, rounded up
const RAM_AP_COST: int   = 4
const RAM_DAMAGE:  String = "1d6"
const RAM_SPEED:   float  = 580.0

func _ready() -> void:
	entity_name       = "Sand Beetle"
	beast_type        = "sand_beetle"
	aggro_range       = 35
	respawns          = true
	xp_value          = 80
	enemy_level       = 2
	stat_strength     = 7
	stat_dexterity    = 4
	stat_agility      = 4
	stat_constitution = 7
	hp_flat_bonus     = -30  # → max_hp = 40
	stat_intelligence = 3

	skills["melee"] = 27
	skills["dodge"] = 5

	innate_defense_flat = 2
	innate_defense_pct  = 0.30

	wander_radius = 12

	sprite_w     = 48
	sprite_h     = 32
	sprite_color = Color(0.42, 0.35, 0.22)

	_attack_weapon = {
		"name":        "Mandibles",
		"type":        "weapon",
		"damage":      "1d4",
		"ap_cost":     1,
		"skill":       "melee",
		"governing":   ["strength"],
		"damage_type": "physical",
		"properties":  [],
	}

	super._ready()

# ── AI turn: try Ram first, fall back to normal move+attack ──────────────────
func _execute_ai_turn() -> void:
	if not CombatManager.active:
		return
	var player: Node = GameManager.player
	if player == null:
		CombatManager.end_turn()
		return
	var player_typed: Player = player as Player
	if player_typed == null:
		CombatManager.end_turn()
		return

	if CombatManager.current_ap() >= RAM_AP_COST:
		if await _try_ram(player_typed):
			if is_instance_valid(self):
				CombatManager.end_turn()
			return

	await _normal_turn(player_typed)
	if is_instance_valid(self):
		CombatManager.end_turn()

# Returns true if Ram was executed (regardless of outcome).
func _try_ram(player_typed: Player) -> bool:
	var dx: int = player_typed.grid_cell.x - grid_cell.x
	var dy: int = player_typed.grid_cell.y - grid_cell.y

	# Must be in a cardinal line
	if dx != 0 and dy != 0:
		return false
	var dist: int = abs(dx) + abs(dy)
	if dist < 3 or dist > RAM_RANGE:
		return false

	# Path must be clear
	if _tile_scene == null:
		return false
	var dir := Vector2i(sign(dx), sign(dy))
	if not _ram_path_clear(grid_cell, dir, player_typed.grid_cell):
		return false

	if not CombatManager.spend_ap(RAM_AP_COST):
		return false

	var target_cell: Vector2i = player_typed.grid_cell - dir
	EventBus.combat_log.emit(
		"Sand Beetle → %s  [Ram]\n  Charging %d tiles!" % [
			player_typed.entity_name, dist - 1])
	EventBus.attack_started.emit(self, player_typed)

	# Animate the charge
	var c: Vector2i = grid_cell + dir
	while c != target_cell + dir:
		if not is_instance_valid(self) or not _in_combat:
			return true
		var target_screen: Vector2 = TileScene.grid_to_screen(c)
		var duration: float = _visual_pos.distance_to(target_screen) / RAM_SPEED
		_tile_scene.unregister_entity(grid_cell)
		grid_cell = c
		_tile_scene.register_entity(grid_cell, self)
		var tween := create_tween()
		tween.tween_property(self, "_visual_pos", target_screen, duration)
		await tween.finished
		queue_redraw()
		c += dir

	if not is_instance_valid(self) or not _in_combat or not is_instance_valid(player_typed):
		return true

	# Deal damage
	var raw: int = Entity.roll_dice(RAM_DAMAGE) + maxi(0, stat_strength - 5)
	var final_dmg: float = float(raw)
	if player_typed.has_method("calc_damage_received"):
		final_dmg = player_typed.calc_damage_received(raw,
			{"damage_type": "physical", "name": "Ram", "properties": []})

	player_typed.current_hp -= final_dmg
	EventBus.damage_dealt.emit(player_typed, final_dmg, "attack")
	EventBus.damage_floater.emit(player_typed, "-%.1f Ram!" % final_dmg, Color(1.0, 0.55, 0.0))

	var def_name: String = player_typed.get("entity_name") if player_typed.get("entity_name") != null else "?"
	var log_lines: PackedStringArray = [
		"  Damage: %.1f  (%d raw, %.1f absorbed)" % [final_dmg, raw, float(raw) - final_dmg]
			if final_dmg != float(raw)
			else "  Damage: %.1f" % final_dmg,
	]

	# Apply Dazed (non-stacking)
	if player_typed.has_method("get") and player_typed.get("status_effects") != null:
		if player_typed.status_effects.get("dazed", []).is_empty():
			player_typed.status_effects["dazed"] = [1]
			EventBus.status_applied.emit(player_typed, "dazed")
			EventBus.damage_floater.emit(player_typed, "dazed", Color(0.85, 0.65, 0.10))
			log_lines.append("  %s is Dazed — AP and MP halved next turn!" % def_name)
		else:
			log_lines.append("  (%s already dazed)" % def_name)

	EventBus.combat_log.emit("\n".join(log_lines))
	EventBus.attack_resolved.emit(self, true)

	await get_tree().create_timer(0.28).timeout
	return true

# Path between (exclusive) from_cell and target_cell along dir must be walkable.
func _ram_path_clear(from_cell: Vector2i, dir: Vector2i, target_cell: Vector2i) -> bool:
	var check: Vector2i = from_cell + dir
	while check != target_cell:
		if not _tile_scene.is_walkable(check):
			return false
		check += dir
	return true

# Look for a cardinal-aligned cell (clear line to the player, in Ram range)
# reachable within move_budget steps, so next turn's Ram has a shot.
func _find_ram_setup_cell(player_typed: Player, move_budget: int) -> Vector2i:
	if _tile_scene == null or move_budget <= 0:
		return Vector2i(-1, -1)
	var p_cell: Vector2i = player_typed.grid_cell

	var candidates: Array[Vector2i] = []
	for k in range(3, RAM_RANGE + 1):
		candidates.append(Vector2i(p_cell.x - k, p_cell.y))
		candidates.append(Vector2i(p_cell.x + k, p_cell.y))
		candidates.append(Vector2i(p_cell.x, p_cell.y - k))
		candidates.append(Vector2i(p_cell.x, p_cell.y + k))

	var best: Vector2i = Vector2i(-1, -1)
	var best_steps: int = 999999
	for cell in candidates:
		if cell == grid_cell or not _tile_scene.is_walkable(cell):
			continue
		var dir := Vector2i(sign(p_cell.x - cell.x), sign(p_cell.y - cell.y))
		if not _ram_path_clear(cell, dir, p_cell):
			continue
		var path: Array[Vector2i] = Pathfinding.find_path(grid_cell, cell, _tile_scene)
		if path.is_empty() or path.size() > move_budget:
			continue
		if path.size() < best_steps:
			best_steps = path.size()
			best = cell
	return best

# Normal move + mandible attack (mirrors base Enemy AI logic)
func _normal_turn(player_typed: Player) -> void:
	var attack_cost: int = _attack_weapon.get("ap_cost", 1)
	# Ram-alignment seeking only makes sense against a target we can currently
	# see — if resolve_ai_target_cell sends us somewhere other than the live
	# player (alerted/searching/wandering), just approach that cell normally.
	var p_cell: Vector2i = CombatManager.resolve_ai_target_cell(self, player_typed)
	var engaged: bool = p_cell == player_typed.grid_cell
	var manhattan: int = abs(grid_cell.x - p_cell.x) + abs(grid_cell.y - p_cell.y)

	if manhattan <= 1:
		_unreachable_turns = 0
	if manhattan > 1 and _tile_scene != null:
		var move_budget: int = CombatManager.current_mp() + maxi(0, CombatManager.current_ap() - attack_cost)
		var dest: Vector2i = Vector2i(-1, -1)
		var path: Array[Vector2i] = []
		if engaged:
			# Melee takes priority whenever it's actually reachable this turn —
			# only spend the turn lining up a charge instead when melee isn't
			# reachable this turn anyway (too far, or the direct route is blocked).
			var melee_cell: Vector2i = _find_adjacent_to(p_cell)
			var melee_path: Array[Vector2i] = Pathfinding.find_path(grid_cell, melee_cell, _tile_scene) if melee_cell != Vector2i(-1, -1) else []
			if not melee_path.is_empty() and melee_path.size() <= move_budget:
				dest = melee_cell
				path = melee_path
			else:
				var align_cell: Vector2i = _find_ram_setup_cell(player_typed, move_budget)
				dest = align_cell if align_cell != Vector2i(-1, -1) else melee_cell
				path = Pathfinding.find_path(grid_cell, dest, _tile_scene) if dest != Vector2i(-1, -1) else []
		else:
			dest = _find_adjacent_to(p_cell)
			path = Pathfinding.find_path(grid_cell, dest, _tile_scene) if dest != Vector2i(-1, -1) else []
		if path.is_empty():
			_unreachable_turns += 1
			CombatManager.mark_unreachable(self)
			if _unreachable_turns >= UNREACHABLE_GIVE_UP_TURNS:
				_gave_up_chase = true
				GameLogger.warn("MOVE", "%s has had no path to %s for %d turns (zone %s) — giving up the chase" % [
					entity_name, str(p_cell), _unreachable_turns, str(GameManager.world_pos)])
		else:
			_unreachable_turns = 0
		if move_budget > 0 and not path.is_empty():
			var steps: int = mini(move_budget, path.size())
			for i in range(steps):
				if not is_instance_valid(self) or not _in_combat:
					return
				var next_cell: Vector2i = path[i]
				if not _tile_scene.is_walkable(next_cell):
					GameLogger.error("MOVE", "%s combat-move step blocked at %s (zone %s) — path went stale mid-turn" % [
						entity_name, str(next_cell), str(GameManager.world_pos)])
					break
				var target_screen: Vector2 = TileScene.grid_to_screen(next_cell)
				var duration: float = _visual_pos.distance_to(target_screen) / COMBAT_MOVE_SPEED
				_tile_scene.unregister_entity(grid_cell)
				CombatManager.record_move(self, grid_cell, next_cell)
				grid_cell = next_cell
				_tile_scene.register_entity(grid_cell, self)
				_tile_scene.update_entity_visibility()
				CombatManager.spend_move()
				var tween := create_tween()
				tween.tween_property(self, "_visual_pos", target_screen, duration)
				await tween.finished
				queue_redraw()
				if not is_instance_valid(self) or not _in_combat:
					return

	if not _attack_weapon.is_empty() and attack_cost > 0:
		while is_instance_valid(self) and _in_combat and CombatManager.active:
			p_cell = player_typed.grid_cell
			manhattan = abs(grid_cell.x - p_cell.x) + abs(grid_cell.y - p_cell.y)
			if manhattan > 1:
				break
			if CombatManager.current_ap() < attack_cost:
				break
			if player_typed.get("current_hp") != null and player_typed.current_hp <= 0:
				break
			CombatManager.resolve_attack(self, player_typed, _attack_weapon)
			await get_tree().create_timer(0.28).timeout
			if not is_instance_valid(self) or not _in_combat:
				return
			if not is_instance_valid(player_typed):
				return
