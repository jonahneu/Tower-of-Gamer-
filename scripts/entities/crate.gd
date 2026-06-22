extends LootContainer
class_name Crate
# A small lootable wooden crate with a persistent internal inventory.

const SPRITE_W: float = 20.0
const SPRITE_H: float = 16.0

func _ready() -> void:
	entity_name = "Crate"
	super._ready()

func get_description() -> String:
	if get_inventory().is_empty():
		return "A small wooden crate. It's empty."
	return "A small wooden crate, lid cracked open."

func get_click_polygon() -> PackedVector2Array:
	var x := -SPRITE_W / 2.0
	var y := -SPRITE_H + TileScene.TILE_H / 4.0
	return PackedVector2Array([
		position + Vector2(x,            y),
		position + Vector2(x + SPRITE_W, y),
		position + Vector2(x + SPRITE_W, y + SPRITE_H),
		position + Vector2(x,            y + SPRITE_H),
	])

func _draw() -> void:
	var base_y: float = TileScene.TILE_H / 4.0
	var wood: Color      = Color(0.55, 0.40, 0.24, 1.0)
	var wood_dark: Color = Color(0.40, 0.28, 0.16, 1.0)
	var shadow_col: Color = Color(0.15, 0.12, 0.10, 0.35)

	# Ground shadow
	draw_colored_polygon(PackedVector2Array([
		Vector2(-11.0, base_y + 1.0),
		Vector2( 11.0, base_y + 1.0),
		Vector2( 9.0,  base_y - 2.0),
		Vector2(-9.0,  base_y - 2.0),
	]), shadow_col)

	# Crate body
	var x := -SPRITE_W / 2.0
	var y := base_y - SPRITE_H
	draw_rect(Rect2(x, y, SPRITE_W, SPRITE_H), wood)

	# Slat lines
	draw_line(Vector2(x, y + SPRITE_H * 0.33), Vector2(x + SPRITE_W, y + SPRITE_H * 0.33), wood_dark, 1.0)
	draw_line(Vector2(x, y + SPRITE_H * 0.66), Vector2(x + SPRITE_W, y + SPRITE_H * 0.66), wood_dark, 1.0)
	draw_line(Vector2(x + SPRITE_W * 0.5, y), Vector2(x + SPRITE_W * 0.5, y + SPRITE_H), wood_dark, 1.0)

	# Outline
	draw_rect(Rect2(x, y, SPRITE_W, SPRITE_H), Color(0.30, 0.20, 0.10, 1.0), false, 1.0)

	if _highlighted:
		draw_rect(Rect2(x, y, SPRITE_W, SPRITE_H), Color(1.0, 0.85, 0.0, 0.25))
		draw_rect(Rect2(x, y, SPRITE_W, SPRITE_H), Color(1.0, 0.85, 0.0, 1.0), false, 2.0)
		_draw_name_label(y - 4.0)
