class_name Car
extends RefCounted

# Individual car representation with DNA and genetic operations
# Handles mutation and reproduction for the genetic algorithm

var dna: CarDNA
var score: float = 0.0

func _init(car_dna: CarDNA = null):
	if car_dna:
		dna = car_dna
	else:
		dna = CarDNA.new()

func mutate() -> Car:
	"""Mutate the car's DNA string using various string operations"""
	var mutated_string = dna.get_dna_string()
	var replace_p = 0.15
	var remove_p = 0.05
	var insert_p = 0.10

	# Convert to character array for easier manipulation
	var chars = []
	for i in range(mutated_string.length()):
		chars.append(mutated_string[i])

	var i = 0
	while i < chars.size():
		var r = randf()
		if r < replace_p:
			# Replace character with random alphanumeric
			chars[i] = _get_random_char()
			i += 1
		elif r < replace_p + remove_p and chars.size() > 3:
			# Remove character (but keep minimum length)
			chars.remove_at(i)
		elif r < replace_p + remove_p + insert_p:
			# Insert random character
			chars.insert(i, _get_random_char())
			i += 1
		else:
			i += 1

	# Convert back to string
	var new_dna_string = ""
	for character in chars:
		new_dna_string += character

	var mutated_dna = CarDNA.new(new_dna_string)
	return Car.new(mutated_dna)

func _get_random_char() -> String:
	"""Get a random alphanumeric character"""
	var chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
	return chars[randi() % chars.length()]

static func reproduce(car1: Car, car2: Car) -> Car:
	"""Reproduce two cars by combining their DNA strings"""
	var dna1 = car1.dna.get_dna_string()
	var dna2 = car2.dna.get_dna_string()

	# Simple string crossover - take sections from each parent
	var child_dna = ""
	var max_length = max(dna1.length(), dna2.length())

	for i in range(max_length):
		if randf() < 0.5:
			# Take from parent 1
			if i < dna1.length():
				child_dna += dna1[i]
		else:
			# Take from parent 2
			if i < dna2.length():
				child_dna += dna2[i]

	# Alternative crossover method: take chunks
	if randf() < 0.3:  # 30% chance to use chunk crossover
		child_dna = _chunk_crossover(dna1, dna2)

	var child_car_dna = CarDNA.new(child_dna)
	var child = Car.new(child_car_dna)
	return child.mutate()

static func _chunk_crossover(dna1: String, dna2: String) -> String:
	"""Perform chunk-based crossover between two DNA strings"""
	var result = ""
	var pos = 0

	while pos < max(dna1.length(), dna2.length()):
		var chunk_size = randi_range(1, 4)
		var use_first = randf() < 0.5

		for i in range(chunk_size):
			if pos + i >= max(dna1.length(), dna2.length()):
				break

			if use_first and pos + i < dna1.length():
				result += dna1[pos + i]
			elif not use_first and pos + i < dna2.length():
				result += dna2[pos + i]
			elif pos + i < dna1.length():
				result += dna1[pos + i]
			elif pos + i < dna2.length():
				result += dna2[pos + i]

		pos += chunk_size

	return result

func get_translated_dna() -> Dictionary:
	"""Get the translated frame and powertrain from the DNA string"""
	return dna.translate_to_frame_and_powertrain()

func get_dna_string() -> String:
	"""Get the raw DNA string"""
	return dna.get_dna_string()

# --- Scene construction moved from CarSimulation ---

func build_in(parent: Node2D, car_index: int, dna_dict: Dictionary) -> RigidBody2D:
	"""Build this car's scene (chassis, wheels, joints) under `parent` and return the chassis body.
	Handles both new dna_string format and old frame/powertrain dicts."""
	# Stable parent for this car
	var car_root := Node2D.new()
	car_root.name = "Car_%d" % car_index
	car_root.add_to_group("car")
	parent.add_child(car_root)

	# Chassis
	var chassis := RigidBody2D.new()
	chassis.position = Vector2(50, 150 - car_index * 30)
	chassis.mass = 10.0
	chassis.gravity_scale = 1.0
	chassis.name = "Chassis"
	chassis.can_sleep = false
	chassis.linear_damp = 0.1
	chassis.angular_damp = 0.2

	# Unique collision layer per car; only collide with ground (layer 1)
	var car_layer: int = 2 + (car_index % 29)
	chassis.collision_layer = 1 << car_layer
	chassis.collision_mask = 1

	# Determine parts from DNA
	var frame_parts: Array = []
	var powertrain_parts: Array = []
	var use_new_dna: bool = false
	if dna_dict.has("dna_string"):
		use_new_dna = true
		# Ensure our Car.dna matches provided dict
		dna = CarDNA.new()
		dna.from_dict(dna_dict)
		var translated = dna.translate_to_frame_and_powertrain()
		frame_parts = translated.frame
		powertrain_parts = translated.powertrain
	else:
		# Old format compatibility
		frame_parts = dna_dict.get("frame", [])
		powertrain_parts = dna_dict.get("powertrain", [])

	if frame_parts.size() == 0:
		push_error("Car has no frame parts - DNA: " + str(dna_dict))
		return null

	# Attach chassis under stable root
	car_root.add_child(chassis)

	# Spacing and anchors
	var spacing := 50
	var anchor_positions: Array = []

	# First pass: rectangles advance x
	var x_offset := 0
	for i in range(frame_parts.size()):
		var frame_code: String = str(frame_parts[i])
		if frame_code == "R":
			_add_rectangle_to_chassis(chassis, Vector2(x_offset, 0), car_index, car_layer)
			anchor_positions.append(x_offset)
			x_offset += spacing
		# Wheels do not advance x_offset

	# Ensure at least one rectangle anchor
	if anchor_positions.is_empty():
		_add_rectangle_to_chassis(chassis, Vector2(0, 0), car_index, car_layer)
		anchor_positions.append(0)

	# Second pass: attach wheels near nearest prior rectangle
	var rect_progress: int = 0
	for i in range(frame_parts.size()):
		var frame_code: String = str(frame_parts[i])
		if frame_code == "R":
			rect_progress += 1
			continue
		elif frame_code == "W":
			var anchor_index: int = max(0, rect_progress - 1)
			anchor_index = min(anchor_index, anchor_positions.size() - 1)
			var anchor_x: int = int(anchor_positions[anchor_index])
			var wheel_dna: CarDNA = dna if use_new_dna else null
			var wheel_power: float = _calculate_wheel_power(powertrain_parts, i, wheel_dna, i)
			var wheel_size: Vector2 = _get_wheel_size(i, use_new_dna)
			_add_connected_wheel(chassis, Vector2(anchor_x, 35), wheel_power, car_index, car_layer, wheel_size)

	# Visual variety
	chassis.modulate = Color.from_hsv(float(car_index) / 20.0, 0.8, 1.0)

	return chassis

func _add_rectangle_to_chassis(chassis: RigidBody2D, offset: Vector2, car_index: int, _car_layer: int) -> void:
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = Vector2(45, 25)

	var collision := CollisionShape2D.new()
	collision.shape = rect_shape
	collision.position = offset
	chassis.add_child(collision)

	# Visual
	var visual := ColorRect.new()
	visual.size = Vector2(45, 25)
	visual.position = offset - Vector2(22.5, 12.5)
	visual.color = Color.from_hsv(float(car_index) / 20.0, 0.6, 0.8)
	collision.add_child(visual)

func _get_wheel_size(wheel_pos: int, use_new_dna: bool) -> Vector2:
	# Get wheel size from DNA string, fallback to default if old format
	if use_new_dna and dna:
		var size := dna.get_wheel_size(wheel_pos)
		return Vector2(size, size)
	return Vector2(36, 36)

func _add_connected_wheel(chassis: RigidBody2D, offset: Vector2, power: float, car_index: int, car_layer: int, wheel_size: Vector2 = Vector2(36, 36)) -> RigidBody2D:
	var wheel_body := RigidBody2D.new()
	wheel_body.position = chassis.position + offset
	wheel_body.mass = 3.0
	wheel_body.gravity_scale = 1.0
	wheel_body.name = "Wheel_" + str(car_index)
	# Ensure rotation is visible and doesn't sleep away
	wheel_body.can_sleep = false
	wheel_body.angular_damp = 0.1

	# Same collision properties as chassis
	wheel_body.collision_layer = 1 << car_layer
	wheel_body.collision_mask = 1

	var circle_shape := CircleShape2D.new()
	circle_shape.radius = wheel_size.x / 2

	var collision := CollisionShape2D.new()
	collision.shape = circle_shape
	wheel_body.add_child(collision)

	# Visuals container that rotates with the wheel
	var visual := Node2D.new()
	visual.name = "Visual"
	visual.z_index = 20
	wheel_body.add_child(visual)

	# Draw a filled circle and a spoke for rotation perception
	var color := Color.from_hsv(float(car_index) / 20.0, 1.0, 0.9)
	var poly := Polygon2D.new()
	poly.polygon = _make_circle_points(circle_shape.radius, 24)
	poly.color = color
	visual.add_child(poly)

	var spoke := Line2D.new()
	spoke.width = 2.0
	spoke.default_color = Color.BLACK
	spoke.points = PackedVector2Array([Vector2.ZERO, Vector2(circle_shape.radius, 0)])
	visual.add_child(spoke)

	# Add wheel to same root as chassis
	var root := chassis.get_parent()
	if root:
		root.add_child(wheel_body)
	else:
		# Fallback; should not happen when using build_in
		wheel_body.owner = chassis.owner

	# Create pin joint under the stable root now that both are in the tree
	var joint := PinJoint2D.new()
	joint.global_position = wheel_body.global_position  # rotate about wheel center
	if root:
		root.add_child(joint)
	else:
		chassis.add_child(joint)
	joint.node_a = chassis.get_path()
	joint.node_b = wheel_body.get_path()

	# Store wheel power and radius for motor application
	wheel_body.set_meta("motor_power", power)
	wheel_body.set_meta("car_index", car_index)
	wheel_body.set_meta("wheel_radius", float(wheel_size.x) / 2.0)
	# Optional: group wheels for convenience
	wheel_body.add_to_group("motor_wheel")

	return wheel_body

func _make_circle_points(radius: float, segments: int = 24) -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array()
	for i in range(segments):
		var t := TAU * float(i) / float(segments)
		pts.append(Vector2(cos(t), sin(t)) * radius)
	return pts

func _calculate_wheel_power(powertrain_parts: Array, wheel_position: int, car_dna: CarDNA = null, dna_index: int = 0) -> float:
	var current_power := 0.0
	var _current_torque := 10000.0

	var power_factor := 1.0
	var efficiency_factor := 1.0
	if car_dna:
		power_factor = car_dna.get_power_factor(dna_index)
		efficiency_factor = car_dna.get_efficiency_factor(dna_index)

	for i in range(min(powertrain_parts.size(), wheel_position + 1)):
		var part_code = powertrain_parts[i]
		match part_code:
			"C":
				current_power += randf_range(50.0, 150.0) * power_factor
			"D":
				var efficiency := randf_range(0.85, 0.95) * efficiency_factor
				current_power *= efficiency
				_current_torque *= efficiency
			"G":
				var input_ratio := randf_range(0.7, 1.5)
				var wheel_proportion := randf_range(0.2, 0.8)
				current_power *= input_ratio
				_current_torque /= input_ratio
				if i == wheel_position:
					return current_power * wheel_proportion
	return current_power

func update_wheels(car_root: Node, preview: bool = false) -> void:
	# Centralized wheel update logic for this car
	if car_root == null or not is_instance_valid(car_root):
		return
	for node in car_root.get_children():
		if node is RigidBody2D and node.is_in_group("motor_wheel"):
			# Ensure wheels stay awake
			node.can_sleep = false
			if preview:
				# Force visible rotation for previews
				var target_av: float = 12.0
				node.angular_velocity = target_av
				var visual := node.get_node_or_null("Visual")
				if visual and visual is Node2D:
					var angle_increment: float = 0.25
					visual.rotation += angle_increment
			else:
				# Physics-driven torque from metadata
				assert(node.has_meta("motor_power"), "Wheel missing motor_power meta: %s" % node.name)
				var power: float = float(node.get_meta("motor_power"))
				var radius: float = float(node.get_meta("wheel_radius", 18.0))
				var torque_scale: float = 2.0 * float(max(12.0, radius)) / 18.0
				var torque: float = float(max(5.0, power)) * torque_scale
				node.apply_torque_impulse(torque)
