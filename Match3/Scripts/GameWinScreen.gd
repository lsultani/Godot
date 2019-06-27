extends "res://Scripts/BaseMenuPanel.gd"

func _on_ContinueBtn_pressed():
	SoundManager.play_fixed_sound(1)
	get_tree().reload_current_scene()


func _on_GoalHolder_game_won():
	slide_in()
