class_name Car
extends RefCounted

# Individual car representation with DNA and genetic operations
# Handles mutation and reproduction for the genetic algorithm

var dna: CarDNA
var score: float = 0.0
var _rect_bodies: Array[RigidBody2D] = []
var _connectors: Array = []  # each: {a: RigidBody2D, b: RigidBody2D, theta_star: float, k: float, c: float, slack: float, tau_cap: float}

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
	Uses DNA v2 translation for modules and parameters."""
	# Stable parent for this car
	var car_root: Node2D = Node2D.new()
	car_root.name = "Car_%d" % car_index
	car_root.add_to_group("car")
	parent.add_child(car_root)

	# Unique collision layer per car; only collide with ground (layer 1)
	var car_layer: int = 2 + (car_index % 29)

	# Determine parts from DNA v2
	if dna_dict.has("dna_string"):
		dna = CarDNA.new()
		dna.from_dict(dna_dict)
	else:
		# Construct from provided dict fallback (rare); treat as string directly if present
		dna = CarDNA.new(str(dna_dict.get("dna", "")))

	var v2: Dictionary = dna.translate_v2()
	var modules: Array = v2.get("modules", []) as Array
	var positions: Array = v2.get("positions", []) as Array
	var rect_params_list: Array = v2.get("rect_params", []) as Array
	var wheel_params_list: Array = v2.get("wheel_params", []) as Array
	# connectors from DNA are not directly used here; we compute adjacency ourselves
	var _globals: Dictionary = v2.get("globals", {}) as Dictionary

	if modules.is_empty():
		push_error("Car has no modules - DNA: " + str(dna_dict))
		return null

	_rect_bodies.clear()
	self._connectors.clear()

	# Build rectangle bodies
	var base_pos: Vector2 = Vector2(50, 150 - car_index * 30)
	var rect_index_by_module: Dictionary = {}
	for i in range(modules.size()):
		if modules[i] == "R":
			var rparams: Dictionary = rect_params_list[i] if i < rect_params_list.size() else {}
			var w: float = float(rparams.get("width", 45.0))
			var h: float = float(rparams.get("height", 25.0))
			var density: float = float(rparams.get("density", 1.0))
			var x_local: float = float(positions[i]) - float(positions[0]) if positions.size() > 0 else 0.0
			var body: RigidBody2D = _create_rectangle_body(car_root, base_pos + Vector2(x_local, 0), Vector2(w, h), car_index, car_layer, density)
			_rect_bodies.append(body)
			rect_index_by_module[i] = _rect_bodies.size() - 1

	# Ensure at least one rectangle exists
	if _rect_bodies.is_empty():
		var body: RigidBody2D = _create_rectangle_body(car_root, base_pos, Vector2(45, 25), car_index, car_layer, 1.0)
		_rect_bodies.append(body)
		rect_index_by_module[0] = 0

	# Attach wheels to nearest prior rectangle
	var last_rect_body: RigidBody2D = null
	for i in range(modules.size()):
		if modules[i] == "R":
			# Update last_rect_body to this module's rectangle
			if rect_index_by_module.has(i):
				last_rect_body = _rect_bodies[int(rect_index_by_module[i])]
			continue
		elif modules[i] == "W":
			if last_rect_body:
				var wparams: Dictionary = wheel_params_list[i] if i < wheel_params_list.size() else {}
				var radius: float = float(wparams.get("radius", 18.0))
				var motor_power: float = float(wparams.get("motor_power", 90.0))
				var friction: float = float(wparams.get("friction", 1.0))
				var wheel_size: Vector2 = Vector2(radius * 2.0, radius * 2.0)
				_add_connected_wheel(last_rect_body, Vector2(0, 35), motor_power, car_index, car_layer, wheel_size, friction)

	# Build rotational connectors by chaining rectangles in encounter order (ignoring wheels)
	if _rect_bodies.size() >= 2:
		for r in range(_rect_bodies.size() - 1):
			var a: RigidBody2D = _rect_bodies[r]
			var b: RigidBody2D = _rect_bodies[r + 1]
			# Place two PinJoint2D anchors to strongly couple positions (approximate a weld)
			var mid: Vector2 = (a.global_position + b.global_position) / 2.0
			var dir: Vector2 = b.global_position - a.global_position
			var dist: float = dir.length()
			if dist > 0.001:
				dir /= dist
			else:
				dir = Vector2.RIGHT
			var perp: Vector2 = Vector2(-dir.y, dir.x)
			var size_a: Vector2 = a.get_meta("rect_size", Vector2(45, 25))
			var size_b: Vector2 = b.get_meta("rect_size", Vector2(45, 25))
			var spread: float = min(size_a.y, size_b.y) * 0.45
			var anchor1: Vector2 = mid + perp * spread
			var anchor2: Vector2 = mid - perp * spread

			var joint1: PinJoint2D = PinJoint2D.new()
			joint1.global_position = anchor1
			car_root.add_child(joint1)
			joint1.node_a = a.get_path()
			joint1.node_b = b.get_path()

			var joint2: PinJoint2D = PinJoint2D.new()
			joint2.global_position = anchor2
			car_root.add_child(joint2)
			joint2.node_a = a.get_path()
			joint2.node_b = b.get_path()
			# PD parameters from DNA (use the corresponding module index if available, fallback to r)
			var idx_for_params: int = r
			var cparams: Dictionary = dna.connector_params(idx_for_params)
			var target: float = deg_to_rad(float(cparams.get("angle_deg", 0.0)))
			# Much stronger base stiffness/damping and higher caps; scale by mass/inertia
			var base_k: float = float(cparams.get("stiffness_k", 0.8)) * 150.0
			var base_d: float = float(cparams.get("damping_c", 0.4)) * 40.0
			var avg_mass: float = 0.5 * (a.mass + b.mass)
			var Ia: float = float(a.get_meta("inertia_est", a.mass * 2000.0))
			var Ib: float = float(b.get_meta("inertia_est", b.mass * 2000.0))
			var I_avg: float = max(1.0, 0.5 * (Ia + Ib))
			var k_eff: float = base_k * (1.0 + avg_mass / 6.0)
			var d_eff: float = base_d * (1.0 + avg_mass / 6.0)
			var slack: float = min(deg_to_rad(float(cparams.get("slack_deg", 0.2))), deg_to_rad(0.1))
			var tau_cap: float = clamp(60000.0 + 1200.0 * avg_mass + 0.08 * I_avg, 30000.0, 200000.0)
			self._connectors.append({
				"a": a, "b": b, "theta_star": target, "k": k_eff, "c": d_eff, "slack": slack, "tau_cap": tau_cap
			})

	# Choose primary body as the first rectangle
	var primary: RigidBody2D = _rect_bodies[0]
	# Visual variety: tint rectangle visuals
	primary.modulate = Color.from_hsv(float(car_index) / 20.0, 0.8, 1.0)
	return primary

func _create_rectangle_body(root: Node2D, global_pos: Vector2, size: Vector2, car_index: int, car_layer: int, density: float) -> RigidBody2D:
	var body: RigidBody2D = RigidBody2D.new()
	body.position = global_pos
	body.gravity_scale = 1.0
	body.name = "Rect_" + str(car_index) + "_" + str(_rect_bodies.size())
	body.can_sleep = false
	body.linear_damp = 0.1
	body.angular_damp = 0.2
	# Collision settings: this car's unique layer, collide only with ground (layer 1)
	body.collision_layer = 1 << car_layer
	body.collision_mask = 1

	var rect_shape: RectangleShape2D = RectangleShape2D.new()
	rect_shape.size = size
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.shape = rect_shape
	body.add_child(collision)

	# Visual
	var visual: ColorRect = ColorRect.new()
	visual.size = rect_shape.size
	visual.position = Vector2(-rect_shape.size.x / 2.0, -rect_shape.size.y / 2.0)
	visual.color = Color.from_hsv(float(car_index) / 20.0, 0.6, 0.8)
	collision.add_child(visual)

	# Mass from area * density (scaled)
	var area: float = max(1.0, size.x * size.y)
	body.mass = clamp((area * density) / 200.0, 2.0, 80.0)

	# Store geometry and inertia estimate for connector scaling
	body.set_meta("rect_size", size)
	var inertia_est: float = body.mass * (size.x * size.x + size.y * size.y) / 12.0
	body.set_meta("inertia_est", inertia_est)

	root.add_child(body)
	return body

func _get_wheel_size(wheel_pos: int, use_new_dna: bool) -> Vector2:
	# Get wheel size from DNA string, fallback to default if old format
	if use_new_dna and dna:
		var size: float = dna.get_wheel_size(wheel_pos)
		return Vector2(size, size)
	return Vector2(36, 36)

func _add_connected_wheel(host: RigidBody2D, offset: Vector2, power: float, car_index: int, car_layer: int, wheel_size: Vector2 = Vector2(36, 36), friction: float = 1.0) -> RigidBody2D:
	var wheel_body: RigidBody2D = RigidBody2D.new()
	wheel_body.position = host.position + offset
	wheel_body.mass = 3.0
	wheel_body.gravity_scale = 1.0
	wheel_body.name = "Wheel_" + str(car_index)
	# Ensure rotation is visible and doesn't sleep away
	wheel_body.can_sleep = false
	wheel_body.angular_damp = 0.1

	# Same collision properties as chassis
	wheel_body.collision_layer = 1 << car_layer
	wheel_body.collision_mask = 1

	var circle_shape: CircleShape2D = CircleShape2D.new()
	circle_shape.radius = wheel_size.x / 2

	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.shape = circle_shape
	# Apply wheel friction via physics material
	var mat: PhysicsMaterial = PhysicsMaterial.new()
	mat.friction = friction
	wheel_body.physics_material_override = mat
	wheel_body.add_child(collision)

	# Visuals container that rotates with the wheel
	var visual: Node2D = Node2D.new()
	visual.name = "Visual"
	visual.z_index = 20
	wheel_body.add_child(visual)

	# Draw a filled circle and a spoke for rotation perception
	var color: Color = Color.from_hsv(float(car_index) / 20.0, 1.0, 0.9)
	var poly: Polygon2D = Polygon2D.new()
	poly.polygon = _make_circle_points(circle_shape.radius, 24)
	poly.color = color
	visual.add_child(poly)

	var spoke: Line2D = Line2D.new()
	spoke.width = 2.0
	spoke.default_color = Color.BLACK
	spoke.points = PackedVector2Array([Vector2.ZERO, Vector2(circle_shape.radius, 0)])
	visual.add_child(spoke)

	# Add wheel to same root as chassis
	var root: Node = host.get_parent()
	if root:
		root.add_child(wheel_body)
	else:
		# Fallback; should not happen when using build_in
		wheel_body.owner = host.owner

	# Create pin joint under the stable root now that both are in the tree
	var joint: PinJoint2D = PinJoint2D.new()
	joint.global_position = wheel_body.global_position  # rotate about wheel center
	if root:
		root.add_child(joint)
	else:
		host.add_child(joint)
	joint.node_a = host.get_path()
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

func update_connectors(delta: float) -> void:
	# Apply PD torque on rectangle connectors to approach target relative angle
	for c in _connectors:
		var a: RigidBody2D = c.a
		var b: RigidBody2D = c.b
		if not is_instance_valid(a) or not is_instance_valid(b):
			continue
		var theta_star: float = c.theta_star
		var k: float = c.k
		var d: float = c.c
		var slack: float = c.slack
		var cap: float = c.tau_cap
		var theta: float = wrapf(b.rotation - a.rotation, -PI, PI)
		var err: float = theta_star - theta
		# slack dead-zone
		if abs(err) < slack:
			continue
		if err > 0:
			err -= slack
		else:
			err += slack
		var omega_rel: float = b.angular_velocity - a.angular_velocity
		# Scale by estimated inertia and apply as impulse for stronger effect per-step
		var Ia: float = float(a.get_meta("inertia_est", a.mass * 2000.0))
		var Ib: float = float(b.get_meta("inertia_est", b.mass * 2000.0))
		var I_avg: float = max(1.0, 0.5 * (Ia + Ib))
		var tau: float = (k * err - d * omega_rel) * max(1.0, I_avg * 0.001)
		tau = clamp(tau, -cap, cap)
		var tau_imp: float = tau * delta
		# equal and opposite torques
		b.apply_torque_impulse(tau_imp)
		a.apply_torque_impulse(-tau_imp)
