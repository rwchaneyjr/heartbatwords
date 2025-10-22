@tool
extends Node3D
# Scales self + children to a uniform factor AND resizes common CollisionShapes (Jolt prefers size edits vs node scale)

@export var uniform_scale: float = 0.3
@export var APPLY_NOW: bool = false:
	set(v):
		if v:
			_apply_scale(self)
			APPLY_NOW = false
			print("✓ Applied uniform scale ", uniform_scale, " to ", name)

func _apply_scale(n: Node) -> void:
	# Meshes/Node3Ds: set transform scale
	if n is Node3D and not (n is CollisionShape3D):
		(n as Node3D).scale = Vector3.ONE * uniform_scale

	# Collision shapes: resize the SHAPE (better for Jolt) rather than node transform
	if n is CollisionShape3D and (n as CollisionShape3D).shape:
		var cs := n as CollisionShape3D
		match cs.shape:
			BoxShape3D:
				cs.shape.size *= uniform_scale
			SphereShape3D:
				cs.shape.radius *= uniform_scale
			CapsuleShape3D:
				cs.shape.radius *= uniform_scale
				cs.shape.height *= uniform_scale
			CylinderShape3D:
				cs.shape.radius *= uniform_scale
				cs.shape.height *= uniform_scale
			_:
				# Fallback: scale the node if shape type isn't directly resizable
				(n as Node3D).scale = Vector3.ONE * uniform_scale

	for c in n.get_children():
		_apply_scale(c)
