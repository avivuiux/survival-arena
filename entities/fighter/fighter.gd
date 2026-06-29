extends Node2D

# =============================================================
#  Fighter - a player-controlled combatant. Movement uses a
#  configurable key set so two instances can share one keyboard.
#  Has a melee attack, HP, and knockback. On KO it tells the Game.
#  Slice 3+4: two fighters duel locally with win/lose + reset.
# =============================================================

const SPEED := 320.0
const SIZE := 30.0
const REACH := 42.0
const HIT_W := 48.0
const HIT_H := 48.0
const ATTACK_ACTIVE := 0.12
const ATTACK_COOLDOWN := 0.34
const MAX_HP := 100
const DAMAGE := 12
const KNOCKBACK := 360.0
const FRICTION := 900.0
const FLASH_TIME := 0.12
const DASH_SPEED := 720.0       # quick burst
const DASH_TIME := 0.14         # how long the dash lasts (also the i-frame window)
const DASH_COOLDOWN := 0.55
# --- Movement momentum (the two feel knobs) ---
const ACCEL := 1300.0           # ramp-up to max speed (lower = more sluggish start)
const DRAG := 600.0             # glide-to-stop after release (lower = more floaty drift)

# Configured by Game before add_child:
var game
var fighter_name := "P1"
var body_color := Color(0.95, 0.55, 0.20)
var key_up := KEY_W
var key_down := KEY_S
var key_left := KEY_A
var key_right := KEY_D
var key_attack := KEY_SPACE
var key_dash := KEY_SHIFT

var active := true
var hp := MAX_HP
var facing := Vector2.RIGHT
var velocity := Vector2.ZERO        # knockback velocity
var _move_vel := Vector2.ZERO       # input movement velocity (has momentum)
var _attacking := false
var _attack_time := 0.0
var _cooldown := 0.0
var _attack_prev := false
var _flash := 0.0
var _dashing := false
var _dash_time := 0.0
var _dash_cd := 0.0
var _dash_dir := Vector2.RIGHT
var _dash_prev := false
var _iframe := 0.0
var _hitbox: Area2D
var _hurtbox: Area2D
var _already_hit: Array = []

func _ready() -> void:
	_hurtbox = Area2D.new()
	_hurtbox.monitoring = false
	_hurtbox.monitorable = true
	_hurtbox.add_to_group("hurtbox")
	var hcs := CollisionShape2D.new()
	var hsh := RectangleShape2D.new()
	hsh.size = Vector2(SIZE, SIZE)
	hcs.shape = hsh
	_hurtbox.add_child(hcs)
	add_child(_hurtbox)

	_hitbox = Area2D.new()
	_hitbox.monitoring = false
	_hitbox.monitorable = false
	var acs := CollisionShape2D.new()
	var ash := RectangleShape2D.new()
	ash.size = Vector2(HIT_W, HIT_H)
	acs.shape = ash
	_hitbox.add_child(acs)
	add_child(_hitbox)
	_update_hitbox_position()

func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta
	if _flash > 0.0:
		_flash -= delta
	if _dash_cd > 0.0:
		_dash_cd -= delta
	if _iframe > 0.0:
		_iframe -= delta

	# Knockback always applies (so a KO'd fighter still slides) - paused while dashing.
	if not _dashing:
		if velocity.length() > 1.0:
			position += velocity * delta
			velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
			if game:
				position = game.clamp_to_arena(position)
		else:
			velocity = Vector2.ZERO

	if active:
		var dir := Vector2.ZERO
		if Input.is_physical_key_pressed(key_up): dir.y -= 1.0
		if Input.is_physical_key_pressed(key_down): dir.y += 1.0
		if Input.is_physical_key_pressed(key_left): dir.x -= 1.0
		if Input.is_physical_key_pressed(key_right): dir.x += 1.0
		if dir != Vector2.ZERO:
			dir = dir.normalized()
			if not _dashing:
				facing = dir

		# Dash trigger (edge-detected). Gives a burst + brief i-frames.
		var dp := Input.is_physical_key_pressed(key_dash)
		if dp and not _dash_prev and not _dashing and _dash_cd <= 0.0:
			_dash_dir = dir if dir != Vector2.ZERO else facing
			_dashing = true
			_dash_time = DASH_TIME
			_dash_cd = DASH_COOLDOWN
			_iframe = DASH_TIME
			velocity = Vector2.ZERO
			_move_vel = Vector2.ZERO
		_dash_prev = dp

		if _dashing:
			position += _dash_dir * DASH_SPEED * delta
			if game:
				position = game.clamp_to_arena(position)
			_dash_time -= delta
			if _dash_time <= 0.0:
				_dashing = false
				_move_vel = _dash_dir * SPEED * 0.5   # glide out of the dash
			_update_hitbox_position()
		else:
			# Momentum movement: accelerate toward the target, glide to a stop.
			var target := Vector2.ZERO
			if dir != Vector2.ZERO and not _attacking:
				target = dir * SPEED
			var rate := ACCEL if target != Vector2.ZERO else DRAG
			_move_vel = _move_vel.move_toward(target, rate * delta)
			if _move_vel != Vector2.ZERO:
				position += _move_vel * delta
				if game:
					position = game.clamp_to_arena(position)
				_update_hitbox_position()
			var ap := Input.is_physical_key_pressed(key_attack)
			if ap and not _attack_prev and not _attacking and _cooldown <= 0.0:
				_start_attack()
			_attack_prev = ap

	queue_redraw()

func _physics_process(delta: float) -> void:
	if not _attacking:
		return
	_attack_time -= delta
	for area in _hitbox.get_overlapping_areas():
		if area.is_in_group("hurtbox") and not _already_hit.has(area):
			var target := area.get_parent()
			if target == self:
				continue
			_already_hit.append(area)
			if target and target.has_method("take_hit"):
				target.take_hit(facing, DAMAGE)
	if _attack_time <= 0.0:
		_attacking = false
		_hitbox.monitoring = false

func _start_attack() -> void:
	_attacking = true
	_attack_time = ATTACK_ACTIVE
	_cooldown = ATTACK_COOLDOWN
	_already_hit.clear()
	_update_hitbox_position()
	_hitbox.monitoring = true

func _update_hitbox_position() -> void:
	if _hitbox:
		_hitbox.position = facing * REACH

func take_hit(dir: Vector2, dmg: int) -> void:
	if not active or _iframe > 0.0:   # dashing dodges the hit
		return
	hp -= dmg
	velocity += dir.normalized() * KNOCKBACK
	_flash = FLASH_TIME
	if game:
		game.hit_stop(0.06)
		game.add_shake(7.0)
	if hp <= 0:
		hp = 0
		active = false
		if game:
			game.add_shake(14.0)
			game.on_ko(self)

func reset_fighter(pos: Vector2) -> void:
	hp = MAX_HP
	position = pos
	velocity = Vector2.ZERO
	_move_vel = Vector2.ZERO
	_attacking = false
	_hitbox.monitoring = false
	_flash = 0.0
	_dashing = false
	_dash_cd = 0.0
	_iframe = 0.0
	active = true

func _draw() -> void:
	# facing indicator
	draw_line(Vector2.ZERO, facing * (SIZE * 0.9), Color(1, 1, 1, 0.5), 2.0)
	# dash trail (afterimages behind the burst)
	if _dashing:
		for i in range(1, 4):
			var gpos := -_dash_dir * (float(i) * 11.0)
			var ga := 0.28 - float(i) * 0.06
			draw_rect(Rect2(gpos - Vector2(SIZE, SIZE) / 2.0, Vector2(SIZE, SIZE)),
				Color(0.55, 0.85, 1.0, maxf(ga, 0.05)))
	# body
	var col := body_color
	if _flash > 0.0:
		col = body_color.lerp(Color(1, 1, 1), clampf(_flash / FLASH_TIME, 0.0, 1.0))
	elif _iframe > 0.0:
		col = body_color.lerp(Color(0.55, 0.85, 1.0), 0.55)   # cyan = invulnerable
	if not active:
		col = body_color.darkened(0.5)
	var r := Rect2(-Vector2(SIZE, SIZE) / 2.0, Vector2(SIZE, SIZE))
	draw_rect(r, col)
	draw_rect(r, Color(1, 1, 1, 0.9), false, 2.0)
	# attack telegraph
	if _attacking:
		var t := clampf(_attack_time / ATTACK_ACTIVE, 0.0, 1.0)
		var c := Color(1.0, 0.95, 0.6, 0.20 + 0.55 * t)
		var hr := Rect2(facing * REACH - Vector2(HIT_W, HIT_H) / 2.0, Vector2(HIT_W, HIT_H))
		draw_rect(hr, c)
	# HP bar
	var bw := 50.0
	var bh := 6.0
	var by := -SIZE / 2.0 - 16.0
	draw_rect(Rect2(-bw / 2.0, by, bw, bh), Color(0, 0, 0, 0.5))
	var ratio := clampf(float(hp) / float(MAX_HP), 0.0, 1.0)
	var hpcol := Color(0.40, 0.85, 0.40) if ratio > 0.3 else Color(0.90, 0.40, 0.30)
	draw_rect(Rect2(-bw / 2.0, by, bw * ratio, bh), hpcol)
