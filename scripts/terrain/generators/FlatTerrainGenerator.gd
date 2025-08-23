class_name FlatTerrainGenerator
extends TerrainGeneratorBase

func generate(parent: Node2D, profile: TerrainProfile) -> Dictionary:
	var root := Node2D.new()
	root.name = "TerrainRoot"
	root.add_to_group("terrain")
	parent.add_child(root)

	var ground := StaticBody2D.new()
	ground.collision_layer = 1
	ground.collision_mask = 0

	var mat := PhysicsMaterial.new()
	mat.friction = clampf(profile.friction, 0.2, 2.0)
	ground.physics_material_override = mat

	var ground_shape := RectangleShape2D.new()
	ground_shape.size = Vector2(profile.ground_length, 100)

	var ground_collision := CollisionShape2D.new()
	ground_collision.shape = ground_shape
	ground_collision.position = Vector2(0, profile.ground_height)

	ground.add_child(ground_collision)
	root.add_child(ground)

	var ground_visual := ColorRect.new()
	ground_visual.size = Vector2(profile.ground_length, 100)
	ground_visual.position = Vector2(-profile.ground_length/2.0, profile.ground_height - 50)
	ground_visual.color = profile.color_ground
	ground_visual.add_to_group("terrain")
	root.add_child(ground_visual)

	return {
		"root": root,
		"ground": ground,
		"start_position": Vector2(0, profile.ground_height - 150),
		"bounds": Rect2(Vector2(-profile.ground_length/2.0, profile.ground_height - 100), Vector2(profile.ground_length, 100))
	}
