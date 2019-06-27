extends "res://Scripts/BaseMenuPanel.gd"

signal sound_change
signal back_button
export (Texture) var sound_on
export (Texture) var sound_off

# Sound Btn
func _on_Button_1_pressed():
	ConfigManager.sound_on = !ConfigManager.sound_on 
	change_sound_texture()
	ConfigManager.save_config()
	SoundManager.set_volume()
	SoundManager.play_fixed_sound(1)

func change_sound_texture():
	if ConfigManager.sound_on == true:
		$"MarginContainer/MainContainer/Buttons/Button 1".texture_normal = sound_on
	else:
		$"MarginContainer/MainContainer/Buttons/Button 1".texture_normal = sound_off

# Back Btn
func _on_Button_2_pressed():
	SoundManager.play_fixed_sound(1)
	emit_signal("back_button")

func _on_Game_Menu_read_sound():
	change_sound_texture()
