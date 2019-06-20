extends TextureRect

onready var score_label = $MarginContainer/HBoxContainer/ScoreLabel
var current_score = 0

func _ready():
	_on_grid_update_score(current_score)

func _on_grid_update_score(amount_to_change):
	current_score += amount_to_change
	score_label.text = String(current_score)
