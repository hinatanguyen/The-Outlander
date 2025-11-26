extends CharacterBody2D

signal health_changed(new_value)

const SPEED = 300.0
const JUMP_VELOCITY = -650.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# You had both anim and sprite pointing to the same thing, 
# I kept them both so your code doesn't break.
@onready var anim = $AnimatedSprite2D
@onready var sprite = $AnimatedSprite2D 
@onready var collision_shape = $CollisionShape2D
@onready var muzzle = $Muzzle

@export var bullet_scene : PackedScene

var is_attacking = false
var is_hurt = false
var is_dead = false
var health = 100 

func _physics_process(delta):
	if is_dead: return 
	
	# HURT STATE
	if is_hurt:
		if not is_on_floor():
			velocity.y += gravity * delta
		move_and_slide()
		return

	# GRAVITY
	if not is_on_floor():
		velocity.y += gravity * delta
		
	# ATTACK (Left Mouse Click)
	# This checks if you click AND you aren't already attacking
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not is_attacking:
		perform_attack()

	# MOVEMENT
	if not is_attacking:
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY

		var direction = Input.get_axis("move_left", "move_right")
		
		if direction:
			velocity.x = direction * SPEED
			anim.play("walk")
			if direction < 0: 
				anim.flip_h = true
			else: 
				anim.flip_h = false
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			anim.play("idle")

	move_and_slide()

# --- ACTIONS ---

func perform_attack():
	is_attacking = true
	
	# Stop moving when shooting
	if is_on_floor():
		velocity.x = 0		
	
	anim.play("attack")
	
	# FIRE THE BULLET HERE
	shoot()

func shoot():
	if bullet_scene:	
		var bullet = bullet_scene.instantiate()
		
		# check direction based on sprite flip
		if sprite.flip_h == true:
			bullet.direction = -1
		else:
			bullet.direction = 1
		
		# Add bullet to the SCENE ROOT, not the parent
		get_tree().current_scene.add_child(bullet)
		
		# Set position after adding to scene
		bullet.global_position = muzzle.global_position
		
		
		
func take_damage():
	if is_hurt or is_dead: return
	
	health -= 1
	health_changed.emit(health)
	print("Current Health: ", health) 
	
	if health <= 0:
		die()
	else:
		is_hurt = true
		velocity.x = 0
		anim.play("hurt")

func die():
	is_dead = true
	velocity.x = 0
	anim.play("death")
	collision_shape.set_deferred("disabled", true)
	print("Player Died")

func _on_animated_sprite_2d_animation_finished():
	if anim.animation == "attack":
		is_attacking = false
		anim.play("idle")
		
	elif anim.animation == "hurt":
		is_hurt = false
		anim.play("idle")

# This handles the single key press for testing damage
func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_H:	
			take_damage()
