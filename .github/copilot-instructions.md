# Car Evolution Simulation – Copilot Instructions

These are workspace instructions for GitHub Copilot. Use this as persistent context when proposing code, refactors, or docs in this repository.

## Project Overview
Genetic algorithm-based car evolution simulator built in Godot 4. Cars are defined by alphanumeric DNA strings that translate deterministically into chassis and powertrain. Populations race, are scored, and evolve over generations.

## Important Godot Resource Path Conventions
- Scripts live under `res://scripts/` and scenes under `res://scenes/`.
- When loading or preloading, always use full paths:
  - Correct: `preload("res://scenes/MainMenu.tscn")`
  - Correct: `load("res://scripts/CarSimulation.gd")`
  - Avoid root-relative shortcuts like `res://MainMenu.tscn` for files inside `scenes/`.
- Use typed nodes and signals where practical (Godot 4).

## Core Architecture

### DNA System (String-Based)
- Single alphanumeric DNA string → translated into component sequences.
- New format example: "A3x9K2m" → maps to Frame and Powertrain sequences.
- Translation rules:
  - Car length = clamp((dna.length % 10) + 3, 3, 12)
  - Frame: even ASCII → Rectangle chassis `R`, odd ASCII → Wheel `W`
  - Powertrain: ASCII % 3 → 0:`C` (Cylinder), 1:`D` (DriveShaft), 2:`G` (GearSet)
- Parameters by position (bounded for stability):
  - Wheel size: 15–35
  - Power factor: 0.5–1.5
  - Efficiency: 0.7–1.0
- Universal compatibility: any alphanumeric string yields a valid car.
- Backward compatibility: still accepts old `{ "frame": [], "powertrain": [] }` dict format.

### Key Classes and Files
- `scripts/CarDNA.gd` (class `CarDNA`)
  - DNA validation and cleaning, random generation
  - Translation to frame/powertrain (`translate_to_frame_and_powertrain`)
  - Parameter extraction (`get_wheel_size`, `get_power_factor`, `get_efficiency_factor`)
- `scripts/Car.gd` (class `Car`)
  - Holds `CarDNA`, score, mutation and reproduction (string-based)
  - Crossover: per-char and optional chunk-based
- `scripts/CarSimulation.gd` (scene script attached at runtime)
  - Builds cars from DNA, Godot physics, race simulation, scoring, cleanup
  - Collision layers: ground on layer 1; cars on unique layers (2–30) and only collide with ground
- `scripts/PopulationManager.gd` (class `PopulationManager`)
  - Evolution loop, population init, scoring via `CarSimulation`, selection, elitism, breeding
- `scenes/GameManager.gd` (class `GameManager`)
  - Scene switching between `MainMenu`, `Main`, `TestDrive`

## Coding Standards (GDScript)
- snake_case for variables and functions; PascalCase for classes/constants.
- Prefer explicit typing: `var speed: float = 0.0`.
- Descriptive names for GA parameters.
- Document complex GA operations and edge cases.
- Keep string-DNA as the primary representation; preserve old dict format support.

## DNA String Best Practices
- Validate to alphanumeric only; maintain minimum length of 3.
- Handle edge cases (empty, single char, very long strings).
- Deterministic mappings to ensure reproducibility.
- Implement/maintain elitism so top DNA survives.

Note on current validation: `CarDNA._validate_and_clean_dna` uses `is_valid_identifier()` and `is_valid_int()` per character, which may exclude some valid alphanumeric characters. Prefer an explicit alphanumeric check when modifying.

## Genetic Algorithm Best Practices
- Crossover: combine character sequences from parent DNA strings (single-point or chunk-based).
- Mutation: character replace/insert/delete with balanced rates.
- Always revalidate DNA after genetic ops; enforce min length 3.
- Consistent, distance-based fitness with survival bonus.
- Maintain diversity with moderate mutation and retain ratio.

Current defaults (PopulationManager):
- `population_size`: 20
- `dna_length` target: 12 (actual varies ±4)
- `generations`: 10
- `retain_ratio`: 0.5
- `mutation_rate`: 0.1 (in addition to `Car.mutate()` internal rates: replace 15%, remove 5% (min len 3), insert 10%)

## Physics & Collision System (Godot 4)
- Physics tick rate: 60 (`Engine.physics_ticks_per_second`).
- Race duration: 15s (`SIMULATION_TIME`).
- Ground and obstacles on collision layer 1 only; cars on layers 2–30 and collide only with layer 1.
- Wheels connected via `PinJoint2D`. Apply torque and forward impulse when in ground contact.
- Terrain includes ramps/bumps; ensure performance for ~20–30 cars.
- NaN/instability handling: bound parameters and add penalties if falling off-world (y > 600).

## File & Scene Conventions
- Scenes:
  - `scenes/MainMenu.tscn` + `scenes/MainMenu.gd`
  - `scenes/Main.tscn` + `scenes/Main.gd`
  - `scenes/TestDrive.tscn` + `scenes/TestDrive.gd`
  - `scenes/GameManager.tscn` + `scenes/GameManager.gd`
- Scripts:
  - `scripts/CarDNA.gd`, `scripts/Car.gd`, `scripts/CarSimulation.gd`, `scripts/PopulationManager.gd`, `scripts/population.gd`
- Legacy reference: `old_code/vroomon/` (Python implementation + tests for edge cases)

## Common Tasks
- Add DNA translation rules:
  1) Extend `_char_to_frame_part` / `_char_to_powertrain_part` in `CarDNA.gd`
  2) Add new parameter extractors (e.g., suspension stiffness)
  3) Use new parameters in `CarSimulation.build_car_from_dna`
  4) Test with diverse DNA strings
- Modify genetics:
  - Adjust `Car.mutate()` and crossover strategy
  - Consider length distribution effects and maintain validity
- Tweak evolution parameters in `PopulationManager.gd` (sizes, rates, generations, retain ratio)
- Update terrain in `CarSimulation._add_terrain_obstacles()`

## Scoring
- Score = forward distance + small survival bonus; strong penalty if car falls.
- Sort results descending; keep top performers (elitism) into next generation.

## Performance
- Limit concurrent physics load; clean up bodies every generation.
- Efficient collision: each car on unique layer; mask collides only with ground.
- Monitor memory when increasing population.

## Backward Compatibility
- New format: `{ "dna_string": "alphanumeric" }`
- Old format still accepted: `{ "frame": [..], "powertrain": [..] }`
- Prefer new format in all new code and serialization.

## Common Pitfalls & Gotchas
- Resource paths: always include `res://scripts/` or `res://scenes/` prefixes when loading.
- Collision layers: layer indices map to bitmasks; ensure cars don’t collide with each other (mask should include only layer 1).
- DNA validation: avoid excluding valid alphanumerics; ensure min length 3.
- Determinism: translation should always yield the same parts for the same DNA.
- Cleanups: free car bodies and wheels on simulation end to avoid accumulation.

## Workspace Structure (current)
```
/home/calvin/code/vroomon/
├── project.godot
├── README.md
├── assets/
├── scenes/
│   ├── GameManager.gd & GameManager.tscn
│   ├── Main.gd & Main.tscn
│   ├── MainMenu.gd & MainMenu.tscn
│   ├── TestDrive.gd & TestDrive.tscn
│   └── root.tscn
├── scripts/
│   ├── Car.gd
│   ├── CarDNA.gd
│   ├── CarSimulation.gd
│   ├── PopulationManager.gd
│   └── population.gd
└── old_code/
    └── vroomon/ (Python reference implementation + tests)
```

## Quick Examples
```gdscript
# Translate DNA
var dna = CarDNA.new("ABC123")
var translated = dna.translate_to_frame_and_powertrain()
# {"frame": ["W","R","W"], "powertrain": ["C","D","G"]}

# Mutation
var car = Car.new(dna)
var mutated = car.mutate()

# Build & simulate (via PopulationManager)
var pm = PopulationManager.new()
pm.start_evolution()
```

Priorities: maintain GA correctness with string DNA, physics stability via DNA-derived parameters, clean and maintainable code, and dual DNA format support.

## Useful Godot docs
- GDScript basics: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html
- @GDScript built-ins (globals, math constants): https://docs.godotengine.org/en/stable/classes/class_@gdscript.html
- GlobalScope functions (math helpers): https://docs.godotengine.org/en/stable/classes/class_@globalscope.html
- Class reference index: https://docs.godotengine.org/en/stable/classes/index.html
- 2D physics overview: https://docs.godotengine.org/en/stable/tutorials/physics/physics_introduction_2d.html