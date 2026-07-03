extends Node3D

# =============================================================
#  THROWAWAY SLICE (DESIGN.md §In-arena view - 3D fork, 2026-07-03).
#  Prove that a rotating 3D model reads well at arena scale on the dark
#  floor and KILLS the snap problem (a 3D model rotates continuously to
#  any heading). One FANG GLB, iso-ish camera, continuous Y-rotation by
#  input. NOT wired into the game - fully reversible. If Aviv likes it,
#  we plan the real 3D-in-2D integration; if not, we revert to sprites.
# =============================================================

# Two candidate 3D FANGs the concept lane produced (Tab cycles them).
const GLBS := [
	"res://concept/characters/fang/FANG_hero_3d_v1.glb",   # leveled-up hero design (default)
	"res://concept/characters/fang/FANG_3d_v2_tripo.glb",  # earlier tank-top version
]
const GLB_NAMES := ["FANG hero-v1", "FANG v2 (tank-top)"]
const TURN := 2.4          # rad/s manual rotation
const AUTO := 0.5          # gentle idle spin so smoothness reads even hands-off

var _model: Node3D
var _glb_idx := 0
var _yaw := 0.0
var _auto := true
var _info: Label

func _ready() -> void:
	# Dark arena-like environment (matches game.gd floor RGB).
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.15, 0.17, 0.22)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.6, 0.72)
	env.ambient_light_energy = 0.7
	we.environment = env
	add_child(we)

	# Key + subtle fill so the model reads regardless of its material.
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-52.0, -38.0, 0.0)
	key.light_energy = 1.35
	add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20.0, 140.0, 0.0)
	fill.light_energy = 0.4
	add_child(fill)

	# A simple ground plane so the iso read has a floor (like the arena).
	var floor_mesh := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(8.0, 8.0)
	floor_mesh.mesh = pm
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.15, 0.17, 0.22)
	floor_mesh.material_override = fmat
	add_child(floor_mesh)

	# Iso-ish camera: above + back, looking down at mid-body (Overwatch-ish).
	var cam := Camera3D.new()
	cam.fov = 40.0
	add_child(cam)
	cam.look_at_from_position(Vector3(0.0, 2.6, 4.2), Vector3(0.0, 1.0, 0.0), Vector3.UP)

	var ci := CanvasLayer.new()
	_info = Label.new()
	_info.position = Vector2(16.0, 12.0)
	ci.add_child(_info)
	add_child(ci)

	_load_model()

# (Re)load the current candidate GLB, framed to a fixed height with feet at y=0.
func _load_model() -> void:
	if _model:
		_model.queue_free()
		_model = null
	var path: String = GLBS[_glb_idx]
	var packed: PackedScene = load(path)
	if packed == null:
		push_error("GLB failed to load (needs import?): " + path)
		_show_error()
		return
	_model = packed.instantiate()
	add_child(_model)

	# Frame at identity (rotation 0) so the AABB is axis-aligned, THEN apply yaw.
	var aabb := _combined_aabb(_model)
	var h: float = maxf(aabb.size.y, 0.001)
	var target_h := 2.0
	var s := target_h / h
	_model.scale = Vector3(s, s, s)
	var c := aabb.position + aabb.size * 0.5
	_model.position = Vector3(-c.x * s, -aabb.position.y * s, -c.z * s)
	_model.rotation.y = _yaw
	_refresh_info()

func _refresh_info() -> void:
	if _info:
		_info.text = "3D SLICE  ·  %s   (Tab = swap model)\nLeft/Right (or A/D) = rotate  ·  Space = auto-spin  ·  Esc = quit" % GLB_NAMES[_glb_idx]

func _process(delta: float) -> void:
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
	if _model:
		_model.rotation.y = _yaw
	if Input.is_physical_key_pressed(KEY_ESCAPE):
		get_tree().quit()

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_SPACE:
		_auto = not _auto
	elif event.keycode == KEY_TAB:
		_glb_idx = (_glb_idx + 1) % GLBS.size()
		_load_model()

func _show_error() -> void:
	var ci := CanvasLayer.new()
	var l := Label.new()
	l.position = Vector2(16.0, 40.0)
	l.text = "GLB failed to load - run the editor once to import, then relaunch."
	ci.add_child(l)
	add_child(ci)

# Combined AABB over all MeshInstance3D descendants, in the model-root frame.
# Called while _model sits at identity (before we scale/move it), so each mesh's
# global transform equals its model-local transform.
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
