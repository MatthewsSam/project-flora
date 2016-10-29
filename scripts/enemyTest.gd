extends KinematicBody

###TODO:#############################################
#		Figure out why some cubes stop moving		#
#####################################################

#If multiplayer is added, create a reference for each player
#Perform occasional distance and line of sight check
#Track based on results


#####################
#	OPTIMIZATIONS	#
#####################
#-Compare zeroing out look at with trig at the start of movement
#
#

export(float) var speed = 5.0
var scene_root



#The offset applied to movement if rays trigger
export(int) var move_mult = 3



#How close will the character get to the target
#before stopping
export(float) var min_distance = 2



#Player references
export var player_ref = ""
var player_obj


#AI
#Bool to toggle AI, skipping code while inactive
export(bool) var ai_active = false
export(float) var move_solve_length = .5
var movement_solving = false
var solve_timer = Timer.new()
var solve_roll



#Raycast references
export(NodePath) var left_ray
var left_ref
export(NodePath) var forward_ray
var forward_ref
export(NodePath) var right_ray
var right_ref



#Planned movement for the character
var movement_vector
var motion
export(float) var gravity_force = -5.0




#################
#	Functions	#
#################


func run_ai():
	#Check if the player has been spotted; if not, skip out
	if(!ai_active):
		return
	
	#Else, check the distance and move if it isn't too close
	if(get_translation().distance_to(player_obj.get_translation()) >= min_distance):
		move_myself()


func move_myself():
	#Look at the player and calculate original path
	var s = get_scale()
	look_at(player_obj.get_translation(), Vector3(0, 1, 0))
	set_scale(s)
	
	#movement_vector = player_obj.get_global_transform().origin - get_global_transform().origin
	
	var position = get_global_transform().origin
	var player_position = player_obj.get_global_transform().origin
	movement_vector = player_position - position
	var facing = fmod(atan2(movement_vector.normalized().x, movement_vector.normalized().z), PI * 2)
	set_rotation(Vector3(0, facing + PI, 0))
	
	
	#Check the movement solving timer
	if(solve_timer.get_time_left() == 0):
		solve_timer.stop()
		movement_solving = false
	
	
	
	#Uncomment and check prints if rays seem to not be working;
	#the direction may be wrong or they may not be colliding
	#print(forward_ref.is_colliding(), left_ref.is_colliding(), right_ref.is_colliding())
	
	
	
	#Move away from object if only one collision returns true
	if(right_ref.is_colliding() and !left_ref.is_colliding()):
		movement_vector.x = get_translation().x + move_mult
	
	if(left_ref.is_colliding() and !right_ref.is_colliding()):
		movement_vector.x = -get_translation().x - move_mult
	
	
	
	#Else, run an RNG occasionally to try to move around object
	if(left_ref.is_colliding() and right_ref.is_colliding()):
		
		#If we aren't currently trying to solve the movement
		#issue, start trying to solve it
		if(!movement_solving):
			solve_roll = randi() % 2 + 1
			solve_timer.set_wait_time(move_solve_length)
			solve_timer.start()
			movement_solving = true
			#print("Attempting to solve being stuck. Solve roll is ", solve_roll)
		
		if(solve_roll == 1):
			movement_vector.x = get_translation().x + move_mult
		
		if(solve_roll == 2):
			movement_vector.x = -get_translation().x - move_mult
	
	
	
	if(forward_ref.is_colliding()): 
		movement_vector.z = get_translation().z - move_mult
	
	
	
	motion = move(movement_vector.normalized() * speed * get_fixed_process_delta_time())
	
	if(self.is_colliding()):
		var n = get_collision_normal()
		motion = n.slide(motion)
		move(motion)



func _ready():
	scene_root = get_tree().get_root().get_child(1)
	randomize()
	print(scene_root.get_name())
	
	
	
	player_obj = scene_root.get_node(player_ref)
	if(player_ref != null):
		print("Successfully found player!")
	
	else:
		print("Player is null!")
		return
	
	
	
	#Get raycast references
	forward_ref = get_node(forward_ray)
	left_ref = get_node(left_ray)
	right_ref = get_node(right_ray)
	
	
	
	#Add player and self as exceptions
	forward_ref.add_exception(self)
	left_ref.add_exception(self)
	right_ref.add_exception(self)
	forward_ref.add_exception(player_obj)
	left_ref.add_exception(player_obj)
	right_ref.add_exception(player_obj)
	
	
	
	#Timer setup
	solve_timer.set_one_shot(true)
	
	set_fixed_process(true)



func _fixed_process(delta):
	run_ai()
	
	#Gravity
	move(Vector3(0, gravity_force * delta, 0))