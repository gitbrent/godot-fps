extends CharacterBody3D
class_name EnemyController
#
@onready var state_machine = $StateMachine
@onready var state_display_label = $DBG_StateDisplay
@onready var animation_player: AnimationPlayer = $AnimationPlayer
#
@export var health: int = 100
@export var rotation_speed := 10.0
@export var show_state_debug: bool = true:
	set(value):
		show_state_debug = value
		if state_display_label:
			state_display_label.visible = show_state_debug
#
var is_dead := false
var is_initialized = false # Keep the initialization flag

func _ready() -> void:
	# Connect the StateMachine's 'transitioned' signal to a function in this script
	state_machine.state_changed.connect(_on_state_transitioned)
	# Set the initial visibility of the label based on the export variable
	if state_display_label:
		state_display_label.visible = show_state_debug
	
	# Trigger the initial state transition to set the label text and run enter()
	if state_machine.current_state:
		# Manually call the transition function for the initial state
		_on_state_transitioned(state_machine.current_state, state_machine.current_state.name)
	
	# --- Keep Initialization Delay ---
	await get_tree().physics_frame
	is_initialized = true
	# --- End Initialization Delay ---

func _physics_process(delta: float) -> void:
	# STEP 1: Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# --- Get Desired Horizontal Velocity from State ---
	var desired_horizontal_velocity = Vector3.ZERO
	# Ensure the state machine is initialized and has a current state before asking for movement
	if is_initialized and state_machine.current_state:
		# Call the current state's physics_update to get the desired horizontal movement
		desired_horizontal_velocity = state_machine.current_state.physics_update(delta)

	# --- Apply Horizontal Velocity ---
	# Set the horizontal components of the CharacterBody3D's velocity
	velocity.x = desired_horizontal_velocity.x
	velocity.z = desired_horizontal_velocity.z

	# --- Handle Rotation (if you added this) ---
	# Check if there is significant horizontal movement
	if Vector3(velocity.x, 0, velocity.z).length_squared() > 0.01:
		var target_look_direction = Vector3(velocity.x, 0, velocity.z).normalized()
		var target_angle = atan2(target_look_direction.x, target_look_direction.z)
		var current_angle = rotation.y
		var new_angle = lerp_angle(current_angle, target_angle, delta * rotation_speed)
		rotation.y = new_angle

	# LAST: Perform the final move and slide calculation once
	move_and_slide()

# Function called when the state machine transitions to a new state
func _on_state_transitioned(state: EnemyState, new_state_name: String) -> void:
	# Update the text of the Label3D node to show the new state name
	if state_display_label and show_state_debug:
		state_display_label.text = new_state_name

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
