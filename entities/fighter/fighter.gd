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

# Configured by Game before add_child:
var game
var fighter_name := "P1"
var body_color := Color(0.95, 0.55, 0.20)
var key_up := KEY_W
var key_down := KEY_S
var key_left := KEY_A
var key_right := KEY_D
var key_attack := KEY_SPACE

var active := true
var hp := MAX_HP
var facing := Vector2.RIGHT
var velocity := Vector2.ZERO
var _attacking := false
var _attack_time := 0.0
var _cooldown := 0.0
var _attack_prev := false
var _flash := 0.0
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

	# Knockback always applies (so a KO'd fighter still slides).
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
			facing = dir
			if not _attacking:
				position += dir * SPEED * delta
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
	if not active:
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
	_attacking = false
	_hitbox.monitoring = false
	_flash = 0.0
	active = true

func _draw() -> void:
	# facing indicator
	draw_line(Vector2.ZERO, facing * (SIZE * 0.9), Color(1, 1, 1, 0.5), 2.0)
	# body
	var col := body_color
	if _flash > 0.0:
		col = body_color.lerp(Color(1, 1, 1), clampf(_flash / FLASH_TIME, 0.0, 1.0))
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
