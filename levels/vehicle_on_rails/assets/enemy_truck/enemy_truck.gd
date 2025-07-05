extends CharacterBody3D

signal enemy_truck_hit

# --- Movement Parameters ---
@export var speed = 10.0
## How quickly the truck can turn towards its target. Higher is sharper.
@export var turn_speed = 3.0
@export var follow_distance = 5.0
@export var weave_amplitude = 4.0
@export var weave_speed = 2.0
@export var ahead_distance = 10.0 
@export var stop_distance = 1.0 # NEW: Distance at which the truck fully stops and holds orientation

# --- Private Variables ---
var player_vehicle: Node3D = null
var rng = RandomNumberGenerator.new()


func _ready():
	var player_nodes = get_tree().get_nodes_in_group("player_vehicle")
	if not player_nodes.is_empty():
		player_vehicle = player_nodes[0]


func _physics_process(delta):
	if not player_vehicle:
		return

	# --- 1. Calculate Target ---
	var target_position = player_vehicle.global_position + (-player_vehicle.global_transform.basis.z * ahead_distance)
	
	var time = Time.get_ticks_msec() / 1000.0
	var weave_value = sin(time * weave_speed) * weave_amplitude
	target_position += player_vehicle.global_transform.basis.x * weave_value
	
	# --- 2. Calculate Desired Movement Direction ---
	var current_distance_to_target = global_position.distance_to(target_position)
	var desired_movement_direction = Vector3.ZERO # Initialize to zero, will be set if moving

	if current_distance_to_target > stop_distance:
		# Only calculate a movement direction if we're further than stop_distance
		desired_movement_direction = global_position.direction_to(target_position)
	
	# --- 3. Steering/Rotation Logic ---
	# Only rotate if there's a valid direction to move towards
	if desired_movement_direction.length_squared() > 0.0001: # Check for non-zero direction
		var current_truck_forward = transform.basis.z # Truck's visual +Z is forward
		
		# Smoothly interpolate the truck's current forward to the desired movement direction
		var new_truck_forward = current_truck_forward.slerp(desired_movement_direction, turn_speed * delta)
		
		# Ensure the new_truck_forward has some length (should be handled by length_squared check above, but good practice)
		if new_truck_forward.length_squared() < 0.0001:
			new_truck_forward = current_truck_forward
		else:
			new_truck_forward = new_truck_forward.normalized()
		
		# Apply the rotation. 'looking_at' makes the node's +Z axis point at the target.
		#transform = transform.looking_at(global_position + new_truck_forward, Vector3.UP)
	
	# --- 4. Movement Logic ---
	# Set velocity based on desired movement direction and distance to target
	if current_distance_to_target > follow_distance:
		# If far away, move at full speed towards the target
		velocity = desired_movement_direction * speed
	elif current_distance_to_target > stop_distance:
		# If within follow_distance but not yet at stop_distance, slow down
		# Scale speed linearly or with a curve based on distance
		var slowdown_factor = (current_distance_to_target - stop_distance) / (follow_distance - stop_distance)
		velocity = desired_movement_direction * speed * slowdown_factor
	else:
		# If at or within stop_distance, stop completely
		velocity = Vector3.ZERO

	move_and_slide()


func _on_area_3d_body_entered(body: Node3D) -> void:
	print("ENEMY_TRUCK_AREA hit with a bullet!")
	emit_signal("enemy_truck_hit")
