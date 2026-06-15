extends Cannibal
class_name CannibalScout

# ── Cannibal Scout ────────────────────────────────────────────────────────────
# A regular cannibal (same stats as Cannibal) armed with a hunting bow instead
# of a knife. Keeps its distance and fires from range rather than closing to
# melee. Shares Cannibal's Yell.
# ranged 8 (PER/DEX mod +1) → effective 8.8, matching Cannibal's melee 8.8.

const BOW_RANGE: int = 18

func _ready() -> void:
	entity_name = "Cannibal Scout"
	super._ready()
	skills["ranged"] = 8
	sprite_color = Color(0.46, 0.42, 0.32)   # lighter hide — marks the bow-user
	_attack_weapon = DataManager.get_item("shortbow")


# ── AI turn: yell, close to bow range, then fire while LoS holds ──────────────
func _execute_ai_turn() -> void:
	if not CombatManager.active:
		return
	if _yell_phase():
		await get_tree().create_timer(0.45).timeout
		if not is_instance_valid(self) or not _in_combat:
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
	var p_cell: Vector2i = player_typed.grid_cell

	# ── Move phase: close to within bow range if currently farther away ──────
	var cheby: int = maxi(abs(grid_cell.x - p_cell.x), abs(grid_cell.y - p_cell.y))
	if cheby > BOW_RANGE and _tile_scene != null:
		var move_budget: int = CombatManager.current_mp() + maxi(0, CombatManager.current_ap() - bow_cost)
		var adj: Vector2i = _find_adjacent_to(p_cell)
		if adj != Vector2i(-1, -1) and move_budget > 0:
			var path: Array[Vector2i] = Pathfinding.find_path(grid_cell, adj, _tile_scene)
			var steps: int = mini(move_budget, path.size())
			for i in range(steps):
				if not is_instance_valid(self) or not _in_combat:
					return
				var next_cell: Vector2i = path[i]
				var target_screen: Vector2 = TileScene.grid_to_screen(next_cell)
				var duration: float = _visual_pos.distance_to(target_screen) / COMBAT_MOVE_SPEED
				_tile_scene.unregister_entity(grid_cell)
				grid_cell = next_cell
				_tile_scene.register_entity(grid_cell, self)
				CombatManager.spend_move()
				var tween := create_tween()
				tween.tween_property(self, "_visual_pos", target_screen, duration)
				await tween.finished
				queue_redraw()
				if not is_instance_valid(self) or not _in_combat:
					return
				cheby = maxi(abs(grid_cell.x - p_cell.x), abs(grid_cell.y - p_cell.y))
				if cheby <= BOW_RANGE:
					break

	# ── Attack phase: fire while in range with line of sight ──────────────────
	while is_instance_valid(self) and _in_combat and CombatManager.active:
		p_cell = player_typed.grid_cell
		cheby = maxi(abs(grid_cell.x - p_cell.x), abs(grid_cell.y - p_cell.y))
		if cheby > BOW_RANGE or CombatManager.current_ap() < bow_cost:
			break
		if player.get("current_hp") != null and player.current_hp <= 0:
			break
		if _tile_scene != null and not _tile_scene.has_line_of_sight(grid_cell, p_cell):
			break
		CombatManager.resolve_attack(self, player, _attack_weapon)
		await get_tree().create_timer(0.28).timeout
		if not is_instance_valid(self) or not _in_combat:
			return

	if is_instance_valid(self):
		CombatManager.end_turn()
