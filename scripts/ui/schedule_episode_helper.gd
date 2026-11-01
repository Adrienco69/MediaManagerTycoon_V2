class_name ScheduleEpisodeHelper
extends RefCounted


static func get_episode_count(program: Dictionary) -> int:
	var available_episodes: int = int(program.get("episodes_available", 0))
	var total_episodes: int = int(program.get("episodes_total", 0))
	if available_episodes > 0:
		return available_episodes
	return maxi(total_episodes, 0)


static func requires_episode_choice(program: Dictionary) -> bool:
	return get_episode_count(program) > 1


static func get_episode_data(program: Dictionary, global_episode: int) -> Dictionary:
	var episode_count: int = get_episode_count(program)
	if global_episode < 1 or global_episode > episode_count:
		return {}

	var season_info: Dictionary = _find_season_info(program, global_episode)
	if season_info.is_empty():
		return {
			"episode_global": global_episode,
			"season_number": 1,
			"episode_number": global_episode,
			"label": "Épisode %d/%d" % [global_episode, episode_count]
		}

	var season_number: int = int(season_info.get("season_number", 1))
	var episode_number: int = int(season_info.get("episode_number", global_episode))
	return {
		"episode_global": global_episode,
		"season_number": season_number,
		"episode_number": episode_number,
		"label": "Saison %d | Épisode %d | %d/%d" % [
			season_number,
			episode_number,
			global_episode,
			episode_count
		]
	}


static func get_compact_label(program: Dictionary, episode_data: Dictionary) -> String:
	if episode_data.is_empty():
		return ""

	var global_episode: int = int(episode_data.get("episode_global", 0))
	if global_episode <= 0:
		return ""

	var seasons_value: Variant = program.get("seasons", [])
	if seasons_value is Array and not (seasons_value as Array).is_empty():
		var season_number: int = int(episode_data.get("season_number", 1))
		var episode_number: int = int(episode_data.get("episode_number", global_episode))
		return "S%dE%02d" % [season_number, episode_number]

	return "Épisode %d" % global_episode


static func _find_season_info(program: Dictionary, global_episode: int) -> Dictionary:
	var seasons_value: Variant = program.get("seasons", [])
	if not seasons_value is Array:
		return {}

	for season_value: Variant in seasons_value:
		if not season_value is Dictionary:
			continue
		var season: Dictionary = season_value as Dictionary
		var season_number: int = int(season.get("number", 0))
		var first_episode: int = int(season.get("first_episode", 0))
		var last_episode: int = int(season.get("last_episode", 0))
		if season_number <= 0 or first_episode <= 0 or last_episode < first_episode:
			continue
		if global_episode >= first_episode and global_episode <= last_episode:
			return {
				"season_number": season_number,
				"episode_number": (global_episode - first_episode) + 1
			}

	return {}
