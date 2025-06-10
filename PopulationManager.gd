class_name PopulationManager
extends Node2D

# Population Manager for genetic algorithm
# Handles evolution, selection, and population management

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

func _on_simulation_completed(_car_data: Dictionary, _score: float):
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

func stop_evolution():
	# Stop the current evolution process
	is_running = false
	print("Evolution stopped by user")