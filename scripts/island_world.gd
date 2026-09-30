class_name IslandWorld
extends Node2D

const SPAWN := Vector2(0.0, 180.0)
const SAFE_RADIUS := 180.0
const COAST_COLLISION_DEPTH := 2200.0
const DECORATION_SAFE_RADIUS := 240.0
const RESOURCE_MIN_SPACING := 56.0
const RESOURCE_SPAWN_CLEARANCE := 240.0
const RESOURCE_COAST_CLEARANCE := 72.0
const RESOURCE_STRUCTURE_CLEARANCE := 110.0
const RARE_PART_MIN_RADIUS := 650.0
const OBJECTS_TEXTURE := preload("res://assets/pixel/objects.png")
const GROUND_DETAILS_TEXTURE := preload("res://assets/pixel/ground_details.png")
const RESOURCE_SCENE := preload("res://scenes/objects/resource_pickup.tscn")

const LAND_POINTS: Array[Vector2] = [
	Vector2(-1430, -110), Vector2(-1335, -505), Vector2(-1080, -790),
	Vector2(-720, -1000), Vector2(-310, -1080), Vector2(120, -1060),
	Vector2(540, -1100), Vector2(920, -900), Vector2(1245, -610),
	Vector2(1430, -235), Vector2(1400, 175), Vector2(1210, 545),
	Vector2(900, 825), Vector2(520, 1035), Vector2(80, 1100),
	Vector2(-350, 1050), Vector2(-760, 925), Vector2(-1090, 700),
	Vector2(-1340, 370)
]

const RESERVED_POINTS: Array[Vector2] = [
	Vector2(-305, 175), Vector2(365, 215), Vector2(-475, -70), Vector2(225, -400),
	Vector2(-340, -285), Vector2(505, -165), Vector2(-165, 510), Vector2(285, 335),
	Vector2(-410, 360), Vector2(90, -525), Vector2(-250, -440), Vector2(-760, -180),
	Vector2(650, -520), Vector2(775, 410), Vector2(-620, 620), Vector2(-1070, -405),
	Vector2(1060, -425), Vector2(180, 980)
]

@export var spawn_position := SPAWN

var _land_polygon := PackedVector2Array(LAND_POINTS)

@onready var ground: TileMapLayer = $Ground
@onready var coast_collision: StaticBody2D = $CoastCollision
@onready var decorations: Node2D = $Decorations
@onready var resources_root: Node2D = $Resources


func _ready() -> void:
	_build_resources()
	_build_coast_collision()
	_build_decorations()
	distribute_resources(1)


func is_walkable(point: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(point, _land_polygon)


func constrain_position(point: Vector2) -> Vector2:
	if is_walkable(point):
		return point
	var nearest := Vector2.ZERO
	var nearest_distance := INF
	for index in LAND_POINTS.size():
		var candidate := Geometry2D.get_closest_point_to_segment(
			point,
			LAND_POINTS[index],
			LAND_POINTS[(index + 1) % LAND_POINTS.size()]
		)
		var distance := point.distance_squared_to(candidate)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = candidate
	return nearest.move_toward(Vector2.ZERO, 14.0)


func get_resource_nodes() -> Array[Node]:
	var result: Array[Node] = []
	for child: Node in resources_root.get_children():
		result.append(child)
	return result


func distribute_resources(world_seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = world_seed
	var placed: Array[Vector2] = []
	var pickups := get_resource_nodes()
	# Peças raras são posicionadas primeiro para garantir regiões distantes.
	pickups.sort_custom(func(a: Node, b: Node) -> bool: return a.kind == "part" and b.kind != "part")
	for pickup: Node2D in pickups:
		var position_found := false
		for attempt in 5000:
			var candidate := Vector2(
				snappedf(rng.randf_range(-1320.0, 1320.0), 4.0),
				snappedf(rng.randf_range(-990.0, 1010.0), 4.0)
			)
			if not _resource_position_is_valid(candidate, pickup.kind, placed):
				continue
			pickup.position = candidate
			placed.append(candidate)
			position_found = true
			break
		if not position_found:
			push_error("Não foi possível distribuir %s com a semente %d" % [pickup.resource_id, world_seed])


func _resource_position_is_valid(point: Vector2, kind: String, placed: Array[Vector2]) -> bool:
	if not is_walkable(point) or point.distance_to(SPAWN) < RESOURCE_SPAWN_CLEARANCE:
		return false
	if kind == "part" and point.length() < RARE_PART_MIN_RADIUS:
		return false
	if _distance_to_coast(point) < RESOURCE_COAST_CLEARANCE:
		return false
	for existing: Vector2 in placed:
		if point.distance_to(existing) < RESOURCE_MIN_SPACING:
			return false
	for structure: Node2D in $Structures.get_children():
		if point.distance_to(structure.position) < RESOURCE_STRUCTURE_CLEARANCE:
			return false
	for decoration: Node2D in decorations.get_children():
		if point.distance_to(decoration.position) < 34.0:
			return false
	return true


func _distance_to_coast(point: Vector2) -> float:
	var nearest := INF
	for index in LAND_POINTS.size():
		var edge_point := Geometry2D.get_closest_point_to_segment(
			point,
			LAND_POINTS[index],
			LAND_POINTS[(index + 1) % LAND_POINTS.size()]
		)
		nearest = minf(nearest, point.distance_to(edge_point))
	return nearest


func _build_resources() -> void:
	if resources_root.get_child_count() > 0:
		return
	var common_offsets: Array[Vector2] = [
		Vector2(-42, -30), Vector2(0, -38), Vector2(42, -28),
		Vector2(-42, 25), Vector2(0, 36), Vector2(42, 24)
	]
	_append_resource_clusters("wood", [Vector2(-305, 175), Vector2(365, 215), Vector2(-475, -70), Vector2(225, -400)], common_offsets)
	_append_resource_clusters("stone", [Vector2(-340, -285), Vector2(505, -165), Vector2(-165, 510)], common_offsets)
	_append_resource_clusters("food", [Vector2(285, 335), Vector2(-410, 360), Vector2(90, -525), Vector2(-250, -440)], [Vector2(-25, 0), Vector2(25, 0)])
	_append_resource_clusters("scrap", [Vector2(-760, -180), Vector2(650, -520), Vector2(775, 410), Vector2(-620, 620)], [Vector2(-32, -32), Vector2(32, -32), Vector2(-32, 32), Vector2(32, 32)])
	for index in 3:
		_add_resource(
			"part_%02d" % (index + 1),
			"part",
			[Vector2(-1070, -405), Vector2(1060, -425), Vector2(180, 980)][index]
		)


func _append_resource_clusters(kind: String, anchors: Array, offsets: Array) -> void:
	var item_number := 1
	for anchor: Vector2 in anchors:
		for offset: Vector2 in offsets:
			_add_resource("%s_%02d" % [kind, item_number], kind, anchor + offset)
			item_number += 1


func _add_resource(resource_id: String, kind: String, resource_position: Vector2) -> void:
	var pickup := RESOURCE_SCENE.instantiate()
	pickup.name = resource_id
	pickup.resource_id = resource_id
	pickup.kind = kind
	pickup.position = resource_position
	resources_root.add_child(pickup)


func set_visual_state(collected: Dictionary, stage: int, fuel: float, night_amount: float, won: bool) -> void:
	$Structures/Lighthouse.set_stage(stage, won)
	$Structures/Campfire.set_fuel(fuel, night_amount)
	for pickup: Node in get_resource_nodes():
		if pickup.has_method("set_collected"):
			var resource_id: Variant = pickup.get("resource_id")
			pickup.call("set_collected", collected.has(resource_id))


func _build_coast_collision() -> void:
	for child: Node in coast_collision.get_children():
		child.queue_free()
	for index in LAND_POINTS.size():
		var edge_start := LAND_POINTS[index]
		var edge_end := LAND_POINTS[(index + 1) % LAND_POINTS.size()]
		var edge := edge_end - edge_start
		var outward := Vector2(edge.y, -edge.x).normalized() * COAST_COLLISION_DEPTH
		var polygon := CollisionPolygon2D.new()
		polygon.name = "CoastSegment%02d" % index
		polygon.polygon = PackedVector2Array([
			edge_start,
			edge_end,
			edge_end + outward,
			edge_start + outward
		])
		coast_collision.add_child(polygon)


func _build_decorations() -> void:
	if decorations.get_child_count() > 0:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 0x0FA2016
	_add_random_decorations(rng, 42, Rect2(0, 96, 64, 64), Vector2.ONE, 78.0, "broadleaf_tree")
	_add_random_decorations(rng, 20, Rect2(64, 96, 64, 64), Vector2.ONE, 78.0, "pine_tree")
	_add_random_decorations(rng, 28, Rect2(160, 8, 32, 32), Vector2.ONE, 38.0, "small_stone")
	_add_random_decorations(rng, 36, Rect2(192, 8, 32, 32), Vector2.ONE, 30.0, "soil_patch")
	_add_ground_details(rng, 30, 0, "grass_tuft")
	_add_ground_details(rng, 24, 1, "fallen_leaves")
	_add_ground_details(rng, 20, 2, "pebbles")
	_add_ground_details(rng, 18, 3, "earth_crack")


func _add_random_decorations(rng: RandomNumberGenerator, count: int, region: Rect2, sprite_scale: Vector2, clearance: float, detail_kind: String) -> void:
	var created := 0
	var attempts := 0
	while created < count and attempts < count * 60:
		attempts += 1
		var point := Vector2(rng.randf_range(-1320.0, 1320.0), rng.randf_range(-990.0, 1010.0))
		if not is_walkable(point) or point.length() < DECORATION_SAFE_RADIUS or _near_reserved_point(point, clearance):
			continue
		var sprite := Sprite2D.new()
		sprite.name = "Decoration%03d" % decorations.get_child_count()
		sprite.position = point
		sprite.scale = sprite_scale
		sprite.texture = _atlas_region(region)
		sprite.set_meta("detail_kind", detail_kind)
		decorations.add_child(sprite)
		created += 1


func _add_ground_details(rng: RandomNumberGenerator, count: int, atlas_index: int, detail_kind: String) -> void:
	var created := 0
	var attempts := 0
	while created < count and attempts < count * 60:
		attempts += 1
		var point := Vector2(rng.randf_range(-1320.0, 1320.0), rng.randf_range(-990.0, 1010.0))
		if not is_walkable(point) or point.length() < 190.0 or _near_reserved_point(point, 28.0):
			continue
		var sprite := Sprite2D.new()
		sprite.name = "GroundDetail%03d" % decorations.get_child_count()
		sprite.position = point.round()
		sprite.z_index = -2
		sprite.texture = _ground_detail_region(atlas_index)
		sprite.set_meta("detail_kind", detail_kind)
		decorations.add_child(sprite)
		created += 1


func _near_reserved_point(point: Vector2, clearance: float) -> bool:
	for reserved: Vector2 in RESERVED_POINTS:
		if point.distance_squared_to(reserved) < clearance * clearance:
			return true
	return false


func _atlas_region(region: Rect2) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = OBJECTS_TEXTURE
	texture.region = region
	return texture


func _ground_detail_region(atlas_index: int) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = GROUND_DETAILS_TEXTURE
	texture.region = Rect2(atlas_index * 32, 0, 32, 32)
	return texture
