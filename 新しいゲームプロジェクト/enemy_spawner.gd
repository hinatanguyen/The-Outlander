extends Node2D

@export var enemy_scene: PackedScene
@export var spawn_interval: float = 1.0
@export var max_enemies: int = 5

var spawn_points: Array[Node2D] = []
var spawn_timer: float = 0.0
var current_enemy_count: int = 0

func _ready():
	# Collect all Marker2D children as spawn points
	for child in get_children():
		if child is Marker2D:
			spawn_points.append(child)
	
	if spawn_points.is_empty():
		print("WARNING: No spawn points found! Add Marker2D nodes as children.")

func _process(delta):
	if not enemy_scene or spawn_points.is_empty():
		return
	
	spawn_timer += delta
	
	if spawn_timer >= spawn_interval and current_enemy_count < max_enemies:
		spawn_enemy()
		spawn_timer = 0.0

func spawn_enemy():
	# Pick a random spawn point
	var spawn_point = spawn_points[randi() % spawn_points.size()]
	
	# Create enemy instance
	var enemy = enemy_scene.instantiate()
	enemy.global_position = spawn_point.global_position
	
	# Ensure visibility (Render on top of background)
	enemy.z_index = 5
	
	# Add to scene tree
	get_parent().add_child(enemy)
	
	# Connect death signal to track count
	if enemy.has_signal("tree_exited"):
		enemy.tree_exited.connect(_on_enemy_died)
	
	current_enemy_count += 1

func _on_enemy_died():
	current_enemy_count -= 1
