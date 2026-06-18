extends Control

# ── Constants ──────────────────────────────────────────────────────────────────
const STAT_NAMES  = ["strength","dexterity","agility","constitution","intelligence","willpower","perception"]
const STAT_ABBREV = {"strength":"STR","dexterity":"DEX","agility":"AGI",
	"constitution":"CON","intelligence":"INT","willpower":"WIL","perception":"PER"}

const SKILL_NAMES = ["melee","ranged","dodge","convince","intimidate",
	"sneak","sleight_of_hand","alchemy","occultism","smithing","survival","cooking"]
const SKILL_DISPLAY = {
	"melee":"Melee","ranged":"Ranged","dodge":"Dodge",
	"convince":"Convince","intimidate":"Intimidate","sneak":"Sneak",
	"sleight_of_hand":"Sleight of Hand","alchemy":"Alchemy","occultism":"Occultism",
	"smithing":"Smithing","survival":"Survival","cooking":"Cooking",
}
const SKILL_GOV = {
	"melee":"STR/DEX","ranged":"PER+STR/DEX","dodge":"DEX/AGI",
	"convince":"WIL","intimidate":"STR/WIL","sneak":"DEX",
	"sleight_of_hand":"DEX","alchemy":"INT","occultism":"INT/WIL",
	"smithing":"INT/STR","survival":"CON/WIL/PER","cooking":"INT",
}

const SKILL_GOV_NOTE: Dictionary = {
	"melee":           "Higher of STR or DEX modifier.\nImproves both hit chance and damage.",
	"ranged":          "To-hit: 70% PER modifier + 30% best(STR/DEX).\nDamage governing set per-weapon (STR or DEX).",
	"dodge":           "Higher of DEX or AGI modifier.\nAGI also grants more AP and MB in combat.",
	"convince":        "Willpower modifier.\nHigh WIL = more persuasive speech.",
	"intimidate":      "Higher of STR or WIL modifier.\nPhysical presence (STR) or force of will (WIL).",
	"sneak":           "Dexterity modifier.\nOpposed by enemy Perception stat when detected.",
	"sleight_of_hand": "Dexterity modifier.\nFine motor control: picking pockets, lock manipulation.",
	"alchemy":         "Intelligence modifier.\nINT improves recipe outcomes and ingredient yield.",
	"occultism":       "Higher of INT or WIL modifier.\nKnowledge (INT) or spiritual attunement (WIL).",
	"smithing":        "Higher of INT or STR modifier.\nBlueprint knowledge (INT) and brute work (STR).",
	"survival":        "Highest of CON, WIL, or PER modifier.\nEndurance (CON), mental fortitude (WIL), or awareness of the land (PER).",
	"cooking":         "Intelligence modifier.\nKnowledge of ingredients and technique. Governs preservation recipe quality and rest-time meal quality.",
}

const STAT_TOOLTIP: Dictionary = {
	"strength": "Skills: Melee (STR/DEX), Ranged to-hit (PER+STR/DEX), Smithing (INT/STR), Intimidate (STR/WIL)\n• Melee and Ranged damage bonus (+mod per hit, per weapon)\n• Ranged to-hit: STR competes with DEX for the 30% non-PER portion\n• Carry capacity: +10 per modifier\n• Modifier = stat − 5  (e.g. STR 7 → +2)",
	"dexterity": "Skills: Melee (STR/DEX), Ranged to-hit (PER+STR/DEX), Dodge (DEX/AGI),\n  Sneak (DEX), Sleight of Hand (DEX)\n• Ranged/Melee damage bonus (+mod per hit, per weapon)\n• Crit chance: 30% weight\n• Initiative bonus (+mod)\n• Modifier = stat − 5",
	"agility": "Skills: Dodge (DEX/AGI)\n• Action Points (AP) = Agility stat  (attacks per turn)\n• Movement Points (MP) = Agility stat  (tiles per turn)\n• Initiative bonus (+mod)\n• Modifier = stat − 5",
	"constitution": "Skills: Survival (CON/WIL/PER)\n• Max HP = 5 × (5 + CON mod) × (level + 1)\n• Carry capacity: +5 per modifier\n• Bleed resistance: reduces bleed application chance\n• CON increases applied retroactively to HP\n• Modifier = stat − 5",
	"intelligence": "Skills: Alchemy (INT), Occultism (INT/WIL), Smithing (INT/STR)\n• Skill points per level: base 30 + floor(INT mod × 2.5)\n  (character creation pool is 60 + INT mod × 5)\n• Skill cap per level: 20 at Lv.1, +10 each level after\n• Modifier = stat − 5",
	"willpower": "Skills: Convince (WIL), Intimidate (STR/WIL),\n  Occultism (INT/WIL), Survival (CON/WIL/PER)\n• Spirit pool: WIL × 10 (resource for all magic abilities)\n• Magic damage bonus: WIL modifier applies to spell damage\n• Governs mental resilience and spiritual attunement\n• Modifier = stat − 5",
	"perception": "Skills: Ranged to-hit (70% PER weight), Survival (CON/WIL/PER)\n• Ranged to-hit formula: (PER_mod×0.7 + best(STR,DEX)_mod×0.3)\n• Crit chance: 70% weight  — formula: (PER_mod×0.7 + DEX_mod×0.3) × 3%\n• Detects hidden objects and secret passages\n• NPCs and enemies use Perception to detect sneaking\n• Modifier = stat − 5",
}

const BACKGROUNDS: Dictionary = {
	"Gladiator":
		"Trained to fight for the crowd's amusement. You survived the arena long enough to earn your freedom — or what passes for it.\n\nBonus: +1 STR or AGI\nStarting skills: Melee ↑↑, Dodge ↑, Intimidate ↑",
	"Mason":
		"Hauled stone, shaped it, stacked it. The city is built on your back and you have nothing to show for it.\n\nBonus: +1 STR or CON\nStarting skills: Smithing ↑↑, Survival ↑, Melee ↑",
	"Apothecary's Assistant":
		"Ground herbs, mixed remedies, kept records. Privy to things your master didn't realize you were learning.\n\nBonus: +1 INT or DEX\nStarting skills: Alchemy ↑↑, Sneak ↑, Occultism ↑",
	"Temple Servant":
		"Cleaned sacred spaces, prepared ritual objects, stood in corners during ceremonies. You heard things.\n\nBonus: +1 WIL or INT\nStarting skills: Occultism ↑↑, Sneak ↑, Convince ↑",
	"Field Hand":
		"Worked land outside the city walls. Patient, practical, and capable of enduring more than most.\n\nBonus: +1 CON or AGI\nStarting skills: Survival ↑↑, Alchemy ↑, Ranged ↑",
	"Domestic":
		"Served in a wealthy household. Learned to stay invisible. Learned what invisibility lets you see.\n\nBonus: +1 DEX or WIL\nStarting skills: Cooking ↑↑, Sneak ↑↑, Convince ↑",
}

const BACKGROUND_BONUS_OPTIONS: Dictionary = {
	"Gladiator":              ["strength", "agility"],
	"Mason":                  ["strength", "constitution"],
	"Apothecary's Assistant": ["intelligence", "dexterity"],
	"Temple Servant":         ["willpower", "intelligence"],
	"Field Hand":             ["constitution", "agility"],
	"Domestic":               ["dexterity", "willpower"],
}

# ↑ = 5 bonus points, ↑↑ = 10 bonus points. Added on top of the normal skill pool.
const BACKGROUND_SKILLS: Dictionary = {
	"Gladiator":              {"melee": 10, "dodge": 5, "intimidate": 5},
	"Mason":                  {"smithing": 10, "survival": 5, "melee": 5},
	"Apothecary's Assistant": {"alchemy": 10, "sneak": 5, "occultism": 5},
	"Temple Servant":         {"occultism": 10, "sneak": 5, "convince": 5},
	"Field Hand":             {"survival": 10, "alchemy": 5, "ranged": 5},
	"Domestic":               {"cooking": 10, "sneak": 10, "convince": 5},
}

var _feats: Dictionary = {}

const STAT_MIN          = 4
const STAT_MAX          = 8
const BASE_SKILL_POINTS = 60
# Hard cap on total effective skill points in a skill at level 1
# (player-invested + background bonus combined cannot exceed this).
const SKILL_CAP         = 20

# ── Character State ────────────────────────────────────────────────────────────
var stats: Dictionary = {}
var stat_points: int = 5
var skills: Dictionary = {}          # player-allocated points only
var background: String = ""
var bonus_stat: String = ""          # which stat has the +1 background bonus
var bonus_choices: Array = []        # eligible stats for the current background
var _bg_skill_bonus: Dictionary = {} # skill points granted by background (not from pool)
var selected_feat: String = ""

# ── UI References ──────────────────────────────────────────────────────────────
var _name_input: LineEdit
var _stat_point_lbl: Label
var _skill_point_lbl: Label
var _stat_val_lbls: Dictionary = {}
var _stat_mod_lbls: Dictionary = {}
var _stat_minus_btns: Dictionary = {}
var _stat_plus_btns: Dictionary = {}
var _stat_bonus_btns: Dictionary = {}
var _skill_invested_lbls: Dictionary = {}
var _skill_total_lbls: Dictionary = {}
var _skill_minus_btns: Dictionary = {}
var _skill_plus_btns: Dictionary = {}
var _bg_buttons: Dictionary = {}
var _bg_desc_lbl: Label
var _feat_buttons: Dictionary = {}
var _feat_req_lbls: Dictionary = {}
var _feat_desc_lbl: Label
var _begin_btn: Button

# ── Panel navigation (left-to-right wizard at the bottom of the screen) ─────────
const PANEL_NAMES: Array = ["Background", "Stats", "Skills", "Feat"]
var _panels: Array = []
var _tab_btns: Array = []
var _prev_btn: Button
var _next_btn: Button
var _current_panel: int = 0
var _hp_bar: ProgressBar
var _hp_label: Label
var _skill_tooltip_panel: PanelContainer = null
var _skill_tooltip_lbl: Label = null
var _skill_detail_overlay: Control = null
var _crit_lbl: Label = null

# ── Hold-to-repeat ─────────────────────────────────────────────────────────────
var _hold_action: Callable = Callable()
var _hold_timer: float = 0.0
const HOLD_DELAY: float = 0.4
const HOLD_RATE:  float = 0.07

func _process(delta: float) -> void:
	if not _hold_action.is_valid():
		return
	_hold_timer -= delta
	if _hold_timer <= 0.0:
		_hold_action.call()
		_hold_timer = HOLD_RATE

func _start_hold(action: Callable) -> void:
	action.call()
	_hold_action = action
	_hold_timer = HOLD_DELAY

func _stop_hold() -> void:
	_hold_action = Callable()

# ── Init ───────────────────────────────────────────────────────────────────────
func _ready() -> void:
	for s in STAT_NAMES:  stats[s]  = 5
	for s in SKILL_NAMES: skills[s] = 0
	_build_feats_from_data_manager()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_refresh_all()

func _build_feats_from_data_manager() -> void:
	for feat_id in DataManager.feats:
		var f: Dictionary = DataManager.feats[feat_id]
		if f.get("source", "") != "level_up":
			continue
		var stats_req: Dictionary  = f.get("requirements", {}).get("stats", {})
		var skills_req: Dictionary = f.get("requirements", {}).get("skills", {})
		_feats[f["name"]] = {
			"id":           feat_id,
			"effect":       f.get("description", ""),
			"req_stat":     stats_req.keys()[0]   if not stats_req.is_empty()  else "",
			"req_stat_val": stats_req.values()[0] if not stats_req.is_empty()  else 0,
			"req_skill":    skills_req.keys()[0]   if not skills_req.is_empty() else "",
			"req_skill_val": skills_req.values()[0] if not skills_req.is_empty() else 0,
		}

# ══════════════════════════════════════════════════════════════════════════════
# UI CONSTRUCTION
# ══════════════════════════════════════════════════════════════════════════════
func _build_ui() -> void:
	var bg = ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.05, 0.08)
	add_child(bg)

	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left","margin_right","margin_top","margin_bottom"]:
		margin.add_theme_constant_override(side, 20)
	add_child(margin)

	var root_vbox = VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 10)
	margin.add_child(root_vbox)

	var title_row = HBoxContainer.new()
	root_vbox.add_child(title_row)
	var back_btn = Button.new()
	back_btn.text = "< Back"
	back_btn.custom_minimum_size = Vector2(80, 0)
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/title_screen.tscn"))
	title_row.add_child(back_btn)
	var title_lbl = Label.new()
	title_lbl.text = "CHARACTER CREATION"
	title_lbl.add_theme_font_size_override("font_size", 26)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title_lbl)
	_spacer(title_row, 80, 0)

	var name_row = HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	root_vbox.add_child(name_row)
	var name_lbl = Label.new()
	name_lbl.text = "NAME"
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.custom_minimum_size = Vector2(60, 0)
	name_row.add_child(name_lbl)
	_name_input = LineEdit.new()
	_name_input.placeholder_text = "Enter character name..."
	_name_input.custom_minimum_size = Vector2(0, 34)
	_name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(_name_input)

	_hsep(root_vbox)

	# Panel area — only one of the four pages is visible at a time, switched via
	# the bottom nav bar (left-to-right: Background → Stats → Skills → Feat).
	var panel_root = Control.new()
	panel_root.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	panel_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(panel_root)

	_panels = [
		_build_background_panel(),
		_build_stats_panel(),
		_build_skills_panel(),
		_build_feat_panel(),
	]
	for p in _panels:
		(p as Control).set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		panel_root.add_child(p)

	root_vbox.add_child(_build_bottom_nav())

	# Floating skill/stat tooltip (shown on label hover)
	_skill_tooltip_panel = PanelContainer.new()
	_skill_tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_skill_tooltip_panel.visible = false
	_skill_tooltip_panel.z_index = 200
	var tip_style := StyleBoxFlat.new()
	tip_style.bg_color = Color(0.10, 0.08, 0.14, 0.97)
	tip_style.set_corner_radius_all(4)
	tip_style.border_width_left   = 1
	tip_style.border_width_right  = 1
	tip_style.border_width_top    = 1
	tip_style.border_width_bottom = 1
	tip_style.border_color = Color(0.35, 0.30, 0.50)
	tip_style.content_margin_left   = 10
	tip_style.content_margin_right  = 10
	tip_style.content_margin_top    = 8
	tip_style.content_margin_bottom = 8
	_skill_tooltip_panel.add_theme_stylebox_override("panel", tip_style)
	_skill_tooltip_lbl = Label.new()
	_skill_tooltip_lbl.add_theme_font_size_override("font_size", 12)
	_skill_tooltip_lbl.add_theme_color_override("font_color", Color(0.88, 0.88, 0.92))
	_skill_tooltip_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_skill_tooltip_panel.add_child(_skill_tooltip_lbl)
	add_child(_skill_tooltip_panel)

	_show_panel(0)

# ── Bottom nav: page tabs + prev/next + begin ──────────────────────────────────
func _build_bottom_nav() -> Control:
	var nav = HBoxContainer.new()
	nav.add_theme_constant_override("separation", 8)

	_prev_btn = Button.new()
	_prev_btn.text = "< Prev"
	_prev_btn.custom_minimum_size = Vector2(100, 44)
	_prev_btn.pressed.connect(func(): _show_panel(_current_panel - 1))
	nav.add_child(_prev_btn)

	var tabs_box = HBoxContainer.new()
	tabs_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs_box.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs_box.add_theme_constant_override("separation", 8)
	for i in range(PANEL_NAMES.size()):
		var tab_btn = Button.new()
		tab_btn.text = "%d. %s" % [i + 1, PANEL_NAMES[i]]
		tab_btn.toggle_mode = true
		tab_btn.custom_minimum_size = Vector2(140, 40)
		tab_btn.pressed.connect(_show_panel.bind(i))
		_tab_btns.append(tab_btn)
		tabs_box.add_child(tab_btn)
	nav.add_child(tabs_box)

	_next_btn = Button.new()
	_next_btn.text = "Next >"
	_next_btn.custom_minimum_size = Vector2(100, 44)
	_next_btn.pressed.connect(func(): _show_panel(_current_panel + 1))
	nav.add_child(_next_btn)

	_begin_btn = Button.new()
	_begin_btn.text = "BEGIN"
	_begin_btn.custom_minimum_size = Vector2(120, 44)
	_begin_btn.pressed.connect(_on_begin)
	nav.add_child(_begin_btn)

	return nav

func _show_panel(idx: int) -> void:
	idx = clampi(idx, 0, _panels.size() - 1)
	_current_panel = idx
	for i in range(_panels.size()):
		(_panels[i] as Control).visible = (i == idx)
	for i in range(_tab_btns.size()):
		(_tab_btns[i] as Button).button_pressed = (i == idx)
	_prev_btn.disabled = (idx == 0)
	_next_btn.visible  = (idx < _panels.size() - 1)
	_begin_btn.visible = (idx == _panels.size() - 1)

# ── Panel: background ───────────────────────────────────────────────────────────
func _build_background_panel() -> Control:
	var scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	var row = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 16)
	scroll.add_child(row)

	var list_col = VBoxContainer.new()
	list_col.custom_minimum_size = Vector2(240, 0)
	list_col.add_theme_constant_override("separation", 6)
	_section_label(list_col, "BACKGROUND")
	for bg_name in BACKGROUNDS.keys():
		var btn = Button.new()
		btn.text = bg_name
		btn.toggle_mode = true
		btn.custom_minimum_size = Vector2(0, 36)
		btn.pressed.connect(_on_background.bind(bg_name))
		_bg_buttons[bg_name] = btn
		list_col.add_child(btn)
	row.add_child(list_col)

	_vsep(row)

	var desc_col = VBoxContainer.new()
	desc_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc_col.add_theme_constant_override("separation", 6)
	_section_label(desc_col, "DESCRIPTION")
	_bg_desc_lbl = Label.new()
	_bg_desc_lbl.text = "Select a background."
	_bg_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bg_desc_lbl.add_theme_font_size_override("font_size", 14)
	desc_col.add_child(_bg_desc_lbl)
	row.add_child(desc_col)

	return scroll

# ── Panel: stats ─────────────────────────────────────────────────────────────────
func _build_stats_panel() -> Control:
	var scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	var center = CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)

	var col = VBoxContainer.new()
	col.custom_minimum_size = Vector2(440, 0)
	col.add_theme_constant_override("separation", 6)
	center.add_child(col)

	var hdr = HBoxContainer.new()
	col.add_child(hdr)
	_section_label(hdr, "STATS", true)
	_stat_point_lbl = Label.new()
	_stat_point_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hdr.add_child(_stat_point_lbl)

	var sub_hdr = HBoxContainer.new()
	sub_hdr.add_theme_constant_override("separation", 4)
	col.add_child(sub_hdr)
	for pair in [["Stat",true,0],["",false,28],["Val",false,28],["",false,28],["Mod",false,36],["★",false,28]]:
		var l = Label.new()
		l.text = pair[0]
		if pair[1]: l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		else: l.custom_minimum_size = Vector2(pair[2], 0)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", 11)
		sub_hdr.add_child(l)

	for stat in STAT_NAMES:
		col.add_child(_build_stat_row(stat))

	_spacer(col, 0, 6)
	_hsep(col)
	_spacer(col, 0, 4)
	_section_label(col, "HEALTH")
	col.add_child(_build_hp_bar())

	_crit_lbl = Label.new()
	_crit_lbl.add_theme_font_size_override("font_size", 11)
	_crit_lbl.add_theme_color_override("font_color", Color(0.9, 0.75, 0.2))
	col.add_child(_crit_lbl)

	return scroll

func _build_hp_bar() -> Control:
	var container = Control.new()
	container.custom_minimum_size = Vector2(0, 28)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	_hp_bar = ProgressBar.new()
	_hp_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hp_bar.min_value = 0
	_hp_bar.max_value = 100
	_hp_bar.value     = 100
	_hp_bar.show_percentage = false
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.75, 0.1, 0.1)
	_hp_bar.add_theme_stylebox_override("fill", fill_style)
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.18, 0.05, 0.05)
	_hp_bar.add_theme_stylebox_override("background", bg_style)
	container.add_child(_hp_bar)

	_hp_label = Label.new()
	_hp_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hp_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(_hp_label)

	return container

func _build_stat_row(stat: String) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)

	var lbl = Button.new()
	lbl.text = STAT_ABBREV[stat]
	lbl.flat = true
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	lbl.mouse_entered.connect(func(): _show_stat_tooltip(stat, lbl))
	lbl.mouse_exited.connect(_hide_skill_tooltip)

	var minus = Button.new()
	minus.text = "-"
	minus.custom_minimum_size = Vector2(28, 28)
	minus.pressed.connect(_on_stat.bind(stat, -1))
	_stat_minus_btns[stat] = minus

	var val = Label.new()
	val.custom_minimum_size = Vector2(28, 0)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stat_val_lbls[stat] = val

	var plus = Button.new()
	plus.text = "+"
	plus.custom_minimum_size = Vector2(28, 28)
	plus.pressed.connect(_on_stat.bind(stat, 1))
	_stat_plus_btns[stat] = plus

	var mod = Label.new()
	mod.custom_minimum_size = Vector2(36, 0)
	mod.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_stat_mod_lbls[stat] = mod

	var bonus_btn = Button.new()
	bonus_btn.text = "★"
	bonus_btn.custom_minimum_size = Vector2(28, 28)
	bonus_btn.toggle_mode = true
	bonus_btn.visible = false
	bonus_btn.pressed.connect(_on_bonus_select.bind(stat))
	_stat_bonus_btns[stat] = bonus_btn

	for n in [lbl, minus, val, plus, mod, bonus_btn]:
		row.add_child(n)
	return row

func _build_feat_row(feat_name: String) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)

	var btn = Button.new()
	btn.text = feat_name
	btn.toggle_mode = true
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, 30)
	btn.pressed.connect(_on_feat_select.bind(feat_name))
	btn.mouse_entered.connect(func(): _show_feat_tooltip(feat_name, btn))
	btn.mouse_exited.connect(_hide_skill_tooltip)
	_feat_buttons[feat_name] = btn
	row.add_child(btn)

	var feat: Dictionary = _feats[feat_name]
	var req_parts: Array = []
	if feat["req_stat"] != "":
		req_parts.append(STAT_ABBREV.get(feat["req_stat"], feat["req_stat"]) + " " + str(feat["req_stat_val"]))
	if feat["req_skill"] != "":
		req_parts.append(SKILL_DISPLAY.get(feat["req_skill"], feat["req_skill"]) + " " + str(feat["req_skill_val"]))
	var req_lbl = Label.new()
	req_lbl.text = "  ".join(req_parts)
	req_lbl.add_theme_font_size_override("font_size", 11)
	req_lbl.custom_minimum_size = Vector2(90, 0)
	req_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_feat_req_lbls[feat_name] = req_lbl
	row.add_child(req_lbl)

	return row

# ── Panel: feat ────────────────────────────────────────────────────────────────
func _build_feat_panel() -> Control:
	var scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	var row = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 16)
	scroll.add_child(row)

	var list_col = VBoxContainer.new()
	list_col.custom_minimum_size = Vector2(280, 0)
	list_col.add_theme_constant_override("separation", 6)
	_section_label(list_col, "FEAT  (pick 1)")
	for feat_name in _feats.keys():
		list_col.add_child(_build_feat_row(feat_name))
	row.add_child(list_col)

	_vsep(row)

	var desc_col = VBoxContainer.new()
	desc_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc_col.add_theme_constant_override("separation", 6)
	_section_label(desc_col, "DESCRIPTION")
	_feat_desc_lbl = Label.new()
	_feat_desc_lbl.text = "Select a feat."
	_feat_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feat_desc_lbl.add_theme_font_size_override("font_size", 14)
	desc_col.add_child(_feat_desc_lbl)
	row.add_child(desc_col)

	return scroll

# ── Panel: skills (split into two columns) ─────────────────────────────────────
func _build_skills_panel() -> Control:
	var scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	var outer = VBoxContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("separation", 6)
	scroll.add_child(outer)

	var hdr = HBoxContainer.new()
	outer.add_child(hdr)
	_section_label(hdr, "SKILLS", true)
	_skill_point_lbl = Label.new()
	_skill_point_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hdr.add_child(_skill_point_lbl)

	var cols = HBoxContainer.new()
	cols.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_theme_constant_override("separation", 24)
	outer.add_child(cols)

	var half: int = SKILL_NAMES.size() / 2
	for col_idx in range(2):
		var col = VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", 4)

		var sub_hdr = HBoxContainer.new()
		sub_hdr.add_theme_constant_override("separation", 4)
		col.add_child(sub_hdr)
		for pair in [["Skill",true,0],["Gov.",false,52],["",false,28],["Pts",false,28],["",false,28],["Tot.",false,34]]:
			var l = Label.new()
			l.text = pair[0]
			if pair[1]: l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			else: l.custom_minimum_size = Vector2(pair[2], 0)
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			l.add_theme_font_size_override("font_size", 11)
			sub_hdr.add_child(l)

		var start: int = col_idx * half
		var end: int   = SKILL_NAMES.size() if col_idx == 1 else half
		for i in range(start, end):
			col.add_child(_build_skill_row(SKILL_NAMES[i]))
		cols.add_child(col)

	return scroll

func _build_skill_row(skill: String) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)

	var name_lbl = Label.new()
	name_lbl.text = SKILL_DISPLAY[skill]
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var gov_lbl = Button.new()
	gov_lbl.text = SKILL_GOV[skill]
	gov_lbl.custom_minimum_size = Vector2(52, 0)
	gov_lbl.flat = true
	gov_lbl.add_theme_font_size_override("font_size", 11)
	gov_lbl.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	gov_lbl.mouse_entered.connect(func(): _show_skill_tooltip(skill, gov_lbl))
	gov_lbl.mouse_exited.connect(_hide_skill_tooltip)
	gov_lbl.pressed.connect(func(): _show_skill_detail(skill))

	var minus = Button.new()
	minus.text = "-"
	minus.custom_minimum_size = Vector2(28, 26)
	minus.button_down.connect(func(): _start_hold(func(): _on_skill(skill, -1)))
	minus.button_up.connect(_stop_hold)
	_skill_minus_btns[skill] = minus

	var pts_lbl = Label.new()
	pts_lbl.custom_minimum_size = Vector2(28, 0)
	pts_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_skill_invested_lbls[skill] = pts_lbl

	var plus = Button.new()
	plus.text = "+"
	plus.custom_minimum_size = Vector2(28, 26)
	plus.button_down.connect(func(): _start_hold(func(): _on_skill(skill, 1)))
	plus.button_up.connect(_stop_hold)
	_skill_plus_btns[skill] = plus

	var tot_lbl = Label.new()
	tot_lbl.custom_minimum_size = Vector2(34, 0)
	tot_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_skill_total_lbls[skill] = tot_lbl

	for n in [name_lbl, gov_lbl, minus, pts_lbl, plus, tot_lbl]:
		row.add_child(n)
	return row

func _show_skill_tooltip(skill: String, anchor: Control) -> void:
	if _skill_tooltip_panel == null:
		return
	var gov_str: String = SKILL_GOV[skill]
	var note: String    = SKILL_GOV_NOTE.get(skill, "")
	_skill_tooltip_lbl.text = "[%s]  %s\n%s" % [gov_str, SKILL_DISPLAY[skill], note]
	await _size_and_place_tooltip(260, anchor)

func _hide_skill_tooltip() -> void:
	if _skill_tooltip_panel != null:
		_skill_tooltip_panel.visible = false

func _show_feat_tooltip(feat_name: String, anchor: Control) -> void:
	if _skill_tooltip_panel == null:
		return
	var feat: Dictionary = _feats[feat_name]
	var stat_abbr: String = STAT_ABBREV.get(feat["req_stat"], feat["req_stat"].to_upper())
	var req_line: String = "Requires: %s %d" % [stat_abbr, feat["req_stat_val"]]
	if feat["req_skill"] != "":
		req_line += "  /  %s %d" % [SKILL_DISPLAY.get(feat["req_skill"], feat["req_skill"]), feat["req_skill_val"]]
	var met: bool = _feat_available(feat_name)
	var met_str: String = "Requirements met" if met else "Requirements not met"
	_skill_tooltip_lbl.text = "%s\n%s\n\n%s\n%s" % [feat_name, feat["effect"], req_line, met_str]
	await _size_and_place_tooltip(280, anchor)

func _show_stat_tooltip(stat: String, anchor: Control) -> void:
	if _skill_tooltip_panel == null:
		return
	var val: int      = _eff_stat(stat)
	var mod_val: int  = val - 5
	var mod_str: String = ("+%d" % mod_val) if mod_val >= 0 else str(mod_val)
	var note: String  = STAT_TOOLTIP.get(stat, "")
	var crit_line: String = ""
	if stat == "perception" or stat == "dexterity":
		var crit: float = _crit_chance()
		crit_line = "\nCurrent crit chance: %.1f%%" % crit
	_skill_tooltip_lbl.text = "%s — %s  (mod %s)\n%s%s" % [
		stat.capitalize(), STAT_ABBREV[stat], mod_str, note, crit_line]
	await _size_and_place_tooltip(320, anchor)

# Sets tooltip width, waits a frame for the label to measure its wrapped height,
# then sizes the panel to fit and positions it near the anchor.
func _size_and_place_tooltip(tip_width: int, anchor: Control) -> void:
	# Give the panel its width so PanelContainer can pass that width to the label.
	_skill_tooltip_panel.custom_minimum_size = Vector2(tip_width, 0)
	_skill_tooltip_panel.size               = Vector2(tip_width, 0)
	_skill_tooltip_panel.visible = true
	await get_tree().process_frame
	# With width known, the label can compute its wrapped height.
	var content_h: float = _skill_tooltip_lbl.get_minimum_size().y
	var panel_h: float   = content_h + 16.0   # 8 top + 8 bottom content margins
	_skill_tooltip_panel.size = Vector2(tip_width, panel_h)
	_place_tooltip(anchor)

func _place_tooltip(anchor: Control) -> void:
	var vp: Vector2  = get_viewport_rect().size
	var tip: Vector2 = _skill_tooltip_panel.size
	var ar: Rect2    = anchor.get_global_rect()
	var pos: Vector2 = ar.end + Vector2(4, 4)
	if pos.x + tip.x > vp.x:
		pos.x = ar.position.x - tip.x - 4
	if pos.y + tip.y > vp.y:
		pos.y = ar.position.y - tip.y - 4
	_skill_tooltip_panel.global_position = pos

func _show_skill_detail(skill: String) -> void:
	if _skill_detail_overlay != null:
		_skill_detail_overlay.queue_free()

	_skill_detail_overlay = Control.new()
	_skill_detail_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_skill_detail_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_skill_detail_overlay.z_index = 300

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.6)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_skill_detail_overlay.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_skill_detail_overlay.add_child(center)

	var card := VBoxContainer.new()
	card.custom_minimum_size = Vector2(380, 0)
	card.add_theme_constant_override("separation", 10)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.10, 0.14)
	style.border_color = Color(0.4, 0.4, 0.55)
	style.set_border_width_all(1)
	style.set_content_margin_all(20)
	card.add_theme_stylebox_override("panel", style)
	center.add_child(card)

	# Title
	var title := Label.new()
	title.text = SKILL_DISPLAY.get(skill, skill).to_upper()
	title.add_theme_font_size_override("font_size", 20)
	card.add_child(title)

	card.add_child(HSeparator.new())

	# Governing stats + formula
	var gov_raw: String = SKILL_GOV.get(skill, "")
	# Normalise: "PER+DEX" and "STR/DEX" both become an array of abbrevs
	var abbrevs_raw: Array = gov_raw.replace("+", "/").split("/")
	var gov_parts: Array = []
	for abbr in abbrevs_raw:
		abbr = abbr.strip_edges()
		var full_name: String = ""
		for s_name in STAT_ABBREV:
			if STAT_ABBREV[s_name] == abbr:
				full_name = s_name.capitalize()
		gov_parts.append("%s (%s)" % [full_name if full_name != "" else abbr, abbr])

	var gov_lbl := Label.new()
	gov_lbl.text = "Governing: " + "  /  ".join(gov_parts)
	gov_lbl.add_theme_font_size_override("font_size", 13)
	card.add_child(gov_lbl)

	var is_ranged: bool = (skill == "ranged")
	var formula_lbl := Label.new()
	formula_lbl.text = (
		"Formula: effective = invested × (1 + (PER_mod×0.7 + best(STR,DEX)_mod×0.3) × 0.1)"
		if is_ranged else
		"Formula: effective = invested × (1 + best_mod × 0.1)"
	)
	formula_lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	formula_lbl.add_theme_font_size_override("font_size", 12)
	formula_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(formula_lbl)

	card.add_child(HSeparator.new())

	# Current stat values for each governing stat
	var abbrevs: Array = SKILL_GOV.get(skill, "").replace("+", "/").split("/")
	var stat_lines: PackedStringArray = []
	for abbr in abbrevs:
		abbr = (abbr as String).strip_edges()
		var s_name: String = ""
		for sn in STAT_ABBREV:
			if STAT_ABBREV[sn] == abbr:
				s_name = sn
		if s_name == "":
			continue
		var val: int = stats.get(s_name, 5)
		var m: int   = val - 5
		stat_lines.append("  %s (%s):  %d  →  modifier %+d" % [s_name.capitalize(), abbr, val, m])

	var stats_lbl := Label.new()
	stats_lbl.text = "Current stats:\n" + "\n".join(stat_lines)
	stats_lbl.add_theme_font_size_override("font_size", 12)
	card.add_child(stats_lbl)

	var invested: int = skills.get(skill, 0) + _bg_skill_bonus.get(skill, 0)
	var effective: float = _effective_skill(skill)
	var gov_mod_val: float = _gov_mod(skill)
	var example_lbl := Label.new()
	example_lbl.text = "\nWith %d invested:  effective = %.1f\n(governing modifier: %+.2f)" % [invested, effective, gov_mod_val]
	example_lbl.add_theme_font_size_override("font_size", 12)
	example_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.4))
	card.add_child(example_lbl)

	var note: String = SKILL_GOV_NOTE.get(skill, "")
	if note != "":
		card.add_child(HSeparator.new())
		var note_lbl := Label.new()
		note_lbl.text = note
		note_lbl.add_theme_font_size_override("font_size", 12)
		note_lbl.add_theme_color_override("font_color", Color(0.70, 0.70, 0.70))
		note_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_child(note_lbl)

	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.custom_minimum_size = Vector2(120, 36)
	close_btn.pressed.connect(func(): _skill_detail_overlay.queue_free(); _skill_detail_overlay = null)
	card.add_child(close_btn)

	add_child(_skill_detail_overlay)

# ── UI helpers ─────────────────────────────────────────────────────────────────
func _section_label(parent: Control, text: String, expand: bool = false) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 13)
	if expand: l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(l)
	return l

func _spacer(parent: Control, w: int, h: int) -> void:
	var s = Control.new()
	s.custom_minimum_size = Vector2(w, h)
	parent.add_child(s)

func _hsep(parent: Control) -> void:
	parent.add_child(HSeparator.new())

func _vsep(parent: Control) -> void:
	parent.add_child(VSeparator.new())

# ══════════════════════════════════════════════════════════════════════════════
# LOGIC
# ══════════════════════════════════════════════════════════════════════════════

# Effective stat value including the background +1 bonus.
func _eff_stat(stat: String) -> int:
	return stats[stat] + (1 if stat == bonus_stat else 0)

func _skill_pool() -> int:
	return BASE_SKILL_POINTS + ((_eff_stat("intelligence") - 5) * 5)

func _invested_skill_total() -> int:
	var t = 0
	for v in skills.values(): t += v
	return t

func _skill_points_remaining() -> int:
	return _skill_pool() - _invested_skill_total()

func _gov_mod(skill: String) -> float:
	match skill:
		"ranged":
			# 70% PER + 30% best(STR, DEX)
			var per: float = float(_eff_stat("perception") - 5)
			var sd:  float = float(max(_eff_stat("strength") - 5, _eff_stat("dexterity") - 5))
			return per * 0.7 + sd * 0.3
		"melee":             return float(max(_eff_stat("strength")-5, _eff_stat("dexterity")-5))
		"convince":          return float(_eff_stat("willpower")-5)
		"intimidate":        return float(max(_eff_stat("strength")-5, _eff_stat("willpower")-5))
		"dodge":             return float(max(_eff_stat("dexterity")-5, _eff_stat("agility")-5))
		"sneak","sleight_of_hand": return float(_eff_stat("dexterity")-5)
		"alchemy","cooking": return float(_eff_stat("intelligence")-5)
		"occultism":         return float(max(_eff_stat("intelligence")-5, _eff_stat("willpower")-5))
		"smithing":          return float(max(_eff_stat("intelligence")-5, _eff_stat("strength")-5))
		"survival":          return float(max(_eff_stat("constitution")-5, _eff_stat("willpower")-5, _eff_stat("perception")-5))
	return 0.0

func _effective_skill(skill: String) -> float:
	var total_invested: int = skills[skill] + _bg_skill_bonus.get(skill, 0)
	return total_invested * (1.0 + _gov_mod(skill) * 0.1)

func _crit_chance() -> float:
	var per_mod: float = float(_eff_stat("perception") - 5)
	var dex_mod: float = float(_eff_stat("dexterity")  - 5)
	return clampf((per_mod * 0.7 + dex_mod * 0.3) * 3.0, 0.0, 95.0)

func _fmt_effective(val: float) -> String:
	if val == floorf(val): return str(int(val))
	return "%.1f" % val

func _fmt_mod(v: int) -> String:
	return ("+%d" % v) if v >= 0 else str(v)

func _calc_max_hp(level: int = 1) -> int:
	var con_mod = _eff_stat("constitution") - 5
	return ((5 + con_mod) * 10) * level

# ── Callbacks ──────────────────────────────────────────────────────────────────
func _on_stat(stat: String, delta: int) -> void:
	var nv = stats[stat] + delta
	if nv < STAT_MIN or nv > STAT_MAX: return
	if delta == 1 and stat_points <= 0: return
	stats[stat]  = nv
	stat_points -= delta
	var excess = _invested_skill_total() - _skill_pool()
	if excess > 0:
		for s in SKILL_NAMES:
			if excess <= 0: break
			var cut = min(skills[s], excess)
			skills[s] -= cut
			excess    -= cut
	_refresh_all()

func _on_skill(skill: String, delta: int) -> void:
	var total_invested: int = skills[skill] + _bg_skill_bonus.get(skill, 0)
	if delta ==  1 and _skill_points_remaining() <= 0: return
	if delta ==  1 and total_invested >= SKILL_CAP: return
	if delta == -1 and skills[skill] <= 0: return
	skills[skill] += delta
	_refresh_all()

func _on_background(bg_name: String) -> void:
	background    = bg_name
	bonus_choices = BACKGROUND_BONUS_OPTIONS[bg_name]
	bonus_stat    = bonus_choices[0] if bonus_choices.size() == 1 else ""
	_bg_skill_bonus = BACKGROUND_SKILLS[bg_name].duplicate()
	_bg_desc_lbl.text = BACKGROUNDS[bg_name]
	for n in _bg_buttons:
		_bg_buttons[n].button_pressed = (n == bg_name)
	var excess = _invested_skill_total() - _skill_pool()
	if excess > 0:
		for s in SKILL_NAMES:
			if excess <= 0: break
			var cut = min(skills[s], excess)
			skills[s] -= cut
			excess    -= cut
	# Also claw back any player-invested points that now exceed the cap
	for s in SKILL_NAMES:
		var bg_pts: int = _bg_skill_bonus.get(s, 0)
		if skills[s] + bg_pts > SKILL_CAP:
			skills[s] = SKILL_CAP - bg_pts
	_refresh_all()

func _feat_available(feat_name: String) -> bool:
	var feat: Dictionary = _feats[feat_name]
	if feat["req_stat"] != "" and _eff_stat(feat["req_stat"]) < feat["req_stat_val"]:
		return false
	var req_skill: String = feat["req_skill"]
	if req_skill != "":
		var total: int = skills.get(req_skill, 0) + _bg_skill_bonus.get(req_skill, 0)
		if total < feat["req_skill_val"]:
			return false
	return true

func _on_feat_select(feat_name: String) -> void:
	selected_feat = "" if selected_feat == feat_name else feat_name
	_refresh_all()

func _on_bonus_select(stat: String) -> void:
	bonus_stat = "" if stat == bonus_stat else stat
	var excess = _invested_skill_total() - _skill_pool()
	if excess > 0:
		for s in SKILL_NAMES:
			if excess <= 0: break
			var cut = min(skills[s], excess)
			skills[s] -= cut
			excess    -= cut
	_refresh_all()

func _on_begin() -> void:
	if _name_input.text.strip_edges().is_empty():
		_begin_btn.text = "Enter a name first!"
		return
	if background.is_empty():
		_begin_btn.text = "Choose a background first!"
		_show_panel(0)
		return
	if bonus_choices.size() > 1 and bonus_stat.is_empty():
		_begin_btn.text = "Choose your bonus stat (★) first!"
		_show_panel(1)
		return
	if selected_feat != "" and not _feat_available(selected_feat):
		_begin_btn.text = "Your stats no longer meet that feat's requirements!"
		_show_panel(3)
		_refresh_all()
		return

	var final_stats = stats.duplicate()
	if not bonus_stat.is_empty():
		final_stats[bonus_stat] += 1

	var final_skills: Dictionary = {}
	for s in SKILL_NAMES:
		final_skills[s] = skills[s] + _bg_skill_bonus.get(s, 0)

	var max_hp = _calc_max_hp()
	GameManager.player_data = {
		"name":                   _name_input.text.strip_edges(),
		"stats":                  final_stats,
		"skills":                 final_skills,
		"background":             background,
		"max_hp":                 max_hp,
		"current_hp":             max_hp,
		"equipment":              _build_starting_equipment(),
		"inventory":              [],
		"known_cooking_recipes":  ["simple_meal"],
		"level":                  1,
		"xp":                     0,
		"unspent_skill_points":   0,
		"unspent_stat_points":    0,
		"feats":                  [{"id": _feats[selected_feat]["id"], "name": selected_feat, "description": _feats[selected_feat]["effect"]}] if selected_feat != "" else [],
	}
	GameManager.player_data["_saved_grid_cell"] = [18, 6]

	# Reset world/run state so a new game always starts fresh in The Ditch,
	# regardless of where a previous playthrough ended.
	GameManager.world_pos = Vector2i(10, 14)
	GameManager.world_layer = 0
	GameManager.current_layer = 0
	GameManager.explored_tiles = {}
	GameManager.smoke_zones = []
	GameManager.current_zone = null
	GameManager.combat_mode = false
	GameManager.tactical_mode = false
	GameManager.is_sneaking = false

	GameManager.auto_save()
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _build_starting_equipment() -> Dictionary:
	return {
		"hand_1":          null,
		"hand_2":          null,
		"head":            null,
		"torso":           DataManager.get_item("tunic"),
		"feet":            DataManager.get_item("sandals"),
		"back":            null,
		"right_upper_arm": null,
		"left_upper_arm":  null,
		"right_forearm":   null,
		"left_forearm":    null,
		"necklace":        null,
		"ring_right_1":    null,
		"ring_right_2":    null,
		"ring_left_1":     null,
		"ring_left_2":     null,
	}

# ── Refresh ────────────────────────────────────────────────────────────────────
func _refresh_all() -> void:
	_stat_point_lbl.text = "Points: %d" % stat_points
	for stat in STAT_NAMES:
		var eff = _eff_stat(stat)
		_stat_val_lbls[stat].text  = str(stats[stat])
		var mod_val = eff - 5
		_stat_mod_lbls[stat].text  = _fmt_mod(mod_val)
		_stat_mod_lbls[stat].modulate = Color(1.0, 0.85, 0.2) if stat == bonus_stat else Color(1, 1, 1)
		_stat_minus_btns[stat].disabled = (stats[stat] <= STAT_MIN)
		_stat_plus_btns[stat].disabled  = (stats[stat] >= STAT_MAX or stat_points <= 0)
		var eligible = stat in bonus_choices
		_stat_bonus_btns[stat].visible        = eligible
		_stat_bonus_btns[stat].button_pressed = (stat == bonus_stat)

	var sp = _skill_points_remaining()
	_skill_point_lbl.text = "Points: %d" % sp
	for skill in SKILL_NAMES:
		var total_invested: int = skills[skill] + _bg_skill_bonus.get(skill, 0)
		_skill_invested_lbls[skill].text  = str(total_invested)
		_skill_total_lbls[skill].text     = _fmt_effective(_effective_skill(skill))
		_skill_minus_btns[skill].disabled = (skills[skill] <= 0)
		_skill_plus_btns[skill].disabled  = (sp <= 0 or total_invested >= SKILL_CAP)

	var max_hp = _calc_max_hp()
	_hp_bar.max_value = max_hp
	_hp_bar.value     = max_hp
	_hp_label.text    = "%d / %d" % [max_hp, max_hp]

	if _crit_lbl != null:
		var cc: float = _crit_chance()
		_crit_lbl.text = "Crit chance: %.1f%%" % cc if cc > 0.0 else "Crit chance: — (need PER or DEX > 5)"

	for feat_name in _feats.keys():
		var avail: bool = _feat_available(feat_name)
		var f_btn: Button = _feat_buttons[feat_name]
		f_btn.disabled = not avail
		f_btn.button_pressed = (feat_name == selected_feat)
		_feat_req_lbls[feat_name].add_theme_color_override("font_color",
			Color(0.4, 0.8, 0.4) if avail else Color(0.75, 0.35, 0.35))
	_feat_desc_lbl.text = _feats[selected_feat]["effect"] if selected_feat != "" else "Select a feat."

	_begin_btn.text = "BEGIN"
