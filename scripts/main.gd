extends Control
var can_drag = false
var mouse_position
var window_position
var screen_size
var window_size
var is_window_moving = false
var window_moving_direction = 0
signal jump_to_side(side)
@onready var info_label: Label = $InfoLabel
@onready var character: Character = $Character
@onready var path_text_edit: TextEdit = $PathInputContainer/PathTextEdit
@onready var path_input_container: VBoxContainer = $PathInputContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_tree().root.set_transparent_background(true)
	screen_size = DisplayServer.screen_get_size()
	window_size = DisplayServer.window_get_size()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if can_drag:
		DisplayServer.window_set_position(DisplayServer.mouse_get_position() - Vector2i(70, 110))
	# jump to screen side
	if is_window_moving:
		match window_moving_direction:
			SIDE_BOTTOM:
				DisplayServer.window_set_position(DisplayServer.window_get_position() + Vector2i(0, 5))
				if DisplayServer.window_get_position().y >= screen_size.y - window_size.y:
					is_window_moving = false
					jump_to_side.emit(SIDE_BOTTOM)
			SIDE_TOP:
				DisplayServer.window_set_position(DisplayServer.window_get_position() - Vector2i(0, 5))
				if DisplayServer.window_get_position().y <= 0:
					is_window_moving = false
					jump_to_side.emit(SIDE_TOP)
			SIDE_LEFT:
				DisplayServer.window_set_position(DisplayServer.window_get_position() - Vector2i(5, 0))
				if DisplayServer.window_get_position().x <= 0:
					is_window_moving = false
					jump_to_side.emit(SIDE_LEFT)
			SIDE_RIGHT:
				DisplayServer.window_set_position(DisplayServer.window_get_position() + Vector2i(5, 0))
				if DisplayServer.window_get_position().x >= screen_size.x - window_size.x:
					is_window_moving = false
					jump_to_side.emit(SIDE_RIGHT)
	# normal moving animation
	if character.current_state == character.State.IDLE_MOVE:
		match character.animated_sprite.animation:
			"climb":
				if DisplayServer.window_get_position().x >= -50:
					DisplayServer.window_set_position(DisplayServer.window_get_position() - Vector2i(1, 0))
			"ride":
				# TODO two direction
				if DisplayServer.window_get_position().x >= -50:
					DisplayServer.window_set_position(DisplayServer.window_get_position() - Vector2i(2, 0))
	# move on screen side TODO change direction
	if character.current_state == character.State.SIDE_MOVE:
		match character.animated_sprite.animation:
			"left":
				if DisplayServer.window_get_position().y >= -20:
					DisplayServer.window_set_position(DisplayServer.window_get_position() - Vector2i(0, 1))
			"up":
				if DisplayServer.window_get_position().x >= -50:
					DisplayServer.window_set_position(DisplayServer.window_get_position() - Vector2i(1, 0))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Quit"):
		get_tree().quit()
	if event.is_action_pressed("Band"):
		character.play_band_anim()
		path_input_container.show()
		path_text_edit.text = SaveManager.save_data.music_path
	if event.is_action_pressed("Move"):
		can_drag = !can_drag
		mouse_position = Vector2i(get_global_mouse_position())
		if can_drag:
			character.play_drag_anim()
		else:
			# check position and use move anim
			window_position = DisplayServer.window_get_position()
			if window_position.y > screen_size.y*0.7:
				character.play_move_anim("fall")
				is_window_moving = true
				window_moving_direction = SIDE_BOTTOM
			elif window_position.y < screen_size.y*0.15:
				character.play_move_anim("jump")
				is_window_moving = true
				window_moving_direction = SIDE_TOP
			elif window_position.x < screen_size.x*0.15:
				character.play_move_anim("jump")
				is_window_moving = true
				window_moving_direction = SIDE_LEFT
			elif window_position.x > screen_size.x*0.8:
				character.play_move_anim("jump")
				is_window_moving = true
				window_moving_direction = SIDE_RIGHT
			else:
				character.current_state = character.State.IDLE_STATIC
				character.animated_sprite.play("default")


func _on_timer_timeout() -> void:
	info_label.hide()


func _on_path_button_pressed() -> void:
	SaveManager.save_path(path_text_edit.text)
	path_input_container.hide()
	character.load_music()

