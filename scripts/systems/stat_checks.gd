extends RefCounted
class_name StatChecks

# Flat, deterministic stat gates against the player's raw stats (see
# GameManager.player_data["stats"]) — no dice roll, no buffs/modifiers, just
# "does the player have at least N in this stat." For obstacles like forcing
# open a jammed door, not for combat/skill rolls (those stay their own thing).

static func player_stat(stat_name: String) -> int:
	return GameManager.player_data.get("stats", {}).get(stat_name, 5)

static func meets(stat_name: String, required: int) -> bool:
	return player_stat(stat_name) >= required
