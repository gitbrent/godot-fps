# options_menu.gd
extends Control

signal resume_game

@onready var audio_switch: AudioStreamPlayer = $Audio/AudioSwitch
@onready var btn_resume: Button = $CanvasLayer/Panel/VBoxContainer/MarginContainer/BtnResume
@onready var invert_look_toggle_button: Button = $CanvasLayer/Panel/VBoxContainer/PanelContOptions/MarginContainer/VBoxOptions/HBoxInvert/Control/InvertLookToggleButton
@onready var label_off: Label = $CanvasLayer/Panel/VBoxContainer/PanelContOptions/MarginContainer/VBoxOptions/HBoxInvert/Control/LabelOff
@onready var label_on: Label = $CanvasLayer/Panel/VBoxContainer/PanelContOptions/MarginContainer/VBoxOptions/HBoxInvert/Control/LabelOn

func _ready():
	#print("[options_menu] FYI: ", SettingsManager.invert_look)
	btn_resume.pressed.connect(func(): resume_game.emit())
	# Connect the button's 'pressed' signal
	invert_look_toggle_button.pressed.connect(_on_invert_look_toggle_button_pressed)
	# Initial state update
	_update_invert_look_visuals()
	# 3:
	btn_resume.grab_focus()

func _unhandled_input(_event):
	if Input.is_action_just_pressed("ui_cancel"):
		resume_game.emit() # Emit resume signal to close the menu
		get_viewport().set_input_as_handled() # Consume the input

func _on_invert_look_toggle_button_pressed() -> void:
	# 1: sound FX
	audio_switch.play()
	# 2: toggle the setting in SettingsManager
	SettingsManager.invert_look = !SettingsManager.invert_look
	# 3: update the UI visuals
	_update_invert_look_visuals()

func _update_invert_look_visuals() -> void:
	if SettingsManager.invert_look:
		# Invert look is ON
		label_off.modulate = Color(0.5, 0.5, 0.5, 1.0) # Dim OFF
		label_on.modulate = Color(1.0, 1.0, 1.0, 1.0)  # Brighten ON
		# Or:
		# label_off.hide()
		# label_on.show()
	else:
		# Invert look is OFF
		label_off.modulate = Color(1.0, 1.0, 1.0, 1.0) # Brighten OFF
		label_on.modulate = Color(0.5, 0.5, 0.5, 1.0)  # Dim ON
		# Or:
		# label_off.show()
		# label_on.hide()
