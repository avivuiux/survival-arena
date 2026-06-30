extends Node2D

# =============================================================
#  Game - orchestrates the arena: spawns two fighters, owns the
#  arena bounds, provides juice services (hit-stop, shake), and
#  runs the round flow (KO -> winner banner -> reset).
#  Slice 3+4: local two-player duel with win/lose.
# =============================================================

const ARENA_RADIUS_X := 320.0
const ARENA_SQUASH := 0.6
const RINGOUT_M := 1.18           # shoved past this multiple of the edge = ring-out
const FighterScript := preload("res://entities/fighter/fighter.gd")

const P1_SPAWN := Vector2(-140.0, 0.0)
const P2_SPAWN := Vector2(140.0, 0.0)

# Character archetypes (data-driven; first step of the L2 roster)
const ARCHETYPES := {
	"balanced": {"hp": 100, "speed": 320.0, "damage": 12, "atk_cd": 0.34, "skill": "chill"},
	"rusher":   {"hp": 70,  "speed": 430.0, "damage": 18, "atk_cd": 0.26, "skill": "lunge"},
	"tank":     {"hp": 150, "speed": 240.0, "damage": 14, "atk_cd": 0.40, "skill": "shockwave"},
}
const WINS_NEEDED := 2           # best-of-3: first to 2 round wins takes the match

var arena_center := Vector2.ZERO
var _shake := 0.0
var _sparks: Array = []
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

	_refresh_select()
	queue_redraw()

func _make_fighter(fname: String, color: Color, ku: int, kd: int, kl: int, kr: int,
		ka: int, kdash: int, kskill: int, archetype: String, pos: Vector2) -> Node2D:
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
	f.display_name = archetype.to_upper()
	f.key_up = ku
	f.key_down = kd
	f.key_left = kl
	f.key_right = kr
	f.key_attack = ka
	f.key_dash = kdash
	f.key_skill = kskill
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
	if event.keycode == KEY_B:
		_p2.is_bot = not _p2.is_bot
		_update_mode_label()
	elif event.keycode == KEY_R:
		_return_to_select()

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
	_hint.text = "P1 %s: WASD / Space / Shift / E=skill      P2 %s: Arrows / Enter / (/) / .=skill      B=bot   R=re-pick" % [p1_arch.to_upper(), p2_arch.to_upper()]
	_hint.visible = true
	_mode_label.visible = true

	_p1 = _make_fighter("P1", Color(0.95, 0.55, 0.20),
		KEY_W, KEY_S, KEY_A, KEY_D, KEY_SPACE, KEY_SHIFT, KEY_E, p1_arch, arena_center + P1_SPAWN)
	_p2 = _make_fighter("P2", Color(0.35, 0.65, 0.95),
		KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_ENTER, KEY_SLASH, KEY_PERIOD, p2_arch, arena_center + P2_SPAWN)
	_fighters = [_p1, _p2]
	_p2.is_bot = true
	_update_mode_label()
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

# Keep a position inside the isometric diamond: |dx|/rx + |dy|/ry <= 1
func clamp_to_arena(pos: Vector2) -> Vector2:
	var off := pos - arena_center
	var rx := ARENA_RADIUS_X
	var ry := ARENA_RADIUS_X * ARENA_SQUASH
	var m := absf(off.x) / rx + absf(off.y) / ry
	if m > 1.0:
		return arena_center + off / m
	return pos

# True once a fighter has been shoved past the ring-out boundary.
func is_ringout(pos: Vector2) -> bool:
	var off := pos - arena_center
	var rx := ARENA_RADIUS_X
	var ry := ARENA_RADIUS_X * ARENA_SQUASH
	return (absf(off.x) / rx + absf(off.y) / ry) > RINGOUT_M

func add_shake(amount: float) -> void:
	_shake = maxf(_shake, amount)

# Spark burst aimed along a hit direction (impact feedback).
func spawn_sparks(pos: Vector2, dir: Vector2, count: int, color: Color) -> void:
	var base := dir.angle() if dir.length() > 0.01 else 0.0
	for i in range(count):
		var ang := base + randf_range(-0.8, 0.8)
		var spd := randf_range(120.0, 340.0)
		_sparks.append({"pos": pos, "vel": Vector2(cos(ang), sin(ang)) * spd, "life": 0.28, "max": 0.28, "col": color})

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
	Engine.time_scale = 1.0

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

func _draw() -> void:
	var rx := ARENA_RADIUS_X
	var ry := ARENA_RADIUS_X * ARENA_SQUASH
	var pts := PackedVector2Array([
		arena_center + Vector2(0.0, -ry),
		arena_center + Vector2(rx, 0.0),
		arena_center + Vector2(0.0, ry),
		arena_center + Vector2(-rx, 0.0),
	])
	draw_colored_polygon(pts, Color(0.15, 0.17, 0.22))
	var outline := pts + PackedVector2Array([pts[0]])
	draw_polyline(outline, Color(0.35, 0.40, 0.48), 2.0)

	# ring-out boundary (faint red): get shoved past this and you're out
	var ro := RINGOUT_M
	var rpts := PackedVector2Array([
		arena_center + Vector2(0.0, -ry * ro),
		arena_center + Vector2(rx * ro, 0.0),
		arena_center + Vector2(0.0, ry * ro),
		arena_center + Vector2(-rx * ro, 0.0),
	])
	draw_polyline(rpts + PackedVector2Array([rpts[0]]), Color(0.80, 0.30, 0.30, 0.35), 2.0)

	for s in _sparks:
		var a := clampf(s["life"] / s["max"], 0.0, 1.0)
		var c: Color = s["col"]
		c.a = a
		var p: Vector2 = s["pos"]
		draw_line(p, p - s["vel"].normalized() * (4.0 + 7.0 * a), c, 2.0)
