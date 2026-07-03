extends Node3D

# =============================================================
#  THROWAWAY SLICE (DESIGN.md §In-arena view - 3D fork, 2026-07-03).
#  Riskiest-assumption-first feel test for the 3D pivot: does the TUNED
#  movement Aviv locked as "מעולה" survive in a 3D iso arena with the real
#  FANG model? Reuses the EXACT movement model from fighter.gd (same knobs,
#  same envelope) so the feel is identical - only the render is 3D.
#  Combat / bot / HP / procedural juice are OUT (next slice). Not wired
#  into the game; fully reversible.
# =============================================================

const GLB := "res://concept/characters/fang/FANG_hero_3d_v1.glb"

# --- movement knobs, copied verbatim from entities/fighter/fighter.gd (rusher) ---
const TURN_RATE := 4.3
const DRAG := 163.0
const WALK_SPEED := 150.0
const ACCEL := 2600.0
const BOOST_ATTACK_TIME := 1.08
const BOOST_ATTACK_SHARP := 0.7
const BOOST_OVERSHOOT := 0.07
const BOOST_OVERSHOOT_SETTLE := 0.22
const SPEED := 325.0                 # rusher top speed

# --- arena in SIM pixels (same units as the 2D game, so the feel matches) ---
const HALF := Vector2(560.0, 320.0)  # half-extents (px); arena = 1120 x 640
const WORLD_SCALE := 0.01            # 1 sim px = 0.01 world units -> arena ~11.2 x 6.4 units
const MODEL_H := 1.05                # model height in world units (~10% of arena width, like the game)

var _facing := Vector2.RIGHT
var _move_vel := Vector2.ZERO
var _pos := Vector2.ZERO
var _boost_t := 0.0
var _boosting_prev := false

var _player: Node3D
var _yaw_off := deg_to_rad(270.0)    # model front correction (Aviv-tuned: FANG_hero_3d_v1 faces -X)
var _info: Label

func _ready() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.10, 0.11, 0.15)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.6, 0.72)
	env.ambient_light_energy = 0.65
	we.environment = env
	add_child(we)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-55.0, -35.0, 0.0)
	key.light_energy = 1.3
	add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-18.0, 130.0, 0.0)
	fill.light_energy = 0.35
	add_child(fill)

	_build_floor()

	# Fixed iso camera framing the whole arena (Overwatch-ish tilt).
	var cam := Camera3D.new()
	cam.fov = 52.0
	add_child(cam)
	cam.look_at_from_position(Vector3(0.0, 10.5, 8.5), Vector3(0.0, 0.4, 0.0), Vector3.UP)

	_player = _spawn_fang()
	# a stationary FANG to navigate around (scale / speed reference)
	var dummy := _spawn_fang()
	dummy.position = Vector3(2.6, 0.0, -0.6)
	dummy.rotation.y = PI

	var ci := CanvasLayer.new()
	_info = Label.new()
	_info.position = Vector2(16.0, 12.0)
	ci.add_child(_info)
	add_child(ci)
	_refresh_info()

func _build_floor() -> void:
	var mesh := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(HALF.x * 2.0 * WORLD_SCALE, HALF.y * 2.0 * WORLD_SCALE)
	mesh.mesh = pm
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode unshaded;
uniform vec3 base_col : source_color = vec3(0.13, 0.15, 0.19);
uniform vec3 line_col : source_color = vec3(0.26, 0.31, 0.40);
uniform float cells = 14.0;
void fragment() {
	vec2 uv = UV * cells;
	vec2 g = abs(fract(uv - 0.5) - 0.5) / fwidth(uv);
	float line = min(g.x, g.y);
	float a = 1.0 - min(line, 1.0);
	ALBEDO = mix(base_col, line_col, a);
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mesh.material_override = mat
	add_child(mesh)

	# bright border frame so the bounds read
	var border := Color(0.40, 0.46, 0.56)
	var w := HALF.x * WORLD_SCALE
	var d := HALF.y * WORLD_SCALE
	for edge in [
		[Vector3(-w, 0.02, -d), Vector3(w, 0.02, -d)],
		[Vector3(-w, 0.02, d), Vector3(w, 0.02, d)],
		[Vector3(-w, 0.02, -d), Vector3(-w, 0.02, d)],
		[Vector3(w, 0.02, -d), Vector3(w, 0.02, d)],
	]:
		_add_line(edge[0], edge[1], border)

func _add_line(a: Vector3, b: Vector3, col: Color) -> void:
	var im := ImmediateMesh.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = col
	im.surface_begin(Mesh.PRIMITIVE_LINES, mat)
	im.surface_add_vertex(a)
	im.surface_add_vertex(b)
	im.surface_end()
	var mi := MeshInstance3D.new()
	mi.mesh = im
	add_child(mi)

func _spawn_fang() -> Node3D:
	var packed: PackedScene = load(GLB)
	if packed == null:
		push_error("GLB failed to load (needs import?): " + GLB)
		return Node3D.new()
	var m: Node3D = packed.instantiate()
	add_child(m)
	var aabb := _combined_aabb(m)
	var h: float = maxf(aabb.size.y, 0.001)
	var s := MODEL_H / h
	m.scale = Vector3(s, s, s)
	var c := aabb.position + aabb.size * 0.5
	# center horizontally, feet at y=0
	m.position = Vector3(-c.x * s, -aabb.position.y * s, -c.z * s)
	return m

func _process(delta: float) -> void:
	var in_dir := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_LEFT): in_dir.x -= 1.0
	if Input.is_physical_key_pressed(KEY_RIGHT): in_dir.x += 1.0
	if Input.is_physical_key_pressed(KEY_UP): in_dir.y -= 1.0
	if Input.is_physical_key_pressed(KEY_DOWN): in_dir.y += 1.0
	var booster := Input.is_physical_key_pressed(KEY_A)

	if in_dir != Vector2.ZERO:
		in_dir = in_dir.normalized()
		var diff := wrapf(in_dir.angle() - _facing.angle(), -PI, PI)
		_facing = _facing.rotated(clampf(diff, -TURN_RATE * delta, TURN_RATE * delta))

	if booster:
		if not _boosting_prev:
			_boost_t = _attack_time_for_speed(_move_vel.length())
		else:
			_boost_t += delta
		_boosting_prev = true
		_move_vel = _facing * _boost_speed(_boost_t)
	else:
		_boosting_prev = false
		_boost_t = 0.0
		var cur := _move_vel.length()
		if in_dir != Vector2.ZERO:
			var mag: float
			if cur > WALK_SPEED:
				mag = move_toward(cur, WALK_SPEED, DRAG * delta)
			else:
				mag = move_toward(cur, WALK_SPEED, ACCEL * delta)
			_move_vel = _facing * mag
		else:
			_move_vel = _facing * move_toward(cur, 0.0, DRAG * delta)

	_pos += _move_vel * delta
	_pos.x = clampf(_pos.x, -HALF.x, HALF.x)
	_pos.y = clampf(_pos.y, -HALF.y, HALF.y)

	if _player:
		_player.position = Vector3(_pos.x * WORLD_SCALE, 0.0, _pos.y * WORLD_SCALE)
		var fwd := Vector3(_facing.x, 0.0, _facing.y)
		_player.rotation.y = atan2(fwd.x, fwd.z) + _yaw_off

	_refresh_info()
	if Input.is_physical_key_pressed(KEY_ESCAPE):
		get_tree().quit()

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_BRACKETLEFT:
		_yaw_off -= deg_to_rad(15.0)
	elif event.keycode == KEY_BRACKETRIGHT:
		_yaw_off += deg_to_rad(15.0)

func _refresh_info() -> void:
	if not _info:
		return
	var spd := _move_vel.length()
	_info.text = "3D ARENA SLICE  ·  Arrows steer · A run · [ ] fix model front · Esc quit\nspeed %4.0f / %d  (%3.0f%%)   facing %4.0f°   yaw-fix %3.0f°\n(movement = exact game feel; combat + juice come next slice)" % [
		spd, int(SPEED), spd / SPEED * 100.0, rad_to_deg(_facing.angle()), rad_to_deg(_yaw_off)]

# --- envelope functions, copied verbatim from fighter.gd (Aviv's tuned curve) ---
func _boost_speed(t: float) -> float:
	var x := clampf(t / BOOST_ATTACK_TIME, 0.0, 1.0)
	var base := (1.0 - pow(1.0 - x, BOOST_ATTACK_SHARP)) * SPEED
	if BOOST_OVERSHOOT > 0.0 and t >= BOOST_ATTACK_TIME:
		var peak := SPEED * (1.0 + BOOST_OVERSHOOT)
		var dt := t - BOOST_ATTACK_TIME
		if dt < BOOST_OVERSHOOT_SETTLE:
			var k := dt / BOOST_OVERSHOOT_SETTLE
			return peak + (SPEED - peak) * (1.0 - pow(1.0 - k, 2.0))
		return SPEED
	return base

func _attack_time_for_speed(v: float) -> float:
	var frac := clampf(v / SPEED, 0.0, 0.999)
	var x := 1.0 - pow(1.0 - frac, 1.0 / BOOST_ATTACK_SHARP)
	return x * BOOST_ATTACK_TIME

func _combined_aabb(node: Node) -> AABB:
	var acc := AABB()
	var has := false
	for mi in _mesh_instances(node):
		var a: AABB = mi.get_global_transform() * mi.get_aabb()
		if not has:
			acc = a
			has = true
		else:
			acc = acc.merge(a)
	return acc if has else AABB(Vector3(-0.5, 0.0, -0.5), Vector3.ONE)

func _mesh_instances(node: Node) -> Array:
	var out: Array = []
	if node is MeshInstance3D:
		out.append(node)
	for child in node.get_children():
		out.append_array(_mesh_instances(child))
	return out
