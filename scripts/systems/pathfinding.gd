extends RefCounted
class_name Pathfinding

# A* pathfinding on the isometric grid.
# Usage: var path = Pathfinding.find_path(start, end, tile_scene)

static func find_path(start: Vector2i, goal: Vector2i, tile: TileScene) -> Array[Vector2i]:
	if not tile.is_walkable(goal):
		return []
	if start == goal:
		return []

	var open: Array[Vector2i] = [start]
	var came_from: Dictionary = {}
	var g_score: Dictionary = { start: 0 }
	var f_score: Dictionary = { start: _heuristic(start, goal) }

	while open.size() > 0:
		var current = _lowest_f(open, f_score)

		if current == goal:
			return _reconstruct(came_from, current)

		open.erase(current)

		for neighbor in _neighbors(current, tile):
			var tentative_g = g_score[current] + 1
			if not g_score.has(neighbor) or tentative_g < g_score[neighbor]:
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g
				f_score[neighbor] = tentative_g + _heuristic(neighbor, goal)
				if not open.has(neighbor):
					open.append(neighbor)

	return []  # No path found

static func _heuristic(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)

static func _lowest_f(open: Array[Vector2i], f_score: Dictionary) -> Vector2i:
	var best = open[0]
	for cell in open:
		if f_score.get(cell, 9999) < f_score.get(best, 9999):
			best = cell
	return best

static func _neighbors(cell: Vector2i, tile: TileScene) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var dirs = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
	for d in dirs:
		var n = cell + d
		if tile.is_walkable(n):
			result.append(n)
	return result

static func _reconstruct(came_from: Dictionary, current: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = [current]
	while came_from.has(current):
		current = came_from[current]
		path.push_front(current)
	path.remove_at(0)  # Drop the start cell itself
	return path
