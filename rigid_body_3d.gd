extends RigidBody3D

@export var pitch_speed: float = 20.0
@export var hit_speed: float = 15.0
@export var trigger_z: float = 1.5
@export var return_z: float = -5.0     # where to return toward after hit

var hit: bool = false
var start_pos: Vector3
var forward_dir: Vector3
var backward_dir: Vector3

func _ready() -> void:
	gravity_scale = 0
	can_sleep = false
	linear_velocity = Vector3.ZERO
	
	start_pos = global_position
	
	# forward direction: toward +Z plane
	forward_dir = (Vector3(start_pos.x, start_pos.y, trigger_z) - start_pos).normalized()
	
	# backward direction: return to behind start
	backward_dir = (Vector3(start_pos.x, start_pos.y, return_z) - Vector3(start_pos.x, start_pos.y, trigger_z)).normalized()

	await get_tree().create_timer(1.0).timeout
	start_pitch()

func start_pitch() -> void:
	linear_velocity = forward_dir * pitch_speed

func _physics_process(delta: float) -> void:
	if not hit and global_position.z >= trigger_z:
		rotate_y(deg_to_rad(180))
		reverse_direction()

func reverse_direction() -> void:
	if hit: return
	hit = true

	# Face backward visually
	rotate_y(PI)

	# Use backward_dir for motion
	linear_velocity = backward_dir * hit_speed
