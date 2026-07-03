extends Node3D

# =============================================================
#  THROWAWAY (concept lane, 2026-07-03) - ZERO 3D asymmetry audit.
#  Loads ZERO_hero_3d_v1.glb, renders 8 full-body angles + 4 face
#  closeups to PNG, then quits. Output goes OUTSIDE the repo
#  (scratchpad) - nothing here is a game asset. Delete freely.
# =============================================================

const GLB := "res://concept/characters/zero/ZERO_chibi_3d_v1.glb"
const OUT_DIR := "C:/Users/Aviv/AppData/Local/Temp/claude/c--Users-Aviv-OneDrive-Desktop-AvivUIUX/92f9f530-def2-4537-bda8-e081b3fc53ed/scratchpad/zero_chibi"

var _model: Node3D
var _cam: Camera3D
var _center := Vector3.ZERO
var _height := 2.0

func _ready() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.82, 0.82, 0.84)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1, 1, 1)
	env.ambient_light_energy = 1.1
	we.environment = env
	add_child(we)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-45.0, -30.0, 0.0)
	key.light_energy = 1.1
	add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25.0, 150.0, 0.0)
	fill.light_energy = 0.6
	add_child(fill)

	var packed: PackedScene = load(GLB)
	if packed == null:
		push_error("GLB not imported yet: " + GLB)
		get_tree().quit(1)
		return
	_model = packed.instantiate()
	add_child(_model)

	var aabb := _combined_aabb(_model)
	var h: float = maxf(aabb.size.y, 0.001)
	var s := 2.0 / h
	_model.scale = Vector3(s, s, s)
	var c := aabb.position + aabb.size * 0.5
	_model.position = Vector3(-c.x * s, -aabb.position.y * s, -c.z * s)
	_height = 2.0
	_center = Vector3(0.0, 1.0, 0.0)

	_cam = Camera3D.new()
	_cam.fov = 35.0
	add_child(_cam)

	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	_run_captures.call_deferred()

func _run_captures() -> void:
	# 8 full-body angles, straight-on camera at chest height.
	for i in range(8):
		var yaw := deg_to_rad(45.0 * i)
		_model.rotation.y = yaw
		_cam.look_at_from_position(Vector3(0.0, 1.05, 3.6), _center, Vector3.UP)
		await _snap("%s/body_%03d.png" % [OUT_DIR, int(45.0 * i)])
	# 4 face closeups.
	for i in range(4):
		var yaw := deg_to_rad(90.0 * i)
		_model.rotation.y = yaw
		_cam.look_at_from_position(Vector3(0.0, 1.78, 1.1), Vector3(0.0, 1.72, 0.0), Vector3.UP)
		await _snap("%s/face_%03d.png" % [OUT_DIR, int(90.0 * i)])
	get_tree().quit(0)

func _snap(path: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(path)

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
