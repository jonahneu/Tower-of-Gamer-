extends Node2D
# Prop: a simple wooden table.

@export var grid_cell: Vector2i = Vector2i(0, 0)

const TOP_W: float  = 48.0
const TOP_H: float  = 14.0
const LEG_H: float  = 10.0

var _tile_scene: TileScene = null

func _ready() -> void:
	_tile_scene = get_parent() as TileScene
	if _tile_scene == null:
		return
	position = TileScene.grid_to_screen(grid_cell)
	queue_redraw()

func _draw() -> void:
	var base_y: float  = TileScene.TILE_H / 4.0
	var col: Color     = Color(0.52, 0.36, 0.18)   # warm brown wood
	var col_dark: Color = col.darkened(0.35)
	var col_top: Color  = col.lightened(0.15)

	# Legs — two short rectangles below the tabletop
	var leg_w: float = TOP_W * 0.12
	draw_rect(Rect2(-TOP_W * 0.38, base_y, leg_w, LEG_H), col_dark)
	draw_rect(Rect2( TOP_W * 0.26, base_y, leg_w, LEG_H), col_dark)

	# Tabletop — flat elevated surface
	var top := Rect2(-TOP_W * 0.5, -TOP_H + base_y, TOP_W, TOP_H)
	draw_rect(top, col)

	# Lighter surface highlight
	draw_rect(Rect2(-TOP_W * 0.4, -TOP_H + base_y + 2.0, TOP_W * 0.8, TOP_H * 0.45), col_top)

	# Outline
	draw_rect(top, col_dark, false, 1.0)
