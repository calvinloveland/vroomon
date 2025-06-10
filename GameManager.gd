class_name GameManager
extends Node

# Game Manager - Handles scene transitions and main menu navigation
# Central controller for switching between different game modes

var current_scene: Node
var main_menu_scene: PackedScene
var evolution_scene: PackedScene
var test_drive_scene: PackedScene

func _ready():
	# Load scene resources
	main_menu_scene = preload("res://MainMenu.tscn")
	evolution_scene = preload("res://Main.tscn")
	test_drive_scene = preload("res://TestDrive.tscn")
	
	# Start with main menu - defer to avoid "busy setting up children" error
	call_deferred("switch_to_main_menu")

func switch_to_main_menu():
	print("Switching to Main Menu")
	_change_scene(main_menu_scene)
	
	# Connect menu signals after scene is loaded
	await get_tree().process_frame
	if current_scene and current_scene.has_signal("mode_selected"):
		current_scene.mode_selected.connect(_on_mode_selected)

func switch_to_evolution():
	print("Switching to Evolution Mode")
	_change_scene(evolution_scene)

func switch_to_test_drive():
	print("Switching to Test Drive Mode")
	_change_scene(test_drive_scene)

func switch_to_overworld():
	print("Overworld mode not implemented yet")
	# TODO: Implement overworld scene

func _change_scene(scene_resource: PackedScene):
	# Remove current scene
	if current_scene:
		current_scene.queue_free()
		await current_scene.tree_exited
	
	# Load new scene - use call_deferred to avoid tree setup conflicts
	current_scene = scene_resource.instantiate()
	call_deferred("_add_scene_to_tree", current_scene)

func _add_scene_to_tree(scene: Node):
	get_tree().root.add_child(scene)

func _on_mode_selected(mode: String):
	match mode:
		"evolution":
			switch_to_evolution()
		"test":
			switch_to_test_drive()
		"overworld":
			switch_to_overworld()
		_:
			print("Unknown mode: ", mode)