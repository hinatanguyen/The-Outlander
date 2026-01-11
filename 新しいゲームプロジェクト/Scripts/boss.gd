extends CharacterBody2D

# ==========================================
#                  CONFIGURATION
# ==========================================
@export_group("Stats")
@export var max_hp: int = 500        
@export var move_speed: float = 160.0 
@export var speed_phase_2: float = 200.0 
@export var acceleration: float = 900.0 

@export_group("Damage Values")
@export var damage_punch: int = 15      
@export var damage_kick: int = 20       
@export var damage_slide: int = 20      
@export var damage_ultimate: int = 30  
@export var damage_orc_explosion: int = 45   # AOE Explosion Damage
@export var explosion_radius: float = 250.0  # Explosion Radius
@export var heal_amount: int = 150           # Heal amount on explosion

@export_group("Skill Settings")
@export var orc_hitbox_size: Vector2 = Vector2(60, 100)
@export var projectile_scene: PackedScene 
@export var minion_scene: PackedScene      

# ==========================================
#                  VARIABLES
# ==========================================
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var current_hp: int
var player = null
var is_dead = false
var can_attack = true 

var is_phase_2 = false
var is_transforming = false
var is_casting_fire = false # Flag defining CHARGING + INVULNERABLE state

# HP Threshold Triggers
var has_triggered_50_percent = false
var has_triggered_25_percent = false

var current_minion_node = null 
var is_summoning = false       
var stuck_timer = 0.0 

# --- UI & NODES ---
@onready var sprite_anim = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D
@onready var muzzle = $Muzzle 
@onready var dialog_box = get_node_or_null("CanvasLayer/DialogPanel")
@onready var dialog_text = get_node_or_null("CanvasLayer/DialogPanel/Label")
@onready var health_bar = get_node_or_null("CanvasLayer/HealthBar")

# ==========================================
#                  MAIN LOOP
# ==========================================
func _ready():
	add_to_group("enemy")
	current_hp = max_hp
	print("--- BOSS READY: FIXED FLY + HEAL + 2 MINIONS EVERY TIME ---")
	
	var anim_names = sprite_anim.sprite_frames.get_animation_names()
	if "OrcFire" not in anim_names:
		print("!!! WARNING: ANIMATION 'OrcFire' NOT FOUND !!!")
	
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = current_hp
		health_bar.show()
	
	find_player_automatically()
	if dialog_box: dialog_box.hide(); start_intro_dialogue()
	play_anim_safe("Motion_animations_1_Spritelist")

func _physics_process(delta):
	# 1. Gravity (Disabled when casting fire/flying)
	if not is_on_floor() and not is_casting_fire: 
		velocity.y += gravity * delta
	
	# Anti-stuck mechanism
	if not can_attack and not is_transforming and not is_dead and not is_casting_fire:
		stuck_timer += delta
		if stuck_timer > 3.0:
			reset_state()
	else:
		stuck_timer = 0.0

	if is_dead or is_transforming:
		velocity.x = move_toward(velocity.x, 0, acceleration * delta)
		move_and_slide()
		return

	if player == null:
		find_player_automatically()
		velocity.x = move_toward(velocity.x, 0, acceleration * delta)
		move_and_slide()
		return

	var distance = global_position.distance_to(player.global_position)
	var direction_x = sign(player.global_position.x - global_position.x)
	
	if can_attack and direction_x != 0: 
		update_facing_direction(direction_x)

	# 2. RUN AI
	if is_phase_2:
		ai_phase_2(distance, direction_x, delta)
	else:
		ai_phase_1_full_skills(distance, direction_x, delta)
	
	move_and_slide()

# ==========================================
#                LOGIC PHASE 1
# ==========================================
func ai_phase_1_full_skills(dist, dir_x, delta):
	if not can_attack: 
		if sprite_anim.animation == "Slide_Attack":
			var slide_dir = -1 if sprite_anim.flip_h else 1
			velocity.x = slide_dir * move_speed * 2.5
		else:
			velocity.x = move_toward(velocity.x, 0, acceleration * delta * 2)
		return

	if dist > 250:
		var dice = randf()
		if dice < 0.4: perform_skill("Slide_Attack", damage_slide)
		elif dice < 0.8: perform_skill("Ability_Use", 0) 
		else: 
			velocity.x = move_toward(velocity.x, dir_x * move_speed, acceleration * delta)
			play_anim_safe("Motion_animations_1_Spritelist")
	elif dist > 100:
		if randf() < 0.5: perform_ranged_attack() 
		else: 
			velocity.x = move_toward(velocity.x, dir_x * move_speed, acceleration * delta)
			play_anim_safe("Motion_animations_1_Spritelist")
	else:
		velocity.x = move_toward(velocity.x, 0, acceleration * delta * 2) 
		var dice = randf()
		if dice < 0.5: perform_skill("Punch_1", damage_punch)
		elif dice < 0.8: perform_skill("Fire_Kick", damage_kick)
		else: perform_skill("Dodge", 0)

# ==========================================
#                LOGIC PHASE 2 (ORC KING)
# ==========================================
func ai_phase_2(dist, dir_x, delta):
	if not can_attack: 
		if is_casting_fire:
			# Flying/Charging logic managed by Skill function
			pass 
		elif "OrcKing_Dash" in sprite_anim.animation:
			var dash_dir = -1 if sprite_anim.flip_h else 1
			velocity.x = dash_dir * speed_phase_2 * 4.5
		else:
			velocity.x = move_toward(velocity.x, 0, acceleration * delta * 2)
		return

	if dist > 250:
		velocity.x = move_toward(velocity.x, dir_x * speed_phase_2, acceleration * delta)
		play_anim_safe("OrcKing_Idle") 
	else:
		velocity.x = move_toward(velocity.x, 0, acceleration * delta * 2)
		
		# [UPDATED] Only Dash skills, no random flying
		var dice = randf()
		if dice < 0.33: perform_skill("OrcKing_Dash1", 15)
		elif dice < 0.66: perform_skill("OrcKing_Dash2", 20)
		else: perform_skill("OrcKing_Dash3", 30)

# ==========================================
#            SKILL SYSTEM
# ==========================================
func perform_orc_fire_skill(is_forced: bool = false):
	# If forced (HP threshold), reset everything to prioritize this
	if is_forced:
		can_attack = true
		is_casting_fire = false
		velocity = Vector2.ZERO 
		print("!!! FORCE CAST: 75/50/25% HP TRIGGER !!!")

	if not can_attack: return
	
	if player:
		var dir_to_player = sign(player.global_position.x - global_position.x)
		if dir_to_player != 0: sprite_anim.flip_h = (dir_to_player < 0)

	can_attack = false
	is_casting_fire = true # START INVULNERABLE & GRAVITY OFF
	velocity.x = 0
	
	# 1. PLAY ANIMATION "OrcFire"
	sprite_anim.stop() 
	if sprite_anim.sprite_frames.has_animation("OrcFire"):
		print(">>> Playing OrcFire...")
		sprite_anim.play("OrcFire")
	else:
		print(">>> MISSING 'OrcFire'. Playing Idle.")
		sprite_anim.play("OrcKing_Idle")

	# 2. LOW JUMP (70px)
	var tween = create_tween()
	tween.tween_property(self, "position:y", position.y - 70, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# 3. WAIT FOR ANIMATION TO FINISH
	print(">>> Waiting for animation to finish...")
	await sprite_anim.animation_finished
	
	# 4. COMBO: AOE EXPLOSION + HEAL + SUMMON
	create_explosion_aoe_and_heal()
	
	# [IMPORTANT] Ensure minions are spawned EVERY time this skill runs
	spawn_two_minions() 
	
	# 5. END
	print(">>> Skill Done. Falling down.")
	
	await get_tree().create_timer(0.2).timeout
	
	is_casting_fire = false 
	can_attack = true

# [NEW] EXPLOSION AND HEAL LOGIC
func create_explosion_aoe_and_heal():
	print(">>> BOOM! EXPLOSION & HEAL!")
	
	# Heal Effect (Green Color)
	modulate = Color(0.2, 1.5, 0.2) 
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.5)
	
	# Heal Logic
	current_hp = min(current_hp + heal_amount, max_hp)
	if health_bar: health_bar.value = current_hp
	print(">>> Boss Healed: +", heal_amount, " HP. Current: ", current_hp)
	
	# Damage Logic (Only Player takes damage)
	if player:
		var dist = global_position.distance_to(player.global_position)
		if dist <= explosion_radius:
			if player.has_method("take_damage"):
				player.take_damage(damage_orc_explosion)

func spawn_two_minions():
	if not minion_scene:
		print(">>> ERROR: Minion Scene not assigned!")
		return
		
	print(">>> SPAWNING 2 MINIONS (10px offset)!")
	for i in [-1, 1]:
		var minion = minion_scene.instantiate()
		# [UPDATED] Spawn offset decreased to 10px
		var spawn_offset = Vector2(i * 10, 0)
		minion.global_position = global_position + spawn_offset
		get_parent().call_deferred("add_child", minion)

func perform_skill(anim_name, damage):
	if not can_attack: return
	if anim_name == "Ability_Use":
		if is_instance_valid(current_minion_node) or is_summoning: return 

	if player:
		var dir_to_player = sign(player.global_position.x - global_position.x)
		if dir_to_player != 0: sprite_anim.flip_h = (dir_to_player < 0)

	can_attack = false
	if anim_name != "Slide_Attack" and not "OrcKing_Dash" in anim_name: 
		velocity.x = 0
		
	play_anim_safe(anim_name)
	
	if anim_name == "Ability_Use":
		is_summoning = true
		await get_tree().create_timer(0.5).timeout
		if minion_scene and not is_instance_valid(current_minion_node): 
			var minion = minion_scene.instantiate()
			var spawn_dir = -1 if sprite_anim.flip_h else 1
			minion.global_position = global_position + Vector2(spawn_dir * 80, -400)
			get_parent().add_child(minion)
			current_minion_node = minion
		is_summoning = false
	
	if damage > 0:
		var delay_time = 0.3
		if "OrcKing_Dash" in anim_name: delay_time = 0.25 
		
		await get_tree().create_timer(delay_time).timeout
		if player and global_position.distance_to(player.global_position) < 200:
			if player.has_method("take_damage"): 
				player.take_damage(damage)

	await sprite_anim.animation_finished
	await get_tree().create_timer(0.3).timeout
	can_attack = true

func perform_ranged_attack():
	if not can_attack: return
	if player:
		var dir_to_player = sign(player.global_position.x - global_position.x)
		if dir_to_player != 0: sprite_anim.flip_h = (dir_to_player < 0)

	can_attack = false
	velocity.x = 0 
	
	play_anim_safe("Explosive_Strike")
	await get_tree().create_timer(0.5).timeout
	
	if projectile_scene and muzzle:
		var bullet = projectile_scene.instantiate()
		bullet.global_position = muzzle.global_position
		if player: bullet.direction = (player.global_position - global_position).normalized()
		get_tree().root.add_child(bullet)
		
	if player and global_position.distance_to(player.global_position) < 200:
		if player.has_method("take_damage"):
			player.take_damage(damage_ultimate)

# ==========================================
#                TAKE DAMAGE (INVULNERABLE)
# ==========================================
func take_damage(amount):
	if is_dead or is_transforming: return
	
	# Check Invulnerability
	if is_casting_fire:
		modulate = Color(0.5, 0.5, 2.0) 
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color.WHITE, 0.1)
		return 

	var actual_damage = amount * 2
	current_hp -= actual_damage
	if health_bar: health_bar.value = current_hp
	
	modulate = Color(10, 0, 0) 
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)
	
	# Threshold 75%: Transform to Orc
	if not is_phase_2 and current_hp <= max_hp * 0.75:
		enter_phase_2()
		return

	# Threshold 50% & 25%: Only check in Phase 2
	if is_phase_2:
		if current_hp <= max_hp * 0.50 and not has_triggered_50_percent:
			has_triggered_50_percent = true
			perform_orc_fire_skill(true)
			return
			
		elif current_hp <= max_hp * 0.25 and not has_triggered_25_percent:
			has_triggered_25_percent = true
			perform_orc_fire_skill(true)
			return

	if not is_phase_2 and sprite_anim.sprite_frames.has_animation("Hurt"):
		if randf() < 0.3:
			can_attack = false 
			sprite_anim.play("Hurt")
			await sprite_anim.animation_finished
			can_attack = true

	if current_hp <= 0: die()

func reset_state():
	can_attack = true
	is_transforming = false
	is_summoning = false
	is_casting_fire = false 
	modulate = Color.WHITE
	velocity.x = 0
	play_anim_safe("Motion_animations_1_Spritelist")

func enter_phase_2():
	print(">>> ENTERING PHASE 2: ORC KING")
	is_transforming = true; is_phase_2 = true; velocity = Vector2.ZERO
	has_triggered_50_percent = false
	has_triggered_25_percent = false
	if is_instance_valid(current_minion_node): current_minion_node.queue_free()
	play_anim_safe("Turning_Orc")
	await sprite_anim.animation_finished
	update_hitbox(orc_hitbox_size)
	is_transforming = false
	
	# [NEW] Trigger fly skill immediately after transformation (75% threshold)
	perform_orc_fire_skill(true)

func play_anim_safe(anim_name):
	if is_phase_2 and anim_name == "Motion_animations_1_Spritelist":
		anim_name = "OrcKing_Idle"
	
	if sprite_anim.sprite_frames.has_animation(anim_name): 
		if sprite_anim.animation != anim_name: sprite_anim.play(anim_name)
	else: 
		if is_phase_2: sprite_anim.play("OrcKing_Idle")
		else: sprite_anim.play("Motion_animations_1_Spritelist")

func update_facing_direction(dir_x):
	if dir_x < 0: sprite_anim.flip_h = true; if muzzle: muzzle.position.x = -abs(muzzle.position.x)
	elif dir_x > 0: sprite_anim.flip_h = false; if muzzle: muzzle.position.x = abs(muzzle.position.x)

func update_hitbox(size_vec):
	if collision_shape.shape is RectangleShape2D:
		collision_shape.shape.size = size_vec
		collision_shape.position.y = -size_vec.y / 2
		
func find_player_automatically():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0: player = players[0]
	elif get_parent().has_node("Player"): player = get_parent().get_node("Player")

func start_intro_dialogue():
	if dialog_text: dialog_box.show(); dialog_text.text = "You cannot defeat me!"; await get_tree().create_timer(2.0).timeout; dialog_box.hide()

func die():
	is_dead = true; velocity = Vector2.ZERO
	if health_bar: health_bar.hide()
	if sprite_anim.sprite_frames.has_animation("Death"): sprite_anim.play("Death")
	else: sprite_anim.stop(); modulate.a = 0.5
	await get_tree().create_timer(1.0).timeout; queue_free()
