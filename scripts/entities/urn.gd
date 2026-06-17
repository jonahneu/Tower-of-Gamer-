extends LootContainer
class_name Urn
# A small lootable clay urn with a persistent internal inventory.

const SPRITE_W: float = 14.0
const SPRITE_H: float = 22.0

func _ready() -> void:
	entity_name = "Urn"
	super._ready()

func get_description() -> String:
	if get_inventory().is_empty():
		return "A small clay urn. It's empty."
	return "A small clay urn, its lid sitting ajar."

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
	var clay: Color       = Color(0.72, 0.42, 0.26, 1.0)
	var clay_dark: Color  = Color(0.55, 0.30, 0.18, 1.0)
	var shadow_col: Color = Color(0.15, 0.12, 0.10, 0.35)

	# Ground shadow
	draw_colored_polygon(PackedVector2Array([
		Vector2(-9.0, base_y + 1.0),
		Vector2( 9.0, base_y + 1.0),
		Vector2( 7.0, base_y - 2.0),
		Vector2(-7.0, base_y - 2.0),
	]), shadow_col)

	# Urn body
	var body := PackedVector2Array([
		Vector2(-3.0, base_y - 20.0),
		Vector2( 3.0, base_y - 20.0),
		Vector2( 7.0, base_y - 10.0),
		Vector2( 5.0, base_y -  2.0),
		Vector2(-5.0, base_y -  2.0),
		Vector2(-7.0, base_y - 10.0),
	])
	draw_colored_polygon(body, clay)

	# Rim
	draw_colored_polygon(PackedVector2Array([
		Vector2(-4.0, base_y - 21.0),
		Vector2( 4.0, base_y - 21.0),
		Vector2( 4.0, base_y - 19.0),
		Vector2(-4.0, base_y - 19.0),
	]), clay_dark)

	# Outline
	var outline := PackedVector2Array(body)
	outline.append(body[0])
	draw_polyline(outline, Color(0.35, 0.18, 0.10, 1.0), 1.0)

	if _highlighted:
		draw_colored_polygon(body, Color(1.0, 0.85, 0.0, 0.25))
		draw_polyline(outline, Color(1.0, 0.85, 0.0), 2.0)
		_draw_name_label(base_y - 24.0)
