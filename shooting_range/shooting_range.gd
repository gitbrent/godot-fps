extends Node3D

@export var enemy_scene: PackedScene
#
@onready var spawn1_marker_3d: Marker3D = $Spawn1/Marker3D
#
var spawned_enemy: EnemyController = null

func _on_target_poster_1_poster_hit() -> void:
	spawn_enemy('attack')

func spawn_enemy(state_name) -> void:
	# 1:
	if not enemy_scene:
		print("[s_r] assert failed!")
		return
	# 2:
	spawned_enemy = enemy_scene.instantiate()
	get_tree().current_scene.add_child(spawned_enemy)
	spawned_enemy.can_patrol = true
	spawned_enemy.global_position = spawn1_marker_3d.global_position
	spawned_enemy.state_machine.request_state_change(state_name)

func _on_player_controller_player_died() -> void:
	if spawned_enemy:
		spawned_enemy.queue_free()
