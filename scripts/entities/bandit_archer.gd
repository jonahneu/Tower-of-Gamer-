extends Enemy
class_name BanditArcher

# Level 2 archer — keeps its distance and fires while line of sight holds.
# Long Ranged feat lets it attempt shots out to double normal bow range
# (with the same accuracy falloff past nominal range the player gets from it).

const BOW_RANGE: int = 16

func _ready() -> void:
	entity_name       = "Bandit Archer"
	beast_type        = "human"
	is_human          = true
	aggro_range       = 16
	wander_radius     = 2
	respawns          = false
	xp_value          = 35
	enemy_level       = 2
	level             = 2

	stat_strength     = 5
	stat_dexterity    = 7
	stat_agility      = 6
	stat_constitution = 6
	stat_intelligence = 5
	stat_willpower    = 5
	stat_perception   = 8

	skills["melee"]  = 6
	skills["ranged"] = 18
	skills["dodge"]  = 8

	sprite_w     = 24
	sprite_h     = 42
	sprite_color = Color(0.42, 0.38, 0.28)   # lighter hide — marks the bow-user

	_attack_weapon = DataManager.get_item("shortbow")
	feats.append("long_ranged")

	super._ready()


func _effective_bow_range() -> int:
	return BOW_RANGE * 2 if "long_ranged" in feats else BOW_RANGE


# ── AI turn ────────────────────────────────────────────────────────────────────
# Priority: if already able to fire (even with a long-range penalty), spend
# MP only — never AP — trying to shed the penalty by closing to BOW_RANGE,
# then fire with whatever AP remains. AP is only ever spent on movement when
# the target is out of range entirely (or we're chasing a non-visible
# search/wander cell). If AP runs too low to fire mid-turn, fall back to
# spending leftover MP closing toward no-penalty range instead of idling.
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

	var bow_cost: int = _attack_weapon.get("ap_cost", 2)
	var max_range: int = _effective_bow_range()
	# Bow-range closing only makes sense against a target we can currently see
	# — otherwise just approach whatever cell resolve_ai_target_cell gives us
	# (alert origin / last-known cell / wander direction).
	var p_cell: Vector2i = CombatManager.resolve_ai_target_cell(self, player_typed)
	var engaged: bool = p_cell == player_typed.grid_cell
	var cheby: int = maxi(abs(grid_cell.x - p_cell.x), abs(grid_cell.y - p_cell.y))

	if (engaged and cheby > max_range or not engaged and cheby > 1) and _tile_scene != null:
		# Can't fire at all from here — spend MP then spare AP closing in.
		# When engaged, stop as soon as max_range is reached rather than
		# burning AP all the way down to BOW_RANGE; the no-penalty shave-down
		# below handles the rest with MP only.
		await _step_toward(p_cell, false, max_range if engaged else -1, bow_cost)

	if engaged and _tile_scene != null:
		await _step_toward(p_cell, true, BOW_RANGE)

	# ── Reposition phase: in range but LoS blocked → find a clear angle ───────
	p_cell = player_typed.grid_cell
	cheby = maxi(abs(grid_cell.x - p_cell.x), abs(grid_cell.y - p_cell.y))
	if engaged and cheby <= max_range and _tile_scene != null \
			and not _tile_scene.has_line_of_sight(grid_cell, p_cell):
		var los_cell: Vector2i = _find_los_position(p_cell, max_range)
		if los_cell != Vector2i(-1, -1):
			await _step_to_cell(los_cell, false, bow_cost)

	# ── Attack phase: fire while in range with line of sight ──────────────────
	while is_instance_valid(self) and _in_combat and CombatManager.active:
		p_cell = player_typed.grid_cell
		cheby = maxi(abs(grid_cell.x - p_cell.x), abs(grid_cell.y - p_cell.y))
		if cheby > max_range:
			break
		if player.get("current_hp") != null and player.current_hp <= 0:
			break
		if _tile_scene != null and not _tile_scene.has_line_of_sight(grid_cell, p_cell):
			break
		if CombatManager.current_ap() < bow_cost:
			# Too little AP left to fire this turn — spend any leftover MP
			# closing toward no-penalty range instead of standing still.
			await _step_toward(p_cell, true, BOW_RANGE)
			break
		CombatManager.resolve_attack(self, player, _attack_weapon)
		await get_tree().create_timer(0.28).timeout
		if not is_instance_valid(self) or not _in_combat:
			return

	if is_instance_valid(self):
		CombatManager.end_turn()


# BFS outward over walkable cells (4-directional, matching Pathfinding's
# movement model) from the archer's current position, returning the nearest
# (by walking distance) cell within `max_range` of the player with LoS to
# them. Mirrors Lizard._find_los_position — BFS order beats straight-line
# distance when the straight-line-nearest cell sits behind the very
# obstacle blocking LoS in the first place.
func _find_los_position(p_cell: Vector2i, max_range: int) -> Vector2i:
	if _tile_scene == null:
		return Vector2i(-1, -1)
	const SEARCH_RADIUS: int = 6
	var visited: Dictionary = {grid_cell: 0}
	var queue: Array[Vector2i] = [grid_cell]
	var head: int = 0
	while head < queue.size():
		var cur: Vector2i = queue[head]
		head += 1
		var to_player: int = maxi(abs(cur.x - p_cell.x), abs(cur.y - p_cell.y))
		if to_player <= max_range and _tile_scene.has_line_of_sight(cur, p_cell):
			return cur
		var depth: int = visited[cur]
		if depth >= SEARCH_RADIUS:
			continue
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nb: Vector2i = cur + d
			if visited.has(nb) or not _tile_scene.is_walkable(nb):
				continue
			visited[nb] = depth + 1
			queue.append(nb)
	return Vector2i(-1, -1)


# Moves directly to `target` (already the destination, unlike _step_toward's
# adjacent-to-target search) — used for LoS repositioning, where the
# destination is a precomputed clear cell rather than something to stand
# next to.
func _step_to_cell(target: Vector2i, mp_only: bool, attack_cost: int = 0) -> void:
	if _tile_scene == null or target == grid_cell:
		return
	var move_budget: int
	if mp_only:
		move_budget = CombatManager.current_mp()
	else:
		move_budget = CombatManager.current_mp() + maxi(0, CombatManager.current_ap() - attack_cost)
	if move_budget <= 0:
		return
	var path: Array[Vector2i] = Pathfinding.find_path(grid_cell, target, _tile_scene)
	if path.is_empty():
		return
	var steps: int = mini(move_budget, path.size())
	for i in range(steps):
		if not is_instance_valid(self) or not _in_combat:
			return
		var next_cell: Vector2i = path[i]
		if not _tile_scene.is_walkable(next_cell):
			GameLogger.error("MOVE", "%s combat-move step blocked at %s (zone %s) — path went stale mid-turn" % [
				entity_name, str(next_cell), str(GameManager.world_pos)])
			return
		var target_screen: Vector2 = TileScene.grid_to_screen(next_cell)
		var duration: float = _visual_pos.distance_to(target_screen) / COMBAT_MOVE_SPEED
		_tile_scene.unregister_entity(grid_cell)
		CombatManager.record_move(self, grid_cell, next_cell)
		grid_cell = next_cell
		_tile_scene.register_entity(grid_cell, self)
		_tile_scene.update_entity_visibility()
		if mp_only:
			CombatManager.spend_mp(1)
		else:
			CombatManager.spend_move()
		var tween := create_tween()
		tween.tween_property(self, "_visual_pos", target_screen, duration)
		await tween.finished
		queue_redraw()
		if not is_instance_valid(self) or not _in_combat:
			return


# Moves toward `target` along the path to a cell adjacent to it, stopping
# early once within `break_range` (skip the check entirely with -1). When
# mp_only is true, only MP is spent (and the budget is capped to current MP)
# so AP stays free for attacking; otherwise spends MP then spare AP, reserving
# `attack_cost` AP for an attack this turn where possible.
func _step_toward(target: Vector2i, mp_only: bool, break_range: int, attack_cost: int = 0) -> void:
	if _tile_scene == null:
		return
	if break_range >= 0 and maxi(abs(grid_cell.x - target.x), abs(grid_cell.y - target.y)) <= break_range:
		return
	var move_budget: int
	if mp_only:
		move_budget = CombatManager.current_mp()
	else:
		move_budget = CombatManager.current_mp() + maxi(0, CombatManager.current_ap() - attack_cost)
	if move_budget <= 0:
		return
	var adj: Vector2i = _find_adjacent_to(target)
	var path: Array[Vector2i] = Pathfinding.find_path(grid_cell, adj, _tile_scene) if adj != Vector2i(-1, -1) else []
	if path.is_empty():
		_unreachable_turns += 1
		CombatManager.mark_unreachable(self)
		if _unreachable_turns >= UNREACHABLE_GIVE_UP_TURNS:
			_gave_up_chase = true
			GameLogger.warn("MOVE", "%s has had no path to %s for %d turns (zone %s) — giving up the chase" % [
				entity_name, str(target), _unreachable_turns, str(GameManager.world_pos)])
		return
	_unreachable_turns = 0
	var steps: int = mini(move_budget, path.size())
	for i in range(steps):
		if not is_instance_valid(self) or not _in_combat:
			return
		var next_cell: Vector2i = path[i]
		if not _tile_scene.is_walkable(next_cell):
			GameLogger.error("MOVE", "%s combat-move step blocked at %s (zone %s) — path went stale mid-turn" % [
				entity_name, str(next_cell), str(GameManager.world_pos)])
			return
		var target_screen: Vector2 = TileScene.grid_to_screen(next_cell)
		var duration: float = _visual_pos.distance_to(target_screen) / COMBAT_MOVE_SPEED
		_tile_scene.unregister_entity(grid_cell)
		CombatManager.record_move(self, grid_cell, next_cell)
		grid_cell = next_cell
		_tile_scene.register_entity(grid_cell, self)
		_tile_scene.update_entity_visibility()
		if mp_only:
			CombatManager.spend_mp(1)
		else:
			CombatManager.spend_move()
		var tween := create_tween()
		tween.tween_property(self, "_visual_pos", target_screen, duration)
		await tween.finished
		queue_redraw()
		if not is_instance_valid(self) or not _in_combat:
			return
		if break_range >= 0 and maxi(abs(grid_cell.x - target.x), abs(grid_cell.y - target.y)) <= break_range:
			return
