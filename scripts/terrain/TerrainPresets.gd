class_name TerrainPresets
extends Object

static func get_names() -> Array[String]:
	return ["Grassland", "Flat"]

static func get_profile(name: String) -> TerrainProfile:
	var p := TerrainProfile.new()
	match name:
		"Grassland":
			p.name = name
			p.friction = 1.0
			p.ground_length = 5000.0
			p.ground_height = 400.0
			p.color_ground = Color(0.40, 0.26, 0.13)
			p.color_obstacle = Color.DARK_GRAY
			p.obstacle_count = 5
			p.obstacle_params = {"height_base": 50.0, "height_step": 10.0, "width": 100.0}
		"Flat":
			p.name = name
			p.friction = 1.0
			p.ground_length = 5000.0
			p.ground_height = 400.0
			p.obstacle_count = 0
		_:
			p.name = name
	return p

static func get_generator(name: String) -> TerrainGeneratorBase:
	match name:
		"Grassland":
			return BumpsTerrainGenerator.new()
		"Flat":
			return FlatTerrainGenerator.new()
		_:
			return FlatTerrainGenerator.new()
