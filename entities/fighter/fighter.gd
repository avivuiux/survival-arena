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
const KNOCKBACK := 540.0         # more shove on melee hits (Aviv: more knockback)
const FRICTION := 900.0
const FLASH_TIME := 0.12
const DASH_SPEED := 720.0       # quick burst
const DASH_TIME := 0.14         # how long the dash lasts (also the i-frame window)
const DASH_COOLDOWN := 0.55
# --- Movement momentum (the two feel knobs) ---
const ACCEL := 2600.0           # walk ramp (boost now uses the envelope below, not this)
const DRAG := 163.0             # glide-to-stop after release ~= release_time 2s from top (Aviv tuner)
const TURN_RATE := 4.3          # heading turn speed (rad/s) - you STEER, not snap (SP feel) - Aviv: slower turn
const WALK_SPEED := 150.0       # walk FLOOR: hold a dir to sustain current speed, or build up to this (Aviv tuner)

# Booster movement ENVELOPE - the run-speed curve, tuned in tools/tuner/movement-tuner.html (Aviv 2026-07-01).
# top speed = each fighter's `speed`; the shape below is shared.
const BOOST_ATTACK_TIME := 1.08     # seconds to ramp from 0 to top while holding A
const BOOST_ATTACK_SHARP := 0.7     # <1 = gentle start that builds & accelerates at the end (ease-in)
const BOOST_OVERSHOOT := 0.07       # briefly blow past top by this fraction then settle (floaty pop)
const BOOST_OVERSHOOT_SETTLE := 0.22 # seconds to settle from the overshoot back to top
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
const RANGED_COOLDOWN := 0.45    # long-range aimed attack (every fighter has it)
# --- Momentum read (procedural, greybox - DESIGN.md function-first) ---
const TRAIL_INTERVAL := 0.035    # seconds between afterimage samples
const TRAIL_LIFE := 0.28         # afterimage fade time
const TRAIL_MIN_SPEED := 190.0   # trail only above this speed (walk floor stays clean)
const STRETCH_MAX := 0.16        # body stretch along velocity at top speed (16%)
# --- Action pose (squash & stretch on combat beats - visual only, no timing change) ---
const POSE_ATTACK_STRETCH := 0.20  # forward lean-in while the swing is active
const POSE_HIT_SQUASH := 0.20      # flatten along the hit direction when you take one
const POSE_HIT_TIME := 0.14
const POSE_PARRY_POP := 0.16       # brief uniform pop on a perfect parry
const POSE_PARRY_TIME := 0.12
# --- Attack wind-up (GAMEPLAY-CHANGING test slice, Aviv-approved 2026-07-02) ---
# A short pre-swing commit: body cocks back, THEN the hit activates. Makes attacks
# readable/parryable-on-reaction (the SP spacing+parry mind-game). Revert = set to 0.0.
const WINDUP_TIME := 0.08
const BLOCK_DMG_MULT := 0.25     # damage taken while blocking a frontal hit
const BLOCK_KNOCK_MULT := 0.3
const PARRY_WINDOW := 0.18        # block just started = perfect parry (full negate)

# Configured by Game before add_child:
var game
var fighter_name := "P1"
var body_color := Color(0.95, 0.55, 0.20)
# Per-character stats (set by Game from an archetype)
var max_hp := 100
var speed := 320.0
var damage := 12
var attack_cooldown := 0.34
var skill_type := "chill"       # "chill" | "lunge" | "shockwave"
var display_name := ""          # archetype name shown above the head
var art_path := ""              # optional character art (res:// png); else greybox square
var key_up := KEY_W
var key_down := KEY_S
var key_left := KEY_A
var key_right := KEY_D
var key_attack := KEY_SPACE
var key_dash := KEY_SHIFT
var key_skill := KEY_E
var key_ranged := KEY_Q
var key_defense := KEY_C
var key_booster := KEY_A
var is_bot := false
var passive := false            # bot stands idle (practice mode)

var active := true
var hp := 100
var facing := Vector2.RIGHT
var velocity := Vector2.ZERO        # knockback velocity
var _move_vel := Vector2.ZERO       # input movement velocity (has momentum)
var _art_tex: Texture2D = null      # loaded character art, if any
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
var _skill_cd_max := 1.0
var _skill_prev := false
var _ranged_cd := 0.0
var _ranged_prev := false
var _blocking := false
var _block_time := 0.0
var _chill_time := 0.0          # how long THIS fighter stays slowed
var _cast_anim := 0.0           # expanding-ring visual timer
var _cast_radius := 140.0       # radius the cast ring draws to
var _bot_retreat := 0.0         # bot: backing-off timer after a swing
var _bot_dodge_cd := 0.0        # bot: cooldown between dodges
var _boost_t := 0.0             # time held on the booster - drives the movement envelope
var _boosting_prev := false     # was boosting last frame (for continuity-seeding on boost start)
var _trail: Array = []          # momentum afterimages: {pos, life}
var _trail_timer := 0.0
var _pose := ""                 # action pose: "hit" | "parry" (attack derives from _attacking)
var _pose_time := 0.0
var _pose_max := 1.0
var _pose_dir := Vector2.RIGHT  # hit squash axis (the knock direction)
var _winding := false           # attack wind-up: committed, hit not active yet
var _windup_time := 0.0
var debug_draw := false         # F3: draw the live velocity vector on this fighter
var _hitbox: Area2D
var _hurtbox: Area2D
var _already_hit: Array = []

func _ready() -> void:
	hp = max_hp
	if art_path != "":
		_art_tex = load(art_path)
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
	if _ranged_cd > 0.0:
		_ranged_cd -= delta
	if _chill_time > 0.0:
		_chill_time -= delta
	if _cast_anim > 0.0:
		_cast_anim -= delta
	if _bot_retreat > 0.0:
		_bot_retreat -= delta
	if _bot_dodge_cd > 0.0:
		_bot_dodge_cd -= delta
	if _pose_time > 0.0:
		_pose_time -= delta
		if _pose_time <= 0.0:
			_pose = ""
	# Wind-up: the commit window before the swing - when it expires, the hit goes live.
	if _winding and active:
		_windup_time -= delta
		if _windup_time <= 0.0:
			_winding = false
			_start_attack()
	# Momentum trail: fade existing afterimages (even after KO), sample new ones at speed.
	if not _trail.is_empty():
		for t in _trail:
			t["life"] -= delta
		_trail = _trail.filter(func(t): return t["life"] > 0.0)
	_trail_timer -= delta
	if active and _trail_timer <= 0.0 and _move_vel.length() > TRAIL_MIN_SPEED:
		_trail.append({"pos": position, "life": TRAIL_LIFE})
		_trail_timer = TRAIL_INTERVAL

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
		var want_ranged := false
		var want_block := false
		var want_booster := false
		if is_bot:
			if not passive:                       # practice mode: bot stands idle
				var intent := _bot_think()
				in_dir = intent["dir"]
				want_attack = intent["attack"]
				want_dash = intent["dash"]
				want_skill = intent["skill"]
				want_ranged = intent["ranged"]
				want_block = intent["block"]
				want_booster = intent["booster"]
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
			var kp_r := Input.is_physical_key_pressed(key_ranged)
			want_ranged = kp_r and not _ranged_prev
			_ranged_prev = kp_r
			want_block = Input.is_physical_key_pressed(key_defense)
			want_booster = Input.is_physical_key_pressed(key_booster)

		if in_dir != Vector2.ZERO:
			in_dir = in_dir.normalized()
			if not _dashing:
				# Steer: turn the heading toward input, NOT instantly (선회 momentum).
				var diff := wrapf(in_dir.angle() - facing.angle(), -PI, PI)
				facing = facing.rotated(clampf(diff, -TURN_RATE * delta, TURN_RATE * delta))

		# Defense (hold): blocks + parry window. Roots you; you can still turn to face.
		if want_block and not _dashing:
			if not _blocking:
				_blocking = true
				_block_time = 0.0
			else:
				_block_time += delta
		else:
			_blocking = false

		if _blocking:
			_move_vel = _move_vel.move_toward(Vector2.ZERO, DRAG * delta)
			if _move_vel != Vector2.ZERO:
				position += _move_vel * delta
				if game:
					position = game.clamp_to_arena(position)
			_update_hitbox_position()
			queue_redraw()
			return

		# Dash removed (SP had no momentary dash). Lunge still uses the burst internally.
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
			# SP movement: the BOOSTER (A) is the THRUST along your facing (arrow or not).
			# Boost speed follows the tuned ENVELOPE (ease-in ramp + overshoot); releasing it
			# glides out via DRAG. Arrows STEER (above) + give a light WALK on their own.
			if not _attacking and not _winding and want_booster:
				if not _boosting_prev:
					# CONTINUITY: begin the run curve at the speed we're ALREADY moving, not from 0,
					# so pressing run while walking flows up smoothly instead of snapping/re-ramping.
					_boost_t = _attack_time_for_speed(_move_vel.length())
				else:
					_boost_t += delta
				_boosting_prev = true
				var mag := _boost_speed(_boost_t)
				if _chill_time > 0.0:
					mag *= CHILL_SLOW
				_move_vel = facing * mag                     # envelope drives the run speed directly
			else:
				_boosting_prev = false
				_boost_t = 0.0                               # not boosting - envelope resets
				var cur := _move_vel.length()
				if not _attacking and not _winding and in_dir != Vector2.ZERO:
					# WALK = SETTLE to the walk floor (Aviv 2026-07-02: "speed doesn't return to
					# walk speed" - pure sustain kept run-speed forever once the trail made it
					# visible). Above the floor: glide DOWN gently (same DRAG as free glide, ~2s)
					# so run momentum isn't trampled, it settles. Below: build UP to the floor.
					var floor_spd := WALK_SPEED
					if _chill_time > 0.0:
						floor_spd *= CHILL_SLOW
					var mag: float
					if cur > floor_spd:
						mag = move_toward(cur, floor_spd, DRAG * delta)
					else:
						mag = move_toward(cur, floor_spd, ACCEL * delta)
					_move_vel = facing * mag                 # direction follows facing (steering bends it)
				else:
					# no direction held: glide to a stop via DRAG, following your facing.
					var glide_mag := move_toward(cur, 0.0, DRAG * delta)
					_move_vel = facing * glide_mag
			if _move_vel != Vector2.ZERO:
				position += _move_vel * delta
				if game:
					position = game.clamp_to_arena(position)
				_update_hitbox_position()
			if want_attack and not _attacking and not _winding and _cooldown <= 0.0:
				_begin_windup()
			if want_skill and _skill_cd <= 0.0 and _chill_time <= 0.0:
				if skill_type == "lunge":
					_cast_lunge()
				elif skill_type == "shockwave":
					_cast_shockwave()
				else:
					_cast_chill()
			if want_ranged and _ranged_cd <= 0.0:
				_ranged_cd = RANGED_COOLDOWN
				if game:
					game.spawn_projectile(position, facing, self)

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

# Press -> wind-up (committed, readable). The actual hit activates when it expires.
func _begin_windup() -> void:
	if WINDUP_TIME <= 0.0:
		_start_attack()
		return
	_winding = true
	_windup_time = WINDUP_TIME
	_cooldown = attack_cooldown + WINDUP_TIME   # cooldown counts from the press

func _start_attack() -> void:
	_attacking = true
	_attack_time = ATTACK_ACTIVE
	if _cooldown <= 0.0:
		_cooldown = attack_cooldown             # direct path (windup disabled)
	_already_hit.clear()
	_update_hitbox_position()
	_hitbox.monitoring = true

func _update_hitbox_position() -> void:
	if _hitbox:
		_hitbox.position = facing * REACH

func _cast_chill() -> void:
	_skill_cd = CHILL_COOLDOWN
	_skill_cd_max = CHILL_COOLDOWN
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
	_skill_cd_max = LUNGE_COOLDOWN
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
	_skill_cd_max = SHOCK_COOLDOWN
	_cast_anim = CHILL_CAST_ANIM
	_cast_radius = SHOCK_RADIUS
	if game and game.has_method("apply_shockwave"):
		game.apply_shockwave(position, SHOCK_RADIUS, SHOCK_KNOCKBACK, SHOCK_DAMAGE, self)
		game.add_shake(9.0)

# Reactive AI: chase, attack in range, then space out; dodge the foe's swing
# but only occasionally (dodge cooldown) so the player gets punish windows.
func _bot_think() -> Dictionary:
	var out := {"dir": Vector2.ZERO, "attack": false, "dash": false, "skill": false, "ranged": false, "block": false, "booster": false}
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

	# Block a close swing (the bot's defensive option now that dash is gone).
	# The wind-up is readable - the bot reacts to it like a player would.
	if (foe._attacking or foe._winding) and dist < 80.0 and _chill_time <= 0.0 and randf() < 0.4:
		out["dir"] = dir_to
		out["block"] = true
		return out

	# After a swing, back off to reset spacing (less glued / aggressive).
	if _bot_retreat > 0.0:
		out["dir"] = -dir_to           # walk back off (no boost = gentle spacing)
		return out

	# Chill: foe in range, skill ready, foe not already chilled.
	if dist < CHILL_RADIUS * 0.9 and _skill_cd <= 0.0 and foe._chill_time <= 0.0 and _chill_time <= 0.0:
		out["dir"] = dir_to
		out["skill"] = true
		return out

	# Poke with the ranged attack at mid-distance.
	if dist > REACH + 25.0 and dist < 320.0 and _ranged_cd <= 0.0 and randf() < 0.05:
		out["dir"] = dir_to
		out["ranged"] = true
		return out

	# Approach, or commit to an attack when actually ready (then space out).
	if dist > REACH + 14.0:
		out["dir"] = dir_to
		if dist > 200.0:
			out["booster"] = true     # boost only to close a big gap; walk for short spacing
	else:
		out["dir"] = dir_to
		# Less aggressive: don't swing the instant it can - hesitate, then space out longer
		# so the player gets real openings (Aviv: "bot too aggressive").
		if _cooldown <= 0.0 and randf() < 0.55:
			out["attack"] = true
			_bot_retreat = randf_range(0.9, 1.5)
	return out

# Boost speed at time t held (mirrors tools/tuner/movement-tuner.html): ease-in attack
# to `speed`, then a brief overshoot that settles back. Aviv's tuned curve.
func _boost_speed(t: float) -> float:
	var x := clampf(t / BOOST_ATTACK_TIME, 0.0, 1.0)
	var base := (1.0 - pow(1.0 - x, BOOST_ATTACK_SHARP)) * speed
	if BOOST_OVERSHOOT > 0.0 and t >= BOOST_ATTACK_TIME:
		var peak := speed * (1.0 + BOOST_OVERSHOOT)
		var dt := t - BOOST_ATTACK_TIME
		if dt < BOOST_OVERSHOOT_SETTLE:
			var k := dt / BOOST_OVERSHOOT_SETTLE
			return peak + (speed - peak) * (1.0 - pow(1.0 - k, 2.0))
		return speed
	return base

# Inverse of the attack ramp: the envelope time at which the run curve equals speed `v`.
# Used to seed the boost so it CONTINUES from your current speed instead of restarting at 0.
func _attack_time_for_speed(v: float) -> float:
	var frac := clampf(v / speed, 0.0, 0.999)
	var x := 1.0 - pow(1.0 - frac, 1.0 / BOOST_ATTACK_SHARP)
	return x * BOOST_ATTACK_TIME

func take_hit(dir: Vector2, dmg: int, knock: float = KNOCKBACK) -> void:
	if not active or _iframe > 0.0:   # dashing dodges the hit
		return
	# Blocking a frontal hit: parry (block just started) negates; otherwise chip.
	if _blocking and facing.dot(-dir.normalized()) > 0.25:
		if _block_time <= PARRY_WINDOW:
			_flash = FLASH_TIME
			_iframe = 0.12
			_pose = "parry"
			_pose_time = POSE_PARRY_TIME
			_pose_max = POSE_PARRY_TIME
			if game:
				game.add_shake(4.0)
				game.spawn_sparks(position + facing * REACH, -dir, 10, Color(0.7, 0.95, 1.0))
			return
		dmg = int(round(float(dmg) * BLOCK_DMG_MULT))
		knock *= BLOCK_KNOCK_MULT
	hp -= dmg
	velocity += dir.normalized() * knock
	_flash = FLASH_TIME
	_pose = "hit"
	_pose_time = POSE_HIT_TIME
	_pose_max = POSE_HIT_TIME
	_pose_dir = dir.normalized()
	if game:
		game.hit_stop(0.06)
		game.add_shake(7.0)
		game.spawn_sparks(position, dir, 9, Color(1.0, 0.9, 0.55))
	if hp <= 0:
		hp = 0
		active = false
		if game:
			game.add_shake(14.0)
			game.spawn_burst(position, 24, body_color.lerp(Color(1, 1, 1), 0.5))
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
	_boost_t = 0.0
	_boosting_prev = false
	_blocking = false
	_block_time = 0.0
	_trail.clear()
	_trail_timer = 0.0
	_pose = ""
	_pose_time = 0.0
	_winding = false
	_windup_time = 0.0
	active = true

func _draw() -> void:
	# momentum trail (behind everything): afterimages fade out, read = "I am moving fast"
	for t in _trail:
		var ta: float = (t["life"] / TRAIL_LIFE)
		var lp: Vector2 = t["pos"] - position
		var ts: float = SIZE * (0.55 + 0.35 * ta)          # older = smaller
		draw_rect(Rect2(lp - Vector2(ts, ts) / 2.0, Vector2(ts, ts)),
			Color(body_color.r, body_color.g, body_color.b, ta * 0.20))
	# facing indicator
	draw_line(Vector2.ZERO, facing * (SIZE * 0.9), Color(1, 1, 1, 0.5), 2.0)
	# DEBUG (F3): live velocity vector (yellow) - shows when momentum diverges from facing
	if debug_draw and _move_vel.length() > 1.0:
		var vv := _move_vel * 0.12
		draw_line(Vector2.ZERO, vv, Color(1.0, 0.85, 0.15), 3.0)
		draw_circle(vv, 3.5, Color(1.0, 0.85, 0.15))
	# block / parry shield arc in front
	if _blocking:
		var bc := Color(0.65, 0.95, 1.0) if _block_time <= PARRY_WINDOW else Color(0.5, 0.7, 0.9, 0.85)
		var bang := facing.angle()
		draw_arc(facing * (SIZE * 0.55), 24.0, bang - 0.95, bang + 0.95, 18, bc, 4.0)
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
	# body - character art if present, else the greybox square
	if _art_tex != null:
		var th := 116.0
		var tw := th * (float(_art_tex.get_width()) / float(_art_tex.get_height()))
		var flip := -1.0 if facing.x < -0.05 else 1.0
		var mod := Color(1, 1, 1)
		if _flash > 0.0:
			mod = Color(2.2, 2.2, 2.2)            # white hit flash
		elif _iframe > 0.0:
			mod = Color(0.7, 1.1, 1.5)            # cyan dodge
		elif _chill_time > 0.0:
			mod = Color(0.7, 0.85, 1.3)           # icy
		if not active:
			mod = Color(0.5, 0.5, 0.55)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(flip, 1.0))
		draw_texture_rect(_art_tex, Rect2(-tw / 2.0, -th * 0.62, tw, th), false, mod)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		var col := body_color
		if _flash > 0.0:
			col = body_color.lerp(Color(1, 1, 1), clampf(_flash / FLASH_TIME, 0.0, 1.0))
		elif _iframe > 0.0:
			col = body_color.lerp(Color(0.55, 0.85, 1.0), 0.55)   # cyan = invulnerable
		elif _chill_time > 0.0:
			col = body_color.lerp(Color(0.50, 0.70, 1.0), 0.55)   # icy = chilled / slowed
		if not active:
			col = body_color.darkened(0.5)
		# Body transform: an ACTION POSE (squash & stretch on combat beats) wins over the
		# MOMENTUM stretch. All visual-only - no gameplay timing changes.
		var rot := 0.0
		var scl := Vector2.ONE
		if _winding:
			# cock BACK - the readable anticipation beat (builds toward the release)
			var we := 1.0 - clampf(_windup_time / maxf(WINDUP_TIME, 0.001), 0.0, 1.0)
			rot = facing.angle()
			scl = Vector2(1.0 - 0.14 * we, 1.0 + 0.10 * we)
		elif _attacking:
			# lean INTO the swing, strongest at the start, easing out
			var ap := clampf(_attack_time / ATTACK_ACTIVE, 0.0, 1.0)
			rot = facing.angle()
			scl = Vector2(1.0 + POSE_ATTACK_STRETCH * ap, 1.0 - POSE_ATTACK_STRETCH * 0.6 * ap)
		elif _pose == "hit":
			# flatten along the knock direction - the impact "lands" on the body
			var he := clampf(_pose_time / _pose_max, 0.0, 1.0)
			rot = _pose_dir.angle()
			scl = Vector2(1.0 - POSE_HIT_SQUASH * he, 1.0 + POSE_HIT_SQUASH * 0.8 * he)
		elif _pose == "parry":
			# clean uniform pop - "I caught it"
			var pe := clampf(_pose_time / _pose_max, 0.0, 1.0)
			scl = Vector2.ONE * (1.0 + POSE_PARRY_POP * pe)
		elif active:
			# momentum stretch: elongate along the velocity axis, scaled by speed
			var mspd := _move_vel.length()
			var mk := clampf(mspd / maxf(speed, 1.0), 0.0, 1.15) * STRETCH_MAX
			if mk > 0.01:
				rot = _move_vel.angle()
				scl = Vector2(1.0 + mk, 1.0 - mk * 0.55)
		var posed := scl != Vector2.ONE
		if posed:
			draw_set_transform(Vector2.ZERO, rot, scl)
		var r := Rect2(-Vector2(SIZE, SIZE) / 2.0, Vector2(SIZE, SIZE))
		draw_rect(r, col)
		draw_rect(r, Color(1, 1, 1, 0.9), false, 2.0)
		if posed:
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
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

	# skill cooldown bar (below HP) - bright when the skill is ready
	var sby := by + bh + 3.0
	var sready := _skill_cd <= 0.0
	var sratio := 1.0 if sready else clampf(1.0 - _skill_cd / maxf(_skill_cd_max, 0.001), 0.0, 1.0)
	var scol := Color(0.55, 0.85, 1.0) if sready else Color(0.45, 0.50, 0.65)
	draw_rect(Rect2(-bw / 2.0, sby, bw, 4.0), Color(0, 0, 0, 0.5))
	draw_rect(Rect2(-bw / 2.0, sby, bw * sratio, 4.0), scol)

	# name above the head
	var font := ThemeDB.fallback_font
	if font:
		draw_string(font, Vector2(-60.0, by - 8.0), display_name,
			HORIZONTAL_ALIGNMENT_CENTER, 120.0, 13, Color(1, 1, 1, 0.85))
