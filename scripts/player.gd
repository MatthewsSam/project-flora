
extends KinematicBody

# camera pan speed & angle
var view_sensitivity = 0.25
var yaw = 0
var pitch = 0

# walking/running control variables
var acceleration = 0.25
var max_speed = 5 # units per second
var deceleration = 0.25

var direction = Vector3(0,0,1)
var speed = 0

# jumping control variables
var gravity = 0.5
var jump_force = 10

# it's much simpler to keep horizontal and vertical velocities separated
# than it is to try to isolate them later
var hvel = Vector3()
var vvel = Vector3()

# current floor we're standing on, if any
var ground = null

# various flags
var is_moving = false
var quit_triggered = false
var jump_triggered = false

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	set_process_input(true)
	set_fixed_process(true)
	
	var eyes = get_node("Yaw/Camera/Eyes")
	eyes.add_exception(self)

func _input(ev):
	# toggle input capture
	if Input.is_action_pressed("quit") and !quit_triggered:
		toggle_capture()
		quit_triggered = true
	
	if !Input.is_action_pressed("quit"):
		quit_triggered = false
	
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if ev.type == InputEvent.MOUSE_MOTION:
			yaw = fmod(yaw - ev.relative_x * view_sensitivity, 360)
			pitch = max(min(pitch - ev.relative_y * view_sensitivity, 85), -85)
			get_node("Yaw").set_rotation(Vector3(0, deg2rad(yaw), 0))
			get_node("Yaw/Camera").set_rotation(Vector3(deg2rad(pitch),0,0))
	
	if ev.type == InputEvent.MOUSE_BUTTON:
		if ev.is_pressed() and !ev.is_echo():
			# TODO: implement picking
			pass

func _fixed_process(delta):
	process_input()
	# need to reconsider crosshair
	# process_picking()
	
	process_internal_motion(direction, delta)
	if ground:
		process_external_motion(ground)

func toggle_capture():
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func handle_mouse(button):
	var camera = get_node("Yaw/Camera")
	var size = get_viewport().get_rect().size
	var facing = camera.project_ray_normal(size / 2)
	var eyes = get_node("Yaw/Camera/Eyes")
	
	if eyes.is_colliding():
		var target = eyes.get_collider()
		if target.has_method("pick"):
			target.pick(self)

func process_picking():
	var eyes = get_node("Yaw/Camera/Eyes")
	var cross = get_node("Yaw/Camera/Crosshair")
	var target = null
	
	if eyes.is_colliding():
		target = eyes.get_collider()
		if target.has_method("pick"):
			cross.set_modulate(Color(1,0,0))
		else:
			cross.set_modulate(Color(1,1,1))
	else:
		cross.set_modulate(Color(1,1,1))

func process_input():
	var camera = get_node("Yaw/Camera")
	var size = get_viewport().get_rect().size
	var facing = camera.project_ray_normal(size / 2)
	var hfacing = Vector3(facing.x, 0, facing.z).normalized()
	
	var f = Input.is_action_pressed("move_forwards")
	var b = Input.is_action_pressed("move_backwards")
	var l = Input.is_action_pressed("move_left")
	var r = Input.is_action_pressed("move_right")
	
	if f or b or l or r:
		is_moving = true
		
		direction = Vector3()
		
		if f and not b:
			direction += hfacing
		elif b and not f:
			direction += -hfacing
		
		if l and not r:
			direction += hfacing.cross(Vector3(0,-1,0))
		elif r and not l:
			direction += -hfacing.cross(Vector3(0,-1,0))
		
		direction = direction.normalized()
	else:
		is_moving = false

func process_internal_motion(direction, delta):
	var jump = Input.is_action_pressed("jump")
	
	if !jump:
		jump_triggered = false
	
	if ground != null and jump and !jump_triggered:
		vvel *= 0
		vvel += Vector3(0, 1, 0) * jump_force
		jump_triggered = true
	
	vvel += Vector3(0, -gravity, 0)
	
	if is_moving:
		speed = min(speed + acceleration, max_speed)
	else:
		speed = max(speed - deceleration, 0)
	
	hvel = direction * speed
	
	var velocity = delta * (hvel + vvel)
	
	var original = velocity
	var motion = move(velocity)
	
	var grounded = false
	ground = null
	
	var attempts = 4
	
	while is_colliding() and attempts:
		var normal = get_collision_normal()
		
		if rad2deg(acos(normal.dot(Vector3(0, 1, 0)))) < 30:
			ground = get_collider()
			grounded = true
		
		motion = normal.slide(motion)
		velocity = normal.slide(velocity)
		
		if original.dot(velocity) > 0:
			motion = move(motion)
			if motion.length() < 0.001:
				break
		
		attempts -= 1
	
	if grounded:
		vvel *= 0

# stub, if we have conveyor belts or something we'll need this
# probably a more appropriate place for friction if i can get that working
func process_external_motion(ground):
	return
