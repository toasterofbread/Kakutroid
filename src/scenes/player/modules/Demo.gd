extends PlayerModule
class_name PlayerModuleDemo

const DEMO_IGNORED_ACTIONS: Array = ["DEBUG_quit", "demo_toggle_recording", "demo_play_file", "demo_load_file"]
const DEMOFILE_DIRECTORY: String = "res://data/demofiles/"

onready var module_input: PlayerModuleInput = player.module_input

# - Playback -
var playback_frame: int = 0
var playing: bool = false setget set_playing
var playback_data: Array = null

# - Recording -
var recording: bool = false setget set_recording
var recorded_data: Array = []

func _process(_delta: float):
	if player.debug_mode:
		if Input.is_action_just_pressed("demo_toggle_recording"):
			if playing:
				TextNotification.create("Cannot record, demo is currently playing")
			else:
				set_recording(!recording)
		
		if Input.is_action_just_pressed("demo_play_file"):
			if recording:
				TextNotification.create("Cannot play, demo is currently recording")
			elif not is_data_loaded():
				ButtonPromptNotification.create("A demo file must be loaded first", "demo_load_file")
			else:
				play()
			
		elif Input.is_action_just_pressed("demo_load_file"):
			var action: CustomDialog.Action = yield(CustomDialog.create_and_yield_option({
				"buttons": ["Load", "Cancel"],
				"input": true,
				"input_initial": DEMOFILE_DIRECTORY,
				"input_hint": "Load path",
				"title": "Load demofile",
				"body": "Input path of demofile to load"
			}), "completed")
			
			if action.get_button() == "Play" or action.is_input_confirm():
				if not File.new().file_exists(action.get_input_text()):
					TextNotification.create("No file exists at specified path").clear_after(Notification.LENGTH_NORMAL)
				else:
					load_file(action.get_input_text())

func _physics_process(_delta: float):
	if recording:
		var pressed_actions: Array = []
		for action in InputMap.get_actions():
			if action in DEMO_IGNORED_ACTIONS:
				continue
			if module_input.is_action_pressed(action):
				pressed_actions.append(action)
		recorded_data.append(pressed_actions)
	
	elif playing and is_data_loaded():
		if has_frame():
			playback_frame += 1
		else:
			set_playing(false)

func is_action_pressed_on_frame(action: String, frame_offset: int = 0) -> bool:
	assert(is_data_loaded())
	return has_frame(frame_offset) and action in playback_data[playback_frame + frame_offset]

func has_frame(frame_offset: int = 0) -> bool:
	assert(is_data_loaded())
	return playback_frame + frame_offset >= 0 and playback_frame + frame_offset < len(playback_data)

func is_data_loaded() -> bool:
	return playback_data != null

func set_recording(value: bool):
	if recording == value:
		return
	recording = value
	player.modulate = Color.blue if recording else Color.white
	
	if not recording and not recorded_data.empty():
		
		var action: CustomDialog.Action = yield(CustomDialog.create_and_yield_option({
			"buttons": ["Save", "Cancel"],
			"title": "Save recording",
			"body": "Input path to save recorded demo file:",
			"input": true,
			"input_hint": "Save path",
			"input_initial": DEMOFILE_DIRECTORY,
		}), "completed")
		
		if action.get_button() == "Save" or action.is_input_confirm():
			var write_path: String = action.get_input_text()
		
			var file: File = File.new()
			if file.file_exists(write_path):
				action = yield(CustomDialog.create_and_yield_option({
					"buttons": ["Overwrite", "Cancel"], 
					"title": "Overwrite file?", 
					"body": "A file already exists at path:\n\n" + write_path
				}), "completed")
				
				if action.get_button() != "Overwrite":
					write_path = null
			
			if write_path != null:
				file.open(write_path, File.WRITE)
				file.store_string(to_json(recorded_data))
				file.close()
				
				yield(CustomDialog.create_and_yield_option({
					"buttons": ["OK"], 
					"title": "File saved", 
					"body": "Recorded input data saved to file '" + write_path + "'. Size: " + str(len(recorded_data)) + " frames."
				}), "completed")
			
			recorded_data.clear()

func set_playing(value: bool):
	if playing == value:
		return
	playing = value
	module_input.demo_mode = playing
	player.modulate = Color.blue if playing and player.debug_mode else Color.white

func play(file_path: String = null):
	assert(file_path != null or is_data_loaded(), "Playback data must be loaded")
	
	if file_path != null:
		load_file(file_path)
	
	playback_frame = 0
	set_playing(true)

func load_file(file_path: String):
	var file: File = File.new()
	assert(file.file_exists(file_path))
	
	file.open(file_path, File.READ)
	playback_data = parse_json(file.get_as_text())
	file.close()
