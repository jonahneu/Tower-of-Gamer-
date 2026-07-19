extends Node2D
class_name CorpsePile
# Placeholder prop: a pile of past sacrifices who fell through the chute and
# didn't survive the landing, sitting just inside the tunnel. Visual only —
# non-blocking (the player's own entry point lands right on/near it) —
# examinable, no dialogue: description is a placeholder for the user to write.

@export var grid_cell: Vector2i = Vector2i(0, 0)

var entity_name: String = "Corpse Pile"
var is_interactable: bool = true
var blocks_movement: bool = false
var _tile_scene: TileScene = null
var _highlighted: bool = false

func _ready() -> void:
	_tile_scene = get_parent() as TileScene
	position = TileScene.grid_to_screen(grid_cell)
	if _tile_scene != null:
		_tile_scene.register_entity(grid_cell, self)
	EventBus.highlight_toggled.connect(_on_highlight_toggled)
	queue_redraw()

func _exit_tree() -> void:
	if _tile_scene != null:
		_tile_scene.unregister_entity(grid_cell)

func get_interaction_options() -> Array:
	return [{"label": "Examine", "id": "examine", "priority": 50}]

func get_description() -> String:
	return "[PLACEHOLDER: corpse-pile examine text — user's to write]"

func _on_highlight_toggled(active: bool) -> void:
	_highlighted = active
	queue_redraw()

func get_click_polygon() -> PackedVector2Array:
	var w := TileScene.TILE_W * 1.1
	var h := TileScene.TILE_H * 1.1
	return PackedVector2Array([
		position + Vector2(0, -h), position + Vector2(w, 0),
		position + Vector2(0, h),  position + Vector2(-w, 0),
	])

func _draw() -> void:
	# Rough placeholder mound — spread-out overlapping dark irregular blobs
	# reading as "several bodies sprawled across the floor" from iso view, no
	# attempt at real corpse shapes.
	var base_col := Color(0.30, 0.16, 0.14)
	var shade_col := Color(0.20, 0.10, 0.09)
	draw_circle(Vector2(-34, 6),  16.0, shade_col)
	draw_circle(Vector2(26, -10), 14.0, shade_col)
	draw_circle(Vector2(4, 16),   15.0, shade_col)
	draw_circle(Vector2(-14, -6), 17.0, base_col)
	draw_circle(Vector2(18, 8),   15.0, base_col)
	draw_circle(Vector2(-30, -12), 11.0, base_col)
	draw_circle(Vector2(32, 14),  10.0, base_col)

	if _highlighted:
		draw_circle(Vector2(0, 2), 42.0, Color(1.0, 0.85, 0.0, 0.16))
		draw_arc(Vector2(0, 2), 42.0, 0, TAU, 32, Color(1.0, 0.85, 0.0), 2.0)
		_draw_name_label(-50.0)

func _draw_name_label(label_y: float) -> void:
	if entity_name == "":
		return
	var font := ThemeDB.fallback_font
	var fs: int = 11
	var tw: float = font.get_string_size(entity_name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var lx := -tw / 2.0
	draw_rect(Rect2(lx - 3, label_y - fs - 1, tw + 6, fs + 4), Color(0, 0, 0, 0.65))
	draw_string(font, Vector2(lx, label_y), entity_name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1.0, 0.95, 0.7))
