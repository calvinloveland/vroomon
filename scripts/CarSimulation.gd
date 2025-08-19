extends Node2D

# Car Physics Simulation Scene
# Handles multiple cars racing simultaneously with proper part connections

signal simulation_completed(results: Array)

const SIMULATION_TIME = 15.0  # seconds - longer for more interesting races
const PHYSICS_STEPS_PER_SECOND = 60
const CAR_SPACING = 150  # pixels between car starting positions

var current_cars: Array = []
var ground: StaticBody2D
var simulation_timer: float = 0.0
var is_simulating: bool = false
var car_results: Array = []
var motor_preview_always_on: bool = false

# Area configuration (can be changed at runtime)
var area_config: Dictionary = AreaConfigs.get_preset("Grassland")

func _ready():
	# Create ground
	setup_ground()

	# Set physics settings for better simulation
	Engine.physics_ticks_per_second = PHYSICS_STEPS_PER_SECOND

func set_area_config(config: Dictionary) -> void:
	area_config = config
	_rebuild_environment()

func _rebuild_environment():
	# Remove existing terrain visuals/obstacles
	for child in get_children():
		if child is Node and child != ground and (child.is_in_group("terrain") or child is ColorRect):
			child.queue_free()
	# Recreate ground if needed
	if is_instance_valid(ground):
		ground.queue_free()
	setup_ground()

func setup_ground():
	ground = StaticBody2D.new()
	add_child(ground)

	# Set ground to collision layer 1
	ground.collision_layer = 1
	ground.collision_mask = 0  # Ground doesn't need to detect anything

	# Physics material for friction
	var mat := PhysicsMaterial.new()
	mat.friction = float(area_config.get("friction", 1.0))
	ground.physics_material_override = mat

	# Create longer ground for racing based on area
	var ground_length: float = float(area_config.get("ground_length", 5000.0))
	var ground_shape = RectangleShape2D.new()
	ground_shape.size = Vector2(ground_length, 100)

	var ground_collision = CollisionShape2D.new()
	ground_collision.shape = ground_shape
	ground_collision.position = Vector2(0, 400)  # Ground level

	ground.add_child(ground_collision)

	# Visual representation of ground
	var ground_visual = ColorRect.new()
	ground_visual.size = Vector2(ground_length, 100)
	ground_visual.position = Vector2(-ground_length/2.0, 350)
	var color_val = area_config.get("ground_color", Color.BROWN)
	ground_visual.color = color_val
	ground_visual.add_to_group("terrain")
	add_child(ground_visual)

	# Add some obstacles for more interesting terrain
	_add_terrain_obstacles()

func _add_terrain_obstacles():
	# Add bumps and ramps per area config
	var obstacle_count: int = int(area_config.get("obstacle_count", 5))
	var base_h: float = float(area_config.get("obstacle_height_base", 50.0))
	var step_h: float = float(area_config.get("obstacle_height_step", 10.0))
	var ground_length: float = float(area_config.get("ground_length", 5000.0))
	var spacing = ground_length / float(obstacle_count + 1)

	for i in range(obstacle_count):
		var x_pos = spacing * float(i + 1)
		var obstacle = StaticBody2D.new()
		obstacle.add_to_group("terrain")
		add_child(obstacle)

		# Set obstacles to same collision layer as ground
		obstacle.collision_layer = 1
		obstacle.collision_mask = 0

		# Physics material for friction matches ground
		var mat := PhysicsMaterial.new()
		mat.friction = float(area_config.get("friction", 1.0))
		obstacle.physics_material_override = mat

		var obstacle_shape = RectangleShape2D.new()
		obstacle_shape.size = Vector2(100, base_h + i * step_h)

		var obstacle_collision = CollisionShape2D.new()
		obstacle_collision.shape = obstacle_shape
		obstacle_collision.position = Vector2(x_pos, 375 - (obstacle_shape.size.y/2.0))

		obstacle.add_child(obstacle_collision)

		# Visual
		var obstacle_visual = ColorRect.new()
		obstacle_visual.size = obstacle_shape.size
		obstacle_visual.position = Vector2(-obstacle_shape.size.x/2, -obstacle_shape.size.y/2)
		obstacle_visual.color = Color.DARK_GRAY
		obstacle_visual.add_to_group("terrain")
		obstacle_collision.add_child(obstacle_visual)

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
