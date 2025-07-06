extends Node3D

const ENEMY_SCENE = preload("res://levels/vehicle_on_rails/assets/enemy_truck/enemy_truck.tscn")
@onready var spawn_point_1: Marker3D = $SpawnAreas/SpawnPoint1

func _ready() -> void:
	_spawn_enemy_truck_1()

func _spawn_enemy_truck_1() -> void:
	# 1. Create an instance of the enemy scene.
	var new_enemy = ENEMY_SCENE.instantiate()
	
	# 2. Add the new enemy to the scene.
	add_child(new_enemy)
	
	# 3. Set the enemy's position to the spawn point's position.
	new_enemy.global_position = spawn_point_1.global_position
	
	# TODO: add signal "enemy_truck_exploded"
