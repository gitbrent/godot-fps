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

#region vars
# EXPORTS
@export var attack_range: float = 20.0
@export var attack_cooldown: float = 0.5
@export var seek_cover_health_threshold_percent: float = 0.9 # Go to cover if health is below 40%
@export var min_distance_to_seek_cover: float = 0.5 # Don't seek cover if player is too close
@export var cover_check_interval: float = 0.5 # How often to check for cover
# ONREADY
@onready var animation_player: AnimationPlayer = $"../../AnimationPlayer"
@onready var audio_enemy_spotted: AudioStreamPlayer = $"../../Audio/Contact!"
@onready var audio_enemy_lost: AudioStreamPlayer = $"../../Audio/IveLostThem"
# VARS
var distance_to_player: float = INF
var has_line_of_sight: bool = false
var time_since_last_attack: float = 0.0
var _cover_check_timer: float = 0.0
#endregion

func enter() -> void:
	_cover_check_timer = 0.0 # Reset timer on entry
	# 1: Be ready to fire immediately on entering (or add a delay)
	time_since_last_attack = attack_cooldown
	# 1: show corresponding animation
	animation_player.play("RIFLE_DOWN_TO_AIM")
	await animation_player.animation_finished
	animation_player.play("FIRING_RIFLE")
	audio_enemy_spotted.play()
	# 2: When entering, try to find a target immediately
	var target = enemy_controller.get_current_target()
	if target == null:
		# If no target found on entering, transition back to idle
		transitioned.emit(self, "idle")

func update(delta: float) -> void:
	# 1: Update attack cooldown timer
	time_since_last_attack += delta
	# 2: Check if ready to attack based on cooldown and line of sight
	if time_since_last_attack >= attack_cooldown and has_line_of_sight:
		# 2-1: Reset cooldown
		time_since_last_attack = 0.0
		# 2-2: Call the fire_weapon method on the enemy_controller, passing target position
		var target = enemy_controller.get_current_target()
		# FIXME: below hard-coded target
		var target_pos = target.global_transform.origin + Vector3.UP * 1.5  # player chest
		enemy_controller.fire_weapon(target_pos)
	# 3: check for cover periodically
	_cover_check_timer += delta
	if _cover_check_timer >= cover_check_interval:
		_cover_check_timer = 0.0
		_check_and_seek_cover()

func physics_update(_delta: float) -> Vector3:
	var desired_horizontal_velocity = Vector3.ZERO
	var target = enemy_controller.get_current_target()
	
	## 1: Check for nearest player and transition to chase if found within range
	#if player and is_instance_valid(player):
		#var distance = enemy_controller.global_position.distance_to(player.global_position)
		#if distance <= attack_range:
			## WIP: NEW: 
			## FIXME: causes thrashing - check for cover first
			#print("Player detected within range! Transitioning to cover.")
			#transitioned.emit(self, "cover")
			#return desired_horizontal_velocity # Return current velocity before state change
	
	# 2:
	if target and is_instance_valid(target):
		distance_to_player = enemy_controller.global_position.distance_to(target.global_position)
		has_line_of_sight = enemy_controller.can_see(target)
		# --- Determine Desired Facing Direction ---
		# Set the desired rotation direction towards the target target
		var direction_to_player = target.global_position - enemy_controller.global_position
		direction_to_player.y = 0 # Ignore vertical difference for horizontal facing
		if direction_to_player.length_squared() > 0.001:
			desired_rotation_direction = direction_to_player.normalized()
		# else: If distance is zero, keep the last valid desired_rotation_direction or a default.
	else: # Player is null or invalid (target lost)
		distance_to_player = INF # Player not found, set distance to infinity
		has_line_of_sight = false
		# If target is lost, the rotation direction might revert to a default or last known,
		# or you might handle a "lost target" rotation behavior here.

	# --- State Transition Logic (Consolidated Here) ---
	var next_state_name = "" # Variable to hold the name of the state to transition to

	# Condition 1: Player is lost (null or invalid instance)
	if target == null or !is_instance_valid(target):
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
		#print("[enemt-state] `Attack` --> ", next_state_name, " - ", distance_to_player > attack_range, has_line_of_sight)
		transitioned.emit(self, next_state_name)
		
		# Reset state-specific variables on transition out
		distance_to_player = INF
		has_line_of_sight = false

	# --- Return Desired Velocity ---
	# The enemy stands still while attacking, so return zero velocity
	return desired_horizontal_velocity

func exit() -> void:
	#print("[ENEMY-STATE] ATTACK -> ?")
	#audio_enemy_lost.play() # <-- this is annoying, lol
	pass

# CLASS CUSTOM FUNCS -----------------------------------------------

func _check_and_seek_cover() -> void:
	var player = enemy_controller.get_current_target()
	
	if not player or not is_instance_valid(player):
		return # No player to interact with
	
	var current_health_percent = float(enemy_controller.current_health) / enemy_controller.max_health
	var distance_to_player = enemy_controller.global_position.distance_to(player.global_position)
	
	# Conditions to seek cover:
	if current_health_percent < seek_cover_health_threshold_percent and distance_to_player > min_distance_to_seek_cover:
		print("[state_attack] find_and_go_to_cover!")
		enemy_controller.find_and_go_to_cover(enemy_controller.name)
		# If find_and_go_to_cover successfully found and reserved cover,
		# it will automatically request the state change.
		#print("Enemy ", enemy_controller.name, " successfully initiated cover search.")
	# else:
		# print("Enemy ", enemy_controller.name, " did not seek cover. Health: ", current_health_percent, ", Distance: ", distance_to_player)
