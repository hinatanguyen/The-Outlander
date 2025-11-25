extends CanvasLayer

@onready var health_fill = $UI_Container/HealthBarFrame/HealthFill

const MAX_HEALTH = 100.0 
var max_bar_width = 0.0

func _ready():
	# Capture the width immediately
	max_bar_width = health_fill.size.x
	print("HUD Ready. Max Bar Width captured: ", max_bar_width)
	
	# Wait for 1 frame to let the rest of the scene load
	await get_tree().process_frame
	
	find_and_connect_player()

func find_and_connect_player():
	var player = null
	
	# METHOD 1: Check Group "player" (Best)
	player = get_tree().get_first_node_in_group("player")
	
	# METHOD 2: Check Parent's children (Sibling check)
	if not player:
		player = get_parent().get_node_or_null("Player")
		
	# METHOD 3: Search recursively (Last Resort)
	if not player:
		player = get_tree().root.find_child("Player", true, false)

	if player:
		print("Player found! Connecting HUD.")
		# Disconnect first to avoid double-connection errors if this runs twice
		if player.health_changed.is_connected(_on_player_health_changed):
			player.health_changed.disconnect(_on_player_health_changed)
			
		player.health_changed.connect(_on_player_health_changed)
		# Initialize bar
		_on_player_health_changed(player.health)
	else:
		print("CRITICAL ERROR: Player node NOT found. HUD will not update.")
		print("Please ensure your Player node is in the scene and named 'Player'.")

func _on_player_health_changed(new_value):
	var health_percent = float(new_value) / MAX_HEALTH
	var new_width = max_bar_width * health_percent
	health_fill.size.x = new_width
	
	if new_value <= 0:
		health_fill.hide()
	else:
		health_fill.show()
