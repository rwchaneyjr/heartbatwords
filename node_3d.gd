extends Node3D

@export var start_delay: float = 3.0
@export var pitch_speed: float = 20.0
@export var hit_speed: float   = 15.0
@export var friction: float    = 0.0
@export var lock_y: bool       = true
@export var rotate_x_90: bool  = true

@export var pitch_direction: Vector3 = Vector3(0, 0, -1)
@export var hit_trigger_z: float = 1.5
@export var letters_container: NodePath = NodePath("")

@export var wave_cycle: float = 1.2
@export var wave_amp_y: float = 0.34
@export var wave_amp_x: float = 0.12
@export var scale_amp: float  = 0.20
@export var phase_gap: float  = 0.50
@export var roll_amp_deg: float = 8.0

var velocity: Vector3 = Vector3.ZERO
var _reversed_once := false
var _start_y := 0.0
var _prev_z := 0.0  # <-- track last z to detect crossing

# wave caches
var _letters: Array[Node3D] = []
var _base_pos: Array[Vector3] = []
var _base_scale: Array[Vector3] = []
var _base_rot_z: Array[float] = []
var _wave_t := 0.0

func _ready() -> void:
	#if rotate_x_90:
		#rotate_x(deg_to_rad(90))

	_start_y = global_position.y
	_prev_z = global_position.z
	_gather_letters()

	await get_tree().create_timer(start_delay).timeout
	start_pitch()

func start_pitch() -> void:
	# Throw *along* the chosen direction (not negated)
	var dir := -pitch_direction
	dir.y = 0.0
	if dir.length() <= 0.0001:
		dir = Vector3(0, 0, -1)
	velocity = dir.normalized() * pitch_speed

func _physics_process(delta: float) -> void:
	# simple linear drag (optional)
	if friction > 0.0 and velocity.length() > 0.0:
		var v: float = max(velocity.length() - friction * delta, 0.0)
		velocity = (velocity.normalized() * v) if v > 0.0 else Vector3.ZERO

	# move the whole word
	global_position += velocity * delta

	if lock_y:
		global_position.y = _start_y

	# reverse once when we CROSS the trigger plane from below to >=
	if _prev_z < hit_trigger_z and global_position.z >= hit_trigger_z:
		reverse_direction()

	_prev_z = global_position.z

	# update the per-letter wave
	_apply_wave(delta)

func reverse_direction() -> void:
	# face the opposite way (visual)
	rotate_y(PI)

	# flip travel direction; keep it horizontal
	var back := -velocity.normalized()
	back.y = 0.0
	velocity = back.normalized() * hit_speed

# --- helpers ---------------------------------------------------------------

func _gather_letters() -> void:
	_letters.clear()
	_base_pos.clear()
	_base_scale.clear()
	_base_rot_z.clear()

	var holder: Node = self
	if letters_container != NodePath(""):
		var n := get_node_or_null(letters_container)
		if n:
			holder = n

	for c in holder.get_children():
		if c is Node3D:
			var n3 := c as Node3D
			_letters.append(n3)
			_base_pos.append(n3.transform.origin)
			_base_scale.append(n3.scale)
			_base_rot_z.append(n3.rotation.z)

func _pop_letters() -> void:
	for i in _letters.size():
		var k := _letters[i]
		k.scale = _base_scale[i] * 1.1

func _apply_wave(delta: float) -> void:
	if _letters.is_empty():
		return

	_wave_t = fmod(_wave_t + delta, wave_cycle)
	var two_pi := TAU

	for i in _letters.size():
		var L := _letters[i]
		var base_p := _base_pos[i]
		var base_s := _base_scale[i]
		var base_rz := _base_rot_z[i]

		var phase := ((_wave_t - float(i) * phase_gap) / wave_cycle) * two_pi

		var dy := sin(phase) * wave_amp_y
		var dx := cos(phase) * wave_amp_x
		L.transform.origin = base_p + Vector3(dx, dy, 0.0)

		var s := 1.0 + sin(phase) * scale_amp
		L.scale = base_s * s

		var tilt := deg_to_rad(sin(phase) * roll_amp_deg)
		L.rotation.z = base_rz + tilt
