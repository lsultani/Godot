extends "res://Scripts/BaseMenuPanel.gd"

signal sound_change
signal back_button

# Sound Btn
func _on_Button_1_pressed():
	emit_signal("sound_change")

# Back Btn
func _on_Button_2_pressed():
	emit_signal("back_button")
