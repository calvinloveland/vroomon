class_name TerrainProfile
extends Resource

@export var name: String = "Flat"
@export var seed: int = 0
@export var ground_length: float = 5000.0
@export var friction: float = 1.0
@export var ground_height: float = 400.0
@export var color_ground: Color = Color.BROWN
@export var color_obstacle: Color = Color.DARK_GRAY
@export var obstacle_count: int = 5
@export var obstacle_params: Dictionary = {}

func clone() -> TerrainProfile:
	var p := TerrainProfile.new()
	p.name = name
	p.seed = seed
	p.ground_length = ground_length
	p.friction = friction
	p.ground_height = ground_height
	p.color_ground = color_ground
	p.color_obstacle = color_obstacle
	p.obstacle_count = obstacle_count
	p.obstacle_params = obstacle_params.duplicate(true)
	return p
