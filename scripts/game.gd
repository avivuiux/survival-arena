extends Node2D

# =============================================================
#  Game - orchestrates the arena: spawns two fighters, owns the
#  arena bounds, provides juice services (hit-stop, shake), and
#  runs the round flow (KO -> winner banner -> reset).
#  Slice 3+4: local two-player duel with win/lose.
# =============================================================

const ARENA_MARGIN := 24.0      # arena = the WHOLE screen (Aviv 2026-07-01), minus a thin edge
const FighterScript := preload("res://entities/fighter/fighter.gd")

const P1_SPAWN := Vector2(-210.0, 0.0)   # wider start gap to match the bigger arena
const P2_SPAWN := Vector2(210.0, 0.0)

# Character archetypes (data-driven; first step of the L2 roster)
# HP raised across the board so rounds last longer (Aviv: "ends too fast, low HP");
# spread narrowed so no matchup is wildly lopsided ("bot has more HP than me").
const ARCHETYPES := {
	"balanced": {"hp": 170, "speed": 320.0, "damage": 12, "atk_cd": 0.34, "skill": "chill"},
	"rusher":   {"hp": 120, "speed": 325.0, "damage": 18, "atk_cd": 0.26, "skill": "lunge", "art": "res://concept/characters/fang/FANG_ingame_v1_cutout.png"},
	"tank":     {"hp": 220, "speed": 240.0, "damage": 14, "atk_cd": 0.40, "skill": "shockwave"},
}
const WINS_NEEDED := 2           # best-of-3: first to 2 round wins takes the match
const PROJ_SPEED := 560.0        # ranged shot
const PROJ_LIFE := 0.9
const PROJ_DAMAGE := 8
const PROJ_KNOCK := 260.0        # more shove on ranged hits (Aviv: more knockback)
const PROJ_RADIUS := 12.0

var arena_center := Vector2.ZERO
var _shake := 0.0
var _sparks: Array = []
var _projectiles: Array = []
var _p1: Node2D
var _p2: Node2D
var _fighters: Array = []
var _state := "select"            # "select" | "fighting" | "round_over"
var _banner: Label
var _mode_label: Label
var _hint: Label
var _title_label: Label
var _select_label: Label
var _arch_keys: Array = []
var _sel_index := 0
var _p1_score := 0
var _p2_score := 0
var _score_label: Label
var _debug := false
var _slowmo := false
var _debug_label: Label
var _facing_snap := 0             # ISO facing test (F6): 0 = off, 4, 8 - display-only

func _ready() -> void:
	arena_center = get_viewport_rect().size / 2.0
	_arch_keys = ARCHETYPES.keys()
	var vp := get_viewport_rect().size

	var ui := CanvasLayer.new()
	add_child(ui)

	_hint = Label.new()
	_hint.position = Vector2(16.0, 12.0)
	_hint.visible = false
	ui.add_child(_hint)

	_mode_label = Label.new()
	_mode_label.position = Vector2(16.0, 32.0)
	_mode_label.visible = false
	ui.add_child(_mode_label)

	_banner = Label.new()
	_banner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner.add_theme_font_size_override("font_size", 52)
	_banner.visible = false
	ui.add_child(_banner)

	# Character-select UI (shown first; arena draws behind it)
	_title_label = Label.new()
	_title_label.text = "CHOOSE YOUR FIGHTER\n(A / D to change,  Space to start)"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 28)
	_title_label.position = Vector2(vp.x / 2.0 - 240.0, 100.0)
	_title_label.size = Vector2(480.0, 90.0)
	ui.add_child(_title_label)

	_select_label = Label.new()
	_select_label.add_theme_font_size_override("font_size", 20)
	_select_label.position = Vector2(vp.x / 2.0 - 240.0, 210.0)
	_select_label.size = Vector2(480.0, 220.0)
	ui.add_child(_select_label)

	_score_label = Label.new()
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score_label.add_theme_font_size_override("font_size", 22)
	_score_label.position = Vector2(vp.x / 2.0 - 200.0, 14.0)
	_score_label.size = Vector2(400.0, 30.0)
	_score_label.visible = false
	ui.add_child(_score_label)

	_debug_label = Label.new()
	_debug_label.position = Vector2(16.0, 58.0)
	_debug_label.add_theme_font_size_override("font_size", 15)
	_debug_label.add_theme_color_override("font_color", Color(0.55, 1.0, 0.65))
	_debug_label.visible = false
	ui.add_child(_debug_label)

	_refresh_select()
	queue_redraw()

func _make_fighter(fname: String, color: Color, ku: int, kd: int, kl: int, kr: int,
		ka: int, kdash: int, kskill: int, kranged: int, kdef: int, kboost: int, archetype: String, pos: Vector2) -> Node2D:
	var f := FighterScript.new()
	f.game = self
	f.fighter_name = fname
	f.body_color = color
	var a: Dictionary = ARCHETYPES[archetype]
	f.max_hp = a["hp"]
	f.speed = a["speed"]
	f.damage = a["damage"]
	f.attack_cooldown = a["atk_cd"]
	f.skill_type = a["skill"]
	f.art_path = a.get("art", "")
	f.display_name = archetype.to_upper()
	f.key_up = ku
	f.key_down = kd
	f.key_left = kl
	f.key_right = kr
	f.key_attack = ka
	f.key_dash = kdash
	f.key_skill = kskill
	f.key_ranged = kranged
	f.key_defense = kdef
	f.key_booster = kboost
	f.position = pos
	add_child(f)
	return f

# AoE chill: slow every other active fighter within radius of the cast origin.
func apply_chill(origin: Vector2, radius: float, duration: float, caster) -> void:
	for f in _fighters:
		if f == caster or not f.active:
			continue
		if origin.distance_to(f.position) <= radius:
			f.apply_chill(duration)

# AoE shockwave: shove (and lightly damage) every other fighter within radius.
func apply_shockwave(origin: Vector2, radius: float, knock: float, dmg: int, caster) -> void:
	for f in _fighters:
		if f == caster or not f.active:
			continue
		var d: Vector2 = f.position - origin
		if d.length() <= radius:
			var dir: Vector2 = d.normalized() if d.length() > 0.001 else Vector2.RIGHT
			f.take_hit(dir, dmg, knock)

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if _state == "select":
		if event.keycode == KEY_A or event.keycode == KEY_LEFT:
			_sel_index = (_sel_index - 1 + _arch_keys.size()) % _arch_keys.size()
			_refresh_select()
		elif event.keycode == KEY_D or event.keycode == KEY_RIGHT:
			_sel_index = (_sel_index + 1) % _arch_keys.size()
			_refresh_select()
		elif event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			_begin_match()
		return
	if event.keycode == KEY_TAB:
		_return_to_select()
	elif event.keycode == KEY_P and _p2:
		_p2.passive = not _p2.passive
		if _p2.passive:
			_mode_label.text = "PRACTICE - bot idle   (P = wake bot)"
		else:
			_mode_label.text = "vs BOT (%s)   P = practice" % _p2.display_name
	elif event.keycode == KEY_F3:
		_debug = not _debug
		_debug_label.visible = _debug
		if _p1: _p1.debug_draw = _debug
		if _p2: _p2.debug_draw = _debug
		if _p1: _p1.queue_redraw()
		if _p2: _p2.queue_redraw()
	elif event.keycode == KEY_F4:
		_slowmo = not _slowmo
		Engine.time_scale = 0.25 if _slowmo else 1.0
	elif event.keycode == KEY_F6:
		# ISO view model (DESIGN.md §In-arena view): toggle the 8-heading body view
		# (5 drawings via mirroring). Aim/steering/poses stay continuous either way.
		_facing_snap = 8 if _facing_snap == 0 else 0
		for f in _fighters:
			f.facing_snap = _facing_snap
			f.queue_redraw()
		var snap_txt := "OFF" if _facing_snap == 0 else "ON - 8 views, sticky switch (wedge = the sprite's view)"
		_mode_label.text = "ISO body-view: %s   (F6 toggles)" % snap_txt
		_mode_label.visible = true
		queue_redraw()

func _refresh_select() -> void:
	var t := ""
	for i in range(_arch_keys.size()):
		var k: String = _arch_keys[i]
		var a: Dictionary = ARCHETYPES[k]
		var marker := "> " if i == _sel_index else "    "
		t += "%s%s   -   hp %d   spd %d   dmg %d   skill: %s\n\n" % [
			marker, k.to_upper(), int(a["hp"]), int(a["speed"]), int(a["damage"]), a["skill"]]
	if _select_label:
		_select_label.text = t

func _begin_match() -> void:
	var p1_arch: String = _arch_keys[_sel_index]
	var p2_arch: String = _arch_keys[randi() % _arch_keys.size()]

	_title_label.visible = false
	_select_label.visible = false
	_hint.text = "%s   -   Arrows steer · A run · S melee · D ranged · R skill · Space block       Tab = re-pick · P = practice" % p1_arch.to_upper()
	_hint.visible = true
	_mode_label.text = "vs BOT (%s)   P = practice" % p2_arch.to_upper()
	_mode_label.visible = true

	# Single-client: you (P1) steer with arrows; left hand on the action keys. Opponent = bot.
	_p1 = _make_fighter("P1", Color(0.95, 0.55, 0.20),
		KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT,
		KEY_S, KEY_SHIFT, KEY_R, KEY_D, KEY_SPACE, KEY_A,
		p1_arch, arena_center + P1_SPAWN)
	_p2 = _make_fighter("P2", Color(0.35, 0.65, 0.95),
		KEY_KP_8, KEY_KP_2, KEY_KP_4, KEY_KP_6, KEY_KP_5, KEY_KP_0, KEY_KP_7, KEY_KP_9, KEY_KP_1, KEY_KP_3,
		p2_arch, arena_center + P2_SPAWN)
	_fighters = [_p1, _p2]
	_p2.is_bot = true            # opponent always a bot (single-client; stand-in for remote players)
	_p1.debug_draw = _debug
	_p2.debug_draw = _debug
	_p1.facing_snap = _facing_snap
	_p2.facing_snap = _facing_snap
	_p1_score = 0
	_p2_score = 0
	_score_label.visible = true
	_update_score()
	_state = "fighting"

func _return_to_select() -> void:
	if _p1:
		_p1.queue_free()
	if _p2:
		_p2.queue_free()
	_p1 = null
	_p2 = null
	_fighters = []
	_banner.visible = false
	_hint.visible = false
	_mode_label.visible = false
	_score_label.visible = false
	_title_label.visible = true
	_select_label.visible = true
	_refresh_select()
	_state = "select"

func _update_mode_label() -> void:
	if _mode_label:
		_mode_label.text = "P2 = %s    (press B to toggle)" % ("BOT" if _p2.is_bot else "HUMAN")

func _process(delta: float) -> void:
	if _debug and _p1 and _state == "fighting":
		_debug_label.text = _debug_text()

	# Screen shake: offset the scene root, decaying back to rest.
	if _shake > 0.05:
		position = Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake))
		_shake = move_toward(_shake, 0.0, 40.0 * delta)
	elif position != Vector2.ZERO:
		_shake = 0.0
		position = Vector2.ZERO

	if not _sparks.is_empty():
		for s in _sparks:
			s["pos"] += s["vel"] * delta
			s["vel"] *= 0.90
			s["life"] -= delta
		_sparks = _sparks.filter(func(s): return s["life"] > 0.0)
		queue_redraw()

	if not _projectiles.is_empty():
		for p in _projectiles:
			p["pos"] += p["vel"] * delta
			p["life"] -= delta
			for f in _fighters:
				if f == p["owner"] or not f.active:
					continue
				if p["pos"].distance_to(f.position) < PROJ_RADIUS + 16.0:
					f.take_hit(p["vel"].normalized(), PROJ_DAMAGE, PROJ_KNOCK)
					spawn_sparks(p["pos"], p["vel"], 6, p["col"])
					p["life"] = 0.0
					break
		_projectiles = _projectiles.filter(func(p): return p["life"] > 0.0)
		queue_redraw()

# Arena = the whole screen: clamp to the viewport rect, minus a thin margin.
func clamp_to_arena(pos: Vector2) -> Vector2:
	var vp := get_viewport_rect().size
	return Vector2(
		clampf(pos.x, ARENA_MARGIN, vp.x - ARENA_MARGIN),
		clampf(pos.y, ARENA_MARGIN, vp.y - ARENA_MARGIN))

func add_shake(amount: float) -> void:
	_shake = maxf(_shake, amount)

# Spark burst aimed along a hit direction (impact feedback).
func spawn_sparks(pos: Vector2, dir: Vector2, count: int, color: Color) -> void:
	var base := dir.angle() if dir.length() > 0.01 else 0.0
	for i in range(count):
		var ang := base + randf_range(-0.8, 0.8)
		var spd := randf_range(120.0, 340.0)
		_sparks.append({"pos": pos, "vel": Vector2(cos(ang), sin(ang)) * spd, "life": 0.28, "max": 0.28, "col": color})

# Fire a ranged shot in a direction (from a fighter's aim/facing).
func spawn_projectile(pos: Vector2, dir: Vector2, owner) -> void:
	var d := dir.normalized() if dir.length() > 0.01 else Vector2.RIGHT
	_projectiles.append({"pos": pos + d * 26.0, "vel": d * PROJ_SPEED, "owner": owner, "life": PROJ_LIFE, "col": owner.body_color})

# Omnidirectional burst (KO pop).
func spawn_burst(pos: Vector2, count: int, color: Color) -> void:
	for i in range(count):
		var ang := randf_range(0.0, TAU)
		var spd := randf_range(160.0, 470.0)
		_sparks.append({"pos": pos, "vel": Vector2(cos(ang), sin(ang)) * spd, "life": 0.45, "max": 0.45, "col": color})

# Brief global freeze on impact - the core of "satisfying impact".
func hit_stop(duration: float) -> void:
	Engine.time_scale = 0.0
	var t := get_tree().create_timer(duration, true, false, true)  # ignore_time_scale
	await t.timeout
	Engine.time_scale = 0.25 if _slowmo else 1.0   # keep slow-mo if the debug toggle is on

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

	var winner_score: int = _p1_score if winner == _p1 else _p2_score
	if winner_score >= WINS_NEEDED:
		_banner.text = "%s WINS THE MATCH!" % winner.fighter_name
		_banner.visible = true
		var t := get_tree().create_timer(3.0)
		await t.timeout
		_new_match()
	else:
		_banner.text = "%s wins the round" % winner.fighter_name
		_banner.visible = true
		var t := get_tree().create_timer(1.6)
		await t.timeout
		_reset_round()

func _reset_round() -> void:
	_banner.visible = false
	_p1.reset_fighter(arena_center + P1_SPAWN)
	_p2.reset_fighter(arena_center + P2_SPAWN)
	_state = "fighting"

func _new_match() -> void:
	_p1_score = 0
	_p2_score = 0
	_update_score()
	_reset_round()

func _update_score() -> void:
	if _score_label:
		_score_label.text = "P1   %d  -  %d   P2      (first to %d)" % [_p1_score, _p2_score, WINS_NEEDED]

# Live mechanics readout for the F3 debug overlay (reads P1's real state).
func _debug_text() -> String:
	var v: Vector2 = _p1._move_vel
	var spd := v.length()
	var top: float = _p1.speed
	var phase := "idle"
	if _p1._attacking:
		phase = "attack"
	elif _p1._boosting_prev:
		phase = "BOOST"
	elif spd > 5.0:
		phase = "glide"
	var face_ang := rad_to_deg(_p1.facing.angle())
	var vel_ang := rad_to_deg(v.angle()) if spd > 1.0 else face_ang
	var d_ang := absf(wrapf(vel_ang - face_ang, -180.0, 180.0))
	var a_held: bool = Input.is_physical_key_pressed(KEY_A)
	return "F3 debug  ·  F4 slow-mo:%s\nspeed  %5.0f / %d   (%3.0f%%)\nphase  %s     boost_t %.2fs\nfacing %4.0f°   vel %4.0f°   diff %3.0f°\nA (run): %s" % [
		("ON" if _slowmo else "off"), spd, int(top), (spd / maxf(top, 1.0) * 100.0),
		phase, _p1._boost_t, face_ang, vel_ang, d_ang, ("HELD" if a_held else "-")]

# ISO floor grid: two families of 2:1-slope lines (the classic iso diamond), clipped
# to the floor rect. Visual only.
func _draw_iso_grid(rect: Rect2) -> void:
	var spacing := 56.0
	var col := Color(0.21, 0.24, 0.31)
	for sgn in [1.0, -1.0]:
		var slope: float = 0.5 * sgn
		# y-intercept range so every line crossing the rect is covered
		var b1: float = rect.position.y - slope * rect.position.x
		var b2: float = rect.position.y - slope * rect.end.x
		var b3: float = rect.end.y - slope * rect.position.x
		var b4: float = rect.end.y - slope * rect.end.x
		var lo: float = minf(minf(b1, b2), minf(b3, b4))
		var hi: float = maxf(maxf(b1, b2), maxf(b3, b4))
		var b: float = floorf(lo / spacing) * spacing
		while b <= hi:
			# clip y = slope*x + b to the rect via the x-range where y stays inside
			var xa: float = (rect.position.y - b) / slope
			var xb: float = (rect.end.y - b) / slope
			var xlo: float = maxf(rect.position.x, minf(xa, xb))
			var xhi: float = minf(rect.end.x, maxf(xa, xb))
			if xlo < xhi:
				draw_line(Vector2(xlo, slope * xlo + b), Vector2(xhi, slope * xhi + b), col, 1.0)
			b += spacing

func _draw() -> void:
	# Full-screen arena floor + border. ISO test: a 2:1 diamond grid tilts the ground
	# plane for the eye (presentation only - bounds + clamp unchanged).
	var vp := get_viewport_rect().size
	var rect := Rect2(Vector2(ARENA_MARGIN, ARENA_MARGIN), vp - Vector2(ARENA_MARGIN, ARENA_MARGIN) * 2.0)
	draw_rect(rect, Color(0.15, 0.17, 0.22), true)
	_draw_iso_grid(rect)
	draw_rect(rect, Color(0.35, 0.40, 0.48), false, 2.0)

	for s in _sparks:
		var a := clampf(s["life"] / s["max"], 0.0, 1.0)
		var c: Color = s["col"]
		c.a = a
		var p: Vector2 = s["pos"]
		draw_line(p, p - s["vel"].normalized() * (4.0 + 7.0 * a), c, 2.0)

	for pr in _projectiles:
		var pp: Vector2 = pr["pos"]
		var pc: Color = pr["col"]
		draw_line(pp, pp - pr["vel"].normalized() * 14.0, Color(pc.r, pc.g, pc.b, 0.5), 3.0)
		draw_circle(pp, 5.0, pc)
