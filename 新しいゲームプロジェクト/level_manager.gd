# level_manager.gd
extends Node

@export var portal_scene: PackedScene  # Assign your portal scene here
@export var portal_spawn_position: Vector2 = Vector2(800, 400)  # Where portal appears
@export var enemies_to_defeat: int = 20  # Total enemies to defeat for level complete

var enemies_defeated: int = 0
var level_complete: bool = false
var spawners: Array[Node] = []

signal level_completed
signal enemy_defeated(count: int)

func _ready():
	# This now finds ALL nodes you checked "spawners" for in the editor
	spawners = get_tree().get_nodes_in_group("spawners")
	print("LevelManager: Found ", spawners.size(), " spawners via Group")

func find_spawners(node: Node):
	# Recursively find all enemy_spawner nodes
	for child in node.get_children():
		if child.has_method("activate_spawner"):
			spawners.append(child)
			print("LevelManager: Found spawner - ", child.name)
		find_spawners(child)

func register_enemy(enemy: Node):
	# Connect to enemy's death signal
	if enemy.has_signal("tree_exited"):
		enemy.tree_exited.connect(_on_enemy_killed)

func _on_enemy_killed():
	if level_complete:
		return
		
	enemies_defeated += 1
	emit_signal("enemy_defeated", enemies_defeated)
	
	print("Enemies defeated: ", enemies_defeated, "/", enemies_to_defeat)
	
	# Check if level is complete
	if enemies_defeated >= enemies_to_defeat:
		complete_level()

func complete_level():
	if level_complete:
		return
		
	level_complete = true
	
	# 1. Stop Spawners
	for spawner in spawners:
		if "is_active" in spawner: spawner.is_active = false
		if spawner.has_node("Timer"): spawner.get_node("Timer").stop()
		spawner.set_process(false)
		spawner.set_physics_process(false)
	
	# 2. Kill/Die remaining enemies
	var remaining_enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in remaining_enemies:
		if enemy.has_method("die"):
			enemy.die()
		else:
			enemy.queue_free()

	# 3. UI & PORTAL (FASTER)
	show_completion_notification()
	
	# CHANGED: Reduced delay from 1.5s to 0.1s (Basically instant)
	await get_tree().create_timer(0.1).timeout 
	spawn_portal()
	
	emit_signal("level_completed")

func show_completion_notification():
	# 1. Create a temporary CanvasLayer (This makes it stick to the camera)
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100 # Ensure it's on top of everything
	get_tree().root.add_child(canvas_layer)
	
	# 2. Create the Label
	var notification = Label.new()
	notification.text = "CLEARED"
	
	# Style settings (Huge text)
	var settings = LabelSettings.new()
	settings.font_size = 128
	settings.font_color = Color.GREEN_YELLOW
	settings.outline_size = 20
	settings.outline_color = Color.BLACK
	notification.label_settings = settings
	
	# 3. Center it on the screen using Anchors (Best practice for UI)
	notification.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notification.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Add to the CanvasLayer so it ignores camera movement
	canvas_layer.add_child(notification)
	
	# Set anchors to center (0.5 means 50% of screen width/height)
	notification.anchors_preset = Control.PRESET_CENTER
	
	# 4. Animation (Pop in)
	notification.scale = Vector2.ZERO
	notification.pivot_offset = Vector2(notification.size.x / 2, notification.size.y / 2) # Pivot center isn't calculated perfectly until next frame, but presets help
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(notification, "scale", Vector2.ONE, 0.15)
	
	# 5. Cleanup
	# Fade out and delete the whole CanvasLayer, not just the label
	var fade_tween = create_tween()
	fade_tween.tween_property(notification, "modulate:a", 0.0, 1.0).set_delay(2.0)
	# When done, delete the CanvasLayer (which deletes the label too)
	fade_tween.tween_callback(canvas_layer.queue_free)

func spawn_portal():
	if not portal_scene:
		push_error("Portal scene not assigned to LevelManager!")
		return
	
	var portal = portal_scene.instantiate()
	portal.global_position = portal_spawn_position
	portal.z_index = 10
	
	get_tree().root.add_child(portal)
	print("Portal spawned at: ", portal_spawn_position)
