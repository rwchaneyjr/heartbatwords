extends Node3D

@export var target: Node3D  # Drag your target/empty cube here
@export var speed: float = 15.0
@export var start_position: Node3D  # Optional: starting point

var is_moving: bool = true
var returning: bool = false

func _ready():
	# Store starting position if not set
	if not start_position:
		start_position = Node3D.new()
		get_parent().add_child(start_position)
		start_position.global_position = global_position
	
	# Connect collision signals from the Area3D
	var area = get_node_or_null("Area3D")
	if area:
		area.body_entered.connect(_on_hit)
		area.area_entered.connect(_on_hit)

func _physics_process(delta):
	if not is_moving:
		return
	
	# Choose which position to move toward
	var goal = target.global_position if not returning else start_position.global_position
	
	# Move toward the goal
	global_position = global_position.move_toward(goal, speed * delta)

func _on_hit(body):
	# Check if it's the bat that hit us
	print("Hit! Now returning: ", !returning)
	returning = !returning
