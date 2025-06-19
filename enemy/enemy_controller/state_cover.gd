## state_cover.gd
## DESIGN: 
## - use animations to move the model via croush/stand (aka: dont manipulate the y-axis via code)
## - adjust the height of the Hitbox/CollisionShape3D to align with char model via code
extends EnemyState
class_name EnemyCover

## this animation sequence works!
# CROUCH_RAPID_FIRE > CROUCH_TO_STAND_RIFLE > FIRING_RIFLE > (RELOADING)
# > STAND_TO_CROUCH_RIFLE [then repeat above]

# simple fire loop:
# > STAND_TO_CROUCH_RIFLE > CROUCH_RAPID_FIRE > CROUCH_TO_STAND_RIFLE > FIRING_RIFLE

#region vars
# EXPORT
@export var shoot_from_cover_cooldown: float = 1.0
@export var cover_arrival_tolerance: float = 0.5 # How close enemy needs to be to cover spot
@export var crouch_height_offset: float = 1.0 # How much to lower Y position when crouching (positive value)
@export var crouch_tween_duration: float = 0.2 # How long it takes to crouch/stand up
@export var cover_move_duration: float = 1.5 # How long it takes to move to the cover spot
@export var cover_peek_duration: float = 2.0 # How long to peek out
@export var cover_hide_duration: float = 3.0 # How long to stay hidden
# WIP: CURRENT: Animation Names (can be exported for easier tweaking in editor)
@export var anim_move_to_cover: String = "RUNNING" # e.g., a crouching run or quick movement
@export var anim_taking_cover: String = "STAND_TO_CROUCH_RIFLE"   # This might be the initial crouch down
@export var anim_crouch_idle: String = "CROUCH_IDLE"     # While fully hidden/crouched
@export var anim_peek_up: String = "CROUCH_TO_STAND_RIFLE"         # Transition from hide to peek
@export var anim_aim_down_rifle: String = "FIRING_RIFLE" # When fully peeked and shooting
@export var anim_hide_down: String = "STAND_TO_CROUCH_RIFLE"       # Transition from peek to hide
@export var anim_stand_up: String = "CROUCH_TO_STAND_RIFLE"           # When leaving cover
# ONREADY
@onready var audio_taking_cover: AudioStreamPlayer = $"../../Audio/TakingCover"
# VAR
var _target_cover_transform: Transform3D
var _current_peek_timer: float = 0.0
var _current_hide_timer: float = 0.0
var _is_peeking: bool = false
var _time_since_last_shot_from_cover: float = 0.0
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
	# Assuming enemy's +Z is forward, use use_model_front=true to face into cover
	enemy_controller.look_at(_target_cover_transform.origin + _target_cover_transform.basis.z, Vector3.UP, true)

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
		
		# --- Animation and Collision while peeking ---
		# Assume that when _is_peeking is true, the enemy is either animating UP
		# or is already at the standing height and should be aiming.
		enemy_controller.play_animation(anim_aim_down_rifle)
		enemy_controller.set_collision_to_standing()
		
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
			enemy_controller.play_animation(anim_taking_cover)
			enemy_controller.set_collision_to_crouch()
	
	else: # Hiding behind cover
		_current_hide_timer += delta
		
		# Ensure enemy is at crouched height for hiding
		enemy_controller.play_animation(anim_crouch_idle)
		enemy_controller.set_collision_to_crouch()
		
		# Face the cover point's forward direction when hiding (ensure this is always updated)
		# Assuming cover point's +basis.z is INTO cover
		enemy_controller.look_at(_target_cover_transform.origin + _target_cover_transform.basis.z, Vector3.UP, true) 
		
		if _current_hide_timer >= cover_hide_duration:
			_is_peeking = true
			_current_peek_timer = 0.0
			# Play animation to peek out
			print("[EnemyCover] ... enemy PEEKING from cover.")
			# Animation: Start peeking up
			enemy_controller.play_animation(anim_peek_up)
			enemy_controller.set_collision_to_standing()
		
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

	# reset
	enemy_controller.play_animation(anim_stand_up)
	enemy_controller.set_collision_to_standing()

# CLASS-SPECIFIC =========================================

func _start_crouch_animation() -> void:
	# Ensure the Y position is based on the target cover transform for consistency
	enemy_controller.play_animation(anim_taking_cover)
	enemy_controller.set_collision_to_crouch()
