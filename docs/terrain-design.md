# Terrain System Refactor – Design Document

Last updated: 2025-08-22

## Goals

- Introduce an abstract terrain system so different race terrains can be swapped without touching the simulation core.
- Keep physics stable and performant (single ground body when possible, few shapes, predictable friction).
- Maintain current preset-driven UX (Area presets like Grassland) and backward compatibility with `set_area_config`.
- Keep deterministic runs when provided a seed.

## TL;DR

- Add a Terrain Manager that owns a Terrain Generator.
- Generators implement a small interface: generate → builds ground/obstacles; clear → removes them; get spawn/ground accessors.
- Presets map to a TerrainProfile (friction, length, visuals, obstacle params, seed).
- CarSimulation delegates terrain creation to the manager.

## Concepts and Contracts

- TerrainProfile (data)
  - Type: Resource (scripts/terrain/TerrainProfile.gd)
  - Purpose: Immutable config bundle passed to a generator.
  - Fields (minimal):
    - name: String
    - seed: int
    - ground_length: float
    - friction: float
    - ground_height: float (y baseline)
    - color_ground: Color
    - color_obstacle: Color
    - obstacle_count: int
    - obstacle_params: Dictionary (per-generator free-form)

- TerrainGenerator (logic)
  - Type: Resource (scripts/terrain/TerrainGeneratorBase.gd → abstract) with concrete subclasses.
  - Contract:
    - generate(parent: Node2D, profile: TerrainProfile) → TerrainHandle
    - clear(handle: TerrainHandle) → void
  - Notes:
    - Prefer a single StaticBody2D for ground with one or few CollisionShape2D/CollisionPolygon2D children.
    - All terrain bodies on collision_layer 1, collision_mask 0.

- TerrainHandle (opaque)
  - Type: Dictionary or small class (GDScript class) describing what was built so it can be cleared quickly.
  - Suggested fields:
    - root: Node2D (container with group "terrain")
    - ground: StaticBody2D
    - start_position: Vector2
    - bounds: Rect2

- TerrainManager (integration)
  - Type: Node (scripts/terrain/TerrainManager.gd)
  - Responsibilities:
    - Hold current generator + profile.
    - Build/clear lifecycle.
    - Provide accessors used by `CarSimulation` (ground body, start position).

### Minimal Interface (contract)

- TerrainGeneratorBase
  - Inputs: parent: Node2D, profile: TerrainProfile
  - Outputs: TerrainHandle
  - Errors: Must handle invalid params gracefully (clamp lengths, counts ≥ 0, etc.)
  - Success criteria: ground exists and spans start to start + ground_length; all terrain on layer 1.

- TerrainManager
  - Methods:
    - set_profile(profile: TerrainProfile) → void
    - set_generator(generator: TerrainGeneratorBase) → void
    - rebuild(parent: Node2D) → void
    - get_ground() → StaticBody2D
    - get_start_position() → Vector2

## Proposed Class Layout

- scripts/terrain/TerrainProfile.gd (Resource)
  - class_name TerrainProfile
  - export vars for all fields above with sensible defaults.

- scripts/terrain/TerrainGeneratorBase.gd (Resource)
  - class_name TerrainGeneratorBase
  - virtual func generate(parent: Node2D, profile: TerrainProfile) -> Dictionary: pass
  - virtual func clear(handle: Dictionary) -> void: pass

- Generators (Resource subclasses)
  - FlatTerrainGenerator.gd
    - Builds: one long ground RectangleShape2D at y=ground_height.
  - BumpsTerrainGenerator.gd
    - Builds: repeated rectangular bumps using obstacle_count and height/width params.
  - RampTerrainGenerator.gd
    - Builds: periodic ramps (inclined rectangles) with frequency/angle params.
  - NoiseTerrainGenerator.gd
    - Builds: a CollisionPolygon2D heightmap via OpenSimplexNoise or seeded RNG.
    - Performance note: Limit vertex count; chunk if needed.

- scripts/terrain/TerrainManager.gd (Node)
  - class_name TerrainManager
  - Holds: var profile: TerrainProfile; var generator: TerrainGeneratorBase; var handle: Dictionary
  - Methods: set_profile, set_generator, rebuild(parent), clear(), get_ground, get_start_position.

## Integration with CarSimulation.gd

Current state:

- CarSimulation handles terrain in `setup_ground()` + `_add_terrain_obstacles()` and uses `area_config` via `AreaConfigs.get_preset(name)`.

Refactor plan:

1. Create TerrainProfile and TerrainGenerators as above.
1. Add TerrainManager as a child of `CarSimulation` or compose it inside the script.
1. Replace `setup_ground()` and `_add_terrain_obstacles()` with a call to `terrain_manager.rebuild(self)`.
1. Keep `set_area_config(config: Dictionary)` API for compatibility. Translate the `config` to a `TerrainProfile`, and choose the generator based on `config.get("type", "flat")` or a mapping table.
1. Expose `get_ground()` if needed by other subsystems.

Sketch (usage):

```gdscript
# In CarSimulation.gd
@onready var terrain_manager := TerrainManager.new()

func _ready():
    add_child(terrain_manager)
    # init from AreaConfigs
    var profile := TerrainProfile.new()
    _apply_area_config_to_profile(profile, area_config)
    var gen := FlatTerrainGenerator.new() # or based on area
    terrain_manager.set_profile(profile)
    terrain_manager.set_generator(gen)
    terrain_manager.rebuild(self)
```

## Backward Compatibility

- `set_area_config(config)` continues to work.
- Default generator is Flat or Bumps to mimic current behavior.
- Collision layers and friction stay identical to today.

## Performance Notes

- Prefer a single StaticBody2D for the main ground.
- Use a modest number of shapes. For heightmaps, cap vertex count, or chunk into ~3–5 polygons.
- Reuse materials (PhysicsMaterial) across shapes to avoid allocations.

## Determinism

- TerrainProfile carries a `seed`. Generators should use this with Godot’s RNG or OpenSimplexNoise.
- Given the same profile, the terrain is identical.

## Edge Cases

- obstacle_count = 0 → just flat ground.
- ground_length < viewport width → still ensure spawn area is safe.
- friction outside [0.2, 2.0] → clamp to safe range.
- Extreme obstacle sizes → clamp height, widths.

## Migration Plan (incremental)

Scaffolding: add TerrainProfile, TerrainGeneratorBase, TerrainManager; implement FlatTerrainGenerator to match current flat track.

Swap-in: replace CarSimulation terrain setup with TerrainManager calls; add config→profile mapping.

Parity: implement BumpsTerrainGenerator to replicate `_add_terrain_obstacles()` behavior.

Extensions: add Ramp and Noise generators.

UX: optionally expose terrain type and seed in Main UI.

## Testing

- Unit-like checks in `CarSimulation`:
  - After rebuild, `terrain_manager.get_ground()` is valid and on layer 1.
  - Bounds cover at least [start_x, start_x + ground_length].
  - Friction equals profile.friction.
- Smoke test: Build three terrains in a row; ensure old terrain is cleared (no leaked `RigidBody2D/StaticBody2D`).

## Open Questions

- Should TerrainProfile be saved as `.tres` assets for presets? (Recommended for iteration.)
- Do we want terrain-specific scoring modifiers (e.g., bonus on ramps)? If yes, add optional hooks on the generator.
- Should the manager emit a `terrain_rebuilt(profile)` signal for UI hooks?

## Appendix – File map (proposed)

- scripts/terrain/
  - TerrainProfile.gd
  - TerrainGeneratorBase.gd
  - TerrainManager.gd
  - generators/
    - FlatTerrainGenerator.gd
    - BumpsTerrainGenerator.gd
    - RampTerrainGenerator.gd
    - NoiseTerrainGenerator.gd

```gdscript
# TerrainGeneratorBase.gd (stub)
class_name TerrainGeneratorBase
extends Resource

func generate(parent: Node2D, profile) -> Dictionary:
    push_error("Not implemented")
    return {}

func clear(handle: Dictionary) -> void:
    # Default clear: free root if present
    if handle.has("root") and is_instance_valid(handle.root):
        handle.root.queue_free()
```

```gdscript
# TerrainManager.gd (stub)
class_name TerrainManager
extends Node

var profile
var generator: TerrainGeneratorBase
var handle: Dictionary = {}

func set_profile(p):
    profile = p

func set_generator(g: TerrainGeneratorBase):
    generator = g

func rebuild(parent: Node2D):
    clear()
    if generator and profile:
        handle = generator.generate(parent, profile)

func clear():
    if generator and handle:
        generator.clear(handle)
        handle = {}

func get_ground() -> StaticBody2D:
    return handle.get("ground", null)

func get_start_position() -> Vector2:
    return handle.get("start_position", Vector2.ZERO)
```
