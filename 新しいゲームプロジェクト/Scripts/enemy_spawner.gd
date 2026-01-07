extends Node2D

@export_group("Enemy 設定")
@export var enemy_scene: PackedScene
@export var spawn_interval: float = 2.0
@export var max_enemies: int = 40 # 画面上に同時に存在できる最大数
@export var total_spawns_limit: int = 10 # この数までスポーンしたら停止

@export_group("状態")
@export var is_active: bool = false 

# スポーン地点の配列
var spawn_points: Array[Node2D] = []
# スポーン間隔管理用タイマー
var spawn_timer: float = 0.0
# 現在存在している敵の数
var current_enemy_count: int = 0
# これまでにスポーンした敵の総数
var total_spawned: int = 0 

# レベル管理ノードへの参照
var level_manager: Node = null 

func _ready():
	# 子ノードの Marker2D をすべてスポーン地点として収集
	for child in get_children():
		if child is Marker2D:
			spawn_points.append(child)
	
	# 現在のシーン内から LevelManager を検索
	# ルート全体を探さないことで、前のシーンの LevelManager を誤取得するのを防ぐ
	level_manager = get_tree().current_scene.find_child("LevelManager", true, false)
	
	if not level_manager:
		push_warning("現在のシーンに LevelManager が見つかりません。ノード名を確認してください。")

func _process(delta):
	if not is_active:
		return
	
	# 総スポーン数の上限に達したら停止
	if total_spawned >= total_spawns_limit:
		is_active = false 
		return
	
	# 敵シーンまたはスポーン地点がない場合は何もしない
	if not enemy_scene or spawn_points.is_empty():
		return
	
	spawn_timer += delta
	
	# 一定時間経過し、かつ画面上の敵数が上限未満のときのみスポーン
	if spawn_timer >= spawn_interval and current_enemy_count < max_enemies:
		spawn_enemy()
		spawn_timer = 0.0

func spawn_enemy():
	# ランダムなスポーン地点を選択
	var spawn_point = spawn_points[randi() % spawn_points.size()]
	
	# 敵を生成
	var enemy = enemy_scene.instantiate()
	enemy.global_position = spawn_point.global_position
	enemy.z_index = 5
	
	# シーンに追加（process/physics 中でも安全）
	get_tree().current_scene.add_child(enemy)
	
	# 敵が削除されたときにカウントを減らすための接続
	if enemy.has_signal("tree_exited"):
		enemy.tree_exited.connect(_on_enemy_died)
	
	# LevelManager に敵を登録（撃破数カウント用）
	if is_instance_valid(level_manager) and level_manager.has_method("register_enemy"):
		level_manager.register_enemy(enemy)
	
	current_enemy_count += 1
	total_spawned += 1

func _on_enemy_died():
	# 敵がシーンから消えたら現在数を減らす
	current_enemy_count -= 1

func activate_spawner():
	# スポーナーを有効化
	is_active = true
