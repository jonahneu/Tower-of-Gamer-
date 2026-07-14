extends LootContainer
class_name LockedChest
# A chest that starts locked. Openable with a specific key item in inventory,
# or a flat Sleight of Hand skill threshold (no dice roll) — same flat-threshold
# pattern jammed_door.gd uses for a Strength check, just against a skill instead
# of a stat (see stat_checks.gd for the stat-only precedent this mirrors).

@export var required_key_id: String = ""
@export var sleight_of_hand_threshold: int = 5

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
	if _player_has_key():
		_unlocked = true
		EventBus.combat_log.emit("You unlock the chest with the %s." % DataManager.get_item(required_key_id).get("name", "key"))
	elif _player_meets_sleight_of_hand():
		_unlocked = true
		EventBus.combat_log.emit("You work the lock open. [Sleight of Hand %d]" % sleight_of_hand_threshold)
	else:
		EventBus.combat_log.emit("The chest is locked. [Requires the key, or Sleight of Hand %d]" % sleight_of_hand_threshold)
