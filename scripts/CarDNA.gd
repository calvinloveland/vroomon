class_name CarDNA
extends RefCounted

# Car DNA representation for genetic algorithm
# DNA is now a single alphanumeric string that gets translated into car components

var dna_string: String = ""

func _init(dna: String = ""):
	if dna.length() == 0:
		# Generate random DNA if none provided
		dna_string = _generate_random_dna()
	else:
		dna_string = _validate_and_clean_dna(dna)

func _generate_random_dna(length: int = -1) -> String:
	"""Generate a random alphanumeric DNA string"""
	var target_length = length if length > 0 else randi_range(8, 20)
	var chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
	var result = ""

	for i in range(target_length):
		result += chars[randi() % chars.length()]

	return result

func _validate_and_clean_dna(dna: String) -> String:
	"""Ensure DNA contains only alphanumeric characters"""
	var cleaned = ""
	for i in range(dna.length()):
		var character = dna[i]
		if character.is_valid_identifier() or character.is_valid_int():
			cleaned += character

	# Ensure minimum length
	if cleaned.length() < 3:
		cleaned += _generate_random_dna(3 - cleaned.length())

	return cleaned

func to_dict() -> Dictionary:
	return {"dna_string": dna_string}

func from_dict(data: Dictionary):
	dna_string = data.get("dna_string", _generate_random_dna())

func duplicate_dna() -> CarDNA:
	return CarDNA.new(dna_string)

func get_dna_string() -> String:
	return dna_string

func set_dna_string(new_dna: String):
	dna_string = _validate_and_clean_dna(new_dna)

# Translation functions to convert DNA string into car components
func translate_to_frame_and_powertrain() -> Dictionary:
	"""Convert the DNA string into frame and powertrain sequences"""
	var frame_parts = []
	var powertrain_parts = []

	# Use DNA string to determine car structure
	var car_length = max(3, min(12, (dna_string.length() % 10) + 3))

	for i in range(car_length):
		# Use different parts of DNA string for frame and powertrain
		var frame_char = dna_string[i % dna_string.length()]
		var powertrain_char = dna_string[(i + int(dna_string.length() / 2.0)) % dna_string.length()]

		# Translate frame character to part type
		var frame_part = _char_to_frame_part(frame_char)
		frame_parts.append(frame_part)

		# Translate powertrain character to part type
		var powertrain_part = _char_to_powertrain_part(powertrain_char)
		powertrain_parts.append(powertrain_part)

	return {"frame": frame_parts, "powertrain": powertrain_parts}

func _char_to_frame_part(character: String) -> String:
	"""Convert a single character to a frame part type"""
	var ascii_val = character.unicode_at(0)

	# Simple mapping based on character value
	if ascii_val % 2 == 0:
		return "R"  # Rectangle chassis
	else:
		return "W"  # Wheel

func _char_to_powertrain_part(character: String) -> String:
	"""Convert a single character to a powertrain part type"""
	var ascii_val = character.unicode_at(0)

	# Map to three powertrain types
	match ascii_val % 3:
		0:
			return "C"  # Cylinder
		1:
			return "D"  # DriveShaft
		_:
			return "G"  # GearSet

# Advanced translation functions for numeric parameters
func get_wheel_size(wheel_position: int) -> float:
	"""Get wheel size based on DNA and position"""
	var char_index = (wheel_position * 2 + 1) % dna_string.length()
	var character = dna_string[char_index]
	var ascii_val = character.unicode_at(0)
	return 15.0 + (ascii_val % 20)  # Wheel size between 15-35

func get_power_factor(wheel_position: int) -> float:
	"""Get power multiplier based on DNA and position"""
	var char_index = (wheel_position * 3 + 2) % dna_string.length()
	var character = dna_string[char_index]
	var ascii_val = character.unicode_at(0)
	return 0.5 + (ascii_val % 100) / 100.0  # Power factor between 0.5-1.5

func get_efficiency_factor(wheel_position: int) -> float:
	"""Get efficiency factor based on DNA and position"""
	var char_index = (wheel_position * 4 + 3) % dna_string.length()
	var character = dna_string[char_index]
	var ascii_val = character.unicode_at(0)
	return 0.7 + (ascii_val % 30) / 100.0  # Efficiency between 0.7-1.0
