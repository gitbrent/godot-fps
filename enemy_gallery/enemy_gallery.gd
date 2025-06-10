# enemy_gallery.gd
extends Node3D
class_name EnemyGallery

# UI references (assign these in the Inspector)
@onready var enemy_model_container: Node3D = $EnemyModelCont
@onready var animation_buttons_vbox: VBoxContainer = $CanvasLayer/MarginContainer/HBoxContainer/VBoxContainer/AnimationButtonsVBox

var _current_enemy_instance: EnemyController = null
var _current_animation_player: AnimationPlayer = null # To store a reference to the AnimationPlayer
var _current_animation_name: String = ""

func _ready() -> void:
	# Ensure this gallery is processed even when the game is paused
	set_process_mode(Node.PROCESS_MODE_ALWAYS)
	set_process_input(true)
	
	# Optional: Set up initial display or load a default enemy
	load_enemy("res://enemy/enemy_controller/enemy_controller.tscn")

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		GameManager.load_main_menu()
		get_viewport().set_input_as_handled() # Consume the input

# Function to load an enemy model from a path
func load_enemy(enemy_model_path: String) -> void:
	_clear_enemy_display()
	
	# 1. Load the enemy scene
	var enemy_prefab = load(enemy_model_path)
	if not enemy_prefab is PackedScene:
		printerr("Error: Path '", enemy_model_path, "' does not point to a PackedScene.")
		return
	
	_current_enemy_instance = enemy_prefab.instantiate() as EnemyController
	if not _current_enemy_instance:
		printerr("Error instantiating enemy from '", enemy_model_path, "'.")
		return
	
	# 2. Add the instantiated enemy to the scene
	enemy_model_container.add_child(_current_enemy_instance)
	_current_enemy_instance.show_detection_area_debug = false
	_current_enemy_instance.show_state_debug = false
	# FIXME: model appears at (-1,.2,0)?!
	_current_enemy_instance.position = Vector3(0,0,0)
	print(_current_enemy_instance.position)
	print(enemy_model_container.global_position)
	# FIXME: ^^^
	
	# 3. Find the AnimationPlayer within the enemy model
	# We need to recursively search for the AnimationPlayer as it might not be a direct child
	_current_animation_player = _find_animation_player(_current_enemy_instance)
	
	if not _current_animation_player:
		printerr("Warning: No AnimationPlayer found in the loaded enemy model at '", enemy_model_path, "'.")
		return
	
	# 4. Populate animation buttons
	_populate_animation_buttons()
	
	# 5. Play the first animation found by default (optional)
	#if not _current_animation_player.get_animation_list().is_empty():
	#	var first_anim = _current_animation_player.get_animation_list()[0]
	#	play_animation(first_anim)

func _clear_enemy_display() -> void:
	if _current_enemy_instance and is_instance_valid(_current_enemy_instance):
		_current_enemy_instance.queue_free()
		_current_enemy_instance = null
	_current_animation_player = null
	_current_animation_name = ""
	_clear_animation_buttons()

func _clear_animation_buttons() -> void:
	for child in animation_buttons_vbox.get_children():
		if child is Button: # Only remove the buttons we added
			child.queue_free()

# Recursive function to find an AnimationPlayer
func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var anim_player = _find_animation_player(child)
		if anim_player:
			return anim_player
	return null

func _populate_animation_buttons() -> void:
	# 1: clear buttons
	_clear_animation_buttons()
	# 2: reality check
	if not _current_animation_player:
		return
	# 3:
	var animation_list = _current_animation_player.get_animation_list()
	if animation_list.is_empty():
		var no_anim_label = Label.new()
		no_anim_label.text = "No Animations Found"
		animation_buttons_vbox.add_child(no_anim_label)
		return
	# 4: Flag to track if the first valid button has been created
	var first_button_created = false
	# 5:
	for anim_name in animation_list:
		# Filter out animations containing '/'
		if "/" in anim_name:
			continue # Skip this animation and move to the next one
		var button = Button.new()
		button.text = anim_name
		# Connect the button's pressed signal to a lambda function that calls play_animation
		button.pressed.connect(func(): play_animation(anim_name))
		animation_buttons_vbox.add_child(button)
		# If this is the first button we've successfully added (after filtering)
		if not first_button_created:
			button.grab_focus() # Give focus to this button
			first_button_created = true # Set the flag so we don't focus subsequent buttons

func play_animation(anim_name: String) -> void:
	if _current_animation_player and _current_animation_player.has_animation(anim_name):
		_current_animation_player.play(anim_name)
		_current_animation_name = anim_name
		print("Playing animation: ", anim_name)
	else:
		printerr("Animation '", anim_name, "' not found or no AnimationPlayer available.")

# You can add controls for rotation here if needed, similar to your WeaponGallery.
# For example, in _process if input is handled:
# func _process(delta):
#     if Input.is_action_pressed("rotate_right"):
#         enemy_model_container.rotate_y(deg_to_rad(90) * delta)
#     if Input.is_action_pressed("rotate_left"):
#         enemy_model_container.rotate_y(deg_to_rad(-90) * delta)
