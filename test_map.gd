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

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#pass
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.size() < 2:
		spawn_enemy()

func spawn_enemy() -> void:
	if enemy_scene:
		#print("[test_map] spawning enemy...")
		spawned_enemy = enemy_scene.instantiate()
		get_tree().current_scene.add_child(spawned_enemy)
		spawned_enemy.global_position = Vector3(0.0, 0.0, -12.0)
