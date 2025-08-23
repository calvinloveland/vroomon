extends Node2D

# Car Physics Simulation Scene
# Handles multiple cars racing simultaneously with proper part connections

signal simulation_completed(results: Array)

const TerrainManager = preload("res://scripts/terrain/TerrainManager.gd")
const TerrainPresets = preload("res://scripts/terrain/TerrainPresets.gd")

const SIMULATION_TIME = 15.0  # seconds - longer for more interesting races
const PHYSICS_STEPS_PER_SECOND = 60
const CAR_SPACING = 150  # pixels between car starting positions

var current_cars: Array = []
var ground: StaticBody2D
var simulation_timer: float = 0.0
var is_simulating: bool = false
var car_results: Array = []
var motor_preview_always_on: bool = false
@onready var terrain_manager = TerrainManager.new()
var terrain_name: String = "Grassland"

func _ready():
	add_child(terrain_manager)
	_rebuild_environment()
	# Set physics settings for better simulation
	Engine.physics_ticks_per_second = PHYSICS_STEPS_PER_SECOND

func set_terrain_preset(name: String) -> void:
	terrain_name = name
	_rebuild_environment()

func _rebuild_environment():
	# Clear any existing terrain and build via manager
	terrain_manager.clear()
	var profile := TerrainPresets.get_profile(terrain_name)
	var generator := TerrainPresets.get_generator(terrain_name)
	terrain_manager.set_profile(profile)
	terrain_manager.set_generator(generator)
	terrain_manager.rebuild(self)
	ground = terrain_manager.get_ground()

func setup_ground():
	# Deprecated: terrain now built by TerrainManager
	pass

func _add_terrain_obstacles():
	# Deprecated: obstacles built by TerrainManager generators
	pass

func simulate_population(car_dna_dicts: Array) -> Array:
	if is_simulating:
		await simulation_completed

	is_simulating = true
	simulation_timer = 0.0
	current_cars = []
	car_results = []

	print("Starting race with ", car_dna_dicts.size(), " cars!")

	# Build all cars from DNA (delegated to Car)
	for i in range(car_dna_dicts.size()):
		var car_data = car_dna_dicts[i]
		var car := Car.new()
		var car_body := car.build_in(self, i, car_data)
		if car_body:
			current_cars.append({
				"root": car_body.get_parent(),
				"body": car_body,
				"car": car,
				"data": car_data,
				"initial_position": car_body.position,
				"car_index": i
			})

	# Wait for simulation to complete
	await simulation_completed

	return car_results

# Deprecated: kept as wrapper for backwards compatibility in callers, delegates to Car
func build_car_from_dna(dna_dict: Dictionary, car_index: int) -> RigidBody2D:
	var car := Car.new()
	var body := car.build_in(self, car_index, dna_dict)
	if body:
		# Track for preview updates
		current_cars.append({
			"root": body.get_parent(),
			"body": body,
			"car": car,
			"data": dna_dict,
			"initial_position": body.position,
			"car_index": car_index
		})
	return body

func enable_motor_preview(on: bool = true) -> void:
	motor_preview_always_on = on

func _physics_process(delta):
	# In test mode, still run motors even if not simulating a full race
	if not is_simulating and not motor_preview_always_on:
		return

	if is_simulating:
		simulation_timer += delta

	# Apply motor forces to all wheels via Car API
	for entry in current_cars:
		if entry.has("car") and is_instance_valid(entry.root):
			var preview := not is_simulating and motor_preview_always_on
			entry.car.update_wheels(entry.root, preview)
			# Drive flexible connectors (always on during physics)
			entry.car.update_connectors(delta)

	# End simulation after time limit only in full sim mode
	if is_simulating and simulation_timer >= SIMULATION_TIME:
		end_simulation()

func _is_wheel_on_ground(wheel: RigidBody2D) -> bool:
	# Improved ground contact detection using global coordinates
	var space_state = wheel.get_world_2d().direct_space_state
	var from_pos: Vector2 = wheel.global_position
	var to_pos: Vector2 = from_pos + Vector2(0, 25)
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(from_pos, to_pos)
	query.exclude = [wheel]  # Don't detect the wheel itself
	var result: Dictionary = space_state.intersect_ray(query)
	return result and (result.collider == ground or result.collider.get_parent() == ground)

func end_simulation():
	is_simulating = false

	# Calculate results for all cars
	car_results = []
	for car_data in current_cars:
		var car_body = car_data.body
		var score = calculate_score(car_body, car_data.initial_position)
		car_results.append({
			"data": car_data.data,
			"score": score,
			"final_position": car_body.position,
			"car_index": car_data.car_index
		})

	# Sort results by score for easy identification of winner
	car_results.sort_custom(func(a, b): return a.score > b.score)

	print("Race finished! Winner: Car ", car_results[0].car_index, " with score: ", car_results[0].score)

	# Clean up all cars (free the whole root)
	for car_data in current_cars:
		if car_data.has("root") and is_instance_valid(car_data.root):
			car_data.root.queue_free()
		elif is_instance_valid(car_data.body):
			car_data.body.queue_free()

	# Remove any orphaned bodies
	for child in get_children():
		if child.is_in_group("car"):
			child.queue_free()
		elif child is RigidBody2D and child != ground and "Wheel_" in child.name:
			child.queue_free()

	current_cars = []
	emit_signal("simulation_completed", car_results)

func calculate_score(car_body: RigidBody2D, initial_position: Vector2) -> float:
	if not car_body or not is_instance_valid(car_body):
		return 0.0

	# Score based on distance traveled and survival
	var distance_traveled = car_body.position.x - initial_position.x
	var height_maintained = initial_position.y - car_body.position.y

	# Bonus for forward movement, penalty for falling too much
	var base_score = max(0, distance_traveled)
	var survival_bonus = max(0, -height_maintained * 0.5)  # Small bonus for staying high

	# Penalty for falling off the world
	if car_body.position.y > 600:  # Fell too far
		base_score *= 0.1

	return base_score + survival_bonus
