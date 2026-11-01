class_name PlayerScheduleManager
extends RefCounted

const SLOT_COUNT_PER_DAY: int = 48
const SLOT_MINUTES: int = 30

var _days: Dictionary = {}


func reset() -> void:
	_days.clear()


func load_data(value: Variant) -> void:
	_days.clear()
	if not value is Dictionary:
		return

	var source: Dictionary = value as Dictionary
	for key_value: Variant in source.keys():
		var key: String = String(key_value)
		var day_value: Variant = source.get(key_value, [])
		if not day_value is Array:
			continue

		var clean_day: Array[Dictionary] = _empty_day()
		var source_day: Array = day_value as Array
		var limit: int = mini(source_day.size(), SLOT_COUNT_PER_DAY)
		for slot_index: int in range(limit):
			var slot_value: Variant = source_day[slot_index]
			if slot_value is Dictionary:
				clean_day[slot_index] = (slot_value as Dictionary).duplicate(true)
		_days[key] = clean_day


func get_save_data() -> Dictionary:
	return _days.duplicate(true)


func get_day_slots(
	channel_number: int,
	week_number: int,
	day_index: int
) -> Array[Dictionary]:
	var key: String = _make_key(channel_number, week_number, day_index)
	if not _days.has(key):
		return _empty_day()

	var day_value: Variant = _days.get(key, [])
	if not day_value is Array:
		return _empty_day()

	var result: Array[Dictionary] = _empty_day()
	var day: Array = day_value as Array
	var limit: int = mini(day.size(), SLOT_COUNT_PER_DAY)
	for slot_index: int in range(limit):
		var slot_value: Variant = day[slot_index]
		if slot_value is Dictionary:
			result[slot_index] = (slot_value as Dictionary).duplicate(true)
	return result


func can_place_program(
	channel_number: int,
	week_number: int,
	day_index: int,
	start_slot: int,
	program: Dictionary
) -> bool:
	if channel_number <= 0:
		return false
	if week_number < 1 or week_number > 52:
		return false
	if day_index < 0 or day_index > 6:
		return false
	if start_slot < 0 or start_slot >= SLOT_COUNT_PER_DAY:
		return false

	var duration_minutes: int = maxi(int(program.get("duration_minutes", SLOT_MINUTES)), SLOT_MINUTES)
	var slots_needed: int = maxi(1, int(ceil(float(duration_minutes) / float(SLOT_MINUTES))))
	if start_slot + slots_needed > SLOT_COUNT_PER_DAY:
		return false

	var day: Array[Dictionary] = get_day_slots(channel_number, week_number, day_index)
	for slot_index: int in range(start_slot, start_slot + slots_needed):
		if not day[slot_index].is_empty():
			return false

	return true


func place_program(
	channel_number: int,
	week_number: int,
	day_index: int,
	start_slot: int,
	program: Dictionary,
	episode_data: Dictionary = {}
) -> bool:
	if not can_place_program(channel_number, week_number, day_index, start_slot, program):
		return false

	var duration_minutes: int = maxi(int(program.get("duration_minutes", SLOT_MINUTES)), SLOT_MINUTES)
	var slots_needed: int = maxi(1, int(ceil(float(duration_minutes) / float(SLOT_MINUTES))))
	var key: String = _make_key(channel_number, week_number, day_index)
	var day: Array[Dictionary] = get_day_slots(channel_number, week_number, day_index)
	var program_id: String = String(program.get("id", ""))
	var program_name: String = String(program.get("name", "Programme"))
	var episode_global: int = int(episode_data.get("episode_global", 0))
	var season_number: int = int(episode_data.get("season_number", 0))
	var episode_number: int = int(episode_data.get("episode_number", 0))

	day[start_slot] = {
		"kind": "start",
		"program_id": program_id,
		"program_name": program_name,
		"duration_minutes": duration_minutes,
		"start_slot": start_slot,
		"slots_count": slots_needed,
		"episode_global": episode_global,
		"season_number": season_number,
		"episode_number": episode_number
	}

	for slot_index: int in range(start_slot + 1, start_slot + slots_needed):
		day[slot_index] = {
			"kind": "continuation",
			"program_id": program_id,
			"program_name": program_name,
			"duration_minutes": duration_minutes,
			"start_slot": start_slot,
			"episode_global": episode_global,
			"season_number": season_number,
			"episode_number": episode_number
		}

	_days[key] = day
	return true


func update_program_episode(
	channel_number: int,
	week_number: int,
	day_index: int,
	start_slot: int,
	episode_data: Dictionary
) -> bool:
	if start_slot < 0 or start_slot >= SLOT_COUNT_PER_DAY:
		return false

	var key: String = _make_key(channel_number, week_number, day_index)
	var day: Array[Dictionary] = get_day_slots(channel_number, week_number, day_index)
	var start_entry: Dictionary = day[start_slot]
	if start_entry.is_empty() or String(start_entry.get("kind", "")) != "start":
		return false

	var slots_count: int = maxi(int(start_entry.get("slots_count", 1)), 1)
	var episode_global: int = int(episode_data.get("episode_global", 0))
	var season_number: int = int(episode_data.get("season_number", 0))
	var episode_number: int = int(episode_data.get("episode_number", 0))
	if episode_global <= 0:
		return false

	var end_slot: int = mini(start_slot + slots_count, SLOT_COUNT_PER_DAY)
	for slot_index: int in range(start_slot, end_slot):
		var entry: Dictionary = day[slot_index]
		if entry.is_empty():
			continue
		if int(entry.get("start_slot", start_slot)) != start_slot:
			continue
		entry["episode_global"] = episode_global
		entry["season_number"] = season_number
		entry["episode_number"] = episode_number
		day[slot_index] = entry

	_days[key] = day
	return true


func _make_key(channel_number: int, week_number: int, day_index: int) -> String:
	return "%d:%d:%d" % [channel_number, week_number, day_index]


func _empty_day() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	result.resize(SLOT_COUNT_PER_DAY)
	for slot_index: int in range(SLOT_COUNT_PER_DAY):
		result[slot_index] = {}
	return result
