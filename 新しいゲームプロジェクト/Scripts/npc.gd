extends CharacterBody2D

var player = null
var player_in_range = false
var dialogue_active = false
var dialogue_timer = 0.0

var dialogue_bubble = null
var dialogue_label = null
var prompt_label = null

const INTERACTION_RANGE = 150.0
const DEFAULT_DIALOGUE_TEXT = "Hello adventurer, please defeat\nthe orcs to reach the next level."
const DIALOGUE_DURATION = 6.0

# Export variable to allow custom dialogue per level
@export var custom_dialogue_text: String = ""

func _ready():
	print("=== NPC Script Starting ===")
	
	# Find UI elements by exact path
	dialogue_bubble = get_node_or_null("DialogueBubble")
	prompt_label = get_node_or_null("PromptLabel")
	
	if dialogue_bubble:
		dialogue_label = dialogue_bubble.get_node_or_null("Label")
		print("Found DialogueBubble")
		if dialogue_label:
			print("Found DialogueBubble/Label")
		dialogue_bubble.visible = false
	else:
		print("ERROR: DialogueBubble not found!")
	
	if prompt_label:
		print("Found PromptLabel")
		prompt_label.visible = false
	else:
		print("ERROR: PromptLabel not found!")
	
	# Find player
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		print("Found player: ", player.name, " at position ", player.global_position)
	else:
		print("ERROR: No player found in 'player' group!")
	
	# Verify interact action
	if InputMap.has_action("interact"):
		print("'interact' action found in InputMap")
	else:
		print("WARNING: 'interact' action NOT in InputMap")
	
	add_to_group("npc")
	print("NPC ready. Position: ", global_position)
	print("=== NPC Script Ready ===\n")

func _process(delta):
	if player == null:
		return
	
	var distance = global_position.distance_to(player.global_position)
	player_in_range = distance < INTERACTION_RANGE
	
	# Show/hide prompt
	if prompt_label:
		if player_in_range and not dialogue_active:
			prompt_label.visible = true
		else:
			prompt_label.visible = false
	
	# Auto-close dialogue after 9 seconds
	if dialogue_active:
		dialogue_timer += delta
		if dialogue_timer >= DIALOGUE_DURATION:
			hide_dialogue_box()
	
	# Check E key
	if player_in_range:
		if InputMap.has_action("interact") and Input.is_action_just_pressed("interact"):
			print("E pressed via 'interact' action!")
			if not dialogue_active:
				show_dialogue_box()
			else:
				hide_dialogue_box()
	
	# Close dialogue with ESC
	if dialogue_active and Input.is_action_just_pressed("ui_cancel"):
		print("ESC pressed - closing dialogue")
		hide_dialogue_box()

func _unhandled_input(event):
	# Handle ESC in unhandled input to catch it after pause menu
	if dialogue_active and event.is_action_pressed("ui_cancel"):
		print("ESC detected in unhandled_input")
		hide_dialogue_box()
		get_tree().root.set_input_as_handled()

func show_dialogue_box():
	print("Showing dialogue box...")
	dialogue_active = true
	dialogue_timer = 0.0  # Reset timer when showing
	
	if dialogue_bubble and dialogue_label:
		# Use custom text if set, otherwise use default
		var text_to_show = custom_dialogue_text if custom_dialogue_text != "" else DEFAULT_DIALOGUE_TEXT
		dialogue_label.text = text_to_show
		dialogue_bubble.visible = true
		print("Dialogue box shown with text: ", text_to_show)
		print("Will auto-close in ", DIALOGUE_DURATION, " seconds")
	else:
		print("ERROR: Cannot show dialogue - bubble or label is null!")

func hide_dialogue_box():
	print("Hiding dialogue box...")
	dialogue_active = false
	
	if dialogue_bubble:
		dialogue_bubble.visible = false
		print("Dialogue box hidden!")
