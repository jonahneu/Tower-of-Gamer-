extends Node2D
class_name LootContainer
# Base class for lootable containers (urns, chests, etc.) with a persistent
# inventory the player can take items from and store items into. Contents
# survive zone transitions via GameManager.player_data["container_inventories"].

@export var grid_cell: Vector2i = Vector2i(0, 0)
@export var container_id: String = ""                               # must be unique across the save
@export var loot_item_ids: PackedStringArray = PackedStringArray()  # starting contents (item ids)

var entity_name: String = "Container"
var is_interactable: bool = true
var blocks_movement: bool = false
var _highlighted: bool = false
var _tile_scene: TileScene = null

func _ready() -> void:
	_tile_scene = get_parent() as TileScene
	position = TileScene.grid_to_screen(grid_cell)
	if _tile_scene != null:
		_tile_scene.register_ground_item(self)
	EventBus.highlight_toggled.connect(_on_highlight_toggled)
	queue_redraw()

# Returns this container's persistent contents, seeding them from loot_item_ids
# the first time the container is opened.
func get_inventory() -> Array:
	var stores: Dictionary = GameManager.player_data.get("container_inventories", {})
	if not stores.has(container_id):
		var initial: Array = []
		for item_id in loot_item_ids:
			initial.append(DataManager.get_item(item_id))
		stores[container_id] = initial
		GameManager.player_data["container_inventories"] = stores
	return stores[container_id]

func set_inventory(items: Array) -> void:
	var stores: Dictionary = GameManager.player_data.get("container_inventories", {})
	stores[container_id] = items
	GameManager.player_data["container_inventories"] = stores

func get_interaction_options() -> Array:
	return [
		{"label": "Open",    "id": "open_container", "priority": 100},
		{"label": "Examine", "id": "examine",         "priority": 50},
	]

func get_description() -> String:
	return "There's nothing remarkable about it."

func get_click_polygon() -> PackedVector2Array:
	var x := -8.0
	var y := -16.0 + TileScene.TILE_H / 4.0
	return PackedVector2Array([
		position + Vector2(x,        y),
		position + Vector2(x + 16.0, y),
		position + Vector2(x + 16.0, y + 16.0),
		position + Vector2(x,        y + 16.0),
	])

func _exit_tree() -> void:
	if _tile_scene != null:
		_tile_scene.unregister_ground_item(self)

func _on_highlight_toggled(active: bool) -> void:
	_highlighted = active
	queue_redraw()

func _draw_name_label(label_y: float) -> void:
	if entity_name == "":
		return
	var font := ThemeDB.fallback_font
	var fs: int = 11
	var tw: float = font.get_string_size(entity_name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var lx := -tw / 2.0
	draw_rect(Rect2(lx - 3, label_y - fs - 1, tw + 6, fs + 4), Color(0, 0, 0, 0.65))
	draw_string(font, Vector2(lx, label_y), entity_name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1.0, 0.95, 0.7))
