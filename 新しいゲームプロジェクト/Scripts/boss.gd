extends CharacterBody2D

# ==========================================
#                  CẤU HÌNH
# ==========================================
@export_group("Stats")
@export var max_hp: int = 1000
@export var move_speed: float = 160.0 # Đã tăng tốc độ chạy thường (cũ 120)
@export var speed_phase_2: float = 140.0

# --- CẤU HÌNH DASH (MỚI) ---
@export var dash_speed: float = 600.0 # Tốc độ lướt cực nhanh
@export var dash_range: float = 250.0 # Khoảng cách kích hoạt Dash
@export var dash_cooldown_time: float = 3.0 # Thời gian hồi chiêu Dash

@export_group("Damage Values")
@export var damage_punch: int = 30
@export var damage_ultimate: int = 80

@export_group("Phase 2 Settings")
@export var orc_hitbox_size: Vector2 = Vector2(60, 100)
@export var projectile_scene: PackedScene 

# ==========================================
#                  BIẾN
# ==========================================
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var current_hp: int
var player = null
var is_dead = false
var can_attack = true

# Trạng thái Dash
var is_dashing = false
var can_dash = true

# Trạng thái Phase
var is_phase_2 = false
var is_transforming = false

# --- UI & NODES ---
@onready var sprite_anim = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D
@onready var muzzle = $Muzzle 
@onready var dialog_box = get_node_or_null("CanvasLayer/DialogPanel")
@onready var dialog_text = get_node_or_null("CanvasLayer/DialogPanel/Label")

# KẾT NỐI THANH MÁU (Quan trọng để thấy máu tụt)
@onready var health_bar = $CanvasLayer/HealthBar 

# ==========================================
#                  MAIN LOOP
# ==========================================
func _ready():
	add_to_group("enemy")
	current_hp = max_hp
	
	# Cài đặt thanh máu ban đầu
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = current_hp
		health_bar.show()
	
	find_player_automatically()
	
	if dialog_box:
		dialog_box.hide()
		start_intro_dialogue()
	
	play_anim_safe("Motion_animations_1_Spritelist")

func _physics_process(delta):
	# 1. Trọng lực
	if not is_on_floor():
		velocity.y += gravity * delta
	
	if is_dead or is_transforming:
		velocity.x = move_toward(velocity.x, 0, 10)
		move_and_slide()
		return

	# 2. Tìm Player
	if player == null:
		find_player_automatically()
		velocity.x = 0
		move_and_slide()
		return

	# 3. Tính toán khoảng cách
	var distance = global_position.distance_to(player.global_position)
	var direction_x = sign(player.global_position.x - global_position.x)
	
	# Quay mặt
	if direction_x != 0 and not is_dashing: # Không quay mặt khi đang lướt
		update_facing_direction(direction_x)

	# 4. LOGIC DASH (MỚI)
	# Nếu đang Dash thì giữ nguyên tốc độ Dash, bỏ qua logic di chuyển thường
	if is_dashing:
		velocity.x = direction_x * dash_speed
		move_and_slide()
		return # Ngắt hàm tại đây để không chạy logic đi bộ bên dưới

	# Kích hoạt Dash nếu Player ở quá xa
	if can_dash and distance > dash_range and can_attack:
		perform_dash()
		move_and_slide()
		return

	# 5. DI CHUYỂN BÌNH THƯỜNG
	if is_phase_2:
		ai_phase_2(distance, direction_x)
	else:
		ai_phase_1(distance, direction_x)
	
	move_and_slide()

# ==========================================
#                  LOGIC DASH (MỚI)
# ==========================================
func perform_dash():
	if not can_dash: return
	
	is_dashing = true
	can_dash = false
	can_attack = false # Không đánh khi đang lướt
	
	print(">>> BOSS DASHING!")
	
	# Chạy Anim Dash (Dodge)
	play_anim_safe("Dodge")
	
	# Lướt trong 0.5 giây
	await get_tree().create_timer(0.5).timeout
	
	is_dashing = false
	can_attack = true
	
	# Chạy lại anim đi bộ
	play_anim_safe("Motion_animations_1_Spritelist")
	
	# Hồi chiêu Dash
	await get_tree().create_timer(dash_cooldown_time).timeout
	can_dash = true

# ==========================================
#              HÀM NHẬN DAMAGE (SỬA LỖI)
# ==========================================
func take_damage(amount):
	if is_dead or is_transforming: return
	
	current_hp -= amount
	print("Boss bị bắn! HP còn: ", current_hp)
	
	# --- CẬP NHẬT UI (SỬA LỖI THANH MÁU KHÔNG TỤT) ---
	if health_bar:
		health_bar.value = current_hp
	# -------------------------------------------------
	
	# Hiệu ứng nháy đỏ
	modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	modulate = Color.WHITE
	
	# Chuyển Phase
	if not is_phase_2 and current_hp <= max_hp / 2.0:
		enter_phase_2()
		return

	if current_hp <= 0:
		die()

# ==========================================
#              LOGIC CHIẾN ĐẤU CŨ
# ==========================================
func ai_phase_1(dist, dir_x):
	if not can_attack: 
		velocity.x = 0; return

	if dist > 60:
		velocity.x = dir_x * move_speed
		play_anim_safe("Motion_animations_1_Spritelist")
	else:
		velocity.x = 0
		perform_melee_attack("Punch_1", damage_punch)

func ai_phase_2(dist, dir_x):
	if not can_attack: 
		velocity.x = 0; return

	if dist > 300 and randf() < 0.02:
		perform_ranged_attack(); return

	if dist > 100:
		velocity.x = dir_x * speed_phase_2
		play_anim_safe("Motion_animations_1_Spritelist")
		modulate = Color(1.5, 0.5, 0.5)
	else:
		velocity.x = 0
		perform_melee_attack("Punch_1", damage_punch * 2)

# ... (Giữ nguyên các hàm perform_melee_attack, perform_ranged_attack, 
#      enter_phase_2, find_player_automatically, update_facing_direction, 
#      die, start_intro_dialogue như code cũ của bạn) ...

func perform_melee_attack(anim_name, damage):
	if not can_attack: return
	can_attack = false
	velocity.x = 0
	play_anim_safe(anim_name)
	await sprite_anim.animation_finished
	if player and global_position.distance_to(player.global_position) < 120:
		if player.has_method("take_damage"): player.take_damage(damage)
	await get_tree().create_timer(0.5).timeout
	can_attack = true

func perform_ranged_attack():
	can_attack = false
	velocity.x = 0
	play_anim_safe("Explosive_Strike")
	await get_tree().create_timer(0.5).timeout
	if projectile_scene and muzzle:
		var bullet = projectile_scene.instantiate()
		bullet.global_position = muzzle.global_position
		if player: bullet.direction = (player.global_position - global_position).normalized()
		get_tree().root.add_child(bullet)
	await sprite_anim.animation_finished
	can_attack = true
	
func enter_phase_2():
	is_transforming = true; is_phase_2 = true; velocity = Vector2.ZERO
	play_anim_safe("Turning_Orc")
	await sprite_anim.animation_finished
	update_hitbox(orc_hitbox_size)
	is_transforming = false

func play_anim_safe(anim_name):
	if sprite_anim.sprite_frames.has_animation(anim_name): sprite_anim.play(anim_name)
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
	if dialog_text: dialog_box.show(); dialog_text.text = "I am The Emperor!"; await get_tree().create_timer(2.0).timeout; dialog_box.hide()

func die():
	is_dead = true; velocity = Vector2.ZERO; if health_bar: health_bar.hide()
	if sprite_anim.sprite_frames.has_animation("Death"): sprite_anim.play("Death")
	else: sprite_anim.stop(); modulate.a = 0.5
	await get_tree().create_timer(1.0).timeout; queue_free()
