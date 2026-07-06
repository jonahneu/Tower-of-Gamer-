extends Entity
class_name JammedDoor

const DOOR_H: int = 28

@export var grid_cell: Vector2i = Vector2i(40, 32)
var is_open: bool = false
var _highlighted: bool = false
var _tile_scene: TileScene = null

const TOP    = Vector2(0,                        -TileScene.TILE_H / 2.0)
const RIGHT  = Vector2( TileScene.TILE_W / 2.0,  0)
const BOTTOM = Vector2(0,                         TileScene.TILE_H / 2.0)
const LEFT   = Vector2(-TileScene.TILE_W / 2.0,  0)

func _ready() -> void:
	is_interactable = true
	blocks_movement = true
	entity_name = "Jammed Door"
	_tile_scene = get_parent() as TileScene
	position = TileScene.grid_to_screen(grid_cell)
	_tile_scene.register_entity(grid_cell, self)
	_tile_scene.los_blocked_cells[grid_cell] = true
	EventBus.highlight_toggled.connect(_on_highlight_toggled)
	if _save_key() in GameManager.player_data.get("unlocked_doors", []):
		_open_permanently()
	queue_redraw()

func _save_key() -> String:
	var td: Dictionary = GameManager.get_tile_data(GameManager.world_layer, GameManager.world_pos)
	return td.get("scene", str(GameManager.world_pos)) + "::" + name

func _open_permanently() -> void:
	is_open = true
	blocks_movement = false
	if _tile_scene != null:
		_tile_scene.blocked_cells.erase(grid_cell)
		_tile_scene.los_blocked_cells.erase(grid_cell)

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
	if is_open:
		return [{"label": "Examine", "id": "examine", "priority": 50}]
	return [
		{"label": "Pick Lock",  "id": "pick_lock",  "priority": 100},
		{"label": "Force Open", "id": "force_open", "priority": 90},
		{"label": "Examine",    "id": "examine",     "priority": 50},
	]

func get_description() -> String:
	if is_open:
		return "A heavy iron door, frame bent outward where it was forced."
	return "A heavy iron door, jammed shut in its frame. The lock is old but solid."

func get_action_label() -> String:
	return "Pick Lock" if not is_open else "Examine"

func interact() -> void:
	attempt_pick_lock()

func attempt_pick_lock() -> void:
	var skills: Dictionary = GameManager.player_data.get("skills", {})
	var soh: int = skills.get("sleight_of_hand", 0)
	var stats: Dictionary = GameManager.player_data.get("stats", {})
	var dex_mod: int = stats.get("dexterity", 5) - 5
	var chance: int = clampi(25 + soh * 10 + dex_mod * 3, 5, 90)
	var roll: int = randi_range(1, 100)
	if roll <= chance:
		_succeed("You work the tumblers carefully. The lock gives way with a quiet click.")
	else:
		EventBus.combat_log.emit("Pick Lock: roll %d vs %d%% — the lock holds." % [roll, chance])

const FORCE_OPEN_STRENGTH: int = 8

func attempt_force_open() -> void:
	var stats: Dictionary = GameManager.player_data.get("stats", {})
	var str_val: int = stats.get("strength", 5)
	if str_val >= FORCE_OPEN_STRENGTH:
		_succeed("You throw your shoulder into the door. Metal screeches — the frame gives way.")
	else:
		EventBus.combat_log.emit("Force Open: requires %d Strength (you have %d)." % [FORCE_OPEN_STRENGTH, str_val])

func _succeed(msg: String) -> void:
	EventBus.combat_log.emit(msg)
	var key := _save_key()
	var unlocked: Array = GameManager.player_data.get("unlocked_doors", [])
	if key not in unlocked:
		unlocked.append(key)
	GameManager.player_data["unlocked_doors"] = unlocked
	_open_permanently()
	queue_redraw()
	EventBus.los_blockers_changed.emit()

func _on_highlight_toggled(active: bool) -> void:
	_highlighted = active
	queue_redraw()

func _draw() -> void:
	var h  := float(DOOR_H)
	var rh := Vector2(0, -h)
	if is_open:
		draw_colored_polygon(PackedVector2Array([TOP, RIGHT, BOTTOM, LEFT]), Color(0.22, 0.18, 0.14, 0.18))
		draw_polyline(PackedVector2Array([TOP, RIGHT, BOTTOM, LEFT, TOP]), Color(0.22, 0.18, 0.14, 0.75), 2.0)
	else:
		draw_colored_polygon(PackedVector2Array([LEFT, BOTTOM, BOTTOM+rh, LEFT+rh]),   Color(0.22, 0.20, 0.18))
		draw_colored_polygon(PackedVector2Array([BOTTOM, RIGHT, RIGHT+rh, BOTTOM+rh]), Color(0.18, 0.16, 0.14))
		draw_colored_polygon(PackedVector2Array([TOP+rh, RIGHT+rh, BOTTOM+rh, LEFT+rh]), Color(0.30, 0.27, 0.23))
		# bolt line across top face
		draw_line(LEFT+rh+Vector2(4,-2), RIGHT+rh+Vector2(-4,-2), Color(0.12,0.10,0.08), 1.5)
		draw_polyline(PackedVector2Array([TOP+rh, RIGHT+rh, BOTTOM+rh, LEFT+rh, TOP+rh]), Color(0.08,0.07,0.05), 1.0)
		draw_line(LEFT,   LEFT   + rh, Color(0.08,0.07,0.05), 1.0)
		draw_line(BOTTOM, BOTTOM + rh, Color(0.08,0.07,0.05), 1.0)
		draw_line(RIGHT,  RIGHT  + rh, Color(0.08,0.07,0.05), 1.0)
	if _highlighted:
		draw_colored_polygon(PackedVector2Array([LEFT, BOTTOM, BOTTOM+rh, LEFT+rh]),     Color(1.0,0.85,0.0,0.25))
		draw_colored_polygon(PackedVector2Array([BOTTOM, RIGHT, RIGHT+rh, BOTTOM+rh]),   Color(1.0,0.85,0.0,0.25))
		draw_colored_polygon(PackedVector2Array([TOP+rh, RIGHT+rh, BOTTOM+rh, LEFT+rh]), Color(1.0,0.85,0.0,0.25))
		draw_polyline(PackedVector2Array([LEFT+rh, TOP+rh, RIGHT+rh, RIGHT, BOTTOM, LEFT, LEFT+rh]),
			Color(1.0,0.85,0.0), 2.0)
		_draw_name_label(TOP.y - float(DOOR_H) - 4)

func _draw_name_label(label_y: float) -> void:
	if entity_name == "":
		return
	var font := ThemeDB.fallback_font
	var fs: int = 11
	var tw: float = font.get_string_size(entity_name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var lx := -tw / 2.0
	draw_rect(Rect2(lx - 3, label_y - fs - 1, tw + 6, fs + 4), Color(0,0,0,0.65))
	draw_string(font, Vector2(lx, label_y), entity_name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1.0,0.95,0.7))
