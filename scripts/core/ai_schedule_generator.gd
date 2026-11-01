class_name AIScheduleGenerator
extends RefCounted

const SLOTS_PER_DAY: int = 48
const SLOT_MINUTES: int = 30


static func build_day(
	programs: Array[Dictionary],
	schedule_seed: int,
	week_number: int,
	day_index: int
) -> Array[String]:
	var result: Array[String] = []
	result.resize(SLOTS_PER_DAY)
	for index: int in range(SLOTS_PER_DAY):
		result[index] = "Vide"

	if programs.is_empty():
		return result

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(schedule_seed) + (week_number * 1009) + (day_index * 97)

	var slot_index: int = 0
	var previous_program_id: String = ""

	while slot_index < SLOTS_PER_DAY:
		var remaining_slots: int = SLOTS_PER_DAY - slot_index
		var candidates: Array[Dictionary] = []

		for program: Dictionary in programs:
			var duration_minutes: int = maxi(int(program.get("duration_minutes", SLOT_MINUTES)), SLOT_MINUTES)
			var required_slots: int = maxi(int(ceil(float(duration_minutes) / float(SLOT_MINUTES))), 1)
			if required_slots <= remaining_slots:
				candidates.append(program)

		if candidates.is_empty():
			break

		var selected: Dictionary = candidates[rng.randi_range(0, candidates.size() - 1)]
		if candidates.size() > 1:
			var attempts: int = 0
			while String(selected.get("id", "")) == previous_program_id and attempts < 5:
				selected = candidates[rng.randi_range(0, candidates.size() - 1)]
				attempts += 1

		var program_name: String = String(selected.get("name", "Programme"))
		var program_id: String = String(selected.get("id", program_name))
		var duration_minutes: int = maxi(int(selected.get("duration_minutes", SLOT_MINUTES)), SLOT_MINUTES)
		var required_slots: int = maxi(int(ceil(float(duration_minutes) / float(SLOT_MINUTES))), 1)

		for offset: int in range(required_slots):
			if slot_index + offset >= SLOTS_PER_DAY:
				break
			result[slot_index + offset] = program_name if offset == 0 else "↳ %s" % program_name

		previous_program_id = program_id
		slot_index += required_slots

	return result
