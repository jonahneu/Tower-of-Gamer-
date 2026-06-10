extends Node2D
# Renders a circular pit (the pipe shaft) and the surrounding wall ring.
# full_circle = false (default): south-half dome only — horizontal pipe curving down.
# full_circle = true:            360° ring — vertical pipe cross-section.
# Place as a child of TileScene in undercity zones.

# ── Geometry constants (grid tiles) ──────────────────────────────────────────
const PIT_CENTER_X: int = 40
const PIT_CENTER_Y: int = 40
const PIT_RADIUS:   int = 22   # inner hole radius (floor opens here)
const WALL_R_INNER: int = 30   # inner edge of the dome wall ring
const WALL_R_OUTER: int = 35   # outer edge; meets east/west straight walls at y=40

# ── Visual constants ──────────────────────────────────────────────────────────
const COL_PIT_CENTER: Color = Color(0.02, 0.02, 0.04)   # deepest dark
const COL_PIT_EDGE:   Color = Color(0.07, 0.06, 0.09)   # slightly lighter at rim

const COL_VOID:  Color = Color(0.02, 0.02, 0.04)   # outside dome (full circle)

# Dome wall cell colors — match straight outer walls (building.gd defaults)
const COL_SW:  Color = Color(0.50, 0.45, 0.38)
const COL_SE:  Color = Color(0.38, 0.33, 0.26)
const COL_TOP: Color = Color(0.62, 0.57, 0.50)
const COL_OUT: Color = Color(0.18, 0.12, 0.08)

@export var full_circle: bool = false   # true on the lower (cross-section) level

func _in_north_gap(x: int, y: int) -> bool:
	return full_circle and y < PIT_CENTER_Y and abs(x - PIT_CENTER_X) <= 2

var _wall_nodes: Array = []
var _tile_scene: TileScene = null

func _ready() -> void:
	_tile_scene = get_parent() as TileScene
	if _tile_scene == null:
		push_error("TunnelEntrance: parent must be TileScene")
		return
	_register_blocked_cells()
	call_deferred("_spawn_visuals")


func _register_blocked_cells() -> void:
	var cx  := PIT_CENTER_X
	var cy  := PIT_CENTER_Y
	var pr2 := PIT_RADIUS * PIT_RADIUS
	var wi2 := WALL_R_INNER * WALL_R_INNER

	for x in range(0, TileScene.GRID_COLS):
		for y in range(0, TileScene.GRID_ROWS):
			var dx := x - cx
			var dy := y - cy
			var d2  := dx * dx + dy * dy
			var in_north := y < cy
			if d2 <= pr2:
				var cell := Vector2i(x, y)
				_tile_scene.blocked_cells[cell] = true
				_tile_scene.pit_tiles[cell]     = true
			elif d2 >= wi2:
				# South half always blocked; north half only on full_circle
				if (not in_north or full_circle) and not _in_north_gap(x, y):
					var wall_cell := Vector2i(x, y)
					_tile_scene.blocked_cells[wall_cell] = true
					_tile_scene.los_blocked_cells[wall_cell] = true


func _spawn_visuals() -> void:
	if _tile_scene == null:
		return
	var cx  := PIT_CENTER_X
	var cy  := PIT_CENTER_Y
	var pr  := float(PIT_RADIUS)
	var wri := float(WALL_R_INNER)
	var wro := float(WALL_R_OUTER)

	for x in range(0, TileScene.GRID_COLS):
		for y in range(0, TileScene.GRID_ROWS):
			var cell := Vector2i(x, y)
			var dx   := float(x - cx)
			var dy   := float(y - cy)
			var dist := sqrt(dx * dx + dy * dy)

			if dist <= pr:
				# Pit: dark gradient — darkest at center, slightly lighter at rim
				var t := dist / pr
				_tile_scene.cell_fill_colors[cell] = COL_PIT_CENTER.lerp(COL_PIT_EDGE, t)

			elif dist >= wri and dist <= wro:
				# Wall ring: south half always; north half only on full_circle
				if (y >= cy or full_circle) and not _in_north_gap(x, y):
					var wc := WallCell.new()
					wc.col_sw  = COL_SW
					wc.col_se  = COL_SE
					wc.col_top = COL_TOP
					wc.col_out = COL_OUT
					wc.position = TileScene.grid_to_screen(cell)
					_tile_scene.add_child(wc)
					_wall_nodes.append(wc)

			elif dist > wro:
				# Void: south half always; north half only on full_circle
				if (y >= cy or full_circle) and not _in_north_gap(x, y):
					_tile_scene.cell_fill_colors[cell] = COL_VOID


func _exit_tree() -> void:
	for wc in _wall_nodes:
		if is_instance_valid(wc):
			wc.queue_free()
	_wall_nodes.clear()
