extends RigidBody3D

@export var pitch_speed: float = 20.0
@export var hit_speed: float = 15.0

var hit = false

func _ready():
	gravity_scale = 0
	linear_velocity = Vector3.ZERO  # Stay still at spawn

	await get_tree().create_timer(1.0).timeout
	start_pitch()

func start_pitch():
	# Move toward bat (opposite of where the word is facing)
	linear_velocity = -global_transform.basis.z.normalized() * pitch_speed

func reverse_direction():
	if hit:
		return
	hit = true

	# Turn the word 180° around Y axis
	rotate_y(deg_to_rad(180))

	# Fly in the new forward direction
	linear_velocity = -global_transform.basis.z.normalized() * hit_speed
