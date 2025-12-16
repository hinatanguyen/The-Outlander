extends Area2D

# CHANGE THIS LINE:
@export var next_scene_path: String = "res://node_2d.tscn" 

func _ready():
	body_entered.connect(_on_body_entered)
	if $AnimatedSprite2D:
		$AnimatedSprite2D.play("default")

func _on_body_entered(body):
	if body.name == "Player" or body.is_in_group("player"):
		print("Looping back to Level 1...")
		call_deferred("change_level")

func change_level():
	if next_scene_path == "":
		return
	
	# This reloads the current scene from scratch
	get_tree().change_scene_to_file(next_scene_path)
