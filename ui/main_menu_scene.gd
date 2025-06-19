extends Control

#region vars
@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var label_footer: Label = $CanvasLayer/MainContainer/LabelFooter
#endregion

func _ready() -> void:
	var version_string = ProjectSettings.get_setting("application/config/version")
	label_footer.text = "godot engine 4.x | rel v" + version_string

func _unhandled_input(_event):
	if Input.is_action_just_pressed("ui_accept"):
		_on_button_start_pressed()
	elif Input.is_action_just_pressed("ui_select"):
		_on_button_gallery_pressed()
	elif Input.is_action_just_pressed("ui_cancel"):
		_on_button_enemy_pressed()
	elif Input.is_action_just_pressed("joypad_l2"):
		_on_button_range_pressed()
	elif Input.is_action_just_pressed("joypad_r2"):
		_on_btn_cover_pressed()

# HANDLERS ================================================

func _on_button_start_pressed() -> void:
	GameManager.load_level("res://levels/level_1.tscn")

func _on_button_gallery_pressed() -> void:
	GameManager.load_weapon_gallery()

func _on_button_range_pressed() -> void:
	GameManager.load_level("res://levels/shooting_range/shooting_range.tscn")

func _on_button_enemy_pressed() -> void:
	#GameManager.load_level("res://enemy_gallery/enemy_gallery.tscn")
	GameManager.load_enemy_gallery()

func _on_btn_cover_pressed() -> void:
	GameManager.load_level("res://levels/cover_range/cover_range.tscn")
