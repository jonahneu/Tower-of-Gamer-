extends Control
class_name ItemIcon

var item_id: String = "":
	set(v):
		item_id = v
		queue_redraw()

func _draw() -> void:
	if item_id == "":
		return
	var w := size.x
	var h := size.y

	# Carved-material loot is generated dynamically as "<beast_type>_<material>"
	# (see DataManager.resolve_carve) and has no static entry in the match below —
	# handle the common material types generically so every animal's drops render
	# sensibly, including ones added in the future.
	if item_id.ends_with("_bones"):
		_draw_bone(w, h, Color(0.88, 0.85, 0.78))
		return
	if item_id.ends_with("_pelt"):
		var beast_type: String = item_id.substr(0, item_id.length() - "_pelt".length())
		_draw_pelt(w, h, _pelt_color_for_beast(beast_type))
		return
	if item_id.begins_with("sun_dried_"):
		_draw_smoked_meat(w, h, Color(0.72, 0.58, 0.38))
		return
	if item_id.begins_with("salt_cured_"):
		_draw_salt_cured_meat(w, h, Color(0.72, 0.62, 0.50))
		return
	if item_id.ends_with("_meat"):
		_draw_meat(w, h, Color(0.74, 0.32, 0.30))
		return
	if item_id.ends_with("_skin"):
		var skin_beast: String = item_id.substr(0, item_id.length() - "_skin".length())
		_draw_skin(w, h, _skin_color_for_beast(skin_beast))
		return
	if item_id.ends_with("_fangs"):
		_draw_fangs(w, h, Color(0.92, 0.90, 0.83))
		return
	if item_id.ends_with("_skull"):
		_draw_skull(w, h, Color(0.90, 0.87, 0.80))
		return
	if item_id.ends_with("_acid_gland"):
		_draw_gland(w, h, Color(0.70, 0.80, 0.28))
		return

	match item_id:
		# ── Stone/Primitive Weapons ──────────────────────────────────────────────
		"knife":
			_draw_knife(w, h, Color(0.75, 0.72, 0.68))     # gray stone
		"stone_axe":
			_draw_axe(w, h, Color(0.72, 0.68, 0.62), Color(0.55, 0.42, 0.28))
		"spear":
			_draw_spear(w, h, Color(0.72, 0.68, 0.62), Color(0.55, 0.42, 0.28))
		"whip":
			_draw_whip(w, h, Color(0.60, 0.40, 0.20))
		"sling":
			_draw_sling(w, h, Color(0.60, 0.50, 0.35))
		"shortbow":
			_draw_bow(w, h, Color(0.55, 0.38, 0.18), 0.6)
		"longbow":
			_draw_bow(w, h, Color(0.45, 0.30, 0.12), 0.85)
		"quiver":
			_draw_quiver(w, h, Color(0.55, 0.38, 0.18))
		# ── Bronze Weapons ───────────────────────────────────────────────────────
		"bronze_shortsword":
			_draw_sword(w, h, Color(0.78, 0.58, 0.18), 0.55)
		"bronze_sword":
			_draw_sword(w, h, Color(0.78, 0.58, 0.18), 0.75)
		"bronze_axe":
			_draw_axe(w, h, Color(0.78, 0.58, 0.18), Color(0.55, 0.42, 0.28))
		"bronze_spear":
			_draw_spear(w, h, Color(0.78, 0.58, 0.18), Color(0.55, 0.42, 0.28))
		"bronze_shortsword_blessed":
			_draw_sword(w, h, Color(0.95, 0.88, 0.55), 0.55)
		# ── Iron/steel weapons ───────────────────────────────────────────────────
		"sword":
			_draw_sword(w, h, Color(0.74, 0.76, 0.80), 0.75)
		"shortsword":
			_draw_sword(w, h, Color(0.74, 0.76, 0.80), 0.55)
		"axe":
			_draw_axe(w, h, Color(0.70, 0.72, 0.76), Color(0.45, 0.32, 0.20))
		"blunderbuss":
			_draw_blunderbuss(w, h, Color(0.45, 0.40, 0.35), Color(0.30, 0.22, 0.15))
		# ── Unarmed / fist weapons ───────────────────────────────────────────────
		"unarmed":
			_draw_fist(w, h, Color(0.80, 0.68, 0.55))
		"brass_knuckles":
			_draw_knuckles(w, h, Color(0.80, 0.65, 0.30))
		"enchanted_fist_wraps":
			_draw_fist(w, h, Color(0.65, 0.55, 0.85))
		# ── Armor ────────────────────────────────────────────────────────────────
		"bronze_helmet_barrier":
			_draw_helm(w, h, Color(0.55, 0.65, 0.85))
		"hide_shield":
			_draw_shield(w, h, Color(0.70, 0.58, 0.40))
		"wooden_shield":
			_draw_shield(w, h, Color(0.62, 0.48, 0.30))
		"bronze_shield":
			_draw_shield(w, h, Color(0.78, 0.58, 0.18))
		"bronze_scale_hauberk":
			_draw_corselet(w, h, Color(0.78, 0.58, 0.18))
		"bronze_helm":
			_draw_helm(w, h, Color(0.78, 0.58, 0.18))
		"bronze_greaves":
			_draw_greaves(w, h, Color(0.78, 0.58, 0.18))
		# ── Trinkets ─────────────────────────────────────────────────────────────
		"cloth_scripture_armband":
			_draw_armband(w, h, Color(0.88, 0.82, 0.65))
		"bronze_spirit_armband":
			_draw_armband(w, h, Color(0.78, 0.58, 0.18))
		"iron_spirit_armband":
			_draw_armband(w, h, Color(0.50, 0.52, 0.58))
		"basic_hide_trophy_armband":
			_draw_armband(w, h, Color(0.65, 0.48, 0.30))
		"basic_fang_trophy_necklace":
			_draw_necklace(w, h, Color(0.85, 0.80, 0.65))
		"basic_skull_trophy_headdress":
			_draw_headdress(w, h, Color(0.88, 0.84, 0.72))
		"basic_bone_ring":
			_draw_ring(w, h, Color(0.90, 0.87, 0.78))
		"coyote_bone_charm":
			_draw_bone_necklace(w, h, Color(0.88, 0.85, 0.78))
		"coyote_pelt_strip":
			_draw_pelt_strip(w, h, Color(0.70, 0.58, 0.40))
		"coyote_fang_pendant":
			_draw_fang_pendant(w, h, Color(0.88, 0.84, 0.72))
		"coyote_skull_headpiece":
			_draw_headdress(w, h, Color(0.85, 0.80, 0.70))
		# ── Plants & gathered materials ──────────────────────────────────────────
		"dusk_flower":
			_draw_flower(w, h, Color(0.42, 0.28, 0.50), Color(0.20, 0.14, 0.26))
		"desert_succulent":
			_draw_succulent(w, h, Color(0.46, 0.62, 0.42))
		"dates":
			_draw_dates(w, h, Color(0.42, 0.22, 0.14))
		"wild_onion":
			_draw_onion(w, h, Color(0.82, 0.78, 0.82))
		"reed_tuber":
			_draw_tuber(w, h, Color(0.78, 0.70, 0.52))
		# ── Fish (caught with a fishing rod) ──────────────────────────────────────
		"tilapia":
			_draw_fish(w, h, Color(0.58, 0.68, 0.72))
		"catfish":
			_draw_fish(w, h, Color(0.42, 0.46, 0.42), true)
		# ── Consumables & tagged items ────────────────────────────────────────────
		"blast_tag":
			_draw_blast_tag(w, h, Color(0.85, 0.55, 0.20))
		"smoke_bomb":
			_draw_bomb(w, h, Color(0.55, 0.55, 0.58))
		"dark_vial", "basic_lingering_poison":
			_draw_vial(w, h, Color(0.30, 0.55, 0.25))
		"salt":
			_draw_salt(w, h)
		"coin":
			_draw_coin(w, h, Color(0.85, 0.70, 0.25))
		# ── Spells ───────────────────────────────────────────────────────────────
		"heat", "burning_palm":
			_draw_flame(w, h, Color(0.95, 0.55, 0.15))
		# ── Talismans & scribe supplies ───────────────────────────────────────────
		"basic_protective_talisman":
			_draw_talisman(w, h, Color(0.88, 0.82, 0.65), Color(1.0, 0.55, 0.1))
		"blank_talisman":
			_draw_talisman(w, h, Color(0.88, 0.82, 0.65), Color(0.55, 0.52, 0.48))
		"fishing_rod":
			_draw_fishing_rod(w, h, Color(0.55, 0.42, 0.28))
		"ink":
			_draw_ink_pot(w, h)
		# ── Clothing ─────────────────────────────────────────────────────────────
		"tunic":
			_draw_tunic(w, h, Color(0.70, 0.65, 0.55))
		"work_trousers":
			_draw_trousers(w, h, Color(0.30, 0.28, 0.25))
		"sandals":
			_draw_boots(w, h, Color(0.72, 0.60, 0.40), false)
		"work_boots":
			_draw_boots(w, h, Color(0.42, 0.32, 0.22), true)
		"leather_vest":
			_draw_corselet(w, h, Color(0.45, 0.35, 0.22))
		"desert_shawl":
			_draw_shawl(w, h, Color(0.85, 0.78, 0.58))
		_:
			# Fallback: every item gets at least a simple shape+color keyed to its
			# type, so nothing ever renders blank. Add a specific case above as
			# items get real art — this is just the always-on safety net.
			_draw_generic(w, h, item_id)

# ── Weapon drawers ────────────────────────────────────────────────────────────

func _draw_knife(w: float, h: float, col: Color) -> void:
	# Blade: narrow triangle pointing up; handle: small rect at bottom
	var cx := w * 0.5
	var blade_top := h * 0.08
	var blade_bot := h * 0.68
	var blade_w   := w * 0.18
	var handle_w  := w * 0.22
	var handle_h  := h * 0.24
	draw_polygon([
		Vector2(cx, blade_top),
		Vector2(cx + blade_w, blade_bot),
		Vector2(cx - blade_w, blade_bot),
	], [col])
	draw_rect(Rect2(cx - handle_w * 0.5, blade_bot, handle_w, handle_h),
		col.darkened(0.35))

func _draw_sword(w: float, h: float, col: Color, length_frac: float) -> void:
	# Blade: tall narrow diamond shape; cross-guard; handle
	var cx := w * 0.5
	var tip  := h * 0.05
	var base := h * (0.05 + length_frac * 0.60)
	var bw   := w * 0.10
	var guard_w := w * 0.55
	var guard_h := h * 0.04
	var hnd_h   := h * 0.22
	# Blade
	draw_polygon([
		Vector2(cx, tip),
		Vector2(cx + bw, (tip + base) * 0.5),
		Vector2(cx, base),
		Vector2(cx - bw, (tip + base) * 0.5),
	], [col])
	# Guard
	draw_rect(Rect2(cx - guard_w * 0.5, base, guard_w, guard_h), col.darkened(0.25))
	# Handle
	draw_rect(Rect2(cx - w * 0.08, base + guard_h, w * 0.16, hnd_h), col.darkened(0.40))

func _draw_axe(w: float, h: float, head_col: Color, hnd_col: Color) -> void:
	var cx := w * 0.5
	# Handle: vertical rod offset slightly left
	var hx := cx - w * 0.06
	draw_line(Vector2(hx, h * 0.10), Vector2(hx, h * 0.92), hnd_col, 3.0)
	# Axe head: polygon on the right side, mid-upper area
	var hy := h * 0.22
	draw_polygon([
		Vector2(hx, hy),
		Vector2(hx + w * 0.45, hy - h * 0.08),
		Vector2(hx + w * 0.50, hy + h * 0.14),
		Vector2(hx + w * 0.40, hy + h * 0.22),
		Vector2(hx, hy + h * 0.16),
	], [head_col])

func _draw_spear(w: float, h: float, tip_col: Color, hnd_col: Color) -> void:
	var cx := w * 0.5
	# Long handle
	draw_line(Vector2(cx, h * 0.18), Vector2(cx, h * 0.95), hnd_col, 3.0)
	# Triangular tip
	draw_polygon([
		Vector2(cx, h * 0.04),
		Vector2(cx + w * 0.14, h * 0.22),
		Vector2(cx - w * 0.14, h * 0.22),
	], [tip_col])

func _draw_whip(w: float, h: float, col: Color) -> void:
	# S-curve line from top-left to bottom-right
	var pts: PackedVector2Array = []
	var steps := 16
	for i in range(steps + 1):
		var t  := float(i) / steps
		var px := w * 0.15 + t * w * 0.70
		var py := h * 0.10 + t * h * 0.80 + sin(t * PI * 2.0) * h * 0.15
		pts.append(Vector2(px, py))
	draw_polyline(pts, col, 2.0)

func _draw_sling(w: float, h: float, col: Color) -> void:
	# Pouch at bottom center, two strings going up to left and right
	var cx := w * 0.5
	var py := h * 0.72
	var pw := w * 0.28
	var ph := h * 0.18
	# Pouch
	draw_rect(Rect2(cx - pw * 0.5, py, pw, ph), col)
	# Strings
	draw_line(Vector2(cx - pw * 0.4, py), Vector2(w * 0.10, h * 0.10), col, 2.0)
	draw_line(Vector2(cx + pw * 0.4, py), Vector2(w * 0.90, h * 0.10), col, 2.0)

func _draw_bow(w: float, h: float, col: Color, height_frac: float) -> void:
	# Arc on left side, string on right
	var arc_pts: PackedVector2Array = []
	var steps := 20
	var top    := h * (1.0 - height_frac) * 0.5
	var bot    := h - top
	var cx_bow := w * 0.38
	var bulge  := w * 0.32
	for i in range(steps + 1):
		var t  := float(i) / steps
		var py := top + t * (bot - top)
		var px := cx_bow - sin(t * PI) * bulge
		arc_pts.append(Vector2(px, py))
	draw_polyline(arc_pts, col, 3.0)
	# String: straight line
	draw_line(Vector2(cx_bow, top), Vector2(cx_bow, bot), col.lightened(0.5), 1.0)

func _draw_quiver(w: float, h: float, col: Color) -> void:
	# Cylindrical quiver body
	var cx := w * 0.5
	var qw  := w * 0.36
	var top := h * 0.16
	var bot := h * 0.90
	draw_rect(Rect2(cx - qw * 0.5, top, qw, bot - top), col.darkened(0.2))
	# Arrow shafts sticking out
	for dx in [-0.08, 0.0, 0.08]:
		draw_line(Vector2(cx + dx * w, top - h * 0.10), Vector2(cx + dx * w, top + h * 0.12),
			col.lightened(0.3), 2.0)

func _draw_shield(w: float, h: float, col: Color) -> void:
	# Kite-ish shield shape
	var cx := w * 0.5
	draw_polygon([
		Vector2(cx, h * 0.06),
		Vector2(w * 0.88, h * 0.28),
		Vector2(w * 0.88, h * 0.60),
		Vector2(cx, h * 0.94),
		Vector2(w * 0.12, h * 0.60),
		Vector2(w * 0.12, h * 0.28),
	], [col])
	# Boss (center circle)
	draw_circle(Vector2(cx, h * 0.45), w * 0.10, col.darkened(0.30))

# ── Armor drawers ─────────────────────────────────────────────────────────────

func _draw_corselet(w: float, h: float, col: Color) -> void:
	# Torso silhouette
	var cx := w * 0.5
	draw_polygon([
		Vector2(cx - w * 0.32, h * 0.08),
		Vector2(cx + w * 0.32, h * 0.08),
		Vector2(cx + w * 0.28, h * 0.88),
		Vector2(cx - w * 0.28, h * 0.88),
	], [col])
	# Shoulder bumps
	draw_circle(Vector2(cx - w * 0.32, h * 0.14), w * 0.12, col.lightened(0.1))
	draw_circle(Vector2(cx + w * 0.32, h * 0.14), w * 0.12, col.lightened(0.1))

func _draw_helm(w: float, h: float, col: Color) -> void:
	# Dome + cheek guards
	var cx := w * 0.5
	# Main dome (arc approximated)
	var dome_pts: PackedVector2Array = []
	for i in range(13):
		var t  := float(i) / 12.0
		var a  := PI + t * PI
		dome_pts.append(Vector2(cx + cos(a) * w * 0.38, h * 0.44 + sin(a) * h * 0.36))
	dome_pts.append(Vector2(cx + w * 0.38, h * 0.44))
	dome_pts.append(Vector2(cx - w * 0.38, h * 0.44))
	draw_colored_polygon(dome_pts, col)
	# Brim
	draw_rect(Rect2(cx - w * 0.44, h * 0.44, w * 0.88, h * 0.08), col.darkened(0.2))
	# Cheek guards
	draw_rect(Rect2(cx - w * 0.38, h * 0.52, w * 0.18, h * 0.30), col.darkened(0.15))
	draw_rect(Rect2(cx + w * 0.20, h * 0.52, w * 0.18, h * 0.30), col.darkened(0.15))

func _draw_greaves(w: float, h: float, col: Color) -> void:
	# Two shin plates side by side
	var pad_w := w * 0.32
	var pad_h := h * 0.70
	var top   := h * 0.14
	draw_rect(Rect2(w * 0.10, top, pad_w, pad_h), col)
	draw_rect(Rect2(w * 0.58, top, pad_w, pad_h), col)
	# Knee cap bumps
	draw_circle(Vector2(w * 0.26, top + pad_h * 0.20), w * 0.10, col.lightened(0.15))
	draw_circle(Vector2(w * 0.74, top + pad_h * 0.20), w * 0.10, col.lightened(0.15))

# ── Trinket drawers ───────────────────────────────────────────────────────────

func _draw_armband(w: float, h: float, col: Color) -> void:
	var cx := w * 0.5
	var cy := h * 0.5
	var r: float = min(w, h) * 0.35
	draw_arc(Vector2(cx, cy), r, 0.0, TAU, 32, col, 5.0)

func _draw_necklace(w: float, h: float, col: Color) -> void:
	var cx := w * 0.5
	# Cord arc
	var arc_pts: PackedVector2Array = []
	for i in range(17):
		var t := float(i) / 16.0
		var a := PI * 0.1 + t * PI * 0.8
		arc_pts.append(Vector2(cx + cos(a) * w * 0.40, h * 0.30 + sin(a) * h * 0.30))
	draw_polyline(arc_pts, col, 2.0)
	# Pendant
	draw_circle(Vector2(cx, h * 0.66), w * 0.10, col)

func _draw_headdress(w: float, h: float, col: Color) -> void:
	# Skull-ish: dome + eye sockets
	var cx := w * 0.5
	var dome_pts: PackedVector2Array = []
	for i in range(13):
		var t := float(i) / 12.0
		var a := PI + t * PI
		dome_pts.append(Vector2(cx + cos(a) * w * 0.35, h * 0.50 + sin(a) * h * 0.38))
	dome_pts.append(Vector2(cx + w * 0.35, h * 0.50))
	dome_pts.append(Vector2(cx - w * 0.35, h * 0.50))
	draw_colored_polygon(dome_pts, col)
	draw_circle(Vector2(cx - w * 0.14, h * 0.42), w * 0.08, Color(0.1, 0.1, 0.1, 0.7))
	draw_circle(Vector2(cx + w * 0.14, h * 0.42), w * 0.08, Color(0.1, 0.1, 0.1, 0.7))
	# Jaw line
	draw_rect(Rect2(cx - w * 0.22, h * 0.50, w * 0.44, h * 0.20), col.darkened(0.1))

func _draw_ring(w: float, h: float, col: Color) -> void:
	var cx := w * 0.5
	var cy := h * 0.5
	var r: float = min(w, h) * 0.28
	draw_arc(Vector2(cx, cy), r, 0.0, TAU, 32, col, 4.0)

func _draw_pelt_strip(w: float, h: float, col: Color) -> void:
	# Rough rectangular strip with frayed edges
	var cx := w * 0.5
	var strip_w := w * 0.50
	var strip_h := h * 0.70
	draw_rect(Rect2(cx - strip_w * 0.5, h * 0.15, strip_w, strip_h), col)
	# Fur texture: short lines on edges
	for i in range(6):
		var y := h * 0.15 + float(i) * strip_h / 5.0
		draw_line(Vector2(cx - strip_w * 0.5, y), Vector2(cx - strip_w * 0.5 - w * 0.08, y + h * 0.04), col.lightened(0.2), 1.5)
		draw_line(Vector2(cx + strip_w * 0.5, y), Vector2(cx + strip_w * 0.5 + w * 0.08, y + h * 0.04), col.lightened(0.2), 1.5)

func _draw_fang_pendant(w: float, h: float, col: Color) -> void:
	var cx := w * 0.5
	# Cord
	var cord_pts: PackedVector2Array = []
	for i in range(9):
		var t := float(i) / 8.0
		var a := PI * 0.2 + t * PI * 0.6
		cord_pts.append(Vector2(cx + cos(a) * w * 0.36, h * 0.25 + sin(a) * h * 0.20))
	draw_polyline(cord_pts, col, 2.0)
	# Fang: thin pointed triangle
	draw_polygon([
		Vector2(cx, h * 0.44),
		Vector2(cx + w * 0.10, h * 0.62),
		Vector2(cx - w * 0.10, h * 0.62),
	], [col])
	draw_polygon([
		Vector2(cx + w * 0.14, h * 0.44),
		Vector2(cx + w * 0.22, h * 0.58),
		Vector2(cx + w * 0.08, h * 0.58),
	], [col.darkened(0.1)])

func _draw_bone_necklace(w: float, h: float, col: Color) -> void:
	var cx := w * 0.5
	# Draped cord
	var cord_pts: PackedVector2Array = []
	for i in range(9):
		var t := float(i) / 8.0
		var a := PI * 0.15 + t * PI * 0.7
		cord_pts.append(Vector2(cx + cos(a) * w * 0.38, h * 0.24 + sin(a) * h * 0.16))
	draw_polyline(cord_pts, Color(0.55, 0.45, 0.32), 1.5)
	# Small bone beads strung along the cord
	for t in [0.18, 0.5, 0.82]:
		var p: Vector2 = cord_pts[int(t * 8.0)]
		draw_circle(Vector2(p.x, p.y + h * 0.05), w * 0.035, col)
	# Central bone pendant — mini version of the classic bone shape
	var pcx: float = cx
	var pcy: float = h * 0.62
	var shaft_w: float = w * 0.20
	var shaft_h: float = h * 0.07
	var knob_r: float = w * 0.045
	draw_rect(Rect2(pcx - shaft_w * 0.5, pcy - shaft_h * 0.5, shaft_w, shaft_h), col)
	for x in [pcx - shaft_w * 0.5, pcx + shaft_w * 0.5]:
		draw_circle(Vector2(x, pcy - knob_r * 0.6), knob_r, col)
		draw_circle(Vector2(x, pcy + knob_r * 0.6), knob_r, col)
	draw_rect(Rect2(pcx - shaft_w * 0.5, pcy - shaft_h * 0.5, shaft_w, shaft_h), col.darkened(0.3), false, 1.0)

# ── Clothing drawers ──────────────────────────────────────────────────────────

func _draw_tunic(w: float, h: float, col: Color) -> void:
	# T-shape: body + sleeves
	var cx := w * 0.5
	# Body
	draw_rect(Rect2(cx - w * 0.28, h * 0.28, w * 0.56, h * 0.65), col)
	# Sleeves
	draw_rect(Rect2(w * 0.05, h * 0.28, w * 0.90, h * 0.22), col)
	# Neckline
	draw_arc(Vector2(cx, h * 0.28), w * 0.12, PI, TAU, 12, col.darkened(0.5), 2.0)

func _draw_trousers(w: float, h: float, col: Color) -> void:
	# Two leg tubes side by side
	var lw := w * 0.36
	draw_rect(Rect2(w * 0.08, h * 0.10, lw, h * 0.82), col)
	draw_rect(Rect2(w * 0.56, h * 0.10, lw, h * 0.82), col)
	# Waistband
	draw_rect(Rect2(w * 0.08, h * 0.10, w * 0.84, h * 0.12), col.lightened(0.15))

func _draw_boots(w: float, h: float, col: Color, tall: bool) -> void:
	# Single boot silhouette (pair implied)
	var cx := w * 0.5
	var shaft_h: float = h * 0.50 if tall else h * 0.18
	var sole_y  := h * 0.85
	# Shaft
	draw_rect(Rect2(cx - w * 0.22, sole_y - shaft_h, w * 0.44, shaft_h), col)
	# Foot/sole extends right
	draw_polygon([
		Vector2(cx - w * 0.22, sole_y - shaft_h * 0.30),
		Vector2(cx - w * 0.22, sole_y),
		Vector2(cx + w * 0.42, sole_y),
		Vector2(cx + w * 0.44, sole_y - shaft_h * 0.20),
		Vector2(cx + w * 0.20, sole_y - shaft_h * 0.32),
	], [col])
	draw_rect(Rect2(cx - w * 0.22, sole_y, w * 0.68, h * 0.06), col.darkened(0.4))

func _draw_gloves(w: float, h: float, col: Color) -> void:
	var cx := w * 0.5
	# Palm
	draw_rect(Rect2(cx - w * 0.28, h * 0.38, w * 0.56, h * 0.45), col)
	# Four fingers
	var fw := w * 0.10
	var fh := h * 0.28
	for i in range(4):
		var fx := (cx - w * 0.22) + i * (fw + w * 0.04)
		draw_rect(Rect2(fx, h * 0.10, fw, fh), col.darkened(0.1))
	# Thumb
	draw_rect(Rect2(cx + w * 0.28, h * 0.42, w * 0.14, h * 0.20), col.darkened(0.1))

func _draw_hood(w: float, h: float, col: Color) -> void:
	var cx := w * 0.5
	# Hood silhouette — like a teardrop/cowl shape
	var hood_pts: PackedVector2Array = []
	for i in range(13):
		var t := float(i) / 12.0
		var a := PI + t * PI
		hood_pts.append(Vector2(cx + cos(a) * w * 0.38, h * 0.48 + sin(a) * h * 0.40))
	hood_pts.append(Vector2(cx + w * 0.38, h * 0.48))
	hood_pts.append(Vector2(cx - w * 0.38, h * 0.48))
	draw_colored_polygon(hood_pts, col)
	# Face opening
	draw_arc(Vector2(cx, h * 0.50), w * 0.24, PI * 0.15, PI * 0.85, 12, col.darkened(0.6), 2.0)

func _draw_hat(w: float, h: float, col: Color) -> void:
	var cx := w * 0.5
	# Brim
	draw_rect(Rect2(w * 0.08, h * 0.56, w * 0.84, h * 0.10), col.darkened(0.2))
	# Crown dome
	var dome_pts: PackedVector2Array = []
	for i in range(13):
		var t := float(i) / 12.0
		var a := PI + t * PI
		dome_pts.append(Vector2(cx + cos(a) * w * 0.28, h * 0.56 + sin(a) * h * 0.44))
	dome_pts.append(Vector2(cx + w * 0.28, h * 0.56))
	dome_pts.append(Vector2(cx - w * 0.28, h * 0.56))
	draw_colored_polygon(dome_pts, col)

func _draw_shawl(w: float, h: float, col: Color) -> void:
	# Draped cloth — wide at top, tapers
	var cx := w * 0.5
	draw_polygon([
		Vector2(w * 0.05, h * 0.10),
		Vector2(w * 0.95, h * 0.10),
		Vector2(w * 0.75, h * 0.90),
		Vector2(cx,      h * 0.80),
		Vector2(w * 0.25, h * 0.90),
	], [col])

func _draw_talisman(w: float, h: float, cloth_col: Color, ink_col: Color) -> void:
	# Small cloth square with a symbolic line/mark on it
	draw_rect(Rect2(w * 0.15, h * 0.12, w * 0.70, h * 0.76), cloth_col)
	draw_rect(Rect2(w * 0.15, h * 0.12, w * 0.70, h * 0.76), cloth_col.darkened(0.3), false, 1.5)
	# Simple protective symbol — vertical line + horizontal bar
	var cx := w * 0.5
	var cy := h * 0.5
	draw_line(Vector2(cx, h * 0.26), Vector2(cx, h * 0.74), ink_col, 2.0)
	draw_line(Vector2(w * 0.28, cy - h * 0.08), Vector2(w * 0.72, cy - h * 0.08), ink_col, 2.0)

func _draw_ink_pot(w: float, h: float) -> void:
	# Small squat pot, dark liquid inside
	var pot_col := Color(0.40, 0.34, 0.28)
	var ink_col := Color(0.12, 0.10, 0.14)
	# Pot body
	draw_rect(Rect2(w * 0.20, h * 0.38, w * 0.60, h * 0.50), pot_col)
	# Rim
	draw_rect(Rect2(w * 0.16, h * 0.34, w * 0.68, h * 0.08), pot_col.lightened(0.15))
	# Ink surface
	draw_rect(Rect2(w * 0.22, h * 0.42, w * 0.56, h * 0.10), ink_col)

# ── Misc placeholder drawers ──────────────────────────────────────────────────

func _draw_flower(w: float, h: float, petal_col: Color, center_col: Color) -> void:
	# Five overlapping petals around a center, on a short stem
	var cx := w * 0.5
	var cy := h * 0.40
	var r: float = min(w, h) * 0.16
	for i in range(5):
		var a: float = TAU * float(i) / 5.0 - PI * 0.5
		draw_circle(Vector2(cx + cos(a) * r * 1.05, cy + sin(a) * r * 1.05), r, petal_col)
	draw_circle(Vector2(cx, cy), r * 0.62, center_col)
	var stem_col := Color(0.40, 0.55, 0.30)
	draw_line(Vector2(cx, cy + r * 0.6), Vector2(cx, h * 0.92), stem_col, 2.0)
	draw_line(Vector2(cx, h * 0.76), Vector2(cx + w * 0.13, h * 0.84), stem_col, 1.5)

func _draw_succulent(w: float, h: float, col: Color) -> void:
	# Rosette of fleshy, pointed leaves radiating from a base
	var cx := w * 0.5
	var cy := h * 0.68
	var angles: Array = [-100.0, -58.0, -22.0, 22.0, 58.0, 100.0]
	for i in range(angles.size()):
		var a: float = deg_to_rad(angles[i])
		var leaf_len: float = h * (0.30 if i % 2 == 0 else 0.40)
		var dir: Vector2 = Vector2(sin(a), -cos(a))
		var tip: Vector2 = Vector2(cx, cy) + dir * leaf_len
		var perp: Vector2 = Vector2(dir.y, -dir.x) * (w * 0.05)
		draw_polygon([Vector2(cx, cy) - perp, tip, Vector2(cx, cy) + perp], [col])
	draw_circle(Vector2(cx, cy), w * 0.06, col.lightened(0.25))

func _draw_dates(w: float, h: float, col: Color) -> void:
	# A small cluster of dates hanging from a short stem
	var positions: Array = [Vector2(0.38, 0.46), Vector2(0.60, 0.40), Vector2(0.50, 0.66)]
	for pos in positions:
		var cx: float = pos.x * w
		var cy: float = pos.y * h
		var pts: PackedVector2Array = []
		for i in range(13):
			var t := float(i) / 12.0
			var a := t * TAU
			pts.append(Vector2(cx + cos(a) * w * 0.13, cy + sin(a) * h * 0.18))
		draw_polygon(pts, [col])
		draw_polyline(pts + PackedVector2Array([pts[0]]), col.darkened(0.35), 1.0)
		draw_circle(Vector2(cx - w * 0.03, cy - h * 0.05), w * 0.025, Color(1.0, 1.0, 1.0, 0.30))
	draw_line(Vector2(w * 0.38, h * 0.30), Vector2(w * 0.60, h * 0.24), Color(0.45, 0.55, 0.30), 1.5)

func _draw_onion(w: float, h: float, bulb_col: Color) -> void:
	# Rounded bulb with vertical striations, a green sprout, and root threads
	var cx := w * 0.5
	var cy := h * 0.58
	var pts: PackedVector2Array = []
	for i in range(17):
		var t := float(i) / 16.0
		var a := t * TAU
		var ry: float = h * (0.22 if sin(a) < 0.0 else 0.30)
		pts.append(Vector2(cx + cos(a) * w * 0.26, cy + sin(a) * ry))
	draw_polygon(pts, [bulb_col])
	draw_polyline(pts + PackedVector2Array([pts[0]]), bulb_col.darkened(0.30), 1.3)
	for dx in [-0.10, 0.0, 0.10]:
		draw_line(Vector2(cx + dx * w, cy - h * 0.18), Vector2(cx + dx * w, cy + h * 0.26), bulb_col.darkened(0.18), 1.0)
	var stem_col := Color(0.45, 0.62, 0.30)
	draw_line(Vector2(cx, cy - h * 0.22), Vector2(cx + w * 0.05, cy - h * 0.42), stem_col, 2.0)
	draw_line(Vector2(cx, cy - h * 0.22), Vector2(cx - w * 0.05, cy - h * 0.40), stem_col, 2.0)
	var root_col := Color(0.85, 0.80, 0.70)
	for dx in [-0.06, 0.0, 0.06]:
		draw_line(Vector2(cx + dx * w, cy + h * 0.26), Vector2(cx + dx * w * 1.6, cy + h * 0.36), root_col, 1.0)

func _draw_tuber(w: float, h: float, col: Color) -> void:
	# Lumpy root vegetable with a few "eyes" and root threads
	var cx := w * 0.5
	var cy := h * 0.54
	var pts: PackedVector2Array = []
	for i in range(13):
		var t := float(i) / 12.0
		var a := t * TAU
		var wob: float = 1.0 + 0.10 * sin(a * 3.0)
		pts.append(Vector2(cx + cos(a) * w * 0.30 * wob, cy + sin(a) * h * 0.24 * wob))
	draw_polygon(pts, [col])
	draw_polyline(pts + PackedVector2Array([pts[0]]), col.darkened(0.30), 1.3)
	var eye_col: Color = col.darkened(0.35)
	for pos in [Vector2(0.42, 0.46), Vector2(0.60, 0.58), Vector2(0.50, 0.40)]:
		draw_circle(Vector2(pos.x * w, pos.y * h), w * 0.025, eye_col)
	for dx in [-0.10, 0.05]:
		draw_line(Vector2(cx + dx * w, cy + h * 0.22), Vector2(cx + dx * w * 1.4, cy + h * 0.34), col.darkened(0.20), 1.0)

func _draw_fish(w: float, h: float, col: Color, barbels: bool = false) -> void:
	# Oval body with a triangular tail fin, eye, and gill mark; catfish add whisker barbels
	var cx := w * 0.42
	var cy := h * 0.5
	var body: PackedVector2Array = []
	for i in range(17):
		var t := float(i) / 16.0
		var a := t * TAU
		body.append(Vector2(cx + cos(a) * w * 0.30, cy + sin(a) * h * 0.20))
	draw_polygon(body, [col])
	draw_polyline(body + PackedVector2Array([body[0]]), col.darkened(0.35), 1.3)
	var tail: PackedVector2Array = [
		Vector2(cx + w * 0.28, cy),
		Vector2(cx + w * 0.50, cy - h * 0.18),
		Vector2(cx + w * 0.50, cy + h * 0.18),
	]
	draw_polygon(tail, [col.darkened(0.15)])
	draw_circle(Vector2(cx - w * 0.16, cy - h * 0.04), w * 0.03, Color(0.10, 0.10, 0.10))
	draw_line(Vector2(cx - w * 0.05, cy - h * 0.14), Vector2(cx - w * 0.05, cy + h * 0.14), col.darkened(0.25), 1.0)
	if barbels:
		for dy in [-0.05, 0.05]:
			draw_line(Vector2(cx - w * 0.30, cy + dy * h), Vector2(cx - w * 0.44, cy + dy * h * 2.5), col.darkened(0.10), 1.0)

func _draw_fishing_rod(w: float, h: float, col: Color) -> void:
	# Diagonal rod from bottom-left to upper-right; line droops from tip to a small hook
	var bx := w * 0.15
	var by := h * 0.88
	var tx := w * 0.82
	var ty := h * 0.10
	draw_line(Vector2(bx, by), Vector2(tx, ty), col, 3.0)
	# Line: from tip down to the right, then a short hook curl at the end
	var lx1 := tx
	var ly1 := ty
	var lx2 := tx + w * 0.08
	var ly2 := ty + h * 0.32
	draw_line(Vector2(lx1, ly1), Vector2(lx2, ly2), col.lightened(0.4), 1.5)
	# Hook: small arc at line end
	draw_arc(Vector2(lx2 - w * 0.04, ly2), w * 0.045, PI * 0.1, PI * 1.1, 10, col.lightened(0.3), 1.5)

func _draw_blunderbuss(w: float, h: float, barrel_col: Color, stock_col: Color) -> void:
	# Diagonal barrel (flared muzzle) + angled stock
	var bx1 := w * 0.22
	var by1 := h * 0.85
	var bx2 := w * 0.62
	var by2 := h * 0.18
	draw_line(Vector2(bx1, by1), Vector2(bx2, by2), barrel_col, 5.0)
	# Flared muzzle
	draw_polygon([
		Vector2(bx2, by2),
		Vector2(bx2 + w * 0.16, by2 + h * 0.02),
		Vector2(bx2 + w * 0.04, by2 + h * 0.16),
	], [barrel_col.lightened(0.15)])
	# Stock
	draw_line(Vector2(bx1, by1), Vector2(bx1 - w * 0.16, by1 + h * 0.02), stock_col, 6.0)

func _draw_fist(w: float, h: float, col: Color) -> void:
	# Simple clenched fist: rounded palm block + four knuckle bumps
	var cx := w * 0.5
	draw_rect(Rect2(cx - w * 0.26, h * 0.40, w * 0.52, h * 0.42), col)
	for i in range(4):
		var kx := (cx - w * 0.22) + i * (w * 0.15)
		draw_circle(Vector2(kx, h * 0.38), w * 0.075, col.lightened(0.12))
	# Thumb
	draw_rect(Rect2(cx - w * 0.34, h * 0.52, w * 0.12, h * 0.20), col.darkened(0.1))

func _draw_knuckles(w: float, h: float, col: Color) -> void:
	# Four linked rings in a row
	var ry := h * 0.42
	var r: float = w * 0.11
	for i in range(4):
		var rx := w * 0.22 + i * (w * 0.19)
		draw_arc(Vector2(rx, ry), r, 0.0, TAU, 20, col, 3.0)
	# Connecting bar beneath
	draw_rect(Rect2(w * 0.16, ry + r * 0.6, w * 0.68, h * 0.10), col.darkened(0.2))

func _draw_blast_tag(w: float, h: float, col: Color) -> void:
	# Small tag/label shape with a burst mark on it
	var cx := w * 0.5
	draw_polygon([
		Vector2(w * 0.18, h * 0.16),
		Vector2(w * 0.74, h * 0.16),
		Vector2(w * 0.86, h * 0.50),
		Vector2(w * 0.74, h * 0.84),
		Vector2(w * 0.18, h * 0.84),
	], [col.darkened(0.35)])
	# Burst star
	for i in range(6):
		var a := float(i) / 6.0 * TAU
		draw_line(Vector2(cx, h * 0.5), Vector2(cx + cos(a) * w * 0.18, h * 0.5 + sin(a) * h * 0.18), col, 2.5)

func _draw_bomb(w: float, h: float, col: Color) -> void:
	# Round body with a lit fuse
	var cx := w * 0.5
	var cy := h * 0.58
	var r: float = min(w, h) * 0.30
	draw_circle(Vector2(cx, cy), r, col)
	draw_circle(Vector2(cx, cy), r, col.darkened(0.35), false, 1.5)
	# Fuse
	draw_line(Vector2(cx, cy - r), Vector2(cx + w * 0.12, h * 0.16), Color(0.55, 0.42, 0.28), 2.0)
	draw_circle(Vector2(cx + w * 0.12, h * 0.16), w * 0.05, Color(1.0, 0.65, 0.15))

func _draw_vial(w: float, h: float, liquid_col: Color) -> void:
	# Slim glass vial with colored liquid and a cork
	var cx := w * 0.5
	var bw := w * 0.28
	var top := h * 0.30
	var bot := h * 0.86
	draw_rect(Rect2(cx - bw * 0.5, top, bw, bot - top), Color(0.75, 0.80, 0.85, 0.35))
	draw_rect(Rect2(cx - bw * 0.5, top, bw, bot - top), Color(0.75, 0.80, 0.85, 0.7), false, 1.5)
	# Liquid fill (lower portion)
	var fill_top := top + (bot - top) * 0.45
	draw_rect(Rect2(cx - bw * 0.5 + 1.5, fill_top, bw - 3.0, bot - fill_top - 1.5), liquid_col)
	# Cork
	draw_rect(Rect2(cx - bw * 0.35, top - h * 0.10, bw * 0.7, h * 0.12), Color(0.55, 0.42, 0.28))

func _draw_flame(w: float, h: float, col: Color) -> void:
	# Simple teardrop flame shape, two-toned
	var cx := w * 0.5
	draw_polygon([
		Vector2(cx, h * 0.10),
		Vector2(cx + w * 0.26, h * 0.62),
		Vector2(cx, h * 0.92),
		Vector2(cx - w * 0.26, h * 0.62),
	], [col])
	draw_polygon([
		Vector2(cx, h * 0.34),
		Vector2(cx + w * 0.13, h * 0.66),
		Vector2(cx, h * 0.84),
		Vector2(cx - w * 0.13, h * 0.66),
	], [col.lightened(0.35)])

func _draw_coin(w: float, h: float, col: Color) -> void:
	# Round coin: rim, inner ring, and a small embossed glint
	var cx := w * 0.5
	var cy := h * 0.5
	var r: float = min(w, h) * 0.32
	draw_circle(Vector2(cx, cy), r, col)
	draw_circle(Vector2(cx, cy), r, col.darkened(0.45), false, 1.5)
	draw_circle(Vector2(cx, cy), r * 0.62, col.darkened(0.18), false, 1.0)
	draw_circle(Vector2(cx - r * 0.32, cy - r * 0.32), r * 0.16, col.lightened(0.45))

func _draw_pelt(w: float, h: float, col: Color) -> void:
	# Roughly oval hide with a ragged outline and a few fur-texture strokes
	var cx := w * 0.5
	var cy := h * 0.54
	var pts: Array[Vector2] = [
		Vector2(cx - w * 0.30, cy - h * 0.30),
		Vector2(cx + w * 0.10, cy - h * 0.36),
		Vector2(cx + w * 0.34, cy - h * 0.08),
		Vector2(cx + w * 0.26, cy + h * 0.30),
		Vector2(cx - w * 0.06, cy + h * 0.36),
		Vector2(cx - w * 0.34, cy + h * 0.12),
	]
	draw_polygon(pts, [col])
	draw_polyline(pts + [pts[0]], col.darkened(0.35), 1.5)
	var fur: Color = col.darkened(0.22)
	for i in range(3):
		var fx: float = cx - w * 0.16 + i * w * 0.16
		draw_line(Vector2(fx, cy - h * 0.16), Vector2(fx - w * 0.05, cy + h * 0.16), fur, 1.0)

func _draw_meat(w: float, h: float, col: Color) -> void:
	# Rough cut of raw meat: lumpy red body, pale fat marbling, small bone end
	var cx := w * 0.5
	var cy := h * 0.56
	var pts: Array[Vector2] = [
		Vector2(cx - w * 0.28, cy - h * 0.26),
		Vector2(cx + w * 0.12, cy - h * 0.34),
		Vector2(cx + w * 0.34, cy - h * 0.04),
		Vector2(cx + w * 0.22, cy + h * 0.30),
		Vector2(cx - w * 0.10, cy + h * 0.34),
		Vector2(cx - w * 0.34, cy + h * 0.06),
	]
	draw_polygon(pts, [col])
	draw_polyline(pts + [pts[0]], col.darkened(0.35), 1.5)
	var fat: Color = Color(0.92, 0.86, 0.78)
	draw_line(Vector2(cx - w * 0.18, cy - h * 0.12), Vector2(cx + w * 0.10, cy - h * 0.02), fat, 1.5)
	draw_line(Vector2(cx - w * 0.08, cy + h * 0.10), Vector2(cx + w * 0.18, cy + h * 0.18), fat, 1.5)
	draw_circle(Vector2(cx + w * 0.30, cy - h * 0.02), w * 0.06, Color(0.88, 0.85, 0.78))

func _draw_skin(w: float, h: float, col: Color) -> void:
	# Stretched scaly hide: rounded panel with rows of overlapping scale arcs
	var cx := w * 0.5
	var rect := Rect2(cx - w * 0.30, h * 0.16, w * 0.60, h * 0.70)
	draw_rect(rect, col)
	draw_rect(rect, col.darkened(0.35), false, 1.5)
	var scale_col: Color = col.darkened(0.22)
	var rows := 5
	var cols := 3
	for r in range(rows):
		var ry: float = rect.position.y + (float(r) + 0.5) * rect.size.y / rows
		var offset: float = (rect.size.x / cols) * 0.5 if r % 2 == 1 else 0.0
		for c in range(cols):
			var sx: float = rect.position.x + offset + (float(c) + 0.5) * rect.size.x / cols
			if sx > rect.position.x + rect.size.x - 2.0 or sx < rect.position.x + 2.0:
				continue
			draw_arc(Vector2(sx, ry), w * 0.06, PI, TAU, 8, scale_col, 1.3)

func _skin_color_for_beast(beast_type: String) -> Color:
	match beast_type:
		"lizard": return Color(0.50, 0.62, 0.42)   # mottled olive-green scales
		_:
			# Same deterministic-fallback approach as pelts: any future scaled
			# beast gets its own stable, distinguishable hide color for free.
			var hue: float = float(beast_type.hash() % 360) / 360.0
			return Color.from_hsv(hue, 0.30, 0.62)

func _draw_fangs(w: float, h: float, col: Color) -> void:
	# A pair of curved canine fangs leaning toward each other, points down
	var shade: Color = col.darkened(0.15)
	for side in [-1.0, 1.0]:
		var bx: float = w * 0.5 + side * w * 0.16
		var lean: float = -side * w * 0.10
		var pts: PackedVector2Array = [
			Vector2(bx - w * 0.07, h * 0.16),
			Vector2(bx + w * 0.07, h * 0.16),
			Vector2(bx + lean, h * 0.86),
		]
		draw_polygon(pts, [col])
		draw_polyline(PackedVector2Array([pts[0], pts[2], pts[1]]), shade, 1.2)
		draw_circle(Vector2(bx, h * 0.18), w * 0.05, shade)

func _draw_skull(w: float, h: float, col: Color) -> void:
	# Front-facing animal skull: cranium dome, snout, eye sockets, teeth row
	var cx := w * 0.5
	var dome_pts: PackedVector2Array = []
	for i in range(13):
		var t := float(i) / 12.0
		var a := PI + t * PI
		dome_pts.append(Vector2(cx + cos(a) * w * 0.32, h * 0.40 + sin(a) * h * 0.30))
	dome_pts.append(Vector2(cx + w * 0.32, h * 0.40))
	dome_pts.append(Vector2(cx - w * 0.32, h * 0.40))
	draw_colored_polygon(dome_pts, col)
	draw_polygon([
		Vector2(cx - w * 0.20, h * 0.40),
		Vector2(cx + w * 0.20, h * 0.40),
		Vector2(cx + w * 0.12, h * 0.74),
		Vector2(cx - w * 0.12, h * 0.74),
	], [col])
	var socket: Color = Color(0.12, 0.10, 0.10, 0.85)
	draw_circle(Vector2(cx - w * 0.13, h * 0.36), w * 0.075, socket)
	draw_circle(Vector2(cx + w * 0.13, h * 0.36), w * 0.075, socket)
	draw_polygon([
		Vector2(cx, h * 0.50),
		Vector2(cx + w * 0.045, h * 0.60),
		Vector2(cx - w * 0.045, h * 0.60),
	], [socket])
	var t_col: Color = col.darkened(0.15)
	for i in range(4):
		var tx: float = cx - w * 0.105 + float(i) * w * 0.07
		draw_rect(Rect2(tx, h * 0.70, w * 0.05, h * 0.08), t_col)

func _draw_gland(w: float, h: float, col: Color) -> void:
	# Glistening organic sac with a highlight and a drip of acid beneath it
	var cx := w * 0.5
	var cy := h * 0.42
	var pts: PackedVector2Array = []
	for i in range(17):
		var t := float(i) / 16.0
		var a := t * TAU
		pts.append(Vector2(cx + cos(a) * w * 0.24, cy + sin(a) * h * 0.22))
	draw_polygon(pts, [col])
	draw_polyline(pts, col.darkened(0.35), 1.3)
	draw_circle(Vector2(cx - w * 0.08, cy - h * 0.06), w * 0.06, Color(1.0, 1.0, 1.0, 0.35))
	draw_polygon([
		Vector2(cx - w * 0.045, cy + h * 0.20),
		Vector2(cx + w * 0.045, cy + h * 0.20),
		Vector2(cx, cy + h * 0.42),
	], [col.darkened(0.08)])
	draw_circle(Vector2(cx, cy + h * 0.46), w * 0.035, col.darkened(0.05))

func _pelt_color_for_beast(beast_type: String) -> Color:
	match beast_type:
		"coyote":            return Color(0.72, 0.60, 0.42)   # sandy brown-gray coat
		"adolescent_coyote": return Color(0.80, 0.72, 0.58)   # paler, downy juvenile coat
		_:
			# Deterministic fallback so any future beast still gets its own stable,
			# distinguishable pelt color without needing a manual entry here.
			var hue: float = float(beast_type.hash() % 360) / 360.0
			return Color.from_hsv(hue, 0.32, 0.72)

func _draw_bone(w: float, h: float, col: Color) -> void:
	# Classic bone: horizontal shaft with paired knobs at each end
	var cy: float = h * 0.5
	var shaft_h: float = h * 0.16
	var left: float = w * 0.30
	var right: float = w * 0.70
	var knob_r: float = min(w, h) * 0.12
	draw_rect(Rect2(left, cy - shaft_h * 0.5, right - left, shaft_h), col)
	for x in [left, right]:
		draw_circle(Vector2(x, cy - knob_r * 0.75), knob_r, col)
		draw_circle(Vector2(x, cy + knob_r * 0.75), knob_r, col)
	var edge: Color = col.darkened(0.3)
	draw_rect(Rect2(left, cy - shaft_h * 0.5, right - left, shaft_h), edge, false, 1.0)
	for x in [left, right]:
		draw_circle(Vector2(x, cy - knob_r * 0.75), knob_r, edge, false, 1.0)
		draw_circle(Vector2(x, cy + knob_r * 0.75), knob_r, edge, false, 1.0)

func _draw_smoked_meat(w: float, h: float, col: Color) -> void:
	# Jerky strip: a flat darkened rectangle with a few diagonal grain lines, plus smoke wisps
	var cx := w * 0.5
	var rect := Rect2(cx - w * 0.28, h * 0.34, w * 0.56, h * 0.38)
	draw_rect(rect, col)
	draw_rect(rect, col.darkened(0.4), false, 1.5)
	var grain := col.darkened(0.25)
	for i in range(3):
		var gy: float = rect.position.y + (float(i) + 0.5) * rect.size.y / 3.0
		draw_line(Vector2(rect.position.x + w * 0.04, gy),
			Vector2(rect.position.x + rect.size.x - w * 0.04, gy + h * 0.04), grain, 1.0)
	# Smoke wisps above
	for dx in [-0.12, 0.0, 0.12]:
		var wx: float = cx + dx * w
		var pts: PackedVector2Array = []
		for i in range(7):
			var t := float(i) / 6.0
			pts.append(Vector2(wx + sin(t * PI * 1.5) * w * 0.04, h * 0.28 - t * h * 0.22))
		draw_polyline(pts, Color(0.70, 0.70, 0.72, 0.55), 1.2)

func _draw_salt_cured_meat(w: float, h: float, col: Color) -> void:
	# Pale cured slab with white salt crystals dotted on surface
	var cx := w * 0.5
	var rect := Rect2(cx - w * 0.30, h * 0.28, w * 0.60, h * 0.46)
	draw_rect(rect, col)
	draw_rect(rect, col.darkened(0.3), false, 1.5)
	var crystal := Color(0.92, 0.92, 0.94)
	for pos in [Vector2(0.36, 0.38), Vector2(0.52, 0.44), Vector2(0.44, 0.56),
				Vector2(0.62, 0.36), Vector2(0.30, 0.52)]:
		draw_rect(Rect2(pos.x * w - 2.0, pos.y * h - 2.0, 4.0, 4.0), crystal)

func _draw_salt(w: float, h: float) -> void:
	# Small mound of coarse salt in a low bowl/dish
	var cx := w * 0.5
	var bowl_col := Color(0.52, 0.46, 0.38)
	var salt_col := Color(0.90, 0.90, 0.92)
	# Bowl
	draw_arc(Vector2(cx, h * 0.66), w * 0.35, 0.0, PI, 16, bowl_col, 3.0)
	draw_line(Vector2(cx - w * 0.35, h * 0.66), Vector2(cx + w * 0.35, h * 0.66), bowl_col, 3.0)
	# Salt mound (filled semicircle)
	var mound: PackedVector2Array = []
	for i in range(13):
		var t := float(i) / 12.0
		var a := PI + t * PI
		mound.append(Vector2(cx + cos(a) * w * 0.28, h * 0.62 + sin(a) * h * 0.16))
	mound.append(Vector2(cx + w * 0.28, h * 0.62))
	mound.append(Vector2(cx - w * 0.28, h * 0.62))
	draw_colored_polygon(mound, salt_col)
	# Crystal glints
	for pos in [Vector2(0.42, 0.52), Vector2(0.52, 0.48), Vector2(0.60, 0.54)]:
		draw_rect(Rect2(pos.x * w - 1.5, pos.y * h - 1.5, 3.0, 3.0), Color(1.0, 1.0, 1.0, 0.7))

func _draw_generic(w: float, h: float, item_id_for_lookup: String) -> void:
	# Always-on fallback: a simple shape + color keyed to the item's type, so
	# every item renders *something* even before it gets a hand-made icon.
	var item_type: String = DataManager.get_item(item_id_for_lookup).get("type", "")
	var col: Color
	match item_type:
		"weapon":     col = Color(0.70, 0.68, 0.65)
		"armor":      col = Color(0.55, 0.58, 0.65)
		"clothing":   col = Color(0.62, 0.56, 0.45)
		"trinket":    col = Color(0.80, 0.74, 0.58)
		"material":   col = Color(0.55, 0.65, 0.45)
		"consumable": col = Color(0.70, 0.40, 0.55)
		"tool":       col = Color(0.58, 0.54, 0.46)
		"spell":      col = Color(0.58, 0.40, 0.78)
		"quest_item": col = Color(0.82, 0.68, 0.30)
		_:            col = Color(0.55, 0.55, 0.58)
	var pad: float = min(w, h) * 0.18
	var r := Rect2(pad, pad, w - pad * 2.0, h - pad * 2.0)
	draw_rect(r, col)
	draw_rect(r, col.darkened(0.4), false, 1.5)
	# Small corner notch so it visibly reads as "placeholder" rather than a
	# finished icon.
	draw_line(Vector2(pad, pad), Vector2(pad + (r.size.x) * 0.35, pad), col.lightened(0.3), 2.0)
