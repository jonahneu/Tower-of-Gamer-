extends Node2D
# Prop: a large dead lizard lying on the ground, being skinned by the Old Hunter.
# Non-interactable, does not block movement.

@export var grid_cell: Vector2i = Vector2i(0, 0)

const BODY_W: float = 100.0
const BODY_H: float = 56.0

var _tile_scene: TileScene = null

func _ready() -> void:
	_tile_scene = get_parent() as TileScene
	if _tile_scene == null:
		return
	position = TileScene.grid_to_screen(grid_cell)
	queue_redraw()

func _draw() -> void:
	# Anchored near the top of this tile, extending southward to cover the tile below.
	# TILE_H/2 = 16px per tile step; offset so the rect starts ~8px above centre
	# and reaches ~48px below, covering both (51,26) and (51,27).
	var top_y: float = -8.0
	var col: Color = Color(0.20, 0.38, 0.14)   # olive-green, deadened

	# Main body — wide flat rectangle (lying along the north-south axis)
	var body := Rect2(-BODY_W * 0.5, top_y, BODY_W, BODY_H)
	draw_rect(body, col)

	# Head bump on the left end, slightly protruding
	var head_w: float = BODY_W * 0.18
	draw_rect(
		Rect2(-BODY_W * 0.5 - 4.0, top_y - 3.0, head_w, BODY_H + 3.0),
		col.darkened(0.22)
	)

	# Faded belly stripe — half-transparent, muted from death
	draw_rect(
		Rect2(-BODY_W * 0.22, top_y + BODY_H * 0.3, BODY_W * 0.44, BODY_H * 0.4),
		Color(0.45, 0.70, 0.18, 0.30)
	)

	# Outline
	draw_rect(body, col.darkened(0.45), false, 1.0)
