extends Node

const PlayerChannelManagerScript = preload("res://scripts/core/player_channel_manager.gd")
const PlayerScheduleManagerScript = preload("res://scripts/core/player_schedule_manager.gd")
const MMTNRegistryScript = preload("res://scripts/core/mmtn_registry.gd")
const ProductionManagerScript = preload("res://scripts/core/production_manager.gd")
const ProductionRulesScript = preload("res://scripts/core/production_rules.gd")
const BroadcastEngineScript = preload("res://scripts/core/broadcast_engine.gd")

signal time_changed
signal credits_changed(new_value: int)
signal speed_changed(new_mode: int)
signal identity_changed(player_name: String, company_name: String)
signal channel_created(channel: Dictionary)
signal programs_changed
signal productions_changed
signal schedule_changed
signal broadcast_completed(event: Dictionary)

enum TimeMode {
	PAUSED,
	HOUR,
	DAY,
	WEEK
}

const DAYS := [
	"Lundi",
	"Mardi",
	"Mercredi",
	"Jeudi",
	"Vendredi",
	"Samedi",
	"Dimanche"
]

const MONTHS := [
	{"name": "Floréal", "weeks": 7},
	{"name": "Clôture", "weeks": 8},
	{"name": "Crépuscule", "weeks": 7},
	{"name": "Zénith", "weeks": 8},
	{"name": "Origine", "weeks": 7},
	{"name": "Essor", "weeks": 8},
	{"name": "Brumal", "weeks": 7}
]

const STARTING_CREDITS := 1200

const GAME_MINUTES_PER_REAL_SECOND := {
	TimeMode.HOUR: 6.0,
	TimeMode.DAY: 72.0,
	TimeMode.WEEK: 336.0
}

var player_name: String = ""
var company_name: String = ""
var credits: int = STARTING_CREDITS
var year: int = 1
var month_index: int = 0
var week_in_month: int = 1
var week_in_year: int = 1
var day_in_week: int = 1
var hour: int = 0
var minute: int = 0
var time_mode: TimeMode = TimeMode.PAUSED

var _minute_buffer: float = 0.0
var _player_channel_manager: PlayerChannelManager = PlayerChannelManagerScript.new()
var _player_schedule_manager: PlayerScheduleManager = PlayerScheduleManagerScript.new()
var _mmtn_registry: MMTNRegistry = MMTNRegistryScript.new()
var _production_manager: ProductionManager = ProductionManagerScript.new()
var _broadcast_engine: BroadcastEngine = BroadcastEngineScript.new()


func _ready() -> void:
	_player_channel_manager.channel_created.connect(_on_channel_created)


func _process(delta: float) -> void:
	if time_mode == TimeMode.PAUSED:
		return

	_minute_buffer += delta * GAME_MINUTES_PER_REAL_SECOND[time_mode]
	var whole_minutes: int = int(floor(_minute_buffer))
	if whole_minutes <= 0:
		return

	_minute_buffer -= whole_minutes
	advance_minutes(whole_minutes)


func start_new_game(new_player_name: String, new_company_name: String) -> void:
	player_name = new_player_name.strip_edges()
	company_name = new_company_name.strip_edges()
	credits = STARTING_CREDITS
	year = 1
	month_index = 0
	week_in_month = 1
	week_in_year = 1
	day_in_week = 1
	hour = 0
	minute = 0
	time_mode = TimeMode.PAUSED
	_minute_buffer = 0.0
	_player_channel_manager.reset()
	_player_schedule_manager.reset()
	_mmtn_registry.reset()
	_production_manager.reset()
	_broadcast_engine.reset()

	_emit_full_state_refresh()


func get_save_data() -> Dictionary:
	return {
		"player_name": player_name,
		"company_name": company_name,
		"credits": credits,
		"calendar": {
			"year": year,
			"month_index": month_index,
			"week_in_month": week_in_month,
			"week_in_year": week_in_year,
			"day_in_week": day_in_week,
			"hour": hour,
			"minute": minute
		},
		"time_mode": int(time_mode),
		"player_channels": _player_channel_manager.get_channels(),
		"player_schedules": _player_schedule_manager.get_save_data(),
		"broadcast_engine": _broadcast_engine.get_save_data(),
		"mmtn_history": _mmtn_registry.get_channels(),
		"programs": _production_manager.get_programs(),
		"active_productions": _production_manager.get_active_productions(),
		"launch_series_telefilm_distribution": _production_manager.get_launch_series_telefilm_distribution()
	}


func load_save_data(data: Dictionary) -> bool:
	var loaded_player_name: String = String(data.get("player_name", "")).strip_edges()
	var loaded_company_name: String = String(data.get("company_name", "")).strip_edges()
	if loaded_player_name.is_empty() or loaded_company_name.is_empty():
		return false

	player_name = loaded_player_name
	company_name = loaded_company_name
	credits = maxi(int(data.get("credits", STARTING_CREDITS)), 0)

	var calendar_value: Variant = data.get("calendar", {})
	var calendar: Dictionary = {}
	if calendar_value is Dictionary:
		calendar = calendar_value

	year = maxi(int(calendar.get("year", 1)), 1)
	month_index = clampi(int(calendar.get("month_index", 0)), 0, MONTHS.size() - 1)
	week_in_month = maxi(int(calendar.get("week_in_month", 1)), 1)
	week_in_year = clampi(int(calendar.get("week_in_year", 1)), 1, 52)
	day_in_week = clampi(int(calendar.get("day_in_week", 1)), 1, 7)
	hour = clampi(int(calendar.get("hour", 0)), 0, 23)
	minute = clampi(int(calendar.get("minute", 0)), 0, 59)
	time_mode = int(clampi(int(data.get("time_mode", TimeMode.PAUSED)), TimeMode.PAUSED, TimeMode.WEEK)) as TimeMode
	_minute_buffer = 0.0

	var channels_value: Variant = data.get("player_channels", [])
	var channels: Array = channels_value if channels_value is Array else []
	_player_channel_manager.load_channels(channels)

	var schedules_value: Variant = data.get("player_schedules", {})
	_player_schedule_manager.load_data(schedules_value)
	_broadcast_engine.load_data(data.get("broadcast_engine", {}))

	var mmtn_value: Variant = data.get("mmtn_history", [])
	var mmtn_history: Array = mmtn_value if mmtn_value is Array else []
	_mmtn_registry.load_history(mmtn_history)

	var programs_value: Variant = data.get("programs", [])
	var programs: Array = programs_value if programs_value is Array else []
	var active_value: Variant = data.get("active_productions", [])
	var active_productions: Array = active_value if active_value is Array else []
	var distribution_value: Variant = data.get("launch_series_telefilm_distribution", {})
	var distribution: Dictionary = distribution_value if distribution_value is Dictionary else {}
	_production_manager.load_data(programs, distribution, active_productions)

	_emit_full_state_refresh()
	return true


func _emit_full_state_refresh() -> void:
	identity_changed.emit(player_name, company_name)
	credits_changed.emit(credits)
	time_changed.emit()
	speed_changed.emit(time_mode)
	programs_changed.emit()
	productions_changed.emit()
	schedule_changed.emit()


func has_started_game() -> bool:
	return not player_name.is_empty() and not company_name.is_empty()


func create_first_channel(channel_name: String) -> bool:
	return _player_channel_manager.create_first_channel(channel_name)


func has_player_channel() -> bool:
	return _player_channel_manager.has_first_channel()


func get_first_channel() -> Dictionary:
	return _player_channel_manager.get_first_channel()


func get_player_channels() -> Array[Dictionary]:
	return _player_channel_manager.get_channels()


func get_player_day_schedule(
	channel: Dictionary,
	week_number: int,
	day_index: int
) -> Array[Dictionary]:
	var channel_number: int = int(channel.get("mmtn_number", 0))
	return _player_schedule_manager.get_day_slots(channel_number, week_number, day_index)


# Programme actuellement à l'antenne sur la première chaîne du joueur.
# Une case de continuation conserve les données du programme initial.
func get_current_player_broadcast() -> Dictionary:
	var channel: Dictionary = get_first_channel()
	if channel.is_empty():
		return {}
	var slots: Array[Dictionary] = get_player_day_schedule(
		channel, week_in_year, day_in_week - 1
	)
	var slot: int = hour * 2 + int(minute / 30)
	if slot < 0 or slot >= slots.size():
		return {}
	var entry: Dictionary = slots[slot]
	if entry.is_empty():
		return {}
	return entry


func get_current_player_broadcast_text() -> String:
	var entry: Dictionary = get_current_player_broadcast()
	if entry.is_empty():
		return "Actuellement : Aucun programme"
	var program_name: String = String(entry.get("program_name", "")).strip_edges()
	if program_name.is_empty():
		return "Actuellement : Aucun programme"
	var episode_number: int = int(entry.get("episode_number", 0))
	var global_episode: int = int(entry.get("episode_global", 0))
	var season_number: int = int(entry.get("season_number", 0))
	if global_episode > 0:
		if season_number > 0 and episode_number > 0:
			return "Actuellement : %s | S%dE%02d" % [
				program_name, season_number, episode_number
			]
		return "Actuellement : %s | Épisode %d" % [
			program_name, global_episode
		]
	return "Actuellement : %s" % program_name


func can_schedule_program(
	channel: Dictionary,
	week_number: int,
	day_index: int,
	slot_index: int,
	program: Dictionary
) -> bool:
	var channel_number: int = int(channel.get("mmtn_number", 0))
	return _player_schedule_manager.can_place_program(
		channel_number,
		week_number,
		day_index,
		slot_index,
		program
	)


func can_fit_schedule_program(
	channel: Dictionary,
	week_number: int,
	day_index: int,
	slot_index: int,
	program: Dictionary
) -> bool:
	var channel_number: int = int(channel.get("mmtn_number", 0))
	return _player_schedule_manager.can_fit_program(
		channel_number,
		week_number,
		day_index,
		slot_index,
		program
	)


func get_schedule_conflicts(
	channel: Dictionary,
	week_number: int,
	day_index: int,
	slot_index: int,
	program: Dictionary,
	ignored_start_slot: int = -1
) -> Array[Dictionary]:
	var channel_number: int = int(channel.get("mmtn_number", 0))
	return _player_schedule_manager.get_conflicts(
		channel_number,
		week_number,
		day_index,
		slot_index,
		program,
		ignored_start_slot
	)


func schedule_program(
	channel: Dictionary,
	week_number: int,
	day_index: int,
	slot_index: int,
	program: Dictionary,
	episode_data: Dictionary = {}
) -> bool:
	var channel_number: int = int(channel.get("mmtn_number", 0))
	var placed: bool = _player_schedule_manager.place_program(
		channel_number,
		week_number,
		day_index,
		slot_index,
		program,
		episode_data
	)
	if placed:
		schedule_changed.emit()
	return placed


func replace_scheduled_program(
	channel: Dictionary,
	week_number: int,
	day_index: int,
	slot_index: int,
	program: Dictionary,
	episode_data: Dictionary = {}
) -> bool:
	var channel_number: int = int(channel.get("mmtn_number", 0))
	var placed: bool = _player_schedule_manager.replace_program(
		channel_number,
		week_number,
		day_index,
		slot_index,
		program,
		episode_data
	)
	if placed:
		schedule_changed.emit()
	return placed


func remove_scheduled_program(
	channel: Dictionary,
	week_number: int,
	day_index: int,
	slot_index: int
) -> bool:
	var channel_number: int = int(channel.get("mmtn_number", 0))
	var removed: bool = _player_schedule_manager.remove_program_at(
		channel_number,
		week_number,
		day_index,
		slot_index
	)
	if removed:
		schedule_changed.emit()
	return removed


func move_scheduled_program(
	channel: Dictionary,
	source_week: int,
	source_day: int,
	source_slot: int,
	target_week: int,
	target_day: int,
	target_slot: int,
	replace_conflicts: bool = false
) -> bool:
	var channel_number: int = int(channel.get("mmtn_number", 0))
	var moved: bool = _player_schedule_manager.move_program(
		channel_number,
		source_week,
		source_day,
		source_slot,
		target_week,
		target_day,
		target_slot,
		replace_conflicts
	)
	if moved:
		schedule_changed.emit()
	return moved


func update_scheduled_episode(
	channel: Dictionary,
	week_number: int,
	day_index: int,
	slot_index: int,
	episode_data: Dictionary
) -> bool:
	var channel_number: int = int(channel.get("mmtn_number", 0))
	var updated: bool = _player_schedule_manager.update_program_episode(
		channel_number,
		week_number,
		day_index,
		slot_index,
		episode_data
	)
	if updated:
		schedule_changed.emit()
	return updated


func get_broadcast_results() -> Array[Dictionary]:
	return _broadcast_engine.get_history()


func get_broadcast_total_revenue() -> int:
	return _broadcast_engine.total_revenue


func get_group_programs() -> Array[Dictionary]:
	return _production_manager.get_programs()


func get_active_productions() -> Array[Dictionary]:
	return _production_manager.get_active_productions()


func create_production(spec: Dictionary) -> String:
	var format_name: String = String(spec.get("format", ""))
	var cost: int = ProductionRulesScript.get_cost(format_name)
	if credits < cost:
		return "Crédits insuffisants : cette production coûte %d CC." % cost

	var error_text: String = _production_manager.start_new_production(spec)
	if not error_text.is_empty():
		return error_text

	spend_credits(cost)
	productions_changed.emit()
	return ""


func get_program(program_id: String) -> Dictionary:
	return _production_manager.get_program(program_id)


func record_program_broadcast(
	program_id: String,
	season_number: int,
	episode_number: int,
	date_text: String,
	time_text: String,
	channel_name: String,
	broadcast_type: String
) -> bool:
	var recorded: bool = _production_manager.record_broadcast(
		program_id,
		season_number,
		episode_number,
		date_text,
		time_text,
		channel_name,
		broadcast_type
	)
	if recorded:
		programs_changed.emit()
	return recorded


func get_zap_channels() -> Array[Dictionary]:
	return _mmtn_registry.get_channels()


func register_mmtn_channel(channel: Dictionary) -> void:
	_mmtn_registry.register_channel(channel)


func close_mmtn_channel(mmtn_number: int, closed_date: String) -> bool:
	var snapshot: Array[Dictionary] = []
	for channel: Dictionary in _mmtn_registry.get_channels():
		if int(channel.get("mmtn_number", -1)) != mmtn_number:
			continue
		var existing: Variant = channel.get("programs", [])
		if existing is Array:
			for value: Variant in existing:
				if value is Dictionary:
					snapshot.append((value as Dictionary).duplicate(true))
		if snapshot.is_empty():
			for owned: Dictionary in _player_channel_manager.get_channels():
				if int(owned.get("mmtn_number", -1)) == mmtn_number:
					snapshot = _production_manager.get_programs()
					break
		break
	return _mmtn_registry.close_channel(mmtn_number, closed_date, snapshot)


func set_time_mode(new_mode: TimeMode) -> void:
	if time_mode == new_mode:
		return
	time_mode = new_mode
	speed_changed.emit(time_mode)


func set_credits(new_value: int) -> void:
	credits = maxi(new_value, 0)
	credits_changed.emit(credits)


func add_credits(amount: int) -> void:
	set_credits(credits + amount)


func spend_credits(amount: int) -> bool:
	if amount < 0 or credits < amount:
		return false
	set_credits(credits - amount)
	return true


func advance_minutes(amount: int) -> void:
	if amount <= 0:
		return

	var start_year: int = year
	var start_year_minute: int = (
		((week_in_year - 1) * 7 + (day_in_week - 1)) * 1440
		+ hour * 60 + minute
	)

	var active_before: int = _production_manager.get_active_productions().size()
	var production_visible_change: bool = _production_manager.advance_minutes(amount)
	var active_after: int = _production_manager.get_active_productions().size()
	if production_visible_change:
		productions_changed.emit()
	if active_after < active_before:
		programs_changed.emit()

	var total_minutes: int = minute + amount
	minute = total_minutes % 60

	var total_hours: int = hour + int(total_minutes / 60)
	hour = total_hours % 24

	var days_to_advance: int = int(total_hours / 24)
	for _i: int in range(days_to_advance):
		_advance_one_day()

	var channel: Dictionary = _player_channel_manager.get_first_channel()
	var processed: Dictionary = _broadcast_engine.process_interval(
		start_year, start_year_minute, amount,
		channel, _player_schedule_manager, _production_manager
	)
	var revenue: int = int(processed.get("revenue", 0))
	if revenue > 0:
		add_credits(revenue)
	if int(processed.get("count", 0)) > 0:
		programs_changed.emit()
	var completed_value: Variant = processed.get("completed_events", [])
	if completed_value is Array:
		for event_value: Variant in completed_value:
			if event_value is Dictionary:
				broadcast_completed.emit((event_value as Dictionary).duplicate(true))

	time_changed.emit()


func _advance_one_day() -> void:
	day_in_week += 1
	if day_in_week <= 7:
		return

	day_in_week = 1
	week_in_month += 1
	week_in_year += 1

	var current_month_weeks: int = int(MONTHS[month_index]["weeks"])
	if week_in_month <= current_month_weeks:
		return

	week_in_month = 1
	month_index += 1

	if month_index < MONTHS.size():
		return

	month_index = 0
	year += 1
	week_in_year = 1


func _on_channel_created(channel: Dictionary) -> void:
	_production_manager.assign_launch_programs(String(channel.get("name", "")))

	var player_programs: Array[Dictionary] = _production_manager.get_programs()
	var distribution: Dictionary = _production_manager.get_launch_series_telefilm_distribution()
	var mg1_series_telefilm_value: Variant = distribution.get("mg1", {})
	var mg1_series_telefilm: Dictionary = {}
	if mg1_series_telefilm_value is Dictionary:
		mg1_series_telefilm = mg1_series_telefilm_value

	_mmtn_registry.register_initial_channels(
		channel,
		company_name,
		player_programs,
		mg1_series_telefilm
	)
	programs_changed.emit()
	channel_created.emit(channel)


func get_day_name() -> String:
	return DAYS[day_in_week - 1]


func get_month_name() -> String:
	return String(MONTHS[month_index]["name"])


func get_day_of_month() -> int:
	return ((week_in_month - 1) * 7) + day_in_week


func get_date_text() -> String:
	return "%s %d %s %04d" % [get_day_name(), get_day_of_month(), get_month_name(), year]


func get_week_text() -> String:
	return "Semaine %d/52" % week_in_year


func get_time_text() -> String:
	return "%02d:%02d" % [hour, minute]


func get_speed_text() -> String:
	match time_mode:
		TimeMode.HOUR:
			return "Heure"
		TimeMode.DAY:
			return "Jour"
		TimeMode.WEEK:
			return "Semaine"
		_:
			return "Pause"
