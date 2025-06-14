extends Control

signal show_options
signal resume_game
signal quit_game

@onready var btn_options: Button = $CanvasLayer/Panel/VBoxContainer/BtnOptions
@onready var btn_resume: Button = $CanvasLayer/Panel/VBoxContainer/BtnResume
@onready var btn_quit: Button = $CanvasLayer/Panel/VBoxContainer/BtnQuit

func _ready():
	# Ensure your pause menu is processed even when the game is paused
	set_process_mode(Node.PROCESS_MODE_ALWAYS)
	set_process_input(true) # Ensure it processes input
	
	# Connect button signals (as you likely already have)
	btn_options.pressed.connect(func(): show_options.emit())
	btn_resume.pressed.connect(func(): resume_game.emit())
	btn_quit.pressed.connect(func(): quit_game.emit())
	# Connect other buttons like Options or Main Menu here
	
	# --- IMPORTANT: Set initial focus ---
	# This tells Godot which control node should be selected first.
	btn_resume.grab_focus()
	
	# Optional: Handle ui_cancel for closing the menu
	# This ensures that pressing Esc/B-button also closes the menu
	Input.set_custom_mouse_cursor(null) # Clear custom mouse cursor if you set one, so mouse input isn't overridden while menu is active

func _unhandled_input(_event):
	if Input.is_action_just_pressed("ui_cancel"):
		resume_game.emit() # Emit resume signal to close the menu
		get_viewport().set_input_as_handled() # Consume the input
