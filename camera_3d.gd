# CameraFollow3D.gd
extends Camera3D

# === Assign in Inspector ===
@export var target: Node3D

# === Tuning ===
@export var distance: float = 4# smaller = closer
@export var follow_height: float = 4    # vertical lift
@export var horizontal_offset: float =9# strafe left/right

# Offset space:
# - use_initial_camera_axes: lock offset to how this camera was oriented at _ready()
# - follow_in_target_space: (legacy) rotate offset with player facing
# - otherwise: use camera's current axes
@export var use_initial_camera_axes: bool = true
@export var follow_in_target_space: bool = false

# === Smoothing ===
@export var smooth_motion: bool = true
@export var move_lerp_speed: float = 10.0
@export var look_lerp_speed: float = 14.0

var _anchor_basis: Basis  # camera's axes captured at _ready()

func _ready() -> void:
	_anchor_basis = global_transform.basis

func _physics_process(delta: float) -> void:
	if target == null:
		push_warning("CameraFollow3D: assign a 'target' (drag your character Node3D into the Inspector).")
		return

	# 1) Choose axes for offset (this controls whether the camera 'orbits' on player turn)
	var forward: Vector3
	var right: Vector3
	if use_initial_camera_axes:
		forward = -_anchor_basis.z     # fixed world-ish forward from camera start
		right   =  _anchor_basis.x
	elif follow_in_target_space:
		forward = -target.global_transform.basis.z
		right   =  target.global_transform.basis.x
	else:
		forward = -global_transform.basis.z
		right   =  global_transform.basis.x

	# 2) Desired position: behind + up + horizontal slide
	var desired_pos := target.global_transform.origin
	desired_pos += forward * distance
	desired_pos.y += follow_height
	desired_pos += right * horizontal_offset

	# 3) Move (smoothed or snap)
	if smooth_motion:
		var t := 1.0 - exp(-move_lerp_speed * delta)
		global_transform.origin = global_transform.origin.lerp(desired_pos, t)
	else:
		global_transform.origin = desired_pos

	# 4) Keep the player centered: always face the target
	var desired_basis := Transform3D().looking_at(
		target.global_transform.origin - global_transform.origin,
		Vector3.UP
	).basis

	if smooth_motion:
		var r := 1.0 - exp(-look_lerp_speed * delta)
		global_transform.basis = global_transform.basis.slerp(desired_basis, r)
	else:
		global_transform.basis = desired_basis
