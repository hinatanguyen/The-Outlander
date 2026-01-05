extends Node

@export var portal_scene: PackedScene
@export var portal_spawn_marker: Marker2D
@export var portal_spawn_position: Vector2 = Vector2(800, 200)
@export var enemies_to_defeat: int = 1

var enemies_defeated: int = 0
var level_complete: bool = false
var spawners: Array[Node] = []

signal level_completed
signal enemy_defeated(count: int)

func _ready():
	spawners = get_tree().get_nodes_in_group("spawners")
	print("LevelManager: Found ", spawners.size(), " spawners via Group")

func register_enemy(enemy: Node):
	if enemy.has_signal("tree_exited"):
		enemy.tree_exited.connect(_on_enemy_killed)

func _on_enemy_killed():
	if level_complete:
		return
		
	enemies_defeated += 1
	emit_signal("enemy_defeated", enemies_defeated)
	
	print("Enemies defeated: ", enemies_defeated, "/", enemies_to_defeat)
	
	if enemies_defeated >= enemies_to_defeat:
		complete_level()

func complete_level():
	if level_complete:
		return
		
	level_complete = true
	
	# Stop spawners - FIXED: Check if spawners array is valid
	for spawner in spawners:
		if not is_instance_valid(spawner):
			continue
		if "is_active" in spawner: 
			spawner.is_active = false
		if spawner.has_node("Timer"): 
			spawner.get_node("Timer").stop()
		spawner.set_process(false)
		spawner.set_physics_process(false)
	
	# Kill remaining enemies - FIXED: Check tree validity
	if not get_tree():
		return
		
	var remaining_enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in remaining_enemies:
		if not is_instance_valid(enemy):
			continue
		if enemy.has_method("die"):
			enemy.die()
		else:
			enemy.queue_free()

	# Show notification and spawn portal
	show_completion_notification()
	await get_tree().create_timer(0.1).timeout 
	spawn_portal()
	
	emit_signal("level_completed")

func show_completion_notification():
	# FIXED: Check if tree is valid before accessing
	if not get_tree():
		return
		
	var current_scene = get_tree().current_scene
	if not current_scene:
		return
	
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	current_scene.add_child(canvas_layer)
	
	var notification_label = Label.new()  # RENAMED to avoid shadowing warning
	notification_label.text = "CLEARED"
	
	var settings = LabelSettings.new()
	settings.font_size = 128
	settings.font_color = Color.GREEN_YELLOW
	settings.outline_size = 20
	settings.outline_color = Color.BLACK
	notification_label.label_settings = settings
	
	notification_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notification_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	canvas_layer.add_child(notification_label)
	notification_label.anchors_preset = Control.PRESET_CENTER
	
	# Animation
	notification_label.scale = Vector2.ZERO
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(notification_label, "scale", Vector2.ONE, 0.15)
	
	# Fade out
	var fade_tween = create_tween()
	fade_tween.tween_property(notification_label, "modulate:a", 0.0, 1.0).set_delay(2.0)
	fade_tween.tween_callback(canvas_layer.queue_free)

func spawn_portal():
	if not portal_scene:
		push_error("Portal scene not assigned to LevelManager!")
		return
	
	# FIXED: Check tree validity
	if not get_tree():
		return
		
	var current_scene = get_tree().current_scene
	if not current_scene:
		return
	
	var portal = portal_scene.instantiate()
	
	# Use marker position if available
	if portal_spawn_marker and is_instance_valid(portal_spawn_marker):
		portal.global_position = portal_spawn_marker.global_position
		print("Portal spawned at marker position: ", portal.global_position)
	else:
		portal.global_position = portal_spawn_position
		print("Portal spawned at exported position: ", portal.global_position)
	
	portal.z_index = 10
	
	current_scene.add_child(portal)
