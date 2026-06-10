extends Entity
class_name Door

const DOOR_H: int = 28  # height of the door block in pixels

@export var grid_cell: Vector2i = Vector2i(40, 28)
var is_open: bool = false
var _highlighted: bool = false
var _tile_scene: TileScene = null

# Tile diamond corners (relative to grid_to_screen center)
const TOP    = Vector2(0,                        -TileScene.TILE_H / 2.0)  # (0,  -16)
const RIGHT  = Vector2( TileScene.TILE_W / 2.0,  0)                        # (32,   0)
const BOTTOM = Vector2(0,                         TileScene.TILE_H / 2.0)  # (0,   16)
const LEFT   = Vector2(-TileScene.TILE_W / 2.0,  0)                        # (-32,  0)

func _ready() -> void:
	is_interactable = true
	blocks_movement = true
	entity_name = "Wooden Door"
	_tile_scene = get_parent() as TileScene
	position = TileScene.grid_to_screen(grid_cell)
	_tile_scene.register_entity(grid_cell, self)
	_tile_scene.los_blocked_cells[grid_cell] = true
	EventBus.highlight_toggled.connect(_on_highlight_toggled)
	queue_redraw()

func get_click_polygon() -> PackedVector2Array:
	# Full outer boundary of the raised block in TileScene-local coords
	var rh := Vector2(0, -float(DOOR_H))
	return PackedVector2Array([
		position + LEFT  + rh,
		position + TOP   + rh,
		position + RIGHT + rh,
		position + RIGHT,
		position + BOTTOM,
		position + LEFT,
	])

func get_interaction_options() -> Array:
	return [
		{"label": "Close" if is_open else "Open", "id": "open", "priority": 100},
		{"label": "Examine",                       "id": "examine", "priority": 50},
	]

func get_description() -> String:
	return "A sturdy wooden door. It is %s." % ("open" if is_open else "closed")

func get_action_label() -> String:
	return "Close" if is_open else "Open"

func interact() -> void:
	is_open = not is_open
	blocks_movement = not is_open
	if is_open:
		_tile_scene.blocked_cells.erase(grid_cell)
		_tile_scene.los_blocked_cells.erase(grid_cell)
	else:
		_tile_scene.blocked_cells[grid_cell] = true
		_tile_scene.los_blocked_cells[grid_cell] = true
	EventBus.los_blockers_changed.emit()
	queue_redraw()

func _on_highlight_toggled(active: bool) -> void:
	_highlighted = active
	queue_redraw()

func _draw() -> void:
	var h = float(DOOR_H)

	if is_open:
		# Draw a faint filled diamond + clear outline so the tile is still clickable
		draw_colored_polygon(
			PackedVector2Array([TOP, RIGHT, BOTTOM, LEFT]),
			Color(0.62, 0.36, 0.10, 0.18))
		draw_polyline(
			PackedVector2Array([TOP, RIGHT, BOTTOM, LEFT, TOP]),
			Color(0.62, 0.36, 0.10, 0.75), 2.0)
	else:
		# South-west face (left → bottom, raised)
		draw_colored_polygon(
			PackedVector2Array([LEFT, BOTTOM, BOTTOM + Vector2(0,-h), LEFT + Vector2(0,-h)]),
			Color(0.42, 0.22, 0.06))
		# South-east face (bottom → right, raised)
		draw_colored_polygon(
			PackedVector2Array([BOTTOM, RIGHT, RIGHT + Vector2(0,-h), BOTTOM + Vector2(0,-h)]),
			Color(0.35, 0.18, 0.04))
		# Top face — raised by h so corners exactly cap the side faces
		var rh := Vector2(0, -h)
		draw_colored_polygon(
			PackedVector2Array([TOP+rh, RIGHT+rh, BOTTOM+rh, LEFT+rh]),
			Color(0.62, 0.36, 0.10))
		# Outline
		draw_polyline(PackedVector2Array([TOP+rh, RIGHT+rh, BOTTOM+rh, LEFT+rh, TOP+rh]), Color(0.20, 0.10, 0.02), 1.0)
		draw_line(LEFT,   LEFT   + rh, Color(0.20, 0.10, 0.02), 1.0)
		draw_line(BOTTOM, BOTTOM + rh, Color(0.20, 0.10, 0.02), 1.0)
		draw_line(RIGHT,  RIGHT  + rh, Color(0.20, 0.10, 0.02), 1.0)

	if _highlighted:
		var rh2 := Vector2(0, -float(DOOR_H))
		# Overlay all three visible faces
		draw_colored_polygon(PackedVector2Array([LEFT, BOTTOM, BOTTOM+rh2, LEFT+rh2]),   Color(1.0, 0.85, 0.0, 0.25))
		draw_colored_polygon(PackedVector2Array([BOTTOM, RIGHT, RIGHT+rh2, BOTTOM+rh2]), Color(1.0, 0.85, 0.0, 0.25))
		draw_colored_polygon(PackedVector2Array([TOP+rh2, RIGHT+rh2, BOTTOM+rh2, LEFT+rh2]), Color(1.0, 0.85, 0.0, 0.25))
		# Outline the full block perimeter
		draw_polyline(PackedVector2Array([LEFT+rh2, TOP+rh2, RIGHT+rh2, RIGHT, BOTTOM, LEFT, LEFT+rh2]),
			Color(1.0, 0.85, 0.0), 2.0)
		_draw_name_label(TOP.y - float(DOOR_H) - 4)

func _draw_name_label(label_y: float) -> void:
	if entity_name == "":
		return
	var font := ThemeDB.fallback_font
	var fs: int = 11
	var tw: float = font.get_string_size(entity_name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var lx := -tw / 2.0
	draw_rect(Rect2(lx - 3, label_y - fs - 1, tw + 6, fs + 4), Color(0, 0, 0, 0.65))
	draw_string(font, Vector2(lx, label_y), entity_name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1.0, 0.95, 0.7))
