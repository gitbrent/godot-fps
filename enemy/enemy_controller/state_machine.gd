## state_machine.gd
## - The StateMachine's parent is the `EnemyController`.
extends Node

signal state_changed(state:EnemyState, new_state_name: String)

@export var initial_state: EnemyState
var current_state: EnemyState
var states: Dictionary = {}
var enemy_controller_ref: CharacterBody3D = null

func _ready() -> void:
	# 1: get ref to parent enemy controller
	# doing this porgramatilcally is superior to using Properties
	if get_parent() is CharacterBody3D:
		enemy_controller_ref = get_parent()
	
	for child in get_children():
		if child is EnemyState:
			states[child.name.to_lower()] = child
			child.enemy_controller = enemy_controller_ref
			child.transitioned.connect(on_child_transitioned)
	
	if initial_state:
		initial_state.enter()
		current_state = initial_state
		state_changed.emit(current_state, current_state.name)

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

## This function is called when a state *child* emits its transitioned signal
func on_child_transitioned(state:EnemyState, new_state_name:String):
	if state != current_state:
		return
	request_state_change(new_state_name)

## Public method to request a state change by name
func request_state_change(state_name: String) -> void:
	var new_state = states.get(state_name.to_lower())
	if !new_state:
		# Optionally print a warning if the state name is not found
		print("Warning: State '" + state_name + "' not found in StateMachine.")
		return
	
	# If we have a current state, call its exit function
	if current_state:
		current_state.exit()
	
	# Set the new current state and call its enter function
	current_state = new_state
	current_state.enter()
	
	# Emit a signal from the StateMachine itself
	state_changed.emit(new_state, state_name)
