extends Node
# DataManager — central item/skill/feat definitions.

var skills: Dictionary = {}
var feats: Dictionary = {}
var items: Dictionary = {}

func _ready() -> void:
	_load_items()
	_load_feats()

func get_feat(id: String) -> Dictionary:
	return feats.get(id, {}).duplicate(true)

func get_all_feats() -> Array:
	return feats.values().map(func(f): return f.duplicate(true))

# ── Feat definitions ──────────────────────────────────────────────────────────
# source: "level_up" = selectable at character creation / level-up
#         "story"    = granted by world events; never shown in the pick list
# requirements:
#   "stats"  — minimum stat values (e.g. {"dexterity": 8})
#   "skills" — minimum skill invested points (e.g. {"melee": 15})
# effect_tag: short machine-readable string checked by combat/skill/etc. systems
func _load_feats() -> void:
	feats["long_ranged"] = {
		"id": "long_ranged", "name": "Long Ranged", "source": "level_up",
		"description": "You can place shots others wouldn't attempt. Ranged attacks may be made at up to double normal range. Each tile past normal range linearly reduces your hit chance, reaching 50% of normal at double range.",
		"requirements": {"stats": {"perception": 8}, "skills": {"ranged": 20}},
		"effect_tag": "double_range_penalty",
	}
	feats["runner"] = {
		"id": "runner", "name": "Runner", "source": "level_up",
		"description": "You don't slow down when the MP runs dry. Each AP spent on movement after your MP is exhausted moves you 2 tiles instead of 1.",
		"requirements": {"stats": {"agility": 6}, "skills": {}},
		"effect_tag": "ap_move_2mp",
	}
	feats["brutal"] = {
		"id": "brutal", "name": "Brutal", "source": "level_up",
		"description": "You hit hard enough to make armor not matter. All of your attacks ignore 20% of the target's armor (both flat and percentage), stacking multiplicatively with any other armor penetration.",
		"requirements": {"stats": {"strength": 8}, "skills": {}},
		"effect_tag": "armor_ignore_20pct",
	}
	feats["heavy_hitter"] = {
		"id": "heavy_hitter", "name": "Heavy Hitter", "source": "level_up",
		"description": "You commit fully to every swing. Melee attacks deal bonus damage equal to the percentage of your turn's total AP that attack cost — spend it all on one strike for double damage, half for 1.5x, and so on.",
		"requirements": {"stats": {"strength": 8}, "skills": {"melee": 15}},
		"effect_tag": "heavy_hitter",
	}
	feats["bloodletting"] = {
		"id": "bloodletting", "name": "Bloodletting", "source": "level_up",
		"description": "You know exactly where to cut. On weapons that can already inflict Bleed, your chance to do so is increased by 30%.",
		"requirements": {"stats": {"dexterity": 8}, "skills": {}},
		"effect_tag": "bleed_chance_x1.3",
	}
	feats["fast_hands"] = {
		"id": "fast_hands", "name": "Fast Hands", "source": "level_up",
		"description": "Your speed with bare hands is exceptional. Unarmed attacks cost 1 AP instead of 2.",
		"requirements": {"stats": {"dexterity": 8}, "skills": {"melee": 15}},
		"effect_tag": "unarmed_ap_1",
	}
	feats["iron_belly"] = {
		"id": "iron_belly", "name": "Iron Belly", "source": "level_up",
		"description": "Years of mixing and tasting have given your gut walls of iron. You take only half damage from anything you consume.",
		"requirements": {"stats": {"constitution": 6}, "skills": {"alchemy": 15}},
		"effect_tag": "consumed_half_damage",
	}
	feats["shrug_off"] = {
		"id": "shrug_off", "name": "Shrug Off", "source": "level_up",
		"description": "Your will is a wall. When a status effect is successfully applied to you, there is a 10% chance your mind simply refuses it.",
		"requirements": {"stats": {"willpower": 8}, "skills": {}},
		"effect_tag": "status_ignore_10pct",
	}
	feats["bulky"] = {
		"id": "bulky", "name": "Bulky", "source": "level_up",
		"description": "Thick of frame and built to take a beating. You gain 10% resistance to all damage types, applied multiplicatively on top of your armor and any other resistances. The bulk comes at a cost, though — you carry a permanent −10 penalty to Sneak and Dodge, as if always weighed down in armor.",
		"requirements": {"stats": {"constitution": 8}, "skills": {}},
		"effect_tag": "bulky_resist_and_penalty",
	}
	feats["harvester"] = {
		"id": "harvester", "name": "Hunter-Gatherer", "source": "level_up",
		"description": "You know how to take more than your share from the land. Whenever you carve a kill or pick a plant, there's a chance you walk away with double the yield. This chance scales with your survival skill — 10% at 20, up to 100% at 200.",
		"requirements": {"stats": {}, "skills": {"survival": 15}},
		"effect_tag": "harvest_double_chance",
	}
	feats["chain_caster"] = {
		"id": "chain_caster", "name": "Chain Caster", "source": "level_up",
		"description": "Each spell you cast leaves the weave primed for the next. Every spell already cast this turn reduces the Spirit cost of your next spell by 10%, multiplicatively.",
		"requirements": {"stats": {"agility": 8}, "skills": {"occultism": 20}},
		"effect_tag": "chain_caster_sp_discount",
	}

	# ── Story-granted (not selectable at level-up) ────────────────────────────
	feats["inner_flame"] = {
		"id": "inner_flame", "name": "Inner Flame", "source": "story",
		"description": "You have experienced the flame and carry it within you now. Grants permanent Level 0 spirit protection — the spirits of the night cannot take you unaware.",
		"requirements": {"stats": {}, "skills": {}},
		"effect_tag": "spirit_protection_level_0",
	}

# ── Trophy crafting recipes ────────────────────────────────────────────────────
# Quality scaling: multiplier = quality * 0.25
#   Quality 0 (Ruined)   = 0%   of base buff
#   Quality 1 (Poor)     = 25%
#   Quality 2 (Common)   = 50%
#   Quality 3 (Good)     = 75%
#   Quality 4 (Fine)     = 100% ← reference value
#   Quality 5 (Pristine) = 125%
# base_buffs values are at Fine quality (100%).
# Buffs contributed by each beast material when used as the PRIMARY material in a trophy recipe.
# Values are at Fine quality (mult = 1.0). craft_trophy scales them by quality * 0.25.
# Secondary materials (binding, cord, etc.) never contribute buffs — only the primary does.
# Add new beasts/materials here. Higher-tier materials may require higher recipe craft_levels later.
const BEAST_MATERIAL_BUFFS: Dictionary = {
	"coyote": {
		"pelt":  {"defense_pct": 0.02},
		"bones": {},
		"fangs": {"skill_bonus": {"melee": 5.0}},
		"skull": {"governing_bonus": {"melee": 1.0}, "defense_flat": 1.0, "defense_pct": 0.03},
		"meat":  {},
	},
	"adolescent_coyote": {
		"pelt":  {"defense_pct": 0.035},
		"bones": {},
		"fangs": {"skill_bonus": {"melee": 7.0}},
		"meat":  {},
	},
	"lizard": {
		"bones":      {},
		"skin":       {"skill_bonus": {"ranged": 5.0, "sneak": 2.0}},
		"acid_gland": {},
	},
	"sand_beetle": {
		"meat":      {},
		"mandibles": {"defense_flat": 1.0, "defense_pct": 0.04},
		"shell":     {},
	},
}

const RECIPES: Dictionary = {
	# item_type_name: short label appended after beast + material in the output item's name.
	# e.g. coyote pelt + "Armband" → "Coyote Pelt Armband"
	"basic_hide_trophy_armband": {
		"id":                 "basic_hide_trophy_armband",
		"category":           "way_of_beasts",
		"item_type_name":     "Armband",
		"required_materials": ["hide"],          # "hide" accepts pelt, skin, etc. (see MATERIAL_GROUPS)
		"slot":               "upper_arm",
		"trophy_type":        "armband",
		"spirit_ward":        true,
		"weight":             0.5,
		"lore":               "A strip of hide bound around the upper arm. Marks you as one who has taken life with their hands.",
		# Skill gate: crafting >= craft_level, or survival >= ceil(craft_level * 0.6) if hunter_taught
		# craft_level is at Fine quality (4); scales as quality * 0.25 the same way buffs do.
		"craft_level":        10,
		"hunter_taught":      true,
	},
	"basic_fang_trophy_necklace": {
		"id":                 "basic_fang_trophy_necklace",
		"category":           "way_of_beasts",
		"item_type_name":     "Fang Necklace",
		"required_materials": ["fangs", "hide"], # fangs = primary, hide = cord/binding
		"slot":               "necklace",
		"trophy_type":        "fang_necklace",
		"spirit_ward":        true,
		"weight":             0.1,
		"lore":               "Fangs hung on a cord of sinew. Sharp and purposeful.",
		"craft_level":        15,
		"hunter_taught":      true,
	},
	"basic_bone_ring": {
		"id":                 "basic_bone_ring",
		"category":           "way_of_beasts",
		"item_type_name":     "Bone Ring",
		"required_materials": ["bones"],
		"slot":               "ring",
		"trophy_type":        "bone_ring",
		"spirit_ward":        true,
		"weight":             0.05,
		"lore":               "A fragment of bone shaped into a ring and worn on the finger. The barest acknowledgement of what you have taken.",
		"craft_level":        5,
		"hunter_taught":      true,
	},
	"basic_skull_trophy_headdress": {
		"id":                 "basic_skull_trophy_headdress",
		"category":           "way_of_beasts",
		"item_type_name":     "Skull Headdress",
		"required_materials": ["skull", "hide"], # skull = primary, hide = lining/strap
		"slot":               "head",
		"trophy_type":        "skull_headdress",
		"spirit_ward":        true,
		"weight":             1.0,
		"lore":               "A skull fitted to sit above the brow. Its hollow eyes look where you look.",
		"craft_level":        25,
		"hunter_taught":      true,
	},
}

# ── Alchemy recipes ────────────────────────────────────────────────────────────
# required_items: Array of item IDs that must be in the player's inventory.
# result_item:    item ID of the crafted result.
# alchemy_level:  minimum alchemy (or occultism) skill required.
const ALCHEMY_RECIPES: Dictionary = {
	"dark_vial_brew": {
		"id":               "dark_vial_brew",
		"name":             "First Poison of Acclimation",
		"category":         "alchemy",
		"required_items":   ["dusk_flower", "desert_succulent"],
		"result_item":      "dark_vial",
		"alchemy_level":    15,
		"occultism_level":  0,
		"lore":             "Extract essence from both plants and combine them. The body already knows how to resist a little poison — this just reminds it.",
	},
	"basic_lingering_poison_brew": {
		"id":               "basic_lingering_poison_brew",
		"name":             "Basic Lingering Poison",
		"category":         "alchemy",
		"required_items":   ["dusk_flower", "lizard_acid_gland"],
		"result_item":      "basic_lingering_poison",
		"alchemy_level":    20,
		"occultism_level":  0,
		"lore":             "Crush the dusk flower petals into the intact acid gland over low heat until the contents render down. The mixture coats a blade cleanly and clings until washed off.",
	},
	"smoke_bomb_brew": {
		"id":               "smoke_bomb_brew",
		"name":             "Smoke Bomb",
		"category":         "alchemy",
		"required_items":   ["desert_succulent", "desert_succulent"],
		"result_item":      "smoke_bomb",
		"alchemy_level":    15,
		"occultism_level":  999,
		"lore":             "Pack dried succulent fibers into a clay ball with a slow-burn core. When it breaks open the oils smoke densely for several minutes.",
	},
}

func get_recipe(id: String) -> Dictionary:
	return RECIPES.get(id, {})

func get_alchemy_recipe(id: String) -> Dictionary:
	return ALCHEMY_RECIPES.get(id, {})

# ── Scripture recipes ─────────────────────────────────────────────────────────
# Scripture crafting: specific inventory items → talisman result.
# No skill check at craft time — skill gating happens when the scribe teaches the recipe.
const SCRIPTURE_RECIPES: Dictionary = {
	"basic_protective_talisman_craft": {
		"id":             "basic_protective_talisman_craft",
		"name":           "Basic Protective Talisman",
		"category":       "scriptures",
		"required_items": ["blank_talisman", "ink"],
		"result_item":    "basic_protective_talisman",
		"lore":           "Copy the protection scripture onto the blank talisman using the ink. Focus on the forms — the meaning follows the accuracy of the strokes.",
	},
	"blast_tag_craft": {
		"id":             "blast_tag_craft",
		"name":           "Blast Tag",
		"category":       "scriptures",
		"required_items": ["blank_talisman", "ink"],
		"result_item":    "blast_tag",
		"lore":           "A volatile detonation scripture compressed onto a folded seal. The strokes store potential — spent SP releases it all at once.",
	},
	"enchanted_fist_wraps_craft": {
		"id":             "enchanted_fist_wraps_craft",
		"name":           "Enchanted Fist Wraps",
		"category":       "scriptures",
		"required_items": ["blank_talisman", "ink"],
		"result_item":    "enchanted_fist_wraps",
		"lore":           "Scripture of projection and force, written to channel strikes beyond physical contact. The cloth becomes a conduit, not just a covering.",
	},
}

func get_scripture_recipe(id: String) -> Dictionary:
	return SCRIPTURE_RECIPES.get(id, {})

func craft_scripture(recipe_id: String) -> Dictionary:
	var recipe: Dictionary = SCRIPTURE_RECIPES.get(recipe_id, {})
	if recipe.is_empty():
		return {}
	var result: Dictionary = get_item(recipe.get("result_item", "")).duplicate(true)
	if result.is_empty():
		return {}
	result["player_made"] = true
	return result

# Returns whether the player meets the skill requirement for an alchemy recipe.
# Passes if alchemy >= alchemy_level OR occultism >= alchemy_level.
func check_alchemy_skill(recipe_id: String, player_skills: Dictionary) -> Dictionary:
	var recipe: Dictionary  = ALCHEMY_RECIPES.get(recipe_id, {})
	var req_alchemy: int    = recipe.get("alchemy_level", 0)
	var req_occultism: int  = recipe.get("occultism_level", req_alchemy)
	var alchemy: int        = int(player_skills.get("alchemy", 0))
	var occultism: int      = int(player_skills.get("occultism", 0))
	var can_craft: bool     = req_alchemy == 0 or alchemy >= req_alchemy or occultism >= req_occultism
	return {
		"can_craft":        can_craft,
		"required_level":   req_alchemy,
		"req_alchemy":      req_alchemy,
		"req_occultism":    req_occultism,
		"player_alchemy":   alchemy,
		"player_occultism": occultism,
	}

# Crafts an alchemy item — returns the result item dict (with player_made flag).
func craft_alchemy(recipe_id: String) -> Dictionary:
	var recipe: Dictionary = ALCHEMY_RECIPES.get(recipe_id, {})
	if recipe.is_empty():
		return {}
	var result: Dictionary = get_item(recipe.get("result_item", "")).duplicate(true)
	if result.is_empty():
		return {}
	result["player_made"] = true
	return result

# Returns whether the player can craft a Way of Beasts recipe given their current skills.
# craft_level scales as quality * 0.25 (Fine=4 is reference).
# hunter_taught recipes use survival only — no smithing required.
# Returns: {can_craft, required_survival, player_survival, hunter_taught}
func check_craft_skill(recipe_id: String, quality: int, player_skills: Dictionary) -> Dictionary:
	var recipe: Dictionary     = RECIPES.get(recipe_id, {})
	var craft_level: int       = recipe.get("craft_level", 0)
	var hunter_taught: bool    = recipe.get("hunter_taught", false)
	var required: int          = int(ceil(craft_level * quality * 0.25))
	var req_survival: int      = int(ceil(required * 0.6)) if hunter_taught else -1
	# Hunter-taught floor: survival >= 10
	if hunter_taught:
		req_survival = maxi(req_survival, 10)
	var player_survival: int   = int(player_skills.get("survival", 0))
	var can_craft: bool        = craft_level == 0
	if not can_craft and hunter_taught:
		can_craft = player_survival >= req_survival
	elif not can_craft:
		# Non-hunter recipes fall back to smithing
		var player_smithing: int = int(player_skills.get("smithing", 0))
		can_craft = player_smithing >= required
	return {
		"can_craft":          can_craft,
		"required_crafting":  required,
		"required_survival":  req_survival,
		"player_crafting":    int(player_skills.get("smithing", 0)),
		"player_survival":    player_survival,
		"hunter_taught":      hunter_taught,
	}

# Generates a crafted trophy item from a recipe and a materials dict.
# materials: { material_type: item_dict }  — first required_materials entry = primary (sets quality).
# Buff values scale linearly with quality (multiplier = quality * 0.25).
func craft_trophy(recipe_id: String, materials: Dictionary) -> Dictionary:
	var recipe: Dictionary = RECIPES.get(recipe_id, {})
	if recipe.is_empty():
		return {}
	var primary_type: String = recipe.get("required_materials", [""])[0]
	var material: Dictionary = materials.get(primary_type, {})
	if material.is_empty():
		return {}
	var quality: int       = material.get("quality", 0)
	var beast_src: String  = material.get("beast_source", "unknown")
	var mult: float        = quality * 0.25
	var prefix: String     = _QUALITY_PREFIXES[quality]

	var mat_type: String  = material.get("material_type", "")
	var bb: Dictionary    = BEAST_MATERIAL_BUFFS.get(beast_src, {}).get(mat_type, {})
	var mat_label: String = _mat_display(mat_type)
	var item_type: String = recipe.get("item_type_name", "Trophy")

	var item: Dictionary = {
		"id":              "%s_%s_%s" % [beast_src, mat_type, recipe_id],
		"name":            "%s%s %s %s" % [prefix, beast_src.capitalize(), mat_label, item_type],
		"type":            "trinket",
		"slot":            recipe["slot"],
		"trophy_type":     recipe["trophy_type"],
		"beast_source":    beast_src,
		"mat_type":        mat_type,
		"spirit_ward":     recipe.get("spirit_ward", false),
		"quality":         quality,
		"quality_name":    _QUALITY_NAMES[quality],
		"weight":          recipe.get("weight", 0.5),
		"defense_flat":    0.0,
		"defense_pct":     0.0,
		"skill_bonus":     {},
		"governing_bonus": {},
		"carry_weight_bonus": 0,
	}

	if bb.has("defense_pct"):
		item["defense_pct"] = bb["defense_pct"] * mult
	if bb.has("defense_flat"):
		item["defense_flat"] = bb["defense_flat"] * mult
	if bb.has("skill_bonus"):
		var sb: Dictionary = {}
		for skill in bb["skill_bonus"]:
			sb[skill] = bb["skill_bonus"][skill] * mult
		item["skill_bonus"] = sb
	if bb.has("governing_bonus"):
		var gb: Dictionary = {}
		for stat in bb["governing_bonus"]:
			gb[stat] = bb["governing_bonus"][stat] * mult
		item["governing_bonus"] = gb

	item["description"] = _craft_trophy_desc(recipe, item, quality)
	return item

func _craft_trophy_desc(recipe: Dictionary, item: Dictionary, quality: int) -> String:
	var lines: PackedStringArray = [
		recipe.get("lore", ""),
		"",
		"Quality: %s" % _QUALITY_NAMES[quality],
		"Spirit Ward (level 0) — allows rest in the city only.",
	]
	if item["defense_pct"] > 0.0:
		lines.append("Armor: +%.1f%%" % (item["defense_pct"] * 100.0))
	if item["defense_flat"] > 0.0:
		lines.append("Flat armor: +%.2f" % item["defense_flat"])
	for skill in item["skill_bonus"]:
		lines.append("%s: +%.2f" % [skill.capitalize(), item["skill_bonus"][skill]])
	for stat in item["governing_bonus"]:
		lines.append("Governing bonus (%s, melee to-hit): +%.2f" % [stat.capitalize(), item["governing_bonus"][stat]])
	return "\n".join(lines)

# Returns a formatted description of a recipe's effects at all quality tiers (for crafting preview).
func get_recipe_preview(recipe_id: String, primary_material: Dictionary) -> String:
	var recipe: Dictionary = RECIPES.get(recipe_id, {})
	if recipe.is_empty():
		return "—"
	var primary_type: String = recipe.get("required_materials", [""])[0]
	var crafted: Dictionary = craft_trophy(recipe_id, {primary_type: primary_material})
	if crafted.is_empty():
		return "—"
	return crafted.get("description", "—")

# ── Carving ───────────────────────────────────────────────────────────────────
# Quality tiers: 0=Ruined 1=Poor 2=Common 3=Good 4=Fine 5=Pristine
# Each loot_pool entry: {material, min_roll, base_quality, quality_step}
# Final quality = clamp(base_quality + (roll - min_roll) / quality_step + beast_quality_mod, 0, 5)

# Maps recipe slot names to the material types that can fill them.
# Add new entries here as new beasts and materials are introduced.
# Later-game materials may carry higher per-recipe craft_level overrides (future).
const MATERIAL_GROUPS: Dictionary = {
	"hide":    ["pelt", "skin"],          # coyote pelt, lizard skin, etc.
	"bones":   ["bones"],                 # all bones — listed explicitly so group logic is uniform
	"fangs":   ["fangs", "mandibles"],    # sharp/hard striking parts — fangs give melee bonus, mandibles give defense bonus
	"protein": ["meat", "tuber"],         # pottage's primary slot — meat (incl. fish) or a starchy tuber
	"scraps":  ["tuber", "vegetable"],    # pottage's optional slots — root or greens, but not a second cut of meat
}

# Returns the slot name from required_slots that accepts mat_type, or "" if none.
# Checks direct matches first, then group membership.
func resolve_material_slot(mat_type: String, required_slots: Array) -> String:
	if mat_type in required_slots:
		return mat_type
	for slot in required_slots:
		if mat_type in MATERIAL_GROUPS.get(slot, []):
			return slot
	return ""

# Returns a human-readable label for a recipe slot, listing accepted alternatives.
# e.g. "hide" → "Hide  (pelt / skin)"
func slot_display_name(slot: String) -> String:
	var group: Array = MATERIAL_GROUPS.get(slot, [])
	if group.is_empty() or (group.size() == 1 and group[0] == slot):
		return slot.capitalize()
	return "%s  (%s)" % [slot.capitalize(), " / ".join(group)]

# ── Smithing recipes ──────────────────────────────────────────────────────────
# Metal quality: quality_value float 0.0-1.0 (1.0 = reference / "Fine").
# Quality scales defense_flat and defense_pct stats on the crafted item.
# Magical properties (spirit_ward, armor_ignore_pct, all_resist, harms_intangible) are always full.
# smithing_level: minimum smithing skill required; 0 = always craftable if taught.
const SMITHING_RECIPES: Dictionary = {
	"bronze_spirit_armband": {
		"id":               "bronze_spirit_armband",
		"name":             "Bronze Spirit Armband",
		"category":         "smithing",
		"required_material": "ancient_bronze_scrap",
		"result_base": {
			"id":          "bronze_spirit_armband",
			"name":        "Bronze Spirit Armband",
			"type":        "trinket",
			"slot":        "upper_arm",
			"spirit_ward": true,
			"spirit_ward_level": 0,
			"defense_flat": 0.0,
			"defense_pct":  0.04,
			"all_resist":   0.0,
			"properties":   [],
			"weight":       0.3,
		},
		"lore":            "A band of worked bronze worn on the upper arm. Channels ambient spirit energy and holds it against the skin.",
		"smithing_level":  0,
	},
	"bronze_shortsword_blessed": {
		"id":               "bronze_shortsword_blessed",
		"name":             "Blessed Bronze Shortsword",
		"category":         "smithing",
		"required_material": "ancient_bronze_scrap",
		"result_base": {
			"id":                "bronze_shortsword_blessed",
			"name":              "Blessed Bronze Shortsword",
			"type":              "weapon",
			"slot":              "hand_1",
			"damage":            "1d6",
			"ap_cost":           3,
			"range":             1,
			"damage_type":       "physical",
			"skill":             "melee",
			"governing":         ["strength", "dexterity"],
			"armor_ignore_pct":  0.20,
			"harms_intangible":  true,
			"defense_flat":      0.0,
			"properties":        ["blessed_weapon"],
			"weight":            1.5,
		},
		"lore":            "A short blade worked with metal-prayer. Something about it feels wrong to spirits.",
		"smithing_level":  0,
	},
	"bronze_helmet_barrier": {
		"id":               "bronze_helmet_barrier",
		"name":             "Barrier Bronze Helmet",
		"category":         "smithing",
		"required_material": "ancient_bronze_scrap",
		"result_base": {
			"id":           "bronze_helmet_barrier",
			"name":         "Barrier Bronze Helmet",
			"type":         "armor",
			"slot":         "head",
			"defense_flat":  1.5,
			"defense_pct":   0.03,
			"all_resist":    0.05,
			"properties":    ["barrier_armor"],
			"weight":        1.5,
		},
		"lore":            "A bronze cap hammered with concentric rings. Each layer deflects a little of everything.",
		"smithing_level":  0,
	},
}

func get_smithing_recipe(id: String) -> Dictionary:
	return SMITHING_RECIPES.get(id, {})

# Maps a metal quality_value float to a display label.
func metal_quality_name(quality: float) -> String:
	if quality < 0.2:  return "Corroded"
	if quality < 0.4:  return "Degraded"
	if quality < 0.6:  return "Standard"
	if quality < 0.8:  return "Quality"
	if quality < 1.0:  return "Fine"
	return "Exceptional"

# Crafts a smithing item from a recipe and a metal material dict.
# Scales defense_flat and defense_pct by quality_value; other stats are fixed.
func craft_smithing(recipe_id: String, material: Dictionary) -> Dictionary:
	var recipe: Dictionary = SMITHING_RECIPES.get(recipe_id, {})
	if recipe.is_empty():
		return {}
	var quality: float     = material.get("quality_value", 0.5)
	var q_name: String     = metal_quality_name(quality)
	var base: Dictionary   = recipe.get("result_base", {}).duplicate(true)
	base["defense_flat"]   = base.get("defense_flat", 0.0) * quality
	base["defense_pct"]    = base.get("defense_pct",  0.0) * quality
	base["player_made"]    = true
	base["quality_value"]  = quality
	base["quality_name"]   = q_name
	if quality < 1.0:
		base["name"] = "%s %s" % [q_name, recipe.get("result_base", {}).get("name", "?")]
	base["description"]    = _craft_smithing_desc(recipe, base)
	return base

func _craft_smithing_desc(recipe: Dictionary, item: Dictionary) -> String:
	var lines: PackedStringArray = [recipe.get("lore", "")]
	lines.append("")
	lines.append("Quality: %s (%.0f%%)" % [item.get("quality_name", "?"), item.get("quality_value", 0.5) * 100.0])
	if item.get("spirit_ward", false):
		lines.append("Spirit Ward (level 0) — allows rest in the city.")
	if item.get("defense_pct", 0.0) > 0.0:
		lines.append("Armor: +%.1f%%" % (item["defense_pct"] * 100.0))
	if item.get("defense_flat", 0.0) > 0.0:
		lines.append("Flat armor: +%.2f" % item["defense_flat"])
	if item.get("all_resist", 0.0) > 0.0:
		lines.append("All damage resistance: %.0f%%" % (item["all_resist"] * 100.0))
	if item.get("armor_ignore_pct", 0.0) > 0.0:
		lines.append("Armor ignore: %.0f%%" % (item["armor_ignore_pct"] * 100.0))
	if item.get("harms_intangible", false):
		lines.append("Can harm intangible enemies.")
	return "\n".join(lines)

# Checks whether the player meets the smithing skill requirement for a smithing recipe.
func check_smithing_skill(recipe_id: String, player_skills: Dictionary) -> Dictionary:
	var recipe: Dictionary = SMITHING_RECIPES.get(recipe_id, {})
	var required: int      = recipe.get("smithing_level", 0)
	var player_s: int      = int(player_skills.get("smithing", 0))
	var can_craft: bool    = required == 0 or player_s >= required
	return {
		"can_craft":        can_craft,
		"required_smithing": required,
		"player_smithing":  player_s,
	}

# ── Cooking / preservation recipes ───────────────────────────────────────────
# cooking_level: minimum cooking skill (0 = always craftable once known).
# survival_level: alternative gate for smoke_meat (either cooking OR survival qualifies).
# is_rest_recipe: if true, used at rest time rather than the crafting panel.
# required_materials: matched by material_type via resolve_material_slot (same as WoB).
const COOKING_RECIPES: Dictionary = {
	"simple_meal": {
		"id":                 "simple_meal",
		"name":               "Simple Meal",
		"lore":               "Any edible food, prepared plainly. Not skilled work, but it fills the stomach and lets you rest.",
		"required_materials": ["meat", "tuber", "vegetable"],
		"cooking_level":      0,
		"survival_level":     0,
		"is_rest_recipe":     true,
	},
	"sun_dry": {
		"id":                 "sun_dry",
		"name":               "Sun-Dry Meat",
		"lore":               "Slice it thin and leave it in the sun. No fire needed, just patience. Doesn't last as long as salt, but asks nothing of you but time.",
		"required_materials": ["meat"],
		"cooking_level":      10,
		"surface_only":       true,
		"produces":           "sun_dried",
		"expires_in_rests":   4,
	},
	"cure_meat": {
		"id":                 "cure_meat",
		"name":               "Cure Meat",
		"lore":               "Pack the meat in salt. Draws out the water, holds the rest. Keeps longer than anything sun-dried.",
		"required_materials": ["meat", "salt"],
		"cooking_level":      15,
		"produces":           "salt_cured",
		"expires_in_rests":   10,
	},
	"smoke_meat": {
		"id":                  "smoke_meat",
		"name":                "Smoke Meat",
		"lore":                "Hang it over a low, smoky fire and let it sit. Keeps as long as salt-curing, and the smoke works its way into the meat — whatever you cook it into later turns out better for it.",
		"required_materials":  ["meat"],
		"cooking_level":       8,
		"survival_level":      15,
		"produces":            "smoked",
		"expires_in_rests":    10,
		"cooking_potency_mult": 1.2,
	},
	"stick_roast": {
		"id":                 "stick_roast",
		"name":               "Stick Roast",
		"lore":               "Skewer it on a green stick and hold it over the flame until it's done. The oldest trick there is. Works with fresh or preserved meat or fish.",
		"required_materials": ["meat"],
		"cooking_level":      5,
		"is_rest_recipe":     true,
		"base_buff":          {"hp_pct": 0.05},
	},
	"ash_bake": {
		"id":                 "ash_bake",
		"name":               "Ash Bake",
		"lore":               "Pack it in wet clay or leaves and bury it in the embers. Nothing escapes — you get more out of what you have. Works with fresh or preserved meat or fish.",
		"required_materials": ["meat"],
		"cooking_level":      15,
		"is_rest_recipe":     true,
		"base_buff":          {"hp_pct": 0.07, "phys_dr_flat": 1.0},
	},
	"pottage": {
		"id":                 "pottage",
		"name":               "Pottage",
		"lore":               "Boil it low and slow with whatever scraps are at hand — meat or root, herbs if you've got them.",
		"required_materials": ["protein"],
		"optional_materials": ["scraps"],
		"optional_max":       2,
		"min_optional":       1,
		"cooking_level":      25,
		"is_rest_recipe":     true,
		"base_buff":          {"hp_pct": 0.10, "sp_pct": 0.05},
		"meatless_buff":      {"hp_pct": 0.05, "sp_pct": 0.10},
	},
}

func get_cooking_recipe(id: String) -> Dictionary:
	return COOKING_RECIPES.get(id, {})

# Returns whether the player meets the skill gate for a cooking recipe.
# smoke_meat accepts cooking >= 8 OR survival >= 15.
func check_cooking_skill(recipe_id: String, player_skills: Dictionary) -> Dictionary:
	var recipe: Dictionary  = COOKING_RECIPES.get(recipe_id, {})
	var req_cooking: int    = recipe.get("cooking_level", 0)
	var req_survival: int   = recipe.get("survival_level", -1)
	var player_c: int       = int(player_skills.get("cooking", 0))
	var player_s: int       = int(player_skills.get("survival", 0))
	var can_craft: bool     = req_cooking == 0
	if not can_craft:
		can_craft = player_c >= req_cooking
	if not can_craft and req_survival >= 0:
		can_craft = player_s >= req_survival
	return {
		"can_craft":       can_craft,
		"req_cooking":     req_cooking,
		"req_survival":    req_survival,
		"player_cooking":  player_c,
		"player_survival": player_s,
	}

# Produces a preserved or cooked food item from a recipe and a primary ingredient.
func craft_cooking(recipe_id: String, primary_item: Dictionary) -> Dictionary:
	var recipe: Dictionary = COOKING_RECIPES.get(recipe_id, {})
	if recipe.is_empty() or recipe.get("is_rest_recipe", false):
		return {}

	# ── Preservation recipe ───────────────────────────────────────────────────
	var prefix: String = recipe.get("produces", "preserved")
	var beast: String  = primary_item.get("beast_source", "")
	var display: String = primary_item.get("name", "Meat")
	var beast_table: Dictionary = CARVE_TABLES.get(beast, {})
	var beast_display: String = beast_table.get("display_name", display)
	var prefix_display: String
	match prefix:
		"sun_dried":  prefix_display = "Sun-Dried"
		"salt_cured": prefix_display = "Salt-Cured"
		_:            prefix_display = prefix.capitalize()
	var result: Dictionary = {
		"id":               "%s_%s_meat" % [prefix, beast],
		"name":             "%s %s Meat" % [prefix_display, beast_display],
		"type":             "material",
		"material_type":    "meat",
		"preservation":     prefix,
		"beast_source":     beast,
		"quality":          primary_item.get("quality", 1),
		"quality_name":     primary_item.get("quality_name", ""),
		"description":      "%s, preserved by %s." % [primary_item.get("description", "Meat."), prefix_display.to_lower()],
		"slot":             null,
		"weight":           primary_item.get("weight", 1.5),
		"uses_remaining":   primary_item.get("uses_remaining", 1),
		"max_uses":         primary_item.get("max_uses", 1),
		"expires_in_rests": recipe.get("expires_in_rests", 5),
		"player_made":      true,
	}
	# Salt-cured meat is a "higher level" preserved food — eating it plain at
	# rest (without cooking it into a recipe) grants a small passive buff.
	if prefix == "salt_cured":
		result["passive_meal_buff"] = {"id": "salted_provisions", "name": "Salted Provisions", "hp_pct": 0.03}
	# Smoked meat doesn't add its own buff, but makes whatever it's cooked into stronger.
	if recipe.has("cooking_potency_mult"):
		result["cooking_potency_mult"] = recipe["cooking_potency_mult"]
	return result

# ── Rest-time recipe ingredient bonuses ──────────────────────────────────────
# Keyed by beast_source (meat/fish) or item id (plants). Applied on top of a
# rest recipe's base_buff/meatless_buff by compute_meal_buff().
#   hp_pct_mult  — multiplies the recipe's hp_pct by a quality-scaled factor
#   mp_pct_mult  — adds an mp_pct to the buff equal to (factor - 1.0), quality-scaled
#   phys_dr_pct  — adds a quality-scaled flat physical damage-reduction percentage
#   stat_flat    — adds a flat amount to the named active_meal_buff stat key
const RECIPE_INGREDIENT_BONUSES: Dictionary = {
	"coyote":     {"type": "hp_pct_mult", "common": 1.25, "lo": 1.15, "hi": 1.35},
	"lizard":     {"type": "stat_flat",   "stat": "per_flat", "amount": 1},
	"tilapia":    {"type": "mp_pct_mult", "common": 1.25, "lo": 1.15, "hi": 1.35},
	"catfish":    {"type": "phys_dr_pct", "common": 0.10, "lo": 0.08, "hi": 0.12},
	"dates":       {"type": "stat_flat",   "stat": "agi_flat", "amount": 1},
	"wild_onion":  {"type": "stat_flat",   "stat": "wil_flat", "amount": 1},
	"sand_beetle": {"type": "stat_flat",   "stat": "phys_dr_flat", "amount": 1},
}

# Scales a quality-dependent value linearly around quality 2 ("Common"),
# stepping by (common - lo) / 2 per quality tier and clamping to [lo, hi].
# e.g. quality_scaled(0, 1.25, 1.15, 1.35) == 1.15; quality_scaled(2, ...) == 1.25
func quality_scaled(quality: int, common: float, lo: float, hi: float) -> float:
	var step: float = (common - lo) / 2.0
	return clampf(common + float(quality - 2) * step, lo, hi)

# Returns the RECIPE_INGREDIENT_BONUSES entry for an inventory item, or {} if none.
func get_ingredient_bonus(item: Dictionary) -> Dictionary:
	var beast: String = item.get("beast_source", "")
	var key: String = beast if beast != "" else item.get("id", "")
	return RECIPE_INGREDIENT_BONUSES.get(key, {})

# Computes the active_meal_buff dict for a rest recipe given its chosen
# ingredients. primary_item fills the recipe's first required slot; secondary_items
# are pottage's optional vegetable/herb additions (0-2). Ingredient bonuses stack.
func compute_meal_buff(recipe_id: String, primary_item: Dictionary, secondary_items: Array = []) -> Dictionary:
	var recipe: Dictionary = COOKING_RECIPES.get(recipe_id, {})
	if recipe.is_empty():
		return {}
	var is_meatless: bool = primary_item.get("material_type", "") == "tuber" and recipe.has("meatless_buff")
	var base: Dictionary = (recipe["meatless_buff"] if is_meatless else recipe.get("base_buff", {})).duplicate()
	var buff: Dictionary = {"id": recipe_id, "name": recipe.get("name", recipe_id.capitalize())}
	for k in base:
		buff[k] = base[k]

	for ing in ([primary_item] + secondary_items):
		var bonus: Dictionary = get_ingredient_bonus(ing)
		if bonus.is_empty():
			continue
		var quality: int = ing.get("quality", 2)
		match bonus.get("type", ""):
			"hp_pct_mult":
				if buff.has("hp_pct"):
					buff["hp_pct"] = buff["hp_pct"] * quality_scaled(quality, bonus["common"], bonus["lo"], bonus["hi"])
			"mp_pct_mult":
				buff["mp_pct"] = quality_scaled(quality, bonus["common"], bonus["lo"], bonus["hi"]) - 1.0
			"phys_dr_pct":
				buff["phys_dr_pct"] = quality_scaled(quality, bonus["common"], bonus["lo"], bonus["hi"])
			"stat_flat":
				var stat_key: String = bonus["stat"]
				buff[stat_key] = buff.get(stat_key, 0) + bonus["amount"]

	# Smoked meat (and any future ingredient marked the same way) makes the
	# resulting meal stronger across the board, not just its own bonus line.
	var potency: float = primary_item.get("cooking_potency_mult", 1.0)
	if potency != 1.0:
		for k in buff:
			if buff[k] is float or buff[k] is int:
				buff[k] = buff[k] * potency
	return buff

# Human-readable description lines for the numeric keys of an active/passive
# meal buff dict (hp_pct, sp_pct, mp_pct, hit_flat, phys_dr_flat, phys_dr_pct,
# per_flat, agi_flat, wil_flat). Used by the rest UI's cook preview, the eat
# panel's passive-buff line, and the status panel's active meal buff display.
func format_meal_buff_lines(buff: Dictionary) -> Array:
	var lines: Array = []
	if buff.has("hp_pct"):
		lines.append("+%d%% max HP" % int(round(buff["hp_pct"] * 100)))
	if buff.has("sp_pct"):
		lines.append("+%d%% max SP" % int(round(buff["sp_pct"] * 100)))
	if buff.has("mp_pct"):
		lines.append("+%d%% max MP" % int(round(buff["mp_pct"] * 100)))
	if buff.has("hit_flat"):
		lines.append("+%d%% to hit" % int(buff["hit_flat"]))
	if buff.has("phys_dr_flat"):
		lines.append("+%d flat physical damage reduction" % int(buff["phys_dr_flat"]))
	if buff.has("phys_dr_pct"):
		lines.append("+%d%% physical damage reduction" % int(round(buff["phys_dr_pct"] * 100)))
	if buff.has("per_flat"):
		lines.append("+%d Perception" % int(buff["per_flat"]))
	if buff.has("agi_flat"):
		lines.append("+%d Agility" % int(buff["agi_flat"]))
	if buff.has("wil_flat"):
		lines.append("+%d Willpower" % int(buff["wil_flat"]))
	return lines

const CARVE_TABLES: Dictionary = {
	"coyote": {
		"display_name": "Coyote",
		# Roll is 1d100 + effective survival skill.
		# min_roll=40: pass → bones + meat guaranteed together
		# min_roll=65: good roll also yields a pelt
		# min_roll=85: excellent roll also yields fangs
		# quality_step=15: every 15 points above min_roll = +1 quality tier (0=Ruined … 5=Pristine)
		"loot_pool": [
			{"material": "bones", "min_roll": 40, "base_quality": 1, "quality_step": 15},
			{"material": "meat",  "min_roll": 40, "base_quality": 1, "quality_step": 15},
			{"material": "pelt",  "min_roll": 65, "base_quality": 2, "quality_step": 15},
			{"material": "fangs", "min_roll": 85, "base_quality": 3, "quality_step": 15},
			{"material": "skull", "min_roll": 100, "base_quality": 4, "quality_step": 15},
		],
	},
	"adolescent_coyote": {
		"display_name": "Adolescent Coyote",
		"loot_pool": [
			{"material": "bones", "min_roll": 40, "base_quality": 1, "quality_step": 15},
			{"material": "meat",  "min_roll": 40, "base_quality": 1, "quality_step": 15},
			{"material": "pelt",  "min_roll": 60, "base_quality": 2, "quality_step": 15},
			{"material": "fangs", "min_roll": 80, "base_quality": 3, "quality_step": 15},
			{"material": "skull", "min_roll": 95, "base_quality": 4, "quality_step": 15},
		],
	},
	"lizard": {
		"display_name": "Lizard",
		# min_roll=40: bones (always recoverable on a decent roll)
		# min_roll=60: meat — small animal, easily damaged, harder to get clean meat
		# min_roll=65: skin — careful work needed to keep it intact
		# min_roll=70: acid gland — needs care but findable without high survival
		"loot_pool": [
			{"material": "bones",      "min_roll": 40,  "base_quality": 1, "quality_step": 15},
			{"material": "meat",       "min_roll": 60,  "base_quality": 1, "quality_step": 15},
			{"material": "skin",       "min_roll": 65,  "base_quality": 2, "quality_step": 15},
			{"material": "acid_gland", "min_roll": 70,  "base_quality": 3, "quality_step": 15},
		],
	},
	"sand_beetle": {
		"display_name": "Sand Beetle",
		# min_roll=40: meat — always available on a passable roll
		# min_roll=70: mandibles — hard chitin, need care not to crack them
		# min_roll=90: shell — intact shell plating is difficult to separate cleanly
		"loot_pool": [
			{"material": "meat",      "min_roll": 40, "base_quality": 1, "quality_step": 15},
			{"material": "mandibles", "min_roll": 70, "base_quality": 2, "quality_step": 15},
			{"material": "shell",     "min_roll": 90, "base_quality": 3, "quality_step": 15},
		],
	},
}

const _QUALITY_PREFIXES: Array = ["Ruined ", "Poor ", "", "Good ", "Fine ", "Pristine "]
const _QUALITY_NAMES: Array    = ["Ruined", "Poor", "Common", "Good", "Fine", "Pristine"]

func resolve_carve(beast_type: String, roll: int, quality_mod: int) -> Array:
	var table: Dictionary = CARVE_TABLES.get(beast_type, {})
	if table.is_empty():
		return []
	var display: String = table.get("display_name", beast_type.capitalize())
	var result: Array = []
	for entry in table.get("loot_pool", []):
		if roll < entry["min_roll"]:
			continue
		var excess: int   = roll - entry["min_roll"]
		var quality: int  = clampi(entry["base_quality"] + int(excess / entry["quality_step"]) + quality_mod, 0, 5)
		var prefix: String = _QUALITY_PREFIXES[quality]
		var mat: String    = entry["material"]
		var loot_item: Dictionary = {
			"id":           "%s_%s" % [beast_type, mat],
			"name":         "%s%s %s" % [prefix, display, _mat_display(mat)],
			"type":         "material",
			"material_type": mat,
			"beast_source": beast_type,
			"quality":      quality,
			"quality_name": _QUALITY_NAMES[quality],
			"description":  _carve_desc(mat, quality),
			"slot":         null,
			"weight":       _mat_weight(mat),
		}
		if mat == "meat":
			var uses: int = 2 if quality >= 4 else 1
			loot_item["uses_remaining"] = uses
			loot_item["max_uses"] = uses
			loot_item["expires_in_rests"] = 2
		result.append(loot_item)
	return result

func _mat_weight(mat: String) -> float:
	match mat:
		"bones":      return 1.0
		"meat":       return 1.5
		"pelt":       return 2.0
		"fangs":      return 0.5
		"skull":      return 1.5
		"skin":       return 1.2
		"acid_gland": return 0.4
		"mandibles":  return 0.4
		"shell":      return 2.5
	return 1.0

func _mat_display(mat: String) -> String:
	match mat:
		"bones":      return "Bones"
		"meat":       return "Meat"
		"pelt":       return "Pelt"
		"fangs":      return "Fangs"
		"skull":      return "Skull"
		"skin":       return "Skin"
		"acid_gland": return "Acid Gland"
		"mandibles":  return "Mandibles"
		"shell":      return "Shell"
	return mat.capitalize()

func _carve_desc(mat: String, q: int) -> String:
	match mat:
		"pelt":
			return ["Badly torn. Barely recognizable.", "Poorly removed, damaged in places.",
				"Adequately harvested. Serviceable.", "Carefully removed and mostly intact.",
				"Cleanly harvested. Excellent condition.", "Expertly prepared. Every hair in place."][q]
		"meat":
			return ["Ruined. Not fit to eat.", "Roughly cut. Edible but poor.",
				"Standard cuts. Acceptable.", "Good cuts with little waste.",
				"Carefully butchered. Choice portions.", "Pristine cuts. A skilled hand at work."][q]
		"bones":
			return ["Shattered fragments. Useless.", "Cracked and rough. Barely usable.",
				"Intact bones, roughly cleaned.", "Clean and solid.",
				"Well-prepared. Strong and smooth.", "Perfectly extracted. Ideal for craft or adornment."][q]
		"fangs":
			return ["Broken at the root. Worthless.", "Chipped and rough.",
				"Intact but unimpressive.", "Clean and sharp.",
				"Excellent. Sharp and fully intact.", "Perfect specimens. Razor sharp."][q]
		"skull":
			return ["Shattered. Beyond use.", "Cracked badly. Barely holds together.",
				"Intact but rough. Could be worked.", "Clean and solid. Good material.",
				"Well-prepared. Strong and undamaged.", "Perfect. Every tooth in place."][q]
		"skin":
			return ["Torn beyond use. Riddled with holes.", "Poorly removed, stiff and cracked.",
				"Intact but rough. Workable with care.", "Clean and supple. Good material.",
				"Carefully peeled. Flexible and intact.", "Flawless. Not a nick in it."][q]
		"acid_gland":
			return ["Ruptured. The acid has eaten through everything.", "Damaged. Most of the contents lost.",
				"Intact but handled roughly. Something inside still moves.", "Sealed and solid. Handle carefully.",
				"Perfectly extracted. The sac is full and undamaged.", "Pristine. Not a drop spilled."][q]
		"mandibles":
			return ["Shattered at the joint. Useless fragments.", "Cracked and brittle. Barely intact.",
				"Intact but roughly handled. Some surface chipping.", "Clean and hard. Good material.",
				"Carefully extracted. Smooth and fully intact.", "Perfect specimens. Not a crack in the chitin."][q]
		"shell":
			return ["Smashed beyond salvage.", "Cracked through. Only the smallest fragments hold.",
				"Intact but badly chipped. Workable with effort.", "Solid plating, mostly clean.",
				"Well-separated. Broad sections fully intact.", "Flawless. The full dorsal plate in one piece."][q]
	return ""

# ── Fishing ───────────────────────────────────────────────────────────────────
# Roll is 1d100 + effective survival skill.
# min_roll=40: a fish bites at all — below this, the line comes back empty.
# quality_step=15: every 15 points above min_roll = +1 quality tier (0=Ruined … 5=Pristine)
const FISH_TABLES: Dictionary = {
	"river": {
		"min_roll": 40,
		"base_quality": 1,
		"quality_step": 15,
		"species": [
			{"id": "tilapia", "weight": 65},
			{"id": "catfish", "weight": 35},
		],
	},
}

# Returns {} on a failed catch, otherwise a quality-tiered copy of the caught fish item.
func resolve_fish(table_id: String, roll: int, quality_mod: int) -> Dictionary:
	var table: Dictionary = FISH_TABLES.get(table_id, {})
	if table.is_empty() or roll < int(table["min_roll"]):
		return {}
	var excess: int  = roll - int(table["min_roll"])
	var quality: int = clampi(int(table["base_quality"]) + int(excess / int(table["quality_step"])) + quality_mod, 0, 5)

	var species: Array = table.get("species", [])
	var total_weight: int = 0
	for s in species:
		total_weight += int(s.get("weight", 1))
	var pick: int = randi_range(1, total_weight)
	var chosen_id: String = ""
	for s in species:
		pick -= int(s.get("weight", 1))
		if pick <= 0:
			chosen_id = s.get("id", "")
			break

	var fish: Dictionary = get_item(chosen_id)
	if fish.is_empty():
		return {}
	fish["name"] = "%s%s" % [_QUALITY_PREFIXES[quality], fish.get("name", "")]
	fish["quality"] = quality
	fish["quality_name"] = _QUALITY_NAMES[quality]
	fish["description"] = _fish_desc(quality)
	if quality >= 4:
		fish["uses_remaining"] = 2
		fish["max_uses"] = 2
	return fish

func _fish_desc(q: int) -> String:
	return ["Ruined. The flesh has spoiled — not fit to eat.",
		"Battered and bruised. Edible, but unappetizing.",
		"A common river fish, freshly caught.",
		"A good catch, firm and fresh.",
		"An excellent catch — plump and perfectly fresh.",
		"A pristine specimen. Worth showing off before it's cooked."][q]

# ── Item helpers ──────────────────────────────────────────────────────────────

# Returns a fresh copy of an item by ID (safe to store in equipment/inventory).
func get_item(id: String) -> Dictionary:
	return items.get(id, {}).duplicate(true)

# ── Item definitions ──────────────────────────────────────────────────────────
# type:       "weapon" | "armor" | "clothing" | "tool" | "ammo"
# slot:       "hand" | "head" | "body" | "legs" | "feet" | "hands" | "back" | null (inventory-only)
# governing:  stats used for hit roll AND damage bonus (uses highest modifier)
# properties: passive tags checked by combat system
# abilities:  active abilities granted while equipped
#
# Armor fields:
#   defense_flat (int)  — subtracted from raw damage before percentage
#   defense_pct  (float) — e.g. 0.06 for 6%; stacks multiplicatively across slots
#
# Weapon fields:
#   damage      (String) — dice expression e.g. "1d8"
#   ap_cost     (int)    — AP to attack
#   range       (int)    — max tile range
#   skill       (String) — "melee" | "ranged"
#   reload_cost (int)    — AP to reload (for weapons requiring reload)
#   throw_range (int)    — range when thrown from inventory (knife)
#
# Bonus fields:
#   skill_bonus         (Dictionary) — e.g. {"sneak": 3}
#   governing_bonus     (Dictionary) — e.g. {"melee": 1} raises the governing stat modifier
#                                      used in effective-skill (to-hit only, not damage)
#   carry_weight_bonus  (int)
#
# Trinket fields (type = "trinket"):
#   spirit_ward  (bool)  — grants minimum spiritual protection to sleep in the city
#   All armor/bonus fields apply; slot is a valid equipment slot (head, necklace, etc.)

func _load_items() -> void:
	# ── Weapons ──────────────────────────────────────────────────────────────

	items["unarmed"] = {
		"id": "unarmed", "weight": 0.1, "name": "Unarmed", "type": "weapon", "slot": null,
		"description": "A bare-knuckle strike.",
		"damage": "1d3", "ap_cost": 2, "range": 1,
		"skill": "melee", "governing": ["strength", "dexterity"],
		"damage_type": "physical",
		"properties": [], "abilities": [],
		# DEX only contributes half its modifier to damage (speed ≠ power for bare hands)
		"half_dex_damage": true,
	}

	items["knife"] = {
		"id": "knife", "weight": 1.0, "name": "Simple Stone Knife", "type": "weapon", "slot": "hand",
		"description": "A crudely knapped stone blade hafted with sinew. Light enough to throw.",
		"damage": "1d4", "ap_cost": 2, "range": 1,
		"skill": "melee", "governing": ["strength", "dexterity"],
		"damage_type": "physical",
		"properties": ["bleed", "thrown"], "abilities": [],
		"throw_range": 12,
		"point_blank": "disadvantage",  # thrown at melee range: roll to-hit twice, take worse
	}

	items["shortsword"] = {
		"id": "shortsword", "weight": 2.5, "name": "Bronze Shortsword", "type": "weapon", "slot": "hand",
		"description": "A compact bronze blade. Heavier than iron would be, but well-shaped and reliably sharp.",
		"damage": "1d6+3", "ap_cost": 3, "range": 1,
		"skill": "melee", "governing": ["strength", "dexterity"],
		"damage_type": "physical",
		"properties": ["bleed"], "abilities": [],
	}

	items["scimitar"] = {
		"id": "scimitar", "weight": 2.5, "name": "Scimitar", "type": "weapon", "slot": "hand",
		"description": "",
		"damage": "1d6", "ap_cost": 2, "range": 1,
		"skill": "melee", "governing": ["strength", "dexterity"],
		"damage_type": "physical",
		"properties": ["bleed"], "abilities": [],
	}

	items["spear"] = {
		"id": "spear", "weight": 4.0, "name": "Wooden Spear", "type": "weapon", "slot": "hand",
		"description": "A long hardwood shaft sharpened to a point and fire-hardened. Keeps enemies at distance.",
		"damage": "1d4", "ap_cost": 3, "range": 2,
		"skill": "melee", "governing": ["strength", "dexterity"],
		"damage_type": "physical",
		"properties": [], "abilities": [],
	}

	items["bronze_spear"] = {
		"id": "bronze_spear", "weight": 4.0, "name": "Bronze Spear", "type": "weapon", "slot": "hand",
		"description": "A long hardwood shaft tipped with a cast bronze point. Standard issue for soldiers.",
		"damage": "1d6+1", "ap_cost": 3, "range": 2,
		"skill": "melee", "governing": ["strength", "dexterity"],
		"damage_type": "physical", "properties": [], "abilities": [],
	}

	items["stone_axe"] = {
		"id": "stone_axe", "weight": 5.0, "name": "Stone Axe", "type": "weapon", "slot": "hand",
		"description": "A heavy stone head lashed to a wooden haft. Crude but punishing. The weight of it works through light armor.",
		"damage": "1d6", "ap_cost": 3, "range": 1,
		"skill": "melee", "governing": ["strength"],
		"damage_type": "physical",
		"properties": ["armor_pierce_light"], "abilities": [],
	}

	items["whip"] = {
		"id": "whip", "weight": 1.5, "name": "Whip", "type": "weapon", "slot": "hand",
		"description": "A long leather whip. Painful, and useful for disarming.",
		"damage": "1d3", "ap_cost": 2, "range": 3,
		"skill": "melee", "governing": ["dexterity"],
		"damage_type": "physical",
		"properties": [], "abilities": ["disarm"],
	}

	items["sword"] = {
		"id": "sword", "weight": 4.0, "name": "Bronze Sword", "type": "weapon", "slot": "hand",
		"description": "A full-length bronze blade, double-edged and well-balanced. The mark of a serious fighter.",
		"damage": "1d8+3", "ap_cost": 3, "range": 1,
		"skill": "melee", "governing": ["strength", "dexterity"],
		"damage_type": "physical",
		"properties": ["bleed"], "abilities": [],
	}

	items["axe"] = {
		"id": "axe", "weight": 6.0, "name": "Bronze Axe", "type": "weapon", "slot": "hand",
		"description": "A heavy axe head cast in bronze, mounted on a hardwood haft. Punches through armor.",
		"damage": "1d10", "ap_cost": 4, "range": 1,
		"skill": "melee", "governing": ["strength"],
		"damage_type": "physical",
		# heavy_weapon: strength's contribution to this weapon's damage roll is doubled.
		"properties": ["armor_pierce", "heavy_weapon"], "abilities": [],
	}

	items["sling"] = {
		"id": "sling", "weight": 0.3, "name": "Sling", "type": "weapon", "slot": "hand",
		"description": "A leather strap for hurling stones. Cheap, silent, and effective at range. No special ammunition needed — any loose stone will do.",
		"damage": "1d3", "ap_cost": 3, "range": 12,
		"skill": "ranged", "governing": ["dexterity", "strength"],
		"damage_type": "physical",
		"properties": [], "abilities": [],
		"point_blank": "blocked",
	}

	items["shortbow"] = {
		"id": "shortbow", "weight": 2.0, "name": "Shortbow", "type": "weapon", "slot": "hand",
		"description": "A compact bow, quick to draw and easy to carry.",
		"damage": "1d6", "ap_cost": 3, "range": 18,
		"skill": "ranged", "governing": ["dexterity"],
		"damage_type": "physical",
		"properties": [], "abilities": [],
		"ammo": "quiver",
		"point_blank": "blocked",   # cannot fire when an enemy is adjacent
	}

	items["longbow"] = {
		"id": "longbow", "weight": 3.0, "name": "Longbow", "type": "weapon", "slot": "hand",
		"description": "A powerful bow with exceptional range.",
		"damage": "1d8", "ap_cost": 4, "range": 24,
		"skill": "ranged", "governing": ["dexterity"],
		"damage_type": "physical",
		"properties": [], "abilities": [],
		"ammo": "quiver",
		"point_blank": "blocked",   # cannot fire when an enemy is adjacent
	}

	# ── Pyromancy spells ─────────────────────────────────────────────────────
	# Spell "weapons" — not equippable in hand slots, used via the spell bar.
	# spirit_cost: deducted from current_spirit before the attack fires.
	# "melee_type": true means future melee feats apply to this spell.

	items["burning_palm"] = {
		"id": "burning_palm", "name": "Burning Palm", "type": "spell",
		"description": "Channel fire through an open palm. Deals unarmed damage plus 1d6 + Willpower fire damage. Requires a free hand. Uses Melee skill to hit.\nCosts 2 SP and 2 AP. Chance to apply Burning (4 turns, 1d4 fire/turn).",
		"damage": "0", "ap_cost": 2, "range": 1,
		"spirit_cost": 2,
		"skill": "melee", "governing": [],
		"damage_type": "physical",
		"bonus_fire_damage": "1d6",
		"properties": ["burning", "use_melee_weapon_damage"], "abilities": [],
		"weight": 0.0,
	}

	items["heat"] = {
		"id": "heat", "name": "Heat", "type": "spell",
		"description": "A ranged spell that applies a Heated stack (fire damage each turn, ignores 40%% fire resistance). Uses Occultism to hit; resisted by Constitution.\nCosts 4 SP and 2 AP. Range: 14. Stacks can trigger Burning.",
		"damage": "0", "ap_cost": 2, "range": 14,
		"spirit_cost": 4,
		"skill": "occultism", "governing": ["willpower"],
		"damage_type": "fire",
		"resistance": "constitution",
		"properties": ["heated", "effect_only"], "abilities": [],
		"point_blank": "",
		"weight": 0.0,
	}

	# ── Ammo ─────────────────────────────────────────────────────────────────

	items["quiver"] = {
		"id": "quiver", "weight": 1.5, "name": "Quiver", "type": "ammo", "slot": "back",
		"description": "A quiver of arrows. Bottomless for now.",
		"properties": [], "abilities": [],
	}

	# ── Tools (inventory-only for now) ────────────────────────────────────────

	items["hide_shield"] = {
		"id": "hide_shield", "weight": 2.0, "name": "Hide Shield", "type": "armor", "slot": "hand",
		"description": "A frame of bent wood stretched with thick hide. Light, but takes the worst out of a blow — if you get it up in time.",
		"block_flat": 4, "governing": ["strength", "dexterity"],
		"skill_bonus": {"sneak": -3, "dodge": -3}, "carry_weight_bonus": 0,
	}

	items["wooden_shield"] = {
		"id": "wooden_shield", "weight": 4.0, "name": "Wooden Shield", "type": "armor", "slot": "hand",
		"description": "A sturdy wooden shield. Blocks a meaningful amount of damage but leaves only one hand free — if you get it up in time.",
		"block_flat": 6, "governing": ["strength", "dexterity"],
		"skill_bonus": {"sneak": -8, "dodge": -8}, "carry_weight_bonus": 0,
	}

	items["lockpicking_kit"] = {
		"id": "lockpicking_kit", "weight": 0.5, "name": "Lockpicking Kit", "type": "tool", "slot": null,
		"description": "A set of fine picks and tension wrenches.",
		"properties": [], "abilities": [],
	}

	items["torch"] = {
		"id": "torch", "weight": 1.0, "name": "Torch", "type": "tool", "slot": "hand",
		"description": "A pitch-soaked length of wood, bound and lit. Casts a steady ring of light.",
		"light_source": true,
		"properties": [], "abilities": [],
	}

	items["desert_shawl"] = {
		"id": "desert_shawl", "weight": 1.0, "name": "Desert Shawl", "type": "tool", "slot": "back",
		"description": "A wide cloth wrap that shields from sun and sand. (Desert mechanics TBD.)",
		"properties": [], "abilities": [],
	}

	items["shovel"] = {
		"id": "shovel", "weight": 3.0, "name": "Shovel", "type": "tool", "slot": null,
		"description": "A sturdy iron shovel.",
		"properties": [], "abilities": [],
	}

	items["rope"] = {
		"id": "rope", "weight": 1.5, "name": "Rope", "type": "tool", "slot": null,
		"description": "Thirty feet of tough rope.",
		"properties": [], "abilities": [],
	}

	items["archaeology_kit"] = {
		"id": "archaeology_kit", "weight": 1.0, "name": "Archaeology Kit", "type": "tool", "slot": null,
		"description": "Brushes, picks, and measuring tools for careful excavation.",
		"properties": [], "abilities": [],
	}

	items["tinkering_tools"] = {
		"id": "tinkering_tools", "weight": 1.0, "name": "Tinkering Tools", "type": "tool", "slot": null,
		"description": "A compact set of precision tools for working with mechanisms and devices.",
		"properties": [], "abilities": [],
	}

	items["brewers_kit"] = {
		"id": "brewers_kit", "weight": 2.0, "name": "Brewer's Kit", "type": "tool", "slot": null,
		"description": "Vials, measures, and a compact burner for mixing compounds.",
		"properties": [], "abilities": [],
	}

	items["salt"] = {
		"id": "salt", "weight": 0.3, "name": "Salt", "type": "material",
		"material_type": "salt",
		"description": "Coarse mineral salt, gathered from the riverbank deposits where the desert heat draws moisture to the surface.",
		"slot": null, "properties": [], "abilities": [],
	}

	items["fishing_rod"] = {
		"id": "fishing_rod", "weight": 2.0, "name": "Fishing Rod", "type": "tool", "slot": null,
		"description": "A simple rod of river cane with a line and hook. Activate at disturbed water to fish.",
		"properties": [], "abilities": [],
	}

	# ── Quest items ───────────────────────────────────────────────────────────

	items["coin"] = {
		"id":          "coin",
		"name":        "Coin",
		"type":        "currency",
		"slot":        null,
		"weight":      0.05,
		"description": "A small metal coin.",
		"properties": [], "abilities": [],
	}

	items["small_pouch"] = {
		"id":          "small_pouch",
		"name":        "Small Pouch",
		"type":        "quest_item",
		"slot":        null,
		"weight":      0.2,
		"description": "A small cloth pouch sealed with twine. The apothecary asked you to deliver this to the keeper of the rest house north of here.",
		"properties": [], "abilities": [],
	}

	# ── Smithing materials ───────────────────────────────────────────────────

	items["ancient_bronze_scrap"] = {
		"id": "ancient_bronze_scrap", "name": "Ancient Bronze Scrap", "type": "material",
		"material_type": "metal", "slot": null, "weight": 0.5,
		"uses": 2, "max_uses": 2, "quality_value": 0.5, "quality_name": "Standard",
		"description": "A lump of corroded bronze salvaged from the ruins of the old city below. Still workable if you know what you're doing.\n\nQuality: Standard (50%)\nUses: 2",
		"properties": [], "abilities": [],
	}

	items["bandit_leader_head"] = {
		"id": "bandit_leader_head", "name": "Bandit Leader's Head", "type": "material",
		"slot": null, "weight": 2.0,
		"description": "Grim proof that the bandit camp's leader is dead.",
		"properties": [], "abilities": [],
	}

	# ── Smithed items (static fallback; craft_smithing() generates quality-scaled versions) ──

	items["bronze_spirit_armband"] = {
		"id": "bronze_spirit_armband", "name": "Bronze Spirit Armband", "type": "trinket",
		"slot": "upper_arm", "spirit_ward": true, "spirit_ward_level": 0,
		"defense_flat": 0.0, "defense_pct": 0.02, "all_resist": 0.0, "weight": 0.3,
		"description": "A band of worked bronze worn on the upper arm. Channels ambient spirit energy.\n\nSpirit Ward (level 0) — allows rest in the city.\nArmor: +2.0%",
		"properties": [], "abilities": [],
	}

	items["bronze_shortsword_blessed"] = {
		"id": "bronze_shortsword_blessed", "name": "Blessed Bronze Shortsword", "type": "weapon",
		"slot": "hand_1", "damage": "1d6", "ap_cost": 3, "range": 1,
		"skill": "melee", "governing": ["strength", "dexterity"], "damage_type": "physical",
		"armor_ignore_pct": 0.20, "harms_intangible": true, "weight": 1.5, "defense_flat": 0.0,
		"description": "A short blade worked with metal-prayer. Something about it feels wrong to spirits.\n\nArmor ignore: 20%\nCan harm intangible enemies.",
		"properties": ["blessed_weapon"], "abilities": [],
	}

	items["bronze_helmet_barrier"] = {
		"id": "bronze_helmet_barrier", "name": "Barrier Bronze Helmet", "type": "armor",
		"slot": "head", "defense_flat": 0.75, "defense_pct": 0.015, "all_resist": 0.05, "weight": 1.5,
		"description": "A bronze cap hammered with concentric rings. Each layer deflects a little of everything.\n\nFlat armor: +0.75\nArmor: +1.5%\nAll damage resistance: 5%",
		"properties": ["barrier_armor"], "abilities": [],
	}

	# ── Harvestable plants ────────────────────────────────────────────────────

	items["dusk_flower"] = {
		"id": "dusk_flower", "name": "Dusk Flower", "type": "material",
		"material_type": "plant", "slot": null, "weight": 0.05,
		"description": "A darkly colored flower found growing by the river. Its petals are a deep, bruised purple.",
		"properties": [], "abilities": [],
	}

	items["desert_succulent"] = {
		"id": "desert_succulent", "name": "Desert Succulent", "type": "material",
		"material_type": "plant", "slot": null, "weight": 0.05,
		"description": "A small waxy succulent from the desert. Stores moisture in its thick leaves.",
		"properties": [], "abilities": [],
	}

	items["dates"] = {
		"id": "dates", "name": "Dates", "type": "material",
		"material_type": "vegetable", "slot": null, "weight": 0.1,
		"uses_remaining": 1, "max_uses": 1,
		"description": "Sweet, sticky dates from a desert palm. Worth holding onto — they're hard to find.",
		"properties": [], "abilities": [],
	}

	items["wild_onion"] = {
		"id": "wild_onion", "name": "Wild Onion", "type": "material",
		"material_type": "vegetable", "slot": null, "weight": 0.1,
		"uses_remaining": 1, "max_uses": 1,
		"description": "A pungent bulb growing in scattered clusters near the river.",
		"properties": [], "abilities": [],
	}

	items["reed_tuber"] = {
		"id": "reed_tuber", "name": "Reed Tuber", "type": "material",
		"material_type": "tuber", "slot": null, "weight": 0.2,
		"uses_remaining": 1, "max_uses": 1,
		"description": "A starchy tuber dug up from cattail roots at the river's edge.",
		"properties": [], "abilities": [],
	}

	# ── Fish (caught with a fishing rod at riverside fishing spots) ──────────
	items["tilapia"] = {
		"id": "tilapia", "name": "Tilapia", "type": "material",
		"material_type": "meat", "beast_source": "tilapia", "slot": null, "weight": 0.8,
		"quality": 2, "quality_name": "Common",
		"uses_remaining": 1, "max_uses": 1, "expires_in_rests": 2,
		"description": "A common river fish, freshly caught.",
		"properties": [], "abilities": [],
	}

	items["catfish"] = {
		"id": "catfish", "name": "Catfish", "type": "material",
		"material_type": "meat", "beast_source": "catfish", "slot": null, "weight": 1.2,
		"quality": 2, "quality_name": "Common",
		"uses_remaining": 1, "max_uses": 1, "expires_in_rests": 2,
		"description": "A heavy-bodied river catfish. Less common than tilapia.",
		"properties": [], "abilities": [],
	}

	# ── Meat (sold raw or preserved by the Meat-Hawker) ──────────────────────
	items["coyote_meat"] = {
		"id": "coyote_meat", "name": "Coyote Meat", "type": "material",
		"material_type": "meat", "beast_source": "coyote", "slot": null, "weight": 1.5,
		"quality": 2, "quality_name": "Common",
		"uses_remaining": 1, "max_uses": 1, "expires_in_rests": 2,
		"description": "Standard cuts of coyote meat, butchered and ready to cook.",
		"properties": [], "abilities": [],
	}
	items["lizard_meat"] = {
		"id": "lizard_meat", "name": "Lizard Meat", "type": "material",
		"material_type": "meat", "beast_source": "lizard", "slot": null, "weight": 1.5,
		"quality": 2, "quality_name": "Common",
		"uses_remaining": 1, "max_uses": 1, "expires_in_rests": 2,
		"description": "Standard cuts of lizard meat, butchered and ready to cook.",
		"properties": [], "abilities": [],
	}
	items["sand_beetle_meat"] = {
		"id": "sand_beetle_meat", "name": "Sand Beetle Meat", "type": "material",
		"material_type": "meat", "beast_source": "sand_beetle", "slot": null, "weight": 1.5,
		"quality": 2, "quality_name": "Common",
		"uses_remaining": 1, "max_uses": 1, "expires_in_rests": 2,
		"description": "Standard cuts of sand beetle meat, butchered and ready to cook.",
		"properties": [], "abilities": [],
	}
	for beast in ["coyote", "lizard", "sand_beetle"]:
		var beast_display: String = CARVE_TABLES[beast]["display_name"]
		items["sun_dried_%s_meat" % beast] = {
			"id": "sun_dried_%s_meat" % beast, "name": "Sun-Dried %s Meat" % beast_display, "type": "material",
			"material_type": "meat", "beast_source": beast, "preservation": "sun_dried", "slot": null, "weight": 1.5,
			"quality": 2, "quality_name": "Common",
			"uses_remaining": 1, "max_uses": 1, "expires_in_rests": 4,
			"description": "%s meat, preserved by sun-drying." % beast_display,
			"properties": [], "abilities": [],
		}
		items["salt_cured_%s_meat" % beast] = {
			"id": "salt_cured_%s_meat" % beast, "name": "Salt-Cured %s Meat" % beast_display, "type": "material",
			"material_type": "meat", "beast_source": beast, "preservation": "salt_cured", "slot": null, "weight": 1.5,
			"quality": 2, "quality_name": "Common",
			"uses_remaining": 1, "max_uses": 1, "expires_in_rests": 10,
			"description": "%s meat, preserved by salt-curing." % beast_display,
			"passive_meal_buff": {"id": "salted_provisions", "name": "Salted Provisions", "hp_pct": 0.03},
			"properties": [], "abilities": [],
		}
		items["smoked_%s_meat" % beast] = {
			"id": "smoked_%s_meat" % beast, "name": "Smoked %s Meat" % beast_display, "type": "material",
			"material_type": "meat", "beast_source": beast, "preservation": "smoked", "slot": null, "weight": 1.5,
			"quality": 2, "quality_name": "Common",
			"uses_remaining": 1, "max_uses": 1, "expires_in_rests": 10,
			"description": "%s meat, preserved by smoking over a slow fire." % beast_display,
			"cooking_potency_mult": 1.2,
			"properties": [], "abilities": [],
		}

	# ── Consumables ───────────────────────────────────────────────────────────

	items["dark_vial"] = {
		"id":          "dark_vial",
		"name":        "Dark Green Vial",
		"type":        "consumable",
		"slot":        null,
		"weight":      0.1,
		"on_use":      "drink_vial",
		"description": "A small dark green vial of something murky. Whatever is in it, the apothecary sold it cheap for a reason.\n\nDouble-click to drink.\n\nEffect: 1d4 damage. Grants Spirit Ward Lv.1 for 3 rests.",
		"properties": [], "abilities": [],
	}

	items["basic_lingering_poison"] = {
		"id":          "basic_lingering_poison",
		"name":        "Basic Lingering Poison",
		"type":        "consumable",
		"slot":        null,
		"weight":      0.1,
		"on_use":      "apply_poison",
		"description": "A crude coating venom. Apply to an equipped weapon before combat — the coating stays poisoned until your next rest.\n\nLeft-click to apply to your equipped weapon.\n\nEffect: weapon attacks have a high chance to inflict Poison (d6 per turn, 3 turns, stackable).",
		"properties": [], "abilities": [],
	}

	items["smoke_bomb"] = {
		"id":           "smoke_bomb",
		"name":         "Smoke Bomb",
		"type":         "consumable",
		"slot":         null,
		"weight":       0.4,
		"on_use":       "deploy_smoke_bomb",
		"ap_cost":      2,
		"throw_range":  12,
		"smoke_radius": 2,
		"smoke_turns":  3,
		"description":  "A sealed clay vessel filled with acrid smoke powder. Throw it at a location within range to create a blinding cloud.\n\nIn combat: 2 AP, range 12. Click target tile to throw.\nAccuracy affected by Ranged skill.\n\nEffect: 5-tile cloud for 3 rounds. Ranged attacks into, out of, or through smoke: −40 to hit. Sneak treats effective skill as +25 in smoke.",
		"properties": [], "abilities": [],
	}

	# ── Clothing (percentage armor only) ─────────────────────────────────────

	items["tunic"] = {
		"id": "tunic", "weight": 1.0, "name": "Tunic", "type": "clothing", "slot": "torso",
		"description": "A simple linen tunic, worn and faded. Yours.",
		"defense_flat": 0, "defense_pct": 0.01,
		"skill_bonus": {}, "carry_weight_bonus": 0,
	}

	items["sandals"] = {
		"id": "sandals", "weight": 0.5, "name": "Sandals", "type": "clothing", "slot": "feet",
		"description": "Leather sandals, held together more by habit than by craft.",
		"defense_flat": 0, "defense_pct": 0.0,
		"skill_bonus": {}, "carry_weight_bonus": 0,
	}

	items["leather_vest"] = {
		"id": "leather_vest", "weight": 1.5, "name": "Leather Vest", "type": "clothing", "slot": "torso",
		"description": "A close-fitting vest of cured leather.",
		"defense_flat": 3, "defense_pct": 0.0,
		"skill_bonus": {}, "carry_weight_bonus": 0,
	}

	items["padded_cloth_armor"] = {
		"id": "padded_cloth_armor", "weight": 2.0, "name": "Padded Cloth Armor", "type": "armor", "slot": "torso",
		"description": "Layers of dense cloth, quilted thick enough to take the sting out of a blow.",
		"defense_flat": 0, "defense_pct": 0.10,
		"skill_bonus": {"sneak": -6, "dodge": -6}, "carry_weight_bonus": 0,
	}

	items["work_trousers"] = {
		"id": "work_trousers", "weight": 1.5, "name": "Work Trousers", "type": "clothing", "slot": "legs",
		"description": "Thick canvas trousers reinforced at the knees.",
		"defense_flat": 0, "defense_pct": 0.02,
		"skill_bonus": {}, "carry_weight_bonus": 0,
	}

	items["work_boots"] = {
		"id": "work_boots", "weight": 2.0, "name": "Hide Boots", "type": "clothing", "slot": "feet",
		"description": "Stitched hide boots, broken in from years of hard use.",
		"defense_flat": 0, "defense_pct": 0.02,
		"skill_bonus": {}, "carry_weight_bonus": 0,
	}

	# ── Smithy wares ─────────────────────────────────────────────────────────────

	# Bronze armor — sold by the smith
	items["bronze_helm"] = {
		"id": "bronze_helm", "weight": 1.5, "name": "Bronze Helm", "type": "armor", "slot": "head",
		"description": "A cast bronze helm covering the skull and cheeks. Heavy, but a blow to an unprotected head ends fights.",
		"defense_flat": 2, "defense_pct": 0.03, "skill_bonus": {"sneak": -3, "dodge": -3}, "carry_weight_bonus": 0,
	}
	items["bronze_scale_hauberk"] = {
		"id": "bronze_scale_hauberk", "weight": 6.0, "name": "Bronze Scale Hauberk", "type": "armor", "slot": "torso",
		"description": "Overlapping bronze scales wired to a leather backing. Expensive, heavy, and highly effective.",
		"defense_flat": 5, "defense_pct": 0.10, "skill_bonus": {"sneak": -12, "dodge": -12}, "carry_weight_bonus": 0,
	}
	items["bronze_greaves"] = {
		"id": "bronze_greaves", "weight": 2.0, "name": "Bronze Greaves", "type": "armor", "slot": "legs",
		"description": "Formed bronze plates strapped around the shins. Standard protection for infantry.",
		"defense_flat": 1, "defense_pct": 0.04, "skill_bonus": {"sneak": -4, "dodge": -4}, "carry_weight_bonus": 0,
	}
	items["bronze_shield"] = {
		"id": "bronze_shield", "weight": 6.0, "name": "Bronze Shield", "type": "armor", "slot": "hand",
		"description": "A bronze-faced shield, heavy enough to stop a blade outright — for those nimble enough to swing it into place in time.",
		"block_flat": 10, "governing": ["dexterity"], "skill_bonus": {"sneak": -10, "dodge": -10}, "carry_weight_bonus": 0,
	}

	# Spirit armbands — bronze is the smith's basic offering; iron is a higher tier for later
	items["cloth_scripture_armband"] = {
		"id": "cloth_scripture_armband", "weight": 0.2, "name": "Cloth Scripture Armband",
		"type": "trinket", "slot": "upper_arm",
		"description": "A strip of linen with pictographic scripture written in careful ink. Basic spirit protection from an apprentice scribe — the writing holds.",
		"spirit_ward": true, "spirit_ward_level": 0,
		"defense_flat": 0, "defense_pct": 0.0,
		"skill_bonus": {}, "governing_bonus": {}, "carry_weight_bonus": 0,
		"properties": [], "abilities": [],
	}
	items["bronze_spirit_armband"] = {
		"id": "bronze_spirit_armband", "weight": 0.6, "name": "Bronze Spirit Armband",
		"type": "trinket", "slot": "upper_arm",
		"description": "A hammered bronze band shaped to fit the upper arm. Basic spirit protection — the smiths have been making these for generations. It won't hold in the undercity, but it'll see you through the night up here.",
		"spirit_ward": true, "spirit_ward_level": 0,
		"defense_flat": 0, "defense_pct": 0.0,
		"skill_bonus": {}, "governing_bonus": {}, "carry_weight_bonus": 0,
		"properties": [], "abilities": [],
	}

	items["iron_spirit_armband"] = {
		"id": "iron_spirit_armband", "weight": 0.8, "name": "Iron Spirit Armband",
		"type": "trinket", "slot": "upper_arm",
		"description": "A hammered iron band shaped to fit the upper arm. Iron is not wasted on decoration — smiths who make these regard the concession as a spiritual act in itself. The band wards against spirits.",
		"spirit_ward": true,
		"defense_flat": 0, "defense_pct": 0.01,
		"skill_bonus": {}, "governing_bonus": {}, "carry_weight_bonus": 0,
		"properties": [], "abilities": [],
	}

	# Taboo mirror of the Way of Beasts trophies — worn by undercity cannibals
	# who take the powers of those they personally killed. Not lootable: the
	# power only belongs to the wearer (see Way of Beasts core rule).
	items["human_skin_trophy"] = {
		"id": "human_skin_trophy", "weight": 1.0, "name": "Skinned Trophy",
		"type": "trinket", "slot": "back",
		"description": "A cured human hide, worn like a cloak. A taboo mirror of the Way of Beasts.",
		"defense_flat": 0, "defense_pct": 0.0,
		"skill_bonus": {}, "governing_bonus": {"melee": 1}, "carry_weight_bonus": 0,
		"properties": [], "abilities": [],
	}

	# Quest items for the smith's errand
	items["smith_invoice"] = {
		"id": "smith_invoice", "weight": 0.0, "name": "Smith's Invoice",
		"type": "quest_item", "slot": null,
		"description": "A clay tablet scratched with simple markings. It reads: 'One batch flame accelerant, standard mix. On account of the smithy, market district. Paid on delivery.'",
		"properties": [], "abilities": [],
	}
	items["flame_accelerant"] = {
		"id": "flame_accelerant", "weight": 0.5, "name": "Flame Accelerant",
		"type": "quest_item", "slot": null,
		"description": "A sealed clay jar of viscous dark liquid. It smells faintly of pitch and something older. The fire cult marks the seal with a simple burned symbol.",
		"properties": [], "abilities": [],
	}

	items["unnamed_package"] = {
		"id": "unnamed_package", "weight": 3.0, "name": "Merchant's Package",
		"type": "quest_item", "slot": null,
		"description": "A bundle wrapped in waxed cloth and bound tight with cord. A merchant's mark is pressed into the wax seal. Whatever is inside belongs to someone.",
		"properties": [], "abilities": [],
	}

	# ── Scribe supplies ───────────────────────────────────────────────────────

	items["transcribed_scripture"] = {
		"id": "transcribed_scripture", "weight": 0.1, "name": "Transcribed Scripture",
		"type": "quest_item", "slot": null,
		"description": "A rolled scripture, carefully transcribed in the scribe's hand. Meant for a customer in the residential district.",
		"properties": [], "abilities": [],
	}

	items["ink"] = {
		"id": "ink", "weight": 0.1, "name": "Ink",
		"type": "material", "slot": null,
		"description": "A small pot of dense black ink, the kind used by scribes. Standard supply.",
		"properties": [], "abilities": [],
	}
	items["blank_talisman"] = {
		"id": "blank_talisman", "weight": 0.05, "name": "Blank Talisman",
		"type": "material", "slot": null,
		"description": "A small piece of treated cloth, cut and prepared for inscription. The surface holds ink cleanly.",
		"properties": [], "abilities": [],
	}
	items["basic_protective_talisman"] = {
		"id": "basic_protective_talisman", "weight": 0.05, "name": "Basic Protective Talisman",
		"type": "talisman", "slot": "talisman",
		"description": "A simple cloth talisman inscribed with basic protective scripture. The strokes are careful if not masterful.",
		"spirit_ward": true, "spirit_ward_level": 0,
		"defense_flat": 0, "defense_pct": 0.0,
		"skill_bonus": {}, "governing_bonus": {}, "carry_weight_bonus": 0,
		"properties": [], "abilities": [],
	}
	items["blast_tag"] = {
		"id": "blast_tag", "weight": 0.05, "name": "Blast Tag",
		"type": "consumable", "slot": null,
		"description": "A folded talisman painted with volatile detonation scripture. Throw it to plant the seal, then spend SP to detonate it — blasting everything nearby with physical and fire force.",
		"special": "blast_tag",
		"ap_cost": 2,
		"detonate_ap_cost": 2,
		"detonate_sp_cost": 2,
		"throw_range": 12,
		"blast_radius": 4,
		"damage_physical": "2d6",
		"damage_fire":     "2d6",
		"governing":       ["willpower"],
		"properties": [], "abilities": [],
	}
	items["enchanted_fist_wraps"] = {
		"id": "enchanted_fist_wraps", "weight": 0.3, "name": "Enchanted Fist Wraps",
		"type": "weapon", "slot": "hand",
		"description": "Linen wraps densely inscribed with scripture that channels strikes outward across distance. Counts as unarmed — feats and bonuses that apply to unarmed attacks apply here too.",
		"damage": "1d3", "ap_cost": 2, "range": 6,
		"skill": "melee", "governing": ["strength", "dexterity"],
		"damage_type": "physical",
		"properties": ["projected_melee", "unarmed_type"],
		"bonus_scripture_damage": "1d6",
		"abilities": [],
	}

	# ── Trinkets (crafted from beast trophies) ────────────────────────────────
	# All trinkets provide spirit_ward — minimum spiritual protection to sleep in the city.
	# Higher-tier trophies add small combat bonuses on top.

	items["coyote_bone_charm"] = {
		"id": "coyote_bone_charm", "weight": 0.1, "name": "Coyote Bone Charm", "type": "trinket", "slot": "necklace",
		"description": "A handful of coyote bones tied together with sinew. Simple, but the spirits know it.",
		"spirit_ward": true,
		"defense_flat": 0, "defense_pct": 0.0,
		"skill_bonus": {}, "governing_bonus": {}, "carry_weight_bonus": 0,
	}

	items["coyote_pelt_strip"] = {
		"id": "coyote_pelt_strip", "weight": 0.5, "name": "Coyote Pelt Strip", "type": "trinket", "slot": "upper_arm",
		"description": "A strip of coyote hide bound around the upper arm. Worn smooth against the skin.",
		"spirit_ward": true,
		"defense_flat": 0, "defense_pct": 0.02,
		"skill_bonus": {}, "governing_bonus": {}, "carry_weight_bonus": 0,
	}

	items["coyote_fang_pendant"] = {
		"id": "coyote_fang_pendant", "weight": 0.1, "name": "Coyote Fang Pendant", "type": "trinket", "slot": "necklace",
		"description": "A coyote fang hung on a cord of braided sinew. The old hunter drilled the hole himself.",
		"spirit_ward": true,
		"defense_flat": 0, "defense_pct": 0.0,
		"skill_bonus": {"melee": 5}, "governing_bonus": {}, "carry_weight_bonus": 0,
	}

	items["coyote_skull_headpiece"] = {
		"id": "coyote_skull_headpiece", "weight": 1.0, "name": "Coyote Skull Headpiece", "type": "trinket", "slot": "head",
		"description": "The full skull of a coyote, fitted to sit over the brow. Its hollow eyes look forward when you do.",
		"spirit_ward": true,
		"defense_flat": 1, "defense_pct": 0.03,
		"skill_bonus": {}, "governing_bonus": {"melee": 1}, "carry_weight_bonus": 0,
	}
