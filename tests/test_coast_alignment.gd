extends SceneTree

var failures := 0

const INNER_CORNER_TILES := {
	Vector2i(-1, -1): Vector2i(0, 4),
	Vector2i(1, -1): Vector2i(1, 4),
	Vector2i(-1, 1): Vector2i(2, 4),
	Vector2i(1, 1): Vector2i(3, 4),
}


func _initialize() -> void:
	call_deferred("run")


func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)


func is_land(island: Node2D, cell: Vector2i) -> bool:
	return island.is_walkable(Vector2(cell * 32) + Vector2(16, 16))


func edge_matches(image: Image, tile_a: Vector2i, side_a: Vector2i, tile_b: Vector2i, side_b: Vector2i) -> bool:
	for offset in 32:
		var point_a := tile_a * 32
		var point_b := tile_b * 32
		if side_a.x != 0:
			point_a += Vector2i(31 if side_a.x > 0 else 0, offset)
		else:
			point_a += Vector2i(offset, 31 if side_a.y > 0 else 0)
		if side_b.x != 0:
			point_b += Vector2i(31 if side_b.x > 0 else 0, offset)
		else:
			point_b += Vector2i(offset, 31 if side_b.y > 0 else 0)
		if image.get_pixelv(point_a) != image.get_pixelv(point_b):
			return false
	return true


func run() -> void:
	var island := (load("res://scenes/world/island.tscn") as PackedScene).instantiate()
	var ground := island.get_node("Ground") as TileMapLayer
	var atlas_texture := load("res://assets/pixel/terrain_atlas.png") as Texture2D
	var atlas := atlas_texture.get_image()
	var checked_inner_corners := 0
	var mismatched_inner_corners := 0

	for cell: Vector2i in ground.get_used_cells():
		if not is_land(island, cell):
			continue
		var north := is_land(island, cell + Vector2i.UP)
		var east := is_land(island, cell + Vector2i.RIGHT)
		var south := is_land(island, cell + Vector2i.DOWN)
		var west := is_land(island, cell + Vector2i.LEFT)
		if not (north and east and south and west):
			continue
		for diagonal: Vector2i in INNER_CORNER_TILES:
			if is_land(island, cell + diagonal):
				continue
			checked_inner_corners += 1
			if ground.get_cell_atlas_coords(cell) != INNER_CORNER_TILES[diagonal]:
				mismatched_inner_corners += 1

	check(checked_inner_corners >= 8, "A costa deve conter cantos internos diagonais suficientes para validar o contorno")
	check(
		mismatched_inner_corners == 0,
		"Todo canto diagonal da costa deve usar o tile interno alinhado; desalinhados: %d/%d" % [mismatched_inner_corners, checked_inner_corners]
	)
	var straight_edge_contracts := [
		[Vector2i(0, 3), Vector2i.UP, Vector2i(0, 0), Vector2i.UP],
		[Vector2i(0, 3), Vector2i.DOWN, Vector2i(0, 1), Vector2i.DOWN],
		[Vector2i(1, 3), Vector2i.LEFT, Vector2i(0, 0), Vector2i.LEFT],
		[Vector2i(1, 3), Vector2i.RIGHT, Vector2i(0, 1), Vector2i.RIGHT],
		[Vector2i(2, 3), Vector2i.UP, Vector2i(0, 1), Vector2i.UP],
		[Vector2i(2, 3), Vector2i.DOWN, Vector2i(0, 0), Vector2i.DOWN],
		[Vector2i(3, 3), Vector2i.LEFT, Vector2i(0, 1), Vector2i.LEFT],
		[Vector2i(3, 3), Vector2i.RIGHT, Vector2i(0, 0), Vector2i.RIGHT],
	]
	var broken_edges := 0
	for contract: Array in straight_edge_contracts:
		if not edge_matches(atlas, contract[0], contract[1], contract[2], contract[3]):
			broken_edges += 1
	check(broken_edges == 0, "As bordas retas do atlas devem repetir exatamente água/areia; desalinhadas: %d" % broken_edges)
	if failures == 0:
		print("Alinhamento costeiro: %d cantos internos corretos" % checked_inner_corners)
	island.free()
	quit(1 if failures > 0 else 0)
