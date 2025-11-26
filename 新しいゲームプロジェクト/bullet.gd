extends Area2D

var speed = 600
var direction = 1 # 1 is right, -1 is left

func _physics_process(delta):
	# Move the bullet in WORLD SPACE
	global_position.x += speed * direction * delta

func _on_body_entered(body):
	# Ignore the Player
	if body.name == "Player":
		return
	
	# Check if the object is a Wall/Floor (TileMap)
	if body is TileMapLayer or body is TileMap:
		return
	
	# If it hits anything else (like an Enemy), destroy the bullet
	queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
