class_name Dummy
extends Node2D

# =============================================================
#  Dummy - a stationary practice target. Takes knockback when hit,
#  flashes, drives the hit-stop + screen-shake, and eases back to
#  its home spot so you can keep wailing on it. HP refills on KO so
#  the "is the hit satisfying?" loop never stops.
# =============================================================

const SIZE := 34.0
const MAX_HP := 100
const DAMAGE := 10
const KNOCKBACK := 380.0
const FRICTION := 900.0         # how fast knockback bleeds off
const RETURN_SPEED := 90.0      # drift back home when at rest
const FLASH_TIME := 0.12

var game
var hp := MAX_HP
var velocity := Vector2.ZERO
var home := Vector2.ZERO
var _flash := 0.0
var _hurtbox: Area2D

func _ready() -> void:
	home = position
	_hurtbox = Area2D.new()
	_hurtbox.monitoring = false
	_hurtbox.monitorable = true
	_hurtbox.add_to_group("hurtbox")
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(SIZE, SIZE)
	cs.shape = shape
	_hurtbox.add_child(cs)
	add_child(_hurtbox)

func take_hit(dir: Vector2) -> void:
	hp -= DAMAGE
	velocity += dir.normalized() * KNOCKBACK
	_flash = FLASH_TIME
	if game:
		game.hit_stop(0.06)
		game.add_shake(7.0)
	if hp <= 0:
		hp = MAX_HP
		_flash = FLASH_TIME * 1.6
		if game:
			game.add_shake(12.0)

func _process(delta: float) -> void:
	if velocity.length() > 1.0:
		position += velocity * delta
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
		if game:
			position = game.clamp_to_arena(position)
	else:
		velocity = Vector2.ZERO
		position = position.move_toward(home, RETURN_SPEED * delta)

	if _flash > 0.0:
		_flash -= delta
	queue_redraw()

func _draw() -> void:
	var base := Color(0.45, 0.50, 0.60)
	var col := base
	if _flash > 0.0:
		var f := clampf(_flash / FLASH_TIME, 0.0, 1.0)
		col = base.lerp(Color(1, 1, 1), f)
	var r := Rect2(-Vector2(SIZE, SIZE) / 2.0, Vector2(SIZE, SIZE))
	draw_rect(r, col)
	draw_rect(r, Color(0.10, 0.10, 0.12, 0.8), false, 2.0)

	# HP bar above the dummy
	var bw := 46.0
	var bh := 6.0
	var bx := -bw / 2.0
	var by := -SIZE / 2.0 - 16.0
	draw_rect(Rect2(bx, by, bw, bh), Color(0, 0, 0, 0.5))
	var ratio := clampf(float(hp) / float(MAX_HP), 0.0, 1.0)
	draw_rect(Rect2(bx, by, bw * ratio, bh), Color(0.40, 0.85, 0.40))
