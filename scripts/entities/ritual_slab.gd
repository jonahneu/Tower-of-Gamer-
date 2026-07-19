extends Node2D
class_name RitualSlab
# Prop: the sacrifice slab at the center of the ritual chamber (DesignDoc_BronzeAge.md
# §13, "The Interrupted Sacrifice"). Visual only — blocks movement (it's solid
# stone), examinable, no dialogue: description is a placeholder for the user to
# write, per the no-Claude-dialogue rule on this feature.
# Spans 3 tiles running north to south. grid_cell is the NORTHERNMOST (lowest-y)
# of the three; the other two extend south (+y) from it. Registered as the same
# entity at all three cells, so clicking/examining any segment hits this node.

@export var grid_cell: Vector2i = Vector2i(40, 40)

var blocks_movement: bool = true
var is_interactable: bool = true
var _tile_scene: TileScene = null
var _highlighted: bool = false

const TILE_W := TileScene.TILE_W
const TILE_H := TileScene.TILE_H

func _cells() -> Array[Vector2i]:
	return [grid_cell, grid_cell + Vector2i(0, 1), grid_cell + Vector2i(0, 2)]

# Per-segment screen-space offsets from the middle segment (this node's
# position), derived from grid_to_screen's north/south step: (TILE_W/2, -TILE_H/2)
# per cell moved north, (-TILE_W/2, TILE_H/2) per cell moved south.
func _segment_offsets() -> Array[Vector2]:
	var w := TILE_W * 0.5
	var h := TILE_H * 0.5
	return [Vector2(w, -h), Vector2(0, 0), Vector2(-w, h)]

func _ready() -> void:
	_tile_scene = get_parent() as TileScene
	position = TileScene.grid_to_screen(grid_cell + Vector2i(0, 1))  # pivot = middle segment
	if _tile_scene != null:
		for cell in _cells():
			_tile_scene.register_entity(cell, self)
	EventBus.highlight_toggled.connect(_on_highlight_toggled)
	queue_redraw()

func _exit_tree() -> void:
	if _tile_scene != null:
		for cell in _cells():
			_tile_scene.unregister_entity(cell)

func get_interaction_options() -> Array:
	return [{"label": "Examine", "id": "examine", "priority": 50}]

func get_description() -> String:
	return "[PLACEHOLDER: sacrifice-slab examine text — user's to write]"

func _on_highlight_toggled(active: bool) -> void:
	_highlighted = active
	queue_redraw()

# Single 8-point hull around all 3 segments (three edge-adjacent diamonds share
# vertices pairwise — see the offsets in _segment_offsets — so this traces the
# outer boundary of the union rather than three disjoint/self-intersecting
# diamonds, which Geometry2D.is_point_in_polygon (player.gd) requires).
func get_click_polygon() -> PackedVector2Array:
	var w := TILE_W * 0.5
	var h := TILE_H * 0.5
	return PackedVector2Array([
		position + Vector2(w, -2 * h),
		position + Vector2(2 * w, -h),
		position + Vector2(w, 0),
		position + Vector2(0, h),
		position + Vector2(-w, 2 * h),
		position + Vector2(-2 * w, h),
		position + Vector2(-w, 0),
		position + Vector2(0, -h),
	])

func _draw() -> void:
	var w := TILE_W * 0.5
	var h := TILE_H * 0.5
	var raise := 10.0

	for off in _segment_offsets():
		# Slab top (flat stone surface, slightly raised)
		var top_pts := PackedVector2Array([
			off + Vector2(0, -h - raise), off + Vector2(w, -raise),
			off + Vector2(0, h - raise),  off + Vector2(-w, -raise),
		])
		draw_colored_polygon(top_pts, Color(0.38, 0.36, 0.34))
		draw_polyline(top_pts + PackedVector2Array([top_pts[0]]), Color(0.16, 0.15, 0.14), 1.5)

		# Side faces down to the ground, reads as a raised block
		draw_colored_polygon(PackedVector2Array([
			off + Vector2(-w, -raise), off + Vector2(0, h - raise), off + Vector2(0, h), off + Vector2(-w, 0),
		]), Color(0.26, 0.25, 0.23))
		draw_colored_polygon(PackedVector2Array([
			off + Vector2(0, h - raise), off + Vector2(w, -raise), off + Vector2(w, 0), off + Vector2(0, h),
		]), Color(0.30, 0.29, 0.27))

		if _highlighted:
			draw_colored_polygon(top_pts, Color(1.0, 0.85, 0.0, 0.22))
			draw_polyline(top_pts + PackedVector2Array([top_pts[0]]), Color(1.0, 0.85, 0.0), 2.0)

	# Dark stain at the slab's center — old, not explained further than this
	draw_circle(Vector2(0, -raise * 0.4), 6.0, Color(0.22, 0.05, 0.05, 0.55))
