extends CanvasLayer

@onready var volume_slider = $CenterContainer/Panel/VolumeSlider
@onready var resume_button = $CenterContainer/Panel/Button
@onready var main_menu_button = $CenterContainer/Panel/Button2

func _ready():
	# 他のUI（HUDなど）より前面に表示するためにレイヤーを設定
	layer = 128
	# 初期状態は非表示
	hide()
	# ポーズ中もこのスクリプトが動作するように設定
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# 各ボタンとスライダーのシグナル接続
	resume_button.pressed.connect(_on_resume_button_pressed)
	main_menu_button.pressed.connect(_on_main_menu_button_pressed)
	volume_slider.value_changed.connect(_on_volume_slider_value_changed)
	
	# ボリュームの初期化
	_on_volume_slider_value_changed(volume_slider.value)

func _input(event):
	# ESCキー（ui_cancel）が押されたらポータル状態を切り替え
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause():
	# ゲームの停止状態を反転
	var new_pause_state = !get_tree().paused
	get_tree().paused = new_pause_state
	# メニューの表示・非表示を切り替え
	visible = new_pause_state
	
	if new_pause_state:
		# マウスカーソルを表示し、ボタンにフォーカスを当てる
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		resume_button.grab_focus()
	else:
		# ゲームに戻る時はカーソルをキャプチャ（非表示）にする
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_resume_button_pressed():
	# ゲームを再開
	get_tree().paused = false
	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_main_menu_button_pressed():
	# メインメニューに戻る前に必ずポーズを解除
	get_tree().paused = false
	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# 安全にメインメニューシーンへ遷移
	get_tree().call_deferred("change_scene_to_file", "res://Scene/MainMenu.tscn")

func _on_volume_slider_value_changed(value):
	# マスター音量の調整
	var bus_index = AudioServer.get_bus_index("Master")
	var volume_db = linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(bus_index, volume_db)
	
	# 音量が0ならミュートにする
	if value == 0:
		AudioServer.set_bus_mute(bus_index, true)
	else:
		AudioServer.set_bus_mute(bus_index, false)
