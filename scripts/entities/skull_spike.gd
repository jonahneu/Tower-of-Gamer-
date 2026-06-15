extends Node2D
class_name SkullSpike
# Prop: a sharpened post topped with a human skull — a territorial warning marker. Visual only.

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
	var wood_col: Color   = Color(0.32, 0.22, 0.13)
	var bone_col: Color   = Color(0.85, 0.81, 0.71)
	var socket_col: Color = Color(0.18, 0.14, 0.12)

	# Spike post
	draw_line(Vector2(0.0, base_y + 2.0), Vector2(0.0, base_y - 22.0), wood_col, 2.5)
	# Sharpened tip
	draw_colored_polygon(PackedVector2Array([
		Vector2(-1.5, base_y - 22.0),
		Vector2( 1.5, base_y - 22.0),
		Vector2( 0.0, base_y - 27.0),
	]), wood_col)

	# Skull mounted near the top of the spike
	draw_circle(Vector2(0.0, base_y - 19.0), 4.5, bone_col)
	# Jaw
	draw_colored_polygon(PackedVector2Array([
		Vector2(-2.5, base_y - 16.0),
		Vector2( 2.5, base_y - 16.0),
		Vector2( 1.5, base_y - 12.5),
		Vector2(-1.5, base_y - 12.5),
	]), bone_col)
	# Eye sockets
	draw_circle(Vector2(-1.8, base_y - 19.5), 1.1, socket_col)
	draw_circle(Vector2( 1.8, base_y - 19.5), 1.1, socket_col)
