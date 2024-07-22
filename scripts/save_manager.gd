extends Node

var save_file_path = ProjectSettings.globalize_path("res://")
var save_file_name = "save.tres"
var save_data = SaveData.new()


func verify_save_directory(path: String):
	DirAccess.make_dir_absolute(path)

func load_save_data():
	if FileAccess.file_exists(save_file_path + save_file_name):
		save_data = ResourceLoader.load(save_file_path + save_file_name).duplicate(true)
		print('save data loaded')

func save_path(path):
	save_data.save_music_path(path)
	save()

func check_path():
	if save_data.music_path == "":
		return false
	else:
		return true
		
func save():
	ResourceSaver.save(save_data, save_file_path + save_file_name)
	print('data saved')

# Called when the node enters the scene tree for the first time.
func _ready():
	verify_save_directory(save_file_path)
	load_save_data()
