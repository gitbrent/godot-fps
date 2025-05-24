extends CanvasLayer

@onready var label: Label = $Label
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	# 1: defaults
	label.visible = false

func show_321_countdown() -> void:
	label.visible = true

	label.text = "3"
	animation_player.play("321_go")
	await animation_player.animation_finished

	label.text = "2"
	animation_player.play("321_go")
	await animation_player.animation_finished

	label.text = "1"
	animation_player.play("321_go")
	await animation_player.animation_finished
