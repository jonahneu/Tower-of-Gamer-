extends Control

var _load_overlay: Control = null

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg = ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.05, 0.08)
	add_child(bg)

	# Centered column
	var center = VBoxContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	center.grow_horizontal = Control.GROW_DIRECTION_BOTH
	center.grow_vertical   = Control.GROW_DIRECTION_BOTH
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 14)
	add_child(center)

	var title = Label.new()
	title.text = "PLACEHOLDER TITLE"
	title.add_theme_font_size_override("font_size", 52)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(title)

	_spacer(center, 30)

	_btn(center, "NEW GAME",  _on_new_game)
	_btn(center, "CONTINUE",  _on_continue, not GameManager.has_any_save())
	_btn(center, "OPTIONS",   _on_options,  true)   # greyed — not yet built
	_btn(center, "QUIT",      _on_quit)

func _btn(parent: Control, label: String, cb: Callable, disabled: bool = false) -> void:
	var b = Button.new()
	b.text = label
	b.custom_minimum_size = Vector2(220, 52)
	b.disabled = disabled
	b.pressed.connect(cb)
	parent.add_child(b)

func _spacer(parent: Control, h: int) -> void:
	var s = Control.new()
	s.custom_minimum_size = Vector2(0, h)
	parent.add_child(s)

func _on_new_game() -> void:
	get_tree().change_scene_to_file("res://scenes/character_creation/character_creation.tscn")

func _on_continue() -> void:
	var best = _most_recent_save_slot()
	if best >= 0:
		_load_slot(best)

func _most_recent_save_slot() -> int:
	var all_slots: Array = [GameManager.AUTO_SLOT, GameManager.PREV_AUTO_SLOT,
		0, GameManager.PREV_QUICK_SLOT]
	for i in range(1, GameManager.SLOT_COUNT + 1):
		all_slots.append(i)
	var best_slot: int = -1
	var best_ts: String = ""
	for slot in all_slots:
		var info: Dictionary = GameManager.get_save_info(slot)
		if info["exists"] and info["timestamp"] > best_ts:
			best_ts = info["timestamp"]
			best_slot = slot
	return best_slot

func _build_load_overlay() -> Control:
	var overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	var bg = ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.0, 0.85)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(bg)

	var centerer = CenterContainer.new()
	centerer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(centerer)

	var card = VBoxContainer.new()
	card.add_theme_constant_override("separation", 12)
	card.custom_minimum_size = Vector2(640, 0)
	centerer.add_child(card)

	# Header
	var header = HBoxContainer.new()
	card.add_child(header)
	var title_lbl = Label.new()
	title_lbl.text = "LOAD GAME"
	title_lbl.add_theme_font_size_override("font_size", 24)
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_lbl)
	var back_btn = Button.new()
	back_btn.text = "✕  Back"
	back_btn.pressed.connect(func(): overlay.visible = false)
	header.add_child(back_btn)

	card.add_child(HSeparator.new())

	# All slots, most recently saved first; empty slots sink to the bottom.
	var display_slots: Array = [GameManager.AUTO_SLOT, GameManager.PREV_AUTO_SLOT,
		0, GameManager.PREV_QUICK_SLOT]
	for i in range(1, GameManager.SLOT_COUNT + 1):
		display_slots.append(i)
	display_slots.sort_custom(func(a, b):
		var ia: Dictionary = GameManager.get_save_info(a)
		var ib: Dictionary = GameManager.get_save_info(b)
		if ia["exists"] != ib["exists"]:
			return ia["exists"]
		return ia["timestamp"] > ib["timestamp"]
	)

	for slot in display_slots:
		var info = GameManager.get_save_info(slot)

		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		row.custom_minimum_size = Vector2(0, 38)
		card.add_child(row)

		var slot_lbl = Label.new()
		slot_lbl.text = info["slot_name"]
		slot_lbl.custom_minimum_size = Vector2(140, 0)
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

		var load_btn = Button.new()
		load_btn.text = "Load"
		load_btn.custom_minimum_size = Vector2(80, 34)
		load_btn.disabled = not info["exists"]
		if info["exists"]:
			var s = slot
			load_btn.pressed.connect(func(): _load_slot(s))
		row.add_child(load_btn)

		var del_btn = Button.new()
		del_btn.text = "✕"
		del_btn.custom_minimum_size = Vector2(34, 34)
		del_btn.disabled = not info["exists"]
		del_btn.add_theme_color_override("font_color", Color(0.85, 0.35, 0.35))
		if info["exists"]:
			var s = slot
			del_btn.pressed.connect(func(): _delete_slot(s))
		row.add_child(del_btn)

	return overlay

func _load_slot(slot: int) -> void:
	GameManager.load_from_slot(slot)
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _delete_slot(slot: int) -> void:
	_confirm_delete(slot, func():
		GameManager.delete_save(slot)
		if _load_overlay != null:
			_load_overlay.queue_free()
		_load_overlay = _build_load_overlay()
		add_child(_load_overlay)
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

func _on_options() -> void:
	pass

func _on_quit() -> void:
	get_tree().quit()
