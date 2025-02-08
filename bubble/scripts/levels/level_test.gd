extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	var main_camera = get_viewport().get_camera_2d()
	if main_camera:
		print("Default Camera2D Found:", main_camera.name)
	else:
		print("No default Camera2D found.")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
