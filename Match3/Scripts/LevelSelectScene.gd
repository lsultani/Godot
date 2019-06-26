extends CanvasLayer

func _ready():
	pass

func _on_backButton_pressed():
	get_tree().change_scene("res://Scenes/Game Menu.tscn")
