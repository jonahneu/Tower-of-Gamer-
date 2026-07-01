extends Enemy
class_name AdolescentCoyote

# ── Adolescent Coyote ─────────────────────────────────────────────────────────
# A sub-adult coyote — larger, darker, and tougher than the adults.
# Stats are 1.5× base coyote (rounded up).
# STR 8, DEX 8, AGI 9, CON 8, INT 8, WIL 8, PER 8
# max_hp 30: CON 8 → base 80, hp_flat_bonus=-50 → 30
# AGI 9 → AP=9, MP=18
# melee 30, dodge 30
# Innate armor: 2 flat + 7.5% physical damage reduction
# xp_value: 60, enemy_level: 2
#
# Howl (1 AP): Forces all non-combat Coyotes in the zone into combat immediately.
#   Prioritized on first turn when idle coyotes are present. Used once per combat.
#
# Passive — Drawn to Combat: While not in combat during active combat,
#   wanders toward the nearest participant instead of wandering randomly.

var _howled: bool = false

func _ready() -> void:
	entity_name       = "Adolescent Coyote"
	beast_type        = "adolescent_coyote"
	aggro_range       = 16
	respawns          = true
	xp_value          = 60
	enemy_level       = 2
	wander_radius     = 0

	stat_strength     = 8
	stat_dexterity    = 8
	stat_agility      = 9
	stat_constitution = 8
	stat_intelligence = 8
	stat_willpower    = 8
	stat_perception   = 8

	hp_flat_bonus     = -50   # CON 8: 5*(5+3)*2=80; 80+(-50)=30 max_hp

	skills["melee"] = 30
	skills["dodge"] = 30

	innate_defense_flat = 1.5
	innate_defense_pct  = 0.15

	# ── Sprite: bigger and darker than a regular coyote ───────────────────────
	sprite_w     = 50
	sprite_h     = 26
	sprite_color = Color(0.58, 0.48, 0.32)   # darker sandy tan

	# ── Bite weapon ───────────────────────────────────────────────────────────
	_attack_weapon = {
		"name":        "Bite",
		"type":        "weapon",
		"damage":      "1d4+1",
		"ap_cost":     1,
		"range":       1,
		"skill":       "melee",
		"governing":   ["strength", "dexterity"],
		"damage_type": "physical",
		"properties":  ["bleed"],
	}

	super._ready()


# ── Passive: wander toward combat when not participating ──────────────────────
func _pick_wander_target() -> void:
	if GameManager.combat_mode and not _in_combat and _tile_scene != null:
		# Find the nearest combat participant
		var nearest_cell := Vector2i(-1, -1)
		var nearest_dist: int = 99999
		for p in CombatManager.participants:
			var cell = p.get("grid_cell")
			if cell == null:
				continue
			var c := cell as Vector2i
			var dist := maxi(abs(grid_cell.x - c.x), abs(grid_cell.y - c.y))
			if dist < nearest_dist:
				nearest_dist = dist
				nearest_cell = c
		if nearest_cell != Vector2i(-1, -1) and nearest_dist > 1:
			var adj := _find_adjacent_to(nearest_cell)
			if adj == Vector2i(-1, -1):
				adj = nearest_cell
			var path: Array[Vector2i] = Pathfinding.find_path(grid_cell, adj, _tile_scene)
			if not path.is_empty():
				_wander_path = path
				return
	super._pick_wander_target()


# ── AI turn ───────────────────────────────────────────────────────────────────
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

	# ── Howl phase: pull in nearby coyotes before doing anything else ─────────
	if not _howled and CombatManager.current_ap() >= 1 and _tile_scene != null:
		var idle_coyotes: Array = []
		for entity in _tile_scene.get_all_entities():
			var coyote := entity as Enemy
			if coyote != null and coyote != self and coyote.beast_type.contains("coyote") \
					and not coyote._in_combat and not coyote._dead:
				idle_coyotes.append(coyote)
		if not idle_coyotes.is_empty():
			EventBus.damage_floater.emit(self, "Howling!", Color(1.0, 0.80, 0.15))
			CombatManager.spend_ap(1)
			_howled = true
			for coyote in idle_coyotes:
				if is_instance_valid(coyote):
					CombatManager.add_participant(coyote)
					CombatManager.alert_entity(coyote, grid_cell)
			await get_tree().create_timer(0.45).timeout
			if not is_instance_valid(self) or not _in_combat:
				return
		else:
			_howled = true  # no coyotes to call — skip in future turns

	# ── Move phase: close to player ───────────────────────────────────────────
	var attack_cost: int = _attack_weapon.get("ap_cost", 1)
	var p_cell: Vector2i = CombatManager.resolve_ai_target_cell(self, player_typed)
	var manhattan: int = abs(grid_cell.x - p_cell.x) + abs(grid_cell.y - p_cell.y)
	if manhattan <= 1:
		_unreachable_turns = 0
	if manhattan > 1 and _tile_scene != null:
		var adj: Vector2i = _find_adjacent_to(p_cell)
		var path: Array[Vector2i] = Pathfinding.find_path(grid_cell, adj, _tile_scene) if adj != Vector2i(-1, -1) else []
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

	# ── Attack phase ──────────────────────────────────────────────────────────
	while is_instance_valid(self) and _in_combat and CombatManager.active:
		p_cell = player_typed.grid_cell
		manhattan = abs(grid_cell.x - p_cell.x) + abs(grid_cell.y - p_cell.y)
		if manhattan > 1:
			break
		if CombatManager.current_ap() < attack_cost:
			break
		if player.get("current_hp") != null and player.current_hp <= 0:
			break
		CombatManager.resolve_attack(self, player, _attack_weapon)
		await get_tree().create_timer(0.28).timeout
		if not is_instance_valid(self) or not _in_combat:
			return

	if is_instance_valid(self):
		CombatManager.end_turn()


# ── Reset howl when combat ends ───────────────────────────────────────────────
func _on_combat_ended(victor: String) -> void:
	_howled = false
	super._on_combat_ended(victor)


# ── Drawing ───────────────────────────────────────────────────────────────────
func _draw() -> void:
	var w: float      = float(sprite_w)
	var h: float      = float(sprite_h)
	var base_y: float = TileScene.TILE_H / 4.0
	var rect := Rect2(-w * 0.5, -h + base_y, w, h)
	var draw_color: Color = _heated_tint(sprite_color)

	# Body
	draw_rect(rect, draw_color)
	# Dark dorsal stripe
	draw_rect(Rect2(-w * 0.18, -h + base_y, w * 0.36, h * 0.45), draw_color.darkened(0.28))
	# Outline — slightly thicker than the base coyote to read as larger
	draw_rect(rect, draw_color.darkened(0.42), false, 1.4)

	_draw_burning_aura(rect)
	_draw_aggro_ring()
