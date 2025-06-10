class_name CarDNA
extends RefCounted

# Car DNA representation for genetic algorithm
# Contains frame and powertrain genetic information

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

func duplicate_dna() -> CarDNA:
	return CarDNA.new(frame.duplicate(), powertrain.duplicate())