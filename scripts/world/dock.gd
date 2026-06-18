extends Node2D
# Wooden dock/pier planking. Marks a rectangle of cells as walkable and
# colors them like timber, overriding whatever was there before (river,
# road) — used to carry the market-gate road out over the water at the
# riverbank docks. Must sit later in the scene tree than RiverBank so its
# unblocking wins.

const DOCK_COLOR := Color(0.42, 0.32, 0.20, 0.92)

@export var X1: int = 0
@export var X2: int = 14
@export var Y1: int = 36
@export var Y2: int = 43

func _ready() -> void:
	var ts := get_parent() as TileScene
	if ts == null:
		return
	for row in range(Y1, Y2 + 1):
		for col in range(X1, X2 + 1):
			var cell := Vector2i(col, row)
			ts.blocked_cells.erase(cell)
			ts.cell_fill_colors[cell] = DOCK_COLOR
