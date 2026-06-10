extends Node2D
class_name Counter

# Creates one WallCell child per counter tile, added directly to TileScene so that
# y_sort_enabled on TileScene handles correct isometric depth ordering.

const COUNTER_H: float = 14.0

const COL_SW:  Color = Color(0.42, 0.28, 0.14)
const COL_SE:  Color = Color(0.32, 0.20, 0.08)
const COL_TOP: Color = Color(0.56, 0.40, 0.22)
const COL_OUT: Color = Color(0.18, 0.10, 0.04)

# Horizontal span (default): set X1, X2, Y — counter runs along X at fixed Y.
# Vertical span: set X, Y1, Y2 — counter runs along Y at fixed X.
@export var X1: int = 43
@export var X2: int = 48
@export var Y:  int = 57
@export var X:  int = -1   # set >= 0 to use vertical mode
@export var Y1: int = -1
@export var Y2: int = -1

var _wall_nodes: Array = []
var _tile_scene: TileScene = null

func _ready() -> void:
	_tile_scene = get_parent() as TileScene
	if _tile_scene == null:
		push_error("Counter parent is not TileScene")
		return
	if X >= 0:
		for y in range(Y1, Y2 + 1):
			_tile_scene.blocked_cells[Vector2i(X, y)] = true
	else:
		for x in range(X1, X2 + 1):
			_tile_scene.blocked_cells[Vector2i(x, Y)] = true
	call_deferred("_spawn_wall_cells")

func _spawn_wall_cells() -> void:
	if _tile_scene == null:
		return
	if X >= 0:
		for y in range(Y1, Y2 + 1):
			var wc := WallCell.new()
			wc.wall_h = COUNTER_H
			wc.col_sw = COL_SW
			wc.col_se = COL_SE
			wc.col_top = COL_TOP
			wc.col_out = COL_OUT
			wc.position = TileScene.grid_to_screen(Vector2i(X, y))
			_tile_scene.add_child(wc)
			_wall_nodes.append(wc)
	else:
		for x in range(X1, X2 + 1):
			var wc := WallCell.new()
			wc.wall_h = COUNTER_H
			wc.col_sw = COL_SW
			wc.col_se = COL_SE
			wc.col_top = COL_TOP
			wc.col_out = COL_OUT
			wc.position = TileScene.grid_to_screen(Vector2i(x, Y))
			_tile_scene.add_child(wc)
			_wall_nodes.append(wc)

func _exit_tree() -> void:
	for wc in _wall_nodes:
		if is_instance_valid(wc):
			wc.queue_free()
	_wall_nodes.clear()
