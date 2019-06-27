extends "res://Scripts/BaseMenuPanel.gd"

var is_out = false

func _on_ContinueBtn_pressed():
	SoundManager.play_fixed_sound(1)
	#get_tree().paused = true
	get_tree().change_scene("res://Scenes/LevelSelectScene.tscn")


func _on_GoalHolder_game_won():
	if is_out == false:
		is_out = true
	slide_in()
