# CameraFollow3D.gd
extends Camera3D

# === Assign this in the Inspector by dragging your player Node3D here ===
@export var target: Node3D

# === Tuning ===
@export var distance: float = 7           # smaller = closer to player
@export var follow_height: float = .8    # vertical lift
@export var horizontal_offset: float =  8# strafe left/right relative to player

# Follow relative to the player's facing and not the camera's
@export var follow_in_target_space: bool = true

# === Smoothing ===
@export var smooth_motion: bool = true
@export var move_lerp_speed: float = 10.0
@export var look_lerp_speed: float = 14.0

func _physics_process(delta: float) -> void:
	if target == null:
		push_warning("CameraFollow3D: assign a 'target' (drag your character Node3D into the Inspector).")
		return

	# Axes to use for offsetting
	var forward: Vector3
	var right: Vector3
	if follow_in_target_space:
		forward = -target.global_transform.basis.z   # target forward
		right   =  target.global_transform.basis.x   # target right
	else:
		forward = -global_transform.basis.z          # camera forward (old behavior)
		right   =  global_transform.basis.x          # camera right

	# Desired camera position: behind + up + horizontal slide
	var desired_pos := target.global_transform.origin
	desired_pos += forward * distance
	desired_pos.y += follow_height
	desired_pos += right * horizontal_offset

	# Smooth move
	if smooth_motion:
		var t := 1.0 - exp(-move_lerp_speed * delta)
		global_transform.origin = global_transform.origin.lerp(desired_pos, t)
	else:
		global_transform.origin = desired_pos

	# Look at the target
	var desired_basis := Transform3D().looking_at(
		target.global_transform.origin - global_transform.origin,
		Vector3.UP
	).basis

	if smooth_motion:
		var r := 1.0 - exp(-look_lerp_speed * delta)
		global_transform.basis = global_transform.basis.slerp(desired_basis, r)
	else:
		global_transform.basis = desired_basis
