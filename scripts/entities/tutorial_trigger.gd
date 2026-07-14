extends Entity
class_name TutorialTrigger
# Invisible one-shot trigger: fires once when the player's grid_cell enters
# trigger_radius of grid_cell. Can auto-save on trigger, and/or show a
# dismissible tutorial popup (title/body) that's also recorded into the
# journal's Tutorials tab via GameManager.add_tutorial() so the player can
# revisit it later. The popup only fires when tutorial_id is set — the
# AutoSaveTrigger instance in zone_escape_route.tscn uses this same script
# purely for the autosave-on-entry beat, with tutorial_id left blank.

@export var grid_cell: Vector2i = Vector2i(0, 0)
@export var trigger_radius: int = 0
@export var auto_save_on_trigger: bool = false
@export var tutorial_id: String = ""
@export var tutorial_title: String = ""
@export var tutorial_body: String = ""

var _fired: bool = false

func _ready() -> void:
	is_interactable = false
	blocks_movement = false

func _process(_delta: float) -> void:
	if _fired:
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
	_fired = true
	if auto_save_on_trigger:
		GameManager.auto_save()
	if tutorial_id != "" and not GameManager.has_tutorial(tutorial_id):
		GameManager.add_tutorial({"id": tutorial_id, "title": tutorial_title, "body": tutorial_body})
		EventBus.tutorial_popup_requested.emit(tutorial_id, tutorial_title, tutorial_body)
