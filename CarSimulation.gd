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

func _ready():
	# Create ground
	setup_ground()
	
	# Set physics settings for better simulation
	Engine.physics_ticks_per_second = PHYSICS_STEPS_PER_SECOND

func setup_ground():
	ground = StaticBody2D.new()
	add_child(ground)
	
	# Set ground to collision layer 1
	ground.collision_layer = 1
	ground.collision_mask = 0  # Ground doesn't need to detect anything
	
	# Create longer ground for racing
	var ground_shape = RectangleShape2D.new()
	ground_shape.size = Vector2(5000, 100)
	
	var ground_collision = CollisionShape2D.new()
	ground_collision.shape = ground_shape
	ground_collision.position = Vector2(0, 400)  # Ground level
	
	ground.add_child(ground_collision)
	
	# Visual representation of ground
	var ground_visual = ColorRect.new()
	ground_visual.size = Vector2(5000, 100)
	ground_visual.position = Vector2(-2500, 350)
	ground_visual.color = Color.BROWN
	add_child(ground_visual)
	
	# Add some obstacles for more interesting terrain
	_add_terrain_obstacles()

func _add_terrain_obstacles():
	# Add some bumps and ramps to make the race more interesting
	var obstacle_positions = [500, 1000, 1500, 2000, 2500]
	for i in range(obstacle_positions.size()):
		var obstacle = StaticBody2D.new()
		add_child(obstacle)
		
		# Set obstacles to same collision layer as ground
		obstacle.collision_layer = 1
		obstacle.collision_mask = 0
		
		var obstacle_shape = RectangleShape2D.new()
		obstacle_shape.size = Vector2(100, 50 + i * 10)  # Increasing height
		
		var obstacle_collision = CollisionShape2D.new()
		obstacle_collision.shape = obstacle_shape
		obstacle_collision.position = Vector2(obstacle_positions[i], 375 - (25 + i * 5))
		
		obstacle.add_child(obstacle_collision)
		
		# Visual
		var obstacle_visual = ColorRect.new()
		obstacle_visual.size = obstacle_shape.size
		obstacle_visual.position = Vector2(-obstacle_shape.size.x/2, -obstacle_shape.size.y/2)
		obstacle_visual.color = Color.DARK_GRAY
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
				"body": car_body,
				"data": car_data,
				"initial_position": car_body.position,
				"car_index": i
			})
			add_child(car_body)
	
	# Wait for simulation to complete
	await simulation_completed
	
	return car_results

func build_car_from_dna(dna_dict: Dictionary, car_index: int) -> RigidBody2D:
	var car_body = RigidBody2D.new()
	# Space cars out at the start line, but keep them closer to origin
	car_body.position = Vector2(50, 150 - car_index * 30)  # Start closer to camera view
	car_body.mass = 10.0
	car_body.gravity_scale = 1.0
	car_body.name = "Car_" + str(car_index)
	
	# Set collision layers so cars don't collide with each other
	# Each car gets its own collision layer (layers 2-31, layer 1 is for ground)
	var car_layer = 2 + (car_index % 29)  # Cycle through layers 2-30
	car_body.collision_layer = 1 << car_layer  # Car exists on its own layer
	car_body.collision_mask = 1  # Car only collides with ground (layer 1)
	
	var frame_parts = dna_dict.get("frame", [])
	var powertrain_parts = dna_dict.get("powertrain", [])
	
	if frame_parts.size() == 0:
		push_error("Car has no frame parts")
		return null
	
	# Build connected car structure
	var all_bodies = [car_body]  # Keep track of all bodies for connections
	var x_offset = 0
	
	# Add main chassis parts first
	for i in range(frame_parts.size()):
		var frame_code = frame_parts[i]
		
		if frame_code == "R":
			_add_rectangle_to_car(car_body, Vector2(x_offset, 0), car_index, car_layer)
		
		x_offset += 50
	
	# Add wheels and connect them properly
	x_offset = 0
	for i in range(frame_parts.size()):
		var frame_code = frame_parts[i]
		
		if frame_code == "W":
			var wheel_power = _calculate_wheel_power(powertrain_parts, i)
			var wheel_body = _add_connected_wheel(car_body, Vector2(x_offset, 35), wheel_power, car_index, car_layer)
			if wheel_body:
				all_bodies.append(wheel_body)
		
		x_offset += 50
	
	# Add some visual variety based on car index
	car_body.modulate = Color.from_hsv(float(car_index) / 20.0, 0.8, 1.0)
	
	return car_body

func _add_rectangle_to_car(car_body: RigidBody2D, offset: Vector2, car_index: int, car_layer: int):
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

func _add_connected_wheel(car_body: RigidBody2D, offset: Vector2, power: float, car_index: int, car_layer: int) -> RigidBody2D:
	var wheel_body = RigidBody2D.new()
	wheel_body.position = car_body.position + offset
	wheel_body.mass = 3.0
	wheel_body.gravity_scale = 1.0
	wheel_body.name = "Wheel_" + str(car_index)
	
	# Set same collision properties as the car body
	wheel_body.collision_layer = 1 << car_layer  # Same layer as car
	wheel_body.collision_mask = 1  # Only collides with ground
	
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = 18
	
	var collision = CollisionShape2D.new()
	collision.shape = circle_shape
	wheel_body.add_child(collision)
	
	# Visual representation
	var visual = ColorRect.new()
	visual.size = Vector2(36, 36)
	visual.position = Vector2(-18, -18)
	visual.color = Color.from_hsv(float(car_index) / 20.0, 1.0, 0.9)
	collision.add_child(visual)
	
	# Create proper pin joint connection
	var joint = PinJoint2D.new()
	car_body.add_child(joint)
	joint.position = offset
	joint.node_a = car_body.get_path()
	joint.node_b = wheel_body.get_path()
	
	# Store wheel power for motor application
	wheel_body.set_meta("motor_power", power)
	wheel_body.set_meta("car_index", car_index)
	
	add_child(wheel_body)
	
	return wheel_body

func _calculate_wheel_power(powertrain_parts: Array, wheel_position: int) -> float:
	var current_power = 0.0
	var current_torque = 10000.0
	
	for i in range(min(powertrain_parts.size(), wheel_position + 1)):
		var part_code = powertrain_parts[i]
		match part_code:
			"C":  # Cylinder
				current_power += randf_range(50.0, 150.0)
			"D":  # DriveShaft
				var efficiency = randf_range(0.85, 0.95)
				current_power *= efficiency
				current_torque *= efficiency
			"G":  # GearSet
				var input_ratio = randf_range(0.7, 1.5)
				var wheel_proportion = randf_range(0.2, 0.8)
				current_power *= input_ratio
				current_torque /= input_ratio
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
	# Apply continuous motor forces to all wheels
	for child in get_children():
		if child is RigidBody2D and child.has_meta("motor_power"):
			var power = child.get_meta("motor_power", 0.0)
			
			# Apply torque for wheel rotation
			child.apply_torque_impulse(power * 0.1)
			
			# Add forward thrust when wheel is in contact with ground
			if _is_wheel_on_ground(child):
				var thrust_force = Vector2(power * 0.5, 0)
				child.apply_central_impulse(thrust_force)

func _is_wheel_on_ground(wheel: RigidBody2D) -> bool:
	# Improved ground contact detection
	var space_state = wheel.get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(
		wheel.position, 
		wheel.position + Vector2(0, 25)
	)
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
	
	# Clean up all cars
	for car_data in current_cars:
		if is_instance_valid(car_data.body):
			car_data.body.queue_free()
	
	# Remove any orphaned bodies
	for child in get_children():
		if child is RigidBody2D and child != ground and "Car_" in child.name:
			child.queue_free()
		if child is RigidBody2D and "Wheel_" in child.name:
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