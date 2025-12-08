extends Area2D

@export var spawner: Node2D  # Drag your enemy_spawner here

var triggered = false

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if triggered:
		return
	
	if body.is_in_group("player"):
		print("Player entered trigger! Activating spawner...")
		triggered = true
		
		if spawner and spawner.has_method("activate_spawner"):
			spawner.activate_spawner()
