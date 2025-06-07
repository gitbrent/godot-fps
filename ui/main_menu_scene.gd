extends Control

signal btn_clicked_show_gallery
signal btn_clicked_show_enemy

#region vars
@onready var canvas_layer: CanvasLayer = $CanvasLayer
#endregion

func _unhandled_input(event):
	if Input.is_action_just_pressed("ui_accept"):
		_on_button_start_pressed()
	elif Input.is_action_just_pressed("ui_select"):
		_on_button_gallery_pressed()
	elif Input.is_action_just_pressed("shooter_reload"):
		_on_button_enemy_pressed()

# HANDLERS ================================================

func _on_button_start_pressed() -> void:
	GameManager.load_level("res://levels/level_1.tscn")

func _on_button_gallery_pressed() -> void:
	emit_signal("btn_clicked_show_gallery")

func _on_button_enemy_pressed() -> void:
	emit_signal("btn_clicked_show_enemy")
