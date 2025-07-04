extends Node3D

# Preload the enemy scene at the top of your script for better performance.
# Replace with the actual path to your enemy vehicle scene.
const ENEMY_SCENE = preload("res://levels/vehicle_on_rails/assets/enemy_truck/enemy_truck.tscn")

# This is the Marker3D you placed in the editor to mark the spawn location.
@onready var spawn_point_1: Marker3D = $SpawnAreas/SpawnPoint1

func _ready() -> void:
	_spawn_enemy_truck_1()

# This function was automatically created by connecting the signal.
func _spawn_enemy_truck_1() -> void:
	# 'body' is the node that entered the Area3D.
	# We can check if it's the player's vehicle, though for now it's the only thing moving.
	print("Player vehicle entered the trigger!")
	
	# 1. Create an instance of the enemy scene.
	var new_enemy = ENEMY_SCENE.instantiate()
	
	# 2. Add the new enemy to the scene.
	add_child(new_enemy)
	
	# 3. Set the enemy's position to the spawn point's position.
	new_enemy.global_position = spawn_point_1.global_position
	
	# 4. IMPORTANT: Disable the trigger so it only runs once.
	#$SpawnTrigger_Trucks.queue_free() # or set_monitoring(false)

# Triggered when `PlayerControlled` collides
func _on_trigger_area_1_body_entered(body: Node3D) -> void:
	print("PLAYER ENCOUNTERED!")
	_spawn_enemy_truck_1()
