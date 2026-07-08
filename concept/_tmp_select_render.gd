extends Node3D

# =============================================================
#  THROWAWAY (concept lane) - render the three GAME-READY GLBs as clean
#  CHARACTER-SELECT portraits. Zero generation credits: the select-screen
#  art IS the in-game object, so it can never drift from the locked look.
#  Renders a turntable (6 yaws) per character on a TRANSPARENT bg, full-body,
#  bright chibi-toon studio light. Aviv picks the hero angle per character;
#  the picks get saved into the repo as the final select assets. Delete freely.
#  Run headless:  Godot --headless --path <repo> concept/_tmp_select_render.tscn --quit-after 240
# =============================================================

const MODELS := [
	{"key": "FANG",  "glb": "res://concept/characters/fang/FANG_chibi_3d_v1.glb",        "tint": Color(1.0, 0.62, 0.28)},
	{"key": "ZERO",  "glb": "res://concept/characters/zero/ZERO_chibi_3d_v2_rigged.glb", "tint": Color(0.45, 0.72, 1.0)},
	{"key": "ATLAS", "glb": "res://concept/characters/atlas/ATLAS_chibi_3d_v1_rigged.glb","tint": Color(0.55, 0.9, 0.55)},
]
const OUT_DIR := "C:/Users/Aviv/AppData/Local/Temp/claude/c--Users-Aviv-OneDrive-Desktop-AvivUIUX/e1706252-dc35-46ab-aeaa-8f93279c1b63/scratchpad/select_portraits"
const YAWS := [300]   # hero angle locked by Aviv (3/4-front). Turntable pass done; finals only.

func _ready() -> void:
	# Transparent viewport so portraits are clean cutouts for card compositing.
	get_viewport().transparent_bg = true
	# Anti-aliasing + high-quality edges for the FINAL select cards (proof pass was jaggy).
	get_viewport().msaa_3d = Viewport.MSAA_8X
	get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA

	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.7, 0.74, 0.85)
	env.ambient_light_energy = 1.0
	we.environment = env
	add_child(we)

	# Bright soft key + fill + rim = the glossy chibi-toon finish reads.
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-42.0, -30.0, 0.0)
	key.light_energy = 1.5
	add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-14.0, 120.0, 0.0)
	fill.light_energy = 0.55
	add_child(fill)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-8.0, 200.0, 0.0)
	rim.light_energy = 0.8
	add_child(rim)

	# Portrait camera: slight hero 3/4 elevation, full-body frame.
	var cam := Camera3D.new()
	cam.fov = 32.0
	add_child(cam)
	cam.look_at_from_position(Vector3(0.0, 1.15, 4.6), Vector3(0.0, 1.0, 0.0), Vector3.UP)

	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	_run.call_deferred()

func _run() -> void:
	for m in MODELS:
		var packed: PackedScene = load(m["glb"])
		if packed == null:
			push_error("GLB failed to load: " + str(m["glb"]))
			continue
		var model: Node3D = packed.instantiate()
		add_child(model)
		# Frame: feet at y=0, ~2 units tall, centered.
		var aabb := _combined_aabb(model)
		var h: float = maxf(aabb.size.y, 0.001)
		var s := 2.0 / h
		model.scale = Vector3(s, s, s)
		var c := aabb.position + aabb.size * 0.5
		model.position = Vector3(-c.x * s, -aabb.position.y * s, -c.z * s)
		for y in YAWS:
			model.rotation.y = deg_to_rad(float(y))
			await get_tree().process_frame
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			var img := get_viewport().get_texture().get_image()
			img.save_png("%s/%s_yaw%03d.png" % [OUT_DIR, m["key"], int(y)])
			print("saved ", m["key"], " yaw ", y)
		remove_child(model)
		model.queue_free()
	print("DONE select portraits -> ", OUT_DIR)
	get_tree().quit()

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
