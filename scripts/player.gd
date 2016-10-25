
extends KinematicBody

export(float) var view_sensitivity = 0.25
export(float) var movement_speed = 1.0
export(float) var friction = 0.9
export(float) var gravity = 9.8

var yaw = 0
var pitch = 0

# it's much simpler to keep horizontal and vertical velocities separated
# than it is to try to isolate them later
var hvel = Vector3()
var vvel = Vector3()

# current floor we're standing on
var ground = null

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	set_process_input(true)
	set_fixed_process(true)
	
	var eyes = get_node("Yaw/Camera/Eyes")
	eyes.add_exception(self)

func _input(ev):
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
	var direction = process_input()
	# need to reconsider crosshair
	# process_picking()
	
	process_internal_motion(direction, delta)
	if ground:
		process_external_motion(ground)

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
	
	var direction = Vector3()
	
	if f and not b: direction += hfacing
	elif b and not f: direction += -hfacing
	
	if l and not r: direction += hfacing.cross(Vector3(0,-1,0))
	elif r and not l: direction += -hfacing.cross(Vector3(0,-1,0))
	
	return direction.normalized()

func process_internal_motion(direction, delta):
	hvel *= friction
	hvel += direction * movement_speed
	vvel += Vector3(0, -gravity, 0)
	
	var velocity = delta * (hvel + vvel)
	
	var original = velocity
	var motion = move(velocity)
	
	var grounded = false
	ground = null
	
	var attempts = 4
	
	while is_colliding() and attempts:
		var normal = get_collision_normal()
		
		if rad2deg(acos(normal.dot(Vector3(0, 1, 0)))) < 30:
			grounded = true
			ground = get_collider()
		
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
func process_external_motion(ground):
	return
