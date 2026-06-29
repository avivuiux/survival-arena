extends Node2D

# =============================================================
#  Fighter - a player-controlled combatant. Movement uses a
#  configurable key set so two instances can share one keyboard.
#  Has a melee attack, HP, and knockback. On KO it tells the Game.
#  Slice 3+4: two fighters duel locally with win/lose + reset.
# =============================================================

const SIZE := 30.0
const REACH := 42.0
const HIT_W := 48.0
const HIT_H := 48.0
const ATTACK_ACTIVE := 0.12
const KNOCKBACK := 360.0
const FRICTION := 900.0
const FLASH_TIME := 0.12
const DASH_SPEED := 720.0       # quick burst
const DASH_TIME := 0.14         # how long the dash lasts (also the i-frame window)
const DASH_COOLDOWN := 0.55
# --- Movement momentum (the two feel knobs) ---
const ACCEL := 1300.0           # ramp-up to max speed (lower = more sluggish start)
const DRAG := 600.0             # glide-to-stop after release (lower = more floaty drift)
# --- Chill skill (first skill: AoE slow that catches a group) ---
const CHILL_COOLDOWN := 3.0
const CHILL_RADIUS := 140.0
const CHILL_DURATION := 1.6     # how long caught enemies stay slowed
const CHILL_SLOW := 0.32        # speed multiplier while chilled
const CHILL_CAST_ANIM := 0.4    # expanding-ring visual length
const BOT_DODGE_CD := 1.3       # min gap between bot dodges (opens punish windows)
const LUNGE_COOLDOWN := 1.4     # rusher skill
const LUNGE_TIME := 0.20        # lunge travel/active window
const SHOCK_COOLDOWN := 2.4     # tank skill
const SHOCK_RADIUS := 130.0
const SHOCK_KNOCKBACK := 620.0
const SHOCK_DAMAGE := 8

# Configured by Game before add_child:
var game
var fighter_name := "P1"
var body_color := Color(0.95, 0.55, 0.20)
# Per-character stats (set by Game from an archetype)
var max_hp := 100
var speed := 320.0
var damage := 12
var attack_cooldown := 0.34
var skill_type := "chill"       # "chill" | "lunge"
var key_up := KEY_W
var key_down := KEY_S
var key_left := KEY_A
var key_right := KEY_D
var key_attack := KEY_SPACE
var key_dash := KEY_SHIFT
var key_skill := KEY_E
var is_bot := false

var active := true
var hp := 100
var facing := Vector2.RIGHT
var velocity := Vector2.ZERO        # knockback velocity
var _move_vel := Vector2.ZERO       # input movement velocity (has momentum)
var _attacking := false
var _lunge := false
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
var _skill_cd := 0.0
var _skill_prev := false
var _chill_time := 0.0          # how long THIS fighter stays slowed
var _cast_anim := 0.0           # expanding-ring visual timer
var _cast_radius := 140.0       # radius the cast ring draws to
var _bot_retreat := 0.0         # bot: backing-off timer after a swing
var _bot_dodge_cd := 0.0        # bot: cooldown between dodges
var _hitbox: Area2D
var _hurtbox: Area2D
var _already_hit: Array = []

func _ready() -> void:
	hp = max_hp
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
	if _skill_cd > 0.0:
		_skill_cd -= delta
	if _chill_time > 0.0:
		_chill_time -= delta
	if _cast_anim > 0.0:
		_cast_anim -= delta
	if _bot_retreat > 0.0:
		_bot_retreat -= delta
	if _bot_dodge_cd > 0.0:
		_bot_dodge_cd -= delta

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
		# --- gather intent: from the bot AI, or from human keys ---
		var in_dir := Vector2.ZERO
		var want_attack := false
		var want_dash := false
		var want_skill := false
		if is_bot:
			var intent := _bot_think()
			in_dir = intent["dir"]
			want_attack = intent["attack"]
			want_dash = intent["dash"]
			want_skill = intent["skill"]
		else:
			if Input.is_physical_key_pressed(key_up): in_dir.y -= 1.0
			if Input.is_physical_key_pressed(key_down): in_dir.y += 1.0
			if Input.is_physical_key_pressed(key_left): in_dir.x -= 1.0
			if Input.is_physical_key_pressed(key_right): in_dir.x += 1.0
			var kp_a := Input.is_physical_key_pressed(key_attack)
			want_attack = kp_a and not _attack_prev
			_attack_prev = kp_a
			var kp_d := Input.is_physical_key_pressed(key_dash)
			want_dash = kp_d and not _dash_prev
			_dash_prev = kp_d
			var kp_s := Input.is_physical_key_pressed(key_skill)
			want_skill = kp_s and not _skill_prev
			_skill_prev = kp_s

		if in_dir != Vector2.ZERO:
			in_dir = in_dir.normalized()
			if not _dashing:
				facing = in_dir

		# Dash: a burst + brief i-frames
		if want_dash and not _dashing and _dash_cd <= 0.0 and _chill_time <= 0.0:
			_dash_dir = in_dir if in_dir != Vector2.ZERO else facing
			_dashing = true
			_dash_time = DASH_TIME
			_dash_cd = DASH_COOLDOWN
			_iframe = DASH_TIME
			velocity = Vector2.ZERO
			_move_vel = Vector2.ZERO

		if _dashing:
			position += _dash_dir * DASH_SPEED * delta
			if game:
				position = game.clamp_to_arena(position)
			_dash_time -= delta
			if _dash_time <= 0.0:
				_dashing = false
				_move_vel = _dash_dir * speed * 0.5   # glide out of the dash
				if _lunge:
					_lunge = false
					_hitbox.monitoring = false
			_update_hitbox_position()
		else:
			# Momentum movement: accelerate toward the target, glide to a stop.
			var spd := speed
			var acc := ACCEL
			if _chill_time > 0.0:        # chilled = sluggish
				spd *= CHILL_SLOW
				acc *= CHILL_SLOW
			var target_vel := Vector2.ZERO
			if in_dir != Vector2.ZERO and not _attacking:
				target_vel = in_dir * spd
			var rate := acc if target_vel != Vector2.ZERO else DRAG
			_move_vel = _move_vel.move_toward(target_vel, rate * delta)
			if _move_vel != Vector2.ZERO:
				position += _move_vel * delta
				if game:
					position = game.clamp_to_arena(position)
				_update_hitbox_position()
			if want_attack and not _attacking and _cooldown <= 0.0:
				_start_attack()
			if want_skill and _skill_cd <= 0.0 and _chill_time <= 0.0:
				if skill_type == "lunge":
					_cast_lunge()
				elif skill_type == "shockwave":
					_cast_shockwave()
				else:
					_cast_chill()

	queue_redraw()

func _physics_process(delta: float) -> void:
	if not _attacking and not _lunge:
		return
	if _attacking:
		_attack_time -= delta
	for area in _hitbox.get_overlapping_areas():
		if area.is_in_group("hurtbox") and not _already_hit.has(area):
			var target := area.get_parent()
			if target == self:
				continue
			_already_hit.append(area)
			if target and target.has_method("take_hit"):
				target.take_hit(facing, damage)
	if _attacking and _attack_time <= 0.0:
		_attacking = false
		if not _lunge:
			_hitbox.monitoring = false

func _start_attack() -> void:
	_attacking = true
	_attack_time = ATTACK_ACTIVE
	_cooldown = attack_cooldown
	_already_hit.clear()
	_update_hitbox_position()
	_hitbox.monitoring = true

func _update_hitbox_position() -> void:
	if _hitbox:
		_hitbox.position = facing * REACH

func _cast_chill() -> void:
	_skill_cd = CHILL_COOLDOWN
	_cast_anim = CHILL_CAST_ANIM
	_cast_radius = CHILL_RADIUS
	if game and game.has_method("apply_chill"):
		game.apply_chill(position, CHILL_RADIUS, CHILL_DURATION, self)
		game.add_shake(5.0)

func apply_chill(duration: float) -> void:
	if active:
		_chill_time = maxf(_chill_time, duration)

# Rusher skill: a fast forward lunge with the hitbox live (a dash that hits).
func _cast_lunge() -> void:
	_skill_cd = LUNGE_COOLDOWN
	_dash_dir = facing
	_dashing = true
	_lunge = true
	_dash_time = LUNGE_TIME
	_dash_cd = DASH_COOLDOWN
	_iframe = LUNGE_TIME * 0.5
	velocity = Vector2.ZERO
	_move_vel = Vector2.ZERO
	_already_hit.clear()
	_update_hitbox_position()
	_hitbox.monitoring = true
	if game:
		game.add_shake(4.0)

# Tank skill: a shockwave that shoves (and lightly damages) everyone nearby.
func _cast_shockwave() -> void:
	_skill_cd = SHOCK_COOLDOWN
	_cast_anim = CHILL_CAST_ANIM
	_cast_radius = SHOCK_RADIUS
	if game and game.has_method("apply_shockwave"):
		game.apply_shockwave(position, SHOCK_RADIUS, SHOCK_KNOCKBACK, SHOCK_DAMAGE, self)
		game.add_shake(9.0)

# Reactive AI: chase, attack in range, then space out; dodge the foe's swing
# but only occasionally (dodge cooldown) so the player gets punish windows.
func _bot_think() -> Dictionary:
	var out := {"dir": Vector2.ZERO, "attack": false, "dash": false, "skill": false}
	var foe = null
	if game:
		for f in game._fighters:
			if f != self and f.active:
				foe = f
				break
	if foe == null:
		return out

	var to_foe: Vector2 = foe.position - position
	var dist := to_foe.length()
	var dir_to: Vector2 = to_foe.normalized() if dist > 0.001 else Vector2.RIGHT

	# Dodge the foe's swing - gated by a cooldown + a roll, so it's beatable.
	if foe._attacking and dist < 85.0 and _dash_cd <= 0.0 and _bot_dodge_cd <= 0.0 \
			and _chill_time <= 0.0 and randf() < 0.5:
		out["dir"] = -dir_to
		out["dash"] = true
		_bot_dodge_cd = BOT_DODGE_CD
		return out

	# After a swing, back off to reset spacing (less glued / aggressive).
	if _bot_retreat > 0.0:
		out["dir"] = -dir_to
		return out

	# Chill: foe in range, skill ready, foe not already chilled.
	if dist < CHILL_RADIUS * 0.9 and _skill_cd <= 0.0 and foe._chill_time <= 0.0 and _chill_time <= 0.0:
		out["dir"] = dir_to
		out["skill"] = true
		return out

	# Approach, or commit to an attack when actually ready (then space out).
	if dist > REACH + 14.0:
		out["dir"] = dir_to
	else:
		out["dir"] = dir_to
		if _cooldown <= 0.0:
			out["attack"] = true
			_bot_retreat = randf_range(0.5, 0.9)
	return out

func take_hit(dir: Vector2, dmg: int, knock: float = KNOCKBACK) -> void:
	if not active or _iframe > 0.0:   # dashing dodges the hit
		return
	hp -= dmg
	velocity += dir.normalized() * knock
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
	hp = max_hp
	position = pos
	velocity = Vector2.ZERO
	_move_vel = Vector2.ZERO
	_attacking = false
	_lunge = false
	_hitbox.monitoring = false
	_flash = 0.0
	_dashing = false
	_dash_cd = 0.0
	_iframe = 0.0
	_skill_cd = 0.0
	_chill_time = 0.0
	_cast_anim = 0.0
	_bot_retreat = 0.0
	_bot_dodge_cd = 0.0
	active = true

func _draw() -> void:
	# facing indicator
	draw_line(Vector2.ZERO, facing * (SIZE * 0.9), Color(1, 1, 1, 0.5), 2.0)
	# chill cast ring (expanding outward)
	if _cast_anim > 0.0:
		var cp := 1.0 - (_cast_anim / CHILL_CAST_ANIM)
		draw_arc(Vector2.ZERO, _cast_radius * cp, 0.0, TAU, 48,
			Color(0.55, 0.80, 1.0, (1.0 - cp) * 0.75), 3.0)
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
	elif _chill_time > 0.0:
		col = body_color.lerp(Color(0.50, 0.70, 1.0), 0.55)   # icy = chilled / slowed
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
	if _lunge:
		var hr2 := Rect2(facing * REACH - Vector2(HIT_W, HIT_H) / 2.0, Vector2(HIT_W, HIT_H))
		draw_rect(hr2, Color(1.0, 0.5, 0.25, 0.55))   # orange = damaging lunge
	# HP bar
	var bw := 50.0
	var bh := 6.0
	var by := -SIZE / 2.0 - 16.0
	draw_rect(Rect2(-bw / 2.0, by, bw, bh), Color(0, 0, 0, 0.5))
	var ratio := clampf(float(hp) / float(max_hp), 0.0, 1.0)
	var hpcol := Color(0.40, 0.85, 0.40) if ratio > 0.3 else Color(0.90, 0.40, 0.30)
	draw_rect(Rect2(-bw / 2.0, by, bw * ratio, bh), hpcol)
