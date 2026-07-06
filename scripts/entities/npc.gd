extends Humanoid
class_name NPC

const SPRITE_W: int = 30
const SPRITE_H: int = 60

var dialogue_text: String = "Hello traveller, welcome to town! What brings you to Dustfall?"

var dialogue_options: Array = [
	{
		"label": "Who are you?",
		"response": "Name's Elara. I'm the town greeter — been welcoming folks through that door for near twenty years now.",
	},
	{
		"label": "What is this place?",
		"response": "Dustfall. Small frontier town, but she's home to all of us out here. Settled about forty years back by folk heading west.",
	},
	{
		"label": "Any trouble lately?",
		"response": "Depends who you ask. Strange lights been seen out east past the ridge. Travellers going that way don't always come back.",
	},
	{
		"label": "Farewell.",
		"response": "Safe travels, friend. Watch yourself out there.",
		"closes": true,
	},
]

@export var grid_cell: Vector2i = Vector2i(41, 15)
var _highlighted: bool = false
var _tile_scene: TileScene = null
var sight_range: int = 16   # tile radius for sight line visual (same as NPC awareness)

# ── Pickpocket ────────────────────────────────────────────────────────────────
var pocket_items: Array = []          # items the player can steal; subclasses populate
var _pickpocket_caught: bool = false  # set true when player is caught; removes option

# ── Hostile / combat state ─────────────────────────────────────────────────────
var is_hostile: bool = false
# Non-empty ally-group tag — when one member goes hostile, every other living
# NPC sharing the tag in the same zone goes hostile too (e.g. the two gate
# thugs backing each other up). Subclasses set this before/in _ready().
# Unrelated to GameManager.add_faction_contact, which tracks dialogue/quest
# reputation rather than combat allies.
var ally_group: String = ""
# True for ordinary townsfolk the city watch protects. Subclasses engaged in
# crime against the player (e.g. Thug) set this false so attacking them
# doesn't summon the guards.
var is_citizen: bool = true
var drops_loot: bool = false
var _dead: bool = false
var _in_combat: bool = false
var _attack_weapon: Dictionary = {}   # empty = use unarmed fallback
var _lunge_offset: Vector2 = Vector2.ZERO
var _visual_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	blocks_movement = true
	is_interactable = true
	fow_hide_when_unseen = true
	entity_name = "Elara"
	_tile_scene = get_parent() as TileScene
	position = TileScene.grid_to_screen(grid_cell)
	_visual_pos = position
	_tile_scene.register_entity(grid_cell, self)
	# Skip spawning if this NPC was permanently killed in a previous visit
	if _is_dead_in_save():
		_tile_scene.unregister_entity(grid_cell)
		queue_free()
		return
	init_hp()
	EventBus.highlight_toggled.connect(_on_highlight_toggled)
	EventBus.sneak_toggled.connect(func(_a): queue_redraw())
	EventBus.combat_started.connect(_on_npc_combat_started)
	EventBus.combat_participant_added.connect(_on_npc_participant_added)
	EventBus.combat_ended.connect(_on_npc_combat_ended)
	EventBus.turn_started.connect(_on_npc_turn_started)
	EventBus.attack_started.connect(_on_npc_attack_started)
	EventBus.damage_floater.connect(func(e, _t, _c): if e == self: queue_redraw())
	queue_redraw()
	# Hide NPCs that still have default placeholder dialogue
	call_deferred("_check_if_placeholder")

var force_hidden: bool = false
var fow_can_show: bool = true   # set false by _check_if_placeholder so FoW never un-hides us

func _check_if_placeholder() -> void:
	if force_hidden or dialogue_text == "" or dialogue_text == "Hello traveller, welcome to town! What brings you to Dustfall?":
		visible = false
		is_interactable = false
		fow_can_show = false

func _process(_delta: float) -> void:
	if _dead:
		return
	if current_hp <= 0 and not _dead:
		_dead = true
		_record_npc_death()
		_spawn_npc_corpse()
		visible = false
		is_interactable = false
		queue_free()
		return
	if _in_combat:
		position = _visual_pos + _lunge_offset
		return
	# When hostile outside of active combat, re-engage the player if they're close.
	# Skip once the player is dead — otherwise this re-triggers combat every
	# frame (it ends instantly since the player isn't alive), looping forever.
	if is_hostile and not GameManager.combat_mode:
		var player := GameManager.player as Player
		if player != null and player.current_hp > 0:
			var dx: int = abs(grid_cell.x - player.grid_cell.x)
			var dy: int = abs(grid_cell.y - player.grid_cell.y)
			if maxi(dx, dy) <= sight_range:
				go_hostile()

# ── Hostility ──────────────────────────────────────────────────────────────────

func go_hostile(sneak_attack: bool = false) -> void:
	if _dead:
		return
	var was_hostile: bool = is_hostile
	is_hostile = true
	is_interactable = false
	if is_citizen and not was_hostile:
		EventBus.crime_witnessed.emit(self)
	_alert_allies()
	if CombatManager.active:
		CombatManager.add_participant(self)
		return
	var combatants: Array = [GameManager.player, self]
	# Pull in other nearby hostile NPCs from the same zone
	if _tile_scene != null:
		for entity in _tile_scene.get_all_entities():
			if entity == self or entity == GameManager.player or entity in combatants:
				continue
			var other_npc := entity as NPC
			if other_npc != null and other_npc.is_hostile and not other_npc._dead:
				combatants.append(other_npc)
	CombatManager.force_start_combat(combatants, {}, sneak_attack)

# Makes every living NPC in the zone that shares this NPC's non-empty
# ally_group tag hostile too. Only reaches allies that aren't hostile yet, so
# this can't bounce back and forth between two allies forever.
func _alert_allies() -> void:
	if ally_group == "" or _tile_scene == null:
		return
	for entity in _tile_scene.get_all_entities():
		if entity == self:
			continue
		var ally := entity as NPC
		if ally != null and ally.ally_group == ally_group and not ally.is_hostile and not ally._dead:
			ally.go_hostile()

# ── Combat signal handlers ─────────────────────────────────────────────────────

func _on_npc_combat_started(participants: Array) -> void:
	if self in participants:
		_in_combat = true
		_visual_pos = TileScene.grid_to_screen(grid_cell)
		position = _visual_pos
		queue_redraw()

func _on_npc_participant_added(entity: Node) -> void:
	if entity == self:
		_in_combat = true
		_visual_pos = TileScene.grid_to_screen(grid_cell)
		position = _visual_pos
		queue_redraw()

func _on_npc_combat_ended(_victor: String) -> void:
	if not _in_combat:
		return
	_in_combat = false
	queue_redraw()
	if current_hp <= 0 and not _dead:
		_dead = true
		_record_npc_death()
		_spawn_npc_corpse()
		visible = false
		is_interactable = false
		queue_free()

func _on_npc_turn_started(entity: Node) -> void:
	if entity != self or not _in_combat:
		return
	await get_tree().create_timer(0.6).timeout
	if not is_instance_valid(self) or not _in_combat:
		return
	_execute_npc_ai_turn()

func _on_npc_attack_started(attacker: Node, defender: Node) -> void:
	if attacker != self:
		return
	var dir: Vector2 = (defender.position - position).normalized()
	var tween := create_tween()
	tween.tween_property(self, "_lunge_offset", dir * 18.0, 0.08)
	tween.tween_property(self, "_lunge_offset", Vector2.ZERO, 0.14)

# ── AI turn ────────────────────────────────────────────────────────────────────

func _execute_npc_ai_turn() -> void:
	if not CombatManager.active:
		return
	var player: Node = GameManager.player
	if player == null:
		CombatManager.end_turn()
		return

	var weapon := _attack_weapon if not _attack_weapon.is_empty() else DataManager.get_item("unarmed")
	var attack_cost: int = weapon.get("ap_cost", 2)

	# Move toward player spending MP then spare AP
	var p_cell: Vector2i = CombatManager.resolve_ai_target_cell(self, player)
	var engaged: bool = p_cell == player.get("grid_cell")
	var manhattan: int = abs(grid_cell.x - p_cell.x) + abs(grid_cell.y - p_cell.y)
	if manhattan > 1 and _tile_scene != null:
		var move_budget: int = CombatManager.current_mp() + maxi(0, CombatManager.current_ap() - attack_cost)
		if move_budget > 0:
			var path: Array[Vector2i] = _best_approach_path_npc(p_cell)
			var steps: int = mini(move_budget, path.size())
			for i in range(steps):
				if not is_instance_valid(self) or not _in_combat:
					return
				var next_cell: Vector2i = path[i]
				var target_screen: Vector2 = TileScene.grid_to_screen(next_cell)
				var duration: float = _visual_pos.distance_to(target_screen) / 280.0
				_tile_scene.unregister_entity(grid_cell)
				CombatManager.record_move(self, grid_cell, next_cell)
				grid_cell = next_cell
				_tile_scene.register_entity(grid_cell, self)
				CombatManager.spend_move()
				var tween := create_tween()
				tween.tween_property(self, "_visual_pos", target_screen, duration)
				await tween.finished
				queue_redraw()
				if not is_instance_valid(self) or not _in_combat:
					return
				if not engaged and _tile_scene.has_line_of_sight(grid_cell, player.get("grid_cell")):
					break

	# Attack phase
	while is_instance_valid(self) and _in_combat and CombatManager.active:
		p_cell = player.get("grid_cell")
		manhattan = abs(grid_cell.x - p_cell.x) + abs(grid_cell.y - p_cell.y)
		if manhattan > 1:
			break
		if CombatManager.current_ap() < attack_cost:
			break
		if player.get("current_hp") != null and player.current_hp <= 0:
			break
		CombatManager.resolve_attack(self, player, weapon)
		await get_tree().create_timer(0.28).timeout
		if not is_instance_valid(self) or not _in_combat:
			return

	if is_instance_valid(self):
		CombatManager.end_turn()

func _best_approach_path_npc(target: Vector2i) -> Array[Vector2i]:
	var best: Array[Vector2i] = []
	for dir in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var c: Vector2i = target + dir
		if c != grid_cell and (_tile_scene == null or not _tile_scene.is_walkable(c)):
			continue
		var candidate: Array[Vector2i] = Pathfinding.find_path(grid_cell, c, _tile_scene)
		if not candidate.is_empty() and (best.is_empty() or candidate.size() < best.size()):
			best = candidate
	return best

func _find_adjacent_to(cell: Vector2i) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_dist: int = 99999
	for dir in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var c: Vector2i = cell + dir
		if c == grid_cell or (_tile_scene != null and _tile_scene.is_walkable(c)):
			var dist: int = abs(c.x - grid_cell.x) + abs(c.y - grid_cell.y)
			if dist < best_dist:
				best_dist = dist
				best = c
	return best

# ── Death persistence ──────────────────────────────────────────────────────────

func _is_dead_in_save() -> bool:
	var tile_data: Dictionary = GameManager.get_tile_data(GameManager.world_layer, GameManager.world_pos)
	var scene_path: String = tile_data.get("scene", str(GameManager.world_pos))
	return (scene_path + "::" + name) in GameManager.player_data.get("dead_permanent", [])

func _record_npc_death() -> void:
	var tile_data: Dictionary = GameManager.get_tile_data(GameManager.world_layer, GameManager.world_pos)
	var scene_path: String = tile_data.get("scene", str(GameManager.world_pos))
	var rid: String = scene_path + "::" + name
	var dead: Array = GameManager.player_data.get("dead_permanent", [])
	if rid not in dead:
		dead.append(rid)
	GameManager.player_data["dead_permanent"] = dead

# ── Loot drop ─────────────────────────────────────────────────────────────────
# Killed NPCs leave a searchable corpse using the same container-panel Search
# interaction as humanoid enemies (see Corpse / Enemy._spawn_corpse), instead
# of scattering individual ground-item pickups.

func _lootable_items() -> Array:
	var items: Array = []
	for item in inventory:
		if item is Dictionary and not item.is_empty():
			items.append((item as Dictionary).duplicate())
	for item in equipment.values():
		if item is Dictionary and not item.is_empty():
			items.append((item as Dictionary).duplicate())
	for item in pocket_items:
		if item is Dictionary and not item.is_empty():
			items.append((item as Dictionary).duplicate())
	return items

func _spawn_npc_corpse() -> void:
	if _tile_scene == null:
		return
	var corpse := Corpse.new()
	corpse.grid_cell   = grid_cell
	corpse.entity_name = entity_name + " Corpse"
	corpse.beast_type  = "human"
	corpse.is_human    = true
	if drops_loot:
		corpse.loot_items = _lootable_items()
	_tile_scene.unregister_entity(grid_cell)
	_tile_scene.add_child(corpse)

# ── Standard interaction ───────────────────────────────────────────────────────

func get_click_polygon() -> PackedVector2Array:
	var x := -SPRITE_W / 2.0
	var y := -SPRITE_H + TileScene.TILE_H / 4.0
	return PackedVector2Array([
		position + Vector2(x,            y),
		position + Vector2(x + SPRITE_W, y),
		position + Vector2(x + SPRITE_W, y + SPRITE_H),
		position + Vector2(x,            y + SPRITE_H),
	])

func get_interaction_options() -> Array:
	var opts: Array = [
		{"label": "Talk",    "id": "talk",    "priority": 100},
		{"label": "Examine", "id": "examine", "priority": 50},
	]
	if not is_hostile:
		if GameManager.is_sneaking:
			opts.append({"label": "Sneak Attack", "id": "sneak_attack", "priority": 20})
		opts.append({"label": "Attack", "id": "attack", "priority": 10})
	if not is_hostile and not _pickpocket_caught:
		var skills: Dictionary = GameManager.player_data.get("skills", {})
		if int(skills.get("sleight_of_hand", 0)) > 0 or GameManager.is_sneaking:
			opts.append({"label": "Pickpocket", "id": "pickpocket", "priority": 30})
	return opts

func _exit_tree() -> void:
	if _tile_scene != null:
		_tile_scene.unregister_entity(grid_cell)

func _on_highlight_toggled(active: bool) -> void:
	_highlighted = active
	queue_redraw()

func _draw_name_label(label_y: float) -> void:
	if entity_name == "":
		return
	var font := ThemeDB.fallback_font
	var fs: int = 11
	var tw: float = font.get_string_size(entity_name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var lx := -tw / 2.0
	draw_rect(Rect2(lx - 3, label_y - fs - 1, tw + 6, fs + 4), Color(0, 0, 0, 0.65))
	draw_string(font, Vector2(lx, label_y), entity_name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1.0, 0.95, 0.7))

# Falls back to _attack_weapon when no hand_1 item is equipped — most NPCs
# only set _attack_weapon (e.g. the Shopkeeper's knife), not equipment.
func get_held_weapon() -> Dictionary:
	var item := super.get_held_weapon()
	if not item.is_empty():
		return item
	if _attack_weapon.get("type", "") == "weapon" and _attack_weapon.get("slot") != null:
		return _attack_weapon
	return {}

func _draw() -> void:
	var rect = Rect2(
		-SPRITE_W / 2.0,
		-SPRITE_H + TileScene.TILE_H / 4.0,
		SPRITE_W,
		SPRITE_H
	)
	draw_rect(rect, Color(0.45, 0.45, 0.60))
	_draw_held_weapon(rect)
	if _highlighted:
		draw_rect(rect, Color(1.0, 0.85, 0.0, 0.35))
		draw_rect(rect, Color(1.0, 0.85, 0.0), false, 2.0)
		_draw_name_label(rect.position.y - 4)
	# Health bar shows on hover-highlight always, and by default (unhighlighted
	# too) for any NPC actively in this combat (hostile NPCs, ally backup, etc.).
	if _highlighted or _in_combat:
		_draw_health_bar(-float(SPRITE_W) / 2.0, rect.position.y - 22.0, float(SPRITE_W))
	# Show sight range ring when player is sneaking — circular outline matching
	# the combat ranged-attack indicator's style rather than a diamond.
	if GameManager.is_sneaking:
		for seg in TileScene.euclidean_ring_segments(grid_cell, sight_range):
			draw_line(seg["a"] - _visual_pos, seg["b"] - _visual_pos, Color(0.85, 0.80, 0.10, 0.45), 1.5)
