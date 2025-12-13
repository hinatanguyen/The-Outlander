extends Control

@onready var help_panel = $HelpPanel

func _ready():
	# YÊU CẦU 1: Hiện bảng ngay khi game bắt đầu
	help_panel.visible = true
	
	# Mẹo: Nếu bạn muốn game tạm dừng khi mới vào để người chơi đọc, bỏ dấu # ở dòng dưới:
	# get_tree().paused = true

func _input(event):
	# YÊU CẦU 2: Bắt sự kiện phím bấm (Keybind)
	if event.is_action_pressed("toggle_help"):
		# Đảo ngược trạng thái: Đang hiện -> Ẩn, Đang ẩn -> Hiện
		help_panel.visible = !help_panel.visible
		
		# (Tùy chọn) Xử lý Pause game nếu muốn
		# get_tree().paused = help_panel.visible
