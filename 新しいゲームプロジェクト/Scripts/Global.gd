extends Node

# この変数は、現在プレイヤーがいるレベルのパスを保持します
var current_level_path : String = ""

# レベルをリスタートする関数
func restart_level():
	# 現在のレベルパスが空でない場合、シーンを再読み込みする
	if current_level_path != "":
		get_tree().change_scene_to_file(current_level_path)
