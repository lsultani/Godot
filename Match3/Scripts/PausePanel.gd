extends "res://Scripts/BaseMenuPanel.gd"


func _on_ContinueBtn_pressed():
	get_tree().paused = false
	slide_out()

func _on_QuitBtn_pressed():
	get_tree().quit()

func _on_bottom_ui_pause_game():
	slide_in()
