extends Node2D
# Prop: a small stack of clay tablets and rolled documents behind the scribe's counter.

@export var grid_cell: Vector2i = Vector2i(0, 0)

var _tile_scene: TileScene = null

func _ready() -> void:
	_tile_scene = get_parent() as TileScene
	if _tile_scene == null:
		return
	position = TileScene.grid_to_screen(grid_cell)
	queue_redraw()

func _draw() -> void:
	var base_y: float = TileScene.TILE_H / 4.0

	# Bottom tablet — widest, dark clay
	draw_rect(Rect2(-13.0, -6.0 + base_y, 26.0, 6.0), Color(0.52, 0.40, 0.28))
	draw_rect(Rect2(-13.0, -6.0 + base_y, 26.0, 6.0), Color(0.28, 0.18, 0.10), false, 0.8)

	# Middle tablet — slightly narrower, lighter clay
	draw_rect(Rect2(-10.0, -11.0 + base_y, 20.0, 5.0), Color(0.60, 0.48, 0.32))
	draw_rect(Rect2(-10.0, -11.0 + base_y, 20.0, 5.0), Color(0.28, 0.18, 0.10), false, 0.8)

	# Top scroll — narrow and round-ish (tall thin rect)
	draw_rect(Rect2(-5.0, -18.0 + base_y, 10.0, 7.0), Color(0.74, 0.64, 0.44))
	draw_rect(Rect2(-5.0, -18.0 + base_y, 10.0, 7.0), Color(0.36, 0.24, 0.12), false, 0.8)
