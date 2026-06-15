extends Node2D
class_name TileScene

# ── Grid configuration ────────────────────────────────────────────────────────
const GRID_COLS: int = 80
const GRID_ROWS: int = 80
const TILE_W: int = 64
const TILE_H: int = 32

var _range_ring_r: int = 0
var _move_grey: Array = []
var _move_yellow: Array = []
var _move_enemies: Array = []
var _path_preview: Array = []
var _attack_ring_r: int = 0
var _attack_ring_inner_r: int = -1
var _blast_flash_alpha: float = 0.0
var _blast_flash_cell: Vector2i = Vector2i(-1, -1)
var _blast_flash_radius: int = 0

func _ready() -> void:
	position = Vector2.ZERO
	y_sort_enabled = true
	queue_redraw()
	EventBus.show_range_ring.connect(_on_show_range_ring)
	EventBus.hide_range_ring.connect(_on_hide_range_ring)
	EventBus.resources_changed.connect(_on_resources_changed_ring)
	EventBus.smoke_zones_changed.connect(queue_redraw)
	EventBus.show_move_range.connect(_on_show_move_range)
	EventBus.hide_move_range.connect(_on_hide_move_range)
	EventBus.show_path_preview.connect(_on_show_path_preview)
	EventBus.hide_path_preview.connect(_on_hide_path_preview)
	EventBus.show_attack_range_overlay.connect(_on_show_attack_range_overlay)
	EventBus.hide_attack_range_overlay.connect(_on_hide_attack_range_overlay)
	EventBus.blast_tag_detonation.connect(_on_blast_tag_detonation)
	_fog = FogOfWar.new()
	_fog.name = "FogOfWar"
	add_child(_fog)
	if GameManager.player != null and is_instance_valid(GameManager.player):
		_fog.compute_fov(GameManager.player.grid_cell)
		_fog.update_entity_visibility()
		_fog.redraw_all()

func save_fov_data(scene_path: String) -> void:
	if _fog == null:
		return
	var all_fov: Dictionary = GameManager.player_data.get("fov_revealed", {})
	all_fov[scene_path] = _fog.get_revealed_data()
	GameManager.player_data["fov_revealed"] = all_fov

func restore_fov_data(scene_path: String) -> void:
	if _fog == null:
		return
	var data: Array = GameManager.player_data.get("fov_revealed", {}).get(scene_path, [])
	if not data.is_empty():
		_fog.load_revealed_data(data)
	if GameManager.player != null and is_instance_valid(GameManager.player):
		_fog.compute_fov(GameManager.player.grid_cell)
		_fog.update_entity_visibility()
		_fog.redraw_all()

func _on_show_range_ring(_center: Vector2i, r: int) -> void:
	_range_ring_r = r
	queue_redraw()

func _on_hide_range_ring() -> void:
	_range_ring_r = 0
	queue_redraw()

func _on_resources_changed_ring(_entity: Node) -> void:
	if _range_ring_r > 0 or _move_grey.size() > 0:
		queue_redraw()

func _on_show_move_range(grey: Array, yellow: Array, enemy: Array) -> void:
	_move_grey    = grey
	_move_yellow  = yellow
	_move_enemies = enemy
	queue_redraw()

func _on_hide_move_range() -> void:
	_move_grey    = []
	_move_yellow  = []
	_move_enemies = []
	queue_redraw()

func _on_show_path_preview(path: Array) -> void:
	_path_preview = path
	queue_redraw()

func _on_hide_path_preview() -> void:
	_path_preview = []
	queue_redraw()

func _on_show_attack_range_overlay(_center: Vector2i, r: int, inner: int) -> void:
	_attack_ring_r       = r
	_attack_ring_inner_r = inner
	queue_redraw()

func _on_hide_attack_range_overlay() -> void:
	_attack_ring_r       = 0
	_attack_ring_inner_r = -1
	queue_redraw()

func _on_blast_tag_detonation(center: Vector2i, radius: int) -> void:
	_blast_flash_cell   = center
	_blast_flash_radius = radius
	_blast_flash_alpha  = 1.0
	queue_redraw()

func _process(delta: float) -> void:
	if _blast_flash_alpha > 0.0:
		_blast_flash_alpha = maxf(0.0, _blast_flash_alpha - delta * 2.5)
		queue_redraw()


# ── Internal state ────────────────────────────────────────────────────────────
var blocked_cells: Dictionary = {}
var los_blocked_cells: Dictionary = {}  # Vector2i → true  (structural only: walls, rocks, closed doors)
var cover_cells: Dictionary = {}    # Vector2i -> float (cover size: 0.5 small, 0.8 large)
var _entity_cells: Dictionary = {}  # Vector2i -> Node
var _displaced_entities: Dictionary = {}  # Vector2i -> Node (bumped by a transient occupant; restored once that cell frees up)
var _ground_items: Array = []        # GroundItem nodes (multiple per cell allowed)
var cell_fill_colors: Dictionary = {}  # Vector2i -> Color (for terrain like river)
var pit_tiles: Dictionary = {}       # Vector2i -> true (draw depth faces, no outline)
var channel_tiles: Dictionary = {}   # Vector2i -> true (shallow water channel)
var _fog: FogOfWar = null

func register_entity(cell: Vector2i, entity: Node) -> void:
	# A mover (enemy/NPC) can step onto a non-blocking entity's cell (e.g. a
	# plant) while passing through. Stash whatever was there so it can be
	# restored once the mover leaves, instead of being permanently evicted.
	var existing: Node = _entity_cells.get(cell, null)
	if existing != null and existing != entity and is_instance_valid(existing):
		_displaced_entities[cell] = existing
	_entity_cells[cell] = entity
	if entity.blocks_movement:
		blocked_cells[cell] = true

func unregister_entity(cell: Vector2i) -> void:
	_entity_cells.erase(cell)
	blocked_cells.erase(cell)
	var displaced: Node = _displaced_entities.get(cell, null)
	if displaced != null:
		_displaced_entities.erase(cell)
		if is_instance_valid(displaced):
			_entity_cells[cell] = displaced
			if displaced.blocks_movement:
				blocked_cells[cell] = true

func register_cover(cell: Vector2i, size: float) -> void:
	cover_cells[cell] = size

func unregister_cover(cell: Vector2i) -> void:
	cover_cells.erase(cell)

func register_ground_item(item: Node) -> void:
	if item not in _ground_items:
		_ground_items.append(item)

func unregister_ground_item(item: Node) -> void:
	_ground_items.erase(item)

func get_ground_items_at(cell: Vector2i) -> Array:
	var result: Array = []
	for gi in _ground_items:
		if is_instance_valid(gi) and gi.grid_cell == cell:
			result.append(gi)
	return result

func get_entity_at(cell: Vector2i) -> Node:
	return _entity_cells.get(cell, null)

# The entity buried under whatever's currently registered at this cell (e.g. a
# plant a corpse landed on top of) — still present, just not the top occupant.
func get_displaced_entity_at(cell: Vector2i) -> Node:
	var d: Node = _displaced_entities.get(cell, null)
	if d != null and is_instance_valid(d):
		return d
	return null

func get_all_entities() -> Array:
	return _entity_cells.values() + _ground_items

# ── Coordinate helpers ────────────────────────────────────────────────────────
static func grid_to_screen(cell: Vector2i) -> Vector2:
	var x = (cell.x - cell.y) * (TileScene.TILE_W / 2.0)
	var y = (cell.x + cell.y) * (TileScene.TILE_H / 2.0)
	return Vector2(x, y)

static func screen_to_grid(pos: Vector2) -> Vector2i:
	var col = int(round((pos.x / (TileScene.TILE_W / 2.0) + pos.y / (TileScene.TILE_H / 2.0)) / 2.0))
	var row = int(round((pos.y / (TileScene.TILE_H / 2.0) - pos.x / (TileScene.TILE_W / 2.0)) / 2.0))
	return Vector2i(col, row)

func is_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < GRID_COLS and cell.y >= 0 and cell.y < GRID_ROWS

func is_walkable(cell: Vector2i) -> bool:
	return is_in_bounds(cell) and not blocked_cells.has(cell)

# ── Line of sight ─────────────────────────────────────────────────────────────
# Returns true if no blocked cell lies between from_cell and to_cell (exclusive).
# Uses linear interpolation to sample intermediate grid cells.
func has_line_of_sight(from_cell: Vector2i, to_cell: Vector2i) -> bool:
	var dx: int = to_cell.x - from_cell.x
	var dy: int = to_cell.y - from_cell.y
	var steps: int = maxi(abs(dx), abs(dy))
	if steps == 0:
		return true
	for i in range(1, steps):
		var t: float = float(i) / float(steps)
		var cx: int = int(round(from_cell.x + dx * t))
		var cy: int = int(round(from_cell.y + dy * t))
		var c := Vector2i(cx, cy)
		if los_blocked_cells.has(c):
			return false
	return true

# ── Drawing ───────────────────────────────────────────────────────────────────
const PIT_DEPTH: float = 24.0
const COL_PIT_FACE_SW: Color = Color(0.18, 0.14, 0.20)
const COL_PIT_FACE_SE: Color = Color(0.12, 0.09, 0.14)

const CHANNEL_DEPTH: float = 5.0
const COL_CHANNEL_FACE_SW: Color = Color(0.10, 0.11, 0.15)
const COL_CHANNEL_FACE_SE: Color = Color(0.07, 0.08, 0.11)

# Draws only the outward-facing edges of tiles within Euclidean distance r.
# Each of the 4 tile edges is drawn only when the grid-neighbour on the other
# side of that edge is outside the circle — giving a clean circular outline.
#
# Edge → neighbour mapping (derived from the isometric vertex identities):
#   T→R  (NE face)  ↔  neighbour (dx, dy-1)
#   R→B  (SE face)  ↔  neighbour (dx+1, dy)
#   B→L  (SW face)  ↔  neighbour (dx, dy+1)
#   L→T  (NW face)  ↔  neighbour (dx-1, dy)
func _draw_euclidean_ring(origin: Vector2i, r: int, color: Color, width: float) -> void:
	var r2: int = r * r
	for dx in range(-r, r + 1):
		for dy in range(-r, r + 1):
			if dx * dx + dy * dy > r2:
				continue
			var cell := Vector2i(origin.x + dx, origin.y + dy)
			if not is_in_bounds(cell):
				continue
			var c := grid_to_screen(cell)
			var hw: float = TILE_W / 2.0
			var hh: float = TILE_H / 2.0
			var T := c + Vector2(0,   -hh)
			var R := c + Vector2( hw,   0)
			var B := c + Vector2(0,    hh)
			var L := c + Vector2(-hw,   0)
			if dx * dx + (dy - 1) * (dy - 1) > r2:
				draw_line(T, R, color, width)
			if (dx + 1) * (dx + 1) + dy * dy > r2:
				draw_line(R, B, color, width)
			if dx * dx + (dy + 1) * (dy + 1) > r2:
				draw_line(B, L, color, width)
			if (dx - 1) * (dx - 1) + dy * dy > r2:
				draw_line(L, T, color, width)

func _iso_diamond(cell: Vector2i) -> PackedVector2Array:
	var c := grid_to_screen(cell)
	return PackedVector2Array([
		c + Vector2(0, -TILE_H / 2.0),
		c + Vector2(TILE_W / 2.0, 0),
		c + Vector2(0,  TILE_H / 2.0),
		c + Vector2(-TILE_W / 2.0, 0),
	])

func _draw() -> void:
	for col in range(GRID_COLS):
		for row in range(GRID_ROWS):
			_draw_iso_tile(Vector2i(col, row))
	# Draw active smoke zones
	for zone in GameManager.smoke_zones:
		var z_center: Vector2i = zone["center"]
		var z_radius: int = zone["radius"]
		for dc in range(-z_radius, z_radius + 1):
			for dr in range(-z_radius, z_radius + 1):
				if maxi(abs(dc), abs(dr)) > z_radius:
					continue
				var cell := Vector2i(z_center.x + dc, z_center.y + dr)
				if not is_in_bounds(cell):
					continue
				var c: Vector2 = grid_to_screen(cell)
				var pts := PackedVector2Array([
					c + Vector2(0, -TILE_H / 2.0),
					c + Vector2(TILE_W / 2.0, 0),
					c + Vector2(0,  TILE_H / 2.0),
					c + Vector2(-TILE_W / 2.0, 0),
				])
				draw_colored_polygon(pts, Color(0.65, 0.68, 0.62, 0.38))
				draw_polyline(pts + PackedVector2Array([pts[0]]), Color(0.60, 0.65, 0.55, 0.55), 1.0)
	# Movement range — grey (MP) and yellow (AP extension)
	for cell in _move_grey:
		var pts := _iso_diamond(cell)
		draw_colored_polygon(pts, Color(0.50, 0.50, 0.58, 0.28))
		draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), Color(0.62, 0.62, 0.70, 0.55), 1.0)
	for cell in _move_yellow:
		var pts := _iso_diamond(cell)
		draw_colored_polygon(pts, Color(0.85, 0.75, 0.08, 0.18))
		draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), Color(1.0, 0.88, 0.12, 0.50), 1.0)
	# Path preview (blue highlight)
	for cell in _path_preview:
		var pts := _iso_diamond(cell)
		draw_colored_polygon(pts, Color(0.18, 0.62, 1.0, 0.38))
		draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), Color(0.28, 0.72, 1.0, 0.72), 1.5)
	# Enemy in-range outlines (red border)
	for cell in _move_enemies:
		var pts := _iso_diamond(cell)
		draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), Color(0.95, 0.12, 0.12, 0.92), 2.5)
	# Blast tag armed indicator (orange tile where the tag is planted)
	if CombatManager.blast_tag_armed and is_in_bounds(CombatManager.blast_tag_cell):
		var btc := CombatManager.blast_tag_cell
		var bpts := _iso_diamond(btc)
		draw_colored_polygon(bpts, Color(1.0, 0.55, 0.05, 0.55))
		draw_polyline(PackedVector2Array([bpts[0], bpts[1], bpts[2], bpts[3], bpts[0]]), Color(1.0, 0.70, 0.10, 0.95), 2.5)
	# Blast tag detonation flash (orange circle that fades)
	if _blast_flash_alpha > 0.0 and is_in_bounds(_blast_flash_cell):
		var fr2: int = _blast_flash_radius * _blast_flash_radius
		for fdx in range(-_blast_flash_radius, _blast_flash_radius + 1):
			for fdy in range(-_blast_flash_radius, _blast_flash_radius + 1):
				if fdx * fdx + fdy * fdy > fr2:
					continue
				var fcell := Vector2i(_blast_flash_cell.x + fdx, _blast_flash_cell.y + fdy)
				if not is_in_bounds(fcell):
					continue
				var fpts := _iso_diamond(fcell)
				draw_colored_polygon(fpts, Color(1.0, 0.45, 0.05, _blast_flash_alpha * 0.80))
	# Red attack range overlay shown when hovering an attack button;
	# yellow inner ring shows the penalty-free range when long_ranged feat is active.
	if _attack_ring_r > 0 and GameManager.player != null and is_instance_valid(GameManager.player):
		var pc = GameManager.player.get("grid_cell")
		if pc != null:
			_draw_euclidean_ring(pc, _attack_ring_r, Color(0.95, 0.15, 0.15, 0.88), 2.0)
			if _attack_ring_inner_r > 0:
				_draw_euclidean_ring(pc, _attack_ring_inner_r, Color(1.0, 0.88, 0.12, 0.70), 1.5)
	# Yellow range ring (smoke throw / weapon range toggle)
	if _range_ring_r > 0 and GameManager.player != null:
		var player_cell = GameManager.player.get("grid_cell")
		if player_cell != null:
			_draw_euclidean_ring(player_cell, _range_ring_r, Color(1.0, 0.95, 0.10, 0.88), 2.0)

func _draw_iso_tile(cell: Vector2i) -> void:
	var center = grid_to_screen(cell)
	var top    = center + Vector2(0,              -TILE_H / 2.0)
	var right  = center + Vector2( TILE_W / 2.0,  0)
	var bottom = center + Vector2(0,               TILE_H / 2.0)
	var left   = center + Vector2(-TILE_W / 2.0,  0)
	if cell_fill_colors.has(cell):
		draw_colored_polygon(PackedVector2Array([top, right, bottom, left]), cell_fill_colors[cell])
	if pit_tiles.has(cell):
		# South depth face: B→L edge (shared with y+1 neighbor) — hole wall visible to player
		if not pit_tiles.has(Vector2i(cell.x, cell.y + 1)):
			draw_colored_polygon(PackedVector2Array([
				bottom, left,
				left   + Vector2(0.0, PIT_DEPTH),
				bottom + Vector2(0.0, PIT_DEPTH),
			]), COL_PIT_FACE_SW)
		# East depth face: R→B edge (shared with x+1 neighbor)
		if not pit_tiles.has(Vector2i(cell.x + 1, cell.y)):
			draw_colored_polygon(PackedVector2Array([
				right, bottom,
				bottom + Vector2(0.0, PIT_DEPTH),
				right  + Vector2(0.0, PIT_DEPTH),
			]), COL_PIT_FACE_SE)
		return  # no outline on pit tiles
	if channel_tiles.has(cell):
		var d := Vector2(0.0, CHANNEL_DEPTH)
		if not channel_tiles.has(Vector2i(cell.x, cell.y + 1)):
			draw_colored_polygon(PackedVector2Array([
				bottom, left, left + d, bottom + d,
			]), COL_CHANNEL_FACE_SW)
		if not channel_tiles.has(Vector2i(cell.x + 1, cell.y)):
			draw_colored_polygon(PackedVector2Array([
				right, bottom, bottom + d, right + d,
			]), COL_CHANNEL_FACE_SE)
		return  # no outline on water tiles
	draw_polyline(PackedVector2Array([top, right, bottom, left, top]), Color(0.6, 0.6, 0.6), 1.0)
