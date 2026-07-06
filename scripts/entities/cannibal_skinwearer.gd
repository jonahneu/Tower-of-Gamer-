extends Enemy
class_name CannibalSkinwearer

# ── Baseline skin-wearer stats ────────────────────────────────────────────────
# Level 3, elite — wears a human-skin trophy (taboo Way of Beasts) for +1 melee.
# CON 6 (mod +1) → base max_hp = 5*6*4 = 120
# AGI 5 → max_ap = max_mp = 5
#
# Grapple: 4 AP melee roll, contested against the player's Strength (same
# structure as Sneak vs. Perception). On success the player is Grappled
# (MP forced to 0 next turn).

const GRAPPLE_AP_COST: int = 4

func _ready() -> void:
	entity_name       = "Skin-wearer"
	beast_type        = "human"
	is_human          = true
	aggro_range       = 14
	xp_value          = 60
	enemy_level       = 3
	level             = 3
	stat_strength     = 6
	stat_dexterity    = 6
	stat_agility      = 6
	stat_constitution = 6
	stat_intelligence = 4
	stat_willpower    = 5
	stat_perception   = 6

	skills["melee"] = 12
	skills["dodge"] = 4

	equipment["back"] = DataManager.get_item("human_skin_trophy")

	sprite_w     = 28
	sprite_h     = 44
	sprite_color = Color(0.58, 0.48, 0.36)   # mottled with skin trophies

	equipment["hand_1"] = DataManager.get_item("knife")
	_attack_weapon = DataManager.get_item("knife")
	feats.append("runner")

	super._ready()

# ── AI turn: grapple when adjacent and able, else move + knife attack ────────
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

	var manhattan: int = abs(grid_cell.x - player_typed.grid_cell.x) + abs(grid_cell.y - player_typed.grid_cell.y)
	var already_grappled: bool = not player_typed.status_effects.get("grappled", []).is_empty()
	if manhattan <= 1 and not already_grappled and CombatManager.current_ap() >= GRAPPLE_AP_COST:
		await _try_grapple(player_typed)
		if is_instance_valid(self):
			CombatManager.end_turn()
		return

	await _normal_turn(player_typed)
	if is_instance_valid(self):
		CombatManager.end_turn()

func _try_grapple(player_typed: Player) -> void:
	if not CombatManager.spend_ap(GRAPPLE_AP_COST):
		return
	EventBus.attack_started.emit(self, player_typed)

	var attacker_eff: float = get_skill_total("melee")
	var stats: Dictionary    = GameManager.player_data.get("stats", {})
	var player_str: int      = stats.get("strength", 5)
	var player_level: int    = GameManager.player_data.get("level", 1)
	var defender_eff: float  = float((1 + (player_str - 5)) * 5 * player_level)
	var chance: int   = clampi(50 + int((attacker_eff - defender_eff) * 2.0), 5, 95)
	var roll: int     = randi_range(1, 100)
	var success: bool = roll <= chance

	var log_lines: PackedStringArray = [
		"%s → %s  [Grapple]" % [entity_name, player_typed.entity_name],
		"  Melee %.1f vs Strength Resist %.1f → %d%% | roll %d — %s" % [
			attacker_eff, defender_eff, chance, roll, "SUCCESS" if success else "FAIL"],
	]

	if success:
		if player_typed.status_effects.get("grappled", []).is_empty():
			player_typed.status_effects["grappled"] = [1]
			EventBus.status_applied.emit(player_typed, "grappled")
			EventBus.damage_floater.emit(player_typed, "grappled!", Color(0.65, 0.25, 0.65))
			log_lines.append("  %s is Grappled — held in place, MP set to 0 next turn!" % player_typed.entity_name)
	else:
		EventBus.damage_floater.emit(player_typed, "miss", Color(0.65, 0.65, 0.70))

	EventBus.combat_log.emit("\n".join(log_lines))
	EventBus.attack_resolved.emit(self, success)
	await get_tree().create_timer(0.28).timeout

# Move + knife attack — mirrors the base Enemy AI loop.
func _normal_turn(player_typed: Player) -> void:
	var attack_cost: int = _attack_weapon.get("ap_cost", 1)
	var p_cell: Vector2i = CombatManager.resolve_ai_target_cell(self, player_typed)
	var engaged: bool = p_cell == player_typed.grid_cell
	var manhattan: int = abs(grid_cell.x - p_cell.x) + abs(grid_cell.y - p_cell.y)

	if manhattan <= 1:
		_unreachable_turns = 0
	if manhattan > 1 and _tile_scene != null:
		var adj: Vector2i = _find_adjacent_to(p_cell)
		var path: Array[Vector2i] = []
		if adj != Vector2i(-1, -1):
			path = Pathfinding.find_path(grid_cell, adj, _tile_scene)
		if path.is_empty():
			_unreachable_turns += 1
			CombatManager.mark_unreachable(self)
			if _unreachable_turns >= UNREACHABLE_GIVE_UP_TURNS:
				_gave_up_chase = true
				GameLogger.warn("MOVE", "%s has had no path to %s for %d turns (zone %s) — giving up the chase" % [
					entity_name, str(p_cell), _unreachable_turns, str(GameManager.world_pos)])
		else:
			_unreachable_turns = 0
		var move_budget: int = CombatManager.current_mp() + maxi(0, CombatManager.current_ap() - attack_cost)
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
				if not engaged and _tile_scene.has_line_of_sight(grid_cell, player_typed.grid_cell):
					break

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
