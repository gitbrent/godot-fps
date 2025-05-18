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
@onready var audio_enemy_lost: AudioStreamPlayer = $"../../Audio/Enemy-lost"
#
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
	# 1: reset vars
	has_line_of_sight = false
	# Update attack cooldown timer
	time_since_last_attack += delta

	# Find target (e.g., the player) - you'll need to get the player reference
	var player = get_tree().get_first_node_in_group("player")

	if !player or !is_instance_valid(player):
		# If target is lost, transition back to follow or idle
		transitioned.emit(self, "Idle")
		return

	# Check if target is still within attack range
	var distance_to_player = enemy_controller.global_position.distance_to(player.global_position)
	if distance_to_player > attack_range:
		# Target moved out of range, transition back to follow
		transitioned.emit(self, "follow")
		return

	# Line of sight check
	if player and distance_to_player <= attack_range:
		# Line of Sight (LOS) check using raycast
		var space_state = enemy_controller.get_world_3d().direct_space_state
		var ray_origin = enemy_controller.global_transform.origin + Vector3.UP * 1.5  # eye height
		var ray_target = player.global_transform.origin + Vector3.UP * 1.5  # player chest
		# TODO: ^ replace with player's Marker3D
		var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_target)
		query.exclude = [enemy_controller]  # don't hit self
		#query.collision_mask = 1  # set to what your world geometry is on (e.g. 1 = World)
		var result = space_state.intersect_ray(query)
		if result and result.collider == player:
			has_line_of_sight = true

	# Check if ready to attack based on cooldown and line of sight
	if time_since_last_attack >= attack_cooldown and has_line_of_sight:
		# Reset cooldown
		time_since_last_attack = 0.0
		# --- Request Attack from Controller ---
		# Call the fire_weapon method on the enemy_controller, passing target position
		var ray_target = player.global_transform.origin + Vector3.UP * 1.5  # player chest
		enemy_controller.fire_weapon(ray_target)
		# --- End Request Attack ---
		# Optionally play a single shot animation or trigger recoil

	if not has_line_of_sight:
		transitioned.emit(self, "Idle")

# physics_update is called by the controller before move_and_slide
# It should return the desired horizontal velocity (Vector3.ZERO when standing still)
# and set the desired_rotation_direction.
func physics_update(delta: float) -> Vector3:
	# If we lost our target player, try to find one again
	if target_player == null or not is_instance_valid(target_player):
		target_player = find_nearest_player()
		if target_player == null:
			# If still no target, transition back to idle
			transitioned.emit(self, "idle")
			return Vector3.ZERO # Return zero velocity
	
	# Calculate the direction and distance to the target player
	var direction_to_player = target_player.global_position - enemy_controller.global_position
	direction_to_player.y = 0 # Ignore vertical difference for horizontal facing
	var distance_to_player = direction_to_player.length()

	# --- Determine Desired Facing Direction ---
	# Set the desired rotation direction towards the target player
	if distance_to_player > 0: # Avoid normalizing a zero vector if exactly at player pos
		desired_rotation_direction = direction_to_player.normalized()
	# else: If distance is zero, keep the last valid desired_rotation_direction or a default.

	# --- Check Transition Conditions ---
	# If the player is outside the attack range, transition back to follow
	if distance_to_player > attack_range:
		transitioned.emit(self, "idle")
		return Vector3.ZERO

	# If the player is too close (optional - if minimum attack range)
	# var minimum_attack_range = 1.0
	# if distance_to_player < minimum_attack_range:
	# 	transitioned.emit(self, "retreat") # Example: transition to a retreat state
	# 	return Vector3.ZERO

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
