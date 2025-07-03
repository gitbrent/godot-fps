extends PathFollow3D

@export var speed = 25.0 # WIP: FAST for dev phase only
@onready var driving: AudioStreamPlayer = $"../../Driving"

func _process(delta):
	# 1: Move the PathFollow3D node along the path
	set_progress(get_progress() + speed * delta)
	# 2: play vehicle sound
	if not driving.playing:
		driving.play()
