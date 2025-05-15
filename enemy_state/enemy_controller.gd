extends CharacterBody3D
class_name EnemyController
#
@onready var state_machine = $StateMachine
@onready var idle_state_node: EnemyState = null # Get a reference to the Idle state node so we can access its detection_range. Initialize to null
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var debug_state_label = $DEBUG/StateDisplay
@onready var debug_area_mesh: MeshInstance3D = $DEBUG/DetectionAreaMesh
#
@export var health: int = 100
@export var rotation_speed := 10.0
@export var show_state_debug: bool = true:
	set(value):
		show_state_debug = value
		if debug_state_label:
			debug_state_label.visible = show_state_debug
@export var show_detection_area_debug: bool = true:
	set(value):
		show_detection_area_debug = value
		# Update the mesh visibility immediately
		if debug_area_mesh:
			debug_area_mesh.visible = value
#
var is_dead := false
var is_initialized = false # Keep the initialization flag

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
	if debug_state_label:
		debug_state_label.visible = show_state_debug
	if debug_area_mesh:
		debug_area_mesh.visible = show_detection_area_debug
		# Set the initial scale of the mesh based on the detection range
		update_detection_area_mesh_scale()
	
	if not Engine.is_editor_hint():
		await get_tree().physics_frame
		is_initialized = true
	else:
		is_initialized = true

func _physics_process(delta: float) -> void:
	# STEP 1: Only run physics logic if not in editor hint mode
	if Engine.is_editor_hint():
		return
	
	# STEP 2: Add the gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# STEP 3:
	var desired_horizontal_velocity = Vector3.ZERO
	if is_initialized and state_machine.current_state:
		desired_horizontal_velocity = state_machine.current_state.physics_update(delta)
	
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

	# LAST: Perform the final move and slide calculation once
	move_and_slide()

# New function to update the scale of the detection area mesh
func update_detection_area_mesh_scale() -> void:
	if debug_area_mesh and idle_state_node:
		var detection_range = idle_state_node.detection_range
		# The CylinderMesh by default has a radius of 1.0 and height of 1.0.
		# We need to scale it by the desired radius on the X and Z axes.
		debug_area_mesh.scale.x = detection_range
		debug_area_mesh.scale.z = detection_range
		# The Y scale controls the height, which we set to a small value in the mesh settings.
		# We usually don't need to change the Y scale here.

# ============================================

# Function called when the state machine transitions to a new state
func _on_state_transitioned(state: EnemyState, new_state_name: String) -> void:
	# Update the text of the Label3D node to show the new state name
	if debug_state_label and show_state_debug:
		debug_state_label.text = new_state_name

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
