extends Node
# EventBus — central signal hub
# All cross-system communication goes through here.

signal combat_started(participants: Array)
signal combat_ended(victor_side: String)   # "player" | "enemy" | "draw"
signal turn_started(entity: Node)
signal turn_ended(entity: Node)
signal tile_changed(tile_id: String, layer: int)
signal interaction_triggered(entity: Node, action_id: String)
signal show_context_menu(entity: Node, options: Array, screen_pos: Vector2)
signal highlight_toggled(active: bool)
signal entity_hovered(entity)   # entity = Node or null
signal zone_exit_requested(direction: String)
signal zone_entered                                              # fired after the new zone is fully set up
signal npc_encountered(npc_name: String)
signal damage_dealt(entity: Node, amount: int, source: String)  # source: "attack"|"bleed"
signal attack_resolved(attacker: Node, hit: bool)              # fired after every attack attempt (hit or miss)
signal attack_started(attacker: Node, defender: Node)          # fired the moment an attack is committed (AP spent)
signal resources_changed(entity: Node)                         # fired whenever AP or MP is spent
signal combat_participant_added(entity: Node)                  # fired when an enemy joins an already-active combat
signal status_applied(entity: Node, status_name: String)
signal status_cleared(entity: Node, status_name: String)
signal combat_log(entry: String)   # fired for every loggable combat event
signal open_crafting_ui(entity: Node)   # entity = the NPC that opened crafting
signal crafting_ui_closed(entity: Node) # entity = same NPC, fired when player closes panel
# shop_items: [{id, price}] the merchant sells to the player.
# buy_list: [{id or material_type, price, remaining}] what the merchant will
# buy from the player right now — pass [] for a merchant that buys nothing.
# on_sale(item): called once a sale to the merchant completes, so the caller
# can persist its own remaining-quantity bookkeeping (e.g. a daily limit).
signal open_shop_ui(merchant: Node, shop_items: Array, buy_list: Array, on_sale: Callable)
signal dialogue_opened(entity: Node)    # fired when the dialogue panel becomes visible
signal dialogue_closed(entity: Node)    # fired when the dialogue panel is dismissed
signal examine_panel_opened             # fired when the object/examine panel becomes visible
signal examine_panel_closed             # fired when the object/examine panel is dismissed
signal player_died                      # fired once when player HP first reaches 0
signal damage_floater(entity: Node, text: String, color: Color)  # floating combat text
signal open_rest_ui(hunter_camp: bool)  # fired to open the rest panel (hunter_camp = complete quest on rest)
signal open_inn_rest_ui                 # fired to open the rest panel in inn mode (coin cost, food provided)
signal open_elder_rest_ui               # fired to open the rest panel with food provided free (elder's fire)
signal open_smith_rest_ui               # fired to open the rest panel with food provided free (smith's forge)
signal open_spell_pick_ui(spell_ids: Array)  # fired to open the pyromancy spell pick panel
signal open_smithing_pick_ui(options: Array) # fired to open the smithing property pick panel; options: [{id, name, description, recipe_id}]
signal smithing_pick_made(pick_id: String)   # fired when player chooses a smithing property
signal player_rested                    # fired after a successful rest
signal xp_gained(amount: int)           # fired whenever XP is awarded
signal leveled_up(new_level: int)       # fired each time the player gains a level
signal sneak_toggled(active: bool)      # fired when player toggles sneak mode
signal tactical_started(participants: Array)  # fired when tactical (non-combat) turn mode begins
signal tactical_ended()                       # fired when tactical mode ends
signal world_layer_changed(new_layer: int)    # fired when player moves between map layers (ladders, etc.)
signal show_range_ring(center_cell: Vector2i, range: int)  # fired by CombatHUD to display a range diamond
signal hide_range_ring()                                   # fired to clear the range diamond
signal smoke_zones_changed                                 # fired when smoke zones are added or expire
signal note_added(note_id: String, note_title: String)     # fired when a new journal note is discovered
signal journal_updated(kind: String)                         # "quest" | "note" | "tutorial" — fired on any quest, note, or tutorial change
signal tutorial_popup_requested(tutorial_id: String, title: String, body: String)   # fired by tutorial_trigger.gd; HUD shows a dismissible popup
signal tutorial_popup_dismissed(tutorial_id: String)   # fired by HUD's Continue button; gates (e.g. Enemy.tutorial_gate_id) unlock on this, not on the request
signal inventory_changed                                    # fired when player inventory is modified outside the shop/craft UI
signal player_moved(cell: Vector2i)                         # fired each time the player steps to a new grid cell
signal los_blockers_changed                                  # fired when a door/gate opens or closes
signal light_levels_changed                                  # fired when TileScene recomputes per-cell light (source added/removed/moved)
signal open_dream_scene                                      # fired after first protected rest to show the premonition dream
signal show_move_range(grey_cells: Array, yellow_cells: Array, enemy_cells: Array)  # BFS reachable tiles this turn
signal hide_move_range()
signal show_path_preview(path: Array)                        # ghost path tiles while hovering
signal hide_path_preview()
signal show_attack_range_overlay(center: Vector2i, r: int, inner_r: int)  # red ring on attack button hover; inner_r=-1 means no inner ring
signal blast_tag_detonation(center: Vector2i, radius: int)               # orange flash visual when a blast tag detonates
signal hide_attack_range_overlay()
signal crime_witnessed(victim: Node)  # fired when an is_citizen NPC is first made hostile (i.e. attacked)
signal overlay_panel_opened   # pause/save/load panel became visible — combat HUD panels yield input
signal overlay_panel_closed   # all of the above hidden — combat HUD panels resume input
