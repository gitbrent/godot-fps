extends Control

signal btn_clicked_start_game
signal btn_clicked_show_gallery
signal btn_clicked_show_enemy

#region vars
@onready var canvas_layer: CanvasLayer = $CanvasLayer
#endregion

func _ready() -> void:
	canvas_layer.visible = false

func _unhandled_input(event):
	if Input.is_action_just_pressed("ui_accept"):
		_on_button_start_pressed()
	elif Input.is_action_just_pressed("ui_select"):
		_on_button_gallery_pressed()
	elif Input.is_action_just_pressed("shooter_reload"):
		_on_button_enemy_pressed()

# HANDLERS ================================================

func _on_button_start_pressed() -> void:
	emit_signal("btn_clicked_start_game")

func _on_button_gallery_pressed() -> void:
	emit_signal("btn_clicked_show_gallery")

func _on_button_enemy_pressed() -> void:
	emit_signal("btn_clicked_show_enemy")

# PUBLIC ==================================================

func show_game_menu(show:bool) -> void:
	canvas_layer.visible = show
