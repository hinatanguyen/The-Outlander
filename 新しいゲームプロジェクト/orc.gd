extends CharacterBody2D

const GRAVITY = 900.0
const WALK_SPEED = 50.0
const ATTACK_RANGE = 40.0

@onready var anim = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D
@onready var hurtbox = $Hurtbox

var health = 3
var is_dead = false
var is_hurt = false
var is_attacking = false
var player = null

func _ready():
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta):
	if is_dead: 
		return
	
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	
	if is_hurt or is_attacking:
		velocity.x = 0
		move_and_slide()
		return
	
	if player:
		var direction_to_player = global_position.direction_to(player.global_position)
		var distance_to_player = global_position.distance_to(player.global_position)
		
		if direction_to_player.x < 0:
			anim.flip_h = true
		else:
			anim.flip_h = false
			
		if distance_to_player > ATTACK_RANGE:
			velocity.x = sign(direction_to_player.x) * WALK_SPEED
			anim.play("walk")
		else:
			velocity.x = 0
			if not is_attacking:
				perform_attack()
	else:
		velocity.x = 0
		if not is_attacking and not is_hurt:
			anim.play("idle")
		
	move_and_slide()

func perform_attack():
	if is_attacking: 
		return
	
	is_attacking = true
	anim.play("attack")
	await anim.animation_finished
	is_attacking = false

func _on_hurtbox_area_entered(area):
	if area.is_in_group("bullet"):
		take_damage()
		area.queue_free()

func take_damage():
	if is_dead: 
		return
	
	health -= 1
	
	if health <= 0:
		die()
	else:
		is_hurt = true
		is_attacking = false
		velocity.x = 0
		anim.play("hurt")
		await anim.animation_finished
		is_hurt = false

func die():
	is_dead = true
	velocity.x = 0
	anim.play("death")
	collision_shape.set_deferred("disabled", true)
	if hurtbox and hurtbox.has_node("CollisionShape2D"):
		hurtbox.get_node("CollisionShape2D").set_deferred("disabled", true)
	
	# Wait 4 seconds then remove the Orc
	await get_tree().create_timer(4.0).timeout
	queue_free()
