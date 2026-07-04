extends Node3D

# =============================================================
#  THROWAWAY (concept lane) - see FANG_chibi_3d_v1 in the ARENA at
#  game scale + game camera, to confirm the locked chibi look reads
#  well in motion (not just a studio turntable). Modeled on the
#  mechanics lane's scripts/threed_test.gd (dark iso floor, iso-ish
#  cam) but concept-owned + points at the chibi GLB. NOT wired into
#  the game. Delete freely. Renders 8 arena angles to PNG on start,
#  then stays open so Aviv can rotate live (arrows / A-D) and judge.
# =============================================================

const GLB := "res://concept/characters/fang/FANG_chibi_3d_v1.glb"
const OUT_DIR := "C:/Users/Aviv/AppData/Local/Temp/claude/c--Users-Aviv-OneDrive-Desktop-AvivUIUX/92f9f530-def2-4537-bda8-e081b3fc53ed/scratchpad/fang_arena"
const TURN := 2.4
const AUTO := 0.5

var _model: Node3D
var _yaw := 0.0
var _auto := true
var _did_captures := false

func _ready() -> void:
	# Dark arena environment (matches game.gd floor RGB).
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.15, 0.17, 0.22)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.6, 0.72)
	env.ambient_light_energy = 0.8
	we.environment = env
	add_child(we)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-52.0, -38.0, 0.0)
	key.light_energy = 1.35
	add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20.0, 140.0, 0.0)
	fill.light_energy = 0.4
	add_child(fill)

	# Arena floor - dark, with a faint grid so scale/motion reads.
	var floor_mesh := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(12.0, 12.0)
	floor_mesh.mesh = pm
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.15, 0.17, 0.22)
	floor_mesh.material_override = fmat
	add_child(floor_mesh)

	# Iso-ish game camera (above + back, looking down at mid-body).
	var cam := Camera3D.new()
	cam.fov = 40.0
	add_child(cam)
	cam.look_at_from_position(Vector3(0.0, 2.6, 4.2), Vector3(0.0, 1.0, 0.0), Vector3.UP)

	var ci := CanvasLayer.new()
	var info := Label.new()
	info.position = Vector2(16.0, 12.0)
	info.text = "FANG chibi in arena  ·  Left/Right or A/D = rotate  ·  Space = auto-spin  ·  Esc = quit"
	ci.add_child(info)
	add_child(ci)

	_load_model()
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	_run_captures.call_deferred()

func _load_model() -> void:
	var packed: PackedScene = load(GLB)
	if packed == null:
		push_error("GLB failed to load: " + GLB)
		return
	_model = packed.instantiate()
	add_child(_model)
	# Frame so feet at y=0 and a readable arena height (~2 units).
	var aabb := _combined_aabb(_model)
	var h: float = maxf(aabb.size.y, 0.001)
	var s := 2.0 / h
	_model.scale = Vector3(s, s, s)
	var c := aabb.position + aabb.size * 0.5
	_model.position = Vector3(-c.x * s, -aabb.position.y * s, -c.z * s)
	_model.rotation.y = _yaw

func _run_captures() -> void:
	for i in range(8):
		_model.rotation.y = deg_to_rad(45.0 * i)
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		img.save_png("%s/arena_%03d.png" % [OUT_DIR, int(45.0 * i)])
	_model.rotation.y = _yaw
	_did_captures = true

func _process(delta: float) -> void:
	if not _did_captures or _model == null:
		return
	var turn := 0.0
	if Input.is_physical_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_A):
		turn -= 1.0
	if Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_physical_key_pressed(KEY_D):
		turn += 1.0
	if turn != 0.0:
		_auto = false
		_yaw += turn * TURN * delta
	elif _auto:
		_yaw += AUTO * delta
	_model.rotation.y = _yaw
	if Input.is_physical_key_pressed(KEY_ESCAPE):
		get_tree().quit()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		_auto = not _auto

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
