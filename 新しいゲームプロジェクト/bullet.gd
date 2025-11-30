extends Area2D

var speed = 600
var direction = 1 # 右が1、左が-1

func _physics_process(delta):
	global_position.x += speed * direction * delta

func _on_body_entered(body):
	# Player は無視する
	if body.name == "Player":
		return
	
	# 壁、床、その他の物体に当たったら弾を削除
	queue_free()

func _on_area_entered(area):
	# 敵のヒットボックスに当たった場合
	if area.name == "Hurtbox" or area.is_in_group("enemy"):
		# 敵側のスクリプトがダメージ処理と弾の削除を行う
		pass

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
