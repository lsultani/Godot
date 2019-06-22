extends "res://Scripts/BaseMenuPanel.gd"

func _on_QuiteBtn_pressed():
	get_tree().change_scene("res://Scenes/Game Menu.tscn")

func _on_RestartBtn_pressed():
	get_tree().reload_current_scene()


func _on_grid_game_over():
	slide_in()
