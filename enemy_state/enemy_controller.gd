extends CharacterBody3D
class_name EnemyController
#
@onready var state_machine = $StateMachine
@onready var idle_state_node: EnemyState = null # Get a reference to the Idle state node so we can access its detection_range. Initialize to null
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var debug_label_state: Label3D = $DEBUG/LabelState
@onready var debug_label_dist: Label3D = $DEBUG/LabelDist
@onready var debug_area_mesh: MeshInstance3D = $DEBUG/DetectionAreaMesh
#
@export var health: int = 100
@export var rotation_speed := 10.0
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

func _ready() -> void:
	# Connect the StateMachine's 'state_changed' signal
	state_machine.state_changed.connect(_on_state_transitioned)
	
	# Find the Idle state node by name from the state machine's children
	if state_machine.has_node("Idle"):
		idle_state_node = state_machine.get_node("Idle") as EnemyState
		if not idle_state_node:
			print("Error: Could not find the 'Idle' state node as an EnemyState child of StateMachine.")
	
	# Trigger the initial state transition to set the label text and run enter()
	if state_machine.current_state:
		_on_state_transitioned(state_machine.current_state, state_machine.current_state.name)
	
	# Set initial visibility for both labels
	if debug_label_state:
		debug_label_state.visible = show_state_debug
		debug_label_dist.visible = show_state_debug
	if debug_area_mesh:
		debug_area_mesh.visible = show_detection_area_debug
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
	# Check if there is significant horizontal movement
	if Vector3(velocity.x, 0, velocity.z).length_squared() > 0.01:
		var target_look_direction = Vector3(velocity.x, 0, velocity.z).normalized()
		var target_angle = atan2(target_look_direction.x, target_look_direction.z)
		var current_angle = rotation.y
		var new_angle = lerp_angle(current_angle, target_angle, delta * rotation_speed)
		rotation.y = new_angle

	# STEP 5:
	draw_idle_detection_area_mesh()
	
	# LAST: Perform the final move and slide calculation once
	move_and_slide()

func draw_idle_detection_area_mesh() -> void:
	if debug_area_mesh and idle_state_node:
		var detection_range = idle_state_node.detection_range
		# The CylinderMesh by default has a radius of 1.0 and height of 1.0.
		# We need to scale it by the desired radius on the X and Z axes.
		debug_area_mesh.scale.x = detection_range * 2
		debug_area_mesh.scale.z = detection_range * 2
		# The Y scale controls the height, which we set to a small value in the mesh settings.
		# We usually don't need to change the Y scale here.
	else:
		debug_area_mesh.visible = false

# ============================================

func _on_state_transitioned(state: EnemyState, new_state_name: String) -> void:
	# 1: Update the text of the Label3D node to show the new state name
	if debug_label_state and show_state_debug:
		debug_label_state.text = new_state_name
	# 2:
	if new_state_name == "Idle":
		idle_state_node = state
	else:
		idle_state_node = null

func take_damage(amount:int) -> void:
	if is_dead:
		return

	health -= amount
	spawn_damage_popup(amount)

	if health <= 0:
		die()
	else:
		animation_player.play("HIT_REACTION")

func die():
	is_dead = true
	velocity = Vector3.ZERO
	state_machine.request_state_change("dead")
	#await animation_player.animation_finished
	#_play_anim_blocking("DYING", func():is_reacting=false)
	# TODO: ^^^ move to state for DIE instead
	#queue_free()

func show_hit(impact_point: Vector3) -> void:
	if not is_dead:
		# You can spawn a blood spurt here later
		print("show_hit: ", impact_point)
		pass

func spawn_damage_popup(amount: int) -> void:
	var popup_scene = preload("res://ui/damage_popup.tscn")
	var popup = popup_scene.instantiate()
	popup.set_popup_data(amount, global_transform.origin + Vector3.UP * 2.0)
	get_tree().root.add_child(popup)
