# state_attack.gd
# The state script should focus on the logic and timing of the attack behavior. Its responsibilities include:
# - When to Attack: 
#   Determining if the conditions for attacking are met (e.g., attack cooldown finished, animation state allows firing).
# - Who/Where to Attack: 
#   Identifying the target (e.g., getting the player character's current position).
# - Requesting the Action: 
#   Telling the EnemyController that it's time to perform an attack action.
# - State-Specific Animation/Sound Timing: 
#   Managing the playback of the attack animation or triggering attack sounds at the correct point in the state's lifecycle or within the animation.
# - Transitioning Out: 
#   Deciding when to exit the "Attack" state (e.g., target moved out of range, enemy needs to reload).
extends EnemyState
class_name EnemyAttack

#region vsars
@export var attack_range: float = 20.0
@export var attack_cooldown: float = 0.5
#
@onready var animation_player: AnimationPlayer = $"../../AnimationPlayer"
@onready var audio_enemy_spotted: AudioStreamPlayer = $"../../Audio/EnemySpotted"
@onready var audio_enemy_lost: AudioStreamPlayer = $"../../Audio/EnemyLost"
#
var player: CharacterBody3D = null
var distance_to_player: float = INF
var has_line_of_sight: bool = false
var time_since_last_attack: float = 0.0
var target_player: CharacterBody3D = null # Keep a reference to the current target player
#endregion

func enter() -> void:
	#print("ENEMY START ATTACKING.")
	# 1: Be ready to fire immediately on entering (or add a delay)
	time_since_last_attack = attack_cooldown
	# 1: show corresponding animation
	animation_player.play("FIRING_RIFLE")
	audio_enemy_spotted.play()
	# 2: When entering, try to find a target player immediately
	target_player = find_nearest_player()
	if target_player == null:
		# If no player found on entering, transition back to idle
		transitioned.emit(self, "idle")

func update(delta: float) -> void:
	# 1: Update attack cooldown timer
	time_since_last_attack += delta
	
	# 2: Check if ready to attack based on cooldown and line of sight
	if time_since_last_attack >= attack_cooldown and has_line_of_sight:
		# Reset cooldown
		time_since_last_attack = 0.0
		# --- Request Attack from Controller ---
		# Call the fire_weapon method on the enemy_controller, passing target position
		var player_target = player.global_transform.origin + Vector3.UP * 1.5  # player chest
		enemy_controller.fire_weapon(player_target)
		# --- End Request Attack ---
		# Optionally play a single shot animation or trigger recoil

func physics_update(delta: float) -> Vector3:
	# 1:
	player = get_tree().get_first_node_in_group("player")
	# 2:
	if player and is_instance_valid(player):
		distance_to_player = enemy_controller.global_position.distance_to(player.global_position)
		has_line_of_sight = enemy_controller.can_see(player)

		# --- Determine Desired Facing Direction ---
		# Set the desired rotation direction towards the target player
		var direction_to_player = player.global_position - enemy_controller.global_position
		direction_to_player.y = 0 # Ignore vertical difference for horizontal facing
		if direction_to_player.length_squared() > 0.001:
			desired_rotation_direction = direction_to_player.normalized()
		# else: If distance is zero, keep the last valid desired_rotation_direction or a default.

	else: # Player is null or invalid (target lost)
		distance_to_player = INF # Player not found, set distance to infinity
		has_line_of_sight = false
		# If player is lost, the rotation direction might revert to a default or last known,
		# or you might handle a "lost target" rotation behavior here.

	# --- State Transition Logic (Consolidated Here) ---
	var next_state_name = "" # Variable to hold the name of the state to transition to

	# Condition 1: Player is lost (null or invalid instance)
	if player == null or !is_instance_valid(player):
		next_state_name = "patrol" # Default transition if target is lost

	# Condition 2: Player moved out of attack range
	elif distance_to_player > attack_range:
		# If target moved out of attack range, transition back to patrol
		next_state_name = "patrol"

	# Condition 3: Lost line of sight (but player is still in range)
	elif !has_line_of_sight:
		# If line of sight is lost while still within range
		# Decide between patrol and idle if LOS is lost in range based on controller property
		if enemy_controller.can_patrol: # Check the can_patrol property on the controller
			next_state_name = "patrol"
		else:
			next_state_name = "idle"

	# Add other transition conditions here (e.g., player too close, enemy health low, reload needed)
	# Example: If reload is needed (based on ammo count managed elsewhere)
	# if enemy_controller.is_reload_needed():
	#    next_state_name = "reload"

	# --- Perform Transition if Needed ---
	if next_state_name != "":
		#print("Transitioning from `Attack` --> ", next_state_name)
		transitioned.emit(self, next_state_name)
		# Reset state-specific variables on transition out
		player = null
		distance_to_player = INF
		has_line_of_sight = false
		# No need to call exit() here - the StateMachine calls it

	# --- Return Desired Velocity ---
	# The enemy stands still while attacking, so return zero velocity
	return Vector3.ZERO

func exit() -> void:
	#print("ENEMY STOP ATTACKING.")
	audio_enemy_lost.play()
	target_player = null # Clear target

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
