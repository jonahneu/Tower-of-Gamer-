extends Entity
class_name TutorialTrigger
# Invisible one-shot trigger: fires once when the player's grid_cell enters
# trigger_radius of grid_cell. Can auto-save on trigger, and/or show a
# dismissible tutorial popup (title/body). The popup only fires when
# tutorial_id is set — the AutoSaveTrigger instance in zone_escape_route.tscn
# uses this same script purely for the autosave-on-entry beat, with
# tutorial_id left blank.
# Journal recording (GameManager.add_tutorial) and the tutorial_popup_dismissed
# signal both fire from HUD's Continue button, not here — enemies gated on a
# tutorial (Enemy.tutorial_gate_id) must stay frozen for the whole time the
# popup is on screen, not just until it's requested.

@export var grid_cell: Vector2i = Vector2i(0, 0)
@export var trigger_radius: int = 0
@export var auto_save_on_trigger: bool = false
@export var tutorial_id: String = ""
@export var tutorial_title: String = ""
@export var tutorial_body: String = ""

# Alternate trigger mode: instead of player proximity to grid_cell, fire the
# first time the named cell enters the player's actual FOV this frame (e.g. a
# ground item coming into view) rather than a fixed radius around a point.
# Sentinel Vector2i(-9999, -9999) means "unused, use trigger_radius instead."
const _UNUSED_CELL: Vector2i = Vector2i(-9999, -9999)
@export var trigger_on_visible_cell: Vector2i = _UNUSED_CELL

var _fired: bool = false
var _tile_scene: TileScene = null

func _ready() -> void:
	is_interactable = false
	blocks_movement = false
	_tile_scene = get_parent() as TileScene

func _process(_delta: float) -> void:
	if _fired:
		return
	if trigger_on_visible_cell != _UNUSED_CELL:
		if _tile_scene == null or not _tile_scene.is_cell_currently_visible(trigger_on_visible_cell):
			return
		_fire()
		return
	var p: Node = GameManager.player
	if p == null:
		return
	var p_cell = p.get("grid_cell")
	if p_cell == null:
		return
	var d: Vector2i = (p_cell as Vector2i) - grid_cell
	if maxi(absi(d.x), absi(d.y)) > trigger_radius:
		return
	_fire()

func _fire() -> void:
	_fired = true
	if auto_save_on_trigger:
		GameManager.auto_save()
	if tutorial_id != "" and not GameManager.has_tutorial(tutorial_id):
		EventBus.tutorial_popup_requested.emit(tutorial_id, tutorial_title, tutorial_body)
