extends Node3D

@export var move_speed: float = 0.02     # movement units per frame
@export var turn_speed: float = 3    # higher = snappier turn
@export var yaw_offset_deg: float = 15  # fix if mesh isn’t aligned
@export var face_node_path: NodePath     # drag your Heart node here

@onready var face_node: Node3D = get_node_or_null(face_node_path)

func _physics_process(delta: float) -> void:
	var dir = Vector3(
		Input.get_axis("ui_right", "ui_left"),
		0.0,
		-Input.get_axis("ui_up", "ui_down")
	)

	if dir.length() < 0.001:
		return
	dir = dir.normalized()

	# --- Move the parent pivot ---
	global_position += dir * move_speed

	# --- Smooth rotation toward movement direction ---
	var forward = dir.normalized()
	var target_basis = Basis.looking_at(forward, Vector3.UP)
	target_basis = Basis(Vector3.UP, deg_to_rad(-90.0)) * target_basis


	var rotator: Node3D = face_node if face_node else self
	rotator.basis = rotator.basis.slerp(target_basis, clamp(turn_speed * delta, 0.0, 1.0))
