extends Node2D
class_name Building

# Creates one WallCell child per wall tile, added directly to TileScene so that
# y_sort_enabled on TileScene handles correct isometric depth ordering.

const WALL_H: float = 28.0

@export var col_sw:  Color = Color(0.50, 0.45, 0.38)
@export var col_se:  Color = Color(0.38, 0.33, 0.26)
@export var col_top: Color = Color(0.62, 0.57, 0.50)
@export var col_out: Color = Color(0.18, 0.12, 0.08)
@export var col_roof: Color = Color(0.45, 0.28, 0.20)

# Height tier: real buildings/huts default to 3x WALL_H. Area/city-edge
# boundary walls (corridor perimeters, district outer walls) are set to 5x
# explicitly per-instance — see wall/building scenes for which is which.
@export var wall_height_mult: float = 3.0

@export var X1: int = 37
@export var X2: int = 43
@export var Y1: int = 24
@export var Y2: int = 28
@export var DOOR_X: int = 40
@export var DOOR_Y: int = -1  # -1 = south face (Y2); else door is at (DOOR_X, DOOR_Y)

# Collapsed/rubble barrier instead of a smooth built wall — most cells render
# as an irregular broken mound (RubbleWallCell), a minority as a flat
# standing-wall remnant. Same blocking/door/occlusion logic either way, only
# the visual per-cell node changes. Use for outdoor ruins barriers; leave
# false for actual intact buildings/rooms.
@export var rubble_style: bool = false

var _wall_nodes: Array = []
var _roof_node: RoofCap = null
var _tile_scene: TileScene = null
var _last_player_cell: Vector2i = Vector2i(-999999, -999999)
var _is_real_room: bool = false   # true when X1..X2 / Y1..Y2 spans a real rectangle

func _get_door_cell() -> Vector2i:
	return Vector2i(DOOR_X, DOOR_Y if DOOR_Y >= 0 else Y2)

func _ready() -> void:
	_tile_scene = get_parent() as TileScene
	if _tile_scene == null:
		push_error("Building parent is not TileScene")
		return
	# Block cells immediately so pathfinding works from frame 1
	var door := _get_door_cell()
	for cell in _compute_wall_cells(door):
		_tile_scene.blocked_cells[cell] = true
		_tile_scene.los_blocked_cells[cell] = true
	# Defer visual node creation until the scene tree is fully ready
	call_deferred("_spawn_wall_cells")

func _spawn_wall_cells() -> void:
	if _tile_scene == null:
		return
	var wall_h: float = WALL_H * wall_height_mult
	var door := _get_door_cell()
	for cell in _compute_wall_cells(door):
		var wc := RubbleWallCell.new() if rubble_style else WallCell.new()
		wc.wall_h    = wall_h
		wc.grid_cell = cell
		wc.col_sw  = col_sw
		wc.col_se  = col_se
		wc.col_top = col_top
		wc.position = TileScene.grid_to_screen(cell)
		_tile_scene.add_child(wc)
		_wall_nodes.append(wc)
	# Dim the inside of real, enterable rooms by default — relevant on the
	# surface, where the outdoor default is FULL daylight and an indoor space
	# with no door (DOOR_X == 999 marks a perimeter/decorative wall, not a
	# room) shouldn't read as just as bright as standing outside.
	if _tile_scene.default_light_level == LightLevels.FULL and DOOR_X != 999:
		var interior := _compute_interior_cells()
		if not interior.is_empty():
			_tile_scene.register_ambient_region(interior, LightLevels.DIM)
	_is_real_room = (X2 - X1 >= 2 and Y2 - Y1 >= 2)
	if _is_real_room:
		_spawn_roof(wall_h)

# Purely-visual flat cap spanning the whole footprint at wall-top height.
# Only spawned for a real rectangular footprint — a degenerate line (a
# corridor/perimeter wall strip, X1==X2 or Y1==Y2) has nothing to cap.
func _spawn_roof(wall_h: float) -> void:
	var top_pt: Vector2    = TileScene.grid_to_screen(Vector2i(X1, Y1)) + Vector2(0, -16)
	var right_pt: Vector2  = TileScene.grid_to_screen(Vector2i(X2, Y1)) + Vector2(32, 0)
	var bottom_pt: Vector2 = TileScene.grid_to_screen(Vector2i(X2, Y2)) + Vector2(0, 16)
	var left_pt: Vector2   = TileScene.grid_to_screen(Vector2i(X1, Y2)) + Vector2(-32, 0)
	var up := Vector2(0, -wall_h)
	var roof := RoofCap.new()
	roof.position = bottom_pt
	roof.points = PackedVector2Array([
		top_pt - bottom_pt + up,
		right_pt - bottom_pt + up,
		up,
		left_pt - bottom_pt + up,
	])
	roof.col_roof = col_roof
	roof.col_out  = col_out
	_tile_scene.add_child(roof)
	_roof_node = roof

# ── Player-visibility translucency ──────────────────────────────────────────
# Walls block line-of-sight by design (real occlusion — a wall genuinely can
# hide something behind it), but the player must never lose track of their
# own character. This is a deliberate carve-out for the player sprite only;
# NPCs/enemies staying legitimately hidden behind walls is correct and
# untouched (fog-of-war handles that independently via fow_hide_when_unseen).
func _process(_delta: float) -> void:
	if _wall_nodes.is_empty():
		return
	var player: Node = GameManager.player
	if player == null:
		return
	var player_cell = player.get("grid_cell")
	if player_cell == null:
		return
	var pc: Vector2i = player_cell
	if pc == _last_player_cell:
		return
	_last_player_cell = pc

	var wall_h: float = WALL_H * wall_height_mult
	var reach: int = ceili((wall_h + 60.0) / (TileScene.TILE_H / 2.0))  # 60 = Player.SPRITE_H
	if pc.x < X1 - reach or pc.x > X2 + reach or pc.y < Y1 - reach or pc.y > Y2 + reach:
		_set_all_translucent(false)
		return

	if _is_real_room and pc in _compute_interior_cells():
		# Per-side, not per-tile: if any tile of a wall face occludes the player,
		# fade that whole face as one unit rather than just the occluding tile —
		# a single tile popping translucent while its neighbors stay solid reads
		# as glitchy in a room big enough to have real wall faces (see the
		# ritual chamber, an 11x15 room, where this was noticeable).
		var side_occluded: Dictionary = {"north": false, "south": false, "east": false, "west": false}
		for wc in _wall_nodes:
			if not is_instance_valid(wc):
				continue
			if cell_occludes_player(wc.grid_cell, pc, wall_h):
				side_occluded[_wall_side(wc.grid_cell)] = true
		# South and east are the two camera-facing walls in this isometric
		# view (the ones that can actually stand between the camera and a
		# player standing further back in the room) — tie them together so
		# either one occluding fades both, instead of just its own face.
		if side_occluded["south"] or side_occluded["east"]:
			side_occluded["south"] = true
			side_occluded["east"] = true
		for wc in _wall_nodes:
			if not is_instance_valid(wc):
				continue
			wc.set_translucent(side_occluded[_wall_side(wc.grid_cell)])
		if _roof_node != null and is_instance_valid(_roof_node):
			_roof_node.set_translucent(true)
		return

	var occluded: bool = false
	for wc in _wall_nodes:
		if not is_instance_valid(wc):
			continue
		var cell: Vector2i = wc.grid_cell
		if cell_occludes_player(cell, pc, wall_h):
			occluded = true
			break
	_set_all_translucent(occluded)

func _set_all_translucent(v: bool) -> void:
	for wc in _wall_nodes:
		if is_instance_valid(wc):
			wc.set_translucent(v)
	if _roof_node != null and is_instance_valid(_roof_node):
		_roof_node.set_translucent(v)

# Does a wall cell at `wall_cell` visually occlude the player standing at
# `player_cell`, given wall height `wall_h`? Uses the same (x−y, x+y)
# transform as TileScene.grid_to_screen(): a cell only needs checking if it
# sorts on/after the player (y_sort draws it after — the wall's tall geometry
# extruding upward from its base can then paint over the player's already-
# drawn sprite), within screen-space reach (wall height + the player's own
# sprite height extending upward from its base), and roughly column-aligned.
static func cell_occludes_player(wall_cell: Vector2i, player_cell: Vector2i, wall_h: float) -> bool:
	var wall_sort: int   = wall_cell.x + wall_cell.y
	var player_sort: int = player_cell.x + player_cell.y
	if player_sort >= wall_sort:
		return false
	var col_diff: int = absi((wall_cell.x - wall_cell.y) - (player_cell.x - player_cell.y))
	if col_diff > 1:
		return false
	var reach: float = (wall_h + 60.0) / (TileScene.TILE_H / 2.0)  # 60 = Player.SPRITE_H
	return float(wall_sort - player_sort) <= reach

# North/south rows span the full X1..X2 (including corners); west/east
# columns only cover the strip between them (see _compute_wall_cells), so
# checking y first here can't misclassify a corner cell as east/west.
func _wall_side(cell: Vector2i) -> String:
	if cell.y == Y1:
		return "north"
	if cell.y == Y2:
		return "south"
	if cell.x == X1:
		return "west"
	return "east"

func _compute_interior_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if X2 - X1 < 2 or Y2 - Y1 < 2:
		return cells
	for x in range(X1 + 1, X2):
		for y in range(Y1 + 1, Y2):
			cells.append(Vector2i(x, y))
	return cells

func _exit_tree() -> void:
	for wc in _wall_nodes:
		if is_instance_valid(wc):
			wc.queue_free()
	_wall_nodes.clear()
	if _roof_node != null and is_instance_valid(_roof_node):
		_roof_node.queue_free()
	_roof_node = null

func _compute_wall_cells(door: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for x in range(X1, X2 + 1):
		if Vector2i(x, Y1) != door:
			cells.append(Vector2i(x, Y1))
	for y in range(Y1 + 1, Y2):
		if Vector2i(X1, y) != door:
			cells.append(Vector2i(X1, y))
	for y in range(Y1 + 1, Y2):
		if Vector2i(X2, y) != door:
			cells.append(Vector2i(X2, y))
	for x in range(X1, X2 + 1):
		if Vector2i(x, Y2) != door:
			cells.append(Vector2i(x, Y2))
	return cells
