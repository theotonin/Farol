extends SceneTree

var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)


func positions_by_id(island: Node2D) -> Dictionary:
	var positions := {}
	for pickup: Node2D in island.get_resource_nodes():
		positions[pickup.resource_id] = pickup.position
	return positions


func run() -> void:
	var island := (load("res://scenes/world/island.tscn") as PackedScene).instantiate()
	root.add_child(island)
	await process_frame
	check(island.has_method("distribute_resources"), "A ilha deve distribuir recursos a partir da semente do salvamento")
	if not island.has_method("distribute_resources"):
		island.queue_free()
		await process_frame
		quit(1)
		return

	var initial := positions_by_id(island)
	island.distribute_resources(1)
	check(initial == positions_by_id(island), "A ilha deve nascer com uma distribuição orgânica, inclusive antes de iniciar a partida")

	island.distribute_resources(13579)
	var first := positions_by_id(island)
	island.distribute_resources(13579)
	var repeated := positions_by_id(island)
	check(first == repeated, "A mesma semente deve restaurar exatamente as mesmas posições")

	island.distribute_resources(24680)
	var different := positions_by_id(island)
	var changed := 0
	for resource_id: String in first:
		if first[resource_id] != different[resource_id]:
			changed += 1
	check(changed >= 60, "Uma nova partida deve redistribuir praticamente todos os drops; alterados: %d" % changed)

	var pickups: Array[Node] = island.get_resource_nodes()
	check(pickups.size() == 69, "A distribuição deve preservar os 69 recursos")
	for index in pickups.size():
		var pickup := pickups[index] as Node2D
		check(island.is_walkable(pickup.position), "%s deve permanecer dentro da ilha" % pickup.resource_id)
		check(pickup.position.distance_to(IslandWorld.SPAWN) >= 240.0, "%s deve deixar o abrigo inicial livre" % pickup.resource_id)
		if pickup.kind == "part":
			check(pickup.position.length() >= 650.0, "%s deve ficar distante do centro" % pickup.resource_id)
		for other_index in range(index + 1, pickups.size()):
			var other := pickups[other_index] as Node2D
			check(pickup.position.distance_to(other.position) >= 56.0, "%s e %s não devem formar uma pilha organizada" % [pickup.resource_id, other.resource_id])

	print("Distribuição orgânica: %d recursos, %d posições alteradas entre sementes" % [pickups.size(), changed])
	island.queue_free()
	await process_frame
	quit(1 if failures > 0 else 0)
