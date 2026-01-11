extends Area2D

# 次のシーンのパスを設定
@export var next_scene_path: String = "" 
var is_changing_scene: bool = false

func _ready():
	# シグナルが接続されていない場合に接続
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
		
	# アニメーションがある場合、デフォルトのアニメーションを再生
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play("default")

# プレイヤーがポータルに入ったときの処理
func _on_body_entered(body):
	if is_changing_scene:
		return
		
	if body.name == "Player" or body.is_in_group("player"):
		# パスが空の場合は警告
		if next_scene_path == "":
			print("警告: 次のシーンのパスが設定されていません！")
			return
			
		is_changing_scene = true
		# 遅延実行でシーン切り替え
		call_deferred("change_level")

# シーン変更の実行
func change_level():
	if not ResourceLoader.exists(next_scene_path):
		push_error("シーンが存在しません: ", next_scene_path)
		return
	
	# 注意: ここにあった CanvasLayer を削除するループは、
	# Autoload のポーズメニューまで消してしまうため削除しました。
	
	get_tree().change_scene_to_file(next_scene_path)
