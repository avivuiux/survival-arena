extends Node3D

# =============================================================
#  GAME 3D - THE UNIFIED GAME, step 1 (DESIGN.md §unified-3D-game).
#  The main game flow (select -> fight the bot -> best-of-3 -> re-pick)
#  on the proven 3D stack: hidden REAL fighter.gd sim + game-shim +
#  render-only 3D layer (locked in arena3d_fight, "כיף - ננעל").
#  Rusher renders the FANG GLB; balanced/tank = colored greybox
#  capsules until their 3D models are locked by the concept lane.
#  The 2D game (game.tscn) stays untouched as fallback.
# =============================================================

const FighterScript := preload("res://entities/fighter/fighter.gd")
# chibi-plus (the locked look, concept lane 2026-07-03). *_hero_3d_v1 = old off-style fallbacks.
const FANG_GLB := "res://concept/characters/fang/FANG_chibi_3d_v1.glb"
const ZERO_GLB := "res://concept/characters/zero/ZERO_chibi_3d_v1.glb"

# --- sim space (same units as the 2D game, so the locked feel is identical) ---
const HALF := Vector2(560.0, 320.0)
const WORLD_SCALE := 0.01
const MODEL_H := 1.05
const MODEL_YAW_OFF := PI * 1.5       # FANG_hero_3d_v1 front correction (locked)

const P1_SPAWN := Vector2(-210.0, 0.0)
const P2_SPAWN := Vector2(210.0, 0.0)
const WINS_NEEDED := 2

# archetypes = game.gd's data (numbers untouched). glb = 3D model when one is locked.
const ARCHETYPES := {
	"balanced": {"hp": 170, "speed": 320.0, "damage": 12, "atk_cd": 0.34, "skill": "chill",
		"color": Color(0.35, 0.65, 0.95), "glb": ZERO_GLB, "yaw_off": PI * 1.5},
	"rusher":   {"hp": 120, "speed": 325.0, "damage": 18, "atk_cd": 0.26, "skill": "lunge",
		"color": Color(0.95, 0.55, 0.20), "glb": FANG_GLB, "yaw_off": PI * 1.5},
	"tank":     {"hp": 220, "speed": 240.0, "damage": 14, "atk_cd": 0.40, "skill": "shockwave",
		"color": Color(0.45, 0.85, 0.45)},
}

# projectiles (sim logic copied from game.gd - same numbers, same rules)
const PROJ_SPEED := 560.0
const PROJ_LIFE := 0.9
const PROJ_DAMAGE := 8
const PROJ_KNOCK := 260.0
const PROJ_RADIUS := 12.0

var _fighters: Array = []             # shim contract: fighter.gd + _bot_think read this
var _p1: Node2D
var _p2: Node2D
var _sim: Node2D
var _cam: Camera3D
var _shake := 0.0
var _slowmo := false
var _state := "select"                # "select" | "fighting" | "round_over"
var _p1_score := 0
var _p2_score := 0
var _sparks: Array = []               # {node, mat, base_col, vel: Vector3, life, max}
var _projectiles: Array = []          # sim px: {pos, vel, owner, life, node}
var _vis := {}                        # fighter -> visual dict
var _info: Label
var _banner: Label
var _score_label: Label
var _title_label: Label
var _select_label: Label
var _ip_edit: LineEdit             # online: host IP the guest connects to (two-machine test)
var _ip_label: Label
var _join_ip := "127.0.0.1"        # cmdline `++ join 192.168.x.x` overrides the field
var _hud: Control
var _view_snap := 0                   # F6: 0 = smooth rotation, 8 / 4 = directional views
var _arch_keys: Array = []
var _sel_index := 1                   # start on rusher (FANG has the locked model)

# --- ONLINE (step 2): net_fight's LOCKED server-authoritative core + lag injector ---
const PORT := 8910
const LAG_STEPS := [0, 30, 60, 100]   # one-way ms; round-trip = x2
const ANIM_IDLE := 0
const ANIM_WINDUP := 1
const ANIM_ATTACK := 2
const ANIM_BLOCK := 3
const ANIM_HIT := 4
const ANIM_PARRY := 5
const ANIM_LUNGE := 6
var _peer: ENetMultiplayerPeer
var _net_role := "none"               # "none" | "host" | "client"
var _my_arch := "rusher"
var _lag_ms := 0
var _lag_queue: Array = []            # FIFO: {at: msec, kind: String, args: Array}
var _prev_attack := false             # guest-side press edge detection
var _prev_skill := false
var _prev_ranged := false

class Hud extends Control:
	var game_ref
	func _draw() -> void:
		if game_ref:
			game_ref._draw_hud(self)

func _ready() -> void:
	_arch_keys = ARCHETYPES.keys()
	_build_stage()
	_build_ui()
	_sim = Node2D.new()
	_sim.visible = false
	add_child(_sim)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(func(_id): _net_teardown("PEER LEFT"))
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(func(): _net_teardown("CONNECTION FAILED"))
	multiplayer.server_disconnected.connect(func(): _net_teardown("HOST LEFT"))
	_refresh_select()
	# dev entries: `++ play rusher` = vs bot, `++ host rusher` / `++ join tank` = online,
	# `++ lag60` = preset delay (also used by headless tests)
	var ua := OS.get_cmdline_user_args()
	for a in ua:
		if ARCHETYPES.has(a):
			_sel_index = _arch_keys.find(a)
		elif a.begins_with("lag"):
			_set_lag(maxi(int(a.substr(3)), 0))
		elif a.count(".") == 3:
			_join_ip = a
	if _ip_edit:
		_ip_edit.text = _join_ip
	if ua.has("play"):
		_begin_match()
	elif ua.has("host"):
		_net_host()
	elif ua.has("join"):
		_net_join()

# ---------- stage (the locked arena3d look) ----------

func _build_stage() -> void:
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

	_cam = Camera3D.new()
	_cam.fov = 52.0
	add_child(_cam)
	_cam.look_at_from_position(Vector3(0.0, 10.5, 8.5), Vector3(0.0, 0.4, 0.0), Vector3.UP)

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

# ---------- UI ----------

func _build_ui() -> void:
	var ui := CanvasLayer.new()
	add_child(ui)
	var vp := get_viewport().get_visible_rect().size

	_hud = Hud.new()
	_hud.game_ref = self
	_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(_hud)

	_info = Label.new()
	_info.position = Vector2(16.0, 12.0)
	_info.visible = false
	ui.add_child(_info)

	_score_label = Label.new()
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score_label.add_theme_font_size_override("font_size", 22)
	_score_label.position = Vector2(vp.x / 2.0 - 200.0, 14.0)
	_score_label.size = Vector2(400.0, 30.0)
	_score_label.visible = false
	ui.add_child(_score_label)

	_banner = Label.new()
	_banner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner.add_theme_font_size_override("font_size", 52)
	_banner.visible = false
	ui.add_child(_banner)

	_title_label = Label.new()
	_title_label.text = "CHOOSE YOUR FIGHTER\n(A / D change  ·  SPACE vs bot  ·  H host  ·  J join at the IP below)"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 28)
	_title_label.position = Vector2(vp.x / 2.0 - 240.0, 100.0)
	_title_label.size = Vector2(480.0, 90.0)
	ui.add_child(_title_label)

	_select_label = Label.new()
	_select_label.add_theme_font_size_override("font_size", 20)
	_select_label.position = Vector2(vp.x / 2.0 - 240.0, 210.0)
	_select_label.size = Vector2(480.0, 200.0)
	ui.add_child(_select_label)

	# --- online host-IP entry (two-machine test): click to type, Enter or J joins ---
	_ip_label = Label.new()
	_ip_label.text = "Online host IP (127.0.0.1 = same machine · click box to type):"
	_ip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ip_label.add_theme_font_size_override("font_size", 15)
	_ip_label.position = Vector2(vp.x / 2.0 - 240.0, 430.0)
	_ip_label.size = Vector2(480.0, 24.0)
	ui.add_child(_ip_label)

	_ip_edit = LineEdit.new()
	_ip_edit.text = "127.0.0.1"
	_ip_edit.placeholder_text = "host IP"
	_ip_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ip_edit.focus_mode = Control.FOCUS_CLICK   # only a click focuses it (Tab stays re-pick)
	_ip_edit.position = Vector2(vp.x / 2.0 - 110.0, 458.0)
	_ip_edit.size = Vector2(220.0, 34.0)
	_ip_edit.text_submitted.connect(func(_t): _net_join())
	ui.add_child(_ip_edit)

func _show_ip(v: bool) -> void:
	if _ip_edit:
		_ip_edit.visible = v
	if _ip_label:
		_ip_label.visible = v

func _refresh_select() -> void:
	var t := ""
	for i in range(_arch_keys.size()):
		var k: String = _arch_keys[i]
		var a: Dictionary = ARCHETYPES[k]
		var marker := "> " if i == _sel_index else "    "
		var model := "3D model" if a.has("glb") else "greybox capsule"
		t += "%s%s   -   hp %d   spd %d   dmg %d   skill: %s   [%s]\n\n" % [
			marker, k.to_upper(), int(a["hp"]), int(a["speed"]), int(a["damage"]), a["skill"], model]
	if _select_label:
		_select_label.text = t

# ---------- match flow ----------

func _begin_match() -> void:
	var p1_arch: String = _arch_keys[_sel_index]
	var p2_arch: String = _arch_keys[randi() % _arch_keys.size()]

	_title_label.visible = false
	_select_label.visible = false
	_show_ip(false)
	_info.visible = true
	_score_label.visible = true

	_p1 = _make_fighter(p1_arch, "YOU", false, P1_SPAWN)
	_p2 = _make_fighter(p2_arch, "BOT", true, P2_SPAWN)
	_p2.facing = Vector2.LEFT
	_fighters = [_p1, _p2]
	_vis[_p1] = _make_visual(ARCHETYPES[p1_arch])
	_vis[_p2] = _make_visual(ARCHETYPES[p2_arch])

	_p1_score = 0
	_p2_score = 0
	_update_score()
	_state = "fighting"
	_refresh_info()

func _return_to_select() -> void:
	for f in _fighters:
		if _vis.has(f):
			var v: Dictionary = _vis[f]
			v["pivot"].queue_free()
			v["tel"].queue_free()
			v["cast"].queue_free()
		f.queue_free()
	_vis.clear()
	_fighters = []
	_p1 = null
	_p2 = null
	for p in _projectiles:
		p["node"].queue_free()
	_projectiles = []
	for sp in _sparks:
		sp["node"].queue_free()
	_sparks = []
	_banner.visible = false
	_info.visible = false
	_score_label.visible = false
	_title_label.visible = true
	_title_label.text = "CHOOSE YOUR FIGHTER\n(A / D change  ·  SPACE vs bot  ·  H host  ·  J join at the IP below)"
	_select_label.visible = true
	_show_ip(true)
	_state = "select"
	_refresh_select()

func _make_fighter(arch: String, fname: String, bot: bool, pos: Vector2) -> Node2D:
	var a: Dictionary = ARCHETYPES[arch]
	var f := FighterScript.new()
	f.game = self
	f.fighter_name = fname
	f.display_name = "%s (%s)" % [arch.to_upper(), fname]
	f.body_color = a["color"]
	f.max_hp = a["hp"]
	f.speed = a["speed"]
	f.damage = a["damage"]
	f.attack_cooldown = a["atk_cd"]
	f.skill_type = a["skill"]
	f.art_path = ""
	f.key_up = KEY_UP
	f.key_down = KEY_DOWN
	f.key_left = KEY_LEFT
	f.key_right = KEY_RIGHT
	f.key_attack = KEY_S
	f.key_dash = KEY_SHIFT
	f.key_skill = KEY_R
	f.key_ranged = KEY_D
	f.key_defense = KEY_SPACE
	f.key_booster = KEY_A
	f.is_bot = bot
	f.facing_snap = _view_snap
	f.position = pos
	_sim.add_child(f)
	return f

# ---------- 3D visuals ----------

func _make_visual(arch: Dictionary) -> Dictionary:
	var pivot := Node3D.new()      # yaw-aligned to facing: local +Z = forward
	add_child(pivot)
	var fix := Node3D.new()        # constant model-front correction
	pivot.add_child(fix)

	var meshes: Array = []
	if arch.has("glb"):
		var packed: PackedScene = load(arch["glb"])
		var model: Node3D
		if packed == null:
			push_error("GLB failed to load: " + str(arch["glb"]))
			model = Node3D.new()
		else:
			model = packed.instantiate()
		fix.add_child(model)
		var aabb := _combined_aabb(model)
		var s := MODEL_H / maxf(aabb.size.y, 0.001)
		model.scale = Vector3.ONE * s
		var cc := aabb.position + aabb.size * 0.5
		model.position = Vector3(-cc.x * s, -aabb.position.y * s, -cc.z * s)
		fix.rotation.y = arch.get("yaw_off", MODEL_YAW_OFF)
		meshes = _mesh_instances(model)
	else:
		# greybox 3D stand-in: a colored capsule at fighter scale
		var cap := MeshInstance3D.new()
		var cm := CapsuleMesh.new()
		cm.radius = 0.22
		cm.height = MODEL_H * 0.9
		cap.mesh = cm
		var cmat := StandardMaterial3D.new()
		cmat.albedo_color = arch["color"]
		cap.material_override = cmat
		cap.position = Vector3(0.0, MODEL_H * 0.45, 0.0)
		fix.add_child(cap)
		# a small nose so the capsule's facing reads
		var nose := MeshInstance3D.new()
		var nm := BoxMesh.new()
		nm.size = Vector3(0.10, 0.10, 0.16)
		nose.mesh = nm
		var nmat := StandardMaterial3D.new()
		nmat.albedo_color = arch["color"].lightened(0.4)
		nose.material_override = nmat
		nose.position = Vector3(0.0, MODEL_H * 0.62, 0.26)
		fix.add_child(nose)
		meshes = [cap, nose]

	# hit-flash / state overlay (ADD blend: black = no effect)
	var overlay := StandardMaterial3D.new()
	overlay.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	overlay.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	overlay.albedo_color = Color(0, 0, 0)
	for mi in meshes:
		mi.material_overlay = overlay

	# identity ring on the floor
	var ring := MeshInstance3D.new()
	var rm := CylinderMesh.new()
	rm.top_radius = 0.30
	rm.bottom_radius = 0.30
	rm.height = 0.01
	ring.mesh = rm
	var ring_mat := StandardMaterial3D.new()
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var rc: Color = arch["color"]
	ring_mat.albedo_color = Color(rc.r, rc.g, rc.b, 0.35)
	ring.material_override = ring_mat
	ring.position = Vector3(0.0, 0.015, 0.0)
	pivot.add_child(ring)

	# block shield plate in front (parry-window color)
	var shield := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(0.55, 0.55, 0.04)
	shield.mesh = sm
	var shield_mat := StandardMaterial3D.new()
	shield_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shield_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shield.material_override = shield_mat
	shield.position = Vector3(0.0, 0.5, 0.38)
	shield.visible = false
	pivot.add_child(shield)

	# attack telegraph: floor quad at the TRUE hitbox
	var tel := MeshInstance3D.new()
	var tm := PlaneMesh.new()
	tm.size = Vector2(48.0 * WORLD_SCALE, 48.0 * WORLD_SCALE)
	tel.mesh = tm
	var tel_mat := StandardMaterial3D.new()
	tel_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tel_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tel.material_override = tel_mat
	tel.position = Vector3(0.0, 0.025, 0.0)
	tel.visible = false
	add_child(tel)

	# skill cast ring (chill / shockwave) - expanding floor ring
	var cast := MeshInstance3D.new()
	var tor := TorusMesh.new()
	tor.inner_radius = 0.93
	tor.outer_radius = 1.0
	cast.mesh = tor
	var cast_mat := StandardMaterial3D.new()
	cast_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cast_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cast.material_override = cast_mat
	cast.position = Vector3(0.0, 0.03, 0.0)
	cast.visible = false
	add_child(cast)

	return {"pivot": pivot, "fix": fix, "meshes": meshes, "overlay": overlay,
		"ring": ring, "shield": shield, "shield_mat": shield_mat,
		"tel": tel, "tel_mat": tel_mat, "cast": cast, "cast_mat": cast_mat, "ko": 0.0}

# ---------- per-frame ----------

func _process(delta: float) -> void:
	_drain_lag_queue()
	if _shake > 0.05:
		_cam.h_offset = randf_range(-_shake, _shake) * 0.01
		_cam.v_offset = randf_range(-_shake, _shake) * 0.01
		_shake = move_toward(_shake, 0.0, 40.0 * delta)
	elif _cam.h_offset != 0.0 or _cam.v_offset != 0.0:
		_shake = 0.0
		_cam.h_offset = 0.0
		_cam.v_offset = 0.0

	if not _sparks.is_empty():
		for sp in _sparks:
			sp["life"] -= delta
			sp["vel"].y -= 6.0 * delta
			sp["node"].position += sp["vel"] * delta
			var a: float = clampf(sp["life"] / sp["max"], 0.0, 1.0)
			var bc: Color = sp["base_col"]
			sp["mat"].albedo_color = Color(bc.r, bc.g, bc.b, a)
		for sp in _sparks:
			if sp["life"] <= 0.0:
				sp["node"].queue_free()
		_sparks = _sparks.filter(func(sp): return sp["life"] > 0.0)

	# projectile sim = referee only (offline, or the online host). Guest nodes are
	# positioned straight from the host's state in _sync_guest_projectiles.
	if _net_role != "client" and not _projectiles.is_empty():
		for p in _projectiles:
			p["pos"] += p["vel"] * delta
			p["life"] -= delta
			p["node"].position = Vector3(p["pos"].x * WORLD_SCALE, 0.45, p["pos"].y * WORLD_SCALE)
			for f in _fighters:
				if f == p["owner"] or not f.active:
					continue
				if p["pos"].distance_to(f.position) < PROJ_RADIUS + 16.0:
					f.take_hit(p["vel"].normalized(), PROJ_DAMAGE, PROJ_KNOCK)
					spawn_sparks(p["pos"], p["vel"], 6, p["owner"].body_color)
					p["life"] = 0.0
					break
		for p in _projectiles:
			if p["life"] <= 0.0:
				p["node"].queue_free()
		_projectiles = _projectiles.filter(func(p): return p["life"] > 0.0)

	# online traffic (only once the match is live)
	if _p1 != null and multiplayer.multiplayer_peer != null and not multiplayer.get_peers().is_empty():
		if _net_role == "host":
			# broadcast the whole authoritative picture every frame
			_recv_state.rpc(_pack(_p1), _pack(_p2), _pack_projectiles())
		elif _net_role == "client":
			# read my keys, send INTENT to the referee
			var dir := Vector2.ZERO
			if Input.is_physical_key_pressed(KEY_UP): dir.y -= 1.0
			if Input.is_physical_key_pressed(KEY_DOWN): dir.y += 1.0
			if Input.is_physical_key_pressed(KEY_LEFT): dir.x -= 1.0
			if Input.is_physical_key_pressed(KEY_RIGHT): dir.x += 1.0
			var block := Input.is_physical_key_pressed(KEY_SPACE)
			var booster := Input.is_physical_key_pressed(KEY_A)
			_recv_held.rpc_id(1, dir, block, booster)
			var a := Input.is_physical_key_pressed(KEY_S)
			if a and not _prev_attack:
				_recv_press.rpc_id(1, "attack")
			_prev_attack = a
			var sk := Input.is_physical_key_pressed(KEY_R)
			if sk and not _prev_skill:
				_recv_press.rpc_id(1, "skill")
			_prev_skill = sk
			var rg := Input.is_physical_key_pressed(KEY_D)
			if rg and not _prev_ranged:
				_recv_press.rpc_id(1, "ranged")
			_prev_ranged = rg

	for f in _fighters:
		_update_visual(f, delta)
	if _state != "select":
		_hud.queue_redraw()

func _update_visual(f, delta: float) -> void:
	if not _vis.has(f):
		return
	var v: Dictionary = _vis[f]
	var pivot: Node3D = v["pivot"]
	pivot.position = Vector3(f.position.x * WORLD_SCALE, 0.0, f.position.y * WORLD_SCALE)
	# F6 directional-view mode (display only - sim/aim/hitboxes stay continuous)
	var face: Vector2 = f.facing
	if f.facing_snap > 0:
		face = f._view_facing()
	var yaw := atan2(face.x, face.y)

	# the locked 2D pose grammar as whole-model transforms
	var pitch := 0.0
	var scl := Vector3.ONE
	if f._winding:
		var we: float = 1.0 - clampf(f._windup_time / maxf(f.WINDUP_TIME, 0.001), 0.0, 1.0)
		pitch = -0.30 * we
		scl = Vector3(1.0, 1.0 + 0.10 * we, 1.0 - 0.14 * we)
	elif f._attacking:
		var ap: float = clampf(f._attack_time / f.ATTACK_ACTIVE, 0.0, 1.0)
		pitch = 0.38 * ap
		scl = Vector3(1.0, 1.0 - 0.12 * ap, 1.0 + f.POSE_ATTACK_STRETCH * ap)
	elif f._pose == "hit":
		var he: float = clampf(f._pose_time / f._pose_max, 0.0, 1.0)
		scl = Vector3(1.0 + 0.10 * he, 1.0 - f.POSE_HIT_SQUASH * he, 1.0 + 0.10 * he)
	elif f._pose == "parry":
		var pe: float = clampf(f._pose_time / f._pose_max, 0.0, 1.0)
		scl = Vector3.ONE * (1.0 + f.POSE_PARRY_POP * pe)
	elif f.active:
		var mspd: float = f._move_vel.length()
		var mk: float = clampf(mspd / maxf(f.speed, 1.0), 0.0, 1.15) * f.STRETCH_MAX
		if mk > 0.01:
			scl = Vector3(1.0 - mk * 0.35, 1.0 - mk * 0.45, 1.0 + mk)

	v["ko"] = move_toward(v["ko"], (PI * 0.5) if not f.active else 0.0, 5.0 * delta)
	pivot.rotation = Vector3(pitch - v["ko"], yaw, 0.0)
	pivot.scale = scl

	var oc := Color(0, 0, 0)
	if f._flash > 0.0:
		oc = Color(0.9, 0.9, 0.9)
	elif f._iframe > 0.0:
		oc = Color(0.05, 0.25, 0.45)
	elif f._chill_time > 0.0:
		oc = Color(0.05, 0.15, 0.40)
	v["overlay"].albedo_color = oc

	var shield: MeshInstance3D = v["shield"]
	shield.visible = f._blocking
	if f._blocking:
		if f._block_time <= f.PARRY_WINDOW:
			v["shield_mat"].albedo_color = Color(0.65, 0.95, 1.0, 0.75)
		else:
			v["shield_mat"].albedo_color = Color(0.40, 0.60, 0.90, 0.45)

	var tel: MeshInstance3D = v["tel"]
	if f._attacking or f._lunge:
		tel.visible = true
		var hp2: Vector2 = f.position + f.facing * f.REACH
		tel.position = Vector3(hp2.x * WORLD_SCALE, 0.025, hp2.y * WORLD_SCALE)
		if f._lunge:
			v["tel_mat"].albedo_color = Color(1.0, 0.5, 0.25, 0.55)
		else:
			var t: float = clampf(f._attack_time / f.ATTACK_ACTIVE, 0.0, 1.0)
			v["tel_mat"].albedo_color = Color(1.0, 0.95, 0.6, 0.20 + 0.45 * t)
	else:
		tel.visible = false

	# skill cast ring (chill / shockwave read)
	var cast: MeshInstance3D = v["cast"]
	if f._cast_anim > 0.0:
		cast.visible = true
		var cp: float = 1.0 - (f._cast_anim / f.CHILL_CAST_ANIM)
		var cr: float = maxf(f._cast_radius * cp * WORLD_SCALE, 0.02)
		cast.position = Vector3(f.position.x * WORLD_SCALE, 0.03, f.position.y * WORLD_SCALE)
		cast.scale = Vector3(cr, 1.0, cr)
		cast.material_override.albedo_color = Color(0.55, 0.80, 1.0, (1.0 - cp) * 0.75)
	else:
		cast.visible = false

# ---------- HUD ----------

func _draw_hud(c: Control) -> void:
	if _state == "select":
		return
	var font := ThemeDB.fallback_font
	# online: real measured link quality (the two-machine test's actual data)
	if _net_role != "none" and font:
		var st := _net_stats()
		if st["rtt"] >= 0:
			var txt := "real RTT ~%d ms   ·   loss %.1f%%" % [st["rtt"], st["loss"]]
			c.draw_string(font, Vector2(c.size.x - 260.0, 26.0), txt,
				HORIZONTAL_ALIGNMENT_LEFT, 250.0, 15, Color(0.70, 0.90, 1.0, 0.92))
	for f in _fighters:
		if not _vis.has(f):
			continue
		var v: Dictionary = _vis[f]
		var head: Vector3 = (v["pivot"] as Node3D).position + Vector3(0.0, MODEL_H * 1.3, 0.0)
		var sp := _cam.unproject_position(head)
		var bw := 64.0
		var bh := 7.0
		c.draw_rect(Rect2(sp + Vector2(-bw / 2.0, 0.0), Vector2(bw, bh)), Color(0, 0, 0, 0.5))
		var ratio := clampf(float(f.hp) / float(f.max_hp), 0.0, 1.0)
		var hpcol := Color(0.40, 0.85, 0.40) if ratio > 0.3 else Color(0.90, 0.40, 0.30)
		c.draw_rect(Rect2(sp + Vector2(-bw / 2.0, 0.0), Vector2(bw * ratio, bh)), hpcol)
		var sready: bool = f._skill_cd <= 0.0
		var sratio: float = 1.0 if sready else clampf(1.0 - f._skill_cd / maxf(f._skill_cd_max, 0.001), 0.0, 1.0)
		var scol := Color(0.55, 0.85, 1.0) if sready else Color(0.45, 0.50, 0.65)
		c.draw_rect(Rect2(sp + Vector2(-bw / 2.0, bh + 2.0), Vector2(bw, 4.0)), Color(0, 0, 0, 0.5))
		c.draw_rect(Rect2(sp + Vector2(-bw / 2.0, bh + 2.0), Vector2(bw * sratio, 4.0)), scol)
		if font:
			c.draw_string(font, sp + Vector2(-60.0, -6.0), f.display_name,
				HORIZONTAL_ALIGNMENT_CENTER, 120.0, 13, Color(1, 1, 1, 0.85))

func _refresh_info() -> void:
	if not _info or _p1 == null:
		return
	var my_f: Node2D = _p1 if _net_role != "client" else _p2
	var practice := ""
	if _net_role == "none" and _p2 and _p2.passive:
		practice = "   ·   PRACTICE (bot frozen, P wakes)"
	var view := "smooth" if _view_snap == 0 else "%d dirs" % _view_snap
	var net := ""
	if _net_role != "none":
		net = "\nONLINE (%s)   ·   LAG one-way %d ms (round-trip %d)   ·   [L] cycles lag" % [
			_net_role.to_upper(), _lag_ms, _lag_ms * 2]
	_info.text = "Arrows steer · A run · S melee · D ranged · R %s · Space block/parry\nTab re-pick · P practice · F4 slow-mo · F6 view (%s) · Esc quit%s%s" % [
		my_f.skill_type, view, practice, net]

# ---------- input (meta keys - fighters read their own keys) ----------

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if _state == "select":
		if _ip_edit and _ip_edit.has_focus():
			# typing an IP - let the field own the keys; Esc just defocuses it
			if event.keycode == KEY_ESCAPE:
				_ip_edit.release_focus()
			return
		if event.keycode == KEY_A or event.keycode == KEY_LEFT:
			_sel_index = (_sel_index - 1 + _arch_keys.size()) % _arch_keys.size()
			_refresh_select()
		elif event.keycode == KEY_D or event.keycode == KEY_RIGHT:
			_sel_index = (_sel_index + 1) % _arch_keys.size()
			_refresh_select()
		elif event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			_begin_match()
		elif event.keycode == KEY_H:
			_net_host()
		elif event.keycode == KEY_J:
			_net_join()
		elif event.keycode == KEY_ESCAPE:
			Engine.time_scale = 1.0
			get_tree().quit()
		return
	if event.keycode == KEY_TAB:
		if _net_role != "none":
			_net_teardown("left the match")
		else:
			_return_to_select()
	elif event.keycode == KEY_ESCAPE:
		Engine.time_scale = 1.0
		get_tree().quit()
	elif event.keycode == KEY_L and _net_role != "none":
		# cycle the simulated one-way delay, synced to the other window
		var i := LAG_STEPS.find(_lag_ms)
		var nxt: int = LAG_STEPS[(i + 1) % LAG_STEPS.size()]
		_set_lag(nxt)
		if multiplayer.multiplayer_peer and not multiplayer.get_peers().is_empty():
			_recv_set_lag.rpc(nxt)
	elif event.keycode == KEY_P and _p2 and _net_role == "none":
		_p2.passive = not _p2.passive
		_refresh_info()
	elif event.keycode == KEY_F4:
		_slowmo = not _slowmo
		Engine.time_scale = 0.25 if _slowmo else 1.0
	elif event.keycode == KEY_F6:
		var next: int = {0: 8, 8: 4, 4: 0}[_view_snap]
		_view_snap = next
		for f in _fighters:
			f.facing_snap = _view_snap
		_refresh_info()

# ================= ONLINE (net_fight's locked core, same 3D render) =================

func _net_host() -> void:
	_my_arch = _arch_keys[_sel_index]
	_peer = ENetMultiplayerPeer.new()
	if _peer.create_server(PORT, 1) != OK:
		_title_label.text = "HOST FAILED (is another host window open?)"
		return
	multiplayer.multiplayer_peer = _peer
	_net_role = "host"
	_state = "waiting"
	_select_label.visible = false
	_show_ip(false)
	var ip := _local_lan_ip()
	_title_label.text = "HOSTING as %s  ·  guest connects to  %s\n(other machine: pick a fighter, type this IP, press J)      Tab cancels" % [_my_arch.to_upper(), ip]

func _net_join() -> void:
	_my_arch = _arch_keys[_sel_index]
	var ip := "127.0.0.1"
	if _ip_edit:
		var t := _ip_edit.text.strip_edges()
		if t != "":
			ip = t
		_ip_edit.release_focus()
	_peer = ENetMultiplayerPeer.new()
	if _peer.create_client(ip, PORT) != OK:
		_title_label.text = "JOIN FAILED (%s)" % ip
		return
	multiplayer.multiplayer_peer = _peer
	_net_role = "client"
	_state = "waiting"
	_select_label.visible = false
	_show_ip(false)
	_title_label.text = "connecting as %s to %s ..." % [_my_arch.to_upper(), ip]

func _on_peer_connected(_id: int) -> void:
	pass    # host waits for the guest's join_info (sent below)

func _on_connected_to_server() -> void:
	_recv_join_info.rpc_id(1, _my_arch)

# host <- guest: "I'm in, this is my fighter" -> host starts the match on both sides
@rpc("any_peer", "call_remote", "reliable")
func _recv_join_info(arch: String) -> void:
	if _net_role != "host" or _state != "waiting":
		return
	var ga := arch if ARCHETYPES.has(arch) else "rusher"
	_recv_match_start.rpc(_my_arch, ga)
	_start_net_match(_my_arch, ga)

@rpc("authority", "call_remote", "reliable")
func _recv_match_start(host_arch: String, guest_arch: String) -> void:
	if _net_role == "client":
		_start_net_match(host_arch, guest_arch)

func _start_net_match(host_arch: String, guest_arch: String) -> void:
	_title_label.visible = false
	_select_label.visible = false
	_show_ip(false)
	_info.visible = true
	_score_label.visible = true
	_p1 = _make_fighter(host_arch, "HOST", false, P1_SPAWN)
	_p2 = _make_fighter(guest_arch, "GUEST", false, P2_SPAWN)
	_p2.facing = Vector2.LEFT
	_fighters = [_p1, _p2]
	_vis[_p1] = _make_visual(ARCHETYPES[host_arch])
	_vis[_p2] = _make_visual(ARCHETYPES[guest_arch])
	if _net_role == "host":
		_p2.remote_driven = true      # the guest's inputs drive it over the network
	else:
		for f in _fighters:
			f.is_bot = true           # both fighters are puppets on the guest window
			f.passive = true
			f._hurtbox.monitorable = false   # host is the only referee
	_p1_score = 0
	_p2_score = 0
	_update_score()
	_state = "fighting"
	_refresh_info()
	print("[game3d] net match started (role=%s, host=%s, guest=%s)" % [_net_role, host_arch, guest_arch])

func _net_teardown(msg: String) -> void:
	if _net_role == "none" and _state == "select":
		return
	_net_role = "none"
	multiplayer.multiplayer_peer = null
	_lag_queue.clear()
	_return_to_select()
	_title_label.text = "CHOOSE YOUR FIGHTER\n(A / D change  ·  SPACE vs bot  ·  H host online  ·  J join)\n- %s -" % msg

# ---- latency injector (slice-4, locked: receive-side delay queue) ----

func _set_lag(v: int) -> void:
	_lag_ms = v
	print("[lag] one-way %d ms (round-trip %d)" % [v, v * 2])
	_refresh_info()

@rpc("any_peer", "call_remote", "reliable")
func _recv_set_lag(v: int) -> void:
	_set_lag(v)

func _lag_or_apply(kind: String, args: Array) -> void:
	if _lag_ms <= 0:
		_apply_msg(kind, args)
	else:
		_lag_queue.append({"at": Time.get_ticks_msec() + _lag_ms, "kind": kind, "args": args})

func _drain_lag_queue() -> void:
	var now := Time.get_ticks_msec()
	while not _lag_queue.is_empty() and _lag_queue[0]["at"] <= now:
		var m: Dictionary = _lag_queue.pop_front()
		_apply_msg(m["kind"], m["args"])

func _apply_msg(kind: String, args: Array) -> void:
	if _p1 == null or _p2 == null:
		return              # torn down (or match not started) while in flight
	match kind:
		"state":
			_apply_state(_p1, args[0], _p2)
			_apply_state(_p2, args[1], _p1)
			_sync_guest_projectiles(args[2])
		"held":
			_p2.remote_intent["dir"] = args[0]
			_p2.remote_intent["block"] = args[1]
			_p2.remote_intent["booster"] = args[2]
		"press":
			_p2.remote_intent[args[0]] = true
		"round_over":
			_apply_round_over(args[0], args[1], args[2], args[3])
		"round_start":
			_apply_round_start(args[0], args[1])

# ---- wire format (net_fight's, + lunge/cast/chill for the full archetype read) ----

func _pack(f: Node2D) -> Array:
	var anim := ANIM_IDLE
	var t := 0.0
	if f._lunge:
		anim = ANIM_LUNGE
		t = f._dash_time
	elif f._winding:
		anim = ANIM_WINDUP
		t = f._windup_time
	elif f._attacking:
		anim = ANIM_ATTACK
		t = f._attack_time
	elif f._pose == "hit":
		anim = ANIM_HIT
		t = f._pose_time
	elif f._pose == "parry":
		anim = ANIM_PARRY
		t = f._pose_time
	elif f._blocking:
		anim = ANIM_BLOCK
		t = f._block_time
	return [f.position, f.facing, f._move_vel, anim, t, f.hp, f.active,
		f._cast_anim, f._cast_radius, f._chill_time]

func _pack_projectiles() -> Array:
	var out := []
	for p in _projectiles:
		var col: Color = p["owner"].body_color if is_instance_valid(p["owner"]) else Color.WHITE
		out.append([p["pos"], p["vel"], col])
	return out

# guest <- host: the authoritative state, every frame
@rpc("authority", "call_remote", "unreliable")
func _recv_state(hf: Array, gf: Array, projs: Array) -> void:
	if _net_role != "client" or _p1 == null:
		return
	_lag_or_apply("state", [hf, gf, projs])

func _apply_state(f: Node2D, arr: Array, other: Node2D) -> void:
	f.position = arr[0]
	f.facing = arr[1]
	f._move_vel = arr[2]
	var anim: int = arr[3]
	var t: float = arr[4]
	f._lunge = anim == ANIM_LUNGE
	f._winding = anim == ANIM_WINDUP
	if anim == ANIM_WINDUP:
		f._windup_time = t
	f._attacking = anim == ANIM_ATTACK
	if anim == ANIM_ATTACK:
		f._attack_time = t
	f._blocking = anim == ANIM_BLOCK
	f._block_time = t if anim == ANIM_BLOCK else 0.0
	if anim == ANIM_HIT:
		f._pose = "hit"
		f._pose_time = t
		f._pose_max = FighterScript.POSE_HIT_TIME
	elif anim == ANIM_PARRY:
		if f._pose != "parry":
			# parry just landed - local juice for it
			spawn_sparks(f.position + f.facing * FighterScript.REACH, -f.facing, 10, Color(0.7, 0.95, 1.0))
			add_shake(4.0)
		f._pose = "parry"
		f._pose_time = t
		f._pose_max = FighterScript.POSE_PARRY_TIME
	# HP / KO - juice is DERIVED from the state, not sent
	var new_hp: int = arr[5]
	var new_active: bool = arr[6]
	if new_hp < f.hp:
		var dir: Vector2 = (f.position - other.position).normalized() if other else Vector2.RIGHT
		f._pose_dir = dir
		f._flash = FighterScript.FLASH_TIME
		spawn_sparks(f.position, dir, 9, Color(1.0, 0.9, 0.55))
		add_shake(7.0)
	if f.active and not new_active and new_hp <= 0:
		spawn_burst(f.position, 24, f.body_color.lerp(Color(1, 1, 1), 0.5))
		add_shake(14.0)
	f.hp = new_hp
	f.active = new_active
	f._cast_anim = arr[7]
	f._cast_radius = arr[8]
	f._chill_time = arr[9]
	f._update_hitbox_position()

# guest display-only projectiles: pool mirrors the host's list
func _sync_guest_projectiles(plist: Array) -> void:
	while _projectiles.size() > plist.size():
		var dead: Dictionary = _projectiles.pop_back()
		dead["node"].queue_free()
	while _projectiles.size() < plist.size():
		var mi := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.07
		sm.height = 0.14
		mi.mesh = sm
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mi.material_override = m
		add_child(mi)
		_projectiles.append({"pos": Vector2.ZERO, "vel": Vector2.ZERO, "owner": null,
			"life": 1.0, "node": mi, "mat": m})
	for i in range(plist.size()):
		var p: Dictionary = _projectiles[i]
		p["pos"] = plist[i][0]
		p["node"].position = Vector3(plist[i][0].x * WORLD_SCALE, 0.45, plist[i][0].y * WORLD_SCALE)
		if p.has("mat"):
			p["mat"].albedo_color = plist[i][2]

# host <- guest: held inputs, every frame
@rpc("any_peer", "call_remote", "unreliable")
func _recv_held(dir: Vector2, block: bool, booster: bool) -> void:
	if _net_role == "host" and _p2:
		var d := dir.normalized() if dir.length() > 1.0 else dir
		_lag_or_apply("held", [d, block, booster])

# host <- guest: one-shot presses (reliable so none get lost)
@rpc("any_peer", "call_remote", "reliable")
func _recv_press(kind: String) -> void:
	if _net_role == "host" and _p2 and kind in ["attack", "skill", "ranged"]:
		_lag_or_apply("press", [kind])

@rpc("authority", "call_remote", "reliable")
func _recv_round_over(text: String, col: Color, sh: int, sg: int) -> void:
	_lag_or_apply("round_over", [text, col, sh, sg])

func _apply_round_over(text: String, col: Color, sh: int, sg: int) -> void:
	_p1_score = sh
	_p2_score = sg
	_state = "round_over"
	_banner.add_theme_color_override("font_color", col)
	_banner.text = text
	_banner.visible = true
	_update_score()

@rpc("authority", "call_remote", "reliable")
func _recv_round_start(sh: int, sg: int) -> void:
	_lag_or_apply("round_start", [sh, sg])

func _apply_round_start(sh: int, sg: int) -> void:
	_p1_score = sh
	_p2_score = sg
	_state = "fighting"
	_banner.visible = false
	_update_score()

# ================= GAME-SHIM SERVICES (the game.gd contract, in 3D) =================

func clamp_to_arena(pos: Vector2) -> Vector2:
	return Vector2(clampf(pos.x, -HALF.x, HALF.x), clampf(pos.y, -HALF.y, HALF.y))

func add_shake(amount: float) -> void:
	_shake = maxf(_shake, amount)

func hit_stop(duration: float) -> void:
	Engine.time_scale = 0.0
	var t := get_tree().create_timer(duration, true, false, true)  # ignore_time_scale
	await t.timeout
	Engine.time_scale = 0.25 if _slowmo else 1.0

func spawn_sparks(pos: Vector2, dir: Vector2, count: int, color: Color) -> void:
	var base := dir.angle() if dir.length() > 0.01 else 0.0
	for i in range(count):
		var ang := base + randf_range(-0.8, 0.8)
		var spd := randf_range(120.0, 340.0) * WORLD_SCALE
		var vel := Vector3(cos(ang) * spd, randf_range(0.5, 1.8), sin(ang) * spd)
		_add_spark(pos, vel, 0.28, color)

func spawn_burst(pos: Vector2, count: int, color: Color) -> void:
	for i in range(count):
		var ang := randf_range(0.0, TAU)
		var spd := randf_range(160.0, 470.0) * WORLD_SCALE
		var vel := Vector3(cos(ang) * spd, randf_range(0.8, 3.0), sin(ang) * spd)
		_add_spark(pos, vel, 0.45, color)

func _add_spark(sim_pos: Vector2, vel: Vector3, life: float, color: Color) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3.ONE * 0.05
	mi.mesh = bm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = color
	mi.material_override = m
	mi.position = Vector3(sim_pos.x * WORLD_SCALE, 0.4, sim_pos.y * WORLD_SCALE)
	add_child(mi)
	_sparks.append({"node": mi, "mat": m, "base_col": color, "vel": vel, "life": life, "max": life})

func spawn_projectile(pos: Vector2, dir: Vector2, owner) -> void:
	var d := dir.normalized() if dir.length() > 0.01 else Vector2.RIGHT
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.07
	sm.height = 0.14
	mi.mesh = sm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = owner.body_color
	mi.material_override = m
	add_child(mi)
	_projectiles.append({"pos": pos + d * 26.0, "vel": d * PROJ_SPEED, "owner": owner,
		"life": PROJ_LIFE, "node": mi})

func apply_chill(origin: Vector2, radius: float, duration: float, caster) -> void:
	for f in _fighters:
		if f == caster or not f.active:
			continue
		if origin.distance_to(f.position) <= radius:
			f.apply_chill(duration)

func apply_shockwave(origin: Vector2, radius: float, knock: float, dmg: int, caster) -> void:
	for f in _fighters:
		if f == caster or not f.active:
			continue
		var d: Vector2 = f.position - origin
		if d.length() <= radius:
			var dir: Vector2 = d.normalized() if d.length() > 0.001 else Vector2.RIGHT
			f.take_hit(dir, dmg, knock)

func on_ko(loser) -> void:
	if _state != "fighting":
		return
	_state = "round_over"
	_p1.active = false
	_p2.active = false

	var winner: Node2D = _p2 if loser == _p1 else _p1
	if winner == _p1:
		_p1_score += 1
	else:
		_p2_score += 1
	_update_score()
	_banner.add_theme_color_override("font_color", winner.body_color)

	var wname: String = winner.fighter_name       # YOU/BOT offline · HOST/GUEST online
	var winner_score: int = _p1_score if winner == _p1 else _p2_score
	var match_over := winner_score >= WINS_NEEDED
	var text: String
	if wname == "YOU":
		text = "YOU WIN THE MATCH!" if match_over else "you win the round"
	else:
		text = ("%s WINS THE MATCH!" % wname) if match_over else ("%s wins the round" % wname.to_lower())
	print("[game3d] round over: %s -> %d - %d" % [wname, _p1_score, _p2_score])
	_banner.text = text
	_banner.visible = true
	if _net_role == "host":
		_recv_round_over.rpc(text, winner.body_color, _p1_score, _p2_score)
	var t := get_tree().create_timer(3.0 if match_over else 1.6)
	await t.timeout
	if _state != "round_over":
		return              # re-picked / disconnected mid-banner
	if match_over:
		_p1_score = 0
		_p2_score = 0
		_update_score()
	_reset_round()
	if _net_role == "host":
		_recv_round_start.rpc(_p1_score, _p2_score)

func _reset_round() -> void:
	_banner.visible = false
	_p1.reset_fighter(P1_SPAWN)
	_p2.reset_fighter(P2_SPAWN)
	_p2.facing = Vector2.LEFT
	_state = "fighting"

func _update_score() -> void:
	if _score_label:
		var left := "YOU" if _net_role == "none" else "HOST"
		var right := "BOT" if _net_role == "none" else "GUEST"
		_score_label.text = "%s   %d  -  %d   %s      (first to %d)" % [left, _p1_score, _p2_score, right, WINS_NEEDED]

# ---------- helpers ----------

# ENet-measured link quality to the other peer (RTT ms + packet-loss %). -1 = no peer.
# Only meaningful over a real two-machine link; on localhost it reads ~0.
func _net_stats() -> Dictionary:
	if _peer == null or multiplayer.multiplayer_peer == null:
		return {"rtt": -1, "loss": 0.0}
	var peers := multiplayer.get_peers()
	if peers.is_empty():
		return {"rtt": -1, "loss": 0.0}
	var pp := _peer.get_peer(peers[0])
	if pp == null:
		return {"rtt": -1, "loss": 0.0}
	var rtt := int(pp.get_statistic(ENetPacketPeer.PEER_ROUND_TRIP_TIME))
	# PEER_PACKET_LOSS is a ratio scaled to 65536 (ENET_PEER_PACKET_LOSS_SCALE)
	var loss := pp.get_statistic(ENetPacketPeer.PEER_PACKET_LOSS) / 65536.0 * 100.0
	return {"rtt": rtt, "loss": loss}

# best-guess LAN IPv4 for the guest to type on the other machine (skips loopback,
# link-local and IPv6; prefers the common private ranges over a VPN/virtual adapter).
func _local_lan_ip() -> String:
	var fallback := ""
	for a in IP.get_local_addresses():
		if a.count(".") != 3 or a.begins_with("127.") or a.begins_with("169.254."):
			continue
		if a.begins_with("192.168.") or a.begins_with("10."):
			return a
		if a.begins_with("172."):
			var second := int(a.split(".")[1])
			if second >= 16 and second <= 31:
				return a
		if fallback == "":
			fallback = a
	return fallback if fallback != "" else "127.0.0.1"

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
