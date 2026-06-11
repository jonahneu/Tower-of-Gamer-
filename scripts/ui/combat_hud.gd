extends Control
# CombatHUD — overlays shown during combat.
#
# Layout:
#   • Turn order bar     — top, visible whole combat.
#   • Combat info panel  — bottom, visible only on player's turn (AP/MP + End Turn).
#   • Hotbar panel       — very bottom, always visible (8 square action slots).
#   • Combat log         — right side, visible whole combat.

# ── Hotbar ────────────────────────────────────────────────────────────────────
const HOTBAR_SLOTS: int = 8
const SLOT_SIZE: int    = 72   # px per square slot

var _hotbar_panel: Control = null
var _hotbar_slot_panels: Array  = []   # Array[PanelContainer]
var _hotbar_slot_styles: Array  = []   # Array[StyleBoxFlat]
var _hotbar_slot_name_lbls: Array = [] # Array[Label]
var _hotbar_slot_cost_lbls: Array = [] # Array[Label]
var _hotbar_slot_icons: Array     = [] # Array[ItemIcon]
var _hotbar_tooltip: Control      = null
var _hotbar_slot_defs: Array    = []   # current list of action dicts
var _hotbar_locked: bool        = true
var _hotbar_lock_btn: Button    = null
var _hotbar_swap_idx: int       = -1   # slot selected for swap (unlock mode)

# ── Combat info panel (AP/MP + End Turn) ─────────────────────────────────────
var _combat_info_panel: Control  = null
var _ap_bar: ProgressBar         = null
var _ap_lbl: Label               = null
var _mp_bar: ProgressBar         = null
var _mp_lbl: Label               = null
var _status_lbl: Label           = null

# ── Combat log panel ──────────────────────────────────────────────────────────
var _log_panel: Control     = null
var _log_vbox: VBoxContainer = null
var _log_scroll: ScrollContainer = null
const LOG_MAX_ENTRIES: int = 60

# ── Turn order bar ────────────────────────────────────────────────────────────
var _turn_order_bar: Control     = null
var _turn_order_hbox: HBoxContainer = null
var _to_entities: Array[Entity]      = []
var _to_panels:   Array[PanelContainer] = []
var _to_styles:   Array[StyleBoxFlat]   = []
var _to_hp_lbls:  Array[Label]          = []

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_hotbar_panel = _build_hotbar_panel()
	add_child(_hotbar_panel)

	_combat_info_panel = _build_combat_info_panel()
	_combat_info_panel.visible = false
	add_child(_combat_info_panel)

	_turn_order_bar = _build_turn_order_bar()
	_turn_order_bar.visible = false
	add_child(_turn_order_bar)

	_log_panel = _build_log_panel()
	_log_panel.visible = false
	add_child(_log_panel)

	_hotbar_tooltip = _build_hotbar_tooltip()
	_hotbar_tooltip.visible = false
	_hotbar_tooltip.z_index = 250
	add_child(_hotbar_tooltip)

	EventBus.combat_started.connect(_on_combat_started)
	EventBus.combat_ended.connect(_on_combat_ended)
	EventBus.tactical_started.connect(_on_tactical_started)
	EventBus.tactical_ended.connect(_on_tactical_ended)
	EventBus.turn_started.connect(_on_turn_started)
	EventBus.turn_ended.connect(_on_turn_ended)
	EventBus.damage_dealt.connect(_on_damage_dealt)
	EventBus.attack_resolved.connect(_on_attack_resolved)
	EventBus.resources_changed.connect(_on_resources_changed)
	EventBus.combat_participant_added.connect(
		func(_e): _rebuild_turn_order(CombatManager.participants))
	EventBus.combat_log.connect(_on_combat_log)
	EventBus.dialogue_opened.connect(func(_e): _hotbar_panel.visible = false)
	EventBus.dialogue_closed.connect(func(_e): _hotbar_panel.visible = true)
	EventBus.inventory_changed.connect(_rebuild_hotbar)

	_rebuild_hotbar()

# ══════════════════════════════════════════════════════════════════════════════
# HOTBAR
# ══════════════════════════════════════════════════════════════════════════════

func _build_hotbar_panel() -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	root.offset_top = -(SLOT_SIZE + 18)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.04, 0.07, 0.90)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 8)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 5)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(hbox)

	_hotbar_slot_panels.clear()
	_hotbar_slot_styles.clear()
	_hotbar_slot_name_lbls.clear()
	_hotbar_slot_cost_lbls.clear()
	_hotbar_slot_icons.clear()

	for i in range(HOTBAR_SLOTS):
		var slot := _build_slot_node(i)
		hbox.add_child(slot)

	# Spacer
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(10, 0)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(spacer)

	# Lock/unlock button
	_hotbar_lock_btn = Button.new()
	_hotbar_lock_btn.text = "Lock"
	_hotbar_lock_btn.custom_minimum_size = Vector2(54, SLOT_SIZE)
	_hotbar_lock_btn.add_theme_font_size_override("font_size", 11)
	_hotbar_lock_btn.pressed.connect(_toggle_lock)
	hbox.add_child(_hotbar_lock_btn)
	_update_lock_btn_style()

	return root

func _build_slot_node(i: int) -> PanelContainer:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12)
	style.border_width_left   = 1
	style.border_width_right  = 1
	style.border_width_top    = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.28, 0.28, 0.35)
	style.corner_radius_top_left     = 3
	style.corner_radius_top_right    = 3
	style.corner_radius_bottom_left  = 3
	style.corner_radius_bottom_right = 3

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   4)
	margin.add_theme_constant_override("margin_right",  4)
	margin.add_theme_constant_override("margin_top",    4)
	margin.add_theme_constant_override("margin_bottom", 4)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(col)

	# Top row: key number (left) + range (right)
	var top_row := HBoxContainer.new()
	top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(top_row)

	var key_lbl := Label.new()
	key_lbl.text = str(i + 1) if i < 9 else "0"
	key_lbl.add_theme_font_size_override("font_size", 10)
	key_lbl.add_theme_color_override("font_color", Color(0.50, 0.50, 0.55))
	key_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	key_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_row.add_child(key_lbl)

	# Center: action icon (name shown only on hover, via tooltip)
	var icon := ItemIcon.new()
	icon.custom_minimum_size = Vector2(36, 36)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(icon)
	_hotbar_slot_icons.append(icon)

	var name_lbl := Label.new()
	name_lbl.visible = false
	col.add_child(name_lbl)

	# Bottom: AP cost
	var cost_lbl := Label.new()
	cost_lbl.add_theme_font_size_override("font_size", 10)
	cost_lbl.add_theme_color_override("font_color", Color(0.55, 0.75, 0.95))
	cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(cost_lbl)

	_hotbar_slot_panels.append(panel)
	_hotbar_slot_styles.append(style)
	_hotbar_slot_name_lbls.append(name_lbl)
	_hotbar_slot_cost_lbls.append(cost_lbl)

	var captured_i := i
	panel.gui_input.connect(func(ev: InputEvent): _on_slot_gui_input(ev, captured_i))

	return panel

func _rebuild_hotbar() -> void:
	_hotbar_slot_defs = _build_slot_defs()
	# In tactical mode weapon slots are non-functional (movement only); show as inactive.
	var in_combat: bool = GameManager.combat_mode and not CombatManager.tactical_mode
	var is_player_turn: bool = in_combat and CombatManager.is_player_turn()
	var ap: int = CombatManager.current_ap() if is_player_turn else 0

	for i in range(HOTBAR_SLOTS):
		var def: Dictionary = _hotbar_slot_defs[i] if i < _hotbar_slot_defs.size() else {"type": "empty"}
		var info: Dictionary = _slot_display_info(def, ap, is_player_turn)
		var style: StyleBoxFlat = _hotbar_slot_styles[i]

		# Swap-selected highlight
		if not _hotbar_locked and _hotbar_swap_idx == i:
			style.bg_color = Color(0.40, 0.35, 0.10)
			style.border_color = Color(1.0, 0.85, 0.20)
		elif not _hotbar_locked:
			style.bg_color = Color(0.10, 0.10, 0.16)
			style.border_color = Color(0.45, 0.45, 0.28)
		elif info.get("enabled", false) and is_player_turn:
			style.bg_color = info.get("bg_color", Color(0.08, 0.08, 0.12))
			style.border_color = Color(0.40, 0.40, 0.50)
		else:
			var base: Color = info.get("bg_color", Color(0.08, 0.08, 0.12))
			style.bg_color = Color(base.r * 0.55, base.g * 0.55, base.b * 0.55)
			style.border_color = Color(0.22, 0.22, 0.28)

		_hotbar_slot_name_lbls[i].text = info.get("label", "")
		_hotbar_slot_cost_lbls[i].text = info.get("cost", "")
		if i < _hotbar_slot_icons.size():
			_hotbar_slot_icons[i].item_id = info.get("icon_id", "")

		var name_color: Color = Color(0.88, 0.88, 0.88) if info.get("enabled", false) and is_player_turn \
				else Color(0.48, 0.48, 0.52)
		_hotbar_slot_name_lbls[i].add_theme_color_override("font_color", name_color)

		# Mouse enter/exit for attack range overlay + name/description tooltip
		if _hotbar_slot_panels[i].mouse_entered.get_connections().size() == 0:
			var cap_i := i
			_hotbar_slot_panels[i].mouse_entered.connect(func():
				_on_slot_hovered(cap_i)
				_show_hotbar_tooltip(cap_i))
			_hotbar_slot_panels[i].mouse_exited.connect(func():
				EventBus.hide_attack_range_overlay.emit()
				_hide_hotbar_tooltip())

func _build_hotbar_tooltip() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(180, 0)
	var style := StyleBoxFlat.new()
	style.bg_color     = Color(0.10, 0.10, 0.14, 0.97)
	style.border_color = Color(0.50, 0.44, 0.32)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left",   8)
	margin.add_theme_constant_override("margin_right",  8)
	margin.add_theme_constant_override("margin_top",     6)
	margin.add_theme_constant_override("margin_bottom",  6)
	panel.add_child(margin)
	var lbl := RichTextLabel.new()
	lbl.name = "Label"
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.bbcode_enabled  = true
	lbl.scroll_active   = false
	lbl.fit_content     = true
	lbl.autowrap_mode   = TextServer.AUTOWRAP_WORD_SMART
	lbl.custom_minimum_size = Vector2(180, 0)
	lbl.add_theme_font_size_override("normal_font_size", 12)
	lbl.add_theme_color_override("default_color", Color(0.92, 0.88, 0.80))
	margin.add_child(lbl)
	return panel

func _show_hotbar_tooltip(idx: int) -> void:
	if _hotbar_tooltip == null or idx >= _hotbar_slot_defs.size():
		return
	var def: Dictionary = _hotbar_slot_defs[idx]
	if def.get("type", "empty") == "empty":
		return
	var in_combat: bool = GameManager.combat_mode and not CombatManager.tactical_mode
	var is_player_turn: bool = in_combat and CombatManager.is_player_turn()
	var ap: int = CombatManager.current_ap() if is_player_turn else 0
	var info: Dictionary = _slot_display_info(def, ap, is_player_turn)
	var label: String = info.get("label", "")
	if label == "" or label == "—":
		return
	var description: String = ""
	if info.has("ability"):
		description = (info["ability"] as Dictionary).get("description", "")
	if description == "" and info.has("item"):
		description = (info["item"] as Dictionary).get("description", "")
	var text: String = "[b]%s[/b]" % label
	if description != "":
		text += "\n" + description
	if info.has("item") and (info["item"] as Dictionary).get("poisoned", false):
		text += "\n[color=#44ee44]Poisoned — applies poison on hit (lasts until rest)[/color]"
	var margin := _hotbar_tooltip.get_child(0) as MarginContainer
	if margin == null:
		return
	var lbl := margin.get_child(0) as RichTextLabel
	if lbl == null:
		return
	lbl.text = text
	var vp_size := get_viewport().get_visible_rect().size
	var pos := get_viewport().get_mouse_position() + Vector2(18, -16)
	pos.x = clampf(pos.x, 4.0, vp_size.x - 200.0)
	pos.y = clampf(pos.y, 4.0, vp_size.y - 100.0)
	_hotbar_tooltip.position = pos
	_hotbar_tooltip.visible = true

func _hide_hotbar_tooltip() -> void:
	if _hotbar_tooltip != null:
		_hotbar_tooltip.visible = false

func _build_slot_defs() -> Array:
	var saved: Array = GameManager.player_data.get("hotbar", [])
	if not saved.is_empty():
		# Resolve saved refs against current equipment/spells
		return _resolve_saved_hotbar(saved)
	return _auto_hotbar_defs()

func _auto_hotbar_defs() -> Array:
	var defs: Array = []
	var equip: Dictionary = GameManager.player_data.get("equipment",
		{"hand_1": null, "hand_2": null})

	for hand_key in ["hand_1", "hand_2"]:
		var raw = equip.get(hand_key, null)
		if raw == null:
			continue
		var item: Dictionary = raw
		if item.get("ap_cost", 0) == 0:
			continue
		defs.append({"type": "weapon", "hand": hand_key})
		for ability in item.get("abilities", []):
			defs.append({"type": "ability", "hand": hand_key, "ability_id": ability.get("id", "")})

	var h1 = equip.get("hand_1", null)
	var h2 = equip.get("hand_2", null)
	var h1_free: bool = h1 == null or (h1 as Dictionary).get("ap_cost", 0) == 0
	var h2_free: bool = h2 == null or (h2 as Dictionary).get("ap_cost", 0) == 0
	if h1_free or h2_free:
		defs.append({"type": "unarmed"})

	for spell_id in GameManager.player_data.get("spells", []):
		defs.append({"type": "spell", "spell_id": str(spell_id)})

	# Consumable hotbar items (blast_tag, etc.)
	var inv_items: Array = GameManager.player_data.get("inventory", [])
	var added_ids: Dictionary = {}
	for inv_item in inv_items:
		var item_id: String = inv_item.get("id", "")
		if inv_item.get("special", "") == "blast_tag" and not added_ids.has(item_id):
			added_ids[item_id] = true
			defs.append({"type": "item", "item_id": item_id})

	while defs.size() < HOTBAR_SLOTS:
		defs.append({"type": "empty"})

	return defs.slice(0, HOTBAR_SLOTS)

func _resolve_saved_hotbar(saved: Array) -> Array:
	var equip: Dictionary = GameManager.player_data.get("equipment",
		{"hand_1": null, "hand_2": null})
	var spells: Array = GameManager.player_data.get("spells", [])
	var spell_ids: Array = spells.map(func(s): return str(s))
	var result: Array = []

	for slot in saved:
		var resolved: Dictionary = {"type": "empty"}
		if slot["type"] == "weapon":
			var raw = equip.get(slot.get("hand", ""), null)
			if raw != null and (raw as Dictionary).get("ap_cost", 0) > 0:
				resolved = slot
		elif slot["type"] == "ability":
			var raw = equip.get(slot.get("hand", ""), null)
			if raw != null:
				var item: Dictionary = raw
				for ab in item.get("abilities", []):
					if ab.get("id", "") == slot.get("ability_id", ""):
						resolved = slot
						break
		elif slot["type"] == "unarmed":
			resolved = slot
		elif slot["type"] == "spell":
			if slot.get("spell_id", "") in spell_ids:
				resolved = slot
		result.append(resolved)

	while result.size() < HOTBAR_SLOTS:
		result.append({"type": "empty"})
	result = result.slice(0, HOTBAR_SLOTS)

	# Inject any newly equipped weapons/spells missing from the saved order.
	var fresh: Array = _auto_hotbar_defs()
	for fresh_def in fresh:
		if fresh_def.get("type", "empty") == "empty":
			continue
		var already_present: bool = false
		for r in result:
			if r.get("type") == fresh_def.get("type") \
					and r.get("hand", "") == fresh_def.get("hand", "") \
					and r.get("spell_id", "") == fresh_def.get("spell_id", "") \
					and r.get("ability_id", "") == fresh_def.get("ability_id", ""):
				already_present = true
				break
		if already_present:
			continue
		for i in range(result.size()):
			if result[i].get("type", "empty") == "empty":
				result[i] = fresh_def
				break

	return result

func _slot_display_info(def: Dictionary, ap: int, is_player_turn: bool) -> Dictionary:
	var equip: Dictionary = GameManager.player_data.get("equipment",
		{"hand_1": null, "hand_2": null})

	match def.get("type", "empty"):
		"weapon":
			var raw = equip.get(def.get("hand", ""), null)
			if raw == null:
				return {"label": "—", "cost": "", "enabled": false, "bg_color": Color(0.08, 0.08, 0.12), "range": 1}
			var item: Dictionary = raw
			var cost: int = item.get("ap_cost", 0)
			var base_range: int = item.get("range", 1)
			var wrange: int = base_range
			var has_long_ranged: bool = wrange > 1 and GameManager.has_feat("long_ranged")
			if has_long_ranged:
				wrange *= 2
			return {
				"label": item.get("name", "?"),
				"cost": "%d AP" % cost,
				"enabled": ap >= cost,
				"bg_color": Color(0.10, 0.16, 0.28),
				"range": wrange,
				"base_range": base_range if has_long_ranged else -1,
				"item": item,
				"icon_id": item.get("id", ""),
			}
		"ability":
			var raw = equip.get(def.get("hand", ""), null)
			if raw == null:
				return {"label": "—", "cost": "", "enabled": false, "bg_color": Color(0.08, 0.08, 0.12), "range": 1}
			var item: Dictionary = raw
			for ab in item.get("abilities", []):
				if ab.get("id", "") == def.get("ability_id", ""):
					var abl: Dictionary = ab
					var cost: int = abl.get("ap_cost", 0)
					var on_cd: bool = CombatManager.get_cooldown(GameManager.player, abl.get("id", "")) > 0
					var needs_load: bool = abl.get("requires_loaded", false)
					var loaded: bool = CombatManager.is_weapon_loaded(GameManager.player, item.get("name", ""))
					var blocked: bool = on_cd or (needs_load and not loaded)
					return {
						"label": abl.get("label", "?"),
						"cost": "%d AP" % cost,
						"enabled": ap >= cost and not blocked,
						"bg_color": Color(0.18, 0.14, 0.08),
						"range": abl.get("range", item.get("range", 1)),
						"item": item,
						"ability": abl,
						"icon_id": item.get("id", ""),
					}
			return {"label": "—", "cost": "", "enabled": false, "bg_color": Color(0.08, 0.08, 0.12), "range": 1}
		"unarmed":
			return {
				"label": "Unarmed",
				"cost": "2 AP",
				"enabled": ap >= 2,
				"bg_color": Color(0.18, 0.12, 0.22),
				"range": 1,
				"icon_id": "unarmed",
				"item": DataManager.get_item("unarmed"),
			}
		"spell":
			var spell: Dictionary = DataManager.get_item(def.get("spell_id", ""))
			if spell.is_empty():
				return {"label": "?", "cost": "", "enabled": false, "bg_color": Color(0.08, 0.08, 0.12), "range": 1}
			var s_ap: int = spell.get("ap_cost", 0)
			var s_sp: int = spell.get("spirit_cost", 0)
			if s_sp > 0 and GameManager.player != null and GameManager.has_feat("chain_caster"):
				var chain_count: int = CombatManager.turn_state.get(GameManager.player, {}).get("spells_cast", 0)
				if chain_count > 0:
					s_sp = int(round(float(s_sp) * pow(0.9, chain_count)))
			var cur_spirit: int = 0
			if GameManager.player != null and is_instance_valid(GameManager.player):
				cur_spirit = GameManager.player.current_spirit
			var equip2: Dictionary = GameManager.player_data.get("equipment", {"hand_1": null, "hand_2": null})
			var h1 = equip2.get("hand_1", null)
			var h2 = equip2.get("hand_2", null)
			var open_hand: bool = (h1 == null or (h1 as Dictionary).get("ap_cost", 0) == 0) \
					or (h2 == null or (h2 as Dictionary).get("ap_cost", 0) == 0)
			return {
				"label": spell.get("name", "?"),
				"cost": "%d AP %d SP" % [s_ap, s_sp],
				"enabled": ap >= s_ap and cur_spirit >= s_sp and open_hand,
				"bg_color": Color(0.20, 0.10, 0.30),
				"range": spell.get("range", 1),
				"item": spell,
				"icon_id": spell.get("id", ""),
			}
		"item":
			var item_id: String = def.get("item_id", "")
			if item_id == "blast_tag":
				if CombatManager.blast_tag_armed:
					var sp_ok: bool = GameManager.player != null \
							and is_instance_valid(GameManager.player) \
							and GameManager.player.current_spirit >= 2
					return {
						"label": "Detonate",
						"cost": "2 AP  2 SP",
						"enabled": ap >= 2 and sp_ok,
						"bg_color": Color(0.35, 0.15, 0.03),
						"range": 4,
						"icon_id": item_id,
					}
				else:
					return {
						"label": "Blast Tag",
						"cost": "2 AP",
						"enabled": ap >= 2 and is_player_turn,
						"bg_color": Color(0.22, 0.10, 0.02),
						"range": 12,
						"icon_id": item_id,
						"item": DataManager.get_item(item_id),
					}
			return {"label": "—", "cost": "", "enabled": false, "bg_color": Color(0.06, 0.06, 0.09), "range": 1, "icon_id": ""}
		_:
			return {"label": "", "cost": "", "enabled": false, "bg_color": Color(0.06, 0.06, 0.09), "range": 1, "icon_id": ""}

func _on_slot_hovered(idx: int) -> void:
	if not (GameManager.combat_mode and CombatManager.is_player_turn()):
		return
	if idx >= _hotbar_slot_defs.size():
		return
	var def: Dictionary = _hotbar_slot_defs[idx]
	var info: Dictionary = _slot_display_info(def, CombatManager.current_ap(), true)
	var r: int = info.get("range", 1)
	if r > 0 and GameManager.player != null:
		var inner_r: int = info.get("base_range", -1)
		EventBus.show_attack_range_overlay.emit(GameManager.player.grid_cell, r, inner_r)

func _on_slot_gui_input(ev: InputEvent, idx: int) -> void:
	if not (ev is InputEventMouseButton and ev.pressed):
		return
	var btn: int = (ev as InputEventMouseButton).button_index

	if btn == MOUSE_BUTTON_LEFT:
		if not _hotbar_locked:
			# Swap mode
			if _hotbar_swap_idx == -1:
				_hotbar_swap_idx = idx
				_rebuild_hotbar()
			elif _hotbar_swap_idx == idx:
				_hotbar_swap_idx = -1
				_rebuild_hotbar()
			else:
				var tmp: Dictionary = _hotbar_slot_defs[_hotbar_swap_idx]
				_hotbar_slot_defs[_hotbar_swap_idx] = _hotbar_slot_defs[idx]
				_hotbar_slot_defs[idx] = tmp
				GameManager.player_data["hotbar"] = _hotbar_slot_defs.duplicate(true)
				_hotbar_swap_idx = -1
				_rebuild_hotbar()
		else:
			_hotbar_activate_slot(idx)
	elif btn == MOUSE_BUTTON_RIGHT:
		if not _hotbar_locked:
			_hotbar_swap_idx = -1
			_rebuild_hotbar()

func _hotbar_activate_slot(idx: int) -> void:
	if idx >= _hotbar_slot_defs.size():
		return
	var def: Dictionary = _hotbar_slot_defs[idx]

	var in_combat_turn: bool = GameManager.combat_mode and CombatManager.is_player_turn()
	var arming_for_sneak: bool = GameManager.is_sneaking and not GameManager.combat_mode

	if not in_combat_turn and not arming_for_sneak:
		return

	var ap: int = CombatManager.current_ap() if in_combat_turn else 0
	var info: Dictionary = _slot_display_info(def, ap, in_combat_turn)

	# While sneaking outside combat, arm the weapon so the player can pick a target.
	if arming_for_sneak:
		var item: Dictionary = {}
		var r: int = 1
		var inner_r: int = -1
		match def.get("type", "empty"):
			"weapon":
				item = info.get("item", {})
				r = info.get("range", 1)
				inner_r = info.get("base_range", -1)
			"unarmed":
				item = DataManager.get_item("unarmed")
		if not item.is_empty():
			CombatManager.set_pending_weapon(item)
			if GameManager.player != null:
				EventBus.show_attack_range_overlay.emit(GameManager.player.grid_cell, r, inner_r)
		return

	# Normal in-combat activation.
	if not info.get("enabled", false):
		return

	match def.get("type", "empty"):
		"weapon":
			var item: Dictionary = info.get("item", {})
			if not item.is_empty():
				_on_attack_pressed(item)
		"ability":
			var item: Dictionary = info.get("item", {})
			var ability: Dictionary = info.get("ability", {})
			if not item.is_empty() and not ability.is_empty():
				_on_ability_pressed(item, ability)
		"unarmed":
			_on_unarmed_pressed()
		"spell":
			var item: Dictionary = info.get("item", {})
			if not item.is_empty():
				_on_attack_pressed(item)
		"item":
			var item_id: String = def.get("item_id", "")
			if item_id == "blast_tag":
				if CombatManager.blast_tag_armed:
					CombatManager.execute_blast_tag_detonate(GameManager.player)
				else:
					var inv: Array = GameManager.player_data.get("inventory", [])
					for ii in range(inv.size()):
						if inv[ii].get("id", "") == "blast_tag":
							CombatManager.begin_blast_tag_deploy(inv[ii], ii)
							break

func _toggle_lock() -> void:
	_hotbar_locked = not _hotbar_locked
	_hotbar_swap_idx = -1
	_update_lock_btn_style()
	_rebuild_hotbar()

func _update_lock_btn_style() -> void:
	if _hotbar_lock_btn == null:
		return
	if _hotbar_locked:
		_hotbar_lock_btn.text = "Unlock"
		_hotbar_lock_btn.remove_theme_color_override("font_color")
	else:
		_hotbar_lock_btn.text = "Lock"
		_hotbar_lock_btn.add_theme_color_override("font_color", Color(1.0, 0.85, 0.20))

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var in_combat_turn: bool = GameManager.combat_mode and CombatManager.is_player_turn()
	var arming_for_sneak: bool = GameManager.is_sneaking and not GameManager.combat_mode
	if not in_combat_turn and not arming_for_sneak:
		return
	var slot_idx: int = -1
	match event.keycode:
		KEY_1: slot_idx = 0
		KEY_2: slot_idx = 1
		KEY_3: slot_idx = 2
		KEY_4: slot_idx = 3
		KEY_5: slot_idx = 4
		KEY_6: slot_idx = 5
		KEY_7: slot_idx = 6
		KEY_8: slot_idx = 7
	if slot_idx >= 0:
		_hotbar_activate_slot(slot_idx)

# ══════════════════════════════════════════════════════════════════════════════
# MOVE RANGE COMPUTATION
# ══════════════════════════════════════════════════════════════════════════════

func _compute_move_range() -> void:
	var player: Node = GameManager.player
	if player == null or not is_instance_valid(player):
		return
	var tile: TileScene = GameManager.current_zone as TileScene
	if tile == null:
		return

	var player_cell: Vector2i = player.grid_cell
	var mp: int  = CombatManager.current_mp()
	var ap: int  = CombatManager.current_ap()
	var has_runner: bool = GameManager.has_feat("runner")
	var ap_tiles: int    = ap * 2 if has_runner else ap
	var total_range: int = mp + ap_tiles

	var grey: Array[Vector2i]   = []
	var yellow: Array[Vector2i] = []
	var dist: Dictionary = {player_cell: 0}
	var queue: Array     = [player_cell]
	var head: int        = 0

	while head < queue.size():
		var cell: Vector2i = queue[head]
		head += 1
		var d: int = dist[cell]
		if d >= total_range:
			continue
		for off in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
			var nb: Vector2i = cell + off
			if dist.has(nb) or not tile.is_walkable(nb):
				continue
			dist[nb] = d + 1
			if d + 1 <= mp:
				grey.append(nb)
			else:
				yellow.append(nb)
			queue.append(nb)

	# Enemies in weapon range
	var weapon_range: int = _get_player_weapon_range()
	var enemy_cells: Array[Vector2i] = []
	for entity in tile.get_all_entities():
		if entity == player:
			continue
		var is_dead = entity.get("_dead")
		if is_dead == null or is_dead == true:
			continue
		var e_cell = entity.get("grid_cell")
		if e_cell == null:
			continue
		var ec: Vector2i = e_cell
		var dx: int = player_cell.x - ec.x
		var dy: int = player_cell.y - ec.y
		if sqrt(float(dx * dx + dy * dy)) <= float(weapon_range):
			enemy_cells.append(ec)

	EventBus.show_move_range.emit(grey, yellow, enemy_cells)

func _get_player_weapon_range() -> int:
	var equip: Dictionary = GameManager.player_data.get("equipment", {})
	var hand1 = equip.get("hand_1", null)
	if hand1 != null and (hand1 as Dictionary).get("ap_cost", 0) > 0:
		var r: int = (hand1 as Dictionary).get("range", 1)
		if r > 1 and GameManager.has_feat("long_ranged"):
			return r * 2
		return r
	return 1

# ══════════════════════════════════════════════════════════════════════════════
# BUILD — combat info panel (bottom, player turn only)
# ══════════════════════════════════════════════════════════════════════════════

func _build_combat_info_panel() -> Control:
	var hotbar_h: int = SLOT_SIZE + 18
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	root.offset_top    = -(hotbar_h + 100)
	root.offset_bottom = -hotbar_h
	root.mouse_filter = Control.MOUSE_FILTER_STOP

	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.05, 0.08, 0.92)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 10)
	root.add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	margin.add_child(col)

	# Resource bars row
	var bars_row := HBoxContainer.new()
	bars_row.add_theme_constant_override("separation", 32)
	col.add_child(bars_row)

	_ap_bar = _add_bar(bars_row, "AP", Color(0.25, 0.65, 0.95))
	_ap_lbl = _add_bar_label(bars_row)
	_mp_bar = _add_bar(bars_row, "MP", Color(0.30, 0.85, 0.45))
	_mp_lbl = _add_bar_label(bars_row)

	# Spacer + end turn
	var filler := Control.new()
	filler.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bars_row.add_child(filler)

	var end_btn := Button.new()
	end_btn.text = "End Turn  [Space]"
	end_btn.custom_minimum_size = Vector2(140, 36)
	end_btn.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
	end_btn.pressed.connect(func(): CombatManager.end_turn())
	bars_row.add_child(end_btn)

	# Status / hit-chance label
	_status_lbl = Label.new()
	_status_lbl.add_theme_font_size_override("font_size", 13)
	_status_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	_status_lbl.visible = false
	col.add_child(_status_lbl)

	return root

func _add_bar(parent: Control, lbl_text: String, fill_color: Color) -> ProgressBar:
	var section := VBoxContainer.new()
	section.add_theme_constant_override("separation", 3)
	section.custom_minimum_size = Vector2(180, 0)
	parent.add_child(section)

	var header := Label.new()
	header.text = lbl_text
	header.add_theme_font_size_override("font_size", 12)
	header.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	section.add_child(header)

	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(180, 18)
	bar.show_percentage = false
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = fill_color
	bar.add_theme_stylebox_override("fill", fill_style)
	section.add_child(bar)

	return bar

func _add_bar_label(parent: Control) -> Label:
	var lbl := Label.new()
	lbl.text = "—"
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.custom_minimum_size = Vector2(60, 0)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	parent.add_child(lbl)
	return lbl

# ══════════════════════════════════════════════════════════════════════════════
# BUILD — turn order bar (top)
# ══════════════════════════════════════════════════════════════════════════════

func _build_turn_order_bar() -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	root.offset_bottom = 54
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.04, 0.07, 0.90)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	root.add_child(margin)

	_turn_order_hbox = HBoxContainer.new()
	_turn_order_hbox.add_theme_constant_override("separation", 5)
	_turn_order_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_turn_order_hbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	margin.add_child(_turn_order_hbox)

	return root

func _rebuild_turn_order(participants: Array) -> void:
	for child in _turn_order_hbox.get_children():
		child.queue_free()
	_to_entities.clear()
	_to_panels.clear()
	_to_styles.clear()
	_to_hp_lbls.clear()

	for raw in participants:
		var e: Entity = raw as Entity
		if e == null:
			continue

		var style := StyleBoxFlat.new()
		style.bg_color     = Color(0.10, 0.10, 0.14)
		style.border_width_left   = 1
		style.border_width_right  = 1
		style.border_width_top    = 1
		style.border_width_bottom = 1
		style.border_color = Color(0.28, 0.28, 0.35)
		style.corner_radius_top_left     = 4
		style.corner_radius_top_right    = 4
		style.corner_radius_bottom_left  = 4
		style.corner_radius_bottom_right = 4

		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", style)
		panel.custom_minimum_size = Vector2(88, 0)

		var inner := MarginContainer.new()
		inner.add_theme_constant_override("margin_left", 6)
		inner.add_theme_constant_override("margin_right", 6)
		inner.add_theme_constant_override("margin_top", 4)
		inner.add_theme_constant_override("margin_bottom", 4)
		panel.add_child(inner)

		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 1)
		inner.add_child(vbox)

		var name_lbl := Label.new()
		name_lbl.text = e.entity_name
		name_lbl.add_theme_font_size_override("font_size", 11)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_color_override("font_color", Color(0.82, 0.82, 0.82))
		vbox.add_child(name_lbl)

		var hp_lbl := Label.new()
		hp_lbl.text = _hp_text(e)
		hp_lbl.add_theme_font_size_override("font_size", 10)
		hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hp_lbl.add_theme_color_override("font_color", Color(0.60, 0.88, 0.55))
		vbox.add_child(hp_lbl)

		_turn_order_hbox.add_child(panel)
		_to_entities.append(e)
		_to_panels.append(panel)
		_to_styles.append(style)
		_to_hp_lbls.append(hp_lbl)

func _highlight_turn_order(current: Node) -> void:
	for i in range(_to_entities.size()):
		var e: Entity = _to_entities[i]
		if not is_instance_valid(e):
			continue
		var style: StyleBoxFlat = _to_styles[i]
		var hp_lbl: Label = _to_hp_lbls[i]
		hp_lbl.text = _hp_text(e)
		if e == current:
			style.bg_color     = Color(0.20, 0.18, 0.08)
			style.border_color = Color(0.90, 0.78, 0.20)
		else:
			style.bg_color     = Color(0.10, 0.10, 0.14)
			style.border_color = Color(0.28, 0.28, 0.35)

func _hp_text(e: Entity) -> String:
	return "%.1f/%.1f" % [e.current_hp, e.max_hp]

# ══════════════════════════════════════════════════════════════════════════════
# REFRESH — combat info panel
# ══════════════════════════════════════════════════════════════════════════════

func _refresh() -> void:
	var entity: Node = CombatManager.current_entity()
	if entity == null:
		return
	var ap: int     = CombatManager.current_ap()
	var mp: int     = CombatManager.current_mp()
	var max_ap: int = CombatManager.max_ap_for(entity)
	var max_mp: int = CombatManager.max_mp_for(entity)

	_ap_bar.max_value = max_ap
	_ap_bar.value     = ap
	_ap_lbl.text      = "%d / %d" % [ap, max_ap]

	_mp_bar.max_value = max_mp
	_mp_bar.value     = mp
	_mp_lbl.text      = "%d / %d" % [mp, max_mp]

	_rebuild_hotbar()
	_compute_move_range()

func _show_status(text: String) -> void:
	_status_lbl.text    = text
	_status_lbl.visible = true

func show_hit_chance(attacker: Node, defender: Node, skill_name: String) -> void:
	var pct: int = CombatManager.calc_hit_chance(attacker, defender, skill_name)
	_show_status("Hit chance: %d%%" % pct)

# ══════════════════════════════════════════════════════════════════════════════
# BUILD — combat log panel (right side)
# ══════════════════════════════════════════════════════════════════════════════

func _build_log_panel() -> Control:
	var hotbar_h: int = SLOT_SIZE + 18
	var root := Control.new()
	root.anchor_left   = 1.0
	root.anchor_right  = 1.0
	root.anchor_top    = 0.0
	root.anchor_bottom = 1.0
	root.offset_left   = -300
	root.offset_right  = -10
	root.offset_top    = 60
	root.offset_bottom = -(hotbar_h + 105)
	root.mouse_filter  = Control.MOUSE_FILTER_IGNORE

	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.05, 0.08, 0.88)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 8)
	root.add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	margin.add_child(col)

	var header := Label.new()
	header.text = "COMBAT LOG"
	header.add_theme_font_size_override("font_size", 11)
	header.add_theme_color_override("font_color", Color(0.55, 0.55, 0.62))
	col.add_child(header)

	col.add_child(HSeparator.new())

	_log_scroll = ScrollContainer.new()
	_log_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(_log_scroll)

	_log_vbox = VBoxContainer.new()
	_log_vbox.add_theme_constant_override("separation", 6)
	_log_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_scroll.add_child(_log_vbox)

	return root

func _on_combat_log(entry: String) -> void:
	var lbl := Label.new()
	lbl.text = entry
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color(0.82, 0.82, 0.85))
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_vbox.add_child(lbl)

	while _log_vbox.get_child_count() > LOG_MAX_ENTRIES:
		_log_vbox.get_child(0).queue_free()

	_log_scroll.call_deferred("set_v_scroll", 999999)

# ══════════════════════════════════════════════════════════════════════════════
# SIGNAL HANDLERS
# ══════════════════════════════════════════════════════════════════════════════

func _on_combat_started(participants: Array) -> void:
	_rebuild_turn_order(participants)
	_turn_order_bar.visible = true
	_log_panel.visible      = true
	_combat_info_panel.visible = false
	_rebuild_hotbar()
	for child in _log_vbox.get_children():
		child.queue_free()

func _on_combat_ended(_victor: String) -> void:
	_combat_info_panel.visible = false
	_turn_order_bar.visible = false
	_log_panel.visible = false
	_to_entities.clear()
	_to_panels.clear()
	_to_styles.clear()
	_to_hp_lbls.clear()
	EventBus.hide_range_ring.emit()
	EventBus.hide_move_range.emit()
	EventBus.hide_path_preview.emit()
	EventBus.hide_attack_range_overlay.emit()
	_rebuild_hotbar()

func _on_tactical_started(participants: Array) -> void:
	_rebuild_turn_order(participants)
	_turn_order_bar.visible = true
	_log_panel.visible      = true
	_combat_info_panel.visible = false
	_rebuild_hotbar()
	for child in _log_vbox.get_children():
		child.queue_free()

func _on_tactical_ended() -> void:
	_combat_info_panel.visible = false
	_turn_order_bar.visible = false
	_log_panel.visible = false
	_to_entities.clear()
	_to_panels.clear()
	_to_styles.clear()
	_to_hp_lbls.clear()
	EventBus.hide_range_ring.emit()
	EventBus.hide_move_range.emit()
	EventBus.hide_path_preview.emit()
	EventBus.hide_attack_range_overlay.emit()
	_rebuild_hotbar()

func _on_turn_started(entity: Node) -> void:
	_highlight_turn_order(entity)
	if entity == GameManager.player:
		_combat_info_panel.visible = true
		_refresh()
		if _status_lbl != null:
			if CombatManager.tactical_mode:
				_show_status("Tactical mode — use [T] to exit, [Space] to end turn.")
			else:
				_status_lbl.visible = false
	else:
		_combat_info_panel.visible = false
		EventBus.hide_move_range.emit()
		EventBus.hide_path_preview.emit()
		EventBus.hide_attack_range_overlay.emit()
		_rebuild_hotbar()

func _on_turn_ended(_entity: Node) -> void:
	_combat_info_panel.visible = false
	EventBus.hide_range_ring.emit()
	EventBus.hide_move_range.emit()
	EventBus.hide_path_preview.emit()
	EventBus.hide_attack_range_overlay.emit()

func _on_damage_dealt(_entity: Node, _amount: int, _source: String) -> void:
	for i in range(_to_entities.size()):
		if is_instance_valid(_to_entities[i]):
			_to_hp_lbls[i].text = _hp_text(_to_entities[i])

func _on_attack_resolved(attacker: Node, _hit: bool) -> void:
	if attacker == GameManager.player:
		_refresh()

func _on_resources_changed(entity: Node) -> void:
	if entity == GameManager.player and CombatManager.is_player_turn():
		_refresh()

# ── Action handlers ────────────────────────────────────────────────────────────

func _on_attack_pressed(weapon: Dictionary) -> void:
	var ap_cost: int = weapon.get("ap_cost", 0)
	if CombatManager.current_ap() >= ap_cost:
		CombatManager.set_pending_weapon(weapon)
		_show_status("Select a target to attack with %s." % weapon.get("name", "weapon"))

func _on_ability_pressed(weapon: Dictionary, ability: Dictionary) -> void:
	if not CombatManager.spend_ap(ability.get("ap_cost", 0)):
		return
	var entity: Node = CombatManager.current_entity()
	var weapon_name: String = weapon.get("name", "")
	if ability.has("sets_loaded"):
		CombatManager.set_weapon_loaded(entity, weapon_name, ability["sets_loaded"])
	var cd: int = ability.get("cooldown", 0)
	if cd > 0:
		CombatManager.set_cooldown(entity, ability.get("id", ""), cd)
	_show_status("%s used." % ability.get("label", "Ability"))
	_refresh()

func _on_unarmed_pressed() -> void:
	if CombatManager.current_ap() >= 2:
		var unarmed: Dictionary = DataManager.get_item("unarmed")
		CombatManager.set_pending_weapon(unarmed)
		_show_status("Select a target to punch.")
