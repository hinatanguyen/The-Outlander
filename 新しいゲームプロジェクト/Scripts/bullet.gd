extends Area2D

var speed = 300
var direction = 1 # 右が1、左が-1
var lifetime = 0.8 # 秒数を設定（お好みで調整）

# [NEW] Damage value for the Boss
var damage_amount = 20 

func _ready():
	add_to_group("player_projectile")
	# アニメーションを再生開始
	$AnimatedSprite2D.play()
	
	# タイマーを作成して設定
	var timer = Timer.new()
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.connect("timeout", Callable(self, "_on_lifetime_timeout"))
	add_child(timer)
	timer.start()

func _physics_process(delta):
	global_position.x += speed * direction * delta

func _on_lifetime_timeout():
	queue_free()

func _on_body_entered(body):
	# Player は無視する
	if body.name == "Player" or body.is_in_group("player"):
		return
	
	# [NEW] START: Logic to handle Boss damage without breaking normal levels
	if body.is_in_group("enemy"):
		# [NEW] Check if the enemy is the Boss (has specific HP logic)
		if body.has_method("take_damage"):
			body.take_damage(damage_amount)
		# [NEW] If it's a normal mob (no take_damage method), it skips this and just runs queue_free() below
	# [NEW] END: Logic added
	
	# 壁、床、その他の物体に当たったら弾を削除
	queue_free()

func _on_area_entered(area):
	# 敵のヒットボックスに当たった場合
	if area.name == "Hurtbox" or area.is_in_group("enemy"):
		# 敵側のスクリプトがダメージ処理と弾の削除を行う
		pass

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
