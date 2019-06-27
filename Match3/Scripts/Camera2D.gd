extends Camera2D

func _ready():
	pass

func move_camera(placement):
	offset = placement

func _on_grid_place_camera(placement):
	move_camera(placement)
