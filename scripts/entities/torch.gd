extends Node
class_name Torch
# A player-carried light source. Instantiated as a child of the Player when a
# light_source-flagged item is equipped, freed when unequipped (or freed
# automatically along with the Player on zone transition). Re-registers its
# position whenever the carrier moves.

const BRIGHT_RADIUS: int = 4
const DIM_RADIUS: int = 7

var _carrier: Node = null
var _tile_scene: TileScene = null

func attach(carrier: Node, tile_scene: TileScene) -> void:
	_carrier = carrier
	_tile_scene = tile_scene
	EventBus.player_moved.connect(_on_carrier_moved)
	_tile_scene.register_light_source(self, carrier.grid_cell, BRIGHT_RADIUS, DIM_RADIUS)

func detach() -> void:
	if _tile_scene != null:
		_tile_scene.unregister_light_source(self)
	if EventBus.player_moved.is_connected(_on_carrier_moved):
		EventBus.player_moved.disconnect(_on_carrier_moved)
	_carrier = null
	_tile_scene = null

func _on_carrier_moved(cell: Vector2i) -> void:
	if _tile_scene != null:
		_tile_scene.update_light_source_position(self, cell)

func _exit_tree() -> void:
	detach()
