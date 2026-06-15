extends Node2D
class_name Corpse

const SPRITE_W: float = 44.0
const SPRITE_H: float = 18.0

var entity_name: String = "Corpse"
var is_interactable: bool = true
var blocks_movement: bool = false
var grid_cell: Vector2i = Vector2i(0, 0)
var beast_type: String = ""
var beast_quality_mod: int = 0
var is_human: bool = false
var _carved: bool = false
var _tile_scene: TileScene = null

func _ready() -> void:
	_tile_scene = get_parent() as TileScene
	if _tile_scene == null:
		return
	position = TileScene.grid_to_screen(grid_cell)
	_tile_scene.register_entity(grid_cell, self)
	queue_redraw()

func mark_carved() -> void:
	_carved = true
	queue_redraw()

func get_interaction_options() -> Array:
	if _carved:
		return [{"label": "Inspect", "id": "examine", "priority": 50}]
	if is_human:
		return [
			{"label": "Search",  "id": "search",  "priority": 100},
			{"label": "Inspect", "id": "examine", "priority": 50},
		]
	return [
		{"label": "Carve",   "id": "carve",   "priority": 100},
		{"label": "Inspect", "id": "examine", "priority": 50},
	]

func get_description() -> String:
	if is_human:
		if _carved:
			return "The body has been searched and stripped of anything useful."
		return "The body lies still, already growing cold."
	var name_cap: String = beast_type.capitalize()
	if _carved:
		return "The %s carcass has been picked clean." % name_cap
	return "The body of a %s, still warm. The fur is intact." % name_cap

func get_click_polygon() -> PackedVector2Array:
	var x := -SPRITE_W / 2.0
	var y := -SPRITE_H / 2.0 + TileScene.TILE_H / 4.0
	return PackedVector2Array([
		position + Vector2(x,           y),
		position + Vector2(x + SPRITE_W, y),
		position + Vector2(x + SPRITE_W, y + SPRITE_H),
		position + Vector2(x,            y + SPRITE_H),
	])

func _draw() -> void:
	var alpha: float = 0.45 if _carved else 1.0
	var col: Color
	match beast_type:
		"lizard": col = Color(0.25, 0.52, 0.28, alpha)
		_:        col = Color(0.55, 0.44, 0.32, alpha)
	draw_rect(
		Rect2(-SPRITE_W / 2.0, -SPRITE_H / 2.0 + TileScene.TILE_H / 4.0, SPRITE_W, SPRITE_H),
		col
	)
