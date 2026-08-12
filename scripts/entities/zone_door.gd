extends Entity
class_name ZoneDoor
# A doorway sitting in a Building wall's DOOR_X/DOOR_Y gap that transitions to
# an adjacent zone on interact, for rooms whose walls are too small (or too
# fully enclosed) to ever let the player reach the true 80x80 grid edge for a
# normal walk-off exit. Same mechanism as ladder.gd/trash_chute.gd — interact()
# emits EventBus.zone_exit_requested(direction), which main.gd's existing
# zone-exit funnel resolves via the CURRENT zone's world_map_data exits{}
# entry. Unlike door.gd, this never toggles open/closed — walking up and
# interacting always attempts the transition, so it stays drawn "closed."

const DOOR_H: int = 66  # matches door.gd — taller than Player.SPRITE_H (60)

@export var grid_cell: Vector2i = Vector2i(40, 40)
@export var direction: String = ""
@export var display_name: String = "Doorway"
@export var action_label: String = "Go Through"

var _highlighted: bool = false
var _tile_scene: TileScene = null

# Player-visibility translucency (mirrors door.gd/building.gd — see building.gd's
# "player must never lose track of their own character" comment).
const TRANSLUCENT_ALPHA: float = 0.14
var _alpha: float = 1.0
var _last_player_cell: Vector2i = Vector2i(-999999, -999999)

var _lintel_h: float = Building.WALL_H * 3.0
var _lintel_col_sw: Color = Color(0.50, 0.45, 0.38)
var _lintel_col_se: Color = Color(0.38, 0.33, 0.26)
var _lintel_col_top: Color = Color(0.62, 0.57, 0.50)

const TOP    = Vector2(0,                        -TileScene.TILE_H / 2.0)
const RIGHT  = Vector2( TileScene.TILE_W / 2.0,  0)
const BOTTOM = Vector2(0,                         TileScene.TILE_H / 2.0)
const LEFT   = Vector2(-TileScene.TILE_W / 2.0,  0)

func _ready() -> void:
	is_interactable = true
	blocks_movement = true
	entity_name = display_name
	_tile_scene = get_parent() as TileScene
	if _tile_scene == null:
		push_error("ZoneDoor: parent must be TileScene")
		return
	position = TileScene.grid_to_screen(grid_cell)
	_tile_scene.register_entity(grid_cell, self)
	_tile_scene.los_blocked_cells[grid_cell] = true
	EventBus.highlight_toggled.connect(_on_highlight_toggled)
	_match_owning_building()
	queue_redraw()

func _process(_delta: float) -> void:
	var player: Node = GameManager.player
	if player == null or not is_instance_valid(player):
		return
	var player_cell_v = player.get("grid_cell")
	if player_cell_v == null:
		return
	var pc: Vector2i = player_cell_v
	if pc == _last_player_cell:
		return
	_last_player_cell = pc
	var effective_h: float = maxf(_lintel_h, float(DOOR_H))
	var occluded: bool = Building.cell_occludes_player(grid_cell, pc, effective_h)
	_set_translucent(occluded)

func _set_translucent(v: bool) -> void:
	var target: float = TRANSLUCENT_ALPHA if v else 1.0
	if is_equal_approx(_alpha, target):
		return
	_alpha = target
	queue_redraw()

func _a(c: Color) -> Color:
	return Color(c.r, c.g, c.b, c.a * _alpha)

# Finds the Building (sibling under TileScene) whose door opening sits at
# this door's grid_cell, and copies its wall height/colors so the lintel
# above the door reads as the same wall, not a mismatched patch.
func _match_owning_building() -> void:
	if _tile_scene == null:
		return
	for child in _tile_scene.get_children():
		if not (child is Building):
			continue
		var b := child as Building
		var door_cell := Vector2i(b.DOOR_X, b.DOOR_Y if b.DOOR_Y >= 0 else b.Y2)
		if door_cell == grid_cell:
			_lintel_h = Building.WALL_H * b.wall_height_mult
			_lintel_col_sw = b.col_sw
			_lintel_col_se = b.col_se
			_lintel_col_top = b.col_top
			return

func get_click_polygon() -> PackedVector2Array:
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
		{"label": action_label, "id": "interact", "priority": 100},
		{"label": "Examine",    "id": "examine",  "priority": 50},
	]

func get_description() -> String:
	return "A doorway leading onward."

func get_action_label() -> String:
	return action_label

func interact() -> void:
	if direction == "":
		push_error("ZoneDoor: direction not set")
		return
	if GameManager.tactical_mode:
		CombatManager.end_tactical()
	EventBus.zone_exit_requested.emit(direction)

func _on_highlight_toggled(active: bool) -> void:
	_highlighted = active
	queue_redraw()

func _draw_lintel() -> void:
	if _lintel_h <= float(DOOR_H):
		return
	var rb := Vector2(0, -float(DOOR_H))
	var rt := Vector2(0, -_lintel_h)
	draw_colored_polygon(PackedVector2Array([LEFT+rb, BOTTOM+rb, BOTTOM+rt, LEFT+rt]), _a(_lintel_col_sw))
	draw_colored_polygon(PackedVector2Array([BOTTOM+rb, RIGHT+rb, RIGHT+rt, BOTTOM+rt]), _a(_lintel_col_se))
	draw_colored_polygon(PackedVector2Array([TOP+rt, RIGHT+rt, BOTTOM+rt, LEFT+rt]), _a(_lintel_col_top))

func _draw() -> void:
	var h = float(DOOR_H)
	_draw_lintel()
	draw_colored_polygon(
		PackedVector2Array([LEFT, BOTTOM, BOTTOM + Vector2(0,-h), LEFT + Vector2(0,-h)]),
		_a(Color(0.42, 0.22, 0.06)))
	draw_colored_polygon(
		PackedVector2Array([BOTTOM, RIGHT, RIGHT + Vector2(0,-h), BOTTOM + Vector2(0,-h)]),
		_a(Color(0.35, 0.18, 0.04)))
	var rh := Vector2(0, -h)
	draw_colored_polygon(
		PackedVector2Array([TOP+rh, RIGHT+rh, BOTTOM+rh, LEFT+rh]),
		_a(Color(0.62, 0.36, 0.10)))
	if _lintel_h <= h:
		draw_polyline(PackedVector2Array([TOP+rh, RIGHT+rh, BOTTOM+rh, LEFT+rh, TOP+rh]), _a(Color(0.20, 0.10, 0.02)), 1.0)
	draw_line(LEFT,   LEFT   + rh, _a(Color(0.20, 0.10, 0.02)), 1.0)
	draw_line(BOTTOM, BOTTOM + rh, _a(Color(0.20, 0.10, 0.02)), 1.0)
	draw_line(RIGHT,  RIGHT  + rh, _a(Color(0.20, 0.10, 0.02)), 1.0)

	if _highlighted:
		var rh2 := Vector2(0, -float(DOOR_H))
		draw_colored_polygon(PackedVector2Array([LEFT, BOTTOM, BOTTOM+rh2, LEFT+rh2]),   Color(1.0, 0.85, 0.0, 0.25))
		draw_colored_polygon(PackedVector2Array([BOTTOM, RIGHT, RIGHT+rh2, BOTTOM+rh2]), Color(1.0, 0.85, 0.0, 0.25))
		draw_colored_polygon(PackedVector2Array([TOP+rh2, RIGHT+rh2, BOTTOM+rh2, LEFT+rh2]), Color(1.0, 0.85, 0.0, 0.25))
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
