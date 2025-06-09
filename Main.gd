extends Control

# Main UI for Car Evolution Simulation
# Simple overlay controls on single viewport

@onready var population_manager: Node2D
@onready var start_button: Button
@onready var generation_label: Label
@onready var best_score_label: Label
@onready var status_label: Label
@onready var progress_bar: ProgressBar
@onready var settings_panel: VBoxContainer
@onready var camera: Camera2D

var is_evolution_running: bool = false

func _ready():
	setup_ui()
	setup_population_manager()
	setup_camera()

func setup_ui():
	# Create overlay panel in top-left corner
	var overlay_panel = VBoxContainer.new()
	overlay_panel.position = Vector2(10, 10)
	overlay_panel.custom_minimum_size = Vector2(300, 400)
	add_child(overlay_panel)
	
	# Add semi-transparent background
	var background = ColorRect.new()
	background.color = Color(0, 0, 0, 0.7)  # Semi-transparent black
	background.size = Vector2(320, 420)
	background.position = Vector2(0, 0)
	add_child(background)
	background.move_to_front()
	overlay_panel.move_to_front()
	
	# Title
	var title = Label.new()
	title.text = "Car Evolution"
	title.add_theme_font_size_override("font_size", 20)
	title.modulate = Color.WHITE
	overlay_panel.add_child(title)
	
	# Settings
	settings_panel = VBoxContainer.new()
	overlay_panel.add_child(settings_panel)
	
	var settings_label = Label.new()
	settings_label.text = "Settings:"
	settings_label.add_theme_font_size_override("font_size", 14)
	settings_label.modulate = Color.WHITE
	settings_panel.add_child(settings_label)
	
	# Population size
	var pop_hbox = HBoxContainer.new()
	settings_panel.add_child(pop_hbox)
	var pop_label = Label.new()
	pop_label.text = "Population:"
	pop_label.custom_minimum_size.x = 80
	pop_label.modulate = Color.WHITE
	pop_hbox.add_child(pop_label)
	var pop_spinbox = SpinBox.new()
	pop_spinbox.min_value = 5
	pop_spinbox.max_value = 30
	pop_spinbox.value = 15
	pop_spinbox.custom_minimum_size.x = 80
	pop_spinbox.value_changed.connect(_on_population_size_changed)
	pop_hbox.add_child(pop_spinbox)
	
	# Generations
	var gen_hbox = HBoxContainer.new()
	settings_panel.add_child(gen_hbox)
	var gen_label = Label.new()
	gen_label.text = "Generations:"
	gen_label.custom_minimum_size.x = 80
	gen_label.modulate = Color.WHITE
	gen_hbox.add_child(gen_label)
	var gen_spinbox = SpinBox.new()
	gen_spinbox.min_value = 1
	gen_spinbox.max_value = 20
	gen_spinbox.value = 10
	gen_spinbox.custom_minimum_size.x = 80
	gen_spinbox.value_changed.connect(_on_generations_changed)
	gen_hbox.add_child(gen_spinbox)
	
	# DNA length
	var dna_hbox = HBoxContainer.new()
	settings_panel.add_child(dna_hbox)
	var dna_label = Label.new()
	dna_label.text = "DNA Length:"
	dna_label.custom_minimum_size.x = 80
	dna_label.modulate = Color.WHITE
	dna_hbox.add_child(dna_label)
	var dna_spinbox = SpinBox.new()
	dna_spinbox.min_value = 3
	dna_spinbox.max_value = 8
	dna_spinbox.value = 5
	dna_spinbox.custom_minimum_size.x = 80
	dna_spinbox.value_changed.connect(_on_dna_length_changed)
	dna_hbox.add_child(dna_spinbox)
	
	# Spacer
	var spacer1 = Control.new()
	spacer1.custom_minimum_size.y = 10
	overlay_panel.add_child(spacer1)
	
	# Start button
	start_button = Button.new()
	start_button.text = "Start Evolution"
	start_button.custom_minimum_size = Vector2(180, 35)
	start_button.pressed.connect(_on_start_button_pressed)
	overlay_panel.add_child(start_button)
	
	# Spacer
	var spacer2 = Control.new()
	spacer2.custom_minimum_size.y = 15
	overlay_panel.add_child(spacer2)
	
	# Progress info
	generation_label = Label.new()
	generation_label.text = "Generation: Not started"
	generation_label.add_theme_font_size_override("font_size", 12)
	generation_label.modulate = Color.WHITE
	overlay_panel.add_child(generation_label)
	
	best_score_label = Label.new()
	best_score_label.text = "Best Score: --"
	best_score_label.add_theme_font_size_override("font_size", 12)
	best_score_label.modulate = Color.WHITE
	overlay_panel.add_child(best_score_label)
	
	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size.y = 20
	progress_bar.show_percentage = false
	overlay_panel.add_child(progress_bar)
	
	status_label = Label.new()
	status_label.text = "Ready to start"
	status_label.add_theme_font_size_override("font_size", 11)
	status_label.modulate = Color.LIGHT_GRAY
	overlay_panel.add_child(status_label)
	
	# Camera controls info
	var spacer3 = Control.new()
	spacer3.custom_minimum_size.y = 15
	overlay_panel.add_child(spacer3)
	
	var controls_label = Label.new()
	controls_label.text = "Controls:"
	controls_label.add_theme_font_size_override("font_size", 12)
	controls_label.modulate = Color.WHITE
	overlay_panel.add_child(controls_label)
	
	var controls_info = Label.new()
	controls_info.text = "• Arrow keys: Move camera\n• Mouse wheel: Zoom\n• Space: Follow leader\n• ESC: Quit"
	controls_info.add_theme_font_size_override("font_size", 10)
	controls_info.modulate = Color.LIGHT_GRAY
	overlay_panel.add_child(controls_info)

func setup_camera():
	camera = Camera2D.new()
	camera.position = Vector2(200, 250)  # Start looking at the starting line
	camera.zoom = Vector2(0.6, 0.6)  # Good overview zoom
	camera.enabled = true
	add_child(camera)

func setup_population_manager():
	var population_script = load("res://population.gd")
	population_manager = Node2D.new()
	population_manager.set_script(population_script)
	add_child(population_manager)
	
	# Connect signals
	population_manager.generation_completed.connect(_on_generation_completed)
	population_manager.evolution_finished.connect(_on_evolution_finished)

func _input(event):
	# Handle escape key
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
		return
	
	if not camera:
		return
	
	# Camera controls
	var camera_speed = 300.0 / camera.zoom.x  # Adjust speed based on zoom
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
		_follow_leader()
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.zoom *= (1.0 + zoom_speed)
			camera.zoom = camera.zoom.clamp(Vector2(0.2, 0.2), Vector2(3.0, 3.0))
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.zoom *= (1.0 - zoom_speed)
			camera.zoom = camera.zoom.clamp(Vector2(0.2, 0.2), Vector2(3.0, 3.0))

func _follow_leader():
	# Find the car that's farthest ahead and follow it
	var leader_position = Vector2(200, 250)
	var max_distance = -999999.0
	
	if population_manager and population_manager.simulation_scene:
		for child in population_manager.simulation_scene.get_children():
			if child is RigidBody2D and "Car_" in child.name:
				if child.position.x > max_distance:
					max_distance = child.position.x
					leader_position = child.position
	
	camera.position = leader_position

func _on_start_button_pressed():
	if is_evolution_running:
		return
	
	is_evolution_running = true
	start_button.text = "Running..."
	start_button.disabled = true
	settings_panel.modulate = Color.GRAY
	
	status_label.text = "Starting evolution..."
	progress_bar.value = 0
	progress_bar.max_value = population_manager.generations
	
	# Start the evolution process
	population_manager.start_evolution()

func _on_population_size_changed(value: float):
	if population_manager:
		population_manager.population_size = int(value)

func _on_generations_changed(value: float):
	if population_manager:
		population_manager.generations = int(value)
		if progress_bar:
			progress_bar.max_value = int(value)

func _on_dna_length_changed(value: float):
	if population_manager:
		population_manager.dna_length = int(value)

func _on_generation_completed(generation: int, best_score: float):
	generation_label.text = "Generation: %d/%d" % [generation, population_manager.generations]
	best_score_label.text = "Best Score: %.1f" % best_score
	progress_bar.value = generation
	status_label.text = "Racing generation %d..." % generation
	
	print("UI: Generation %d completed with best score: %.1f" % [generation, best_score])

func _on_evolution_finished(final_best_car):
	is_evolution_running = false
	start_button.text = "Start Evolution"
	start_button.disabled = false
	settings_panel.modulate = Color.WHITE
	
	status_label.text = "Evolution completed!"
	status_label.modulate = Color.GREEN
	
	print("UI: Evolution finished!")
	
	# Show completion dialog
	show_completion_dialog(final_best_car)

func show_completion_dialog(best_car):
	var dialog = AcceptDialog.new()
	dialog.title = "Evolution Complete!"
	
	var content = VBoxContainer.new()
	
	var result_label = Label.new()
	result_label.text = "Evolution completed successfully!"
	result_label.add_theme_font_size_override("font_size", 16)
	content.add_child(result_label)
	
	var score_label = Label.new()
	score_label.text = "Final Best Score: %.2f" % best_car.score
	score_label.add_theme_font_size_override("font_size", 14)
	content.add_child(score_label)
	
	var dna_label = Label.new()
	dna_label.text = "Best Car DNA:"
	dna_label.add_theme_font_size_override("font_size", 14)
	content.add_child(dna_label)
	
	var frame_label = Label.new()
	frame_label.text = "Frame: %s" % str(best_car.dna.frame)
	frame_label.add_theme_font_size_override("font_size", 12)
	content.add_child(frame_label)
	
	var powertrain_label = Label.new()
	powertrain_label.text = "Powertrain: %s" % str(best_car.dna.powertrain)
	powertrain_label.add_theme_font_size_override("font_size", 12)
	content.add_child(powertrain_label)
	
	dialog.add_child(content)
	add_child(dialog)
	dialog.popup_centered()
	
	dialog.confirmed.connect(func(): dialog.queue_free())
