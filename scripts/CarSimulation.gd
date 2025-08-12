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

	# Build all cars from DNA
	for i in range(car_dna_dicts.size()):
		var car_data = car_dna_dicts[i]
		var car_body = build_car_from_dna(car_data, i)
		if car_body:
			current_cars.append({
				"root": car_body.get_parent(),
				"body": car_body,
				"data": car_data,
				"initial_position": car_body.position,
				"car_index": i
			})
			# Car is already added under a stable root

	# Wait for simulation to complete
	await simulation_completed

	return car_results

func build_car_from_dna(dna_dict: Dictionary, car_index: int) -> RigidBody2D:
	# Create a stable parent for this car
	var car_root := Node2D.new()
	car_root.name = "Car_%d" % car_index
	car_root.add_to_group("car")
	add_child(car_root)

	var car_body = RigidBody2D.new()
	# Space cars out at the start line, but keep them closer to origin
	car_body.position = Vector2(50, 150 - car_index * 30)  # Start closer to camera view
	car_body.mass = 10.0
	car_body.gravity_scale = 1.0
	car_body.name = "Chassis"

	# Set collision layers so cars don't collide with each other
	# Each car gets its own collision layer (layers 2-31, layer 1 is for ground)
	var car_layer = 2 + (car_index % 29)  # Cycle through layers 2-30
	car_body.collision_layer = 1 << car_layer  # Car exists on its own layer
	car_body.collision_mask = 1  # Car only collides with ground (layer 1)

	# Handle both old and new DNA formats for compatibility
	var frame_parts = []
	var powertrain_parts = []
	var car_dna: CarDNA = null

	# Check if this is new DNA string format or old format
	if dna_dict.has("dna_string"):
		# New DNA string format
		car_dna = CarDNA.new()
		car_dna.from_dict(dna_dict)
		var translated = car_dna.translate_to_frame_and_powertrain()
		frame_parts = translated.frame
		powertrain_parts = translated.powertrain
	else:
		# Old format for backward compatibility
		frame_parts = dna_dict.get("frame", [])
		powertrain_parts = dna_dict.get("powertrain", [])

	if frame_parts.size() == 0:
		push_error("Car has no frame parts - DNA: " + str(dna_dict))
		return null

	# Attach chassis under stable root first
	car_root.add_child(car_body)

	# Build connected car structure
	var all_bodies = [car_body]  # Keep track of all bodies for connections
	var x_offset = 0

	# Add main chassis parts first
	for i in range(frame_parts.size()):
		var frame_code = frame_parts[i]

		if frame_code == "R":
			_add_rectangle_to_car(car_body, Vector2(x_offset, 0), car_index, car_layer)

		x_offset += 50

	# Add wheels and connect them properly with enhanced parameters from DNA
	x_offset = 0
	for i in range(frame_parts.size()):
		var frame_code = frame_parts[i]

		if frame_code == "W":
			var wheel_power = _calculate_wheel_power(powertrain_parts, i, car_dna, i)
			var wheel_size = _get_wheel_size_from_dna(car_dna, i)
			var wheel_body = _add_connected_wheel(car_body, Vector2(x_offset, 35), wheel_power, car_index, car_layer, wheel_size)
			if wheel_body:
				all_bodies.append(wheel_body)

		x_offset += 50

	# Add some visual variety based on car index
	car_body.modulate = Color.from_hsv(float(car_index) / 20.0, 0.8, 1.0)

	return car_body

func _add_rectangle_to_car(car_body: RigidBody2D, offset: Vector2, car_index: int, _car_layer: int):
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(45, 25)

	var collision = CollisionShape2D.new()
	collision.shape = rect_shape
	collision.position = offset

	car_body.add_child(collision)

	# Visual representation with car-specific color
	var visual = ColorRect.new()
	visual.size = Vector2(45, 25)
	visual.position = offset - Vector2(22.5, 12.5)
	visual.color = Color.from_hsv(float(car_index) / 20.0, 0.6, 0.8)
	collision.add_child(visual)

func _get_wheel_size_from_dna(car_dna: CarDNA, wheel_pos: int) -> Vector2:
	"""Get wheel size from DNA string, fallback to default if old format"""
	if car_dna:
		var size = car_dna.get_wheel_size(wheel_pos)
		return Vector2(size, size)
	else:
		# Default size for old format
		return Vector2(36, 36)

func _add_connected_wheel(car_body: RigidBody2D, offset: Vector2, power: float, car_index: int, car_layer: int, wheel_size: Vector2 = Vector2(36, 36)) -> RigidBody2D:
	var wheel_body = RigidBody2D.new()
	wheel_body.position = car_body.position + offset
	wheel_body.mass = 3.0
	wheel_body.gravity_scale = 1.0
	wheel_body.name = "Wheel_" + str(car_index)

	# Set same collision properties as the car body
	wheel_body.collision_layer = 1 << car_layer  # Same layer as car
	wheel_body.collision_mask = 1  # Only collides with ground

	var circle_shape = CircleShape2D.new()
	circle_shape.radius = wheel_size.x / 2  # Use custom size from DNA

	var collision = CollisionShape2D.new()
	collision.shape = circle_shape
	wheel_body.add_child(collision)

	# Visual representation
	var visual = ColorRect.new()
	visual.size = wheel_size
	visual.position = Vector2(-wheel_size.x/2, -wheel_size.y/2)
	visual.color = Color.from_hsv(float(car_index) / 20.0, 1.0, 0.9)
	collision.add_child(visual)

	# Add wheel to the same root as chassis
	var root := car_body.get_parent()
	if root:
		root.add_child(wheel_body)
	else:
		add_child(wheel_body)

	# Create pin joint under the stable root now that both bodies are in the tree
	var joint = PinJoint2D.new()
	# Anchor at wheel center in global space so wheel rotates about its own center
	joint.global_position = wheel_body.global_position
	if root:
		root.add_child(joint)
	else:
		add_child(joint)
	# Safe to assign node paths directly
	joint.node_a = car_body.get_path()
	joint.node_b = wheel_body.get_path()

	# Store wheel power for motor application
	wheel_body.set_meta("motor_power", power)
	wheel_body.set_meta("car_index", car_index)
	# Optional: group wheels for convenience
	wheel_body.add_to_group("motor_wheel")

	return wheel_body

func _calculate_wheel_power(powertrain_parts: Array, wheel_position: int, car_dna: CarDNA = null, dna_index: int = 0) -> float:
	var current_power = 0.0
	var _current_torque = 10000.0

	# Use DNA-based power factors if available
	var power_factor = 1.0
	var efficiency_factor = 1.0

	if car_dna:
		power_factor = car_dna.get_power_factor(dna_index)
		efficiency_factor = car_dna.get_efficiency_factor(dna_index)

	for i in range(min(powertrain_parts.size(), wheel_position + 1)):
		var part_code = powertrain_parts[i]
		match part_code:
			"C":  # Cylinder
				current_power += randf_range(50.0, 150.0) * power_factor
			"D":  # DriveShaft
				var efficiency = randf_range(0.85, 0.95) * efficiency_factor
				current_power *= efficiency
				_current_torque *= efficiency
			"G":  # GearSet
				var input_ratio = randf_range(0.7, 1.5)
				var wheel_proportion = randf_range(0.2, 0.8)
				current_power *= input_ratio
				_current_torque /= input_ratio
				if i == wheel_position:
					return current_power * wheel_proportion

	return current_power

func _physics_process(delta):
	if not is_simulating:
		return

	simulation_timer += delta

	# Apply motor forces to all wheels
	_update_all_wheel_motors()

	# End simulation after time limit
	if simulation_timer >= SIMULATION_TIME:
		end_simulation()

func _update_all_wheel_motors():
	# Apply continuous motor forces to all wheels under car roots
	for car_root in get_tree().get_nodes_in_group("car"):
		for node in car_root.get_children():
			if node is RigidBody2D and node.has_meta("motor_power"):
				var power = node.get_meta("motor_power", 0.0)
				# Apply torque for wheel rotation
				node.apply_torque_impulse(power * 0.1)
				# Add forward thrust when wheel is in contact with ground
				if _is_wheel_on_ground(node):
					var thrust_force = Vector2(power * 0.5, 0)
					node.apply_central_impulse(thrust_force)

func _is_wheel_on_ground(wheel: RigidBody2D) -> bool:
	# Improved ground contact detection using global coordinates
	var space_state = wheel.get_world_2d().direct_space_state
	var from_pos = wheel.global_position
	var to_pos = from_pos + Vector2(0, 25)
	var query = PhysicsRayQueryParameters2D.create(from_pos, to_pos)
	query.exclude = [wheel]  # Don't detect the wheel itself
	var result = space_state.intersect_ray(query)
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
