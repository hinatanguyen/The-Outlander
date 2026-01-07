extends CharacterBody2D

signal health_changed(new_value)

const SPEED = 300.0
const JUMP_VELOCITY = -650.0
const MAX_HEALTH = 100
const REGEN_DELAY = 3.0  # 3秒間ダメージを受けなければ回復開始
const REGEN_AMOUNT = 5   # 毎回の回復量
const REGEN_INTERVAL = 0.5  # 0.5秒ごとに回復

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

func _physics_process(delta):
	if is_dead: return 
	
	# 回復システムの更新
	update_health_regeneration(delta)
	
	# ダメージ中
	if is_hurt:
		if not is_on_floor():
			velocity.y += gravity * delta
		move_and_slide()
		return
	
	# 重力
	if not is_on_floor():
		velocity.y += gravity * delta
		
	# 攻撃（左クリック）
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not is_attacking:
		perform_attack()
	
	# 移動処理
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

# --- 回復システム ---
func update_health_regeneration(delta):
	# 体力が満タンなら回復不要
	if health >= MAX_HEALTH:
		is_regenerating = false
		return
	
	# 最後のダメージからの経過時間を追跡
	time_since_last_damage += delta
	
	# 一定時間ダメージを受けていない場合、回復開始
	if time_since_last_damage >= REGEN_DELAY:
		if not is_regenerating:
			is_regenerating = true
			time_since_last_regen = 0.0
		
		# 回復インターバルごとに体力を回復
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
	if is_hurt or is_dead: return
	
	health -= damage_amount
	health_changed.emit(health)
	
	# ダメージを受けたら回復タイマーをリセット
	time_since_last_damage = 0.0
	is_regenerating = false
	
	if health <= 0:
		die()
	else:
		is_hurt = true
		
		# ノックバック
		if anim.flip_h == false:
			velocity.x = -200
		else:
			velocity.x = 200
			
		anim.play("hurt")

func die():
	if is_dead:
		return 
		
	is_dead = true
	velocity.x = 0
	
	# Disable physics processing immediately
	set_physics_process(false)
	set_process(false)
	
	# プレイヤー死亡アニメーション
	anim.play("death")
	
	# コリジョンを無効化
	collision_shape.set_deferred("disabled", true)
	
	# 現在のレベルの保存
	if get_tree() and get_tree().current_scene:
		Global.current_level_path = get_tree().current_scene.scene_file_path
	
	# 死亡アニメーションの後に待機
	await get_tree().create_timer(1.5).timeout
	
	# シーン変更前に有効か確認
	if not is_instance_valid(self):
		return
	
	if not get_tree():
		return
	
	# ゲームオーバーシーンに遷移
	get_tree().call_deferred("change_scene_to_file", "res://Scene/GameOver.tscn")

func _on_animated_sprite_2d_animation_finished():
	if anim.animation == "attack":
		is_attacking = false
		anim.play("idle")
		
	elif anim.animation == "hurt":
		is_hurt = false
		anim.play("idle")

# Test damage with H key (テスト用のキーイベント)
func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_H:	
			take_damage(10)
