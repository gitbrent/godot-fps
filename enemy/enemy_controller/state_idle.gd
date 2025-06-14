extends EnemyState
class_name EnemyIdle

#region vsars
@export var detection_range := 10.0
@onready var animation_player: AnimationPlayer = $"../../AnimationPlayer"
#endregion

func enter() -> void:
	animation_player.play("IDLE_RIFLE")

func physics_update(_delta: float) -> Vector3:
	var players = get_tree().get_nodes_in_group("player")
	var nearest_player_distance = INF
	var nearest_player: CharacterBody3D = null
	var desired_horizontal_velocity = Vector3.ZERO
	
	# 1:
	for player in players:
		if player is CharacterBody3D:
			var distance = enemy_controller.global_position.distance_to(player.global_position)
			if distance < nearest_player_distance:
				nearest_player_distance = distance
				nearest_player = player
	
	# 2: If a player is found within the detection range, transition to follow
	if nearest_player and nearest_player_distance <= detection_range:
		if enemy_controller.can_see(nearest_player):
			transitioned.emit(self, "attack")
	
	# If a threat direction has been set (e.g., after taking damage)
	if enemy_controller.last_known_threat_direction != Vector3(0,0,1): # Check against default
		# Face the direction of threat
		desired_rotation_direction = enemy_controller.last_known_threat_direction
	
	# 3:
	return desired_horizontal_velocity
