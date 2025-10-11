extends Node3D

@export var target: Node3D
@export var start_position: Node3D
@export var speed: float = 15.0

var going_to_target: bool = true

func _ready() -> void:
	var area = $Area3D
	if area:
		area.body_entered.connect(_on_bat_collision)
		#print("✓ Word ready:", name)
		#print("  Collision Layer:", area.collision_layer)
		#print("  Collision Mask:", area.collision_mask)
	#else:
		#print("✗ NO AREA3D FOUND!")

func _physics_process(delta: float) -> void:
	if target == null or start_position == null:
		return
	
	var goal: Vector3
	
	if going_to_target:
		goal = target.global_position
	else:
		goal = start_position.global_position
	
	# Calculate distance (only X and Z, ignore Y)
	var flat_goal = Vector3(goal.x, global_position.y, goal.z)
	var distance = global_position.distance_to(flat_goal)
	
	if distance < 0.5:
		if not going_to_target:
			#print("Reached start, stopping completely")
			set_physics_process(false)
		return
	
	# Move only horizontally (X and Z), keep Y the same
	var direction = (flat_goal - global_position).normalized()
	global_position += direction * speed * delta
	
	#if not going_to_target:
		#print("Moving BACK to start, distance:", distance)

func _on_bat_collision(body: Node3D) -> void:
	#print("!!!! COLLISION WITH:", body.name, " !!!!")
	going_to_target = false
	#print("Now returning to start!")
