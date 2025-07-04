extends CharacterBody3D

signal enemy_truck_hit

# --- Movement Parameters ---
@export var speed = 10.0
## How quickly the truck can turn towards its target. Higher is sharper.
@export var turn_speed = 3.0
@export var follow_distance = 15.0
@export var weave_amplitude = 4.0
@export var weave_speed = 2.0
@export var ahead_distance = 10.0 # NEW: How far ahead of the player the target point is

# --- Private Variables ---
var player_vehicle: Node3D = null
var rng = RandomNumberGenerator.new()


func _ready():
	var player_nodes = get_tree().get_nodes_in_group("player_vehicle")
	if not player_nodes.is_empty():
		player_vehicle = player_nodes[0]
	
	# No longer need target_offset initialized here, as it's dynamic


func _physics_process(delta):
	if not player_vehicle:
		return

	# --- 1. Calculate Target ---
	# Calculate a target point ahead of the player vehicle.
	# The player's forward direction is typically -Z.
	var target_position = player_vehicle.global_position + (-player_vehicle.global_transform.basis.z * ahead_distance)
	
	# Add a weaving offset to the target position, relative to the player's right vector.
	var time = Time.get_ticks_msec() / 1000.0
	var weave_value = sin(time * weave_speed) * weave_amplitude
	target_position += player_vehicle.global_transform.basis.x * weave_value
	
	# --- 2. Direction to Target ---
	var direction_to_target = global_position.direction_to(target_position)

	# --- 3. Steering Logic ---
	# Smoothly interpolate the truck's forward vector towards the target direction.
	# Godot's forward is -Z.
	var current_forward_vector = -transform.basis.z
	var new_forward_vector = current_forward_vector.slerp(direction_to_target, turn_speed * delta)
	
	# Ensure the new_forward_vector has some length to avoid issues with zero vectors
	if new_forward_vector.length_squared() < 0.0001: # Small epsilon
		new_forward_vector = current_forward_vector # Stick with current if target is too close/same
	else:
		new_forward_vector = new_forward_vector.normalized()

	# Apply the new rotation, ensuring the truck stays upright.
	# Use look_at with an up vector to prevent tilting.
	transform = transform.looking_at(global_position + new_forward_vector, Vector3.UP)

	# --- 4. Movement Logic ---
	# Calculate the desired velocity towards the target position
	var desired_velocity = (target_position - global_position).normalized() * speed
	
	# Optionally, you can add a "stop" condition if within follow_distance,
	# but for a pursuit, you might just want to slow down.
	if global_position.distance_to(target_position) < follow_distance:
		# If within follow_distance, reduce speed or just maintain position
		desired_velocity = Vector3.ZERO # Or slow down: desired_velocity *= 0.5 
		pass # Or just let it overshoot a bit and correct

	velocity = desired_velocity
	move_and_slide()


func _on_area_3d_body_entered(body: Node3D) -> void:
	print("ENEMY_TRUCK_AREA hit with a bullet!")
	emit_signal("enemy_truck_hit")
