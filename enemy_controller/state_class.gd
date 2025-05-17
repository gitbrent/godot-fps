# state_class.md
extends Node
class_name EnemyState

signal transitioned(state: EnemyState, new_state_name: String)
signal fade_out_requested()

var enemy_controller: CharacterBody3D = null

func enter() -> void:
	pass # Override in child states

func update(delta: float) -> void:
	pass # Override in child states

## Returns velocity so controller can implement from central location
func physics_update(delta: float) -> Vector3:
	# This is the base implementation. Child classes should override this.
	# By default, return zero velocity if not overridden or if the base function is called.
	return Vector3.ZERO

func exit() -> void:
	pass # Override in child states
