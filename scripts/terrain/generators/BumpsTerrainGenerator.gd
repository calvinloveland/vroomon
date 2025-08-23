class_name BumpsTerrainGenerator
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

	# Base ground
	var base_shape := RectangleShape2D.new()
	base_shape.size = Vector2(profile.ground_length, 100)
	var base_collision := CollisionShape2D.new()
	base_collision.shape = base_shape
	base_collision.position = Vector2(0, profile.ground_height)
	ground.add_child(base_collision)

	# Bumps
	var count: int = max(0, profile.obstacle_count)
	var base_h: float = float(profile.obstacle_params.get("height_base", 50.0))
	var step_h: float = float(profile.obstacle_params.get("height_step", 10.0))
	var width: float = float(profile.obstacle_params.get("width", 100.0))
	var spacing: float = profile.ground_length / float(max(1, count + 1))

	for i in range(count):
		var x_pos: float = -profile.ground_length/2.0 + spacing * float(i + 1)
		var h: float = base_h + float(i) * step_h
		var shape: RectangleShape2D = RectangleShape2D.new()
		shape.size = Vector2(width, h)
		var coll: CollisionShape2D = CollisionShape2D.new()
		coll.shape = shape
		coll.position = Vector2(x_pos, profile.ground_height - (h/2.0 + 50.0))
		ground.add_child(coll)

		var vis: ColorRect = ColorRect.new()
		vis.size = shape.size
		vis.position = Vector2(x_pos - width/2.0, profile.ground_height - h - 50.0)
		vis.color = profile.color_obstacle
		vis.add_to_group("terrain")
		root.add_child(vis)

	root.add_child(ground)

	# Visual ground bar
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
