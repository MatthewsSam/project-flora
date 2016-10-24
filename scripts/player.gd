# Copyright (c) 2015 Calinou
# This source code form is governed by the MIT license.
# See LICENSE.md for more information.

extends RigidBody

var g_itemSelected = null
var g_mouse_captured = true
var g_itemSelectToggle = false
var g_current_position = null
var g_original_position = null
var g_current_state = "ACTIVE"
var isSelectingItem = false
var g_hud = null

var view_sensitivity = 0.25
var yaw = 0
var pitch = 0
var is_moving = false

const max_accel = 0.005
const air_accel = 0.02

var timer = 0

# Walking speed and jumping height are defined later.
var walk_speed
var jump_speed

var health = 100
var stamina = 10000
var ray_length = 10

func _ready():
	set_process_input(true)
	Globals.set_meta("player", self)
	g_hud = Globals.get_meta("hud")
	g_original_position = get_translation()

	# Capture mouse once game is started:
	change_state("ACTIVE")
	set_fixed_process(true)

func _input(event):
	
	if g_current_state == "ACTIVE":
		if event.type == InputEvent.MOUSE_MOTION:
			yaw = fmod(yaw - event.relative_x * view_sensitivity, 360)
			pitch = max(min(pitch - event.relative_y * view_sensitivity, 85), -85)
			get_node("Yaw").set_rotation(Vector3(0, deg2rad(yaw), 0))
			get_node("Yaw/Camera").set_rotation(Vector3(deg2rad(pitch), 0, 0))

	# Toggle mouse capture:
	#if Input.is_action_pressed("toggle_mouse_capture"):
		#g_mouse_captured = !g_mouse_captured


	# Quit the game:
	if Input.is_action_pressed("quit"):
		quit()

	if g_current_state == "ACTIVE":
		if event.type == InputEvent.MOUSE_BUTTON and event.pressed and event.button_index==1:
			var camera = get_node("Yaw/Camera")
			var from = camera.project_ray_origin(event.pos)
			var to = from + camera.project_ray_normal(event.pos) * ray_length

func _fixed_process(delta):
	timer += 1

	if timer >= 8:
		timer = 0

	if g_current_state == "ACTIVE":
		if Input.is_action_pressed("pick_up"):
			if !g_itemSelectToggle:
				if (isSelectingItem == true):
					g_itemSelected.pick_item()
				g_itemSelectToggle = true
	
		elif g_itemSelectToggle:
			g_itemSelectToggle = false

	
	
	is_moving = false
	


func _integrate_forces(state):
	# Default walk speed:
	walk_speed = 3.5
	# Default jump height:
	jump_speed = 3
	
	# Manage if the player select an item
	if g_current_state == "ACTIVE":
		item_select_management()

	# Cap stamina:
	if stamina >= 10000:
		stamina = 10000
	if stamina <= 0:
		stamina = 0

	var aim = get_node("Yaw").get_global_transform().basis

	var direction = Vector3()

	if g_current_state == "ACTIVE":
		if Input.is_action_pressed("move_forwards"):
			direction -= aim[2]
			is_moving = true
		if Input.is_action_pressed("move_backwards"):
			direction += aim[2]
			is_moving = true
		if Input.is_action_pressed("move_left"):
			direction -= aim[0]
			is_moving = true
		if Input.is_action_pressed("move_right"):
			direction += aim[0]
			is_moving = true

	direction = direction.normalized()
	var ray = get_node("Ray")
	
	# Increase walk speed and jump height while running and decrement stamina:
	if Input.is_action_pressed("run") and is_moving and ray.is_colliding() and stamina > 0:
		walk_speed *= 1.4
		jump_speed *= 1.2
		stamina -= 15

	if ray.is_colliding():
		var up = state.get_total_gravity().normalized()
		var normal = ray.get_collision_normal()
		var floor_velocity = Vector3()
		var object = ray.get_collider()

		if object extends RigidBody or object extends StaticBody:
			var point = ray.get_collision_point() - object.get_translation()
			var floor_angular_vel = Vector3()
			if object extends RigidBody:
				floor_velocity = object.get_linear_velocity()
				floor_angular_vel = object.get_angular_velocity()
			elif object extends StaticBody:
				floor_velocity = object.get_constant_linear_velocity()
				floor_angular_vel = object.get_constant_angular_velocity()
			# Surely there should be a function to convert Euler angles to a 3x3 matrix
			var transform = Matrix3(Vector3(1, 0, 0), floor_angular_vel.x)
			transform = transform.rotated(Vector3(0, 1, 0), floor_angular_vel.y)
			transform = transform.rotated(Vector3(0, 0, 1), floor_angular_vel.z)
			floor_velocity += transform.xform_inv(point) - point
			yaw = fmod(yaw + rad2deg(floor_angular_vel.y) * state.get_step(), 360)
			get_node("Yaw").set_rotation(Vector3(0, deg2rad(yaw), 0))

		var diff = floor_velocity + direction * walk_speed - state.get_linear_velocity()
		var vertdiff = aim[1] * diff.dot(aim[1])
		diff -= vertdiff
		diff = diff.normalized() * clamp(diff.length(), 0, max_accel / state.get_step())
		diff += vertdiff

		apply_impulse(Vector3(), diff * get_mass())

		# Regenerate stamina:
		stamina += 5

		if g_current_state == "ACTIVE":
			if Input.is_action_pressed("jump") and stamina > 150:
				apply_impulse(Vector3(), normal * jump_speed * get_mass())
				#get_node("Sounds").play("jump")
				stamina -= 150

	else:
		apply_impulse(Vector3(), direction * air_accel * get_mass())

	state.integrate_forces()

func _exit_scene():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# Functions
# =========

# Enable the mouse
func enable_mouse(tog):
	if (tog):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		view_sensitivity = 0
		g_mouse_captured = false
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		view_sensitivity = 0.25
		g_mouse_captured = true

func change_state(state):
	g_current_state = state
	# If the player is considered active it means he can moves in the map
	if state == "ACTIVE":
		# Reset game speed
		Globals.set_meta("speed", 1.0)
		# The camera is player's camera
		get_node("Yaw/Camera").make_current()
		# The mouse is captured
		enable_mouse(false)
		# The global HUD is displayed
		#get_node("../HUD/display").set_hidden(false)
		#get_node("../HUD/search").set_hidden(true)
		# Reset the player's position
		if g_current_position != null:
			set_translation(g_current_position)
			g_current_position = null

	if state == "CONSOLE":
		enable_mouse(true)
	
	# If the player is doing a job, it means the player's gui is disabled and replaced by custom GUI
	if state == "JOB":
		# The camera will be different
		get_node("Yaw/Camera").clear_current()
		# The mouse will be enabled (to be able to click to stuff)
		enable_mouse(true)
		# The global HUD is hidden
		get_node("../HUD/display").set_hidden(true)
		# The physical player is moved to a location who doesn't interfere with the job
		#g_current_position = get_translation()
		#set_translation(get_node("../player_neutral_position").get_translation())
	
	if state == "SEARCHING":
		# The time goes faster when you search
		Globals.set_meta("speed", 2.0)
		get_node("../HUD/display").set_hidden(true)
		get_node("../HUD/search").set_hidden(false)
		g_hud.set_searchProgress(2)

func reset_player_pos():
	g_current_position = g_original_position
	set_translation(g_original_position)

func get_state():
	return g_current_state

# Manage the selection of items
func item_select_management():
	# detect if the player select an item and if it's the case store it
	var picking_distance = 2
	var transform = get_viewport().get_camera().get_global_transform();
	var result = get_world().get_direct_space_state().intersect_ray(transform.origin, transform.xform(Vector3(0,0,-1*picking_distance)), [self]);
	
	if !result.empty():
		if result["collider"].is_in_group("items"):
			g_itemSelected = result["collider"]
			isSelectingItem = true
		else:
			isSelectingItem = false
	else:
		isSelectingItem = false


	#if isSelectingItem:
		#g_hud.set_crosshair_text(g_itemSelected.get_helper())
		#g_hud.set_time_to_display_crosshair(3)
	#else:
		#g_hud.set_crosshair_text(" \n.\n ")

# Quits the game:
func quit():
	get_tree().quit()
