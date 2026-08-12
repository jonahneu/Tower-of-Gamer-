extends Node2D
class_name PipeMouth
# Purely decorative — a drainage pipe mouth set into a wall face, marking
# where the player climbed out of (Outskirts side) or is about to climb into
# (rest-alcove side) the tutorial's drainage tunnel. Draws over whatever wall
# cell already occupies this grid_cell; doesn't register as an entity or
# affect walkability itself — callers control that via the wall/bounds setup
# around it (see zone_escape_route_rest.tscn / zone_outskirts_ruins_entry.tscn).

@export var grid_cell: Vector2i = Vector2i(0, 0)
@export var wall_h: float = 56.0  # height up the wall face the pipe sits at

const TILE_W := TileScene.TILE_W
const TILE_H := TileScene.TILE_H
const TOP    := Vector2(0,               -TILE_H / 2.0)
const RIGHT  := Vector2( TILE_W / 2.0,  0)
const BOTTOM := Vector2(0,               TILE_H / 2.0)
const LEFT   := Vector2(-TILE_W / 2.0,  0)

const COL_RIM:      Color = Color(0.30, 0.27, 0.22)
const COL_RIM_LIT:  Color = Color(0.42, 0.38, 0.32)
const COL_VOID:     Color = Color(0.02, 0.02, 0.03)
const COL_DRIP:     Color = Color(0.20, 0.24, 0.20, 0.6)

func _ready() -> void:
	position = TileScene.grid_to_screen(grid_cell)
	z_index = 5
	queue_redraw()

func _draw() -> void:
	var c := Vector2(0, -wall_h)
	# Stone rim set into the wall face — a ring around the pipe mouth
	draw_circle(c, 15.0, COL_RIM)
	draw_circle(c, 15.0, COL_RIM_LIT, false, 2.0)
	# Dark pipe interior
	draw_circle(c, 11.0, COL_VOID)
	# A couple of rivets/cracks around the rim for texture
	for a in [30.0, 150.0, 210.0, 330.0]:
		var rad := deg_to_rad(a)
		var p := c + Vector2(cos(rad), sin(rad)) * 12.5
		draw_circle(p, 1.3, COL_RIM_LIT)
	# Faint damp streak below the mouth, running down the wall face
	draw_line(c + Vector2(-3, 10), c + Vector2(-4, 22), COL_DRIP, 3.0)
	draw_line(c + Vector2(4, 10), c + Vector2(5, 20), COL_DRIP, 2.0)
