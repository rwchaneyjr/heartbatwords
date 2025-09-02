extends Camera3D

@export var target: Node3D
@export var follow_speed: float = 10.0
@export var camera_distance: float = 15.0
@export var camera_height: float = 6.0
@export var horizontal_offset: float = 26 # New: positive = right, negative = left

func _ready():
	if not target:
		push_warning("Please drag your player node into the 'target' field in the inspector!")

func _process(delta):
	if not target:
		return
	
	# Calculate camera position with horizontal offset
	var target_position = target.global_position + Vector3(horizontal_offset, camera_height, camera_distance)
	
	global_position = global_position.lerp(target_position, follow_speed * delta)
	look_at(target.global_position, Vector3.UP)
