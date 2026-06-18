extends Node2D
class_name Building

# Creates one WallCell child per wall tile, added directly to TileScene so that
# y_sort_enabled on TileScene handles correct isometric depth ordering.

const WALL_H: float = 28.0

@export var col_sw:  Color = Color(0.50, 0.45, 0.38)
@export var col_se:  Color = Color(0.38, 0.33, 0.26)
@export var col_top: Color = Color(0.62, 0.57, 0.50)
@export var col_out: Color = Color(0.18, 0.12, 0.08)

@export var X1: int = 37
@export var X2: int = 43
@export var Y1: int = 24
@export var Y2: int = 28
@export var DOOR_X: int = 40
@export var DOOR_Y: int = -1  # -1 = south face (Y2); else door is at (DOOR_X, DOOR_Y)

var _wall_nodes: Array = []
var _tile_scene: TileScene = null

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
	var door := _get_door_cell()
	for cell in _compute_wall_cells(door):
		var wc := WallCell.new()
		wc.wall_h  = WALL_H
		wc.col_sw  = col_sw
		wc.col_se  = col_se
		wc.col_top = col_top
		wc.col_out = col_out
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
