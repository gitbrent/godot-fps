extends EnemyState
class_name EnemyFollow

@export var enemy: CharacterBody3D
@export var move_speed := 40.0
@export var follow_area := 25

func enter() -> void:
	#player = get_tree().get_first_node_in_group("Player")
	pass

func physics_update(delta: float) -> void:
	#print("[follow] physics_update")
	#var direction = player.global_position - enemy.global_position
	var direction = Vector3(0,0,0)
	
	if direction.length() > follow_area:
		enemy.velocity = direction.normalized() * move_speed
	else:
		enemy.velocity = Vector3()
	
	# transition to idle state when player is out of range
	if direction.length() > 50:
		transitioned.emit(self, "idle")

	# TODO: find player and follow them
	#var direction = player.global_position - enemy.global_position
	#if direction.length() < follow_area:
	#	transitioned.emit(self, "follow")
