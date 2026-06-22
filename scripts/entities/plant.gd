extends Entity
class_name Plant

# Harvestable plant. Left-click or right-click → Pick Up.
# Tracks harvest state per-plant via player_data["harvested_plants"].
# Respawns after RESPAWN_RESTS rests.

const RESPAWN_RESTS: int = 3

@export var plant_id:   String = ""   # unique key, set per-instance in the scene
@export var plant_type: String = "flower"  # "flower" or "succulent"
@export var item_id:    String = ""   # DataManager item to add on pickup

var _harvested: bool = false
var _highlighted: bool = false
var _tile_scene: TileScene = null

const SPRITE_W: int = 12
const SPRITE_H: int = 12

func _ready() -> void:
	is_interactable = true
	blocks_movement = false
	entity_name = _display_name()
	_tile_scene = get_parent() as TileScene
	if _tile_scene == null:
		return
	position = TileScene.grid_to_screen(get("grid_cell"))
	# Check if this plant was already harvested
	var harvested: Dictionary = GameManager.player_data.get("harvested_plants", {})
	if harvested.has(plant_id) and harvested[plant_id] > 0:
		_harvested = true
		is_interactable = false
	_tile_scene.register_entity(get("grid_cell"), self)
	GameManager.add_encounter(GameManager.world_layer, GameManager.world_pos, entity_name)
	EventBus.highlight_toggled.connect(_on_highlight_toggled)
	queue_redraw()

func _display_name() -> String:
	match plant_type:
		"flower":     return "Dusk Flower"
		"succulent":  return "Desert Succulent"
		"reed":       return "Reed Patch"
		"salt":       return "Salt Deposit"
		"fish":       return "Fishing Spot"
		"wild_onion": return "Wild Onion"
	return "Plant"

@export var grid_cell: Vector2i = Vector2i(10, 10)

func get_interaction_options() -> Array:
	if _harvested:
		return []
	if plant_type == "fish":
		return [
			{"label": "Fish",    "id": "fish",    "priority": 100},
			{"label": "Examine", "id": "examine", "priority": 50},
		]
	var label: String = "Pick Up"
	match plant_type:
		"salt", "reed": label = "Gather"
	return [
		{"label": label, "id": "interact", "priority": 100},
		{"label": "Examine",  "id": "examine",  "priority": 50},
	]

func get_description() -> String:
	match plant_type:
		"flower":     return "A darkly colored flower growing at the river's edge. Its petals are a deep, bruised purple."
		"succulent":  return "A small, waxy succulent with thick leaves. It thrives in the dry desert soil."
		"reed":       return "A dense stand of river reeds. Their roots hide starchy tubers."
		"salt":       return "A crust of white salt left where the river's edge has dried under the sun."
		"fish":       return "A calm eddy where fish gather in the shallows."
		"wild_onion": return "A pungent onion bulb, growing in a small scattered cluster."
	return "A plant."

func interact() -> void:
	if _harvested:
		return
	# Add item to inventory
	var item_data: Dictionary = DataManager.get_item(item_id)
	if not item_data.is_empty():
		var inv: Array = GameManager.player_data.get("inventory", [])
		inv.append(item_data)
		if GameManager.roll_harvest_double():
			inv.append(item_data.duplicate(true))
		GameManager.player_data["inventory"] = inv

	mark_harvested()

# Mark this plant as harvested with a respawn counter, updating its visuals.
func mark_harvested() -> void:
	var harvested: Dictionary = GameManager.player_data.get("harvested_plants", {})
	harvested[plant_id] = RESPAWN_RESTS
	GameManager.player_data["harvested_plants"] = harvested
	_harvested = true
	is_interactable = false
	queue_redraw()

func _on_highlight_toggled(active: bool) -> void:
	_highlighted = active
	queue_redraw()

func _exit_tree() -> void:
	if _tile_scene != null:
		_tile_scene.unregister_entity(grid_cell)

func _draw() -> void:
	if _harvested:
		return
	match plant_type:
		"reed": _draw_reeds()
		"salt": _draw_salt_patch()
		"fish": _draw_ripples()
		_:
			var color: Color
			match plant_type:
				"flower":     color = Color(0.08, 0.05, 0.12)
				"succulent":  color = Color(0.20, 0.55, 0.20)
				"wild_onion": color = Color(0.82, 0.78, 0.82)
				_:            color = Color(0.4, 0.4, 0.4)
			var half := SPRITE_W / 2.0
			draw_rect(Rect2(-half, -SPRITE_H, SPRITE_W, SPRITE_H), color)
	if _highlighted:
		var half := SPRITE_W / 2.0
		draw_rect(Rect2(-half, -SPRITE_H, SPRITE_W, SPRITE_H), Color(1.0, 0.85, 0.0, 0.35))
		draw_rect(Rect2(-half, -SPRITE_H, SPRITE_W, SPRITE_H), Color(1.0, 0.85, 0.0), false, 1.5)
		_draw_name_label(-SPRITE_H - 4)

func _draw_reeds() -> void:
	var stalk := Color(0.45, 0.58, 0.22)
	var tip   := Color(0.65, 0.72, 0.32)
	var mud   := Color(0.30, 0.22, 0.14)
	var tuber := Color(0.78, 0.70, 0.52)
	draw_rect(Rect2(-6, -2, 12, 3), mud)
	draw_circle(Vector2(2, 0), 2.5, tuber)
	for i in range(3):
		var x: float = -5.0 + i * 5.0
		var h: float = SPRITE_H + (3.0 if i == 1 else 0.0)
		draw_line(Vector2(x, 0), Vector2(x, -h), stalk, 2.0)
		draw_line(Vector2(x, -h), Vector2(x + 1.5, -h - 3.0), tip, 2.0)

func _draw_salt_patch() -> void:
	var bright := Color(0.92, 0.92, 0.90)
	var shadow := Color(0.82, 0.82, 0.78)
	draw_rect(Rect2(-7, -3, 14, 4), shadow)
	draw_rect(Rect2(-5, -6, 10, 4), bright)

func _draw_ripples() -> void:
	var col := Color(0.55, 0.78, 0.92, 0.85)
	draw_arc(Vector2(0, -3), 6.0, 0.0, TAU, 16, col, 1.5)
	draw_arc(Vector2(0, -3), 3.0, 0.0, TAU, 12, col, 1.5)

func _draw_name_label(label_y: float) -> void:
	if entity_name == "":
		return
	var font := ThemeDB.fallback_font
	var fs: int = 11
	var tw: float = font.get_string_size(entity_name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var lx := -tw / 2.0
	draw_rect(Rect2(lx - 3, label_y - fs - 1, tw + 6, fs + 4), Color(0, 0, 0, 0.65))
	draw_string(font, Vector2(lx, label_y), entity_name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1.0, 0.95, 0.7))
