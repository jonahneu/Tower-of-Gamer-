extends Enemy
class_name CannibalLeader

# ── Baseline leader stats ─────────────────────────────────────────────────────
# Level 5 — unarmed brawler, immense Strength from eating and wearing victims
# (the "fuller" cannibalism variant of the Way of Beasts; two trophy slots
# worth of bonus, vs. one for an ordinary skin-wearer).
# CON 8 (mod +3) → base max_hp = 5*8*6 = 240
# AGI 4 → max_ap = max_mp = 4 (slow but devastating: two 2-AP punches per turn)
# STR 10 (mod +5), unarmed half-DEX-damage → punches hit for 1d6+5
# Punches have a chance to inflict Dazed, same as the Sand Beetle's Ram.

const DAZE_CHANCE: float = 0.30

func _ready() -> void:
	entity_name       = "Cannibal Leader"
	beast_type        = "human"
	is_human          = true
	aggro_range       = 16
	xp_value          = 150
	enemy_level       = 5
	level             = 5
	stat_strength     = 10
	stat_dexterity    = 5
	stat_agility      = 6
	stat_constitution = 8
	stat_intelligence = 3
	stat_willpower    = 6
	stat_perception   = 5

	skills["melee"] = 18
	skills["dodge"] = 3

	equipment["back"]     = DataManager.get_item("human_skin_trophy")
	equipment["necklace"] = DataManager.get_item("human_skin_trophy")

	sprite_w     = 34
	sprite_h     = 50
	sprite_color = Color(0.50, 0.40, 0.30)

	_attack_weapon = {
		"name":            "Punch",
		"type":            "weapon",
		"damage":          "1d6",
		"ap_cost":         2,
		"skill":           "melee",
		"governing":       ["strength", "dexterity"],
		"damage_type":     "physical",
		"properties":      [],
		"half_dex_damage": true,
	}

	feats.append("runner")
	super._ready()
	EventBus.attack_resolved.connect(_on_attack_resolved)

func _on_attack_resolved(attacker: Node, hit: bool) -> void:
	if attacker != self or not hit:
		return
	var player_typed: Player = GameManager.player as Player
	if player_typed == null:
		return
	if player_typed.status_effects.get("dazed", []).is_empty() and randf() < DAZE_CHANCE:
		player_typed.status_effects["dazed"] = [1]
		EventBus.status_applied.emit(player_typed, "dazed")
		EventBus.damage_floater.emit(player_typed, "dazed", Color(0.85, 0.65, 0.10))
		EventBus.combat_log.emit("%s reels from the blow — Dazed!" % player_typed.entity_name)
