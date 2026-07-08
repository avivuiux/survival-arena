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
# FANG = collectible-toy r2_v4 (the roster-wide style re-lock, 2026-07-05/06). No anim clips on
# this rig yet -> procedural-juice fallback plays; clips get re-forged on it (ANIM-FORGE).
# ZERO/ATLAS = chibi-plus, off-style until their r2_v4-finish replacements land.
const FANG_GLB := "res://concept/characters/fang/FANG_r2v4_3d_v4_rigged.glb"
const ZERO_GLB := "res://concept/characters/zero/ZERO_r2_3d_v1_rigged.glb"  # new cosmic-ice prince (Aviv 2026-07-06)
const ATLAS_GLB := "res://concept/characters/lightknight/LIGHTKNIGHT_3d_v2_magnific.glb"  # light-knight REPLACES ATLAS as the tank (Aviv 2026-07-07)

# --- SFX (slice 1: synthesized in-engine combat sounds, no external assets) ---
const SFX_SWING := preload("res://audio/swing.wav")
const SFX_HIT := preload("res://audio/hit.wav")
const SFX_PARRY := preload("res://audio/parry.wav")
const SFX_KO := preload("res://audio/ko.wav")
const SFX_SHOT := preload("res://audio/shot.wav")
const SFX_CAST := preload("res://audio/cast.wav")
const SFX_BLOCK := preload("res://audio/block.wav")

# --- sim space (same units as the 2D game, so the locked feel is identical) ---
const HALF := Vector2(560.0, 320.0)
const WORLD_SCALE := 0.01
const MODEL_H := 1.25                  # character world-height (bigger = more DOTA/SP presence)
const MODEL_YAW_OFF := PI * 1.5       # FANG_hero_3d_v1 front correction (locked)

# dynamic camera (DOTA/SP feel): frames the MIDPOINT of both fighters, zooms IN when they're
# close (big characters), OUT when they separate. All LIVE-TUNABLE via the F8 panel.
var _cam_dist_min := 7.5               # fighters close -> zoomed in
var _cam_dist_max := 16.0              # fighters spread out -> pulled back to fit the whole 3v3
var _cam_pitch_deg := 38.9            # camera angle above horizon (bigger = more top-down)
var _cam_fov := 58.0
var _cam_smooth := 7.0                 # follow smoothing (bigger = snappier)
var _cam_look_y := 0.7
var _char_scale := 1.0                 # global live character-size multiplier (F8 panel)

const P1_SPAWN := Vector2(-210.0, 0.0)
const P2_SPAWN := Vector2(210.0, 0.0)
const WINS_NEEDED := 2

# --- 3v3 action-MOBA match (GDD Stage 2; all numbers = [PROVE]-by-play starting values) ---
const TEAM_SIZE := 3
const ROUND_TIME := 180.0              # 3 min per round
const RESPAWN_TIME := 10.0             # dead -> back after 10s
const ROUNDS_TO_WIN := 2               # best-of-3
const ORB_INTERVAL := 20.0             # seconds between center-orb spawns
const ORB_BONUS := 2                   # team points for grabbing the orb
const ORB_BUFF_TIME := 6.0             # team power-spike duration after a grab
const ORB_GRAB_DIST := 60.0            # how close (sim units) you must be to grab center
const TEAM0_SPAWNS := [Vector2(-380, -130), Vector2(-380, 0), Vector2(-380, 130)]
const TEAM1_SPAWNS := [Vector2(380, -130), Vector2(380, 0), Vector2(380, 130)]
const TEAM_COL := [Color(0.35, 0.75, 1.0), Color(1.0, 0.5, 0.35)]  # blue (yours) vs orange

# archetypes = game.gd's data (numbers untouched). glb = 3D model when one is locked.
const ARCHETYPES := {
	# scale_mul = visual size vs base (identity read: tank looms). float_h = hover above floor
	# (ZERO floats). Both are RENDER-ONLY - hitboxes/spacing are sim-driven, untouched.
	"balanced": {"hp": 170, "speed": 320.0, "damage": 12, "atk_cd": 0.34, "skill": "chill",
		"ultimate": "chill_nova",
		"color": Color(0.35, 0.65, 0.95), "glb": ZERO_GLB, "yaw_off": PI * 1.5,
		"scale_mul": 1.0, "float_h": 0.18},
	"rusher":   {"hp": 120, "speed": 325.0, "damage": 18, "atk_cd": 0.26, "skill": "lunge",
		"ultimate": "frenzy",
		"color": Color(0.95, 0.55, 0.20), "glb": FANG_GLB, "yaw_off": PI * 1.5,
		"scale_mul": 1.0, "float_h": 0.0},
	"tank":     {"hp": 220, "speed": 240.0, "damage": 14, "atk_cd": 0.40, "skill": "shockwave",
		"ultimate": "quake",
		"color": Color(0.45, 0.85, 0.45), "glb": ATLAS_GLB, "yaw_off": PI * 1.5,
		"scale_mul": 1.35, "float_h": 0.0},
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
var _cam_look := Vector3(0.0, 0.7, 0.0)   # smoothed look target (fighters' midpoint)
var _key_light: DirectionalLight3D        # tuner refs
var _fill_light: DirectionalLight3D
var _env: Environment
var _sky_mat: ProceduralSkyMaterial
var _tuner: Control                        # F8 live-tuning panel
var _shake := 0.0
var _slowmo := false
var _state := "select"                # "select" | "fighting" | "round_over"
var _p1_score := 0                     # (dormant: old 1v1 online path)
var _p2_score := 0
# 3v3 match state
var _team_score := [0, 0]              # round score = kills + orb bonus
var _round_wins := [0, 0]              # rounds won (best-of-3)
var _round_time_left := ROUND_TIME
var _dead := {}                        # fighter -> respawn seconds left
var _team_buff := [0.0, 0.0]           # center-orb power-spike time left per team
var _orb: MeshInstance3D               # center power-orb node
var _orb_active := false
var _orb_timer := ORB_INTERVAL
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
const _view_snap := 0                 # LOCKED SMOOTH (Aviv 2026-07-04): the game must feel
                                      # smooth - no directional stepping. F6 toggle removed.
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

var _sfx_pool: Array = []             # round-robin AudioStreamPlayer pool
var _sfx_i := 0
var _sfx_prev := {}                   # fighter -> {attacking, pose, active} for edge detection

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
	for i in range(10):
		var p := AudioStreamPlayer.new()
		add_child(p)
		_sfx_pool.append(p)
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
	_env = Environment.new()
	# gradient sky (horizon = depth) instead of a flat void colour
	_sky_mat = ProceduralSkyMaterial.new()
	_sky_mat.sky_top_color = Color(0.07, 0.08, 0.13)
	_sky_mat.sky_horizon_color = Color(0.22, 0.26, 0.34)
	_sky_mat.ground_horizon_color = Color(0.16, 0.19, 0.25)
	_sky_mat.ground_bottom_color = Color(0.05, 0.06, 0.09)
	_sky_mat.sun_angle_max = 30.0
	var sky := Sky.new()
	sky.sky_material = _sky_mat
	_env.background_mode = Environment.BG_SKY
	_env.sky = sky
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	_env.ambient_light_energy = 0.55
	# adjustments enabled so the post sliders (saturation/contrast/brightness) work live
	_env.adjustment_enabled = true
	we.environment = _env
	add_child(we)

	_key_light = DirectionalLight3D.new()
	_key_light.rotation_degrees = Vector3(-55.0, -35.0, 0.0)
	_key_light.light_energy = 1.3
	_key_light.shadow_enabled = true   # fighters + walls cast shadows = planted, real space
	add_child(_key_light)
	_fill_light = DirectionalLight3D.new()
	_fill_light.rotation_degrees = Vector3(-18.0, 130.0, 0.0)
	_fill_light.light_energy = 0.35
	add_child(_fill_light)

	_build_floor()

	# center power-orb (3v3 anti-stall objective) - hidden until it spawns
	_orb = MeshInstance3D.new()
	var om := SphereMesh.new()
	om.radius = 0.30; om.height = 0.60
	_orb.mesh = om
	var omat := StandardMaterial3D.new()
	omat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	omat.albedo_color = Color(1.0, 0.88, 0.35)
	_orb.material_override = omat
	_orb.position = Vector3(0.0, 0.7, 0.0)
	_orb.visible = false
	add_child(_orb)

	_cam = Camera3D.new()
	_cam.fov = _cam_fov
	add_child(_cam)
	_cam_look = Vector3(0.0, _cam_look_y, 0.0)
	_cam.position = _cam_look + _cam_dir() * _cam_dist_max
	_cam.look_at(_cam_look, Vector3.UP)

func _build_floor() -> void:
	var mesh := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(HALF.x * 2.0 * WORLD_SCALE, HALF.y * 2.0 * WORLD_SCALE)
	mesh.mesh = pm
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
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

	# --- arena as a place: surrounding ground plane so it sits IN a world, not a void ---
	var surround := MeshInstance3D.new()
	var spm := PlaneMesh.new()
	spm.size = Vector2(w * 8.0, d * 8.0)
	surround.mesh = spm
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(0.085, 0.10, 0.14)
	surround.material_override = smat
	surround.position = Vector3(0.0, -0.03, 0.0)
	add_child(surround)

	# --- low walls (greybox, neutral) - enclosure + height + shadow-casters ---
	var wmat := StandardMaterial3D.new()
	wmat.albedo_color = Color(0.17, 0.20, 0.27)
	var hi := 0.55
	var lo := 0.15                          # near (camera-side) wall stays low so it never occludes
	var t := 0.10
	_add_wall(Vector3(0.0, hi * 0.5, -d), Vector3(w * 2.0 + t, hi, t), wmat)   # far
	_add_wall(Vector3(-w, hi * 0.5, 0.0), Vector3(t, hi, d * 2.0 + t), wmat)   # left
	_add_wall(Vector3(w, hi * 0.5, 0.0), Vector3(t, hi, d * 2.0 + t), wmat)    # right
	_add_wall(Vector3(0.0, lo * 0.5, d), Vector3(w * 2.0 + t, lo, t), wmat)    # near (low rim)

func _add_wall(center: Vector3, size: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = center
	add_child(mi)

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
	_title_label.text = "CHOOSE YOUR FIGHTER\n(A / D change  ·  SPACE start 3v3 vs bots)"
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
	var my_arch: String = _arch_keys[_sel_index]

	_title_label.visible = false
	_select_label.visible = false
	_show_ip(false)
	_info.visible = true
	_score_label.visible = true

	_fighters = []
	_sfx_prev.clear()
	# TEAM 0 (yours): you + 2 bot allies
	for i in range(TEAM_SIZE):
		var arch: String = my_arch if i == 0 else _arch_keys[randi() % _arch_keys.size()]
		var nm := "YOU" if i == 0 else "ALLY %d" % i
		var f := _make_fighter(arch, nm, i != 0, TEAM0_SPAWNS[i])
		f.team = 0
		f.spawn_pos = TEAM0_SPAWNS[i]
		if i == 0:
			_p1 = f
		_fighters.append(f)
		_vis[f] = _make_visual(ARCHETYPES[arch])
	# TEAM 1 (enemy): 3 bots
	for i in range(TEAM_SIZE):
		var arch: String = _arch_keys[randi() % _arch_keys.size()]
		var f := _make_fighter(arch, "ENEMY %d" % (i + 1), true, TEAM1_SPAWNS[i])
		f.team = 1
		f.spawn_pos = TEAM1_SPAWNS[i]
		f.facing = Vector2.LEFT
		_fighters.append(f)
		_vis[f] = _make_visual(ARCHETYPES[arch])

	_team_score = [0, 0]
	_round_wins = [0, 0]
	_start_round()
	_state = "fighting"
	_refresh_info()

func _start_round() -> void:
	_round_time_left = ROUND_TIME
	_team_score = [0, 0]
	_dead.clear()
	_team_buff = [0.0, 0.0]
	_orb_active = false
	_orb_timer = ORB_INTERVAL
	if _orb:
		_orb.visible = false
	for f in _fighters:
		f.reset_fighter(f.spawn_pos)
		f.facing = Vector2.RIGHT if f.team == 0 else Vector2.LEFT
		f._ult_charge = 0.0
	_refresh_scoreboard()

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
	_dead.clear()
	_orb_active = false
	if _orb:
		_orb.visible = false
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
	_title_label.text = "CHOOSE YOUR FIGHTER\n(A / D change  ·  SPACE start 3v3 vs bots)"
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
	f.ultimate_type = a.get("ultimate", "")
	f.key_ultimate = KEY_Q
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
	var fix := Node3D.new()        # constant model-front correction + live char-size
	pivot.add_child(fix)
	fix.scale = Vector3.ONE * _char_scale

	var meshes: Array = []
	var anim: AnimationPlayer = null
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
		var s := (MODEL_H / maxf(aabb.size.y, 0.001)) * float(arch.get("scale_mul", 1.0))
		model.scale = Vector3.ONE * s
		var cc := aabb.position + aabb.size * 0.5
		var lift := float(arch.get("float_h", 0.0))
		model.position = Vector3(-cc.x * s, -aabb.position.y * s + lift, -cc.z * s)
		fix.rotation.y = arch.get("yaw_off", MODEL_YAW_OFF)
		meshes = _mesh_instances(model)
		# skeletal animation (only FANG has clips today; others fall back to procedural juice)
		anim = _find_anim_player(model)
		if anim != null:
			for clip in ["idle", "walk"]:
				if anim.has_animation(clip):
					anim.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
			if anim.has_animation("idle"):
				anim.play("idle")
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
		"tel": tel, "tel_mat": tel_mat, "cast": cast, "cast_mat": cast_mat, "ko": 0.0,
		"anim": anim, "anim_state": "idle",
		"head_h": MODEL_H * float(arch.get("scale_mul", 1.0)) * 1.3 + float(arch.get("float_h", 0.0))}

func _find_anim_player(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var r := _find_anim_player(c)
		if r != null:
			return r
	return null

# skeletal base motion (idle <-> walk); combat beats stay on the procedural whole-model juice
func _drive_anim(f, v: Dictionary) -> void:
	var anim: AnimationPlayer = v.get("anim")
	if anim == null:
		return
	var moving: bool = f.active and f._move_vel.length() > f.speed * 0.18
	var want: String = "walk" if (moving and anim.has_animation("walk")) else "idle"
	if want != v.get("anim_state", "") and anim.has_animation(want):
		anim.play(want, 0.15)     # 0.15s crossfade so the switch reads smooth
		v["anim_state"] = want

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
				if f == p["owner"] or not f.active or f.team == p["owner"].team:
					continue                    # 3v3: projectiles skip teammates
				if p["pos"].distance_to(f.position) < PROJ_RADIUS + 16.0:
					f.take_hit(p["vel"].normalized(), PROJ_DAMAGE, PROJ_KNOCK, p["owner"])
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

	_update_match(delta)
	for f in _fighters:
		_update_visual(f, delta)
	_update_camera(delta)
	if _state != "select":
		_hud.queue_redraw()

func _cam_dir() -> Vector3:
	var p := deg_to_rad(_cam_pitch_deg)
	return Vector3(0.0, sin(p), cos(p))

func _update_camera(delta: float) -> void:
	if _state == "select":
		return
	# frame the CENTROID of all active fighters; zoom to their spread (fits a 3v3 teamfight)
	var sum := Vector3.ZERO
	var n := 0
	for f in _fighters:
		if not f.active:
			continue
		sum += Vector3(f.position.x * WORLD_SCALE, 0.0, f.position.y * WORLD_SCALE)
		n += 1
	if n == 0:
		return
	var mid := sum / float(n)
	var spread := 0.0
	for f in _fighters:
		if not f.active:
			continue
		var p := Vector3(f.position.x * WORLD_SCALE, 0.0, f.position.y * WORLD_SCALE)
		spread = maxf(spread, mid.distance_to(p))
	var dist: float = clampf(remap(spread, 1.5, 6.5, _cam_dist_min, _cam_dist_max), _cam_dist_min, _cam_dist_max)
	var look_goal := Vector3(mid.x, _cam_look_y, mid.z)
	var pos_goal := look_goal + _cam_dir() * dist
	var k := 1.0 - exp(-_cam_smooth * delta)   # frame-rate-independent smoothing (no jitter/snap)
	_cam.fov = _cam_fov
	_cam_look = _cam_look.lerp(look_goal, k)
	_cam.position = _cam.position.lerp(pos_goal, k)
	_cam.look_at(_cam_look, Vector3.UP)

# ---------- F8 live look-tuner (camera / lighting / atmosphere / post) ----------

func _toggle_tuner() -> void:
	if _tuner == null:
		_build_tuner()
	else:
		_tuner.visible = not _tuner.visible

func _build_tuner() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 40
	add_child(layer)
	var panel := PanelContainer.new()
	panel.anchor_left = 1.0; panel.anchor_right = 1.0
	panel.anchor_top = 0.0; panel.anchor_bottom = 1.0
	panel.offset_left = -358; panel.offset_right = -8
	panel.offset_top = 8; panel.offset_bottom = -8
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.07, 0.10, 0.92)
	sb.set_content_margin_all(10.0)
	sb.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", sb)
	layer.add_child(panel)
	_tuner = panel

	var scroll := ScrollContainer.new()
	panel.add_child(scroll)
	var vb := VBoxContainer.new()
	vb.custom_minimum_size = Vector2(330, 0)
	vb.add_theme_constant_override("separation", 3)
	scroll.add_child(vb)

	var title := Label.new()
	title.text = "LOOK TUNER   (F8 to hide)"
	title.add_theme_color_override("font_color", Color(1, 0.9, 0.5))
	vb.add_child(title)

	_tuner_head(vb, "CAMERA")
	_tuner_slider(vb, "Zoom in (close)", 4.0, 12.0, _cam_dist_min, func(v): _cam_dist_min = v)
	_tuner_slider(vb, "Zoom out (far)", 8.0, 22.0, _cam_dist_max, func(v): _cam_dist_max = v)
	_tuner_slider(vb, "Angle (top-down)", 20.0, 78.0, _cam_pitch_deg, func(v): _cam_pitch_deg = v)
	_tuner_slider(vb, "FOV", 38.0, 82.0, _cam_fov, func(v): _cam_fov = v)
	_tuner_slider(vb, "Follow smooth", 2.0, 15.0, _cam_smooth, func(v): _cam_smooth = v)
	_tuner_slider(vb, "Look height", 0.0, 2.0, _cam_look_y, func(v): _cam_look_y = v)
	_tuner_slider(vb, "Character size", 0.5, 2.2, _char_scale, func(v): _set_char_scale(v))

	_tuner_head(vb, "LIGHTING")
	_tuner_slider(vb, "Key energy", 0.0, 3.0, _key_light.light_energy, func(v): _key_light.light_energy = v)
	_tuner_slider(vb, "Key pitch", -90.0, -5.0, _key_light.rotation_degrees.x, func(v): _key_light.rotation_degrees.x = v)
	_tuner_slider(vb, "Key yaw", -180.0, 180.0, _key_light.rotation_degrees.y, func(v): _key_light.rotation_degrees.y = v)
	_tuner_slider(vb, "Fill energy", 0.0, 2.0, _fill_light.light_energy, func(v): _fill_light.light_energy = v)
	_tuner_slider(vb, "Ambient energy", 0.0, 2.0, _env.ambient_light_energy, func(v): _env.ambient_light_energy = v)
	_tuner_check(vb, "Shadows", _key_light.shadow_enabled, func(p): _key_light.shadow_enabled = p)

	_tuner_head(vb, "ATMOSPHERE")
	_tuner_check(vb, "Fog", _env.fog_enabled, func(p): _env.fog_enabled = p)
	_tuner_slider(vb, "Fog density", 0.0, 0.08, _env.fog_density, func(v): _env.fog_density = v)
	_tuner_check(vb, "Glow / bloom", _env.glow_enabled, func(p): _env.glow_enabled = p)
	_tuner_slider(vb, "Glow strength", 0.0, 2.0, _env.glow_strength, func(v): _env.glow_strength = v)
	_tuner_color(vb, "Sky top", _sky_mat.sky_top_color, func(c): _sky_mat.sky_top_color = c)
	_tuner_color(vb, "Sky horizon", _sky_mat.sky_horizon_color, func(c): _sky_mat.sky_horizon_color = c)

	_tuner_head(vb, "POST")
	_tuner_slider(vb, "Saturation", 0.0, 2.0, _env.adjustment_saturation, func(v): _env.adjustment_saturation = v)
	_tuner_slider(vb, "Contrast", 0.5, 1.6, _env.adjustment_contrast, func(v): _env.adjustment_contrast = v)
	_tuner_slider(vb, "Brightness", 0.5, 1.6, _env.adjustment_brightness, func(v): _env.adjustment_brightness = v)

	var btn := Button.new()
	btn.text = "PRINT VALUES (to console)"
	btn.pressed.connect(_print_tuner_values)
	vb.add_child(btn)

func _tuner_head(vb: VBoxContainer, text: String) -> void:
	var sep := HSeparator.new()
	vb.add_child(sep)
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	vb.add_child(l)

func _tuner_slider(vb: VBoxContainer, label: String, mn: float, mx: float, val: float, setter: Callable) -> void:
	var l := Label.new()
	l.text = "%s:  %.2f" % [label, val]
	vb.add_child(l)
	var s := HSlider.new()
	s.min_value = mn; s.max_value = mx; s.step = (mx - mn) / 240.0; s.value = val
	s.custom_minimum_size = Vector2(310, 16)
	s.value_changed.connect(func(v: float):
		l.text = "%s:  %.2f" % [label, v]
		setter.call(v))
	vb.add_child(s)

func _tuner_check(vb: VBoxContainer, label: String, val: bool, setter: Callable) -> void:
	var c := CheckBox.new()
	c.text = label
	c.button_pressed = val
	c.toggled.connect(func(p: bool): setter.call(p))
	vb.add_child(c)

func _tuner_color(vb: VBoxContainer, label: String, val: Color, setter: Callable) -> void:
	var row := HBoxContainer.new()
	var l := Label.new()
	l.text = label
	l.custom_minimum_size = Vector2(150, 0)
	row.add_child(l)
	var cp := ColorPickerButton.new()
	cp.color = val
	cp.custom_minimum_size = Vector2(150, 24)
	cp.color_changed.connect(func(c: Color): setter.call(c))
	row.add_child(cp)
	vb.add_child(row)

func _set_char_scale(v: float) -> void:
	_char_scale = v
	for f in _vis:
		var fx = _vis[f].get("fix")
		if fx != null:
			fx.scale = Vector3.ONE * v

func _print_tuner_values() -> void:
	print("\n===== LOOK TUNER VALUES (paste to Claude to lock) =====")
	print("CAMERA  dist_min=%.2f  dist_max=%.2f  pitch=%.1f  fov=%.1f  smooth=%.1f  look_y=%.2f  char_scale=%.2f" % [
		_cam_dist_min, _cam_dist_max, _cam_pitch_deg, _cam_fov, _cam_smooth, _cam_look_y, _char_scale])
	print("LIGHT   key_energy=%.2f  key_pitch=%.1f  key_yaw=%.1f  fill=%.2f  ambient=%.2f  shadows=%s" % [
		_key_light.light_energy, _key_light.rotation_degrees.x, _key_light.rotation_degrees.y,
		_fill_light.light_energy, _env.ambient_light_energy, str(_key_light.shadow_enabled)])
	print("ATMO    fog=%s density=%.3f  glow=%s strength=%.2f  sky_top=%s  sky_horizon=%s" % [
		str(_env.fog_enabled), _env.fog_density, str(_env.glow_enabled), _env.glow_strength,
		str(_sky_mat.sky_top_color), str(_sky_mat.sky_horizon_color)])
	print("POST    saturation=%.2f  contrast=%.2f  brightness=%.2f" % [
		_env.adjustment_saturation, _env.adjustment_contrast, _env.adjustment_brightness])
	print("========================================================\n")

func _play_sfx(stream: AudioStream, db: float = 0.0, pitch_var: float = 0.06) -> void:
	if stream == null or _sfx_pool.is_empty():
		return
	var p: AudioStreamPlayer = _sfx_pool[_sfx_i]
	_sfx_i = (_sfx_i + 1) % _sfx_pool.size()
	p.stream = stream
	p.volume_db = db
	p.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
	p.play()

# edge-detect combat events off the fighter's own state -> one sound per transition
func _sfx_events(f) -> void:
	var prev: Dictionary = _sfx_prev.get(f,
		{"attacking": false, "pose": "", "active": true, "cast": 0.0, "lunge": false, "block": false})
	if f._attacking and not prev["attacking"]:
		_play_sfx(SFX_SWING, -6.0)
	if f._pose == "hit" and prev["pose"] != "hit":
		_play_sfx(SFX_HIT, -2.0)
	elif f._pose == "parry" and prev["pose"] != "parry":
		_play_sfx(SFX_PARRY, -4.0)
	# skill cast: chill/shockwave set _cast_anim, rusher's lunge sets _lunge
	if (f._cast_anim > 0.0 and prev["cast"] <= 0.0) or (f._lunge and not prev["lunge"]):
		_play_sfx(SFX_CAST, -5.0)
	if f._blocking and not prev["block"]:
		_play_sfx(SFX_BLOCK, -8.0)
	if prev["active"] and not f.active and f.hp <= 0:
		_play_sfx(SFX_KO, -1.0, 0.02)
	_sfx_prev[f] = {"attacking": f._attacking, "pose": f._pose, "active": f.active,
		"cast": f._cast_anim, "lunge": f._lunge, "block": f._blocking}

func _update_visual(f, delta: float) -> void:
	if not _vis.has(f):
		return
	var v: Dictionary = _vis[f]
	_sfx_events(f)
	_drive_anim(f, v)
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

	# only the DEFEATED fighter (hp gone) tips over - the winner is merely frozen at round-over
	var downed: bool = not f.active and f.hp <= 0
	v["ko"] = move_toward(v["ko"], (PI * 0.5) if downed else 0.0, 5.0 * delta)
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
		var head: Vector3 = (v["pivot"] as Node3D).position + Vector3(0.0, v.get("head_h", MODEL_H * 1.3), 0.0)
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
			var ncol: Color = TEAM_COL[f.team].lerp(Color.WHITE, 0.35)   # team-tinted = read who's who
			c.draw_string(font, sp + Vector2(-60.0, -6.0), f.display_name,
				HORIZONTAL_ALIGNMENT_CENTER, 120.0, 13, ncol)

	# player ULTIMATE charge meter (the money-moment readout), bottom-center
	if _p1 != null and is_instance_valid(_p1) and _p1.ultimate_type != "":
		var uw := 240.0
		var ux := (c.size.x - uw) * 0.5
		var uy := c.size.y - 42.0
		c.draw_rect(Rect2(Vector2(ux, uy), Vector2(uw, 12.0)), Color(0, 0, 0, 0.55))
		var uc: float = clampf(_p1._ult_charge, 0.0, 1.0)
		var full: bool = uc >= 1.0
		c.draw_rect(Rect2(Vector2(ux, uy), Vector2(uw * uc, 12.0)),
			Color(1.0, 0.85, 0.30) if full else Color(0.55, 0.50, 0.32))
		if font:
			c.draw_string(font, Vector2(ux, uy - 4.0),
				"ULTIMATE READY (Q)" if full else "ultimate charging",
				HORIZONTAL_ALIGNMENT_CENTER, uw, 14,
				Color(1, 0.9, 0.5) if full else Color(0.85, 0.85, 0.85, 0.8))

func _refresh_info() -> void:
	if not _info or _p1 == null:
		return
	var my_f: Node2D = _p1 if _net_role != "client" else _p2
	var practice := ""
	if _net_role == "none" and _p2 and _p2.passive:
		practice = "   ·   PRACTICE (bot frozen, P wakes)"
	var net := ""
	if _net_role != "none":
		net = "\nONLINE (%s)   ·   LAG one-way %d ms (round-trip %d)   ·   [L] cycles lag" % [
			_net_role.to_upper(), _lag_ms, _lag_ms * 2]
	_info.text = "3v3 · Arrows steer · A run · S melee · D ranged · R %s · Q ULTIMATE · Space block/parry · grab the CENTER ORB\nTab re-pick · F4 slow-mo · F8 look-tuner · Esc quit%s%s" % [
		my_f.skill_type, practice, net]

# ---------- input (meta keys - fighters read their own keys) ----------

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_F8:        # live look-tuner panel (camera / lighting / atmosphere)
		_toggle_tuner()
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

# ================= ONLINE (net_fight's locked core, same 3D render) =================

func _net_host() -> void:
	# online is the old 1v1 path - dormant since the 3v3 pivot (single-client + bots for now).
	_title_label.text = "ONLINE PAUSED\nthe game is now 3v3 vs bots - press SPACE.  (online returns for 3v3 later)"
	return
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
	_title_label.text = "ONLINE PAUSED\nthe game is now 3v3 vs bots - press SPACE.  (online returns for 3v3 later)"
	return
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
	_sfx_prev.clear()
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
	_play_sfx(SFX_SHOT, -7.0)
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
		if f == caster or not f.active or f.team == caster.team:
			continue                            # 3v3: only enemies
		if origin.distance_to(f.position) <= radius:
			f.apply_chill(duration)

func apply_shockwave(origin: Vector2, radius: float, knock: float, dmg: int, caster) -> void:
	for f in _fighters:
		if f == caster or not f.active or f.team == caster.team:
			continue                            # 3v3: only enemies
		var d: Vector2 = f.position - origin
		if d.length() <= radius:
			var dir: Vector2 = d.normalized() if d.length() > 0.001 else Vector2.RIGHT
			f.take_hit(dir, dmg, knock, caster)

# A fighter died: award the kill to whoever last hit it, then queue its respawn.
# In 3v3 a death does NOT end the round - the round ends on the timer, by score.
func on_ko(victim) -> void:
	if _state != "fighting":
		return
	victim.active = false
	var killer = victim._last_hit_by
	if killer != null and killer.team != victim.team:
		_team_score[killer.team] += 1
		_refresh_scoreboard()
	_dead[victim] = RESPAWN_TIME

# per-frame match tick (respawns, buffs, orb, round timer) - called from _process while fighting
func _update_match(delta: float) -> void:
	if _state != "fighting":
		return
	for f in _dead.keys():
		_dead[f] -= delta
		if _dead[f] <= 0.0:
			f.reset_fighter(f.spawn_pos)
			f.facing = Vector2.RIGHT if f.team == 0 else Vector2.LEFT
			_dead.erase(f)
	for i in range(2):
		if _team_buff[i] > 0.0:
			_team_buff[i] -= delta
	_update_orb(delta)
	_round_time_left -= delta
	_refresh_scoreboard()
	if _round_time_left <= 0.0:
		_end_round_by_score()

func _update_orb(delta: float) -> void:
	if not _orb_active:
		_orb_timer -= delta
		if _orb_timer <= 0.0:
			_orb_active = true
			if _orb:
				_orb.visible = true
		return
	# spin + bob the live orb for readability
	if _orb:
		_orb.rotate_y(2.0 * delta)
	for f in _fighters:
		if f.active and f.position.length() <= ORB_GRAB_DIST:
			_grab_orb(f.team)
			return

func _grab_orb(team: int) -> void:
	_team_score[team] += ORB_BONUS
	_team_buff[team] = ORB_BUFF_TIME
	for f in _fighters:
		if f.team == team:
			f._buff_time = ORB_BUFF_TIME
	_orb_active = false
	if _orb:
		_orb.visible = false
	_orb_timer = ORB_INTERVAL
	_play_sfx(SFX_CAST, -1.0)
	spawn_burst(Vector2.ZERO, 20, TEAM_COL[team])
	_refresh_scoreboard()

func _end_round_by_score() -> void:
	_state = "round_over"
	var draw: bool = _team_score[0] == _team_score[1]
	var w: int = 0 if _team_score[0] >= _team_score[1] else 1
	if not draw:
		_round_wins[w] += 1
	var match_over: bool = _round_wins[w] >= ROUNDS_TO_WIN and not draw
	var text: String
	if draw:
		text = "round draw"
	elif w == 0:
		text = "YOU WIN THE MATCH!" if match_over else "your team wins the round"
	else:
		text = "ENEMY WINS THE MATCH!" if match_over else "enemy team wins the round"
	_banner.add_theme_color_override("font_color", TEAM_COL[w] if not draw else Color(0.8, 0.8, 0.8))
	_banner.text = text
	_banner.visible = true
	_refresh_scoreboard()
	print("[game3d] round over  score %d-%d  wins %d-%d" % [_team_score[0], _team_score[1], _round_wins[0], _round_wins[1]])
	var t := get_tree().create_timer(3.0 if match_over else 2.0)
	await t.timeout
	if _state != "round_over":
		return
	_banner.visible = false
	if match_over:
		_return_to_select()
		return
	_start_round()
	_state = "fighting"

func _refresh_scoreboard() -> void:
	if not _score_label:
		return
	var mins := int(max(_round_time_left, 0.0)) / 60
	var secs := int(max(_round_time_left, 0.0)) % 60
	var buff0 := "  [POWER]" if _team_buff[0] > 0.0 else ""
	var buff1 := "  [POWER]" if _team_buff[1] > 0.0 else ""
	_score_label.text = "YOUR TEAM %d%s    %d:%02d    %d ENEMY%s      rounds  %d - %d  (best of 3)" % [
		_team_score[0], buff0, mins, secs, _team_score[1], buff1, _round_wins[0], _round_wins[1]]

# kept as an alias so the dormant 1v1-online functions still compile
func _update_score() -> void:
	_refresh_scoreboard()

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
