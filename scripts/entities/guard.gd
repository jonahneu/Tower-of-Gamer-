extends NPC
class_name Guard

# City guard — spear-armed, posted around town (desert road, market district).
# Placeholder dialogue until the gate-guard questline/dialogue is written.

# When patrol_max_x > patrol_min_x, the guard paces back and forth along
# row `grid_cell.y` between those two columns. Left at -1/-1 (default), the
# guard just stands at its placed grid_cell.
@export var patrol_min_x: int = -1
@export var patrol_max_x: int = -1

const PATROL_STEP_INTERVAL: float = 1.4
const PATROL_STEP_DURATION: float = 0.5

var _patrol_dir: int = 1

func _ready() -> void:
	stat_strength     = 7
	stat_dexterity    = 6
	stat_agility      = 5
	stat_constitution = 6
	stat_willpower    = 6
	stat_perception   = 6
	level             = 2
	skills["melee"] = 22
	skills["dodge"] = 14
	equipment["hand_1"] = DataManager.get_item("bronze_spear")
	equipment["torso"]  = DataManager.get_item("leather_vest")
	equipment["legs"]   = DataManager.get_item("work_trousers")
	_attack_weapon = DataManager.get_item("bronze_spear")
	drops_loot = false
	super._ready()
	entity_name = "Guard"
	dialogue_text = "TBD"
	dialogue_options = [
		{"label": "[Leave]", "response": "", "closes": true},
	]
	if patrol_max_x > patrol_min_x:
		_patrol_loop()
	EventBus.crime_witnessed.connect(_on_crime_witnessed)

# A citizen was just attacked somewhere in the city — if it happened in this
# guard's own zone, wade in against the player. Citizen NPCs default to
# is_citizen = true; thugs (mugging is their crime, not a crime against them)
# opt out, so attacking one doesn't summon the watch.
func _on_crime_witnessed(victim: Node) -> void:
	if is_hostile or _dead or victim == self:
		return
	if victim.get("_tile_scene") != _tile_scene:
		return
	go_hostile()

# Fire-and-forget loop started once from _ready; bails out for good once the
# guard is freed/dead, just skips a beat for combat.
func _patrol_loop() -> void:
	while true:
		await get_tree().create_timer(PATROL_STEP_INTERVAL).timeout
		if not is_instance_valid(self) or _dead:
			return
		if _in_combat or GameManager.combat_mode:
			continue
		_patrol_step()

func _patrol_step() -> void:
	var next_x: int = grid_cell.x + _patrol_dir
	if next_x > patrol_max_x or next_x < patrol_min_x:
		_patrol_dir = -_patrol_dir
		next_x = grid_cell.x + _patrol_dir
	var next_cell := Vector2i(next_x, grid_cell.y)
	if _tile_scene == null or not _tile_scene.is_walkable(next_cell):
		return
	_tile_scene.unregister_entity(grid_cell)
	grid_cell = next_cell
	_tile_scene.register_entity(grid_cell, self)
	var target_screen: Vector2 = TileScene.grid_to_screen(grid_cell)
	var tween := create_tween()
	tween.tween_property(self, "position", target_screen, PATROL_STEP_DURATION)
	await tween.finished
	if is_instance_valid(self):
		_visual_pos = target_screen
		queue_redraw()
