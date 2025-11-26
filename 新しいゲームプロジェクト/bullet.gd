extends Area2D

var speed = 600
var direction = 1 # 1 is right, -1 is left

func _physics_process(delta):
	global_position.x += speed * direction * delta

func _on_body_entered(body):
	# Ignore the Player
	if body.name == "Player":
		return
	
	# Hit a wall, floor, or other body - destroy bullet
	queue_free()

func _on_area_entered(area):
	# Check if it's an enemy hurtbox
	if area.name == "Hurtbox" or area.is_in_group("enemy"):
		# The enemy's script will handle the damage and destroy this bullet
		pass

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
