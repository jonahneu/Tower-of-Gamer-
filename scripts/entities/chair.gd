extends Node2D
# Prop: a simple wooden chair.

@export var grid_cell: Vector2i = Vector2i(0, 0)

const SEAT_W: float = 20.0
const SEAT_H: float = 8.0
const BACK_H: float = 14.0

var _tile_scene: TileScene = null

func _ready() -> void:
	_tile_scene = get_parent() as TileScene
	if _tile_scene == null:
		return
	position = TileScene.grid_to_screen(grid_cell)
	queue_redraw()

func _draw() -> void:
	var base_y: float   = TileScene.TILE_H / 4.0
	var col: Color      = Color(0.48, 0.32, 0.14)   # darker wood than table
	var col_dark: Color = col.darkened(0.40)

	# Chair back — upright rectangle behind the seat
	draw_rect(Rect2(-SEAT_W * 0.5, -SEAT_H - BACK_H + base_y, SEAT_W * 0.22, BACK_H), col_dark)

	# Seat
	var seat := Rect2(-SEAT_W * 0.5, -SEAT_H + base_y, SEAT_W, SEAT_H)
	draw_rect(seat, col)

	# Outline
	draw_rect(seat, col_dark, false, 1.0)
