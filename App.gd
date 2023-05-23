extends Control


signal request_done


var base_path = "user://GodotUnstableDiffusion/NEW/"
var actual_path
var current_image
var json = JSON.new()

@onready var name_text = $HBoxContainer/HSplitContainer/VBoxContainer/TextEdit
@onready var prompt_text = $HBoxContainer/HSplitContainer/VBoxContainer/TextEdit2
@onready var matrix_text = $HBoxContainer/HSplitContainer/VBoxContainer/TextEdit3
@onready var generate_button = $HBoxContainer/HSplitContainer/VBoxContainer/Button
@onready var texture_rect = $HBoxContainer/HSplitContainer/VBoxContainer2/TextureRect
@onready var generating_label = $HBoxContainer/HSplitContainer/VBoxContainer/Label4
@onready var generated_label = $HBoxContainer/HSplitContainer/VBoxContainer2/Label5
@onready var keep_seed_button = $HBoxContainer/HSplitContainer/VBoxContainer/CheckButton
@onready var cfg_slider = $HBoxContainer/HSplitContainer/VBoxContainer/HSlider
@onready var sampler_button = $HBoxContainer/HSplitContainer/VBoxContainer/OptionButton


# Called when the node enters the scene tree for the first time.
func _ready():
	if false:
		prompt_text.text = "stunning girl, Perfect body, Nikon, wet, cumming, intense"
	generate_button.pressed.connect(_on_generate_button_pressed)
	$HTTPRequest.request_completed.connect(_on_request_completed)


func _on_generate_button_pressed():
	_generate(name_text.text, prompt_text.text, matrix_text.text)


# Metadata format:
# base_prompt
# matrix_prompt
func _generate(_name, prompt, matrix):
	while DirAccess.dir_exists_absolute(base_path + _name):
		_name += 'x'
	actual_path = base_path + _name
	DirAccess.make_dir_recursive_absolute(actual_path)
	print(actual_path, ' created')
	var prompt_matrix = _compute_matrix(matrix)
	for s in prompt_matrix:
		print(s)
	var metadata = prompt + '\n' + matrix
	save_file("meta.txt", metadata)
	var seed = -1
	if keep_seed_button.button_pressed:
		randomize()
		seed = randi()
	for i in prompt_matrix.size():
		var true_prompt = prompt + prompt_matrix[i]
		generating_label.text = "generating: " + true_prompt
		print(generating_label.text)
		var img = await _request_image(true_prompt,
			seed,
			cfg_slider.value,
			sampler_button.get_item_text(sampler_button.selected)
		)
		generated_label.text = true_prompt + ":"
		img.save_png(actual_path + "/" + str(i) + ".png")
		texture_rect.texture = ImageTexture.create_from_image(img)
	if prompt_matrix.size() > 1:
		var categorizer = preload("res://categorizer.tscn").instantiate()
		categorizer.path = actual_path + '/'
		get_parent().add_child(categorizer)
		queue_free()


func _compute_matrix(prompt_matrix):
	var matrix = [""]
	for s in prompt_matrix.split(',', false):
		for s2 in matrix.duplicate():
			matrix.append(s2 + ', ' + s)
	return matrix


func _request_image(prompt, seed, cfg_scale, sampler):
	var query = JSON.stringify({
		"prompt": prompt,
		"steps": 40,
		"seed": seed,
		"height": 768,
		"cfg_cale": cfg_scale,
		"sampler_name": sampler,
	})
	$HTTPRequest.request("http://127.0.0.1:7860/sdapi/v1/txt2img",
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		query
	)
	await request_done
	return current_image

func _on_request_completed(res, code, _headers, _body):
	json.parse(_body.get_string_from_utf8())
	var packed_img = json.data['images'][0]
	packed_img = packed_img.split(',', true, 1)[0]
	packed_img = Marshalls.base64_to_raw(packed_img)
	var img = Image.new()
	img.load_png_from_buffer(packed_img)
	current_image = img
	emit_signal("request_done")


func save_file(_name, _text):
	var file = FileAccess.open(actual_path + '/' + _name, FileAccess.WRITE)
	file.store_string(_text)
