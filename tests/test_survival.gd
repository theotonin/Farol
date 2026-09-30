extends SceneTree

const STATE_PATH := "res://scripts/survival_state.gd"

var _failures := 0
var _checks := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	if not ResourceLoader.exists(STATE_PATH):
		_fail("survival_state.gd exists before the rule tests can run")
		_finish()
		return

	_test_new_expedition_starts_at_night()
	_test_capacity_and_transfers()
	_test_eating()
	_test_fuel_and_cycle_boundaries()
	_test_death_preserves_progress_and_releases_carried_parts()
	_test_repair_costs_and_ordering()
	_test_explicit_ignition()
	_test_save_round_trip_and_invalid_loads()
	_finish()


func _new_state():
	var state_script = load(STATE_PATH)
	var state = state_script.new()
	state.new_game()
	return state


func _test_new_expedition_starts_at_night() -> void:
	var state = _new_state()
	_expect_equal(state.day, 1, "a new expedition starts on its first day")
	_expect_equal(state.time_of_day, 270.0, "a new expedition begins thirty seconds into the night")
	_expect_true(state.is_night(), "a new expedition immediately uses nighttime rules")


func _test_capacity_and_transfers() -> void:
	var state = _new_state()
	for index in range(20):
		_expect_true(state.collect("wood", "wood_%d" % index), "items fit until the backpack reaches capacity")
	_expect_equal(state.bag_count(), 20, "the backpack reports its total unit count")
	_expect_false(state.collect("stone", "overflow"), "collection is rejected when the backpack is full")
	_expect_false(state.collect("unknown", "bad_kind"), "unknown resource kinds are rejected")

	state.deposit_all()
	_expect_equal(state.bag_count(), 0, "deposit_all empties the backpack")
	_expect_equal(state.storage.wood, 20, "deposit_all moves every unit into storage")
	_expect_true(state.withdraw("wood"), "a stored unit can be withdrawn")
	_expect_equal(state.bag.wood, 1, "withdraw puts one unit in the backpack")
	_expect_equal(state.storage.wood, 19, "withdraw removes one unit from storage")


func _test_eating() -> void:
	var state = _new_state()
	state.health = 63.0
	_expect_true(state.collect("food", "berries_1"), "food can be collected")
	_expect_true(state.eat(), "food can be eaten while hurt")
	_expect_equal(state.health, 88.0, "food restores 25 health")
	_expect_equal(state.bag.food, 0, "eating consumes one carried food")

	state.health = 100.0
	state.bag.food = 1
	_expect_false(state.eat(), "food is not consumed at full health")
	_expect_equal(state.bag.food, 1, "failed eating preserves food")


func _test_fuel_and_cycle_boundaries() -> void:
	var state = _new_state()
	state.time_of_day = 230.0
	state.fuel = 200.0
	_expect_false(state.tick(20.0), "crossing into night is not a dawn")
	_expect_equal(state.time_of_day, 250.0, "tick advances cycle time across dusk")
	_expect_equal(state.fuel, 190.0, "only the nighttime portion consumes fuel")
	_expect_true(state.is_night(), "cycle time reports the nighttime phase")

	_expect_true(state.collect("wood", "daily_wood"), "a common resource can be marked collected")
	_expect_true(state.collect("part", "unique_part"), "a part can be marked collected")
	_expect_true(state.tick(110.0), "reaching the end of night reports dawn")
	_expect_equal(state.day, 2, "dawn advances the day")
	_expect_equal(state.time_of_day, 0.0, "dawn starts the next day at zero")
	_expect_equal(state.fuel, 80.0, "night fuel consumption stops exactly at dawn")
	_expect_false(state.collected.has("daily_wood"), "common resources renew at dawn")
	_expect_true(state.collected.has("unique_part"), "parts remain collected across dawn")

	state.bag.wood = 1
	state.fuel = 225.0
	_expect_true(state.fuel_fire(), "one carried wood fuels the fire")
	_expect_equal(state.fuel, 240.0, "fuel is capped at 240 seconds")
	_expect_equal(state.bag.wood, 0, "fueling consumes carried wood first")
	state.storage.wood = 1
	_expect_false(state.fuel_fire(), "a full fire rejects additional fuel")
	_expect_equal(state.storage.wood, 1, "rejected fuel is not consumed")
	state.fuel = 200.0
	_expect_true(state.fuel_fire(), "stored wood fuels the fire when no wood is carried")
	_expect_equal(state.fuel, 230.0, "stored wood adds 30 seconds of fuel")
	_expect_equal(state.storage.wood, 0, "fueling consumes one stored wood")
	var invalid_delta_state = _new_state()
	_expect_false(invalid_delta_state.tick(INF), "non-finite cycle deltas are rejected")
	_expect_equal(invalid_delta_state.day, 1, "a rejected cycle delta cannot advance the day")
	_expect_equal(invalid_delta_state.time_of_day, 270.0, "a rejected cycle delta cannot mutate the initial nighttime")


func _test_death_preserves_progress_and_releases_carried_parts() -> void:
	var state = _new_state()
	_expect_true(state.collect("part", "stored_part"), "the stored part can be collected")
	state.deposit_all()
	_expect_true(state.collect("part", "carried_part"), "the carried part can be collected")
	_expect_true(state.collect("stone", "carried_stone"), "a common carried resource can be collected")
	state.storage.wood = 7
	state.repair_stage = 2
	state.fuel = 45.0
	state.health = 4.0
	state.stamina = 3.0

	state.die()
	_expect_equal(state.day, 2, "death resumes on the following day")
	_expect_equal(state.time_of_day, 0.0, "death resumes in the morning")
	_expect_equal(state.health, 100.0, "death restores full health")
	_expect_equal(state.stamina, 100.0, "death restores full stamina")
	_expect_equal(state.bag_count(), 0, "death empties the backpack")
	_expect_equal(state.storage.wood, 7, "death preserves stored common resources")
	_expect_equal(state.storage.part, 1, "death preserves deposited parts")
	_expect_equal(state.repair_stage, 2, "death preserves repair progress")
	_expect_equal(state.fuel, 45.0, "death preserves fire fuel")
	_expect_true(state.collected.has("stored_part"), "deposited parts stay unavailable after death")
	_expect_false(state.collected.has("carried_part"), "lost carried parts become collectible again")
	_expect_false(state.collected.has("carried_stone"), "common resources renew after death")


func _test_repair_costs_and_ordering() -> void:
	var state = _new_state()
	_expect_equal(state.next_cost(), {"wood": 10, "stone": 8}, "the first repair cost is exposed")
	for index in range(3):
		_expect_true(state.collect("part", "repair_part_%d" % index), "repair parts are collected with identities")
	state.deposit_all()
	state.storage.wood = 18
	state.storage.stone = 16
	state.storage.scrap = 14

	_expect_true(state.repair(), "the first repair succeeds with exact stored materials")
	_expect_equal(state.repair_stage, 1, "repairs advance one stage at a time")
	_expect_equal(state.next_cost(), {"wood": 8, "scrap": 6, "part": 1}, "the second cost follows the first")
	_expect_true(state.repair(), "the second repair succeeds in order")
	_expect_equal(state.next_cost(), {"stone": 8, "scrap": 8, "part": 2}, "the third cost follows the second")
	_expect_true(state.repair(), "the third repair succeeds in order")
	_expect_equal(state.repair_stage, 3, "all three repairs can be completed")
	_expect_equal(state.storage, {"wood": 0, "stone": 0, "scrap": 0, "part": 0, "food": 0}, "repairs deduct exactly their listed costs")
	_expect_equal(state.next_cost(), {}, "no repair cost remains after completion")
	_expect_false(state.repair(), "a fourth repair is rejected")
	state.die()
	for index in range(3):
		_expect_true(state.collected.has("repair_part_%d" % index), "parts consumed by repairs remain unavailable")

	var poor_state = _new_state()
	poor_state.storage.wood = 10
	poor_state.storage.stone = 7
	_expect_false(poor_state.repair(), "repair fails when one required material is missing")
	_expect_equal(poor_state.storage.wood, 10, "a failed repair consumes no partial cost")
	var phantom_state = _new_state()
	phantom_state.repair_stage = 1
	phantom_state.storage.wood = 8
	phantom_state.storage.scrap = 6
	phantom_state.storage.part = 1
	_expect_false(phantom_state.repair(), "repair rejects a part count without a stored part identity")
	_expect_equal(phantom_state.storage.part, 1, "a rejected phantom part is not consumed")


func _test_explicit_ignition() -> void:
	var state = _new_state()
	_expect_false(state.ignite(), "the lighthouse cannot ignite before all repairs")
	state.repair_stage = 3
	_expect_false(state.won, "finishing repairs alone does not win")
	_expect_true(state.ignite(), "explicit interaction ignites the repaired lighthouse")
	_expect_true(state.won, "ignition records the rescue victory")
	_expect_false(state.ignite(), "an already ignited lighthouse cannot ignite again")


func _test_save_round_trip_and_invalid_loads() -> void:
	var save_path := "user://survival_test_save.json"
	var state = _new_state()
	var has_world_seed: bool = state.get_property_list().any(func(property: Dictionary) -> bool: return property.name == "world_seed")
	_expect_true(has_world_seed, "survival state exposes the random world seed used by resource placement")
	if has_world_seed:
		state.world_seed = 24680
	state.day = 4
	state.time_of_day = 275.5
	state.health = 72.0
	state.stamina = 41.0
	state.fuel = 88.0
	state.player_position = Vector2(123.5, -47.25)
	_expect_true(state.collect("part", "deposited_part"), "round-trip fixture collects a deposited part")
	state.deposit_all()
	state.storage.wood = 18
	state.storage.stone = 8
	state.storage.scrap = 6
	_expect_true(state.repair(), "round-trip fixture completes the first repair")
	_expect_true(state.repair(), "round-trip fixture consumes an identified part in the second repair")
	_expect_true(state.collect("part", "carried_part"), "round-trip fixture collects a carried part")
	state.storage.wood = 9
	state.bag.food = 2

	_expect_equal(state.save_game(save_path), OK, "a valid state saves successfully")
	state.day = 5
	_expect_equal(state.save_game(save_path), OK, "saving again atomically replaces the checkpoint")
	var loaded = _new_state()
	_expect_true(loaded.load_game(save_path), "a valid save loads successfully")
	_expect_equal(loaded.day, 5, "load restores the day")
	_expect_equal(loaded.time_of_day, 275.5, "load restores cycle time")
	_expect_equal(loaded.health, 72.0, "load restores health")
	_expect_equal(loaded.stamina, 41.0, "load restores stamina")
	_expect_equal(loaded.fuel, 88.0, "load restores fuel")
	_expect_equal(loaded.repair_stage, 2, "load restores repair progress")
	_expect_equal(loaded.bag, state.bag, "load restores the backpack")
	_expect_equal(loaded.storage, state.storage, "load restores storage")
	_expect_equal(loaded.collected, state.collected, "load restores collected resource identities")
	_expect_equal(loaded.player_position, Vector2(123.5, -47.25), "load restores the safe player position")
	if has_world_seed:
		_expect_equal(loaded.world_seed, 24680, "load restores the resource distribution seed")
	loaded.die()
	_expect_true(loaded.collected.has("deposited_part"), "save preserves deposited part identity")
	_expect_false(loaded.collected.has("carried_part"), "save preserves carried part identity for death loss")

	var snapshot := _public_snapshot(loaded)
	_expect_equal(loaded.save_game(save_path), OK, "the post-death fixture can be saved for corruption checks")
	var valid_data = _read_json(save_path)
	var semantic_corruption = valid_data.duplicate(true)
	semantic_corruption.collected.erase("deposited_part")
	semantic_corruption.used_part_ids = []
	_write_text(save_path, JSON.stringify(semantic_corruption))
	_expect_false(loaded.load_game(save_path), "repair progress without its consumed part identities is rejected")
	_expect_equal(_public_snapshot(loaded), snapshot, "semantic corruption cannot partially mutate live state")

	var range_corruption = valid_data.duplicate(true)
	range_corruption.health = 101.0
	_write_text(save_path, JSON.stringify(range_corruption))
	_expect_false(loaded.load_game(save_path), "out-of-range saved values are rejected")
	_expect_equal(_public_snapshot(loaded), snapshot, "out-of-range saves cannot partially mutate live state")

	_write_text(save_path, "{ definitely broken JSON")
	_expect_false(loaded.load_game(save_path), "corrupt JSON is rejected")
	_expect_equal(_public_snapshot(loaded), snapshot, "corrupt JSON cannot partially mutate live state")

	_write_text(save_path, JSON.stringify({"schema_version": 999}))
	_expect_false(loaded.load_game(save_path), "unsupported save schemas are rejected")
	_expect_equal(_public_snapshot(loaded), snapshot, "unsupported schemas cannot partially mutate live state")

	_write_text(save_path, JSON.stringify({"schema_version": 1, "day": 99}))
	_expect_false(loaded.load_game(save_path), "incomplete saves are rejected")
	_expect_equal(_public_snapshot(loaded), snapshot, "incomplete saves cannot partially mutate live state")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))


func _public_snapshot(state) -> Dictionary:
	var snapshot := {
		"day": state.day,
		"time_of_day": state.time_of_day,
		"health": state.health,
		"stamina": state.stamina,
		"fuel": state.fuel,
		"repair_stage": state.repair_stage,
		"won": state.won,
		"bag": state.bag.duplicate(true),
		"storage": state.storage.duplicate(true),
		"collected": state.collected.duplicate(true),
		"player_position": state.player_position,
	}
	if state.get_property_list().any(func(property: Dictionary) -> bool: return property.name == "world_seed"):
		snapshot.world_seed = state.world_seed
	return snapshot


func _write_text(path: String, contents: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_fail("test fixture can open %s for writing" % path)
		return
	file.store_string(contents)
	file.close()


func _read_json(path: String):
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_fail("test fixture can open %s for reading" % path)
		return null
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed


func _expect_true(value: bool, message: String) -> void:
	_checks += 1
	if not value:
		_fail(message)


func _expect_false(value: bool, message: String) -> void:
	_expect_true(not value, message)


func _expect_equal(actual, expected, message: String) -> void:
	_checks += 1
	if actual != expected:
		_fail("%s (expected %s, got %s)" % [message, str(expected), str(actual)])


func _fail(message: String) -> void:
	_failures += 1
	printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("PASS: %d survival rule checks" % _checks)
		quit(0)
	else:
		printerr("FAILED: %d of %d survival rule checks" % [_failures, _checks])
		quit(1)
