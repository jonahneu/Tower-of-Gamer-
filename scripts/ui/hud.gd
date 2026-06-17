extends Control

# ── World map config ───────────────────────────────────────────────────────────
const MAP_COLS   = 20
const MAP_ROWS   = 20
const MAP_LAYERS = 3
const MAP_CELL   = 22   # px per map tile square

# ── Panel refs ─────────────────────────────────────────────────────────────────
var _panels: Dictionary = {}   # "stats" | "inventory" | "map" | "journal" -> Control
var _open: String = ""
var _pause_panel: Control
var _dialogue_panel: Control
var _death_panel: Control
var _player_is_dead: bool = false
var _dialogue_name_lbl: Label
var _dialogue_text_lbl: Label
var _dialogue_options_box: VBoxContainer
var _dialogue_note_indicator: Label
var _dialogue_entity: Node = null
var _object_panel: Control
var _object_name_lbl: Label
var _object_desc_lbl: Label
var _object_action_btn: Button
var _object_entity: Node = null
var _object_primary_action: String = ""
var _context_menu: Control = null
var _save_panel: Control
var _load_panel: Control
var _shop_panel: Control = null
var _shop_merchant: Node = null
var _shop_items: Array = []          # [{id, price}] from the merchant
var _shop_selected_idx: int = -1
var _shop_item_btns: Array = []
var _shop_detail_name: Label = null
var _shop_detail_desc: Label = null
var _shop_buy_btn: Button  = null
var _shop_coins_lbl: Label = null
var _shop_title_lbl: Label = null
var _shop_tab_row: HBoxContainer = null
var _shop_buy_tab_btn: Button = null
var _shop_sell_tab_btn: Button = null
var _shop_quota_lbl: Label = null
var _shop_mode: String = "buy"
var _sell_sellable: Array = []
var _sell_daily_remaining: int = 0
var _sell_selected_idx: int = -1
var _sell_item_btns: Array = []
var _sell_on_sale: Callable
var _save_rows: Array = []   # [{char_lbl, time_lbl, btn}]
var _load_rows: Array = []
var _sneak_btn: Button = null
var _tactical_btn: Button = null
var _container_panel: Control = null
var _container_entity: Node = null
var _container_title_lbl: Label = null
var _log_export_lbl: Label = null

# ── Character sheet live labels ────────────────────────────────────────────────
var _cs_name_lbl:   Label
var _cs_level_lbl:  Label
var _cs_bg_lbl:     Label
var _cs_hp_bar:     ProgressBar
var _cs_hp_lbl:     Label
var _cs_xp_bar:     ProgressBar = null
var _cs_xp_lbl:     Label = null
var _cs_pending_row: Control = null     # shown when unspent points > 0
var _cs_pending_lbl: Label = null
var _cs_stat_vals:  Dictionary = {}   # stat -> Label (value)
var _cs_stat_mods:  Dictionary = {}   # stat -> Label (modifier)
var _cs_stat_plus_btns:  Dictionary = {}  # stat -> Button (allocation, hidden when 0 pts)
var _cs_stat_minus_btns: Dictionary = {}  # stat -> Button (refund, hidden unless snapshot)
var _cs_skill_vals:     Dictionary = {}   # skill -> Label (effective)
var _cs_skill_invested: Dictionary = {}   # skill -> Label (invested)
var _cs_skill_plus_btns: Dictionary = {}  # skill -> Button (allocation, hidden when 0 pts)
var _cs_skill_minus_btns: Dictionary = {} # skill -> Button (refund, hidden unless snapshot)
var _cs_confirm_btn: Button = null        # locks in level-up allocation
var _cs_feats_box: VBoxContainer = null        # owned feats list
var _cs_feat_picker_box: VBoxContainer = null  # pick-a-feat section (shown when unspent_feat_points > 0)
var _cs_stats_page:   Control = null             # stats/skills tab content
var _cs_feats_page:   Control = null             # feats tab content
var _cs_bonuses_page: Control = null             # active bonuses tab content
var _cs_bonuses_vbox: VBoxContainer = null       # rebuilt on each refresh
var _cs_tab_btns: Dictionary = {}               # "stats" / "feats" / "bonuses" -> Button
var _cs_active_tab: String = "stats"
var _levelup_banner: Control = null        # level-up notification overlay

# ── Map live refs ──────────────────────────────────────────────────────────────
var _map_layer: int = 0
var _map_layer_lbl: Label
var _equip_slot_labels: Dictionary = {}  # slot_key -> Label (equip slot display)
var _equip_slot_btns: Dictionary   = {}  # slot_key -> Button (for unequip click)
var _equip_slot_icons: Dictionary  = {}  # slot_key -> ItemIcon
var _inv_slot_btns: Array          = []  # inventory item buttons
var _inv_name_lbls: Array          = []  # name label inside each slot
var _inv_count_lbls: Array         = []  # stack-count label inside each slot
var _inv_slot_icons: Array         = []  # ItemIcon nodes inside inventory slots
var _carry_weight_lbl: Label       = null
var _equip_bonus_lbl: Label        = null

# ── Abilities panel ────────────────────────────────────────────────────────────
var _abilities_vbox: VBoxContainer = null

# ── Journal badge ──────────────────────────────────────────────────────────────
var _journal_unread: int       = 0   # total unread (drives toolbar dot)
var _journal_quest_unread: int = 0
var _journal_notes_unread: int = 0
var _journal_badge_bg: Panel   = null  # toolbar dot (circle)
var _journal_quest_dot: Panel  = null  # dot on Quests tab
var _journal_notes_dot: Panel  = null  # dot on Notes tab

# ── Crafting panel ─────────────────────────────────────────────────────────────
var _crafting_opener: Node              = null
var _crafting_recipe_list: VBoxContainer = null
var _crafting_detail_area: VBoxContainer = null
var _crafting_inv_btns: Array           = []
var _crafting_inv_grid: GridContainer   = null
var _crafting_materials: Array          = []   # [{item, inv_idx, count}]
var _crafting_selected_recipe: String   = ""
var _crafting_slotted: Dictionary       = {}   # material_type → {item, inv_idx}
var _crafting_active_tab: String        = "way_of_beasts"  # "way_of_beasts" | "alchemy" | "cooking" | ...
var _crafting_tab_row: HBoxContainer    = null
var _item_info_panel: Control      = null
var _item_hover_tooltip: Control   = null
var _item_info_drop_target: Dictionary = {}
var _drop_btn: Button              = null
var _affix_talisman_btn: Button    = null
var _pile_panel: Control           = null
var _pile_cell: Vector2i           = Vector2i(-1, -1)
var _keyword_popup: Control        = null
var _status_panel: Control         = null
var _status_rows: VBoxContainer    = null
var _status_timer_lbl: Label       = null   # out-of-combat countdown label
var _hp_bar: ProgressBar           = null
var _hp_bar_lbl: Label             = null
var _sp_bar: ProgressBar           = null   # spirit bar
var _sp_bar_lbl: Label             = null
var _sp_bar_row: Control           = null   # hidden until pyromancy is learned
var _spell_bar: Control            = null   # bottom-center spell action bar
var _spell_pick_panel: Control     = null
var _smithing_pick_panel: Control  = null
var _hud_xp_bar: ProgressBar       = null
var _hud_xp_lbl: Label             = null

var _journal_vbox: VBoxContainer = null
var _journal_thread_expanded: Dictionary = {}   # "parent_id::thread_id" -> bool
var _journal_hide_completed: bool = false
var _journal_tab: String = "quests"
var _journal_notes_vbox: VBoxContainer = null
var _journal_search_edit: LineEdit = null
var _journal_notes_search: String = ""

# ── Pickpocket panel ──────────────────────────────────────────────────────────
var _pickpocket_panel: Control = null
var _pickpocket_title_lbl: Label = null
var _pickpocket_body_lbl: Label = null
var _pickpocket_items_box: VBoxContainer = null
var _pickpocket_close_btn: Button = null
var _pickpocket_entity: Node = null
var _pickpocket_fight_on_close: bool = false

# ── Dream panel ───────────────────────────────────────────────────────────────
var _dream_panel: Control = null
var _dream_beat_idx: int = 0
var _dream_text_lbl: Label = null
var _dream_continue_btn: Button = null

const DREAM_BEATS: Array = [
	"The city stands outside you, impossibly tall. Taller than it should be. Taller than it can be.",
	"You are beneath it now. Looking up. The walls go up past where the sky should start.",
	"Something dark and slow rises from the ground at its base. Not smoke. Older than smoke.",
	"The sound comes in under everything else. Not the spirits you have heard at night. Those were small. This is the sound of something vast, waking or being fed.",
	"A column of light connects the highest point to the sky. The sky does not want it. A storm forms where they meet.",
	"The city begins to come apart. Not quickly. The desert moves in at the edges, patient, as if it has been waiting.",
	"The vision cuts. You do not see how it ends.",
]

const DREAM_CONTACT_THREADS: Dictionary = {
	"old_hunter":       {"id": "dream_ask_hunter",           "title": "Ask the Old Hunter about the dream."},
	"smith":            {"id": "dream_ask_smith",             "title": "Ask the smith about the dream."},
	"scribe":           {"id": "dream_ask_scribe",            "title": "Ask the scribe about the dream."},
	"fire_cult_elder":  {"id": "dream_ask_fire_cult_elder",   "title": "Ask the fire cult elder about the dream."},
	"apothecary":       {"id": "dream_ask_apothecary",        "title": "Ask the apothecary about the dream."},
}

# ── Rest panel ─────────────────────────────────────────────────────────────────
var _rest_hunter_camp: bool = false
var _rest_inn_mode: bool = false       # true when resting at the inn (coin cost, no food needed)
var _rest_food_item: Dictionary = {}   # slotted meat item (empty = none)
var _rest_food_inv_idx: int = -1       # index of slotted item in inventory
var _rest_food_lbl: Label = null
var _rest_food_section: Control = null # container hidden in inn mode
var _rest_cost_lbl: Label = null       # shows "Cost: 2 coins" in inn mode
var _rest_elder_mode: bool = false     # elder's fire — food provided free, no coin
var _rest_smith_mode: bool = false     # smith's forge — food provided free, no coin
var _rest_location_lbl: Label = null
var _rest_spirit_lbl: Label = null
var _rest_exhaustion_lbl: Label = null
var _rest_effects_lbl: Label = null
var _rest_rest_btn: Button = null
var _rest_food_list: VBoxContainer = null

# ── Eat / Cook (camping & hunter-camp only) ──────────────────────────────────
var _rest_mode: String = "eat"             # "eat" | "cook"
var _rest_mode_row: HBoxContainer = null
var _rest_eat_btn: Button = null
var _rest_cook_btn: Button = null
var _rest_cook_recipe: String = ""         # selected rest-recipe id (cook mode)
var _rest_cook_recipe_list: VBoxContainer = null
var _rest_cook_slots: Dictionary = {}      # slot_key ("primary"/"secondary_N") -> {"item": Dictionary, "inv_idx": int}
var _rest_cook_slot_box: VBoxContainer = null
var _rest_cook_preview_lbl: Label = null

var _map_cells: Array = []        # flat array of Panel [row*MAP_COLS + col]
var _map_cell_styles: Array = []  # parallel StyleBoxFlat array
var _map_cell_icons: Array = []   # parallel _MapThumb array (pixel thumbnail)
var _map_tooltip: Control = null
var _map_tooltip_lbl: Label = null
var _hover_tooltip: Control = null

const KEYWORD_DEFS: Dictionary = {
	"bleed":   "Bleed\n──────────────────\nOn hit, chance to inflict Bleed based on the target's CON. At the start of each of the target's turns, each stack deals 1d3 damage. Stacks multiple times.",
	"reload":  "Reload\n──────────────────\nMust be reloaded after each shot. Use the Reload action (costs AP) before firing again.",
	"throw":   "Throw\n──────────────────\nCan be thrown at a target within its throw range.",
	"clumsy":             "Clumsy −1\n──────────────────\nThis weapon is awkward to aim precisely. Your governing stat modifier for the attack skill is reduced by 1 when calculating hit chance.",
	"armor_pierce":       "Armor Pierce\n──────────────────\nIgnores 10% of the target's flat and percentage armor.",
	"armor_pierce_light": "Armor Pierce (Light)\n──────────────────\nIgnores 7% of the target's flat and percentage armor.",
}

const STAT_NAMES  = ["strength","dexterity","agility","constitution","intelligence","willpower","perception"]
const STAT_ABBREV = {"strength":"STR","dexterity":"DEX","agility":"AGI",
	"constitution":"CON","intelligence":"INT","willpower":"WIL","perception":"PER"}
const SKILL_NAMES = ["melee","ranged","dodge","convince","intimidate",
	"sneak","sleight_of_hand","alchemy","occultism","smithing","survival","cooking"]
const SKILL_DISPLAY = {"melee":"Melee","ranged":"Ranged","dodge":"Dodge",
	"convince":"Convince","intimidate":"Intimidate",
	"sneak":"Sneak","sleight_of_hand":"Sleight of Hand","alchemy":"Alchemy",
	"occultism":"Occultism","smithing":"Smithing",
	"survival":"Survival","cooking":"Cooking"}

# ══════════════════════════════════════════════════════════════════════════════
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Always-visible HUD elements added FIRST so they render behind all menus/panels
	var hp_widget := _build_hp_bar()
	add_child(hp_widget)

	_status_panel = _build_status_panel()
	_status_panel.visible = false
	add_child(_status_panel)

	# Toolbar sits above the always-visible elements but below panels/popups
	add_child(_build_toolbar())

	# Panels and menus — added after the always-visible elements so they render on top
	_panels["stats"]      = _build_stats_panel()
	_panels["inventory"]  = _build_inventory_panel()
	_panels["map"]        = _build_map_panel()
	_panels["journal"]    = _build_journal_panel()
	_panels["crafting"]   = _build_crafting_panel()
	_panels["rest"]       = _build_rest_panel()
	_panels["abilities"]  = _build_abilities_panel()

	for p in _panels.values():
		p.visible = false
		p.z_index = 2
		add_child(p)

	_pause_panel = _build_pause_panel()
	_pause_panel.visible = false
	_pause_panel.z_index = 2
	add_child(_pause_panel)

	_dialogue_panel = _build_dialogue_panel()
	_dialogue_panel.visible = false
	_dialogue_panel.z_index = 2
	add_child(_dialogue_panel)

	_object_panel = _build_object_panel()
	_object_panel.visible = false
	_object_panel.z_index = 2
	add_child(_object_panel)

	_save_panel = _build_save_panel()
	_save_panel.visible = false
	_save_panel.z_index = 2
	add_child(_save_panel)

	_load_panel = _build_load_panel()
	_load_panel.visible = false
	_load_panel.z_index = 2
	add_child(_load_panel)

	# Tooltips and popups topmost
	_map_tooltip = _build_map_tooltip()
	_map_tooltip.visible = false
	_map_tooltip.z_index = 3
	add_child(_map_tooltip)

	_hover_tooltip = _build_hover_tooltip()
	_hover_tooltip.visible = false
	_hover_tooltip.z_index = 3
	add_child(_hover_tooltip)

	_item_info_panel = _build_item_info_panel()
	_item_info_panel.visible = false
	_item_info_panel.z_index = 3
	add_child(_item_info_panel)

	_item_hover_tooltip = _build_item_hover_tooltip()
	_item_hover_tooltip.visible = false
	_item_hover_tooltip.z_index = 250
	add_child(_item_hover_tooltip)

	_pile_panel = _build_pile_panel()
	_pile_panel.visible = false
	_pile_panel.z_index = 2
	add_child(_pile_panel)

	_keyword_popup = _build_keyword_popup()
	_keyword_popup.visible = false
	_keyword_popup.z_index = 3
	add_child(_keyword_popup)

	_shop_panel = _build_shop_panel()
	_shop_panel.visible = false
	_shop_panel.z_index = 2
	add_child(_shop_panel)

	_container_panel = _build_container_panel()
	_container_panel.visible = false
	_container_panel.z_index = 2
	add_child(_container_panel)

	# Death panel added last so it renders over everything
	_death_panel = _build_death_panel()
	_death_panel.visible = false
	add_child(_death_panel)

	_pickpocket_panel = _build_pickpocket_panel()
	_pickpocket_panel.visible = false
	_pickpocket_panel.z_index = 2
	add_child(_pickpocket_panel)

	# Dream panel — added after death panel so it renders over everything else
	_dream_panel = _build_dream_panel()
	_dream_panel.visible = false
	add_child(_dream_panel)

	# Spell pick panel — added last so it renders over dialogue/dream panels
	_spell_pick_panel = _build_spell_pick_panel()
	_spell_pick_panel.visible = false
	add_child(_spell_pick_panel)

	_smithing_pick_panel = _build_smithing_pick_panel()
	_smithing_pick_panel.visible = false
	add_child(_smithing_pick_panel)

	EventBus.interaction_triggered.connect(_on_interaction_triggered)
	EventBus.show_context_menu.connect(_on_show_context_menu)
	EventBus.entity_hovered.connect(_on_entity_hovered)
	EventBus.attack_resolved.connect(func(_a, _h): if _hover_tooltip: _hover_tooltip.visible = false)
	EventBus.open_crafting_ui.connect(_on_open_crafting_ui)
	EventBus.journal_updated.connect(_on_journal_updated)
	EventBus.status_applied.connect(func(_e, _s): _refresh_status_panel())
	EventBus.status_cleared.connect(func(_e, _s): _refresh_status_panel())
	EventBus.turn_started.connect(func(_e): _refresh_status_panel())
	EventBus.combat_ended.connect(func(_v): _refresh_status_panel())
	# Out-of-combat bleed ticks emit resources_changed — refresh so tick values stay current
	EventBus.resources_changed.connect(func(e): if e == GameManager.player: _refresh_status_panel())
	EventBus.player_died.connect(_on_player_died)
	EventBus.damage_floater.connect(_spawn_floater)
	EventBus.open_rest_ui.connect(_on_open_rest_ui)
	EventBus.open_inn_rest_ui.connect(_on_open_inn_rest_ui)
	EventBus.open_elder_rest_ui.connect(_on_open_elder_rest_ui)
	EventBus.open_smith_rest_ui.connect(_on_open_smith_rest_ui)
	EventBus.open_shop_ui.connect(_on_open_shop_ui)
	EventBus.open_dream_scene.connect(_open_dream)
	EventBus.player_rested.connect(func(): _refresh_status_panel())
	EventBus.xp_gained.connect(_on_xp_gained)
	EventBus.leveled_up.connect(_on_leveled_up)
	EventBus.inventory_changed.connect(_refresh_inventory)
	EventBus.note_added.connect(func(_id: String, _title: String):
		if _journal_notes_vbox != null and _journal_tab == "notes":
			_refresh_notes()
		if _dialogue_panel != null and _dialogue_panel.visible and _dialogue_note_indicator != null:
			_dialogue_note_indicator.modulate.a = 1.0
			var tw := create_tween()
			tw.tween_interval(2.0)
			tw.tween_property(_dialogue_note_indicator, "modulate:a", 0.0, 0.8))
	EventBus.sneak_toggled.connect(_on_sneak_toggled)
	EventBus.tactical_started.connect(func(_p): _on_tactical_state_changed(true))
	EventBus.tactical_ended.connect(func(): _on_tactical_state_changed(false))
	EventBus.world_layer_changed.connect(func(l): _map_layer = l)
	EventBus.combat_started.connect(func(_p): _close_all(); _on_tactical_state_changed(false))
	EventBus.zone_exit_requested.connect(func(_d): _close_all())
	EventBus.zone_entered.connect(_close_all)
	EventBus.open_spell_pick_ui.connect(_on_open_spell_pick_ui)
	EventBus.open_smithing_pick_ui.connect(_on_open_smithing_pick_ui)

func _process(_delta: float) -> void:
	if _hover_tooltip != null and _hover_tooltip.visible:
		_hover_tooltip.position = get_viewport().get_mouse_position() + Vector2(14, -28)
	# Update out-of-combat status tick countdown
	if is_instance_valid(_status_timer_lbl) and not GameManager.combat_mode:
		var player = GameManager.player
		var t: float = float(player.get("_oc_status_timer")) if player != null else 0.0
		var secs_left: int = ceili(10.0 - t)
		_status_timer_lbl.text = "next tick in %ds" % clampi(secs_left, 0, 10)
	# Update HP bar
	var p = GameManager.player
	if p != null and is_instance_valid(p) and _hp_bar != null:
		var cur: float = p.current_hp
		var mx: float  = p.max_hp
		_hp_bar.max_value = mx
		_hp_bar.value     = cur
		_hp_bar_lbl.text  = "%.1f / %.1f" % [cur, mx]
	# Update Spirit bar
	if _sp_bar != null and _sp_bar_row != null:
		var pyro: bool = GameManager.player_data.get("pyromancy_visible", false)
		_sp_bar_row.visible = pyro
		_sp_bar.visible = pyro
		if pyro and p != null and is_instance_valid(p):
			_sp_bar.max_value = maxi(1, p.max_spirit)
			_sp_bar.value     = p.current_spirit
			_sp_bar_lbl.text  = "%d / %d" % [p.current_spirit, p.max_spirit]
	# Update HUD XP bar
	if _hud_xp_bar != null and not GameManager.player_data.is_empty():
		var d: Dictionary  = GameManager.player_data
		var lvl: int       = d.get("level", 1)
		var xp: int        = d.get("xp", 0)
		var thr: Array     = GameManager.XP_THRESHOLDS
		var at_max: bool   = lvl >= thr.size() - 1
		if at_max:
			_hud_xp_bar.max_value = 1
			_hud_xp_bar.value     = 1
			_hud_xp_lbl.text      = "MAX"
		else:
			var xp_floor: int = thr[lvl]
			var xp_ceil: int  = thr[lvl + 1]
			_hud_xp_bar.max_value = xp_ceil - xp_floor
			_hud_xp_bar.value     = xp - xp_floor
			_hud_xp_lbl.text      = "%d / %d" % [xp - xp_floor, xp_ceil - xp_floor]

func _input(event: InputEvent) -> void:
	if _player_is_dead: return
	if not (event is InputEventKey and event.pressed): return
	match event.keycode:
		KEY_C:      _toggle("stats")
		KEY_I:      _toggle("inventory")
		KEY_M:      _toggle("map")
		KEY_J:      _toggle("journal")
		KEY_K:      _toggle("crafting")
		KEY_B:      _toggle("abilities")
		KEY_R:      _toggle("rest")
		KEY_Z:
			if not GameManager.combat_mode:
				_toggle_sneak()
		KEY_T:
			if not GameManager.combat_mode:
				_toggle_tactical()
		KEY_F5:
			GameManager.save_to_slot(0)
			_show_save_toast()
		KEY_ESCAPE: _on_escape()
		KEY_SPACE:
			if GameManager.combat_mode and CombatManager.is_player_turn():
				CombatManager.end_turn()

func _toggle(name: String) -> void:
	if _open == name:
		_close_all()
		return
	_close_all()
	_open = name
	_panels[name].visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	if name == "stats":
		_cs_switch_tab("stats")
		_refresh_stats()
	if name == "inventory": _refresh_inventory()
	if name == "map":       _refresh_map()
	if name == "journal":
		_refresh_journal()
		_refresh_notes()
	if name == "crafting":   _refresh_crafting()
	if name == "abilities":  _refresh_abilities()
	if name == "rest":       _refresh_rest()
	if name == "journal":
		_journal_unread = 0
		if _journal_badge_bg != null:
			_journal_badge_bg.visible = false
		# Show tab dots for whichever tab has pending unread items
		if _journal_quest_dot != null:
			_journal_quest_dot.visible = _journal_quest_unread > 0
		if _journal_notes_dot != null:
			_journal_notes_dot.visible = _journal_notes_unread > 0
		# Clear the currently visible tab immediately since the player sees it now
		if _journal_tab == "quests":
			_journal_quest_unread = 0
			if _journal_quest_dot != null:
				_journal_quest_dot.visible = false
		else:
			_journal_notes_unread = 0
			if _journal_notes_dot != null:
				_journal_notes_dot.visible = false

func _close_all() -> void:
	var dialogue_was_open: bool = _dialogue_panel.visible
	var crafting_was_open: bool = (_open == "crafting")
	var object_panel_was_open: bool = _object_panel.visible
	for p in _panels.values(): p.visible = false
	_pause_panel.visible = false
	_dialogue_panel.visible = false
	_object_panel.visible = false
	_object_entity = null
	_save_panel.visible = false
	_load_panel.visible = false
	if _shop_panel != null: _shop_panel.visible = false
	if _dream_panel != null: _dream_panel.visible = false
	if _spell_pick_panel != null: _spell_pick_panel.visible = false
	if _smithing_pick_panel != null: _smithing_pick_panel.visible = false
	_close_context_menu()
	if _map_tooltip != null:
		_map_tooltip.visible = false
	_hide_item_info()
	_hide_item_hover_tooltip()
	if _pile_panel != null: _pile_panel.visible = false
	if _container_panel != null: _container_panel.visible = false
	_container_entity = null
	if _pickpocket_panel != null: _pickpocket_panel.visible = false
	_pickpocket_entity = null
	_open = ""
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Emit deferred so listeners run after _close_all() fully completes
	if dialogue_was_open:
		call_deferred("_emit_dialogue_closed", _dialogue_entity)
	if crafting_was_open:
		var opener = _crafting_opener
		_crafting_opener = null
		call_deferred("_emit_crafting_closed", opener)
	if object_panel_was_open:
		EventBus.examine_panel_closed.emit()

func _on_escape() -> void:
	if _context_menu != null:
		_close_context_menu()
		return
	if _open != "" or _pause_panel.visible or _dialogue_panel.visible or _object_panel.visible \
			or (_pickpocket_panel != null and _pickpocket_panel.visible):
		_close_all()
	else:
		_pause_panel.visible = true
		mouse_filter = Control.MOUSE_FILTER_STOP

# ══════════════════════════════════════════════════════════════════════════════
# PAUSE MENU
# ══════════════════════════════════════════════════════════════════════════════
func _build_death_panel() -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.z_index = 300

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.92)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var box := VBoxContainer.new()
	box.name = "DeathBox"
	box.add_theme_constant_override("separation", 16)
	box.custom_minimum_size = Vector2(520, 0)
	center.add_child(box)

	var title := Label.new()
	title.text = "YOU DIED"
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color(0.72, 0.08, 0.08))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var sub := Label.new()
	sub.text = "Your wounds have taken you."
	sub.add_theme_font_size_override("font_size", 14)
	sub.add_theme_color_override("font_color", Color(0.60, 0.55, 0.55))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sub)

	box.add_child(HSeparator.new())

	# Save slot rows are populated by _refresh_death_panel()
	var slots_box := VBoxContainer.new()
	slots_box.name = "SlotsBox"
	slots_box.add_theme_constant_override("separation", 6)
	box.add_child(slots_box)

	box.add_child(HSeparator.new())

	var quit_btn := Button.new()
	quit_btn.text = "Quit to Main Menu"
	quit_btn.custom_minimum_size = Vector2(240, 44)
	quit_btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	quit_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/title_screen.tscn"))
	box.add_child(quit_btn)

	return root

func _refresh_death_panel() -> void:
	var slots_box: VBoxContainer = _death_panel.find_child("SlotsBox", true, false)
	if slots_box == null:
		return
	for child in slots_box.get_children():
		child.queue_free()

	# Show auto saves first, then quick saves, then manual slots
	var display_slots: Array = [
		GameManager.AUTO_SLOT, GameManager.PREV_AUTO_SLOT,
		0, GameManager.PREV_QUICK_SLOT,
	]
	for i in range(1, GameManager.SLOT_COUNT + 1):
		display_slots.append(i)

	var any_shown: bool = false
	for slot in display_slots:
		var info: Dictionary = GameManager.get_save_info(slot)
		if not info["exists"]:
			continue
		any_shown = true
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		slots_box.add_child(row)

		var name_lbl := Label.new()
		name_lbl.text = info["slot_name"]
		name_lbl.custom_minimum_size = Vector2(130, 0)
		name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(name_lbl)

		var char_lbl := Label.new()
		char_lbl.text = info["character_name"]
		char_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		char_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(char_lbl)

		var time_lbl := Label.new()
		time_lbl.text = info["timestamp"]
		time_lbl.custom_minimum_size = Vector2(130, 0)
		time_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		time_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		time_lbl.add_theme_font_size_override("font_size", 11)
		row.add_child(time_lbl)

		var load_btn := Button.new()
		load_btn.text = "Load"
		load_btn.custom_minimum_size = Vector2(80, 34)
		var s: int = slot
		load_btn.pressed.connect(func():
			_player_is_dead = false
			GameManager.load_from_slot(s)
			get_tree().change_scene_to_file("res://scenes/main.tscn"))
		row.add_child(load_btn)

	if not any_shown:
		var empty_lbl := Label.new()
		empty_lbl.text = "No saves found."
		empty_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slots_box.add_child(empty_lbl)

func _on_leveled_up(new_level: int) -> void:
	_refresh_stats()
	# Show a brief banner at the top of the screen
	if _levelup_banner == null:
		_levelup_banner = _build_levelup_banner()
		add_child(_levelup_banner)
	var d: Dictionary = GameManager.player_data
	var parts: Array = ["Level %d!" % new_level]
	var sk: int = d.get("unspent_skill_points", 0)
	var st: int = d.get("unspent_stat_points",  0)
	var ft: int = d.get("unspent_feat_points",  0)
	if sk > 0: parts.append("+%d skill pts" % sk)
	if st > 0: parts.append("+%d stat pts"  % st)
	if ft > 0: parts.append("pick a feat")
	var lbl: Label = _levelup_banner.get_node("Label")
	lbl.text = "LEVEL UP  —  " + "  ·  ".join(parts) + "  (open Character sheet to spend)"
	_levelup_banner.modulate.a = 1.0
	_levelup_banner.visible = true
	var tw := create_tween()
	tw.tween_interval(4.0)
	tw.tween_property(_levelup_banner, "modulate:a", 0.0, 1.0)
	tw.tween_callback(func(): _levelup_banner.visible = false)

func _build_levelup_banner() -> Control:
	var root := PanelContainer.new()
	root.set_anchors_preset(Control.PRESET_TOP_WIDE)
	root.position = Vector2(0, 4)
	root.z_index = 200
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.08, 0.02, 0.92)
	style.border_color = Color(1.0, 0.85, 0.3)
	style.border_width_bottom = 2
	root.add_theme_stylebox_override("panel", style)
	var lbl := Label.new()
	lbl.name = "Label"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(lbl)
	return root

func _on_player_died() -> void:
	# End combat cleanly if still active
	if CombatManager.active:
		CombatManager.active = false
		GameManager.combat_mode = false
		CombatManager.participants.clear()
		CombatManager.turn_state.clear()
		EventBus.combat_ended.emit("enemy")
	_player_is_dead = true
	_close_all()
	_refresh_death_panel()
	_death_panel.visible = true

func _build_pause_panel() -> Control:
	var root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP

	var overlay = ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.0, 0.0, 0.0, 0.75)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(overlay)

	# CenterContainer fills the panel and reliably centers its child
	var centerer = CenterContainer.new()
	centerer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(centerer)

	var col = VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	centerer.add_child(col)

	var title = Label.new()
	title.text = "PAUSED"
	title.add_theme_font_size_override("font_size", 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)

	_pause_spacer(col, 16)

	_pause_btn(col, "Resume",           _close_all)
	_pause_btn(col, "Save Game",        _open_save_panel)
	_pause_btn(col, "Load Game",        _open_load_panel)
	_pause_btn(col, "Settings",         _on_settings)
	_pause_btn(col, "Quit to Menu",     _on_quit_to_menu)
	_pause_btn(col, "Quit to Desktop",  _on_quit_to_desktop)

	return root

func _pause_btn(parent: Control, label: String, cb: Callable) -> void:
	var btn = Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(240, 48)
	btn.pressed.connect(cb)
	parent.add_child(btn)

func _pause_spacer(parent: Control, h: int) -> void:
	var s = Control.new()
	s.custom_minimum_size = Vector2(0, h)
	parent.add_child(s)

func _open_save_panel() -> void:
	_pause_panel.visible = false
	_refresh_save_panel()
	_save_panel.visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP

func _open_load_panel() -> void:
	_pause_panel.visible = false
	_refresh_load_panel()
	_load_panel.visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP

func _toggle_sneak() -> void:
	GameManager.toggle_sneak()
	if GameManager.player != null:
		GameManager.player.queue_redraw()

func _on_sneak_toggled(active: bool) -> void:
	if _sneak_btn != null:
		if active:
			_sneak_btn.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
		else:
			_sneak_btn.remove_theme_color_override("font_color")

func _toggle_tactical() -> void:
	if CombatManager.tactical_mode:
		CombatManager.end_tactical()
	elif not GameManager.combat_mode:
		CombatManager.start_tactical()

func _on_tactical_state_changed(active: bool) -> void:
	if _tactical_btn != null:
		if active:
			_tactical_btn.add_theme_color_override("font_color", Color(0.9, 0.75, 0.2))
		else:
			_tactical_btn.remove_theme_color_override("font_color")

func _on_settings() -> void:
	pass  # TODO: settings menu

func _on_quit_to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/title_screen.tscn")

func _on_quit_to_desktop() -> void:
	get_tree().quit()

# ══════════════════════════════════════════════════════════════════════════════
# SAVE / LOAD PANELS
# ══════════════════════════════════════════════════════════════════════════════
func _build_save_panel() -> Control:
	var shell = _make_panel_shell("SAVE GAME")
	var vbox: VBoxContainer = shell["vbox"]
	_save_rows.clear()
	# Auto saves — read-only
	_save_rows.append(_build_slot_row(vbox, GameManager.AUTO_SLOT,      true, false))
	_save_rows.append(_build_slot_row(vbox, GameManager.PREV_AUTO_SLOT, true, false))
	vbox.add_child(HSeparator.new())
	# Quick saves
	_save_rows.append(_build_slot_row(vbox, 0, true))
	_save_rows.append(_build_slot_row(vbox, GameManager.PREV_QUICK_SLOT, true, false))
	vbox.add_child(HSeparator.new())
	for slot in range(1, GameManager.SLOT_COUNT + 1):
		_save_rows.append(_build_slot_row(vbox, slot, true))
	return shell["root"]

func _build_load_panel() -> Control:
	var shell = _make_panel_shell("LOAD GAME")
	var vbox: VBoxContainer = shell["vbox"]
	_load_rows.clear()
	# Auto saves
	_load_rows.append(_build_slot_row(vbox, GameManager.AUTO_SLOT,      false))
	_load_rows.append(_build_slot_row(vbox, GameManager.PREV_AUTO_SLOT, false))
	vbox.add_child(HSeparator.new())
	# Quick saves
	_load_rows.append(_build_slot_row(vbox, 0, false))
	_load_rows.append(_build_slot_row(vbox, GameManager.PREV_QUICK_SLOT, false))
	vbox.add_child(HSeparator.new())
	for slot in range(1, GameManager.SLOT_COUNT + 1):
		_load_rows.append(_build_slot_row(vbox, slot, false))
	return shell["root"]

# saveable=false: show info but replace Save button with an "auto" label
func _build_slot_row(vbox: VBoxContainer, slot: int, is_save: bool, saveable: bool = true) -> Dictionary:
	var info = GameManager.get_save_info(slot)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.custom_minimum_size = Vector2(0, 38)
	vbox.add_child(row)

	var slot_lbl = Label.new()
	slot_lbl.text = info["slot_name"]
	slot_lbl.custom_minimum_size = Vector2(150, 0)
	slot_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(slot_lbl)

	var char_lbl = Label.new()
	char_lbl.text = info["character_name"] if info["exists"] else "— Empty —"
	char_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	char_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if not info["exists"]:
		char_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	row.add_child(char_lbl)

	var time_lbl = Label.new()
	time_lbl.text = info["timestamp"] if info["exists"] else ""
	time_lbl.custom_minimum_size = Vector2(150, 0)
	time_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	time_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	time_lbl.add_theme_font_size_override("font_size", 11)
	row.add_child(time_lbl)

	var btn: Button = null
	if is_save and not saveable:
		# Prev. Quick Save — auto-only, no manual save button
		var lbl = Label.new()
		lbl.text = "auto"
		lbl.custom_minimum_size = Vector2(80, 34)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))
		row.add_child(lbl)
	else:
		btn = Button.new()
		btn.text = "Save" if is_save else "Load"
		btn.custom_minimum_size = Vector2(80, 34)
		btn.disabled = (not is_save) and (not info["exists"])
		var s = slot
		if is_save:
			btn.pressed.connect(func(): _do_save(s))
		else:
			btn.pressed.connect(func(): _do_load(s))
		row.add_child(btn)

	var del_btn = Button.new()
	del_btn.text = "✕"
	del_btn.custom_minimum_size = Vector2(34, 34)
	del_btn.disabled = not info["exists"]
	del_btn.add_theme_color_override("font_color", Color(0.85, 0.35, 0.35))
	var sd = slot
	del_btn.pressed.connect(func(): _do_delete(sd))
	row.add_child(del_btn)

	return {"char_lbl": char_lbl, "time_lbl": time_lbl, "btn": btn, "del_btn": del_btn, "slot": slot}

func _refresh_save_panel() -> void:
	for row in _save_rows:
		var info = GameManager.get_save_info(row["slot"])
		row["char_lbl"].text = info["character_name"] if info["exists"] else "— Empty —"
		row["char_lbl"].add_theme_color_override("font_color",
			Color(1, 1, 1) if info["exists"] else Color(0.5, 0.5, 0.5))
		row["time_lbl"].text = info["timestamp"] if info["exists"] else ""
		if row.has("del_btn") and row["del_btn"] != null:
			row["del_btn"].disabled = not info["exists"]

func _refresh_load_panel() -> void:
	for row in _load_rows:
		var info = GameManager.get_save_info(row["slot"])
		row["char_lbl"].text = info["character_name"] if info["exists"] else "— Empty —"
		row["char_lbl"].add_theme_color_override("font_color",
			Color(1, 1, 1) if info["exists"] else Color(0.5, 0.5, 0.5))
		row["time_lbl"].text = info["timestamp"] if info["exists"] else ""
		if row["btn"] != null:
			row["btn"].disabled = not info["exists"]
		if row.has("del_btn") and row["del_btn"] != null:
			row["del_btn"].disabled = not info["exists"]

func _do_save(slot: int) -> void:
	GameManager.save_to_slot(slot)
	_refresh_save_panel()
	_refresh_load_panel()

func _do_load(slot: int) -> void:
	GameManager.load_from_slot(slot)
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _do_delete(slot: int) -> void:
	_confirm_delete(slot, func():
		GameManager.delete_save(slot)
		_refresh_save_panel()
		_refresh_load_panel()
	)

func _confirm_delete(slot: int, on_confirm: Callable) -> void:
	var info = GameManager.get_save_info(slot)
	var overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 100

	var dim = ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.7)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(dim)

	var centerer = CenterContainer.new()
	centerer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(centerer)

	var card = VBoxContainer.new()
	card.custom_minimum_size = Vector2(340, 0)
	card.add_theme_constant_override("separation", 16)
	centerer.add_child(card)

	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.12, 0.12, 0.16)
	bg.border_width_left   = 1
	bg.border_width_right  = 1
	bg.border_width_top    = 1
	bg.border_width_bottom = 1
	bg.border_color = Color(0.4, 0.4, 0.5)
	bg.corner_radius_top_left     = 4
	bg.corner_radius_top_right    = 4
	bg.corner_radius_bottom_left  = 4
	bg.corner_radius_bottom_right = 4
	bg.content_margin_left   = 24
	bg.content_margin_right  = 24
	bg.content_margin_top    = 20
	bg.content_margin_bottom = 20
	card.add_theme_stylebox_override("panel", bg)

	var heading = Label.new()
	heading.text = "Delete Save?"
	heading.add_theme_font_size_override("font_size", 20)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(heading)

	var desc = Label.new()
	desc.text = info["slot_name"]
	if info["character_name"] != "":
		desc.text += " — " + info["character_name"]
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	card.add_child(desc)

	var btns = HBoxContainer.new()
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	btns.add_theme_constant_override("separation", 16)
	card.add_child(btns)

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(110, 36)
	cancel_btn.pressed.connect(func(): overlay.queue_free())
	btns.add_child(cancel_btn)

	var confirm_btn = Button.new()
	confirm_btn.text = "Delete"
	confirm_btn.custom_minimum_size = Vector2(110, 36)
	confirm_btn.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	confirm_btn.pressed.connect(func():
		overlay.queue_free()
		on_confirm.call()
	)
	btns.add_child(confirm_btn)

	add_child(overlay)

# ══════════════════════════════════════════════════════════════════════════════
# TOOLBAR
# ══════════════════════════════════════════════════════════════════════════════
func _build_toolbar() -> Control:
	var bar = HBoxContainer.new()
	bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	bar.offset_top = 8
	bar.offset_right = -8
	bar.offset_bottom = 52
	bar.offset_left = -868
	bar.add_theme_constant_override("separation", 6)

	for pair in [["[C] Stats","stats"],["[I] Inventory","inventory"],
				 ["[M] Map","map"],["[J] Journal","journal"],["[K] Crafting","crafting"],
				 ["[B] Abilities","abilities"]]:
		var btn = Button.new()
		btn.text  = pair[0]
		btn.custom_minimum_size = Vector2(100, 36)
		var key = pair[1]
		btn.pressed.connect(func(): _toggle(key))
		bar.add_child(btn)
		if key == "journal":
			_attach_journal_badge(btn)

	_sneak_btn = Button.new()
	_sneak_btn.text = "[Z] Sneak"
	_sneak_btn.custom_minimum_size = Vector2(100, 36)
	_sneak_btn.pressed.connect(_toggle_sneak)
	bar.add_child(_sneak_btn)

	_tactical_btn = Button.new()
	_tactical_btn.text = "[T] Tactical"
	_tactical_btn.custom_minimum_size = Vector2(110, 36)
	_tactical_btn.pressed.connect(_toggle_tactical)
	bar.add_child(_tactical_btn)

	return bar

# ══════════════════════════════════════════════════════════════════════════════
# DIALOGUE PANEL
# ══════════════════════════════════════════════════════════════════════════════
func _build_dialogue_panel() -> Control:
	var root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	root.offset_top = -360
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	# Swallow scroll wheel so camera zoom doesn't fire when hovering over dialogue
	root.gui_input.connect(func(ev): get_viewport().set_input_as_handled() if ev is InputEventMouseButton and ev.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN] else null)

	var bg = ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.04, 0.07, 0.96)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)

	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 20)
	root.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	# Header row: NPC name
	_dialogue_name_lbl = Label.new()
	_dialogue_name_lbl.add_theme_font_size_override("font_size", 18)
	vbox.add_child(_dialogue_name_lbl)

	vbox.add_child(HSeparator.new())

	# NPC speech
	_dialogue_text_lbl = Label.new()
	_dialogue_text_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogue_text_lbl.add_theme_font_size_override("font_size", 14)
	_dialogue_text_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_dialogue_text_lbl)

	vbox.add_child(HSeparator.new())

	# Player response options — wrapped in a scroll container so long lists don't clip
	var opts_scroll := ScrollContainer.new()
	opts_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	opts_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	opts_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(opts_scroll)

	_dialogue_options_box = VBoxContainer.new()
	_dialogue_options_box.add_theme_constant_override("separation", 2)
	_dialogue_options_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opts_scroll.add_child(_dialogue_options_box)

	# Floating note indicator — anchored to bottom-right, hidden until a note fires
	_dialogue_note_indicator = Label.new()
	_dialogue_note_indicator.text = "✦ Journal updated"
	_dialogue_note_indicator.add_theme_font_size_override("font_size", 11)
	_dialogue_note_indicator.add_theme_color_override("font_color", Color(0.88, 0.82, 0.45))
	_dialogue_note_indicator.anchor_left   = 1.0
	_dialogue_note_indicator.anchor_right  = 1.0
	_dialogue_note_indicator.anchor_top    = 1.0
	_dialogue_note_indicator.anchor_bottom = 1.0
	_dialogue_note_indicator.offset_left   = -180
	_dialogue_note_indicator.offset_right  = -16
	_dialogue_note_indicator.offset_top    = -28
	_dialogue_note_indicator.offset_bottom = -8
	_dialogue_note_indicator.modulate.a    = 0.0
	root.add_child(_dialogue_note_indicator)

	return root

func _populate_dialogue_options(options: Array) -> void:
	for child in _dialogue_options_box.get_children():
		child.queue_free()
	for opt in options:
		var btn = Button.new()
		btn.text = "> " + opt["label"]
		btn.flat = true
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.disabled = opt.get("disabled", false)
		var captured = opt
		btn.pressed.connect(func():
			if captured.get("accept_assistance", false):
				GameManager.player_data["starting_assistance_accepted"] = true
				var inv: Array = GameManager.player_data.get("inventory", [])
				for item in captured.get("give_items", []):
					inv.append(item)
				GameManager.player_data["inventory"] = inv
			if captured.has("action"):
				captured["action"].call()
			if captured.get("closes", false):
				var closing_response: String = captured.get("response", "")
				if closing_response != "":
					_dialogue_text_lbl.text = closing_response
					_populate_dialogue_options([{"label": "Close", "response": "", "closes": true}])
				else:
					_close_all()
			elif captured.has("next_options"):
				_dialogue_text_lbl.text = captured.get("response", "")
				_populate_dialogue_options(captured["next_options"])
			else:
				_dialogue_text_lbl.text = captured.get("response", "")
				_populate_dialogue_options([{"label": "Close", "response": "", "closes": true}])
		)
		_dialogue_options_box.add_child(btn)

func _on_interaction_triggered(entity: Node, action_id: String) -> void:
	_close_context_menu()
	match action_id:
		"talk":
			_close_all()
			if entity.has_method("prepare_dialogue"):
				entity.prepare_dialogue()
			_dialogue_entity = entity
			_dialogue_name_lbl.text = entity.get("entity_name") if entity.get("entity_name") != null else "???"
			_dialogue_text_lbl.text = entity.get("dialogue_text") if entity.get("dialogue_text") != null else "..."
			var opts = entity.get("dialogue_options")
			_populate_dialogue_options(opts if opts != null else [])
			_dialogue_panel.visible = true
			mouse_filter = Control.MOUSE_FILTER_STOP
			EventBus.dialogue_opened.emit(entity)
			# Record this NPC as encountered on the world map
			var enc_name = entity.get("entity_name")
			if enc_name != null and enc_name != "":
				GameManager.add_encounter(GameManager.world_layer, GameManager.world_pos, enc_name)
		"carve":
			_handle_carve(entity)
		"search":
			_handle_search(entity)
		"open_container":
			_open_container_panel(entity)
		"fish":
			_handle_fish(entity)
		"open":
			if entity.has_method("interact"):
				entity.interact()
		"examine":
			_open_examine_panel(entity)
		"interact":
			# Generic fallback — if it's an NPC use dialogue, else call interact() or examine
			if entity.get("dialogue_text") != null:
				_close_all()
				_dialogue_entity = entity
				_dialogue_name_lbl.text = entity.get("entity_name") if entity.get("entity_name") != null else "???"
				_dialogue_text_lbl.text = entity.get("dialogue_text")
				var opts = entity.get("dialogue_options")
				_populate_dialogue_options(opts if opts != null else [])
				_dialogue_panel.visible = true
				mouse_filter = Control.MOUSE_FILTER_STOP
				EventBus.dialogue_opened.emit(entity)
			elif entity.has_method("interact"):
				entity.interact()
			else:
				_open_examine_panel(entity)
		"pick_lock":
			if entity.has_method("attempt_pick_lock"):
				entity.attempt_pick_lock()
		"force_open":
			if entity.has_method("attempt_force_open"):
				entity.attempt_force_open()
		"pick_up":
			if entity.has_method("pick_up"):
				entity.pick_up()
				_refresh_inventory()
		"view_pile":
			_open_pile_panel(entity)
		"attack":
			_close_all()
			if entity.has_method("go_hostile"):
				entity.go_hostile()
			else:
				_open_examine_panel(entity)
		"sneak_attack":
			_close_all()
			if entity.has_method("go_hostile"):
				entity.go_hostile(true)
		"pickpocket":
			_do_pickpocket(entity)
		_:
			# Unknown action — just open the examine panel so something happens
			_open_examine_panel(entity)

func _handle_carve(corpse: Node) -> void:
	# Guard against double-dispatch (double-click, object panel + context menu, etc.)
	if corpse.get("_carved"):
		return
	if corpse.has_method("mark_carved"):
		corpse.mark_carved()

	var skills: Dictionary = GameManager.player_data.get("skills", {})
	var invested: float    = float(skills.get("survival", 0))
	var stats: Dictionary  = GameManager.player_data.get("stats", {})
	var con_mod: int = stats.get("constitution", 5) - 5
	var wil_mod: int = stats.get("willpower", 5) - 5
	var gov_mod: int = maxi(con_mod, wil_mod)
	var effective: int = int(invested * (1.0 + gov_mod * 0.1))
	var roll: int = randi_range(1, 100) + effective

	var loot: Array = DataManager.resolve_carve(
		corpse.beast_type,
		roll,
		corpse.beast_quality_mod
	)

	var doubled: bool = not loot.is_empty() and GameManager.roll_harvest_double()
	if doubled:
		for item in loot.duplicate(true):
			loot.append(item)

	var inv: Array = GameManager.player_data.get("inventory", [])
	for item in loot:
		inv.append(item)
	GameManager.player_data["inventory"] = inv

	if not loot.is_empty():
		GameManager.update_quest("hunter_animal_kill",
			"Animal killed and carved — return to the old hunter.")

	_close_all()
	var result_text: String
	if loot.is_empty():
		result_text = "You work at the carcass but can't salvage anything useful.\n\n[Survival roll: %d]" % roll
	else:
		var names: Array = loot.map(func(i): return i["name"])
		result_text = "You carefully work the carcass.\n\n[Survival roll: %d]\n\nYou recover: %s" % [roll, ", ".join(names)]
		if doubled:
			result_text += "\n\nYour eye for the land pays off — you recover double the usual yield."

	_dialogue_name_lbl.text = "Carving"
	_dialogue_text_lbl.text = result_text
	_populate_dialogue_options([{"label": "OK", "response": "", "closes": true}])
	_dialogue_panel.visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	EventBus.dialogue_opened.emit(null)

func _handle_search(corpse: Node) -> void:
	# Guard against double-dispatch (double-click, object panel + context menu, etc.)
	if corpse.get("_carved"):
		return
	if corpse.has_method("mark_carved"):
		corpse.mark_carved()

	_close_all()
	_dialogue_name_lbl.text = "Search"
	_dialogue_text_lbl.text = "You search the body, but there's nothing worth taking."
	_populate_dialogue_options([{"label": "OK", "response": "", "closes": true}])
	_dialogue_panel.visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	EventBus.dialogue_opened.emit(null)

func _handle_fish(plant: Node) -> void:
	var inv: Array = GameManager.player_data.get("inventory", [])
	var has_rod: bool = false
	for item in inv:
		if item.get("id", "") == "fishing_rod":
			has_rod = true
			break

	_close_all()
	_dialogue_name_lbl.text = "Fishing"

	if not has_rod:
		_dialogue_text_lbl.text = "You need a fishing rod to fish here."
		_populate_dialogue_options([{"label": "OK", "response": "", "closes": true}])
		_dialogue_panel.visible = true
		mouse_filter = Control.MOUSE_FILTER_STOP
		EventBus.dialogue_opened.emit(null)
		return

	var skills: Dictionary = GameManager.player_data.get("skills", {})
	var invested: float    = float(skills.get("survival", 0))
	var stats: Dictionary  = GameManager.player_data.get("stats", {})
	var con_mod: int = stats.get("constitution", 5) - 5
	var wil_mod: int = stats.get("willpower", 5) - 5
	var gov_mod: int = maxi(con_mod, wil_mod)
	var effective: int = int(invested * (1.0 + gov_mod * 0.1))
	var roll: int = randi_range(1, 100) + effective

	var caught: Dictionary = DataManager.resolve_fish("river", roll, 0)

	var result_text: String
	if caught.is_empty():
		result_text = "You wait at the water's edge, but nothing bites.\n\n[Survival roll: %d]" % roll
	else:
		inv.append(caught)
		var doubled: bool = GameManager.roll_harvest_double()
		if doubled:
			inv.append(caught.duplicate(true))
		GameManager.player_data["inventory"] = inv
		result_text = "You reel something in.\n\n[Survival roll: %d]\n\nYou catch: %s" % [roll, caught["name"]]
		if doubled:
			result_text += "\n\nYour eye for the land pays off — you catch an extra fish."

	if plant.has_method("mark_harvested"):
		plant.mark_harvested()

	_dialogue_text_lbl.text = result_text
	_populate_dialogue_options([{"label": "OK", "response": "", "closes": true}])
	_dialogue_panel.visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	EventBus.dialogue_opened.emit(null)

func _open_examine_panel(entity: Node) -> void:
	_close_all()
	_object_entity = entity
	_object_primary_action = ""
	_object_name_lbl.text = entity.get("entity_name") if entity.get("entity_name") != null else "Object"
	_object_desc_lbl.text = entity.get_description() if entity.has_method("get_description") else ""
	# Show the primary non-examine action as the action button
	if entity.has_method("get_interaction_options"):
		var opts = entity.get_interaction_options()
		opts = opts.filter(func(o): return o["id"] != "examine")
		if not opts.is_empty():
			opts.sort_custom(func(a, b): return a["priority"] > b["priority"])
			_object_primary_action = opts[0]["id"]
			_object_action_btn.text = opts[0]["label"]
			_object_action_btn.visible = true
		else:
			_object_action_btn.visible = false
	else:
		_object_action_btn.visible = false
	_object_panel.visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	EventBus.examine_panel_opened.emit()

func _on_object_action() -> void:
	if _object_entity == null:
		return
	if _object_primary_action == "open" and _object_entity.has_method("interact"):
		_object_entity.interact()
		# Refresh description and button label after acting
		_object_desc_lbl.text = _object_entity.get_description() if _object_entity.has_method("get_description") else ""
		if _object_entity.has_method("get_interaction_options"):
			var opts = _object_entity.get_interaction_options()
			opts = opts.filter(func(o): return o["id"] != "examine")
			if not opts.is_empty():
				opts.sort_custom(func(a, b): return a["priority"] > b["priority"])
				_object_primary_action = opts[0]["id"]
				_object_action_btn.text = opts[0]["label"]
	elif _object_primary_action == "talk":
		EventBus.interaction_triggered.emit(_object_entity, "talk")
	else:
		EventBus.interaction_triggered.emit(_object_entity, _object_primary_action)

# ── Context menu ──────────────────────────────────────────────────────────────
func _on_show_context_menu(entity: Node, options: Array, screen_pos: Vector2) -> void:
	_close_context_menu()
	_context_menu = _build_context_menu(entity, options, screen_pos)
	add_child(_context_menu)

func _close_context_menu() -> void:
	if _context_menu != null:
		_context_menu.queue_free()
		_context_menu = null

func _build_context_menu(entity: Node, options: Array, screen_pos: Vector2) -> Control:
	# Full-screen transparent catcher to dismiss on outside click
	var root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_close_context_menu())

	# Panel container
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.97)
	style.border_color = Color(0.5, 0.5, 0.6)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	panel.add_child(vbox)

	# Entity name header
	var name_lbl = Label.new()
	name_lbl.text = entity.get("entity_name") if entity.get("entity_name") != null else "Object"
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	vbox.add_child(name_lbl)

	# Status effects section — shown for any entity that has the property
	# (i.e. humanoids: players, enemies, NPCs). For inspect-only panels
	# (no action options below) this becomes the entire body of the popup.
	var statuses: Dictionary = entity.get("status_effects") if entity.get("status_effects") != null else {}
	var has_status_data: bool = false
	for status_name in statuses:
		var stacks: Array = statuses[status_name]
		if stacks.is_empty():
			continue
		has_status_data = true
		var tick_parts: Array = []
		for t in stacks:
			tick_parts.append("%dt" % t)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		var dot := Label.new()
		dot.text = "●"
		dot.add_theme_font_size_override("font_size", 9)
		dot.add_theme_color_override("font_color", Color(0.9, 0.25, 0.25))
		row.add_child(dot)
		var status_lbl := Label.new()
		status_lbl.text = "%s ×%d  (%s)" % [status_name.capitalize(), stacks.size(), ", ".join(tick_parts)]
		status_lbl.add_theme_font_size_override("font_size", 11)
		status_lbl.add_theme_color_override("font_color", Color(0.85, 0.45, 0.45))
		row.add_child(status_lbl)
		# Clickable ? for description
		var info_btn := Button.new()
		info_btn.text = "?"
		info_btn.flat = true
		info_btn.custom_minimum_size = Vector2(18, 18)
		info_btn.add_theme_font_size_override("font_size", 10)
		var cap: String = status_name
		info_btn.pressed.connect(func():
			_show_status_info_popup(cap, info_btn.get_global_rect().position))
		row.add_child(info_btn)
		vbox.add_child(row)
	# Entity has the status_effects property (is a humanoid) but nothing rendered.
	if entity.get("status_effects") != null and not has_status_data:
		var none_lbl := Label.new()
		none_lbl.text = "No active effects."
		none_lbl.add_theme_font_size_override("font_size", 11)
		none_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.65))
		vbox.add_child(none_lbl)

	# Only add the separator when there are action buttons below it
	if not options.is_empty():
		vbox.add_child(HSeparator.new())

	# Sort options by priority
	var sorted = options.duplicate()
	sorted.sort_custom(func(a, b): return a["priority"] > b["priority"])
	for opt in sorted:
		var btn = Button.new()
		btn.text = opt["label"]
		btn.flat = true
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(140, 28)
		var captured_id = opt["id"]
		var captured_entity = opt.get("_entity", entity)
		btn.pressed.connect(func():
			_close_context_menu()
			EventBus.interaction_triggered.emit(captured_entity, captured_id))
		vbox.add_child(btn)

	# Position panel near cursor, clamped to viewport
	panel.set_deferred("position", _clamp_menu_pos(screen_pos, panel))
	return root

func _clamp_menu_pos(pos: Vector2, panel: Control) -> Vector2:
	var vp = get_viewport_rect().size
	# Estimate size; will be refined after layout but good enough for clamping
	var est = Vector2(160, 120)
	return Vector2(
		clamp(pos.x, 0, vp.x - est.x),
		clamp(pos.y, 0, vp.y - est.y)
	)

# ══════════════════════════════════════════════════════════════════════════════
# OBJECT INTERACTION PANEL
# ══════════════════════════════════════════════════════════════════════════════
func _build_object_panel() -> Control:
	var root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	root.offset_top = -160
	root.mouse_filter = Control.MOUSE_FILTER_STOP

	var bg = ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.06, 0.04, 0.96)  # slightly green tint to distinguish from dialogue
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)

	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 20)
	root.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	# Header: object name + close button
	var header = HBoxContainer.new()
	vbox.add_child(header)

	_object_name_lbl = Label.new()
	_object_name_lbl.add_theme_font_size_override("font_size", 18)
	_object_name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_object_name_lbl)

	var close_btn = Button.new()
	close_btn.text = "Leave"
	close_btn.pressed.connect(_close_all)
	header.add_child(close_btn)

	vbox.add_child(HSeparator.new())

	# Description
	_object_desc_lbl = Label.new()
	_object_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_object_desc_lbl.add_theme_font_size_override("font_size", 14)
	_object_desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_object_desc_lbl)

	# Action button (e.g. Open / Close)
	_object_action_btn = Button.new()
	_object_action_btn.custom_minimum_size = Vector2(120, 36)
	_object_action_btn.pressed.connect(_on_object_action)
	vbox.add_child(_object_action_btn)

	return root

# ══════════════════════════════════════════════════════════════════════════════
# SHARED PANEL SHELL
# ══════════════════════════════════════════════════════════════════════════════
func _make_panel_shell(title: String) -> Dictionary:
	var root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP

	var overlay = ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.0, 0.0, 0.0, 0.7)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(overlay)

	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left","margin_right","margin_top","margin_bottom"]:
		margin.add_theme_constant_override(side, 60)
	root.add_child(margin)

	var panel_bg = ColorRect.new()
	panel_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel_bg.color = Color(0.06, 0.06, 0.10, 0.98)
	margin.add_child(panel_bg)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	# Header row
	var hdr = HBoxContainer.new()
	vbox.add_child(hdr)
	var title_lbl = Label.new()
	title_lbl.text = title
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr.add_child(title_lbl)
	var close_btn = Button.new()
	close_btn.text = "✕  Close"
	close_btn.pressed.connect(_close_all)
	hdr.add_child(close_btn)

	vbox.add_child(HSeparator.new())

	return {"root": root, "vbox": vbox}

# ══════════════════════════════════════════════════════════════════════════════
# STATS PANEL
# ══════════════════════════════════════════════════════════════════════════════
func _build_stats_panel() -> Control:
	var shell = _make_panel_shell("CHARACTER")
	var vbox: VBoxContainer = shell["vbox"]

	# Identity row
	var id_row = HBoxContainer.new()
	id_row.add_theme_constant_override("separation", 20)
	vbox.add_child(id_row)

	_cs_name_lbl  = _info_pair(id_row, "Name", "—")
	_cs_level_lbl = _info_pair(id_row, "Level", "1")
	_cs_bg_lbl    = _info_pair(id_row, "Background", "—")

	# XP bar
	var xp_section := VBoxContainer.new()
	xp_section.add_theme_constant_override("separation", 4)
	vbox.add_child(xp_section)
	var xp_hdr := Label.new()
	xp_hdr.text = "EXPERIENCE"
	xp_hdr.add_theme_font_size_override("font_size", 12)
	xp_section.add_child(xp_hdr)
	var xp_container := Control.new()
	xp_container.custom_minimum_size = Vector2(0, 22)
	xp_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	xp_section.add_child(xp_container)
	_cs_xp_bar = ProgressBar.new()
	_cs_xp_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cs_xp_bar.show_percentage = false
	var xp_fill := StyleBoxFlat.new(); xp_fill.bg_color = Color(0.2, 0.5, 0.75)
	var xp_bg   := StyleBoxFlat.new(); xp_bg.bg_color   = Color(0.08, 0.15, 0.22)
	_cs_xp_bar.add_theme_stylebox_override("fill", xp_fill)
	_cs_xp_bar.add_theme_stylebox_override("background", xp_bg)
	xp_container.add_child(_cs_xp_bar)
	_cs_xp_lbl = Label.new()
	_cs_xp_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cs_xp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cs_xp_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_cs_xp_lbl.add_theme_font_size_override("font_size", 11)
	_cs_xp_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	xp_container.add_child(_cs_xp_lbl)

	# Pending allocation row
	_cs_pending_row = HBoxContainer.new()
	_cs_pending_row.visible = false
	vbox.add_child(_cs_pending_row)
	_cs_pending_lbl = Label.new()
	_cs_pending_lbl.add_theme_font_size_override("font_size", 12)
	_cs_pending_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	_cs_pending_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cs_pending_row.add_child(_cs_pending_lbl)
	_cs_confirm_btn = Button.new()
	_cs_confirm_btn.text = "Confirm"
	_cs_confirm_btn.custom_minimum_size = Vector2(80, 26)
	_cs_confirm_btn.visible = false
	_cs_confirm_btn.pressed.connect(func():
		GameManager.confirm_levelup_allocation()
		_refresh_stats())
	_cs_pending_row.add_child(_cs_confirm_btn)

	# HP bar
	var hp_section = VBoxContainer.new()
	hp_section.add_theme_constant_override("separation", 4)
	vbox.add_child(hp_section)
	var hp_hdr = Label.new()
	hp_hdr.text = "HEALTH"
	hp_hdr.add_theme_font_size_override("font_size", 12)
	hp_section.add_child(hp_hdr)
	var hp_container = Control.new()
	hp_container.custom_minimum_size = Vector2(0, 26)
	hp_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_section.add_child(hp_container)
	_cs_hp_bar = ProgressBar.new()
	_cs_hp_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cs_hp_bar.show_percentage = false
	var fill = StyleBoxFlat.new(); fill.bg_color = Color(0.75, 0.1, 0.1)
	var bg   = StyleBoxFlat.new(); bg.bg_color   = Color(0.18, 0.05, 0.05)
	_cs_hp_bar.add_theme_stylebox_override("fill", fill)
	_cs_hp_bar.add_theme_stylebox_override("background", bg)
	hp_container.add_child(_cs_hp_bar)
	_cs_hp_lbl = Label.new()
	_cs_hp_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cs_hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cs_hp_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_cs_hp_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_container.add_child(_cs_hp_lbl)

	# Tab row
	var tab_row := HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 0)
	vbox.add_child(tab_row)
	for tab_def in [["Stats & Skills", "stats"], ["Feats", "feats"], ["Bonuses", "bonuses"]]:
		var tbtn := Button.new()
		tbtn.text = tab_def[0]
		tbtn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tbtn.custom_minimum_size = Vector2(0, 28)
		var tid: String = tab_def[1]
		tbtn.pressed.connect(func(): _cs_switch_tab(tid))
		_cs_tab_btns[tab_def[1]] = tbtn
		tab_row.add_child(tbtn)

	# Shared content area — both pages anchor-fill this, only one visible at a time
	var content := Control.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	vbox.add_child(content)

	# ── Stats & Skills page ───────────────────────────────────────────────────
	_cs_stats_page = VBoxContainer.new()
	_cs_stats_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cs_stats_page.add_theme_constant_override("separation", 8)
	content.add_child(_cs_stats_page)

	var cols = HBoxContainer.new()
	cols.add_theme_constant_override("separation", 30)
	cols.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	_cs_stats_page.add_child(cols)

	cols.add_child(_build_cs_stats_col())
	cols.add_child(VSeparator.new())
	cols.add_child(_build_cs_skills_col())

	# ── Feats page ────────────────────────────────────────────────────────────
	_cs_feats_page = Control.new()
	_cs_feats_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cs_feats_page.visible = false
	content.add_child(_cs_feats_page)

	var feats_scroll := ScrollContainer.new()
	feats_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	feats_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_cs_feats_page.add_child(feats_scroll)

	var feats_inner := VBoxContainer.new()
	feats_inner.add_theme_constant_override("separation", 4)
	feats_inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	feats_scroll.add_child(feats_inner)

	_cs_feat_picker_box = VBoxContainer.new()
	_cs_feat_picker_box.add_theme_constant_override("separation", 4)
	_cs_feat_picker_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cs_feat_picker_box.visible = false
	feats_inner.add_child(_cs_feat_picker_box)

	_cs_feats_box = VBoxContainer.new()
	_cs_feats_box.add_theme_constant_override("separation", 6)
	_cs_feats_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	feats_inner.add_child(_cs_feats_box)

	# ── Bonuses page ──────────────────────────────────────────────────────────
	_cs_bonuses_page = Control.new()
	_cs_bonuses_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cs_bonuses_page.visible = false
	content.add_child(_cs_bonuses_page)

	var bonuses_scroll := ScrollContainer.new()
	bonuses_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bonuses_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_cs_bonuses_page.add_child(bonuses_scroll)

	_cs_bonuses_vbox = VBoxContainer.new()
	_cs_bonuses_vbox.add_theme_constant_override("separation", 6)
	_cs_bonuses_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bonuses_scroll.add_child(_cs_bonuses_vbox)

	_cs_switch_tab("stats")
	return shell["root"]

func _cs_switch_tab(tab: String) -> void:
	_cs_active_tab = tab
	if _cs_stats_page   != null: _cs_stats_page.visible   = (tab == "stats")
	if _cs_feats_page   != null: _cs_feats_page.visible   = (tab == "feats")
	if _cs_bonuses_page != null: _cs_bonuses_page.visible = (tab == "bonuses")
	for tid in _cs_tab_btns:
		var btn: Button = _cs_tab_btns[tid]
		var active: bool = (tid == tab)
		btn.add_theme_color_override("font_color",
			Color(0.05, 0.05, 0.08) if active else Color(0.80, 0.80, 0.85))
		var sbox := StyleBoxFlat.new()
		sbox.bg_color = Color(0.85, 0.72, 0.25) if active else Color(0.14, 0.14, 0.20)
		sbox.corner_radius_top_left  = 4
		sbox.corner_radius_top_right = 4
		sbox.content_margin_top    = 4
		sbox.content_margin_bottom = 4
		btn.add_theme_stylebox_override("normal", sbox)
		btn.add_theme_stylebox_override("hover",  sbox)
		btn.add_theme_stylebox_override("pressed", sbox)
		# Show a dot on the Feats tab when a pick is pending
		var has_pending_feat: bool = GameManager.player_data.get("unspent_feat_points", 0) > 0
		if tid == "feats" and has_pending_feat and not active:
			btn.text = "Feats  ●"
		elif tid == "feats":
			btn.text = "Feats"

func _build_cs_stats_col() -> VBoxContainer:
	var col = VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	var hdr = Label.new(); hdr.text = "STATS"
	hdr.add_theme_font_size_override("font_size", 13)
	col.add_child(hdr)
	var sub = HBoxContainer.new()
	for pair in [["Stat", true], ["Value", false], ["Mod", false], ["+", false]]:
		var l = Label.new(); l.text = pair[0]
		l.add_theme_font_size_override("font_size", 11)
		if pair[1]: l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		else: l.custom_minimum_size = Vector2(28 if pair[0] == "+" else 50, 0); l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sub.add_child(l)
	col.add_child(sub)
	for stat in STAT_NAMES:
		var row = HBoxContainer.new()
		var name_l = Label.new(); name_l.text = STAT_ABBREV[stat]
		name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var val_l = Label.new(); val_l.custom_minimum_size = Vector2(50, 0)
		val_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var mod_l = Label.new(); mod_l.custom_minimum_size = Vector2(50, 0)
		mod_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var plus_btn = Button.new(); plus_btn.text = "+"
		plus_btn.custom_minimum_size = Vector2(28, 24)
		plus_btn.visible = false
		var captured_stat: String = stat
		plus_btn.pressed.connect(func():
			GameManager.spend_stat_point(captured_stat)
			_refresh_stats())
		var minus_btn = Button.new(); minus_btn.text = "-"
		minus_btn.custom_minimum_size = Vector2(28, 24)
		minus_btn.modulate.a = 0.0
		minus_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var captured_stat_r: String = stat
		minus_btn.pressed.connect(func():
			GameManager.refund_stat_point(captured_stat_r)
			_refresh_stats())
		_cs_stat_vals[stat]        = val_l
		_cs_stat_mods[stat]        = mod_l
		_cs_stat_plus_btns[stat]   = plus_btn
		_cs_stat_minus_btns[stat]  = minus_btn
		for n in [name_l, val_l, mod_l, plus_btn, minus_btn]: row.add_child(n)
		col.add_child(row)
	return col

func _build_cs_skills_col() -> VBoxContainer:
	var col = VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 4)
	var hdr = Label.new(); hdr.text = "SKILLS"
	hdr.add_theme_font_size_override("font_size", 13)
	col.add_child(hdr)
	var sub = HBoxContainer.new()
	for pair in [["Skill", true], ["+", false], ["Invested", false], ["Effective", false]]:
		var l = Label.new(); l.text = pair[0]
		l.add_theme_font_size_override("font_size", 11)
		if pair[1]: l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		else: l.custom_minimum_size = Vector2(28 if pair[0] == "+" else 70, 0); l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sub.add_child(l)
	col.add_child(sub)
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 20)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(grid)
	for skill in SKILL_NAMES:
		var row = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var name_l = Label.new(); name_l.text = SKILL_DISPLAY[skill]
		name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var plus_btn = Button.new(); plus_btn.text = "+"
		plus_btn.custom_minimum_size = Vector2(28, 22)
		plus_btn.visible = false
		var captured_skill: String = skill
		plus_btn.pressed.connect(func():
			GameManager.spend_skill_point(captured_skill)
			_refresh_stats())
		var minus_btn = Button.new(); minus_btn.text = "-"
		minus_btn.custom_minimum_size = Vector2(28, 22)
		minus_btn.modulate.a = 0.0
		minus_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var captured_skill_r: String = skill
		minus_btn.pressed.connect(func():
			GameManager.refund_skill_point(captured_skill_r)
			_refresh_stats())
		var inv_l = Label.new(); inv_l.custom_minimum_size = Vector2(60, 0)
		inv_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var eff_l = Label.new(); eff_l.custom_minimum_size = Vector2(70, 0)
		eff_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_cs_skill_vals[skill]       = eff_l
		_cs_skill_invested[skill]   = inv_l
		_cs_skill_plus_btns[skill]  = plus_btn
		_cs_skill_minus_btns[skill] = minus_btn
		for n in [name_l, plus_btn, minus_btn, inv_l, eff_l]: row.add_child(n)
		grid.add_child(row)
	return col

# ══════════════════════════════════════════════════════════════════════════════
# INVENTORY PANEL
# ══════════════════════════════════════════════════════════════════════════════
func _build_inventory_panel() -> Control:
	var shell = _make_panel_shell("INVENTORY")
	var vbox: VBoxContainer = shell["vbox"]

	var main_row = HBoxContainer.new()
	main_row.add_theme_constant_override("separation", 20)
	main_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(main_row)

	# ── Equipment column (left) ──
	var equip_col = VBoxContainer.new()
	equip_col.custom_minimum_size = Vector2(280, 0)
	equip_col.add_theme_constant_override("separation", 8)
	main_row.add_child(equip_col)

	var equip_hdr = Label.new()
	equip_hdr.text = "EQUIPMENT"
	equip_hdr.add_theme_font_size_override("font_size", 13)
	equip_col.add_child(equip_hdr)

	_equip_slot_labels.clear()
	_equip_slot_btns.clear()
	_equip_slot_icons.clear()
	var equip_grid = GridContainer.new()
	equip_grid.columns = 2
	equip_grid.add_theme_constant_override("h_separation", 6)
	equip_grid.add_theme_constant_override("v_separation", 6)
	equip_col.add_child(equip_grid)
	var _equip_slot_pairs: Array = [
		["hand_1","Hand 1"],            ["hand_2","Hand 2"],
		["head","Head"],                ["torso","Torso"],
		["feet","Feet"],                ["back","Back"],
		["right_upper_arm","R. Arm"],   ["left_upper_arm","L. Arm"],
		["right_forearm","R. Forearm"], ["left_forearm","L. Forearm"],
		["necklace","Necklace"],         ["ring_right_1","Ring R1"],
		["ring_right_2","Ring R2"],     ["ring_left_1","Ring L1"],
		["ring_left_2","Ring L2"],
	]
	for pair in _equip_slot_pairs:
		var key: String     = pair[0]
		var display: String = pair[1]
		var slot_col = VBoxContainer.new()
		slot_col.add_theme_constant_override("separation", 2)
		equip_grid.add_child(slot_col)

		var name_lbl = Label.new()
		name_lbl.text = display
		name_lbl.add_theme_font_size_override("font_size", 10)
		name_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
		slot_col.add_child(name_lbl)

		var btn = Button.new()
		btn.custom_minimum_size = Vector2(130, 34)
		btn.text = "—"
		btn.add_theme_font_size_override("font_size", 11)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.clip_contents = true
		btn.pressed.connect(_on_equip_slot_pressed.bind(key))
		btn.gui_input.connect(_on_equip_slot_gui_input.bind(key))
		btn.mouse_entered.connect(_on_equip_slot_mouse_entered.bind(key))
		btn.mouse_exited.connect(_on_equip_slot_mouse_exited)

		var eicon := ItemIcon.new()
		eicon.custom_minimum_size = Vector2(28, 28)
		eicon.size = Vector2(28, 28)
		eicon.position = Vector2(4, 3)
		eicon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(eicon)
		_equip_slot_icons[key] = eicon

		slot_col.add_child(btn)
		_equip_slot_btns[key]   = btn
		_equip_slot_labels[key] = btn

	var bonus_sep = HSeparator.new()
	equip_col.add_child(bonus_sep)

	var bonus_hdr = Label.new()
	bonus_hdr.text = "WORN BONUSES"
	bonus_hdr.add_theme_font_size_override("font_size", 13)
	equip_col.add_child(bonus_hdr)

	_equip_bonus_lbl = Label.new()
	_equip_bonus_lbl.add_theme_font_size_override("font_size", 11)
	_equip_bonus_lbl.add_theme_color_override("font_color", Color(0.75, 0.80, 0.75))
	_equip_bonus_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	equip_col.add_child(_equip_bonus_lbl)

	main_row.add_child(VSeparator.new())

	# ── Inventory grid (right) ──
	var inv_col = VBoxContainer.new()
	inv_col.add_theme_constant_override("separation", 8)
	inv_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inv_col.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	main_row.add_child(inv_col)

	var inv_hdr = Label.new()
	inv_hdr.text = "INVENTORY  (left-click equip, right-click info/drop, double-click use)"
	inv_hdr.add_theme_font_size_override("font_size", 13)
	inv_col.add_child(inv_hdr)

	_carry_weight_lbl = Label.new()
	_carry_weight_lbl.add_theme_font_size_override("font_size", 11)
	_carry_weight_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	inv_col.add_child(_carry_weight_lbl)

	var grid_scroll := ScrollContainer.new()
	grid_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	inv_col.add_child(grid_scroll)

	var grid = GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_scroll.add_child(grid)

	_inv_slot_btns.clear()
	_inv_name_lbls.clear()
	_inv_count_lbls.clear()
	_inv_slot_icons.clear()
	for i in range(50):
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(88, 66)
		btn.clip_contents = true
		btn.text = ""
		btn.pressed.connect(_on_inv_slot_pressed.bind(i))
		btn.gui_input.connect(_on_inv_slot_gui_input.bind(i))
		btn.mouse_entered.connect(_on_inv_slot_mouse_entered.bind(i))
		btn.mouse_exited.connect(_on_inv_slot_mouse_exited)

		# Custom layout: icon + name label + count label inside the button
		var slot_vbox := VBoxContainer.new()
		slot_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		slot_vbox.add_theme_constant_override("separation", 1)
		slot_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(slot_vbox)

		var iicon := ItemIcon.new()
		iicon.custom_minimum_size = Vector2(44, 44)
		iicon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		iicon.size_flags_vertical   = Control.SIZE_EXPAND_FILL
		iicon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot_vbox.add_child(iicon)

		# Name label kept (for layout/array bookkeeping) but hidden — the icon is the
		# primary display now; full name + tooltip shows on hover via _item_hover_tooltip.
		var name_lbl := Label.new()
		name_lbl.visible = false
		slot_vbox.add_child(name_lbl)

		var count_lbl := Label.new()
		count_lbl.add_theme_font_size_override("font_size", 9)
		count_lbl.add_theme_color_override("font_color", Color(0.65, 0.85, 0.65))
		count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		count_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		count_lbl.visible = false
		slot_vbox.add_child(count_lbl)

		grid.add_child(btn)
		_inv_slot_btns.append(btn)
		_inv_name_lbls.append(name_lbl)
		_inv_count_lbls.append(count_lbl)
		_inv_slot_icons.append(iicon)

	return shell["root"]

# ── Inventory / equip logic ────────────────────────────────────────────────────
# Returns [{item: Dictionary, count: int}] — identical items collapsed into one entry.
func _compute_stacks(items: Array) -> Array:
	var stacks: Array = []
	for item in items:
		var merged: bool = false
		for stack in stacks:
			if stack["item"] == item:
				stack["count"] += 1
				merged = true
				break
		if not merged:
			stacks.append({"item": item, "count": 1})
	return stacks

func _compute_stacked_inv() -> Array:
	return _compute_stacks(GameManager.player_data.get("inventory", []))

# Finds the first raw inventory index of an item that equals `target` (deep equality).
func _find_raw_inv_idx(target: Dictionary) -> int:
	var inv: Array = GameManager.player_data.get("inventory", [])
	for i in range(inv.size()):
		if inv[i] == target:
			return i
	return -1

func _display_item_name(item: Dictionary) -> String:
	if item.get("id", "") == "dark_vial" and GameManager.player_data.get("apothecary_vial_name_revealed", false):
		return "First Poison of Acclimation"
	return item.get("name", "?")

func _refresh_inventory() -> void:
	var equip: Dictionary = GameManager.player_data.get("equipment", {})

	for key in _equip_slot_btns:
		var btn: Button = _equip_slot_btns[key]
		var item = equip.get(key)
		if item != null:
			btn.text = ""
			if key in _equip_slot_icons:
				_equip_slot_icons[key].item_id = item.get("id", "")
		else:
			btn.text = "—"
			if key in _equip_slot_icons:
				_equip_slot_icons[key].item_id = ""

	var stacks: Array = _compute_stacked_inv()
	for i in range(_inv_slot_btns.size()):
		var count_lbl: Label = _inv_count_lbls[i]
		var iicon: ItemIcon  = _inv_slot_icons[i] if i < _inv_slot_icons.size() else null
		if i < stacks.size():
			var stack = stacks[i]
			if iicon != null:
				iicon.item_id = stack["item"].get("id", "")
			if stack["count"] > 1:
				count_lbl.text  = "×%d" % stack["count"]
				count_lbl.visible = true
			else:
				count_lbl.visible = false
		else:
			count_lbl.visible = false
			if iicon != null:
				iicon.item_id = ""

	if _carry_weight_lbl != null and GameManager.player != null:
		var player_node = GameManager.player
		var current: float = player_node.get_current_weight()
		var capacity: float = player_node.get_carry_capacity()
		_carry_weight_lbl.text = "Weight: %.1f / %.0f" % [current, capacity]
		var over: bool = current > capacity
		_carry_weight_lbl.add_theme_color_override("font_color",
			Color(0.9, 0.3, 0.3) if over else Color(0.7, 0.7, 0.75))

	_refresh_equip_bonus_lbl()

func _refresh_equip_bonus_lbl() -> void:
	if _equip_bonus_lbl == null:
		return
	var equip: Dictionary = GameManager.player_data.get("equipment", {})

	var flat: float        = 0.0
	var pct_remaining: float = 1.0
	var skill_bonuses: Dictionary    = {}   # skill -> int
	var gov_bonuses: Dictionary      = {}   # skill -> int
	var flags: Array[String]         = []

	for item in equip.values():
		if item == null:
			continue
		flat         += float(item.get("defense_flat", 0))
		pct_remaining *= (1.0 - float(item.get("defense_pct", 0.0)))
		for skill in item.get("skill_bonus", {}).keys():
			skill_bonuses[skill] = skill_bonuses.get(skill, 0) + int(item["skill_bonus"][skill])
		for skill in item.get("governing_bonus", {}).keys():
			gov_bonuses[skill] = gov_bonuses.get(skill, 0) + int(item["governing_bonus"][skill])
		if item.get("spirit_ward", false) and "Spirit ward" not in flags:
			flags.append("Spirit ward")

	var pct_reduction: float = (1.0 - pct_remaining) * 100.0
	var lines: Array[String] = []

	lines.append("Flat armor:      %.0f" % flat)
	lines.append("Dmg reduction:   %.1f%%" % pct_reduction)

	if not skill_bonuses.is_empty():
		lines.append("")
		var parts: Array[String] = []
		for skill in skill_bonuses.keys():
			parts.append("%s %+d" % [skill.capitalize(), skill_bonuses[skill]])
		lines.append("Skill:  " + ",  ".join(parts))

	if not gov_bonuses.is_empty():
		var parts: Array[String] = []
		for skill in gov_bonuses.keys():
			parts.append("%s %+d" % [skill.capitalize(), gov_bonuses[skill]])
		lines.append("Gov:    " + ",  ".join(parts))

	for flag in flags:
		lines.append(flag + ":  ✓")

	_equip_bonus_lbl.text = "\n".join(lines)

func _on_inv_slot_pressed(stack_idx: int) -> void:
	var stacks: Array = _compute_stacked_inv()
	if stack_idx >= stacks.size():
		return
	var item: Dictionary = stacks[stack_idx]["item"]
	var idx: int = _find_raw_inv_idx(item)
	if idx < 0:
		return
	var inv: Array = GameManager.player_data.get("inventory", [])
	var slot_type = item.get("slot", null)
	if slot_type == null or slot_type == "":
		return  # not equippable
	var equip: Dictionary = GameManager.player_data.get("equipment", {})

	# Trophy stacking check — block equipping a trophy from the same beast + same trophy type
	if item.get("trophy_type", "") != "" and item.get("beast_source", "") != "":
		var tt: String = item["trophy_type"]
		var bs: String = item["beast_source"]
		for slot_key in equip:
			var eq = equip[slot_key]
			if eq == null:
				continue
			if eq.get("trophy_type", "") == tt and eq.get("beast_source", "") == bs:
				return  # already wearing the same trophy from the same animal

	# Determine target slot key
	var target_slot: String = ""
	if slot_type == "hand":
		if equip.get("hand_1") == null:
			target_slot = "hand_1"
		elif equip.get("hand_2") == null:
			target_slot = "hand_2"
		else:
			return  # both hand slots full
	elif slot_type == "ring":
		for rk in ["ring_right_1", "ring_right_2", "ring_left_1", "ring_left_2"]:
			if equip.get(rk) == null:
				target_slot = rk
				break
		if target_slot == "":
			return  # all ring slots full
	elif slot_type == "upper_arm":
		if equip.get("right_upper_arm") == null:
			target_slot = "right_upper_arm"
		elif equip.get("left_upper_arm") == null:
			target_slot = "left_upper_arm"
		else:
			return  # both upper arm slots full
	elif slot_type == "talisman":
		# Talismans can go in any slot except hands, feet, and back
		var talisman_slots: Array = [
			"necklace", "right_upper_arm", "left_upper_arm",
			"right_forearm", "left_forearm",
			"ring_right_1", "ring_right_2", "ring_left_1", "ring_left_2",
			"head", "torso",
		]
		for ts in talisman_slots:
			if equip.get(ts) == null:
				target_slot = ts
				break
		if target_slot == "":
			return  # no available slot
	elif equip.has(slot_type):
		if equip.get(slot_type) != null:
			return  # slot occupied
		target_slot = slot_type
	else:
		return  # unknown slot

	# In combat: only hand slots allowed; costs 4 AP
	var is_hand_slot: bool = target_slot in ["hand_1", "hand_2"]
	if GameManager.combat_mode and CombatManager.is_player_turn():
		if not is_hand_slot:
			EventBus.combat_log.emit("You cannot change non-hand equipment during combat.")
			return
		if not CombatManager.spend_ap(4):
			return

	equip[target_slot] = item
	inv.remove_at(idx)
	GameManager.player_data["equipment"] = equip
	GameManager.player_data["inventory"] = inv
	EventBus.inventory_changed.emit()

func _on_equip_slot_pressed(slot_key: String) -> void:
	var equip: Dictionary = GameManager.player_data.get("equipment", {})
	var item = equip.get(slot_key)
	if item == null:
		return

	# In combat: only hand slots allowed; costs 4 AP
	var is_hand_slot: bool = slot_key in ["hand_1", "hand_2"]
	if GameManager.combat_mode and CombatManager.is_player_turn():
		if not is_hand_slot:
			EventBus.combat_log.emit("You cannot unequip non-hand items during combat.")
			return
		if not CombatManager.spend_ap(4):
			return

	var inv: Array = GameManager.player_data.get("inventory", [])
	inv.append(item)
	equip[slot_key] = null
	GameManager.player_data["equipment"] = equip
	GameManager.player_data["inventory"] = inv
	EventBus.inventory_changed.emit()

func _on_equip_slot_mouse_entered(slot_key: String) -> void:
	var equip: Dictionary = GameManager.player_data.get("equipment", {})
	var item = equip.get(slot_key)
	if item != null:
		_show_item_hover_tooltip(item, get_viewport().get_mouse_position())

func _on_equip_slot_mouse_exited() -> void:
	_hide_item_hover_tooltip()

func _on_inv_slot_mouse_entered(stack_idx: int) -> void:
	var stacks: Array = _compute_stacked_inv()
	if stack_idx < stacks.size():
		_show_item_hover_tooltip(stacks[stack_idx]["item"], get_viewport().get_mouse_position())

func _on_inv_slot_mouse_exited() -> void:
	_hide_item_hover_tooltip()

func _on_equip_slot_gui_input(event: InputEvent, slot_key: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		var equip: Dictionary = GameManager.player_data.get("equipment", {})
		var item = equip.get(slot_key)
		if item != null:
			_show_item_info(item, get_viewport().get_mouse_position())

func _on_inv_slot_gui_input(event: InputEvent, stack_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		var stacks: Array = _compute_stacked_inv()
		if stack_idx < stacks.size():
			_show_item_info(stacks[stack_idx]["item"], get_viewport().get_mouse_position(), true)
		else:
			_hide_item_info()
	elif event is InputEventMouseButton and event.double_click and event.button_index == MOUSE_BUTTON_LEFT:
		var stacks: Array = _compute_stacked_inv()
		if stack_idx >= stacks.size():
			return
		var item: Dictionary = stacks[stack_idx]["item"]
		if item.get("type") == "consumable":
			var raw_idx: int = _find_raw_inv_idx(item)
			if raw_idx >= 0:
				_use_consumable(raw_idx, item)

# ── Item info panel ───────────────────────────────────────────────────────────

func _build_item_info_panel() -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(240, 0)
	var style = StyleBoxFlat.new()
	style.bg_color     = Color(0.10, 0.10, 0.14, 0.97)
	style.border_color = Color(0.50, 0.44, 0.32)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_hide_item_info())
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   10)
	margin.add_theme_constant_override("margin_right",  10)
	margin.add_theme_constant_override("margin_top",     8)
	margin.add_theme_constant_override("margin_bottom",  8)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)
	var lbl := RichTextLabel.new()
	lbl.name = "InfoLabel"
	lbl.bbcode_enabled  = true
	lbl.scroll_active   = false
	lbl.fit_content     = true
	lbl.autowrap_mode   = TextServer.AUTOWRAP_WORD_SMART
	lbl.custom_minimum_size = Vector2(220, 0)
	lbl.add_theme_font_size_override("normal_font_size", 12)
	lbl.add_theme_color_override("default_color", Color(0.92, 0.88, 0.80))
	lbl.meta_clicked.connect(_on_keyword_clicked)
	vbox.add_child(lbl)
	_drop_btn = Button.new()
	_drop_btn.name = "DropBtn"
	_drop_btn.text = "Drop"
	_drop_btn.visible = false
	_drop_btn.pressed.connect(_on_drop_btn_pressed)
	vbox.add_child(_drop_btn)
	_affix_talisman_btn = Button.new()
	_affix_talisman_btn.name = "AffixBtn"
	_affix_talisman_btn.text = "Affix to armor..."
	_affix_talisman_btn.visible = false
	_affix_talisman_btn.pressed.connect(_on_affix_talisman_btn_pressed)
	vbox.add_child(_affix_talisman_btn)
	return panel

func _show_item_info(item: Dictionary, screen_pos: Vector2, show_drop: bool = false) -> void:
	if _item_info_panel == null:
		return
	_hide_item_hover_tooltip()
	var margin := _item_info_panel.get_child(0) as MarginContainer
	if margin == null:
		return
	var vbox := margin.get_child(0) as VBoxContainer
	if vbox == null:
		return
	var lbl := vbox.get_child(0) as RichTextLabel
	if lbl == null:
		return
	lbl.text = _format_item_info(item)
	_item_info_drop_target = item
	if _drop_btn != null:
		_drop_btn.visible = show_drop
	if _affix_talisman_btn != null:
		_affix_talisman_btn.visible = show_drop and item.get("type", "") == "talisman"
	# Position first, then show — avoids one-frame flash at wrong position
	var vp_size := get_viewport().get_visible_rect().size
	var pos := screen_pos + Vector2(16, -8)
	pos.x = clampf(pos.x, 4.0, vp_size.x - 260.0)
	pos.y = clampf(pos.y, 4.0, vp_size.y - 120.0)
	_item_info_panel.position = pos
	_item_info_panel.visible = true

func _hide_item_info() -> void:
	if _item_info_panel != null:
		_item_info_panel.visible = false
	_hide_keyword_popup()

func _build_item_hover_tooltip() -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(200, 0)
	var style = StyleBoxFlat.new()
	style.bg_color     = Color(0.10, 0.10, 0.14, 0.97)
	style.border_color = Color(0.50, 0.44, 0.32)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var margin = MarginContainer.new()
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
	lbl.custom_minimum_size = Vector2(200, 0)
	lbl.add_theme_font_size_override("normal_font_size", 12)
	lbl.add_theme_color_override("default_color", Color(0.92, 0.88, 0.80))
	margin.add_child(lbl)
	return panel

func _show_item_hover_tooltip(item: Dictionary, screen_pos: Vector2) -> void:
	if _item_hover_tooltip == null or item.is_empty():
		return
	var margin := _item_hover_tooltip.get_child(0) as MarginContainer
	if margin == null:
		return
	var lbl := margin.get_child(0) as RichTextLabel
	if lbl == null:
		return
	lbl.text = _format_item_info(item)
	var vp_size := get_viewport().get_visible_rect().size
	var pos := screen_pos + Vector2(20, 16)
	pos.x = clampf(pos.x, 4.0, vp_size.x - 220.0)
	pos.y = clampf(pos.y, 4.0, vp_size.y - 120.0)
	_item_hover_tooltip.position = pos
	_item_hover_tooltip.visible = true

func _hide_item_hover_tooltip() -> void:
	if _item_hover_tooltip != null:
		_item_hover_tooltip.visible = false

func _on_drop_btn_pressed() -> void:
	if _item_info_drop_target.is_empty():
		return
	_drop_item(_item_info_drop_target)

func _on_affix_talisman_btn_pressed() -> void:
	var talisman: Dictionary = _item_info_drop_target
	if talisman.get("type", "") != "talisman":
		return
	# Build a list of equipped armor and clothing items to affix to
	var equip: Dictionary = GameManager.player_data.get("equipment", {})
	var options: Array = []
	var hand_slots: Array = ["hand_1", "hand_2", "talisman_1", "talisman_2"]
	var feet_slots: Array = ["feet"]
	for slot_key in equip:
		if slot_key in hand_slots or slot_key in feet_slots:
			continue
		var eq_item = equip.get(slot_key)
		if eq_item == null:
			continue
		var t: String = eq_item.get("type", "")
		if t not in ["armor", "clothing", "trinket"]:
			continue
		var captured_slot: String = slot_key
		var captured_item: Dictionary = eq_item
		options.append({
			"label": "%s (%s)" % [captured_item.get("name", "?"), captured_slot.capitalize().replace("_", " ")],
			"action": func():
				_affix_talisman_to_item(talisman, captured_slot)
		})
	if options.is_empty():
		EventBus.combat_log.emit("No valid armor or clothing equipped to affix to.")
		_hide_item_info()
		return
	_hide_item_info()
	EventBus.show_context_menu.emit(null, options, get_viewport().get_mouse_position())

func _affix_talisman_to_item(talisman: Dictionary, equip_slot: String) -> void:
	var equip: Dictionary = GameManager.player_data.get("equipment", {})
	var target = equip.get(equip_slot)
	if target == null:
		return
	# Copy spirit ward to target
	target["spirit_ward"]       = talisman.get("spirit_ward", false)
	target["spirit_ward_level"] = talisman.get("spirit_ward_level", 0)
	var sw_lvl: int = talisman.get("spirit_ward_level", 0)
	var ins_text: String = "%s — Spirit Ward Lv.%d" % [talisman.get("name", "Talisman"), sw_lvl]
	var inscriptions: Array = target.get("talisman_inscriptions", [])
	inscriptions.append(ins_text)
	target["talisman_inscriptions"] = inscriptions
	equip[equip_slot] = target
	# Remove talisman from inventory
	var inv: Array = GameManager.player_data.get("inventory", [])
	var tal_id: String = talisman.get("id", "")
	for i in range(inv.size() - 1, -1, -1):
		if inv[i].get("id", "") == tal_id:
			inv.remove_at(i)
			break
	GameManager.player_data["inventory"] = inv
	GameManager.player_data["equipment"] = equip
	EventBus.inventory_changed.emit()
	_refresh_inventory()

func _drop_item(item: Dictionary) -> void:
	var item_id: String = item.get("id", "")
	var inv: Array = GameManager.player_data.get("inventory", [])
	for i in range(inv.size()):
		if inv[i].get("id", "") == item_id:
			inv.remove_at(i)
			break
	GameManager.player_data["inventory"] = inv
	_refresh_inventory()
	_hide_item_info()
	var player := GameManager.player
	var zone := GameManager.current_zone
	if player == null or zone == null:
		return
	var gi := GroundItem.new()
	gi.grid_cell = player.get("grid_cell")
	gi.item_data = item.duplicate()
	zone.add_child(gi)
	# Persist the dropped item immediately so zone save/restore is consistent
	var tile_data: Dictionary = GameManager.get_tile_data(GameManager.world_layer, GameManager.world_pos)
	var scene_path: String = tile_data.get("scene", str(GameManager.world_pos))
	var ground_items: Dictionary = GameManager.player_data.get("ground_items", {})
	var arr: Array = ground_items.get(scene_path, [])
	arr.append({"cell": [gi.grid_cell.x, gi.grid_cell.y], "item": item.duplicate()})
	ground_items[scene_path] = arr
	GameManager.player_data["ground_items"] = ground_items

func _build_pile_panel() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(200, 0)
	panel.z_index = 120
	var style := StyleBoxFlat.new()
	style.bg_color     = Color(0.10, 0.10, 0.14, 0.97)
	style.border_color = Color(0.50, 0.44, 0.32)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", style)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   10)
	margin.add_theme_constant_override("margin_right",  10)
	margin.add_theme_constant_override("margin_top",     8)
	margin.add_theme_constant_override("margin_bottom",  8)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.name = "PileVBox"
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)
	return panel

func _open_pile_panel(source: Node) -> void:
	var cell: Vector2i = source.get("grid_cell")
	if cell == null:
		return
	_pile_cell = cell
	_refresh_pile_panel()
	if _pile_panel.visible:
		var vp_size := get_viewport().get_visible_rect().size
		_pile_panel.position = (vp_size - Vector2(220, 0)) / 2.0

func _refresh_pile_panel() -> void:
	var zone := GameManager.current_zone
	if zone == null:
		_pile_panel.visible = false
		return
	var tile_scene := zone as TileScene
	if tile_scene == null:
		_pile_panel.visible = false
		return
	var items: Array = tile_scene.get_ground_items_at(_pile_cell)
	if items.is_empty():
		_pile_panel.visible = false
		return
	var margin := _pile_panel.get_child(0) as MarginContainer
	var vbox  := margin.get_child(0) as VBoxContainer
	for child in vbox.get_children():
		vbox.remove_child(child)
		child.queue_free()
	var hdr := Label.new()
	hdr.text = "Items on ground (%d)" % items.size()
	hdr.add_theme_font_size_override("font_size", 12)
	hdr.add_theme_color_override("font_color", Color(0.75, 0.70, 0.55))
	vbox.add_child(hdr)
	vbox.add_child(HSeparator.new())
	for gi in items:
		if not is_instance_valid(gi):
			continue
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var lbl := Label.new()
		lbl.text = gi.item_data.get("name", "Item")
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", Color(0.92, 0.88, 0.80))
		row.add_child(lbl)
		var btn := Button.new()
		btn.text = "Take"
		var captured: Node = gi
		btn.pressed.connect(func():
			captured.pick_up()
			_refresh_inventory()
			_refresh_pile_panel())
		row.add_child(btn)
		vbox.add_child(row)
	var sep2 := HSeparator.new()
	vbox.add_child(sep2)
	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.pressed.connect(func(): _pile_panel.visible = false)
	vbox.add_child(close_btn)
	_pile_panel.visible = true
	var vp_size := get_viewport().get_visible_rect().size
	_pile_panel.position = (vp_size - Vector2(220, 0)) / 2.0

# ══════════════════════════════════════════════════════════════════════════════
# CONTAINER PANEL — generic two-pane transfer UI for lootable containers
# ══════════════════════════════════════════════════════════════════════════════
func _build_container_panel() -> Control:
	var shell := _make_panel_shell("Container")
	var root: Control       = shell["root"]
	var vbox: VBoxContainer  = shell["vbox"]

	var hdr: HBoxContainer = vbox.get_child(0) as HBoxContainer
	_container_title_lbl = hdr.get_child(0) as Label

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 16)
	vbox.add_child(body)

	var container_vbox := _build_container_column(body, "Contents")
	body.add_child(VSeparator.new())
	var player_vbox := _build_container_column(body, "Inventory")

	root.set_meta("container_vbox", container_vbox)
	root.set_meta("player_vbox", player_vbox)
	return root

# Builds one scrollable list column for the container panel and adds it to `body`.
func _build_container_column(body: HBoxContainer, title: String) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 4)
	body.add_child(col)

	var hdr := Label.new()
	hdr.text = title
	hdr.add_theme_font_size_override("font_size", 13)
	col.add_child(hdr)
	col.add_child(HSeparator.new())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)

	var list_vbox := VBoxContainer.new()
	list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_vbox.add_theme_constant_override("separation", 2)
	scroll.add_child(list_vbox)
	return list_vbox

func _open_container_panel(entity: Node) -> void:
	_close_all()
	_container_entity = entity
	if _container_title_lbl != null:
		var title: String = entity.get("entity_name") if entity.get("entity_name") != null else "Container"
		_container_title_lbl.text = title
	_refresh_container_panel()
	_container_panel.visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP

func _refresh_container_panel() -> void:
	if _container_entity == null or not is_instance_valid(_container_entity):
		_container_panel.visible = false
		return

	var container_vbox: VBoxContainer = _container_panel.get_meta("container_vbox") as VBoxContainer
	var player_vbox: VBoxContainer    = _container_panel.get_meta("player_vbox") as VBoxContainer
	for child in container_vbox.get_children():
		child.queue_free()
	for child in player_vbox.get_children():
		child.queue_free()

	var container_stacks: Array = _compute_stacks(_container_entity.get_inventory())
	_populate_container_column(container_vbox, container_stacks, "Take", _container_take_item)

	var player_stacks: Array = _compute_stacked_inv()
	_populate_container_column(player_vbox, player_stacks, "Store", _container_store_item)

# Fills a container-panel column with one row per stack: [name ×count] + an action button.
func _populate_container_column(list_vbox: VBoxContainer, stacks: Array, action_label: String, action: Callable) -> void:
	if stacks.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "(empty)"
		empty_lbl.add_theme_font_size_override("font_size", 12)
		empty_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
		list_vbox.add_child(empty_lbl)
		return

	for stack in stacks:
		var item: Dictionary = stack["item"]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		var lbl := Label.new()
		var name_text: String = item.get("name", "Item")
		if stack["count"] > 1:
			name_text += " ×%d" % stack["count"]
		lbl.text = name_text
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", Color(0.92, 0.88, 0.80))
		row.add_child(lbl)

		var btn := Button.new()
		btn.text = action_label
		var captured_item: Dictionary = item
		btn.pressed.connect(func(): action.call(captured_item))
		row.add_child(btn)

		list_vbox.add_child(row)

# Moves one copy of `item` from the open container into the player's inventory.
func _container_take_item(item: Dictionary) -> void:
	if _container_entity == null or not is_instance_valid(_container_entity):
		return
	var container_items: Array = _container_entity.get_inventory()
	var idx: int = container_items.find(item)
	if idx == -1:
		return
	container_items.remove_at(idx)
	_container_entity.set_inventory(container_items)

	var inv: Array = GameManager.player_data.get("inventory", [])
	inv.append(item.duplicate())
	GameManager.player_data["inventory"] = inv

	EventBus.inventory_changed.emit()
	_refresh_container_panel()

# Moves one copy of `item` from the player's inventory into the open container.
func _container_store_item(item: Dictionary) -> void:
	var inv: Array = GameManager.player_data.get("inventory", [])
	var idx: int = inv.find(item)
	if idx == -1:
		return
	inv.remove_at(idx)
	GameManager.player_data["inventory"] = inv

	var container_items: Array = _container_entity.get_inventory()
	container_items.append(item.duplicate())
	_container_entity.set_inventory(container_items)

	EventBus.inventory_changed.emit()
	_refresh_container_panel()

func _build_keyword_popup() -> Control:
	var panel := PanelContainer.new()
	panel.z_index = 210
	panel.custom_minimum_size = Vector2(200, 0)
	var style := StyleBoxFlat.new()
	style.bg_color     = Color(0.08, 0.07, 0.04, 0.97)
	style.border_color = Color(0.80, 0.65, 0.20)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", style)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   10)
	margin.add_theme_constant_override("margin_right",  10)
	margin.add_theme_constant_override("margin_top",     8)
	margin.add_theme_constant_override("margin_bottom",  8)
	panel.add_child(margin)
	var lbl := Label.new()
	lbl.name = "KeywordLabel"
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.custom_minimum_size = Vector2(180, 0)
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color(0.95, 0.90, 0.72))
	margin.add_child(lbl)
	return panel

func _show_keyword_popup(keyword: String) -> void:
	if _keyword_popup == null or _item_info_panel == null:
		return
	var def: String = KEYWORD_DEFS.get(keyword, "")
	if def == "":
		return
	var lbl := _keyword_popup.get_child(0).get_child(0) as Label
	if lbl == null:
		return
	lbl.text = def
	# Anchor to the right of the item info panel (use 260 as safe width estimate)
	var vp_size := get_viewport().get_visible_rect().size
	var base := _item_info_panel.position
	var panel_w: float = _item_info_panel.size.x if _item_info_panel.size.x > 10.0 else 260.0
	var pos := base + Vector2(panel_w + 6.0, 0.0)
	pos.x = clampf(pos.x, 4.0, vp_size.x - 220.0)
	pos.y = clampf(pos.y, 4.0, vp_size.y - 200.0)
	_keyword_popup.position = pos
	_keyword_popup.visible = true

func _hide_keyword_popup() -> void:
	if _keyword_popup != null:
		_keyword_popup.visible = false

func _on_keyword_clicked(meta: Variant) -> void:
	var keyword: String = str(meta)
	if _keyword_popup != null and _keyword_popup.visible:
		# Clicking same keyword again closes it
		var lbl := _keyword_popup.get_child(0).get_child(0) as Label
		if lbl != null and lbl.text.begins_with(keyword.capitalize()):
			_hide_keyword_popup()
			return
	_show_keyword_popup(keyword)

func _format_item_info(item: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append(_display_item_name(item))
	var desc: String = item.get("description", "")
	if desc != "":
		lines.append("")
		lines.append(desc)
	lines.append("")
	var item_type: String = item.get("type", "")
	if item_type == "weapon":
		var gov: Array = item.get("governing", [])
		var stats: Dictionary = GameManager.player_data.get("stats", {})
		var best_mod := 0
		for stat in gov:
			var m: int = stats.get(stat, 5) - 5
			if m > best_mod:
				best_mod = m
		var dmg_str: String = item.get("damage", "—")
		if best_mod > 0:
			dmg_str += " +%d" % best_mod
		elif best_mod < 0:
			dmg_str += " %d" % best_mod
		lines.append("Damage: %s   AP: %d   Range: %d" % [
			dmg_str,
			item.get("ap_cost", 0),
			item.get("range", 1),
		])
		var gov_str: String = " / ".join(gov).to_upper()
		# Infer skill from range if the field is missing (bows/guns have range > 1)
		var skill_raw = item.get("skill")
		var skill_str: String
		if skill_raw != null:
			skill_str = str(skill_raw).capitalize()
		elif item.get("range", 1) > 1:
			skill_str = "Ranged"
		else:
			skill_str = "Melee"
		lines.append("Skill: %s  (%s)" % [skill_str, gov_str])
		var props: Array = item.get("properties", [])
		if not props.is_empty():
			var prop_parts: Array[String] = []
			for p_raw in props:
				var p: String = str(p_raw)
				if KEYWORD_DEFS.has(p):
					prop_parts.append("[url=%s][color=#f0c060][u]%s[/u][/color][/url]" % [p, p.capitalize()])
				else:
					prop_parts.append(p.capitalize())
			lines.append("Properties: " + ", ".join(prop_parts))
		var abilities: Array = item.get("abilities", [])
		if not abilities.is_empty():
			lines.append("Abilities: " + ", ".join(abilities.map(func(a): return a.capitalize())))
		if "throw_range" in item:
			lines.append("Throw range: %d" % item["throw_range"])
		if "reload_cost" in item:
			lines.append("Reload cost: %d AP" % item["reload_cost"])
		if item.get("poisoned", false):
			lines.append("[color=#44ee44]Poisoned — applies poison on hit (lasts until rest)[/color]")
	elif item_type in ["armor", "clothing"]:
		var flat: int   = item.get("defense_flat", 0)
		var pct: float  = item.get("defense_pct", 0.0)
		var parts: Array[String] = []
		if flat > 0:
			parts.append("+%d flat" % flat)
		if pct > 0.0:
			parts.append("+%d%%" % int(pct * 100))
		if not parts.is_empty():
			lines.append("Defense: " + "  /  ".join(parts))
		var block_flat: float = item.get("block_flat", 0.0)
		if block_flat > 0.0:
			var gov_parts: Array[String] = []
			for stat in item.get("governing", []):
				gov_parts.append(str(stat).capitalize())
			var gov_str: String = " or ".join(gov_parts) if not gov_parts.is_empty() else "Strength"
			lines.append("Block: +%d flat  (on a successful %s-based melee block)" % [int(block_flat), gov_str])
		lines.append("Type: " + item_type.capitalize())
		var skill_bonus: Dictionary = item.get("skill_bonus", {})
		for sk in skill_bonus:
			lines.append("%s bonus: +%d" % [sk.capitalize(), skill_bonus[sk]])
		var cw: int = item.get("carry_weight_bonus", 0)
		if cw > 0:
			lines.append("Carry weight: +%d" % cw)
		var inscriptions: Array = item.get("talisman_inscriptions", [])
		for ins in inscriptions:
			lines.append("[color=#ff8800]Inscription: %s[/color]" % ins)
	elif item_type == "talisman":
		lines.append("Type: Talisman")
		if item.get("spirit_ward", false):
			var sw_lvl: int = item.get("spirit_ward_level", 0)
			if sw_lvl >= 1:
				lines.append("Spirit Ward (level 1) — allows rest anywhere.")
			else:
				lines.append("Spirit Ward (level 0) — allows rest in the city only.")
		lines.append("Can be equipped in most slots, or affixed permanently to armor or clothing.")
	elif item_type == "ammo":
		lines.append("Type: Ammunition")
	elif item_type == "tool":
		lines.append("Type: Tool")
	elif item_type == "trinket":
		lines.append("Type: Trophy Trinket")
		if item.get("spirit_ward", false):
			var sw_lvl: int = item.get("spirit_ward_level", 0)
			if sw_lvl >= 1:
				lines.append("Spirit Ward (level 1) — allows rest anywhere.")
			else:
				lines.append("Spirit Ward (level 0) — allows rest in the city only.")
		var q: int = item.get("quality", -1)
		if q >= 0:
			lines.append("Quality: %s" % item.get("quality_name", "?"))
		var def_flat: float = item.get("defense_flat", 0.0)
		var def_pct: float  = item.get("defense_pct", 0.0)
		if def_flat > 0.0 or def_pct > 0.0:
			var parts: PackedStringArray = []
			if def_flat > 0.0:  parts.append("+%.2f flat" % def_flat)
			if def_pct  > 0.0:  parts.append("+%.1f%%" % (def_pct * 100.0))
			lines.append("Armor: %s" % "  /  ".join(parts))
		var sb: Dictionary = item.get("skill_bonus", {})
		for sk in sb:
			lines.append("%s: +%.2f" % [sk.capitalize(), sb[sk]])
		var gb: Dictionary = item.get("governing_bonus", {})
		for st in gb:
			lines.append("Governing (%s, melee to-hit): +%.2f" % [st.capitalize(), gb[st]])
	lines.append("")
	lines.append("[click to close]")
	return "\n".join(lines)

# ══════════════════════════════════════════════════════════════════════════════
# MAP PANEL
# ══════════════════════════════════════════════════════════════════════════════
func _build_map_panel() -> Control:
	var shell = _make_panel_shell("WORLD MAP")
	var vbox: VBoxContainer = shell["vbox"]

	# Layer navigation
	var nav = HBoxContainer.new()
	nav.add_theme_constant_override("separation", 10)
	vbox.add_child(nav)
	var up_btn = Button.new(); up_btn.text = "▲ Up"
	up_btn.pressed.connect(_map_layer_change.bind(-1))
	var down_btn = Button.new(); down_btn.text = "▼ Down"
	down_btn.pressed.connect(_map_layer_change.bind(1))
	_map_layer_lbl = Label.new()
	_map_layer_lbl.text = "Surface (Layer 0)"
	_map_layer_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_map_layer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for n in [up_btn, _map_layer_lbl, down_btn]: nav.add_child(n)

	# Tile grid
	var grid_container = HBoxContainer.new()
	grid_container.alignment = BoxContainer.ALIGNMENT_CENTER
	grid_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(grid_container)

	var grid = GridContainer.new()
	grid.columns = MAP_COLS
	grid.add_theme_constant_override("h_separation", 2)
	grid.add_theme_constant_override("v_separation", 2)
	grid_container.add_child(grid)

	_map_cells.clear()
	_map_cell_styles.clear()
	_map_cell_icons.clear()

	for row in range(MAP_ROWS):
		for col in range(MAP_COLS):
			var tile_pos = Vector2i(col, row)

			var cell = Panel.new()
			cell.custom_minimum_size = Vector2(MAP_CELL, MAP_CELL)
			cell.mouse_filter = Control.MOUSE_FILTER_STOP

			var sbox = StyleBoxFlat.new()
			sbox.bg_color = Color(0.08, 0.08, 0.12)
			cell.add_theme_stylebox_override("panel", sbox)

			var icon = _MapThumb.new()
			icon.set_anchors_preset(Control.PRESET_FULL_RECT)
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cell.add_child(icon)

			cell.mouse_entered.connect(_on_map_cell_hover.bind(tile_pos))
			cell.mouse_exited.connect(_on_map_cell_exit)

			grid.add_child(cell)
			_map_cells.append(cell)
			_map_cell_styles.append(sbox)
			_map_cell_icons.append(icon)

	# Legend
	var legend = HBoxContainer.new()
	legend.add_theme_constant_override("separation", 16)
	vbox.add_child(legend)
	for pair in [
		[Color(0.08,0.08,0.12), "Unexplored"],
		[Color(0.32,0.22,0.18), "Slums"],
		[Color(0.30,0.38,0.20), "Wilderness"],
		[Color(0.55,0.45,0.20), "Desert"],
		[Color(0.65,0.55,0.15), "Current"],
	]:
		var lrow = HBoxContainer.new(); lrow.add_theme_constant_override("separation", 4)
		var swatch = ColorRect.new(); swatch.custom_minimum_size = Vector2(16,16); swatch.color = pair[0]
		var lbl = Label.new(); lbl.text = pair[1]; lbl.add_theme_font_size_override("font_size",11)
		lrow.add_child(swatch); lrow.add_child(lbl)
		legend.add_child(lrow)

	return shell["root"]

func _map_layer_change(delta: int) -> void:
	_map_layer = clamp(_map_layer + delta, 0, MAP_LAYERS - 1)
	_refresh_map()

# ══════════════════════════════════════════════════════════════════════════════
# CRAFTING PANEL
# ══════════════════════════════════════════════════════════════════════════════
func _on_open_crafting_ui(entity: Node) -> void:
	_crafting_opener = entity
	_crafting_selected_recipe = ""
	_crafting_slotted = {}
	var pd: Dictionary = GameManager.player_data
	# Default tab based on who opened crafting
	if entity != null and entity.get("entity_name") == "Scribe":
		_crafting_active_tab = "scriptures"
	elif entity != null and entity.get("entity_name") == "Apothecary":
		_crafting_active_tab = "alchemy"
	elif entity != null and entity.get("entity_name") == "Smith":
		_crafting_active_tab = "smithing"
	elif not pd.get("hunter_craft_taught", false) and pd.get("known_alchemy_recipes", []).size() > 0:
		_crafting_active_tab = "alchemy"
	else:
		_crafting_active_tab = "way_of_beasts"
	_toggle("crafting")

func _build_crafting_panel() -> Control:
	var shell := _make_panel_shell("CRAFTING")
	var col: VBoxContainer = shell["vbox"]

	# Main row
	var main_row := HBoxContainer.new()
	main_row.add_theme_constant_override("separation", 20)
	main_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(main_row)

	# Left: recipes + detail
	var left_col := VBoxContainer.new()
	left_col.custom_minimum_size = Vector2(300, 0)
	left_col.add_theme_constant_override("separation", 10)
	main_row.add_child(left_col)

	# ── Craft tabs (rebuilt dynamically in _refresh_crafting) ────────────────
	_crafting_tab_row = HBoxContainer.new()
	_crafting_tab_row.add_theme_constant_override("separation", 4)
	left_col.add_child(_crafting_tab_row)

	_crafting_recipe_list = VBoxContainer.new()
	_crafting_recipe_list.add_theme_constant_override("separation", 4)
	left_col.add_child(_crafting_recipe_list)

	left_col.add_child(HSeparator.new())

	var detail_scroll := ScrollContainer.new()
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left_col.add_child(detail_scroll)

	_crafting_detail_area = VBoxContainer.new()
	_crafting_detail_area.add_theme_constant_override("separation", 8)
	_crafting_detail_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_scroll.add_child(_crafting_detail_area)

	main_row.add_child(VSeparator.new())

	# Right: materials inventory
	var right_col := VBoxContainer.new()
	right_col.add_theme_constant_override("separation", 8)
	right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_col.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	main_row.add_child(right_col)

	var inv_hdr := Label.new()
	inv_hdr.text = "YOUR MATERIALS  (click to use as ingredient)"
	inv_hdr.add_theme_font_size_override("font_size", 13)
	right_col.add_child(inv_hdr)

	var inv_scroll := ScrollContainer.new()
	inv_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inv_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right_col.add_child(inv_scroll)

	_crafting_inv_grid = GridContainer.new()
	_crafting_inv_grid.columns = 3
	_crafting_inv_grid.add_theme_constant_override("h_separation", 6)
	_crafting_inv_grid.add_theme_constant_override("v_separation", 6)
	_crafting_inv_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inv_scroll.add_child(_crafting_inv_grid)

	_crafting_inv_btns.clear()

	return shell["root"]

func _refresh_crafting() -> void:
	# ── Rebuild tab buttons based on what the player knows ───────────────────
	if _crafting_tab_row != null:
		for child in _crafting_tab_row.get_children():
			child.queue_free()
		var pd: Dictionary = GameManager.player_data
		var has_wob: bool       = pd.get("hunter_craft_taught", false)
		var has_alch: bool      = pd.get("known_alchemy_recipes", []).size() > 0
		var has_scripture: bool = pd.get("known_scripture_recipes", []).size() > 0
		var has_smithing: bool  = pd.get("known_smithing_recipes", []).size() > 0
		# Cooking tab: show if any preservation recipe known (simple_meal is rest-only, not crafted)
		var cooking_craft: Array = pd.get("known_cooking_recipes", []).filter(
			func(rid): return not DataManager.get_cooking_recipe(rid).get("is_rest_recipe", false))
		var has_cooking: bool = cooking_craft.size() > 0
		var visible_tabs: Array = []
		if has_wob:
			visible_tabs.append(["The Way of Beasts", "way_of_beasts"])
		if has_alch:
			visible_tabs.append(["Alchemy", "alchemy"])
		if has_scripture:
			visible_tabs.append(["Scriptures", "scriptures"])
		if has_smithing:
			visible_tabs.append(["Smithing", "smithing"])
		if has_cooking:
			visible_tabs.append(["Preserve Food", "cooking"])
		# If the currently active tab is no longer visible, switch to the first available
		var tab_ids: Array = visible_tabs.map(func(t): return t[1])
		if _crafting_active_tab not in tab_ids and not visible_tabs.is_empty():
			_crafting_active_tab = visible_tabs[0][1]
		for tab_def in visible_tabs:
			var tab_btn := Button.new()
			tab_btn.text = tab_def[0]
			tab_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			if tab_def[1] == _crafting_active_tab:
				tab_btn.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
			var cap_tab: String = tab_def[1]
			tab_btn.pressed.connect(func():
				_crafting_active_tab = cap_tab
				_crafting_selected_recipe = ""
				_crafting_slotted = {}
				_refresh_crafting())
			_crafting_tab_row.add_child(tab_btn)

	# Rebuild recipe list for the active tab
	for child in _crafting_recipe_list.get_children():
		child.queue_free()

	if _crafting_active_tab == "alchemy":
		var known_alchemy: Array = GameManager.player_data.get("known_alchemy_recipes", [])
		for rid in known_alchemy:
			var recipe: Dictionary = DataManager.get_alchemy_recipe(rid)
			if recipe.is_empty():
				continue
			var btn := Button.new()
			btn.text = recipe.get("name", rid)
			btn.custom_minimum_size = Vector2(0, 34)
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			if rid == _crafting_selected_recipe:
				btn.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
			var captured_id: String = rid
			btn.pressed.connect(func():
				_crafting_selected_recipe = captured_id
				_crafting_slotted = {}
				_refresh_crafting())
			_crafting_recipe_list.add_child(btn)
	elif _crafting_active_tab == "scriptures":
		var known_scripture: Array = GameManager.player_data.get("known_scripture_recipes", [])
		for rid in known_scripture:
			var recipe: Dictionary = DataManager.get_scripture_recipe(rid)
			if recipe.is_empty():
				continue
			var btn := Button.new()
			btn.text = recipe.get("name", rid)
			btn.custom_minimum_size = Vector2(0, 34)
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			if rid == _crafting_selected_recipe:
				btn.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
			var captured_id: String = rid
			btn.pressed.connect(func():
				_crafting_selected_recipe = captured_id
				_crafting_slotted = {}
				_refresh_crafting())
			_crafting_recipe_list.add_child(btn)
	elif _crafting_active_tab == "smithing":
		var known_smithing: Array = GameManager.player_data.get("known_smithing_recipes", [])
		for rid in known_smithing:
			var recipe: Dictionary = DataManager.get_smithing_recipe(rid)
			if recipe.is_empty():
				continue
			var btn := Button.new()
			btn.text = recipe.get("name", rid)
			btn.custom_minimum_size = Vector2(0, 34)
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			if rid == _crafting_selected_recipe:
				btn.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
			var captured_id: String = rid
			btn.pressed.connect(func():
				_crafting_selected_recipe = captured_id
				_crafting_slotted = {}
				_refresh_crafting())
			_crafting_recipe_list.add_child(btn)
	elif _crafting_active_tab == "cooking":
		var known_cooking: Array = GameManager.player_data.get("known_cooking_recipes", [])
		for rid in known_cooking:
			var recipe: Dictionary = DataManager.get_cooking_recipe(rid)
			if recipe.is_empty() or recipe.get("is_rest_recipe", false):
				continue
			var btn := Button.new()
			btn.text = recipe.get("name", rid)
			btn.custom_minimum_size = Vector2(0, 34)
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			if rid == _crafting_selected_recipe:
				btn.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
			var captured_id: String = rid
			btn.pressed.connect(func():
				_crafting_selected_recipe = captured_id
				_crafting_slotted = {}
				_refresh_crafting())
			_crafting_recipe_list.add_child(btn)
	else:
		var known: Array = GameManager.player_data.get("known_recipes", [])
		for rid in known:
			var recipe: Dictionary = DataManager.get_recipe(rid)
			if recipe.is_empty():
				continue
			if recipe.get("category", "way_of_beasts") != "way_of_beasts":
				continue
			var btn := Button.new()
			btn.text = recipe.get("name", rid)
			btn.custom_minimum_size = Vector2(0, 34)
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			if rid == _crafting_selected_recipe:
				btn.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
			var captured_id: String = rid
			btn.pressed.connect(func():
				_crafting_selected_recipe = captured_id
				_crafting_slotted = {}
				_refresh_crafting())
			_crafting_recipe_list.add_child(btn)

	# Rebuild inventory list (items grouped by id, with count)
	_crafting_materials.clear()
	var inv: Array = GameManager.player_data.get("inventory", [])
	var seen_ids: Dictionary = {}  # item_id -> index in _crafting_materials
	for i in range(inv.size()):
		var item: Dictionary = inv[i]
		var iid: String = item.get("id", "##%d" % i)
		if iid in seen_ids:
			_crafting_materials[seen_ids[iid]]["count"] += 1
		else:
			seen_ids[iid] = _crafting_materials.size()
			_crafting_materials.append({"item": item, "inv_idx": i, "count": 1})

	# Build set of slotted inv indices for highlight check
	var slotted_indices: Array = []
	for val in _crafting_slotted.values():
		slotted_indices.append(val["inv_idx"])

	# Rebuild buttons dynamically so the list can scroll
	_crafting_inv_btns.clear()
	if _crafting_inv_grid != null:
		for child in _crafting_inv_grid.get_children():
			child.queue_free()
		for i in range(_crafting_materials.size()):
			var mat_entry: Dictionary = _crafting_materials[i]
			var mat: Dictionary = mat_entry["item"]
			var count: int = mat_entry.get("count", 1)
			var btn := Button.new()
			btn.custom_minimum_size = Vector2(120, 52)
			btn.add_theme_font_size_override("font_size", 10)
			btn.clip_text = true
			btn.text = mat.get("name", "?") + (" x%d" % count if count > 1 else "")
			if mat_entry["inv_idx"] in slotted_indices:
				btn.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
			var captured_i: int = i
			btn.pressed.connect(_on_crafting_mat_pressed.bind(captured_i))
			_crafting_inv_grid.add_child(btn)
			_crafting_inv_btns.append(btn)

	_refresh_crafting_detail()

func _refresh_crafting_detail() -> void:
	for child in _crafting_detail_area.get_children():
		child.queue_free()

	if _crafting_selected_recipe == "":
		var hint := Label.new()
		hint.text = "Select a recipe from the list."
		hint.add_theme_color_override("font_color", Color(0.55, 0.55, 0.62))
		_crafting_detail_area.add_child(hint)
		return

	# Alchemy, scripture, and smithing recipes have their own detail layouts
	if _crafting_active_tab == "alchemy":
		_refresh_alchemy_detail()
		return
	if _crafting_active_tab == "scriptures":
		_refresh_scripture_detail()
		return
	if _crafting_active_tab == "smithing":
		_refresh_smithing_detail()
		return
	if _crafting_active_tab == "cooking":
		_refresh_cooking_detail()
		return

	var recipe: Dictionary = DataManager.get_recipe(_crafting_selected_recipe)

	var name_lbl := Label.new()
	name_lbl.text = recipe.get("name", "?")
	name_lbl.add_theme_font_size_override("font_size", 14)
	_crafting_detail_area.add_child(name_lbl)

	var req_mats: Array = recipe.get("required_materials", [])
	var req_lbl := Label.new()
	var req_names: Array = []
	for m in req_mats:
		req_names.append(DataManager.slot_display_name(m))
	req_lbl.text = "Requires: %s" % ", ".join(req_names)
	req_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	_crafting_detail_area.add_child(req_lbl)

	var lore_lbl := Label.new()
	lore_lbl.text = recipe.get("lore", "")
	lore_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lore_lbl.add_theme_font_size_override("font_size", 11)
	lore_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	_crafting_detail_area.add_child(lore_lbl)

	_crafting_detail_area.add_child(HSeparator.new())

	# One row per required material showing slot status
	for slot in req_mats:
		var row := HBoxContainer.new()
		var type_lbl := Label.new()
		type_lbl.text = DataManager.slot_display_name(slot) + ":"
		type_lbl.custom_minimum_size = Vector2(130, 0)
		row.add_child(type_lbl)
		var slot_lbl := Label.new()
		if _crafting_slotted.has(slot):
			slot_lbl.text = _crafting_slotted[slot]["item"].get("name", "?")
			slot_lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
		else:
			slot_lbl.text = "— select from inventory"
			slot_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.62))
		row.add_child(slot_lbl)
		_crafting_detail_area.add_child(row)

	# Preview based on primary material quality
	var primary_type: String = req_mats[0] if req_mats.size() > 0 else ""
	if _crafting_slotted.has(primary_type):
		var primary_mat: Dictionary = _crafting_slotted[primary_type]["item"]
		var crafted: Dictionary = DataManager.craft_trophy(_crafting_selected_recipe, {primary_type: primary_mat})
		if not crafted.is_empty():
			var preview_lbl := Label.new()
			preview_lbl.text = "Result: %s\n\n%s" % [crafted.get("name", "?"), crafted.get("description", "")]
			preview_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			preview_lbl.add_theme_font_size_override("font_size", 11)
			_crafting_detail_area.add_child(preview_lbl)

	# Skill requirement label + Craft button
	var all_slotted: bool = req_mats.size() > 0
	for mat_type in req_mats:
		if not _crafting_slotted.has(mat_type):
			all_slotted = false
			break
	var primary_quality: int = 4  # default to Fine for display before material is selected
	if primary_type != "" and _crafting_slotted.has(primary_type):
		primary_quality = _crafting_slotted[primary_type]["item"].get("quality", 4)
	var skill_result: Dictionary = DataManager.check_craft_skill(
		_crafting_selected_recipe, primary_quality,
		GameManager.player_data.get("skills", {}))
	if recipe.get("craft_level", 0) > 0:
		var req_c: int = skill_result["required_crafting"]
		var req_s: int = skill_result["required_survival"]
		var met: bool  = skill_result["can_craft"]
		var skill_lbl := Label.new()
		if skill_result["hunter_taught"] and req_s >= 0:
			skill_lbl.text = "Requires: Survival %d" % req_s
		else:
			skill_lbl.text = "Requires: Smithing %d" % req_c
		skill_lbl.add_theme_font_size_override("font_size", 11)
		skill_lbl.add_theme_color_override("font_color",
			Color(0.35, 0.85, 0.35) if met else Color(0.9, 0.35, 0.35))
		_crafting_detail_area.add_child(skill_lbl)
	if all_slotted:
		var craft_btn := Button.new()
		craft_btn.text = "Craft"
		craft_btn.custom_minimum_size = Vector2(120, 36)
		if skill_result["can_craft"]:
			craft_btn.pressed.connect(_on_craft_pressed)
		else:
			craft_btn.disabled = true
		_crafting_detail_area.add_child(craft_btn)

func _refresh_cooking_detail() -> void:
	var recipe: Dictionary = DataManager.get_cooking_recipe(_crafting_selected_recipe)

	var name_lbl := Label.new()
	name_lbl.text = recipe.get("name", "?")
	name_lbl.add_theme_font_size_override("font_size", 14)
	_crafting_detail_area.add_child(name_lbl)

	var lore_lbl := Label.new()
	lore_lbl.text = recipe.get("lore", "")
	lore_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lore_lbl.add_theme_font_size_override("font_size", 11)
	lore_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	_crafting_detail_area.add_child(lore_lbl)

	_crafting_detail_area.add_child(HSeparator.new())

	# Ingredient rows — player selects from inventory list on the left
	var req_mats: Array = recipe.get("required_materials", [])
	var all_slotted: bool = true
	for slot in req_mats:
		if not _crafting_slotted.has(slot):
			all_slotted = false
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var type_lbl := Label.new()
		type_lbl.text = slot.capitalize() + ":"
		type_lbl.custom_minimum_size = Vector2(60, 0)
		row.add_child(type_lbl)
		if _crafting_slotted.has(slot):
			var slot_lbl := Label.new()
			slot_lbl.text = _crafting_slotted[slot]["item"].get("name", "?") + "  ✓"
			slot_lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
			slot_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(slot_lbl)
			var clear_btn := Button.new()
			clear_btn.text = "×"
			clear_btn.custom_minimum_size = Vector2(28, 0)
			var captured_slot: String = slot
			clear_btn.pressed.connect(func():
				_crafting_slotted.erase(captured_slot)
				_refresh_crafting())
			row.add_child(clear_btn)
		else:
			var slot_lbl := Label.new()
			slot_lbl.text = "— select from inventory list"
			slot_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
			row.add_child(slot_lbl)
		_crafting_detail_area.add_child(row)

	# Preview result
	var _primary_preview_slot: String = _get_primary_cooking_slot()
	if not _primary_preview_slot.is_empty():
		var preview: Dictionary = DataManager.craft_cooking(_crafting_selected_recipe, _crafting_slotted[_primary_preview_slot]["item"])
		if not preview.is_empty():
			var exp_r: int = preview.get("expires_in_rests", -1)
			var buff: Dictionary = preview.get("passive_meal_buff", {})
			var buff_line: String = ""
			if buff.has("hp_pct"):
				buff_line = "\nEaten without cooking: %s — +%d%% max HP until next rest" % [buff.get("name", "Salted Provisions"), int(buff["hp_pct"] * 100)]
			var preview_lbl := Label.new()
			preview_lbl.text = "Result: %s\nSpoils in: %d rests%s\n\n%s" % [
				preview.get("name", "?"), exp_r, buff_line, preview.get("description", "")]
			preview_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			preview_lbl.add_theme_font_size_override("font_size", 11)
			_crafting_detail_area.add_child(preview_lbl)

	# Skill requirement
	var skill_result: Dictionary = DataManager.check_cooking_skill(
		_crafting_selected_recipe, GameManager.player_data.get("skills", {}))
	if recipe.get("cooking_level", 0) > 0:
		var skill_lbl := Label.new()
		var req_c: int = skill_result["req_cooking"]
		var req_s: int = skill_result["req_survival"]
		if req_s >= 0:
			skill_lbl.text = "Requires: Cooking %d  or  Survival %d" % [req_c, req_s]
		else:
			skill_lbl.text = "Requires: Cooking %d" % req_c
		skill_lbl.add_theme_font_size_override("font_size", 11)
		skill_lbl.add_theme_color_override("font_color",
			Color(0.35, 0.85, 0.35) if skill_result["can_craft"] else Color(0.9, 0.35, 0.35))
		_crafting_detail_area.add_child(skill_lbl)

	# Location requirement
	var on_surface: bool = GameManager.world_layer == 0
	var location_ok: bool = (not recipe.get("surface_only", false)) or on_surface
	if recipe.get("surface_only", false):
		var location_lbl := Label.new()
		location_lbl.text = "Requires: Direct sunlight (surface)"
		location_lbl.add_theme_font_size_override("font_size", 11)
		location_lbl.add_theme_color_override("font_color",
			Color(0.35, 0.85, 0.35) if on_surface else Color(0.9, 0.35, 0.35))
		_crafting_detail_area.add_child(location_lbl)

	var craft_btn := Button.new()
	craft_btn.text = "Craft"
	craft_btn.custom_minimum_size = Vector2(120, 36)
	craft_btn.disabled = not (all_slotted and skill_result["can_craft"] and location_ok)
	if not craft_btn.disabled:
		craft_btn.pressed.connect(_on_cooking_craft_pressed)
	_crafting_detail_area.add_child(craft_btn)

func _get_primary_cooking_slot() -> String:
	var recipe: Dictionary = DataManager.get_cooking_recipe(_crafting_selected_recipe)
	if recipe.is_empty():
		return ""
	for slot in recipe.get("required_materials", []):
		if _crafting_slotted.has(slot):
			return slot
	return ""

func _on_cooking_craft_pressed() -> void:
	var recipe: Dictionary = DataManager.get_cooking_recipe(_crafting_selected_recipe)
	if recipe.is_empty():
		return
	var primary_key: String = _get_primary_cooking_slot()
	if primary_key.is_empty():
		return
	var primary_slot: Dictionary = _crafting_slotted.get(primary_key, {})
	if primary_slot.is_empty():
		return
	var primary_item: Dictionary = primary_slot["item"]
	var primary_idx: int         = primary_slot["inv_idx"]
	var crafted: Dictionary      = DataManager.craft_cooking(_crafting_selected_recipe, primary_item)
	if crafted.is_empty():
		return
	var inv: Array = GameManager.player_data.get("inventory", [])
	if primary_idx < 0 or primary_idx >= inv.size():
		return
	# Consume one use of primary ingredient; remove if depleted
	var uses_left: int = inv[primary_idx].get("uses_remaining", 1) - 1
	if uses_left <= 0:
		inv.remove_at(primary_idx)
	else:
		inv[primary_idx]["uses_remaining"] = uses_left
	# Salt is consumed whole (one item per craft)
	if _crafting_slotted.has("salt"):
		var salt_idx: int = _crafting_slotted["salt"]["inv_idx"]
		# Adjust index if primary was removed before it
		if primary_idx < salt_idx and uses_left <= 0:
			salt_idx -= 1
		if salt_idx >= 0 and salt_idx < inv.size():
			inv.remove_at(salt_idx)
	inv.append(crafted)
	GameManager.player_data["inventory"] = inv
	_crafting_slotted = {}
	_crafting_selected_recipe = ""
	_refresh_crafting()
	_refresh_inventory()

func _refresh_smithing_detail() -> void:
	var recipe: Dictionary = DataManager.get_smithing_recipe(_crafting_selected_recipe)

	var name_lbl := Label.new()
	name_lbl.text = recipe.get("name", "?")
	name_lbl.add_theme_font_size_override("font_size", 14)
	_crafting_detail_area.add_child(name_lbl)

	var lore_lbl := Label.new()
	lore_lbl.text = recipe.get("lore", "")
	lore_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lore_lbl.add_theme_font_size_override("font_size", 11)
	lore_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	_crafting_detail_area.add_child(lore_lbl)

	_crafting_detail_area.add_child(HSeparator.new())

	# Find required material in inventory (by ID, checking uses > 0)
	var required_id: String = recipe.get("required_material", "")
	var inv: Array = GameManager.player_data.get("inventory", [])
	var mat_item: Dictionary = {}
	var mat_inv_idx: int = -1
	for i in range(inv.size()):
		if inv[i].get("id", "") == required_id and inv[i].get("uses", 1) > 0:
			mat_item = inv[i]
			mat_inv_idx = i
			break

	var req_data: Dictionary = DataManager.get_item(required_id)
	var have: bool = not mat_item.is_empty()
	var uses_left: int = mat_item.get("uses", 0) if have else 0
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var icon := ItemIcon.new()
	icon.custom_minimum_size = Vector2(28, 28)
	icon.item_id = required_id
	row.add_child(icon)
	var status_lbl := Label.new()
	if have:
		status_lbl.text = "(%d use%s remaining)  ✓" % [uses_left, "s" if uses_left != 1 else ""]
	else:
		status_lbl.text = "✗"
	status_lbl.add_theme_color_override("font_color",
		Color(0.4, 0.9, 0.4) if have else Color(0.85, 0.35, 0.35))
	row.add_child(status_lbl)
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	row.mouse_entered.connect(func(): _show_item_hover_tooltip(req_data, get_viewport().get_mouse_position()))
	row.mouse_exited.connect(_hide_item_hover_tooltip)
	_crafting_detail_area.add_child(row)

	# Quality preview
	if have:
		var quality: float = mat_item.get("quality_value", 0.5)
		var quality_lbl := Label.new()
		quality_lbl.text = "Metal quality: %s (%.0f%%)" % [
			DataManager.metal_quality_name(quality), quality * 100.0]
		quality_lbl.add_theme_font_size_override("font_size", 11)
		quality_lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.80))
		_crafting_detail_area.add_child(quality_lbl)

		var crafted: Dictionary = DataManager.craft_smithing(_crafting_selected_recipe, mat_item)
		if not crafted.is_empty():
			var preview_lbl := Label.new()
			preview_lbl.text = "Result: %s\n\n%s" % [crafted.get("name", "?"), crafted.get("description", "")]
			preview_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			preview_lbl.add_theme_font_size_override("font_size", 11)
			_crafting_detail_area.add_child(preview_lbl)

	# Skill requirement
	var skill_result: Dictionary = DataManager.check_smithing_skill(
		_crafting_selected_recipe, GameManager.player_data.get("skills", {}))
	if recipe.get("smithing_level", 0) > 0:
		var req_lbl := Label.new()
		req_lbl.text = "Requires: Smithing %d" % skill_result["required_smithing"]
		req_lbl.add_theme_font_size_override("font_size", 11)
		req_lbl.add_theme_color_override("font_color",
			Color(0.35, 0.85, 0.35) if skill_result["can_craft"] else Color(0.9, 0.35, 0.35))
		_crafting_detail_area.add_child(req_lbl)

	var craft_btn := Button.new()
	craft_btn.text = "Craft"
	craft_btn.custom_minimum_size = Vector2(120, 36)
	craft_btn.disabled = not (have and skill_result["can_craft"])
	if not craft_btn.disabled:
		craft_btn.pressed.connect(_on_smithing_craft_pressed.bind(mat_inv_idx))
	_crafting_detail_area.add_child(craft_btn)

func _on_smithing_craft_pressed(mat_inv_idx: int) -> void:
	var recipe: Dictionary = DataManager.get_smithing_recipe(_crafting_selected_recipe)
	if recipe.is_empty():
		return
	var inv: Array = GameManager.player_data.get("inventory", [])
	if mat_inv_idx < 0 or mat_inv_idx >= inv.size():
		return
	var mat_item: Dictionary = inv[mat_inv_idx]
	if mat_item.get("uses", 1) <= 0:
		return
	var crafted: Dictionary = DataManager.craft_smithing(_crafting_selected_recipe, mat_item)
	if crafted.is_empty():
		return
	# Consume one use; remove item if uses reaches 0
	var uses_left: int = mat_item.get("uses", 1) - 1
	if uses_left <= 0:
		inv.remove_at(mat_inv_idx)
	else:
		inv[mat_inv_idx]["uses"] = uses_left
		inv[mat_inv_idx]["description"] = mat_item.get("description", "").replace(
			"Uses: %d" % (uses_left + 1), "Uses: %d" % uses_left)
	inv.append(crafted)
	GameManager.player_data["inventory"] = inv
	_crafting_selected_recipe = ""
	_refresh_crafting()
	_refresh_inventory()

func _refresh_alchemy_detail() -> void:
	var recipe: Dictionary = DataManager.get_alchemy_recipe(_crafting_selected_recipe)

	var name_lbl := Label.new()
	name_lbl.text = recipe.get("name", "?")
	name_lbl.add_theme_font_size_override("font_size", 14)
	_crafting_detail_area.add_child(name_lbl)

	var lore_lbl := Label.new()
	lore_lbl.text = recipe.get("lore", "")
	lore_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lore_lbl.add_theme_font_size_override("font_size", 11)
	lore_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	_crafting_detail_area.add_child(lore_lbl)

	_crafting_detail_area.add_child(HSeparator.new())

	# Show required items with have/missing status
	var inv: Array = GameManager.player_data.get("inventory", [])
	var inv_ids: Array = inv.map(func(i2): return i2.get("id", ""))
	var all_present: bool = true
	for item_id in recipe.get("required_items", []):
		var item_data: Dictionary = DataManager.get_item(item_id)
		var have: bool = item_id in inv_ids
		if not have:
			all_present = false
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var icon := ItemIcon.new()
		icon.custom_minimum_size = Vector2(28, 28)
		icon.item_id = item_id
		row.add_child(icon)
		var status_lbl := Label.new()
		status_lbl.text = "✓" if have else "✗"
		status_lbl.add_theme_color_override("font_color",
			Color(0.4, 0.9, 0.4) if have else Color(0.85, 0.35, 0.35))
		row.add_child(status_lbl)
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		var captured_item_data: Dictionary = item_data
		row.mouse_entered.connect(func(): _show_item_hover_tooltip(captured_item_data, get_viewport().get_mouse_position()))
		row.mouse_exited.connect(_hide_item_hover_tooltip)
		_crafting_detail_area.add_child(row)

	# Skill requirement
	var skill_result: Dictionary = DataManager.check_alchemy_skill(
		_crafting_selected_recipe, GameManager.player_data.get("skills", {}))
	var req: int = skill_result["required_level"]
	if req > 0:
		var skill_lbl := Label.new()
		skill_lbl.text = "Requires: Alchemy %d  or  Occultism %d" % [skill_result.get("req_alchemy", req), skill_result.get("req_occultism", req)]
		skill_lbl.add_theme_font_size_override("font_size", 11)
		skill_lbl.add_theme_color_override("font_color",
			Color(0.35, 0.85, 0.35) if skill_result["can_craft"] else Color(0.9, 0.35, 0.35))
		_crafting_detail_area.add_child(skill_lbl)

	var craft_btn := Button.new()
	craft_btn.text = "Craft"
	craft_btn.custom_minimum_size = Vector2(120, 36)
	craft_btn.disabled = not (all_present and skill_result["can_craft"])
	craft_btn.pressed.connect(_on_alchemy_craft_pressed)
	_crafting_detail_area.add_child(craft_btn)

func _on_alchemy_craft_pressed() -> void:
	var recipe: Dictionary = DataManager.get_alchemy_recipe(_crafting_selected_recipe)
	if recipe.is_empty():
		return
	var required_ids: Array = recipe.get("required_items", [])
	var inv: Array = GameManager.player_data.get("inventory", [])
	# Consume one of each required item (last occurrence, descending to preserve indices)
	var to_remove: Array = []
	for item_id in required_ids:
		for i in range(inv.size() - 1, -1, -1):
			if inv[i].get("id", "") == item_id and i not in to_remove:
				to_remove.append(i)
				break
	if to_remove.size() != required_ids.size():
		return  # missing items
	to_remove.sort()
	to_remove.reverse()
	for idx in to_remove:
		inv.remove_at(idx)
	var crafted: Dictionary = DataManager.craft_alchemy(_crafting_selected_recipe)
	if not crafted.is_empty():
		inv.append(crafted)
	GameManager.player_data["inventory"] = inv
	_crafting_slotted = {}
	_crafting_selected_recipe = ""
	_refresh_crafting()
	_refresh_inventory()

func _refresh_scripture_detail() -> void:
	var recipe: Dictionary = DataManager.get_scripture_recipe(_crafting_selected_recipe)

	var name_lbl := Label.new()
	name_lbl.text = recipe.get("name", "?")
	name_lbl.add_theme_font_size_override("font_size", 14)
	_crafting_detail_area.add_child(name_lbl)

	var lore_lbl := Label.new()
	lore_lbl.text = recipe.get("lore", "")
	lore_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lore_lbl.add_theme_font_size_override("font_size", 11)
	lore_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	_crafting_detail_area.add_child(lore_lbl)

	_crafting_detail_area.add_child(HSeparator.new())

	var inv: Array = GameManager.player_data.get("inventory", [])
	var inv_ids: Array = inv.map(func(i2): return i2.get("id", ""))
	var all_present: bool = true
	for item_id in recipe.get("required_items", []):
		var item_data: Dictionary = DataManager.get_item(item_id)
		var have: bool = item_id in inv_ids
		if not have:
			all_present = false
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var icon := ItemIcon.new()
		icon.custom_minimum_size = Vector2(28, 28)
		icon.item_id = item_id
		row.add_child(icon)
		var status_lbl := Label.new()
		status_lbl.text = "✓" if have else "✗"
		status_lbl.add_theme_color_override("font_color",
			Color(0.4, 0.9, 0.4) if have else Color(0.85, 0.35, 0.35))
		row.add_child(status_lbl)
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		var captured_item_data: Dictionary = item_data
		row.mouse_entered.connect(func(): _show_item_hover_tooltip(captured_item_data, get_viewport().get_mouse_position()))
		row.mouse_exited.connect(_hide_item_hover_tooltip)
		_crafting_detail_area.add_child(row)

	var craft_btn := Button.new()
	craft_btn.text = "Craft"
	craft_btn.custom_minimum_size = Vector2(120, 36)
	craft_btn.disabled = not all_present
	craft_btn.pressed.connect(_on_scripture_craft_pressed)
	_crafting_detail_area.add_child(craft_btn)

func _on_scripture_craft_pressed() -> void:
	var recipe: Dictionary = DataManager.get_scripture_recipe(_crafting_selected_recipe)
	if recipe.is_empty():
		return
	var required_ids: Array = recipe.get("required_items", [])
	var inv: Array = GameManager.player_data.get("inventory", [])
	var to_remove: Array = []
	for item_id in required_ids:
		for i in range(inv.size() - 1, -1, -1):
			if inv[i].get("id", "") == item_id and i not in to_remove:
				to_remove.append(i)
				break
	if to_remove.size() != required_ids.size():
		return
	to_remove.sort()
	to_remove.reverse()
	for idx in to_remove:
		inv.remove_at(idx)
	var crafted: Dictionary = DataManager.craft_scripture(_crafting_selected_recipe)
	if not crafted.is_empty():
		inv.append(crafted)
	GameManager.player_data["inventory"] = inv
	_crafting_slotted = {}
	_crafting_selected_recipe = ""
	_refresh_crafting()
	_refresh_inventory()

func _on_crafting_mat_pressed(i: int) -> void:
	if _crafting_selected_recipe == "" or i >= _crafting_materials.size():
		return
	var mat_entry: Dictionary = _crafting_materials[i]
	var mat_type: String      = mat_entry["item"].get("material_type", "")
	var required: Array       = []
	if _crafting_active_tab == "cooking":
		required = DataManager.get_cooking_recipe(_crafting_selected_recipe).get("required_materials", [])
	else:
		required = DataManager.get_recipe(_crafting_selected_recipe).get("required_materials", [])
	var slot: String = DataManager.resolve_material_slot(mat_type, required)
	if slot == "":
		return  # doesn't match any required slot — ignore silently
	_crafting_slotted[slot] = mat_entry
	_refresh_crafting()

func _on_craft_pressed() -> void:
	if _crafting_selected_recipe == "":
		return
	var recipe: Dictionary  = DataManager.get_recipe(_crafting_selected_recipe)
	var required: Array     = recipe.get("required_materials", [])
	for mat_type in required:
		if not _crafting_slotted.has(mat_type):
			return
	# Build materials dict for craft_trophy
	var mats_dict: Dictionary = {}
	for mat_type in required:
		mats_dict[mat_type] = _crafting_slotted[mat_type]["item"]
	var crafted: Dictionary = DataManager.craft_trophy(_crafting_selected_recipe, mats_dict)
	if crafted.is_empty():
		return
	# Remove all consumed items (sort indices descending to avoid index shift)
	var inv: Array = GameManager.player_data.get("inventory", [])
	var to_remove: Array = []
	for mat_type in required:
		to_remove.append(_crafting_slotted[mat_type]["inv_idx"])
	to_remove.sort()
	to_remove.reverse()
	for idx in to_remove:
		if idx < inv.size():
			inv.remove_at(idx)
	inv.append(crafted)
	GameManager.player_data["inventory"] = inv
	_crafting_slotted = {}
	_crafting_selected_recipe = ""
	_refresh_crafting()

func _close_crafting() -> void:
	_close_all()

func _emit_dialogue_closed(entity) -> void:
	EventBus.dialogue_closed.emit(entity)

func _emit_crafting_closed(entity) -> void:
	EventBus.crafting_ui_closed.emit(entity)

# ══════════════════════════════════════════════════════════════════════════════
# STATUS EFFECT PANEL (top-left)
# ══════════════════════════════════════════════════════════════════════════════
func _build_hp_bar() -> Control:
	var root := Control.new()
	root.anchor_left   = 0.0
	root.anchor_top    = 1.0
	root.anchor_right  = 0.0
	root.anchor_bottom = 1.0
	root.offset_left   = 8
	root.offset_right  = 220
	root.offset_top    = -108
	root.offset_bottom = -8
	root.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	root.z_index = 1

	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.06, 0.04, 0.04, 0.90)
	bg_style.set_corner_radius_all(5)
	bg_style.content_margin_left   = 10
	bg_style.content_margin_right  = 10
	bg_style.content_margin_top    = 6
	bg_style.content_margin_bottom = 6
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", bg_style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(vbox)

	var header_row := HBoxContainer.new()
	header_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(header_row)

	var hp_icon := Label.new()
	hp_icon.text = "HP"
	hp_icon.add_theme_font_size_override("font_size", 11)
	hp_icon.add_theme_color_override("font_color", Color(0.65, 0.65, 0.70))
	hp_icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_row.add_child(hp_icon)

	_hp_bar_lbl = Label.new()
	_hp_bar_lbl.text = "— / —"
	_hp_bar_lbl.add_theme_font_size_override("font_size", 11)
	_hp_bar_lbl.add_theme_color_override("font_color", Color(0.90, 0.75, 0.75))
	_hp_bar_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hp_bar_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_row.add_child(_hp_bar_lbl)

	_hp_bar = ProgressBar.new()
	_hp_bar.custom_minimum_size = Vector2(0, 10)
	_hp_bar.show_percentage = false
	_hp_bar.min_value = 0
	_hp_bar.max_value = 1
	_hp_bar.value     = 1
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color(0.75, 0.20, 0.20)
	fill_style.set_corner_radius_all(3)
	_hp_bar.add_theme_stylebox_override("fill", fill_style)
	var bg2 := StyleBoxFlat.new()
	bg2.bg_color = Color(0.15, 0.08, 0.08)
	bg2.set_corner_radius_all(3)
	_hp_bar.add_theme_stylebox_override("background", bg2)
	_hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_hp_bar)

	# Spirit bar row — hidden until pyromancy is learned
	_sp_bar_row = HBoxContainer.new()
	_sp_bar_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_sp_bar_row)
	var sp_icon := Label.new()
	sp_icon.text = "SP"
	sp_icon.add_theme_font_size_override("font_size", 11)
	sp_icon.add_theme_color_override("font_color", Color(0.65, 0.65, 0.70))
	sp_icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sp_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sp_bar_row.add_child(sp_icon)
	_sp_bar_lbl = Label.new()
	_sp_bar_lbl.text = "— / —"
	_sp_bar_lbl.add_theme_font_size_override("font_size", 11)
	_sp_bar_lbl.add_theme_color_override("font_color", Color(0.70, 0.82, 1.0))
	_sp_bar_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_sp_bar_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sp_bar_row.add_child(_sp_bar_lbl)

	_sp_bar = ProgressBar.new()
	_sp_bar.custom_minimum_size = Vector2(0, 10)
	_sp_bar.show_percentage = false
	_sp_bar.min_value = 0
	_sp_bar.max_value = 1
	_sp_bar.value     = 1
	var sp_fill_style := StyleBoxFlat.new()
	sp_fill_style.bg_color = Color(0.28, 0.48, 0.85)
	sp_fill_style.set_corner_radius_all(3)
	_sp_bar.add_theme_stylebox_override("fill", sp_fill_style)
	var sp_bg_style := StyleBoxFlat.new()
	sp_bg_style.bg_color = Color(0.08, 0.08, 0.18)
	sp_bg_style.set_corner_radius_all(3)
	_sp_bar.add_theme_stylebox_override("background", sp_bg_style)
	_sp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_sp_bar)

	# XP row
	var xp_row := HBoxContainer.new()
	xp_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(xp_row)
	var xp_icon := Label.new()
	xp_icon.text = "XP"
	xp_icon.add_theme_font_size_override("font_size", 11)
	xp_icon.add_theme_color_override("font_color", Color(0.55, 0.70, 0.90))
	xp_icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	xp_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	xp_row.add_child(xp_icon)
	_hud_xp_lbl = Label.new()
	_hud_xp_lbl.add_theme_font_size_override("font_size", 11)
	_hud_xp_lbl.add_theme_color_override("font_color", Color(0.65, 0.80, 0.95))
	_hud_xp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hud_xp_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	xp_row.add_child(_hud_xp_lbl)
	_hud_xp_bar = ProgressBar.new()
	_hud_xp_bar.custom_minimum_size = Vector2(0, 6)
	_hud_xp_bar.show_percentage = false
	_hud_xp_bar.min_value = 0
	_hud_xp_bar.max_value = 1
	_hud_xp_bar.value     = 0
	var xp_fill := StyleBoxFlat.new()
	xp_fill.bg_color = Color(0.25, 0.50, 0.80)
	xp_fill.set_corner_radius_all(2)
	_hud_xp_bar.add_theme_stylebox_override("fill", xp_fill)
	var xp_bg := StyleBoxFlat.new()
	xp_bg.bg_color = Color(0.08, 0.12, 0.20)
	xp_bg.set_corner_radius_all(2)
	_hud_xp_bar.add_theme_stylebox_override("background", xp_bg)
	_hud_xp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_hud_xp_bar)

	return root

func _build_status_panel() -> Control:
	var root := Control.new()
	root.anchor_left   = 0.0
	root.anchor_top    = 0.0
	root.anchor_right  = 0.0
	root.anchor_bottom = 0.0
	root.offset_left   = 8
	root.offset_top    = 58   # below turn-order bar height
	root.offset_right  = 260
	root.offset_bottom = 600
	root.mouse_filter  = Control.MOUSE_FILTER_IGNORE

	_status_rows = VBoxContainer.new()
	_status_rows.add_theme_constant_override("separation", 4)
	_status_rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_status_rows)
	return root

func _status_color(status_name: String) -> Color:
	match status_name:
		"burning": return Color(1.0, 0.45, 0.10)
		"heated":  return Color(1.0, 0.65, 0.20)
		"bleed":   return Color(0.92, 0.28, 0.28)
		"poison":  return Color(0.30, 0.88, 0.35)
		_:         return Color(0.85, 0.75, 0.85)

func _refresh_status_panel() -> void:
	if _status_rows == null:
		return
	for child in _status_rows.get_children():
		child.queue_free()

	var player = GameManager.player
	var statuses: Dictionary = {}
	if player != null and player.get("status_effects") != null:
		statuses = player.status_effects
	var vial_rests_check: int = GameManager.player_data.get("vial_protection_rests", 0)
	var ex_check: int = GameManager.player_data.get("exhaustion_stacks", 0)
	var meal_buff_check: Dictionary = GameManager.player_data.get("active_meal_buff", {})
	if statuses.is_empty() and vial_rests_check == 0 and ex_check == 0 and meal_buff_check.is_empty():
		_status_panel.visible = false
		return

	_status_panel.visible = true
	for status_name in statuses:
		var stacks: Array = statuses[status_name]
		if stacks.is_empty():
			continue

		var bg_style := StyleBoxFlat.new()
		bg_style.bg_color = Color(0.08, 0.03, 0.03, 0.90)
		bg_style.set_corner_radius_all(4)
		bg_style.content_margin_left   = 8
		bg_style.content_margin_right  = 6
		bg_style.content_margin_top    = 4
		bg_style.content_margin_bottom = 4
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", bg_style)
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_status_rows.add_child(panel)

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 6)
		hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(hbox)

		# Name + stack count
		var name_lbl := Label.new()
		name_lbl.text = "%s ×%d" % [status_name.capitalize(), stacks.size()]
		name_lbl.add_theme_font_size_override("font_size", 13)
		name_lbl.add_theme_color_override("font_color", _status_color(status_name))
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(name_lbl)

		# Per-stack ticks remaining  e.g. "(3t, 2t)"
		var tick_parts: Array = []
		for t in stacks:
			tick_parts.append("%dt" % t)
		var ticks_lbl := Label.new()
		ticks_lbl.text = "(%s)" % ", ".join(tick_parts)
		ticks_lbl.add_theme_font_size_override("font_size", 11)
		ticks_lbl.add_theme_color_override("font_color", Color(0.60, 0.60, 0.65))
		ticks_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ticks_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(ticks_lbl)

		# ? info button
		var info_btn := Button.new()
		info_btn.text = "?"
		info_btn.flat = true
		info_btn.custom_minimum_size = Vector2(22, 22)
		info_btn.add_theme_font_size_override("font_size", 11)
		var captured: String = status_name
		info_btn.pressed.connect(func(): _show_status_info_popup(captured, info_btn.get_global_rect().position))
		hbox.add_child(info_btn)

	# Vial spirit protection row
	var vial_rests: int = GameManager.player_data.get("vial_protection_rests", 0)
	if vial_rests > 0:
		_status_panel.visible = true
		var vial_bg := StyleBoxFlat.new()
		vial_bg.bg_color = Color(0.04, 0.12, 0.06, 0.90)
		vial_bg.set_corner_radius_all(4)
		vial_bg.content_margin_left   = 8
		vial_bg.content_margin_right  = 6
		vial_bg.content_margin_top    = 4
		vial_bg.content_margin_bottom = 4
		var vial_panel := PanelContainer.new()
		vial_panel.add_theme_stylebox_override("panel", vial_bg)
		vial_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_status_rows.add_child(vial_panel)
		var vial_lbl := Label.new()
		vial_lbl.text = "Spirit Ward Lv.1 — %d rest%s remaining" % [vial_rests, "s" if vial_rests != 1 else ""]
		vial_lbl.add_theme_font_size_override("font_size", 13)
		vial_lbl.add_theme_color_override("font_color", Color(0.30, 0.85, 0.45))
		vial_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vial_panel.add_child(vial_lbl)

	# Exhaustion stacks
	var ex_stacks: int = GameManager.player_data.get("exhaustion_stacks", 0)
	if ex_stacks > 0:
		_status_panel.visible = true
		var ex_bg := StyleBoxFlat.new()
		ex_bg.bg_color = Color(0.10, 0.06, 0.02, 0.90)
		ex_bg.set_corner_radius_all(4)
		ex_bg.content_margin_left   = 8
		ex_bg.content_margin_right  = 6
		ex_bg.content_margin_top    = 4
		ex_bg.content_margin_bottom = 4
		var ex_panel := PanelContainer.new()
		ex_panel.add_theme_stylebox_override("panel", ex_bg)
		ex_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_status_rows.add_child(ex_panel)
		var ex_lbl := Label.new()
		ex_lbl.text = "Exhaustion ×%d  (-%d AP, -%d MP)" % [ex_stacks, ex_stacks, ex_stacks * 2]
		ex_lbl.add_theme_font_size_override("font_size", 13)
		ex_lbl.add_theme_color_override("font_color", Color(0.85, 0.55, 0.20))
		ex_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ex_panel.add_child(ex_lbl)

	# Active meal buff
	var meal_buff: Dictionary = GameManager.player_data.get("active_meal_buff", {})
	if not meal_buff.is_empty():
		_status_panel.visible = true
		var mb_bg := StyleBoxFlat.new()
		mb_bg.bg_color = Color(0.04, 0.10, 0.04, 0.90)
		mb_bg.set_corner_radius_all(4)
		mb_bg.content_margin_left   = 8
		mb_bg.content_margin_right  = 6
		mb_bg.content_margin_top    = 4
		mb_bg.content_margin_bottom = 4
		var mb_panel := PanelContainer.new()
		mb_panel.add_theme_stylebox_override("panel", mb_bg)
		mb_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_status_rows.add_child(mb_panel)
		var buff_lines: Array = DataManager.format_meal_buff_lines(meal_buff)
		var buff_desc: String
		if buff_lines.is_empty():
			buff_desc = meal_buff.get("name", "Meal Buff")
		else:
			buff_desc = "%s — %s" % [meal_buff.get("name", "Meal"), ", ".join(PackedStringArray(buff_lines))]
		var mb_lbl := Label.new()
		mb_lbl.text = buff_desc
		mb_lbl.add_theme_font_size_override("font_size", 13)
		mb_lbl.add_theme_color_override("font_color", Color(0.55, 0.90, 0.40))
		mb_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mb_panel.add_child(mb_lbl)

	# Out-of-combat countdown label — only shown when there are ticking effects (bleed etc.)
	_status_timer_lbl = null
	var has_ticking_effects: bool = statuses.values().any(func(s): return not s.is_empty())
	if not GameManager.combat_mode and has_ticking_effects:
		var timer_bg_style := StyleBoxFlat.new()
		timer_bg_style.bg_color = Color(0.08, 0.03, 0.03, 0.90)
		timer_bg_style.set_corner_radius_all(4)
		timer_bg_style.content_margin_left   = 8
		timer_bg_style.content_margin_right  = 6
		timer_bg_style.content_margin_top    = 4
		timer_bg_style.content_margin_bottom = 4
		var timer_panel := PanelContainer.new()
		timer_panel.add_theme_stylebox_override("panel", timer_bg_style)
		timer_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_status_rows.add_child(timer_panel)
		_status_timer_lbl = Label.new()
		_status_timer_lbl.add_theme_font_size_override("font_size", 11)
		_status_timer_lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.80))
		_status_timer_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		timer_panel.add_child(_status_timer_lbl)

# ══════════════════════════════════════════════════════════════════════════════
# SPELL PICK PANEL
# ══════════════════════════════════════════════════════════════════════════════

func _build_spell_pick_panel() -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP

	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.0, 0.72)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)

	var card := PanelContainer.new()
	card.anchor_left   = 0.5;  card.anchor_right  = 0.5
	card.anchor_top    = 0.5;  card.anchor_bottom = 0.5
	card.offset_left   = -260; card.offset_right  = 260
	card.offset_top    = -230; card.offset_bottom = 230
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.06, 0.04, 0.09, 0.97)
	card_style.set_corner_radius_all(6)
	card_style.border_width_left   = 1
	card_style.border_width_right  = 1
	card_style.border_width_top    = 1
	card_style.border_width_bottom = 1
	card_style.border_color = Color(0.38, 0.20, 0.52)
	card.add_theme_stylebox_override("panel", card_style)
	root.add_child(card)

	var margin := MarginContainer.new()
	for s in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(s, 24)
	card.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "CHOOSE A SPELL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.90, 0.78, 1.0))
	vbox.add_child(title)

	var sub := Label.new()
	sub.text = "The unchosen spell will be available at your next pick."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 11)
	sub.add_theme_color_override("font_color", Color(0.58, 0.58, 0.64))
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(sub)

	var spells_vbox := VBoxContainer.new()
	spells_vbox.add_theme_constant_override("separation", 12)
	spells_vbox.name = "SpellsVbox"
	vbox.add_child(spells_vbox)

	return root

func _on_open_spell_pick_ui(spell_ids: Array) -> void:
	if _spell_pick_panel == null:
		return
	var spells_vbox: Node = _spell_pick_panel.find_child("SpellsVbox", true, false)
	if spells_vbox == null:
		return
	for child in spells_vbox.get_children():
		child.queue_free()

	for raw_id in spell_ids:
		var spell_id: String = str(raw_id)
		var spell: Dictionary = DataManager.get_item(spell_id)
		if spell.is_empty():
			continue

		var card := PanelContainer.new()
		var c_style := StyleBoxFlat.new()
		c_style.bg_color = Color(0.09, 0.06, 0.13)
		c_style.set_corner_radius_all(5)
		c_style.border_width_left   = 1
		c_style.border_width_right  = 1
		c_style.border_width_top    = 1
		c_style.border_width_bottom = 1
		c_style.border_color = Color(0.38, 0.22, 0.55)
		card.add_theme_stylebox_override("panel", c_style)
		spells_vbox.add_child(card)

		var inner := MarginContainer.new()
		for s in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
			inner.add_theme_constant_override(s, 10)
		card.add_child(inner)

		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 4)
		inner.add_child(col)

		var name_lbl := Label.new()
		name_lbl.text = spell.get("name", "?")
		name_lbl.add_theme_font_size_override("font_size", 14)
		name_lbl.add_theme_color_override("font_color", Color(1.0, 0.80, 0.50))
		col.add_child(name_lbl)

		var stats_lbl := Label.new()
		stats_lbl.text = "%s · Fire · %d AP · %d SP · Range %d · %s skill" % [
			"Melee" if spell.get("range", 1) == 1 else "Ranged",
			spell.get("ap_cost", 2),
			spell.get("spirit_cost", 0),
			spell.get("range", 1),
			spell.get("skill", "?").capitalize(),
		]
		stats_lbl.add_theme_font_size_override("font_size", 11)
		stats_lbl.add_theme_color_override("font_color", Color(0.62, 0.62, 0.68))
		col.add_child(stats_lbl)

		var pick_btn := Button.new()
		pick_btn.text = "Choose  %s" % spell.get("name", "?")
		pick_btn.custom_minimum_size = Vector2(0, 36)
		var cap_id: String = spell_id
		var cap_all: Array = spell_ids.duplicate()
		pick_btn.pressed.connect(func():
			var pd: Dictionary  = GameManager.player_data
			var spells: Array   = pd.get("spells", [])
			if cap_id not in spells:
				spells.append(cap_id)
			pd["spells"] = spells
			var pending: Array  = pd.get("pending_pyromancy_picks", [])
			for other_id in cap_all:
				if str(other_id) != cap_id and str(other_id) not in pending:
					pending.append(str(other_id))
			pd["pending_pyromancy_picks"] = pending
			_spell_pick_panel.visible = false
			mouse_filter = Control.MOUSE_FILTER_IGNORE
			EventBus.inventory_changed.emit()
		)
		col.add_child(pick_btn)

	_close_all()
	_spell_pick_panel.visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP

# ══════════════════════════════════════════════════════════════════════════════
# SMITHING PICK PANEL
# ══════════════════════════════════════════════════════════════════════════════

func _build_smithing_pick_panel() -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP

	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.0, 0.72)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)

	var card := PanelContainer.new()
	card.anchor_left   = 0.5;  card.anchor_right  = 0.5
	card.anchor_top    = 0.5;  card.anchor_bottom = 0.5
	card.offset_left   = -260; card.offset_right  = 260
	card.offset_top    = -230; card.offset_bottom = 230
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.05, 0.04, 0.03, 0.97)
	card_style.set_corner_radius_all(6)
	card_style.border_width_left   = 1
	card_style.border_width_right  = 1
	card_style.border_width_top    = 1
	card_style.border_width_bottom = 1
	card_style.border_color = Color(0.55, 0.40, 0.15)
	card.add_theme_stylebox_override("panel", card_style)
	root.add_child(card)

	var margin := MarginContainer.new()
	for s in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(s, 24)
	card.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "CHOOSE A PROPERTY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.95, 0.80, 0.45))
	vbox.add_child(title)

	var sub := Label.new()
	sub.text = "The unchosen property will be available at your next lesson."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 11)
	sub.add_theme_color_override("font_color", Color(0.58, 0.58, 0.64))
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(sub)

	var options_vbox := VBoxContainer.new()
	options_vbox.add_theme_constant_override("separation", 12)
	options_vbox.name = "OptionsVbox"
	vbox.add_child(options_vbox)

	return root

func _on_open_smithing_pick_ui(options: Array) -> void:
	if _smithing_pick_panel == null:
		return
	var options_vbox: Node = _smithing_pick_panel.find_child("OptionsVbox", true, false)
	if options_vbox == null:
		return
	for child in options_vbox.get_children():
		child.queue_free()

	for opt in options:
		var card := PanelContainer.new()
		var c_style := StyleBoxFlat.new()
		c_style.bg_color = Color(0.08, 0.06, 0.04)
		c_style.set_corner_radius_all(5)
		c_style.border_width_left   = 1
		c_style.border_width_right  = 1
		c_style.border_width_top    = 1
		c_style.border_width_bottom = 1
		c_style.border_color = Color(0.50, 0.36, 0.14)
		card.add_theme_stylebox_override("panel", c_style)
		options_vbox.add_child(card)

		var inner := MarginContainer.new()
		for s in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
			inner.add_theme_constant_override(s, 10)
		card.add_child(inner)

		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 4)
		inner.add_child(col)

		var name_lbl := Label.new()
		name_lbl.text = opt.get("name", "?")
		name_lbl.add_theme_font_size_override("font_size", 14)
		name_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.45))
		col.add_child(name_lbl)

		var desc_lbl := Label.new()
		desc_lbl.text = opt.get("description", "")
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.add_theme_color_override("font_color", Color(0.62, 0.62, 0.68))
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col.add_child(desc_lbl)

		var pick_btn := Button.new()
		pick_btn.text = "Learn  %s" % opt.get("name", "?")
		pick_btn.custom_minimum_size = Vector2(0, 36)
		var cap_id: String    = opt.get("id", "")
		pick_btn.pressed.connect(func():
			_smithing_pick_panel.visible = false
			mouse_filter = Control.MOUSE_FILTER_IGNORE
			EventBus.smithing_pick_made.emit(cap_id)
		)
		col.add_child(pick_btn)

	_close_all()
	_smithing_pick_panel.visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP

func _spawn_floater(entity: Node, text: String, color: Color) -> void:
	if not is_instance_valid(entity):
		return
	var vp := entity.get_viewport()
	if vp == null:
		return
	# Convert world position to screen space via the viewport's canvas transform
	var screen_pos: Vector2 = vp.canvas_transform * entity.global_position
	screen_pos += Vector2(randf_range(-12.0, 12.0), -28.0)  # slight random spread, above entity

	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 1)
	lbl.position = screen_pos
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.z_index = 10
	add_child(lbl)

	var tween := create_tween().set_parallel(true)
	tween.tween_property(lbl, "position:y", screen_pos.y - 48.0, 1.1) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(lbl, "modulate:a", 0.0, 0.75).set_delay(0.35)
	get_tree().create_timer(1.15).timeout.connect(lbl.queue_free)

func _on_xp_gained(amount: int) -> void:
	_refresh_stats()
	var player: Node = GameManager.player
	if player == null or not is_instance_valid(player):
		return
	var screen_pos: Vector2 = player.get_viewport().canvas_transform * player.global_position
	screen_pos += Vector2(randf_range(-8.0, 8.0), -52.0)  # higher than damage floaters

	var lbl := Label.new()
	lbl.text = "+%d xp" % amount
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 1)
	lbl.position = screen_pos
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.z_index = 10
	add_child(lbl)

	var tween := create_tween().set_parallel(true)
	tween.tween_property(lbl, "position:y", screen_pos.y - 36.0, 1.4) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(lbl, "modulate:a", 0.0, 0.9).set_delay(0.5)
	get_tree().create_timer(1.45).timeout.connect(lbl.queue_free)

# ══════════════════════════════════════════════════════════════════════════════
# SHOP PANEL
# ══════════════════════════════════════════════════════════════════════════════
func _build_shop_panel() -> Control:
	var shell := _make_panel_shell("Shop")
	var root: Control      = shell["root"]
	var vbox: VBoxContainer = shell["vbox"]

	# Store a ref to the title label so we can update it per merchant.
	# _make_panel_shell puts it in the first HBoxContainer child of vbox.
	var hdr: HBoxContainer = vbox.get_child(0) as HBoxContainer
	_shop_title_lbl = hdr.get_child(0) as Label

	# Coin counter row
	_shop_coins_lbl = Label.new()
	_shop_coins_lbl.add_theme_font_size_override("font_size", 14)
	vbox.add_child(_shop_coins_lbl)

	_shop_tab_row = HBoxContainer.new()
	_shop_tab_row.visible = false
	_shop_tab_row.add_theme_constant_override("separation", 4)
	vbox.add_child(_shop_tab_row)

	_shop_buy_tab_btn = Button.new()
	_shop_buy_tab_btn.text = "Buy"
	_shop_buy_tab_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_shop_buy_tab_btn.pressed.connect(func(): _on_shop_tab_changed("buy"))
	_shop_tab_row.add_child(_shop_buy_tab_btn)

	_shop_sell_tab_btn = Button.new()
	_shop_sell_tab_btn.text = "Sell"
	_shop_sell_tab_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_shop_sell_tab_btn.pressed.connect(func(): _on_shop_tab_changed("sell"))
	_shop_tab_row.add_child(_shop_sell_tab_btn)

	_shop_quota_lbl = Label.new()
	_shop_quota_lbl.add_theme_font_size_override("font_size", 13)
	_shop_quota_lbl.modulate = Color(0.75, 0.75, 0.75)
	_shop_quota_lbl.visible = false
	vbox.add_child(_shop_quota_lbl)

	vbox.add_child(HSeparator.new())

	# Split: item list (left) and item detail (right)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 16)
	vbox.add_child(body)

	# ── Left: scrollable item list ─────────────────────────────────────────────
	var list_container := VBoxContainer.new()
	list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_container.custom_minimum_size = Vector2(280, 0)
	body.add_child(list_container)

	var list_hdr := HBoxContainer.new()
	list_container.add_child(list_hdr)

	var _col_name := Label.new(); _col_name.text = "Item"
	_col_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_col_name.add_theme_font_size_override("font_size", 12)
	_col_name.modulate = Color(0.7, 0.7, 0.7)
	list_hdr.add_child(_col_name)
	for col_text in ["Type", "Wt", "Price"]:
		var col := Label.new(); col.text = col_text
		col.custom_minimum_size = Vector2(48, 0)
		col.add_theme_font_size_override("font_size", 12)
		col.modulate = Color(0.7, 0.7, 0.7)
		list_hdr.add_child(col)

	list_container.add_child(HSeparator.new())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	list_container.add_child(scroll)

	var item_vbox := VBoxContainer.new()
	item_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_vbox.add_theme_constant_override("separation", 2)
	scroll.add_child(item_vbox)

	# _shop_item_btns populated in _refresh_shop — store the vbox ref via metadata
	root.set_meta("item_vbox", item_vbox)

	# ── Right: item detail ─────────────────────────────────────────────────────
	var detail := VBoxContainer.new()
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_theme_constant_override("separation", 8)
	body.add_child(detail)

	_shop_detail_name = Label.new()
	_shop_detail_name.text = "Select an item"
	_shop_detail_name.add_theme_font_size_override("font_size", 16)
	_shop_detail_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_child(_shop_detail_name)

	detail.add_child(HSeparator.new())

	_shop_detail_desc = Label.new()
	_shop_detail_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_shop_detail_desc.add_theme_font_size_override("font_size", 13)
	_shop_detail_desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail.add_child(_shop_detail_desc)

	vbox.add_child(HSeparator.new())

	# ── Bottom: buy button ─────────────────────────────────────────────────────
	var footer := HBoxContainer.new()
	vbox.add_child(footer)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)

	_shop_buy_btn = Button.new()
	_shop_buy_btn.text = "Buy"
	_shop_buy_btn.custom_minimum_size = Vector2(140, 36)
	_shop_buy_btn.disabled = true
	_shop_buy_btn.pressed.connect(_on_shop_action)
	footer.add_child(_shop_buy_btn)

	return root

func _on_open_shop_ui(merchant: Node, shop_items: Array, sellable: Array, daily_remaining: int, on_sale: Callable) -> void:
	_close_all()
	_shop_merchant        = merchant
	_shop_items           = shop_items
	_sell_sellable        = sellable
	_sell_daily_remaining = daily_remaining
	_sell_on_sale         = on_sale
	_shop_mode            = "buy"
	_shop_selected_idx    = -1
	_sell_selected_idx    = -1
	_refresh_shop()
	_shop_panel.visible   = true
	mouse_filter = Control.MOUSE_FILTER_STOP

func _on_shop_tab_changed(mode: String) -> void:
	_shop_mode         = mode
	_shop_selected_idx = -1
	_sell_selected_idx = -1
	_refresh_shop()

func _refresh_shop() -> void:
	var has_sell: bool = not _sell_sellable.is_empty()
	if _shop_merchant != null and _shop_title_lbl != null:
		_shop_title_lbl.text = _shop_merchant.entity_name + "'s Wares"
	_refresh_shop_coin_lbl()

	if _shop_tab_row != null:
		_shop_tab_row.visible = has_sell
	if _shop_buy_tab_btn != null:
		_shop_buy_tab_btn.disabled = _shop_mode == "buy"
	if _shop_sell_tab_btn != null:
		_shop_sell_tab_btn.disabled = _shop_mode == "sell"
	if _shop_quota_lbl != null:
		if _shop_mode == "sell":
			_shop_quota_lbl.text    = "Will buy: %d more today" % _sell_daily_remaining
			_shop_quota_lbl.visible = true
		else:
			_shop_quota_lbl.visible = false

	var item_vbox: VBoxContainer = _shop_panel.get_meta("item_vbox") as VBoxContainer
	for child in item_vbox.get_children():
		child.queue_free()
	_shop_item_btns.clear()
	_sell_item_btns.clear()
	_shop_detail_name.text  = "Select an item"
	_shop_detail_desc.text  = ""
	_shop_buy_btn.disabled  = true
	_shop_buy_btn.text      = "Buy" if _shop_mode == "buy" else "Sell"

	if _shop_mode == "buy":
		for i in range(_shop_items.size()):
			var entry: Dictionary     = _shop_items[i]
			var item_data: Dictionary = DataManager.get_item(entry.get("id", ""))
			if item_data.is_empty():
				continue
			var idx: int = i
			var btn := Button.new()
			btn.flat = true
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			btn.add_theme_font_size_override("font_size", 13)
			btn.custom_minimum_size = Vector2(0, 26)
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var name_str: String  = item_data.get("name", "?").left(22).rpad(23)
			var type_str: String  = _item_type_short(item_data.get("type", "")).rpad(7)
			var wt_str: String    = ("%.1f" % item_data.get("weight", 0.0)).rpad(6)
			var price_str: String = "%d¢" % entry.get("price", 0)
			btn.text = name_str + type_str + wt_str + price_str
			btn.pressed.connect(func(): _on_shop_item_selected(idx))
			item_vbox.add_child(btn)
			_shop_item_btns.append(btn)
	else:
		for i in range(_sell_sellable.size()):
			var entry: Dictionary     = _sell_sellable[i]
			var item_data: Dictionary = entry.get("item", {})
			var idx: int = i
			var btn := Button.new()
			btn.flat = true
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			btn.add_theme_font_size_override("font_size", 13)
			btn.custom_minimum_size = Vector2(0, 26)
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.disabled = _sell_daily_remaining <= 0
			var name_str: String  = item_data.get("name", "?").left(22).rpad(23)
			var qlty_str: String  = item_data.get("quality_name", "?").left(6).rpad(7)
			var wt_str: String    = ("%.1f" % item_data.get("weight", 0.0)).rpad(6)
			var price_str: String = "%d¢" % entry.get("price", 0)
			btn.text = name_str + qlty_str + wt_str + price_str
			btn.pressed.connect(func(): _on_shop_item_selected(idx))
			item_vbox.add_child(btn)
			_sell_item_btns.append(btn)

func _refresh_shop_coin_lbl() -> void:
	var coins: int = 0
	for item in GameManager.player_data.get("inventory", []):
		if item.get("type", "") == "currency":
			coins += 1
	if _shop_coins_lbl != null:
		_shop_coins_lbl.text = "You have: %d coin%s" % [coins, "s" if coins != 1 else ""]

func _on_shop_item_selected(idx: int) -> void:
	var btns: Array
	var item_data: Dictionary
	var price: int
	if _shop_mode == "buy":
		_shop_selected_idx = idx
		_sell_selected_idx = -1
		btns = _shop_item_btns
		var entry: Dictionary = _shop_items[idx]
		item_data = DataManager.get_item(entry.get("id", ""))
		price = entry.get("price", 0)
		var coins: int = 0
		for it in GameManager.player_data.get("inventory", []):
			if it.get("type", "") == "currency":
				coins += 1
		_shop_buy_btn.text     = "Buy — %d coin%s" % [price, "s" if price != 1 else ""]
		_shop_buy_btn.disabled = coins < price
		var desc: String  = item_data.get("description", "")
		var stats: String = _item_stats_line(item_data)
		_shop_detail_desc.text = (stats + "\n\n" if stats != "" else "") + desc
	else:
		_sell_selected_idx = idx
		_shop_selected_idx = -1
		btns = _sell_item_btns
		var entry: Dictionary = _sell_sellable[idx]
		item_data = entry.get("item", {})
		price = entry.get("price", 0)
		_shop_buy_btn.text     = "Sell — %d coin%s" % [price, "s" if price != 1 else ""]
		_shop_buy_btn.disabled = _sell_daily_remaining <= 0
		_shop_detail_desc.text = item_data.get("description", "")

	_shop_detail_name.text = item_data.get("name", "?")
	for j in range(btns.size()):
		var b: Button = btns[j] as Button
		if b == null: continue
		b.modulate = Color(1.3, 1.3, 0.6) if j == idx else Color(1, 1, 1)

func _on_shop_action() -> void:
	if _shop_mode == "buy":
		if _shop_selected_idx < 0 or _shop_selected_idx >= _shop_items.size():
			return
		var entry: Dictionary = _shop_items[_shop_selected_idx]
		var price: int        = entry.get("price", 0)
		var inv: Array        = GameManager.player_data.get("inventory", [])
		var removed: int = 0
		var i: int = inv.size() - 1
		while i >= 0 and removed < price:
			if inv[i].get("type", "") == "currency":
				inv.remove_at(i)
				removed += 1
			i -= 1
		if removed < price:
			return
		var item_data: Dictionary = DataManager.get_item(entry.get("id", ""))
		if not item_data.is_empty():
			inv.append(item_data.duplicate(true))
		GameManager.player_data["inventory"] = inv
		_shop_selected_idx = -1
		_refresh_shop()
	else:
		if _sell_selected_idx < 0 or _sell_selected_idx >= _sell_sellable.size():
			return
		if _sell_daily_remaining <= 0:
			return
		var entry: Dictionary        = _sell_sellable[_sell_selected_idx]
		var item_to_sell: Dictionary = entry.get("item", {})
		var price: int               = entry.get("price", 0)
		var inv: Array               = GameManager.player_data.get("inventory", [])
		var sell_id: String  = item_to_sell.get("id", "")
		var sell_qty: int    = item_to_sell.get("quality", -1)
		var removed: bool = false
		for i in range(inv.size()):
			if inv[i].get("id", "") == sell_id and inv[i].get("quality", -1) == sell_qty:
				inv.remove_at(i)
				removed = true
				break
		if not removed:
			return
		for _c in range(price):
			inv.append(DataManager.get_item("coin"))
		GameManager.player_data["inventory"] = inv
		_sell_daily_remaining -= 1
		if _sell_on_sale.is_valid():
			_sell_on_sale.call(item_to_sell)
		_sell_sellable.remove_at(_sell_selected_idx)
		_refresh_shop()

func _item_type_short(t: String) -> String:
	match t:
		"weapon":   return "Wpn"
		"armor":    return "Arm"
		"clothing": return "Cloth"
		"tool":     return "Tool"
		"trinket":  return "Trnkt"
		"ammo":     return "Ammo"
		_:          return t.left(5)

const _STAT_ABBREV: Dictionary = {
	"strength":     "str",
	"dexterity":    "dex",
	"agility":      "agi",
	"constitution": "con",
	"intelligence": "int",
	"willpower":    "wil",
	"perception":   "per",
}

func _item_stats_line(item: Dictionary) -> String:
	var parts: Array = []
	if item.has("damage"):
		var governing: Array = item.get("governing", [])
		var abbrevs: Array = []
		for stat in governing:
			var abbr: String = _STAT_ABBREV.get(stat, stat.left(3))
			if item.get("half_dex_damage", false) and stat == "dexterity":
				abbr += "×½"
			abbrevs.append(abbr)
		var dmg_dice: String = item["damage"]
		if not abbrevs.is_empty():
			parts.append("%s (%s)" % [dmg_dice, " / ".join(abbrevs)])
		else:
			parts.append(dmg_dice)
	if item.has("range") and item["range"] > 1:
		parts.append("Rng %d" % item["range"])
	if item.get("defense_flat", 0) != 0 or item.get("defense_pct", 0.0) != 0.0:
		parts.append("Def +%d / +%.0f%%" % [item.get("defense_flat",0), item.get("defense_pct",0.0)*100])
	if item.get("block_flat", 0.0) > 0.0:
		var block_gov: Array = item.get("governing", [])
		var block_abbrevs: Array = []
		for stat in block_gov:
			block_abbrevs.append(_STAT_ABBREV.get(stat, str(stat).left(3)))
		if not block_abbrevs.is_empty():
			parts.append("Block %d (%s)" % [int(item["block_flat"]), " / ".join(block_abbrevs)])
		else:
			parts.append("Block %d" % int(item["block_flat"]))
	if item.get("spirit_ward", false):
		parts.append("Spirit Ward")
	if item.get("weight", 0.0) > 0:
		parts.append("%.1f kg" % item["weight"])
	return "  ·  ".join(parts)


func _show_save_toast() -> void:
	var vp_size: Vector2 = get_viewport_rect().size
	var lbl := Label.new()
	lbl.text = "Save Successful"
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.85, 1.0, 0.85))
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 1)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.z_index = 20
	add_child(lbl)
	lbl.reset_size()
	lbl.position = Vector2(16.0, vp_size.y - 48.0)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(lbl, "modulate:a", 1.0, 0.15)
	tween.tween_property(lbl, "modulate:a", 0.0, 0.5).set_delay(1.5)
	get_tree().create_timer(2.1).timeout.connect(lbl.queue_free)

func _show_status_info_popup(status_name: String, near_pos: Vector2) -> void:
	if _keyword_popup == null:
		return
	var def: String = KEYWORD_DEFS.get(status_name, "")
	if def == "":
		return
	var lbl := _keyword_popup.get_child(0).get_child(0) as Label
	if lbl == null:
		return
	lbl.text = def
	var vp_size := get_viewport().get_visible_rect().size
	var pos := near_pos + Vector2(24, 0)
	pos.x = clampf(pos.x, 4.0, vp_size.x - 220.0)
	pos.y = clampf(pos.y, 4.0, vp_size.y - 200.0)
	_keyword_popup.position = pos
	_keyword_popup.visible = true

# ══════════════════════════════════════════════════════════════════════════════
# REST PANEL
# ══════════════════════════════════════════════════════════════════════════════
func _build_rest_panel() -> Control:
	var shell = _make_panel_shell("MAKE CAMP")
	var vbox: VBoxContainer = shell["vbox"]

	# ── Food section (hidden in inn mode) ────────────────────────────────────
	_rest_food_section = VBoxContainer.new()
	_rest_food_section.add_theme_constant_override("separation", 4)
	vbox.add_child(_rest_food_section)

	var food_hdr := Label.new()
	food_hdr.text = "FOOD"
	food_hdr.add_theme_font_size_override("font_size", 14)
	food_hdr.add_theme_color_override("font_color", Color(0.65, 0.60, 0.45))
	_rest_food_section.add_child(food_hdr)

	# Eat / Cook toggle (camping & hunter-camp only — hidden for inn/elder)
	_rest_mode_row = HBoxContainer.new()
	_rest_mode_row.add_theme_constant_override("separation", 6)
	_rest_food_section.add_child(_rest_mode_row)

	_rest_eat_btn = Button.new()
	_rest_eat_btn.text = "Eat"
	_rest_eat_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rest_eat_btn.pressed.connect(func():
		_rest_mode = "eat"
		_refresh_rest())
	_rest_mode_row.add_child(_rest_eat_btn)

	_rest_cook_btn = Button.new()
	_rest_cook_btn.text = "Cook"
	_rest_cook_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rest_cook_btn.pressed.connect(func():
		_rest_mode = "cook"
		_rest_cook_recipe = ""
		_rest_cook_slots = {}
		_refresh_rest())
	_rest_mode_row.add_child(_rest_cook_btn)

	_rest_food_lbl = Label.new()
	_rest_food_lbl.text = "No food slotted"
	_rest_food_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
	_rest_food_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rest_food_section.add_child(_rest_food_lbl)

	# Cook mode: recipe list + ingredient slot rows
	_rest_cook_recipe_list = VBoxContainer.new()
	_rest_cook_recipe_list.add_theme_constant_override("separation", 4)
	_rest_food_section.add_child(_rest_cook_recipe_list)

	_rest_cook_slot_box = VBoxContainer.new()
	_rest_cook_slot_box.add_theme_constant_override("separation", 4)
	_rest_food_section.add_child(_rest_cook_slot_box)

	# Eat mode item list / Cook mode ingredient picker (shared)
	_rest_food_list = VBoxContainer.new()
	_rest_food_list.add_theme_constant_override("separation", 4)
	_rest_food_section.add_child(_rest_food_list)

	# Cook mode: live buff preview
	_rest_cook_preview_lbl = Label.new()
	_rest_cook_preview_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rest_cook_preview_lbl.add_theme_font_size_override("font_size", 11)
	_rest_cook_preview_lbl.add_theme_color_override("font_color", Color(0.55, 0.80, 0.95))
	_rest_food_section.add_child(_rest_cook_preview_lbl)

	_rest_food_section.add_child(HSeparator.new())

	# ── Inn cost (visible in inn mode only) ───────────────────────────────────
	_rest_cost_lbl = Label.new()
	_rest_cost_lbl.visible = false
	vbox.add_child(_rest_cost_lbl)

	vbox.add_child(HSeparator.new())

	# ── Status section ────────────────────────────────────────────────────────
	var status_grid := GridContainer.new()
	status_grid.columns = 2
	status_grid.add_theme_constant_override("h_separation", 16)
	status_grid.add_theme_constant_override("v_separation", 6)
	vbox.add_child(status_grid)

	var loc_hdr := Label.new()
	loc_hdr.text = "LOCATION"
	loc_hdr.add_theme_font_size_override("font_size", 13)
	loc_hdr.add_theme_color_override("font_color", Color(0.65, 0.60, 0.45))
	status_grid.add_child(loc_hdr)
	_rest_location_lbl = Label.new()
	_rest_location_lbl.text = "—"
	status_grid.add_child(_rest_location_lbl)

	var spirit_hdr := Label.new()
	spirit_hdr.text = "SPIRIT WARD"
	spirit_hdr.add_theme_font_size_override("font_size", 13)
	spirit_hdr.add_theme_color_override("font_color", Color(0.65, 0.60, 0.45))
	status_grid.add_child(spirit_hdr)
	_rest_spirit_lbl = Label.new()
	_rest_spirit_lbl.text = "—"
	status_grid.add_child(_rest_spirit_lbl)

	var ex_hdr := Label.new()
	ex_hdr.text = "EXHAUSTION"
	ex_hdr.add_theme_font_size_override("font_size", 13)
	ex_hdr.add_theme_color_override("font_color", Color(0.65, 0.60, 0.45))
	status_grid.add_child(ex_hdr)
	_rest_exhaustion_lbl = Label.new()
	_rest_exhaustion_lbl.text = "—"
	status_grid.add_child(_rest_exhaustion_lbl)

	vbox.add_child(HSeparator.new())

	# ── Effects preview ───────────────────────────────────────────────────────
	_rest_effects_lbl = Label.new()
	_rest_effects_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rest_effects_lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	vbox.add_child(_rest_effects_lbl)

	# ── Rest button ───────────────────────────────────────────────────────────
	_rest_rest_btn = Button.new()
	_rest_rest_btn.text = "Rest"
	_rest_rest_btn.custom_minimum_size = Vector2(160, 44)
	_rest_rest_btn.pressed.connect(_do_rest)
	vbox.add_child(_rest_rest_btn)

	return shell["root"]

func _on_open_rest_ui(hunter_camp: bool) -> void:
	_rest_hunter_camp = hunter_camp
	_rest_inn_mode = false
	_rest_elder_mode = false
	_rest_smith_mode = false
	_rest_food_item = {}
	_rest_food_inv_idx = -1
	_rest_mode = "eat"
	_rest_cook_recipe = ""
	_rest_cook_slots = {}
	_close_all()
	_open = "rest"
	_panels["rest"].visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_refresh_rest()

func _on_open_inn_rest_ui() -> void:
	_rest_hunter_camp = false
	_rest_inn_mode = true
	_rest_elder_mode = false
	_rest_smith_mode = false
	_rest_food_item = {}
	_rest_food_inv_idx = -1
	_rest_mode = "eat"
	_rest_cook_recipe = ""
	_rest_cook_slots = {}
	_close_all()
	_open = "rest"
	_panels["rest"].visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_refresh_rest()

func _on_open_elder_rest_ui() -> void:
	_rest_hunter_camp = false
	_rest_inn_mode = false
	_rest_elder_mode = true
	_rest_smith_mode = false
	_rest_food_item = {}
	_rest_food_inv_idx = -1
	_rest_mode = "eat"
	_rest_cook_recipe = ""
	_rest_cook_slots = {}
	_close_all()
	_open = "rest"
	_panels["rest"].visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_refresh_rest()

func _on_open_smith_rest_ui() -> void:
	_rest_hunter_camp = false
	_rest_inn_mode = false
	_rest_elder_mode = false
	_rest_smith_mode = true
	_rest_food_item = {}
	_rest_food_inv_idx = -1
	_rest_mode = "eat"
	_rest_cook_recipe = ""
	_rest_cook_slots = {}
	_close_all()
	_open = "rest"
	_panels["rest"].visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_refresh_rest()

func _refresh_rest() -> void:
	if _rest_food_lbl == null:
		return

	var inv: Array = GameManager.player_data.get("inventory", [])

	# ── Inn / elder / camping mode ────────────────────────────────────────────
	_rest_food_section.visible = not _rest_inn_mode
	_rest_cost_lbl.visible = _rest_inn_mode

	var has_food: bool
	var location_ok: bool

	if _rest_elder_mode:
		_rest_food_lbl.visible = true
		_rest_mode_row.visible = false
		_rest_cook_recipe_list.visible = false
		_rest_cook_slot_box.visible = false
		_rest_cook_preview_lbl.visible = false
		has_food = true
		location_ok = true
		_rest_food_lbl.text = "Provided by the Elder"
		_rest_food_lbl.add_theme_color_override("font_color", Color(0.80, 0.72, 0.50))
		for child in _rest_food_list.get_children():
			child.queue_free()
		_rest_location_lbl.text = "Elder's Fire  ✓"
		_rest_location_lbl.add_theme_color_override("font_color", Color(0.45, 0.80, 0.45))
		_rest_rest_btn.text = "Rest"
	elif _rest_smith_mode:
		_rest_food_lbl.visible = true
		_rest_mode_row.visible = false
		_rest_cook_recipe_list.visible = false
		_rest_cook_slot_box.visible = false
		_rest_cook_preview_lbl.visible = false
		has_food = true
		location_ok = true
		_rest_food_lbl.text = "Provided by the Smith"
		_rest_food_lbl.add_theme_color_override("font_color", Color(0.80, 0.72, 0.50))
		for child in _rest_food_list.get_children():
			child.queue_free()
		_rest_location_lbl.text = "Smith's Forge  ✓"
		_rest_location_lbl.add_theme_color_override("font_color", Color(0.45, 0.80, 0.45))
		_rest_rest_btn.text = "Rest"
	elif _rest_inn_mode:
		_rest_food_lbl.visible = true
		_rest_mode_row.visible = false
		_rest_cook_recipe_list.visible = false
		_rest_cook_slot_box.visible = false
		_rest_cook_preview_lbl.visible = false
		# Inn provides food — show coin cost instead
		var coins: int = 0
		for item in inv:
			if item.get("type", "") == "currency":
				coins += 1
		var can_afford: bool = coins >= 1
		_rest_cost_lbl.text = "Cost: 1 coin  (%d available)  %s" % [coins, "✓" if can_afford else "✗"]
		_rest_cost_lbl.add_theme_color_override("font_color",
			Color(0.45, 0.80, 0.45) if can_afford else Color(0.75, 0.35, 0.35))
		has_food = can_afford
		location_ok = true
		_rest_location_lbl.text = "Rest House  ✓"
		_rest_location_lbl.add_theme_color_override("font_color", Color(0.45, 0.80, 0.45))
		_rest_rest_btn.text = "Rest (1 coin)"
	elif _rest_hunter_camp:
		_rest_food_lbl.visible = true
		_rest_mode_row.visible = false
		_rest_cook_recipe_list.visible = false
		_rest_cook_slot_box.visible = false
		_rest_cook_preview_lbl.visible = false
		has_food = true
		location_ok = true
		_rest_food_lbl.text = "Provided by the Old Hunter"
		_rest_food_lbl.add_theme_color_override("font_color", Color(0.80, 0.72, 0.50))
		for child in _rest_food_list.get_children():
			child.queue_free()
		_rest_location_lbl.text = "Hunter's Camp  ✓"
		_rest_location_lbl.add_theme_color_override("font_color", Color(0.45, 0.80, 0.45))
		_rest_rest_btn.text = "Rest"
	else:
		# Camping — choose to Eat something plain or Cook a recipe
		_rest_mode_row.visible = true
		_rest_eat_btn.add_theme_color_override("font_color",
			Color(1.0, 0.85, 0.3) if _rest_mode == "eat" else Color(0.85, 0.85, 0.85))
		_rest_cook_btn.add_theme_color_override("font_color",
			Color(1.0, 0.85, 0.3) if _rest_mode == "cook" else Color(0.85, 0.85, 0.85))

		if _rest_mode == "eat":
			_rest_food_lbl.visible = true
			_rest_cook_recipe_list.visible = false
			_rest_cook_slot_box.visible = false
			_rest_cook_preview_lbl.visible = false
			has_food = _refresh_rest_eat(inv)
		else:
			_rest_food_lbl.visible = false
			_rest_cook_recipe_list.visible = true
			_rest_cook_slot_box.visible = true
			_rest_cook_preview_lbl.visible = true
			has_food = _refresh_rest_cook(inv)

		# Location check
		var enemies_present: bool = _zone_has_living_enemies()
		location_ok = not enemies_present
		_rest_location_lbl.text = (
			"Enemies nearby — cannot rest  ✗" if enemies_present
			else "Open ground  ✓"
		)
		_rest_location_lbl.add_theme_color_override("font_color",
			Color(0.45, 0.80, 0.45) if location_ok else Color(0.75, 0.35, 0.35))
		_rest_rest_btn.text = "Rest"

	# Spirit ward (same for both modes)
	var ward_lvl: int = _player_spirit_ward_level()
	var ward_name: String = _player_spirit_ward_name()
	var tile_data_p: Dictionary = GameManager.get_tile_data(GameManager.world_layer, GameManager.world_pos)
	var zone_req_p: int = tile_data_p.get("required_protection_level", 0)
	if ward_lvl >= 0:
		var suffix: String = "  ✓" if ward_lvl >= zone_req_p else "  ✗"
		_rest_spirit_lbl.text = "%s%s" % [ward_name, suffix]
		_rest_spirit_lbl.add_theme_color_override("font_color",
			Color(0.45, 0.80, 0.45) if ward_lvl >= zone_req_p else Color(0.70, 0.55, 0.35))
	else:
		_rest_spirit_lbl.text = "None — spirits may find you  ✗"
		_rest_spirit_lbl.add_theme_color_override("font_color", Color(0.70, 0.55, 0.35))

	# Exhaustion
	var ex: int = GameManager.player_data.get("exhaustion_stacks", 0)
	_rest_exhaustion_lbl.text = "%d stack%s" % [ex, "s" if ex != 1 else ""]
	_rest_exhaustion_lbl.add_theme_color_override("font_color",
		Color(0.75, 0.35, 0.35) if ex > 0 else Color(0.55, 0.55, 0.55))

	# Effects preview
	var shortfall_p: int = zone_req_p - ward_lvl
	var effects: PackedStringArray = ["• HP will be restored to full."]
	if _rest_inn_mode:
		effects.append("• Hearthkeeper's Stew — +10% max HP until next rest.")
	elif _rest_elder_mode:
		effects.append("• Elder's Roast Meat — +10% max SP until next rest.")
	elif _rest_smith_mode:
		effects.append("• Smith's Meal — +1 physical damage resistance until next rest.")
	elif _rest_hunter_camp:
		effects.append("• Dinner with the Old Hunter — +10% to hit until next rest.")
	if _rest_hunter_camp or shortfall_p <= 0:
		effects.append("• Exhaustion will be cleared.")
	elif shortfall_p == 1:
		effects.append("• Partial protection — you will gain 1 exhaustion stack.")
	else:
		effects.append("• No spirit protection — you will gain %d exhaustion stacks." % shortfall_p)
	_rest_effects_lbl.text = "\n".join(effects)

	# Rest button
	_rest_rest_btn.disabled = not (has_food and location_ok)

# ── Eat mode: pick one plain food item to consume for the rest ────────────────
func _refresh_rest_eat(inv: Array) -> bool:
	# Auto-slot the best available plain food (meat, tuber, or vegetable)
	if _rest_food_item.is_empty():
		var best_q: int = -1
		for i in range(inv.size()):
			var item: Dictionary = inv[i]
			var mt: String = item.get("material_type", "")
			if mt in ["meat", "tuber", "vegetable"] and item.get("uses_remaining", 1) > 0:
				var q: int = item.get("quality", 0)
				if q > best_q:
					best_q = q
					_rest_food_item = item
					_rest_food_inv_idx = i

	# Food label
	if _rest_food_item.is_empty():
		_rest_food_lbl.text = "No food available — must have something to eat to rest."
		_rest_food_lbl.add_theme_color_override("font_color", Color(0.70, 0.35, 0.35))
	else:
		var uses: int  = _rest_food_item.get("uses_remaining", 1)
		var max_u: int = _rest_food_item.get("max_uses", 1)
		var exp_r: int = _rest_food_item.get("expires_in_rests", -1)
		var exp_str: String = ("  — spoils in %d rest%s" % [exp_r, "s" if exp_r != 1 else ""]) if exp_r >= 0 else ""
		var passive: Dictionary = _rest_food_item.get("passive_meal_buff", {})
		var buff_str: String = ""
		if not passive.is_empty():
			var lines: Array = DataManager.format_meal_buff_lines(passive)
			if not lines.is_empty():
				buff_str = "\nEaten as-is: %s — %s until next rest" % [passive.get("name", "?"), ", ".join(PackedStringArray(lines))]
		_rest_food_lbl.text = "%s  (%d/%d uses)%s%s" % [_rest_food_item.get("name", "?"), uses, max_u, exp_str, buff_str]
		_rest_food_lbl.add_theme_color_override("font_color",
			Color(0.85, 0.55, 0.35) if exp_r == 1 else Color(0.80, 0.80, 0.65))

	# Food list
	for child in _rest_food_list.get_children():
		child.queue_free()
	for i in range(inv.size()):
		var item: Dictionary = inv[i]
		var mt: String = item.get("material_type", "")
		if mt not in ["meat", "tuber", "vegetable"]:
			continue
		if item.get("uses_remaining", 1) <= 0:
			continue
		if item == _rest_food_item:
			continue
		var btn := Button.new()
		var uses_i: int = item.get("uses_remaining", 1)
		var max_i: int  = item.get("max_uses", 1)
		var exp_i: int  = item.get("expires_in_rests", -1)
		var exp_i_str: String = ("  — spoils in %d" % exp_i) if exp_i >= 0 else ""
		btn.text = "%s  (%d/%d uses)%s" % [item.get("name", "?"), uses_i, max_i, exp_i_str]
		var captured_item: Dictionary = item
		var captured_idx: int = i
		btn.pressed.connect(func():
			_rest_food_item = captured_item
			_rest_food_inv_idx = captured_idx
			_refresh_rest())
		_rest_food_list.add_child(btn)

	return not _rest_food_item.is_empty()

# ── Cook mode: pick a rest recipe, then fill its ingredient slots ─────────────
# Returns the ordered list of ingredient slots for a recipe:
# {"key": "primary"/"secondary_N", "mat_slot": material group name, "optional": bool}
func _cook_recipe_slots(recipe: Dictionary) -> Array:
	var slots: Array = []
	var req: Array = recipe.get("required_materials", [])
	for i in range(req.size()):
		var key: String = "primary" if i == 0 else "primary_%d" % i
		slots.append({"key": key, "mat_slot": req[i], "optional": false})
	var opt: Array = recipe.get("optional_materials", [])
	var opt_max: int = recipe.get("optional_max", 0)
	for i in range(opt_max):
		var mat: String = opt[0] if opt.size() > 0 else ""
		slots.append({"key": "secondary_%d" % i, "mat_slot": mat, "optional": true})
	return slots

func _refresh_rest_cook(inv: Array) -> bool:
	# Recipe list — only recipes that grant a buff (excludes simple_meal)
	for child in _rest_cook_recipe_list.get_children():
		child.queue_free()
	var skills: Dictionary = GameManager.player_data.get("skills", {})
	var known: Array = GameManager.player_data.get("known_cooking_recipes", [])
	for recipe_id in known:
		if recipe_id == "simple_meal":
			continue
		var recipe: Dictionary = DataManager.get_cooking_recipe(recipe_id)
		if recipe.is_empty() or not recipe.get("is_rest_recipe", false):
			continue
		var check: Dictionary = DataManager.check_cooking_skill(recipe_id, skills)
		var btn := Button.new()
		btn.text = recipe.get("name", recipe_id)
		if not check["can_craft"]:
			btn.text += "  (requires Cooking %d)" % check["req_cooking"]
			btn.disabled = true
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.clip_contents = false
		btn.add_theme_color_override("font_color",
			Color(1.0, 0.85, 0.3) if recipe_id == _rest_cook_recipe else Color(0.85, 0.85, 0.85))
		var captured_id: String = recipe_id
		btn.pressed.connect(func():
			_rest_cook_recipe = captured_id
			_rest_cook_slots = {}
			_refresh_rest())
		_rest_cook_recipe_list.add_child(btn)

	# Slot box + ingredient picker
	for child in _rest_cook_slot_box.get_children():
		child.queue_free()
	for child in _rest_food_list.get_children():
		child.queue_free()

	if _rest_cook_recipe == "":
		_rest_cook_preview_lbl.text = "Choose a recipe to cook."
		return false

	var recipe: Dictionary = DataManager.get_cooking_recipe(_rest_cook_recipe)
	var slot_defs: Array = _cook_recipe_slots(recipe)

	var active_slot: String = ""
	var active_def: Dictionary = {}
	var used_indices: Array = []
	for slot_def in slot_defs:
		var key: String = slot_def["key"]
		var label_text: String = DataManager.slot_display_name(slot_def["mat_slot"])
		if slot_def["optional"]:
			label_text += "  (optional)"
		_rest_cook_slot_box.add_child(_build_cook_slot_row(key, label_text))
		if _rest_cook_slots.has(key):
			used_indices.append(_rest_cook_slots[key]["inv_idx"])
		elif active_slot == "":
			active_slot = key
			active_def = slot_def

	# Ingredient picker for the active (first unfilled) slot
	if active_slot != "":
		for i in range(inv.size()):
			if i in used_indices:
				continue
			var item: Dictionary = inv[i]
			if item.get("uses_remaining", 1) <= 0:
				continue
			var mt: String = item.get("material_type", "")
			if DataManager.resolve_material_slot(mt, [active_def["mat_slot"]]) == "":
				continue
			var btn := Button.new()
			btn.text = "%s  (%s)" % [item.get("name", "?"), item.get("quality_name", "?")]
			var captured_item: Dictionary = item
			var captured_idx: int = i
			var captured_key: String = active_slot
			btn.pressed.connect(func():
				_rest_cook_slots[captured_key] = {"item": captured_item, "inv_idx": captured_idx}
				_refresh_rest())
			_rest_food_list.add_child(btn)
		if _rest_food_list.get_child_count() == 0:
			var none_lbl := Label.new()
			none_lbl.text = "No suitable ingredients on hand."
			none_lbl.add_theme_color_override("font_color", Color(0.70, 0.35, 0.35))
			_rest_food_list.add_child(none_lbl)

	# Buff preview
	if _rest_cook_slots.has("primary"):
		var secondary_items: Array = []
		for key in _rest_cook_slots:
			if key.begins_with("secondary"):
				secondary_items.append(_rest_cook_slots[key]["item"])
		var buff: Dictionary = DataManager.compute_meal_buff(_rest_cook_recipe, _rest_cook_slots["primary"]["item"], secondary_items)
		var lines: Array = DataManager.format_meal_buff_lines(buff)
		_rest_cook_preview_lbl.text = "%s — %s until next rest" % [buff.get("name", recipe.get("name", "?")), ", ".join(PackedStringArray(lines))]
		var min_optional: int = recipe.get("min_optional", 0)
		if secondary_items.size() < min_optional:
			var need_slot: String = recipe.get("optional_materials", [""])[0]
			_rest_cook_preview_lbl.text += "\n(Needs at least %d %s.)" % [min_optional, DataManager.slot_display_name(need_slot)]
	else:
		_rest_cook_preview_lbl.text = "Choose ingredients to see the buff."

	return _cook_recipe_ready()

# A cook recipe is ready to make once its required slot is filled and at
# least `min_optional` of its optional slots are filled too (e.g. Pottage
# needs a protein AND a vegetable, even though the vegetable slots are
# individually marked optional to allow a second bonus ingredient).
func _cook_recipe_ready() -> bool:
	if not _rest_cook_slots.has("primary"):
		return false
	var recipe: Dictionary = DataManager.get_cooking_recipe(_rest_cook_recipe)
	var min_optional: int = recipe.get("min_optional", 0)
	if min_optional <= 0:
		return true
	var secondary_count: int = 0
	for key in _rest_cook_slots:
		if key.begins_with("secondary"):
			secondary_count += 1
	return secondary_count >= min_optional

# Builds a single ingredient-slot row for the cook UI: a label, the currently
# slotted item (or a prompt), and a clear button if filled.
func _build_cook_slot_row(slot_key: String, label_text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var lbl := Label.new()
	lbl.text = label_text + ":"
	lbl.custom_minimum_size = Vector2(160, 0)
	row.add_child(lbl)

	var value_lbl := Label.new()
	value_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_lbl.clip_contents = false
	if _rest_cook_slots.has(slot_key):
		var item: Dictionary = _rest_cook_slots[slot_key]["item"]
		value_lbl.text = "%s  (%s)" % [item.get("name", "?"), item.get("quality_name", "?")]
		value_lbl.add_theme_color_override("font_color", Color(0.80, 0.80, 0.65))
	else:
		value_lbl.text = "— choose below —"
		value_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
	row.add_child(value_lbl)

	if _rest_cook_slots.has(slot_key):
		var clear_btn := Button.new()
		clear_btn.text = "×"
		clear_btn.custom_minimum_size = Vector2(28, 0)
		clear_btn.tooltip_text = "Remove this ingredient"
		clear_btn.add_theme_color_override("font_color", Color(0.85, 0.45, 0.45))
		var captured_key: String = slot_key
		clear_btn.pressed.connect(func():
			_rest_cook_slots.erase(captured_key)
			_refresh_rest())
		row.add_child(clear_btn)

	return row

# Consumes one use from each ingredient slotted for the chosen rest recipe.
# Sorted by inventory index descending so removals don't shift earlier indices.
func _consume_cook_slots(inv: Array) -> void:
	var entries: Array = _rest_cook_slots.values()
	entries.sort_custom(func(a, b): return a["inv_idx"] > b["inv_idx"])
	for entry in entries:
		var idx: int = entry["inv_idx"]
		if idx < 0 or idx >= inv.size():
			continue
		var item: Dictionary = inv[idx]
		var uses: int = item.get("uses_remaining", 1) - 1
		if uses <= 0:
			inv.remove_at(idx)
		else:
			item["uses_remaining"] = uses
	GameManager.player_data["inventory"] = inv

func _zone_has_living_enemies() -> bool:
	var zone: Node = GameManager.current_zone
	if zone == null:
		return false
	var tile_scene := zone as TileScene
	if tile_scene == null:
		return false
	for entity in tile_scene.get_all_entities():
		var enemy := entity as Enemy
		if enemy != null and is_instance_valid(enemy) and not enemy._dead and enemy.current_hp > 0:
			return true
	return false

func _player_has_spirit_ward() -> bool:
	return _player_spirit_ward_level() >= 0

func _player_spirit_ward_level() -> int:
	# Returns -1 (none), 0 (basic / feat), or 1 (vial / higher).
	if GameManager.player_data.get("vial_protection_rests", 0) > 0:
		return 1
	var equip: Dictionary = GameManager.player_data.get("equipment", {})
	for slot in equip.values():
		if slot != null and slot.get("spirit_ward", false):
			return 0
	if GameManager.has_feat("inner_flame"):
		return 0
	return -1

func _player_spirit_ward_name() -> String:
	if GameManager.player_data.get("vial_protection_rests", 0) > 0:
		return "Dark Green Vial (Lv.1)"
	var equip: Dictionary = GameManager.player_data.get("equipment", {})
	for slot in equip.values():
		if slot != null and slot.get("spirit_ward", false):
			return "%s (Lv.0)" % slot.get("name", "Trophy")
	if GameManager.has_feat("inner_flame"):
		return "Inner Flame (Lv.0)"
	return ""

# ── Consumable use ─────────────────────────────────────────────────────────────
func _use_consumable(inv_idx: int, item: Dictionary) -> void:
	match item.get("on_use", ""):
		"drink_vial":        _drink_vial(inv_idx)
		"apply_poison":      _apply_poison_to_weapon(inv_idx)
		"deploy_smoke_bomb": _begin_smoke_bomb_deploy(inv_idx, item)

# Applies damage from a consumed item to the player, halved if Iron Belly is active.
# Use this for every drinkable/edible that deals damage on consumption.
func _apply_consumed_damage(p: Node, dmg: int) -> void:
	if GameManager.has_feat("iron_belly"):
		dmg = maxi(1, dmg / 2)
	p.current_hp = maxf(0.0, p.current_hp - float(dmg))
	EventBus.damage_floater.emit(p, "-%.1f" % float(dmg), Color(0.20, 0.78, 0.30))

func _drink_vial(inv_idx: int) -> void:
	var p = GameManager.player
	if p == null or not is_instance_valid(p):
		return
	_apply_consumed_damage(p, randi_range(1, 4))
	GameManager.player_data["vial_protection_rests"] = 3
	var inv: Array = GameManager.player_data.get("inventory", [])
	inv.remove_at(inv_idx)
	GameManager.player_data["inventory"] = inv
	GameManager.update_quest_thread("find_spiritual_protection", "apothecary_vial_path",
		"I drank the vial. It tasted foul and it hurt, but I should be protected for the next few nights.")
	_refresh_inventory()
	_refresh_status_panel()

func _apply_poison_to_weapon(inv_idx: int) -> void:
	var equip: Dictionary = GameManager.player_data.get("equipment", {})
	var target_slot: String = ""
	for slot in ["hand_1", "hand_2"]:
		var item = equip.get(slot)
		if item != null and item.get("type", "") == "weapon":
			target_slot = slot
			break
	if target_slot == "":
		EventBus.combat_log.emit("No weapon equipped to apply poison to.")
		return
	equip[target_slot]["poisoned"] = true
	GameManager.player_data["equipment"] = equip
	var inv: Array = GameManager.player_data.get("inventory", [])
	inv.remove_at(inv_idx)
	GameManager.player_data["inventory"] = inv
	var wpn_name: String = equip[target_slot].get("name", "weapon")
	EventBus.combat_log.emit("Poison applied to %s. It will last until your next rest." % wpn_name)
	_refresh_inventory()

func _begin_smoke_bomb_deploy(inv_idx: int, item: Dictionary) -> void:
	if GameManager.combat_mode:
		CombatManager.begin_smoke_deploy(item, inv_idx)
		_close_all()   # close inventory so player can target
		EventBus.combat_log.emit("Click a tile within range %d to throw the smoke bomb. Right-click to cancel." % item.get("throw_range", 12))
	else:
		# Out of combat: deploy at player position immediately
		var player = GameManager.player
		if player == null:
			return
		var pc: Vector2i = player.get("grid_cell") if player.get("grid_cell") != null else Vector2i(40, 40)
		GameManager.add_smoke_zone(pc, item.get("smoke_radius", 2), item.get("smoke_turns", 3))
		var inv: Array = GameManager.player_data.get("inventory", [])
		inv.remove_at(inv_idx)
		GameManager.player_data["inventory"] = inv
		EventBus.combat_log.emit("Smoke bomb deployed.")
		_refresh_inventory()

func _do_rest() -> void:
	var inv: Array = GameManager.player_data.get("inventory", [])

	if _rest_elder_mode or _rest_hunter_camp or _rest_smith_mode:
		pass  # elder/hunter/smith provide food free — no resource consumed
	elif _rest_inn_mode:
		# Deduct 1 coin
		var removed: int = 0
		var i: int = inv.size() - 1
		while i >= 0 and removed < 1:
			if inv[i].get("type", "") == "currency":
				inv.remove_at(i)
				removed += 1
			i -= 1
		GameManager.player_data["inventory"] = inv
		# First inn sleep: small XP reward
		if not GameManager.player_data.get("inn_first_sleep_done", false):
			GameManager.player_data["inn_first_sleep_done"] = true
			GameManager.add_xp(10)
	elif _rest_mode == "cook" and _cook_recipe_ready():
		_consume_cook_slots(inv)
	else:
		# Consume one food use
		if _rest_food_inv_idx >= 0 and _rest_food_inv_idx < inv.size():
			var item: Dictionary = inv[_rest_food_inv_idx]
			var uses: int = item.get("uses_remaining", 1) - 1
			if uses <= 0:
				inv.remove_at(_rest_food_inv_idx)
			else:
				item["uses_remaining"] = uses
			GameManager.player_data["inventory"] = inv

	# Drain all timed status effects (bleed etc.) before healing — rest is a time-skip
	var p = GameManager.player
	if p != null and is_instance_valid(p) and p.get("status_effects") != null:
		while not p.status_effects.get("bleed", []).is_empty():
			CombatManager.tick_status_effects(p)

	# Apply meal buff for the coming day — clear old, set new based on rest location
	GameManager.player_data.erase("active_meal_buff")
	if _rest_inn_mode:
		GameManager.player_data["active_meal_buff"] = {
			"id": "innkeepers_stew", "name": "Hearthkeeper's Stew", "hp_pct": 0.10
		}
	elif _rest_elder_mode:
		GameManager.player_data["active_meal_buff"] = {
			"id": "elders_roast_meat", "name": "Elder's Roast Meat", "sp_pct": 0.10
		}
	elif _rest_smith_mode:
		GameManager.player_data["active_meal_buff"] = {
			"id": "smiths_meal", "name": "Smith's Meal", "phys_dr_flat": 1.0
		}
	elif _rest_hunter_camp:
		GameManager.player_data["active_meal_buff"] = {
			"id": "dinner_with_old_hunter", "name": "Dinner with the Old Hunter", "hit_flat": 10
		}
	elif _rest_mode == "cook" and _cook_recipe_ready():
		var secondary_items: Array = []
		for key in _rest_cook_slots:
			if key.begins_with("secondary"):
				secondary_items.append(_rest_cook_slots[key]["item"])
		GameManager.player_data["active_meal_buff"] = DataManager.compute_meal_buff(
			_rest_cook_recipe, _rest_cook_slots["primary"]["item"], secondary_items)
	elif not _rest_food_item.is_empty():
		var passive: Dictionary = _rest_food_item.get("passive_meal_buff", {})
		if not passive.is_empty():
			GameManager.player_data["active_meal_buff"] = passive

	# Restore HP and Spirit to full (max values include any active meal buff)
	if p != null and is_instance_valid(p):
		p.current_hp = p.max_hp
		p.current_spirit = p.max_spirit

	# Respawn enemies — clear kill list and saved positions so they appear fresh next load
	GameManager.player_data.erase("dead_respawnables")
	GameManager.player_data.erase("enemy_positions")

	# Check protection BEFORE decrementing the vial counter — the player is
	# protected by this rest if they still have charges remaining.
	var ward_level: int = _player_spirit_ward_level()
	var tile_data: Dictionary = GameManager.get_tile_data(GameManager.world_layer, GameManager.world_pos)
	var zone_req: int = tile_data.get("required_protection_level", 0)

	# Now consume one vial charge (if any)
	var vial_left: int = GameManager.player_data.get("vial_protection_rests", 0)
	if vial_left > 0:
		GameManager.player_data["vial_protection_rests"] = vial_left - 1

	# Handle exhaustion based on how far ward_level falls below zone_req
	var shortfall: int = zone_req - ward_level  # 0 = met, 1 = one tier short, 2+ = unprotected
	if _rest_hunter_camp or shortfall <= 0:
		GameManager.player_data["exhaustion_stacks"] = 0
	else:
		var ex: int = GameManager.player_data.get("exhaustion_stacks", 0)
		GameManager.player_data["exhaustion_stacks"] = ex + shortfall

	# Hunter path: completing the camp rest finishes both thread and parent quest
	if _rest_hunter_camp:
		GameManager.complete_quest_thread("find_spiritual_protection", "hunter_animal_kill")
		GameManager.complete_quest("find_spiritual_protection")
		GameManager.add_xp(75)

	# Vial path: on first protected sleep, add a journal note — but don't complete
	# the thread or quest yet (those only close when the recipe is learned).
	# Only fires when the vial actually provided protection (vial_left > 0 before decrement).
	var vial_path_done: bool = GameManager.player_data.get("vial_path_rest_done", false)
	if shortfall <= 0 and not vial_path_done and vial_left > 0 \
			and GameManager.has_quest_thread("find_spiritual_protection", "apothecary_vial_path"):
		GameManager.player_data["vial_path_rest_done"] = true
		GameManager.update_quest_thread("find_spiritual_protection", "apothecary_vial_path",
			"I slept safely, but the vial won't last forever. I need a more permanent solution.")
		GameManager.add_xp(30)

	# Vial expiry quest update — fires the rest the protection runs out
	if vial_left == 1 and not GameManager.player_data.get("vial_expiry_quest_done", false):
		GameManager.player_data["vial_expiry_quest_done"] = true
		GameManager.update_quest("find_spiritual_protection",
			"I will need to buy more of that strange potion.")

	# Reset per-cycle vial purchase limit
	GameManager.player_data.erase("apothecary_vial_bought_this_cycle")

	# Decrement plant respawn counters; remove any that have reached zero
	var harvested: Dictionary = GameManager.player_data.get("harvested_plants", {})
	for key in harvested.keys():
		harvested[key] -= 1
		if harvested[key] <= 0:
			harvested.erase(key)
	if harvested.is_empty():
		GameManager.player_data.erase("harvested_plants")
	else:
		GameManager.player_data["harvested_plants"] = harvested

	# Tick food spoilage — decrement expires_in_rests on all perishable inventory items;
	# silently remove any that have expired.
	var perishable_inv: Array = GameManager.player_data.get("inventory", [])
	var spoil_i: int = perishable_inv.size() - 1
	while spoil_i >= 0:
		if perishable_inv[spoil_i].has("expires_in_rests"):
			perishable_inv[spoil_i]["expires_in_rests"] -= 1
			if perishable_inv[spoil_i]["expires_in_rests"] <= 0:
				perishable_inv.remove_at(spoil_i)
		spoil_i -= 1
	GameManager.player_data["inventory"] = perishable_inv

	_rest_hunter_camp = false
	_rest_inn_mode    = false
	_rest_elder_mode  = false
	_rest_smith_mode  = false
	_rest_food_item = {}
	_rest_food_inv_idx = -1
	_rest_mode = "eat"
	_rest_cook_recipe = ""
	_rest_cook_slots = {}

	GameManager.clear_weapon_poison()
	GameManager.smoke_zones.clear()
	EventBus.smoke_zones_changed.emit()

	var trigger_dream: bool = (shortfall <= 0
			and not GameManager.player_data.get("dream_seen", false))

	EventBus.player_rested.emit()
	GameManager.auto_save()
	_close_all()

	if trigger_dream:
		EventBus.open_dream_scene.emit()

# ══════════════════════════════════════════════════════════════════════════════
# JOURNAL PANEL
# ══════════════════════════════════════════════════════════════════════════════
func _build_journal_panel() -> Control:
	var shell = _make_panel_shell("JOURNAL")
	var vbox: VBoxContainer = shell["vbox"]

	# Tab row
	var tab_row := HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 4)
	vbox.add_child(tab_row)
	var quests_tab := Button.new()
	quests_tab.text = "Quests"
	quests_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quests_tab.clip_contents = false
	tab_row.add_child(quests_tab)
	var notes_tab := Button.new()
	notes_tab.text = "Notes"
	notes_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	notes_tab.clip_contents = false
	tab_row.add_child(notes_tab)

	# Small dot badges on each tab button (shown when that tab has unread items)
	_journal_quest_dot = _make_dot_badge(8, Color(0.82, 0.15, 0.15))
	_journal_quest_dot.set_anchor_and_offset(SIDE_LEFT,   1.0, -10)
	_journal_quest_dot.set_anchor_and_offset(SIDE_RIGHT,  1.0,  -2)
	_journal_quest_dot.set_anchor_and_offset(SIDE_TOP,    0.0,   2)
	_journal_quest_dot.set_anchor_and_offset(SIDE_BOTTOM, 0.0,  10)
	quests_tab.add_child(_journal_quest_dot)

	_journal_notes_dot = _make_dot_badge(8, Color(0.82, 0.15, 0.15))
	_journal_notes_dot.set_anchor_and_offset(SIDE_LEFT,   1.0, -10)
	_journal_notes_dot.set_anchor_and_offset(SIDE_RIGHT,  1.0,  -2)
	_journal_notes_dot.set_anchor_and_offset(SIDE_TOP,    0.0,   2)
	_journal_notes_dot.set_anchor_and_offset(SIDE_BOTTOM, 0.0,  10)
	notes_tab.add_child(_journal_notes_dot)

	vbox.add_child(HSeparator.new())

	# ── Quests section ─────────────────────────────────────────────────────────
	var quests_section := VBoxContainer.new()
	quests_section.size_flags_vertical = Control.SIZE_EXPAND_FILL
	quests_section.add_theme_constant_override("separation", 8)
	vbox.add_child(quests_section)

	var toggle_row := HBoxContainer.new()
	quests_section.add_child(toggle_row)
	var toggle_btn := CheckButton.new()
	toggle_btn.text = "Hide completed"
	toggle_btn.button_pressed = _journal_hide_completed
	toggle_btn.toggled.connect(func(on: bool):
		_journal_hide_completed = on
		_refresh_journal())
	toggle_row.add_child(toggle_btn)
	quests_section.add_child(HSeparator.new())

	var quests_scroll := ScrollContainer.new()
	quests_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	quests_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	quests_section.add_child(quests_scroll)

	_journal_vbox = VBoxContainer.new()
	_journal_vbox.add_theme_constant_override("separation", 10)
	_journal_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quests_scroll.add_child(_journal_vbox)

	# ── Notes section ──────────────────────────────────────────────────────────
	var notes_section := VBoxContainer.new()
	notes_section.size_flags_vertical = Control.SIZE_EXPAND_FILL
	notes_section.add_theme_constant_override("separation", 8)
	notes_section.visible = false
	vbox.add_child(notes_section)

	var search_row := HBoxContainer.new()
	search_row.add_theme_constant_override("separation", 8)
	notes_section.add_child(search_row)
	var search_lbl := Label.new()
	search_lbl.text = "Search:"
	search_row.add_child(search_lbl)
	_journal_search_edit = LineEdit.new()
	_journal_search_edit.placeholder_text = "Filter notes..."
	_journal_search_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_journal_search_edit.text_changed.connect(func(txt: String):
		_journal_notes_search = txt
		_refresh_notes())
	search_row.add_child(_journal_search_edit)
	notes_section.add_child(HSeparator.new())

	var notes_scroll := ScrollContainer.new()
	notes_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	notes_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	notes_section.add_child(notes_scroll)

	_journal_notes_vbox = VBoxContainer.new()
	_journal_notes_vbox.add_theme_constant_override("separation", 10)
	_journal_notes_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	notes_scroll.add_child(_journal_notes_vbox)

	# Tab switching
	quests_tab.pressed.connect(func():
		_journal_tab = "quests"
		quests_section.visible = true
		notes_section.visible = false
		_journal_quest_unread = 0
		if _journal_quest_dot != null:
			_journal_quest_dot.visible = false
		_refresh_journal())
	notes_tab.pressed.connect(func():
		_journal_tab = "notes"
		quests_section.visible = false
		notes_section.visible = true
		_journal_notes_unread = 0
		if _journal_notes_dot != null:
			_journal_notes_dot.visible = false
		_refresh_notes())

	return shell["root"]

func _refresh_notes() -> void:
	if _journal_notes_vbox == null:
		return
	for child in _journal_notes_vbox.get_children():
		child.queue_free()
	var notes: Array = GameManager.player_data.get("notes", [])
	var filter: String = _journal_notes_search.strip_edges().to_lower()
	var shown: int = 0
	for note in notes:
		var title: String = note.get("title", "")
		var body: String  = note.get("body", "")
		if filter != "" and not title.to_lower().contains(filter) \
				and not body.to_lower().contains(filter):
			continue
		shown += 1
		var title_lbl := Label.new()
		title_lbl.text = title.to_upper()
		title_lbl.add_theme_font_size_override("font_size", 15)
		title_lbl.add_theme_color_override("font_color", Color(0.88, 0.82, 0.65))
		_journal_notes_vbox.add_child(title_lbl)
		var body_lbl := Label.new()
		body_lbl.text = body
		body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body_lbl.add_theme_font_size_override("font_size", 12)
		body_lbl.add_theme_color_override("font_color", Color(0.72, 0.72, 0.72))
		_journal_notes_vbox.add_child(body_lbl)
		_journal_notes_vbox.add_child(HSeparator.new())
	if shown == 0:
		var lbl := Label.new()
		lbl.text = "No notes yet.\n\nExploratory conversations with people in the world will be recorded here." \
			if filter == "" else "No notes match your search."
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		_journal_notes_vbox.add_child(lbl)

func _refresh_journal() -> void:
	for child in _journal_vbox.get_children():
		child.queue_free()
	var quests: Array = GameManager.player_data.get("quests", [])
	if quests.is_empty():
		var lbl = Label.new()
		lbl.text = "No entries yet.\n\nAs you explore the world, discoveries, conversations, and observations will be recorded here."
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		_journal_vbox.add_child(lbl)
		return

	for quest in quests:
		var quest_id: String = quest.get("id", "")
		var completed: bool  = quest.get("completed", false)
		if _journal_hide_completed and completed:
			continue

		# ── Quest title row ────────────────────────────────────────────────────
		var title_row := HBoxContainer.new()
		_journal_vbox.add_child(title_row)

		var title_lbl := Label.new()
		title_lbl.text = quest.get("title", "???").to_upper()
		title_lbl.add_theme_font_size_override("font_size", 15)
		title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title_lbl.add_theme_color_override("font_color",
			Color(0.50, 0.50, 0.50) if completed else Color(0.88, 0.82, 0.65))
		title_row.add_child(title_lbl)

		if completed:
			var done_lbl := Label.new()
			done_lbl.text = "COMPLETED"
			done_lbl.add_theme_font_size_override("font_size", 11)
			done_lbl.add_theme_color_override("font_color", Color(0.40, 0.75, 0.40))
			done_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			title_row.add_child(done_lbl)

		# ── Quest description ──────────────────────────────────────────────────
		var desc_lbl := Label.new()
		desc_lbl.text = quest.get("description", "")
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.add_theme_font_size_override("font_size", 12)
		desc_lbl.add_theme_color_override("font_color",
			Color(0.45, 0.45, 0.45) if completed else Color(0.72, 0.72, 0.72))
		_journal_vbox.add_child(desc_lbl)

		# ── Quest-level updates (if any) ───────────────────────────────────────
		for update in quest.get("updates", []):
			var upd_lbl := Label.new()
			upd_lbl.text = "• " + update
			upd_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			upd_lbl.add_theme_font_size_override("font_size", 12)
			upd_lbl.add_theme_color_override("font_color",
				Color(0.40, 0.55, 0.40) if completed else Color(0.50, 0.85, 0.50))
			_journal_vbox.add_child(upd_lbl)

		# ── Threads (collapsible) ──────────────────────────────────────────────
		var threads: Array = quest.get("threads", [])
		if not threads.is_empty():
			var thread_indent := MarginContainer.new()
			thread_indent.add_theme_constant_override("margin_left", 16)
			_journal_vbox.add_child(thread_indent)
			var thread_vbox := VBoxContainer.new()
			thread_vbox.add_theme_constant_override("separation", 6)
			thread_indent.add_child(thread_vbox)

			for thread in threads:
				var thread_id: String    = thread.get("id", "")
				var t_completed: bool    = thread.get("completed", false)
				var expand_key: String   = quest_id + "::" + thread_id
				var is_expanded: bool    = _journal_thread_expanded.get(expand_key, false)

				# Thread toggle button
				var toggle_btn := Button.new()
				var arrow: String = "▼" if is_expanded else "▶"
				toggle_btn.text = "%s  %s" % [arrow, thread.get("title", "???")]
				toggle_btn.flat = true
				toggle_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
				toggle_btn.add_theme_font_size_override("font_size", 13)
				toggle_btn.add_theme_color_override("font_color",
					Color(0.45, 0.45, 0.45) if t_completed else Color(0.78, 0.78, 0.78))
				if t_completed:
					toggle_btn.text += "  ✓"
				var captured_key: String = expand_key
				toggle_btn.pressed.connect(func():
					_journal_thread_expanded[captured_key] = \
						not _journal_thread_expanded.get(captured_key, false)
					_refresh_journal())
				thread_vbox.add_child(toggle_btn)

				# Expanded content
				if is_expanded:
					var detail_margin := MarginContainer.new()
					detail_margin.add_theme_constant_override("margin_left", 20)
					thread_vbox.add_child(detail_margin)
					var detail_vbox := VBoxContainer.new()
					detail_vbox.add_theme_constant_override("separation", 4)
					detail_margin.add_child(detail_vbox)

					var tdesc_lbl := Label.new()
					tdesc_lbl.text = thread.get("description", "")
					tdesc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
					tdesc_lbl.add_theme_font_size_override("font_size", 12)
					tdesc_lbl.add_theme_color_override("font_color",
						Color(0.45, 0.45, 0.45) if t_completed else Color(0.65, 0.65, 0.65))
					detail_vbox.add_child(tdesc_lbl)

					for upd in thread.get("updates", []):
						var upd_lbl := Label.new()
						upd_lbl.text = "• " + upd
						upd_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
						upd_lbl.add_theme_font_size_override("font_size", 12)
						upd_lbl.add_theme_color_override("font_color",
							Color(0.40, 0.55, 0.40) if t_completed else Color(0.50, 0.85, 0.50))
						detail_vbox.add_child(upd_lbl)

		_journal_vbox.add_child(HSeparator.new())

# ══════════════════════════════════════════════════════════════════════════════
# REFRESH
# ══════════════════════════════════════════════════════════════════════════════
func _refresh_stats() -> void:
	var d = GameManager.player_data
	if d.is_empty(): return
	_cs_switch_tab(_cs_active_tab)
	_refresh_feats()
	_refresh_bonuses()

	var lvl: int = d.get("level", 1)
	_cs_name_lbl.text  = d.get("name", "—")
	_cs_level_lbl.text = str(lvl)
	_cs_bg_lbl.text    = d.get("background", "—")

	var p_live = GameManager.player
	var max_hp: float = (p_live.max_hp if p_live != null and is_instance_valid(p_live) else float(d.get("max_hp", 0)))
	var hp: float     = (p_live.current_hp if p_live != null and is_instance_valid(p_live) else max_hp)
	_cs_hp_bar.max_value = max_hp
	_cs_hp_bar.value     = hp
	_cs_hp_lbl.text      = "%.1f / %.1f" % [hp, max_hp]

	# XP bar
	if _cs_xp_bar != null:
		var xp: int = d.get("xp", 0)
		var thresholds: Array = GameManager.XP_THRESHOLDS
		var xp_floor: int = thresholds[mini(lvl, thresholds.size() - 1)]
		var xp_ceil: int  = thresholds[mini(lvl + 1, thresholds.size() - 1)] if lvl + 1 < thresholds.size() else xp_floor
		var at_max: bool  = lvl >= thresholds.size() - 1
		if at_max:
			_cs_xp_bar.max_value = 1
			_cs_xp_bar.value     = 1
			_cs_xp_lbl.text      = "MAX LEVEL"
		else:
			_cs_xp_bar.max_value = xp_ceil - xp_floor
			_cs_xp_bar.value     = xp - xp_floor
			_cs_xp_lbl.text      = "%d / %d  (%d to next)" % [xp - xp_floor, xp_ceil - xp_floor, xp_ceil - xp]

	# Pending allocation points banner
	var unspent_skill: int = d.get("unspent_skill_points", 0)
	var unspent_stat:  int = d.get("unspent_stat_points",  0)
	var unspent_feat:  int = d.get("unspent_feat_points",  0)
	var has_pending: bool  = unspent_skill > 0 or unspent_stat > 0 or unspent_feat > 0
	var snapshot: Dictionary    = d.get("levelup_snapshot", {})
	var has_snapshot: bool      = not snapshot.is_empty()
	var snap_stats: Dictionary  = snapshot.get("stats",  {})
	var snap_skills: Dictionary = snapshot.get("skills", {})
	if _cs_pending_row != null:
		_cs_pending_row.visible = has_pending or has_snapshot
		var parts: Array = []
		if unspent_skill > 0: parts.append("%d skill point%s" % [unspent_skill, "s" if unspent_skill != 1 else ""])
		if unspent_stat  > 0: parts.append("%d stat point%s"  % [unspent_stat,  "s" if unspent_stat  != 1 else ""])
		if unspent_feat  > 0: parts.append("%d feat pick%s"   % [unspent_feat,  "s" if unspent_feat  != 1 else ""])
		if _cs_pending_lbl != null:
			_cs_pending_lbl.text = ("Unspent: " + "  |  ".join(parts)) if parts.size() > 0 else ""
		if _cs_confirm_btn != null:
			_cs_confirm_btn.visible = has_snapshot

	var stats = d.get("stats", {})
	for stat in STAT_NAMES:
		var val = stats.get(stat, 5)
		var mod = val - 5
		_cs_stat_vals[stat].text = str(val)
		_cs_stat_mods[stat].text = ("+%d" % mod) if mod >= 0 else str(mod)
		if _cs_stat_plus_btns.has(stat):
			var already_spent: bool = has_snapshot and val >= snap_stats.get(stat, val) + 1
			_cs_stat_plus_btns[stat].visible = unspent_stat > 0 and not already_spent
		if _cs_stat_minus_btns.has(stat):
			var show_minus: bool = has_snapshot and val > snap_stats.get(stat, val)
			_cs_stat_minus_btns[stat].modulate.a    = 1.0 if show_minus else 0.0
			_cs_stat_minus_btns[stat].mouse_filter  = Control.MOUSE_FILTER_STOP if show_minus else Control.MOUSE_FILTER_IGNORE

	var skills = d.get("skills", {})
	for skill in SKILL_NAMES:
		var invested: int    = skills.get(skill, 0)
		var gov_mod: int     = _best_mod(skill, stats)
		var equip_gov: int   = _equip_gov_bonus(skill)
		var equip_skill: int = _equip_skill_bonus(skill)
		var effective: float = maxf(0.0, invested * (1.0 + (gov_mod + equip_gov) * 0.1) + equip_skill)
		_cs_skill_invested[skill].text = str(invested)
		_cs_skill_vals[skill].text = _fmt(effective)
		if effective > invested:
			_cs_skill_vals[skill].add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
		else:
			_cs_skill_vals[skill].remove_theme_color_override("font_color")
		if _cs_skill_plus_btns.has(skill):
			_cs_skill_plus_btns[skill].visible = unspent_skill > 0
		if _cs_skill_minus_btns.has(skill):
			var show_minus: bool = has_snapshot and invested > snap_skills.get(skill, invested)
			_cs_skill_minus_btns[skill].modulate.a   = 1.0 if show_minus else 0.0
			_cs_skill_minus_btns[skill].mouse_filter = Control.MOUSE_FILTER_STOP if show_minus else Control.MOUSE_FILTER_IGNORE

func _refresh_feats() -> void:
	if _cs_feats_box == null:
		return

	# ── Feat picker (only when points available) ──────────────────────────────
	var unspent_feat: int = GameManager.player_data.get("unspent_feat_points", 0)
	if _cs_feat_picker_box != null:
		_cs_feat_picker_box.visible = unspent_feat > 0
		for child in _cs_feat_picker_box.get_children():
			child.queue_free()
		if unspent_feat > 0:
			var pick_hdr := Label.new()
			pick_hdr.text = "PICK A FEAT"
			pick_hdr.add_theme_font_size_override("font_size", 12)
			pick_hdr.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
			_cs_feat_picker_box.add_child(pick_hdr)
			var pd: Dictionary = GameManager.player_data
			var p_stats: Dictionary  = pd.get("stats",  {})
			var p_skills: Dictionary = pd.get("skills", {})
			for feat_id in DataManager.feats:
				var f: Dictionary = DataManager.feats[feat_id]
				if f.get("source", "") != "level_up":
					continue
				if GameManager.has_feat(feat_id):
					continue
				var stats_req: Dictionary  = f.get("requirements", {}).get("stats",  {})
				var skills_req: Dictionary = f.get("requirements", {}).get("skills", {})
				var meets: bool = true
				for s in stats_req:
					if p_stats.get(s, 0) < stats_req[s]:
						meets = false; break
				if meets:
					for s in skills_req:
						if p_skills.get(s, 0) < skills_req[s]:
							meets = false; break
				var row := HBoxContainer.new()
				row.add_theme_constant_override("separation", 6)
				var btn := Button.new()
				btn.text = f.get("name", feat_id)
				btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				btn.custom_minimum_size = Vector2(0, 26)
				btn.disabled = not meets
				var fid: String = feat_id
				btn.pressed.connect(func():
					if GameManager.grant_feat(fid):
						_refresh_feats()
						_refresh_stats())
				row.add_child(btn)
				var req_parts: Array = []
				for s in stats_req:
					req_parts.append(STAT_ABBREV.get(s, s.to_upper()) + " " + str(stats_req[s]))
				for s in skills_req:
					req_parts.append(SKILL_DISPLAY.get(s, s) + " " + str(skills_req[s]))
				var req_lbl := Label.new()
				req_lbl.text = "  ".join(req_parts)
				req_lbl.add_theme_font_size_override("font_size", 11)
				req_lbl.add_theme_color_override("font_color",
					Color(0.4, 0.8, 0.4) if meets else Color(0.75, 0.35, 0.35))
				req_lbl.custom_minimum_size = Vector2(110, 0)
				req_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				row.add_child(req_lbl)
				_cs_feat_picker_box.add_child(row)
			_cs_feat_picker_box.add_child(HSeparator.new())

	# ── Owned feats list ──────────────────────────────────────────────────────
	for child in _cs_feats_box.get_children():
		child.queue_free()
	var feats: Array = GameManager.player_data.get("feats", [])
	if feats.is_empty():
		var none_lbl := Label.new()
		none_lbl.text = "None"
		none_lbl.add_theme_font_size_override("font_size", 12)
		none_lbl.add_theme_color_override("font_color", Color(0.45, 0.45, 0.50))
		_cs_feats_box.add_child(none_lbl)
		return
	for feat in feats:
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 2)
		var name_lbl := Label.new()
		name_lbl.text = feat.get("name", "?")
		name_lbl.add_theme_font_size_override("font_size", 13)
		name_lbl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))
		row.add_child(name_lbl)
		var desc_lbl := Label.new()
		desc_lbl.text = feat.get("description", "")
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.add_theme_color_override("font_color", Color(0.70, 0.70, 0.75))
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(desc_lbl)
		_cs_feats_box.add_child(row)

func _refresh_bonuses() -> void:
	if _cs_bonuses_vbox == null:
		return
	for child in _cs_bonuses_vbox.get_children():
		child.queue_free()

	var p_live := GameManager.player
	if p_live == null or not is_instance_valid(p_live):
		var empty := Label.new()
		empty.text = "No character data."
		_cs_bonuses_vbox.add_child(empty)
		return

	var armor: Dictionary = p_live.get_total_armor()
	var flat_total: float = armor.get("flat", 0.0)
	var pct_rem: float    = armor.get("pct_remaining", 1.0)
	var all_resist: float = armor.get("all_resist", 0.0)
	var pct_pct: float    = (1.0 - pct_rem) * 100.0
	var buff: Dictionary  = GameManager.player_data.get("active_meal_buff", {})

	# Gather per-item contributions across all equipped slots
	var flat_sources:  Array      = []
	var pct_sources:   Array      = []
	var ar_sources:    Array      = []
	var block_sources: Array      = []
	var carry_sources: Array      = []
	var skill_srcs: Dictionary    = {}   # skill -> [[item_name, bonus]]
	var gov_srcs:   Dictionary    = {}   # skill -> [[item_name, bonus]]
	var block_total: float = 0.0
	var carry_bonus: int   = 0

	for slot in p_live.equipment:
		var item = p_live.equipment[slot]
		if item == null:
			continue
		var iname: String = item.get("name", "?")
		var itype: String = item.get("type", "")

		if itype in ["armor", "clothing", "trinket"]:
			var df: float = item.get("defense_flat", 0.0)
			var dp: float = item.get("defense_pct",  0.0)
			var ar: float = item.get("all_resist",   0.0)
			if df > 0.0: flat_sources.append([iname, df])
			if dp > 0.0: pct_sources.append( [iname, dp * 100.0])
			if ar > 0.0: ar_sources.append(  [iname, ar * 100.0])

		var bf: float = item.get("block_flat", 0.0)
		if bf > 0.0:
			block_total += bf
			block_sources.append([iname, bf])

		var cwb: int = item.get("carry_weight_bonus", 0)
		if cwb > 0:
			carry_bonus += cwb
			carry_sources.append([iname, cwb])

		for sk in item.get("skill_bonus", {}):
			if not skill_srcs.has(sk): skill_srcs[sk] = []
			skill_srcs[sk].append([iname, item["skill_bonus"][sk]])
		for sk in item.get("governing_bonus", {}):
			if not gov_srcs.has(sk): gov_srcs[sk] = []
			gov_srcs[sk].append([iname, item["governing_bonus"][sk]])

	if buff.has("phys_dr_flat"):
		flat_sources.append([buff.get("name", "Meal"), float(buff["phys_dr_flat"])])
	if buff.has("phys_dr_pct"):
		pct_sources.append([buff.get("name", "Meal"), float(buff["phys_dr_pct"]) * 100.0])

	# ── DEFENSE ───────────────────────────────────────────────────────────────
	_cs_bonuses_vbox.add_child(_bonuses_section_hdr("DEFENSE"))

	if flat_total > 0.0:
		_cs_bonuses_vbox.add_child(_bonuses_kv_row("Flat armor", "%.2f" % flat_total))
		for src in flat_sources:
			_cs_bonuses_vbox.add_child(_bonuses_sub_row("  ↳ %s" % src[0], "+%.2f" % src[1]))
	else:
		_cs_bonuses_vbox.add_child(_bonuses_kv_row("Flat armor", "—"))

	if pct_pct > 0.0:
		_cs_bonuses_vbox.add_child(_bonuses_kv_row("% armor", "%.1f%%" % pct_pct))
		for src in pct_sources:
			_cs_bonuses_vbox.add_child(_bonuses_sub_row("  ↳ %s" % src[0], "%.1f%%" % src[1]))

	if all_resist > 0.0:
		_cs_bonuses_vbox.add_child(_bonuses_kv_row("All-dmg resist", "%.1f%%" % (all_resist * 100.0)))
		for src in ar_sources:
			_cs_bonuses_vbox.add_child(_bonuses_sub_row("  ↳ %s" % src[0], "%.1f%%" % src[1]))

	if GameManager.has_feat("bulky"):
		_cs_bonuses_vbox.add_child(_bonuses_kv_row("Bulky (feat)", "−10% all dmg"))
		_cs_bonuses_vbox.add_child(_bonuses_sub_row("  ↳ multiplicative, after armor", ""))

	if block_total > 0.0:
		_cs_bonuses_vbox.add_child(_bonuses_kv_row("Shield block", "%.1f flat" % block_total))
		for src in block_sources:
			_cs_bonuses_vbox.add_child(_bonuses_sub_row("  ↳ %s" % src[0], "%.1f" % src[1]))

	var sep_samp := HSeparator.new(); sep_samp.modulate.a = 0.25
	_cs_bonuses_vbox.add_child(sep_samp)
	var s_raw: int    = 5
	var s_final: float = p_live.calc_damage_received(s_raw)
	_cs_bonuses_vbox.add_child(_bonuses_kv_row(
		"Sample (5 raw phys)",
		"→ %.2f dealt  (%.2f absorbed)" % [s_final, float(s_raw) - s_final]))

	# ── SKILLS & ACCURACY ─────────────────────────────────────────────────────
	var has_skill: bool = not skill_srcs.is_empty() or not gov_srcs.is_empty() or buff.has("hit_flat")
	if has_skill:
		_cs_bonuses_vbox.add_child(_bonuses_section_hdr("SKILLS & ACCURACY"))
		if buff.has("hit_flat"):
			_cs_bonuses_vbox.add_child(_bonuses_kv_row("To-hit", "+%d%%" % int(buff["hit_flat"])))
			_cs_bonuses_vbox.add_child(_bonuses_sub_row("  ↳ %s" % buff.get("name", "Meal"), ""))
		for sk in skill_srcs:
			var total: float = 0.0
			for src in skill_srcs[sk]: total += src[1]
			_cs_bonuses_vbox.add_child(_bonuses_kv_row(
				SKILL_DISPLAY.get(sk, sk.capitalize()), "+%.0f" % total))
			for src in skill_srcs[sk]:
				_cs_bonuses_vbox.add_child(_bonuses_sub_row("  ↳ %s" % src[0], "+%.0f" % src[1]))
		for sk in gov_srcs:
			var total: float = 0.0
			for src in gov_srcs[sk]: total += src[1]
			_cs_bonuses_vbox.add_child(_bonuses_kv_row(
				"%s governing" % SKILL_DISPLAY.get(sk, sk.capitalize()), "+%d mod" % int(total)))
			for src in gov_srcs[sk]:
				_cs_bonuses_vbox.add_child(_bonuses_sub_row("  ↳ %s" % src[0], "+%d mod" % int(src[1])))

	# ── STATS ─────────────────────────────────────────────────────────────────
	var has_stats: bool = buff.has("per_flat") or buff.has("agi_flat") or buff.has("wil_flat")
	if has_stats:
		_cs_bonuses_vbox.add_child(_bonuses_section_hdr("STATS"))
		var meal_name: String = buff.get("name", "Meal")
		if buff.has("per_flat"):
			_cs_bonuses_vbox.add_child(_bonuses_kv_row("Perception", "+%d" % int(buff["per_flat"])))
			_cs_bonuses_vbox.add_child(_bonuses_sub_row("  ↳ %s" % meal_name, ""))
		if buff.has("agi_flat"):
			_cs_bonuses_vbox.add_child(_bonuses_kv_row("Agility", "+%d" % int(buff["agi_flat"])))
			_cs_bonuses_vbox.add_child(_bonuses_sub_row("  ↳ %s" % meal_name, ""))
		if buff.has("wil_flat"):
			_cs_bonuses_vbox.add_child(_bonuses_kv_row("Willpower", "+%d" % int(buff["wil_flat"])))
			_cs_bonuses_vbox.add_child(_bonuses_sub_row("  ↳ %s" % meal_name, ""))

	# ── RESOURCES ─────────────────────────────────────────────────────────────
	var has_res: bool = buff.has("hp_pct") or buff.has("sp_pct") or buff.has("mp_pct")
	if has_res:
		_cs_bonuses_vbox.add_child(_bonuses_section_hdr("RESOURCES"))
		var meal_name_r: String = buff.get("name", "Meal")
		if buff.has("hp_pct"):
			_cs_bonuses_vbox.add_child(_bonuses_kv_row("Max HP", "+%d%%" % int(round(float(buff["hp_pct"]) * 100.0))))
			_cs_bonuses_vbox.add_child(_bonuses_sub_row("  ↳ %s" % meal_name_r, ""))
		if buff.has("sp_pct"):
			_cs_bonuses_vbox.add_child(_bonuses_kv_row("Max SP", "+%d%%" % int(round(float(buff["sp_pct"]) * 100.0))))
			_cs_bonuses_vbox.add_child(_bonuses_sub_row("  ↳ %s" % meal_name_r, ""))
		if buff.has("mp_pct"):
			_cs_bonuses_vbox.add_child(_bonuses_kv_row("Max MP", "+%d%%" % int(round(float(buff["mp_pct"]) * 100.0))))
			_cs_bonuses_vbox.add_child(_bonuses_sub_row("  ↳ %s" % meal_name_r, ""))

	# ── SPIRIT WARD ───────────────────────────────────────────────────────────
	var ward_lvl: int = _player_spirit_ward_level()
	if ward_lvl >= 0:
		_cs_bonuses_vbox.add_child(_bonuses_section_hdr("SPIRIT WARD"))
		_cs_bonuses_vbox.add_child(_bonuses_kv_row("Ward level", "Lv.%d" % ward_lvl))
		_cs_bonuses_vbox.add_child(_bonuses_sub_row("  ↳ %s" % _player_spirit_ward_name(), ""))

	# ── OTHER (carry weight, etc.) ────────────────────────────────────────────
	if carry_bonus > 0:
		_cs_bonuses_vbox.add_child(_bonuses_section_hdr("OTHER"))
		_cs_bonuses_vbox.add_child(_bonuses_kv_row("Carry capacity", "+%d" % carry_bonus))
		for src in carry_sources:
			_cs_bonuses_vbox.add_child(_bonuses_sub_row("  ↳ %s" % src[0], "+%d" % src[1]))

	# ── FEATS ─────────────────────────────────────────────────────────────────
	var owned_feats: Array = GameManager.player_data.get("feats", [])
	if not owned_feats.is_empty():
		_cs_bonuses_vbox.add_child(_bonuses_section_hdr("FEATS"))
		for f in owned_feats:
			var fn_lbl := Label.new()
			fn_lbl.text = f.get("name", "?")
			fn_lbl.add_theme_font_size_override("font_size", 13)
			fn_lbl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))
			_cs_bonuses_vbox.add_child(fn_lbl)
			var fd_lbl := Label.new()
			fd_lbl.text = f.get("description", "")
			fd_lbl.add_theme_font_size_override("font_size", 11)
			fd_lbl.add_theme_color_override("font_color", Color(0.70, 0.70, 0.75))
			fd_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			fd_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_cs_bonuses_vbox.add_child(fd_lbl)

	# ── ACTIVE MEAL ───────────────────────────────────────────────────────────
	_cs_bonuses_vbox.add_child(_bonuses_section_hdr("ACTIVE MEAL"))
	if buff.is_empty():
		var none_lbl := Label.new()
		none_lbl.text = "None"
		none_lbl.add_theme_font_size_override("font_size", 12)
		none_lbl.add_theme_color_override("font_color", Color(0.45, 0.45, 0.50))
		_cs_bonuses_vbox.add_child(none_lbl)
	else:
		var meal_hdr := Label.new()
		meal_hdr.text = buff.get("name", "Unknown")
		meal_hdr.add_theme_font_size_override("font_size", 13)
		meal_hdr.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))
		_cs_bonuses_vbox.add_child(meal_hdr)
		for line in DataManager.format_meal_buff_lines(buff):
			var ml := Label.new()
			ml.text = "  • " + line
			ml.add_theme_font_size_override("font_size", 12)
			ml.add_theme_color_override("font_color", Color(0.75, 0.75, 0.80))
			_cs_bonuses_vbox.add_child(ml)


func _bonuses_section_hdr(text: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	var sep := HSeparator.new()
	sep.modulate.a = 0.4
	box.add_child(sep)
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color(0.55, 0.75, 0.95))
	box.add_child(lbl)
	return box


func _bonuses_kv_row(key: String, val: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var k := Label.new()
	k.text = key
	k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	k.add_theme_font_size_override("font_size", 12)
	row.add_child(k)
	var v := Label.new()
	v.text = val
	v.add_theme_font_size_override("font_size", 12)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(v)
	return row


func _bonuses_sub_row(left: String, right: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var k := Label.new()
	k.text = left
	k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	k.add_theme_font_size_override("font_size", 11)
	k.add_theme_color_override("font_color", Color(0.52, 0.52, 0.58))
	row.add_child(k)
	if right != "":
		var v := Label.new()
		v.text = right
		v.add_theme_font_size_override("font_size", 11)
		v.add_theme_color_override("font_color", Color(0.52, 0.52, 0.58))
		v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(v)
	return row


func _refresh_map() -> void:
	var layer_names = ["Surface", "Underground I", "Underground II"]
	_map_layer_lbl.text = "%s (Layer %d)" % [layer_names[_map_layer], _map_layer]

	var explored = GameManager.explored_tiles.get(_map_layer, {})

	for row in range(MAP_ROWS):
		for col in range(MAP_COLS):
			var tile_pos = Vector2i(col, row)
			var idx = row * MAP_COLS + col
			var sbox: StyleBoxFlat = _map_cell_styles[idx]
			var icon: _MapThumb = _map_cell_icons[idx]

			var is_current = (tile_pos == GameManager.world_pos and _map_layer == GameManager.world_layer)
			var tile_info = explored.get(tile_pos, {})
			var is_visited = tile_info.get("visited", false)
			var td = GameManager.get_tile_data(_map_layer, tile_pos)

			if is_current:
				sbox.bg_color = Color(0.65, 0.55, 0.15)
				sbox.border_width_top    = 2
				sbox.border_width_bottom = 2
				sbox.border_width_left   = 2
				sbox.border_width_right  = 2
				sbox.border_color = Color(1.0, 0.9, 0.4)
				icon.ttype = td.get("thumbnail_type", "")
				icon.scene_path = td.get("scene", "")
				icon.is_current = true
				icon.queue_redraw()
			elif is_visited and not td.is_empty():
				var ttype = td.get("thumbnail_type", "")
				sbox.bg_color = _thumbnail_color(ttype)
				sbox.border_width_top    = 0
				sbox.border_width_bottom = 0
				sbox.border_width_left   = 0
				sbox.border_width_right  = 0
				icon.ttype = ttype
				icon.scene_path = td.get("scene", "")
				icon.is_current = false
				icon.queue_redraw()
			else:
				sbox.bg_color = Color(0.08, 0.08, 0.12)
				sbox.border_width_top    = 0
				sbox.border_width_bottom = 0
				sbox.border_width_left   = 0
				sbox.border_width_right  = 0
				icon.ttype = ""
				icon.scene_path = ""
				icon.is_current = false
				icon.queue_redraw()

func _thumbnail_color(ttype: String) -> Color:
	match ttype:
		"town":        return Color(0.45, 0.30, 0.15)
		"city":        return Color(0.50, 0.40, 0.28)
		"slums":       return Color(0.32, 0.22, 0.18)
		"plains":      return Color(0.25, 0.42, 0.18)
		"wilderness":  return Color(0.30, 0.38, 0.20)
		"desert":      return Color(0.55, 0.45, 0.20)
		"ruins":       return Color(0.35, 0.35, 0.30)
		_:
			if ttype.begins_with("tunnel_"):
				return Color(0.14, 0.16, 0.20)
			return Color(0.25, 0.25, 0.30)

class _MapThumb extends Control:
	var ttype: String = ""
	var scene_path: String = ""
	var is_current: bool = false

	static var _scene_cache: Dictionary = {}

	const _FLOOR       := Color(0.42, 0.35, 0.22, 1.0)
	const _BUILD       := Color(0.15, 0.12, 0.09, 0.80)
	const _TREE        := Color(0.14, 0.30, 0.10, 0.80)
	const _ROCK        := Color(0.18, 0.15, 0.11, 0.75)
	const _WALL        := Color(0.20, 0.17, 0.13, 0.75)
	const _DEFAULT_TOP := Color(0.62, 0.57, 0.50, 1.0)
	const _DEFAULT_OUT := Color(0.18, 0.12, 0.08, 1.0)
	const _PIT_COL     := Color(0.04, 0.03, 0.06, 1.0)

	# Extract the id="…" value from an [ext_resource …] line.
	static func _res_id(line: String) -> String:
		var idx: int = line.rfind(" id=\"") + 5
		if idx < 5:
			return ""
		var end: int = line.find("\"", idx)
		return line.substr(idx, end - idx) if end > idx else ""

	# Parse a .tscn and return Dicts describing Building and TunnelEntrance nodes.
	# Cached by path so each file is read at most once per session.
	static func _parse_scene(path: String) -> Array:
		if _scene_cache.has(path):
			return _scene_cache[path]
		var f := FileAccess.open(path, FileAccess.READ)
		if f == null:
			_scene_cache[path] = []
			return []
		var text := f.get_as_text()
		f.close()

		var res_map: Dictionary = {}   # id → "building" | "tunnel_entrance"
		var entries: Array = []
		var cur: Dictionary = {}
		var in_node := false
		var cur_type := ""

		for raw in text.split("\n"):
			var line := raw.strip_edges()

			if line.begins_with("[ext_resource "):
				var rid := _res_id(line)
				if rid != "":
					if "building.gd" in line:
						res_map[rid] = "building"
					elif "tunnel_entrance.gd" in line:
						res_map[rid] = "tunnel_entrance"

			elif line.begins_with("[node "):
				if in_node:
					if cur_type == "building" and cur.has_all(["X1","X2","Y1","Y2"]):
						entries.append(cur.duplicate())
					elif cur_type == "tunnel_entrance":
						entries.append(cur.duplicate())
				cur = {}
				cur_type = ""
				in_node = true

			elif in_node:
				if line.begins_with("script = ExtResource(\""):
					var qs: int = line.find("\"") + 1
					var qe: int = line.find("\"", qs)
					if qe > qs:
						cur_type = res_map.get(line.substr(qs, qe - qs), "")
						if cur_type == "tunnel_entrance":
							cur["type"] = "tunnel_entrance"
							cur["full_circle"] = false
				elif line.begins_with("full_circle = "):
					cur["full_circle"] = line.substr(14).strip_edges() == "true"
				elif line.begins_with("X1 = "):
					cur["X1"] = int(line.substr(5))
				elif line.begins_with("X2 = "):
					cur["X2"] = int(line.substr(5))
				elif line.begins_with("Y1 = "):
					cur["Y1"] = int(line.substr(5))
				elif line.begins_with("Y2 = "):
					cur["Y2"] = int(line.substr(5))
				elif line.begins_with("col_top = Color("):
					var s := line.substr(16).trim_suffix(")")
					var p := s.split(",")
					if p.size() >= 3:
						cur["col_top"] = Color(float(p[0]), float(p[1]), float(p[2]))
				elif line.begins_with("col_out = Color("):
					var s := line.substr(16).trim_suffix(")")
					var p := s.split(",")
					if p.size() >= 3:
						cur["col_out"] = Color(float(p[0]), float(p[1]), float(p[2]))

		if in_node:
			if cur_type == "building" and cur.has_all(["X1","X2","Y1","Y2"]):
				entries.append(cur.duplicate())
			elif cur_type == "tunnel_entrance":
				entries.append(cur.duplicate())

		_scene_cache[path] = entries
		return entries

	func _draw() -> void:
		var w := size.x
		var h := size.y

		if scene_path != "":
			var entries := _parse_scene(scene_path)
			if not entries.is_empty():
				var sx: float = w / 80.0
				var sy: float = h / 80.0
				for e in entries:
					if e.get("type", "") == "tunnel_entrance":
						var cx_px: float = 40.0 * sx
						var cy_px: float = 40.0 * sy
						var center := Vector2(cx_px, cy_px)
						var pit_r:  float = 22.0 * sx
						var wall_r: float = 32.5 * sx   # midpoint of wall ring (30–35)
						var full: bool = e.get("full_circle", false)
						var wall_col: Color = _DEFAULT_TOP if not is_current else _DEFAULT_OUT
						draw_circle(center, pit_r, _PIT_COL)
						var arc_end: float = TAU if full else PI
						draw_arc(center, wall_r, 0.0, arc_end, 20, wall_col, 2.0)
					else:
						var col: Color = e.get("col_out", _DEFAULT_OUT) if is_current \
								else e.get("col_top", _DEFAULT_TOP)
						var rx: float = (e["X1"] as int) * sx
						var ry: float = (e["Y1"] as int) * sy
						var rw: float = maxf(((e["X2"] as int) - (e["X1"] as int) + 1) * sx, 1.0)
						var rh: float = maxf(((e["Y2"] as int) - (e["Y1"] as int) + 1) * sy, 1.0)
						draw_rect(Rect2(rx, ry, rw, rh), col)
				return

		if ttype == "":
			return
		var cx := w * 0.5
		var cy := h * 0.5
		var cw := 3.0

		match ttype:
			# ── underground tunnels ──────────────────────────────────────────
			"tunnel_ns":
				draw_rect(Rect2(cx - cw, 0, cw * 2, h), _FLOOR)
			"tunnel_ew":
				draw_rect(Rect2(0, cy - cw, w, cw * 2), _FLOOR)
			"tunnel_x":
				draw_rect(Rect2(cx - cw, 0, cw * 2, h), _FLOOR)
				draw_rect(Rect2(0, cy - cw, w, cw * 2), _FLOOR)
			"tunnel_te":
				draw_rect(Rect2(cx - cw, 0, cw * 2, h), _FLOOR)
				draw_rect(Rect2(cx, cy - cw, w - cx, cw * 2), _FLOOR)
			"tunnel_tw":
				draw_rect(Rect2(cx - cw, 0, cw * 2, h), _FLOOR)
				draw_rect(Rect2(0, cy - cw, cx + cw, cw * 2), _FLOOR)
			"tunnel_ts":
				draw_rect(Rect2(0, cy - cw, w, cw * 2), _FLOOR)
				draw_rect(Rect2(cx - cw, cy, cw * 2, h - cy), _FLOOR)
			"tunnel_tn":
				draw_rect(Rect2(0, cy - cw, w, cw * 2), _FLOOR)
				draw_rect(Rect2(cx - cw, 0, cw * 2, cy + cw), _FLOOR)
			"tunnel_ne":
				draw_rect(Rect2(cx - cw, 0, cw * 2, cy + cw), _FLOOR)
				draw_rect(Rect2(cx, cy - cw, w - cx, cw * 2), _FLOOR)
			"tunnel_nw":
				draw_rect(Rect2(cx - cw, 0, cw * 2, cy + cw), _FLOOR)
				draw_rect(Rect2(0, cy - cw, cx + cw, cw * 2), _FLOOR)
			"tunnel_se":
				draw_rect(Rect2(cx - cw, cy - cw, cw * 2, h - cy + cw), _FLOOR)
				draw_rect(Rect2(cx, cy - cw, w - cx, cw * 2), _FLOOR)
			"tunnel_sw":
				draw_rect(Rect2(cx - cw, cy - cw, cw * 2, h - cy + cw), _FLOOR)
				draw_rect(Rect2(0, cy - cw, cx + cw, cw * 2), _FLOOR)
			# ── surface zones ────────────────────────────────────────────────
			"town", "city":
				var count := 5 if ttype == "city" else 4
				_draw_buildings(w, h, count)
			"slums":
				_draw_buildings(w, h, 3)
				draw_rect(Rect2(1, cy - 1, w - 2, 1), _ROCK)
			"wilderness":
				for p in [Vector2(2,3), Vector2(w-6,2), Vector2(3,h-6), Vector2(w-5,h-5), Vector2(cx-2,cy-2)]:
					draw_rect(Rect2(p.x, p.y, 3, 3), _TREE)
			"desert":
				for p in [Vector2(3,4), Vector2(w-7,3), Vector2(3,h-7), Vector2(w-6,h-6)]:
					draw_rect(Rect2(p.x, p.y, 4, 2), _ROCK)
			"ruins":
				draw_rect(Rect2(1,         1,         w * 0.4, 2), _WALL)
				draw_rect(Rect2(w * 0.6,   1,         w * 0.4 - 1, 2), _WALL)
				draw_rect(Rect2(1,         h - 3,     w * 0.35, 2), _WALL)
				draw_rect(Rect2(w * 0.65,  h - 3,     w * 0.35 - 1, 2), _WALL)
				draw_rect(Rect2(1,         1,         2,  h * 0.4), _WALL)
				draw_rect(Rect2(1,         h * 0.6,   2,  h * 0.4 - 1), _WALL)
			"plains":
				for i in range(3):
					draw_rect(Rect2(2 + i * (w / 3.5), h * 0.35, w / 5.0, 1), _TREE)

	func _draw_buildings(w: float, h: float, count: int) -> void:
		var spots := [
			Vector2(1,       1),
			Vector2(w - 7,   1),
			Vector2(1,       h - 7),
			Vector2(w - 7,   h - 7),
			Vector2(w * 0.5 - 3, h * 0.5 - 3),
		]
		for i in range(min(count, spots.size())):
			draw_rect(Rect2(spots[i].x, spots[i].y, 5, 5), _BUILD)

func _build_map_tooltip() -> Control:
	var panel = PanelContainer.new()
	panel.z_index = 100
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.18, 0.97)
	style.border_width_left   = 1
	style.border_width_right  = 1
	style.border_width_top    = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.45, 0.45, 0.55)
	style.content_margin_left   = 10
	style.content_margin_right  = 10
	style.content_margin_top    = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)

	_map_tooltip_lbl = Label.new()
	_map_tooltip_lbl.add_theme_font_size_override("font_size", 13)
	panel.add_child(_map_tooltip_lbl)

	return panel

func _build_hover_tooltip() -> Control:
	var panel = PanelContainer.new()
	panel.z_index = 200
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.06, 0.10, 0.92)
	style.corner_radius_top_left     = 4
	style.corner_radius_top_right    = 4
	style.corner_radius_bottom_left  = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left   = 8
	style.content_margin_right  = 8
	style.content_margin_top    = 4
	style.content_margin_bottom = 4
	panel.add_theme_stylebox_override("panel", style)
	var lbl = Label.new()
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.name = "Label"
	panel.add_child(lbl)
	return panel

func _on_entity_hovered(entity: Node) -> void:
	if _hover_tooltip == null:
		return
	if entity == null:
		_hover_tooltip.visible = false
		return
	var name_text: String = entity.get("entity_name") if entity.get("entity_name") != null else "???"
	var lbl: Label = _hover_tooltip.get_node("Label")

	if CombatManager.has_pending_weapon() and entity != GameManager.player:
		var weapon: Dictionary = CombatManager.pending_weapon
		var w_range: int = weapon.get("range", 1)
		var has_long_ranged: bool = w_range > 1 and GameManager.has_feat("long_ranged")
		var effective_range: int = w_range * 2 if has_long_ranged else w_range
		var player_typed: Player = GameManager.player as Player
		if player_typed != null and entity.get("grid_cell") != null:
			var entity_cell: Vector2i = entity.get("grid_cell")
			var dx: int = player_typed.grid_cell.x - entity_cell.x
			var dy: int = player_typed.grid_cell.y - entity_cell.y
			var dist: float = sqrt(float(dx * dx + dy * dy))
			if dist > float(effective_range):
				lbl.text = "%s\nOut of Range" % name_text
			else:
				var skill: String = weapon.get("skill", "melee")
				var w_props: Array = weapon.get("properties", [])
				var mod_adj: int = -1 if "clumsy" in w_props else 0
				var pct: int = CombatManager.calc_hit_chance(GameManager.player, entity, skill, 0, mod_adj)
				if has_long_ranged and dist > float(w_range):
					var fraction: float = clampf((dist - float(w_range)) / float(w_range), 0.0, 1.0)
					pct = clampi(int(float(pct) * (1.0 - fraction * 0.5)), 5, 95)
					lbl.text = "%s\nLong Range — Hit: %d%%" % [name_text, pct]
				else:
					lbl.text = "%s\nHit: %d%%" % [name_text, pct]
		else:
			lbl.text = name_text
	else:
		lbl.text = name_text

	var mp := get_viewport().get_mouse_position()
	_hover_tooltip.position = mp + Vector2(14, -28)
	_hover_tooltip.visible = true

func _on_map_cell_hover(tile_pos: Vector2i) -> void:
	if _map_tooltip == null:
		return
	var td = GameManager.get_tile_data(_map_layer, tile_pos)
	if td.is_empty():
		return
	var is_current = (tile_pos == GameManager.world_pos and _map_layer == GameManager.world_layer)
	var explored = GameManager.explored_tiles.get(_map_layer, {}).get(tile_pos, {})
	if not explored.get("visited", false) and not is_current:
		return

	var text = td.get("label", "Unknown")
	var encounters: Array = explored.get("encounters", [])
	if not encounters.is_empty():
		text += "\n──────────"
		for enc in encounters:
			text += "\n• " + enc

	_map_tooltip_lbl.text = text
	_map_tooltip.visible = true

	var idx = tile_pos.y * MAP_COLS + tile_pos.x
	var cell_rect = (_map_cells[idx] as Control).get_global_rect()
	var vp_size = get_viewport().get_visible_rect().size
	_map_tooltip.position = Vector2(
		clamp(cell_rect.position.x + MAP_CELL + 6, 0, vp_size.x - 180),
		clamp(cell_rect.position.y, 0, vp_size.y - 80)
	)

func _on_map_cell_exit() -> void:
	if _map_tooltip != null:
		_map_tooltip.visible = false

# ── Helpers ────────────────────────────────────────────────────────────────────
func _best_mod(skill: String, stats: Dictionary) -> int:
	var s = func(k): return stats.get(k, 5) - 5
	match skill:
		"melee","ranged":               return max(s.call("strength"), s.call("dexterity"))
		"convince":                     return s.call("willpower")
		"intimidate":                   return max(s.call("strength"), s.call("willpower"))
		"dodge":                         return max(s.call("dexterity"), s.call("agility"))
		"sneak","sleight_of_hand":        return s.call("dexterity")
		"alchemy":                      return s.call("intelligence")
		"occultism":                    return max(s.call("intelligence"), s.call("willpower"))
		"smithing":                     return max(s.call("intelligence"), s.call("strength"))
		"survival":                     return max(s.call("constitution"), s.call("willpower"), s.call("perception"))
	return 0

func _equip_skill_bonus(skill: String) -> int:
	var equip: Dictionary = GameManager.player_data.get("equipment", {})
	var total: int = 0
	for slot in equip:
		var item = equip[slot]
		if item == null: continue
		total += item.get("skill_bonus", {}).get(skill, 0)
	return total

func _equip_gov_bonus(skill: String) -> int:
	var equip: Dictionary = GameManager.player_data.get("equipment", {})
	var total: int = 0
	for slot in equip:
		var item = equip[slot]
		if item == null: continue
		total += item.get("governing_bonus", {}).get(skill, 0)
	return total

func _fmt(val: float) -> String:
	return str(int(val)) if val == floorf(val) else "%.1f" % val

# ══════════════════════════════════════════════════════════════════════════════
# PICKPOCKET PANEL
# ══════════════════════════════════════════════════════════════════════════════
func _build_pickpocket_panel() -> Control:
	var root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	root.offset_top = -260
	root.mouse_filter = Control.MOUSE_FILTER_STOP

	var bg = ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.04, 0.07, 0.96)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)

	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 20)
	root.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	_pickpocket_title_lbl = Label.new()
	_pickpocket_title_lbl.add_theme_font_size_override("font_size", 18)
	vbox.add_child(_pickpocket_title_lbl)

	vbox.add_child(HSeparator.new())

	_pickpocket_body_lbl = Label.new()
	_pickpocket_body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_pickpocket_body_lbl.add_theme_font_size_override("font_size", 14)
	_pickpocket_body_lbl.add_theme_color_override("font_color", Color(0.85, 0.75, 0.65))
	vbox.add_child(_pickpocket_body_lbl)

	_pickpocket_items_box = VBoxContainer.new()
	_pickpocket_items_box.add_theme_constant_override("separation", 4)
	vbox.add_child(_pickpocket_items_box)

	vbox.add_child(HSeparator.new())

	_pickpocket_close_btn = Button.new()
	_pickpocket_close_btn.text = "Back away"
	_pickpocket_close_btn.custom_minimum_size = Vector2(120, 32)
	_pickpocket_close_btn.pressed.connect(_on_pickpocket_close)
	vbox.add_child(_pickpocket_close_btn)

	return root

func _do_pickpocket(entity: Node) -> void:
	_close_all()
	_pickpocket_entity = entity

	var pd: Dictionary = GameManager.player_data
	var skills: Dictionary = pd.get("skills", {})
	var stats: Dictionary = pd.get("stats", {})

	var sleight: int = int(skills.get("sleight_of_hand", 0))
	var dex_mod: int = stats.get("dexterity", 5) - 5
	var eff_sleight: float = sleight * (1.0 + dex_mod * 0.1)

	var npc_per: int = entity.get("stat_perception") if entity.get("stat_perception") != null else 5
	var per_mod: int = npc_per - 5
	var eff_per: float = npc_per * (1.0 + per_mod * 0.1)

	var success_chance: int = clampi(50 + int((eff_sleight - eff_per) * 2.0), 5, 95)
	var die: int = randi_range(1, 100)

	var pocket: Array = entity.get("pocket_items") if entity.get("pocket_items") != null else []

	if die <= success_chance:
		_open_pickpocket_success(entity, pocket)
	elif die >= 91:
		entity.set("_pickpocket_caught", true)
		# Show result first; hostile NPCs (is_hostile-capable types) will engage on next action
		_open_pickpocket_result(entity, true)
	else:
		entity.set("_pickpocket_caught", true)
		_open_pickpocket_result(entity, false)

func _on_pickpocket_close() -> void:
	var ent: Node = _pickpocket_entity
	var fight: bool = _pickpocket_fight_on_close
	_pickpocket_fight_on_close = false
	_close_all()
	if fight and is_instance_valid(ent):
		ent.go_hostile()

func _open_pickpocket_success(entity: Node, pocket: Array) -> void:
	var npc_name: String = entity.get("entity_name") if entity.get("entity_name") != null else "them"
	_pickpocket_title_lbl.text = "%s's Pockets" % npc_name
	_pickpocket_body_lbl.visible = pocket.is_empty()
	_pickpocket_body_lbl.text = "Their pockets are empty."
	_pickpocket_items_box.visible = not pocket.is_empty()
	_pickpocket_fight_on_close = false
	_pickpocket_close_btn.text = "Back away"

	for child in _pickpocket_items_box.get_children():
		child.free()

	for i in range(pocket.size()):
		var item: Dictionary = pocket[i]
		var row := HBoxContainer.new()
		var lbl := Label.new()
		lbl.text = item.get("name", "Unknown Item")
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)
		var take_btn := Button.new()
		take_btn.text = "Take"
		var cap_item: Dictionary = item
		var cap_i: int = i
		take_btn.pressed.connect(func(): _take_pickpocket_item(entity, cap_item, cap_i))
		row.add_child(take_btn)
		_pickpocket_items_box.add_child(row)

	_pickpocket_panel.visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP

func _take_pickpocket_item(entity: Node, item: Dictionary, idx: int) -> void:
	var inv: Array = GameManager.player_data.get("inventory", [])
	inv.append(item.duplicate())
	GameManager.player_data["inventory"] = inv
	EventBus.inventory_changed.emit()

	var pocket: Array = entity.get("pocket_items")
	if pocket != null and idx < pocket.size():
		pocket.remove_at(idx)

	_close_all()

func _open_pickpocket_result(entity: Node, critical: bool) -> void:
	var npc_name: String = entity.get("entity_name") if entity.get("entity_name") != null else "them"
	_pickpocket_title_lbl.text = "Caught!"
	_pickpocket_body_lbl.visible = true
	_pickpocket_items_box.visible = false
	_pickpocket_fight_on_close = true
	if critical:
		_pickpocket_body_lbl.text = "*%s grabs your wrist.* Get away from me!" % npc_name
		_pickpocket_close_btn.text = "Break free"
	else:
		_pickpocket_body_lbl.text = "*%s notices your hand near their pocket and steps back.* Don't touch me." % npc_name
		_pickpocket_close_btn.text = "Back away"
	_pickpocket_panel.visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP

# ══════════════════════════════════════════════════════════════════════════════
# DREAM PANEL
# ══════════════════════════════════════════════════════════════════════════════
func _build_dream_panel() -> Control:
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.01, 0.03, 0.97)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(600, 0)
	vbox.add_theme_constant_override("separation", 40)
	center.add_child(vbox)

	_dream_text_lbl = Label.new()
	_dream_text_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dream_text_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dream_text_lbl.add_theme_font_size_override("font_size", 18)
	_dream_text_lbl.add_theme_color_override("font_color", Color(0.85, 0.80, 0.70))
	vbox.add_child(_dream_text_lbl)

	_dream_continue_btn = Button.new()
	_dream_continue_btn.text = "Continue"
	_dream_continue_btn.pressed.connect(_dream_advance)
	vbox.add_child(_dream_continue_btn)

	return bg

func _open_dream() -> void:
	_dream_beat_idx = 0
	_dream_text_lbl.text = DREAM_BEATS[0]
	_dream_continue_btn.text = "Continue"
	_dream_panel.visible = true

func _dream_advance() -> void:
	_dream_beat_idx += 1
	if _dream_beat_idx >= DREAM_BEATS.size():
		_dream_panel.visible = false
		_dream_finish()
		return
	_dream_text_lbl.text = DREAM_BEATS[_dream_beat_idx]
	if _dream_beat_idx == DREAM_BEATS.size() - 1:
		_dream_continue_btn.text = "Wake up"

func _dream_finish() -> void:
	GameManager.player_data["dream_seen"] = true
	GameManager.add_quest({
		"id":          "the_dream",
		"title":       "The Dream",
		"description": "I had a dream. I don't know what it was — but it felt real. Something about the city. Something vast underneath it.",
		"threads":     [],
		"completed":   false,
	})
	var contacts: Array = GameManager.player_data.get("faction_contacts", [])
	for contact_id in contacts:
		var thread_def: Dictionary = DREAM_CONTACT_THREADS.get(contact_id, {})
		if thread_def.is_empty():
			continue
		GameManager.add_quest_thread("the_dream", {
			"id":          thread_def["id"],
			"title":       thread_def["title"],
			"description": thread_def["title"],
			"updates":     [],
			"completed":   false,
		})
	GameManager.add_xp(50)
	EventBus.note_added.emit("the_dream", "The Dream")
	GameManager.auto_save()

# ══════════════════════════════════════════════════════════════════════════════
# ABILITIES PANEL
# ══════════════════════════════════════════════════════════════════════════════
func _build_abilities_panel() -> Control:
	var shell := _make_panel_shell("ABILITIES")
	var vbox: VBoxContainer = shell["vbox"]

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	_abilities_vbox = VBoxContainer.new()
	_abilities_vbox.add_theme_constant_override("separation", 12)
	_abilities_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_abilities_vbox)

	return shell["root"]

func _refresh_abilities() -> void:
	if _abilities_vbox == null:
		return
	for child in _abilities_vbox.get_children():
		child.queue_free()

	var pd: Dictionary = GameManager.player_data
	var spells: Array = pd.get("spells", [])
	var feats: Array  = pd.get("feats", [])

	if spells.is_empty() and feats.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "No abilities yet."
		empty_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.60))
		_abilities_vbox.add_child(empty_lbl)
		return

	if not spells.is_empty():
		var hdr := Label.new()
		hdr.text = "SPELLS"
		hdr.add_theme_font_size_override("font_size", 13)
		hdr.add_theme_color_override("font_color", Color(0.65, 0.55, 0.85))
		_abilities_vbox.add_child(hdr)
		_abilities_vbox.add_child(HSeparator.new())

		for raw_id in spells:
			var spell: Dictionary = DataManager.get_item(str(raw_id))
			if spell.is_empty():
				continue
			_abilities_vbox.add_child(_make_ability_card(spell, true))

	if not feats.is_empty():
		if not spells.is_empty():
			_abilities_vbox.add_child(HSeparator.new())
		var hdr2 := Label.new()
		hdr2.text = "FEATS"
		hdr2.add_theme_font_size_override("font_size", 13)
		hdr2.add_theme_color_override("font_color", Color(0.85, 0.75, 0.45))
		_abilities_vbox.add_child(hdr2)
		_abilities_vbox.add_child(HSeparator.new())

		for feat in feats:
			_abilities_vbox.add_child(_make_ability_card(feat, false))

func _make_ability_card(entry: Dictionary, is_spell: bool) -> Control:
	var card := PanelContainer.new()
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.10, 0.09, 0.15, 0.90)
	card_style.set_corner_radius_all(4)
	card_style.border_width_left = 1; card_style.border_width_right = 1
	card_style.border_width_top = 1; card_style.border_width_bottom = 1
	card_style.border_color = Color(0.28, 0.24, 0.40)
	card_style.content_margin_left = 12; card_style.content_margin_right = 12
	card_style.content_margin_top = 8; card_style.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", card_style)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 4)
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(inner)

	var name_lbl := Label.new()
	name_lbl.text = entry.get("name", "Unknown")
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", Color(0.92, 0.88, 0.98))
	inner.add_child(name_lbl)

	if is_spell:
		var ap: int = entry.get("ap_cost", 0)
		var sp: int = entry.get("spirit_cost", 0)
		var rng: int = entry.get("range", 1)
		var stats_lbl := Label.new()
		stats_lbl.text = "%d AP  •  %d SP  •  Range %d" % [ap, sp, rng]
		stats_lbl.add_theme_font_size_override("font_size", 12)
		stats_lbl.add_theme_color_override("font_color", Color(0.65, 0.75, 0.90))
		inner.add_child(stats_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = entry.get("description", "")
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_size_override("font_size", 13)
	desc_lbl.add_theme_color_override("font_color", Color(0.72, 0.70, 0.75))
	desc_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_child(desc_lbl)

	return card

# ══════════════════════════════════════════════════════════════════════════════
# JOURNAL BADGE
# ══════════════════════════════════════════════════════════════════════════════
func _make_dot_badge(size: int, color: Color) -> Panel:
	var bg := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = color
	var r: int = size / 2
	style.corner_radius_top_left    = r
	style.corner_radius_top_right   = r
	style.corner_radius_bottom_left  = r
	style.corner_radius_bottom_right = r
	bg.add_theme_stylebox_override("panel", style)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.visible = false
	return bg

func _attach_journal_badge(btn: Button) -> void:
	var bg := _make_dot_badge(12, Color(0.82, 0.15, 0.15))
	# 12×12 circle anchored to top-right corner of the toolbar button
	bg.set_anchor_and_offset(SIDE_LEFT,   1.0, -14)
	bg.set_anchor_and_offset(SIDE_RIGHT,  1.0,  -2)
	bg.set_anchor_and_offset(SIDE_TOP,    0.0,   2)
	bg.set_anchor_and_offset(SIDE_BOTTOM, 0.0,  14)
	btn.add_child(bg)
	_journal_badge_bg = bg

func _on_journal_updated(kind: String) -> void:
	if kind == "quest":
		_journal_quest_unread += 1
	else:
		_journal_notes_unread += 1

	if _open == "journal":
		# Journal is open — show the tab dot for the tab that isn't currently active
		if kind == "quest" and _journal_tab != "quests" and _journal_quest_dot != null:
			_journal_quest_dot.visible = true
		elif kind == "note" and _journal_tab != "notes" and _journal_notes_dot != null:
			_journal_notes_dot.visible = true
		return

	_journal_unread += 1
	if _journal_badge_bg != null:
		_journal_badge_bg.visible = true

# ══════════════════════════════════════════════════════════════════════════════
func _info_pair(parent: Control, label: String, default: String) -> Label:
	var col = VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	var lbl = Label.new(); lbl.text = label
	lbl.add_theme_font_size_override("font_size", 11)
	col.add_child(lbl)
	var val = Label.new(); val.text = default
	val.add_theme_font_size_override("font_size", 16)
	col.add_child(val)
	parent.add_child(col)
	return val
