extends Entity
class_name InteriorDoor
# Type-A interior-zone transition (DesignDoc_BronzeAge.md, "Building Interiors —
# Two Tiers"): stepping through this door loads a different TileScene entirely,
# same mechanism ladder.gd already uses for vertical up/down transitions —
# interact() emits EventBus.zone_exit_requested(direction), which main.gd's
# existing zone-exit funnel resolves via the CURRENT zone's world_map_data
# exits{} entry. `direction` is just a lookup key here, not a literal compass
# heading — it only has to match whatever key the current zone's exits{} dict
# uses for this door (see the ritual chamber's "east" exit to the escape route
# for why the key and the door's physical wall side don't have to agree).

@export var grid_cell: Vector2i = Vector2i(40, 40)
@export var direction: String = ""
@export var door_label: String = "Door"

const TILE_W := TileScene.TILE_W
const TILE_H := TileScene.TILE_H
const TOP    := Vector2(0,               -TILE_H / 2.0)
const RIGHT  := Vector2( TILE_W / 2.0,   0)
const BOTTOM := Vector2(0,               TILE_H / 2.0)
const LEFT   := Vector2(-TILE_W / 2.0,   0)

const DOOR_H: float = 26.0
const COL_FACE:    Color = Color(0.30, 0.24, 0.16)
const COL_FACE_2:  Color = Color(0.24, 0.19, 0.12)
const COL_TOP:     Color = Color(0.40, 0.32, 0.20)
const COL_OUTLINE: Color = Color(0.16, 0.12, 0.07)

var _highlighted: bool = false
var _tile_scene: TileScene = null

func _ready() -> void:
	is_interactable = true
	blocks_movement  = true
	entity_name      = door_label
	_tile_scene      = get_parent() as TileScene
	if _tile_scene == null:
		push_error("InteriorDoor: parent must be TileScene")
		return
	position = TileScene.grid_to_screen(grid_cell)
	_tile_scene.register_entity(grid_cell, self)
	EventBus.highlight_toggled.connect(_on_highlight_toggled)
	queue_redraw()

func get_interaction_options() -> Array:
	return [
		{"label": "Go through", "id": "interact", "priority": 100},
		{"label": "Examine",    "id": "examine",  "priority": 50},
	]

func get_description() -> String:
	return "A doorway leading onward."

func get_action_label() -> String:
	return "Go through"

func interact() -> void:
	if direction == "":
		push_error("InteriorDoor: direction not set")
		return
	if GameManager.tactical_mode:
		CombatManager.end_tactical()
	EventBus.zone_exit_requested.emit(direction)

func _on_highlight_toggled(active: bool) -> void:
	_highlighted = active
	queue_redraw()

func get_click_polygon() -> PackedVector2Array:
	var rh := Vector2(0, -DOOR_H)
	return PackedVector2Array([
		position + LEFT  + rh, position + TOP + rh, position + RIGHT + rh,
		position + RIGHT, position + BOTTOM, position + LEFT,
	])

func _draw() -> void:
	var rh := Vector2(0, -DOOR_H)
	draw_colored_polygon(PackedVector2Array([LEFT, BOTTOM, BOTTOM + rh, LEFT + rh]), COL_FACE_2)
	draw_colored_polygon(PackedVector2Array([BOTTOM, RIGHT, RIGHT + rh, BOTTOM + rh]), COL_FACE)
	draw_colored_polygon(PackedVector2Array([TOP + rh, RIGHT + rh, BOTTOM + rh, LEFT + rh]), COL_TOP)
	draw_polyline(PackedVector2Array([TOP + rh, RIGHT + rh, BOTTOM + rh, LEFT + rh, TOP + rh]), COL_OUTLINE, 1.0)

	if _highlighted:
		draw_colored_polygon(PackedVector2Array([LEFT, BOTTOM, BOTTOM + rh, LEFT + rh]), Color(1.0, 0.85, 0.0, 0.25))
		draw_colored_polygon(PackedVector2Array([BOTTOM, RIGHT, RIGHT + rh, BOTTOM + rh]), Color(1.0, 0.85, 0.0, 0.25))
		draw_colored_polygon(PackedVector2Array([TOP + rh, RIGHT + rh, BOTTOM + rh, LEFT + rh]), Color(1.0, 0.85, 0.0, 0.25))
		draw_polyline(PackedVector2Array([LEFT + rh, TOP + rh, RIGHT + rh, RIGHT, BOTTOM, LEFT, LEFT + rh]), Color(1.0, 0.85, 0.0), 2.0)
		_draw_name_label(TOP.y - DOOR_H - 4)

func _draw_name_label(label_y: float) -> void:
	if entity_name == "":
		return
	var font := ThemeDB.fallback_font
	var fs: int = 11
	var tw: float = font.get_string_size(entity_name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var lx := -tw / 2.0
	draw_rect(Rect2(lx - 3, label_y - fs - 1, tw + 6, fs + 4), Color(0, 0, 0, 0.65))
	draw_string(font, Vector2(lx, label_y), entity_name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1.0, 0.95, 0.7))
