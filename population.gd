extends Node2D

# Car Evolution Simulation - Population Manager
# Translated from Python vroomon codebase

signal generation_completed(generation: int, best_score: float)
signal evolution_finished(final_best_car)

const FRAME_CODES = ["R", "W"]  # R = Rectangle, W = Wheel
const POWERTRAIN_CODES = ["C", "D", "G"]  # C = Cylinder, D = DriveShaft, G = GearSet

var population_size: int = 20
var dna_length: int = 5
var generations: int = 10
var retain_ratio: float = 0.5
var mutation_rate: float = 0.1

var current_generation: int = 0
var population: Array = []
var simulation_scene: Node2D
var is_running: bool = false

class CarDNA:
	var frame: Array = []
	var powertrain: Array = []
	
	func _init(f: Array = [], p: Array = []):
		frame = f.duplicate()
		powertrain = p.duplicate()
	
	func to_dict() -> Dictionary:
		return {"frame": frame, "powertrain": powertrain}
	
	func from_dict(data: Dictionary):
		frame = data.get("frame", [])
		powertrain = data.get("powertrain", [])

class Car:
	var dna: CarDNA
	var score: float = 0.0
	
	const SEQUENCE_LENGTH = 3
	
	func _init(car_dna: CarDNA = null):
		if car_dna:
			dna = car_dna
		else:
			dna = CarDNA.new()
	
	func mutate() -> Car:
		var replace_p = 0.10
		var remove_p = 0.05
		var insert_p = 0.05
		
		var new_frame = dna.frame.duplicate()
		var new_powertrain = dna.powertrain.duplicate()
		var pairs = []
		
		for i in range(new_frame.size()):
			pairs.append([new_frame[i], new_powertrain[i]])
		
		var i = 0
		while i < pairs.size():
			var r = randf()
			if r < replace_p:
				pairs[i] = [FRAME_CODES.pick_random(), POWERTRAIN_CODES.pick_random()]
				i += 1
			elif r < replace_p + remove_p and pairs.size() > 1:
				pairs.remove_at(i)
			elif r < replace_p + remove_p + insert_p:
				pairs.insert(i, [FRAME_CODES.pick_random(), POWERTRAIN_CODES.pick_random()])
				i += 1
			else:
				i += 1
		
		var mutated_frame = []
		var mutated_powertrain = []
		for pair in pairs:
			mutated_frame.append(pair[0])
			mutated_powertrain.append(pair[1])
		
		var mutated_dna = CarDNA.new(mutated_frame, mutated_powertrain)
		return Car.new(mutated_dna)
	
	static func reproduce(car1: Car, car2: Car) -> Car:
		var mother = [car1, car2].pick_random()
		var other = car1 if mother == car2 else car2
		
		# Deep copy mother's DNA
		var child_frame = mother.dna.frame.duplicate()
		var child_powertrain = mother.dna.powertrain.duplicate()
		
		# Crossover with bounds checking to fix IndexError bug from Python version
		for idx in range(child_frame.size()):
			if randf() < 0.5:
				for j in range(Car.SEQUENCE_LENGTH):
					var target_idx = idx + j
					if target_idx < child_frame.size() and target_idx < other.dna.frame.size():
						child_frame[target_idx] = other.dna.frame[target_idx]
			
			if randf() < 0.5:
				for j in range(Car.SEQUENCE_LENGTH):
					var target_idx = idx + j
					if target_idx < child_powertrain.size() and target_idx < other.dna.powertrain.size():
						child_powertrain[target_idx] = other.dna.powertrain[target_idx]
		
		var child_dna = CarDNA.new(child_frame, child_powertrain)
		var child = Car.new(child_dna)
		return child.mutate()

func _ready():
	# Load the simulation scene
	setup_simulation()

func setup_simulation():
	var simulation_script = load("res://CarSimulation.gd")
	simulation_scene = Node2D.new()
	simulation_scene.set_script(simulation_script)
	add_child(simulation_scene)
	
	# Connect signals
	simulation_scene.simulation_completed.connect(_on_simulation_completed)

func start_evolution():
	if is_running:
		return
		
	is_running = true
	print("Car Evolution Simulation Starting...")
	
	# Generate initial population
	population = initialize_population(population_size, dna_length)
	print("Initial population created: ", population.size(), " cars")
	
	# Start evolution
	run_evolution()

func initialize_population(size: int, length: int) -> Array:
	var pop = []
	for i in range(size):
		var dna = generate_random_dna(length)
		var car = Car.new(dna)
		pop.append(car)
	return pop

func generate_random_dna(length: int) -> CarDNA:
	var frame = []
	var powertrain = []
	
	for i in range(length):
		frame.append(FRAME_CODES.pick_random())
		powertrain.append(POWERTRAIN_CODES.pick_random())
	
	return CarDNA.new(frame, powertrain)

func run_evolution():
	for gen in range(generations):
		current_generation = gen
		print("Generation ", gen + 1, "/", generations)
		
		# Score population using physics simulation
		await score_population_async(population)
		
		# Sort by score (descending)
		population.sort_custom(func(a, b): return a.score > b.score)
		
		var best_car = population[0]
		print("Best score: ", best_car.score)
		print("Best car DNA: Frame=", best_car.dna.frame, " Powertrain=", best_car.dna.powertrain)
		
		emit_signal("generation_completed", gen + 1, best_car.score)
		
		# Evolve population for next generation
		if gen < generations - 1:  # Don't evolve after final generation
			population = evolve_population(population)
	
	# Final results
	var final_best = population[0]
	print("Evolution complete! Final best score: ", final_best.score)
	print("Final best DNA: Frame=", final_best.dna.frame, " Powertrain=", final_best.dna.powertrain)
	
	is_running = false
	emit_signal("evolution_finished", final_best)

var current_scoring_index: int = 0
var scoring_population: Array = []

func score_population_async(pop: Array):
	print("Racing ", pop.size(), " cars simultaneously...")
	
	# Prepare all car DNA data for the race
	var car_dna_dicts = []
	for car in pop:
		car_dna_dicts.append(car.dna.to_dict())
	
	# Run the race with all cars at once
	var race_results = await simulation_scene.simulate_population(car_dna_dicts)
	
	# Assign scores back to the cars
	for i in range(pop.size()):
		if i < race_results.size():
			pop[i].score = race_results[i].score
			print("  Car ", i + 1, " score: ", race_results[i].score)
		else:
			pop[i].score = 0.0

func _on_simulation_completed(car_data: Dictionary, score: float):
	# This is called by the simulation scene when a car test completes
	# The scoring is handled in score_population_async
	pass

func evolve_population(scored_pop: Array) -> Array:
	var retain_count = max(2, int(scored_pop.size() * retain_ratio))
	var survivors = []
	
	# Keep top performers
	for i in range(retain_count):
		survivors.append(scored_pop[i])
	
	print("  Survivors: ", survivors.size(), " cars")
	
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
		
		var child = Car.reproduce(parent1, parent2)
		if randf() < mutation_rate:
			child = child.mutate()
		children.append(child)
	
	print("  Children: ", children.size(), " cars")
	return survivors + children
