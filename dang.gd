# WordFlip.gd — attach to each WORD root (Node3D)
# Expected hierarchy:
#   Word(Node3D) [this script]
#     ├─ (your visible letters/mesh)  <-- may be children or siblings
#     └─ Area3D
#         └─ CollisionShape3D  (Shape set, Disabled = Off)

extends Node3D

@export var target: Node3D           # drag your bat or a marker near the bat
@export var speed: float = 15.0
@export var start_position: Node3D   # optional; auto-captured if empty

# (Optional) if your visible letters live under some other parent, set this to that node.
@export var visual_root: Node3D      # if null, the script moves 'self'

# Set this true if your bat is an Area3D (not a PhysicsBody3D)
@export var bat_is_area: bool = false

var returning: bool = false          # false: go to target, true: go back to start
var is_moving: bool = true

@onready var area: Area3D = $Area3D

# debounce so one overlap triggers only one flip
var _can_flip := true

func _ready() -> void:
	if visual_root == null:
		visual_root = self

	# capture start if not provided
	if start_position == null:
		start_position = Node3D.new()
		get_parent().add_child(start_position)
		start_position.global_transform = visual_root.global_transform

	# connect exactly ONE enter signal depending on bat type (prevents double triggers)
	if not area:
		push_warning("No Area3D child found under the word node.")
		return

	if bat_is_area:
		area.area_entered.connect(_on_enter)
		area.area_exited.connect(_on_exit)
	else:
		area.body_entered.connect(_on_enter)
		area.body_exited.connect(_on_exit)

func _physics_process(delta: float) -> void:
	if not is_moving:
		return

	# choose the goal purely by position; no forward vector math
	var goal_node: Node3D = (start_position if returning else target)
	if goal_node == null:
		return

	visual_root.global_position = visual_root.global_position.move_toward(
		goal_node.global_position, speed * delta)

# --- collision handlers ---

func _on_enter(_other) -> void:
	if not _can_flip:
		return
	# flip direction once per overlap window
	returning = !returning
	_can_flip = false
	# print_debug("Flip → returning =", returning)

func _on_exit(_other) -> void:
	# re-arm after separation so next overlap can flip again
	_can_flip = true

func _exit_tree() -> void:
	# clean up auto-created start anchor
	if start_position and start_position.get_parent() == get_parent():
		start_position.queue_free()
