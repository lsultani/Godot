extends "res://Scripts/BaseMenuPanel.gd"


func _on_ContinueBtn_pressed():
	SoundManager.play_fixed_sound(1)
	get_tree().paused = false
	slide_out()

func _on_QuitBtn_pressed():
	SoundManager.play_fixed_sound(1)
	get_tree().paused = false
	get_tree().change_scene("res://Scenes/LevelSelectScene.tscn")

func _on_bottom_ui_pause_game():
	slide_in()
