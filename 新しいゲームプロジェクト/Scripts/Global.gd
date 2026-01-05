extends Node

# This variable will hold the path to the level the player is currently in
var current_level_path : String = ""

func restart_level():
	if current_level_path != "":
		get_tree().change_scene_to_file(current_level_path)
