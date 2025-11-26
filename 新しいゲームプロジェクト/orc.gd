extends CharacterBody2D

const GRAVITY = 900.0
const WALK_SPEED = 50.0
const CHASE_TRIGGER_DISTANCE = 70.0 # Distance to start swinging

@onready var anim = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D
@onready var hurtbox = $Hurtbox
@onready var attack_range_node = $AttackRange # Reference to your new node

var health = 3
var is_dead = false
var is_hurt = false
var is_attacking = false
var player = null
var player_in_attack_zone = false # Tracks if player is physically inside the box

func _ready():
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta):
	if is_dead:
		return
	
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	
	# Stop moving if hurt or attacking
	if is_hurt or is_attacking:
		velocity.x = 0
		move_and_slide()
		return
	
	if player:
		var direction_to_player = global_position.direction_to(player.global_position)
		var distance_to_player = global_position.distance_to(player.global_position)
		
		# --- FLIPPING LOGIC ---
		# We need to flip the Sprite AND the AttackRange box so he attacks the correct side
		if direction_to_player.x < 0:
			anim.flip_h = true
			attack_range_node.scale.x = -1 # Flips the detection box to the left
		else:
			anim.flip_h = false
			attack_range_node.scale.x = 1 # Flips the detection box to the right
			
		# --- MOVEMENT LOGIC ---
		if distance_to_player > CHASE_TRIGGER_DISTANCE:
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
	
	# Wait a split second so damage happens when the axe actually hits (0.3s is a guess)
	# Adjust this number to match your animation speed!
	await get_tree().create_timer(0.3).timeout
	
	# Check if player is still in the box when the axe lands
	if player_in_attack_zone and not is_dead and not is_hurt:
		print("Player hit!")
		if player.has_method("take_damage"):
			player.take_damage(1) # Deal 1 damage
	
	await anim.animation_finished
	is_attacking = false

# --- NEW SIGNAL CONNECTIONS ---

# Signal: AttackRange -> body_entered
func _on_attack_range_body_entered(body):
	if body.is_in_group("player"):
		player_in_attack_zone = true

# Signal: AttackRange -> body_exited
func _on_attack_range_body_exited(body):
	if body.is_in_group("player"):
		player_in_attack_zone = false

# --- EXISTING HURT/DEATH LOGIC ---

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
	
	# Disable hitboxes so dead orc doesn't hurt anyone
	attack_range_node.set_deferred("monitoring", false)
	if hurtbox.has_node("CollisionShape2D"):
		hurtbox.get_node("CollisionShape2D").set_deferred("disabled", true)
	
	await get_tree().create_timer(4.0).timeout
	queue_free()
