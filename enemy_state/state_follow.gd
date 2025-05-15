extends EnemyState
class_name EnemyFollow

@export var move_speed := 4.0
@export var follow_area := 25.0
@export var lose_interest_area := 30.0

@onready var animation_player: AnimationPlayer = $"../../AnimationPlayer"

var target_player: CharacterBody3D = null # Keep a reference to the current target player

func enter() -> void:
	# 1: show corresponding animation
	animation_player.play("WALKING")
	# 2: When entering, try to find a target player immediately
	target_player = find_nearest_player()
	if target_player == null:
		# If no player found on entering, transition back to idle
		transitioned.emit(self, "idle")

# Modified: Calculate and return the desired horizontal velocity
func physics_update(delta: float) -> Vector3:
	# If we lost our target player, try to find one again
	if target_player == null or not is_instance_valid(target_player):
		target_player = find_nearest_player()
		if target_player == null:
			# If still no target, transition back to idle
			transitioned.emit(self, "idle")
			return Vector3.ZERO # Return zero velocity

	# Calculate the direction to the target player
	var direction_to_player = target_player.global_position - enemy_controller.global_position
	# Ignore vertical difference for horizontal movement calculation
	direction_to_player.y = 0

	var distance_to_player = direction_to_player.length()
	var desired_horizontal_velocity = Vector3.ZERO

	if distance_to_player > 0:
		# Normalize the direction to get a unit vector
		var move_direction = direction_to_player.normalized()

		# Check if the player is within the follow area
		if distance_to_player <= follow_area:
			# Move towards the player
			desired_horizontal_velocity = move_direction * move_speed
		# Else (player is outside follow_area but we are still in follow state)
		# The enemy will stop but remain in the follow state until they leave lose_interest_area
		# desired_horizontal_velocity remains Vector3.ZERO

		# Transition to idle state if the player is outside the lose interest area
		if distance_to_player > lose_interest_area:
			transitioned.emit(self, "idle")
			target_player = null # Clear target when transitioning out
			return Vector3.ZERO # Return zero velocity immediately on transition

	return desired_horizontal_velocity # Return the calculated horizontal velocity

func exit() -> void:
	# Stop the walking animation when exiting the follow state
	animation_player.stop()

# CLASS CUSTOM FUNCS -----------------------------------------------

# New helper function to find the nearest player in the "player" group
func find_nearest_player() -> CharacterBody3D:
	# Use the stored enemy_controller reference
	if !enemy_controller: return null

	var players = get_tree().get_nodes_in_group("player")
	var nearest_player: CharacterBody3D = null
	var shortest_distance = INF # Initialize with a very large number

	for player in players:
		if player is CharacterBody3D: # Ensure it's a CharacterBody3D
			var distance = enemy_controller.global_position.distance_to(player.global_position)
			if distance < shortest_distance:
				shortest_distance = distance
				nearest_player = player

	# You could add a check here to only return a player if they are within a certain initial range
	# if shortest_distance > initial_detection_range:
	#     return null

	return nearest_player
