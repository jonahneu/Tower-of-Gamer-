extends Node
# Logger — writes a timestamped diagnostic log to user://logs/game_log.txt.
# Previous session's log is preserved as game_log_prev.txt.
#
# Usage:
#   Logger.info("CATEGORY", "message")
#   Logger.warn("CATEGORY", "message")
#   Logger.error("CATEGORY", "message")
#
# Key game events are captured automatically via EventBus signal connections.

const LOG_DIR      := "user://logs"
const LOG_PATH     := "user://logs/game_log.txt"
const PREV_LOG_PATH := "user://logs/game_log_prev.txt"

var _file: FileAccess = null
var _start_time: float = 0.0

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	_start_time = Time.get_unix_time_from_system()
	_rotate_log()
	_open_log()
	_connect_signals()
	info("INIT", "Session started — %s" % Time.get_datetime_string_from_system())

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and _file != null:
		info("INIT", "Session ended.")
		_file.close()

# ── File management ───────────────────────────────────────────────────────────

func _rotate_log() -> void:
	DirAccess.make_dir_absolute(LOG_DIR)
	if FileAccess.file_exists(LOG_PATH):
		var dir := DirAccess.open(LOG_DIR)
		if dir != null:
			if FileAccess.file_exists(PREV_LOG_PATH):
				dir.remove("game_log_prev.txt")
			dir.rename("game_log.txt", "game_log_prev.txt")

func _open_log() -> void:
	_file = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if _file == null:
		push_error("Logger: could not open log file at %s" % LOG_PATH)

# ── Write helpers ─────────────────────────────────────────────────────────────

func _timestamp() -> String:
	var elapsed := Time.get_unix_time_from_system() - _start_time
	var mins := int(elapsed / 60.0)
	var secs := fmod(elapsed, 60.0)
	return "[%02d:%05.2f]" % [mins, secs]

func _write(level: String, category: String, msg: String) -> void:
	if _file == null:
		return
	_file.store_string("%s [%-5s] [%s] %s\n" % [_timestamp(), level, category, msg])
	_file.flush()   # flush every line so crashes preserve the full log

func info(category: String, msg: String) -> void:
	_write("INFO", category, msg)

func warn(category: String, msg: String) -> void:
	_write("WARN", category, msg)

func error(category: String, msg: String) -> void:
	_write("ERROR", category, msg)

# ── Helpers ───────────────────────────────────────────────────────────────────

func _name(entity: Node) -> String:
	if entity == null or not is_instance_valid(entity):
		return "<freed>"
	var n = entity.get("entity_name")
	return str(n) if n != null else entity.name

func _hp_str(entity: Node) -> String:
	if entity == null or not is_instance_valid(entity):
		return "?"
	var hp  = entity.get("current_hp")
	var mhp = entity.get("max_hp")
	if hp == null or mhp == null:
		return "?"
	return "%.0f/%.0f" % [float(hp), float(mhp)]

func _status_str(entity: Node) -> String:
	if entity == null or not is_instance_valid(entity):
		return ""
	var fx = entity.get("status_effects")
	if fx == null or (fx as Dictionary).is_empty():
		return ""
	var parts: Array = []
	for k in (fx as Dictionary):
		parts.append("%s×%d" % [k, (fx[k] as Array).size()])
	return "  [%s]" % ", ".join(parts)

# ── EventBus connections ──────────────────────────────────────────────────────

func _connect_signals() -> void:
	# Combat lifecycle
	EventBus.combat_started.connect(func(participants: Array):
		var names: Array = []
		for e in participants:
			names.append(_name(e))
		info("COMBAT", "Started — %s" % ", ".join(names)))

	EventBus.combat_ended.connect(func(victor: String):
		info("COMBAT", "Ended — victor: %s" % victor))

	# Tactical mode
	EventBus.tactical_started.connect(func(_p):
		info("TACTICAL", "Tactical mode started"))

	EventBus.tactical_ended.connect(func():
		info("TACTICAL", "Tactical mode ended"))

	# Turns
	EventBus.turn_started.connect(func(entity: Node):
		info("TURN", "Started: %s  HP: %s%s" % [
			_name(entity), _hp_str(entity), _status_str(entity)]))

	EventBus.turn_ended.connect(func(entity: Node):
		info("TURN", "Ended:   %s" % _name(entity)))

	# Status effects
	EventBus.status_applied.connect(func(entity: Node, status_name: String):
		var stacks := 0
		if entity != null and is_instance_valid(entity):
			var fx = entity.get("status_effects")
			if fx != null:
				stacks = (fx as Dictionary).get(status_name, []).size()
		info("STATUS", "%s applied to %s (total stacks now: %d)" % [
			status_name, _name(entity), stacks]))

	EventBus.status_cleared.connect(func(entity: Node, status_name: String):
		info("STATUS", "%s cleared from %s" % [status_name, _name(entity)]))

	# Damage
	EventBus.damage_dealt.connect(func(entity: Node, amount, source: String):
		info("DAMAGE", "%s took %.0f [%s]  HP now: %s" % [
			_name(entity), float(amount), source, _hp_str(entity)]))

	# Attacks
	EventBus.attack_resolved.connect(func(attacker: Node, hit: bool):
		info("ATTACK", "%s — %s" % [_name(attacker), "HIT" if hit else "MISS"]))

	# Player death
	EventBus.player_died.connect(func():
		error("PLAYER", "Player died  HP: %s" % _hp_str(GameManager.player)))
