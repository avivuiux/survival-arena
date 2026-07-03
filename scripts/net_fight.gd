extends Node2D
# =============================================================
#  NET FIGHT - slice 4: LATENCY (see NET.md slice-4 SPEC).
#  Slice 3 (server-authoritative, host = referee) is LOCKED; this
#  adds an ARTIFICIAL-LATENCY INJECTOR so localhost becomes an
#  honest delay simulator: every incoming message (state -> guest,
#  inputs -> host, round events) is queued and applied only after
#  a configurable ONE-WAY delay. Constant delay, order preserved.
#  L cycles 0/30/60/100 ms one-way (= RTT 0/60/120/200), synced to
#  both windows. Deliberately NO mitigation yet (no prediction /
#  interpolation) - the point is to FEEL the raw cost first.
# =============================================================

const PORT := 8910
const ARENA_MARGIN := 24.0
const SPAWN_GAP := 210.0
const WINS_NEEDED := 2
const PROJ_SPEED := 560.0
const PROJ_LIFE := 0.9
const PROJ_DAMAGE := 8
const PROJ_KNOCK := 260.0
const PROJ_RADIUS := 12.0
const FighterScript := preload("res://entities/fighter/fighter.gd")

# action/pose wire enum (host -> guest)
const ANIM_IDLE := 0
const ANIM_WINDUP := 1
const ANIM_ATTACK := 2
const ANIM_BLOCK := 3
const ANIM_HIT := 4
const ANIM_PARRY := 5

var _peer: ENetMultiplayerPeer
var _role := "none"              # "host" | "client" | "none"
var _state := "waiting"          # "waiting" | "fighting" | "round_over"
var _host_f: Node2D = null       # orange, left  (the host's fighter)
var _guest_f: Node2D = null      # blue,  right  (the guest's fighter)
var _fighters: Array = []
var _score_h := 0
var _score_g := 0
var _status: Label
var _banner: Label
var _score_label: Label
var _shake := 0.0
var _sparks: Array = []
var _projectiles: Array = []     # host: full sim dicts · guest: display-only dicts
# guest-side input edge detection (presses become one-shot events)
var _prev_attack := false
var _prev_skill := false
var _prev_ranged := false
# --- slice 4: artificial latency (one-way, applied on RECEIVE in each window) ---
const LAG_STEPS := [0, 30, 60, 100]   # one-way ms; round-trip = x2
var _lag_ms := 0
var _lag_queue: Array = []            # FIFO: {at: msec, kind: String, args: Array}

func _ready() -> void:
	var ui := CanvasLayer.new()
	add_child(ui)
	_status = Label.new()
	_status.position = Vector2(16, 12)
	_status.add_theme_font_size_override("font_size", 17)
	_status.add_theme_color_override("font_color", Color(0.9, 0.93, 1.0))
	ui.add_child(_status)
	_banner = Label.new()
	_banner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner.add_theme_font_size_override("font_size", 52)
	_banner.visible = false
	ui.add_child(_banner)
	_score_label = Label.new()
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score_label.add_theme_font_size_override("font_size", 22)
	_score_label.position = Vector2(get_viewport_rect().size.x / 2.0 - 200.0, 14.0)
	_score_label.size = Vector2(400.0, 30.0)
	_score_label.visible = false
	ui.add_child(_score_label)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(func(_id): _teardown("PEER LEFT - reopen both windows"))
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(func(): _role = "none"; _set_status("CONNECTION FAILED"))
	multiplayer.server_disconnected.connect(func(): _teardown("HOST LEFT - reopen both windows"))
	_set_status()
	queue_redraw()
	# auto-role from the command line (pass after "++"): "host" / "join".
	var ua := OS.get_cmdline_user_args()
	if ua.has("host"):
		_host()
	elif ua.has("join"):
		_join()
	for a in ua:
		if a.begins_with("lag"):
			_set_lag(maxi(int(a.substr(3)), 0))

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if _role == "none":
		if event.keycode == KEY_H:
			_host()
		elif event.keycode == KEY_J:
			_join()
	elif event.keycode == KEY_L:
		# cycle the simulated one-way delay, synced to the other window
		var i := LAG_STEPS.find(_lag_ms)
		var nxt: int = LAG_STEPS[(i + 1) % LAG_STEPS.size()]
		_set_lag(nxt)
		if multiplayer.multiplayer_peer and not multiplayer.get_peers().is_empty():
			_recv_set_lag.rpc(nxt)

func _host() -> void:
	_peer = ENetMultiplayerPeer.new()
	var err := _peer.create_server(PORT, 1)     # exactly one guest
	if err != OK:
		_set_status("HOST FAILED (err %d)" % err)
		return
	multiplayer.multiplayer_peer = _peer
	_role = "host"
	_set_status("waiting for the guest... (press J in the other window)")

func _join() -> void:
	_peer = ENetMultiplayerPeer.new()
	var err := _peer.create_client("127.0.0.1", PORT)
	if err != OK:
		_set_status("JOIN FAILED (err %d)" % err)
		return
	multiplayer.multiplayer_peer = _peer
	_role = "client"
	_set_status("connecting...")

func _on_peer_connected(_id: int) -> void:
	if _role == "host" and _host_f == null:
		_spawn_fighters()

func _on_connected_to_server() -> void:
	if _host_f == null:
		_spawn_fighters()

# Same layout in both windows: host fighter = orange, left, faces right.
# Guest fighter = blue, right, faces left.
func _spawn_fighters() -> void:
	var center := get_viewport_rect().size * 0.5
	_host_f = _make_fighter(true, center)
	_guest_f = _make_fighter(false, center)
	_state = "fighting"
	_score_h = 0
	_score_g = 0
	_score_label.visible = true
	_update_score()
	print("NET FIGHT: fighters spawned (role=%s)" % _role)
	_set_status()

func _make_fighter(host_side: bool, center: Vector2) -> Node2D:
	var f := FighterScript.new()
	f.game = self
	f.fighter_name = "HOST" if host_side else "GUEST"
	f.display_name = f.fighter_name
	f.body_color = Color(0.95, 0.55, 0.20) if host_side else Color(0.35, 0.65, 0.95)
	# rusher-like stats, greybox (no art)
	f.max_hp = 120
	f.speed = 325.0
	f.damage = 18
	f.attack_cooldown = 0.26
	f.skill_type = "lunge"
	f.position = center + Vector2(-SPAWN_GAP if host_side else SPAWN_GAP, 0.0)
	f.facing = Vector2.RIGHT if host_side else Vector2.LEFT
	if _role == "host":
		if host_side:
			# my fighter: the game's real key scheme
			f.key_up = KEY_UP
			f.key_down = KEY_DOWN
			f.key_left = KEY_LEFT
			f.key_right = KEY_RIGHT
			f.key_attack = KEY_S
			f.key_dash = KEY_SHIFT
			f.key_skill = KEY_R
			f.key_ranged = KEY_D
			f.key_defense = KEY_SPACE
			f.key_booster = KEY_A
		else:
			f.remote_driven = true    # the guest's inputs drive it over the network
	else:
		# guest window: BOTH fighters are puppets - the host simulates, we render
		f.is_bot = true
		f.passive = true
	add_child(f)
	if _role != "host":
		# no local damage on the guest - the host is the only referee
		f._hurtbox.monitorable = false
	_fighters.append(f)
	return f

# ---- slice 4: latency injector (receive-side delay queue) ----

func _set_lag(v: int) -> void:
	_lag_ms = v
	print("[lag] one-way %d ms (round-trip %d)" % [v, v * 2])
	_set_status()

@rpc("any_peer", "call_remote", "reliable")
func _recv_set_lag(v: int) -> void:
	_set_lag(v)

func _lag_or_apply(kind: String, args: Array) -> void:
	if _lag_ms <= 0:
		_apply_msg(kind, args)
	else:
		_lag_queue.append({"at": Time.get_ticks_msec() + _lag_ms, "kind": kind, "args": args})

func _drain_lag_queue() -> void:
	var now := Time.get_ticks_msec()
	while not _lag_queue.is_empty() and _lag_queue[0]["at"] <= now:
		var m: Dictionary = _lag_queue.pop_front()
		_apply_msg(m["kind"], m["args"])

func _apply_msg(kind: String, args: Array) -> void:
	if _host_f == null:
		return              # torn down while the message was in flight
	match kind:
		"state":
			_apply_state(_host_f, args[0], _guest_f)
			_apply_state(_guest_f, args[1], _host_f)
			_projectiles = []
			for p in args[2]:
				_projectiles.append({"pos": p[0], "vel": p[1], "col": p[2]})
		"held":
			_guest_f.remote_intent["dir"] = args[0]
			_guest_f.remote_intent["block"] = args[1]
			_guest_f.remote_intent["booster"] = args[2]
		"press":
			_guest_f.remote_intent[args[0]] = true
		"round_over":
			_apply_round_over(args[0], args[1], args[2], args[3])
		"round_start":
			_apply_round_start(args[0], args[1])

func _teardown(msg: String) -> void:
	_role = "none"
	_state = "waiting"
	_lag_queue.clear()
	multiplayer.multiplayer_peer = null
	for f in _fighters:
		f.queue_free()
	_fighters = []
	_host_f = null
	_guest_f = null
	_projectiles = []
	_banner.visible = false
	_score_label.visible = false
	Engine.time_scale = 1.0
	_set_status(msg)

func _process(delta: float) -> void:
	_drain_lag_queue()
	# screen shake (same as game.gd)
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

	# HOST: full projectile sim including hits (game.gd logic - damage is real here)
	if _role == "host" and not _projectiles.is_empty():
		for p in _projectiles:
			p["pos"] += p["vel"] * delta
			p["life"] -= delta
			for f in _fighters:
				if f == p["owner"] or not f.active:
					continue
				if p["pos"].distance_to(f.position) < PROJ_RADIUS + 16.0:
					f.take_hit(p["vel"].normalized(), PROJ_DAMAGE, PROJ_KNOCK)
					spawn_sparks(p["pos"], p["vel"], 6, p["col"])
					p["life"] = 0.0
					break
		_projectiles = _projectiles.filter(func(p): return p["life"] > 0.0)
		queue_redraw()
	elif _role == "client" and not _projectiles.is_empty():
		queue_redraw()

	if _host_f == null or multiplayer.multiplayer_peer == null or multiplayer.get_peers().is_empty():
		return

	if _role == "host":
		# broadcast the whole authoritative picture every frame
		_recv_state.rpc(_pack(_host_f), _pack(_guest_f), _pack_projectiles())
	else:
		# guest: read my keys, send INTENT to the referee
		var dir := Vector2.ZERO
		if Input.is_physical_key_pressed(KEY_UP): dir.y -= 1.0
		if Input.is_physical_key_pressed(KEY_DOWN): dir.y += 1.0
		if Input.is_physical_key_pressed(KEY_LEFT): dir.x -= 1.0
		if Input.is_physical_key_pressed(KEY_RIGHT): dir.x += 1.0
		var block := Input.is_physical_key_pressed(KEY_SPACE)
		var booster := Input.is_physical_key_pressed(KEY_A)
		_recv_held.rpc_id(1, dir, block, booster)
		var a := Input.is_physical_key_pressed(KEY_S)
		if a and not _prev_attack:
			_recv_press.rpc_id(1, "attack")
		_prev_attack = a
		var sk := Input.is_physical_key_pressed(KEY_R)
		if sk and not _prev_skill:
			_recv_press.rpc_id(1, "skill")
		_prev_skill = sk
		var rg := Input.is_physical_key_pressed(KEY_D)
		if rg and not _prev_ranged:
			_recv_press.rpc_id(1, "ranged")
		_prev_ranged = rg

# ---- wire format ----

func _pack(f: Node2D) -> Array:
	var anim := ANIM_IDLE
	var t := 0.0
	if f._winding:
		anim = ANIM_WINDUP
		t = f._windup_time
	elif f._attacking:
		anim = ANIM_ATTACK
		t = f._attack_time
	elif f._pose == "hit":
		anim = ANIM_HIT
		t = f._pose_time
	elif f._pose == "parry":
		anim = ANIM_PARRY
		t = f._pose_time
	elif f._blocking:
		anim = ANIM_BLOCK
		t = f._block_time
	return [f.position, f.facing, f._move_vel, anim, t, f.hp, f.active]

func _pack_projectiles() -> Array:
	var out := []
	for p in _projectiles:
		out.append([p["pos"], p["vel"], p["col"]])
	return out

# guest <- host: the authoritative state, every frame
@rpc("authority", "call_remote", "unreliable")
func _recv_state(hf: Array, gf: Array, projs: Array) -> void:
	if _role != "client" or _host_f == null:
		return
	_lag_or_apply("state", [hf, gf, projs])

func _apply_state(f: Node2D, arr: Array, other: Node2D) -> void:
	f.position = arr[0]
	f.facing = arr[1]
	f._move_vel = arr[2]
	var anim: int = arr[3]
	var t: float = arr[4]
	f._winding = anim == ANIM_WINDUP
	if anim == ANIM_WINDUP:
		f._windup_time = t
	f._attacking = anim == ANIM_ATTACK
	if anim == ANIM_ATTACK:
		f._attack_time = t
	f._blocking = anim == ANIM_BLOCK
	f._block_time = t if anim == ANIM_BLOCK else 0.0
	if anim == ANIM_HIT:
		f._pose = "hit"
		f._pose_time = t
		f._pose_max = FighterScript.POSE_HIT_TIME
	elif anim == ANIM_PARRY:
		if f._pose != "parry":
			# parry pop just landed - local juice for it
			spawn_sparks(f.position + f.facing * FighterScript.REACH, -f.facing, 10, Color(0.7, 0.95, 1.0))
			add_shake(4.0)
		f._pose = "parry"
		f._pose_time = t
		f._pose_max = FighterScript.POSE_PARRY_TIME
	# HP / KO - juice is DERIVED from the state, not sent
	var new_hp: int = arr[5]
	var new_active: bool = arr[6]
	if new_hp < f.hp:
		var dir: Vector2 = (f.position - other.position).normalized() if other else Vector2.RIGHT
		f._pose_dir = dir
		f._flash = FighterScript.FLASH_TIME
		spawn_sparks(f.position, dir, 9, Color(1.0, 0.9, 0.55))
		add_shake(7.0)
	if f.active and not new_active and new_hp <= 0:
		spawn_burst(f.position, 24, f.body_color.lerp(Color(1, 1, 1), 0.5))
		add_shake(14.0)
	f.hp = new_hp
	f.active = new_active
	f._update_hitbox_position()
	f.queue_redraw()

# host <- guest: held inputs, every frame
@rpc("any_peer", "call_remote", "unreliable")
func _recv_held(dir: Vector2, block: bool, booster: bool) -> void:
	if _role == "host" and _guest_f:
		var d := dir.normalized() if dir.length() > 1.0 else dir
		_lag_or_apply("held", [d, block, booster])

# host <- guest: one-shot presses (reliable so none get lost)
@rpc("any_peer", "call_remote", "reliable")
func _recv_press(kind: String) -> void:
	if _role == "host" and _guest_f and kind in ["attack", "skill", "ranged"]:
		_lag_or_apply("press", [kind])

# ---- round flow (host = referee; guest mirrors via reliable events) ----

func on_ko(loser) -> void:
	if _role != "host" or _state != "fighting":
		return
	_state = "round_over"
	_host_f.active = false
	_guest_f.active = false
	var winner: Node2D = _guest_f if loser == _host_f else _host_f
	if winner == _host_f:
		_score_h += 1
	else:
		_score_g += 1
	var wscore: int = _score_h if winner == _host_f else _score_g
	var match_over := wscore >= WINS_NEEDED
	var text := ("%s WINS THE MATCH!" % winner.fighter_name) if match_over \
		else ("%s wins the round" % winner.fighter_name)
	_show_round_over(text, winner.body_color)
	_recv_round_over.rpc(text, winner.body_color, _score_h, _score_g)
	var t := get_tree().create_timer(3.0 if match_over else 1.6)
	await t.timeout
	if _state != "round_over":
		return              # peer left mid-wait
	if match_over:
		_score_h = 0
		_score_g = 0
	var center := get_viewport_rect().size * 0.5
	_host_f.reset_fighter(center + Vector2(-SPAWN_GAP, 0.0))
	_guest_f.reset_fighter(center + Vector2(SPAWN_GAP, 0.0))
	_host_f.facing = Vector2.RIGHT
	_guest_f.facing = Vector2.LEFT
	_state = "fighting"
	_banner.visible = false
	_update_score()
	_recv_round_start.rpc(_score_h, _score_g)

@rpc("authority", "call_remote", "reliable")
func _recv_round_over(text: String, col: Color, sh: int, sg: int) -> void:
	_lag_or_apply("round_over", [text, col, sh, sg])

func _apply_round_over(text: String, col: Color, sh: int, sg: int) -> void:
	_score_h = sh
	_score_g = sg
	_state = "round_over"
	_show_round_over(text, col)

@rpc("authority", "call_remote", "reliable")
func _recv_round_start(sh: int, sg: int) -> void:
	_lag_or_apply("round_start", [sh, sg])

func _apply_round_start(sh: int, sg: int) -> void:
	_score_h = sh
	_score_g = sg
	_state = "fighting"
	_banner.visible = false
	_update_score()

func _show_round_over(text: String, col: Color) -> void:
	_banner.text = text
	_banner.add_theme_color_override("font_color", col)
	_banner.visible = true
	_update_score()

func _update_score() -> void:
	if _score_label:
		_score_label.text = "HOST   %d  -  %d   GUEST      (first to %d)" % [_score_h, _score_g, WINS_NEEDED]

# ---- the "game" services fighter.gd expects (host runs the real fight) ----

func clamp_to_arena(pos: Vector2) -> Vector2:
	var vp := get_viewport_rect().size
	return Vector2(
		clampf(pos.x, ARENA_MARGIN, vp.x - ARENA_MARGIN),
		clampf(pos.y, ARENA_MARGIN, vp.y - ARENA_MARGIN))

func add_shake(amount: float) -> void:
	_shake = maxf(_shake, amount)

func spawn_sparks(pos: Vector2, dir: Vector2, count: int, color: Color) -> void:
	var base := dir.angle() if dir.length() > 0.01 else 0.0
	for i in range(count):
		var ang := base + randf_range(-0.8, 0.8)
		var spd := randf_range(120.0, 340.0)
		_sparks.append({"pos": pos, "vel": Vector2(cos(ang), sin(ang)) * spd, "life": 0.28, "max": 0.28, "col": color})

func spawn_burst(pos: Vector2, count: int, color: Color) -> void:
	for i in range(count):
		var ang := randf_range(0.0, TAU)
		var spd := randf_range(160.0, 470.0)
		_sparks.append({"pos": pos, "vel": Vector2(cos(ang), sin(ang)) * spd, "life": 0.45, "max": 0.45, "col": color})

func spawn_projectile(pos: Vector2, dir: Vector2, owner) -> void:
	# only the referee spawns real projectiles (guest fighters never act locally)
	var d := dir.normalized() if dir.length() > 0.01 else Vector2.RIGHT
	_projectiles.append({"pos": pos + d * 26.0, "vel": d * PROJ_SPEED, "owner": owner, "life": PROJ_LIFE, "col": owner.body_color})

# real hit-stop on the host - the guest inherits the freeze through the state stream
func hit_stop(duration: float) -> void:
	Engine.time_scale = 0.0
	var t := get_tree().create_timer(duration, true, false, true)  # ignore_time_scale
	await t.timeout
	Engine.time_scale = 1.0

func apply_chill(_origin: Vector2, _radius: float, _duration: float, _caster) -> void:
	pass    # no chill caster in this scene (both fighters are rusher-like)

func apply_shockwave(_origin: Vector2, _radius: float, _knock: float, _dmg: int, _caster) -> void:
	pass    # no shockwave caster in this scene

# ---- UI ----

func _set_status(extra := "") -> void:
	if not _status:
		return
	if _role == "none":
		_status.text = "NET FIGHT - slice 4: latency test (host = referee)\n[H] Host    [J] Join localhost\nOpen TWO windows: one Host, one Join."
	else:
		var peers := multiplayer.get_peers().size() if multiplayer.multiplayer_peer else 0
		_status.text = "role: %s   peers: %d\nArrows steer · A run · S melee · D ranged · R lunge · Space block\nSLICE 4 - LAG: one-way %d ms (round-trip %d)   [L] cycles 0/30/60/100" % [_role, peers, _lag_ms, _lag_ms * 2]
	if extra != "":
		_status.text += "\n" + extra

func _draw() -> void:
	var vp := get_viewport_rect().size
	var rect := Rect2(Vector2(ARENA_MARGIN, ARENA_MARGIN), vp - Vector2(ARENA_MARGIN, ARENA_MARGIN) * 2.0)
	draw_rect(rect, Color(0.15, 0.17, 0.22), true)
	draw_rect(rect, Color(0.35, 0.40, 0.48), false, 2.0)

	for s in _sparks:
		var a := clampf(s["life"] / s["max"], 0.0, 1.0)
		var c: Color = s["col"]
		c.a = a
		var p: Vector2 = s["pos"]
		draw_line(p, p - s["vel"].normalized() * (4.0 + 7.0 * a), c, 2.0)

	for pr in _projectiles:
		var pp: Vector2 = pr["pos"]
		var pc: Color = pr["col"]
		draw_line(pp, pp - pr["vel"].normalized() * 14.0, Color(pc.r, pc.g, pc.b, 0.5), 3.0)
		draw_circle(pp, 5.0, pc)
