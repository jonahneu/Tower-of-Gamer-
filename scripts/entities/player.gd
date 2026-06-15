extends Humanoid
class_name Player

# ── Placeholder sprite dimensions ─────────────────────────────────────────────
const SPRITE_W: int = 30
const SPRITE_H: int = 60  # Taller than a tile to give 3D illusion

# ── Movement ──────────────────────────────────────────────────────────────────
const MOVE_SPEED: float = 600.0
const BOB_AMPLITUDE: float = 4.0
const BOB_FREQUENCY: float = 5.0

var grid_cell: Vector2i = Vector2i(40, 40)
var move_path: Array[Vector2i] = []
var _visual_pos: Vector2 = Vector2.ZERO
var _target_pos: Vector2 = Vector2.ZERO
var _tile_scene: TileScene = null
var _bob_time: float = 0.0
var _is_moving: bool = false
var _was_moving: bool = false

# ── Pending interaction (left-click walk-then-interact) ────────────────────────
var _pending_interaction: Node = null
var _pending_context_entity: Node = null
var _pending_sneak_attack: Node = null
var _sneak_attack_auto_target: Node = null  # auto-fires attack on first turn after sneak
var _exiting: bool = false
var _alt_held: bool = false
var _lunge_offset: Vector2 = Vector2.ZERO
var _oc_status_timer: float = 0.0   # out-of-combat status tick accumulator
var _stuck_check_timer: float = 0.0 # periodic "am I embedded in a wall?" self-heal accumulator
var _is_dead: bool = false
var _last_hover_cell: Vector2i = Vector2i(-1, -1)
var _sneak_attack_weapon: Dictionary = {}   # weapon to auto-fire on first sneak-attack turn

# Adds flat per_flat/agi_flat/wil_flat bonuses from the active meal buff on top
# of the raw stat — affects governing modifiers for skills (ranged, dodge,
# convince, occultism, survival, etc.) via get_governing_modifier().
func get_stat_value(stat_name: String) -> int:
	var base: int = super.get_stat_value(stat_name)
	var buff: Dictionary = GameManager.player_data.get("active_meal_buff", {})
	match stat_name:
		"perception": return base + int(buff.get("per_flat", 0))
		"agility":    return base + int(buff.get("agi_flat", 0))
		"willpower":  return base + int(buff.get("wil_flat", 0))
	return base

# Ash Bake (phys_dr_flat) and Catfish (phys_dr_pct) meal bonuses layer onto
# whatever armor the player has equipped.
func get_total_armor() -> Dictionary:
	var armor: Dictionary = super.get_total_armor()
	var buff: Dictionary = GameManager.player_data.get("active_meal_buff", {})
	if buff.has("phys_dr_flat"):
		armor["flat"] += float(buff["phys_dr_flat"])
	if buff.has("phys_dr_pct"):
		armor["pct_remaining"] *= (1.0 - float(buff["phys_dr_pct"]))
	return armor

func _ready() -> void:
	blocks_movement = true
	GameManager.player = self
	var saved = GameManager.player_data.get("_saved_grid_cell", null)
	if saved != null:
		grid_cell = Vector2i(int(saved[0]), int(saved[1]))
		GameManager.player_data.erase("_saved_grid_cell")
	# Sync stats from player_data into entity fields so combat, AP/MP, and
	# initiative all use the correct values from character creation.
	level = GameManager.player_data.get("level", 1)
	var saved_stats: Dictionary = GameManager.player_data.get("stats", {})
	if saved_stats.has("strength"):     stat_strength     = int(saved_stats["strength"])
	if saved_stats.has("dexterity"):    stat_dexterity    = int(saved_stats["dexterity"])
	if saved_stats.has("agility"):      stat_agility      = int(saved_stats["agility"])
	if saved_stats.has("constitution"): stat_constitution = int(saved_stats["constitution"])
	if saved_stats.has("intelligence"): stat_intelligence = int(saved_stats["intelligence"])
	if saved_stats.has("willpower"):    stat_willpower    = int(saved_stats["willpower"])
	if saved_stats.has("perception"):   stat_perception   = int(saved_stats["perception"])
	init_hp()
	init_spirit()
	# Restore state carried across zone transitions
	var saved_hp = GameManager.player_data.get("_saved_hp", null)
	if saved_hp != null:
		current_hp = float(saved_hp)
		GameManager.player_data.erase("_saved_hp")
	var saved_sp = GameManager.player_data.get("_saved_spirit", null)
	if saved_sp != null:
		current_spirit = int(saved_sp)
		GameManager.player_data.erase("_saved_spirit")
	var saved_fx = GameManager.player_data.get("_saved_status_effects", null)
	if saved_fx != null:
		status_effects = saved_fx
		GameManager.player_data.erase("_saved_status_effects")
	var saved_oc = GameManager.player_data.get("_saved_oc_timer", null)
	if saved_oc != null:
		_oc_status_timer = float(saved_oc)
		GameManager.player_data.erase("_saved_oc_timer")
	# Re-fetch any stored items from DataManager so old saves always have
	# current field definitions (fixes missing "skill", "range", etc.).
	_refresh_items_from_data_manager()
	# Load equipment and inventory from player_data into the entity
	var saved_equip: Dictionary = GameManager.player_data.get("equipment", {})
	for slot in saved_equip:
		if equipment.has(slot):
			equipment[slot] = saved_equip[slot]
	var saved_inv: Array = GameManager.player_data.get("inventory", [])
	for item in saved_inv:
		inventory.append(item)
	entity_name = GameManager.player_data.get("name", "Player")
	EventBus.attack_started.connect(_on_attack_started)
	EventBus.combat_started.connect(_on_combat_started)
	EventBus.turn_started.connect(_on_turn_started)
	_tile_scene = get_parent() as TileScene
	_visual_pos = TileScene.grid_to_screen(grid_cell)
	_target_pos = _visual_pos
	position = _visual_pos
	queue_redraw()
	# Deferred: buildings register their blocked cells in _ready() too (siblings),
	# but sibling order means player._ready() runs before them. Check after all
	# _ready() calls complete so blocked_cells is fully populated.
	call_deferred("_unstuck_check")

func _input(event: InputEvent) -> void:
	# Alt / Tab: toggle interactable highlights (fires on both press and release)
	if event is InputEventKey:
		if event.keycode == KEY_ALT:
			_alt_held = event.pressed
			EventBus.highlight_toggled.emit(event.pressed)
			if not event.pressed:
				EventBus.entity_hovered.emit(null)
		elif event.keycode == KEY_TAB:
			EventBus.highlight_toggled.emit(event.pressed)
		return

	# Mouse motion: targeting hover or Alt tooltip — always runs regardless of UI state
	if event is InputEventMouseMotion:
		if _tile_scene == null:
			return
		var mouse_local := _tile_scene.to_local(get_global_mouse_position())
		var target_cell := TileScene.screen_to_grid(mouse_local)
		var entity := _get_entity_at(mouse_local, target_cell)
		# During pending-weapon targeting, always show hit info (no Alt needed)
		if GameManager.combat_mode and CombatManager.has_pending_weapon():
			EventBus.entity_hovered.emit(entity if entity != null and entity != self else null)
		elif _alt_held:
			if entity != null and (entity.is_interactable or GameManager.combat_mode):
				EventBus.entity_hovered.emit(entity)
			else:
				EventBus.entity_hovered.emit(null)
		# Path preview: show walk path on hover during player turn
		if GameManager.combat_mode and CombatManager.is_player_turn() \
				and not CombatManager.has_pending_weapon():
			if target_cell != _last_hover_cell:
				_last_hover_cell = target_cell
				if _tile_scene.is_walkable(target_cell) and target_cell != grid_cell:
					var mp: int = CombatManager.current_mp()
					var ap: int = CombatManager.current_ap()
					var total_range: int = mp + (ap * 2 if GameManager.has_feat("runner") else ap)
					var preview: Array[Vector2i] = Pathfinding.find_path(grid_cell, target_cell, _tile_scene)
					if not preview.is_empty() and preview.size() <= total_range:
						EventBus.show_path_preview.emit(preview)
					else:
						EventBus.hide_path_preview.emit()
				else:
					EventBus.hide_path_preview.emit()
		elif _last_hover_cell != Vector2i(-1, -1):
			_last_hover_cell = Vector2i(-1, -1)
			EventBus.hide_path_preview.emit()

# Mouse button clicks use _unhandled_input so UI panels (MOUSE_FILTER_STOP) absorb
# their own clicks before the game world sees them.
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return
	if _tile_scene == null:
		return

	var mouse_local = _tile_scene.to_local(get_global_mouse_position())
	var target_cell = TileScene.screen_to_grid(mouse_local)
	var entity    = _get_entity_at(mouse_local, target_cell)

	# ── Combat targeting ──────────────────────────────────────────────────────
	if GameManager.combat_mode and CombatManager.is_player_turn() and CombatManager.has_pending_weapon():
		if event.button_index == MOUSE_BUTTON_LEFT:
			if entity != null and entity != self:
				var pw: Dictionary = CombatManager.pending_weapon
				var pw_range: int  = pw.get("range", 1)
				var pw_effective_range: int = pw_range * 2 if (pw_range > 1 and GameManager.has_feat("long_ranged")) else pw_range
				var e_cell: Vector2i = entity.get("grid_cell")
				var dx: int = grid_cell.x - e_cell.x
				var dy: int = grid_cell.y - e_cell.y
				var dist: float = sqrt(float(dx * dx + dy * dy))
				if dist > float(pw_effective_range):
					EventBus.combat_log.emit("Out of range — %s has a range of %d tile%s." % [
						pw.get("name", "weapon"), pw_effective_range, "s" if pw_effective_range != 1 else ""])
				else:
					CombatManager.resolve_attack(self, entity, CombatManager.consume_pending_weapon())
			else:
				CombatManager.clear_pending_weapon()
			return
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			CombatManager.clear_pending_weapon()
			return

	# ── Pending-weapon targeting outside combat (ranged sneak or tactical) ─────
	# Fires when the player has armed a weapon via the hotbar while sneaking.
	if not GameManager.combat_mode and CombatManager.has_pending_weapon():
		if event.button_index == MOUSE_BUTTON_LEFT:
			var pw: Dictionary = CombatManager.pending_weapon
			var eff_range: int = _effective_weapon_range(pw)
			var sneak_target := entity as Enemy
			if sneak_target != null and is_instance_valid(sneak_target) and not sneak_target._dead:
				var e_cell: Vector2i = sneak_target.get("grid_cell")
				var dx: int = grid_cell.x - e_cell.x
				var dy: int = grid_cell.y - e_cell.y
				var dist: float = sqrt(float(dx * dx + dy * dy))
				if dist <= float(eff_range):
					_sneak_attack_weapon = CombatManager.consume_pending_weapon()
					EventBus.hide_attack_range_overlay.emit()
					_pending_sneak_attack = null
					if GameManager.is_sneaking:
						_initiate_sneak_attack(sneak_target)
					else:
						_start_combat_with_auto_attack(sneak_target)
				else:
					EventBus.combat_log.emit("Out of range — %s has a range of %d tile%s." % [
						pw.get("name", "weapon"), eff_range, "s" if eff_range != 1 else ""])
			else:
				CombatManager.clear_pending_weapon()
				EventBus.hide_attack_range_overlay.emit()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			CombatManager.clear_pending_weapon()
			EventBus.hide_attack_range_overlay.emit()
		return

	# ── Sneak attack: left-click enemy while sneaking (outside combat) ───────
	if event.button_index == MOUSE_BUTTON_LEFT \
			and GameManager.is_sneaking and not GameManager.combat_mode:
		var sneak_target := entity as Enemy
		if sneak_target != null and is_instance_valid(sneak_target) and not sneak_target._dead:
			_pending_sneak_attack = null
			if _is_in_reach_of(sneak_target):
				_initiate_sneak_attack(sneak_target)
			else:
				var adj: Vector2i = _find_approach_cell(sneak_target)
				if adj != Vector2i(-1, -1):
					_pending_sneak_attack = sneak_target
					move_path = Pathfinding.find_path(grid_cell, adj, _tile_scene)
					_advance_path()
			return

	# ── Left click ────────────────────────────────────────────────────────────
	if event.button_index == MOUSE_BUTTON_LEFT:
		# In combat: left-click enemy = auto-attack with default weapon (range check)
		if GameManager.combat_mode and CombatManager.is_player_turn() \
				and entity != null and entity != self and entity is Entity and not (entity is Corpse):
			var weapon: Dictionary = _default_attack_weapon()
			var e_cell: Vector2i = entity.get("grid_cell")
			var weapon_range: int = weapon.get("range", 1)
			var effective_range: int = weapon_range * 2 if (weapon_range > 1 and GameManager.has_feat("long_ranged")) else weapon_range
			var dx2: int = grid_cell.x - e_cell.x
			var dy2: int = grid_cell.y - e_cell.y
			var dist: float = sqrt(float(dx2 * dx2 + dy2 * dy2))
			if dist > float(effective_range):
				EventBus.combat_log.emit("Out of range — %s has a range of %d tile%s." % [
					weapon.get("name", "weapon"), effective_range, "s" if effective_range != 1 else ""])
				return
			CombatManager.resolve_attack(self, entity, weapon)
			return
		if entity != null and entity.is_interactable and not (GameManager.combat_mode and entity is Corpse):
			_pending_interaction = null
			if _is_in_reach_of(entity):
				_trigger_primary_action(entity)
			else:
				var adj = _find_approach_cell(entity)
				if adj != Vector2i(-1, -1):
					_pending_interaction = entity
					move_path = Pathfinding.find_path(grid_cell, adj, _tile_scene)
					_advance_path()
				else:
					_trigger_primary_action(entity)   # can't get closer; try anyway
		elif CombatManager.pending_blast_tag_deploy:
			if event.button_index == MOUSE_BUTTON_LEFT:
				var bdx: int = grid_cell.x - target_cell.x
				var bdy: int = grid_cell.y - target_cell.y
				var b_dist: float = sqrt(float(bdx * bdx + bdy * bdy))
				var b_range: int = CombatManager._pending_blast_tag_item.get("throw_range", 12)
				if b_dist > float(b_range):
					EventBus.combat_log.emit("Out of range — blast tag has a throw range of %d." % b_range)
				else:
					var throw_target = entity if (entity != null and entity != self and entity is Enemy) else null
					CombatManager.execute_blast_tag_throw(target_cell, self, throw_target)
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				CombatManager.cancel_blast_tag_deploy()
		elif CombatManager.pending_smoke_deploy:
			if event.button_index == MOUSE_BUTTON_LEFT:
				var sdx: int = grid_cell.x - target_cell.x
				var sdy: int = grid_cell.y - target_cell.y
				var s_dist: float = sqrt(float(sdx * sdx + sdy * sdy))
				var s_range: int = CombatManager._pending_smoke_item.get("throw_range", 12)
				if s_dist > float(s_range):
					EventBus.combat_log.emit("Out of range — smoke bomb has a throw range of %d." % s_range)
				else:
					CombatManager.execute_smoke_deploy(target_cell, self)
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				CombatManager.cancel_smoke_deploy()
		elif _tile_scene.is_walkable(target_cell):
			move_path = Pathfinding.find_path(grid_cell, target_cell, _tile_scene)
			_advance_path()

	# ── Right click: context menu / combat inspect ────────────────────────────
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		_pending_interaction = null
		_pending_context_entity = null
		# In combat, right-clicking any other combatant shows an inspect panel
		# with their active status effects — even non-interactable enemies.
		if GameManager.combat_mode and entity != null and entity != self and entity is Humanoid:
			_show_context_menu_for(entity)
		elif entity != null and entity.is_interactable and not (GameManager.combat_mode and entity is Corpse):
			if _is_in_reach_of(entity):
				_show_context_menu_for(entity)
			else:
				var adj = _find_approach_cell(entity)
				if adj != Vector2i(-1, -1):
					_pending_context_entity = entity
					move_path = Pathfinding.find_path(grid_cell, adj, _tile_scene)
					_advance_path()
				else:
					_show_context_menu_for(entity)   # can't get closer; show anyway

func _process(delta: float) -> void:
	if _visual_pos.distance_to(_target_pos) > 0.5:
		var cam := get_viewport().get_camera_2d()
		var zoom_scale: float = cam.zoom.x if cam else 1.0
		var effective_speed: float = MOVE_SPEED / zoom_scale \
			* (0.8 if GameManager.is_sneaking else 1.0) \
			* (0.2 if is_overburdened() else 1.0)
		_visual_pos = _visual_pos.move_toward(_target_pos, effective_speed * delta)
		_is_moving = true
	elif not move_path.is_empty():
		_visual_pos = _target_pos
		_advance_path()
	else:
		_is_moving = false

	# When movement just completed, fire any pending action
	if _was_moving and not _is_moving:
		if _pending_interaction != null:
			if _is_in_reach_of(_pending_interaction):
				_trigger_primary_action(_pending_interaction)
			_pending_interaction = null
		if _pending_context_entity != null:
			if _is_in_reach_of(_pending_context_entity):
				_show_context_menu_for(_pending_context_entity)
			_pending_context_entity = null
		if _pending_sneak_attack != null:
			var sa_target := _pending_sneak_attack as Enemy
			_pending_sneak_attack = null
			if sa_target != null and is_instance_valid(sa_target) and not sa_target._dead \
					and not GameManager.combat_mode and GameManager.is_sneaking \
					and _is_in_reach_of(sa_target):
				_initiate_sneak_attack(sa_target)
		# Check for zone exit (only when not already mid-transition).
		# Guard: only fire if this direction actually leads somewhere — otherwise
		# walking to a dead-end border sets _exiting = true permanently and locks
		# the player in the zone.
		if not _exiting:
			var dir = _get_exit_direction()
			if dir != "" and GameManager.get_adjacent_tile(dir) != Vector2i(-1, -1):
				_exiting = true
				if GameManager.tactical_mode:
					CombatManager.end_tactical()
				# main.gd's _on_zone_exit (the single funnel both walk-off exits
				# and ladders go through) calls CombatManager.reset_pending_actions()
				# to wipe every armed targeting/throw/deploy mode — no need to
				# duplicate that here.
				EventBus.zone_exit_requested.emit(dir)
	_was_moving = _is_moving

	# Death check
	if current_hp <= 0 and not _is_dead:
		_is_dead = true
		EventBus.player_died.emit()

	# Out-of-combat status tick: 1 combat turn ≈ 10 seconds real time
	# Skip during zone transitions (_exiting) to avoid signals firing mid-handoff
	if not GameManager.combat_mode and not _exiting:
		_oc_status_timer += delta
		if _oc_status_timer >= 10.0:
			_oc_status_timer -= 10.0
			CombatManager.tick_status_effects(self)

	# Universal "am I embedded in a wall?" self-heal — not just at zone-load.
	# Anything that can reposition the player onto a now-blocked cell (a saved
	# position that no longer matches updated terrain, an entity spawning on
	# top of them, future teleport/knockback effects, etc.) gets caught here,
	# not only the zone-transition spawn case _unstuck_check was written for.
	# Skip mid-transition/mid-combat so we don't fight the handoff or yank the
	# player out of a deliberate tactical position.
	if not _exiting and not GameManager.combat_mode and not GameManager.tactical_mode:
		_stuck_check_timer += delta
		if _stuck_check_timer >= 2.0:
			_stuck_check_timer = 0.0
			_unstuck_check()

	if _is_moving:
		_bob_time += delta
	else:
		_bob_time = 0.0

	var bob_y: float = sin(_bob_time * BOB_FREQUENCY * TAU) * BOB_AMPLITUDE if _is_moving else 0.0
	position = _visual_pos + Vector2(0.0, bob_y) + _lunge_offset
	# Crosshair cursor while targeting
	if CombatManager.has_pending_weapon() and (GameManager.combat_mode or GameManager.is_sneaking):
		Input.set_default_cursor_shape(Input.CURSOR_CROSS)
	else:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	queue_redraw()

# ── Path stepping ─────────────────────────────────────────────────────────────
func _advance_path() -> void:
	if move_path.is_empty():
		return
	if get_current_weight() > get_carry_capacity():
		move_path.clear()
		return
	# In combat or tactical mode: block movement off-turn; each tile costs 1 MP or AP.
	if GameManager.combat_mode or GameManager.tactical_mode:
		if not CombatManager.is_player_turn():
			move_path.clear()
			return
		if not CombatManager.spend_move():
			move_path.clear()   # No AP or MP remaining
			return
	grid_cell = move_path.pop_front()
	_target_pos = TileScene.grid_to_screen(grid_cell)
	EventBus.player_moved.emit(grid_cell)

# ── Attack lunge animation ────────────────────────────────────────────────────
func _effective_weapon_range(weapon: Dictionary) -> int:
	var r: int = weapon.get("range", 1)
	return r * 2 if (r > 1 and GameManager.has_feat("long_ranged")) else r

# Starts combat and queues an auto-attack on the first player turn (non-sneak path).
func _start_combat_with_auto_attack(target: Enemy) -> void:
	_sneak_attack_auto_target = target
	var combatants: Array = [self, target]
	if _tile_scene != null:
		for ent in _tile_scene.get_all_entities():
			if ent == self or ent == target:
				continue
			var other := ent as Enemy
			if other == null or other._dead:
				continue
			if maxi(abs(other.grid_cell.x - grid_cell.x), abs(other.grid_cell.y - grid_cell.y)) \
					<= other.aggro_range:
				combatants.append(other)
	CombatManager.force_start_combat(combatants, {}, false)

func _on_combat_started(_participants: Array) -> void:
	move_path.clear()
	_pending_interaction = null
	_pending_context_entity = null
	_pending_sneak_attack = null
	_target_pos = TileScene.grid_to_screen(grid_cell)
	_visual_pos = _target_pos
	position = _visual_pos
	_oc_status_timer = 0.0
	_last_hover_cell = Vector2i(-1, -1)
	# _sneak_attack_weapon intentionally kept — still needed by _on_turn_started

func _on_turn_started(entity: Node) -> void:
	if entity != self or _sneak_attack_auto_target == null:
		return
	var target := _sneak_attack_auto_target
	_sneak_attack_auto_target = null
	if not is_instance_valid(target) or not CombatManager.active:
		return
	var e_cell: Vector2i = target.get("grid_cell")
	var weapon: Dictionary = _sneak_attack_weapon if not _sneak_attack_weapon.is_empty() \
			else _default_attack_weapon()
	_sneak_attack_weapon = {}
	var dx: int = grid_cell.x - e_cell.x
	var dy: int = grid_cell.y - e_cell.y
	if sqrt(float(dx * dx + dy * dy)) > float(_effective_weapon_range(weapon)):
		return
	CombatManager.resolve_attack(self, target, weapon)

func _on_attack_started(attacker: Node, defender: Node) -> void:
	if attacker != self:
		return
	var dir: Vector2 = (defender.position - position).normalized()
	var tween := create_tween()
	tween.tween_property(self, "_lunge_offset", dir * 18.0, 0.08)
	tween.tween_property(self, "_lunge_offset", Vector2.ZERO, 0.14)

# ── Interaction helpers ───────────────────────────────────────────────────────
func _trigger_primary_action(entity: Node) -> void:
	var options = entity.get_interaction_options()
	if options.is_empty():
		EventBus.interaction_triggered.emit(entity, "interact")
		return
	options.sort_custom(func(a, b): return a["priority"] > b["priority"])
	EventBus.interaction_triggered.emit(entity, options[0]["id"])

func _default_attack_weapon() -> Dictionary:
	var equip: Dictionary = GameManager.player_data.get("equipment", {})
	var hand1 = equip.get("hand_1", null)
	if hand1 != null and hand1.get("ap_cost", 0) > 0:
		return hand1
	return DataManager.get_item("unarmed")

func _initiate_sneak_attack(target: Enemy) -> void:
	if GameManager.combat_mode or not GameManager.is_sneaking:
		return
	_sneak_attack_auto_target = target
	var combatants: Array = [self, target]
	# Pull in any other nearby enemy that would join
	if _tile_scene != null:
		for entity in _tile_scene.get_all_entities():
			if entity == self or entity == target:
				continue
			var other := entity as Enemy
			if other == null or other._dead or other._in_combat:
				continue
			var dx: int = abs(other.grid_cell.x - grid_cell.x)
			var dy: int = abs(other.grid_cell.y - grid_cell.y)
			if maxi(dx, dy) <= other.aggro_range:
				combatants.append(other)
	CombatManager.force_start_combat(combatants, {}, true)

func _get_entity_at(mouse_local: Vector2, target_cell: Vector2i) -> Node:
	# First try the exact grid cell
	var e := _tile_scene.get_entity_at(target_cell)
	if e != null:
		return e
	# Fall back to polygon hit-test for entities whose visual body extends above
	# their grid cell (tall sprites like the Shade, raised door tops, etc.).
	# Any entity that defines get_click_polygon() is eligible — not just
	# interactable ones, since enemies like the Shade need to be targetable too.
	for ent in _tile_scene.get_all_entities():
		if not is_instance_valid(ent) or not ent.has_method("get_click_polygon"):
			continue
		var poly: PackedVector2Array = ent.get_click_polygon()
		if poly.size() > 0 and Geometry2D.is_point_in_polygon(mouse_local, poly):
			return ent
	return null

func _show_context_menu_for(entity: Node) -> void:
	var options = entity.get_interaction_options()
	# A non-blocking entity (plant, item, ...) can end up buried under this one
	# (e.g. a corpse landing on top of a harvestable plant) — fold its options
	# into the same menu, tagged so they route back to it on click.
	var cell = entity.get("grid_cell")
	if cell != null and entity.is_interactable:
		var buried: Node = _tile_scene.get_displaced_entity_at(cell)
		if buried != null and buried != entity and buried.is_interactable:
			for opt in buried.get_interaction_options():
				var tagged: Dictionary = opt.duplicate()
				tagged["_entity"] = buried
				tagged["label"] = "%s (%s)" % [tagged["label"], buried.get("entity_name")]
				options.append(tagged)
	if options.is_empty():
		EventBus.interaction_triggered.emit(entity, "interact")
		return
	if options.size() == 1:
		EventBus.interaction_triggered.emit(options[0].get("_entity", entity), options[0]["id"])
	else:
		EventBus.show_context_menu.emit(entity, options, get_viewport().get_mouse_position())

func _get_exit_direction() -> String:
	if grid_cell.y <= 0:  return "north"
	if grid_cell.y >= 79: return "south"
	if grid_cell.x >= 79: return "east"
	if grid_cell.x <= 0:  return "west"
	return ""

func _is_in_reach_of(entity: Node) -> bool:
	var cell: Vector2i = entity.get("grid_cell")
	var reach: int = entity.get("interaction_reach") if entity.get("interaction_reach") != null else 1
	var d = grid_cell - cell
	return abs(d.x) + abs(d.y) <= reach

func _find_approach_cell(entity: Node) -> Vector2i:
	var cell: Vector2i = entity.get("grid_cell")
	var reach: int = entity.get("interaction_reach") if entity.get("interaction_reach") != null else 1
	var best    = Vector2i(-1, -1)
	var best_d2 = 9999999
	# Search all cells within Manhattan distance [1, reach] from the entity.
	for dx in range(-reach, reach + 1):
		for dy in range(-reach, reach + 1):
			var manhattan: int = abs(dx) + abs(dy)
			if manhattan < 1 or manhattan > reach:
				continue
			var c = cell + Vector2i(dx, dy)
			if _tile_scene.is_walkable(c):
				var d2 = (c - grid_cell).length_squared()
				if d2 < best_d2:
					best_d2 = d2
					best = c
	return best

# Rescues the player if they're standing on a blocked cell — relocates them to
# the nearest cell that's both walkable and part of a real, movable-around-in
# open area. Called once (deferred) right after a zone load, AND periodically
# from _process as a general self-heal: anything that can land the player on a
# blocked tile (stale saved position, an entity spawning on top of them, a
# future teleport/knockback effect) gets corrected here, not just bad spawns.
func _unstuck_check() -> void:
	if not is_instance_valid(_tile_scene) or _tile_scene.is_walkable(grid_cell):
		return
	# Search the whole grid, not just a small neighborhood — large structures
	# (e.g. the city-wall perimeter, stacked boulder-mass clusters) can place
	# the nearest walkable cell more than a few tiles away from a bad spawn.
	# Also reject cells in small sealed pockets: some obstacles (e.g. boulder
	# masses) are built from the doorless Building perimeter, which leaves a
	# walkable-but-enclosed interior — landing there would trap the player
	# worse than the original bad spawn.
	const MIN_OPEN_REGION: int = 40
	var max_radius: int = TileScene.GRID_COLS + TileScene.GRID_ROWS
	for radius in range(1, max_radius):
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				if abs(dx) + abs(dy) != radius:
					continue
				var c := grid_cell + Vector2i(dx, dy)
				if _tile_scene.is_walkable(c) and _connected_region_size(c, MIN_OPEN_REGION) >= MIN_OPEN_REGION:
					grid_cell = c
					_visual_pos = TileScene.grid_to_screen(c)
					_target_pos = _visual_pos
					position = _visual_pos
					return

# Bounded BFS flood-fill: counts walkable cells reachable from `start`, stopping
# as soon as `cap` is reached. We only need to know whether the open region is
# "big enough to move around in," not its exact size.
func _connected_region_size(start: Vector2i, cap: int) -> int:
	var seen: Dictionary = { start: true }
	var queue: Array[Vector2i] = [start]
	var count := 0
	while not queue.is_empty() and count < cap:
		var cur: Vector2i = queue.pop_front()
		count += 1
		var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
		for d in dirs:
			var n: Vector2i = cur + d
			if not seen.has(n) and _tile_scene.is_walkable(n):
				seen[n] = true
				queue.append(n)
	return count

func _exit_tree() -> void:
	if GameManager.player == self:
		GameManager.player = null

func _draw() -> void:
	var rect = Rect2(
		-SPRITE_W / 2.0,
		-SPRITE_H + TileScene.TILE_H / 4.0,
		SPRITE_W,
		SPRITE_H
	)
	var body_color: Color = Color(0.45, 0.45, 0.45) if GameManager.is_sneaking else Color(0.75, 0.75, 0.75)
	draw_rect(rect, body_color)

# Re-fetches every stored item from DataManager (matching on "id") so that saves
# made before a data update automatically get current field definitions.
func _refresh_items_from_data_manager() -> void:
	var equip: Dictionary = GameManager.player_data.get("equipment", {})
	var equip_changed := false
	for slot in equip:
		var raw = equip[slot]
		if raw == null:
			continue
		var item_id: String = str(raw.get("id")) if raw.get("id") != null else ""
		if item_id == "":
			continue
		var fresh: Dictionary = DataManager.get_item(item_id)
		if not fresh.is_empty():
			# Preserve per-instance runtime flags that aren't part of the static
			# item definition (e.g. a poison coating applied via a consumable).
			if raw.get("poisoned", false):
				fresh["poisoned"] = true
			equip[slot] = fresh
			equip_changed = true
	if equip_changed:
		GameManager.player_data["equipment"] = equip

	var inv: Array = GameManager.player_data.get("inventory", [])
	var inv_changed := false
	for i in range(inv.size()):
		var raw = inv[i]
		if raw == null:
			continue
		var item_id: String = str(raw.get("id")) if raw.get("id") != null else ""
		if item_id == "":
			continue
		var fresh: Dictionary = DataManager.get_item(item_id)
		if not fresh.is_empty():
			if raw.get("poisoned", false):
				fresh["poisoned"] = true
			inv[i] = fresh
			inv_changed = true
	if inv_changed:
		GameManager.player_data["inventory"] = inv
