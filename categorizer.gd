extends Control

var path = "user://GodotUnstableDiffusion/NEW/lalatestxxxxxxxxxxxxxxxxxxxxxx/"
@onready var prompt_label = $VBoxContainer/Label
@onready var buttons_container = $VBoxContainer/HBoxContainer
@onready var lines_container = $VBoxContainer/ScrollContainer/VBoxContainer

var matrix_size
var rmatrix


func _ready():
	init(path)


func init(path):
	var file = FileAccess.open(path + "meta.txt", FileAccess.READ)
	var content = file.get_as_text()
	print(content)
	content = content.split('\n')
	prompt_label.text = content[0]
	rmatrix = _compute_matrix(content[1])
	print('rmatrix: ', rmatrix)
	var matrix = content[1].split(',')
	matrix_size = matrix.size()
	var i = 0
	for key in matrix:
		var button = Button.new()
		button.text = key
		buttons_container.add_child(button)
		button.pressed.connect(_on_button_pressed.bind(i, key))
		i += 1

func _compute_matrix(prompt_matrix):
	var matrix = [""]
	for s in prompt_matrix.split(','):
		for s2 in matrix.duplicate():
			matrix.append(s2 + ', ' + s)
	return matrix


func _on_button_pressed(nth, key):
	for c in lines_container.get_children():
		lines_container.remove_child(c)
	print(nth, key)
	var step = pow(2, nth)
	var loop = (rmatrix.size() / 2) / step
	for l in loop:
		for s in step:
			var line = preload("res://line.tscn").instantiate()
			lines_container.add_child(line)
			var left_image_index = l * 2 * step + s
			var right_image_index = left_image_index + step
			print(left_image_index, '->', right_image_index)
			var right_img = Image.new()
			right_img.load(path + str(right_image_index) + '.png')
			var left_img = Image.new()
			left_img.load(path + str(left_image_index) + '.png')
			line.init(rmatrix[left_image_index], left_img, right_img)

# N: Step 2^N, loop (size / 2) / step

# 0: Step 1, loop 8
# ___  ___  ___  ___  ___  _____  _____  _____
# 0-1, 2-3, 4-5, 6-7, 8-9, 10-11, 12-13, 14-15
# 1: Step 2, loop 4
# ________  ________  __________  ____________
# 0-2, 1-3, 4-6, 5-7, 8-10, 9-11, 12-14, 13-15
# 2: Step 4, loop 2
# __________________  ________________________
# 0-4, 1-5, 2-6, 1-7, 8-12, 9-13, 10-14, 11-15
# 3: Step 8, loop 1
# ____________________________________________
# 0-8, 1-9, 2-10, 3-11, 4-12, 5-13, 6-14, 7-15
