extends CharacterBody2D

const GRAVITY = 900.0

@onready var anim = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D
@onready var hurtbox = $Hurtbox

var health = 10
var is_dead = false
var is_hurt = false

func _ready():
	anim.play("idle")

func _physics_process(delta):
	if is_dead:
		return
	
	# Apply gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	
	# Don't move during hurt animation
	if is_hurt:
		velocity.x = 0
		move_and_slide()
		return
	
	# Dummy doesn't move, just stays idle
	velocity.x = 0
	if not is_hurt:
		anim.play("idle")
	
	move_and_slide()

# --- Damage / Death handling ---
func _on_hurtbox_area_entered(area):
	if area.is_in_group("player_projectile"):
		take_damage(1)
		area.queue_free()

func take_damage(amount):
	if is_dead:
		return
	
	health -= amount
	
	if health <= 0:
		die()
	else:
		is_hurt = true
		velocity.x = 0
		anim.play("hurt")
		await anim.animation_finished
		is_hurt = false

func die():
	is_dead = true
	velocity.x = 0
	anim.play("die")
	collision_shape.set_deferred("disabled", true)
	
	# Disable hurtbox after death
	if hurtbox.has_node("CollisionShape2D"):
		hurtbox.get_node("CollisionShape2D").set_deferred("disabled", true)
	
	await get_tree().create_timer(4.0).timeout
	queue_free()
