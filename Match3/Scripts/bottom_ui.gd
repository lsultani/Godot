extends TextureRect

signal pause_game

func _on_PauseBtn_pressed():
	# emit signal first
	emit_signal("pause_game")
	# then pause
	get_tree().paused = true
