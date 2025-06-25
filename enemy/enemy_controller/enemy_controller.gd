# enemy_controller.gd
# The controller script acts as the central hub for the enemy character's physical presence and actions.
# Its responsibilities include:
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
# WEAPONS
# - Attach weapons to the `BoneAttachment3D`
# - Use `AnimationPlayer` Property tracks to hide/show the weapon
extends CharacterBody3D
class_name EnemyController

signal died

#region vars
# EXPORTS
@export_group("Props")
@export var max_health: int = 100
@export var rotation_speed := 15.0
@export var fade_out_duration = 1.5 # (seconds)
@export_group("Props-Crouch")
@export var standing_box_size_y: float = 2.0  # Target height of the BoxShape3D when standing
@export var standing_shape_pos_y: float = 1.0 # Target Y-offset for center of standing collider from CharacterBody3D's origin (feet)
@export var crouch_box_size_y: float = 1.25   # Target height of the BoxShape3D when crouching
@export var crouch_shape_pos_y: float = 0.7   # Target Y-offset for center of crouched collider from CharacterBody3D's origin (feet)
@export_group("Behavior")
@export var can_patrol: bool = true
@export var can_change_state: bool = true
@export var melee_attack_range: float = 0.1 # TODO: FUTURE:
@export_group("DEBUG")
@export var debug_show_state: bool = false:
	set(value):
		debug_show_state = value
		if debug_label_state:
			debug_label_state.visible = value # update visibility immediately
@export var debug_show_shots: bool = false:
	set(value):
		debug_show_shots = value
		if debug_label_shots:
			debug_label_shots.visible = value # update visibility immediately
@export var debug_show_dist: bool = false:
	set(value):
		debug_show_dist = value
		if debug_label_dist:
			debug_label_dist.visible = value # update visibility immediately
@export var debug_show_position: bool = false:
	set(value):
		debug_show_position = value
		if debug_label_pos:
			# Update the label visibility immediately
			debug_label_pos.visible = value
@export var debug_show_detect_area: bool = false:
	set(value):
		debug_show_detect_area = value
		if debug_area_mesh:
			# Update the mesh visibility immediately
			debug_area_mesh.visible = value
# ONREADY
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var m16_rifle: Node3D = $Armature/Skeleton3D/BoneAttachment3D/m16_assault_rifle_fixed
# ONREADY: state-machine
@onready var state_machine = $StateMachine
@onready var state_node_idle: EnemyState = null # Get a reference to the Idle state node so we can access its detection_range. Initialize to null
@onready var state_node_patrol: EnemyState = null # Get a reference to the Follow state node so we can access its follow_range. Initialize to null
@onready var state_node_follow: EnemyState = null # Get a reference to the Follow state node so we can access its follow_range. Initialize to null
@onready var state_node_attack: EnemyState = null # Get a reference to the Follow state node so we can access its follow_range. Initialize to null
@onready var state_node_cover: EnemyState = null # Get a reference to the Follow state node so we can access its follow_range. Initialize to null
# ONREADY: audio
@onready var audio_projectile_strike: AudioStreamPlayer = $Audio/ProjectileStrike
@onready var audio_death_yell: AudioStreamPlayer = $Audio/DeathYell
@onready var audio_taking_cover: AudioStreamPlayer = $Audio/TakingCover
# ONREADY: FX
@onready var blood_particles_3d: GPUParticles3D = $BloodParticles3D
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
# WIP:
# New properties for cover management
var _current_cover_point: CoverPoint = null
var _current_cover_spot_transform: Transform3D = Transform3D()
var _is_in_cover: bool = false
# vars-debug
@onready var debug_label_state: Label3D = $DEBUG/LabelState
@onready var debug_label_shots: Label3D = $DEBUG/LabelShots
@onready var debug_label_dist: Label3D = $DEBUG/LabelDist
@onready var debug_label_pos: Label3D = $DEBUG/LabelPosition
@onready var debug_area_mesh: MeshInstance3D = $DEBUG/DetectionAreaMesh
# VARS
var _current_target_node: Node3D = null # (can be Player, Marker3D, another enemy, etc.)
var _automatic_target_detection_interval: float = 2.5
var _automatic_target_detection_timer: float = 0.0
var _player_detection_interval: float = 0.5 # (in seconds)
var _player_detection_timer: float = 0.0
var current_health: int = 100
var is_dead := false
var is_initialized = false
var last_known_threat_direction: Vector3 = Vector3.INF
var desired_rotation_direction: Vector3 = Vector3(0, 0, 1)
var total_shots_fired = 0
#endregion

# NODE BUILT-IN FUNCS ============================================

func _ready() -> void:
	# 1: init vars
	current_health = max_health

	# 2: onnect the StateMachine's 'state_changed' signal
	state_machine.state_changed.connect(_on_state_transitioned)
	
	# 3: iterate through the StateMachine's children (your individual state nodes)
	if state_machine: # Ensure state_machine exists
		for child in state_machine.get_children():
			if child is EnemyState: # Check if the child is one of your state scripts
				# Connect the fade_out_requested signal to the new function in this script
				child.fade_out_requested.connect(_on_fade_out_requested)
	
	# 4: find the Idle state node by name from the state machine's children
	if state_machine.has_node("Idle"):
		state_node_idle = state_machine.get_node("Idle") as EnemyState
	elif state_machine.has_node("Patrol"):
		state_node_patrol = state_machine.get_node("Patrol") as EnemyState
	elif state_machine.has_node("Follow"):
		state_node_follow = state_machine.get_node("Follow") as EnemyState
	elif state_machine.has_node("Attack"):
		state_node_attack = state_machine.get_node("Attack") as EnemyState
	elif state_machine.has_node("Cover"):
		state_node_cover = state_machine.get_node("Cover") as EnemyState

	# 5: rigger the initial state transition to set the label text and run enter()
	if state_machine.current_state:
		_on_state_transitioned(state_machine.current_state, state_machine.current_state.name)
	
	# 6: debug inits
	debug_area_mesh.visible = debug_show_detect_area
	debug_label_state.visible = debug_show_state
	debug_label_dist.visible = debug_show_dist
	debug_label_shots.visible = debug_show_shots
	debug_label_pos.visible = debug_show_position
	debug_label_state.text = ""
	debug_label_dist.text = ""
	debug_label_shots.text = ""
	debug_label_pos.text = ""
	# NOTE: make material unique or the prior enemy who faded_out, set the shared resource albedo.a to 0.0!
	var original_material = debug_area_mesh.get_active_material(0)
	if original_material:
		debug_area_mesh.set_material_override(original_material.duplicate())
	_draw_idle_detection_area_mesh()
	
	# 7: set is_init
	if not Engine.is_editor_hint():
		await get_tree().physics_frame
		is_initialized = true
	else:
		is_initialized = true
	
	# 8:
	set_collision_to_standing()

func _process(_delta: float) -> void:
	# --- Make the State Display Label Face Camera ---
	# Only do this if the label exists and the game is running (not in editor physics process)
	if debug_label_state and !Engine.is_editor_hint():
		var camera = get_viewport().get_camera_3d()
		if camera:
			debug_label_state.look_at(camera.global_transform.origin, Vector3.UP)
			debug_label_state.rotation_degrees.y += 180
			debug_label_dist.look_at(camera.global_transform.origin, Vector3.UP)
			debug_label_dist.rotation_degrees.y += 180
			debug_label_shots.look_at(camera.global_transform.origin, Vector3.UP)
			debug_label_shots.rotation_degrees.y += 180
			debug_label_pos.look_at(camera.global_transform.origin, Vector3.UP)
			debug_label_pos.rotation_degrees.y += 180
	# --- End Camera Facing ---
	if debug_label_pos and !Engine.is_editor_hint():
		var pos := global_position
		debug_label_pos.text = "(%.2f, %.2f, %.2f)" % [pos.x, pos.y, pos.z]

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
	_draw_idle_detection_area_mesh()

	# STEP 6: Update player target periodically
	# Only update target automatically if no external target is set OR if the external target is no longer valid
	if _current_target_node == null or not is_instance_valid(_current_target_node):
		_automatic_target_detection_timer += delta
		if _automatic_target_detection_timer >= _automatic_target_detection_interval:
			_automatic_target_detection_timer = 0.0
			_update_automatic_target() # New function for automatic detection
		
	# LAST: Perform the final move and slide calculation once
	# --- IMPORTANT: Do NOT manually set position.y = 0 here ---
	# Allowing move_and_slide() to manage the CharacterBody3D's position.y is crucial.
	# It will automatically snap to the floor/slopes as long as velocity.y accounts for gravity.
	move_and_slide()

# CLASS FUNCS =============================================

func _on_state_transitioned(state: EnemyState, new_state_name: String) -> void:
	#print("[enemy_cont] on_state_tr: ", new_state_name)
	#
	# 1: Update the text of the Label3D node to show the new state name
	if debug_label_state and debug_show_state:
		debug_label_state.text = new_state_name
	# 2:
	state_node_idle = null
	state_node_follow = null
	state_node_patrol = null
	state_node_attack = null
	state_node_cover = null
	if new_state_name.to_lower() == "idle":
		state_node_idle = state
	elif new_state_name.to_lower() == "patrol":
		state_node_patrol = state
	elif new_state_name.to_lower() == "follow":
		state_node_follow = state
	elif new_state_name.to_lower() == "attack":
		state_node_attack = state
	elif new_state_name.to_lower() == "cover":
		state_node_cover = state

# STANDARD ENEMY GAME FUNCS ===============================

## `take_damage` is called by projectiles if implemented (**DONT RENAME**)
func take_damage(amount:int, direction_of_impact: Vector3) -> void:
	# 1:
	if is_dead:
		return
	# 2:
	current_health -= amount
	_spawn_damage_popup(amount)
	# 3:
	if current_health <= 0:
		_handle_died()
	else:
		animation_player.play("HIT_REACTION")
	# 4:
	last_known_threat_direction = -direction_of_impact
	#print("[E_C] Enemy hit from direction: ", last_known_threat_direction)
	# TODO: switch to PATROL state!
	# Optional: If not currently in combat states (Attack, Follow), transition to an investigate/alert state immediately
	# This might be a dedicated state or trigger this investigation behavior in Idle/Patrol.
	# if state_machine.current_state.name.to_lower() != "attack" and state_machine.current_state.name.to_lower() != "follow":
	#     # Transition to a state that prioritizes checking last_known_threat_location
	#     # state_machine.request_state_change("investigate") # Need an investigate state
	#     # Or just rely on Idle/Patrol checking the variable as implemented below
	# 5: sound effect
	audio_projectile_strike.play()

## `show_hit` is called by projectiles if implemented (**DONT RENAME**)
func show_hit(impact_point: Vector3) -> void:
	if not is_dead:
		#print("[enemy_cont] show_hit: ", impact_point)
		blood_particles_3d.global_position = impact_point
		blood_particles_3d.emitting = true

## Getter for states to retrieve the current target
func get_current_target() -> Node3D:
	return _current_target_node

## Function to allow external scripts to set the enemy's target
# Call this from a spawner, an AI manager, or a mission script.
func set_external_target(target: Node3D) -> void:
	if not is_instance_valid(target):
		printerr(name, ": Attempted to set an invalid target. Clearing external target.")
		_current_target_node = null # Clear if invalid
		return
	_current_target_node = target
	print(name, ": Target set externally to: ", target.name)

## Call this if you want the enemy to stop focusing on an external target
## and revert to its default target acquisition (e.g., finding the nearest player).
func clear_external_target() -> void:
	if _current_target_node != null:
		print(name, ": External target cleared. Reverting to automatic target detection.")
	_current_target_node = null

# CLASS-SPECIFIC FUNCS ====================================

## Public method for states to request an attack
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
	#debug_label_shots.text = "FIRE AT\n"+str(target_position)
	debug_label_shots.text = "shots\n"+str(total_shots_fired)

func can_see(target: Node3D, eye_offset := Vector3.UP * 1.5) -> bool:
	if not is_instance_valid(target):
		return false

	var space_state = get_world_3d().direct_space_state
	var origin = global_transform.origin + eye_offset
	var target_pos = target.global_transform.origin + eye_offset

	var query = PhysicsRayQueryParameters3D.create(origin, target_pos)
	query.exclude = [self] # ignore self
	# IMPORTANT: exclude non-player layers, otherwise, items like bullet will interfere!
	query.collision_mask = 17 # (layer 1=world, layer 5=player)

	var result = space_state.intersect_ray(query)
	return result and result.collider == target

## Method to play animations from states
func play_animation(anim_name: String, blend_time: float = -1.0, custom_speed: float = 1.0) -> void:
	if animation_player and animation_player.has_animation(anim_name):
		animation_player.play(anim_name, blend_time, custom_speed)
	else:
		printerr(name, ": Animation '", anim_name, "' not found or AnimationPlayer not valid.")

# PRIVATE FUNCS ===========================================

func _spawn_damage_popup(amount: int) -> void:
	var popup_scene = preload("res://ui/damage_popup.tscn")
	var popup = popup_scene.instantiate()
	popup.set_popup_data(amount, global_transform.origin + Vector3.UP * 2.0)
	get_tree().root.add_child(popup)

func _handle_died() -> void:
	# 1: flag & stop
	is_dead = true
	velocity = Vector3.ZERO
	# 2: set collision to only world (so they dont fall thru the floor)
	self.set_collision_mask(1)
	self.set_collision_layer(0)
	# 3: update state & signal
	state_machine.request_state_change("dead")
	audio_death_yell.play()
	emit_signal("died")
	# LAST: free
	m16_rifle.queue_free()
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
	var mesh_nodes = _find_meshes_in_children(self) # Use the helper function below

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

## Helper function to recursively find meshes
## This function helps find MeshInstance3D nodes nested within the enemy's children (e.g., inside the imported model scene)
func _find_meshes_in_children(node: Node) -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	for child in node.get_children():
		if child is MeshInstance3D:
			meshes.append(child)
		# Recursively search in children
		meshes.append_array(_find_meshes_in_children(child))
	return meshes

# DEBUG/DEV FUNCS =========================================

func _draw_idle_detection_area_mesh() -> void:
	var mat := debug_area_mesh.material_override as StandardMaterial3D
	var target = get_current_target()
	
	if is_dead:
		debug_label_dist.visible = false
		debug_label_shots.visible = false
		debug_area_mesh.visible = false
		return
	
	if debug_show_detect_area and target:
		var distance = global_position.distance_to(target.global_position)
		debug_label_dist.text = "dist\n"+str(snapped(distance, 0.1))+"m"

	if debug_show_detect_area and state_node_idle:
		var detection_range = state_node_idle.detection_range
		# The CylinderMesh by default has a radius of 1.0 and height of 1.0.
		# We need to scale it by the desired radius on the X and Z axes.
		debug_area_mesh.scale.x = detection_range * 2
		debug_area_mesh.scale.z = detection_range * 2
		# The Y scale controls the height, which we set to a small value in the mesh settings.
		# We usually don't need to change the Y scale here.
		debug_area_mesh.visible = true
		mat.albedo_color = Color(0.0, 0.0, 1.0, 0.1)  # blue
	elif debug_show_detect_area and state_node_patrol:
		var detection_range = state_node_patrol.detection_range
		debug_area_mesh.scale.x = detection_range * 2
		debug_area_mesh.scale.z = detection_range * 2
		debug_area_mesh.visible = true
		mat.albedo_color = Color(1.0, 1.0, 0.0, 0.1)  # yellow
	elif debug_show_detect_area and state_node_follow:
		var detection_range = state_node_follow.follow_range
		debug_area_mesh.scale.x = detection_range * 2
		debug_area_mesh.scale.z = detection_range * 2
		debug_area_mesh.visible = true
	elif debug_show_detect_area and state_node_attack:
		var detection_range = state_node_attack.attack_range
		debug_area_mesh.scale.x = detection_range * 2
		debug_area_mesh.scale.z = detection_range * 2
		debug_area_mesh.visible = true
		mat.albedo_color = Color(1.0, 0.0, 0.0, 0.1)  # red
	elif debug_show_detect_area and state_node_cover:
		var detection_range = 1 # state_node_cover.attack_range
		debug_area_mesh.scale.x = detection_range * 2
		debug_area_mesh.scale.z = detection_range * 2
		debug_area_mesh.visible = true
		mat.albedo_color = Color(0.0, 0.0, 1.0, 0.1)  # green
	else:
		debug_area_mesh.visible = false

# WIP: NEW: @@@@@@@@@@@@@@@!!!!!!!!!!!!!!!~~~~~~~~~~~~~~~~~~~

# Call this from your states (e.g., Patrol, Chase) when enemy needs cover
func find_and_go_to_cover(requester_id: String, search_radius: float = 30.0) -> bool:
	var potential_cover_points = get_tree().get_nodes_in_group("cover_points")
	var nearest_cover_point: CoverPoint = null
	var nearest_cover_transform: Transform3D = Transform3D()
	var shortest_distance_to_cover_spot = INF
	print("FYI: potential_cover_points: ", potential_cover_points)
	
	for cp_node in potential_cover_points:
		if cp_node is CoverPoint and cp_node.is_available_for_use:
			var potential_spot_transform = cp_node.get_nearest_available_spot_transform(global_position)
			if potential_spot_transform != Transform3D():
				var dist = global_position.distance_to(potential_spot_transform.origin)
				if dist < shortest_distance_to_cover_spot and dist <= search_radius:
					shortest_distance_to_cover_spot = dist
					nearest_cover_point = cp_node
					nearest_cover_transform = potential_spot_transform
	
	if nearest_cover_point:
		print("FYI: nearest_cover_point: ", nearest_cover_point)
		# Request and reserve the spot from the actual CoverPoint instance
		_current_cover_point = nearest_cover_point
		_current_cover_spot_transform = _current_cover_point.request_nearest_cover_position(requester_id, global_position)
		if _current_cover_spot_transform != Transform3D():
			state_machine.request_state_change("cover")
			return true
	
	# LAST:
	return false

func leave_cover(requester_id: String) -> void:
	if _current_cover_point and is_instance_valid(_current_cover_point):
		_current_cover_point.release_cover_position(requester_id)
		_current_cover_point = null
		_current_cover_spot_transform = Transform3D()
		_is_in_cover = false # Update flag

func get_current_cover_spot_transform() -> Transform3D:
	return _current_cover_spot_transform

# Function to find and set the target automatically (e.g., nearest player in the "player" group)
func _update_automatic_target() -> void:
	var players = get_tree().get_nodes_in_group("player")
	var nearest_distance = INF
	var nearest_found_target: CharacterBody3D = null

	for potential_target in players:
		if potential_target is CharacterBody3D:
			var distance = global_position.distance_to(potential_target.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_found_target = potential_target
	
	# FIXME: TODO:
	# If player, find Marker3D as target!
	#_current_target_node = nearest_found_target.find_child("Head/AimTarget")
	
	_current_target_node = nearest_found_target
	# print(name, ": Automatically updated target to: ", _current_target_node.name if _current_target_node else "None")

# Public Function for states to adjust collision shape to standing dimensions
func set_collision_to_standing():
	if collision_shape_3d and collision_shape_3d.shape is BoxShape3D:
		var box_shape: BoxShape3D = collision_shape_3d.shape as BoxShape3D
		box_shape.size.y = standing_box_size_y
		collision_shape_3d.position.y = standing_shape_pos_y
	else:
		printerr(name, ": CollisionShape3D not found or not a BoxShape3D for standing setup.")

# Public Function for states to adjust collision shape to crouching dimensions
func set_collision_to_crouch():
	if collision_shape_3d and collision_shape_3d.shape is BoxShape3D:
		var box_shape: BoxShape3D = collision_shape_3d.shape as BoxShape3D
		box_shape.size.y = crouch_box_size_y
		collision_shape_3d.position.y = crouch_shape_pos_y
	else:
		printerr(name, ": CollisionShape3D not found or not a BoxShape3D for crouch setup.")
