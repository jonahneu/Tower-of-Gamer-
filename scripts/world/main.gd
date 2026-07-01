extends Node2D
# Main scene controller — handles zone transitions

const WORLD_ITEMS: Dictionary = {
	"res://scenes/world/zone_desert_north.tscn": [
		{"cell": [34, 71], "item_id": "ancient_bronze_scrap"},
	],
	"res://scenes/world/zone_desert_mid.tscn": [
		{"cell": [52, 71], "item_id": "ancient_bronze_scrap"},
	],
}

var _current_zone: Node = null   # always points to the live TileScene instance

func _ready() -> void:
	EventBus.zone_exit_requested.connect(_on_zone_exit)

	# Check whether the baked-in TileScene matches the saved world position.
	# After a save-load the world_pos may point to a different zone entirely.
	var default_zone = get_node_or_null("TileScene")
	var tile_data    = GameManager.get_tile_data(GameManager.world_layer, GameManager.world_pos)
	var expected_scene: String = tile_data.get("scene", "")
	var wrong_zone: bool = expected_scene != "" and default_zone != null and default_zone.scene_file_path != expected_scene
	GameLogger.info("SAVE", "main.gd _ready() — expected_scene %s, default_zone path %s, wrong_zone %s" % [
		expected_scene, str(default_zone.scene_file_path) if default_zone != null else "<null>", str(wrong_zone)])
	if wrong_zone:
		# Player._ready() (child) already ran and erased _saved_grid_cell — rescue it
		# from the old Player's grid_cell before freeing the zone.
		var old_player = default_zone.get_node_or_null("Player")
		if old_player != null and "grid_cell" in old_player:
			GameManager.player_data["_saved_grid_cell"] = [old_player.grid_cell.x, old_player.grid_cell.y]
			GameLogger.info("SAVE", "main.gd rescued grid_cell %s, hp %s from transient default-zone player" % [
				str(old_player.grid_cell), str(old_player.get("current_hp"))])
			# HP, spirit, status effects, and OC timer were consumed by old player's
			# _ready() — rescue them back so the correct zone's player gets them.
			if old_player.get("current_hp") != null:
				GameManager.player_data["_saved_hp"] = old_player.current_hp
			if old_player.get("current_spirit") != null:
				GameManager.player_data["_saved_spirit"] = old_player.current_spirit
			if old_player.get("status_effects") != null:
				GameManager.player_data["_saved_status_effects"] = old_player.status_effects.duplicate(true)
			var oc = old_player.get("_oc_status_timer")
			if oc != null:
				GameManager.player_data["_saved_oc_timer"] = oc
		# Wrong zone — free the default and instantiate the correct one.
		default_zone.visible      = false
		default_zone.process_mode = Node.PROCESS_MODE_DISABLED
		default_zone.queue_free()
		var new_scene = load(expected_scene).instantiate()
		add_child(new_scene)
		move_child(new_scene, 0)
		_current_zone = new_scene
		var _ts_wrong := new_scene as TileScene
		if _ts_wrong != null:
			_ts_wrong.restore_fov_data(expected_scene)
	else:
		_current_zone = default_zone
		var _ts_same := _current_zone as TileScene
		if _ts_same != null and expected_scene != "":
			_ts_same.restore_fov_data(expected_scene)

	GameManager.current_zone = _current_zone
	# Mark the starting tile as visited when the game loads
	GameManager.mark_tile_visited(GameManager.world_layer, GameManager.world_pos)
	# Give the player their first quest if they don't already have it
	GameManager.add_quest({
		"id":          "find_spiritual_protection",
		"title":       "Try to find spiritual protection",
		"description": "The city is dangerous at night without the help of a god or at least a protective talisman. Find a way to protect yourself before you sleep.",
		"threads":     [],
		"completed":   false,
	})

func _on_zone_exit(direction: String) -> void:
	# Look up next position in the CURRENT layer before any layer change
	var next_pos = GameManager.get_adjacent_tile(direction)
	if next_pos == Vector2i(-1, -1):
		return  # No exit defined in this direction

	# Vertical transitions change the world layer
	var next_layer := GameManager.world_layer
	if direction == "down":
		next_layer += 1
	elif direction == "up":
		next_layer = maxi(0, next_layer - 1)

	var entry_cell = _entry_cell_for(direction)

	# Save living enemy positions, dropped items, and fog-of-war data before freeing.
	# Must happen before queue_free so nodes are still valid.
	if _current_zone != null:
		_save_enemy_positions(_current_zone)
		_save_ground_items(_current_zone)
		var _cur_tile_data: Dictionary = GameManager.get_tile_data(GameManager.world_layer, GameManager.world_pos)
		var _cur_scene_path: String = _cur_tile_data.get("scene", str(GameManager.world_pos))
		var _cur_ts := _current_zone as TileScene
		if _cur_ts != null:
			_cur_ts.save_fov_data(_cur_scene_path)

	# If the player flees mid-combat, end it cleanly before freeing the zone.
	if GameManager.combat_mode:
		CombatManager.abandon_combat()
	# Wipe every armed targeting/throw/deploy mode (pending weapon, smoke bomb,
	# blast tag, ...). Any of these surviving into the new zone hijacks every
	# left-click there — routed into a deploy/throw handler instead of normal
	# movement — which presents to the player as "stuck after zone transition."
	# This is the single funnel both walk-off exits and ladders go through, so
	# resetting here (rather than at each trigger site) can't be missed/drift.
	CombatManager.reset_pending_actions()

	# Hide and disable the current zone via the stored reference.
	# We cannot use get_node("TileScene") here: queue_free() doesn't remove the
	# node immediately, so if both old and new share the name "TileScene" Godot
	# renames the new one — and name-based lookup finds the wrong node next time.
	if _current_zone != null:
		_current_zone.visible = false
		_current_zone.process_mode = Node.PROCESS_MODE_DISABLED
		_current_zone.queue_free()
		_current_zone = null
		GameManager.current_zone = null

	# Update world position and layer, then mark new tile visited
	var layer_changed := (next_layer != GameManager.world_layer)
	GameManager.world_layer = next_layer
	GameManager.world_pos   = next_pos
	GameManager.mark_tile_visited(GameManager.world_layer, next_pos)
	if layer_changed:
		EventBus.world_layer_changed.emit(GameManager.world_layer)

	# Stash transient state so the new Player._ready() picks it up
	GameManager.player_data["_saved_grid_cell"] = [entry_cell.x, entry_cell.y]
	if GameManager.player != null:
		GameManager.player_data["_saved_hp"]             = GameManager.player.current_hp
		GameManager.player_data["_saved_spirit"]          = GameManager.player.current_spirit
		GameManager.player_data["_saved_status_effects"] = GameManager.player.status_effects.duplicate(true)
		GameManager.player_data["_saved_oc_timer"]       = GameManager.player.get("_oc_status_timer")

	# Load and attach the new zone
	var tile_data = GameManager.get_tile_data(GameManager.world_layer, next_pos)
	var scene_path = tile_data.get("scene", "res://scenes/world/tile_scene.tscn")
	var new_scene = load(scene_path).instantiate()
	add_child(new_scene)
	move_child(new_scene, 0)  # Keep behind Camera2D and UILayer
	_current_zone = new_scene
	GameManager.current_zone = new_scene
	_restore_ground_items(new_scene, scene_path)
	var _new_ts := new_scene as TileScene
	if _new_ts != null:
		_new_ts.restore_fov_data(scene_path)

	# Snap camera to the entry position (apply same y-offset as camera follow mode)
	var camera = get_node_or_null("Camera2D")
	if camera:
		var snap_pos := TileScene.grid_to_screen(entry_cell)
		snap_pos.y += camera.get("DIALOGUE_OFFSET_Y") if camera.get("DIALOGUE_OFFSET_Y") != null else 120.0
		camera.position = snap_pos

	# Signal that the new zone is fully ready. Deferred so any call_deferred callbacks
	# from the transition (NPC dialogue_closed one-shots, etc.) fire before this,
	# giving HUD a chance to close any panels they may have re-opened.
	call_deferred("_emit_zone_entered")

func _emit_zone_entered() -> void:
	EventBus.zone_entered.emit()

# Writes every living enemy's current grid_cell into player_data["enemy_positions"].
# Key format matches _respawn_id(): "scene_path::node_name"
func _save_enemy_positions(zone: Node) -> void:
	var tile_scene := zone as TileScene
	if tile_scene == null:
		return
	var tile_data: Dictionary = GameManager.get_tile_data(GameManager.world_layer, GameManager.world_pos)
	var scene_path: String = tile_data.get("scene", str(GameManager.world_pos))
	var positions: Dictionary = GameManager.player_data.get("enemy_positions", {})
	for entity in tile_scene.get_all_entities():
		var enemy := entity as Enemy
		if enemy == null or not is_instance_valid(enemy) or enemy._dead:
			continue
		var key: String = scene_path + "::" + enemy.name
		positions[key] = [enemy.grid_cell.x, enemy.grid_cell.y]
	GameManager.player_data["enemy_positions"] = positions

func _save_ground_items(zone: Node) -> void:
	var tile_data: Dictionary = GameManager.get_tile_data(GameManager.world_layer, GameManager.world_pos)
	var scene_path: String = tile_data.get("scene", str(GameManager.world_pos))
	var ground_items: Dictionary = GameManager.player_data.get("ground_items", {})
	var arr: Array = []
	for child in zone.get_children():
		var gi := child as GroundItem
		if gi == null or gi.item_data.is_empty():
			continue
		arr.append({"cell": [gi.grid_cell.x, gi.grid_cell.y], "item": gi.item_data.duplicate()})
	ground_items[scene_path] = arr
	GameManager.player_data["ground_items"] = ground_items

func _restore_ground_items(zone: Node, scene_path: String) -> void:
	var ground_items: Dictionary = GameManager.player_data.get("ground_items", {})
	# Seed world items on first visit
	if not ground_items.has(scene_path) and WORLD_ITEMS.has(scene_path):
		var seeded: Array = []
		for entry in WORLD_ITEMS[scene_path]:
			var full_item: Dictionary = DataManager.get_item(entry["item_id"])
			if not full_item.is_empty():
				seeded.append({"cell": entry["cell"], "item": full_item})
		ground_items[scene_path] = seeded
		GameManager.player_data["ground_items"] = ground_items
	for entry in ground_items.get(scene_path, []):
		var cell_arr: Array = entry.get("cell", [0, 0])
		var item_dict: Dictionary = entry.get("item", {})
		if item_dict.is_empty():
			continue
		var gi := GroundItem.new()
		gi.grid_cell = Vector2i(cell_arr[0], cell_arr[1])
		gi.item_data = item_dict.duplicate()
		zone.add_child(gi)

# Returns where the player should appear in the new zone.
# They enter from the opposite edge at the same column/row they exited on.
# For underground zones, all corridors use the 10-cell window at positions
# 35–44 (center = 40), so we normalize to that center to prevent spawning
# inside walls when adjacent zones have different opening widths.
func _entry_cell_for(exit_direction: String) -> Vector2i:
	var px: int = 40
	var py: int = 40
	if GameManager.player != null:
		var gc = GameManager.player.get("grid_cell")
		if gc != null:
			px = (gc as Vector2i).x
			py = (gc as Vector2i).y
	match exit_direction:
		"north": return Vector2i(px, TileScene.GRID_ROWS - 2)
		"south": return Vector2i(px, 1)
		"east":  return Vector2i(1,  py)
		"west":  return Vector2i(TileScene.GRID_COLS - 2, py)
		"down":  return Vector2i(40, 16)
		"up":    return Vector2i(40, 16)
	return Vector2i(40, 40)
