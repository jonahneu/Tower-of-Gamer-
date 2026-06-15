extends Enemy
class_name Cannibal

# ── Baseline regular cannibal stats ───────────────────────────────────────────
# Level 2 — a desperate, starving human armed with a stone knife.
# CON 5 (mod 0) → base max_hp = 5*5*3 = 75
# AGI 5 → max_ap = max_mp = 5
#
# Yell (2 AP): once per combat, calls every other idle cannibal (Cannibal,
# CannibalScout, CannibalSkinwearer, CannibalLeader) in the zone into the
# fight. Mirrors the Adolescent Coyote's Howl.

var _yelled: bool = false

func _ready() -> void:
	if entity_name == "Unknown":
		entity_name = "Cannibal"
	beast_type        = "human"
	is_human          = true
	aggro_range       = 14
	xp_value          = 25
	enemy_level       = 2
	level             = 2
	stat_strength     = 5
	stat_dexterity    = 6
	stat_agility      = 5
	stat_constitution = 5
	stat_intelligence = 4
	stat_willpower    = 4
	stat_perception   = 5

	skills["melee"] = 8
	skills["dodge"] = 2

	sprite_w     = 26
	sprite_h     = 42
	sprite_color = Color(0.42, 0.36, 0.30)   # filthy rags

	_attack_weapon = DataManager.get_item("knife")

	super._ready()


# ── AI turn override: try Yell first, then fall back to the normal turn ──────
func _execute_ai_turn() -> void:
	if _yell_phase():
		await get_tree().create_timer(0.45).timeout
		if not is_instance_valid(self) or not _in_combat:
			return
	super._execute_ai_turn()


# Yell (2 AP, once per combat): calls every other idle cannibal-type entity in
# the zone into the fight. Returns true if the yell was performed.
func _yell_phase() -> bool:
	if _yelled or CombatManager.current_ap() < 2 or _tile_scene == null:
		return false

	var idle_cannibals: Array = []
	for entity in _tile_scene.get_all_entities():
		var enemy := entity as Enemy
		if enemy == null or enemy == self:
			continue
		if (entity is Cannibal or entity is CannibalSkinwearer or entity is CannibalLeader) \
				and not enemy._in_combat and not enemy._dead:
			idle_cannibals.append(enemy)

	if idle_cannibals.is_empty():
		_yelled = true  # nothing to call — skip in future turns
		return false

	EventBus.damage_floater.emit(self, "Yelling!", Color(1.0, 0.80, 0.15))
	CombatManager.spend_ap(2)
	_yelled = true
	for enemy in idle_cannibals:
		if is_instance_valid(enemy):
			CombatManager.add_participant(enemy)
	return true


func _on_combat_ended(victor: String) -> void:
	_yelled = false
	super._on_combat_ended(victor)
