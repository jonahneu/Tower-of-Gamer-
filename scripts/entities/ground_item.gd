extends Node2D
class_name GroundItem

const SPRITE_W: float = 14.0
const SPRITE_H: float = 10.0

var entity_name: String = "Item"
var is_interactable: bool = true
var blocks_movement: bool = false
var item_data: Dictionary = {}
var grid_cell: Vector2i = Vector2i(0, 0)
var _tile_scene: TileScene = null
var _draw_offset: Vector2 = Vector2.ZERO
var _highlighted: bool = false

func _ready() -> void:
	_tile_scene = get_parent() as TileScene
	position = TileScene.grid_to_screen(grid_cell)
	entity_name = item_data.get("name", "Item")
	if _tile_scene != null:
		_tile_scene.register_ground_item(self)
		# Offset based on how many items are already at this cell
		var idx: int = _tile_scene.get_ground_items_at(grid_cell).size() - 1
		_draw_offset = Vector2(idx * 5, idx * -4)
	EventBus.highlight_toggled.connect(_on_highlight_toggled)
	queue_redraw()

func get_interaction_options() -> Array:
	var opts: Array = [
		{"label": "Pick Up", "id": "pick_up",    "priority": 100},
		{"label": "Examine",  "id": "examine",    "priority": 50},
	]
	if _tile_scene != null and _tile_scene.get_ground_items_at(grid_cell).size() > 1:
		opts.append({"label": "View Pile", "id": "view_pile", "priority": 150})
	return opts

func get_description() -> String:
	var desc: String = item_data.get("description", "")
	return desc if desc != "" else item_data.get("name", "An item.")

func get_click_polygon() -> PackedVector2Array:
	var x := -SPRITE_W / 2.0 + _draw_offset.x
	var y := -SPRITE_H / 2.0 + TileScene.TILE_H / 4.0 + _draw_offset.y
	return PackedVector2Array([
		position + Vector2(x,            y),
		position + Vector2(x + SPRITE_W, y),
		position + Vector2(x + SPRITE_W, y + SPRITE_H),
		position + Vector2(x,            y + SPRITE_H),
	])

func pick_up() -> void:
	var inv: Array = GameManager.player_data.get("inventory", [])
	inv.append(item_data.duplicate())
	GameManager.player_data["inventory"] = inv
	_remove_from_persistence()
	if _tile_scene != null:
		_tile_scene.unregister_ground_item(self)
	queue_free()

func _remove_from_persistence() -> void:
	var tile_data: Dictionary = GameManager.get_tile_data(GameManager.world_layer, GameManager.world_pos)
	var scene_path: String = tile_data.get("scene", str(GameManager.world_pos))
	var ground_items: Dictionary = GameManager.player_data.get("ground_items", {})
	if not ground_items.has(scene_path):
		return
	var arr: Array = ground_items[scene_path]
	var item_id: String = item_data.get("id", "")
	for i in range(arr.size()):
		var e: Dictionary = arr[i]
		if e.get("cell") == [grid_cell.x, grid_cell.y] and e.get("item", {}).get("id", "") == item_id:
			arr.remove_at(i)
			break
	ground_items[scene_path] = arr
	GameManager.player_data["ground_items"] = ground_items

func _exit_tree() -> void:
	if _tile_scene != null:
		_tile_scene.unregister_ground_item(self)

func _on_highlight_toggled(active: bool) -> void:
	_highlighted = active
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(
		-SPRITE_W / 2.0 + _draw_offset.x,
		-SPRITE_H / 2.0 + TileScene.TILE_H / 4.0 + _draw_offset.y,
		SPRITE_W, SPRITE_H
	)
	draw_rect(rect, Color(0.72, 0.58, 0.18))
	if _highlighted:
		draw_rect(rect, Color(1.0, 0.85, 0.0, 0.35))
		draw_rect(rect, Color(1.0, 0.85, 0.0), false, 1.5)
		_draw_name_label(rect.position.y - 4)
	else:
		draw_rect(rect, Color(0.95, 0.82, 0.40), false, 1.5)

func _draw_name_label(label_y: float) -> void:
	if entity_name == "":
		return
	var font := ThemeDB.fallback_font
	var fs: int = 11
	var tw: float = font.get_string_size(entity_name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var lx := -tw / 2.0
	draw_rect(Rect2(lx - 3, label_y - fs - 1, tw + 6, fs + 4), Color(0, 0, 0, 0.65))
	draw_string(font, Vector2(lx, label_y), entity_name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1.0, 0.95, 0.7))
