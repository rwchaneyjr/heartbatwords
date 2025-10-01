extends Node3D

# Export the bat target so you can set it in the inspector
@export var bat: Node3D
@export var speed: float = 10.0

# Movement direction (will be calculated based on bat position)
var direction: Vector3 = Vector3.ZERO
var is_moving: bool = true

func _ready():
	if bat:
		# Calculate initial direction toward the bat
		direction = (bat.global_position - global_position).normalized()

func _physics_process(delta):
	if not is_moving:
		return
	
	# Move the sword in the current direction
	global_position += direction * speed * delta

func _on_area_3d_body_entered(body):
	# Reverse direction when hitting something
	direction = -direction
	print("Hit something! Reversing direction")

# Alternative: If using Area3D collision
func _on_area_3d_area_entered(area):
	# Reverse direction when hitting something
	direction = -direction
	print("Hit something! Reversing direction")
