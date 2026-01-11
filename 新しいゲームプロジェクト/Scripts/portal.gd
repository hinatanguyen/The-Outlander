extends Area2D

# 次のレベル（シーン）へのパスを指定する変数
@export var next_scene_path: String = "" 
# シーン遷移が重複して発生しないためのフラグ
var is_changing_scene: bool = false

func _ready():
	# プレイヤーの侵入を検知するシグナルを接続
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
		
	# アニメーションノードが存在する場合、再生を開始
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play("default")

# プレイヤーがポータルに接触した時の処理
func _on_body_entered(body):
	# すでに遷移中の場合は何もしない
	if is_changing_scene:
		return
		
	# 接触したオブジェクトがプレイヤーかどうかを確認
	if body.name == "Player" or body.is_in_group("player"):
		# 次のシーンが設定されていない場合は処理を中断
		if next_scene_path == "":
			return
			
		is_changing_scene = true
		# 現在のフレーム終了後にシーン変更を実行
		call_deferred("change_level")

# シーン遷移の実行処理
func change_level():
	# 指定されたシーンファイルが存在するか確認
	if not ResourceLoader.exists(next_scene_path):
		push_error("指定されたシーンが見つかりません: ", next_scene_path)
		return
	
	# 注意: get_tree().root 内の CanvasLayer を削除する古い処理は削除しました。
	# これにより、Autoload のポーズメニューが消えるのを防いでいます。
	
	# 新しいシーンへ切り替え
	get_tree().change_scene_to_file(next_scene_path)
