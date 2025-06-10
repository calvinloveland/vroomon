class_name Car
extends RefCounted

# Individual car representation with DNA and genetic operations
# Handles mutation and reproduction for the genetic algorithm

const FRAME_CODES = ["R", "W"]  # R = Rectangle, W = Wheel
const POWERTRAIN_CODES = ["C", "D", "G"]  # C = Cylinder, D = DriveShaft, G = GearSet
const SEQUENCE_LENGTH = 3

var dna: CarDNA
var score: float = 0.0

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
			for j in range(SEQUENCE_LENGTH):
				var target_idx = idx + j
				if target_idx < child_frame.size() and target_idx < other.dna.frame.size():
					child_frame[target_idx] = other.dna.frame[target_idx]
		
		if randf() < 0.5:
			for j in range(SEQUENCE_LENGTH):
				var target_idx = idx + j
				if target_idx < child_powertrain.size() and target_idx < other.dna.powertrain.size():
					child_powertrain[target_idx] = other.dna.powertrain[target_idx]
	
	var child_dna = CarDNA.new(child_frame, child_powertrain)
	var child = Car.new(child_dna)
	return child.mutate()