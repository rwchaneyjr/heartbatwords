extends RigidBody3D

@export var pitch_speed: float = 20.0
@export var hit_speed: float = 15.0
@export var trigger_z: float = 1.5   # Z position where hit triggers

var hit: bool = false

func _ready() -> void:
	gravity_scale = 0
	linear_velocity = Vector3.ZERO

	# Wait 1 second, then start the pitch
	await get_tree().create_timer(1.0).timeout
	start_pitch()

func start_pitch() -> void:
	# Move toward bat (word faces away from the bat, so use -Z)
	linear_velocity = -global_transform.basis.z.normalized() * pitch_speed

func _physics_process(delta: float) -> void:
	# Check position each frame, trigger hit if close enough
	if global_position.z >= trigger_z:
		reverse_direction()

func reverse_direction() -> void:
	if hit:
		return
	hit = true

	# Rotate 180° around Y so the word faces back
	rotate_y(deg_to_rad(180))
 
	# Set velocity to new forward direction
	#bat.play("Swing")
	linear_velocity = -global_transform.basis.z.normalized() * hit_speed
