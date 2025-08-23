extends MeshInstance3D
@export var start_delay: float = 3.0
@export var pitch_speed: float = 20.0       # speed toward the plate
@export var hit_speed: float   = 15.0       # speed after being "hit" back
@export var friction: float    = 0.0        # linear drag (units/sec)
@export var lock_y: bool       = true       # keep constant height
@export var rotate_x_90: bool  = true       # rotate 90° on X at start

# Throw direction (default: world -Z like mound -> plate)
@export var pitch_direction: Vector3 = Vector3(0, 0, -1)

# Reverse when crossing this Z (>= triggers the hit in your logic below)
@export var hit_trigger_z: float = 1.5

# Letters live here (optional). If empty, we’ll use this node’s direct children.
@export var letters_container: NodePath = NodePath("")

# --- Wave / snake animation settings (per-letter) ---
@export var wave_cycle: float = 1.2         # seconds for a full wave
@export var wave_amp_y: float = 0.34        # vertical bob amplitude (meters)
@export var wave_amp_x: float = 0.12       # sideways sway amplitude (meters)
@export var scale_amp: float  = 0.20       # +/-10% scale pulse
@export var phase_gap: float  = 0.50       # seconds between letters (D->A->N->G)
@export var roll_amp_deg: float = 8.0       # small tilt per letter (coaster bank)

var velocity: Vector3 = Vector3.ZERO
var _reversed_once: bool = false
var _start_y: float = 0.0

# wave caches
var _letters: Array[Node3D] = []
var _base_pos: Array[Vector3] = []
var _base_scale: Array[Vector3] = []
var _base_rot_z: Array[float] = []
var _wave_t: float = 0.0

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	_start_y = global_position.y
	start_pitch()
func _on_body_entered(body):
	if body.name == "WordMesh":
		var bat = get_node("../Heart/Bat/AnimationPlayer")
		$Area3D.set_collision_mask_value(1, false)
		bat.play("Swing")
		body.reverse_direction()  # Assumes WordMesh has this function



func start_pitch() -> void:
	# NOTE: you had "-pitch_direction" here; keeping it as you wrote,
	# but if your throw heads the wrong way, set "var dir := pitch_direction" instead.
	var dir := -pitch_direction
	dir.y = 0.0
	if dir.length() <= 0.0001:
		dir = Vector3(0, 0, -1)
	velocity = dir.normalized() * pitch_speed

func _physics_process(delta: float) -> void:
	# simple linear drag (optional)
	if friction > 0.0 and velocity.length() > 0.0:
		var v: float = max(velocity.length() - friction * delta, 0.0)
		velocity = velocity.normalized() * v if v > 0.0 else Vector3.ZERO

	# move the whole word (Node3D has no built-in mover)
	global_position += velocity * delta

	if lock_y:
		global_position.y = _start_y

	# reverse once when we pass the trigger plane
	if not _reversed_once and global_position.z >= hit_trigger_z:
		rotate_y(deg_to_rad(180))
		reverse_direction()
		_reversed_once = true

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
			_base_pos.append(n3.transform.origin)         # local pos
			_base_scale.append(n3.scale)                  # local scale
			_base_rot_z.append(n3.rotation.z)             # local Z-rot (bank)

# A tiny squash on impact (call from reverse_direction if you want)
func _pop_letters() -> void:
	for i in _letters.size():
		var k := _letters[i]
		k.scale = _base_scale[i] * 1.1

# Animate letters with a traveling wave / rollercoaster feel
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

		# phase offset per letter so the wave travels across D->A->N->G
		var phase := ((_wave_t - float(i) * phase_gap) / wave_cycle) * two_pi

		# position offsets
		var dy := sin(phase) * wave_amp_y
		var dx := cos(phase) * wave_amp_x
		L.transform.origin = base_p + Vector3(dx, dy, 0.0)

		# scale pulse (symmetric xyz)
		var s := 1.0 + sin(phase) * scale_amp
		L.scale = base_s * s

		# small banking roll for coaster feel
		var tilt := deg_to_rad(sin(phase) * roll_amp_deg)
		L.rotation.z = base_rz + tilt
