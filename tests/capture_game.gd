extends SceneTree
## Verificação visual local; execute com um display gráfico (não --headless).

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.save_path = "user://visual_check.json"
	await shot("menu")
	game.start_new_game()
	await shot("intro")
	game.begin_play()
	await shot("day")
	game.pause_game()
	await shot("paused")
	game.handle_action("resume", "")
	game.ui.toggle_shelter()
	await shot("shelter")
	game.ui.shelter.hide()
	game.state.time_of_day = 270.0
	game.state.fuel = 80.0
	game.spawn_enemies(true)
	game.update_view()
	await shot("night")
	var combat_enemy: Enemy = game.enemies_node.get_child(0) as Enemy
	combat_enemy.set_physics_process(false)
	combat_enemy.global_position = game.player.global_position + Vector2(44, 0)
	game.player.set_physics_process(false)
	game.player.face_movement(Vector2.RIGHT)
	await physics_frame
	game.player._request_attack()
	game.update_view()
	await shot("combat")
	game.state.repair_stage = 3
	game.state.won = true
	game.mode = "rescue"
	game.rescue_time = 4.0
	game.camera.zoom = Vector2(0.36, 0.36)
	game.camera.position = Vector2(180, 0)
	game.camera.reset_smoothing()
	await shot("rescue")
	game.mode = "victory"
	game.ui.show_victory(4)
	await shot("victory")
	game.sound.set_muted(true)
	game.queue_free()
	await create_timer(0.2).timeout
	if FileAccess.file_exists("user://visual_check.json"):
		DirAccess.remove_absolute("user://visual_check.json")
	quit()

func shot(label: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	var result := picture.save_png("/tmp/o-farol-%s.png" % label)
	print("Captura ", label, ": ", result)
