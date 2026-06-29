extends Node2D

# =============================================================
#  Survival Arena - greybox vertical slice (phase 1)
#  Goal of this slice: ONE controllable character moving inside
#  an isometric-style arena. No art, no combat yet - just proving
#  the foundation is alive and feels okay to move.
#  Move: WASD or arrow keys.
# =============================================================

const ARENA_RADIUS_X := 320.0          # half-width of the diamond floor
const ARENA_SQUASH := 0.6              # vertical squash -> isometric look
const PLAYER_SPEED := 320.0            # pixels / second
const PLAYER_SIZE := 30.0

var arena_center := Vector2.ZERO
var player_pos := Vector2.ZERO

func _ready() -> void:
	arena_center = get_viewport_rect().size / 2.0
	player_pos = arena_center
	queue_redraw()

func _process(delta: float) -> void:
	var dir := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W) or Input.is_action_pressed("ui_up"):
		dir.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_action_pressed("ui_down"):
		dir.y += 1.0
	if Input.is_physical_key_pressed(KEY_A) or Input.is_action_pressed("ui_left"):
		dir.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_action_pressed("ui_right"):
		dir.x += 1.0

	if dir != Vector2.ZERO:
		player_pos += dir.normalized() * PLAYER_SPEED * delta
		_clamp_to_arena()
		queue_redraw()

# Keep the player inside the diamond: |dx|/rx + |dy|/ry <= 1
func _clamp_to_arena() -> void:
	var off := player_pos - arena_center
	var rx := ARENA_RADIUS_X
	var ry := ARENA_RADIUS_X * ARENA_SQUASH
	var m := absf(off.x) / rx + absf(off.y) / ry
	if m > 1.0:
		player_pos = arena_center + off / m

func _draw() -> void:
	var rx := ARENA_RADIUS_X
	var ry := ARENA_RADIUS_X * ARENA_SQUASH

	# Isometric diamond floor
	var floor_pts := PackedVector2Array([
		arena_center + Vector2(0.0, -ry),
		arena_center + Vector2(rx, 0.0),
		arena_center + Vector2(0.0, ry),
		arena_center + Vector2(-rx, 0.0),
	])
	draw_colored_polygon(floor_pts, Color(0.15, 0.17, 0.22))
	var outline := floor_pts + PackedVector2Array([floor_pts[0]])
	draw_polyline(outline, Color(0.35, 0.40, 0.48), 2.0)

	# Player (greybox square)
	var s := PLAYER_SIZE
	var rect := Rect2(player_pos - Vector2(s, s) / 2.0, Vector2(s, s))
	draw_rect(rect, Color(0.95, 0.55, 0.20))
	draw_rect(rect, Color(1.0, 1.0, 1.0, 0.9), false, 2.0)
