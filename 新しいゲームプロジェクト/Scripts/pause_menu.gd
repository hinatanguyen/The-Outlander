extends CanvasLayer

@onready var volume_slider = $CenterContainer/Panel/VolumeSlider
@onready var resume_button = $CenterContainer/Panel/Button
@onready var main_menu_button = $CenterContainer/Panel/Button2

func _ready():
	hide() 
	process_mode = Node.PROCESS_MODE_ALWAYS 
	
	volume_slider.min_value = 0
	volume_slider.max_value = 100
	volume_slider.value = 50
	
	resume_button.pressed.connect(_on_resume_button_pressed)
	main_menu_button.pressed.connect(_on_main_menu_button_pressed)
	volume_slider.value_changed.connect(_on_volume_slider_value_changed)
	
	_on_volume_slider_value_changed(volume_slider.value)
	
	# シーン変更を監視し、ポーズメニューを非表示にする
	get_tree().node_added.connect(_on_scene_changed)

func _on_scene_changed(node):
	# シーンツリーのルートが変更されたとき、ポーズメニューを非表示にする
	if node == get_tree().current_scene:
		hide()
		get_tree().paused = false

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause():
	var new_pause_state = !get_tree().paused
	get_tree().paused = new_pause_state
	visible = new_pause_state
	
	if new_pause_state:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_resume_button_pressed():
	get_tree().paused = false
	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_main_menu_button_pressed():
	# シーンを変更する前にすべてをリセットする
	visible = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# 現在のフレーム後にシーン変更が行われるよう、call_deferred を使用する
	get_tree().call_deferred("change_scene_to_file", "res://Scene/MainMenu.tscn")

func _on_volume_slider_value_changed(value):
	var bus_index = AudioServer.get_bus_index("Master")
	var volume_db = linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(bus_index, volume_db)
	
	if value == 0:
		AudioServer.set_bus_mute(bus_index, true)
	else:
		AudioServer.set_bus_mute(bus_index, false)
