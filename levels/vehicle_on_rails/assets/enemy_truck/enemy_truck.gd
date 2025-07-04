extends CharacterBody3D

signal enemy_truck_hit

@export var speed = 10.0

# We need a reference to the player's vehicle to chase it.
# This will be null until we find the player.
var player_vehicle: CharacterBody3D = null

func _ready():
	# When the truck spawns, try to find the player's vehicle in the scene.
	var player_nodes = get_tree().get_nodes_in_group("player_vehicle")
	if not player_nodes.is_empty():
		player_vehicle = player_nodes[0]

func _physics_process(delta):
	# If we haven't found the player, don't do anything.
	if not player_vehicle:
		return

	# 1. Calculate the direction from the truck to the player.
	# We use global_position to get their positions in the world.
	var direction_to_player = global_position.direction_to(player_vehicle.global_position)

	# 2. Point the truck towards the player.
	# This makes the truck turn to face its target.
	look_at(player_vehicle.global_position, Vector3.UP)

	# 3. Set the velocity.
	# We only want to move forward, so we use the truck's own forward vector (-transform.basis.z).
	velocity = -transform.basis.z * speed

	# 4. Move the truck.
	# move_and_slide() handles the actual movement and collision.
	move_and_slide()

func _on_area_3d_body_entered(body: Node3D) -> void:
	print("ENEMY_TRUCK_AREA hit with a bullet!")
	emit_signal("enemy_truck_hit")
	# WORKS! not used by level_1 (controller yet) (useful?)
