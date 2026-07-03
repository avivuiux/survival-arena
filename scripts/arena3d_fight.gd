extends Node3D

# =============================================================
#  3D COMBAT SLICE (DESIGN.md §In-arena view - 3D combat SPEC, 2026-07-03).
#  THE question: is the 3D FIGHT fun? Player-FANG vs bot-FANG in the iso view,
#  real melee / wind-up / parry / spacing / knockback / KO / best-of-3.
#
#  Structure (this IS the integration pattern, not a fork):
#  - The SIM is the REAL game: two untouched fighter.gd instances run in a
#    hidden 2D layer. Nothing about combat is copied or re-implemented.
#  - This root script is a GAME SHIM: it provides the same services game.gd
#    provides (clamp / shake / hit-stop / sparks / burst / projectiles /
#    chill / shockwave / KO + round flow), re-expressed in 3D.
#  - The 3D layer is RENDER-ONLY: it mirrors sim position/facing/action state
#    onto the GLB every frame. Action reads = whole-Node3D transforms ONLY
#    (pitch-lean + non-uniform scale + material overlay). NO bones, NO baked
#    animation - that is the scope guard.
# =============================================================

const FighterScript := preload("res://entities/fighter/fighter.gd")
const GLB := "res://concept/characters/fang/FANG_hero_3d_v1.glb"

# --- sim space (same units as the 2D game, so the locked feel is identical) ---
const HALF := Vector2(560.0, 320.0)   # arena half-extents in sim px
const WORLD_SCALE := 0.01             # 1 sim px = 0.01 world units
const MODEL_H := 1.05                 # model height in world units
const MODEL_YAW_OFF := PI * 1.5       # FANG_hero_3d_v1 front correction (locked in arena3d_test)

const P1_SPAWN := Vector2(-210.0, 0.0)
const P2_SPAWN := Vector2(210.0, 0.0)
const WINS_NEEDED := 2

# rusher archetype stats (from game.gd ARCHETYPES - FANG mirror match)
const RUSHER := {"hp": 120, "speed": 325.0, "damage": 18, "atk_cd": 0.26, "skill": "lunge"}

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
var _state := "fighting"              # "fighting" | "round_over"
var _p1_score := 0
var _p2_score := 0
var _sparks: Array = []               # {node, mat, base_col, vel: Vector3, life, max}
var _projectiles: Array = []          # sim px: {pos, vel, owner, life, node}
var _vis := {}                        # fighter -> {pivot, fix, meshes, overlay, ring, shield, shield_mat, tel, tel_mat, ko}
var _info: Label
var _banner: Label
var _score_label: Label
var _hud: Control
var _view_snap := 0                   # F6: 0 = smooth rotation, 8 / 4 = directional views

class Hud extends Control:
	var game_ref
	func _draw() -> void:
		if game_ref:
			game_ref._draw_hud(self)

func _ready() -> void:
	_build_stage()
	_build_ui()

	# --- the hidden REAL sim ---
	_sim = Node2D.new()
	_sim.visible = false
	add_child(_sim)
	_p1 = _make_fighter("YOU", Color(0.95, 0.55, 0.20), false, P1_SPAWN)
	_p2 = _make_fighter("BOT", Color(0.35, 0.65, 0.95), true, P2_SPAWN)
	_fighters = [_p1, _p2]

	# --- the 3D render layer ---
	_vis[_p1] = _make_visual(Color(0.95, 0.55, 0.20))
	_vis[_p2] = _make_visual(Color(0.35, 0.65, 0.95))

	_update_score()
	_refresh_info()

# ---------- stage (env / lights / floor / camera - the arena3d_test approved look) ----------

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
	ui.add_child(_info)

	_score_label = Label.new()
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score_label.add_theme_font_size_override("font_size", 22)
	_score_label.position = Vector2(vp.x / 2.0 - 200.0, 14.0)
	_score_label.size = Vector2(400.0, 30.0)
	ui.add_child(_score_label)

	_banner = Label.new()
	_banner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner.add_theme_font_size_override("font_size", 52)
	_banner.visible = false
	ui.add_child(_banner)

# ---------- fighters (the real thing, configured like game.gd does) ----------

func _make_fighter(fname: String, color: Color, bot: bool, pos: Vector2) -> Node2D:
	var f := FighterScript.new()
	f.game = self
	f.fighter_name = fname
	f.display_name = fname
	f.body_color = color
	f.max_hp = RUSHER["hp"]
	f.speed = RUSHER["speed"]
	f.damage = RUSHER["damage"]
	f.attack_cooldown = RUSHER["atk_cd"]
	f.skill_type = RUSHER["skill"]
	f.art_path = ""
	# player keys = the main game's mapping (arrows steer, A run, S melee, D ranged, R skill, Space block)
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
	f.position = pos
	_sim.add_child(f)
	return f

# ---------- 3D visuals ----------

func _make_visual(ring_col: Color) -> Dictionary:
	var pivot := Node3D.new()      # yaw-aligned to facing: local +Z = forward
	add_child(pivot)
	var fix := Node3D.new()        # constant model-front correction
	pivot.add_child(fix)

	var packed: PackedScene = load(GLB)
	var model: Node3D
	if packed == null:
		push_error("GLB failed to load (needs import?): " + GLB)
		model = Node3D.new()
	else:
		model = packed.instantiate()
	fix.add_child(model)
	# fit: height = MODEL_H, centered, feet at y=0 (measured at identity, THEN yaw-fixed)
	var aabb := _combined_aabb(model)
	var s := MODEL_H / maxf(aabb.size.y, 0.001)
	model.scale = Vector3.ONE * s
	var cc := aabb.position + aabb.size * 0.5
	model.position = Vector3(-cc.x * s, -aabb.position.y * s, -cc.z * s)
	fix.rotation.y = MODEL_YAW_OFF

	# hit-flash / state overlay (ADD blend: black = no effect)
	var overlay := StandardMaterial3D.new()
	overlay.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	overlay.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	overlay.albedo_color = Color(0, 0, 0)
	var meshes := _mesh_instances(model)
	for mi in meshes:
		mi.material_overlay = overlay

	# identity ring on the floor (who am I / who is the bot)
	var ring := MeshInstance3D.new()
	var rm := CylinderMesh.new()
	rm.top_radius = 0.30
	rm.bottom_radius = 0.30
	rm.height = 0.01
	ring.mesh = rm
	var ring_mat := StandardMaterial3D.new()
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_mat.albedo_color = Color(ring_col.r, ring_col.g, ring_col.b, 0.35)
	ring.material_override = ring_mat
	ring.position = Vector3(0.0, 0.015, 0.0)
	pivot.add_child(ring)

	# block shield plate in front (parry-window color = the 2D read)
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

	# attack telegraph: floor quad at the TRUE hitbox (the hitbox does not lie)
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

	return {"pivot": pivot, "fix": fix, "meshes": meshes, "overlay": overlay,
		"ring": ring, "shield": shield, "shield_mat": shield_mat,
		"tel": tel, "tel_mat": tel_mat, "ko": 0.0}

# ---------- per-frame: shake, sparks, projectiles, mirroring ----------

func _process(delta: float) -> void:
	# camera shake (the 2D screen-shake, on the camera offsets)
	if _shake > 0.05:
		_cam.h_offset = randf_range(-_shake, _shake) * 0.01
		_cam.v_offset = randf_range(-_shake, _shake) * 0.01
		_shake = move_toward(_shake, 0.0, 40.0 * delta)
	elif _cam.h_offset != 0.0 or _cam.v_offset != 0.0:
		_shake = 0.0
		_cam.h_offset = 0.0
		_cam.v_offset = 0.0

	# sparks: fly, fall, fade
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

	# projectiles: sim logic copied from game.gd (same numbers), node mirrors sim pos
	if not _projectiles.is_empty():
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

	# mirror the sim onto the 3D models
	for f in _fighters:
		_update_visual(f, delta)
	_hud.queue_redraw()
	_refresh_info()

func _update_visual(f, delta: float) -> void:
	var v: Dictionary = _vis[f]
	var pivot: Node3D = v["pivot"]
	pivot.position = Vector3(f.position.x * WORLD_SCALE, 0.0, f.position.y * WORLD_SCALE)
	# F6 directional-view mode: the MODEL shows one of N headings (sticky switch,
	# fighter.gd's locked hysteresis) - sim/aim/hitboxes stay continuous.
	var face: Vector2 = f.facing
	if f.facing_snap > 0:
		face = f._view_facing()
	var yaw := atan2(face.x, face.y)

	# --- the locked 2D pose grammar, re-expressed as whole-model transforms ---
	var pitch := 0.0            # >0 = lean forward (into facing), <0 = lean back
	var scl := Vector3.ONE      # pivot-local: x=side, y=up, z=forward
	if f._winding:
		# cock BACK - the readable anticipation beat
		var we: float = 1.0 - clampf(f._windup_time / maxf(f.WINDUP_TIME, 0.001), 0.0, 1.0)
		pitch = -0.30 * we
		scl = Vector3(1.0, 1.0 + 0.10 * we, 1.0 - 0.14 * we)
	elif f._attacking:
		# lean INTO the swing, strongest at the start, easing out
		var ap: float = clampf(f._attack_time / f.ATTACK_ACTIVE, 0.0, 1.0)
		pitch = 0.38 * ap
		scl = Vector3(1.0, 1.0 - 0.12 * ap, 1.0 + f.POSE_ATTACK_STRETCH * ap)
	elif f._pose == "hit":
		# squash - the impact "lands" (vertical here, not knock-axis like 2D; if it
		# reads weak that is DATA for the live test)
		var he: float = clampf(f._pose_time / f._pose_max, 0.0, 1.0)
		scl = Vector3(1.0 + 0.10 * he, 1.0 - f.POSE_HIT_SQUASH * he, 1.0 + 0.10 * he)
	elif f._pose == "parry":
		# clean uniform pop - "I caught it"
		var pe: float = clampf(f._pose_time / f._pose_max, 0.0, 1.0)
		scl = Vector3.ONE * (1.0 + f.POSE_PARRY_POP * pe)
	elif f.active:
		# momentum stretch along the motion axis (velocity follows facing in this model)
		var mspd: float = f._move_vel.length()
		var mk: float = clampf(mspd / maxf(f.speed, 1.0), 0.0, 1.15) * f.STRETCH_MAX
		if mk > 0.01:
			scl = Vector3(1.0 - mk * 0.35, 1.0 - mk * 0.45, 1.0 + mk)

	# KO read: the model TIPS OVER backward (rotates around the feet)
	v["ko"] = move_toward(v["ko"], (PI * 0.5) if not f.active else 0.0, 5.0 * delta)
	pivot.rotation = Vector3(pitch - v["ko"], yaw, 0.0)
	pivot.scale = scl

	# state overlay (ADD blend): white hit-flash / cyan i-frame / icy chill
	var oc := Color(0, 0, 0)
	if f._flash > 0.0:
		oc = Color(0.9, 0.9, 0.9)
	elif f._iframe > 0.0:
		oc = Color(0.05, 0.25, 0.45)
	elif f._chill_time > 0.0:
		oc = Color(0.05, 0.15, 0.40)
	v["overlay"].albedo_color = oc

	# block shield + parry-window color (bright cyan = perfect-parry window open)
	var shield: MeshInstance3D = v["shield"]
	shield.visible = f._blocking
	if f._blocking:
		if f._block_time <= f.PARRY_WINDOW:
			v["shield_mat"].albedo_color = Color(0.65, 0.95, 1.0, 0.75)
		else:
			v["shield_mat"].albedo_color = Color(0.40, 0.60, 0.90, 0.45)

	# attack telegraph at the TRUE hitbox
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

# ---------- HUD (bars projected above heads, like the 2D game) ----------

func _draw_hud(c: Control) -> void:
	var font := ThemeDB.fallback_font
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
		# skill cooldown (bright when ready)
		var sready: bool = f._skill_cd <= 0.0
		var sratio: float = 1.0 if sready else clampf(1.0 - f._skill_cd / maxf(f._skill_cd_max, 0.001), 0.0, 1.0)
		var scol := Color(0.55, 0.85, 1.0) if sready else Color(0.45, 0.50, 0.65)
		c.draw_rect(Rect2(sp + Vector2(-bw / 2.0, bh + 2.0), Vector2(bw, 4.0)), Color(0, 0, 0, 0.5))
		c.draw_rect(Rect2(sp + Vector2(-bw / 2.0, bh + 2.0), Vector2(bw * sratio, 4.0)), scol)
		if font:
			c.draw_string(font, sp + Vector2(-60.0, -6.0), f.display_name,
				HORIZONTAL_ALIGNMENT_CENTER, 120.0, 13, Color(1, 1, 1, 0.85))

func _refresh_info() -> void:
	if not _info:
		return
	var practice := "   ·   PRACTICE (bot frozen, P wakes)" if _p2 and _p2.passive else ""
	var view := "smooth" if _view_snap == 0 else "%d directions" % _view_snap
	_info.text = "3D FIGHT SLICE  ·  Arrows steer · A run · S melee · D ranged · R lunge · Space block/parry · P practice · F4 slow-mo · F6 view (%s) · Esc quit%s" % [view, practice]

# ---------- input (meta keys only - fighters read their own keys) ----------

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_ESCAPE:
		Engine.time_scale = 1.0
		get_tree().quit()
	elif event.keycode == KEY_P and _p2:
		_p2.passive = not _p2.passive
	elif event.keycode == KEY_F4:
		_slowmo = not _slowmo
		Engine.time_scale = 0.25 if _slowmo else 1.0
	elif event.keycode == KEY_F6:
		# directional-view test: smooth -> 8 headings -> 4 -> smooth (display only)
		var next: int = {0: 8, 8: 4, 4: 0}[_view_snap]
		_view_snap = next
		for f in _fighters:
			f.facing_snap = _view_snap

# ================= GAME-SHIM SERVICES (the game.gd contract, in 3D) =================

func clamp_to_arena(pos: Vector2) -> Vector2:
	return Vector2(clampf(pos.x, -HALF.x, HALF.x), clampf(pos.y, -HALF.y, HALF.y))

func add_shake(amount: float) -> void:
	_shake = maxf(_shake, amount)

# Brief global freeze on impact (copied verbatim from game.gd).
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

# AoE services copied from game.gd (unreachable in the FANG mirror-match, kept for parity).
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

# Round flow (copied from game.gd, YOU/BOT wording).
func on_ko(loser) -> void:
	if _state == "round_over":
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

	var you_won := winner == _p1
	var winner_score: int = _p1_score if you_won else _p2_score
	print("[fight] round over: %s -> YOU %d - %d BOT" % [winner.fighter_name, _p1_score, _p2_score])
	if winner_score >= WINS_NEEDED:
		_banner.text = "YOU WIN THE MATCH!" if you_won else "BOT WINS THE MATCH!"
		_banner.visible = true
		var t := get_tree().create_timer(3.0)
		await t.timeout
		_p1_score = 0
		_p2_score = 0
		_update_score()
		_reset_round()
	else:
		_banner.text = "you win the round" if you_won else "bot wins the round"
		_banner.visible = true
		var t := get_tree().create_timer(1.6)
		await t.timeout
		_reset_round()

func _reset_round() -> void:
	_banner.visible = false
	_p1.reset_fighter(P1_SPAWN)
	_p2.reset_fighter(P2_SPAWN)
	_state = "fighting"

func _update_score() -> void:
	if _score_label:
		_score_label.text = "YOU   %d  -  %d   BOT      (first to %d)" % [_p1_score, _p2_score, WINS_NEEDED]

# ---------- helpers (from arena3d_test) ----------

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
