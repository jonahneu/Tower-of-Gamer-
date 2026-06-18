extends Node2D
class_name Campfire
# Prop: a small campfire. Visual only — does not block movement or interaction.

@export var grid_cell: Vector2i = Vector2i(0, 0)
@export var bright_radius: int = 5
@export var dim_radius: int = 9

var blocks_movement: bool = false
var is_interactable: bool = false
var _tile_scene: TileScene = null

func _ready() -> void:
	_tile_scene = get_parent() as TileScene
	position = TileScene.grid_to_screen(grid_cell)
	if _tile_scene != null:
		_tile_scene.register_light_source(self, grid_cell, bright_radius, dim_radius)
	queue_redraw()

func _exit_tree() -> void:
	if _tile_scene != null:
		_tile_scene.unregister_light_source(self)

func _draw() -> void:
	var base_y: float = TileScene.TILE_H / 4.0

	# Stone ring — six small stones in an oval
	var stone_col: Color = Color(0.42, 0.38, 0.32)
	for i in range(6):
		var angle: float = i * TAU / 6.0
		var sx: float = cos(angle) * 7.0
		var sy: float = sin(angle) * 3.5 + base_y
		draw_circle(Vector2(sx, sy), 2.2, stone_col)

	# Embers / hot coals at base
	draw_rect(Rect2(-4.0, base_y - 3.0, 8.0, 3.5), Color(0.88, 0.32, 0.05, 0.90))

	# Main flame body
	draw_rect(Rect2(-3.0, base_y - 9.0, 6.0, 7.0), Color(0.96, 0.62, 0.08, 0.82))

	# Brighter inner flame
	draw_rect(Rect2(-1.5, base_y - 12.0, 3.0, 5.0), Color(1.0, 0.88, 0.30, 0.78))

	# Tip flicker
	draw_rect(Rect2(-0.8, base_y - 15.0, 1.6, 4.0), Color(1.0, 0.96, 0.65, 0.60))
