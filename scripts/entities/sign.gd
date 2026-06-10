extends Node2D
class_name Sign

# Which wall face to hang on:
#   "se" — south-east face (visible when approaching from the south, used for south-wall doors)
#   "sw" — south-west face (visible when approaching from the west)
var face: String = "se"

var sign_text: String   = ""
var entity_name: String = ""
var grid_cell: Vector2i = Vector2i(0, 0)
var is_interactable: bool = false
var is_sign: bool = true
var _tile_scene: TileScene = null
var _highlighted: bool = false
var _hovered: bool = false

# Sign size in screen pixels — width along the wall face, height up the wall.
const SIGN_W: float = 20.0
const SIGN_H: float = 8.0

# WallCell constants (must match wall_cell.gd)
const WALL_H: float = 28.0

func _ready() -> void:
	position = TileScene.grid_to_screen(grid_cell)
	# Nudge forward in the y-sort so the sign renders in front of the WallCell it sits on.
	position.y += 0.5
	entity_name = sign_text
	_tile_scene = get_parent() as TileScene
	if _tile_scene != null:
		_tile_scene.register_ground_item(self)
	EventBus.highlight_toggled.connect(_on_highlight_toggled)
	queue_redraw()

# Returns the four corners of the sign parallelogram in local space.
func _corners() -> PackedVector2Array:
	var hw := SIGN_W / 2.0
	var h  := SIGN_H
	if face == "sw":
		# SW face: from L=(-32,0) to B=(0,16). Moving right (+x) also moves down (+y * 0.5).
		# Face center at local (-16, -6).
		return PackedVector2Array([
			Vector2(-16.0 - hw, -6.0 - hw * 0.5),            # BL
			Vector2(-16.0 + hw, -6.0 + hw * 0.5),            # BR
			Vector2(-16.0 + hw, -6.0 + hw * 0.5 - h),        # TR
			Vector2(-16.0 - hw, -6.0 - hw * 0.5 - h),        # TL
		])
	else:  # "se"
		# SE face: from B=(0,16) to R=(32,0). Moving right (+x) moves up (-y * 0.5).
		# Face center at local (16, -6).
		return PackedVector2Array([
			Vector2(16.0 - hw, -6.0 + hw * 0.5),             # BL
			Vector2(16.0 + hw, -6.0 - hw * 0.5),             # BR
			Vector2(16.0 + hw, -6.0 - hw * 0.5 - h),         # TR
			Vector2(16.0 - hw, -6.0 + hw * 0.5 - h),         # TL
		])

func _process(_delta: float) -> void:
	var local_mouse := to_local(get_global_mouse_position())
	var now := Geometry2D.is_point_in_polygon(local_mouse, _corners())
	if now != _hovered:
		_hovered = now
		queue_redraw()

func get_interaction_options() -> Array:
	return []

func get_click_polygon() -> PackedVector2Array:
	var result := PackedVector2Array()
	for c in _corners():
		result.append(position + c)
	return result

func _on_highlight_toggled(active: bool) -> void:
	_highlighted = active
	queue_redraw()

func _exit_tree() -> void:
	if _tile_scene != null:
		_tile_scene.unregister_ground_item(self)

func _draw() -> void:
	var corners := _corners()
	draw_colored_polygon(corners, Color(0.38, 0.25, 0.12))
	var outline := PackedVector2Array(corners)
	outline.append(outline[0])
	draw_polyline(outline, Color(0.62, 0.44, 0.20), 1.0)
	if _highlighted or _hovered:
		var min_y := corners[0].y
		for c in corners:
			if c.y < min_y: min_y = c.y
		_draw_label(min_y - 4.0)

func _draw_label(label_y: float) -> void:
	var font := ThemeDB.fallback_font
	var fs: int = 11
	var tw: float = font.get_string_size(sign_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var lx := -tw / 2.0
	draw_rect(Rect2(lx - 3.0, label_y - fs - 1.0, tw + 6.0, fs + 4.0), Color(0.0, 0.0, 0.0, 0.70))
	draw_string(font, Vector2(lx, label_y), sign_text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1.0, 0.95, 0.75))
