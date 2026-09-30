extends SceneTree

var failures := 0


func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)


func _initialize() -> void:
	call_deferred("run")


func drive_probe(probe: CharacterBody2D, start: Vector2, motion: Vector2, steps: int = 80) -> KinematicCollision2D:
	probe.global_position = start
	for step in steps:
		var collision := probe.move_and_collide(motion)
		if collision != null:
			return collision
	return null


func resource_has_reachable_spot(island: Node2D, pickup: Node2D) -> bool:
	var query_shape := CircleShape2D.new()
	query_shape.radius = 8.0
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = query_shape
	query.collision_mask = 1
	query.collide_with_areas = false
	query.collide_with_bodies = true
	for radius: float in [0.0, 20.0, 40.0, 60.0]:
		for direction_index in 16:
			var candidate := pickup.global_position + Vector2.from_angle(TAU * direction_index / 16.0) * radius
			if not island.is_walkable(candidate):
				continue
			query.transform = Transform2D(0.0, candidate)
			if island.get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty():
				return true
	return false


func run() -> void:
	var island_scene := load("res://scenes/world/island.tscn") as PackedScene
	check(island_scene != null, "A cena da ilha deve existir e carregar")
	if island_scene == null:
		quit(1)
		return

	var island := island_scene.instantiate()
	var serialized_ground := island.get_node("Ground") as TileMapLayer
	var serialized_cells: Array[Vector2i] = serialized_ground.get_used_cells()
	check(serialized_cells.size() >= 6900, "Ground deve trazer aproximadamente 6956 células serializadas antes de _ready")
	var serialized_path_count := 0
	for cell: Vector2i in serialized_cells:
		var atlas_coords := serialized_ground.get_cell_atlas_coords(cell)
		if atlas_coords.y == 1 and atlas_coords.x >= 4:
			serialized_path_count += 1
	check(serialized_path_count > 50, "Ground serializado deve incluir os caminhos de terra")

	var sentinel_cell := Vector2i.ZERO
	var sentinel_source := -1
	var sentinel_atlas := Vector2i(-1, -1)
	var sentinel_alternative := 0
	if not serialized_cells.is_empty():
		sentinel_cell = serialized_cells[0]
		sentinel_source = serialized_ground.get_cell_source_id(sentinel_cell)
		sentinel_atlas = serialized_ground.get_cell_atlas_coords(sentinel_cell)
		sentinel_alternative = serialized_ground.get_cell_alternative_tile(sentinel_cell)
		serialized_ground.erase_cell(sentinel_cell)
	root.add_child(island)
	await physics_frame
	if sentinel_source >= 0:
		check(serialized_ground.get_cell_source_id(sentinel_cell) == -1, "_ready não deve limpar nem reconstruir o Ground serializado")
		serialized_ground.set_cell(sentinel_cell, sentinel_source, sentinel_atlas, sentinel_alternative)

	check(island.get_node("Ground") is TileMapLayer, "O chão deve ser TileMapLayer")
	check(island.get_node("CoastCollision") is StaticBody2D, "A costa deve ser física")
	var lighthouse := island.get_node("Structures/Lighthouse") as StaticBody2D
	var lighthouse_sprite := lighthouse.get_node("Sprite") as Sprite2D
	var lighthouse_body := lighthouse.get_node("BodyCollision") as CollisionShape2D
	check(lighthouse_sprite.scale.is_equal_approx(Vector2(3.0, 3.0)), "Farol deve ter escala visual 3x em relação ao atlas pixel art")
	check(absf(lighthouse_sprite.position.y) <= 1.0, "Sprite ampliado do farol deve permanecer centralizado no nó da construção")
	check(lighthouse_body.position.y >= 80.0 and lighthouse_body.position.y <= 120.0, "Hitbox deve acompanhar visualmente a base inferior do farol")
	check((lighthouse_body.shape as RectangleShape2D).size.x >= 120.0, "A base física do farol ampliado deve acompanhar sua largura visual")
	var resource_nodes: Array[Node] = island.get_resource_nodes()
	check(island.get_node("Resources").get_child_count() > 0, "Resources deve conter os pickups físicos da Task 4")
	check(not resource_nodes.is_empty(), "get_resource_nodes deve expor os pickups físicos")
	var resource_ids := {}
	var part_count := 0
	for pickup: Node in resource_nodes:
		check(pickup is Area2D, "%s deve ser Area2D atravessável" % pickup.name)
		check(pickup.is_in_group("resources"), "%s deve estar no grupo resources" % pickup.name)
		check(pickup.collision_layer == 4, "%s deve estar na camada interaction" % pickup.name)
		check(pickup.collision_mask == 2, "%s deve detectar actors" % pickup.name)
		check(not resource_ids.has(pickup.resource_id), "ID de recurso deve ser único: " + pickup.resource_id)
		resource_ids[pickup.resource_id] = true
		if pickup.kind == "part":
			part_count += 1
	check(part_count == 3, "A ilha deve conter exatamente três peças raras")
	check(island.spawn_position == Vector2(0, 180), "O spawn deve permanecer abaixo da base ampliada do farol")
	check(island.is_walkable(Vector2(0, 180)), "O spawn reposicionado deve ser caminhável")
	check(not island.is_walkable(Vector2(0, 1250)), "O mar além da costa não deve ser caminhável")

	var ground := island.get_node("Ground") as TileMapLayer
	var used_rect := ground.get_used_rect()
	check(used_rect.position.x * 32 <= -1430, "O mapa deve alcançar aproximadamente x=-1430")
	check(used_rect.end.x * 32 >= 1430, "O mapa deve alcançar aproximadamente x=1430")
	check(used_rect.position.y * 32 <= -1100, "O mapa deve alcançar aproximadamente y=-1100")
	check(used_rect.end.y * 32 >= 1100, "O mapa deve alcançar aproximadamente y=1100")

	var decorations := island.get_node("Decorations")
	check(decorations.get_child_count() > 0, "A ilha deve ter decorações")
	for decoration in decorations.find_children("*", "", true, false):
		check(not decoration is CollisionObject2D, "Decoração deve ser atravessável")
		if decoration is Sprite2D:
			var sprite := decoration as Sprite2D
			var integer_scale := (
				is_equal_approx(sprite.scale.x, roundf(sprite.scale.x))
				and is_equal_approx(sprite.scale.y, roundf(sprite.scale.y))
				and sprite.scale.x >= 1.0
				and sprite.scale.y >= 1.0
			)
			check(integer_scale, "%s deve usar escala inteira para preservar pixel art" % sprite.name)

	for structure_name: String in ["Lighthouse", "Storage", "RuinNW", "RuinNE", "RuinSE", "RuinSW"]:
		var structure := island.get_node("Structures/" + structure_name)
		check(structure is StaticBody2D, "%s deve bloquear" % structure_name)
		check(structure.is_in_group("structures"), "%s deve estar no grupo structures" % structure_name)
		check(structure.collision_layer == 1, "%s deve estar na camada world" % structure_name)
		check(structure.collision_mask == 2, "%s deve detectar actors" % structure_name)
		var interaction := structure.get_node("Interaction") as Area2D
		check(interaction != null, "%s deve ter área de interação" % structure_name)
		if interaction != null:
			check(interaction.collision_layer == 4, "%s deve interagir na camada interaction" % structure_name)
			check(interaction.collision_mask == 2, "%s deve detectar actors na interação" % structure_name)

	var campfire: Node = island.get_node("Structures/Campfire")
	check(campfire is Area2D, "Campfire deve ser Area2D atravessável")
	check(not (campfire is StaticBody2D), "Campfire não deve criar parede física")
	check(campfire.is_in_group("structures") and campfire.is_in_group("shelter"), "Campfire deve preservar grupos de interação")
	if campfire is Area2D:
		check((campfire.collision_layer & 1) == 0, "Campfire não deve ocupar a camada world")
		check(campfire.collision_layer == 4, "Campfire deve interagir na camada interaction")
		check(campfire.collision_mask == 2, "Campfire deve detectar actors")
	check(campfire.get_node_or_null("InteractionShape") is CollisionShape2D, "Campfire deve ter forma de interação sem colisão corporal")
	var fire_light := campfire.get_node_or_null("Light") as PointLight2D
	check(fire_light != null, "Campfire deve conter PointLight2D real")
	campfire.set_fuel(0.0, 1.0)
	if fire_light != null:
		check(not fire_light.visible and fire_light.energy == 0.0, "Luz deve apagar sem combustível")
	campfire.set_fuel(20.0, 1.0)
	if fire_light != null:
		check(fire_light.visible and fire_light.energy > 0.0, "Luz deve acender com combustível à noite")
		var night_energy: float = fire_light.energy
		campfire.set_fuel(20.0, 0.0)
		check(not fire_light.visible and fire_light.energy < night_energy, "Luz deve acompanhar a intensidade noturna")

	# O estado visual precisa ser seguro antes de os pickups da Task 4 existirem.
	island.set_visual_state({}, 3, 20.0, 1.0, true)
	check(island.get_node("Structures/Lighthouse").stage == 3, "Farol deve refletir o estágio visual")
	check(island.get_node("Structures/Campfire").fuel == 20.0, "Fogueira deve refletir o combustível")

	var query := PhysicsPointQueryParameters2D.new()
	query.position = Vector2(0, 1250)
	query.collision_mask = 1
	var hits: Array[Dictionary] = island.get_world_2d().direct_space_state.intersect_point(query)
	check(hits.any(func(hit: Dictionary) -> bool: return hit.collider == island.get_node("CoastCollision")), "O mar além do litoral deve colidir")

	var player_probe := (load("res://scenes/actors/player.tscn") as PackedScene).instantiate() as CharacterBody2D
	var enemy_probe := (load("res://scenes/actors/enemy.tscn") as PackedScene).instantiate() as CharacterBody2D
	root.add_child(player_probe)
	root.add_child(enemy_probe)
	player_probe.set_physics_process(false)
	enemy_probe.set_physics_process(false)
	await physics_frame

	var coast_cases := [
		["norte", Vector2(0, -980), Vector2.UP * 4.0],
		["leste", Vector2(1300, 0), Vector2.RIGHT * 4.0],
		["sul", Vector2(0, 1000), Vector2.DOWN * 4.0],
		["oeste", Vector2(-1300, 0), Vector2.LEFT * 4.0],
	]
	for coast_case: Array in coast_cases:
		for probe: CharacterBody2D in [player_probe, enemy_probe]:
			var coast_hit := drive_probe(probe, coast_case[1], coast_case[2])
			check(
				coast_hit != null and coast_hit.get_collider() == island.get_node("CoastCollision"),
				"%s deve ser bloqueado pela costa no lado %s" % [probe.name, coast_case[0]]
			)

	for structure_name: String in ["Lighthouse", "Storage", "RuinNW", "RuinNE", "RuinSE", "RuinSW"]:
		var structure := island.get_node("Structures/" + structure_name) as StaticBody2D
		var body_shape := structure.get_node("BodyCollision") as CollisionShape2D
		for probe: CharacterBody2D in [player_probe, enemy_probe]:
			var structure_hit := drive_probe(probe, body_shape.global_position + Vector2(-80, 0), Vector2.RIGHT * 4.0, 40)
			check(
				structure_hit != null and structure_hit.get_collider() == structure,
				"%s deve ser bloqueado por %s" % [probe.name, structure_name]
			)

	for probe: CharacterBody2D in [player_probe, enemy_probe]:
		var campfire_hit := drive_probe(probe, campfire.global_position + Vector2(-90, 0), Vector2.RIGHT * 4.0, 45)
		check(campfire_hit == null, "%s deve atravessar a fogueira" % probe.name)

	var crossed_decoration := false
	for decoration: Node2D in decorations.get_children():
		var decoration_hit := drive_probe(player_probe, decoration.global_position + Vector2(-32, 0), Vector2.RIGHT * 4.0, 16)
		if decoration_hit == null:
			crossed_decoration = true
			break
	check(crossed_decoration, "Jogador deve atravessar ao menos uma decoração real sem colisão")

	var reachable_resources := 0
	for pickup: Node2D in resource_nodes:
		if resource_has_reachable_spot(island, pickup):
			reachable_resources += 1
		else:
			check(false, "Recurso sem posição física alcançável: %s" % pickup.resource_id)
	check(reachable_resources == resource_nodes.size(), "Todos os 69 recursos devem ter ponto de interação alcançável")
	print("Playtest físico: 4 costas, 6 construções, fogueira, decoração e %d recursos verificados com Player/Enemy" % reachable_resources)

	player_probe.queue_free()
	enemy_probe.queue_free()
	island.queue_free()
	await process_frame
	quit(1 if failures else 0)
