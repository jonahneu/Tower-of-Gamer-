extends Enemy
class_name AcidLizard

# ── Stats ─────────────────────────────────────────────────────────────────────
# HP 20:  CON 4 → base 40, hp_flat_bonus=-20 → max_hp=20
# AGI 4   → max_ap=4, max_mp=4
# PER 6   → mod +1 (governs ranged alongside DEX)
# Eff. melee  18: skills["melee"]=18,  STR mod 0 → 18 * 1.0 = 18
# Eff. ranged 22: skills["ranged"]=20, PER mod +1 → 20 * 1.1 = 22
# Bite:  1 AP, range 1, 1d3 physical
# Spit:  2 AP, range 8, 1d6+1 acid — bypasses armor

var _bite_weapon: Dictionary = {}
var _spit_weapon: Dictionary = {}

func _ready() -> void:
	entity_name       = "Acid Lizard"
	beast_type        = "lizard"
	aggro_range       = 20
	respawns          = false
	xp_value          = 60
	enemy_level       = 2
	wander_radius     = 3

	stat_strength     = 5
	stat_dexterity    = 5
	stat_agility      = 4
	stat_constitution = 4
	stat_intelligence = 5
	stat_willpower    = 5
	stat_perception   = 8

	hp_flat_bonus     = -20   # 40 base + (-20) → max_hp 20

	skills["melee"]  = 18
	skills["ranged"] = 20
	skills["dodge"]  = 15

	# ── Sprite ───────────────────────────────────────────────────────────────
	sprite_w     = 28
	sprite_h     = 10
	sprite_color = Color(0.30, 0.52, 0.22)   # muted olive-green

	# ── Weapons ──────────────────────────────────────────────────────────────
	_bite_weapon = {
		"name":        "Bite",
		"type":        "weapon",
		"damage":      "1d3",
		"ap_cost":     1,
		"range":       1,
		"skill":       "melee",
		"governing":   ["strength"],
		"damage_type": "physical",
		"properties":  [],
	}

	_spit_weapon = {
		"name":        "Acid Spit",
		"type":        "weapon",
		"damage":      "1d6+1",
		"ap_cost":     2,
		"range":       16,
		"skill":       "ranged",
		"governing":   ["perception", "dexterity"],
		"damage_type": "acid",
		"properties":  [],
	}

	# Default attack weapon for lunge/icon purposes; overridden per-attack in AI
	_attack_weapon = _bite_weapon

	super._ready()


# ── Ranged AI turn ────────────────────────────────────────────────────────────
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

	const SPIT_RANGE: int = 16
	var p_cell: Vector2i = player_typed.grid_cell

	# ── Move phase: close to within spit range if farther away ───────────────
	var cheby: int = maxi(abs(grid_cell.x - p_cell.x), abs(grid_cell.y - p_cell.y))
	if cheby > SPIT_RANGE and _tile_scene != null:
		var spit_cost: int = _spit_weapon.get("ap_cost", 2)
		var move_budget: int = CombatManager.current_mp() + maxi(0, CombatManager.current_ap() - spit_cost)
		if move_budget > 0:
			var path: Array[Vector2i] = _best_approach_path(p_cell)
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
				# Stop early once we're within spit range
				var d: int = maxi(abs(grid_cell.x - p_cell.x), abs(grid_cell.y - p_cell.y))
				if d <= SPIT_RANGE:
					break

	# ── Reposition phase: within spit range but LoS blocked → find a clear cell ─
	p_cell = player_typed.grid_cell
	cheby = maxi(abs(grid_cell.x - p_cell.x), abs(grid_cell.y - p_cell.y))
	var zone: TileScene = GameManager.current_zone as TileScene
	if cheby <= SPIT_RANGE and _tile_scene != null and zone != null \
			and not zone.has_line_of_sight(grid_cell, p_cell):
		var los_cell: Vector2i = _find_los_position(p_cell, SPIT_RANGE, zone)
		if los_cell != Vector2i(-1, -1):
			var spit_cost: int = _spit_weapon.get("ap_cost", 2)
			var move_budget: int = CombatManager.current_mp() + maxi(0, CombatManager.current_ap() - spit_cost)
			if move_budget > 0:
				var path: Array[Vector2i] = Pathfinding.find_path(grid_cell, los_cell, _tile_scene)
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

	# ── Fallback: if still no LoS and not adjacent, try to close to bite range ──
	p_cell = player_typed.grid_cell
	cheby = maxi(abs(grid_cell.x - p_cell.x), abs(grid_cell.y - p_cell.y))
	if cheby > 1 and _tile_scene != null:
		var zone_fb: TileScene = GameManager.current_zone as TileScene
		var los_blocked: bool = zone_fb == null or not zone_fb.has_line_of_sight(grid_cell, p_cell)
		if los_blocked:
			var bite_cost: int = _bite_weapon.get("ap_cost", 1)
			var budget_fb: int = CombatManager.current_mp() + maxi(0, CombatManager.current_ap() - bite_cost)
			if budget_fb > 0:
				var path_fb: Array[Vector2i] = _best_approach_path(p_cell)
				var steps_fb: int = mini(budget_fb, path_fb.size())
				for i in range(steps_fb):
					if not is_instance_valid(self) or not _in_combat:
						return
					var next_cell: Vector2i = path_fb[i]
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

	# ── Attack phase: bite if adjacent, spit if in range with LoS ───────────
	while is_instance_valid(self) and _in_combat and CombatManager.active:
		p_cell = player_typed.grid_cell
		cheby = maxi(abs(grid_cell.x - p_cell.x), abs(grid_cell.y - p_cell.y))
		var ap: int = CombatManager.current_ap()

		if cheby <= 1 and ap >= _bite_weapon.get("ap_cost", 1):
			_attack_weapon = _bite_weapon
			CombatManager.resolve_attack(self, player, _bite_weapon)
		elif cheby <= SPIT_RANGE and ap >= _spit_weapon.get("ap_cost", 2):
			# Only spit if we have line of sight
			zone = GameManager.current_zone as TileScene
			var has_los: bool = true
			if zone != null:
				has_los = zone.has_line_of_sight(grid_cell, p_cell)
			if has_los:
				_attack_weapon = _spit_weapon
				CombatManager.resolve_attack(self, player, _spit_weapon)
			else:
				break  # LoS still blocked after repositioning — end turn
		else:
			break

		await get_tree().create_timer(0.28).timeout
		if not is_instance_valid(self) or not _in_combat:
			return

	if is_instance_valid(self):
		CombatManager.end_turn()


# ── LoS repositioning helper ──────────────────────────────────────────────────
# Searches cells within a small radius of the lizard's current position for
# one that is walkable, within `spit_range` of the player, and has LoS to them.
# Returns the nearest such cell, or Vector2i(-1,-1) if none found.
func _find_los_position(p_cell: Vector2i, spit_range: int, zone: TileScene) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_dist: int = 99999
	const SEARCH_RADIUS: int = 6
	for dx in range(-SEARCH_RADIUS, SEARCH_RADIUS + 1):
		for dy in range(-SEARCH_RADIUS, SEARCH_RADIUS + 1):
			var c := Vector2i(grid_cell.x + dx, grid_cell.y + dy)
			if not _tile_scene.is_walkable(c):
				continue
			var to_player: int = maxi(abs(c.x - p_cell.x), abs(c.y - p_cell.y))
			if to_player > spit_range:
				continue
			if not zone.has_line_of_sight(c, p_cell):
				continue
			var dist: int = maxi(abs(dx), abs(dy))
			if dist < best_dist:
				best_dist = dist
				best = c
	return best


# ── Click detection ───────────────────────────────────────────────────────────
func get_click_polygon() -> PackedVector2Array:
	var w: float  = float(sprite_w)
	var h: float  = float(sprite_h)
	var base_y: float = TileScene.TILE_H / 4.0
	var x: float  = -w * 0.5
	var y: float  = -h + base_y
	return PackedVector2Array([
		Vector2(x, y), Vector2(-x, y),
		Vector2(-x, y + h), Vector2(x, y + h),
	])


# ── Drawing ───────────────────────────────────────────────────────────────────
func _draw() -> void:
	var w: float    = float(sprite_w)
	var h: float    = float(sprite_h)
	var base_y: float = TileScene.TILE_H / 4.0
	var body := Rect2(-w * 0.5, -h + base_y, w, h)
	var draw_color: Color = _heated_tint(sprite_color)

	# Body
	draw_rect(body, draw_color)

	# Darker head bump on the left side
	var head_w: float = w * 0.25
	draw_rect(Rect2(-w * 0.5, -h + base_y - 2.0, head_w, h + 2.0), draw_color.darkened(0.2))

	# Acid-green belly stripe
	draw_rect(Rect2(-w * 0.3, -h * 0.35 + base_y, w * 0.6, h * 0.35), Color(0.55, 0.85, 0.25, 0.60))

	# Thin outline
	draw_rect(body, draw_color.darkened(0.35), false, 1.0)

	_draw_burning_aura(body)
	_draw_aggro_ring()
