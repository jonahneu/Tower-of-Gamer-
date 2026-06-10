extends Node2D
# Marks the western river tiles as blue and unwalkable.
# The eastern edge of the river follows a gentle irregular line so it looks
# like a real bank rather than a straight wall.

const RIVER_COLOR := Color(0.12, 0.28, 0.62, 0.90)

# Eastern edge X for each band of rows (6 bands × ~13 rows = 80 rows).
# River covers X = 0 … edge_x-1 inclusive.
const BAND_EDGES: Array = [6, 8, 5, 9, 7, 6]
const BAND_SIZE:  int   = 13

func _ready() -> void:
	var ts := get_parent() as TileScene
	if ts == null:
		return
	for row in range(TileScene.GRID_ROWS):
		var band: int  = mini(row / BAND_SIZE, BAND_EDGES.size() - 1)
		var edge_x: int = BAND_EDGES[band]
		for col in range(edge_x):
			var cell := Vector2i(col, row)
			ts.blocked_cells[cell]    = true
			ts.cell_fill_colors[cell] = RIVER_COLOR
