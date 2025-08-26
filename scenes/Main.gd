extends Control

# Main UI for Car Evolution Simulation
# Simple overlay controls on single viewport

@onready var population_manager: Node2D
@onready var start_button: Button
@onready var back_button: Button
@onready var generation_label: Label
@onready var best_score_label: Label
@onready var status_label: Label
@onready var progress_bar: ProgressBar
@onready var settings_panel: VBoxContainer
@onready var camera: Camera2D

var is_evolution_running: bool = false
var wallet_label: Label
var stats_panel: RichTextLabel

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
	pop_spinbox.min_value = 10
	pop_spinbox.max_value = 200
	pop_spinbox.value = 100
	pop_spinbox.custom_minimum_size.x = 80
	pop_spinbox.value_changed.connect(_on_population_size_changed)
	pop_hbox.add_child(pop_spinbox)

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
	dna_spinbox.max_value = 24
	dna_spinbox.value = 12
	dna_spinbox.custom_minimum_size.x = 80
	dna_spinbox.value_changed.connect(_on_dna_length_changed)
	dna_hbox.add_child(dna_spinbox)

	# Terrain preset
	var area_hbox = HBoxContainer.new()
	settings_panel.add_child(area_hbox)
	var area_label = Label.new()
	area_label.text = "Terrain:"
	area_label.custom_minimum_size.x = 80
	area_label.modulate = Color.WHITE
	area_hbox.add_child(area_label)
	var area_option = OptionButton.new()
	# Populate options sorted alphabetically
	var names: Array[String] = TerrainPresets.get_names()
	names.sort()
	for name in names:
		area_option.add_item(name)
	# Default select Grassland if present
	for i in range(area_option.get_item_count()):
		if area_option.get_item_text(i) == "Grassland":
			area_option.select(i)
			break
	area_option.item_selected.connect(func(index): _on_area_changed(area_option.get_item_text(index)))
	area_hbox.add_child(area_option)

	# Spacer
	var spacer1 = Control.new()
	spacer1.custom_minimum_size.y = 10
	overlay_panel.add_child(spacer1)

	# Button container
	var button_container = HBoxContainer.new()
	overlay_panel.add_child(button_container)

	# Back button
	back_button = Button.new()
	back_button.text = "🏠 Menu"
	back_button.custom_minimum_size = Vector2(80, 35)
	back_button.pressed.connect(_on_back_pressed)
	button_container.add_child(back_button)

	# Load button
	var load_button = Button.new()
	load_button.text = "Load"
	load_button.custom_minimum_size = Vector2(80, 35)
	load_button.pressed.connect(func(): _on_load_pressed())
	button_container.add_child(load_button)

	start_button = Button.new()
	start_button.text = "Start Evolution"
	start_button.custom_minimum_size = Vector2(180, 35)
	start_button.pressed.connect(_on_start_button_pressed)
	overlay_panel.add_child(start_button)

	# Save now button
	var save_button = Button.new()
	save_button.text = "Save Now"
	save_button.custom_minimum_size = Vector2(110, 28)
	save_button.pressed.connect(func(): if population_manager and population_manager.has_method("save_now"): population_manager.save_now())
	overlay_panel.add_child(save_button)

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

	wallet_label = Label.new()
	wallet_label.text = "Wallet: $0"
	wallet_label.add_theme_font_size_override("font_size", 12)
	wallet_label.modulate = Color.WHITE
	overlay_panel.add_child(wallet_label)

	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size.y = 20
	progress_bar.show_percentage = false
	overlay_panel.add_child(progress_bar)

	status_label = Label.new()
	status_label.text = "Ready to start"
	# Stats panel
	var spacer_stats = Control.new()
	spacer_stats.custom_minimum_size.y = 10
	overlay_panel.add_child(spacer_stats)
	var stats_title = Label.new()
	stats_title.text = "Generation Stats"
	stats_title.add_theme_font_size_override("font_size", 12)
	stats_title.modulate = Color.WHITE
	overlay_panel.add_child(stats_title)
	stats_panel = RichTextLabel.new()
	stats_panel.bbcode_enabled = true
	stats_panel.scroll_active = true
	stats_panel.scroll_following = true
	stats_panel.fit_content = true
	stats_panel.custom_minimum_size = Vector2(300, 160)
	stats_panel.add_theme_color_override("default_color", Color(0.9, 0.9, 0.9))
	overlay_panel.add_child(stats_panel)
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
	population_manager = PopulationManager.new()
	add_child(population_manager)

	# Connect signals
	population_manager.generation_completed.connect(_on_generation_completed)
	population_manager.generation_stats.connect(_on_generation_stats)
	population_manager.evolution_finished.connect(_on_evolution_finished)
	# Initialize terrain preset
	if population_manager.has_method("set_terrain_preset"):
		population_manager.set_terrain_preset("Grassland")

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

func _on_area_changed(name: String) -> void:
	if population_manager and population_manager.has_method("set_terrain_preset"):
		population_manager.set_terrain_preset(name)
		status_label.text = "Area set to %s" % name

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

	# Try to load previous state; if none, start fresh
	var loaded: bool = false
	if population_manager and population_manager.has_method("try_load_state"):
		loaded = population_manager.try_load_state()
	if loaded:
		status_label.text = "Loaded previous state; continuing evolution..."
		population_manager.is_running = true
		population_manager.run_evolution()
	else:
		# Start the evolution process
		population_manager.start_evolution()

func _on_load_pressed():
	if not population_manager or not population_manager.has_method("try_load_state"):
		return
	var ok: bool = population_manager.try_load_state()
	if ok:
		status_label.text = "State loaded."
		# Reflect wallet and maybe other UI
		if wallet_label:
			wallet_label.text = "Wallet: $%d" % population_manager.wallet
	else:
		status_label.text = "No saved state found."

func _on_back_pressed():
	if is_evolution_running:
		# Ask for confirmation to stop the evolution
		var dialog = ConfirmationDialog.new()
		dialog.dialog_text = "Are you sure you want to go back? The evolution will be stopped."
		dialog.popup_centered()
		dialog.confirmed.connect(_on_back_confirmed)
		add_child(dialog)
	else:
		# No evolution in progress, just go back
		_go_to_menu()

func _on_back_confirmed():
	# Stop the evolution
	is_evolution_running = false
	if population_manager:
		population_manager.stop_evolution()

	# Go back to the menu
	_go_to_menu()

func _go_to_menu():
	# Here you would typically change to the main menu scene
	# For now, we just print a message and reset the UI
	print("Going back to menu...")

	# Reset UI elements
	generation_label.text = "Generation: Not started"
	best_score_label.text = "Best Score: --"
	if wallet_label:
		wallet_label.text = "Wallet: $%d" % 0
	progress_bar.value = 0
	status_label.text = "Ready to start"
	status_label.modulate = Color.LIGHT_GRAY

	# Enable buttons
	start_button.disabled = false
	start_button.text = "Start Evolution"
	settings_panel.modulate = Color.WHITE

func _on_population_size_changed(value: float):
	if population_manager:
		population_manager.population_size = int(value)

func _on_generations_changed(value: float):
	pass # Deprecated: evolution runs indefinitely; progress bar loops visually

func _on_dna_length_changed(value: float):
	if population_manager:
		population_manager.dna_length = int(value)

func _on_generation_completed(generation: int, best_score: float):
	generation_label.text = "Generation: %d" % generation
	best_score_label.text = "Best Score: %.1f" % best_score
	if wallet_label:
		wallet_label.text = "Wallet: $%d" % population_manager.wallet
	# In infinite mode, loop progress bar visually
	progress_bar.max_value = 20
	progress_bar.value = generation % int(progress_bar.max_value)
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

func _on_generation_stats(generation: int, stats: Dictionary, breeding: Dictionary):
	if not stats_panel:
		return
	var lines: Array[String] = []
	lines.append("[b]Gen %d[/b]" % generation)
	if stats and stats.has("count"):
		lines.append("Count: %d  Min: %.1f  Q1: %.1f  Median: %.1f  Q3: %.1f  Max: %.1f  Mean: %.1f" % [
			int(stats.get("count", 0)),
			float(stats.get("min", 0.0)),
			float(stats.get("q1", 0.0)),
			float(stats.get("median", 0.0)),
			float(stats.get("q3", 0.0)),
			float(stats.get("max", 0.0)),
			float(stats.get("mean", 0.0))
		])
	if breeding and breeding.has("survivors"):
		lines.append("Survivors: %d  Children: %d  Retain: %.0f%%  Mut: %.0f%%" % [
			int(breeding.get("survivors", 0)),
			int(breeding.get("children", 0)),
			float(breeding.get("retain_ratio", 0.0)) * 100.0,
			float(breeding.get("mutation_rate", 0.0)) * 100.0
		])
	if breeding and breeding.has("pair_samples"):
		var pairs: Array = breeding.get("pair_samples", []) as Array
		var pair_strs: Array = []
		for p in pairs:
			pair_strs.append("(%s,%s)" % [str(p.get("p1", "-")), str(p.get("p2", "-"))])
		lines.append("Pairs: " + ", ".join(pair_strs))
	stats_panel.append_text("%s\n" % "\n".join(lines))
	stats_panel.scroll_to_line(stats_panel.get_line_count())

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
