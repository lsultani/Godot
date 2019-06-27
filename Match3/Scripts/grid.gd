extends Node2D

# State Machine
enum {wait, move, win}
var state 

# Grid Variables
export (int) var width
export (int) var height
export (int) var x_start 
export (int) var y_start 
export (int) var offset
export (int) var y_offset

# Obstacles Variables
export (PoolVector2Array) var empty_spaces
export (PoolVector2Array) var ice_spaces
export (PoolVector2Array) var lock_spaces
export (PoolVector2Array) var concrete_spaces
export (PoolVector2Array) var slime_spaces
var damaged_slime = false

# Obstacle Signals
signal make_ice
signal damage_ice
signal make_lock
signal damage_lock
signal make_concrete
signal damage_concrete
signal make_slime
signal damage_slime

# Preset Board
export (PoolVector3Array) var preset_spaces

# The pieces array
var possible_pieces = [
	preload("res://Scenes/blue_piece.tscn"),
	preload("res://Scenes/green_piece.tscn"),
	preload("res://Scenes/light_green_piece.tscn"),
	preload("res://Scenes/orange_piece.tscn"),
	preload("res://Scenes/pink_piece.tscn"),
	preload("res://Scenes/yellow_piece.tscn")
]

# Hints Variables
export (PackedScene) var hint_effect
var hint = null
var hint_match_color = ""

# Current pieces in the scene array
var all_pieces = []
var clone_array = []
var current_matches = []

# Swap Back Variables
var piece_one = null
var piece_two = null
var last_place = Vector2(0,0)
var last_direction = Vector2(0,0)
var move_checked = false

# Touch Variables
var first_touch = Vector2(0,0)
var final_touch = Vector2(0,0)
var controlling = false

# Scoring Variables
signal update_score
signal setup_max_score
export (int) var max_score
export (int) var piece_value
var streak = 1

# Counter Variables
signal update_counter
export (int) var current_counter_value
export (bool) var is_counting_moves
signal game_over

# Goal Check Variables
signal check_goal

# was a color bomb used?
var color_bomb_used = false

# Collectibles
export (PackedScene) var collectible_piece
export (bool) var collectibles_in_scene 
export (int) var max_collectibles
var current_collectibles = 0

# Effects
var particle_effect = preload("res://Scenes/ParticleEffect.tscn")
var animated_effect = preload("res://Scenes/AnimatedExplosion.tscn")

# Sounds
signal play_sound

#Camera Variables
signal place_camera
signal camera_effect

func _ready():
	state = move
	randomize()
	move_camera()
	all_pieces = make_2d_array()
	clone_array = make_2d_array()
	spawn_preset_pieces()
	if collectibles_in_scene:
		spawn_collectibles(max_collectibles)
	spawn_pieces()
	spawn_ice()
	spawn_lock()
	spawn_concrete()
	spawn_slime()
	emit_signal("update_counter", current_counter_value)
	emit_signal("setup_max_score", max_score)
	if !is_counting_moves:
		$Timer.start()

func move_camera():
	var new_pos = grid_to_pixel(float(width - 1)/2, float(height - 1)/2)
	emit_signal("place_camera", new_pos)

func restricted_fill(place):
	# Check empty pieces
	if is_in_array(empty_spaces, place):
		return true
	if is_in_array(concrete_spaces, place):
		return true
	if is_in_array(slime_spaces, place):
		return true
	return false

func restricted_move(place):
	# Check lock pieces
	if is_in_array(lock_spaces, place):
		return true
	return false

func is_in_array(array, item):
	if array != null:
		for i in array.size():
			if array[i] == item:
				return true
		return false

func remove_from_array(array, item):
	for i in range(array.size() -1, -1, -1):
		if array[i] == item:
			array.remove(i)

func make_2d_array():
	var array = []
	for i in width:
		array.append([])
		for j in height:
			array[i].append(null)
	return array

func spawn_pieces():
	for i in width:
		for j in height:
			if !restricted_fill(Vector2(i,j)) and all_pieces[i][j] == null:
				#Choose random number & store
				var rand = floor( rand_range(0, possible_pieces.size() ))
				var piece = possible_pieces[rand].instance()
				var loops = 0
				while( match_at(i, j, piece.color) and loops < 100 ):
					rand = floor( rand_range(0, possible_pieces.size() ))
					loops += 1
					piece = possible_pieces[rand].instance()
				#Instance that piece from the array
				add_child(piece)
				piece.position = grid_to_pixel(i, j)
				all_pieces[i][j] = piece #store
	if is_deadlocked():
		shuffle_board()
	$HintTimer.start()

func is_piece_collectible(column, row):
	if all_pieces[column][row] != null:
		if all_pieces[column][row].color == "None":
			return true
	return false

func spawn_ice():
	if ice_spaces != null:
		for i in ice_spaces.size():
			emit_signal("make_ice", ice_spaces[i])

func spawn_lock():
	if lock_spaces != null:
		for i in lock_spaces.size():
			emit_signal("make_lock", lock_spaces[i])

func spawn_concrete():
	if concrete_spaces != null:
		for i in concrete_spaces.size():
			emit_signal("make_concrete", concrete_spaces[i])

func spawn_slime():
	if slime_spaces != null:	
		for i in slime_spaces.size():
			emit_signal("make_slime", slime_spaces[i])

func spawn_collectibles(number_to_spawn):
	for i in number_to_spawn:
		var column = floor( rand_range(0, width) )
		# Check to make sure its an empty space or that it doesnt have a restricted piece
		# height - 1 places at top position of column
		# Note: Issue if you have more collectibles than actual columns 
		while all_pieces[column][height - 1] != null or restricted_fill( Vector2(column, height - 1) ):
			column = floor( rand_range(0, width) )
		var current = collectible_piece.instance()
		add_child(current)
		current.position = grid_to_pixel(column, height - 1)
		all_pieces[column][height - 1] = current
		current_collectibles += 1

func spawn_preset_pieces():
	if preset_spaces != null:
		if preset_spaces.size() > 0:
			for i in preset_spaces.size():
				var piece = possible_pieces[preset_spaces[i].z].instance()
				add_child(piece)
				piece.position = grid_to_pixel(preset_spaces[i].x, preset_spaces[i].y)
				all_pieces[preset_spaces[i].x][preset_spaces[i].y] = piece #store 

func match_at(i, j, color):
	# Check to left
	if i > 1:
		if all_pieces[i-1][j] != null and all_pieces[i-2][j] != null:
			if all_pieces[i-1][j].color == color and all_pieces[i-2][j].color == color:
				return true
	# Check down
	if j > 1: 
		if all_pieces[i][j-1] != null and all_pieces[i][j-2] != null:
			if all_pieces[i][j-1].color == color and all_pieces[i][j-2].color == color:
				return true

func grid_to_pixel(column, row):
	var new_x = x_start + offset * column
	var new_y = y_start + -offset * row
	return Vector2(new_x, new_y)

func pixel_to_grid(pixel_x, pixel_y):
	var new_x = round( (pixel_x - x_start) / offset )
	var new_y = round( (pixel_y - y_start) / -offset )
	return Vector2(new_x, new_y)

func is_in_grid(grid_position):
	if grid_position.x >= 0 and grid_position.x < width:
		if grid_position.y >= 0 and grid_position.y < height:
			return true
	return false

func touch_input():
	if Input.is_action_just_pressed("ui_touch"):
		if is_in_grid(pixel_to_grid(get_global_mouse_position().x, get_global_mouse_position().y)):
			first_touch = pixel_to_grid(get_global_mouse_position().x, get_global_mouse_position().y)
			controlling = true
			destroy_hint()
	if Input.is_action_just_released("ui_touch"):
		if is_in_grid(pixel_to_grid(get_global_mouse_position().x, get_global_mouse_position().y)) and controlling:
			controlling = false
			final_touch = pixel_to_grid(get_global_mouse_position().x, get_global_mouse_position().y)
			touch_difference(first_touch, final_touch)

func swap_pieces(column, row, direction):
	var first_piece = all_pieces[column][row]
	var other_piece = all_pieces[column + direction.x][row + direction.y]
	#check that first and other piece are not null:
	if first_piece != null and other_piece != null:
		if !restricted_move(Vector2(column, row)) and !restricted_move(Vector2(column, row) + direction):
			# If both pieces are color bomb clear board
			if first_piece.color == "Color" and other_piece.color == "Color":
				clear_board()
			if is_color_bomb(first_piece, other_piece):
				if is_piece_collectible(column, row) or is_piece_collectible(column + direction.x, row + direction.y):
					swap_back()
					return #exit method entirely
				if first_piece.color == "Color":
					match_color(other_piece.color)
					match_and_dim(first_piece)
					add_to_array( Vector2(column, row) )
				else:
					match_color(first_piece.color)
					match_and_dim(other_piece)
					add_to_array(Vector2(column + direction.x, row + direction.y) )
			store_info(first_piece, other_piece, Vector2(column, row), direction)
			state = wait
			all_pieces[column][row] = other_piece
			all_pieces[column + direction.x][row + direction.y] = first_piece
			first_piece.move(grid_to_pixel(column + direction.x, row + direction.y))
			other_piece.move(grid_to_pixel(column, row))
			if !move_checked:
				find_matches()

func is_color_bomb(piece_one, piece_two):
	if piece_one.color == "Color" or piece_two.color == "Color":
		color_bomb_used = true
		return true
	return false

func store_info(first_piece, other_piece, place, direction):
	piece_one = first_piece
	piece_two = other_piece
	last_place = place
	last_direction = direction

func swap_back():
	# Move previously swapped pieces back to original place if there is no match
	if piece_one !=null and piece_two != null:
		swap_pieces(last_place.x, last_place.y, last_direction)
	state = move
	move_checked = false
	$HintTimer.start()

func touch_difference(grid_1, grid_2):
	var difference = grid_2 - grid_1;
	if abs(difference.x) > abs(difference.y):
		if difference.x > 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(1, 0))
		elif difference.x < 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(-1, 0))
	elif abs(difference.y) > abs(difference.x):
		if difference.y > 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(0, 1))
		elif difference.y < 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(0, -1))

func _process(delta):
	if state == move:
		touch_input()

func find_matches(query = false, array = all_pieces):
	for i in width:
		for j in height:
			if array[i][j] != null:
				var current_color = array[i][j].color
				if i > 0 and i < width - 1:
					#check if left and right are not null
					if array[i-1][j] != null and array[i+1][j] != null:
						#check if left and right match current color
						if array[i-1][j].color == current_color and array[i+1][j].color == current_color:
							# There is a match
							if query:
								hint_match_color = current_color
								return true
							match_and_dim(array[i-1][j])
							match_and_dim(array[i][j])
							match_and_dim(array[i+1][j])
							add_to_array(Vector2(i, j))
							add_to_array(Vector2(i + 1, j))
							add_to_array(Vector2(i - 1, j))
				if j > 0 and j < height - 1:
					#check if above and below are not null
					if array[i][j-1] != null and array[i][j+1] != null:
						#check if above and below match current color
						if array[i][j-1].color == current_color and array[i][j+1].color == current_color:
							# There is a match
							if query:
								hint_match_color = current_color
								return true
							match_and_dim(array[i][j-1])
							match_and_dim(array[i][j])
							match_and_dim(array[i][j+1])
							add_to_array(Vector2(i, j))
							add_to_array(Vector2(i, j + 1))
							add_to_array(Vector2(i, j - 1))
	if query:
		return false
	get_bombed_pieces()
	get_parent().get_node("destroy_timer").start()

func get_bombed_pieces():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				if all_pieces[i][j].matched:
					if all_pieces[i][j].is_column_bomb:
						match_all_in_column(i)
					elif all_pieces[i][j].is_row_bomb:
						match_all_in_row(j)
					elif all_pieces[i][j].is_adjacent_bomb:
						find_adjacent_pieces(i, j)

func add_to_array(value, array_to_add = current_matches):
	if !array_to_add.has(value):
		array_to_add.append(value)

func is_piece_null(column, row, array = all_pieces):
	if array[column][row] == null:
		return true
	return false

func match_and_dim(item):
	item.matched = true
	item.dim()

func find_bombs():
	#If not a color bomb used
	if !color_bomb_used:
		# Iterate over the current_matches array
		for i in current_matches.size():
			# Store values for match
			var current_column = current_matches[i].x
			var current_row = current_matches[i].y
			var current_color = all_pieces[current_column][current_row].color
			var col_matched = 0
			var row_matched = 0
			# Iterate over current_matches to check for column, row, and color
			for j in current_matches.size():
				var this_column = current_matches[j].x
				var this_row = current_matches[j].y
				var this_color = all_pieces[this_column][this_row].color
				if this_column == current_column and current_color == this_color:
					col_matched += 1
				if this_row == current_row and this_color == current_color:
					row_matched += 1
			# 0 is an adj bomb, 1, is a row bomb, and 2 is a column bomb
			# 3 is a color bomb
			if col_matched == 5 or row_matched == 5:
				make_bomb(3, current_color)
				continue
			elif col_matched >= 3 and row_matched >= 3:
				make_bomb(0, current_color) #adjacent bomb
				continue
			elif col_matched == 4:
				make_bomb(1, current_color)
				continue
			elif row_matched == 4:
				make_bomb(2, current_color)
				continue

func make_bomb(bomb_type, color):
	# iterate over current_matches
	for i in current_matches.size():
		# Cache a few variables
		var current_column = current_matches[i].x
		var current_row = current_matches[i].y
		if all_pieces[current_column][current_row] == piece_one and piece_one.color == color:
			#Make piece_one a bomb
			damage_special(current_column, current_row)
			emit_signal("check_goal", piece_one.color)
			piece_one.matched = false
			change_bomb(bomb_type, piece_one)
		if all_pieces[current_column][current_row] == piece_two and piece_two.color == color:
			#Make piece_two a bomb
			damage_special(current_column, current_row)
			emit_signal("check_goal", piece_two.color)
			piece_two.matched = false
			change_bomb(bomb_type, piece_two)

func change_bomb(bomb_type, piece):
	if bomb_type == 0:
		piece.make_adjacent_bomb()
	elif bomb_type == 1:
		piece.make_row_bomb()
	elif bomb_type == 2:
		piece.make_column_bomb()
	elif bomb_type == 3:
		piece.make_color_bomb()

func destroy_matched():
	find_bombs()
	var was_matched = false
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				if all_pieces[i][j].matched:
					emit_signal("check_goal", all_pieces[i][j].color)
					damage_special(i, j)
					was_matched = true
					all_pieces[i][j].queue_free()
					all_pieces[i][j] = null
					make_effect(particle_effect, i, j)
					make_effect(animated_effect, i, j)
					emit_signal("play_sound")
					cam_effect()
					emit_signal("update_score", piece_value * streak)
	move_checked = true
	if was_matched:
		destroy_hint()
		get_parent().get_node("collapse_timer").start()
	else:
		swap_back()
	current_matches.clear()

func make_effect(effect, column, row):
	var current = effect.instance()
	current.position = grid_to_pixel(column, row)
	add_child(current)

func check_concrete(column, row):
	# Check right
	if column < width -1:
		emit_signal("damage_concrete", Vector2(column + 1, row) )
	# Check left
	if column > 0:
		emit_signal("damage_concrete", Vector2(column - 1, row) )
	# Check up
	if row < height - 1:
		emit_signal("damage_concrete", Vector2(column, row + 1) )
	# Check down
	if row > 0:
		emit_signal("damage_concrete", Vector2(column, row - 1) )

func check_slime(column, row):
	# Check right
	if column < width -1:
		emit_signal("damage_slime", Vector2(column + 1, row) )
	# Check left
	if column > 0:
		emit_signal("damage_slime", Vector2(column - 1, row) )
	# Check up
	if row < height - 1:
		emit_signal("damage_slime", Vector2(column, row + 1) )
	# Check down
	if row > 0:
		emit_signal("damage_slime", Vector2(column, row - 1) )

func damage_special(column, row):
	emit_signal("damage_ice", Vector2(column, row))
	emit_signal("damage_lock", Vector2(column, row))
	check_concrete(column, row)
	check_slime(column, row)

func match_color(color):
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and !is_piece_collectible(i, j):
				if all_pieces[i][j].color == color:
					if all_pieces[i][j].is_column_bomb:
						match_all_in_column(i)
					if all_pieces[i][j].is_row_bomb:
						match_all_in_row(j)
					if all_pieces[i][j].is_column_bomb:
						find_adjacent_pieces(i, j)
					match_and_dim(all_pieces[i][j])
					add_to_array( Vector2(i, j) )

func clear_board():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and !is_piece_collectible(i, j):
				match_and_dim(all_pieces[i][j])
				add_to_array( Vector2(i, j) )

func collapse_columns():
	for i in width:
		for j in height:
			# if null piece found
			if all_pieces[i][j] == null and !restricted_fill(Vector2(i,j)):
				# loop above piece
				for k in range(j+1, height):
					# if this piece is not null
					if all_pieces[i][k] != null:
						# move to empty spot
						all_pieces[i][k].move(grid_to_pixel(i, j))
						# set empty spot to have value of thing we just moved
						all_pieces[i][j] = all_pieces[i][k]
						# reset to null
						all_pieces[i][k] = null
						# leave loop
						break
	get_parent().get_node("refill_timer").start()

func refill_columns():
	streak += 1
	for i in width:
		for j in height:
			if all_pieces[i][j] == null and !restricted_fill(Vector2(i,j)):
				#Choose random number & store
				var rand = floor( rand_range(0, possible_pieces.size() ))
				var piece = possible_pieces[rand].instance()
				var loops = 0
				while( match_at(i, j, piece.color) and loops < 100 ):
					rand = floor( rand_range(0, possible_pieces.size() ))
					loops += 1
					piece = possible_pieces[rand].instance()
					
				#Instance that piece from the array
				add_child(piece)
				piece.position = grid_to_pixel(i, j - y_offset)
				piece.move(grid_to_pixel(i,j))
				all_pieces[i][j] = piece #store
	after_refill()

func after_refill():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				# check if there is a match
				if match_at(i,j, all_pieces[i][j].color):
					find_matches()
					get_parent().get_node("destroy_timer").start()
					return
	if !damaged_slime:
		generate_slime()
	streak = 1
	move_checked = false
	damaged_slime = false
	color_bomb_used = false
	if is_deadlocked():
		$ShuffleTimer.start()
	if is_counting_moves:
		if state != win:
			current_counter_value -= 1
			emit_signal("update_counter")
			if current_counter_value == 0:
				declare_game_over()
			else:
				state = move
	$HintTimer.start()

func generate_slime():
	# Make sure there are slime pieces on the board
	if slime_spaces.size() > 0:
		var slime_made = false
		var tracker = 0
		while !slime_made and tracker < 100:
			# Check random slime
			var random_num = floor( rand_range( 0, slime_spaces.size() ) )
			var curr_x = slime_spaces[random_num].x
			var curr_y = slime_spaces[random_num].y
			var neighbor = find_normal_neighbor(curr_x, curr_y)
			if neighbor != null:
				# Turn that neighbor into a slime 
				# Remove that piece
				all_pieces[neighbor.x][neighbor.y].queue_free()
				# Set it to null
				all_pieces[neighbor.x][neighbor.y] = null
				# Add this new spot to the array of slimes
				slime_spaces.append(Vector2(neighbor.x, neighbor.y))
				# Send a signal to the slime holder to make new slime
				emit_signal("make_slime", Vector2(neighbor.x, neighbor.y))
				slime_made = true
			tracker += 1

func find_normal_neighbor(column, row):
	# Check Right first
	if is_in_grid(Vector2(column + 1, row)):
		if all_pieces[column + 1][row] != null and !is_piece_collectible(column + 1, row):
			return Vector2(column + 1, row)
	# Check Left 
	elif is_in_grid(Vector2(column - 1, row)):
		if all_pieces[column - 1][row] != null and !is_piece_collectible(column - 1, row):
			return Vector2(column - 1, row)
	# Check Up 
	elif is_in_grid(Vector2(column, row + 1)):
		if all_pieces[column][row + 1] != null and !is_piece_collectible(column, row + 1):
			return Vector2(column, row + 1)
	# Check Down 
	elif is_in_grid(Vector2(column, row -1)):
		if all_pieces[column][row - 1] != null and !is_piece_collectible(column, row -1):
			return Vector2(column, row - 1)
	return null

func match_all_in_column(column):
	for i in height:
		if all_pieces[column][i] != null and !is_piece_collectible(column, i):
			if all_pieces[column][i].is_row_bomb:
				match_all_in_row(i)
			if all_pieces[column][i].is_adjacent_bomb:
				find_adjacent_pieces(column, i)
			if all_pieces[column][i].is_color_bomb:
				match_color(all_pieces[column][i].color)
			all_pieces[column][i].matched = true

func match_all_in_row(row):
	for i in width:
		if all_pieces[i][row] != null:
			if all_pieces[i][row].is_column_bomb:
				match_all_in_column(i)
			if all_pieces[i][row].is_adjacent_bomb:
				find_adjacent_pieces(i, row)
			if all_pieces[i][row].is_color_bomb:
				match_color(all_pieces[i][row].color)
			all_pieces[i][row].matched = true

func find_adjacent_pieces(column, row):
	# one less = one greater
	for i in range(-1, 2):
		for j in range(-1, 2):
			# Check to see if is in grid
			if is_in_grid(Vector2(column + i, row + j)):
				if all_pieces[column + i][row + j] != null:
					if all_pieces[column + i][row + j].is_row_bomb:
						match_all_in_row(j)
					if all_pieces[column + i][row + j].is_column_bomb:
						match_all_in_column(i)
					if all_pieces[column + i][row + j].is_color_bomb:
						match_color(all_pieces[column + i][row + j].color)
					all_pieces[column + i][row + j].matched = true

func destroy_collectible():
	for i in width:
		if all_pieces[i][0] != null:
			if all_pieces[i][0].color == "None":
				all_pieces[i][0].matched = true
				current_collectibles -= 1

func switch_pieces(place, direction, array):
	if is_in_grid(place) and !restricted_fill(place) and !restricted_move(place + direction):
		if is_in_grid(place + direction) and !restricted_fill(place + direction) and !restricted_move(place + direction):
			# First, hold the piece to swap with
			var holder = array[place.x + direction.x][place.y + direction.y]
			# Then set the swap spot as the original piece
			array[place.x + direction.x][place.y + direction.y] = array[place.x][place.y]
			# Set the original spot as the other piece
			array[place.x][place.y] = holder

func is_deadlocked():
	# Create a copy of the all_pieces array
	clone_array = copy_array(all_pieces)
	for i in width:
		for j in height:
			#switch and check right
			if switch_and_check(Vector2(i,j), Vector2(1,0), clone_array):
				return false
			#switch and check up
			if switch_and_check(Vector2(i,j), Vector2(0,1), clone_array):
				return false
	return true

func switch_and_check(current_place, direction, array):
	switch_pieces(current_place, direction, array)
	if find_matches(true, array) and !restricted_move(current_place + direction):
		switch_pieces(current_place, direction, array)
		return true
	switch_pieces(current_place, direction, array)
	return false

func copy_array(array_to_copy):
	var new_array = make_2d_array()
	for i in width:
		for j in height:
			new_array[i][j] = array_to_copy[i][j]
	return new_array

func clear_and_store_board():
	var holder_array = []
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				holder_array.append(all_pieces[i][j])
				all_pieces[i][j] = null
	return holder_array

func shuffle_board():
	var holder_array = clear_and_store_board()
	for i in width:
		for j in height:
			if !restricted_fill(Vector2(i,j)) and all_pieces[i][j] == null:
				#Choose random number & store
				var rand = floor( rand_range(0, holder_array.size() ))
				var piece = holder_array[rand]
				var loops = 0
				while( match_at(i, j, piece.color) and loops < 100 ):
					rand = floor( rand_range(0, holder_array.size() ))
					loops += 1
					piece = holder_array[rand]
				piece.move( grid_to_pixel(i, j) )
				all_pieces[i][j] = piece #store
				holder_array.remove(rand)
	if is_deadlocked():
		shuffle_board()
	state = move

func find_all_matches():
	var hint_holder = []
	clone_array = copy_array(all_pieces)
	for i in width:
		for j in height:
			# Check that clone array position is not empty
			if clone_array[i][j] != null and !restricted_move(Vector2(i,j)):
				# Switch and check current position to right, on clone array
				if switch_and_check(Vector2(i,j), Vector2(1,0), clone_array) and is_in_grid(Vector2(i+1, j)) and !restricted_move(Vector2(i+1,j)):
					#add the piece i, j to the hint_holder
					if hint_match_color != "":
						if hint_match_color == clone_array[i][j].color:
							#check to make sure piece is not a lock space
							hint_holder.append(clone_array[i][j])
						else:
							#check to make sure piece is not a lock space
							hint_holder.append(clone_array[i+1][j])
				# Switch and check to left
				if switch_and_check(Vector2(i,j), Vector2(0,1), clone_array) and is_in_grid(Vector2(i, j+1)) and !restricted_move(Vector2(i,j+1)):
					#add the piece i, j to the hint_holder
					if hint_match_color != "":
						if hint_match_color == clone_array[i][j].color:
							#check to make sure piece is not a lock space
							hint_holder.append(clone_array[i][j])
						else:
							#check to make sure piece is not a lock space
							hint_holder.append(clone_array[i][j+1])
	return hint_holder

func generate_hint():
	var hints = find_all_matches()
	if hints != null:
		if hints.size() > 0:
			destroy_hint()
			var rand = floor( rand_range(0, hints.size() ) )
			hint = hint_effect.instance()
			add_child(hint)
			hint.position = hints[rand].position
			hint.Setup(hints[rand].get_node("Sprite").texture)

func destroy_hint():
	if hint:
		hint.queue_free()
		hint = null

func cam_effect():
	emit_signal("camera_effect")

func _on_destroy_timer_timeout():
	destroy_matched()

func _on_collapse_timer_timeout():
	collapse_columns()

func _on_refill_timer_timeout():
	refill_columns()

func _on_lock_holder_remove_lock(place):
#	remove_from_array(lock_spaces, place)
	for i in range(lock_spaces.size() -1, -1, -1):
		if lock_spaces[i] == place:
			lock_spaces.remove(i)

func _on_concrete_holder_remove_concrete(place):
#	remove_from_array(concrete_spaces, place)
	for i in range(concrete_spaces.size() -1, -1, -1):
		if concrete_spaces[i] == place:
			concrete_spaces.remove(i)

func _on_slime_holder_remove_slime(place):
	damaged_slime = true
	for i in range(slime_spaces.size() -1, -1, -1):
		if slime_spaces[i] == place:
			slime_spaces.remove(i)

func _on_Timer_timeout():
	current_counter_value -= 1
	emit_signal("update_counter")
	if current_counter_value == 0:
		if state != win:
			declare_game_over()
		$Timer.stop()

func declare_game_over():
	emit_signal("game_over")
	state = wait

func _on_GoalHolder_game_won():
	state = win

func _on_ShuffleTimer_timeout():
	shuffle_board()

func _on_HintTimer_timeout():
	generate_hint()
