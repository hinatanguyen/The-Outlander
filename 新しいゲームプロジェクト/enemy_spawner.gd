extends Node2D

@export var enemy_scene: PackedScene
@export var spawn_interval: float = 2.0
@export var max_enemies: int = 10
# 最初はスポーンしないように false に設定。インスペクターで変更も可能。
@export var is_active: bool = false 

var spawn_points: Array[Node2D] = []
var spawn_timer: float = 0.0
var current_enemy_count: int = 0

func _ready():
	# 子ノードの Marker2D をスポーン地点として収集
	for child in get_children():
		if child is Marker2D:
			spawn_points.append(child)

func _process(delta):
	# アクティブでない場合は処理を中断（タイマーも進めない）
	if not is_active:
		return

	if not enemy_scene or spawn_points.is_empty():
		return
	
	spawn_timer += delta
	
	if spawn_timer >= spawn_interval and current_enemy_count < max_enemies:
		spawn_enemy()
		spawn_timer = 0.0

func spawn_enemy():
	# ランダムなスポーン地点を選択
	var spawn_point = spawn_points[randi() % spawn_points.size()]
	
	# 敵インスタンスを生成
	var enemy = enemy_scene.instantiate()
	enemy.global_position = spawn_point.global_position
	
	# 背景より前面に描画されるよう設定
	enemy.z_index = 5
	
	# シーンに追加
	get_parent().add_child(enemy)
	
	# 敵が消えた時のシグナルに接続して数を管理する
	if enemy.has_signal("tree_exited"):
		enemy.tree_exited.connect(_on_enemy_died)
	
	current_enemy_count += 1

func _on_enemy_died():
	current_enemy_count -= 1

# トリガーエリアからこの関数を呼び出してスポーンを開始させる
func activate_spawner():
	is_active = true
