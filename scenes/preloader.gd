extends Node2D

# if the loading is instantaneous, at least this many frames are shown
const FRAME_DELAY = 1
# in milliseconds, how much time should we dedicate per frame to loading
# at 60 FPS, 8ms = half a frame
const MAX_BLOCK_TIME = 8

# which scene to load
export(String, FILE, "*.scn,*.tsn") var loading_scene = "res://scenes/level_01/level_01.tscn"

# on error, this signal is fired
# @message	str		the error message to show
signal load_error(message)

# when a new piece of the scene is loaded, this signal is fired
# @loaded	int		how many assets have been loaded
# @total	int		the number of assets that need to be loaded, total
signal load_progress(loaded, total)

# when the loading process has finished, this signal is fired
# @scene	Node	the root node of the loaded scene, useful for post-processing
signal load_finished(scene)

onready var loader = ResourceLoader.load_interactive(loading_scene)
var frame_delay = FRAME_DELAY
var loaded_resource = null

func _ready():
	if loader == null:
		emit_signal("load_error", "Resource not found.")
		return
	
	set_process(true)

func _process(delta):
	if loader == null:
			get_node("/root/autoload").set_scene(loaded_resource)
			set_process(false)
			return
	
	if frame_delay > 0:
		frame_delay -= 1
		return
	else:
		frame_delay = FRAME_DELAY
	
	# spins out for a set amount of time to load whatever it can
	var time = OS.get_ticks_msec()
	while OS.get_ticks_msec() < time + MAX_BLOCK_TIME:
		var result = loader.poll()
		
		# EOF indicates load finish
		if result == ERR_FILE_EOF:
			loaded_resource = loader.get_resource().instance()
			emit_signal("load_finished", loaded_resource)
			# only set it to null, don't switch immediately
			# this allows time for signals to process scene
			loader = null
			break
		elif result == OK:
			emit_signal("load_progress", loader.get_stage(), loader.get_stage_count())
		# no idea what other kinds of errors can fire
		else:
			emit_signal("load_error", "Loading error occurred. Bad file format?")
			loader = null
			break