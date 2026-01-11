extends CharacterBody2D

# ==========================================
#                 CẤU HÌNH (CONFIG)
# ==========================================
@export_group("Stats")
@export var max_hp: int = 1000
@export var move_speed: float = 120.0
@export var speed_phase_2: float = 90.0

@export_group("Damage Values")
@export var damage_punch: int = 30
@export var damage_ultimate: int = 80
@export var damage_bullet: int = 50

@export_group("Phase 2 Settings")
@export var orc_hitbox_size: Vector2 = Vector2(60, 100)
@export var projectile_scene: PackedScene 

# ==========================================
#                 BIẾN (VARIABLES)
# ==========================================
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var current_hp: int
var player = null # Biến chứa thông tin người chơi
var is_dead = false
var can_attack = true

# Trạng thái Phase
var is_phase_2 = false
var is_transforming = false

# UI
@onready var dialog_box = get_node_or_null("CanvasLayer/DialogPanel")
@onready var dialog_text = get_node_or_null("CanvasLayer/DialogPanel/Label")

# Node con
@onready var sprite_anim = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D
@onready var muzzle = $Muzzle 

# ==========================================
#                 MAIN LOOP
# ==========================================
func _ready():
	add_to_group("enemy")
	current_hp = max_hp
	
	# --- CÁCH TÌM PLAYER MỚI (CHỐNG LỖI) ---
	find_player_automatically()
	
	# Xử lý UI
	if dialog_box:
		dialog_box.hide()
		start_intro_dialogue()
	else:
		print("--- SKIP INTRO: Không thấy UI ---")
	
	play_anim_safe("Motion_animations_1_Spritelist")

func _physics_process(delta):
	# 1. TRỌNG LỰC (Luôn chạy)
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Nếu đang chết hoặc biến hình thì dừng di chuyển ngang
	if is_dead or is_transforming:
		velocity.x = move_toward(velocity.x, 0, 10)
		move_and_slide()
		return

	# 2. TÌM LẠI PLAYER NẾU BỊ MẤT
	if player == null:
		find_player_automatically()
		velocity.x = 0 # Đứng yên chờ tìm thấy player
		move_and_slide()
		return

	# 3. LOGIC DI CHUYỂN & TẤN CÔNG
	# Tính khoảng cách
	var distance = global_position.distance_to(player.global_position)
	# Tính hướng: -1 là bên trái, 1 là bên phải
	var direction_x = sign(player.global_position.x - global_position.x)
	
	# Quay mặt Sprite
	if direction_x != 0:
		update_facing_direction(direction_x)

	# Chạy AI theo Phase
	if is_phase_2:
		ai_phase_2(distance, direction_x)
	else:
		ai_phase_1(distance, direction_x)
	
	# QUAN TRỌNG: Lệnh này giúp nhân vật thực sự di chuyển
	move_and_slide()

# ==========================================
#              HÀM TÌM NGƯỜI CHƠI (MỚI)
# ==========================================
func find_player_automatically():
	# Cách 1: Tìm trong nhóm "player" (Khuyên dùng)
	var players_in_group = get_tree().get_nodes_in_group("player")
	if players_in_group.size() > 0:
		player = players_in_group[0]
		print("✅ Đã tìm thấy Player qua Group!")
		return

	# Cách 2: Tìm theo tên (Dự phòng)
	if get_parent().has_node("Player"):
		player = get_parent().get_node("Player")
		print("✅ Đã tìm thấy Player theo tên Node!")
		return
		
	# Nếu vẫn không thấy
	print("❌ Vẫn chưa thấy Player đâu cả. Boss sẽ đứng yên.")

# ==========================================
#              LOGIC CHIẾN ĐẤU
# ==========================================

func ai_phase_1(dist, dir_x):
	if not can_attack: 
		velocity.x = 0
		return

	if dist > 60: # Nếu xa hơn 60px -> CHẠY TỚI
		velocity.x = dir_x * move_speed
		play_anim_safe("Motion_animations_1_Spritelist")
	else: # Nếu gần -> ĐÁNH
		velocity.x = 0
		perform_melee_attack("Punch_1", damage_punch)

func ai_phase_2(dist, dir_x):
	if not can_attack: 
		velocity.x = 0
		return

	# Phase 2: Orc to lớn
	# 1. Bắn xa nếu khoảng cách > 300px (Tỉ lệ ngẫu nhiên)
	if dist > 300 and randf() < 0.02:
		perform_ranged_attack()
		return

	# 2. Đuổi theo
	if dist > 100:
		velocity.x = dir_x * speed_phase_2
		# Tạm dùng anim chạy của người (vì bạn chưa có anim Orc Run)
		play_anim_safe("Motion_animations_1_Spritelist") 
		modulate = Color(1.5, 0.5, 0.5) # Đỏ rực báo hiệu Phase 2
	else:
		velocity.x = 0
		perform_melee_attack("Punch_1", damage_punch * 2) # Đấm đau gấp đôi

# ==========================================
#              HÀNH ĐỘNG (ACTIONS)
# ==========================================

func perform_melee_attack(anim_name, damage):
	if not can_attack: return
	can_attack = false
	velocity.x = 0 # Dừng lại để đấm
	
	play_anim_safe(anim_name)
	
	# Đợi anim chạy hết rồi mới gây damage và cho phép đi tiếp
	await sprite_anim.animation_finished
	
	if player and global_position.distance_to(player.global_position) < 120:
		if player.has_method("take_damage"):
			player.take_damage(damage)
	
	# Nghỉ 0.5s giữa các cú đấm
	await get_tree().create_timer(0.5).timeout
	can_attack = true

func perform_ranged_attack():
	can_attack = false
	velocity.x = 0
	
	print("--- BOSS SỬ DỤNG CHIÊU CUỐI ---")
	play_anim_safe("Explosive_Strike")
	
	# Đợi gồng 0.5 giây
	await get_tree().create_timer(0.5).timeout
	
	if projectile_scene and muzzle:
		var bullet = projectile_scene.instantiate()
		bullet.global_position = muzzle.global_position
		# Bắn về phía Player
		if player:
			bullet.direction = (player.global_position - global_position).normalized()
		get_tree().root.add_child(bullet)
		
	await sprite_anim.animation_finished
	can_attack = true

# ==========================================
#              PHASE TRANSITION (BIẾN HÌNH)
# ==========================================

func take_damage(amount):
	if is_dead or is_transforming: return
	current_hp -= amount
	
	# Chuyển Phase khi máu dưới 50%
	if not is_phase_2 and current_hp <= max_hp / 2.0:
		enter_phase_2()
		return

	if current_hp <= 0:
		die()

func enter_phase_2():
	is_transforming = true
	is_phase_2 = true
	velocity = Vector2.ZERO
	
	play_anim_safe("Turning_Orc")
	
	await sprite_anim.animation_finished
	
	# Cập nhật Hitbox to hơn
	update_hitbox(orc_hitbox_size)
	is_transforming = false
	print("--- BOSS: TRANSFORM COMPLETE ---")

# ==========================================
#              HÀM HỖ TRỢ (UTILS)
# ==========================================

func update_facing_direction(dir_x):
	if dir_x < 0:
		sprite_anim.flip_h = true
		if muzzle: muzzle.position.x = -abs(muzzle.position.x)
	elif dir_x > 0:
		sprite_anim.flip_h = false
		if muzzle: muzzle.position.x = abs(muzzle.position.x)

func play_anim_safe(anim_name):
	if sprite_anim.sprite_frames.has_animation(anim_name):
		sprite_anim.play(anim_name)
	else:
		# Fallback nếu thiếu anim
		sprite_anim.play("Motion_animations_1_Spritelist")

func update_hitbox(size_vec):
	if collision_shape.shape is RectangleShape2D:
		collision_shape.shape.size = size_vec
		collision_shape.position.y = -size_vec.y / 2

func start_intro_dialogue():
	if dialog_text:
		dialog_box.show()
		dialog_text.text = "I am The Emperor!"
		await get_tree().create_timer(2.0).timeout
		dialog_box.hide()

func die():
	is_dead = true
	velocity = Vector2.ZERO
	if sprite_anim.sprite_frames.has_animation("Death"):
		sprite_anim.play("Death")
	else:
		sprite_anim.stop()
		modulate.a = 0.5
	await get_tree().create_timer(1.0).timeout
	queue_free()
