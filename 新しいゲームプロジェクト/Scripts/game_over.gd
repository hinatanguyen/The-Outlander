extends Control

func _ready():
	# Show mouse cursor on game over
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# Make sure game is not paused
	get_tree().paused = false

# リスタートボタンが押されたときの処理
func _on_restart_button_pressed():
	# グローバルスクリプトを使用して、保存されたレベルに戻る
	Global.restart_level()

# 終了ボタンが押されたときの処理
func _on_quit_button_pressed():
	# ゲームを終了する
	get_tree().quit()
