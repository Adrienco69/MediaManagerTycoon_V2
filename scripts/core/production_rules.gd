class_name ProductionRules
extends RefCounted

const DAY_MINUTES: int = 1440
const FORMATS: Array[String] = [
	"Série",
	"Shortcom",
	"Série-téléfilm",
	"Téléfilm",
	"Film"
]


static func get_formats() -> Array[String]:
	var result: Array[String] = []
	for format_name: String in FORMATS:
		result.append(format_name)
	return result


static func get_durations(format_name: String) -> Array[int]:
	var result: Array[int] = []
	match format_name:
		"Série":
			result = [30, 60, 90]
		"Shortcom":
			result = [30]
		"Série-téléfilm":
			result = [60, 90]
		"Téléfilm":
			result = [90, 120]
		"Film":
			result = [90, 120, 150, 180]
	return result


static func is_single_unit(format_name: String) -> bool:
	return format_name == "Téléfilm" or format_name == "Film"


static func get_cost(format_name: String) -> int:
	if format_name == "Téléfilm" or format_name == "Film":
		return 1700
	return 850


static func get_total_minutes(
	format_name: String,
	duration_minutes: int,
	episode_count: int
) -> int:
	var episodes: int = maxi(episode_count, 1)
	var total_days: int = 0

	match format_name:
		"Série":
			total_days = episodes * 7
		"Shortcom":
			total_days = int(ceil(float(episodes) / 2.0))
		"Série-téléfilm":
			if duration_minutes == 60:
				total_days = episodes * 14
			elif duration_minutes == 90:
				total_days = episodes * 21
		"Téléfilm":
			if duration_minutes == 90:
				total_days = 21
			elif duration_minutes == 120:
				total_days = 28
		"Film":
			match duration_minutes:
				90:
					total_days = 21
				120:
					total_days = 28
				150:
					total_days = 35
				180:
					total_days = 42

	return total_days * DAY_MINUTES


static func get_total_days(
	format_name: String,
	duration_minutes: int,
	episode_count: int
) -> int:
	var total_minutes: int = get_total_minutes(format_name, duration_minutes, episode_count)
	if total_minutes <= 0:
		return 0
	return int(ceil(float(total_minutes) / float(DAY_MINUTES)))


static func get_produced_episode_count(production: Dictionary) -> int:
	var total_episodes: int = maxi(int(production.get("episodes_total", 1)), 1)
	var remaining_minutes: int = maxi(int(production.get("production_remaining_minutes", 0)), 0)
	if remaining_minutes <= 0:
		return total_episodes

	var total_minutes: int = maxi(int(production.get("production_total_minutes", 0)), 0)
	var elapsed_minutes: int = maxi(total_minutes - remaining_minutes, 0)
	var format_name: String = String(production.get("format", ""))
	var duration_minutes: int = int(production.get("duration_minutes", 0))
	var produced: int = 0

	match format_name:
		"Série":
			produced = int(elapsed_minutes / (7 * DAY_MINUTES))
		"Shortcom":
			produced = int(elapsed_minutes / DAY_MINUTES) * 2
		"Série-téléfilm":
			var episode_days: int = 14 if duration_minutes == 60 else 21
			produced = int(elapsed_minutes / (episode_days * DAY_MINUTES))
		_:
			produced = 0

	return clampi(produced, 0, total_episodes)


static func format_remaining_time(remaining_minutes: int) -> String:
	var safe_minutes: int = maxi(remaining_minutes, 0)
	var days: int = int(safe_minutes / DAY_MINUTES)
	var rest: int = safe_minutes % DAY_MINUTES
	var hours: int = int(rest / 60)
	var minutes: int = rest % 60

	if days > 0 and hours == 0 and minutes == 0:
		return "%d j" % days
	if days > 0:
		return "%d j %02dh%02d" % [days, hours, minutes]
	return "%02dh%02d" % [hours, minutes]
