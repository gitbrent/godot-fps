## DESGIN: Only the `UIRoot` node is set to Process>Always
## so it can listen to joypad/keys.
## Others need to stay at default so game can pause!
extends CanvasLayer

func _input(event):
	if Input.is_action_just_pressed("joypad_start"):
		GameManager.start_btn_pressed()
