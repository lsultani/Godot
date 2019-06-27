extends CanvasLayer

func _ready():
	pass

func _on_backButton_pressed():
	SoundManager.play_fixed_sound(1)
	get_tree().change_scene("res://Scenes/Game Menu.tscn")
