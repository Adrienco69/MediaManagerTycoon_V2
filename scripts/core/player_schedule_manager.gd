class_name PlayerScheduleManager
extends RefCounted

const SLOT_COUNT_PER_DAY: int = 48
const SLOT_MINUTES: int = 30
const DAYS_PER_WEEK: int = 7
const WEEKS_PER_YEAR: int = 52
const TOTAL_SLOTS_PER_YEAR: int = SLOT_COUNT_PER_DAY * DAYS_PER_WEEK * WEEKS_PER_YEAR

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


func can_fit_program(
	channel_number: int,
	week_number: int,
	day_index: int,
	start_slot: int,
	program: Dictionary
) -> bool:
	if channel_number <= 0:
		return false
	if week_number < 1 or week_number > WEEKS_PER_YEAR:
		return false
	if day_index < 0 or day_index >= DAYS_PER_WEEK:
		return false
	if start_slot < 0 or start_slot >= SLOT_COUNT_PER_DAY:
		return false

	var absolute_start: int = _to_absolute_slot(week_number, day_index, start_slot)
	var slots_needed: int = _get_slots_needed(program)
	return absolute_start + slots_needed <= TOTAL_SLOTS_PER_YEAR


func can_place_program(
	channel_number: int,
	week_number: int,
	day_index: int,
	start_slot: int,
	program: Dictionary
) -> bool:
	if not can_fit_program(channel_number, week_number, day_index, start_slot, program):
		return false
	return get_conflicts(channel_number, week_number, day_index, start_slot, program).is_empty()


func get_conflicts(
	channel_number: int,
	week_number: int,
	day_index: int,
	start_slot: int,
	program: Dictionary,
	ignored_start_slot: int = -1
) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not can_fit_program(channel_number, week_number, day_index, start_slot, program):
		return result

	var ignored_broadcast_id: String = ""
	if ignored_start_slot >= 0:
		var source_day: Array[Dictionary] = get_day_slots(channel_number, week_number, day_index)
		if ignored_start_slot < source_day.size():
			ignored_broadcast_id = String(source_day[ignored_start_slot].get("broadcast_id", ""))

	var seen: Dictionary = {}
	var absolute_start: int = _to_absolute_slot(week_number, day_index, start_slot)
	var slots_needed: int = _get_slots_needed(program)
	for offset: int in range(slots_needed):
		var position: Dictionary = _from_absolute_slot(absolute_start + offset)
		var day: Array[Dictionary] = get_day_slots(
			channel_number,
			int(position["week"]),
			int(position["day"])
		)
		var entry: Dictionary = day[int(position["slot"])]
		if entry.is_empty():
			continue

		var broadcast_id: String = String(entry.get("broadcast_id", ""))
		if not ignored_broadcast_id.is_empty() and broadcast_id == ignored_broadcast_id:
			continue

		var identity: String = broadcast_id
		if identity.is_empty():
			identity = "%d:%d:%d" % [
				int(entry.get("origin_week", int(position["week"]))),
				int(entry.get("origin_day", int(position["day"]))),
				int(entry.get("origin_slot", int(entry.get("start_slot", position["slot"]))))
			]
		if seen.has(identity):
			continue
		seen[identity] = true

		var origin: Dictionary = _get_origin_entry(channel_number, entry, position)
		if not origin.is_empty():
			result.append(origin)
	return result


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
	return _write_program(channel_number, week_number, day_index, start_slot, program, episode_data)


func replace_program(
	channel_number: int,
	week_number: int,
	day_index: int,
	start_slot: int,
	program: Dictionary,
	episode_data: Dictionary = {}
) -> bool:
	if not can_fit_program(channel_number, week_number, day_index, start_slot, program):
		return false

	var conflicts: Array[Dictionary] = get_conflicts(
		channel_number,
		week_number,
		day_index,
		start_slot,
		program
	)
	for conflict: Dictionary in conflicts:
		_remove_broadcast_by_entry(channel_number, conflict)

	return _write_program(channel_number, week_number, day_index, start_slot, program, episode_data)


func remove_program_at(
	channel_number: int,
	week_number: int,
	day_index: int,
	slot_index: int
) -> bool:
	if slot_index < 0 or slot_index >= SLOT_COUNT_PER_DAY:
		return false

	var day: Array[Dictionary] = get_day_slots(channel_number, week_number, day_index)
	var entry: Dictionary = day[slot_index]
	if entry.is_empty():
		return false
	return _remove_broadcast_by_entry(channel_number, entry)


func remove_automation(channel_number: int, automation_id: String) -> int:
	if channel_number <= 0 or automation_id.is_empty():
		return 0

	var broadcasts: Dictionary = {}
	for key_value: Variant in _days.keys():
		var key: String = String(key_value)
		var parts: PackedStringArray = key.split(":")
		if parts.size() < 3 or int(parts[0]) != channel_number:
			continue
		var day_value: Variant = _days.get(key, [])
		if not day_value is Array:
			continue
		for entry_value: Variant in day_value:
			if not entry_value is Dictionary:
				continue
			var entry: Dictionary = entry_value as Dictionary
			if String(entry.get("automation_id", "")) != automation_id:
				continue
			var broadcast_id: String = String(entry.get("broadcast_id", ""))
			if not broadcast_id.is_empty():
				broadcasts[broadcast_id] = true

	var removed_count: int = 0
	for broadcast_id_value: Variant in broadcasts.keys():
		if _remove_broadcast_by_id(channel_number, String(broadcast_id_value)):
			removed_count += 1
	return removed_count


func move_program(
	channel_number: int,
	source_week: int,
	source_day: int,
	source_slot: int,
	target_week: int,
	target_day: int,
	target_slot: int,
	replace_conflicts: bool = false
) -> bool:
	var source_slots: Array[Dictionary] = get_day_slots(channel_number, source_week, source_day)
	if source_slot < 0 or source_slot >= source_slots.size():
		return false
	var source_entry: Dictionary = source_slots[source_slot]
	if source_entry.is_empty():
		return false

	var source_position: Dictionary = {
		"week": source_week,
		"day": source_day,
		"slot": source_slot
	}
	var start_entry: Dictionary = _get_origin_entry(channel_number, source_entry, source_position)
	if start_entry.is_empty():
		return false

	var origin_week: int = int(start_entry.get("origin_week", source_week))
	var origin_day: int = int(start_entry.get("origin_day", source_day))
	var origin_slot: int = int(start_entry.get("origin_slot", start_entry.get("start_slot", source_slot)))
	var program: Dictionary = {
		"id": String(start_entry.get("program_id", "")),
		"name": String(start_entry.get("program_name", "Programme")),
		"duration_minutes": int(start_entry.get("duration_minutes", SLOT_MINUTES))
	}
	var episode_data: Dictionary = {
		"episode_global": int(start_entry.get("episode_global", 0)),
		"season_number": int(start_entry.get("season_number", 0)),
		"episode_number": int(start_entry.get("episode_number", 0)),
		"automation_id": String(start_entry.get("automation_id", "")),
		"automation_frequency": String(start_entry.get("automation_frequency", ""))
	}

	if not can_fit_program(channel_number, target_week, target_day, target_slot, program):
		return false

	var backup: Dictionary = start_entry.duplicate(true)
	if not _remove_broadcast_by_entry(channel_number, start_entry):
		return false

	var conflicts: Array[Dictionary] = get_conflicts(
		channel_number,
		target_week,
		target_day,
		target_slot,
		program
	)
	if not conflicts.is_empty() and not replace_conflicts:
		_write_program(channel_number, origin_week, origin_day, origin_slot, program, episode_data)
		return false

	if replace_conflicts:
		for conflict: Dictionary in conflicts:
			_remove_broadcast_by_entry(channel_number, conflict)

	if _write_program(channel_number, target_week, target_day, target_slot, program, episode_data):
		return true

	_write_program(
		channel_number,
		origin_week,
		origin_day,
		origin_slot,
		program,
		{
			"episode_global": int(backup.get("episode_global", 0)),
			"season_number": int(backup.get("season_number", 0)),
			"episode_number": int(backup.get("episode_number", 0)),
			"automation_id": String(backup.get("automation_id", "")),
			"automation_frequency": String(backup.get("automation_frequency", ""))
		}
	)
	return false


func update_program_episode(
	channel_number: int,
	week_number: int,
	day_index: int,
	start_slot: int,
	episode_data: Dictionary
) -> bool:
	var day: Array[Dictionary] = get_day_slots(channel_number, week_number, day_index)
	if start_slot < 0 or start_slot >= day.size():
		return false
	var entry: Dictionary = day[start_slot]
	if entry.is_empty():
		return false

	var broadcast_id: String = String(entry.get("broadcast_id", ""))
	if broadcast_id.is_empty():
		return false
	var episode_global: int = int(episode_data.get("episode_global", 0))
	if episode_global <= 0:
		return false

	for key_value: Variant in _days.keys():
		var key: String = String(key_value)
		var parts: PackedStringArray = key.split(":")
		if parts.size() < 3 or int(parts[0]) != channel_number:
			continue
		var stored_day: Array = (_days.get(key, []) as Array).duplicate(true)
		var changed: bool = false
		for slot_index: int in range(stored_day.size()):
			var value: Variant = stored_day[slot_index]
			if not value is Dictionary:
				continue
			var stored_entry: Dictionary = value as Dictionary
			if String(stored_entry.get("broadcast_id", "")) != broadcast_id:
				continue
			stored_entry["episode_global"] = episode_global
			stored_entry["season_number"] = int(episode_data.get("season_number", 0))
			stored_entry["episode_number"] = int(episode_data.get("episode_number", 0))
			stored_day[slot_index] = stored_entry
			changed = true
		if changed:
			_days[key] = stored_day
	return true


func _write_program(
	channel_number: int,
	week_number: int,
	day_index: int,
	start_slot: int,
	program: Dictionary,
	episode_data: Dictionary
) -> bool:
	if not can_fit_program(channel_number, week_number, day_index, start_slot, program):
		return false

	var duration_minutes: int = maxi(int(program.get("duration_minutes", SLOT_MINUTES)), SLOT_MINUTES)
	var slots_needed: int = _get_slots_needed(program)
	var program_id: String = String(program.get("id", ""))
	var program_name: String = String(program.get("name", "Programme"))
	var episode_global: int = int(episode_data.get("episode_global", 0))
	var season_number: int = int(episode_data.get("season_number", 0))
	var episode_number: int = int(episode_data.get("episode_number", 0))
	var automation_id: String = String(episode_data.get("automation_id", ""))
	var automation_frequency: String = String(episode_data.get("automation_frequency", ""))
	var broadcast_id: String = "%d_%d_%d_%d_%d" % [
		channel_number,
		week_number,
		day_index,
		start_slot,
		Time.get_ticks_usec()
	]
	var absolute_start: int = _to_absolute_slot(week_number, day_index, start_slot)

	for offset: int in range(slots_needed):
		var position: Dictionary = _from_absolute_slot(absolute_start + offset)
		var target_week: int = int(position["week"])
		var target_day: int = int(position["day"])
		var target_slot: int = int(position["slot"])
		var key: String = _make_key(channel_number, target_week, target_day)
		var day: Array[Dictionary] = get_day_slots(channel_number, target_week, target_day)
		day[target_slot] = {
			"kind": "start" if offset == 0 else "continuation",
			"program_id": program_id,
			"program_name": program_name,
			"duration_minutes": duration_minutes,
			"start_slot": start_slot,
			"slots_count": slots_needed,
			"episode_global": episode_global,
			"season_number": season_number,
			"episode_number": episode_number,
			"automation_id": automation_id,
			"automation_frequency": automation_frequency,
			"broadcast_id": broadcast_id,
			"origin_week": week_number,
			"origin_day": day_index,
			"origin_slot": start_slot
		}
		_days[key] = day
	return true


func _remove_broadcast_by_entry(channel_number: int, entry: Dictionary) -> bool:
	var broadcast_id: String = String(entry.get("broadcast_id", ""))
	if not broadcast_id.is_empty():
		return _remove_broadcast_by_id(channel_number, broadcast_id)

	var origin_week: int = int(entry.get("origin_week", 0))
	var origin_day: int = int(entry.get("origin_day", -1))
	var origin_slot: int = int(entry.get("origin_slot", entry.get("start_slot", -1)))
	if origin_week <= 0 or origin_day < 0 or origin_slot < 0:
		return false
	return _remove_legacy_broadcast(channel_number, origin_week, origin_day, origin_slot)


func _remove_broadcast_by_id(channel_number: int, broadcast_id: String) -> bool:
	if broadcast_id.is_empty():
		return false
	var removed: bool = false
	for key_value: Variant in _days.keys():
		var key: String = String(key_value)
		var parts: PackedStringArray = key.split(":")
		if parts.size() < 3 or int(parts[0]) != channel_number:
			continue
		var day_value: Variant = _days.get(key, [])
		if not day_value is Array:
			continue
		var day: Array = (day_value as Array).duplicate(true)
		var changed: bool = false
		for slot_index: int in range(day.size()):
			var value: Variant = day[slot_index]
			if not value is Dictionary:
				continue
			if String((value as Dictionary).get("broadcast_id", "")) == broadcast_id:
				day[slot_index] = {}
				changed = true
				removed = true
		if changed:
			_days[key] = day
	return removed


func _remove_legacy_broadcast(
	channel_number: int,
	week_number: int,
	day_index: int,
	start_slot: int
) -> bool:
	var day: Array[Dictionary] = get_day_slots(channel_number, week_number, day_index)
	if start_slot < 0 or start_slot >= day.size():
		return false
	var start_entry: Dictionary = day[start_slot]
	if start_entry.is_empty():
		return false
	var slots_count: int = maxi(int(start_entry.get("slots_count", 1)), 1)
	var end_slot: int = mini(start_slot + slots_count, SLOT_COUNT_PER_DAY)
	for slot_index: int in range(start_slot, end_slot):
		var current: Dictionary = day[slot_index]
		if not current.is_empty() and int(current.get("start_slot", start_slot)) == start_slot:
			day[slot_index] = {}
	_days[_make_key(channel_number, week_number, day_index)] = day
	return true


func _get_origin_entry(
	channel_number: int,
	entry: Dictionary,
	fallback_position: Dictionary
) -> Dictionary:
	var origin_week: int = int(entry.get("origin_week", int(fallback_position.get("week", 1))))
	var origin_day: int = int(entry.get("origin_day", int(fallback_position.get("day", 0))))
	var origin_slot: int = int(entry.get("origin_slot", entry.get("start_slot", fallback_position.get("slot", 0))))
	var origin_day_slots: Array[Dictionary] = get_day_slots(channel_number, origin_week, origin_day)
	if origin_slot < 0 or origin_slot >= origin_day_slots.size():
		return {}
	var origin: Dictionary = origin_day_slots[origin_slot]
	if origin.is_empty():
		return entry.duplicate(true)
	return origin.duplicate(true)


func _get_slots_needed(program: Dictionary) -> int:
	var duration_minutes: int = maxi(int(program.get("duration_minutes", SLOT_MINUTES)), SLOT_MINUTES)
	return maxi(1, int(ceil(float(duration_minutes) / float(SLOT_MINUTES))))


func _to_absolute_slot(week_number: int, day_index: int, slot_index: int) -> int:
	return (((week_number - 1) * DAYS_PER_WEEK) + day_index) * SLOT_COUNT_PER_DAY + slot_index


func _from_absolute_slot(absolute_slot: int) -> Dictionary:
	var absolute_day: int = int(absolute_slot / SLOT_COUNT_PER_DAY)
	return {
		"week": int(absolute_day / DAYS_PER_WEEK) + 1,
		"day": absolute_day % DAYS_PER_WEEK,
		"slot": absolute_slot % SLOT_COUNT_PER_DAY
	}


func _make_key(channel_number: int, week_number: int, day_index: int) -> String:
	return "%d:%d:%d" % [channel_number, week_number, day_index]


func _empty_day() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	result.resize(SLOT_COUNT_PER_DAY)
	for slot_index: int in range(SLOT_COUNT_PER_DAY):
		result[slot_index] = {}
	return result
