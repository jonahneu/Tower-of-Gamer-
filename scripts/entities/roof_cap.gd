extends Node2D
class_name RoofCap

# Purely-visual flat cap spanning a Building's whole footprint at wall-top
# height. Spawned by building.gd only for a real rectangular footprint (see
# building.gd's roof-spawn guard) — line-segment/corridor walls never get one.
# `points` are the 4 footprint corners (N, E, S, W winding, matching
# wall_cell.gd's own T/R/B/L order) in local space, already offset upward by
# the building's wall height.

var points: PackedVector2Array = PackedVector2Array()
var col_roof: Color = Color(0.45, 0.28, 0.20)
var col_out:  Color = Color(0.18, 0.12, 0.08)

const TRANSLUCENT_ALPHA: float = 0.28
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
	if points.size() < 3:
		return
	draw_colored_polygon(points, _a(col_roof))
	draw_polyline(points + PackedVector2Array([points[0]]), _a(col_out), 1.0)

func _a(c: Color) -> Color:
	return Color(c.r, c.g, c.b, c.a * alpha)
