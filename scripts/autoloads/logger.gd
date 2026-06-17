extends Node
# GameLogger — writes a timestamped diagnostic log to user://logs/game_log.txt.
# Previous session's log is preserved as game_log_prev.txt.
#
# Autoload name is GameLogger, not Logger — Godot 4.6 ships a native
# engine class literally called "Logger", which silently shadows an
# autoload of the same name in other scripts' static analysis.
#
# Usage:
#   GameLogger.info("CATEGORY", "message")
#   GameLogger.warn("CATEGORY", "message")
#   GameLogger.error("CATEGORY", "message")
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

# ── Export ────────────────────────────────────────────────────────────────────
# Copies the last 24 hours of log entries to Desktop (fallback: Documents).
# Returns the export path, or "" on failure.
func export_log() -> String:
	if _file != null:
		_file.flush()
	# Lines older than 24h are stripped. Timestamps are [MM:SS.ss] relative to
	# session start, so cutoff_minutes is the elapsed-minute mark for 24h ago.
	var elapsed := Time.get_unix_time_from_system() - _start_time
	var cutoff_minutes: float = maxf(0.0, elapsed / 60.0 - 1440.0)

	var src := FileAccess.open(LOG_PATH, FileAccess.READ)
	if src == null:
		warn("LOGGER", "Export failed — could not open log for reading")
		return ""
	var lines: PackedStringArray = []
	while not src.eof_reached():
		var line := src.get_line()
		if line == "":
			continue
		if cutoff_minutes > 0.0 and line.begins_with("["):
			var end_b := line.find("]")
			if end_b > 1:
				var colon := line.find(":")
				if colon > 0 and colon < end_b:
					var line_minutes := float(line.substr(1, colon - 1))
					if line_minutes < cutoff_minutes:
						continue
		lines.append(line)
	src.close()

	var ts := Time.get_datetime_string_from_system().replace(":", "").replace(" ", "_")
	var filename := "tower_log_%s.txt" % ts
	for dir_id in [OS.SYSTEM_DIR_DESKTOP, OS.SYSTEM_DIR_DOCUMENTS]:
		var out_path := OS.get_system_dir(dir_id).path_join(filename)
		var dst := FileAccess.open(out_path, FileAccess.WRITE)
		if dst != null:
			dst.store_string("\n".join(lines))
			dst.close()
			info("LOGGER", "Exported to %s" % out_path)
			return out_path
	warn("LOGGER", "Export failed — could not write to Desktop or Documents")
	return ""

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

	# Zone transitions
	EventBus.zone_entered.connect(func():
		info("ZONE", "Entered zone — world pos: %s" % str(GameManager.world_pos)))

	# Combat participant added mid-combat (e.g. summoned via Howl)
	EventBus.combat_participant_added.connect(func(entity: Node):
		info("COMBAT", "Participant added mid-combat: %s  HP: %s" % [_name(entity), _hp_str(entity)]))

	# Player death
	EventBus.player_died.connect(func():
		error("PLAYER", "Player died  HP: %s" % _hp_str(GameManager.player)))
