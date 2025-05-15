extends Node3D

@export var player: PlayerController
@export var enemy_scene: PackedScene
var spawned_enemy: EnemyController

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# STEP 1: assert
	if !player or !enemy_scene:
		print("ASSERT FAILED")
		return
	# STEP 2:
	spawn_enemy()
	# DEBUG: (below) (works!)
	#await get_tree().create_timer(5).timeout
	#spawned_enemy.state_machine.request_state_change("follow")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func spawn_enemy() -> void:
	if enemy_scene:
		print("[test_map] spawning enemy...")
		spawned_enemy = enemy_scene.instantiate()
		get_tree().current_scene.add_child(spawned_enemy)
		#spawned_enemy.global_position = Vector3(-2.0, 0.0, -4.0)
