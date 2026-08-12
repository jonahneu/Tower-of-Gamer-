extends Node
# GameManager — global game state

var current_layer: int = 0
var combat_mode: bool = false
var tactical_mode: bool = false
# True while a tutorial popup (hud.gd) is on screen. Enemy._process() checks
# this and freezes entirely (no wander, no aggro/detection) — a full engine
# pause would also need every relevant UI node re-flagged PROCESS_MODE_ALWAYS
# to keep responding, which is riskier than just freezing enemies for what's
# actually being asked: don't let a popup you can't react to cost you a
# sneaking attempt.
var tutorial_popup_open: bool = false
var is_sneaking: bool = false
var _player: Node = null
var player: Node:
	get:
		if not is_instance_valid(_player):
			_player = null
		return _player
	set(value):
		_player = value
var player_data: Dictionary = {}
var current_zone: Node = null   # live TileScene; set by main.gd on every transition
var smoke_zones: Array = []     # Array of {center:Vector2i, radius:int, turns_remaining:int}

const SLOT_COUNT: int = 5        # manual slots 1–5
const PREV_QUICK_SLOT: int = 6   # second-most-recent quick save (auto-shifted)
const AUTO_SLOT: int = 7         # most-recent auto save
const PREV_AUTO_SLOT: int = 8    # previous auto save (auto-shifted)

# ── World map state ────────────────────────────────────────────────────────────
var world_pos: Vector2i = Vector2i(-1, 15)   # current tile on the 20×20 world map (default = the ritual chamber, the new-game start)
var world_layer: int = 0

# Tile definitions per layer. Populated in _ready because Vector2i keys can't
# be used in const Dictionaries.
var world_map_data: Dictionary = {}

# Exploration tracking: {layer_int: {Vector2i: {visited: bool, encounters: Array}}}
var explored_tiles: Dictionary = {}

func _ready() -> void:
	world_map_data = {
		0: {  # Surface layer
			Vector2i(10, 14): {
				"scene":          "res://scenes/world/zone_ditch.tscn",
				"label":          "The Ditch",
				"area":           "The Ditch",
				"thumbnail_type": "slums",
				"exits":          {
					"north": Vector2i(10, 13),
					"south": Vector2i(10, 15),
					"west":  Vector2i(9, 14),
				},
			},
			# Residential District (10,11)/(11,11) removed 2026-08-10: the
			# Residential District as a separate lower-city zone was cut
			# 2026-07-22 (ordinary citizens live spread throughout the Ditch
			# instead — see project_starting_area_scale_reframe memory), and
			# this cleanup was deferred until the next map rebuild. That's
			# now. KNOWN BREAKAGE: scribe.gd's "scribe_delivery" quest still
			# sends the player to "the residential district, north east
			# corner" for an NPC whose name was already a "[TBD]" placeholder
			# — that quest destination no longer exists anywhere and needs a
			# new home before it can be completed.
			Vector2i(10, 12): {
				"scene":          "res://scenes/world/zone_market.tscn",
				"label":          "Market District",
				"area":           "The Ditch",
				"thumbnail_type": "city",
				"exits":          {
					"south": Vector2i(10, 13),
					"west":  Vector2i(9, 12),
				},
			},
			Vector2i(9, 12): {
				"scene":          "res://scenes/world/zone_market_gate.tscn",
				"label":          "Market District — Gate",
				"area":           "The Ditch",
				"thumbnail_type": "city",
				"exits":          {
					"west":  Vector2i(8, 12),
					"east":  Vector2i(10, 12),
					"north": Vector2i(9, 11),
					"south": Vector2i(9, 13),
				},
			},
			Vector2i(8, 12): {
				"scene":                    "res://scenes/world/zone_desert_road.tscn",
				"label":                    "The Desert",
				"area":           "The Outskirts",
				"thumbnail_type":           "desert",
				"required_protection_level": 1,
				"exits":                    {
					"west":  Vector2i(7, 12),
					"east":  Vector2i(9, 12),
					"north": Vector2i(8, 11),
				},
			},
			Vector2i(10, 13): {
				"scene":          "res://scenes/world/zone_market_lower.tscn",
				"label":          "Lower Market District",
				"area":           "The Ditch",
				"thumbnail_type": "slums",
				"exits":          {
					"north": Vector2i(10, 12),
					"south": Vector2i(10, 14),
				},
			},
			Vector2i(10, 15): {
				"scene":          "res://scenes/world/zone_ditch_lower.tscn",
				"label":          "The Ditch — Lower",
				"area":           "The Ditch",
				"thumbnail_type": "slums",
				"exits":          {
					"north": Vector2i(10, 14),
					"south": Vector2i(10, 16),
					"west":  Vector2i(9, 15),
				},
			},
			# Escape-route tutorial dungeon (opening-hook rewrite, see
			# GettingStarted/OpeningRewrite_Plan.md). Not part of the normal
			# explorable world — reachable only via the ritual chamber's exit
			# door below. Off-grid coordinate (outside hud.gd's 20×20 MAP_COLS/
			# MAP_ROWS grid) so, like the chamber, it can never surface on the
			# world-map screen even after being visited — this was always the
			# intent ("not part of the normal explorable world"), corrected
			# 2026-07-14 after initially being placed on the addressable grid.
			# One-way: its final room ends at a Collapsed Ledge (TrashChute,
			# visual_style "ledge", direction "fall") instead of a walked-off
			# edge — the separate drop-alcove connector room was folded away
			# 2026-08-04, so the hallway itself now ends in the drop straight
			# into the rest alcove below. Deliberately has no return exit back
			# toward the chamber.
			Vector2i(-1, 18): {
				"scene":          "res://scenes/world/zone_escape_route.tscn",
				"label":          "Drainage Tunnel",
				"thumbnail_type": "slums",
				"is_interior":    true,
				"exits":          {
					"fall": Vector2i(-1, 19),
				},
			},
			# Rest alcove — the escape route's final beat (2026-07-29; the
			# drop-alcove connector room that used to sit between this and the
			# escape route above was removed 2026-08-04, so the ledge at the
			# end of the escape route now drops straight in here). A small
			# room between the tutorial dungeon and the Lower Ditch where the
			# player is taught Make Camp (cooking + resting, both live on the
			# same R-key panel) before setting out. required_protection_level
			# forces a fresh, unprotected character to pick up 1 exhaustion
			# stack on this first rest — the tutorial's whole point is to make
			# that consequence legible before the player is out in the world
			# on their own. Off-grid and one-way for the same reasons as the
			# escape route above.
			Vector2i(-1, 19): {
				"scene":                     "res://scenes/world/zone_escape_route_rest.tscn",
				"label":                     "Drainage Tunnel — Rest Alcove",
				"thumbnail_type":            "slums",
				"is_interior":               true,
				"required_protection_level": 1,
				"exits":                     {
					# Exits into the Outskirts ruins chain (2026-08-10), not
					# directly into Lower Ditch — see the "Outskirts ruins
					# chain" block below. Plain "west" walk-off (2026-08-11):
					# the door gap sits at x=0, the true west edge, so no
					# ZoneDoor/interact step is needed — just a rubble pipe
					# mouth to look at (see pipe_mouth.gd) and step through.
					# Landing point is still hand-placed, not the generic
					# formula — see the world_pos check in main.gd's
					# _entry_cell_for() — since Ruins Entry's arrival point
					# doesn't sit anywhere near its own true edges.
					"west": Vector2i(9, 18),
				},
			},
			# The ritual chamber (opening-hook rewrite, §13 "The Interrupted
			# Sacrifice") — a Type-A interior per DesignDoc_BronzeAge.md's
			# "Building Interiors — Two Tiers": its own small TileScene, entered/
			# exited via a door (scripts/entities/interior_door.gd) rather than a
			# walk-off zone edge. is_interior marks it as such; combined with the
			# out-of-range coordinate below (outside hud.gd's 20×20 MAP_COLS/
			# MAP_ROWS grid), it can never surface on the world-map screen.
			# One-way: the exit door leads to the escape route above; nothing
			# points back here. This is now the new-game start location (see
			# character_creation.gd) and the Taskmaster is fully cut. The
			# ritual-interruption/mark/escape cutscene itself is still unbuilt
			# (Phase 3) — the player currently just begins here directly.
			Vector2i(-1, 15): {
				"scene":          "res://scenes/world/zone_ritual_chamber.tscn",
				"label":          "The Ritual Chamber",
				"thumbnail_type": "interior",
				"is_interior":    true,
				"exits":          {
					"east": Vector2i(-1, 18),
				},
			},
			Vector2i(10, 16): {
				"scene":          "res://scenes/world/zone_ditch_undercity.tscn",
				"label":          "The Ditch — Undercity Entrance",
				"area":           "The Ditch",
				"thumbnail_type": "slums",
				"exits":          {
					"north": Vector2i(10, 15),
					"down":  Vector2i(10, 16),
				},
			},
			Vector2i(9, 14): {
				"scene":          "res://scenes/world/zone_outside_gate.tscn",
				"label":          "The Ditch — Exit Drain",
				"area":           "The Ditch",
				"thumbnail_type": "slums",
				"exits":          {
					"north": Vector2i(9, 13),
					"east":  Vector2i(10, 14),
					"west":  Vector2i(8, 14),
					"south": Vector2i(9, 15),
				},
			},
			Vector2i(8, 14): {
				"scene":                    "res://scenes/world/zone_desert.tscn",
				"label":                    "The Desert",
				"area":           "The Outskirts",
				"thumbnail_type":           "desert",
				"required_protection_level": 1,
				"exits":                    {
					"north": Vector2i(8, 13),
					"east":  Vector2i(9, 14),
					"west":  Vector2i(7, 14),
				},
			},
			Vector2i(7, 14): {
				"scene":                    "res://scenes/world/zone_river.tscn",
				"label":                    "Riverbank",
				"area":           "The Outskirts",
				"thumbnail_type":           "wilderness",
				"required_protection_level": 1,
				"exits":                    {
					"north": Vector2i(7, 13),
					"east":  Vector2i(8, 14),
					"south": Vector2i(7, 15),
				},
			},
			Vector2i(7, 12): {
				"scene":                    "res://scenes/world/zone_docks.tscn",
				"label":                    "Riverbank — Docks",
				"area":           "The Outskirts",
				"thumbnail_type":           "wilderness",
				"required_protection_level": 1,
				"exits":                    {
					"south": Vector2i(7, 13),
					"east":  Vector2i(8, 12),
					"north": Vector2i(7, 11),
				},
			},
			Vector2i(7, 11): {
				"scene":                    "res://scenes/world/zone_river_bend.tscn",
				"label":                    "Riverbank — Bend",
				"area":           "The Outskirts",
				"thumbnail_type":           "wilderness",
				"required_protection_level": 1,
				"exits":                    {
					"south": Vector2i(7, 12),
					"north": Vector2i(7, 10),
					"east":  Vector2i(8, 11),
				},
			},
			Vector2i(8, 11): {
				"scene":                    "res://scenes/world/zone_desert_flats.tscn",
				"label":                    "The Desert",
				"area":           "The Outskirts",
				"thumbnail_type":           "desert",
				"required_protection_level": 1,
				"exits":                    {
					"south": Vector2i(8, 12),
					"north": Vector2i(8, 10),
					"east":  Vector2i(9, 11),
					"west":  Vector2i(7, 11),
				},
			},
			Vector2i(9, 11): {
				"scene":                    "res://scenes/world/zone_desert_outpost.tscn",
				"label":                    "The Desert",
				"area":           "The Outskirts",
				"thumbnail_type":           "desert",
				"required_protection_level": 1,
				"exits":                    {
					"south": Vector2i(9, 12),
					"north": Vector2i(9, 10),
					"west":  Vector2i(8, 11),
				},
			},
			Vector2i(7, 10): {
				"scene":                    "res://scenes/world/zone_river_headwaters.tscn",
				"label":                    "Riverbank — Headwaters",
				"area":           "The Outskirts",
				"thumbnail_type":           "wilderness",
				"required_protection_level": 1,
				"exits":                    {
					"south": Vector2i(7, 11),
					"east":  Vector2i(8, 10),
					"north": Vector2i(7, 9),
				},
			},
			Vector2i(8, 10): {
				"scene":                    "res://scenes/world/zone_desert_scrub.tscn",
				"label":                    "The Desert",
				"area":           "The Outskirts",
				"thumbnail_type":           "desert",
				"required_protection_level": 1,
				"exits":                    {
					"south": Vector2i(8, 11),
					"east":  Vector2i(9, 10),
					"west":  Vector2i(7, 10),
					"north": Vector2i(8, 9),
				},
			},
			Vector2i(7, 9): {
				"scene":                    "res://scenes/world/zone_desert_camp_southwest.tscn",
				"label":                    "Riverbank",
				"area":           "The Outskirts",
				"thumbnail_type":           "wilderness",
				"required_protection_level": 1,
				"exits":                    {
					"south": Vector2i(7, 10),
					"north": Vector2i(7, 8),
					"east":  Vector2i(8, 9),
				},
			},
			Vector2i(7, 8): {
				"scene":                    "res://scenes/world/zone_desert_camp_west.tscn",
				"label":                    "Riverbank",
				"area":           "The Outskirts",
				"thumbnail_type":           "wilderness",
				"required_protection_level": 1,
				"exits":                    {
					"south": Vector2i(7, 9),
					"east":  Vector2i(8, 8),
				},
			},
			Vector2i(8, 9): {
				"scene":                    "res://scenes/world/zone_desert_camp_south.tscn",
				"label":                    "The Desert",
				"area":           "The Outskirts",
				"thumbnail_type":           "desert",
				"required_protection_level": 1,
				"exits":                    {
					"south": Vector2i(8, 10),
					"north": Vector2i(8, 8),
					"west":  Vector2i(7, 9),
					"east":  Vector2i(9, 9),
				},
			},
			Vector2i(9, 10): {
				"scene":                    "res://scenes/world/zone_desert_borderlands.tscn",
				"label":                    "The Desert",
				"area":           "The Outskirts",
				"thumbnail_type":           "desert",
				"required_protection_level": 1,
				"exits":                    {
					"south": Vector2i(9, 11),
					"west":  Vector2i(8, 10),
					"north": Vector2i(9, 9),
				},
			},
			Vector2i(9, 9): {
				"scene":                    "res://scenes/world/zone_desert_north_pass.tscn",
				"label":                    "The Desert",
				"area":           "The Outskirts",
				"thumbnail_type":           "desert",
				"required_protection_level": 1,
				"exits":                    {
					"south": Vector2i(9, 10),
					"north": Vector2i(9, 8),
					"west":  Vector2i(8, 9),
				},
			},
			Vector2i(9, 8): {
				"scene":                    "res://scenes/world/zone_desert_north_flat.tscn",
				"label":                    "The Desert",
				"area":           "The Outskirts",
				"thumbnail_type":           "desert",
				"required_protection_level": 1,
				"exits":                    {
					"south": Vector2i(9, 9),
					"west":  Vector2i(8, 8),
				},
			},
			Vector2i(8, 8): {
				"scene":                    "res://scenes/world/zone_desert_bandit_camp.tscn",
				"label":                    "The Desert — Bandit Camp",
				"area":           "The Outskirts",
				"thumbnail_type":           "desert",
				"required_protection_level": 1,
				"exits":                    {
					"east":  Vector2i(9, 8),
					"south": Vector2i(8, 9),
					"west":  Vector2i(7, 8),
				},
			},
			Vector2i(7, 13): {
				"scene":                    "res://scenes/world/zone_river_north.tscn",
				"label":                    "Riverbank — North",
				"area":           "The Outskirts",
				"thumbnail_type":           "wilderness",
				"required_protection_level": 1,
				"exits":                    {
					"north": Vector2i(7, 12),
					"south": Vector2i(7, 14),
					"east":  Vector2i(8, 13),
				},
			},
			Vector2i(8, 13): {
				"scene":                    "res://scenes/world/zone_desert_mid.tscn",
				"label":                    "The Desert",
				"area":           "The Outskirts",
				"thumbnail_type":           "desert",
				"required_protection_level": 1,
				"exits":                    {
					"south": Vector2i(8, 14),
					"east":  Vector2i(9, 13),
					"west":  Vector2i(7, 13),
				},
			},
			Vector2i(9, 13): {
				"scene":                    "res://scenes/world/zone_desert_north.tscn",
				"label":                    "The Desert",
				"area":           "The Outskirts",
				"thumbnail_type":           "desert",
				"required_protection_level": 1,
				"exits":                    {
					"south": Vector2i(9, 14),
					"west":  Vector2i(8, 13),
					"north": Vector2i(9, 12),
				},
			},
			# River zones (column 7) cut off from the Outskirts ruins chain
			# 2026-08-10 — their old "east" exits led into zone_desert_east/
			# _deep/_wastes, now replaced below. Each gets a bit of ruin
			# dressed onto its east edge (see the .tscn files) so the dead
			# end reads as deliberate rather than an unfinished exit.
			Vector2i(7, 15): {
				"scene":                    "res://scenes/world/zone_river_south.tscn",
				"label":                    "Riverbank — South",
				"area":                     "The Outskirts",
				"thumbnail_type":           "wilderness",
				"required_protection_level": 1,
				"exits":                    {
					"north": Vector2i(7, 14),
					"south": Vector2i(7, 16),
				},
			},
			Vector2i(7, 16): {
				"scene":                    "res://scenes/world/zone_riverbank_deep.tscn",
				"label":                    "Riverbank — Deep",
				"area":                     "The Outskirts",
				"thumbnail_type":           "wilderness",
				"required_protection_level": 1,
				"exits":                    {
					"north": Vector2i(7, 15),
					"south": Vector2i(7, 17),
				},
			},
			Vector2i(7, 17): {
				"scene":                    "res://scenes/world/zone_river_marshes.tscn",
				"label":                    "Riverbank — Marshes",
				"area":                     "The Outskirts",
				"thumbnail_type":           "wilderness",
				"required_protection_level": 1,
				"exits":                    {
					"north": Vector2i(7, 16),
					"south": Vector2i(7, 18),
				},
			},
			Vector2i(7, 18): {
				"scene":                    "res://scenes/world/zone_river_delta.tscn",
				"label":                    "Riverbank — Delta",
				"area":                     "The Outskirts",
				"thumbnail_type":           "wilderness",
				"required_protection_level": 1,
				"exits":                    {
					"north": Vector2i(7, 17),
				},
			},
			# Outskirts ruins chain, added 2026-08-10, rebuilt four times same
			# day after user feedback: (1) wide-open no-wall zones looked
			# like empty desert with no visible fork; (2) building.gd
			# interior "Door" entities at every connection, wrong for an
			# outdoor rubble path; (3) right walk-off idea but wrong compass
			# layout; (4) this version — direction keys didn't actually
			# match the real relative position of the coordinates they
			# pointed to (e.g. Entry "west" pointed at a tile that was
			# actually northwest of it), which reads as nonsensical once
			# you're navigating it, even though each individual zone's
			# internal geometry was fine. Every hop below is now a genuine
			# single-cell cardinal step between its Vector2i and its
			# target's, same as every other zone pair in this file — no
			# more "west" that's actually diagonal.
			#
			# Layout: rest alcove's exit pipe (one-way, matches the escape
			# route's own convention) drops the player at Ruins Entry
			# (9,18). Entry forks: north to Path A (9,17, coyotes), or west
			# to Path B1 (8,18) — an all-new 3-zone climb (8,18)->(8,17)->
			# (8,16), the last of which holds a rock pile worth checking
			# (nothing hidden there yet — that's a separate open item, not
			# this zone's fault) — before turning east into Convergence
			# (9,16), where Path A's own "north" hop also lands. Convergence
			# opens north into Drainage Mouth (9,15), which opens east into
			# Lower Ditch (how the player returns to the city) and
			# separately north into the pre-existing zone_outside_gate.
			# Fully bidirectional throughout (real, revisitable Outskirts
			# terrain, not another one-way tutorial corridor) — only the
			# rest-alcove -> Entry hand-off itself stays one-way.
			#
			# Walls throughout use Building's rubble_style=true
			# (scripts/entities/rubble_wall_cell.gd) — jagged broken-rubble
			# mounds for most cells, occasional flat "standing wall remnant"
			# cells mixed in, instead of smooth built walls.
			#
			# Replaces the old zone_desert_east/_south/_deep/_wall/_wastes/
			# _den (columns 8-9, rows 15-17) — everything in those six zones
			# was generic dressing (rocks, coyote/beetle spawns, unnamed
			# harvestables) with one exception: the Merchant's Package
			# WorldItem for the Distraught Merchant quest. NOT yet re-placed
			# anywhere (2026-08-11) — pulled from zone_desert_den without a
			# new home yet; distraught_merchant.gd's quest text was loosened
			# to not name a specific location until one is chosen.
			# Deliberately a separate stretch of ruins from the Old
			# Hunter/Ground-Exit-Path Outskirts cluster further north/west.
			Vector2i(9, 18): {
				"scene":                    "res://scenes/world/zone_outskirts_ruins_entry.tscn",
				"label":                    "Outskirts Ruins — Entry",
				"area":                     "The Outskirts",
				"thumbnail_type":           "ruins",
				"required_protection_level": 1,
				"exits":                    {
					"north": Vector2i(9, 17),
					"west":  Vector2i(8, 18),
				},
			},
			Vector2i(9, 17): {
				"scene":                    "res://scenes/world/zone_outskirts_path_a.tscn",
				"label":                    "Outskirts Ruins — Path A",
				"area":                     "The Outskirts",
				"thumbnail_type":           "ruins",
				"required_protection_level": 1,
				"exits":                    {
					"north": Vector2i(9, 16),
					"south": Vector2i(9, 18),
				},
			},
			Vector2i(8, 18): {
				"scene":                    "res://scenes/world/zone_outskirts_path_b1.tscn",
				"label":                    "Outskirts Ruins — Path B (Lower)",
				"area":                     "The Outskirts",
				"thumbnail_type":           "ruins",
				"required_protection_level": 1,
				"exits":                    {
					"east":  Vector2i(9, 18),
					"north": Vector2i(8, 17),
				},
			},
			Vector2i(8, 17): {
				"scene":                    "res://scenes/world/zone_outskirts_path_b.tscn",
				"label":                    "Outskirts Ruins — Path B (Mid)",
				"area":                     "The Outskirts",
				"thumbnail_type":           "ruins",
				"required_protection_level": 1,
				"exits":                    {
					"south": Vector2i(8, 18),
					"north": Vector2i(8, 16),
				},
			},
			Vector2i(8, 16): {
				"scene":                    "res://scenes/world/zone_outskirts_path_b3.tscn",
				"label":                    "Outskirts Ruins — Path B (Upper)",
				"area":                     "The Outskirts",
				"thumbnail_type":           "ruins",
				"required_protection_level": 1,
				"exits":                    {
					"south": Vector2i(8, 17),
					"east":  Vector2i(9, 16),
				},
			},
			Vector2i(9, 16): {
				"scene":                    "res://scenes/world/zone_outskirts_convergence.tscn",
				"label":                    "Outskirts Ruins — Convergence",
				"area":                     "The Outskirts",
				"thumbnail_type":           "ruins",
				"required_protection_level": 1,
				"exits":                    {
					"south": Vector2i(9, 17),
					"west":  Vector2i(8, 16),
					"north": Vector2i(9, 15),
				},
			},
			Vector2i(9, 15): {
				"scene":                    "res://scenes/world/zone_outskirts_drainage_mouth.tscn",
				"label":                    "Outskirts Ruins — Drainage Mouth",
				"area":                     "The Outskirts",
				"thumbnail_type":           "ruins",
				"required_protection_level": 1,
				"exits":                    {
					"east":  Vector2i(10, 15),
					"north": Vector2i(9, 14),
					"south": Vector2i(9, 16),
				},
			},
		},
		1: {  # Underground I
			Vector2i(10, 16): {
				"scene":                    "res://scenes/world/zone_undercity_depth1.tscn",
				"label":                    "Undercity — Depth One",
				"area":           "The Undercity",
				"thumbnail_type":           "tunnel_ns",
				"required_protection_level": 1,
				"exits":                    {
					"up":    Vector2i(10, 16),
					"north": Vector2i(10, 15),
				},
			},
			Vector2i(10, 15): {
				"scene":                    "res://scenes/world/zone_undercity_room1.tscn",
				"label":                    "Undercity — Chamber",
				"area":           "The Undercity",
				"thumbnail_type":           "tunnel_ns",
				"required_protection_level": 1,
				"exits":                    {
					"south": Vector2i(10, 16),
					"north": Vector2i(10, 14),
				},
			},
			Vector2i(10, 14): {
				"scene":                    "res://scenes/world/zone_undercity_fork.tscn",
				"label":                    "Undercity — Crossroads",
				"area":           "The Undercity",
				"thumbnail_type":           "tunnel_x",
				"required_protection_level": 1,
				"exits":                    {
					"south": Vector2i(10, 15),
					"north": Vector2i(10, 13),
					"east":  Vector2i(11, 14),
					"west":  Vector2i(9, 14),
				},
			},
			Vector2i(11, 14): {
				"scene":                    "res://scenes/world/zone_undercity_east_arm.tscn",
				"label":                    "Undercity — East Passage",
				"area":           "The Undercity",
				"thumbnail_type":           "tunnel_nw",
				"required_protection_level": 1,
				"exits":                    {
					"west":  Vector2i(10, 14),
					"north": Vector2i(11, 13),
				},
			},
			Vector2i(11, 13): {
				"scene":                    "res://scenes/world/zone_undercity_east_s1.tscn",
				"label":                    "Undercity — East Tunnels",
				"area":           "The Undercity",
				"thumbnail_type":           "tunnel_ns",
				"required_protection_level": 1,
				"exits":                    {
					"south": Vector2i(11, 14),
					"north": Vector2i(11, 12),
				},
			},
			Vector2i(11, 12): {
				"scene":                    "res://scenes/world/zone_undercity_east_bypass.tscn",
				"label":                    "Undercity — East Tunnels",
				"area":           "The Undercity",
				"thumbnail_type":           "tunnel_ns",
				"required_protection_level": 1,
				"exits":                    {
					"south": Vector2i(11, 13),
					"north": Vector2i(11, 11),
					"west":  Vector2i(10, 12),
				},
			},
			Vector2i(11, 11): {
				"scene":                    "res://scenes/world/zone_undercity_east_u1.tscn",
				"label":                    "Undercity — East Tunnels",
				"area":           "The Undercity",
				"thumbnail_type":           "tunnel_ns",
				"required_protection_level": 1,
				"exits":                    {
					"south": Vector2i(11, 12),
					"north": Vector2i(11, 10),
				},
			},
			Vector2i(11, 10): {
				"scene":                    "res://scenes/world/zone_undercity_east_exit.tscn",
				"label":                    "Undercity — East Tunnels",
				"area":           "The Undercity",
				"thumbnail_type":           "tunnel_ts",
				"required_protection_level": 1,
				"exits":                    {
					"south": Vector2i(11, 11),
					"west":  Vector2i(10, 10),
					"east":  Vector2i(12, 10),
				},
			},
			Vector2i(12, 10): {
				"scene":                    "res://scenes/world/zone_undercity_east_camp.tscn",
				"label":                    "Undercity — Cannibal Camp",
				"area":           "The Undercity",
				"thumbnail_type":           "tunnel_sw",
				"required_protection_level": 1,
				"exits":                    {
					"west": Vector2i(11, 10),
				},
			},
			Vector2i(10, 13): {
				"scene":                    "res://scenes/world/zone_undercity_north1.tscn",
				"label":                    "Undercity — Main Passage",
				"area":           "The Undercity",
				"thumbnail_type":           "tunnel_ns",
				"required_protection_level": 1,
				"exits":                    {
					"south": Vector2i(10, 14),
					"north": Vector2i(10, 12),
				},
			},
			Vector2i(10, 12): {
				"scene":                    "res://scenes/world/zone_undercity_north2.tscn",
				"label":                    "Undercity — The Cave-In",
				"area":           "The Undercity",
				"thumbnail_type":           "tunnel_ts",
				"required_protection_level": 1,
				"exits":                    {
					"south": Vector2i(10, 13),
					"east":  Vector2i(11, 12),
					"west":  Vector2i(9, 12),
				},
			},
			Vector2i(10, 11): {
				"scene":                    "res://scenes/world/zone_undercity_north3.tscn",
				"label":                    "Undercity — Main Passage",
				"area":           "The Undercity",
				"thumbnail_type":           "tunnel_ns",
				"required_protection_level": 1,
				"exits":                    {
					"north": Vector2i(10, 10),
				},
			},
			Vector2i(10, 10): {
				"scene":                    "res://scenes/world/zone_undercity_north4.tscn",
				"label":                    "Undercity — The Toad's Lair",
				"area":           "The Undercity",
				"thumbnail_type":           "tunnel_ts",
				"required_protection_level": 1,
				"exits":                    {
					"south": Vector2i(10, 11),
					"east":  Vector2i(11, 10),
					"west":  Vector2i(9, 10),
				},
			},
			Vector2i(9, 14): {
				"scene":                    "res://scenes/world/zone_undercity_west_arm.tscn",
				"label":                    "Undercity — West Passage",
				"area":           "The Undercity",
				"thumbnail_type":           "tunnel_ns",
				"required_protection_level": 1,
				"exits":                    {
					"east":  Vector2i(10, 14),
					"north": Vector2i(9, 13),
				},
			},
			Vector2i(9, 13): {
				"scene":                    "res://scenes/world/zone_undercity_west_s1.tscn",
				"label":                    "Undercity — West Tunnels",
				"area":           "The Undercity",
				"thumbnail_type":           "tunnel_ns",
				"required_protection_level": 1,
				"exits":                    {
					"south": Vector2i(9, 14),
					"north": Vector2i(9, 12),
				},
			},
			Vector2i(9, 12): {
				"scene":                    "res://scenes/world/zone_undercity_west_bypass.tscn",
				"label":                    "Undercity — West Tunnels",
				"area":           "The Undercity",
				"thumbnail_type":           "tunnel_ns",
				"required_protection_level": 1,
				"exits":                    {
					"south": Vector2i(9, 13),
					"north": Vector2i(9, 11),
					"east":  Vector2i(10, 12),
				},
			},
			Vector2i(9, 11): {
				"scene":                    "res://scenes/world/zone_undercity_west_u1.tscn",
				"label":                    "Undercity — West Tunnels",
				"area":           "The Undercity",
				"thumbnail_type":           "tunnel_ns",
				"required_protection_level": 1,
				"exits":                    {
					"south": Vector2i(9, 12),
					"north": Vector2i(9, 10),
				},
			},
			Vector2i(9, 10): {
				"scene":                    "res://scenes/world/zone_undercity_west_exit.tscn",
				"label":                    "Undercity — West Tunnels",
				"area":           "The Undercity",
				"thumbnail_type":           "tunnel_ts",
				"required_protection_level": 1,
				"exits":                    {
					"south": Vector2i(9, 11),
					"east":  Vector2i(10, 10),
					"west":  Vector2i(8, 10),
				},
			},
			Vector2i(8, 10): {
				"scene":                    "res://scenes/world/zone_undercity_west_den.tscn",
				"label":                    "Undercity — Animal Den",
				"area":           "The Undercity",
				"thumbnail_type":           "tunnel_se",
				"required_protection_level": 1,
				"exits":                    {
					"east": Vector2i(9, 10),
				},
			},
		},
	}
	EventBus.player_rested.connect(_on_player_rested)
	EventBus.tutorial_popup_dismissed.connect(_on_tutorial_popup_dismissed)
	EventBus.zone_entered.connect(_on_zone_entered_for_character_creation)

# Character creation now happens at the END of the tutorial, not before it —
# "New Game" starts the player with a light stat spread (just enough to
# survive the escape route) via start_new_tutorial_run(), and player_data
# carries character_created = false the whole way through. The first time the
# player arrives in zone_outskirts_ruins_entry (the tutorial's actual exit
# point, moved 2026-08-10 from zone_ditch_lower when the Outskirts ruins
# chain was added between the rest alcove and the Ditch) with that flag
# still false, this fires the actual character_creation.tscn scene so they
# build their real character having just lived through combat/sneaking, and
# before facing the coyotes on the ruins path ahead.
# Existing saves have no character_created key at all, and default (true)
# there means this never fires for them.
const _TUTORIAL_EXIT_ZONE: String = "res://scenes/world/zone_outskirts_ruins_entry.tscn"
func _on_zone_entered_for_character_creation() -> void:
	if player_data.get("character_created", true):
		return
	if current_zone == null or not is_instance_valid(current_zone):
		return
	if current_zone.scene_file_path != _TUTORIAL_EXIT_ZONE:
		return
	# Stash live player state the same way a normal zone transition/save would —
	# character_creation.tscn has no Player node, so this survives the trip and
	# gets consumed by the next Player._ready() when we return to main.tscn.
	if player != null and is_instance_valid(player):
		player_data["_saved_grid_cell"]    = [player.grid_cell.x, player.grid_cell.y]
		player_data["_saved_hp"]           = player.current_hp
		player_data["_saved_spirit"]       = player.current_spirit
		player_data["_saved_status_effects"] = player.status_effects.duplicate(true)
		var oc = player.get("_oc_status_timer")
		if oc != null:
			player_data["_saved_oc_timer"] = oc
	call_deferred("_go_to_character_creation")

func _go_to_character_creation() -> void:
	get_tree().change_scene_to_file("res://scenes/character_creation/character_creation.tscn")

# "New Game" default — 6 STR/AGI (enough to actually fight/move well in the
# roach and sneak tutorials), 5 in every other stat, 10 in every skill, no
# background. Real character creation happens later, see
# _on_zone_entered_for_character_creation() above.
func start_new_tutorial_run() -> void:
	var skill_names: Array = ["melee","ranged","dodge","convince","intimidate",
		"sneak","sleight_of_hand","alchemy","occultism","smithing","survival","cooking"]
	var default_stats: Dictionary = {
		"strength": 6, "dexterity": 5, "agility": 6, "constitution": 5,
		"intelligence": 5, "willpower": 5, "perception": 5,
	}
	var default_skills: Dictionary = {}
	for s in skill_names: default_skills[s] = 10

	player_data = {
		"name":                   "",
		"stats":                  default_stats,
		"skills":                 default_skills,
		"background":             "",
		"max_hp":                 50,
		"current_hp":             50,
		"equipment": {
			"hand_1": null, "hand_2": null, "head": null,
			"torso": DataManager.get_item("tunic"), "feet": DataManager.get_item("sandals"),
			"back": null, "right_upper_arm": null, "left_upper_arm": null,
			"right_forearm": null, "left_forearm": null, "necklace": null,
			"ring_right_1": null, "ring_right_2": null, "ring_left_1": null, "ring_left_2": null,
		},
		"inventory":              [],
		"known_cooking_recipes":  ["simple_meal"],
		"level":                  1,
		"xp":                     0,
		"unspent_skill_points":   0,
		"unspent_stat_points":    0,
		"feats":                  [],
		"character_created":      false,
	}
	player_data["_saved_grid_cell"] = [40, 29]

	world_pos = Vector2i(-1, 15)
	world_layer = 0
	current_layer = 0
	explored_tiles = {}
	smoke_zones = []
	current_zone = null
	combat_mode = false
	tactical_mode = false
	is_sneaking = false

	auto_save()

# The player starts the escape-route tutorial with an empty quest log —
# find_spiritual_protection is granted once they've been given more context,
# on dismissal of the escape-route exit tutorial popup (see
# zone_escape_route.tscn's ExitTutorialMessage), not at game start.
func _on_tutorial_popup_dismissed(tutorial_id: String) -> void:
	if tutorial_id != "escape_route_exit":
		return
	add_quest({
		"id":          "find_spiritual_protection",
		"title":       "Try to find spiritual protection",
		"description": "The city is dangerous at night without the help of a god or at least a protective talisman. Find a way to protect yourself before you sleep.",
		"threads":     [],
		"completed":   false,
	})

# ── NPC departure tracking ─────────────────────────────────────────────────────
# Called on every rest regardless of which zone is loaded.
# Sets departure flags so NPCs check them in _ready() and skip spawning.
# When an NPC IS loaded in the current zone it handles its own departure via its
# own player_rested connection — game_manager only steps in when the NPC is absent.
func _on_player_rested() -> void:
	# Old Hunter: two-rest sequence once the kill quest thread is completed.
	# Skip if the hunter is present — his own _on_player_rested handles it.
	var hunter_present: bool = false
	if current_zone != null and is_instance_valid(current_zone):
		for child in current_zone.get_children():
			if child.get("entity_name") == "Old Hunter":
				hunter_present = true
				break
	if not hunter_present:
		var hunter_thread_done: bool = false
		for q in player_data.get("quests", []):
			if q.get("id") == "find_spiritual_protection":
				for t in q.get("threads", []):
					if t.get("id") == "hunter_animal_kill" and t.get("completed", false):
						hunter_thread_done = true
		if hunter_thread_done:
			if not player_data.get("hunter_can_leave", false):
				player_data["hunter_can_leave"] = true
			elif not player_data.get("hunter_left", false):
				player_data["hunter_left"] = true

# ── World map helpers ──────────────────────────────────────────────────────────
func get_tile_data(layer: int, pos: Vector2i) -> Dictionary:
	return world_map_data.get(layer, {}).get(pos, {})

func get_adjacent_tile(direction: String) -> Vector2i:
	var exits = get_tile_data(world_layer, world_pos).get("exits", {})
	return exits.get(direction, Vector2i(-1, -1))

func mark_tile_visited(layer: int, pos: Vector2i) -> void:
	if not explored_tiles.has(layer):
		explored_tiles[layer] = {}
	if not explored_tiles[layer].has(pos):
		explored_tiles[layer][pos] = {"visited": false, "encounters": []}
	explored_tiles[layer][pos]["visited"] = true

func add_encounter(layer: int, pos: Vector2i, entity_name: String) -> void:
	if not explored_tiles.has(layer):
		explored_tiles[layer] = {}
	if not explored_tiles[layer].has(pos):
		explored_tiles[layer][pos] = {"visited": true, "encounters": []}
	var list: Array = explored_tiles[layer][pos]["encounters"]
	if not (entity_name in list):
		list.append(entity_name)

func remove_encounter(layer: int, pos: Vector2i, entity_name: String) -> void:
	var list: Array = explored_tiles.get(layer, {}).get(pos, {}).get("encounters", [])
	list.erase(entity_name)

# ── XP / Level system ─────────────────────────────────────────────────────────
# Cumulative XP required to reach each level (index = level number).
# Level 1 starts at 0; level 2 requires 350 total XP; etc.
const XP_THRESHOLDS: Array = [0, 0, 350, 1050, 2250, 4050]

func add_xp(base_xp: int, enemy_level: int = -1) -> void:
	var scaled: int = base_xp if enemy_level < 0 else _scale_enemy_xp(base_xp, enemy_level)
	player_data["xp"] = player_data.get("xp", 0) + scaled
	EventBus.xp_gained.emit(scaled)
	_check_level_up()

func add_note(note: Dictionary, xp: int = 5) -> void:
	var notes: Array = player_data.get("notes", [])
	for n in notes:
		if n.get("id") == note.get("id"):
			return
	notes.append(note)
	player_data["notes"] = notes
	add_xp(xp)
	EventBus.note_added.emit(note.get("id", ""), note.get("title", ""))
	EventBus.journal_updated.emit("note")

# Records a tutorial into the journal's Tutorials tab so the player can
# revisit it later. No XP — unlike add_note(), this is systemic instruction,
# not a lore/exploration reward. Dedupes by id (a player who somehow re-enters
# a trigger's radius won't get a duplicate journal entry).
func has_tutorial(tutorial_id: String) -> bool:
	for t in player_data.get("tutorials", []):
		if t.get("id") == tutorial_id:
			return true
	return false

func add_tutorial(tutorial: Dictionary) -> void:
	if has_tutorial(tutorial.get("id", "")):
		return
	var tutorials: Array = player_data.get("tutorials", [])
	tutorials.append(tutorial)
	player_data["tutorials"] = tutorials
	EventBus.journal_updated.emit("tutorial")

func xp_for_next_level() -> int:
	var lvl: int = player_data.get("level", 1)
	if lvl >= XP_THRESHOLDS.size() - 1:
		return 0
	return XP_THRESHOLDS[lvl + 1] - player_data.get("xp", 0)

func _scale_enemy_xp(base_xp: int, enemy_level: int) -> int:
	var diff: int = enemy_level - player_data.get("level", 1)
	var mult: float
	if   diff >= 3:  mult = 2.0
	elif diff == 2:  mult = 1.5
	elif diff == 1:  mult = 1.25
	elif diff == 0:  mult = 1.0
	elif diff == -1: mult = 0.6
	elif diff == -2: mult = 0.25
	else:            mult = 0.125
	return maxi(1, int(base_xp * mult))

func _check_level_up() -> void:
	var lvl: int = player_data.get("level", 1)
	var xp: int  = player_data.get("xp", 0)
	while lvl < XP_THRESHOLDS.size() - 1 and xp >= XP_THRESHOLDS[lvl + 1]:
		lvl += 1
		_apply_level_up(lvl)
	player_data["level"] = lvl

func _apply_level_up(new_level: int) -> void:
	var stats_dict: Dictionary = player_data.get("stats", {})

	# Set player level now so CON spending during allocation uses the correct level.
	# HP gain is deferred to confirm_levelup_allocation — spending CON during allocation
	# will retroactively recalculate max_hp for the new level, so no double-apply.
	if player != null and is_instance_valid(player):
		player.level = new_level

	# Skill points: half the creation pool, using current INT (not retroactive)
	var int_stat: int   = stats_dict.get("intelligence", 5)
	var skill_pts: int  = 30 + (int_stat - 5) * 5 / 2
	player_data["unspent_skill_points"] = player_data.get("unspent_skill_points", 0) + skill_pts

	# Stat points + feat pick on even levels
	if new_level % 2 == 0:
		player_data["unspent_stat_points"] = player_data.get("unspent_stat_points", 0) + 2
		player_data["unspent_feat_points"] = player_data.get("unspent_feat_points", 0) + 1

	# Snapshot for refund — preserve only if none exists yet (multi-level-up accumulates)
	if not player_data.has("levelup_snapshot"):
		player_data["levelup_snapshot"] = {
			"stats":  player_data.get("stats",  {}).duplicate(),
			"skills": player_data.get("skills", {}).duplicate(),
		}

	EventBus.leveled_up.emit(new_level)

func grant_feat(feat_id: String) -> bool:
	if player_data.get("unspent_feat_points", 0) <= 0:
		return false
	if has_feat(feat_id):
		return false
	var f: Dictionary = DataManager.feats.get(feat_id, {})
	if f.is_empty():
		return false
	var feats: Array = player_data.get("feats", [])
	feats.append({"id": feat_id, "name": f.get("name", feat_id), "description": f.get("description", "")})
	player_data["feats"] = feats
	player_data["unspent_feat_points"] = player_data.get("unspent_feat_points", 0) - 1
	return true

# Spend one unspent stat point on a given stat. Handles CON/INT side-effects.
func spend_stat_point(stat: String) -> bool:
	if player_data.get("unspent_stat_points", 0) <= 0:
		return false
	# Each stat may only receive one point per level-up allocation session.
	var snapshot: Dictionary = player_data.get("levelup_snapshot", {})
	if not snapshot.is_empty():
		var snap_val: int = snapshot.get("stats", {}).get(stat, 5)
		var stats_dict_check: Dictionary = player_data.get("stats", {})
		if stats_dict_check.get(stat, 5) >= snap_val + 1:
			return false
	var stats_dict: Dictionary = player_data.get("stats", {})
	var old_int: int = stats_dict.get("intelligence", 5)
	stats_dict[stat] = stats_dict.get(stat, 5) + 1
	player_data["stats"] = stats_dict
	player_data["unspent_stat_points"] -= 1
	_sync_stat_to_player(stat)

	# CON retroactive: recalculate max HP for all past levels
	if stat == "constitution":
		var lvl: int    = player_data.get("level", 1)
		var con_mod: int = stats_dict.get("constitution", 5) - 5
		var new_max: float = 5.0 * (5 + con_mod) * (lvl + 1)
		var delta: float   = new_max - float(player_data.get("max_hp", 0))
		player_data["max_hp"] = new_max
		if player != null and is_instance_valid(player):
			player.max_hp     = new_max
			player.current_hp = clampf(player.current_hp + delta, 1.0, new_max)

	# INT immediate bonus: adds skill points for this level and going forward
	if stat == "intelligence":
		var new_int: int  = stats_dict.get("intelligence", 5)
		var old_pts: int  = 25 + (old_int - 5) * 5 / 2
		var new_pts: int  = 25 + (new_int - 5) * 5 / 2
		var bonus: int    = new_pts - old_pts
		if bonus > 0:
			player_data["unspent_skill_points"] = player_data.get("unspent_skill_points", 0) + bonus

	return true

# Lock in all spent allocation points, apply deferred HP gain, and clear the refund snapshot.
func confirm_levelup_allocation() -> void:
	if player_data.has("levelup_snapshot"):
		if player_data.get("unspent_skill_points", 0) > 0 \
				or player_data.get("unspent_stat_points", 0) > 0 \
				or player_data.get("unspent_feat_points", 0) > 0:
			return  # can't confirm until every point is spent
		# Apply HP gain using the final stats after all allocation choices.
		# If CON was spent during allocation, that already bumped max_hp retroactively
		# for the new level, so hp_gain here may be 0 or close to it.
		var lvl: int = player_data.get("level", 1)
		var stats: Dictionary = player_data.get("stats", {})
		var con_mod: int = stats.get("constitution", 5) - 5
		var final_max: float = 5.0 * float(5 + con_mod) * float(lvl + 1)
		var current_max: float = float(player_data.get("max_hp", 0.0))
		var hp_gain: float = final_max - current_max
		if hp_gain > 0.0:
			player_data["max_hp"] = final_max
			if player != null and is_instance_valid(player):
				player.max_hp     = final_max
				player.current_hp = clampf(player.current_hp + hp_gain, 1.0, final_max)
	player_data.erase("levelup_snapshot")

# Refund one point from a stat back to unspent_stat_points.
# Blocked if the stat is already at or below the snapshot value.
# INT refund blocked if the bonus skill points have already been spent.
func refund_stat_point(stat: String) -> bool:
	var snapshot: Dictionary   = player_data.get("levelup_snapshot", {})
	if snapshot.is_empty():
		return false
	var snap_stats: Dictionary = snapshot.get("stats", {})
	var stats_dict: Dictionary = player_data.get("stats", {})
	if stats_dict.get(stat, 5) <= snap_stats.get(stat, 5):
		return false

	if stat == "intelligence":
		var old_int: int = stats_dict.get("intelligence", 5)
		var new_int: int = old_int - 1
		var bonus: int   = (25 + (old_int - 5) * 5 / 2) - (25 + (new_int - 5) * 5 / 2)
		if player_data.get("unspent_skill_points", 0) < bonus:
			return false  # INT bonus skill points already spent; can't refund
		player_data["unspent_skill_points"] = player_data.get("unspent_skill_points", 0) - bonus

	stats_dict[stat] = stats_dict.get(stat, 5) - 1
	player_data["stats"] = stats_dict
	player_data["unspent_stat_points"] = player_data.get("unspent_stat_points", 0) + 1
	_sync_stat_to_player(stat)

	if stat == "constitution":
		var lvl: int     = player_data.get("level", 1)
		var con_mod: int = stats_dict.get("constitution", 5) - 5
		var new_max: float = 5.0 * (5 + con_mod) * (lvl + 1)
		var delta: float   = new_max - float(player_data.get("max_hp", 0))
		player_data["max_hp"] = new_max
		if player != null and is_instance_valid(player):
			player.max_hp     = new_max
			player.current_hp = clampf(player.current_hp + delta, 1.0, new_max)

	return true

# Refund one invested skill point back to unspent_skill_points.
func refund_skill_point(skill: String) -> bool:
	var snapshot: Dictionary    = player_data.get("levelup_snapshot", {})
	if snapshot.is_empty():
		return false
	var snap_skills: Dictionary = snapshot.get("skills", {})
	var skills_dict: Dictionary = player_data.get("skills", {})
	if skills_dict.get(skill, 0) <= snap_skills.get(skill, 0):
		return false
	skills_dict[skill] = skills_dict.get(skill, 0) - 1
	player_data["skills"] = skills_dict
	player_data["unspent_skill_points"] = player_data.get("unspent_skill_points", 0) + 1
	return true

# Per-skill cap: 20 at level 1, +10 every level after that (level 2 → 30, level 3 → 40, …)
func skill_cap_for_level(level: int) -> int:
	return 20 + (level - 1) * 10

# Spend one unspent skill point on a given skill.
func spend_skill_point(skill: String) -> bool:
	if player_data.get("unspent_skill_points", 0) <= 0:
		return false
	var skills_dict: Dictionary = player_data.get("skills", {})
	var level: int = player_data.get("level", 1)
	var cap: int = skill_cap_for_level(level)
	if skills_dict.get(skill, 0) >= cap:
		return false
	skills_dict[skill] = skills_dict.get(skill, 0) + 1
	player_data["skills"] = skills_dict
	player_data["unspent_skill_points"] -= 1
	return true

func _sync_stat_to_player(stat: String) -> void:
	if player == null or not is_instance_valid(player):
		return
	var val: int = player_data.get("stats", {}).get(stat, 5)
	match stat:
		"strength":     player.stat_strength     = val
		"dexterity":    player.stat_dexterity    = val
		"agility":      player.stat_agility      = val
		"constitution": player.stat_constitution = val
		"intelligence": player.stat_intelligence = val
		"willpower":    player.stat_willpower    = val
		"perception":   player.stat_perception   = val

func toggle_sneak() -> void:
	is_sneaking = not is_sneaking
	EventBus.sneak_toggled.emit(is_sneaking)

func exit_sneak() -> void:
	if is_sneaking:
		is_sneaking = false
		EventBus.sneak_toggled.emit(false)

# ── Quest helpers ─────────────────────────────────────────────────────────────
func add_quest(quest: Dictionary) -> void:
	if not player_data.has("quests"):
		player_data["quests"] = []
	var quests: Array = player_data["quests"]
	for q in quests:
		if q.get("id") == quest.get("id"):
			return  # already tracked
	quests.append(quest)
	EventBus.journal_updated.emit("quest")

# Appends a bullet-point update to an existing quest. No-op if quest not found.
func update_quest(quest_id: String, update_text: String) -> void:
	for q in player_data.get("quests", []):
		if q.get("id") == quest_id:
			if not q.has("updates"):
				q["updates"] = []
			if update_text not in q["updates"]:
				q["updates"].append(update_text)
				EventBus.journal_updated.emit("quest")
			return

func complete_quest(quest_id: String) -> void:
	for q in player_data.get("quests", []):
		if q.get("id") == quest_id:
			q["completed"] = true
			EventBus.journal_updated.emit("quest")
			return

# ── Thread helpers (sub-quests within a parent quest) ─────────────────────────
func add_quest_thread(parent_id: String, thread: Dictionary) -> void:
	for q in player_data.get("quests", []):
		if q.get("id") == parent_id:
			if not q.has("threads"):
				q["threads"] = []
			for t in q["threads"]:
				if t.get("id") == thread.get("id"):
					return  # already exists
			q["threads"].append(thread)
			EventBus.journal_updated.emit("quest")
			return

func update_quest_thread(parent_id: String, thread_id: String, update_text: String) -> void:
	for q in player_data.get("quests", []):
		if q.get("id") != parent_id:
			continue
		for t in q.get("threads", []):
			if t.get("id") == thread_id:
				if not t.has("updates"):
					t["updates"] = []
				if update_text not in t["updates"]:
					t["updates"].append(update_text)
					EventBus.journal_updated.emit("quest")
				return

func complete_quest_thread(parent_id: String, thread_id: String) -> void:
	for q in player_data.get("quests", []):
		if q.get("id") != parent_id:
			continue
		for t in q.get("threads", []):
			if t.get("id") == thread_id:
				t["completed"] = true
				EventBus.journal_updated.emit("quest")
				return

func has_quest(quest_id: String) -> bool:
	for q in player_data.get("quests", []):
		if q.get("id") == quest_id:
			return true
	return false

func has_quest_thread(parent_id: String, thread_id: String) -> bool:
	for q in player_data.get("quests", []):
		if q.get("id") != parent_id:
			continue
		for t in q.get("threads", []):
			if t.get("id") == thread_id:
				return true
	return false

func is_quest_thread_completed(parent_id: String, thread_id: String) -> bool:
	for q in player_data.get("quests", []):
		if q.get("id") != parent_id:
			continue
		for t in q.get("threads", []):
			if t.get("id") == thread_id:
				return t.get("completed", false)
	return false

# ── Faction contact helpers ───────────────────────────────────────────────────
# Tracks which NPCs have explained their religion/path to the player.
# Used after the premonition dream to build quest threads pointing back to them.
func add_faction_contact(npc_id: String) -> void:
	var contacts: Array = player_data.get("faction_contacts", [])
	if npc_id not in contacts:
		contacts.append(npc_id)
		player_data["faction_contacts"] = contacts

# ── Feat helpers ──────────────────────────────────────────────────────────────
func add_feat(feat: Dictionary) -> void:
	var feats: Array = player_data.get("feats", [])
	for f in feats:
		if f.get("id") == feat.get("id"):
			return   # already have it
	feats.append(feat)
	player_data["feats"] = feats

func has_feat(feat_id: String) -> bool:
	for f in player_data.get("feats", []):
		if f.get("id") == feat_id:
			return true
	return false

# Hunter-Gatherer feat: chance to double the yield from a survival harvest (carving
# a corpse or picking a plant). Scales linearly with invested survival skill —
# 10% at 20, 100% at 200 (and clamped to that range outside it).
func roll_harvest_double() -> bool:
	if not has_feat("harvester"):
		return false
	var survival: float = float(player_data.get("skills", {}).get("survival", 0))
	var chance: float = clampf(10.0 + (survival - 20.0) * (90.0 / 180.0), 0.0, 100.0)
	return randf() * 100.0 < chance

# ── Path helpers ───────────────────────────────────────────────────────────────
func get_save_path(slot: int) -> String:
	match slot:
		0:              return "user://save_quick.json"
		PREV_QUICK_SLOT: return "user://save_quick_prev.json"
		AUTO_SLOT:       return "user://save_auto.json"
		PREV_AUTO_SLOT:  return "user://save_auto_prev.json"
		_:               return "user://save_%d.json" % slot

# ── Metadata sidecar ─────────────────────────────────────────────────────────
# A save file can be several MB (fog-of-war revealed-cell data dwarfs everything
# else in player_data once a few zones are explored). get_save_info() used to
# JSON.parse_string() the *entire* save just to read slot_name/character_name/
# timestamp — done for every slot, every time the Save or Load panel opened,
# which hung the whole engine for several seconds once saves got large enough.
# This tiny sidecar carries just those three fields so listing slots never
# touches the heavy file.
func _meta_path(slot: int) -> String:
	return get_save_path(slot).replace(".json", ".meta.json")

func _write_meta(slot: int, slot_name: String, character_name: String, timestamp: String) -> void:
	var file = FileAccess.open(_meta_path(slot), FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({
		"slot_name": slot_name, "character_name": character_name, "timestamp": timestamp,
	}))
	file.close()

# ── Serialization helpers for explored_tiles (Vector2i keys → strings) ────────
func _serialize_explored() -> Dictionary:
	var result: Dictionary = {}
	for layer_key in explored_tiles:
		result[str(layer_key)] = {}
		for pos_key in explored_tiles[layer_key]:
			result[str(layer_key)]["%d,%d" % [pos_key.x, pos_key.y]] = explored_tiles[layer_key][pos_key]
	return result

func _deserialize_explored(data: Dictionary) -> void:
	explored_tiles = {}
	for layer_str in data:
		var layer_int = int(layer_str)
		explored_tiles[layer_int] = {}
		for pos_str in data[layer_str]:
			var parts = pos_str.split(",")
			var pos = Vector2i(int(parts[0]), int(parts[1]))
			explored_tiles[layer_int][pos] = data[layer_str][pos_str]

# ── Save ───────────────────────────────────────────────────────────────────────
func _write_save(slot: int, slot_name: String) -> void:
	var grid_cell = [40, 40]
	if player != null and "grid_cell" in player:
		grid_cell = [player.grid_cell.x, player.grid_cell.y]
	elif player_data.has("_saved_grid_cell"):
		var sc = player_data["_saved_grid_cell"]
		grid_cell = [sc[0], sc[1]]

	# Snapshot runtime state that lives on the Player node into player_data so
	# it persists across saves. These are cleared back out after writing so the
	# live player_data dict stays clean.
	# Save fog-of-war for the current zone before writing
	var cur_ts := current_zone as TileScene if is_instance_valid(current_zone) else null
	if cur_ts != null:
		var tile_data_fow: Dictionary = get_tile_data(world_layer, world_pos)
		var scene_path_fow: String = tile_data_fow.get("scene", str(world_pos))
		cur_ts.save_fov_data(scene_path_fow)

	var stashed_keys: Array = []
	if player != null and is_instance_valid(player):
		player_data["_saved_hp"] = player.current_hp
		stashed_keys.append("_saved_hp")
		player_data["_saved_spirit"] = player.current_spirit
		stashed_keys.append("_saved_spirit")
		if player.get("status_effects") != null:
			player_data["_saved_status_effects"] = player.status_effects.duplicate(true)
			stashed_keys.append("_saved_status_effects")
		var oc = player.get("_oc_status_timer")
		if oc != null:
			player_data["_saved_oc_timer"] = oc
			stashed_keys.append("_saved_oc_timer")

	var dt = Time.get_datetime_dict_from_system()
	var data = {
		"slot_name":      slot_name,
		"character_name": player_data.get("name", "Unknown"),
		"timestamp":      "%d-%02d-%02d %02d:%02d" % [dt.year, dt.month, dt.day, dt.hour, dt.minute],
		"player_data":    player_data,
		"grid_cell":      grid_cell,
		"layer":          world_layer,
		"world_pos":      [world_pos.x, world_pos.y],
		"explored_tiles": _serialize_explored(),
	}
	var file = FileAccess.open(get_save_path(slot), FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	_write_meta(slot, slot_name, data["character_name"], data["timestamp"])
	GameLogger.info("SAVE", "Wrote slot %d (%s) — grid_cell %s, world_pos %s, hp %s" % [
		slot, slot_name, str(grid_cell), str(world_pos), str(player_data.get("_saved_hp", "?"))])

	for key in stashed_keys:
		player_data.erase(key)

func save_to_slot(slot: int) -> void:
	# Before overwriting the quick save, shift it to the previous-quick-save slot.
	# Copies the raw file instead of parsing/re-stringifying it — the save can be
	# several MB of fog-of-war data, and re-parsing it on every quicksave was a
	# needless hitch (same underlying cost as the get_save_info() freeze above).
	if slot == 0 and FileAccess.file_exists(get_save_path(0)):
		DirAccess.copy_absolute(get_save_path(0), get_save_path(PREV_QUICK_SLOT))
		var info: Dictionary = get_save_info(0)
		_write_meta(PREV_QUICK_SLOT, "Prev. Quick Save", info["character_name"], info["timestamp"])
	var name: String = "Quick Save" if slot == 0 else "Save %d" % slot
	_write_save(slot, name)

func auto_save() -> void:
	# Shift current auto save → previous auto save slot before writing new one
	if FileAccess.file_exists(get_save_path(AUTO_SLOT)):
		DirAccess.copy_absolute(get_save_path(AUTO_SLOT), get_save_path(PREV_AUTO_SLOT))
		var info: Dictionary = get_save_info(AUTO_SLOT)
		_write_meta(PREV_AUTO_SLOT, "Prev. Auto Save", info["character_name"], info["timestamp"])
	_write_save(AUTO_SLOT, "Auto Save")

# ── Load ───────────────────────────────────────────────────────────────────────
func load_from_slot(slot: int) -> void:
	var path = get_save_path(slot)
	if not FileAccess.file_exists(path):
		return
	var file = FileAccess.open(path, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed == null:
		return
	# Loading mid-combat would otherwise leave combat_mode/active stuck true
	# after the scene reload, pointing at participants from the zone that's
	# about to be discarded — that silently swallows all input in the new zone.
	CombatManager.reset_for_load()
	# Smoke zones are runtime state on GameManager (not serialized) — clear them
	# so phantom smoke from the abandoned session doesn't bleed into the new scene.
	smoke_zones.clear()
	# Sneak flag lives on GameManager (not in player_data) — reset it so the new
	# scene always starts with the player visible.
	is_sneaking = false
	player_data = parsed.get("player_data", {})
	world_layer = parsed.get("layer", 0)
	var cell    = parsed.get("grid_cell", [40, 40])
	player_data["_saved_grid_cell"] = cell
	var wp = parsed.get("world_pos", [10, 14])
	world_pos = Vector2i(int(wp[0]), int(wp[1]))
	_deserialize_explored(parsed.get("explored_tiles", {}))
	GameLogger.info("SAVE", "Loaded slot %d — grid_cell %s, world_pos %s, layer %d, hp %s" % [
		slot, str(cell), str(world_pos), world_layer, str(player_data.get("_saved_hp", "?"))])

# ── Info / existence ───────────────────────────────────────────────────────────
func get_save_info(slot: int) -> Dictionary:
	var base = {
		"exists": false, "slot": slot,
		"slot_name": (
			"Quick Save"      if slot == 0
			else "Prev. Quick Save" if slot == PREV_QUICK_SLOT
			else "Auto Save"       if slot == AUTO_SLOT
			else "Prev. Auto Save" if slot == PREV_AUTO_SLOT
			else "Save %d" % slot),
		"character_name": "", "timestamp": "",
	}
	var path = get_save_path(slot)
	if not FileAccess.file_exists(path):
		return base
	# Fast path: the metadata sidecar (see _write_meta) is tiny regardless of how
	# big the actual save is.
	var meta_file = FileAccess.open(_meta_path(slot), FileAccess.READ)
	if meta_file != null:
		var meta = JSON.parse_string(meta_file.get_as_text())
		meta_file.close()
		if meta != null:
			return {
				"exists":         true,
				"slot":           slot,
				"slot_name":      meta.get("slot_name",      base["slot_name"]),
				"character_name": meta.get("character_name", "Unknown"),
				"timestamp":      meta.get("timestamp",      ""),
			}
	# No sidecar (save predates this fix, or it was deleted) — fall back to a full
	# parse just this once, then write the sidecar so every call after this is fast.
	var file = FileAccess.open(path, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed == null:
		return base
	var info: Dictionary = {
		"exists":         true,
		"slot":           slot,
		"slot_name":      parsed.get("slot_name",      base["slot_name"]),
		"character_name": parsed.get("character_name", "Unknown"),
		"timestamp":      parsed.get("timestamp",      ""),
	}
	_write_meta(slot, info["slot_name"], info["character_name"], info["timestamp"])
	return info

func delete_save(slot: int) -> void:
	var path = get_save_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	var meta = _meta_path(slot)
	if FileAccess.file_exists(meta):
		DirAccess.remove_absolute(meta)

func has_any_save() -> bool:
	for i in range(SLOT_COUNT + 1):   # slots 0–5
		if FileAccess.file_exists(get_save_path(i)):
			return true
	for slot in [PREV_QUICK_SLOT, AUTO_SLOT, PREV_AUTO_SLOT]:
		if FileAccess.file_exists(get_save_path(slot)):
			return true
	return false

# ── Smoke zone helpers ────────────────────────────────────────────────────────

func add_smoke_zone(center: Vector2i, radius: int, turns: int) -> void:
	smoke_zones.append({"center": center, "radius": radius, "turns_remaining": turns})
	EventBus.smoke_zones_changed.emit()
	if current_zone != null and current_zone.has_method("queue_redraw"):
		current_zone.queue_redraw()

func is_in_smoke(cell: Vector2i) -> bool:
	for zone in smoke_zones:
		var c: Vector2i = zone["center"]
		var r: int = zone["radius"]
		if maxi(abs(cell.x - c.x), abs(cell.y - c.y)) <= r:
			return true
	return false

func path_crosses_smoke(from_cell: Vector2i, to_cell: Vector2i) -> bool:
	var dx: int = to_cell.x - from_cell.x
	var dy: int = to_cell.y - from_cell.y
	var steps: int = maxi(abs(dx), abs(dy))
	if steps == 0:
		return is_in_smoke(from_cell)
	for i in range(steps + 1):
		var t: float = float(i) / float(steps)
		var cx: int = int(round(from_cell.x + dx * t))
		var cy: int = int(round(from_cell.y + dy * t))
		if is_in_smoke(Vector2i(cx, cy)):
			return true
	return false

func tick_smoke_zones() -> void:
	var changed := false
	var i: int = smoke_zones.size() - 1
	while i >= 0:
		smoke_zones[i]["turns_remaining"] -= 1
		if smoke_zones[i]["turns_remaining"] <= 0:
			smoke_zones.remove_at(i)
			changed = true
		i -= 1
	if changed:
		EventBus.smoke_zones_changed.emit()
		if current_zone != null and current_zone.has_method("queue_redraw"):
			current_zone.queue_redraw()

func clear_weapon_poison() -> void:
	var equip: Dictionary = player_data.get("equipment", {})
	for slot in ["hand_1", "hand_2"]:
		var item = equip.get(slot)
		if item != null and item.get("poisoned", false):
			item.erase("poisoned")

# Any torch that's been equipped (and thus activated) burns out at the next
# rest, however long it was actually carried for.
func burn_out_torches() -> void:
	var equip: Dictionary = player_data.get("equipment", {})
	var burned: bool = false
	for slot in ["hand_1", "hand_2"]:
		var item = equip.get(slot)
		if item != null and item.get("light_source", false) and item.get("torch_activated", false):
			equip[slot] = null
			burned = true
	if burned:
		EventBus.inventory_changed.emit()
