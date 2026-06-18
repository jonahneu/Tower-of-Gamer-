extends Node2D
class_name GlowingFungi
# Prop: bioluminescent cave fungus. Static decoration — dim light only, no
# bright tier (passing bright_radius = -1 to register_light_source, since
# depth <= -1 is never true for any BFS depth).

@export var grid_cell: Vector2i = Vector2i(0, 0)
@export var dim_radius: int = 4

var blocks_movement: bool = false
var is_interactable: bool = false
var _tile_scene: TileScene = null

func _ready() -> void:
	_tile_scene = get_parent() as TileScene
	position = TileScene.grid_to_screen(grid_cell)
	if _tile_scene != null:
		_tile_scene.register_light_source(self, grid_cell, -1, dim_radius)
	queue_redraw()

func _exit_tree() -> void:
	if _tile_scene != null:
		_tile_scene.unregister_light_source(self)

func _draw() -> void:
	var base_y: float = TileScene.TILE_H / 4.0
	var glow_col: Color = Color(0.35, 0.95, 0.75, 0.55)
	var core_col: Color = Color(0.70, 1.0, 0.90, 0.85)

	for i in range(5):
		var angle: float = i * TAU / 5.0 + 0.4
		var gx: float = cos(angle) * 7.0
		var gy: float = sin(angle) * 3.5 + base_y
		draw_circle(Vector2(gx, gy), 4.0, glow_col)
		draw_circle(Vector2(gx, gy), 1.6, core_col)
