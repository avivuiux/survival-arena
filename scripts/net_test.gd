extends Node2D
# =============================================================
#  NET TEST - PROTOTYPE, THROWAWAY (see NET.md slice 1).
#  Proves the pipe ONLY: two Godot instances connect over ENet
#  (localhost) and see each other's square move in real time.
#  NOT the game, NOT the final authority model. Client-authoritative
#  position broadcast = the cheapest thing that answers "does the
#  pipe work?" Do NOT grow this into production - rewrite (NET.md).
# =============================================================

const PORT := 8910
const SIZE := 34.0
const SPEED := 320.0

var _peer: ENetMultiplayerPeer
var _role := "none"              # "host" | "client" | "none"
var _my_pos := Vector2(200, 200)
var _peers := {}                 # remote id -> Vector2 (their square)
var _status: Label

func _ready() -> void:
	_my_pos = get_viewport_rect().size * 0.5
	var ui := CanvasLayer.new()
	add_child(ui)
	_status = Label.new()
	_status.position = Vector2(16, 12)
	_status.add_theme_font_size_override("font_size", 18)
	ui.add_child(_status)
	multiplayer.peer_connected.connect(func(_id): _set_status())
	multiplayer.peer_disconnected.connect(func(id): _peers.erase(id); _set_status())
	multiplayer.connected_to_server.connect(func(): _set_status("connected"))
	multiplayer.connection_failed.connect(func(): _role = "none"; _set_status("CONNECTION FAILED"))
	multiplayer.server_disconnected.connect(func(): _role = "none"; _peers.clear(); _set_status("SERVER LEFT"))
	_set_status()
	queue_redraw()

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if _role == "none":
		if event.keycode == KEY_H:
			_host()
		elif event.keycode == KEY_J:
			_join()

func _host() -> void:
	_peer = ENetMultiplayerPeer.new()
	var err := _peer.create_server(PORT, 8)
	if err != OK:
		_set_status("HOST FAILED (err %d)" % err)
		return
	multiplayer.multiplayer_peer = _peer
	_role = "host"
	_set_status()

func _join() -> void:
	_peer = ENetMultiplayerPeer.new()
	var err := _peer.create_client("127.0.0.1", PORT)
	if err != OK:
		_set_status("JOIN FAILED (err %d)" % err)
		return
	multiplayer.multiplayer_peer = _peer
	_role = "client"
	_set_status("connecting...")

func _process(delta: float) -> void:
	if _role == "none":
		return
	var dir := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_UP) or Input.is_physical_key_pressed(KEY_W): dir.y -= 1.0
	if Input.is_physical_key_pressed(KEY_DOWN) or Input.is_physical_key_pressed(KEY_S): dir.y += 1.0
	if Input.is_physical_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_A): dir.x -= 1.0
	if Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_physical_key_pressed(KEY_D): dir.x += 1.0
	if dir != Vector2.ZERO:
		_my_pos += dir.normalized() * SPEED * delta
		var vp := get_viewport_rect().size
		_my_pos.x = clampf(_my_pos.x, SIZE, vp.x - SIZE)
		_my_pos.y = clampf(_my_pos.y, SIZE, vp.y - SIZE)
	# Broadcast my position to every other peer (client-authoritative, prototype only).
	if multiplayer.multiplayer_peer and not multiplayer.get_peers().is_empty():
		_recv_pos.rpc(_my_pos)
	queue_redraw()

@rpc("any_peer", "call_remote", "unreliable")
func _recv_pos(pos: Vector2) -> void:
	_peers[multiplayer.get_remote_sender_id()] = pos

func _my_id() -> int:
	return multiplayer.get_unique_id() if multiplayer.multiplayer_peer else 0

func _color_for(id: int) -> Color:
	return Color.from_hsv(float(abs(id * 47) % 360) / 360.0, 0.6, 0.95)

func _set_status(extra := "") -> void:
	if not _status:
		return
	if _role == "none":
		_status.text = "NET TEST (prototype)\n[H] Host    [J] Join localhost\nOpen TWO windows: one Host, one Join."
	else:
		_status.text = "role: %s   my id: %d   peers: %d\nMove: arrows / WASD" % [
			_role, _my_id(), multiplayer.get_peers().size()]
		if extra != "":
			_status.text += "\n" + extra

func _draw() -> void:
	var vp := get_viewport_rect().size
	draw_rect(Rect2(Vector2(8, 8), vp - Vector2(16, 16)), Color(0.13, 0.15, 0.20), true)
	draw_rect(Rect2(Vector2(8, 8), vp - Vector2(16, 16)), Color(0.30, 0.34, 0.42), false, 2.0)
	# remote squares
	for id in _peers:
		var p: Vector2 = _peers[id]
		draw_rect(Rect2(p - Vector2(SIZE, SIZE) / 2.0, Vector2(SIZE, SIZE)), _color_for(id))
		draw_rect(Rect2(p - Vector2(SIZE, SIZE) / 2.0, Vector2(SIZE, SIZE)), Color(1, 1, 1, 0.8), false, 2.0)
	# my square (yellow outline = "that's me")
	if _role != "none":
		draw_rect(Rect2(_my_pos - Vector2(SIZE, SIZE) / 2.0, Vector2(SIZE, SIZE)), _color_for(_my_id()))
		draw_rect(Rect2(_my_pos - Vector2(SIZE, SIZE) / 2.0, Vector2(SIZE, SIZE)), Color(1, 1, 0.4), false, 3.0)
