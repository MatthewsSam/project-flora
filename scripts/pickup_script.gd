extends Area


#########################
#	Exported Variables	#
#########################


#whether or not target_name is used; otherwise,
#collision data is used to get name
export var use_target_name = false

#the name of the target if above bool is true
export var target_name = ""

#what function is to be called on affected obj;
#string is passed to object as function call
export var func_to_call = ""

#forces player to interact instead of using 
#the object automatically
export var can_interact_with = false

#calls func_to_call when entering area
export var call_on_enter = true

#should the object be destroyed?
export var destroy_on_use = true

#is a ... passed in the function
#and what value should it have
export var use_bool = false
export var bool_to_pass = false

export var use_number = false
export var num_to_pass = 0.0

export var use_string = false
export var string_to_pass = ""


#########################
#	Global Variables	#
#########################


#used to find the scene root in ready()
var root_node

#whether or not the target is in the area
var target_is_inside = false

#the target object, either acquired by name or collision
var target_obj


#################
#	Functions	#
#################


func destroy_my_self():
	self.queue_free()


func _ready():
	#if getting by name, find the obj that way
	root_node = get_node("/root").get_child(0)
	target_obj = root_node.get_node(target_name)
	
	if(use_target_name):
		if(!use_bool and !use_string and !use_number):
			target_obj.call(func_to_call)
		
		if(use_bool):
			target_obj.call(func_to_call, bool_to_pass)
		
		if(use_number):
			target_obj.call(func_to_call, num_to_pass)
		
		if(use_string):
			target_obj.call(func_to_call, string_to_pass)
		
		
		if(destroy_on_use):
			destroy_my_self()


func _input(event):
	if(Input.is_action_pressed("interact")):
		if(!use_bool and !use_string and !use_number):
			target_obj.call(func_to_call)
		
		if(use_bool):
			target_obj.call(func_to_call, bool_to_pass)
		
		if(use_number):
			target_obj.call(func_to_call, num_to_pass)
		
		if(use_string):
			target_obj.call(func_to_call, string_to_pass)
		
		if(destroy_on_use):
			destroy_my_self()


#Called when a body enters
func on_my_body_enter( body ):
	print(body.get_name())
	if(body.has_method(func_to_call) and call_on_enter):
		if(!use_bool and !use_string and !use_number):
			target_obj.call(func_to_call)
		
		if(use_bool):
			target_obj.call(func_to_call, bool_to_pass)
		
		if(use_number):
			target_obj.call(func_to_call, num_to_pass)
		
		if(use_string):
			target_obj.call(func_to_call, string_to_pass)
		
		if(destroy_on_use):
			destroy_my_self()
	
	if(body.get_name() == target_name):
		target_is_inside = true
		
#		print(target_is_inside)
		
		if(can_interact_with):
			set_process_input(true)


#called when a body exits
func _on_my_body_exit( body ):
	if(body.get_name() == target_name):
		target_is_inside = false
		
#		print(target_is_inside)
		
		if(can_interact_with):
			set_process_input(false)