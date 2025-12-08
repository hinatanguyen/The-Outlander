extends CharacterBody2D

signal health_changed(new_value)

const SPEED = 300.0
const JUMP_VELOCITY = -650.0
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

func _physics_process(delta):
	if is_dead: return 
	
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
		
# --- ダメージ処理（更新版） ---

# Orc が送ってくるダメージ量（1）を受け取れるようにした
func take_damage(damage_amount):
	if is_hurt or is_dead: return
	
	health -= damage_amount
	health_changed.emit(health)
	
	if health <= 0:
		die()
	else:
		is_hurt = true
		
		# ノックバック（攻撃を受けた方向と逆に吹っ飛ぶ）
		if anim.flip_h == false:
			velocity.x = -200 # 左へ吹っ飛び
		else:
			velocity.x = 200  # 右へ吹っ飛び
			
		anim.play("hurt")

func die():
	is_dead = true
	velocity.x = 0
	anim.play("death")
	collision_shape.set_deferred("disabled", true)
	
	# 1.5 秒待って死亡アニメを再生
	await get_tree().create_timer(1.5).timeout
	
	# Game Over シーンへ移動
	get_tree().change_scene_to_file("res://GameOver.tscn")

func _on_animated_sprite_2d_animation_finished():
	if anim.animation == "attack":
		is_attacking = false
		anim.play("idle")
		
	elif anim.animation == "hurt":
		is_hurt = false
		anim.play("idle")

# KEY_H を押したときのテストダメージ（10）
func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_H:	
			take_damage(10)
