extends Node

@export_group("Level Settings")
@export var next_level_path: String = "res://Scene/level3.tscn"
@export var enemies_to_defeat: int = 20

@export_group("Portal Settings")
@export var portal_scene: PackedScene
@export var portal_spawn_marker: Marker2D
@export var portal_spawn_position: Vector2 = Vector2(800, 200)

var enemies_defeated: int = 0
var level_complete: bool = false
var spawners: Array[Node] = []

signal level_completed
signal enemy_defeated(count: int)

func _ready():
	# スポーナーを取得
	spawners = get_tree().get_nodes_in_group("spawners")
	
	# すでにシーン内にいる敵を自動的に登録
	for enemy in get_tree().get_nodes_in_group("enemy"):
		register_enemy(enemy)

func register_enemy(enemy: Node):
	# 敵が"tree_exited"シグナルに接続されていない場合、接続する
	if not enemy.is_connected("tree_exited", _on_enemy_killed):
		enemy.tree_exited.connect(_on_enemy_killed)

func _on_enemy_killed():
	# ツリーが存在しない場合は処理を中止
	if not get_tree():
		return
		
	if level_complete: 
		return
	
	# プレイヤーが死亡しているか確認
	var players = get_tree().get_nodes_in_group("player")
	for player in players:
		if is_instance_valid(player) and player.get("is_dead") == true:
			return
	
	enemies_defeated += 1
	emit_signal("enemy_defeated", enemies_defeated)
	
	if enemies_defeated >= enemies_to_defeat:
		complete_level()

func complete_level():
	# ツリーが存在しない場合は処理を中止
	if not get_tree():
		return
		
	if level_complete:
		return
	
	# プレイヤーが死亡しているか確認
	var players = get_tree().get_nodes_in_group("player")
	for player in players:
		if is_instance_valid(player) and player.get("is_dead") == true:
			return
	
	level_complete = true
	
	# スポーナーを停止
	if get_tree():
		var all_spawners = get_tree().get_nodes_in_group("spawners")
		for spawner in all_spawners:
			if is_instance_valid(spawner):
				spawner.is_active = false
				if spawner.has_method("set_process"):
					spawner.set_process(false)
	
	# 残りの敵を倒す
	if get_tree():
		var remaining_enemies = get_tree().get_nodes_in_group("enemy")
		for enemy in remaining_enemies:
			if is_instance_valid(enemy) and enemy.has_method("die"):
				enemy.die()
	
	show_completion_notification()
	
	# ポータルを出現させる前に待機
	await get_tree().create_timer(1.0).timeout
	
	# ツリーが存在しない場合は処理を中止
	if not get_tree():
		return
	
	# プレイヤーがまだ生きているか確認
	for player in get_tree().get_nodes_in_group("player"):
		if is_instance_valid(player) and player.get("is_dead") == true:
			return
	
	spawn_portal()
	emit_signal("level_completed")

func spawn_portal():
	# ポータルのシーンが設定されていない場合、処理を中止
	if not portal_scene: 
		return
	
	# ツリーまたはシーンが存在しない場合、処理を中止
	if not get_tree() or not get_tree().current_scene:
		return
	
	var portal = portal_scene.instantiate()
	
	# ポータルに次のレベルのパスを渡す
	if portal.get("next_scene_path") != null:
		portal.next_scene_path = next_level_path
	
	var current_scene = get_tree().current_scene
	current_scene.add_child(portal)
	
	# ポータルの出現位置を設定
	if portal_spawn_marker and is_instance_valid(portal_spawn_marker):
		portal.global_position = portal_spawn_marker.global_position
	else:
		portal.global_position = portal_spawn_position

func show_completion_notification():
	# ツリーまたはシーンが存在しない場合、処理を中止
	if not get_tree() or not get_tree().current_scene:
		return
	
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	get_tree().current_scene.add_child(canvas_layer)
	
	var label = Label.new()
	label.text = "LEVEL CLEARED"
	
	var settings = LabelSettings.new()
	settings.font_size = 80
	settings.font_color = Color.GOLD
	settings.outline_size = 10
	settings.outline_color = Color.BLACK
	label.label_settings = settings
	
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	
	canvas_layer.add_child(label)
	
	# アニメーション
	label.scale = Vector2(0.1, 0.1)
	label.pivot_offset = label.size / 2
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2.ONE, 0.5)
	
	# 2秒後にフェードアウト
	await get_tree().create_timer(2.0).timeout
	
	if is_instance_valid(canvas_layer):
		var fade = create_tween()
		fade.tween_property(canvas_layer, "modulate:a", 0.0, 0.5)
		fade.tween_callback(canvas_layer.queue_free)
