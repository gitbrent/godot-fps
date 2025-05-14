extends EnemyState
class_name EnemyDead

@onready var animation_player: AnimationPlayer = $"../../AnimationPlayer"

func enter() -> void:
	print("DEAD!")
	animation_player.play("DYING")
	await animation_player.animation_finished
	# FIXME: queue_free()
	# send signal to parent to fade away and queu free??
