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
	if adj == Vector2i(-1, -1):
		return
	var path: Array[Vector2i] = Pathfinding.find_path(grid_cell, adj, _tile_scene)
	var steps: int = mini(move_budget, path.size())
	for i in range(steps):
		if not is_instance_valid(self) or not _in_combat:
			return
		var next_cell: Vector2i = path[i]
		var target_screen: Vector2 = TileScene.grid_to_screen(next_cell)
		var duration: float = _visual_pos.distance_to(target_screen) / COMBAT_MOVE_SPEED
		_tile_scene.unregister_entity(grid_cell)
		CombatManager.record_move(self, grid_cell, next_cell)
		grid_cell = next_cell
		_tile_scene.register_entity(grid_cell, self)
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
