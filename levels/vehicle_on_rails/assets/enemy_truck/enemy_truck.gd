extends CharacterBody3D

#region vars
@export_group("Props: Core")
@export var vehicle_health = 100
@export var broken_model: PackedScene = preload("res://levels/vehicle_on_rails/assets/enemy_truck/enemy_truck_exploded.tscn")
@export_group("Props: Movement")
@export var speed = 15.0
@export var turn_speed = 3.0 # How quickly the truck can turn towards its target. Higher is sharper.
@export var follow_distance = 8.0
@export var weave_amplitude = 3.0
@export var weave_speed = 2.0
@export var ahead_distance = 10.0 
@export var stop_distance = 1.0 # Distance at which the truck fully stops and holds orientation
@export var yaw_offset_degrees = 0.0 # For final visual adjustment (e.g., 90, -90, 180)
@export_group("DEBUG")
@export var debug_show_health: bool = false:
	set(value):
		debug_show_health = value
		if debug_label_health:
			# Update the label visibility immediately
			debug_label_health.visible = value
# ONREADY
@onready var sketchfab_model: Node3D = $Sketchfab_model
@onready var enemy_controller: EnemyController = $EnemyController
@onready var debug_label_health: Label3D = $Debug/DebugLabelHealth
@onready var smoke_effect_1: Node3D = $SmokeEffect1
@onready var smoke_effect_2: Node3D = $SmokeEffect2
# PRIVATE VARS
var player_vehicle: Node3D = null
var rng = RandomNumberGenerator.new()
var is_dead = false
var curr_vehicle_health = 0
#endregion

# NODE BUILT-IN FUNCS ============================================

func _ready() -> void:
	# 1: UI defaults
	curr_vehicle_health = vehicle_health
	smoke_effect_1.visible = false
	smoke_effect_2.visible = false
	# 1:
	var player_nodes = get_tree().get_nodes_in_group("player_vehicle")
	if not player_nodes.is_empty():
		player_vehicle = player_nodes[0]
	# 2:
	enemy_controller.state_machine.request_state_change('attack')
	enemy_controller.can_patrol = false
	enemy_controller.can_change_state = false
	# 3:
	debug_label_health.text = str(vehicle_health)

func _physics_process(delta) -> void:
	if is_dead: # NEW: Don't process movement if dead
		return
		
	if not player_vehicle:
		return

	# --- 1. Calculate Target ---
	var target_position = player_vehicle.global_position + (-player_vehicle.global_transform.basis.z * ahead_distance)
	
	var time = Time.get_ticks_msec() / 1000.0
	var weave_value = sin(time * weave_speed) * weave_amplitude
	target_position += player_vehicle.global_transform.basis.x * weave_value
	
	# --- 2. Calculate Desired Movement Direction (only in XZ plane) ---
	var current_distance_to_target = global_position.distance_to(target_position)
	var desired_movement_direction = Vector3.ZERO 

	if current_distance_to_target > stop_distance:
		desired_movement_direction = global_position.direction_to(target_position)
		desired_movement_direction.y = 0 
		desired_movement_direction = desired_movement_direction.normalized()
	
	# --- 3. Steering/Rotation Logic: Direct Basis Manipulation ---
	# Only rotate if there's a valid direction to move towards or if we're not completely stopped
	# This ensures it holds its last facing direction when fully stopped rather than snapping
	if desired_movement_direction.length_squared() > 0.0001 or velocity.length_squared() > 0.0001: 
		var current_truck_forward = transform.basis.z # Truck's visual +Z is forward
		
		# Smoothly interpolate the truck's current forward to the desired movement direction
		var interpolated_forward = current_truck_forward.slerp(desired_movement_direction, turn_speed * delta)
		
		if interpolated_forward.length_squared() < 0.0001:
			interpolated_forward = current_truck_forward
		else:
			interpolated_forward = interpolated_forward.normalized()
		
		# Create a new basis where the Godot node's -Z points towards interpolated_forward
		# This effectively makes the node's +Z (your truck's front) point towards interpolated_forward.
		# If it's still 180 degrees off, then you'd use `interpolated_forward` directly here:
		var new_basis = Basis.looking_at(-interpolated_forward, Vector3.UP) # OR Basis.looking_at(interpolated_forward, Vector3.UP) depending on your yaw_offset setting
		
		transform.basis = new_basis
		
		# Apply the final visual yaw offset if set (for the 90-degree issue)
		if yaw_offset_degrees != 0.0:
			transform = transform.rotated(Vector3.UP, deg_to_rad(yaw_offset_degrees))
	
	# --- 4. Movement Logic ---
	if current_distance_to_target > follow_distance:
		velocity = desired_movement_direction * speed
	elif current_distance_to_target > stop_distance:
		var slowdown_factor = (current_distance_to_target - stop_distance) / (follow_distance - stop_distance)
		velocity = desired_movement_direction * speed * slowdown_factor
	else:
		velocity = Vector3.ZERO

	move_and_slide()

# CLASS FUNCS =============================================

func _handle_damage(amount: int) -> void:
	if is_dead:
		return
	
	# 1: take damage
	curr_vehicle_health -= amount
	
	# 2: debug
	debug_label_health.text = str(curr_vehicle_health)
	
	# 3:
	if curr_vehicle_health <= 0:
		_handle_die()
	elif curr_vehicle_health < (vehicle_health * 0.75):
		smoke_effect_1.visible = true
		smoke_effect_2.visible = true
	elif curr_vehicle_health < (vehicle_health * 0.55):
		pass
		# TODO: show FIRE


func _handle_die() -> void:
	# ----------------
	# FIRST: Prevent calling die multiple times
	# ----------------
	if is_dead:
		return
	is_dead = true
	# ----------------
	# 1: stop movement and collisions
	# ----------------
	# 1.a. Stop movement immediately
	velocity = Vector3.ZERO
	set_physics_process(false)
	# 1.b. Make the truck non-collidable (prevents open "air" space from stopping other bodies)
	set_collision_layer(0)
	set_collision_mask(0)
	# ----------------
	# 2: Instantiate and position the broken model
	# ----------------
	if not broken_model:
		printerr("Broken model scene not set!")
	else:
		var broken_model_inst = broken_model.instantiate()
		get_parent().add_child(broken_model_inst)
		# Ensure the exploded version appears exactly where the old one was
		broken_model_inst.global_transform = self.global_transform
		broken_model_inst.do_explode()
	# ----------------
	# LAST: free node
	# ----------------
	#sketchfab_model.visible = false
	queue_free()

# CLASS SIGNALS =============================================

func _on_area_3d_body_entered(body: Node3D) -> void:
	_handle_damage(10) # TODO: hard-coded for now [gun should send]
