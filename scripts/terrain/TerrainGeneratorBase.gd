class_name TerrainGeneratorBase
extends Resource

func generate(_parent: Node2D, _profile: TerrainProfile) -> Dictionary:
	push_error("TerrainGeneratorBase.generate not implemented")
	return {}

func clear(handle: Dictionary) -> void:
	if handle.has("root") and is_instance_valid(handle.root):
		handle.root.queue_free()
