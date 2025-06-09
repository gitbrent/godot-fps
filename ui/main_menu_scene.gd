extends Control

#region vars
@onready var canvas_layer: CanvasLayer = $CanvasLayer
#endregion

func _unhandled_input(event):
	if Input.is_action_just_pressed("ui_accept"):
		_on_button_start_pressed()
	elif Input.is_action_just_pressed("ui_select"):
		_on_button_gallery_pressed()
	elif Input.is_action_just_pressed("ui_cancel"):
		_on_button_enemy_pressed()
	elif Input.is_action_just_pressed("shooter_reload"):
		_on_button_range_pressed()

# HANDLERS ================================================

func _on_button_start_pressed() -> void:
	GameManager.load_level("res://levels/level_1.tscn")

func _on_button_gallery_pressed() -> void:
	GameManager.load_weapon_gallery()

func _on_button_range_pressed() -> void:
	GameManager.load_level("res://levels/shooting_range/shooting_range.tscn")

func _on_button_enemy_pressed() -> void:
	GameManager.load_level("res://enemy_gallery/enemy_gallery.tscn")
