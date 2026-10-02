extends SceneTree

var failures := 0

func check(value: bool, message: String) -> void:
	if not value:
		push_error(message)
		failures += 1

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.save_path = "user://audio_test.json"
	check(game.sound.has_method("update_soundscape"), "Audio must follow the expedition state")
	if not game.sound.has_method("update_soundscape"):
		game.queue_free()
		await process_frame
		quit(1)
		return
	game.update_view()
	check(game.sound.music_theme == "day", "Menu should use the exploration theme")
	game.start_new_game()
	game.begin_play()
	game.state.time_of_day = 100.0
	game.update_view()
	check(game.sound.music_theme == "day", "Daytime exploration should select calm music")
	game.state.time_of_day = 270.0
	game.update_view()
	check(game.sound.music_theme == "night", "Nightfall should select tense music")
	game.pause_game()
	game.update_view()
	check(game.sound.music_theme == "night", "Pause should preserve the current theme")
	game.mode = "rescue"
	game.update_view()
	check(game.sound.music_theme == "rescue", "Rescue should select hopeful music")
	game.handle_action("mute", "")
	check(game.sound.muted, "Existing toggle must mute music and effects")
	if DisplayServer.get_name() != "headless":
		for player in game.sound._music:
			check(player.stream_paused, "Mute must pause every music player")
		check(game.sound._ocean.stream_paused and game.sound._campfire.stream_paused, "Mute must pause both ambience loops")
	game.handle_action("mute", "")
	check(not game.sound.muted and game.sound.music_theme == "rescue", "Unmute should retain the correct theme")
	if DisplayServer.get_name() != "headless":
		check(not game.sound._ocean.stream_paused, "Unmute must resume ambience")
		game.sound.update_soundscape("playing", true, 0.0, true)
		check(game.sound._campfire.volume_db > -30.0, "A nearby lit campfire should be audible")
		game.sound.update_soundscape("playing", true, 400.0, true)
		check(game.sound._campfire.volume_db <= -80.0, "Distant campfire must fade out")
		await create_timer(2.7).timeout
		check(game.sound._music[game.sound._active_music].playing, "Selected music must keep playing after crossfade")
		check(not game.sound._music[1 - game.sound._active_music].playing, "Previous music must stop after crossfade")
	for theme in ["day", "night", "rescue", "ocean", "campfire"]:
		var stream = load("res://assets/audio/%s.wav" % theme)
		check(stream is AudioStreamWAV and stream.get_length() >= 8.0, "Audio loop must load: " + theme)
		var loop = game.sound._loop_stream(theme)
		check(loop.loop_end == (705600 if theme in ["day", "night", "rescue"] else 253575), "Loop must cover the entire track, including compressed imports: " + theme)
	for cue in ["step", "swing", "click", "collect", "hit", "hurt", "repair"]:
		check(game.sound._synthesize(cue) is AudioStreamWAV, "Effect must exist: " + cue)
	game.sound.set_muted(true)
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	if FileAccess.file_exists("user://audio_test.json"):
		DirAccess.remove_absolute("user://audio_test.json")
	print("Soundscape: ", failures, " failures")
	quit(0 if failures == 0 else 1)
