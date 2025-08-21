extends Node3D

@export var start_delay: float = 3.0
@export var pitch_speed: float = 20.0       # speed toward the plate
@export var hit_speed: float   = 15.0       # speed after being "hit" back
@export var friction: float    = 0.0        # linear drag (units/sec)
@export var lock_y: bool       = true       # keep constant height
@export var rotate_x_90: bool  = true       # rotate 90° on X at start

# Throw direction (default: world -Z like mound -> plate)
@export var pitch_direction: Vector3 = Vector3(0, 0, -1)

# Reverse when crossing this Z (<= triggers the hit)
@export var hit_trigger_z: float = 1.0

@export var letters_container: NodePath = NodePath("")  # optional holder of D/A/N/G

var velocity: Vector3 = Vector3.ZERO
var _reversed_once: bool = false
var _start_y: float = 0.0
var _letters: Array[Node3D] = []

func _ready() -> void:
	if rotate_x_90:
		rotate_x(deg_to_rad(90.0))

	_start_y = global_position.y
	_gather_letters()

	await get_tree().create_timer(start_delay).timeout
	start_pitch()

func start_pitch() -> void:
	var dir := -pitch_direction
	dir.y = 0.0
	if dir.length() <= 0.0001:
		dir = Vector3(0, 0, -1)
	velocity = dir.normalized() * pitch_speed

func _physics_process(delta: float) -> void:
	# apply simple linear drag (optional)
	if friction > 0.0 and velocity.length() > 0.0:
		var v: float = max(velocity.length() - friction * delta, 0.0)
		velocity = velocity.normalized() * v if v > 0.0 else Vector3.ZERO

	# *** THIS actually moves the Node3D ***
	global_position += velocity * delta

	if lock_y:
		global_position.y = _start_y

	# reverse once when we pass the trigger plane
	if not _reversed_once and global_position.z >= hit_trigger_z:
		reverse_direction()
		_reversed_once = true

func reverse_direction() -> void:
	# face the opposite way (visual)
	rotate_y(PI)
	# flip travel direction; keep it horizontal
	var back := -velocity.normalized()
	back.y = 0.0
	velocity = back.normalized() * hit_speed

# --- helpers (optional) ---
func _gather_letters() -> void:
	var holder: Node = self
	if letters_container != NodePath(""):
		var n := get_node_or_null(letters_container)
		if n:
			holder = n
	for c in holder.get_children():
		if c is Node3D:
			_letters.append(c)

func _pop_letters() -> void:
	for k in _letters:
		if k:
			k.scale = k.scale * 1.1
