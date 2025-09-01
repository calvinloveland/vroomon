class_name SaveManager
extends RefCounted

# Simple save/load manager for evolution state between runs

static func _save_path() -> String:
	return "user://save_state.json"

static func save_population_state(pm: PopulationManager) -> void:
	# Expect a PopulationManager-like object
	if pm == null:
		return
	var data := {
		"version": 1,
		"timestamp": Time.get_unix_time_from_system(),
		"run_id": pm._run_id,
		"terrain_name": pm.terrain_name,
		"current_generation": pm.current_generation,
		"wallet": pm.wallet,
		"params": {
			"population_size": pm.population_size,
			"dna_length": pm.dna_length,
			"retain_ratio": pm.retain_ratio,
			"mutation_rate": pm.mutation_rate
		},
		"population": []
	}
	var pop_arr: Array = pm.population
	for car in pop_arr:
		var entry := {
			"id": car.id,
			"parents": car.parents,
			"mutated": car.mutated_from_parents,
			"dna": car.dna.to_dict() if car and car.dna else {},
			"dna_string": car.get_dna_string(),
			"score": car.score
		}
		data["population"].append(entry)

	var path := _save_path()
	var dir := path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("SaveManager: Failed to open save file for write: " + path)
		return
	f.store_string(JSON.stringify(data))
	f.flush()
	f.close()
	print("SaveManager: Saved state to ", path)

static func load_population_state() -> Dictionary:
	var path := _save_path()
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("SaveManager: Failed to open save file for read: " + path)
		return {}
	var text := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("SaveManager: Invalid save file format")
		return {}
	return parsed

static func apply_population_state(pm: PopulationManager, state: Dictionary) -> bool:
	if not state:
		return false
	# Basic fields
	if state.has("terrain_name"):
		pm.terrain_name = String(state["terrain_name"])
		if pm.simulation_scene and pm.simulation_scene.has_method("set_terrain_preset"):
			pm.simulation_scene.set_terrain_preset(pm.terrain_name)
	if state.has("current_generation"):
		pm.current_generation = int(state["current_generation"])
	if state.has("wallet"):
		pm.wallet = int(state["wallet"])
	if state.has("params"):
		var p: Dictionary = state["params"]
		pm.population_size = int(p.get("population_size", pm.population_size))
		pm.dna_length = int(p.get("dna_length", pm.dna_length))
		pm.retain_ratio = float(p.get("retain_ratio", pm.retain_ratio))
		pm.mutation_rate = float(p.get("mutation_rate", pm.mutation_rate))
	# Run id
	if state.has("run_id"):
		pm._run_id = String(state["run_id"])
	# Rebuild population
	var new_pop: Array = []
	var max_seq: int = 0
	if state.has("population"):
		for entry in state["population"]:
			var dna_dict: Dictionary = entry.get("dna", {})
			var car := Car.new(CarDNA.new())
			car.dna.from_dict(dna_dict)
			var id_str: String = String(entry.get("id", ""))
			var parents_any: Array = entry.get("parents", [])
			var parents: Array[String] = []
			for p in parents_any:
				parents.append(String(p))
			var mutated: bool = bool(entry.get("mutated", false))
			car.set_lineage(id_str, parents, mutated)
			car.score = float(entry.get("score", 0.0))
			new_pop.append(car)
			# Update counter from id suffix if matches pattern RUN-00001
			if id_str.find("-") != -1:
				var parts: PackedStringArray = id_str.rsplit("-", true, 1)
				if parts.size() == 2:
					var seq := int(parts[1])
					if seq > max_seq:
						max_seq = seq
	pm.population = new_pop
	pm._id_counter = max_seq
	return not new_pop.is_empty()
