# state_class.md
extends Node
class_name EnemyState

signal transitioned(state: EnemyState, new_state_name: String)
signal fade_out_requested()

var enemy_controller: CharacterBody3D = null
var desired_rotation_direction: Vector3 = Vector3(0, 0, 1)

func enter() -> void:
	pass # Override in child states

## Called every frame
## update() is for non-physics logic like timers and input
func update(delta: float) -> void:
	pass # Override in child states

## Called every physics frame
## physics_update is called by the controller before move_and_slide
## (use for movement and physics calculations)
## Returns velocity so controller can implement from central location
# It should return the desired horizontal velocity (Vector3.ZERO when standing still)
# and set the desired_rotation_direction.

func physics_update(delta: float) -> Vector3:
	# This is the base implementation. Child classes should override this.
	# By default, return zero velocity if not overridden or if the base function is called.
	return Vector3.ZERO

func exit() -> void:
	pass # Override in child states
