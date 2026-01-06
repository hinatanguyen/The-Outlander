extends Control

@onready var help_panel = $HelpPanel

func _ready():
	# 要求 1: ゲーム開始時にヘルプパネルを表示
	help_panel.visible = true

func _input(event):
	
	if event.is_action_pressed("toggle_help"):
		# ステータスを反転: 表示中 -> 非表示、非表示中 -> 表示
		help_panel.visible = !help_panel.visible
