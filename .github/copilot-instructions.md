# Car Evolution Simulation - Copilot Instructions

## Project Overview
This is a genetic algorithm-based car evolution simulator built in Godot 4. Cars with alphanumeric DNA strings compete in races and evolve over generations to become better at navigating terrain.

## Core Architecture

### DNA System
- Cars are defined by **single alphanumeric DNA strings** that get translated into car components
- **New Format**: `"A3x9K2m"` → Automatically translates to frame and powertrain sequences
- **Translation Rules**:
  - Car length determined by DNA string length (3-12 parts)
  - Even ASCII values → Rectangle chassis (`R`)
  - Odd ASCII values → Wheel attachment (`W`)
  - ASCII % 3 determines powertrain: Cylinder (`C`), DriveShaft (`D`), GearSet (`G`)
- **Parameters**: Character positions encode wheel sizes, power factors, efficiency values
- **Universal Compatibility**: Any alphanumeric string produces a valid car design
- **Backward Compatibility**: System supports old `{"frame": [], "powertrain": []}` format

### Key Classes and Their Responsibilities
- `scripts/CarDNA.gd`: DNA string validation, translation to components, parameter extraction
- `scripts/CarSimulation.gd`: Physics simulation, car construction from DNA, racing environment
- `scripts/PopulationManager.gd`: Genetic algorithm operations (string-based crossover, mutation)
- `scenes/GameManager.gd`: Overall game flow coordination and state management
- `scripts/Car.gd`: Individual car behavior with simplified string genetic operations

### Physics and Collision System
- Uses Godot 4 physics engine with multi-layer collision detection
- Each car gets its own collision layer (layers 2-30) to prevent car-to-car interference
- Cars only collide with ground/obstacles (layer 1) for realistic racing
- Wheels attached via PinJoint2D for suspension simulation

## Coding Standards

### GDScript Conventions
- Use snake_case for variables and functions
- Use PascalCase for class names and constants
- Prefer explicit typing: `var speed: float = 0.0`
- Use descriptive variable names, especially for genetic algorithm parameters
- Add documentation comments for complex genetic operations

### DNA String Best Practices
- Always validate DNA strings contain only alphanumeric characters
- Handle edge cases in genetic operations (empty strings, single character DNA)
- Maintain minimum DNA length of 3 characters for valid cars
- Use deterministic character-to-component mapping for reproducible results
- Implement elitism to preserve best-performing DNA strings

### Genetic Algorithm Best Practices
- **String Crossover**: Combine character sequences from parent DNA strings
- **Character Mutation**: Replace, insert, or delete individual characters
- **Validation**: Ensure DNA strings remain valid after genetic operations
- Use consistent fitness evaluation criteria
- Maintain population diversity through balanced mutation rates

### Physics Simulation Guidelines
- Clean up physics bodies properly after each generation
- Use appropriate collision masks and layers
- Limit simulation time to prevent infinite races
- Handle NaN values in physics calculations (reference old_code/tests for edge cases)

## Domain-Specific Knowledge

### DNA Translation Process
- **Character Mapping**: ASCII values determine component types via modulo operations
- **Position-Based Parameters**: Character position affects wheel size (15-35), power factor (0.5-1.5), efficiency (0.7-1.0)
- **Deterministic Output**: Same DNA string always produces identical car design
- **Bounded Parameters**: All extracted values mapped to reasonable ranges for physics stability

### Car Construction
- Cars are built procedurally from translated DNA using RigidBody2D nodes
- Frame parts connected in sequence determined by DNA translation
- Wheels attached at positions where DNA translates to `W` components
- Power distribution calculated from DNA-derived parameters and powertrain complexity
- Each car needs unique collision layer assignment for non-interfering racing

### Evolution Parameters
- Population size typically 20-30 cars with varied DNA string lengths
- DNA target length affects car complexity (longer = more parts)
- Simulation time limited to 15 seconds per race
- Fitness based on distance traveled with survival bonus
- Character mutation rates should be carefully balanced (15% replace, 5% remove, 10% insert)
- Elite selection preserves top-performing DNA strings

### Performance Considerations
- Limit concurrent physics simulations
- Use efficient collision detection
- Clean up resources between generations
- Monitor memory usage with large populations

## File Patterns

### Scene Structure
- Main scenes: MainMenu, GameManager, TestDrive
- Car construction happens dynamically in CarSimulation
- UI elements should be responsive and informative

### Legacy Code Reference
- The `old_code/` directory contains Python implementation with extensive tests
- Use as reference for genetic algorithm logic and edge case handling
- Test files show important bug fixes and physics edge cases

## Common Tasks

### Adding New DNA Translation Rules
1. Extend character mapping in `CarDNA._char_to_frame_part()` or `_char_to_powertrain_part()`
2. Add new parameter extraction functions (e.g., `get_suspension_stiffness(position: int)`)
3. Update car construction logic in `CarSimulation.build_car_from_dna()`
4. Test with various DNA strings to ensure robust behavior across character ranges

### Modifying String-Based Genetics
- Adjust character mutation rates in `Car.mutate()` for different evolution dynamics
- Modify crossover methods in `Car.reproduce()` (single-point vs chunk-based)
- Consider impact on DNA string length distribution in population
- Test genetic operations with edge cases (very short/long strings)

### DNA String Examples
```gdscript
# Simple car
var dna = CarDNA.new("ABC123")
var translated = dna.translate_to_frame_and_powertrain()
# Result: {"frame": ["W", "R", "W"], "powertrain": ["C", "D", "G"]}

# Testing specific parameters
var wheel_size = dna.get_wheel_size(0)  # Size for first wheel
var power_factor = dna.get_power_factor(1)  # Power factor for second position
```

### Debug DNA Issues
- Check DNA string validation in `CarDNA._validate_and_clean_dna()` (currently uses `is_valid_identifier()` and `is_valid_int()`)
- Verify translation consistency by testing same DNA string multiple times
- Monitor for edge cases in character-to-parameter mapping
- Ensure DNA strings maintain valid characters after genetic operations
- Note: Current validation may exclude some valid alphanumeric characters

## Error Handling
- Always validate DNA strings before car construction using `CarDNA._validate_and_clean_dna()`
- Handle physics simulation edge cases with DNA-derived parameters
- Provide meaningful error messages for invalid DNA string operations
- Gracefully handle empty or corrupted DNA strings by generating fallback random DNA
- Log DNA strings alongside error messages for debugging genetic operations

## DNA String Migration Notes
- System maintains compatibility with old `{"frame": [], "powertrain": []}` format
- New DNA format: `{"dna_string": "alphanumeric_string"}`
- Migration path: Convert old arrays to representative DNA strings if needed
- All new population generation uses alphanumeric DNA string format

## Current Project Structure
```
/home/calvin/vroomon/
├── project.godot
├── README.md
├── assets/
│   ├── icon.svg
│   └── icon.svg.import
├── scenes/
│   ├── GameManager.gd & GameManager.tscn
│   ├── Main.gd & Main.tscn
│   ├── MainMenu.gd & MainMenu.tscn
│   ├── TestDrive.gd & TestDrive.tscn
│   └── root.tscn
├── scripts/
│   ├── Car.gd & Car.gd.uid
│   ├── CarDNA.gd & CarDNA.gd.uid
│   ├── CarSimulation.gd & CarSimulation.gd.uid
│   ├── PopulationManager.gd & PopulationManager.gd.uid
│   └── population.gd & population.gd.uid
└── old_code/
    └── vroomon/ (Python reference implementation)
```

When working on this project, prioritize genetic algorithm correctness with string-based DNA, physics stability with DNA-derived parameters, and maintainable code structure that supports both DNA formats.