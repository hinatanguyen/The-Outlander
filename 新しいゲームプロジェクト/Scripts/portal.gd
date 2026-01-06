extends Area2D

# 次のシーンのパスを設定（レベルを柔軟に変更できるようにする）
@export var next_scene_path: String = "" 
var is_changing_scene: bool = false

func _ready():
	# シグナルが接続されていない場合に接続
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
		
	# アニメーションがある場合、デフォルトのアニメーションを再生
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play("default")

# プレイヤーがポータルに入ったときにシーンを変更する処理
func _on_body_entered(body):
	if is_changing_scene:
		return
		
	if body.name == "Player" or body.is_in_group("player"):
		# 次のシーンのパスが設定されていない場合、警告
		if next_scene_path == "":
			print("警告: 次のシーンのパスが設定されていません！")
			return
			
		is_changing_scene = true
		print("次のレベルに進む: ", next_scene_path)
		call_deferred("change_level")

# シーン変更の処理
func change_level():
	# シーンファイルが存在するか確認
	if not ResourceLoader.exists(next_scene_path):
		push_error("シーンが存在しません: ", next_scene_path)
		return
	
	# 永続的なオブジェクトのクリーンアップ
	cleanup_persistent_objects()
	# 新しいシーンに変更
	get_tree().change_scene_to_file(next_scene_path)

# トランジションUIなどの永続的なオブジェクトをクリーンアップ
func cleanup_persistent_objects():
	# CanvasLayer ノードをターゲットにしてクリーンアップ
	for child in get_tree().root.get_children():
		if child is CanvasLayer:
			child.queue_free()
