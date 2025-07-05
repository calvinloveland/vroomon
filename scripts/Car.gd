class_name Car
extends RefCounted

# Individual car representation with DNA and genetic operations
# Handles mutation and reproduction for the genetic algorithm

var dna: CarDNA
var score: float = 0.0

func _init(car_dna: CarDNA = null):
	if car_dna:
		dna = car_dna
	else:
		dna = CarDNA.new()

func mutate() -> Car:
	"""Mutate the car's DNA string using various string operations"""
	var mutated_string = dna.get_dna_string()
	var replace_p = 0.15
	var remove_p = 0.05
	var insert_p = 0.10
	
	# Convert to character array for easier manipulation
	var chars = []
	for i in range(mutated_string.length()):
		chars.append(mutated_string[i])
	
	var i = 0
	while i < chars.size():
		var r = randf()
		if r < replace_p:
			# Replace character with random alphanumeric
			chars[i] = _get_random_char()
			i += 1
		elif r < replace_p + remove_p and chars.size() > 3:
			# Remove character (but keep minimum length)
			chars.remove_at(i)
		elif r < replace_p + remove_p + insert_p:
			# Insert random character
			chars.insert(i, _get_random_char())
			i += 1
		else:
			i += 1
	
	# Convert back to string
	var new_dna_string = ""
	for character in chars:
		new_dna_string += character
	
	var mutated_dna = CarDNA.new(new_dna_string)
	return Car.new(mutated_dna)

func _get_random_char() -> String:
	"""Get a random alphanumeric character"""
	var chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
	return chars[randi() % chars.length()]

static func reproduce(car1: Car, car2: Car) -> Car:
	"""Reproduce two cars by combining their DNA strings"""
	var dna1 = car1.dna.get_dna_string()
	var dna2 = car2.dna.get_dna_string()
	
	# Simple string crossover - take sections from each parent
	var child_dna = ""
	var max_length = max(dna1.length(), dna2.length())
	
	for i in range(max_length):
		if randf() < 0.5:
			# Take from parent 1
			if i < dna1.length():
				child_dna += dna1[i]
		else:
			# Take from parent 2
			if i < dna2.length():
				child_dna += dna2[i]
	
	# Alternative crossover method: take chunks
	if randf() < 0.3:  # 30% chance to use chunk crossover
		child_dna = _chunk_crossover(dna1, dna2)
	
	var child_car_dna = CarDNA.new(child_dna)
	var child = Car.new(child_car_dna)
	return child.mutate()

static func _chunk_crossover(dna1: String, dna2: String) -> String:
	"""Perform chunk-based crossover between two DNA strings"""
	var result = ""
	var pos = 0
	
	while pos < max(dna1.length(), dna2.length()):
		var chunk_size = randi_range(1, 4)
		var use_first = randf() < 0.5
		
		for i in range(chunk_size):
			if pos + i >= max(dna1.length(), dna2.length()):
				break
			
			if use_first and pos + i < dna1.length():
				result += dna1[pos + i]
			elif not use_first and pos + i < dna2.length():
				result += dna2[pos + i]
			elif pos + i < dna1.length():
				result += dna1[pos + i]
			elif pos + i < dna2.length():
				result += dna2[pos + i]
		
		pos += chunk_size
	
	return result

func get_translated_dna() -> Dictionary:
	"""Get the translated frame and powertrain from the DNA string"""
	return dna.translate_to_frame_and_powertrain()

func get_dna_string() -> String:
	"""Get the raw DNA string"""
	return dna.get_dna_string()