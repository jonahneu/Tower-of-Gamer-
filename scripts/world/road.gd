extends Node2D
# Marks a horizontal dirt-road band running east-west across the tile so
# players can follow it between zones.

const ROAD_COLOR := Color(0.55, 0.46, 0.32, 0.85)
const ROAD_Y1: int = 36
const ROAD_Y2: int = 43

func _ready() -> void:
	var ts := get_parent() as TileScene
	if ts == null:
		return
	for row in range(ROAD_Y1, ROAD_Y2 + 1):
		for col in range(TileScene.GRID_COLS):
			var cell := Vector2i(col, row)
			# Don't paint road over cells already blocked by other terrain (e.g.
			# river water in zone_docks) — a plain dirt road can't run through
			# water. A dock/pier node placed later in the scene tree still
			# paints its own walkway on top of this, same as before.
			if ts.blocked_cells.has(cell):
				continue
			ts.cell_fill_colors[cell] = ROAD_COLOR
