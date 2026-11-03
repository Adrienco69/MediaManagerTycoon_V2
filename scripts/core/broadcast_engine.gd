class_name BroadcastEngine
extends RefCounted

# Diffusion, audience et revenu : une seule transaction à l'heure de début.
const SLOT_MINUTES: int = 30
const MINUTES_PER_DAY: int = 1440
const DAYS_PER_YEAR: int = 364
const MINUTES_PER_YEAR: int = DAYS_PER_YEAR * MINUTES_PER_DAY
const MONTH_NAMES: Array[String] = [
	"Floréal", "Clôture", "Crépuscule", "Zénith",
	"Origine", "Essor", "Brumal"
]
const MONTH_WEEKS: Array[int] = [7, 8, 7, 8, 7, 8, 7]
const DAY_NAMES: Array[String] = [
	"Lundi", "Mardi", "Mercredi", "Jeudi",
	"Vendredi", "Samedi", "Dimanche"
]

# Montants documentés ; les autres valeurs sont provisoires et centralisées ici.
const JT_CC: int = 5
const GAME_CC: int = 10
const TALK_CC: int = 15
const SERIES_CC: int = 30
const FILM_CC: int = 50
const OTHER_CC: int = 15

var history: Array[Dictionary] = []
var processed_ids: Dictionary = {}
var total_revenue: int = 0


func reset() -> void:
	history.clear()
	processed_ids.clear()
	total_revenue = 0


func load_data(value: Variant) -> void:
	reset()
	if not value is Dictionary:
		return
	var data: Dictionary = value as Dictionary
	var history_value: Variant = data.get("history", [])
	if history_value is Array:
		for item: Variant in history_value:
			if item is Dictionary:
				history.append((item as Dictionary).duplicate(true))
	var processed_value: Variant = data.get("processed_ids", {})
	if processed_value is Dictionary:
		processed_ids = (processed_value as Dictionary).duplicate(true)
	else:
		for item: Dictionary in history:
			processed_ids[String(item.get("id", ""))] = true
	total_revenue = maxi(int(data.get("total_revenue", 0)), 0)


func get_save_data() -> Dictionary:
	return {
		"history": history.duplicate(true),
		"processed_ids": processed_ids.duplicate(true),
		"total_revenue": total_revenue
	}


func get_history() -> Array[Dictionary]:
	return history.duplicate(true)


# Les bornes sont [début, fin), ce qui gère une accélération traversant
# plusieurs jours, mois et années sans perdre de créneau.
func process_interval(
	start_year: int,
	start_year_minute: int,
	minutes_elapsed: int,
	channel: Dictionary,
	schedule_manager: PlayerScheduleManager,
	production_manager: ProductionManager
) -> Dictionary:
	var result: Dictionary = {"revenue": 0, "count": 0}
	if minutes_elapsed <= 0 or channel.is_empty():
		return result
	var channel_number: int = int(channel.get("mmtn_number", 0))
	if channel_number <= 0:
		return result
	var start_absolute: int = (start_year - 1) * MINUTES_PER_YEAR + start_year_minute
	var end_absolute: int = start_absolute + minutes_elapsed
	var boundary: int = start_absolute
	if posmod(boundary, SLOT_MINUTES) != 0:
		boundary += SLOT_MINUTES - posmod(boundary, SLOT_MINUTES)
	while boundary < end_absolute:
		var zero_year: int = int(boundary / MINUTES_PER_YEAR)
		var year_number: int = zero_year + 1
		var year_minute: int = boundary % MINUTES_PER_YEAR
		var day_number: int = int(year_minute / MINUTES_PER_DAY)
		var slot_number: int = int((year_minute % MINUTES_PER_DAY) / SLOT_MINUTES)
		var week_number: int = int(day_number / 7) + 1
		var day_index: int = day_number % 7
		var day_slots: Array[Dictionary] = schedule_manager.get_day_slots(
			channel_number, week_number, day_index
		)
		if slot_number < day_slots.size():
			var entry: Dictionary = day_slots[slot_number]
			if String(entry.get("kind", "")) == "start":
				var broadcast_id: String = String(entry.get("broadcast_id", ""))
				if broadcast_id.is_empty():
					broadcast_id = "%d:%d:%d:%d" % [
						channel_number, week_number, day_index, slot_number
					]
				var transaction_id: String = "%d:%s" % [year_number, broadcast_id]
				if not processed_ids.has(transaction_id):
					var event: Dictionary = _build_event(
						transaction_id, year_number, day_number, slot_number,
						entry, channel, production_manager
					)
					if not event.is_empty():
						processed_ids[transaction_id] = true
						history.append(event)
						var amount: int = int(event.get("revenue_cc", 0))
						total_revenue += amount
						result["revenue"] = int(result["revenue"]) + amount
						result["count"] = int(result["count"]) + 1
		boundary += SLOT_MINUTES
	return result


func _build_event(
	transaction_id: String,
	year_number: int,
	day_number: int,
	slot_number: int,
	entry: Dictionary,
	channel: Dictionary,
	production_manager: ProductionManager
) -> Dictionary:
	var program_id: String = String(entry.get("program_id", ""))
	if program_id.is_empty():
		return {}
	var program: Dictionary = production_manager.get_program(program_id)
	if program.is_empty():
		return {}
	var episode_global: int = int(entry.get("episode_global", 0))
	var season_number: int = int(entry.get("season_number", 0))
	var episode_number: int = int(entry.get("episode_number", 0))
	var previous: int = 0
	var same_episode: int = 0
	for earlier: Dictionary in history:
		if String(earlier.get("program_id", "")) != program_id:
			continue
		previous += 1
		if int(earlier.get("episode_global", 0)) == episode_global:
			same_episode += 1
	var first_run: bool = same_episode == 0
	var format_name: String = String(program.get("format", program.get("family", "")))
	var revenue: int = get_format_revenue(format_name)
	var audience: int = _calculate_audience(
		program_id, slot_number, previous, same_episode, format_name
	)
	var date_text: String = _date_text(year_number, day_number)
	var time_text: String = "%02d:%02d" % [
		int(slot_number / 2), (slot_number % 2) * SLOT_MINUTES
	]
	var broadcast_type: String = "Inédit" if first_run else "Rediffusion"
	var recorded: bool = production_manager.record_broadcast(
		program_id, season_number, episode_number, date_text,
		time_text, String(channel.get("name", "Chaîne")), broadcast_type,
		audience, revenue
	)
	if not recorded:
		return {}
	return {
		"id": transaction_id,
		"year": year_number,
		"day_of_year": day_number,
		"slot": slot_number,
		"date": date_text,
		"time": time_text,
		"channel_number": int(channel.get("mmtn_number", 0)),
		"channel_name": String(channel.get("name", "Chaîne")),
		"program_id": program_id,
		"program_name": String(program.get("name", "")),
		"episode_global": episode_global,
		"season_number": season_number,
		"episode_number": episode_number,
		"type": broadcast_type,
		"audience_viewers": audience,
		"revenue_cc": revenue
	}


static func get_format_revenue(format_name: String) -> int:
	var format_key: String = format_name.strip_edges().to_lower()
	if format_key == "jt" or "journal" in format_key or "information" in format_key:
		return JT_CC
	if "jeux tv" in format_key or "jeu tv" in format_key:
		return GAME_CC
	if "talk" in format_key:
		return TALK_CC
	if "film" in format_key or "cinéma" in format_key:
		return FILM_CC
	if "série" in format_key or "serie" in format_key or "shortcom" in format_key:
		return SERIES_CC
	return OTHER_CC


static func _calculate_audience(
	program_id: String,
	slot_number: int,
	previous: int,
	same_episode: int,
	format_name: String
) -> int:
	# Premier modèle technique, sans concurrence IA : à équilibrer.
	var hour_number: int = int(slot_number / 2)
	var base: int = 1800000
	if hour_number >= 21 and hour_number < 24:
		base = 4600000
	elif hour_number >= 18:
		base = 3200000
	elif hour_number >= 10:
		base = 2400000
	elif hour_number < 6:
		base = 650000
	var stable_variation: int = posmod(program_id.hash(), 1000001) - 500000
	var format_modifier: float = 1.0
	if "film" in format_name.to_lower():
		format_modifier = 1.12
	elif "jt" == format_name.to_lower():
		format_modifier = 0.9
	var fatigue: float = maxf(0.35, 1.0 - (float(same_episode) * 0.12) - (float(previous) * 0.008))
	return maxi(int(round((base + stable_variation) * format_modifier * fatigue)), 100000)


static func _date_text(year_number: int, day_number: int) -> String:
	var remaining: int = day_number
	for index: int in range(MONTH_WEEKS.size()):
		var month_days: int = MONTH_WEEKS[index] * 7
		if remaining < month_days:
			return "%s %d %s %04d" % [
				DAY_NAMES[day_number % 7], remaining + 1,
				MONTH_NAMES[index], year_number
			]
		remaining -= month_days
	return "%s %d Brumal %04d" % [DAY_NAMES[day_number % 7], 49, year_number]
