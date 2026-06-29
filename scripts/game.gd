extends Node2D

# =============================================================
#  Game - orchestrates the arena: spawns two fighters, owns the
#  arena bounds, provides juice services (hit-stop, shake), and
#  runs the round flow (KO -> winner banner -> reset).
#  Slice 3+4: local two-player duel with win/lose.
# =============================================================

const ARENA_RADIUS_X := 320.0
const ARENA_SQUASH := 0.6
const FighterScript := preload("res://entities/fighter/fighter.gd")

const P1_SPAWN := Vector2(-140.0, 0.0)
const P2_SPAWN := Vector2(140.0, 0.0)

var arena_center := Vector2.ZERO
var _shake := 0.0
var _p1: Node2D
var _p2: Node2D
var _state := "fighting"          # "fighting" | "round_over"
var _banner: Label

func _ready() -> void:
	arena_center = get_viewport_rect().size / 2.0

	var ui := CanvasLayer.new()
	add_child(ui)

	var hint := Label.new()
	hint.text = "P1: WASD + Space     P2: Arrows + Enter"
	hint.position = Vector2(16.0, 12.0)
	ui.add_child(hint)

	_banner = Label.new()
	_banner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner.add_theme_font_size_override("font_size", 52)
	_banner.visible = false
	ui.add_child(_banner)

	_p1 = _make_fighter("P1", Color(0.95, 0.55, 0.20),
		KEY_W, KEY_S, KEY_A, KEY_D, KEY_SPACE, arena_center + P1_SPAWN)
	_p2 = _make_fighter("P2", Color(0.35, 0.65, 0.95),
		KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_ENTER, arena_center + P2_SPAWN)

	queue_redraw()

func _make_fighter(fname: String, color: Color, ku: int, kd: int, kl: int, kr: int,
		ka: int, pos: Vector2) -> Node2D:
	var f := FighterScript.new()
	f.game = self
	f.fighter_name = fname
	f.body_color = color
	f.key_up = ku
	f.key_down = kd
	f.key_left = kl
	f.key_right = kr
	f.key_attack = ka
	f.position = pos
	add_child(f)
	return f

func _process(delta: float) -> void:
	# Screen shake: offset the scene root, decaying back to rest.
	if _shake > 0.05:
		position = Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake))
		_shake = move_toward(_shake, 0.0, 40.0 * delta)
	elif position != Vector2.ZERO:
		_shake = 0.0
		position = Vector2.ZERO

# Keep a position inside the isometric diamond: |dx|/rx + |dy|/ry <= 1
func clamp_to_arena(pos: Vector2) -> Vector2:
	var off := pos - arena_center
	var rx := ARENA_RADIUS_X
	var ry := ARENA_RADIUS_X * ARENA_SQUASH
	var m := absf(off.x) / rx + absf(off.y) / ry
	if m > 1.0:
		return arena_center + off / m
	return pos

func add_shake(amount: float) -> void:
	_shake = maxf(_shake, amount)

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
	_banner.text = "%s WINS!" % winner.fighter_name
	_banner.add_theme_color_override("font_color", winner.body_color)
	_banner.visible = true
	var t := get_tree().create_timer(2.0)
	await t.timeout
	_reset_round()

func _reset_round() -> void:
	_banner.visible = false
	_p1.reset_fighter(arena_center + P1_SPAWN)
	_p2.reset_fighter(arena_center + P2_SPAWN)
	_state = "fighting"

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
