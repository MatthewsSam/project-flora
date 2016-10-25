extends Node

# the scene that handles preloading of other scenes
var preloader_scene = preload("res://scenes/preloader.tscn")
var current_scene = null

func _ready():
	var root = get_tree().get_root()
	current_scene = root.get_child(root.get_child_count() - 1)

func get_scene():
	return current_scene

# sets the scene immediately, no preloading screen
func set_scene(path_or_scene):
	# if it's a path, just block until it's loaded
	# as we didn't request a preloader
	if typeof(path_or_scene) == TYPE_STRING:
		path_or_scene = ResourceLoader.load(path_or_scene)
	
	# otherwise throw it at the scene swapper
	# it can handle both packedscenes and scenes
	call_deferred("_deferred_set_scene", path_or_scene)

# sets the scene after interactive preloading
func set_scene_preloaded(path):
	# create an instance of the preloader, setting the path
	var preloader_instance = preloader_scene.instance()
	preloader_instance.loading_scene = path
	
	# swap to the preloader scene
	call_deferred("_deferred_set_scene", preloader_instance)

func _deferred_set_scene(scene):
	current_scene.free()
	
	if scene extends PackedScene:
		current_scene = scene.instance()
	else:
		current_scene = scene
	
	get_tree().get_root().add_child(current_scene)
	get_tree().set_current_scene(current_scene)