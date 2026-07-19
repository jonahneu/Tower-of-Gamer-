extends Entity
class_name TrashChute
# Type-A interior-zone transition (DesignDoc_BronzeAge.md, "Building Interiors —
# Two Tiers"): a refuse chute cut into the ritual chamber's floor that the
# player drops through to reach the escape route below. Same mechanism as
# interior_door.gd/ladder.gd — interact() emits EventBus.zone_exit_requested
# (direction), which main.gd's existing zone-exit funnel resolves via the
# CURRENT zone's world_map_data exits{} entry. `direction` is just a lookup
# key here, not a literal compass heading or a vertical-layer change.

@export var grid_cell: Vector2i = Vector2i(40, 40)
@export var direction: String = ""

const TILE_W := TileScene.TILE_W
const TILE_H := TileScene.TILE_H
const TOP    := Vector2(0,               -TILE_H / 2.0)
const RIGHT  := Vector2( TILE_W / 2.0,   0)
const BOTTOM := Vector2(0,               TILE_H / 2.0)
const LEFT   := Vector2(-TILE_W / 2.0,   0)

const HOLE_DEPTH: float = 22.0
const COL_RIM:      Color = Color(0.34, 0.30, 0.24)
const COL_FACE_SW:  Color = Color(0.10, 0.09, 0.10)
const COL_FACE_SE:  Color = Color(0.06, 0.05, 0.06)
const COL_HOLE:     Color = Color(0.03, 0.03, 0.04)
const COL_OUTLINE:  Color = Color(0.16, 0.13, 0.10)

var _highlighted: bool = false
var _tile_scene: TileScene = null

func _ready() -> void:
	is_interactable = true
	blocks_movement  = true
	entity_name      = "Refuse Chute"
	_tile_scene      = get_parent() as TileScene
	if _tile_scene == null:
		push_error("TrashChute: parent must be TileScene")
		return
	position = TileScene.grid_to_screen(grid_cell)
	_tile_scene.register_entity(grid_cell, self)
	EventBus.highlight_toggled.connect(_on_highlight_toggled)
	queue_redraw()

func get_interaction_options() -> Array:
	return [
		{"label": "Jump Down", "id": "interact", "priority": 100},
		{"label": "Examine",   "id": "examine",  "priority": 50},
	]

func get_description() -> String:
	return "A refuse chute cut into the floor, wide enough for a body. It drops into darkness below."

func get_action_label() -> String:
	return "Jump Down"

func interact() -> void:
	if direction == "":
		push_error("TrashChute: direction not set")
		return
	if GameManager.tactical_mode:
		CombatManager.end_tactical()
	EventBus.zone_exit_requested.emit(direction)

func _on_highlight_toggled(active: bool) -> void:
	_highlighted = active
	queue_redraw()

func get_click_polygon() -> PackedVector2Array:
	return PackedVector2Array([position + TOP, position + RIGHT, position + BOTTOM, position + LEFT])

func _draw() -> void:
	# Stone rim flush with the floor
	draw_colored_polygon(PackedVector2Array([TOP, RIGHT, BOTTOM, LEFT]), COL_RIM)
	# Dark hole sunk into the middle of the tile
	var hole_pts := PackedVector2Array([
		TOP.lerp(Vector2.ZERO, 0.55), RIGHT.lerp(Vector2.ZERO, 0.55),
		BOTTOM.lerp(Vector2.ZERO, 0.55), LEFT.lerp(Vector2.ZERO, 0.55),
	])
	var d := Vector2(0.0, HOLE_DEPTH)
	# Depth faces so the hole reads as sinking down, not just a flat dark patch
	draw_colored_polygon(PackedVector2Array([hole_pts[2], hole_pts[3], hole_pts[3] + d, hole_pts[2] + d]), COL_FACE_SW)
	draw_colored_polygon(PackedVector2Array([hole_pts[1], hole_pts[2], hole_pts[2] + d, hole_pts[1] + d]), COL_FACE_SE)
	draw_colored_polygon(hole_pts, COL_HOLE)
	draw_polyline(PackedVector2Array([TOP, RIGHT, BOTTOM, LEFT, TOP]), COL_OUTLINE, 1.0)
	draw_polyline(hole_pts + PackedVector2Array([hole_pts[0]]), COL_OUTLINE, 1.0)

	if _highlighted:
		draw_colored_polygon(PackedVector2Array([TOP, RIGHT, BOTTOM, LEFT]), Color(1.0, 0.85, 0.0, 0.20))
		draw_polyline(PackedVector2Array([TOP, RIGHT, BOTTOM, LEFT, TOP]), Color(1.0, 0.85, 0.0), 2.0)
		_draw_name_label(TOP.y - 4)

func _draw_name_label(label_y: float) -> void:
	if entity_name == "":
		return
	var font := ThemeDB.fallback_font
	var fs: int = 11
	var tw: float = font.get_string_size(entity_name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var lx := -tw / 2.0
	draw_rect(Rect2(lx - 3, label_y - fs - 1, tw + 6, fs + 4), Color(0, 0, 0, 0.65))
	draw_string(font, Vector2(lx, label_y), entity_name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1.0, 0.95, 0.7))
