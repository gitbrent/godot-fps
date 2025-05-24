extends Control

signal btn_clicked_start_game

@onready var canvas_layer: CanvasLayer = $CanvasLayer

func _ready() -> void:
	canvas_layer.visible = false

func _on_button_start_pressed() -> void:
	emit_signal("btn_clicked_start_game")

# PUBLIC ===============================

func show_game_menu(show:bool) -> void:
	canvas_layer.visible = show
