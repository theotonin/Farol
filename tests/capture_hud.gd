extends SceneTree
## Final HUD review in the reference and minimum window sizes.

var game
var failures := 0

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.save_path = "user://hud_capture.json"
	game.sound.set_muted(true)
	game.start_new_game()
	game.begin_play()
	game.set_physics_process(false)
	game.player.set_enabled(false)
	game.enemies_node.process_mode = Node.PROCESS_MODE_DISABLED
	game.state.time_of_day = 100.0
	game.state.repair_stage = 1
	game.state.bag = {"wood": 4, "stone": 3, "scrap": 2, "part": 1, "food": 2}
	game.state.fuel = 80.0
	game.ui.toast_timer = 0.0
	await shot("day")
	game.ui.show_pickup("wood")
	await shot("pickup")
	game.state.time_of_day = 270.0
	game.state.health = 28.0
	game.state.stamina = 47.0
	game.state.repair_stage = 2
	game.state.bag = {"wood": 8, "stone": 4, "scrap": 4, "part": 2, "food": 2}
	await shot("night")
	game.ui.toggle_shelter()
	game.ui.toast("Materiais guardados. O depósito permanece após a morte.")
	await shot("shelter")
	root.size = Vector2i(960, 540)
	await shot("shelter-small")
	game.ui.shelter.hide()
	game.ui.toast_timer = 0.0
	await shot("small")
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	if FileAccess.file_exists("user://hud_capture.json"):
		DirAccess.remove_absolute("user://hud_capture.json")
	quit(0 if failures == 0 else 1)

func shot(label: String) -> void:
	game.update_view()
	if label == "pickup":
		game.ui.update_hud(game.state, 100.0, "E  ·  Coletar madeira", false)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png("/tmp/o-farol-hud-%s.png" % label)
	if result != OK:
		failures += 1
	print("HUD ", label, ": ", error_string(result))
