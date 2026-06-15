extends Node2D
class_name TanningRack
# Prop: a wooden frame with a hide stretched and laced for curing. Visual only.

@export var grid_cell: Vector2i = Vector2i(0, 0)

var blocks_movement: bool = false
var is_interactable: bool = false
var _tile_scene: TileScene = null

func _ready() -> void:
	_tile_scene = get_parent() as TileScene
	position = TileScene.grid_to_screen(grid_cell)
	queue_redraw()

func _draw() -> void:
	var base_y: float = TileScene.TILE_H / 4.0
	var wood_col: Color  = Color(0.36, 0.25, 0.15)
	var wood_dark: Color = Color(0.24, 0.16, 0.10)
	var hide_col: Color  = Color(0.74, 0.60, 0.42)
	var hide_dark: Color = Color(0.56, 0.44, 0.28)

	# Corner posts
	draw_line(Vector2(-14.0, base_y + 2.0), Vector2(-14.0, base_y - 24.0), wood_col, 2.5)
	draw_line(Vector2( 14.0, base_y + 2.0), Vector2( 14.0, base_y - 24.0), wood_dark, 2.5)

	# Top and bottom crossbars
	draw_line(Vector2(-14.0, base_y - 24.0), Vector2(14.0, base_y - 24.0), wood_col, 2.0)
	draw_line(Vector2(-14.0, base_y - 6.0),  Vector2(14.0, base_y - 6.0),  wood_col, 2.0)

	# Stretched hide
	var hide := PackedVector2Array([
		Vector2(-12.0, base_y - 22.0),
		Vector2( 12.0, base_y - 22.0),
		Vector2( 12.0, base_y - 8.0),
		Vector2(-12.0, base_y - 8.0),
	])
	draw_colored_polygon(hide, hide_col)
	draw_polyline(hide + PackedVector2Array([hide[0]]), hide_dark, 1.0)

	# Lacing marks
	for i in range(5):
		var lx: float = -10.0 + i * 5.0
		draw_line(Vector2(lx, base_y - 22.0), Vector2(lx, base_y - 8.0), hide_dark, 0.6)
