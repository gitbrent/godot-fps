extends Node3D

@export var BASE_INTENSITY:float = 3.0;
var final_intensity: float = 0.0

func _ready() -> void:
	# Generate a random float between -0.5 and 0.5
	var random_offset = randf_range(-0.5, 0.5)
	# Apply the random offset to the base intensity
	final_intensity = BASE_INTENSITY + random_offset
	#print("[FYI] Explosion Intensity: ", final_intensity)
	# 1: explode
	for pieces:RigidBody3D in self.get_children():
		pieces.apply_impulse(pieces.get_child(0).position*final_intensity, self.global_position);
	# 2: remove
	await get_tree().create_timer(2).timeout;
	queue_free();
