extends EnemyState
class_name EnemyIdle

# The CharacterBody3D this script controls
@export var enemy: CharacterBody3D
# How fast the enemy moves while wandering
@export var move_speed := 2.5 # Increased speed slightly for more noticeable movement
# This variable is not used in the current wandering logic,
# but could be used to constrain the wander area if needed later.
@export var follow_area := 10

# The current random direction the enemy is moving in
var move_direction: Vector3
# How long the enemy will move in the current direction before picking a new one
var wander_time: float

# Sets a new random horizontal direction and a random time to wander in that direction
func randomize_wander() -> void:
	# Generate a random direction on the XZ plane
	move_direction = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	# Set a random time to continue in this direction
	wander_time = randf_range(2, 5) # Increased time range for longer straight movements

# Called when entering the idle state
func enter() -> void:
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
func physics_update(delta: float) -> void:
	if enemy:
		# Calculate the desired horizontal velocity based on the random direction and move speed
		var desired_velocity = move_direction * move_speed
		# Maintain the existing vertical velocity (important for gravity)
		enemy.velocity.x = desired_velocity.x
		enemy.velocity.z = desired_velocity.z
		# The y velocity is not changed here, so gravity/jumping will still work
