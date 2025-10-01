extends RigidBody3D

@export var bat_node: NodePath
@export var speed: float = 5.0

var bat: Node3D

func _ready() -> void:
	gravity_scale = 0.0      # don’t fall
	sleeping = false         # don’t freeze
	if bat_node != NodePath(""):
		bat = get_node(bat_node)

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if bat == null:
		return
	# chase the bat every physics tick
	var dir: Vector3 = (bat.global_transform.origin - global_transform.origin).normalized()
	linear_velocity = dir * speed
