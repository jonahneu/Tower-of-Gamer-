extends Entity
class_name Rock

# A cover object. Blocks movement and line of sight.
# rock_size = "small" : single tile, good-sized boulder.
# rock_size = "large" : 2×2 tile footprint — blocks grid_cell plus the three
#                       cells at (+1,0), (0,+1), and (+1,+1). Provides real cover.

@export var grid_cell: Vector2i = Vector2i(10, 10)
@export var rock_size: String = "small"

var _tile_scene: TileScene = null
# Extra cells registered as blocked for the large variant.
var _extra_cells: Array[Vector2i] = []

# Single-tile boulder dimensions (px)
const ROCK_W_SMALL: int = 34
const ROCK_H_SMALL: int = 20

# Multi-tile boulder dimensions (px) — sized to span the 2×2 isometric footprint
const ROCK_W_LARGE: int = 72
const ROCK_H_LARGE: int = 46

func _ready() -> void:
	is_interactable = false
	blocks_movement = true
	entity_name     = "Rock"
	_tile_scene = get_parent() as TileScene
	if _tile_scene == null:
		return
	position = TileScene.grid_to_screen(grid_cell)
	_tile_scene.register_entity(grid_cell, self)

	var cover_size: float = 0.8 if rock_size == "large" else 0.5
	_tile_scene.register_cover(grid_cell, cover_size)

	if rock_size == "large":
		_tile_scene.los_blocked_cells[grid_cell] = true
		var offsets: Array[Vector2i] = [
			Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)
		]
		for off in offsets:
			var c: Vector2i = grid_cell + off
			_extra_cells.append(c)
			if _tile_scene != null:
				_tile_scene.blocked_cells[c] = true
				_tile_scene.los_blocked_cells[c] = true
				_tile_scene.register_cover(c, cover_size)

func _exit_tree() -> void:
	if _tile_scene == null:
		return
	_tile_scene.unregister_entity(grid_cell)
	if rock_size == "large":
		_tile_scene.los_blocked_cells.erase(grid_cell)
	_tile_scene.unregister_cover(grid_cell)
	for c in _extra_cells:
		_tile_scene.blocked_cells.erase(c)
		_tile_scene.los_blocked_cells.erase(c)
		_tile_scene.unregister_cover(c)

func _draw() -> void:
	var base_y: float = TileScene.TILE_H / 4.0

	if rock_size == "large":
		_draw_large(base_y)
	else:
		_draw_small(base_y)

func _draw_small(base_y: float) -> void:
	var w: float = float(ROCK_W_SMALL)
	var h: float = float(ROCK_H_SMALL)

	var body := PackedVector2Array([
		Vector2(-w * 0.50,  base_y - h * 0.10),
		Vector2(-w * 0.30,  base_y - h),
		Vector2( w * 0.10,  base_y - h * 1.10),
		Vector2( w * 0.50,  base_y - h * 0.70),
		Vector2( w * 0.45,  base_y - h * 0.05),
		Vector2(-w * 0.10,  base_y + h * 0.05),
	])
	draw_colored_polygon(body, Color(0.50, 0.47, 0.43))

	var highlight := PackedVector2Array([
		Vector2(-w * 0.20,  base_y - h * 0.95),
		Vector2( w * 0.08,  base_y - h * 1.05),
		Vector2( w * 0.35,  base_y - h * 0.65),
		Vector2( w * 0.10,  base_y - h * 0.55),
	])
	draw_colored_polygon(highlight, Color(0.68, 0.64, 0.58))
	draw_polyline(body + PackedVector2Array([body[0]]), Color(0.28, 0.25, 0.22), 1.2)

func _draw_large(base_y: float) -> void:
	# The visual centre of the 2×2 footprint in screen space is offset from
	# the anchor cell by the average of the four cell offsets:
	#   (0,0)  (+TILE_W/2, +TILE_H/2)  (-TILE_W/2, +TILE_H/2)  (0, +TILE_H)
	# Average → (0, +TILE_H/2) = (0, +16).  We shift the rock body down by that
	# amount so it sits centred over the full footprint.
	var cy: float = base_y + TileScene.TILE_H * 0.5   # visual centre of 2×2
	var w: float  = float(ROCK_W_LARGE)
	var h: float  = float(ROCK_H_LARGE)

	# Main body — wider, rougher silhouette
	var body := PackedVector2Array([
		Vector2(-w * 0.50,  cy - h * 0.12),
		Vector2(-w * 0.38,  cy - h * 0.88),
		Vector2(-w * 0.10,  cy - h * 1.05),
		Vector2( w * 0.18,  cy - h * 1.08),
		Vector2( w * 0.50,  cy - h * 0.72),
		Vector2( w * 0.48,  cy - h * 0.08),
		Vector2( w * 0.10,  cy + h * 0.08),
		Vector2(-w * 0.15,  cy + h * 0.06),
	])
	draw_colored_polygon(body, Color(0.48, 0.45, 0.41))

	# Secondary mass — gives a boulder-cluster feel
	var secondary := PackedVector2Array([
		Vector2(-w * 0.22,  cy - h * 0.10),
		Vector2(-w * 0.45,  cy - h * 0.80),
		Vector2(-w * 0.18,  cy - h * 0.90),
		Vector2( w * 0.05,  cy - h * 0.60),
		Vector2( w * 0.02,  cy - h * 0.08),
	])
	draw_colored_polygon(secondary, Color(0.44, 0.41, 0.37))

	# Highlight face
	var highlight := PackedVector2Array([
		Vector2(-w * 0.05,  cy - h * 1.00),
		Vector2( w * 0.15,  cy - h * 1.04),
		Vector2( w * 0.40,  cy - h * 0.68),
		Vector2( w * 0.12,  cy - h * 0.52),
	])
	draw_colored_polygon(highlight, Color(0.70, 0.66, 0.60))

	# Outline
	draw_polyline(body + PackedVector2Array([body[0]]), Color(0.26, 0.23, 0.20), 1.4)
