extends Entity
class_name Ladder

# Interactable ladder on the pit rim — transports the player between vertically
# stacked zones.  Place at the walkable tile immediately north of the pit edge.

@export var direction: String = "down"   # "down" or "up"
@export var grid_cell: Vector2i = Vector2i(40, 17)

# ── Tile geometry constants ───────────────────────────────────────────────────
const TILE_W := TileScene.TILE_W
const TILE_H := TileScene.TILE_H
const TOP    := Vector2(0,               -TILE_H / 2.0)
const RIGHT  := Vector2( TILE_W / 2.0,   0)
const BOTTOM := Vector2(0,               TILE_H / 2.0)
const LEFT   := Vector2(-TILE_W / 2.0,   0)

# ── Visual constants ──────────────────────────────────────────────────────────
const LADDER_DEPTH: float = 30.0      # px rungs extend into the pit
const COL_PLATFORM: Color = Color(0.22, 0.17, 0.12)        # dark wood tile top
const COL_FRAME:    Color = Color(0.42, 0.30, 0.18)        # pole colour
const COL_RUNG:     Color = Color(0.60, 0.44, 0.26)        # rung colour
const COL_OUTLINE:  Color = Color(0.70, 0.62, 0.48)        # tile outline

var _highlighted: bool = false
var _tile_scene: TileScene = null

func _ready() -> void:
	is_interactable = true
	blocks_movement = true
	entity_name     = "Rope Ladder"
	_tile_scene     = get_parent() as TileScene
	if _tile_scene == null:
		push_error("Ladder: parent must be TileScene")
		return
	position = TileScene.grid_to_screen(grid_cell)
	_tile_scene.register_entity(grid_cell, self)
	EventBus.highlight_toggled.connect(_on_highlight_toggled)
	queue_redraw()


func get_interaction_options() -> Array:
	var label := "Climb Down" if direction == "down" else "Climb Up"
	return [
		{"label": label,    "id": "interact", "priority": 100},
		{"label": "Examine","id": "examine",  "priority": 50},
	]


func get_description() -> String:
	if direction == "down":
		return "A rope ladder descending into the darkness below."
	return "A rope ladder leading back up. Faint light seeps in from above."


func get_action_label() -> String:
	return "Climb Down" if direction == "down" else "Climb Up"


func interact() -> void:
	if GameManager.tactical_mode:
		CombatManager.end_tactical()
	EventBus.zone_exit_requested.emit(direction)


func _on_highlight_toggled(active: bool) -> void:
	_highlighted = active
	queue_redraw()


func get_click_polygon() -> PackedVector2Array:
	if direction == "down":
		return PackedVector2Array([
			position + TOP, position + RIGHT,
			position + BOTTOM + Vector2(0.0, LADDER_DEPTH),
			position + LEFT,
		])
	else:
		return PackedVector2Array([
			position + TOP + Vector2(0.0, -LADDER_DEPTH),
			position + RIGHT, position + BOTTOM, position + LEFT,
		])


func _draw() -> void:
	# ── Top face (dark wooden platform) ──────────────────────────────────────
	draw_colored_polygon(PackedVector2Array([TOP, RIGHT, BOTTOM, LEFT]), COL_PLATFORM)
	draw_polyline(PackedVector2Array([TOP, RIGHT, BOTTOM, LEFT, TOP]), COL_OUTLINE, 1.0)

	# ── Two poles along the south (B→L) edge, extending toward the pit ───────
	# "down" → poles go downward (+Y) into the pit below the tile
	# "up"   → poles go upward (−Y) through the pit ceiling above
	var p_a: Vector2 = BOTTOM.lerp(LEFT, 0.30)
	var p_b: Vector2 = BOTTOM.lerp(LEFT, 0.65)
	var pole_offset := Vector2(0.0, LADDER_DEPTH if direction == "down" else -LADDER_DEPTH)

	draw_line(p_a, p_a + pole_offset, COL_FRAME, 3.0)
	draw_line(p_b, p_b + pole_offset, COL_FRAME, 3.0)

	# ── Rungs ─────────────────────────────────────────────────────────────────
	var rung_count: int = 5
	for i in range(rung_count):
		var t := (float(i) + 0.5) / float(rung_count)
		var offset := pole_offset * t
		draw_line(p_a + offset, p_b + offset, COL_RUNG, 2.0)

	# ── Highlight overlay ─────────────────────────────────────────────────────
	if _highlighted:
		draw_colored_polygon(
			PackedVector2Array([TOP, RIGHT, BOTTOM, LEFT]),
			Color(1.0, 0.85, 0.0, 0.25))
		draw_polyline(
			PackedVector2Array([TOP, RIGHT, BOTTOM, LEFT, TOP]),
			Color(1.0, 0.85, 0.0), 2.0)
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
