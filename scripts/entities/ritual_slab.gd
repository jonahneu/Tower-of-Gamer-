extends Node2D
class_name RitualSlab
# Prop: the sacrifice slab at the center of the ritual chamber (DesignDoc_BronzeAge.md
# §13, "The Interrupted Sacrifice"). Visual only — blocks movement (it's solid
# stone), examinable, no dialogue: description is a placeholder for the user to
# write, per the no-Claude-dialogue rule on this feature.

@export var grid_cell: Vector2i = Vector2i(40, 40)

var blocks_movement: bool = true
var is_interactable: bool = true
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
	return "[PLACEHOLDER: sacrifice-slab examine text — user's to write]"

func _on_highlight_toggled(active: bool) -> void:
	_highlighted = active
	queue_redraw()

func get_click_polygon() -> PackedVector2Array:
	var w := TileScene.TILE_W * 0.55
	var h := TileScene.TILE_H * 0.55
	return PackedVector2Array([
		position + Vector2(0, -h), position + Vector2(w, 0),
		position + Vector2(0, h),  position + Vector2(-w, 0),
	])

func _draw() -> void:
	var w := TileScene.TILE_W * 0.5
	var h := TileScene.TILE_H * 0.5
	var raise := 10.0

	# Slab top (flat stone surface, slightly raised)
	var top_pts := PackedVector2Array([
		Vector2(0, -h - raise), Vector2(w, -raise),
		Vector2(0, h - raise),  Vector2(-w, -raise),
	])
	draw_colored_polygon(top_pts, Color(0.38, 0.36, 0.34))
	draw_polyline(top_pts + PackedVector2Array([top_pts[0]]), Color(0.16, 0.15, 0.14), 1.5)

	# Side faces down to the ground, reads as a raised block
	draw_colored_polygon(PackedVector2Array([
		Vector2(-w, -raise), Vector2(0, h - raise), Vector2(0, h), Vector2(-w, 0),
	]), Color(0.26, 0.25, 0.23))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, h - raise), Vector2(w, -raise), Vector2(w, 0), Vector2(0, h),
	]), Color(0.30, 0.29, 0.27))

	# Dark stain at the slab's center — old, not explained further than this
	draw_circle(Vector2(0, -raise * 0.4), 6.0, Color(0.22, 0.05, 0.05, 0.55))

	if _highlighted:
		draw_colored_polygon(top_pts, Color(1.0, 0.85, 0.0, 0.22))
		draw_polyline(top_pts + PackedVector2Array([top_pts[0]]), Color(1.0, 0.85, 0.0), 2.0)
