extends Node3D

@export var target: Node3D
@export var speed: float = 19.0
@export var start_position: Node3D

var returning: bool = false
var is_moving: bool = true
@onready var area: Area3D = $Area3D

var _can_flip: bool = true

func _ready() -> void:
	if start_position == null:
		start_position = Node3D.new()
		get_parent().add_child(start_position)
		start_position.global_transform = global_transform
	
	if area:
		area.body_entered.connect(_on_any_enter)
		area.area_entered.connect(_on_any_enter)
		area.body_exited.connect(_on_any_exit)
		area.area_exited.connect(_on_any_exit)
	else:
		push_warning("No Area3D child found under the word node.")

func _physics_process(delta: float) -> void:
	if not is_moving:
		return
	
	# Normal movement between start and target
	var goal_node: Node3D = start_position if returning else target
	if goal_node == null:
		return
	
	var goal: Vector3 = goal_node.global_position
	global_position = global_position.move_toward(goal, speed * delta)

func _on_any_enter(collider) -> void:
	if _can_flip:
		# Simply reverse direction
		returning = not returning
		_can_flip = false

func _on_any_exit(_x) -> void:
	_can_flip = true

func _exit_tree() -> void:
	if start_position and start_position.get_parent() == get_parent():
		start_position.queue_free()
