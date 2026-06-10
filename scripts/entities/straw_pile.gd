extends Node2D
# Prop: a pile of straw in the corner of the inn — where guests sleep.
# Non-interactable, does not block movement.

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
	var col: Color       = Color(0.78, 0.65, 0.18)   # dry straw gold
	var col_dark: Color  = col.darkened(0.30)
	var col_shadow: Color = col.darkened(0.50)

	# Asymmetric bounds: clipped on the east (right) side so it doesn't bleed
	# through the east wall; clipped on the south (bottom) so it doesn't bleed
	# through the south wall (straw anchor at Y=24, south wall at Y=27).
	var x_left: float   = -150.0
	var x_right: float  =   65.0
	var w: float        = x_right - x_left   # 215
	var y_top: float    = -40.0              # -h/2 + base_y
	var y_bottom: float =  44.0              # clipped south (was 56) to clear south wall

	# Base mound
	var body := Rect2(x_left, y_top, w, y_bottom - y_top)
	draw_rect(body, col)

	# Slightly narrower top layer to give a mounded feel
	var top_left  := x_left  + w * 0.15
	var top_w     := w * 0.70
	draw_rect(Rect2(top_left, y_top - 3.0, top_w, (y_bottom - y_top) * 0.55), col.lightened(0.12))

	# Straw-stalk lines suggesting loose hay
	for i: int in range(5):
		var t: float  = float(i) / 4.0
		var lx: float = x_left + w * 0.08 + t * w * 0.84
		var top: float = y_top - 2.0 + t * 3.0
		var bot: float = y_bottom - 1.0
		draw_line(Vector2(lx, top), Vector2(lx + 4.0, bot), col_dark, 1.0)

	# Outline
	draw_rect(body, col_shadow, false, 1.0)
