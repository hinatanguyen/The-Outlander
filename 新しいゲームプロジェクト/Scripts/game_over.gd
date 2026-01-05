extends Control

func _on_restart_button_pressed():
	# Use the global script to go back to the saved level
	Global.restart_level()

func _on_quit_button_pressed():
	get_tree().quit()
