# THROWAWAY (concept chat) - captures FANG in the real arena for art reference.
# Run:  Godot ... --path <repo> -s res://concept/_tmp_capture.gd
# Deleted after use. Not part of the game.
extends SceneTree

var _frames := 0
var _game: Node

func _initialize() -> void:
	var scene = load("res://scenes/game.tscn").instantiate()
	root.add_child(scene)
	_game = scene

func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 10:
		var keys: Array = _game._arch_keys
		_game._sel_index = keys.find("rusher")
		_game._begin_match()
		_game._p2.passive = true   # freeze the bot for a clean reference shot
		# runtime-only art override: test the NEW in-game sprite without touching game.gd
		var img := Image.load_from_file(ProjectSettings.globalize_path("res://concept/characters/fang/FANG_arena_v1.png"))
		_game._p1._art_tex = ImageTexture.create_from_image(img)
	if _frames == 70:
		var img: Image = root.get_texture().get_image()
		var err := img.save_png("res://concept/characters/fang/fang_arena_v1_ingame.png")
		print("CAPTURE saved, err=", err)
	if _frames >= 75:
		quit()
	return false
