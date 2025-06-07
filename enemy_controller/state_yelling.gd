extends EnemyState
class_name EnemyYelling

#region vsars
@onready var animation_player: AnimationPlayer = $"../../AnimationPlayer"
#endregion

func enter() -> void:
	animation_player.play("YELLING")
