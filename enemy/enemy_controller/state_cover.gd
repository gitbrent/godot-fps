# state_cover.gd
extends EnemyState
class_name EnemyCover

#region vars
# EXPORT
@export var shoot_from_cover_cooldown: float = 1.0
@export var cover_arrival_tolerance: float = 0.5 # How close enemy needs to be to cover spot
@export var crouch_height_offset: float = 1.0 # How much to lower Y position when crouching (positive value)
@export var crouch_tween_duration: float = 0.2 # How long it takes to crouch/stand up
@export var cover_move_duration: float = 1.5 # How long it takes to move to the cover spot
@export var cover_peek_duration: float = 2.0 # How long to peek out
@export var cover_hide_duration: float = 3.0 # How long to stay hidden
# ONREADY
@onready var audio_taking_cover: AudioStreamPlayer = $"../../Audio/TakingCover"
# VAR
var _target_cover_transform: Transform3D
var _current_peek_timer: float = 0.0
var _current_hide_timer: float = 0.0
var _is_peeking: bool = false
var _time_since_last_shot_from_cover: float = 0.0
var _crouch_target_y: float # The Y-coordinate for the current crouch/stand state
var _movement_tween: Tween = null
var _crouch_tween: Tween = null
#endregion

func enter() -> void:
	print("[EnemyCover] entered state...")
	# 1:
	_is_peeking = false # Start in hidden/crouched state
	_current_peek_timer = 0.0
	_current_hide_timer = 0.0
	_time_since_last_shot_from_cover = shoot_from_cover_cooldown # Ready to shoot immediately
	
	# 2:
	if audio_taking_cover and is_instance_valid(audio_taking_cover):
		audio_taking_cover.play()
	else:
		printerr("EnemyCover: AudioStreamPlayer 'Audio/TakingCover' not found or invalid.")
	
	# 3: Get the cover spot transform from the controller
	_target_cover_transform = enemy_controller.get_current_cover_spot_transform()
	if _target_cover_transform == Transform3D():
		printerr("EnemyCoverState: No valid cover transform assigned! Transitioning back to patrol.")
		transitioned.emit(self, "patrol")
		return
	
	# 4: Stop any existing tweens
	if _movement_tween and _movement_tween.is_running():
		_movement_tween.kill()
	if _crouch_tween and _crouch_tween.is_running():
		_crouch_tween.kill()
	
	# --- Tween Movement to Cover Spot (XZ only for now, Y handled by crouch) ---
	_movement_tween = create_tween()
	_movement_tween.set_trans(Tween.TRANS_SINE)
	_movement_tween.set_ease(Tween.EASE_OUT)
	
	# Tween only X and Z to the target cover origin's XZ
	_movement_tween.tween_property(enemy_controller, "global_position",
		Vector3(_target_cover_transform.origin.x, enemy_controller.global_position.y, _target_cover_transform.origin.z),
		cover_move_duration
	)
	
	# After moving to XZ, immediately start crouching
	_movement_tween.tween_callback(self._start_crouch_animation)
	
	# Look in cover direction (this can happen immediately)
	enemy_controller.look_at(_target_cover_transform.origin + _target_cover_transform.basis.z, Vector3.UP)
	
	# TODO: set the enemy's animation to a "cover_move" animation, then transition to "cover_idle"
	# once the movement tween is finished.

# This function handles the logic while in cover (e.g., peeking, shooting)
func update(delta: float) -> void:
	var target = enemy_controller.get_current_target()
	
	_time_since_last_shot_from_cover += delta
	
	# NOTE: stay fixed by design (we want to "fix" certain enemies in place on future maps)
	#if not target or not is_instance_valid(target):
		#print("[EnemyCover] Player lost, transitioning to patrol.")
		#transitioned.emit(self, "patrol")
		#return
	
	if _is_peeking:
		_current_peek_timer += delta
		
		# Ensure enemy is at standing height for peeking
		var stand_y = _target_cover_transform.origin.y
		if not is_approximately_equal_float(enemy_controller.global_position.y, stand_y, 0.01):
			_animate_crouch(stand_y) # Raise to stand
		
		# Face target while peeking
		if target and is_instance_valid(target):
			enemy_controller.look_at(target.global_position, Vector3.UP, true)
		
		if _time_since_last_shot_from_cover >= shoot_from_cover_cooldown:
			if enemy_controller.has_method("fire_weapon"):
				var target_area = target.global_transform.origin
				enemy_controller.fire_weapon(target_area)
				_time_since_last_shot_from_cover = 0.0
			else:
				printerr("EnemyController does not have a 'fire_weapon' method.")
		
		if _current_peek_timer >= cover_peek_duration:
			_is_peeking = false
			_current_hide_timer = 0.0
			# Play animation to hide behind cover
			print("[EnemyCover] ... enemy HIDING behind cover.")
			# Face the cover point's forward direction when hiding
			enemy_controller.look_at(_target_cover_transform.origin + _target_cover_transform.basis.z, Vector3.UP)
			_animate_crouch(_target_cover_transform.origin.y - crouch_height_offset) # Crouch back down
			# TODO: Play "crouch_hide" animation
	else: # Hiding behind cover
		_current_hide_timer += delta
		
		# Ensure enemy is at crouched height for hiding
		var crouch_y = _target_cover_transform.origin.y - crouch_height_offset
		if not is_approximately_equal_float(enemy_controller.global_position.y, crouch_y, 0.01):
			_animate_crouch(crouch_y) # Crouch down
		
		if _current_hide_timer >= cover_hide_duration:
			_is_peeking = true
			_current_peek_timer = 0.0
			# Play animation to peek out
			print("[EnemyCover] ... enemy PEEKING from cover.")
			# TODO: Play "crouch_peek" animation
		
		# Face the cover point's forward direction when hiding
		# If cover point's +basis.z is INTO cover, and enemy's +Z is its forward, this should be fine.
		enemy_controller.look_at(_target_cover_transform.origin + _target_cover_transform.basis.z, Vector3.UP, true) # Set use_model_front to true here too!
		
	# --- State Transition Logic from Cover ---
	# FUTURE: melee attack
	#var distance_to_player = enemy_controller.global_position.distance_to(player.global_position)
	#if distance_to_player < enemy_controller.melee_attack_range:
		#print("[EnemyCover] Player too close, transitioning to patrol.")
		#transitioned.emit(self, "patrol")
		#return

func physics_update(delta: float) -> Vector3:
	# In cover state, enemy's movement is handled by Tweens
	return Vector3.ZERO

func exit() -> void:
	print("[EnemyCover] ... exited `Cover` state.")
	enemy_controller.leave_cover(enemy_controller.name) # Release the cover spot
	
	# Ensure enemy stands up when leaving cover
	if _crouch_tween and _crouch_tween.is_running():
		_crouch_tween.kill()
	if not is_approximately_equal_float(enemy_controller.global_position.y, _target_cover_transform.origin.y, 0.01):
		_animate_crouch(_target_cover_transform.origin.y) # Stand up
	
	# TODO: Reset animations if any specific cover animations were playing
	# You might want to wait for the stand-up animation to finish before transitioning if it's very quick.

# CLASS-SPECIFIC =========================================

# Helper function for float comparison (to avoid floating point inaccuracies)
func is_approximately_equal_float(a: float, b: float, tolerance: float) -> bool:
	return abs(a - b) < tolerance

func _start_crouch_animation() -> void:
	# Ensure the Y position is based on the target cover transform for consistency
	_crouch_target_y = _target_cover_transform.origin.y - crouch_height_offset
	_animate_crouch(_crouch_target_y)
	# TODO: Play "crouch_idle" animation

func _animate_crouch(target_y: float) -> void:
	#print("_animate_crouch!!")
	if _crouch_tween and _crouch_tween.is_running():
		_crouch_tween.kill()
	
	_crouch_tween = create_tween()
	_crouch_tween.set_trans(Tween.TRANS_SINE)
	_crouch_tween.set_ease(Tween.EASE_OUT)
	_crouch_tween.tween_property(enemy_controller, "global_position:y", target_y, crouch_tween_duration)
