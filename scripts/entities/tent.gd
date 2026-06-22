extends Entity
class_name Tent

# A simple representation of a pitched tent. Single-tile footprint, blocks
# movement and line of sight, and provides cover like a small rock.

@export var grid_cell: Vector2i = Vector2i(10, 10)

const TENT_W: int = 36
const TENT_H: int = 26

var _tile_scene: TileScene = null

func _ready() -> void:
	is_interactable = false
	blocks_movement = true
	entity_name     = "Tent"
	_tile_scene = get_parent() as TileScene
	if _tile_scene == null:
		return
	position = TileScene.grid_to_screen(grid_cell)
	_tile_scene.register_entity(grid_cell, self)
	_tile_scene.los_blocked_cells[grid_cell] = true
	_tile_scene.register_cover(grid_cell, 0.5)

func _exit_tree() -> void:
	if _tile_scene == null:
		return
	_tile_scene.unregister_entity(grid_cell)
	_tile_scene.los_blocked_cells.erase(grid_cell)
	_tile_scene.unregister_cover(grid_cell)

func _draw() -> void:
	var base_y: float = TileScene.TILE_H / 4.0
	var w: float = float(TENT_W)
	var h: float = float(TENT_H)

	var body := PackedVector2Array([
		Vector2(-w * 0.50, base_y),
		Vector2( 0.0,       base_y - h),
		Vector2( w * 0.50, base_y),
	])
	draw_colored_polygon(body, Color(0.52, 0.42, 0.28))

	var shaded := PackedVector2Array([
		Vector2( 0.0,       base_y - h),
		Vector2( w * 0.50, base_y),
		Vector2( w * 0.15, base_y),
	])
	draw_colored_polygon(shaded, Color(0.40, 0.32, 0.20))

	draw_polyline(body + PackedVector2Array([body[0]]), Color(0.22, 0.17, 0.10), 1.2)
