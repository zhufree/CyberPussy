extends Node2D
class_name Character

enum State {
	IDLE_STATIC, # play idle_static_anims randomly
	IDLE_MOVE, # play idle_move_anims randomly, window move with it
	CHAT, # default anim, play voice, maybe split band to play songs
	SIDE_MOVE, # play move anims depends on direction, then switch to idle
	DRAG,
	BAND
}
var idle_static_anims = ["door", "hole", "sese"] # 'default'
var idle_move_anims = ["climb", "ride"] #"push" # move with window
var side_move_anims = ["left", "up", "catch"]
var current_state = State.IDLE_STATIC

@onready var idel_static_timer: Timer = $IdleStaticAnimTimer
@onready var idel_move_timer: Timer = $IdleMoveAnimTimer
@onready var voice_random: AudioStreamPlayer2D = $VoiceRandom
@onready var voice_hem: AudioStreamPlayer2D = $VoiceHem
@onready var voice_hmm: AudioStreamPlayer2D = $VoiceHmm
@onready var music_player: AudioStreamPlayer2D = $MusicPlayer

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var random_words = []
var hem_words = []
var music_list = []


# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	animated_sprite.play(idle_static_anims.pick_random())
	load_audios_from_folder("res://assets/audio/love_words", random_words)
	load_audios_from_folder("res://assets/audio/hem", hem_words)

func load_music():
	var music_path = SaveManager.save_data.music_path
	var dir = DirAccess.open(music_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			var extension = file_name.get_extension()
			if extension == "wav" or extension == "mp3" or extension == "ogg":
				var file_path = music_path + "/" + file_name
				# var resource = ResourceLoader.load(file_path)
				# if resource:
					# 使用文件名作为键，将资源存储在字典中
				music_list.append(file_path)
			file_name = dir.get_next()
		dir.list_dir_end()
		play_music()
	else:
		print("An error occurred when trying to access the path.")

func play_music():
	var file_path = music_list.pick_random()
	print(file_path)
	var audio_stream
	match file_path.get_extension():
		"wav":
			audio_stream = load_wav(file_path)
		"mp3":
			audio_stream = AudioStreamMP3.new()
			var file = FileAccess.open(file_path, FileAccess.READ)
			audio_stream.data = file.get_buffer(file.get_length())
			file.close()
		"ogg":
			audio_stream = AudioStreamOggVorbis.load_from_file(file_path)
	music_player.stream = audio_stream
	music_player.play()

func load_audios_from_folder(folder_path: String, target_list):
	var dir = DirAccess.open(folder_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			var extension = file_name.get_extension()
			if extension == "wav":
				var file_path = folder_path + "/" + file_name
				var resource = ResourceLoader.load(file_path)
				if resource:
					# 使用文件名作为键，将资源存储在字典中
					target_list.append(resource)
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		print("An error occurred when trying to access the path.")

func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event.is_action_pressed("ChatStart"):
		voice_random.stream = random_words.pick_random()
		voice_random.play()

func play_band_anim():
	animated_sprite.play("band")
	current_state = State.BAND
	
func play_drag_anim():
	animated_sprite.flip_h = false
	animated_sprite.play("drag")
	current_state = State.DRAG

func play_move_anim(anim: String):
	animated_sprite.play(anim)
	current_state = State.SIDE_MOVE


func _on_move_anim_timer_timeout() -> void:
	if current_state != State.DRAG and current_state != State.SIDE_MOVE:
		current_state = State.IDLE_MOVE
		if not animated_sprite.is_playing():
			animated_sprite.play(idle_move_anims.pick_random())
			voice_hem.stream = hem_words.pick_random()
			voice_hem.play()


# this state changing depends on touching window, not animation finish
func _on_main_window_jump_to_side(side: Variant) -> void:
	if current_state != State.DRAG:
		match side:
			SIDE_TOP:
				animated_sprite.play("up")
			SIDE_LEFT:
				animated_sprite.play("left")
			SIDE_RIGHT:
				animated_sprite.flip_h = true
				animated_sprite.play("left")
			SIDE_BOTTOM:
				animated_sprite.play("catch")


func _on_idel_static_anim_timer_timeout() -> void:
	if current_state != State.DRAG and current_state != State.SIDE_MOVE:
		current_state = State.IDLE_STATIC
		if not animated_sprite.is_playing():
			var random_anim = idle_static_anims.pick_random()
			animated_sprite.play(random_anim)
			if random_anim == "sese":
				voice_hmm.play()
			else:
				voice_hem.stream = hem_words.pick_random()
				voice_hem.play()
	

var side_move_count = 0
var loop_count = 0
func _on_animated_sprite_2d_animation_looped() -> void:
	if current_state == State.IDLE_STATIC or current_state == State.IDLE_MOVE:
		if loop_count > 10:
			animated_sprite.animation = "default"
			animated_sprite.stop()
			var random_bool = randf() < 0.5
			if random_bool:
				idel_move_timer.wait_time = randi() % 20 + 10
				idel_move_timer.start()
			else:
				idel_static_timer.wait_time = randi() % 10 + 10
				idel_static_timer.start()
			loop_count = 0
		else:
			loop_count += 1
	if current_state == State.SIDE_MOVE:
		if side_move_count > 5:
			side_move_count = 0
			animated_sprite.stop()
			if animated_sprite.animation == "left":
				animated_sprite.flip_h = false
				animated_sprite.animation = "default"
			current_state = State.IDLE_STATIC
		else:
			side_move_count += 1

func reset_window_position(x = -1, y = -1):
	if x >= 0:
		Window.position.x = x
	if y >= 0:
		Window.position.y = y


func _on_music_player_finished() -> void:
	play_music()


#Take a Packed Byte Array and reverse it to read little endian data to an integer
func read_le_int(file:FileAccess, byte_size:int):
	var file_buffer:PackedByteArray = file.get_buffer(byte_size)
	file_buffer.reverse()
	return file_buffer.hex_encode().hex_to_int()

func load_wav(path:String):
	var wav_file:AudioStreamWAV = AudioStreamWAV.new()
	var file:FileAccess = FileAccess.open(path, FileAccess.READ)
	
	#CHUNK ID
	var file_buffer:PackedByteArray = file.get_buffer(4)
	if(file_buffer.get_string_from_ascii() != "RIFF"):
		push_error("[load_wav] Invalid file type - not RIFF")
		return false
	#CHUNK SIZE - Full byte size minus first 8 bytes
	var chunk_size:int = read_le_int(file, 4)
	var real_size:int = file.get_length()-8
	if(chunk_size != real_size):
		push_error("[load_wav] Chunk size does not match. Chunk: ", chunk_size,". Expected: ",real_size)
		return false
	#FORMAT
	file_buffer = file.get_buffer(4)
	if(file_buffer.get_string_from_ascii() != "WAVE"):
		push_error("[load_wav] Invalid file type - not WAVE")
		return false
	#SUB CHUNK1 ID
	file_buffer = file.get_buffer(4)
	if(file_buffer.get_string_from_ascii() != "fmt "):
		push_error("[load_wav] Invalid file type - not fmt")
		return false
	#SUB CHUNK1 SIZE
	var s_chunk1_size:int = read_le_int(file, 4)
	if(s_chunk1_size != 16):
		push_error("[load_wav] Unsupported type. Only supports PCM.")
		return false
	#AUDIO FORMAT
	var audio_format:int = read_le_int(file, 2)
	if(audio_format != 1):
		push_error("[load_wav] Unsupported type. Only supports PCM.")
		return false
	#NUMBER OF CHANNELS
	var channels:int = read_le_int(file, 2)
	if(channels > 2):
		push_error("[load_wav] Unsupported channel amount. Only supports Mono or Stereo.")
		return false
	#SAMPLE RATE
	var sample_rate:int = read_le_int(file, 4)
	#BYTE RATE = SampleRate*NumChannels*BitsPerSample/8
	var byte_rate:int = read_le_int(file, 4)
	#Block Align = NumChannels*BitsPerSample/8
	var block_align:int = read_le_int(file, 2)
	#BITS PER SAMPLE
	var bit_rate:int = read_le_int(file, 2)
	#"DATA" TEXT
	file_buffer = file.get_buffer(4)
	if(file_buffer.get_string_from_ascii() != "data"):
		push_error("[load_wav] Invalid file type - not 'data'")
		return false
	#AUDIO DATA SIZE
	var audio_data_size:int = read_le_int(file, 4)
	
	
	#Confirming values
	var expected_byte_rate:float = sample_rate * channels * bit_rate / 8.0
	if(byte_rate != expected_byte_rate):
		push_error("[load_wav] Invalid formatting, byte rate incorrect.")
		return false
	
	var expected_block_align:float = channels * bit_rate / 8.0
	if(block_align != expected_block_align):
		push_error("[load_wav] Invalid formatting, block align incorrect.")
		return false
	####Adding Data to AudioStreamWAV####
	match(bit_rate):
		8:
			wav_file.format = AudioStreamWAV.FORMAT_8_BITS
		16:
			wav_file.format = AudioStreamWAV.FORMAT_16_BITS
		_:
			push_error("[load_wav] Unsupported bit rate")
			return false
	
	wav_file.mix_rate = sample_rate
	if(channels == 2):
		wav_file.stereo = true
	else:
		wav_file.stereo = false
	
	#Audio Data's starting offset is the full file size minus the difference between chunk size and audio data size, minus 8 for the 8 bytes not included in chunk size
	wav_file.data = file.get_buffer(file.get_length()-(chunk_size-audio_data_size)-8)
	
	return wav_file
