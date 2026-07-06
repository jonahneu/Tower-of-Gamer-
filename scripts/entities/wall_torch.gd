extends Node2D
class_name WallTorch
# Prop: a standing or wall-mounted torch. Visual only — does not block
# movement or interaction. Smaller light radius than a campfire/bonfire.

@export var grid_cell: Vector2i = Vector2i(0, 0)
@export var bright_radius: int = 6
@export var dim_radius: int = 11

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

	# Wooden post
	draw_rect(Rect2(-1.2, base_y - 14.0, 2.4, 14.0), Color(0.32, 0.22, 0.14))

	# Pitch-soaked binding near the top
	draw_rect(Rect2(-2.0, base_y - 15.0, 4.0, 2.5), Color(0.20, 0.14, 0.10))

	# Embers at the head
	draw_rect(Rect2(-2.5, base_y - 19.0, 5.0, 4.0), Color(0.90, 0.35, 0.05, 0.92))

	# Main flame body
	draw_rect(Rect2(-2.0, base_y - 25.0, 4.0, 7.0), Color(0.96, 0.62, 0.08, 0.85))

	# Brighter inner flame
	draw_rect(Rect2(-1.0, base_y - 28.5, 2.0, 4.5), Color(1.0, 0.88, 0.30, 0.80))

	# Tip flicker
	draw_rect(Rect2(-0.5, base_y - 31.0, 1.0, 2.8), Color(1.0, 0.96, 0.65, 0.65))
