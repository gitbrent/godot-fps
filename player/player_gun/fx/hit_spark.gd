extends Node3D

@onready var hit_effect: GPUParticles3D = $Hit_VFX/HitEffect
@onready var sparks: GPUParticles3D = $Hit_VFX/Sparks
@onready var smoke_puff: GPUParticles3D = $Hit_VFX/SmokePuff

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 1:
	hit_effect.emitting = true
	# 2:
	sparks.emitting = true
	# NEW
	smoke_puff.emitting = true
	# 3:
	await get_tree().create_timer(0.75).timeout
	$Hit_VFX/Decal.queue_free()
