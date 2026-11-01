class_name ZapProgramLabel
extends RefCounted


static func build(
	program: Dictionary,
	channel: Dictionary,
	week_number: int,
	day_index: int,
	slot_index: int
) -> String:
	var title: String = String(program.get("name", "Programme"))
	var duration_minutes: int = int(program.get("duration_minutes", 0))
	var parts: Array[String] = [title]

	var episode_label: String = _get_episode_label(
		program,
		channel,
		week_number,
		day_index,
		slot_index
	)
	if not episode_label.is_empty():
		parts.append(episode_label)

	if duration_minutes > 0:
		parts.append("%d min" % duration_minutes)

	return " | ".join(parts)


static func _get_episode_label(
	program: Dictionary,
	channel: Dictionary,
	week_number: int,
	day_index: int,
	slot_index: int
) -> String:
	var available_episodes: int = int(program.get("episodes_available", 0))
	var total_episodes: int = int(program.get("episodes_total", 0))
	var episode_count: int = available_episodes if available_episodes > 0 else total_episodes

	if episode_count <= 1:
		return ""

	var schedule_seed: int = int(channel.get("schedule_seed", 1))
	var program_id: String = String(program.get("id", program.get("name", "programme")))
	var stable_value: int = abs(
		schedule_seed
		+ (week_number * 1009)
		+ (day_index * 97)
		+ (slot_index * 31)
		+ int(program_id.hash())
	)
	var global_episode: int = (stable_value % episode_count) + 1

	var season_info: Dictionary = _find_season_info(program, global_episode)
	if not season_info.is_empty():
		return "S%dE%02d" % [
			int(season_info.get("season", 0)),
			int(season_info.get("episode_in_season", 0))
		]

	return "Épisode %d" % global_episode


static func _find_season_info(program: Dictionary, global_episode: int) -> Dictionary:
	var seasons_value: Variant = program.get("seasons", [])
	if not seasons_value is Array:
		return {}

	for season_value: Variant in seasons_value:
		if not season_value is Dictionary:
			continue
		var season: Dictionary = season_value
		var season_number: int = int(season.get("number", 0))
		var first_episode: int = int(season.get("first_episode", 0))
		var last_episode: int = int(season.get("last_episode", 0))
		if season_number <= 0 or first_episode <= 0 or last_episode < first_episode:
			continue
		if global_episode >= first_episode and global_episode <= last_episode:
			return {
				"season": season_number,
				"episode_in_season": (global_episode - first_episode) + 1
			}

	return {}
