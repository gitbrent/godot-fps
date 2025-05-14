extends CharacterBody3D
class_name EnemyController
#
@onready var state_machine = $StateMachine
@onready var state_display_label = $DBG_StateDisplay
@onready var animation_player: AnimationPlayer = $AnimationPlayer
#
@export var health: int = 100
@export var show_state_debug: bool = true:
	set(value):
		show_state_debug = value
		if state_display_label:
			state_display_label.visible = show_state_debug
#
var is_dead := false

func _ready() -> void:
	# Connect the StateMachine's 'transitioned' signal to a function in this script
	state_machine.state_changed.connect(_on_state_transitioned)
	# Set the initial visibility of the label based on the export variable
	if state_display_label:
		state_display_label.visible = show_state_debug
		# Also set the initial text
		if state_machine.current_state:
			state_display_label.text = state_machine.current_state.name

func _physics_process(delta: float) -> void:
	# STEP 1: Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	# LAST:
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
