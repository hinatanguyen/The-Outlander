extends Area2D

@export var next_scene_path: String = "res://Scene/level2.tscn"
var is_changing_scene: bool = false

func _ready():
	body_entered.connect(_on_body_entered)
	if $AnimatedSprite2D:
		$AnimatedSprite2D.play("default")

func _on_body_entered(body):
	if is_changing_scene:
		return
		
	if body.name == "Player" or body.is_in_group("player"):
		is_changing_scene = true
		print("Changing to next level: ", next_scene_path)
		call_deferred("change_level")

func change_level():
	if next_scene_path == "":
		return
	
	if not ResourceLoader.exists(next_scene_path):
		push_error("Scene does not exist: ", next_scene_path)
		return
	
	# CRITICAL: Clean up any persistent UI or objects added to root
	cleanup_persistent_objects()
	
	# Change scene
	get_tree().change_scene_to_file(next_scene_path)

func cleanup_persistent_objects():
	# Remove any CanvasLayers (completion notifications)
	for child in get_tree().root.get_children():
		if child is CanvasLayer:
			child.queue_free()
	
	# Remove any loose portals in root
	for child in get_tree().root.get_children():
		if child.name.begins_with("Portal") or child is Area2D:
			if child != get_tree().current_scene:
				child.queue_free()
