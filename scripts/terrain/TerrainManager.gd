class_name TerrainManager
extends Node

var profile: TerrainProfile
var generator: TerrainGeneratorBase
var handle: Dictionary = {}

func set_profile(p: TerrainProfile) -> void:
	profile = p

func set_generator(g: TerrainGeneratorBase) -> void:
	generator = g

func rebuild(parent: Node2D) -> void:
	clear()
	if generator and profile:
		handle = generator.generate(parent, profile)

func clear() -> void:
	if generator and handle:
		generator.clear(handle)
		handle = {}

func get_ground() -> StaticBody2D:
	return handle.get("ground", null)

func get_start_position() -> Vector2:
	return handle.get("start_position", Vector2.ZERO)
