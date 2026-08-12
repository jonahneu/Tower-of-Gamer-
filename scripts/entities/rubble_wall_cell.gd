extends WallCell
class_name RubbleWallCell

# A broken, jagged variant of WallCell — collapsed masonry/rubble instead of a
# smooth built wall. Per-cell shape is derived from grid_cell so it's stable
# across redraws/reloads rather than re-rolling randomly. Most cells render as
# an irregular rubble mound; a minority render as a flat remnant of standing
# wall (reusing WallCell's own flat box), so a rubble line reads as "mostly
# broken, with the occasional surviving wall section" rather than uniformly
# jagged or uniformly smooth.

func _seed() -> int:
	return absi((grid_cell.x * 92821 + grid_cell.y * 68917) % 1000)

func _is_flat_remnant() -> bool:
	return _seed() % 100 < 22  # ~22% of cells keep a flat standing-wall look

func _draw() -> void:
	if _is_flat_remnant():
		super._draw()
		return
	var s: int = _seed()
	# Jagged top edge: 4 irregular peaks/valleys instead of one flat line,
	# height varies per-cell so neighboring rubble reads as uneven debris.
	var h1: float = wall_h * (0.55 + float(s % 7) / 10.0)
	var h2: float = wall_h * (0.70 + float((s / 7) % 6) / 10.0)
	var h3: float = wall_h * (0.45 + float((s / 13) % 8) / 10.0)
	var h4: float = wall_h * (0.60 + float((s / 29) % 5) / 10.0)
	var p_l  := L
	var p_ll := L.lerp(B, 0.25) + Vector2(0, -h1)
	var p_c1 := L.lerp(B, 0.5)  + Vector2(0, -h2)
	var p_c2 := B.lerp(R, 0.5)  + Vector2(0, -h3)
	var p_rr := B.lerp(R, 0.75) + Vector2(0, -h4)
	var p_r  := R
	var p_b  := B
	# SW rubble face (left -> bottom-mid), broken/uneven top instead of flat
	draw_colored_polygon(PackedVector2Array([p_l, p_ll, p_c1, p_b, L]), _a(col_sw))
	# SE rubble face (bottom-mid -> right), matching uneven top
	draw_colored_polygon(PackedVector2Array([p_b, p_c2, p_rr, p_r, B]), _a(col_se))
	# Top scree — thin cap along the jagged ridge line so it doesn't read as
	# a flat roof, just loose rubble catching light along the high points
	draw_colored_polygon(PackedVector2Array([p_ll, p_c1, p_c2, p_rr]), _a(col_top))
	# A couple of loose debris chunks scattered at the base, breaking up the
	# silhouette further so adjacent cells don't read as one smooth mound
	var chunk_a := L.lerp(B, 0.35) + Vector2(0, -h1 * 0.3)
	var chunk_b := B.lerp(R, 0.65) + Vector2(0, -h4 * 0.25)
	draw_circle(chunk_a, 3.0 + float(s % 3), _a(col_sw.darkened(0.15)))
	draw_circle(chunk_b, 2.5 + float((s / 3) % 3), _a(col_se.darkened(0.1)))
