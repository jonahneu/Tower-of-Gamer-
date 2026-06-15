extends Node2D
class_name BonePile
# Prop: a scattered heap of bones topped with a skull. Visual only.

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
	var bone_col: Color   = Color(0.82, 0.78, 0.68)
	var bone_dark: Color  = Color(0.62, 0.58, 0.48)
	var shadow_col: Color = Color(0.15, 0.12, 0.10, 0.35)

	# Ground shadow / mound base
	draw_colored_polygon(PackedVector2Array([
		Vector2(-16.0, base_y + 2.0),
		Vector2( 16.0, base_y + 2.0),
		Vector2( 12.0, base_y - 4.0),
		Vector2(-12.0, base_y - 4.0),
	]), shadow_col)

	# Scattered long bones
	_draw_bone(Vector2(-8.0, base_y - 2.0), -0.5, bone_col)
	_draw_bone(Vector2( 4.0, base_y - 4.0),  0.35, bone_col)
	_draw_bone(Vector2(-2.0, base_y - 7.0), -1.2, bone_dark)
	_draw_bone(Vector2( 9.0, base_y - 1.0),  1.0, bone_dark)

	# A skull resting on top
	draw_circle(Vector2(0.0, base_y - 9.0), 4.0, bone_col)
	draw_circle(Vector2(-1.5, base_y - 8.5), 1.0, Color(0.20, 0.16, 0.14))
	draw_circle(Vector2( 1.5, base_y - 8.5), 1.0, Color(0.20, 0.16, 0.14))

func _draw_bone(center: Vector2, angle: float, col: Color) -> void:
	var length: float = 9.0
	var w: float = 2.0
	var dir := Vector2(cos(angle), sin(angle))
	var perp := Vector2(-dir.y, dir.x)
	var a := center + dir * length * 0.5
	var b := center - dir * length * 0.5
	var poly := PackedVector2Array([
		a + perp * w, a - perp * w,
		b - perp * w, b + perp * w,
	])
	draw_colored_polygon(poly, col)
	draw_circle(a, w * 1.3, col)
	draw_circle(b, w * 1.3, col)
