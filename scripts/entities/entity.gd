extends Node2D
class_name Entity

# ── Identity ──────────────────────────────────────────────────────────────────
@export var entity_name: String = "Unknown"
@export var entity_id: String = ""

# ── Tags ──────────────────────────────────────────────────────────────────────
@export var blocks_movement: bool = false
@export var is_interactable: bool = false
var fow_hide_when_unseen: bool = false   # overridden true in NPC and Enemy
# How many tiles away the player can initiate interaction (1 = adjacent only).
# Set to 2 for NPCs behind a counter so the player can talk across it.
var interaction_reach: int = 1

# ── Base Stats ────────────────────────────────────────────────────────────────
# All stats default to 5 (= +0 modifier).
@export var stat_strength: int = 5
@export var stat_dexterity: int = 5
@export var stat_agility: int = 5
@export var stat_constitution: int = 5
@export var stat_intelligence: int = 5
@export var stat_willpower: int = 5
@export var stat_perception: int = 5

# ── Derived ───────────────────────────────────────────────────────────────────
var level: int = 1
var hp_flat_bonus: float = 0.0   # flat offset added to max_hp (can be negative)
var max_hp: float:
	get:
		var base: float = 5.0 * (5 + modifier(stat_constitution)) * (level + 1) + hp_flat_bonus
		var buff: Dictionary = GameManager.player_data.get("active_meal_buff", {})
		if buff.has("hp_pct"):
			base *= (1.0 + float(buff["hp_pct"]))
		return base
var current_hp: float = -1.0  # -1 means uninitialised; call init_hp() after setting stats

# ── Combat resources ──────────────────────────────────────────────────────────
# AP and MP both equal the raw agility stat (not modifier), plus meal buffs.
var max_ap: int:
	get:
		var buff: Dictionary = GameManager.player_data.get("active_meal_buff", {})
		return stat_agility + int(buff.get("agi_flat", 0))
var max_mp: int:
	get:
		var buff: Dictionary = GameManager.player_data.get("active_meal_buff", {})
		var base: int = stat_agility + int(buff.get("agi_flat", 0))
		if buff.has("mp_pct"):
			base = int(round(float(base) * (1.0 + float(buff["mp_pct"]))))
		return base
var current_ap: int = 0
var current_mp: int = 0

func init_hp() -> void:
	current_hp = max_hp

# ── Spirit ────────────────────────────────────────────────────────────────────
# Casting resource — based on willpower, restored only on rest (not per-turn), plus meal buffs.
var max_spirit: int:
	get:
		var buff: Dictionary = GameManager.player_data.get("active_meal_buff", {})
		var wil: int = stat_willpower + int(buff.get("wil_flat", 0))
		var base: int = wil * 5 * (level + 1)
		if buff.has("sp_pct"):
			base = int(float(base) * (1.0 + float(buff["sp_pct"])))
		return base
var current_spirit: int = 0

func init_spirit() -> void:
	current_spirit = max_spirit

func restore_ap_mp() -> void:
	current_ap = max_ap
	current_mp = max_mp

# ── Interaction ───────────────────────────────────────────────────────────────
# Returns a list of interaction options sorted by priority (highest = primary).
# Each entry: {"label": String, "id": String, "priority": int}
func get_interaction_options() -> Array:
	return []

# Override to return a screen-space polygon (in parent's local coords) that
# covers the full visible block, for click detection on raised geometry.
func get_click_polygon() -> PackedVector2Array:
	return PackedVector2Array()

# ── Modifier helper ───────────────────────────────────────────────────────────
# Returns the modifier for a given stat value (value - 5).
static func modifier(stat_value: int) -> int:
	return stat_value - 5

# ── Dice roller ───────────────────────────────────────────────────────────────
# Parses and rolls expressions like "1d6", "2d6", "1d3-1", "1d8+2".
static func roll_dice(expr: String) -> int:
	var parts := expr.to_lower().split("d")
	if parts.size() != 2:
		return int(expr)
	var num_dice := int(parts[0]) if parts[0].length() > 0 else 1
	var rest := parts[1]
	var sides := 0
	var modifier := 0
	if "+" in rest:
		var p := rest.split("+")
		sides    = int(p[0])
		modifier = int(p[1])
	elif "-" in rest:
		var p := rest.split("-")
		sides    = int(p[0])
		modifier = -int(p[1])
	else:
		sides = int(rest)
	var total := modifier
	for i in range(num_dice):
		total += randi_range(1, sides)
	return total

func mod_str() -> int: return modifier(stat_strength)
func mod_dex() -> int: return modifier(stat_dexterity)
func mod_agi() -> int: return modifier(stat_agility)
func mod_con() -> int: return modifier(stat_constitution)
func mod_int() -> int: return modifier(stat_intelligence)
func mod_wil() -> int: return modifier(stat_willpower)
func mod_per() -> int: return modifier(stat_perception)
