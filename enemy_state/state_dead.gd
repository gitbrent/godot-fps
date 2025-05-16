extends EnemyState
class_name EnemyDead

@onready var animation_player: AnimationPlayer = $"../../AnimationPlayer"
@onready var ow_my_balls: AudioStreamPlayer = $"../../Audio/ow-my-balls"

func enter() -> void:
	print("DEAD!")
	# 1: normal
	#animation_player.play("DYING")
	# --OR--
	# 2: burtal way to go
	ow_my_balls.play()
	animation_player.play("animations-test05/BRUTAL_DEATH")

	# 3:
	await animation_player.animation_finished
	# FIXME: queue_free()
	# send signal to parent to fade away and queu free??
