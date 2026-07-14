extends Entity
class_name TutorialTrigger
# Invisible one-shot trigger: fires once when the player's grid_cell enters
# trigger_radius of grid_cell, optionally auto-saving and/or logging a message
# via the existing EventBus.combat_log channel (the established precedent for
# one-off narrative/system text outside combat — see jammed_door.gd).
# New minimal utility added for the escape-route tutorial dungeon; no equivalent
# "tutorial popup" system existed in the codebase to reuse.

@export var grid_cell: Vector2i = Vector2i(0, 0)
@export var trigger_radius: int = 0
@export var message: String = ""
@export var auto_save_on_trigger: bool = false

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
	if message != "":
		EventBus.combat_log.emit(message)
