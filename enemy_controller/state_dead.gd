extends EnemyState
class_name EnemyDead

@onready var animation_player: AnimationPlayer = $"../../AnimationPlayer"
@onready var audio_brutal: AudioStreamPlayer = $"../../Audio/ow-my-balls"

func enter() -> void:
	print("ENEMY DEAD!")
	# 1: normal
	#animation_player.play("DYING")
	# --OR--
	# 2: burtal way to go
	audio_brutal.play()
	animation_player.play("BRUTAL_DEATH")

	# 3:
	await animation_player.animation_finished
	fade_out_requested.emit()
