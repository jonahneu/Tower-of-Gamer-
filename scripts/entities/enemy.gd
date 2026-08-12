extends Humanoid
class_name Enemy

# ── Sprite ────────────────────────────────────────────────────────────────────
# Sideways rectangle — wider than tall (quadruped silhouette).
# Subclasses can override to change size/colour.
var sprite_w: int = 40
var sprite_h: int = 20
var sprite_color: Color = Color(0.55, 0.45, 0.35)

# ── Grid ──────────────────────────────────────────────────────────────────────
@export var grid_cell: Vector2i = Vector2i(40, 40)
var _tile_scene: TileScene = null
var _visual_pos: Vector2 = Vector2.ZERO

# grid_cell updates the instant a move starts (so pathing/combat logic is
# never stale), but _visual_pos only catches up gradually over the move's
# tween — leaving a brief window where this enemy's logical cell is one step
# ahead of where its sprite is actually drawn. Anything that highlights "the
# enemy is here" for the player (e.g. combat_hud.gd's move-range preview)
# should check this first, or it can show the highlight one tile off from
# the visible sprite mid-move.
func is_visually_settled() -> bool:
	return _visual_pos.distance_to(TileScene.grid_to_screen(grid_cell)) < 1.0

# ── Wander AI ─────────────────────────────────────────────────────────────────
const WANDER_INTERVAL_MIN: float = 0.8
const WANDER_INTERVAL_MAX: float = 2.5
const WANDER_MOVE_SPEED: float = 170.0
const BOB_AMPLITUDE: float = 3.0
const BOB_FREQUENCY: float = 5.0
var _wander_timer: float = 0.0
var _wander_path: Array[Vector2i] = []
var _wander_target_pos: Vector2 = Vector2.ZERO
var _bob_time: float = 0.0
var _lunge_offset: Vector2 = Vector2.ZERO
# Set > 0 in subclass _ready() to constrain wandering to a radius around spawn point.
var wander_radius: int = 0
var _home_cell: Vector2i = Vector2i(-1, -1)

# ── Detection ─────────────────────────────────────────────────────────────────
# Chebyshev (square) aggro zone. Subclasses override in _ready() before super.
var aggro_range: int = 26
# Edge-trigger flags: detection fires once when the player enters the range zone,
# and again when they reach bump range (≤1). Both reset when the player leaves.
var _aggro_entered: bool = false
var _bump_entered: bool  = false

# Optional tutorial gate: while set and not yet unlocked, this enemy never
# aggros no matter how close the player gets — instead, the first time the
# player would have entered aggro range, it requests the named tutorial popup
# once. The gate opens (aggro starts working normally) only once that popup is
# actually dismissed (EventBus.tutorial_popup_dismissed), not merely shown —
# so the enemy stays frozen for as long as the popup is on screen.
@export var tutorial_gate_id: String = ""
@export var tutorial_gate_title: String = ""
@export var tutorial_gate_body: String = ""
var _tutorial_gate_open: bool = true
var _tutorial_gate_requested: bool = false

# ── Beast identity (set by subclass before super._ready()) ────────────────────
var beast_type: String = ""         # e.g. "coyote" — keys DataManager carve table
var beast_quality_mod: int = 0      # quality offset applied to carving results
var is_human: bool = false          # true = corpse is searched, never carved

# ── Searchable loot (set by subclass before super._ready()) ───────────────────
# Specific item ids found when a human corpse is searched (quest tokens, etc).
# Unrelated to is_human's carve-vs-search branching above.
var loot_item_ids: Array = []

# Whatever this entity had equipped (weapon, shield, armor) or was carrying
# loose when it died, so Search finds their actual gear alongside any curated
# loot_item_ids above. Kept as full item dicts (not just ids) so per-instance
# customization — e.g. the Bandit Leader's poisoned scimitar — survives looting.
func _lootable_items() -> Array:
	var items: Array = []
	for slot in equipment:
		var item = equipment[slot]
		if item is Dictionary and not item.is_empty():
			items.append((item as Dictionary).duplicate())
	for item in inventory:
		if item is Dictionary and not item.is_empty():
			items.append((item as Dictionary).duplicate())
	return items

# ── XP (set by subclass before super._ready()) ────────────────────────────────
var xp_value: int    = 0    # base XP awarded on death (scaled by level diff)
var enemy_level: int = 1    # internal level; not shown to player

# ── Respawn ────────────────────────────────────────────────────────────────────
# Subclasses set this to true before super._ready() to opt in to rest-respawn.
var respawns: bool = false

# ── Combat ────────────────────────────────────────────────────────────────────
const COMBAT_MOVE_SPEED: float = 280.0   # px/s — close to player MOVE_SPEED
var _in_combat: bool = false
# Consecutive combat turns with no cardinal-walkable path to the target at all —
# tracks a LOS-but-unreachable stalemate (e.g. line of sight leaks through a
# diagonal gap between two blocked cells that pathfinding can't cross).
var _unreachable_turns: int = 0
const UNREACHABLE_GIVE_UP_TURNS: int = 3
# Once true, this entity permanently stops counting as "seeing" the player for
# group-awareness purposes this combat — without this, _refresh_group_awareness()
# re-confirms the same phantom sighting every turn and the fight never disengages.
var _gave_up_chase: bool = false
var _dead: bool = false
var _highlighted: bool = false
# Subclass sets this before or in _ready(); used by the AI attack step.
var _attack_weapon: Dictionary = {}

const RESPAWN_RESTS: int = 2   # rests a killed respawnable enemy stays dead for

func _respawn_id() -> String:
	var tile_data: Dictionary = GameManager.get_tile_data(GameManager.world_layer, GameManager.world_pos)
	return tile_data.get("scene", str(GameManager.world_pos)) + "::" + name

func _is_dead_in_save() -> bool:
	var rid: String = _respawn_id()
	if respawns:
		return GameManager.player_data.get("dead_respawnables", {}).has(rid)
	else:
		return rid in GameManager.player_data.get("dead_permanent", [])

# dead_respawnables maps respawn_id -> rests remaining until it comes back
# (see hud.gd's _do_rest, which decrements every entry by one per rest).
func _record_death() -> void:
	var rid: String = _respawn_id()
	if respawns:
		var dead: Dictionary = GameManager.player_data.get("dead_respawnables", {})
		dead[rid] = RESPAWN_RESTS
		GameManager.player_data["dead_respawnables"] = dead
	else:
		var dead: Array = GameManager.player_data.get("dead_permanent", [])
		if rid not in dead:
			dead.append(rid)
		GameManager.player_data["dead_permanent"] = dead

func _load_saved_position() -> Vector2i:
	var tile_data: Dictionary = GameManager.get_tile_data(GameManager.world_layer, GameManager.world_pos)
	var scene_path: String = tile_data.get("scene", str(GameManager.world_pos))
	var key: String = scene_path + "::" + name
	var positions: Dictionary = GameManager.player_data.get("enemy_positions", {})
	if positions.has(key):
		var cell = positions[key]
		return Vector2i(int(cell[0]), int(cell[1]))
	return Vector2i(-1, -1)

func _ready() -> void:
	fow_hide_when_unseen = true
	if _is_dead_in_save():
		queue_free()
		return
	# Restore last known position if the player previously fled this zone
	var saved := _load_saved_position()
	if saved != Vector2i(-1, -1):
		grid_cell = saved
	blocks_movement = true
	is_interactable = false
	_tile_scene = get_parent() as TileScene
	if _tile_scene == null:
		push_error("Enemy '%s' parent is not TileScene" % entity_name)
		return
	_visual_pos = TileScene.grid_to_screen(grid_cell)
	_wander_target_pos = _visual_pos
	position = _visual_pos
	_home_cell = grid_cell
	_tile_scene.register_entity(grid_cell, self)
	GameManager.add_encounter(GameManager.world_layer, GameManager.world_pos, entity_name)
	_wander_timer = randf_range(WANDER_INTERVAL_MIN, WANDER_INTERVAL_MAX)
	init_hp()
	if tutorial_gate_id != "":
		_tutorial_gate_open = GameManager.has_tutorial(tutorial_gate_id)
		EventBus.tutorial_popup_dismissed.connect(_on_tutorial_popup_dismissed)
	EventBus.combat_started.connect(_on_combat_started)
	EventBus.combat_participant_added.connect(_on_combat_participant_added)
	EventBus.combat_ended.connect(_on_combat_ended)
	EventBus.highlight_toggled.connect(_on_highlight_toggled)
	EventBus.turn_started.connect(_on_turn_started)
	EventBus.attack_started.connect(_on_attack_started)
	EventBus.sneak_toggled.connect(_on_sneak_toggled)
	EventBus.status_applied.connect(func(e, _s): if e == self: queue_redraw())
	EventBus.status_cleared.connect(func(e, _s): if e == self: queue_redraw())
	EventBus.damage_floater.connect(func(e, _t, _c): if e == self: queue_redraw())
	queue_redraw()

func _spawn_corpse() -> void:
	if _tile_scene == null or beast_type == "":
		return
	var corpse := Corpse.new()
	corpse.grid_cell         = grid_cell
	corpse.entity_name       = entity_name + " Corpse"
	corpse.beast_type        = beast_type
	corpse.beast_quality_mod = beast_quality_mod
	corpse.is_human          = is_human
	corpse.loot_item_ids     = loot_item_ids
	corpse.loot_items        = _lootable_items()
	_record_death()
	_tile_scene.unregister_entity(grid_cell)
	_tile_scene.add_child(corpse)
	if xp_value > 0:
		GameManager.add_xp(xp_value, enemy_level)
	if CombatManager.active:
		CombatManager.remove_participant(self)
	queue_free()

func _process(delta: float) -> void:
	if current_hp <= 0:
		if not _dead:
			_dead = true
			_spawn_corpse()
		return
	# Animate burning aura each frame
	if not status_effects.get("burning", []).is_empty():
		queue_redraw()
	# Freeze everything (wander, aggro/detection) while a tutorial popup is on
	# screen — otherwise an enemy can close the distance or spot the player
	# while they're stuck reading text they can't react to yet.
	if GameManager.tutorial_popup_open:
		return
	# Freeze wander animation/movement during actual combat turns — those have
	# their own dedicated turn-based AI step elsewhere. Tactical mode (the
	# "everyone moves turn by turn" toggle used to sneak/time past a patrol
	# without a fight) used to be lumped in with this same early return, which
	# skipped the detection check below entirely — making every enemy blind
	# while tactical mode was on, with no way to ever get spotted. Tactical
	# mode should still freeze wander movement (below), just not detection.
	if _in_combat:
		position = _visual_pos + _lunge_offset
		return

	# ── Detection / aggro check ──────────────────────────────────────────────
	# Skip entirely once the player is dead — otherwise a nearby enemy keeps
	# re-triggering combat every frame (combat ends instantly because the
	# player isn't alive, _on_combat_ended resets _in_combat, and the next
	# _process re-detects them), looping forever and leaving CombatManager
	# state in a way that crashes the next scene reload.
	var player_typed: Player = GameManager.player as Player
	if player_typed != null and player_typed.current_hp > 0:
		if GameManager.combat_mode:
			# Combat already active — join it if any participant is in aggro range
			if _check_join_active_combat():
				return
		else:
			# No combat yet — edge-trigger detection when the player enters range.
			# Fires once on range entry, then again if they close to bump range (≤1).
			# Re-rolls only after the player fully exits and re-enters aggro range.
			var dx: int   = grid_cell.x - player_typed.grid_cell.x
			var dy: int   = grid_cell.y - player_typed.grid_cell.y
			var dist: float = sqrt(float(dx * dx + dy * dy))
			if dist <= float(effective_aggro_range()):
				if tutorial_gate_id != "" and not _tutorial_gate_open:
					_request_tutorial_gate()
					return
				if not _aggro_entered:
					_aggro_entered = true
					if dist <= 1:
						_bump_entered = true  # entered directly at bump range
					_trigger_combat()
				elif dist <= 1 and not _bump_entered:
					_bump_entered = true
					_trigger_combat()
				return
			else:
				# Player left aggro range — reset so the next approach gets a fresh check
				_aggro_entered = false
				_bump_entered  = false

	# Tactical mode freezes wander movement (turn-based positioning only) —
	# detection above has already run for this frame regardless.
	if CombatManager.tactical_mode:
		position = _visual_pos + _lunge_offset
		return

	# ── Wander movement ───────────────────────────────────────────────────────
	if _visual_pos.distance_to(_wander_target_pos) > 1.0:
		_visual_pos = _visual_pos.move_toward(_wander_target_pos, WANDER_MOVE_SPEED * delta)
	elif not _wander_path.is_empty():
		_visual_pos = _wander_target_pos
		var next_cell: Vector2i = _wander_path.pop_front()
		if _tile_scene.is_walkable(next_cell):
			_tile_scene.unregister_entity(grid_cell)
			grid_cell = next_cell
			_tile_scene.register_entity(grid_cell, self)
			# Outside combat, only the player's own movement refreshes fog-of-war
			# visibility — without this, a wandering enemy stepping into or out
			# of view doesn't show up until the player happens to move too.
			_tile_scene.update_entity_visibility()
		else:
			GameLogger.warn("MOVE", "%s wander step blocked at %s (zone %s) — path went stale" % [
				entity_name, str(next_cell), str(GameManager.world_pos)])
		_wander_target_pos = TileScene.grid_to_screen(grid_cell)
		queue_redraw()
	else:
		_wander_timer -= delta
		if _wander_timer <= 0.0:
			_wander_timer = randf_range(WANDER_INTERVAL_MIN, WANDER_INTERVAL_MAX)
			_pick_wander_target()

	# ── Bob and position update ───────────────────────────────────────────────
	if _visual_pos.distance_to(_wander_target_pos) > 1.0:
		_bob_time += delta
	else:
		_bob_time = 0.0
	var bob_y: float = sin(_bob_time * BOB_FREQUENCY * TAU) * BOB_AMPLITUDE if _bob_time > 0.0 else 0.0
	position = _visual_pos + Vector2(0.0, bob_y) + _lunge_offset

func _pick_wander_target() -> void:
	if _tile_scene == null:
		return
	var dirs: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
		Vector2i(2, 0), Vector2i(-2, 0), Vector2i(0, 2), Vector2i(0, -2),
		Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1),
	]
	dirs.shuffle()
	for dir in dirs:
		var target: Vector2i = grid_cell + dir
		# Enforce wander radius around spawn point if set
		if wander_radius > 0 and _home_cell != Vector2i(-1, -1):
			var dx: int = abs(target.x - _home_cell.x)
			var dy: int = abs(target.y - _home_cell.y)
			if maxi(dx, dy) > wander_radius:
				continue
		if _tile_scene.is_walkable(target):
			var path: Array[Vector2i] = Pathfinding.find_path(grid_cell, target, _tile_scene)
			if not path.is_empty():
				_wander_path = path
			return

# ── Combat triggers ───────────────────────────────────────────────────────────

func _check_join_active_combat() -> bool:
	for participant in CombatManager.participants:
		if not is_instance_valid(participant):
			continue
		var p_cell = participant.get("grid_cell")
		if p_cell == null:
			continue
		var cell: Vector2i = p_cell
		var dx: int = grid_cell.x - cell.x
		var dy: int = grid_cell.y - cell.y
		if sqrt(float(dx * dx + dy * dy)) <= float(effective_aggro_range()):
			# A solid wall (e.g. a closed door between two separate encounters)
			# should stop an uninvolved enemy from joining a fight purely by
			# distance — without this, enemies on the far side of a wall could
			# still "hear" a fight through it and pile on.
			if _tile_scene != null and not _tile_scene.has_line_of_sight(grid_cell, cell):
				continue
			CombatManager.add_participant(self)
			return true
	return false

# Caps aggro_range by how well this entity can currently perceive the player
# given both their light tiers (LightLevels.vision_cap) — an enemy in the dark
# (or whose target is in the dark) can't spot the player from as far away.
func effective_aggro_range() -> int:
	if _tile_scene == null or GameManager.player == null:
		return aggro_range
	var player_typed: Player = GameManager.player as Player
	if player_typed == null:
		return aggro_range
	var my_light: int = _tile_scene.get_light_level(grid_cell)
	var player_light: int = _tile_scene.get_light_level(player_typed.grid_cell)
	return LightLevels.vision_cap(my_light, player_light, aggro_range)

func _request_tutorial_gate() -> void:
	if _tutorial_gate_requested:
		return
	_tutorial_gate_requested = true
	if not GameManager.has_tutorial(tutorial_gate_id):
		EventBus.tutorial_popup_requested.emit(tutorial_gate_id, tutorial_gate_title, tutorial_gate_body)
	else:
		_tutorial_gate_open = true  # already seen in a prior visit — nothing to wait for

func _on_tutorial_popup_dismissed(dismissed_id: String) -> void:
	if dismissed_id == tutorial_gate_id:
		_tutorial_gate_open = true

func _trigger_combat() -> void:
	if _in_combat or GameManager.combat_mode:
		return
	_in_combat = true
	var combatants: Array = [GameManager.player, self]
	# Pull in any other enemy already within their own aggro range of the player
	if _tile_scene != null:
		var player_typed: Player = GameManager.player as Player
		if player_typed != null:
			for entity in _tile_scene.get_all_entities():
				if entity == self or entity == GameManager.player:
					continue
				var other: Enemy = entity as Enemy
				if other == null or other._in_combat:
					continue
				var dx: int = other.grid_cell.x - player_typed.grid_cell.x
				var dy: int = other.grid_cell.y - player_typed.grid_cell.y
				if sqrt(float(dx * dx + dy * dy)) <= float(other.effective_aggro_range()):
					combatants.append(other)
	if GameManager.is_sneaking and GameManager.player != null:
		var player_typed_inner: Player = GameManager.player as Player
		if _tile_scene != null and player_typed_inner != null \
				and not _tile_scene.has_line_of_sight(grid_cell, player_typed_inner.grid_cell):
			_in_combat = false
			return  # wall blocks detection while sneaking
		var player_skills: Dictionary = GameManager.player_data.get("skills", {})
		var sneak_skill: int  = int(player_skills.get("sneak", 0))
		var dex_mod: int      = Entity.modifier(GameManager.player.stat_dexterity)
		var smoke_bonus: int  = 25 if (GameManager.is_in_smoke(player_typed_inner.grid_cell) or GameManager.is_in_smoke(grid_cell)) else 0
		var eff_sneak: float  = (sneak_skill + smoke_bonus) * (1.0 + dex_mod * 0.1)
		var per_mod: int      = Entity.modifier(stat_perception)
		var light_penalty: int = 0
		if _tile_scene != null:
			light_penalty = LightLevels.perception_penalty(_tile_scene.get_light_level(player_typed_inner.grid_cell))
		var eff_per: float    = (1.0 + per_mod) * 5.0 * enemy_level + light_penalty
		var detect_chance: int = clampi(50 + int((eff_per - eff_sneak) * 2.0), 5, 95)

		# Bump: player walked directly adjacent — enemy gets 3 detection rolls
		var is_bump: bool = false
		if player_typed_inner != null:
			var bx: int = abs(grid_cell.x - player_typed_inner.grid_cell.x)
			var by: int = abs(grid_cell.y - player_typed_inner.grid_cell.y)
			is_bump = maxi(bx, by) <= 1
		var total_rolls: int = 3 if is_bump else 1

		var all_dice: Array = []
		var evaded: bool = true
		for _r in range(total_rolls):
			var die: int = randi_range(1, 100)
			all_dice.append(die)
			if die <= detect_chance:
				evaded = false
				break   # detected on any single success

		if evaded:
			_in_combat = false
			return
		var stealth_info: Dictionary = {
			"detector":      entity_name,
			"sneak_skill":   sneak_skill,
			"dex_mod":       dex_mod,
			"eff_sneak":     eff_sneak,
			"enemy_per":     stat_perception,
			"enemy_per_mod": per_mod,
			"enemy_level":   enemy_level,
			"eff_per":       eff_per,
			"detect_chance": detect_chance,
			"dice":          all_dice,
			"is_bump":       is_bump,
		}
		# force_start_combat (not start_combat) — detection can now fire while
		# tactical mode is active but no fight has started yet (see the
		# _process reordering above), and start_combat's own "if active:
		# return" guard would silently no-op in that case since tactical mode
		# already set active=true. force_start_combat cleanly exits tactical
		# mode first, then starts real combat.
		CombatManager.force_start_combat(combatants, stealth_info)
		# Safety: if combat didn't actually start (e.g. CombatManager was already
		# active from a stale state), un-mark ourselves so detection can retry.
		if not CombatManager.active:
			_in_combat = false
		return
	CombatManager.force_start_combat(combatants)
	# Safety: if start_combat returned early because active was already true,
	# reset _in_combat so this enemy doesn't freeze permanently.
	if not CombatManager.active:
		_in_combat = false

func _on_combat_started(participants: Array) -> void:
	if self in participants:
		_snap_to_grid()

func _on_combat_participant_added(entity: Node) -> void:
	if entity == self:
		_snap_to_grid()

func _snap_to_grid() -> void:
	_in_combat = true
	_aggro_entered = false
	_bump_entered  = false
	_unreachable_turns = 0
	_gave_up_chase = false
	_visual_pos = TileScene.grid_to_screen(grid_cell)
	_wander_target_pos = _visual_pos
	position = _visual_pos
	queue_redraw()

func _on_combat_ended(_victor: String) -> void:
	if not _in_combat:
		return
	_in_combat = false
	queue_redraw()
	if current_hp <= 0 and not _dead:
		_dead = true
		_spawn_corpse()

func _on_attack_started(attacker: Node, defender: Node) -> void:
	if attacker != self:
		return
	# Skip lunge for ranged attacks (attacker and defender more than 1 cell apart)
	var def_cell = defender.get("grid_cell")
	if def_cell != null:
		var dx: int = abs(grid_cell.x - (def_cell as Vector2i).x)
		var dy: int = abs(grid_cell.y - (def_cell as Vector2i).y)
		if maxi(dx, dy) > 1:
			return
	var dir: Vector2 = (defender.position - position).normalized()
	var tween := create_tween()
	tween.tween_property(self, "_lunge_offset", dir * 18.0, 0.08)
	tween.tween_property(self, "_lunge_offset", Vector2.ZERO, 0.14)

func _on_turn_started(entity: Node) -> void:
	if entity != self:
		return
	if CombatManager.tactical_mode:
		await get_tree().create_timer(0.3).timeout
		if not is_instance_valid(self) or not CombatManager.tactical_mode:
			return
		_execute_tactical_turn()
		return
	# Normal combat: small pause then AI acts
	await get_tree().create_timer(0.6).timeout
	if not is_instance_valid(self) or not _in_combat:
		return
	_execute_ai_turn()

# ── Tactical turn ─────────────────────────────────────────────────────────────

func _execute_tactical_turn() -> void:
	if not CombatManager.tactical_mode:
		return
	var player_typed: Player = GameManager.player as Player
	if player_typed == null:
		CombatManager.end_turn()
		return

	# Detection check before moving
	if _tactical_check_detection(player_typed):
		return  # combat started; turn handling taken over by combat system

	# Spend MP on wander movement
	_pick_wander_target()
	var steps: int = mini(CombatManager.current_mp(), _wander_path.size())
	for _s in range(steps):
		if not is_instance_valid(self) or not CombatManager.tactical_mode:
			return
		if _wander_path.is_empty():
			break
		var next_cell: Vector2i = _wander_path.pop_front()
		if not _tile_scene.is_walkable(next_cell):
			GameLogger.warn("MOVE", "%s tactical step blocked at %s (zone %s) — path went stale" % [
				entity_name, str(next_cell), str(GameManager.world_pos)])
			break
		var target_screen: Vector2 = TileScene.grid_to_screen(next_cell)
		var duration: float = _visual_pos.distance_to(target_screen) / WANDER_MOVE_SPEED
		_tile_scene.unregister_entity(grid_cell)
		grid_cell = next_cell
		_tile_scene.register_entity(grid_cell, self)
		_tile_scene.update_entity_visibility()
		CombatManager.spend_mp(1)
		var tween := create_tween()
		tween.tween_property(self, "_visual_pos", target_screen, duration)
		await tween.finished
		queue_redraw()
		if not is_instance_valid(self) or not CombatManager.tactical_mode:
			return
		# Re-check detection after each step
		if _tactical_check_detection(player_typed):
			return

	if is_instance_valid(self) and CombatManager.tactical_mode:
		CombatManager.end_turn()

# Returns true if the enemy detected the player and transitioned to combat.
func _tactical_check_detection(player_typed: Player) -> bool:
	var dx: int = grid_cell.x - player_typed.grid_cell.x
	var dy: int = grid_cell.y - player_typed.grid_cell.y
	if sqrt(float(dx * dx + dy * dy)) > float(effective_aggro_range()):
		return false

	if not GameManager.is_sneaking:
		# Player is visible and in range — engage immediately
		_start_combat_from_tactical()
		return true

	if _tile_scene != null and not _tile_scene.has_line_of_sight(grid_cell, player_typed.grid_cell):
		return false  # wall blocks detection while sneaking

	# Stealth detection roll
	var player_skills: Dictionary = GameManager.player_data.get("skills", {})
	var sneak_skill: int  = int(player_skills.get("sneak", 0))
	var dex_mod: int      = Entity.modifier(GameManager.player.stat_dexterity)
	var eff_sneak: float  = sneak_skill * (1.0 + dex_mod * 0.1)
	var per_mod: int      = Entity.modifier(stat_perception)
	var light_penalty: int = 0
	if _tile_scene != null:
		light_penalty = LightLevels.perception_penalty(_tile_scene.get_light_level(player_typed.grid_cell))
	var eff_per: float    = (1.0 + per_mod) * 5.0 * enemy_level + light_penalty
	var detect_chance: int = clampi(50 + int((eff_per - eff_sneak) * 2.0), 5, 95)
	var die: int           = randi_range(1, 100)
	if die > detect_chance:
		return false  # not detected this step

	var stealth_info: Dictionary = {
		"detector":      entity_name,
		"sneak_skill":   sneak_skill,
		"dex_mod":       dex_mod,
		"eff_sneak":     eff_sneak,
		"enemy_per":     stat_perception,
		"enemy_per_mod": per_mod,
		"enemy_level":   enemy_level,
		"eff_per":       eff_per,
		"detect_chance": detect_chance,
		"dice":          [die],
		"is_bump":       false,
	}
	_start_combat_from_tactical(stealth_info)
	return true

func _start_combat_from_tactical(stealth_info: Dictionary = {}) -> void:
	var combatants: Array = [GameManager.player, self]
	if _tile_scene != null:
		var player_typed: Player = GameManager.player as Player
		if player_typed != null:
			for entity in _tile_scene.get_all_entities():
				if entity == self or entity == GameManager.player:
					continue
				var other := entity as Enemy
				if other == null or other._dead:
					continue
				var dx: int = other.grid_cell.x - player_typed.grid_cell.x
				var dy: int = other.grid_cell.y - player_typed.grid_cell.y
				if sqrt(float(dx * dx + dy * dy)) <= float(other.effective_aggro_range()):
					combatants.append(other)
	CombatManager.force_start_combat(combatants, stealth_info)

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

	var attack_cost: int = _attack_weapon.get("ap_cost", 1) if not _attack_weapon.is_empty() else 0

	# ── Move phase: spend MP then spare AP to close distance ──────────────────
	var p_cell: Vector2i = CombatManager.resolve_ai_target_cell(self, player_typed)
	var engaged: bool = p_cell == player_typed.grid_cell
	var manhattan: int = abs(grid_cell.x - p_cell.x) + abs(grid_cell.y - p_cell.y)
	if manhattan <= 1:
		_unreachable_turns = 0
	if manhattan > 1 and _tile_scene != null:
		var path: Array[Vector2i] = _best_approach_path(p_cell)
		if path.is_empty():
			_unreachable_turns += 1
			CombatManager.mark_unreachable(self)
			if _unreachable_turns >= UNREACHABLE_GIVE_UP_TURNS:
				_gave_up_chase = true
				GameLogger.warn("MOVE", "%s has had no path to %s for %d turns (zone %s) — giving up the chase" % [
					entity_name, str(p_cell), _unreachable_turns, str(GameManager.world_pos)])
		else:
			_unreachable_turns = 0
			# A path opened back up — don't leave this entity permanently
			# blind (see _entity_can_see_player's _gave_up_chase check)
			# over what turned out to be a transient blockage (e.g. allies
			# briefly crowding the only approach cells).
			_gave_up_chase = false
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
				# Chasing a stale cell (searching/alerted/wandering) — stop the
				# instant we regain sight of the player instead of walking the
				# rest of this turn's path toward where they used to be.
				if not engaged and _tile_scene.has_line_of_sight(grid_cell, player_typed.grid_cell):
					break

	# ── Attack phase: spend all remaining AP on attacks ───────────────────────
	if not _attack_weapon.is_empty() and attack_cost > 0:
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
			if not is_instance_valid(player_typed):
				return

	if is_instance_valid(self):
		CombatManager.end_turn()

# Returns the shortest valid A* path that brings us adjacent to `target`.
# Tries all four cardinal adjacent cells and picks the shortest reachable one.
func _best_approach_path(target: Vector2i) -> Array[Vector2i]:
	var best: Array[Vector2i] = []
	for dir in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var c: Vector2i = target + dir
		if c != grid_cell and (_tile_scene == null or not _tile_scene.is_walkable(c)):
			continue
		var candidate: Array[Vector2i] = Pathfinding.find_path(grid_cell, c, _tile_scene)
		if not candidate.is_empty() and (best.is_empty() or candidate.size() < best.size()):
			best = candidate
	return best

# Returns the best walkable cell adjacent to `cell` (prefers cells closest to us).
func _find_adjacent_to(cell: Vector2i) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_dist: int = 99999
	var adj_dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for dir in adj_dirs:
		var c: Vector2i = cell + dir
		# Allow our own current cell (we'll vacate it)
		if c == grid_cell or (_tile_scene != null and _tile_scene.is_walkable(c)):
			var dist: int = abs(c.x - grid_cell.x) + abs(c.y - grid_cell.y)
			if dist < best_dist:
				best_dist = dist
				best = c
	return best

# ── Drawing ───────────────────────────────────────────────────────────────────

func _on_highlight_toggled(active: bool) -> void:
	_highlighted = active
	queue_redraw()

func _on_sneak_toggled(sneak_active: bool) -> void:
	queue_redraw()
	# When the player stops sneaking, immediately check if they're visible.
	# The normal aggro edge-trigger won't re-fire since _aggro_entered is already set.
	if sneak_active or _dead or GameManager.combat_mode:
		return
	var player := GameManager.player
	if player == null:
		return
	var dx: int = grid_cell.x - player.grid_cell.x
	var dy: int = grid_cell.y - player.grid_cell.y
	if sqrt(float(dx * dx + dy * dy)) > float(aggro_range):
		return
	if _tile_scene != null and not _tile_scene.has_line_of_sight(grid_cell, player.grid_cell):
		return
	_aggro_entered = true
	_trigger_combat()

func _draw_aggro_ring() -> void:
	var top_y: float = -sprite_h + TileScene.TILE_H / 4.0
	if _highlighted:
		var hw: float = sprite_w / 2.0 + 2.0
		var hh: float = sprite_h + 2.0
		draw_rect(Rect2(-hw, top_y - 2.0, hw * 2.0, hh), Color(1.0, 0.85, 0.0, 0.30))
		draw_rect(Rect2(-hw, top_y - 2.0, hw * 2.0, hh), Color(1.0, 0.85, 0.0), false, 2.0)
		var font := ThemeDB.fallback_font
		var fs: int = 11
		var label: String = entity_name
		var tw: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var lx := -tw / 2.0
		var ly: float = top_y - 6.0
		draw_rect(Rect2(lx - 3, ly - fs - 1, tw + 6, fs + 4), Color(0, 0, 0, 0.65))
		draw_string(font, Vector2(lx, ly), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1.0, 0.95, 0.7))
	# Health bar shows on hover-highlight always, and by default (unhighlighted
	# too) for any enemy actively in this combat.
	if _highlighted or _in_combat:
		_draw_health_bar(-float(sprite_w) / 2.0, top_y - 24.0, float(sprite_w))
	if not GameManager.is_sneaking:
		return
	# Circular outline matching aggro_range's actual Euclidean check (and the
	# combat ranged-attack indicator's style) rather than a Chebyshev diamond.
	# Red = this enemy can actually see that far; blue = a rock/wall blocks
	# line of sight there, so detection effectively drops to nothing on that
	# stretch of the ring — made high-contrast (not just a dim grey) so cover
	# reads clearly at a glance instead of looking like a rendering gap.
	for seg in TileScene.euclidean_ring_segments(grid_cell, aggro_range):
		var a: Vector2 = seg["a"] - _visual_pos
		var b: Vector2 = seg["b"] - _visual_pos
		var has_los: bool = _tile_scene == null or _tile_scene.has_line_of_sight(grid_cell, seg["cell"])
		if has_los:
			draw_line(a, b, Color(0.85, 0.10, 0.10, 0.55), 1.5)
		else:
			draw_line(a, b, Color(0.25, 0.55, 0.95, 0.60), 1.5)

# Returns base_color tinted orange in proportion to Heated stack count — used
# by subclasses with a custom _draw() so the tint applies to their sprite too.
func _heated_tint(base_color: Color) -> Color:
	var heat_stacks: int = status_effects.get("heated", []).size()
	if heat_stacks <= 0:
		return base_color
	var tint_strength: float = minf(0.80, heat_stacks * 0.14)
	return base_color.lerp(Color(0.90, 0.40, 0.06), tint_strength)

# Draws a flickering red-orange outline around rect while Burning is active —
# used by subclasses with a custom _draw() so the aura applies to their sprite too.
func _draw_burning_aura(rect: Rect2) -> void:
	if status_effects.get("burning", []).is_empty():
		return
	var t: float = fmod(Time.get_ticks_msec() / 180.0, 1.0)
	var alpha: float = 0.55 + 0.35 * sin(t * TAU)
	var fire_col: Color = Color(1.0, 0.30, 0.0, alpha).lerp(Color(1.0, 0.65, 0.0, alpha), t)
	var aura := Rect2(rect.position - Vector2(3.0, 3.0), rect.size + Vector2(6.0, 6.0))
	draw_rect(aura, fire_col, false, 2.5)

# Falls back to _attack_weapon when no hand_1 item is equipped — most human
# enemies (Cannibal, Cannibal Scout, ...) only set _attack_weapon.
func get_held_weapon() -> Dictionary:
	var item := super.get_held_weapon()
	if not item.is_empty():
		return item
	if _attack_weapon.get("type", "") == "weapon" and _attack_weapon.get("slot") != null:
		return _attack_weapon
	return {}

func _draw() -> void:
	var rect := Rect2(
		-sprite_w / 2.0,
		-sprite_h + TileScene.TILE_H / 4.0,
		float(sprite_w),
		float(sprite_h)
	)
	var draw_color: Color = _heated_tint(sprite_color)

	draw_rect(rect, draw_color)
	if is_human:
		_draw_held_weapon(rect)
	_draw_burning_aura(rect)
	_draw_aggro_ring()
