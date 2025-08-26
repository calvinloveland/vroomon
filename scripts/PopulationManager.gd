class_name PopulationManager
extends Node2D

# Population Manager for genetic algorithm
# Handles evolution, selection, and population management

signal generation_completed(generation: int, best_score: float)
signal generation_stats(generation: int, stats: Dictionary, breeding: Dictionary)
signal evolution_finished(final_best_car)

var population_size: int = 100
var dna_length: int = 12  # Target length for DNA strings
var generations: int = 10  # Ignored in infinite mode; kept for UI compatibility
var retain_ratio: float = 0.5
var mutation_rate: float = 0.1

var current_generation: int = 0
var population: Array = []
var simulation_scene: Node2D
var is_running: bool = false

# Logging and lineage tracking
var _run_id: String = ""
var _log_dir: String = ""
var _log_path: String = ""
var _id_counter: int = 0
var _last_results: Array = []

const SaveManager = preload("res://scripts/SaveManager.gd")

# Simple economy
var wallet: int = 0
var terrain_name: String = "Grassland"

func _ready():
	# Load the simulation scene
	setup_simulation()

func setup_simulation():
	var simulation_script = load("res://scripts/CarSimulation.gd")
	simulation_scene = Node2D.new()
	simulation_scene.set_script(simulation_script)
	add_child(simulation_scene)

	# Connect signals
	simulation_scene.simulation_completed.connect(_on_simulation_completed)

	# Set default terrain preset
	if simulation_scene.has_method("set_terrain_preset"):
		simulation_scene.set_terrain_preset(terrain_name)

func set_terrain_preset(name: String) -> void:
	terrain_name = name
	if simulation_scene and simulation_scene.has_method("set_terrain_preset"):
		simulation_scene.set_terrain_preset(terrain_name)

func start_evolution():
	if is_running:
		return

	is_running = true
	print("Car Evolution Simulation Starting...")
	print("Using new alphanumeric DNA string format")

	# Initialize run logging
	var dt := Time.get_datetime_dict_from_system()
	_run_id = "%04d%02d%02d_%02d%02d%02d" % [int(dt["year"]), int(dt["month"]), int(dt["day"]), int(dt["hour"]), int(dt["minute"]), int(dt["second"])]
	_log_dir = "user://evolution_logs"
	DirAccess.make_dir_recursive_absolute(_log_dir)
	_log_path = _log_dir + "/run_" + _run_id + ".jsonl"

	# Generate initial population
	population = initialize_population(population_size, dna_length)
	print("Initial population created: ", population.size(), " cars")

	# Start evolution (infinite until stopped)
	run_evolution()

func initialize_population(size: int, target_length: int) -> Array:
	var pop = []
	for i in range(size):
		var dna = generate_random_dna(target_length)
		var car = Car.new(dna)
		# assign lineage id
		car.set_lineage(_next_id(), [])
		pop.append(car)
	return pop

func generate_random_dna(target_length: int) -> CarDNA:
	"""Generate a random DNA string of the target length"""
	var chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
	var dna_string = ""

	var actual_length = randi_range(max(3, target_length - 4), target_length + 4)

	for i in range(actual_length):
		dna_string += chars[randi() % chars.length()]

	return CarDNA.new(dna_string)

func run_evolution():
	var gen: int = 0
	while is_running:
		current_generation = gen
		print("Generation ", gen + 1, " (infinite)")

		# Score population using physics simulation
		await score_population_async(population)
		# Persist JSONL logs for this generation
		_log_generation(gen, population, _last_results)

		# Sort by score (descending)
		population.sort_custom(func(a, b): return a.score > b.score)

		var best_car = population[0]
		print("Best score: ", best_car.score)
		print("Best car DNA: '", best_car.get_dna_string(), "'")

		# Compute stats across the whole generation
		var scores: Array = []
		for c in population:
			scores.append(c.score)
		var stats := _compute_score_stats(scores)

		emit_signal("generation_completed", gen + 1, best_car.score)
		emit_signal("generation_stats", gen + 1, stats, _last_breeding_stats)

		# Auto-save state each generation
		SaveManager.save_population_state(self)

		# Economy update (simple): earn based on best score
		wallet += int(max(0.0, best_car.score) / 50.0)

		# Evolve population for next generation
		var evo := evolve_population(population)
		population = evo.population
		_last_breeding_stats = evo.breeding

		gen += 1

	# When stopped externally
	if not population.is_empty():
		var final_best = population[0]
		emit_signal("evolution_finished", final_best)

func _compute_score_stats(scores: Array) -> Dictionary:
	var result := {}
	if scores.is_empty():
		return result
	var sorted := scores.duplicate()
	sorted.sort()  # ascending
	var n: int = sorted.size()
	var sum_val: float = 0.0
	for s in sorted:
		sum_val += float(s)
	var mean: float = sum_val / float(n)
	var median: float = (float(sorted[n/2]) + float(sorted[(n-1)/2])) / 2.0
	var q1: float = float(sorted[int(floor((n - 1) * 0.25))])
	var q3: float = float(sorted[int(floor((n - 1) * 0.75))])
	result["count"] = n
	result["mean"] = mean
	result["median"] = median
	result["q1"] = q1
	result["q3"] = q3
	result["min"] = float(sorted[0])
	result["max"] = float(sorted[n - 1])
	return result

func score_population_async(pop: Array):
	print("Racing ", pop.size(), " cars simultaneously...")

	# Prepare all car DNA data for the race
	var car_dna_dicts = []
	for car in pop:
		car_dna_dicts.append(car.dna.to_dict())

	# Run the race with all cars at once
	var race_results = await simulation_scene.simulate_population(car_dna_dicts)
	_last_results = race_results

	# Assign scores back to the cars
	# Results come sorted by score with 'car_index' back-reference; build mapping
	var index_to_score: Dictionary = {}
	for r in race_results:
		index_to_score[int(r.car_index)] = float(r.score)
	for i in range(pop.size()):
		var s: float = float(index_to_score.get(i, 0.0))
		pop[i].score = s
		print("  Car ", i + 1, " ('", pop[i].get_dna_string(), "') score: ", s)

func _on_simulation_completed(_results: Array) -> void:
	# CarSimulation emits an Array of results at the end of a full race.
	# We await simulate_population() elsewhere, so nothing to do here.
	pass

var _last_breeding_stats: Dictionary = {}

func evolve_population(scored_pop: Array) -> Dictionary:
	var retain_count = max(2, int(scored_pop.size() * retain_ratio))
	var survivors = []
	var parent_usage: Dictionary = {}
	var pair_samples: Array = []

	# Keep top performers
	for i in range(retain_count):
		survivors.append(scored_pop[i])
		parent_usage[i] = 0

	print("  Survivors: ", survivors.size(), " cars")
	print("  Top survivor DNA: '", survivors[0].get_dna_string(), "'")

	# Generate children through reproduction
	var children = []
	while survivors.size() + children.size() < population_size:
		var parent1 = survivors.pick_random()
		var parent2 = survivors.pick_random()

		# Ensure parents are different
		var attempts = 0
		while parent1 == parent2 and attempts < 10:
			parent2 = survivors.pick_random()
			attempts += 1

		# Track usage counts by survivor indices
		var p1_idx: int = survivors.find(parent1)
		var p2_idx: int = survivors.find(parent2)
		if p1_idx >= 0:
			parent_usage[p1_idx] = int(parent_usage.get(p1_idx, 0)) + 1
		if p2_idx >= 0:
			parent_usage[p2_idx] = int(parent_usage.get(p2_idx, 0)) + 1
		if pair_samples.size() < 8:
			pair_samples.append({"p1": p1_idx, "p2": p2_idx})

		var child = Car.reproduce(parent1, parent2)
		if randf() < mutation_rate:
			child = child.mutate()
		# assign lineage id and parents
		var pids: Array[String] = [parent1.id, parent2.id]
		child.set_lineage(_next_id(), pids, true)
		children.append(child)

	print("  Children: ", children.size(), " cars")
	var breeding := {
		"retain_ratio": retain_ratio,
		"mutation_rate": mutation_rate,
		"survivors": survivors.size(),
		"children": children.size(),
		"parent_usage": parent_usage,
		"pair_samples": pair_samples
	}
	return {"population": survivors + children, "breeding": breeding}

func _next_id() -> String:
	_id_counter += 1
	return "%s-%05d" % [_run_id, _id_counter]

func _log_generation(gen: int, pop: Array, results: Array) -> void:
	# Append JSON per car: { run_id, gen, id, parents, dna, score, meta }
	var fh := FileAccess.open(_log_path, FileAccess.READ_WRITE)
	if fh == null:
		# Try create if not exist
		fh = FileAccess.open(_log_path, FileAccess.WRITE)
	if fh == null:
		push_error("Failed to open log file: " + _log_path)
		return
	# Move to end for append
	fh.seek_end()
	for i in range(pop.size()):
		var car: Car = pop[i]
		var entry := {
			"run_id": _run_id,
			"generation": gen + 1,
			"index": i,
			"id": car.id,
			"parents": car.parents,
			"mutated": car.mutated_from_parents,
			"dna": car.dna.to_dict(),
			"dna_string": car.get_dna_string(),
			"score": car.score,
			"terrain": terrain_name
		}
		fh.store_line(JSON.stringify(entry))
	fh.flush()
	fh.close()

func stop_evolution():
	# Stop the current evolution process
	is_running = false
	print("Evolution stopped by user")
	# Save on stop
	SaveManager.save_population_state(self)

func save_now():
	SaveManager.save_population_state(self)

func try_load_state() -> bool:
	var state := SaveManager.load_population_state()
	if not state:
		return false
	var ok := SaveManager.apply_population_state(self, state)
	return ok
