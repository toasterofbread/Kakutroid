extends PlayerModule
class_name PlayerModuleDemo

signal PLAYBACK_FINISHED

const DEMO_IGNORED_ACTIONS: Array = [
	"DEBUG_quit", 
	"demo_toggle_recording", 
	"demo_play_file", 
	"demo_load_file",
	"ui_accept",
	"ui_home",
	"ui_select"
]
const DEMOFILE_DIRECTORY: String = "res://assets/resources/input_demos/"

onready var module_input: PlayerModuleInput = player.module_input

var demo_data: InputDemo = InputDemo.new()

# - Playback -
var playing: bool = false setget set_playing
var playback_frame: int = 0

var recording: bool = false setget set_recording

func _process(_delta: float):
	if player.is_paused():
		return
	
	if player.debug_mode:
		if Input.is_action_just_pressed("demo_toggle_recording"):
			if playing:
				TextNotification.create("Cannot record, demo is currently playing")
			else:
				set_recording(!recording)
		
		if Input.is_action_just_pressed("demo_play_file"):
			if recording:
				TextNotification.create("Cannot play, demo is currently recording")
			elif demo_data.get_frame_count() == 0:
				TextNotification.create("Demo data is empty")
			else:
				playback_frame = 0
				set_playing(!playing)
			
		elif Input.is_action_just_pressed("demo_load_file"):
			var action: CustomDialog.Action = yield(CustomDialog.create_and_yield_option({
				"buttons": ["Load", "Cancel"],
				"input": true,
				"input_hint": "Filename",
				"title": "Load demofile",
				"body": "Input filename of demofile to load"
			}), "completed")
			
			if action.get_button() == "Play" or action.is_input_confirm():
				var path: String = DEMOFILE_DIRECTORY.plus_file(action.get_input_text()) + ".tres"
				if not File.new().file_exists(path):
					TextNotification.create("No file exists at specified path")
				else:
					load_demo_file(path)
					TextNotification.create("Loaded demo file. Frames: " + str(demo_data.get_frame_count()))

func _physics_process(_delta: float):
	if player.is_paused():
		return
	
	if recording:
		demo_data.record_inputs()
	elif playing:
		if has_frame():
			playback_frame += 1
		else:
			set_playing(false)
			emit_signal("PLAYBACK_FINISHED")

func is_action_pressed_on_frame(action: String, frame_offset: int = 0) -> bool:
	return demo_data.is_action_pressed_on_frame(action, playback_frame + frame_offset)

func has_frame(frame_offset: int = 0) -> bool:
	return demo_data.has_frame(playback_frame + frame_offset)

func set_recording(value: bool):
	if recording == value:
		return
	recording = value
	player.modulate = Color.blue if recording else Color.white
	
	if recording:
		demo_data = InputDemo.new()
		demo_data.ignored_actions = DEMO_IGNORED_ACTIONS
		demo_data.metadata["player_data"] = player.save_data
		demo_data.metadata["player_background"] = player.background
	
	if not recording and demo_data.get_frame_count() != 0:
		
		var action: CustomDialog.Action = yield(CustomDialog.create_and_yield_option({
			"buttons": ["Save", "Cancel"],
			"title": "Save recording?",
			"body": "Input demo filename:",
			"input": true,
			"input_hint": "Filename",
		}), "completed")
		
		if action.get_button() == "Save" or action.is_input_confirm():
			var write_path: String = DEMOFILE_DIRECTORY.plus_file(action.get_input_text()) + ".tres"
			
			if File.new().file_exists(write_path):
				action = yield(CustomDialog.create_and_yield_option({
					"buttons": ["Overwrite", "Cancel"], 
					"title": "Overwrite file?", 
					"body": "A demo already exists at path:\n\n" + write_path
				}), "completed")
				
				if action.get_button() != "Overwrite":
					write_path = null
			
			if write_path != null:
				ResourceSaver.save(write_path, demo_data)
				TextNotification.create("Saved demo to " + write_path)
		
	if player.debug_mode:
		TextNotification.create("Started demo recording" if recording else "Stopped demo recording", Notification.LENGTH_SHORT)

func set_playing(value: bool):
	if playing == value:
		return
	playing = value
	module_input.demo_mode = playing
	player.modulate = Color.blue if playing and player.debug_mode else Color.white
	
	if player.debug_mode:
		TextNotification.create("Started demo playback" if playing else "Stopped demo playback", Notification.LENGTH_SHORT)

func play():
	playback_frame = 0
	set_playing(true)

func load_demo_file(file_path: String):
	demo_data = load(file_path)
