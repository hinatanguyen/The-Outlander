extends CharacterBody2D

signal health_changed(new_value)

const SPEED = 300.0
const JUMP_VELOCITY = -650.0
const MAX_HEALTH = 100
const REGEN_DELAY = 3.0  # 3秒間ダメージを受けなければ回復開始
const REGEN_AMOUNT = 5   # 毎回の回復量
const REGEN_INTERVAL = 0.5  # 0.5秒ごとに回復
const FRICTION = 1000.0 

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var anim = $AnimatedSprite2D
@onready var sprite = $AnimatedSprite2D 
@onready var collision_shape = $CollisionShape2D
@onready var muzzle = $Muzzle

@export var bullet_scene : PackedScene

var is_attacking = false
var is_hurt = false
var is_dead = false
var health = 100

# 回復システム用の変数
var time_since_last_damage = 0.0
var time_since_last_regen = 0.0
var is_regenerating = false

func _ready():
	add_to_group("player")

func _physics_process(delta):
	if is_dead: return 
	
	# 回復システムの更新
	update_health_regeneration(delta)
	
	# [FIX] XỬ LÝ KHI BỊ ĐAU (HURT) - ƯU TIÊN SỐ 1
	if is_hurt:
		# Áp dụng trọng lực
		if not is_on_floor():
			velocity.y += gravity * delta
		
		# [FIX] Không cho phép điều khiển hay tấn công khi đang bị đẩy lùi
		move_and_slide()
		
		# [FIX] Nếu chạm đất thì cho phép điều khiển lại ngay để tránh cảm giác bị mất lái lâu
		if is_on_floor() and velocity.y >= 0:
			# Có thể thêm delay nhỏ ở đây nếu muốn, nhưng để mượt thì cho phép luôn
			pass 
			
		return # Dừng hàm tại đây, bỏ qua mọi logic bên dưới
	
	# Trọng lực (Khi bình thường)
	if not is_on_floor():
		velocity.y += gravity * delta
		
	# [FIX] TẤN CÔNG (Chỉ khi không bị đau)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not is_attacking and not is_hurt:
		perform_attack()
	
	# DI CHUYỂN (Chỉ khi không tấn công và không bị đau)
	if not is_attacking and not is_hurt:
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

# --- 回復システム ---
func update_health_regeneration(delta):
	if health >= MAX_HEALTH:
		is_regenerating = false
		return
	
	time_since_last_damage += delta
	
	if time_since_last_damage >= REGEN_DELAY:
		if not is_regenerating:
			is_regenerating = true
			time_since_last_regen = 0.0
		
		time_since_last_regen += delta
		if time_since_last_regen >= REGEN_INTERVAL:
			regenerate_health()
			time_since_last_regen = 0.0

func regenerate_health():
	if health < MAX_HEALTH:
		health = min(health + REGEN_AMOUNT, MAX_HEALTH)
		health_changed.emit(health)

# --- 行動処理 ---
func perform_attack():
	is_attacking = true
	if is_on_floor():
		velocity.x = 0		
	anim.play("attack")
	shoot()

func shoot():
	if bullet_scene:	
		var bullet = bullet_scene.instantiate()
		if sprite.flip_h == true:
			bullet.direction = -1
		else:
			bullet.direction = 1
		get_tree().current_scene.add_child(bullet)
		bullet.global_position = muzzle.global_position

# --- ダメージ処理 ---
func take_damage(damage_amount):
	if is_dead: return # Bỏ qua check is_hurt ở đây để cho phép bị đánh liên tục (stunlock) hoặc reset timer
	
	# [FIX] Nếu đang tấn công mà bị đánh -> Hủy tấn công ngay lập tức
	if is_attacking:
		is_attacking = false
	
	health -= damage_amount
	health_changed.emit(health)
	
	time_since_last_damage = 0.0
	is_regenerating = false
	
	if health <= 0:
		die()
	else:
		is_hurt = true
		
		# [FIX] Đẩy nhẹ lên trên để tránh kẹt chân vào sàn
		velocity.y = -200 
		
		# Đẩy lùi
		if anim.flip_h == false:
			velocity.x = -300
		else:
			velocity.x = 300
			
		anim.play("hurt")
		
		# [FIX QUAN TRỌNG - SAFETY TIMER]
		# Tự động hết bị đau sau 0.4 giây dù animation có lỗi hay không
		# Giúp nhân vật KHÔNG BAO GIỜ BỊ KẸT VĨNH VIỄN khi va chạm với Boss
		# Dùng biến tạm để tránh xung đột timer nếu bị đánh liên tục
		var timer = get_tree().create_timer(0.4)
		await timer.timeout
		# Chỉ reset nếu nhân vật vẫn còn sống
		if not is_dead:
			is_hurt = false
			velocity.x = 0 # Dừng trượt

func die():
	if is_dead: return
		
	is_dead = true
	velocity.x = 0
	
	set_physics_process(false)
	set_process(false)
	
	anim.play("death")
	collision_shape.set_deferred("disabled", true)
	
	if get_tree() and get_tree().current_scene:
		Global.current_level_path = get_tree().current_scene.scene_file_path
	
	await get_tree().create_timer(1.5).timeout
	
	if not is_instance_valid(self): return
	if not get_tree(): return
	
	get_tree().call_deferred("change_scene_to_file", "res://Scene/GameOver.tscn")

func _on_animated_sprite_2d_animation_finished():
	if anim.animation == "attack":
		is_attacking = false
		if not is_hurt: # Chỉ về idle nếu không đang bị đau
			anim.play("idle")
		
	elif anim.animation == "hurt":
		is_hurt = false
		if not is_attacking:
			anim.play("idle")

# Test damage with H key
func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_H:	
			take_damage(10)
