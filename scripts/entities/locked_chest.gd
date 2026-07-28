extends LootContainer
class_name LockedChest
# A chest that starts locked. Openable with a specific key item in inventory,
# or a flat Sleight of Hand skill threshold (no dice roll) — same flat-threshold
# pattern jammed_door.gd uses for a Strength check, just against a skill instead
# of a stat (see stat_checks.gd for the stat-only precedent this mirrors).

@export var required_key_id: String = ""
@export var sleight_of_hand_threshold: int = 5

# Optional first-Unlock-attempt tutorial popup — mirrors Enemy.tutorial_gate_id,
# but doesn't need to freeze anything: the first "Unlock" click just shows the
# popup instead of resolving, so it fires exactly when the player actually
# tries to open this chest, not merely when they walk near it.
@export var tutorial_gate_id: String = ""
@export var tutorial_gate_title: String = ""
@export var tutorial_gate_body: String = ""

var _unlocked: bool = false

func _player_has_key() -> bool:
	if required_key_id == "":
		return false
	for item in GameManager.player_data.get("inventory", []):
		if item is Dictionary and item.get("id", "") == required_key_id:
			return true
	return false

func _player_meets_sleight_of_hand() -> bool:
	var skill: int = int(GameManager.player_data.get("skills", {}).get("sleight_of_hand", 0))
	return skill >= sleight_of_hand_threshold

func get_interaction_options() -> Array:
	if _unlocked:
		return super.get_interaction_options()
	return [
		{"label": "Unlock", "id": "interact", "priority": 100},
		{"label": "Examine", "id": "examine", "priority": 50},
	]

func get_description() -> String:
	if _unlocked:
		return super.get_description()
	return "A locked chest."

func interact() -> void:
	if _unlocked:
		return
	if tutorial_gate_id != "" and not GameManager.has_tutorial(tutorial_gate_id):
		EventBus.tutorial_popup_requested.emit(tutorial_gate_id, tutorial_gate_title, tutorial_gate_body)
		return
	if _player_has_key():
		_unlocked = true
		EventBus.combat_log.emit("You unlock the chest with the %s." % DataManager.get_item(required_key_id).get("name", "key"))
	elif _player_meets_sleight_of_hand():
		_unlocked = true
		EventBus.combat_log.emit("You work the lock open. [Sleight of Hand %d]" % sleight_of_hand_threshold)
	else:
		EventBus.combat_log.emit("The chest is locked. [Requires the key, or Sleight of Hand %d]" % sleight_of_hand_threshold)
	queue_redraw()

func _draw() -> void:
	_draw_crate_body()
	if not _unlocked:
		var base_y: float = TileScene.TILE_H / 4.0 - CRATE_H * 0.5
		draw_rect(Rect2(-3.0, base_y - 2.0, 6.0, 6.0), Color(0.75, 0.68, 0.20))
	if _highlighted:
		var ring_y: float = -CRATE_H * 0.5 + TileScene.TILE_H / 4.0
		draw_circle(Vector2(0, ring_y), 26.0, Color(1.0, 0.85, 0.0, 0.16))
		draw_arc(Vector2(0, ring_y), 26.0, 0, TAU, 32, Color(1.0, 0.85, 0.0), 2.0)
		_draw_name_label(ring_y - CRATE_H - 6.0)
