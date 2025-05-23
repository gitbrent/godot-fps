# enemy_controller.gd
# The controller script should act as the central hub for the enemy character's physical presence and actions. Its responsibilities include:
# - Character Core: 
#     Handling fundamental character properties (health, movement, physics, death).
# - Node References: 
#     Holding @onready references to important child nodes like the AnimationPlayer, 
#     the StateMachine, the visual model, and the weapon node(s).
# - Executing Actions: 
#     Implementing the actual mechanics of actions that the state requests. 
#     This includes the details of how the weapon is fired.
# - Character-Wide Effects: 
#     Handling things like applying damage, playing hit reactions, managing death, 
#     and potentially applying recoil effects to the whole character or just the arms/weapon rig.
extends CharacterBody3D
class_name EnemyController

#region vars
@onready var state_machine = $StateMachine
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var debug_label_state: Label3D = $DEBUG/LabelState
@onready var debug_label_dist: Label3D = $DEBUG/LabelDist
@onready var debug_label_gun: Label3D = $DEBUG/LabelGun
@onready var debug_area_mesh: MeshInstance3D = $DEBUG/DetectionAreaMesh
@onready var state_node_idle: EnemyState = null # Get a reference to the Idle state node so we can access its detection_range. Initialize to null
@onready var state_node_patrol: EnemyState = null # Get a reference to the Follow state node so we can access its follow_range. Initialize to null
@onready var state_node_follow: EnemyState = null # Get a reference to the Follow state node so we can access its follow_range. Initialize to null
@onready var state_node_attack: EnemyState = null # Get a reference to the Follow state node so we can access its follow_range. Initialize to null
@onready var m16_rifle: Node3D = $m16_assault_rifle_fixed
#
@export_group("Props")
@export var health: int = 100
@export var rotation_speed := 15.0
@export var fade_out_duration = 1.5 # (seconds)
@export_group("Behavior")
@export var can_patrol: bool = false
@export_group("DEBUG")
@export var show_state_debug: bool = true:
	set(value):
		show_state_debug = value
		if debug_label_state:
			debug_label_state.visible = show_state_debug
@export var show_detection_area_debug: bool = true:
	set(value):
		show_detection_area_debug = value
		# Update the mesh visibility immediately
		if debug_area_mesh:
			debug_area_mesh.visible = value
#
var is_dead := false
var is_initialized = false
var last_known_threat_location: Vector3 = Vector3.INF
var desired_rotation_direction: Vector3 = Vector3(0, 0, 1)
var total_shots_fired = 0
#endregion

func _ready() -> void:
	# Connect the StateMachine's 'state_changed' signal
	state_machine.state_changed.connect(_on_state_transitioned)
	
	# Iterate through the StateMachine's children (your individual state nodes)
	if state_machine: # Ensure state_machine exists
		for child in state_machine.get_children():
			if child is EnemyState: # Check if the child is one of your state scripts
				# Connect the fade_out_requested signal to the new function in this script
				child.fade_out_requested.connect(_on_fade_out_requested)
	
	# Find the Idle state node by name from the state machine's children
	if state_machine.has_node("Idle"):
		state_node_idle = state_machine.get_node("Idle") as EnemyState
	elif state_machine.has_node("Patrol"):
		state_node_patrol = state_machine.get_node("Patrol") as EnemyState
	elif state_machine.has_node("Follow"):
		state_node_follow = state_machine.get_node("Follow") as EnemyState
	elif state_machine.has_node("Attack"):
		state_node_attack = state_machine.get_node("Attack") as EnemyState

	# Trigger the initial state transition to set the label text and run enter()
	if state_machine.current_state:
		_on_state_transitioned(state_machine.current_state, state_machine.current_state.name)
	
	# Set initial visibility for debugs
	if debug_label_state:
		debug_label_state.visible = show_state_debug
		debug_label_dist.visible = show_state_debug
		debug_label_gun.visible = show_state_debug
		
	if debug_area_mesh:
		debug_area_mesh.visible = show_detection_area_debug
		# make material unique or the prior enemy who faded_out, set the shared resource albedo.a to 0.0!
		var original_material = debug_area_mesh.get_active_material(0)
		if original_material:
			debug_area_mesh.set_material_override(original_material.duplicate())
		# Set the initial scale of the mesh based on the detection range
		draw_idle_detection_area_mesh()
	
	if not Engine.is_editor_hint():
		await get_tree().physics_frame
		is_initialized = true
	else:
		is_initialized = true

func _process(delta: float) -> void:
	# --- Make the State Display Label Face Camera ---
	# Only do this if the label exists and the game is running (not in editor physics process)
	if debug_label_state and !Engine.is_editor_hint():
		var camera = get_viewport().get_camera_3d()
		if camera:
			debug_label_state.look_at(camera.global_transform.origin, Vector3.UP)
			debug_label_state.rotation_degrees.y += 180
			debug_label_dist.look_at(camera.global_transform.origin, Vector3.UP)
			debug_label_dist.rotation_degrees.y += 180
			debug_label_gun.look_at(camera.global_transform.origin, Vector3.UP)
			debug_label_gun.rotation_degrees.y += 180
	# --- End Camera Facing ---

func _physics_process(delta: float) -> void:
	# STEP 1: Add the gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# STEP 2:
	var desired_horizontal_velocity = Vector3.ZERO
	if is_initialized and state_machine.current_state:
		desired_horizontal_velocity = state_machine.current_state.physics_update(delta)
	
	# STEP 3:
	velocity.x = desired_horizontal_velocity.x
	velocity.z = desired_horizontal_velocity.z

	# STEP 4: Handle Rotation
	var current_move_direction_horizontal = Vector3(velocity.x, 0, velocity.z)
	var direction_to_face = current_move_direction_horizontal # Default to using movement direction
	# If not currently moving horizontally, use the state's desired rotation direction
	# Check if the horizontal velocity is negligible (i.e., the character is standing still horizontally)
	if current_move_direction_horizontal.length_squared() < 0.001:
		# If standing still horizontally, use the desired rotation direction provided by the current state
		if is_initialized and state_machine.current_state:
			direction_to_face = state_machine.current_state.desired_rotation_direction
		# Else (not initialized or no state), 'direction_to_face' remains the zero velocity vector,
		# and the subsequent check will prevent rotation.
	# Else (if moving horizontally), 'direction_to_face' remains the horizontal velocity vector,
	# and the character will rotate to face its movement direction (as before).
	#
	# Ensure the direction to face is not a zero vector before calculating angle
	# This prevents errors if the state hasn't set a desired_rotation_direction yet or if velocity is zero
	if direction_to_face.length_squared() > 0.001:
		# Calculate the target angle (angle around the Y-axis) from the direction to face
		var target_angle = atan2(direction_to_face.x, direction_to_face.z)
		# Get the current rotation around the Y-axis
		var current_angle = rotation.y
		# Lerp (linear interpolation) the current angle towards the target angle for smooth rotation
		# Use lerp_angle for correct interpolation across the -PI to PI boundary
		var new_angle = lerp_angle(current_angle, target_angle, delta * rotation_speed)
		# Apply the new rotation to the enemy controller
		rotation.y = new_angle
	
	# STEP 5:
	draw_idle_detection_area_mesh()
	
	# LAST: Perform the final move and slide calculation once
	move_and_slide()

func _on_state_transitioned(state: EnemyState, new_state_name: String) -> void:
	#print("[enemy_cont] on_state_tr: ", new_state_name)
	#
	# 1: Update the text of the Label3D node to show the new state name
	if debug_label_state and show_state_debug:
		debug_label_state.text = new_state_name
	# 2:
	state_node_idle = null
	state_node_follow = null
	state_node_patrol = null
	state_node_attack = null
	if new_state_name.to_lower() == "idle":
		state_node_idle = state
	elif new_state_name.to_lower() == "patrol":
		state_node_patrol = state
	elif new_state_name.to_lower() == "follow":
		state_node_follow = state
	elif new_state_name.to_lower() == "attack":
		state_node_attack = state

# STANDARD GAME FUNCS ==========================================

## `take_damage` is called by projectiles if implemented (**DONT RENAME**)
func take_damage(amount:int) -> void:
	# 1:
	if is_dead:
		return
	# 2:
	health -= amount
	spawn_damage_popup(amount)
	# 3:
	if health <= 0:
		handle_died()
	else:
		animation_player.play("HIT_REACTION")

## `show_hit` is called by projectiles if implemented (**DONT RENAME**)
func show_hit(impact_point: Vector3) -> void:
	if not is_dead:
		# You can spawn a blood spurt here later
		print("[enemy_cont] show_hit: ", impact_point)
		pass

# CLASS-SPECIFIC FUNCS ============================================

# Public method for states to request an attack
func fire_weapon(target_position: Vector3) -> void:
	# 1: cannot fire if dead
	if is_dead:
		return
	# 2: firing logic
	var fire_result = m16_rifle.request_fire(target_position)
	if fire_result:
		total_shots_fired += 1
	#print("Enemy fired at position: ", target_position) # Placeholder print
	# 3: debug
	#debug_label_gun.text = "FIRE AT\n"+str(target_position)
	debug_label_gun.text = "shots\n"+str(total_shots_fired)

# Private funcs

func can_see(target: Node3D, eye_offset := Vector3.UP * 1.5) -> bool:
	if not is_instance_valid(target):
		return false

	var space_state = get_world_3d().direct_space_state
	var origin = global_transform.origin + eye_offset
	var target_pos = target.global_transform.origin + eye_offset

	var query = PhysicsRayQueryParameters3D.create(origin, target_pos)
	query.exclude = [self]  # ignore self
	# query.collision_mask = 1  # use if needed to restrict what "blocks" vision

	var result = space_state.intersect_ray(query)
	return result and result.collider == target

func spawn_damage_popup(amount: int) -> void:
	var popup_scene = preload("res://ui/damage_popup.tscn")
	var popup = popup_scene.instantiate()
	popup.set_popup_data(amount, global_transform.origin + Vector3.UP * 2.0)
	get_tree().root.add_child(popup)

func handle_died():
	is_dead = true
	velocity = Vector3.ZERO
	state_machine.request_state_change("dead")
	#await animation_player.animation_finished
	#_play_anim_blocking("DYING", func():is_reacting=false)
	# TODO: ^^^ move to state for DIE instead
	#queue_free()

func _on_fade_out_requested() -> void:
	# Disable physics and collision so the dead enemy doesn't interact anymore
	set_physics_process(false)
	set_process(false) # Stop _process updates (like camera facing if it's still active here)
	# You might also want to disable specific collision layers/masks
	# set_collision_mask_value(your_layer, false)
	# set_collision_layer_value(your_layer, false)
	# If you have a CollisionShape3D directly, you can disable it:
	# if $CollisionShape3D: $CollisionShape3D.disabled = true # Adjust path if needed

	# Find all MeshInstance3D nodes that are children (recursive search needed)
	var mesh_nodes = find_meshes_in_children(self) # Use the helper function below

	var tween = create_tween()
	var meshes_found = false # Flag to track if we found meshes to fade

	for mesh in mesh_nodes:
		# Ensure the mesh has a valid mesh resource
		if !mesh.mesh:
			continue

		# Iterate through all surfaces of the mesh
		# Use get_active_material to get the material considering overrides
		for surface_idx in range(mesh.mesh.get_surface_count()):
			var material = mesh.get_active_material(surface_idx)

			if material is StandardMaterial3D:
				# IMPORTANT: For fading, the material needs to have its Transparency
				# property set to "Alpha" or "Alpha Dither" in the Inspector or via script.
				# If it's Opaque, tweening alpha won't work visually.

				# Tween the albedo color's alpha to 0.0 for fading
				# The parallel() makes all these tweens run simultaneously
				tween.parallel().tween_property(material, "albedo_color:a", 0.0, fade_out_duration)
				meshes_found = true # Mark that we found at least one mesh to fade

			# Add checks for other material types if your model uses them
			# If you have materials that use the "Modulate" color (like some imported types),
			# you might need to tween mesh.modulate.a instead, but StandardMaterial3D is common.

	# Queue free the enemy node after the fade tween finishes
	# Only queue_free if a tween was created (i.e., if there were meshes to fade)
	if meshes_found:
		tween.tween_callback(func(): queue_free())
	else:
		# If no meshes were found to fade, just queue_free immediately
		print("No meshes found to fade, queue_freeing immediately.")
		queue_free()

# --- Add the helper function to recursively find meshes ---
# This function helps find MeshInstance3D nodes nested within the enemy's children (e.g., inside the imported model scene)
func find_meshes_in_children(node: Node) -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	for child in node.get_children():
		if child is MeshInstance3D:
			meshes.append(child)
		# Recursively search in children
		meshes.append_array(find_meshes_in_children(child))
	return meshes

# DEBUG/FYI FUNCS ==================================================

func draw_idle_detection_area_mesh() -> void:
	var mat := debug_area_mesh.material_override as StandardMaterial3D

	if is_dead:
		debug_label_dist.visible = false
		debug_label_gun.visible = false
		debug_area_mesh.visible = false
		return
	
	if show_detection_area_debug:
		var players = get_tree().get_nodes_in_group("player")
		var nearest_player: CharacterBody3D = null
		for player in players:
			if player is CharacterBody3D:
				var distance = global_position.distance_to(player.global_position)
				debug_label_dist.text = "dist\n"+str(snapped(distance, 0.1))+"m"

	if debug_area_mesh and state_node_idle:
		var detection_range = state_node_idle.detection_range
		# The CylinderMesh by default has a radius of 1.0 and height of 1.0.
		# We need to scale it by the desired radius on the X and Z axes.
		debug_area_mesh.scale.x = detection_range * 2
		debug_area_mesh.scale.z = detection_range * 2
		# The Y scale controls the height, which we set to a small value in the mesh settings.
		# We usually don't need to change the Y scale here.
		debug_area_mesh.visible = true
		mat.albedo_color = Color(0.0, 0.0, 1.0, 0.1)  # blue
	elif debug_area_mesh and state_node_patrol:
		var detection_range = state_node_patrol.detection_range
		debug_area_mesh.scale.x = detection_range * 2
		debug_area_mesh.scale.z = detection_range * 2
		debug_area_mesh.visible = true
		mat.albedo_color = Color(1.0, 1.0, 0.0, 0.1)  # yellow
	elif debug_area_mesh and state_node_follow:
		var detection_range = state_node_follow.follow_range
		debug_area_mesh.scale.x = detection_range * 2
		debug_area_mesh.scale.z = detection_range * 2
		debug_area_mesh.visible = true
	elif debug_area_mesh and state_node_attack:
		var detection_range = state_node_attack.attack_range
		debug_area_mesh.scale.x = detection_range * 2
		debug_area_mesh.scale.z = detection_range * 2
		debug_area_mesh.visible = true
		mat.albedo_color = Color(1.0, 0.0, 0.0, 0.1)  # red
	else:
		debug_area_mesh.visible = false
