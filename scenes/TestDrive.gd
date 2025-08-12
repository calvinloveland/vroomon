class_name TestDrive
extends Control

# Test Drive Mode - Single car testing with reset functionality
# Simple scene to test individual car designs

@onready var camera: Camera2D
@onready var simulation_scene: Node2D
@onready var ui_overlay: VBoxContainer
@onready var back_button: Button
@onready var reset_button: Button
@onready var info_label: Label
@onready var timer_label: Label

var test_timer: float = 0.0
var reset_time: float = 15.0
var current_car: RigidBody2D

func _ready():
	setup_ui()
	setup_simulation()
	setup_camera()
	spawn_test_car()

func setup_ui():
	# Create UI overlay in top-left
	ui_overlay = VBoxContainer.new()
	ui_overlay.position = Vector2(10, 10)
	ui_overlay.custom_minimum_size = Vector2(250, 150)
	add_child(ui_overlay)

	# Semi-transparent background
	var background = ColorRect.new()
	background.color = Color(0, 0, 0, 0.7)
	background.size = Vector2(270, 170)
	background.position = Vector2(0, 0)
	add_child(background)
	background.move_to_front()
	ui_overlay.move_to_front()

	# Title
	var title = Label.new()
	title.text = "🚗 Test Drive Mode"
	title.add_theme_font_size_override("font_size", 18)
	title.modulate = Color.WHITE
	ui_overlay.add_child(title)

	# Timer display
	timer_label = Label.new()
	timer_label.text = "Time: 0.0s / 15.0s"
	timer_label.add_theme_font_size_override("font_size", 14)
	timer_label.modulate = Color.YELLOW
	ui_overlay.add_child(timer_label)

	# Info label
	info_label = Label.new()
	info_label.text = "Testing random car design"
	info_label.add_theme_font_size_override("font_size", 12)
	info_label.modulate = Color.LIGHT_GRAY
	ui_overlay.add_child(info_label)

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size.y = 10
	ui_overlay.add_child(spacer)

	# Buttons container
	var button_container = HBoxContainer.new()
	ui_overlay.add_child(button_container)

	# Reset button
	reset_button = Button.new()
	reset_button.text = "🔄 Reset"
	reset_button.custom_minimum_size = Vector2(80, 35)
	reset_button.pressed.connect(_on_reset_pressed)
	button_container.add_child(reset_button)

	# Back button
	back_button = Button.new()
	back_button.text = "🏠 Menu"
	back_button.custom_minimum_size = Vector2(80, 35)
	back_button.pressed.connect(_on_back_pressed)
	button_container.add_child(back_button)

	# Controls info
	var spacer2 = Control.new()
	spacer2.custom_minimum_size.y = 10
	ui_overlay.add_child(spacer2)

	var controls_info = Label.new()
	controls_info.text = "• Arrow keys: Move camera\n• Mouse wheel: Zoom\n• Space: Follow car"
	controls_info.add_theme_font_size_override("font_size", 10)
	controls_info.modulate = Color.LIGHT_GRAY
	ui_overlay.add_child(controls_info)

func setup_simulation():
	var simulation_script = load("res://scripts/CarSimulation.gd")
	simulation_scene = Node2D.new()
	simulation_scene.set_script(simulation_script)
	add_child(simulation_scene)
	# Default area preset for test drive
	if simulation_scene.has_method("set_area_config"):
		simulation_scene.set_area_config(AreaConfigs.get_preset("Grassland"))

func setup_camera():
	camera = Camera2D.new()
	camera.position = Vector2(200, 250)
	camera.zoom = Vector2(0.8, 0.8)
	camera.enabled = true
	add_child(camera)

func spawn_test_car():
	# Generate a random DNA string for testing
	var chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
	var dna_string = ""
	var dna_length = randi_range(8, 16)

	for i in range(dna_length):
		dna_string += chars[randi() % chars.length()]

	# Create CarDNA and translate it for display
	var car_dna_obj = CarDNA.new(dna_string)
	var translated = car_dna_obj.translate_to_frame_and_powertrain()

	var car_dna_dict = {"dna_string": dna_string}

	# Build the car using the simulation scene (builder adds it under a stable root)
	current_car = simulation_scene.build_car_from_dna(car_dna_dict, 0)
	if current_car:
		info_label.text = "DNA: '%s'\nFrame: %s\nPowertrain: %s" % [dna_string, str(translated.frame), str(translated.powertrain)]

		# Reset timer
		test_timer = 0.0

		print("Spawned test car with DNA string: '", dna_string, "'")
		print("  Translated to - Frame: ", translated.frame, ", Powertrain: ", translated.powertrain)

func _process(delta):
	test_timer += delta
	timer_label.text = "Time: %.1fs / %.1fs" % [test_timer, reset_time]

	# Auto-reset after time limit
	if test_timer >= reset_time:
		reset_car()

	# Update camera to follow car if it exists
	if current_car and is_instance_valid(current_car):
		# Smoothly follow the car
		var target_pos = current_car.position
		camera.position = camera.position.lerp(target_pos, delta * 2.0)

func reset_car():
	print("Resetting test car...")

	# Remove old car (prefer freeing the CarRoot)
	if current_car and is_instance_valid(current_car):
		var root := current_car.get_parent()
		if root and is_instance_valid(root) and root.name.begins_with("Car_"):
			root.queue_free()
		else:
			current_car.queue_free()
		current_car = null

	# Wait a frame for cleanup
	await get_tree().process_frame

	# Spawn new car
	spawn_test_car()

func _on_reset_pressed():
	reset_car()

func _on_back_pressed():
	# Return to main menu
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _input(event):
	if not camera:
		return

	# Camera controls
	var camera_speed = 300.0 / camera.zoom.x
	var zoom_speed = 0.15

	if event.is_action_pressed("ui_left"):
		camera.position.x -= camera_speed
	elif event.is_action_pressed("ui_right"):
		camera.position.x += camera_speed
	elif event.is_action_pressed("ui_up"):
		camera.position.y -= camera_speed
	elif event.is_action_pressed("ui_down"):
		camera.position.y += camera_speed
	elif event.is_action_pressed("ui_accept"):  # Space key
		if current_car and is_instance_valid(current_car):
			camera.position = current_car.position
	elif event.is_action_pressed("ui_cancel"):  # Escape key
		_on_back_pressed()

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.zoom *= (1.0 + zoom_speed)
			camera.zoom = camera.zoom.clamp(Vector2(0.2, 0.2), Vector2(3.0, 3.0))
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.zoom *= (1.0 - zoom_speed)
			camera.zoom = camera.zoom.clamp(Vector2(0.2, 0.2), Vector2(3.0, 3.0))
