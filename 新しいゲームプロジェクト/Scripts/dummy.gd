extends CharacterBody2D

# 重力の強さ
const GRAVITY = 900.0

@onready var anim = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D
@onready var hurtbox = $Hurtbox

# 体力
var health = 10
# 死亡しているかどうか
var is_dead = false
# ダメージを受けている最中かどうか
var is_hurt = false

func _ready():
	# 初期状態ではアイドルアニメーションを再生
	anim.play("idle")

func _physics_process(delta):
	if is_dead:
		return
	
	# 重力を適用
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	
	# ダメージ中は動かない
	if is_hurt:
		velocity.x = 0
		move_and_slide()
		return
	
	# ダミーは移動せず、その場で待機
	velocity.x = 0
	if not is_hurt:
		anim.play("idle")
	
	move_and_slide()

# --- ダ
