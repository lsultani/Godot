extends TextureRect

onready var score_label = $MarginContainer/HBoxContainer/ScoreLabel
onready var counter_label = $MarginContainer/HBoxContainer/CounterLabel
var current_score = 0
var current_count = 0

func _ready():
	_on_grid_update_score(current_score)

func _on_grid_update_score(amount_to_change):
	current_score += amount_to_change
	score_label.text = String(current_score)

func _on_grid_update_counter(amount_to_change = -1):
	current_count += amount_to_change
	counter_label.text = String(current_count)
