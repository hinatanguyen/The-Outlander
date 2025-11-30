extends CanvasLayer

@onready var health_fill = $UI_Container/HealthBarFrame/HealthFill

const MAX_HEALTH = 100.0 
var max_bar_width = 0.0

func _ready():
	# バーの最大幅を記録
	max_bar_width = health_fill.size.x
	print("HUD Ready. Max Bar Width captured: ", max_bar_width)
	
	# 1 フレーム待ち、シーンのロードを完了させる
	await get_tree().process_frame
	
	find_and_connect_player()

func find_and_connect_player():
	var player = null
	
	# 方法1: "player" グループから検索（推奨）
	player = get_tree().get_first_node_in_group("player")
	
	# 方法2: 親の子ノードから検索
	if not player:
		player = get_parent().get_node_or_null("Player")
		
	# 方法3: 再帰的に検索（最終手段）
	if not player:
		player = get_tree().root.find_child("Player", true, false)

	if player:
		print("Player 発見！HUD に接続します。")
		# 二重接続を避けるため、一度切断する
		if player.health_changed.is_connected(_on_player_health_changed):
			player.health_changed.disconnect(_on_player_health_changed)
			
		player.health_changed.connect(_on_player_health_changed)
		# 初期バー更新
		_on_player_health_changed(player.health)
	else:
		print("重大エラー: Player ノードが見つかりません。HUD は更新されません。")
		print("Player ノードの名前が 'Player' になっているか確認してください。")

func _on_player_health_changed(new_value):
	var health_percent = float(new_value) / MAX_HEALTH
	var new_width = max_bar_width * health_percent
	health_fill.size.x = new_width
	
	if new_value <= 0:
		health_fill.hide()
	else:
		health_fill.show()
