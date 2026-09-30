extends RefCounted

## Pure survival rules for O Farol. This object has no scene-tree dependency.
## Inventory keys are always: wood, stone, scrap, part, food.

const MAX_CAPACITY := 20
const MAX_HEALTH := 100.0
const MAX_STAMINA := 100.0
const DAY_DURATION := 240.0
const NIGHT_DURATION := 120.0
const NEW_GAME_START_TIME := 270.0
const MAX_FUEL := 240.0
const FUEL_PER_WOOD := 30.0
const FOOD_HEALING := 25.0
const SAVE_SCHEMA_VERSION := 1

const RESOURCE_KINDS := ["wood", "stone", "scrap", "part", "food"]
const RESOURCE_LABELS := {
	"wood": "Madeira",
	"stone": "Pedra",
	"scrap": "Sucata",
	"part": "Peça",
	"food": "Comida",
}
const REPAIR_COSTS := [
	{"wood": 10, "stone": 8},
	{"wood": 8, "scrap": 6, "part": 1},
	{"stone": 8, "scrap": 8, "part": 2},
]

var day: int = 1
var time_of_day: float = NEW_GAME_START_TIME
var health: float = MAX_HEALTH
var stamina: float = MAX_STAMINA
var fuel: float = 0.0
var repair_stage: int = 0
var won: bool = false
var bag: Dictionary = {}
var storage: Dictionary = {}
var collected: Dictionary = {}
var player_position: Vector2 = Vector2.ZERO
var world_seed: int = 1

# Part identity is kept separately so death can release only carried parts.
var _bag_part_ids: Array = []
var _storage_part_ids: Array = []
var _used_part_ids: Array = []


func _init() -> void:
	new_game()


func new_game(seed: int = 1) -> void:
	day = 1
	time_of_day = NEW_GAME_START_TIME
	health = MAX_HEALTH
	stamina = MAX_STAMINA
	fuel = 0.0
	repair_stage = 0
	won = false
	bag = _empty_inventory()
	storage = _empty_inventory()
	collected = {}
	player_position = Vector2.ZERO
	world_seed = maxi(1, seed)
	_bag_part_ids = []
	_storage_part_ids = []
	_used_part_ids = []


func collect(kind: String, id: String) -> bool:
	if not RESOURCE_KINDS.has(kind) or id.strip_edges().is_empty():
		return false
	if collected.has(id) or bag_count() >= MAX_CAPACITY:
		return false
	bag[kind] = int(bag[kind]) + 1
	collected[id] = kind
	if kind == "part":
		_bag_part_ids.append(id)
	return true


func deposit_all() -> void:
	for kind in RESOURCE_KINDS:
		storage[kind] = int(storage[kind]) + int(bag[kind])
		bag[kind] = 0
	_storage_part_ids.append_array(_bag_part_ids)
	_bag_part_ids.clear()


func withdraw(kind: String) -> bool:
	if not RESOURCE_KINDS.has(kind):
		return false
	if bag_count() >= MAX_CAPACITY or int(storage[kind]) <= 0:
		return false
	storage[kind] = int(storage[kind]) - 1
	bag[kind] = int(bag[kind]) + 1
	if kind == "part" and not _storage_part_ids.is_empty():
		_bag_part_ids.append(_storage_part_ids.pop_back())
	return true


func eat() -> bool:
	if health >= MAX_HEALTH or int(bag["food"]) <= 0:
		return false
	bag["food"] = int(bag["food"]) - 1
	health = minf(MAX_HEALTH, health + FOOD_HEALING)
	return true


func fuel_fire() -> bool:
	if fuel >= MAX_FUEL:
		return false
	if int(bag["wood"]) > 0:
		bag["wood"] = int(bag["wood"]) - 1
	elif int(storage["wood"]) > 0:
		storage["wood"] = int(storage["wood"]) - 1
	else:
		return false
	fuel = minf(MAX_FUEL, fuel + FUEL_PER_WOOD)
	return true


func repair() -> bool:
	if repair_stage < 0 or repair_stage >= REPAIR_COSTS.size():
		return false
	var cost: Dictionary = REPAIR_COSTS[repair_stage]
	for kind in cost:
		if int(storage[kind]) < int(cost[kind]):
			return false
	if int(cost.get("part", 0)) > _storage_part_ids.size():
		return false
	for kind in cost:
		var amount := int(cost[kind])
		storage[kind] = int(storage[kind]) - amount
		if kind == "part":
			for unused in range(amount):
				if _storage_part_ids.is_empty():
					break
				_used_part_ids.append(_storage_part_ids.pop_back())
	repair_stage += 1
	return true


func ignite() -> bool:
	if won or repair_stage < REPAIR_COSTS.size():
		return false
	won = true
	return true


func die() -> void:
	day += 1
	time_of_day = 0.0
	health = MAX_HEALTH
	stamina = MAX_STAMINA
	for id in collected.keys():
		if collected[id] != "part" or _bag_part_ids.has(id):
			collected.erase(id)
	bag = _empty_inventory()
	_bag_part_ids.clear()


func tick(delta: float) -> bool:
	if delta <= 0.0 or not is_finite(delta):
		return false
	var remaining := delta
	var dawned := false
	var cycle_duration := DAY_DURATION + NIGHT_DURATION
	while remaining > 0.0:
		if time_of_day < DAY_DURATION:
			var daylight_step := minf(remaining, DAY_DURATION - time_of_day)
			time_of_day += daylight_step
			remaining -= daylight_step
		else:
			var night_step := minf(remaining, cycle_duration - time_of_day)
			fuel = maxf(0.0, fuel - night_step)
			time_of_day += night_step
			remaining -= night_step
			if time_of_day >= cycle_duration:
				time_of_day = 0.0
				day += 1
				dawned = true
				_renew_common_resources()
	return dawned


func is_night() -> bool:
	return time_of_day >= DAY_DURATION


func bag_count() -> int:
	var total := 0
	for kind in RESOURCE_KINDS:
		total += int(bag.get(kind, 0))
	return total


func next_cost() -> Dictionary:
	if repair_stage < 0 or repair_stage >= REPAIR_COSTS.size():
		return {}
	return REPAIR_COSTS[repair_stage].duplicate(true)


func save_game(path: String = "user://save.json") -> Error:
	if path.is_empty():
		return ERR_INVALID_PARAMETER
	var temporary_path := path + ".tmp"
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(_save_data()))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary_path))
		return write_error
	var rename_error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(temporary_path),
		ProjectSettings.globalize_path(path)
	)
	if rename_error != OK:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary_path))
	return rename_error


func load_game(path: String = "user://save.json") -> bool:
	if path.is_empty() or not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK or not json.data is Dictionary:
		return false
	var candidate := _validated_save(json.data)
	if candidate.is_empty():
		return false

	# Commit only after the complete document has passed validation.
	day = candidate.day
	time_of_day = candidate.time_of_day
	health = candidate.health
	stamina = candidate.stamina
	fuel = candidate.fuel
	repair_stage = candidate.repair_stage
	won = candidate.won
	bag = candidate.bag
	storage = candidate.storage
	collected = candidate.collected
	player_position = candidate.player_position
	world_seed = candidate.world_seed
	_bag_part_ids = candidate.bag_part_ids
	_storage_part_ids = candidate.storage_part_ids
	_used_part_ids = candidate.used_part_ids
	return true


func _empty_inventory() -> Dictionary:
	return {"wood": 0, "stone": 0, "scrap": 0, "part": 0, "food": 0}


func _renew_common_resources() -> void:
	for id in collected.keys():
		if collected[id] != "part":
			collected.erase(id)


func _save_data() -> Dictionary:
	return {
		"schema_version": SAVE_SCHEMA_VERSION,
		"day": day,
		"time_of_day": time_of_day,
		"health": health,
		"stamina": stamina,
		"fuel": fuel,
		"repair_stage": repair_stage,
		"won": won,
		"bag": bag.duplicate(true),
		"storage": storage.duplicate(true),
		"collected": collected.duplicate(true),
		"player_position": [player_position.x, player_position.y],
		"world_seed": world_seed,
		"bag_part_ids": _bag_part_ids.duplicate(),
		"storage_part_ids": _storage_part_ids.duplicate(),
		"used_part_ids": _used_part_ids.duplicate(),
	}


func _validated_save(data: Dictionary) -> Dictionary:
	var required := [
		"schema_version", "day", "time_of_day", "health", "stamina", "fuel",
		"repair_stage", "won", "bag", "storage", "collected", "player_position",
		"bag_part_ids", "storage_part_ids", "used_part_ids",
	]
	for key in required:
		if not data.has(key):
			return {}
	if not _is_integer(data.schema_version) or int(data.schema_version) != SAVE_SCHEMA_VERSION:
		return {}
	if not _is_integer(data.day) or int(data.day) < 1:
		return {}
	if not _is_finite_number(data.time_of_day):
		return {}
	var loaded_time := float(data.time_of_day)
	if loaded_time < 0.0 or loaded_time >= DAY_DURATION + NIGHT_DURATION:
		return {}
	if not _number_in_range(data.health, 0.0, MAX_HEALTH):
		return {}
	if not _number_in_range(data.stamina, 0.0, MAX_STAMINA):
		return {}
	if not _number_in_range(data.fuel, 0.0, MAX_FUEL):
		return {}
	if not _is_integer(data.repair_stage):
		return {}
	var loaded_stage := int(data.repair_stage)
	if loaded_stage < 0 or loaded_stage > REPAIR_COSTS.size():
		return {}
	if typeof(data.won) != TYPE_BOOL or (data.won and loaded_stage < REPAIR_COSTS.size()):
		return {}
	var loaded_bag := _validated_inventory(data.bag, true)
	var loaded_storage := _validated_inventory(data.storage, false)
	if loaded_bag.is_empty() or loaded_storage.is_empty():
		return {}
	var loaded_collected: Variant = _validated_collected(data.collected)
	if loaded_collected == null:
		return {}
	var loaded_position: Variant = _validated_position(data.player_position)
	if loaded_position == null:
		return {}
	var loaded_world_seed := 1
	if data.has("world_seed"):
		if not _is_integer(data.world_seed) or int(data.world_seed) < 1:
			return {}
		loaded_world_seed = int(data.world_seed)
	var bag_ids: Variant = _validated_part_ids(data.bag_part_ids, loaded_collected)
	var storage_ids: Variant = _validated_part_ids(data.storage_part_ids, loaded_collected)
	var used_ids: Variant = _validated_part_ids(data.used_part_ids, loaded_collected)
	if bag_ids == null or storage_ids == null or used_ids == null:
		return {}
	if bag_ids.size() != int(loaded_bag.part) or storage_ids.size() != int(loaded_storage.part):
		return {}
	var all_part_ids: Array = []
	all_part_ids.append_array(bag_ids)
	all_part_ids.append_array(storage_ids)
	all_part_ids.append_array(used_ids)
	var collected_part_count := 0
	for id in loaded_collected:
		if loaded_collected[id] == "part":
			collected_part_count += 1
	if all_part_ids.size() != collected_part_count:
		return {}
	var expected_used_parts := 0
	for completed_stage in range(loaded_stage):
		expected_used_parts += int(REPAIR_COSTS[completed_stage].get("part", 0))
	if used_ids.size() != expected_used_parts:
		return {}
	var unique_part_ids := {}
	for id in all_part_ids:
		if unique_part_ids.has(id):
			return {}
		unique_part_ids[id] = true

	return {
		"day": int(data.day),
		"time_of_day": loaded_time,
		"health": float(data.health),
		"stamina": float(data.stamina),
		"fuel": float(data.fuel),
		"repair_stage": loaded_stage,
		"won": data.won,
		"bag": loaded_bag,
		"storage": loaded_storage,
		"collected": loaded_collected,
		"player_position": loaded_position,
		"world_seed": loaded_world_seed,
		"bag_part_ids": bag_ids,
		"storage_part_ids": storage_ids,
		"used_part_ids": used_ids,
	}


func _validated_inventory(value, enforce_capacity: bool) -> Dictionary:
	if not value is Dictionary or value.size() != RESOURCE_KINDS.size():
		return {}
	var result := _empty_inventory()
	var total := 0
	for kind in RESOURCE_KINDS:
		if not value.has(kind) or not _is_integer(value[kind]) or int(value[kind]) < 0:
			return {}
		result[kind] = int(value[kind])
		total += int(value[kind])
	if enforce_capacity and total > MAX_CAPACITY:
		return {}
	return result


func _validated_collected(value):
	if not value is Dictionary:
		return null
	var result := {}
	for id in value:
		if not id is String or id.strip_edges().is_empty():
			return null
		if not value[id] is String or not RESOURCE_KINDS.has(value[id]):
			return null
		result[id] = value[id]
	return result


func _validated_position(value):
	if not value is Array or value.size() != 2:
		return null
	if not _is_finite_number(value[0]) or not _is_finite_number(value[1]):
		return null
	return Vector2(float(value[0]), float(value[1]))


func _validated_part_ids(value, loaded_collected: Dictionary):
	if not value is Array:
		return null
	var result: Array = []
	for id in value:
		if not id is String or not loaded_collected.has(id) or loaded_collected[id] != "part":
			return null
		result.append(id)
	return result


func _is_integer(value) -> bool:
	if typeof(value) == TYPE_INT:
		return true
	return typeof(value) == TYPE_FLOAT and is_finite(value) and value == floor(value)


func _is_finite_number(value) -> bool:
	return (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and is_finite(float(value))


func _number_in_range(value, minimum: float, maximum: float) -> bool:
	return _is_finite_number(value) and float(value) >= minimum and float(value) <= maximum
