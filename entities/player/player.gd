class_name Player
extends Node2D

# =============================================================
#  Player - moves (WASD / arrows), faces its move direction, and
#  swings a melee attack (Space). The attack enables a short-lived
#  hitbox in front; anything in the "hurtbox" group it overlaps
#  during the active window takes a hit.
# =============================================================

const SPEED := 320.0
const SIZE := 30.0
const REACH := 42.0            # how far in front the hitbox sits
const HIT_W := 48.0
const HIT_H := 48.0
const ATTACK_ACTIVE := 0.12    # seconds the hitbox is live
const ATTACK_COOLDOWN := 0.34

var game                        # reference to Game (arena + juice)
var facing := Vector2.RIGHT
var attacking := false
var _attack_time := 0.0
var _cooldown := 0.0
var _hitbox: Area2D
var _already_hit: Array = []

func _ready() -> void:
	_hitbox = Area2D.new()
	_hitbox.monitoring = false
	_hitbox.monitorable = false
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(HIT_W, HIT_H)
	cs.shape = shape
	_hitbox.add_child(cs)
	add_child(_hitbox)
	_update_hitbox_position()

func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta

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
		dir = dir.normalized()
		facing = dir
		if not attacking:
			position += dir * SPEED * delta
			if game:
				position = game.clamp_to_arena(position)
		_update_hitbox_position()

	if Input.is_action_just_pressed("ui_accept") and not attacking and _cooldown <= 0.0:
		_start_attack()

	queue_redraw()

func _physics_process(delta: float) -> void:
	if not attacking:
		return
	_attack_time -= delta
	for area in _hitbox.get_overlapping_areas():
		if area.is_in_group("hurtbox") and not _already_hit.has(area):
			_already_hit.append(area)
			var target := area.get_parent()
			if target and target.has_method("take_hit"):
				target.take_hit(facing)
	if _attack_time <= 0.0:
		attacking = false
		_hitbox.monitoring = false

func _start_attack() -> void:
	attacking = true
	_attack_time = ATTACK_ACTIVE
	_cooldown = ATTACK_COOLDOWN
	_already_hit.clear()
	_update_hitbox_position()
	_hitbox.monitoring = true

func _update_hitbox_position() -> void:
	if _hitbox:
		_hitbox.position = facing * REACH

func _draw() -> void:
	# facing indicator
	draw_line(Vector2.ZERO, facing * (SIZE * 0.9), Color(1, 1, 1, 0.5), 2.0)
	# body
	var r := Rect2(-Vector2(SIZE, SIZE) / 2.0, Vector2(SIZE, SIZE))
	draw_rect(r, Color(0.95, 0.55, 0.20))
	draw_rect(r, Color(1, 1, 1, 0.9), false, 2.0)
	# attack swing telegraph
	if attacking:
		var t := clampf(_attack_time / ATTACK_ACTIVE, 0.0, 1.0)
		var c := Color(1.0, 0.95, 0.6, 0.20 + 0.55 * t)
		var hr := Rect2(facing * REACH - Vector2(HIT_W, HIT_H) / 2.0, Vector2(HIT_W, HIT_H))
		draw_rect(hr, c)
