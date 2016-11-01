extends Spatial

export(StringArray) var resource_path
var zombie_ref = []

export(float) var spawn_frequency = 2.0
var is_spawning = true
var spawn_timer = Timer.new()

var cust_time_running = false
var cust_time

func _ready():
	for i in resource_path:
		zombie_ref.append(i)
	
	print(zombie_ref)
	spawn_timer = Timer.new()
	
	randomize()
	#spawn_timer.set_one_shot(true)
	#spawn_timer.set_autostart(false)
	#spawn_timer.set_timer_process_mode(1)
	set_process(true)



func run_timer():
	if(!spawn_timer.is_active()):
		spawn_timer.start()
		spawn_timer.set_wait_time(spawn_frequency)
	
	#print(spawn_timer.get_time_left())
	#print(spawn_timer.get_wait_time())
	
	if(spawn_timer.get_time_left() == 0):
		var i = round(rand_range(0, zombie_ref.size() - 1))
		
		var obj = load(zombie_ref[i]).instance()
		
		#print(i)
		
		self.add_child(obj)
		
		spawn_timer.set_wait_time(spawn_frequency)


func custom_timer():
	if(!cust_time_running):
		cust_time = spawn_frequency
		cust_time_running = true
	
	if(cust_time_running):
		cust_time -= get_process_delta_time()
		
		if(cust_time <= 0):
			cust_time = spawn_frequency
			var i = round(rand_range(0, zombie_ref.size() - 1))
			
			var obj = load(zombie_ref[i]).instance()
			self.add_child(obj, true)


func _process(delta):
	if(is_spawning):
		custom_timer()