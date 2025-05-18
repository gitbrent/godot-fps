extends EnemyState
class_name EnemyIdle

#region vsars
@export var move_speed := 2.5
@export var detection_range := 10.0
# The current random direction the enemy is moving in
var move_direction: Vector3
# How long the enemy will move in the current direction before picking a new one
var wander_time: float
#
@onready var animation_player: AnimationPlayer = $"../../AnimationPlayer"
#endregion

func enter() -> void:
	animation_player.play("WALKING")
	randomize_wander()

func update(delta: float) -> void:
	# Countdown the wander time
	if wander_time > 0:
		wander_time -= delta
	else:
		# If wander time is up, pick a new random direction and time
		randomize_wander()

func physics_update(delta: float) -> Vector3:
	# --- Player Detection Logic (WIP) ---
	var players = get_tree().get_nodes_in_group("player")
	var nearest_player_distance = INF
	var nearest_player: CharacterBody3D = null
	# 1:
	for player in players:
		if player is CharacterBody3D:
			var distance = enemy_controller.global_position.distance_to(player.global_position)
			if distance < nearest_player_distance:
				nearest_player_distance = distance
				nearest_player = player

	# 2: If a player is found within the detection range, transition to follow
	if nearest_player and nearest_player_distance <= detection_range:
		# TODO: 20250517: Raycast to check visibility of player
		transitioned.emit(self, "attack")
		# OLD BELOW:
		#print("IDLE->FOLLOW: ", nearest_player_distance, detection_range)
		#transitioned.emit(self, "follow")
		# You might also want to pass the detected player reference to the follow state
		# This requires modifying the state machine and follow state to accept it.
		# For now, the follow state will find the nearest player itself on enter.
	#
	# --- End Player Detection Logic ---

	# LAST: Return the desired horizontal velocity for wandering
	return move_direction * move_speed
	# FUTURE: Return zero velocity if you want them to stand still when idle
	#return Vector3.ZERO

# UNIQUE CLASS FUNCS -----------------------------------------------

# Sets a new random horizontal direction and a random time to wander in that direction
func randomize_wander() -> void:
	# Generate a random direction on the XZ plane
	move_direction = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	# Set a random time to continue in this direction
	wander_time = randf_range(2, 5) # Increased time range for longer straight movements
