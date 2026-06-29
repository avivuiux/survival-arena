extends Node2D

# =============================================================
#  Game - orchestrates the arena: spawns entities, owns the
#  arena bounds, and provides "juice" services (hit-stop, shake)
#  that entities call into when a hit lands.
#  Slice 2: one player + one dummy, proving the hit feels good.
# =============================================================

const ARENA_RADIUS_X := 320.0
const ARENA_SQUASH := 0.6

# Explicit preloads (robust in headless + editor; no reliance on class_name cache)
const PlayerScript := preload("res://entities/player/player.gd")
const DummyScript := preload("res://entities/dummy/dummy.gd")

var arena_center := Vector2.ZERO
var _shake := 0.0
var _player: Node2D
var _dummy: Node2D

func _ready() -> void:
	arena_center = get_viewport_rect().size / 2.0

	_player = PlayerScript.new()
	_player.game = self
	_player.position = arena_center + Vector2(-110.0, 40.0)
	add_child(_player)

	_dummy = DummyScript.new()
	_dummy.game = self
	_dummy.position = arena_center + Vector2(120.0, -10.0)
	add_child(_dummy)

	queue_redraw()

func _process(delta: float) -> void:
	# Screen shake: offset the whole scene root, decaying back to rest.
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
	# ignore_time_scale = true so the timer ticks while everything else is frozen
	var t := get_tree().create_timer(duration, true, false, true)
	await t.timeout
	Engine.time_scale = 1.0

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
