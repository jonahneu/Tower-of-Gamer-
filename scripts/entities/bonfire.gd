extends Node2D
class_name Bonfire
# Prop: a large communal fire pit. Visual only — does not block movement or interaction.

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

	# Stone ring — wide oval of stones
	var stone_col: Color = Color(0.42, 0.38, 0.32)
	for i in range(10):
		var angle: float = i * TAU / 10.0
		var sx: float = cos(angle) * 13.0
		var sy: float = sin(angle) * 6.5 + base_y
		draw_circle(Vector2(sx, sy), 2.6, stone_col)

	# Charred logs crossing the pit
	draw_rect(Rect2(-11.0, base_y - 4.0, 22.0, 3.0), Color(0.20, 0.14, 0.10))
	draw_rect(Rect2(-8.0,  base_y - 1.0, 20.0, 3.0), Color(0.26, 0.17, 0.11))

	# Embers / hot coals at base
	draw_rect(Rect2(-8.0, base_y - 6.0, 16.0, 5.0), Color(0.90, 0.35, 0.05, 0.92))

	# Main flame body
	draw_rect(Rect2(-6.0, base_y - 17.0, 12.0, 12.0), Color(0.96, 0.62, 0.08, 0.85))

	# Brighter inner flame
	draw_rect(Rect2(-3.0, base_y - 22.0, 6.0, 8.0), Color(1.0, 0.88, 0.30, 0.80))

	# Tip flicker
	draw_rect(Rect2(-1.5, base_y - 27.0, 3.0, 6.0), Color(1.0, 0.96, 0.65, 0.65))
