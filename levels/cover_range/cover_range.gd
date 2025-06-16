extends Node3D

#region
@onready var marker_enemy_spawn: Marker3D = $MeshSpawnArea/MarkerEnemySpawn
@export var enemy_scene: PackedScene
var active_enemies: Array[EnemyController] = []
#endregion

func _ready() -> void:
	_spawn_enemy()

func _spawn_enemy() -> EnemyController:
	# 1:
	if not enemy_scene:
		print("[CoverRange] assert failed!")
		return null
	
	# 2:
	var new_enemy:EnemyController = enemy_scene.instantiate() as EnemyController
	# IMPORTANT: these props are used in `_ready()`, so set before add_child!
	new_enemy.can_patrol = false
	new_enemy.debug_show_state = true
	new_enemy.debug_show_detect_area = false
	add_child(new_enemy)
	new_enemy.global_position = marker_enemy_spawn.global_position
	new_enemy.state_machine.request_state_change("cover")
	new_enemy.can_change_state = false
	new_enemy.name = "Enemy"+str(active_enemies.size())
	
	# 3: Add the new enemy to your tracking array
	active_enemies.append(new_enemy)
	
	# 4: Connect to a signal from the enemy to know when it dies (or is removed)
	if new_enemy.has_signal("died"):
		new_enemy.died.connect(_on_enemy_died.bind(new_enemy))
	else:
		# Fallback: connect to tree_exited if no specific 'died' signal, though 'died' is better
		new_enemy.tree_exited.connect(Callable(self, "_on_enemy_removed_from_tree").bind(new_enemy))
	
	# LAST:
	return new_enemy

func _on_enemy_died(enemy_instance: EnemyController) -> void:
	# This function will be called when an enemy emits its 'died' signal
	if active_enemies.has(enemy_instance):
		active_enemies.erase(enemy_instance)
	# NOTE: can add logic here for scoring, wave progression, etc.
	print("Enemy died! Active enemies remaining: ", active_enemies.size())

func _on_area_3d_body_entered(body: Node3D) -> void:
	print("WANTED POSTER hit!")
	var new_enemy = _spawn_enemy()
	print("SPANWED ENEMY: ", new_enemy.name)
