extends MeshInstance3D# WordHoming_RB.gd

@export var bat_node: NodePath
@export var speed: float = 6.0
@export var turn_speed: float = 5.0
@export var hit_recoil_time: float = 0.35
@export var recoil_speed_multiplier: float = 1.25

var _bat: Node
var _state := "seek"
var _recoil_timer := 0.0
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	_bat = get_node_or_null(bat_node)
	if has_node("Hitbox"):
		$Hitbox.body_entered.connect(_on_hitbox_body_entered)

func _physics_process(delta: float) -> void:
	if not _bat: return

	match _state:
		"seek":
			var to_bat: Vector3 = (_bat.global_transform.origin - global_transform.origin)
			if to_bat.length() > 0.001:
				var desired := to_bat.normalized() * speed
				var t: float = min(1.0, max(0.0, turn_speed * delta))
				linear_velocity = linear_velocity.lerp(desired, t)
		"recoil":
			_recoil_timer -= delta
			if _recoil_timer <= 0.0:
				_state = "seek"

func _on_hitbox_body_entered(body: Node) -> void:
	if body == _bat:
		var away: Vector3 = (global_transform.origin - _bat.global_transform.origin).normalized()
		away = away.rotated(Vector3.UP, _rng.randf_range(-0.6, 0.6))
		linear_velocity = away * speed * recoil_speed_multiplier
		_state = "recoil"
		_recoil_timer = hit_recoil_time
