# state_cover.gd
extends EnemyState
class_name EnemyCover

#region vars
# EXPORTS
@export var cover_arrival_tolerance: float = 0.5 # How close enemy needs to be to cover spot
@export var cover_peek_duration: float = 2.0 # How long to peek out
@export var cover_hide_duration: float = 3.0 # How long to stay hidden
@export var shoot_from_cover_cooldown: float = 1.0
@onready var audio_taking_cover: AudioStreamPlayer = $"../../Audio/TakingCover"
# VARS
var _target_cover_transform: Transform3D
var _current_peek_timer: float = 0.0
var _current_hide_timer: float = 0.0
var _is_peeking: bool = false
var _time_since_last_shot_from_cover: float = 0.0
#endregion

func enter() -> void:
	print("[EnemyCover] entered state...")
	audio_taking_cover.play()
	_is_peeking = false
	_current_peek_timer = 0.0
	_current_hide_timer = 0.0
	_time_since_last_shot_from_cover = shoot_from_cover_cooldown # Ready to shoot immediately

	# Get the cover spot transform from the controller
	_target_cover_transform = enemy_controller.get_current_cover_spot_transform()
	if _target_cover_transform == Transform3D():
		printerr("EnemyCoverState: No valid cover transform assigned! Transitioning back to patrol.")
		transitioned.emit(self, "patrol")
		return
	
	# Start moving towards the cover position
	# TODO: 20250615: use tween and AnimationPlayer!
	enemy_controller.global_position = _target_cover_transform.origin # Snap to position for simplicity, or Tween for smooth
	# Look in cover direction
	enemy_controller.look_at(_target_cover_transform.origin + _target_cover_transform.basis.z, Vector3.UP) 
	
	# TODO: set the enemy's animation to a "cover_idle" pose.
	
	# WIP: wish.com crouch mechanism
	#enemy_controller.global_position = Vector3(_target_cover_transform.origin.x, _target_cover_transform.origin.y-2, _target_cover_transform.origin.z)

# This function handles the logic while in cover (e.g., peeking, shooting)
func update(delta: float) -> void:
	var player = enemy_controller.get_target_player()
	
	_time_since_last_shot_from_cover += delta
	
	if not player or not is_instance_valid(player):
		# Player lost while in cover, therefore, transition to patrol
		transitioned.emit(self, "patrol")
		return
	
	if _is_peeking:
		_current_peek_timer += delta
		# Face player while peeking
		enemy_controller.look_at(player.global_position, Vector3.UP)
		
		if _time_since_last_shot_from_cover >= shoot_from_cover_cooldown:
			# Shoot while peeking
			var player_target = player.global_transform.origin + Vector3.UP * 1.5
			enemy_controller.fire_weapon(player_target)
			_time_since_last_shot_from_cover = 0.0
		
		if _current_peek_timer >= cover_peek_duration:
			_is_peeking = false
			_current_hide_timer = 0.0
			# Play animation to hide behind cover
			print("Enemy hiding behind cover.")
			# Face the cover point's forward direction when hiding
			enemy_controller.look_at(_target_cover_transform.origin + _target_cover_transform.basis.z, Vector3.UP)
	else: # Hiding behind cover
		_current_hide_timer += delta
		if _current_hide_timer >= cover_hide_duration:
			_is_peeking = true
			_current_peek_timer = 0.0
			# Play animation to peek out
			print("[EnemyCover] ... enemy peeking from cover.")

	# --- State Transition Logic from Cover ---
	# Example conditions to leave cover:
	# 1. Player is too close (flanked)
	var distance_to_player = enemy_controller.global_position.distance_to(player.global_position)
	if distance_to_player < enemy_controller.melee_attack_range:
		transitioned.emit(self, "chase") # Or "melee_attack"
		return

	# 2. Cover point is no longer safe (e.g., destroyed, or player has line of sight to it)
	# This requires more complex logic, potentially signals from the CoverPoint itself.
	# For now, let's keep it simple.

	# 3. No longer has line of sight to player for too long while trying to attack
	# (Already handled by _current_peek_timer, causing it to hide)

func physics_update(delta: float) -> Vector3:
	# In cover state, enemy mostly stands still or subtly adjusts position
	# If just snapped to cover in enter, return ZERO.
	return Vector3.ZERO

func exit() -> void:
	print("[EnemyCover] ... exited `Cover` state.")
	enemy_controller.leave_cover(enemy_controller.name) # Release the cover spot
	# Reset animations if any specific cover animations were playing
