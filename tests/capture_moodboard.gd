extends SceneTree
## Run on a graphical display; screenshots go directly into res://Moodboard/.

var game
var failures := 0

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://Moodboard"))
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.save_path = "user://moodboard_capture.json"
	game.sound.set_muted(true)
	game.start_new_game()
	game.state.world_seed = 103
	game.island.distribute_resources(103)
	game.begin_play()
	game.set_physics_process(false)
	game.player.set_enabled(false)
	game.enemies_node.process_mode = Node.PROCESS_MODE_DISABLED
	game.state.time_of_day = 100.0
	game.state.fuel = 100.0
	game.ui.toast_label.hide()
	game.ui.hud.hide()
	game.ui.shelter.hide()
	await shot("01-farol-e-abrigo", Vector2(0, 80), 1.5)
	await shot("02-ruinas-na-floresta", Vector2(-845, -235), 1.5)
	await shot("03-praia-e-oceano", Vector2(180, 900), 1.2)
	game.state.time_of_day = 270.0
	await shot("04-luz-na-noite", Vector2(25, 80), 1.5)
	game.spawn_enemies(true)
	var enemy = game.enemies_node.get_child(0)
	enemy.global_position = Vector2(295, 170)
	game.player.global_position = Vector2(260, 170)
	game.player.face_movement(Vector2.RIGHT)
	game.player._request_attack()
	await shot("05-sobrevivencia", Vector2(250, 135), 2.0)
	game.state.repair_stage = 3
	game.state.won = true
	game.mode = "rescue"
	game.rescue_time = 4.0
	game._update_rescue_visuals()
	await shot("06-resgate", Vector2(180, 0), 0.36)
	game.state.time_of_day = 100.0
	game.mode = "playing"
	game.state.won = false
	game.rescue_visuals.hide()
	await shot("07-ilha", Vector2.ZERO, 0.27)
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	if FileAccess.file_exists("user://moodboard_capture.json"):
		DirAccess.remove_absolute("user://moodboard_capture.json")
	quit(0 if failures == 0 else 1)

func shot(label: String, center: Vector2, zoom: float) -> void:
	game.player.global_position = center + Vector2(0, 65) if label not in ["05-sobrevivencia", "06-resgate", "07-ilha"] else game.player.global_position
	game.camera.zoom = Vector2.ONE * zoom
	game.camera.position = center
	game.camera.reset_smoothing()
	game.update_view()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	var result := picture.save_png("res://Moodboard/%s.png" % label)
	if result != OK:
		failures += 1
	print("Moodboard ", label, ": ", error_string(result))
