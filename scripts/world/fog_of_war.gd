extends Node2D
class_name FogOfWar

const RADIUS: int = 40
const CHUNK_SIZE: int = 10  # tiles per chunk side; 80/10 = 8×8 = 64 chunks total

const COLOR_UNEXPLORED: Color = Color(0.0, 0.0, 0.0, 1.0)
const COLOR_REMEMBERED: Color = Color(0.0, 0.0, 0.0, 0.65)

var visible_cells: Dictionary = {}   # Vector2i → true  (current frame)
var revealed_cells: Dictionary = {}  # Vector2i → true  (ever seen)

var _tile_scene: TileScene = null
var _origin: Vector2i = Vector2i(-1, -1)
var _fov_offsets: Array[Vector2i] = []
var _chunks: Array = []   # flat array of _FogChunk nodes

# ── Inner chunk class ──────────────────────────────────────────────────────────
# Each chunk owns a 10×10 tile region and only redraws when its cells change.
class _FogChunk extends Node2D:
	const _COL_UNEXPLORED: Color = Color(0.0, 0.0, 0.0, 1.0)
	const _COL_REMEMBERED: Color = Color(0.0, 0.0, 0.0, 0.65)
	const _COL_LIGHT_DIM: Color  = Color(0.05, 0.05, 0.15, 0.30)
	const _COL_LIGHT_DARK: Color = Color(0.02, 0.02, 0.08, 0.55)

	var col_start: int = 0
	var row_start: int = 0
	var col_end: int = 0
	var row_end: int = 0
	var fow = null   # FogOfWar reference (untyped to avoid inner-class forward-ref issues)

	func _draw() -> void:
		if fow == null:
			return
		var hw: float = TileScene.TILE_W / 2.0
		var hh: float = TileScene.TILE_H / 2.0
		for col in range(col_start, col_end):
			for row in range(row_start, row_end):
				var cell := Vector2i(col, row)
				if fow.visible_cells.has(cell):
					if fow._tile_scene == null:
						continue
					var tier: int = fow._tile_scene.get_light_level(cell)
					if tier == LightLevels.DIM or tier == LightLevels.DARK:
						var center: Vector2 = TileScene.grid_to_screen(cell)
						var pts := PackedVector2Array([
							center + Vector2(0.0,  -hh),
							center + Vector2(hw,   0.0),
							center + Vector2(0.0,   hh),
							center + Vector2(-hw,  0.0),
						])
						draw_colored_polygon(pts, _COL_LIGHT_DIM if tier == LightLevels.DIM else _COL_LIGHT_DARK)
					continue
				var center: Vector2 = TileScene.grid_to_screen(cell)
				var pts := PackedVector2Array([
					center + Vector2(0.0,  -hh),
					center + Vector2(hw,   0.0),
					center + Vector2(0.0,   hh),
					center + Vector2(-hw,  0.0),
				])
				if fow.revealed_cells.has(cell):
					draw_colored_polygon(pts, _COL_REMEMBERED)
				else:
					draw_colored_polygon(pts, _COL_UNEXPLORED)

# ── Lifecycle ──────────────────────────────────────────────────────────────────
func _ready() -> void:
	z_index = 100
	z_as_relative = false
	_tile_scene = get_parent() as TileScene
	EventBus.player_moved.connect(_on_player_moved)
	EventBus.los_blockers_changed.connect(_on_los_blockers_changed)
	EventBus.light_levels_changed.connect(_on_light_levels_changed)
	EventBus.turn_ended.connect(func(_entity: Node):
		if _origin != Vector2i(-1, -1) and GameManager.combat_mode:
			update_entity_visibility())
	_precompute_fov_offsets()
	_create_chunks()

func _create_chunks() -> void:
	var chunk_cols: int = int(ceil(float(TileScene.GRID_COLS) / CHUNK_SIZE))
	var chunk_rows: int = int(ceil(float(TileScene.GRID_ROWS) / CHUNK_SIZE))
	for cy in range(chunk_rows):
		for cx in range(chunk_cols):
			var chunk := _FogChunk.new()
			chunk.col_start = cx * CHUNK_SIZE
			chunk.row_start = cy * CHUNK_SIZE
			chunk.col_end   = mini(chunk.col_start + CHUNK_SIZE, TileScene.GRID_COLS)
			chunk.row_end   = mini(chunk.row_start + CHUNK_SIZE, TileScene.GRID_ROWS)
			chunk.fow = self
			add_child(chunk)
			_chunks.append(chunk)

func _precompute_fov_offsets() -> void:
	var r2: int = RADIUS * RADIUS
	for dx in range(-RADIUS, RADIUS + 1):
		for dy in range(-RADIUS, RADIUS + 1):
			if dx * dx + dy * dy <= r2:
				_fov_offsets.append(Vector2i(dx, dy))

# ── Signal handlers ────────────────────────────────────────────────────────────
func _on_player_moved(cell: Vector2i) -> void:
	var old_visible := visible_cells.duplicate()
	compute_fov(cell)
	update_entity_visibility()
	_redraw_dirty_chunks(old_visible)

func _on_los_blockers_changed() -> void:
	if _origin == Vector2i(-1, -1):
		return
	var old_visible := visible_cells.duplicate()
	compute_fov(_origin)
	update_entity_visibility()
	_redraw_dirty_chunks(old_visible)

# Light changes can alter a cell's tint while it stays in visible_cells the
# whole time (no enter/exit transition for _redraw_dirty_chunks to catch), so
# this does a full redraw rather than relying on the visible-set diff.
func _on_light_levels_changed() -> void:
	if _origin == Vector2i(-1, -1):
		return
	compute_fov(_origin)
	update_entity_visibility()
	redraw_all()

# ── FOV computation ────────────────────────────────────────────────────────────
func compute_fov(origin: Vector2i) -> void:
	_origin = origin
	visible_cells.clear()
	if _tile_scene == null:
		return
	var observer_level: int = _tile_scene.get_light_level(origin)
	for offset in _fov_offsets:
		var cell := Vector2i(origin.x + offset.x, origin.y + offset.y)
		if not _tile_scene.is_in_bounds(cell):
			continue
		var target_level: int = _tile_scene.get_light_level(cell)
		var cap: int = LightLevels.vision_cap(observer_level, target_level, RADIUS)
		if offset.x * offset.x + offset.y * offset.y > cap * cap:
			continue
		if _tile_scene.has_line_of_sight(origin, cell):
			visible_cells[cell] = true
			revealed_cells[cell] = true

	# If a wall face is visible the wall top should be visible too.
	# The three cells that appear "above" a wall tile in isometric screen space
	# are (x-1, y), (x, y-1), and (x-1, y-1); reveal them so their fog polygons
	# don't cover sign text or wall tops.
	var to_add: Array[Vector2i] = []
	for cell in visible_cells.keys():
		if not _tile_scene.los_blocked_cells.has(cell):
			continue
		for off in [Vector2i(-1, 0), Vector2i(0, -1), Vector2i(-1, -1)]:
			var nb := Vector2i(cell.x + off.x, cell.y + off.y)
			if _tile_scene.is_in_bounds(nb) and not visible_cells.has(nb):
				to_add.append(nb)
	for nb in to_add:
		visible_cells[nb] = true
		revealed_cells[nb] = true

func update_entity_visibility() -> void:
	if _tile_scene == null:
		return
	for entity in _tile_scene.get_all_entities():
		if not is_instance_valid(entity):
			continue
		if not entity.get("fow_hide_when_unseen"):
			continue
		var cell = entity.get("grid_cell")
		if cell == null:
			continue
		if visible_cells.has(cell):
			entity.visible = entity.get("fow_can_show") != false
		else:
			entity.visible = false

# ── Chunk redraw ───────────────────────────────────────────────────────────────
# Only the chunks whose cells changed state get redrawn each step.
func _redraw_dirty_chunks(old_visible: Dictionary) -> void:
	var dirty: Dictionary = {}
	for cell in visible_cells:
		if not old_visible.has(cell):
			dirty[Vector2i(cell.x / CHUNK_SIZE, cell.y / CHUNK_SIZE)] = true
	for cell in old_visible:
		if not visible_cells.has(cell):
			dirty[Vector2i(cell.x / CHUNK_SIZE, cell.y / CHUNK_SIZE)] = true
	if dirty.is_empty():
		return
	for chunk in _chunks:
		if dirty.has(Vector2i(chunk.col_start / CHUNK_SIZE, chunk.row_start / CHUNK_SIZE)):
			chunk.queue_redraw()

# Called from TileScene after initial compute_fov or zone restore — redraws all chunks.
func redraw_all() -> void:
	for chunk in _chunks:
		chunk.queue_redraw()

# ── Serialization ──────────────────────────────────────────────────────────────
func get_revealed_data() -> Array:
	var result: Array = []
	for cell in revealed_cells:
		result.append([cell.x, cell.y])
	return result

func load_revealed_data(data: Array) -> void:
	for pair in data:
		revealed_cells[Vector2i(int(pair[0]), int(pair[1]))] = true
