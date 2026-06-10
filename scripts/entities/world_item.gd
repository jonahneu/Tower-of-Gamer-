extends Entity
class_name WorldItem

# A one-time ground pickup. Placed in a scene with item_id and package_id.
# Tracks pickup state in player_data["picked_up_items"] — never respawns.

@export var grid_cell:  Vector2i = Vector2i(10, 10)
@export var item_id:    String   = ""
@export var package_id: String   = ""   # unique key for this world instance

var _picked_up:  bool     = false
var _highlighted: bool    = false
var _tile_scene: TileScene = null

const SPRITE_W: int = 14
const SPRITE_H: int = 10

func _ready() -> void:
	is_interactable  = true
	blocks_movement  = false
	var item_data: Dictionary = DataManager.get_item(item_id)
	entity_name = item_data.get("name", "Item")
	_tile_scene = get_parent() as TileScene
	if _tile_scene == null:
		return
	position = TileScene.grid_to_screen(get("grid_cell"))
	var picked: Array = GameManager.player_data.get("picked_up_items", [])
	if package_id in picked:
		_picked_up        = true
		is_interactable   = false
	_tile_scene.register_entity(get("grid_cell"), self)
	EventBus.highlight_toggled.connect(_on_highlight_toggled)
	queue_redraw()

func get_interaction_options() -> Array:
	if _picked_up:
		return []
	return [
		{"label": "Pick Up", "id": "interact", "priority": 100},
		{"label": "Examine",  "id": "examine",  "priority": 50},
	]

func get_description() -> String:
	return DataManager.get_item(item_id).get("description", "")

func interact() -> void:
	if _picked_up:
		return
	var item_data: Dictionary = DataManager.get_item(item_id)
	if not item_data.is_empty():
		var inv: Array = GameManager.player_data.get("inventory", [])
		inv.append(item_data)
		GameManager.player_data["inventory"] = inv
	var picked: Array = GameManager.player_data.get("picked_up_items", [])
	if package_id not in picked:
		picked.append(package_id)
	GameManager.player_data["picked_up_items"] = picked
	if item_id == "unnamed_package" and GameManager.has_quest("merchant_lost_cargo"):
		GameManager.update_quest_thread("merchant_lost_cargo", "recover_cargo",
			"You found the merchant's package in a coyote den south of the city wall.")
	_picked_up      = true
	is_interactable = false
	queue_redraw()

func _on_highlight_toggled(active: bool) -> void:
	_highlighted = active
	queue_redraw()

func _exit_tree() -> void:
	if _tile_scene != null:
		_tile_scene.unregister_entity(grid_cell)

func _draw() -> void:
	if _picked_up:
		return
	var col := Color(0.55, 0.38, 0.20)
	draw_rect(Rect2(-SPRITE_W * 0.5, -SPRITE_H, SPRITE_W, SPRITE_H), col)
	draw_line(Vector2(0, -SPRITE_H), Vector2(0, 0), col.darkened(0.45), 1.0)
	draw_line(Vector2(-SPRITE_W * 0.5, -SPRITE_H * 0.5),
			  Vector2( SPRITE_W * 0.5, -SPRITE_H * 0.5), col.darkened(0.45), 1.0)
	if _highlighted:
		draw_rect(Rect2(-SPRITE_W * 0.5, -SPRITE_H, SPRITE_W, SPRITE_H),
				  Color(1.0, 0.85, 0.0, 0.35))
		draw_rect(Rect2(-SPRITE_W * 0.5, -SPRITE_H, SPRITE_W, SPRITE_H),
				  Color(1.0, 0.85, 0.0), false, 1.5)
		_draw_name_label(-SPRITE_H - 4)

func _draw_name_label(label_y: float) -> void:
	if entity_name == "":
		return
	var font := ThemeDB.fallback_font
	var fs: int   = 11
	var tw: float = font.get_string_size(entity_name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var lx := -tw / 2.0
	draw_rect(Rect2(lx - 3, label_y - fs - 1, tw + 6, fs + 4), Color(0, 0, 0, 0.65))
	draw_string(font, Vector2(lx, label_y), entity_name,
				HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1.0, 0.95, 0.7))
