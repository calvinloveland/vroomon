# Car Evolution Simulation

A genetic algorithm-based car evolution simulator built in Godot 4. Watch as cars with different DNA compete in races and evolve over generations to become better at navigating terrain.

## Overview

This project uses evolutionary algorithms to automatically design and optimize car configurations. Cars are defined by their genetic code (DNA) which determines their frame structure and powertrain components. Through multiple generations of racing, selection, and mutation, the cars evolve to become more efficient at traversing obstacles.

## Features

- **Genetic Algorithm Evolution**: Cars evolve over generations using selection, crossover, and mutation
- **Physics-Based Racing**: Realistic 2D physics simulation with proper wheel-ground interaction
- **Dynamic Car Construction**: Cars are built procedurally from their genetic code
- **Multi-Car Racing**: Up to 30 cars can race simultaneously without collision interference
- **Terrain Obstacles**: Racing track includes ramps and obstacles for challenging navigation
- **Population Management**: Automated generation management and fitness scoring
- **Visual Feedback**: Real-time racing visualization with color-coded cars
- **Test Drive Mode**: Individual car testing capabilities
- **Alphanumeric DNA System**: Any string can evolve into a functional car design
- **Pluggable Terrain**: Terrain built via a TerrainManager with swappable generators (Flat, Bumps, ...)

## How It Works

### DNA System
 
Cars are now defined by a **single alphanumeric DNA string** that gets translated into car components:

**Examples:**

- DNA String: `"A3x9K2m"` → Translates to specific frame and powertrain configurations
- DNA String: `"Hello123"` → Creates a completely different car design
- DNA String: `"XyZ789abc"` → Another unique car configuration

**Translation Process:**

- **Car Length**: Determined by DNA string length (3-12 parts maximum)
- **Frame Parts**: Character ASCII values determine part types
  - Even ASCII values → Rectangle chassis component
  - Odd ASCII values → Wheel attachment point
- **Powertrain Parts**: Different character positions determine engine components
  - ASCII % 3 = 0 → Cylinder (power generation)
  - ASCII % 3 = 1 → DriveShaft (power transmission)
  - ASCII % 3 = 2 → GearSet (power distribution)
- **Parameters**: Characters encode wheel sizes, power factors, and efficiency values

### Evolution Process

1. **Initial Population**: Random alphanumeric DNA strings are generated
2. **Translation**: Each DNA string is converted into a car design
3. **Racing Simulation**: All cars race simultaneously on the same obstacle course
4. **Fitness Evaluation**: Cars are scored based on distance traveled and survival
5. **Selection**: Best performing cars are selected for breeding
6. **Reproduction**: New DNA strings created through string crossover and character mutation
7. **Iteration**: Process continues for multiple generations, improving performance

### Scoring System

Cars are evaluated using a comprehensive fitness function:

- **Primary Score**: Distance traveled forward (main objective)
- **Survival Bonus**: Small bonus for maintaining height (not falling)
- **Penalty**: Severe penalty for falling off the world (y > 600)

## Key Benefits of DNA String System

### Simplified Genetics

- **Easy Reproduction**: Simple string operations for crossover (combine parent strings)
- **Flexible Mutation**: Character replacement, insertion, or deletion
- **Universal Compatibility**: Any alphanumeric string can become a car
- **Rich Parameter Space**: Single string encodes both structure and fine-tuned parameters

### Robust Evolution

- **No Invalid DNA**: Every string produces a valid (though possibly poor) car design
- **Continuous Search Space**: Small string changes create gradual design variations
- **Emergent Complexity**: Simple character rules create complex car behaviors

## File Structure

```text
├── scenes/
│   ├── Main.gd & Main.tscn
│   ├── MainMenu.gd & MainMenu.tscn
│   ├── GameManager.gd & GameManager.tscn
│   └── TestDrive.gd & TestDrive.tscn
├── scripts/
│   ├── Car.gd                    # Individual car behavior and physics
│   ├── CarDNA.gd                 # Genetic code representation and manipulation
│   ├── CarSimulation.gd          # Physics simulation and racing environment (uses TerrainManager)
│   ├── PopulationManager.gd      # Genetic algorithm implementation
│   ├── population.gd             # Population data structures
│   └── terrain/
│       ├── TerrainManager.gd
│       ├── TerrainProfile.gd
│       ├── TerrainGeneratorBase.gd
│       ├── TerrainPresets.gd
│       └── generators/
│           ├── FlatTerrainGenerator.gd
│           └── BumpsTerrainGenerator.gd
├── assets/
└── old_code/                     # Previous Python implementation for reference
```

## Getting Started

### Prerequisites

- Godot 4.x
- Basic understanding of genetic algorithms (helpful but not required)

### Installation

1. Clone this repository:

```bash
git clone <repository-url>
cd vroomon
```

1. Open the project in Godot 4

1. Run the project (F5) and start Evolution from the UI

### Usage

1. Launch the application
2. Click "Start Evolution"
3. Watch cars race and evolve over generations
4. Use the Terrain preset dropdown to switch terrain presets

### Terrain System

Terrain is managed by `TerrainManager` using a `TerrainProfile` and a selected generator.

- Add new terrain types by creating a generator in `scripts/terrain/generators/` that implements `generate(parent, profile) -> Dictionary` and `clear(handle)`.
- Select a preset via `TerrainPresets.get_names()` in the UI or call `CarSimulation.set_terrain_preset(name)`.
- Profiles control friction, ground length/height, colors, and obstacle parameters.

#### Test Drive Mode

1. Select "Test Drive" from the main menu
2. Design a custom car or use a generated one
3. Test individual car performance on the track

## Technical Details

### DNA Translation Algorithm

- **Character Mapping**: Each character's ASCII value determines component types
- **Position-Based Parameters**: Character position affects wheel size, power, efficiency
- **Deterministic**: Same DNA string always produces identical car design
- **Bounded Outputs**: All parameters mapped to reasonable ranges (wheel size 15-35, etc.)

### Physics Simulation

- **Engine**: Godot 4 physics engine at 60 FPS
- **Collision System**: Multi-layer collision to prevent car-to-car interference
- **Motor System**: Dynamic torque and thrust application based on DNA-derived parameters
- **Terrain**: Built by TerrainManager with preset generators (e.g., Flat, Bumps)

### Key Parameters

- `SIMULATION_TIME`: Race duration (15 seconds)
- `CAR_SPACING`: Starting position spacing between cars
- `PHYSICS_STEPS_PER_SECOND`: Physics simulation frequency (60 FPS)
- Population size and mutation rates configurable in PopulationManager

### Car Construction

Cars are procedurally built from DNA with:

- Connected chassis components using rigid body physics
- Wheels attached via PinJoint2D for realistic suspension
- Power distribution calculated from DNA-derived parameters
- Individual collision layers to prevent interference
- Variable wheel sizes and power factors based on DNA

## Key Classes

- **`scripts/CarDNA.gd`**: Handles DNA string validation, translation, and parameter extraction
- **`scripts/CarSimulation.gd`**: Handles physics simulation, car construction, and racing
- **`scripts/PopulationManager.gd`**: Manages genetic algorithm operations and evolution
- **`scenes/GameManager.gd`**: Coordinates overall game flow and state management
- **`scripts/Car.gd`**: Individual car behavior with simplified string-based genetic operations

## Development

### DNA String Examples

```gdscript
# Simple car
var dna = CarDNA.new("ABC123")
var translated = dna.translate_to_frame_and_powertrain()
# Result: {"frame": ["W", "R", "W"], "powertrain": ["C", "D", "G"]}

# Complex car with varied parameters
var dna = CarDNA.new("X7m2K9pQw")
# Creates larger car with DNA-specific wheel sizes and power factors
```

### Adding New Translation Rules

1. Extend character mapping in `CarDNA._char_to_frame_part()` or `_char_to_powertrain_part()`
2. Add new parameter extraction functions (e.g., `get_suspension_stiffness()`)
3. Update car construction in `CarSimulation.build_car_from_dna()`
4. Test with various DNA strings to ensure robust behavior

### Modifying Evolution Parameters

Key parameters to adjust in `PopulationManager.gd`:

- DNA string target length (affects car complexity)
- Mutation rates for character operations
- Selection pressure and elitism
- Population size and generation limits

## Architecture Notes

### DNA Format

The system uses a single alphanumeric DNA string: `{ "dna_string": "A3x9K2m" }`.

### String-Based Genetics

- **Crossover**: Take character chunks from parent DNA strings
- **Mutation**: Replace, insert, or delete individual characters
- **Validation**: Ensures only alphanumeric characters, minimum length of 3

### Performance Optimization

- Efficient physics simulation with proper collision masking
- Limited simulation time to prevent infinite races
- Automatic cleanup of car bodies after each generation
- Character-to-parameter mapping uses modulo operations for speed

## Legacy Code

The `old_code/` directory contains a previous Python implementation using:

- pygame for visualization
- pymunk for 2D physics
- Comprehensive test suite
- Coverage reporting

This can serve as reference for algorithm details and testing approaches.

## Contributing

Contributions are welcome! Areas for improvement:

- **Additional Part Types**: New frame and powertrain components
- **Advanced Terrain**: Procedural track generation
- **Enhanced Genetics**: More sophisticated genetic operators
- **Performance**: Multi-threading and optimization
- **Visualization**: Better real-time analytics and charts
- **AI Integration**: Neural network controllers

### Development Setup

1. Fork the repository
2. Create a feature branch
3. Make changes and test thoroughly
4. Submit a pull request with detailed description

## Future Enhancements

- **Complex Terrain**: Dynamic obstacle generation and varied environments
- **Real-time Visualization**: Live performance charts and genealogy trees
- **Export Capabilities**: Save and share successful car designs


## Acknowledgments

- Built with Godot Engine for robust 2D physics simulation
- Inspired by classic genetic algorithm demonstrations
