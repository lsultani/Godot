extends Node

# Goal information
export (Texture) var goal_texture
export (int) var max_goal_needed
export (String) var goal_string
var number_goal_collected = 0
var goal_met = false

func check_goal(goal_type):
	if goal_type == goal_string:
		update_goal()

func update_goal():
	if number_goal_collected < max_goal_needed:
		number_goal_collected += 1
	if number_goal_collected == max_goal_needed:
		if !goal_met:
			goal_met = true
