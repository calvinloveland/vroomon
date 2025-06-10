class_name MainMenu
extends Control

# Main Menu for Car Evolution Simulation
# Provides navigation to different game modes

signal mode_selected(mode: String)

@onready var title_label: Label
@onready var evolution_button: Button
@onready var test_button: Button
@onready var overworld_button: Button
@onready var quit_button: Button

func _ready():
	setup_ui()
	connect_signals()

func setup_ui():
	# Set full screen
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Create main container
	var main_container = VBoxContainer.new()
	main_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	main_container.custom_minimum_size = Vector2(400, 500)
	add_child(main_container)
	
	# Add spacing at top
	var top_spacer = Control.new()
	top_spacer.custom_minimum_size.y = 100
	main_container.add_child(top_spacer)
	
	# Title
	title_label = Label.new()
	title_label.text = "Car Evolution Simulator"
	title_label.add_theme_font_size_override("font_size", 36)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.modulate = Color.WHITE
	main_container.add_child(title_label)
	
	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "Genetic Algorithm Vehicle Evolution"
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.modulate = Color.LIGHT_GRAY
	main_container.add_child(subtitle)
	
	# Add spacing
	var spacer1 = Control.new()
	spacer1.custom_minimum_size.y = 60
	main_container.add_child(spacer1)
	
	# Menu buttons container
	var button_container = VBoxContainer.new()
	button_container.custom_minimum_size.x = 300
	main_container.add_child(button_container)
	
	# Evolution Mode Button
	evolution_button = Button.new()
	evolution_button.text = "🧬 Evolution Mode"
	evolution_button.custom_minimum_size = Vector2(300, 60)
	evolution_button.add_theme_font_size_override("font_size", 18)
	button_container.add_child(evolution_button)
	
	# Add button spacing
	var btn_spacer1 = Control.new()
	btn_spacer1.custom_minimum_size.y = 20
	button_container.add_child(btn_spacer1)
	
	# Test Mode Button
	test_button = Button.new()
	test_button.text = "🚗 Test Drive"
	test_button.custom_minimum_size = Vector2(300, 60)
	test_button.add_theme_font_size_override("font_size", 18)
	button_container.add_child(test_button)
	
	# Add button spacing
	var btn_spacer2 = Control.new()
	btn_spacer2.custom_minimum_size.y = 20
	button_container.add_child(btn_spacer2)
	
	# Overworld Mode Button
	overworld_button = Button.new()
	overworld_button.text = "🌍 Overworld (Coming Soon)"
	overworld_button.custom_minimum_size = Vector2(300, 60)
	overworld_button.add_theme_font_size_override("font_size", 18)
	overworld_button.disabled = true
	overworld_button.modulate = Color.GRAY
	button_container.add_child(overworld_button)
	
	# Add button spacing
	var btn_spacer3 = Control.new()
	btn_spacer3.custom_minimum_size.y = 40
	button_container.add_child(btn_spacer3)
	
	# Quit Button
	quit_button = Button.new()
	quit_button.text = "❌ Quit"
	quit_button.custom_minimum_size = Vector2(300, 50)
	quit_button.add_theme_font_size_override("font_size", 16)
	quit_button.modulate = Color.LIGHT_CORAL
	button_container.add_child(quit_button)
	
	# Add background color
	var background = ColorRect.new()
	background.color = Color(0.1, 0.1, 0.2, 1.0)  # Dark blue background
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	# Move background to back by moving it to index 0
	move_child(background, 0)

func connect_signals():
	evolution_button.pressed.connect(_on_evolution_pressed)
	test_button.pressed.connect(_on_test_pressed)
	overworld_button.pressed.connect(_on_overworld_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_evolution_pressed():
	print("Starting Evolution Mode...")
	emit_signal("mode_selected", "evolution")

func _on_test_pressed():
	print("Starting Test Drive Mode...")
	emit_signal("mode_selected", "test")

func _on_overworld_pressed():
	print("Starting Overworld Mode...")
	emit_signal("mode_selected", "overworld")

func _on_quit_pressed():
	print("Quitting application...")
	get_tree().quit()

func _input(event):
	if event.is_action_pressed("ui_cancel"):  # Escape key
		get_tree().quit()