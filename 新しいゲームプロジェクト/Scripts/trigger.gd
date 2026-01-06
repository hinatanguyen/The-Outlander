extends Area2D

@export var spawner: Node2D

var triggered = false

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if triggered:
		return
	
	if body.is_in_group("player"):
		triggered = true
		
		if spawner and spawner.has_method("activate_spawner"):
			spawner.activate_spawner()
