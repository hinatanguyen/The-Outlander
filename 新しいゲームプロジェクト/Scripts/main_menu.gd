extends Control

@onready var start_button = $StartButton
@onready var source_button = $SourceButton
@onready var exit_button = $ExitButton

func _ready():
	# ボタンのシグナルを接続する
	start_button.pressed.connect(_on_start_pressed)
	source_button.pressed.connect(_on_source_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

func _on_start_pressed():
	# ゲームシーンに切り替える
	get_tree().change_scene_to_file("res://Scene/level1.tscn")

func _on_source_pressed():
	# ブラウザで GitHub リポジトリを開く
	OS.shell_open("https://github.com/hinatanguyen/The-Outlander")

func _on_exit_pressed():
	# ゲームを終了する
	get_tree().quit()
