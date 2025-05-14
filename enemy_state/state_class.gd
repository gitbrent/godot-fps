## SRC: https://www.youtube.com/watch?v=ow_Lum-Agbs
## DATE: 2025-05-08
extends Node
class_name EnemyState

signal transitioned(state: EnemyState, new_state_name: String)

func enter() -> void:
	pass # Override in child states

func exit() -> void:
	pass # Override in child states

func update(delta: float) -> void:
	pass # Override in child states

func physics_update(delta: float) -> void:
	pass # Override in child states
