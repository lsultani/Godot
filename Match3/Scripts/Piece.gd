extends Node2D

export (String) var color;
var move_tween
var matched = false

func _ready():
	#get_note("move_tween")
	move_tween = $move_tween 

func move(target):
	move_tween.interpolate_property(self, "position", position, target, .3, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	move_tween.start()

func dim():
	#get_node("Sprite")
	var sprite = $Sprite 
	sprite.modulate = Color(1, 1, 1, .5)