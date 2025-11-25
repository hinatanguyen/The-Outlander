extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -650.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var anim = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D

var is_attacking = false
var is_hurt = false
var is_dead = false
var health = 3

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

	# ATTACK
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and is_on_floor() and not is_attacking:
		perform_attack()
	
	# TEST DAMAGE
	if Input.is_key_pressed(KEY_H):
		take_damage()

	# MOVEMENT
	if not is_attacking:
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY

		var direction = Input.get_axis("move_left", "move_right")
		
		if direction:
			velocity.x = direction * SPEED
			anim.play("walk")
			if direction < 0: anim.flip_h = true
			else: anim.flip_h = false
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			anim.play("idle")

	move_and_slide()

# --- ACTIONS ---

func perform_attack():
	is_attacking = true
	velocity.x = 0
	anim.play("attack")

func take_damage():
	if is_hurt or is_dead: return
	
	health -= 1
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

# This runs automatically whenever ANY animation finishes (attack, hurt, death)
func _on_animated_sprite_2d_animation_finished():
	# Check WHICH animation just finished
	if anim.animation == "attack":
		is_attacking = false
		anim.play("idle")
		
	elif anim.animation == "hurt":
		is_hurt = false
		anim.play("idle")

func _unhandled_input(event):
	# Check if the event is a Key Press, specifically the "H" key
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_H:
			print("H Key Pressed! Taking Damage...") # Debug message
			take_damage()
