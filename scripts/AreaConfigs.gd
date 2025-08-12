class_name AreaConfigs
extends RefCounted

static func get_presets() -> Dictionary:
	return {
		"Grassland": {
			"name": "Grassland",
			"friction": 1.0,
			"ground_length": 5000.0,
			"obstacle_count": 5,
			"obstacle_height_base": 50.0,
			"obstacle_height_step": 10.0,
			"ground_color": Color(0.35, 0.65, 0.35)
		},
		"Sand": {
			"name": "Sand",
			"friction": 1.5,
			"ground_length": 4600.0,
			"obstacle_count": 4,
			"obstacle_height_base": 30.0,
			"obstacle_height_step": 8.0,
			"ground_color": Color(0.80, 0.70, 0.45)
		},
		"Hills": {
			"name": "Hills",
			"friction": 0.9,
			"ground_length": 5600.0,
			"obstacle_count": 7,
			"obstacle_height_base": 60.0,
			"obstacle_height_step": 20.0,
			"ground_color": Color(0.25, 0.55, 0.30)
		}
	}

static func get_preset(name: String) -> Dictionary:
	var presets = get_presets()
	if presets.has(name):
		return presets[name]
	return presets["Grassland"]
