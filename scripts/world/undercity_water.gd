extends Node2D
# Paints a shallow water channel through undercity zones.
# draw_ns: N-S strip centred on col 40. draw_ew: E-W strip centred on row 40.
# Both active in the crossroads; only draw_ns in corridor/pit zones.

const HALF: int = 1   # half-width: 1 → 3 tiles wide (39-41)
const COL_WATER: Color = Color(0.16, 0.20, 0.28)

@export var draw_ns: bool = true
@export var draw_ew: bool = true

var _tile_scene: TileScene = null

func _ready() -> void:
	_tile_scene = get_parent() as TileScene
	if _tile_scene == null:
		push_error("UndercityWater: parent must be TileScene")
		return
	call_deferred("_paint")

func _paint() -> void:
	for col in range(TileScene.GRID_COLS):
		for row in range(TileScene.GRID_ROWS):
			var cell := Vector2i(col, row)
			if _tile_scene.blocked_cells.has(cell):
				continue
			var in_ns: bool = draw_ns and abs(col - 40) <= HALF
			var in_ew: bool = draw_ew and abs(row - 40) <= HALF
			if in_ns or in_ew:
				_tile_scene.cell_fill_colors[cell] = COL_WATER
				_tile_scene.channel_tiles[cell] = true
	_tile_scene.queue_redraw()
