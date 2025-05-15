extends EnemyState
class_name EnemyIdle

@export var move_speed := 2.5 # Increased speed slightly for more noticeable movement
@export var follow_area := 10

# The current random direction the enemy is moving in
var move_direction: Vector3
# How long the enemy will move in the current direction before picking a new one
var wander_time: float

@onready var animation_player: AnimationPlayer = $"../../AnimationPlayer"

func enter() -> void:
	animation_player.play("WALKING")
	randomize_wander()

# Called every frame (can be used for non-physics related logic)
func update(delta: float) -> void:
	# Countdown the wander time
	if wander_time > 0:
		wander_time -= delta
	else:
		# If wander time is up, pick a new random direction and time
		randomize_wander()

# Called every physics frame (use for movement and physics calculations)
func physics_update(delta: float) -> Vector3:
	if enemy_controller:
		# Calculate the desired horizontal velocity based on the random direction and move speed
		# Maintain the existing vertical velocity (important for gravity)
		# The y velocity is not changed here, so gravity/jumping will still work
		return move_direction * move_speed
	return Vector3.ZERO

# UNIQUE CLASS FUNCS ---------------------------------

# Sets a new random horizontal direction and a random time to wander in that direction
func randomize_wander() -> void:
	# Generate a random direction on the XZ plane
	move_direction = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	# Set a random time to continue in this direction
	wander_time = randf_range(2, 5) # Increased time range for longer straight movements
