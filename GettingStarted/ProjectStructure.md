# Godot 4 Project Structure
## Frontier Fantasy CRPG

This document defines the folder layout and purpose of every major component.
All paths are relative to `res://` (the Godot project root).

---

## Top-Level Layout

```
res://
├── assets/
├── resources/
├── scenes/
├── scripts/
└── project.godot
```

---

## assets/
Raw imported files. Godot imports these automatically. You never reference them directly in code — use `resources/` for that.

```
assets/
├── sprites/
│   ├── characters/       # Sprite sheets / frames for player, NPCs, enemies
│   ├── objects/          # Interactable and blocking object art
│   ├── tiles/            # Background tiles, world map thumbnails
│   └── ui/               # Icons, panel borders, button art
├── audio/
│   ├── music/
│   └── sfx/
└── fonts/
```

---

## resources/
Godot Resource files (`.tres` / `.res`). These are structured data objects — think of them as the game's database rows. You define a resource type once in a script, then fill out instances of it here.

```
resources/
├── characters/           # Saved character data (player saves, NPC templates)
├── items/                # Item definitions (weapon stats, container contents, etc.)
├── skills/               # Skill definitions (name, governing stats, description)
├── feats/                # Feat definitions
├── paths/                # Trainer path and transhumanist path definitions
└── tiles/                # Tile metadata (which edges connect, notes, explored state)
```

---

## scenes/
Godot Scenes (`.tscn`). Every visible or interactive thing in the game is a scene.
Each scene has a root node and an attached script from `scripts/`.

```
scenes/
├── main.tscn                        # Entry point; loads other scenes
│
├── character_creation/
│   └── character_creation.tscn      # Stat allocation, background pick, feat pick
│
├── world/
│   ├── tile_scene.tscn              # A single area/tile the player walks around in
│   └── world_map.tscn               # The layered overview map (UI)
│
├── entities/
│   ├── entity.tscn                  # Base entity (superclass scene)
│   ├── player.tscn                  # Player character (extends entity)
│   ├── npc.tscn                     # Humanoid NPC (extends entity)
│   └── enemy.tscn                   # Enemy (extends entity)
│
├── objects/
│   ├── interactable_object.tscn     # Base interactable (door, container, computer…)
│   └── blocking_object.tscn         # Non-interactable blocker (rock, tree, building)
│
└── ui/
    ├── hud.tscn                     # Always-on screen: alt-highlight, map button, etc.
    ├── character_sheet.tscn         # Stats, modifiers, active paths, feats
    ├── skills_panel.tscn            # Skill list with values and governing stats
    ├── inventory.tscn               # Inventory grid + equipment slots
    ├── world_map_ui.tscn            # Full world map overlay
    └── interaction_panel.tscn       # Object/dialogue interaction window
```

---

## scripts/
GDScript files (`.gd`). Each scene has one attached script. Scripts in `autoloads/`
are global singletons — always loaded, accessible from anywhere.

```
scripts/
│
├── autoloads/                       # Global singletons (registered in Project Settings)
│   ├── game_manager.gd              # Game state: current tile, turn mode, scene transitions
│   ├── event_bus.gd                 # Signal hub — decoupled communication between systems
│   └── data_manager.gd             # Loads and provides access to resource data
│
├── entities/
│   ├── entity.gd                    # Base class: stats, skills, inventory, position, tags
│   ├── humanoid.gd                  # Extends entity: humanoid-specific logic
│   ├── player.gd                    # Extends humanoid: input handling, camera follow
│   ├── npc.gd                       # Extends humanoid: dialogue, schedule, faction
│   └── enemy.gd                     # Extends humanoid: AI, detection, aggro
│
├── world/
│   ├── tile_scene.gd                # Manages objects, NPCs, and pathfinding in one tile
│   ├── tile_manager.gd              # Handles tile transitions (edge walking, layer changes)
│   └── world_map.gd                 # World map data: explored state, notes, connections
│
├── objects/
│   ├── interactable_object.gd       # Base: is_interactable, blocks_movement, on_interact()
│   └── door.gd                      # Extends interactable: toggles blocks_movement on use
│
├── systems/
│   ├── pathfinding.gd               # A* grid pathfinding; reads blocks_movement tags
│   ├── combat_manager.gd            # Turn order, action resolution, combat state
│   ├── dialogue_manager.gd          # Dialogue tree loading, branching, skill checks
│   └── interaction_manager.gd       # Routes clicks → dialogue or object interaction panel
│
├── ui/
│   ├── hud.gd                       # Alt-key highlight trigger, menu button handlers
│   ├── character_sheet.gd           # Reads entity data; displays stats/modifiers/feats
│   ├── skills_panel.gd              # Reads skill list; calculates and displays totals
│   ├── inventory_ui.gd              # Renders inventory grid and equipment slots
│   ├── world_map_ui.gd              # Renders layered map, handles hover notes, layer nav
│   └── interaction_panel.gd         # Displays object descriptions and player options
│
└── character_creation/
    └── character_creation.gd        # Point-buy logic, background selection, skill allocation
```

---

## Key Architecture Notes

### Autoloads (Singletons)
Three global scripts are always running. You register these in **Project Settings → Autoload**.

| Singleton | What it does |
|---|---|
| `GameManager` | Tracks game state (current tile, current layer, combat mode on/off, active player). Handles scene transitions. |
| `EventBus` | A central signal hub. Systems talk to each other by emitting and listening to signals here, rather than holding direct references to each other. |
| `DataManager` | Loads resource files (items, skills, feats, paths) at startup and provides lookup functions. |

### Entity Inheritance Chain
```
entity.gd          ← base stats, inventory, tags
  └── humanoid.gd  ← humanoid stat block, skill list, equipment slots
        ├── player.gd   ← player input, camera
        ├── npc.gd      ← dialogue, faction, AI schedule
        └── enemy.gd    ← combat AI, detection radius
```

### Scene ↔ Script Pairing
Every `.tscn` file has exactly one `.gd` file attached to its root node.
The scene defines structure (nodes, layout); the script defines behavior.

### MVP Build Order
1. `entity.gd` + `humanoid.gd` — data model first, no visuals yet
2. `character_creation.tscn/.gd` — creates and stores a player character resource
3. `tile_scene.tscn/.gd` + `pathfinding.gd` — isometric grid, right-click movement
4. `player.gd` — place player on grid, move with pathfinding
5. `hud.gd` + Alt-key highlight
6. `character_sheet`, `skills_panel`, `inventory_ui` — read-only menus
7. `world_map_ui` — empty layered map with layer navigation

---

## Setup Checklist (Before Writing Any Code)

- [ ] Download and install **Godot 4** (stable) from godotengine.org
- [ ] Create a new project, name it (working title TBD)
- [ ] Set the renderer to **Compatibility** (best for 2D pixel art)
- [ ] Create the folder structure above manually in the Godot FileSystem panel
- [ ] Register the three autoloads in Project Settings → Autoload
- [ ] Set the default scene to `scenes/main.tscn`
