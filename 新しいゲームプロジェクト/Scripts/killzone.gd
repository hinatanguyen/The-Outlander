extends Area2D

# Killzoneが有効になった時に呼ばれる
func _ready():
	# 物体が入った時に接続
	body_entered.connect(_on_body_entered)

# 物体がKillzoneに入ったときの処理
func _on_body_entered(body: Node2D) -> void:
	# プレイヤーかどうか確認
	if body.name == "Player" or body.is_in_group("player"):
		# プレイヤーに die() メソッドがあれば実行
		if body.has_method("die"):
			body.die()
	else:
		# プレイヤー以外の物体が入った場合は特に何もしない
		pass
