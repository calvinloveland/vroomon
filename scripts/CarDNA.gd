class_name CarDNA
extends RefCounted

# Car DNA representation for genetic algorithm
# DNA is now a single alphanumeric string that gets translated into car components

var dna_string: String = ""
var locality_window: int = 4  # controls how far a single char affects nearby parameters (v2)

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
	"""Ensure DNA contains only explicit base62 alphanumerics (0-9A-Za-z)."""
	var cleaned: String = ""
	for i in range(dna.length()):
		var ch: String = dna[i]
		if _is_base62(ch):
			cleaned += ch
	# Do not force a minimum length; if empty after cleaning, seed a deterministic single char
	if cleaned.length() == 0:
		cleaned = "0"
	return cleaned

static func _is_base62(ch: String) -> bool:
	if ch.length() != 1:
		return false
	var c := ch.unicode_at(0)
	return (c >= 48 and c <= 57) or (c >= 65 and c <= 90) or (c >= 97 and c <= 122)

static func _base62_val(ch: String) -> int:
	# Return value in 0..61; non-base62 returns 0
	if ch.length() != 1:
		return 0
	var c := ch.unicode_at(0)
	if c >= 48 and c <= 57:
		return c - 48
	elif c >= 65 and c <= 90:
		return 10 + (c - 65)
	elif c >= 97 and c <= 122:
		return 36 + (c - 97)
	return 0

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

# -----------------------------
# DNA v2 scaffolding and helpers
# -----------------------------

func u(channel: int, idx: int, w: int = -1) -> float:
	"""Locality-preserving uniform [0,1). Uses a small window around idx.
	If DNA is very short, wraps indices and remains deterministic."""
	var n: int = dna_string.length()
	if n == 0:
		return 0.5
	var window: int = w if w > 0 else locality_window
	var h: int = 0
	# Sum/XOR over a small window with wrap-around to remain length-agnostic
	for dj in range(-window, window + 1):
		var j: int = (idx + dj) % n
		if j < 0:
			j += n
		h ^= _mix64(channel, idx, j, _base62_val(dna_string[j]))
	# Convert to uniform [0,1) using 32-bit output to avoid 64-bit hex literal issues
	var mantissa: int = h & 0xFFFFFFFF
	return float(mantissa) / 4294967296.0

static func _mix64(c: int, i: int, j: int, v: int) -> int:
	# 32-bit-safe mixing (Murmur3 finalizer style) to avoid oversized hex literals
	var x: int = ((int(c) * 0x9E3779B1) ^ (int(i) * 0x85EBCA6B) ^ (int(j) * 0xC2B2AE35) ^ int(v)) & 0xFFFFFFFF
	x = (x ^ (x >> 16)) * 0x85EBCA6B & 0xFFFFFFFF
	x = (x ^ (x >> 13)) * 0xC2B2AE35 & 0xFFFFFFFF
	x = x ^ (x >> 16)
	return x

func z_normal(channel: int, idx: int, w: int = -1) -> float:
	"""Standard normal via inverse CDF of uniform u(channel, idx)."""
	var uu: float = clamp(u(channel, idx, w), 1e-9, 1.0 - 1e-9)
	return _inv_cdf_standard_normal(uu)

static func _inv_cdf_standard_normal(p: float) -> float:
	# Acklam's approximation for inverse normal CDF
	# Coefficients
	var a0 = -3.969683028665376e+01
	var a1 =  2.209460984245205e+02
	var a2 = -2.759285104469687e+02
	var a3 =  1.383577518672690e+02
	var a4 = -3.066479806614716e+01
	var a5 =  2.506628277459239e+00
	var b0 = -5.447609879822406e+01
	var b1 =  1.615858368580409e+02
	var b2 = -1.556989798598866e+02
	var b3 =  6.680131188771972e+01
	var b4 = -1.328068155288572e+01
	var c0 = -7.784894002430293e-03
	var c1 = -3.223964580411365e-01
	var c2 = -2.400758277161838e+00
	var c3 = -2.549732539343734e+00
	var c4 =  4.374664141464968e+00
	var c5 =  2.938163982698783e+00
	var d0 =  7.784695709041462e-03
	var d1 =  3.224671290700398e-01
	var d2 =  2.445134137142996e+00
	var d3 =  3.754408661907416e+00

	var plow = 0.02425
	var phigh: float = 1.0 - plow
	var q: float
	var r: float
	if p < plow:
		q = sqrt(-2.0 * log(p))
		var num_l: float = (((((c0 * q + c1) * q + c2) * q + c3) * q + c4) * q + c5)
		var den_l: float = (((((d0 * q + d1) * q + d2) * q + d3) * q + 1.0))
		return num_l / den_l
	elif p > phigh:
		q = sqrt(-2.0 * log(1.0 - p))
		var num_h: float = (((((c0 * q + c1) * q + c2) * q + c3) * q + c4) * q + c5)
		var den_h: float = (((((d0 * q + d1) * q + d2) * q + d3) * q + 1.0))
		return -(num_h / den_h)
	else:
		q = p - 0.5
		r = q * q
		var num_c: float = (((((a0 * r + a1) * r + a2) * r + a3) * r + a4) * r + a5)
		var den_c: float = (((((b0 * r + b1) * r + b2) * r + b3) * r + b4) * r + 1.0)
		return (num_c * q) / den_c

# ---- v2 channel accessors (initial stubs) ----

func translate_v2() -> Dictionary:
	"""Produce v2 outputs: modules, positions, per-module params, connectors, and globals."""
	var modules: Array[String] = []  # e.g., ["R","W","R",...]
	var M: int = 0
	# Smoothly estimate module count using an accumulator; no fixed DNA length needed
	var acc: float = 2.0  # base modules
	var i: int = 0
	while acc < 6.0 and i < 64:
		acc += 0.6 + 0.8 * u(0, i)
		M = int(floor(acc))
		i += 1
	if M < 2:
		M = 2
	for k in range(M):
		# Soft choice between R/W using threshold; placeholder for logits/softmax
		var val: float = u(1, k)
		modules.append("R" if val < 0.6 else "W")

	# Positions along chassis spine
	var positions: Array[float] = []
	var x_acc: float = 0.0
	var last_rect_x: float = 0.0
	for k in range(M):
		var is_rect: bool = modules[k] == "R"
		if is_rect:
			var dx: float = clamp(50.0 + 10.0 * z_normal(20, k), 25.0, 90.0)
			x_acc += dx
			last_rect_x = x_acc
			positions.append(x_acc)
		else:
			# Wheel aligns to nearest prior rectangle anchor (last_rect_x)
			positions.append(last_rect_x)

	# Per-module params
	var rect_params_list: Array = []
	var wheel_params_list: Array = []
	for k in range(M):
		if modules[k] == "R":
			rect_params_list.append(rect_params(k))
			wheel_params_list.append(null)
		else:
			rect_params_list.append(null)
			wheel_params_list.append(wheel_params(k))

	# Connectors between consecutive rectangles
	var connectors: Array = []
	for k in range(M - 1):
		if modules[k] == "R" and modules[k + 1] == "R":
			var cparams: Dictionary = connector_params(k)
			cparams["i"] = k
			cparams["j"] = k + 1
			connectors.append(cparams)

	return {
		"modules": modules,
		"positions": positions,
		"rect_params": rect_params_list,
		"wheel_params": wheel_params_list,
		"connectors": connectors,
		"globals": global_params(),
	}

func module_type_logits(i: int) -> PackedFloat32Array:
	# Placeholder 2-class logits [R, W]
	var v: float = float(u(1, i))
	return PackedFloat32Array([1.0 - v, v])

func rect_params(i: int) -> Dictionary:
	# Example parameters drawn from normals (placeholders)
	return {
		"width": clamp(48.0 + 10.0 * z_normal(2, i), 24.0, 120.0),
		"height": clamp(24.0 + 6.0 * z_normal(3, i), 12.0, 60.0),
		"density": clamp(1.0 + 0.25 * z_normal(4, i), 0.5, 2.0),
	}

func wheel_params(i: int) -> Dictionary:
	return {
		"radius": clamp(18.0 + 6.0 * z_normal(5, i), 10.0, 40.0),
		"friction": clamp(1.0 + 0.3 * z_normal(6, i), 0.4, 2.0),
		"motor_power": clamp(90.0 + 40.0 * z_normal(7, i), 0.0, 200.0),
	}

func powertrain_params(i: int) -> Dictionary:
	return {
		"gear_ratio": clamp(2.0 + 0.6 * z_normal(8, i), 0.5, 5.0),
		"efficiency": clamp(0.9 + 0.05 * z_normal(9, i), 0.5, 1.0),
	}

func connector_params(i: int) -> Dictionary:
	# Parameters for rotational connector between rectangles i and i+1
	return {
		"angle_deg": clamp(0.0 + 20.0 * z_normal(13, i), -90.0, 90.0),
		"stiffness_k": clamp(0.8 + 0.3 * z_normal(14, i), 0.1, 2.0),
		"damping_c": clamp(0.4 + 0.2 * z_normal(15, i), 0.05, 1.0),
		"slack_deg": clamp(2.0 + 1.0 * z_normal(16, i), 0.0, 10.0),
	}

func global_params() -> Dictionary:
	return {
		"com_shift": 5.0 * z_normal(10, 0),
		"damping_linear": clamp(0.1 + 0.05 * z_normal(11, 0), 0.01, 0.5),
		"damping_angular": clamp(0.2 + 0.05 * z_normal(12, 0), 0.01, 0.7),
	}

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
