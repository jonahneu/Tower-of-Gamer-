extends Node2D
class_name WallCell

# Draws a single isometric box at the node's local origin.
# Position should be set to TileScene.grid_to_screen(cell) before adding to scene.

const T := Vector2(0,  -16)
const R := Vector2(32,   0)
const B := Vector2(0,   16)
const L := Vector2(-32,  0)

var wall_h: float = 28.0
var grid_cell: Vector2i = Vector2i.ZERO
var col_sw:  Color = Color(0.50, 0.45, 0.38)
var col_se:  Color = Color(0.38, 0.33, 0.26)
var col_top: Color = Color(0.62, 0.57, 0.50)

# Player-visibility translucency (Building drives this — see building.gd's
# per-frame occlusion check). 1.0 = normal solid wall.
const TRANSLUCENT_ALPHA: float = 0.14
var alpha: float = 1.0

func _ready() -> void:
	queue_redraw()

func set_translucent(v: bool) -> void:
	var target: float = TRANSLUCENT_ALPHA if v else 1.0
	if is_equal_approx(alpha, target):
		return
	alpha = target
	queue_redraw()

func _draw() -> void:
	var rh := Vector2(0, -wall_h)
	draw_colored_polygon(PackedVector2Array([L, B, B+rh, L+rh]), _a(col_sw))
	draw_colored_polygon(PackedVector2Array([B, R, R+rh, B+rh]), _a(col_se))
	draw_colored_polygon(PackedVector2Array([T+rh, R+rh, B+rh, L+rh]), _a(col_top))

func _a(c: Color) -> Color:
	return Color(c.r, c.g, c.b, c.a * alpha)
