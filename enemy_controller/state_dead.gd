extends EnemyState
class_name EnemyDead
## This state is responsible for the immediate visual and audio feedback of death.

@onready var animation_player: AnimationPlayer = $"../../AnimationPlayer"
@onready var audio_brutal: AudioStreamPlayer = $"../../Audio/Ow-right-in-the-fkn-nuts"
@onready var audio_argh: AudioStreamPlayer = $"../../Audio/ARGH"

func enter() -> void:
	#print("ENEMY DEAD!")
	# 1: normal
	#animation_player.play("DYING")
	# --OR--
	# 2: burtal way to go
	#audio_brutal.play()
	audio_argh.play()
	animation_player.play("BRUTAL_DEATH")

	# 3:
	await animation_player.animation_finished
	fade_out_requested.emit()
