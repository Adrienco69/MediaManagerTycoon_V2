class_name ZapProgramLabel
extends RefCounted

const ScheduleEpisodeHelperScript = preload("res://scripts/ui/schedule_episode_helper.gd")


static func build(
	program: Dictionary,
	channel: Dictionary,
	week_number: int,
	day_index: int,
	slot_index: int,
	slot_entry: Dictionary = {}
) -> String:
	var title: String = String(program.get("name", "Programme"))
	var duration_minutes: int = int(program.get("duration_minutes", 0))
	var parts: Array[String] = [title]

	var episode_label: String = _get_episode_label(
		program,
		channel,
		week_number,
		day_index,
		slot_index,
		slot_entry
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
	slot_index: int,
	slot_entry: Dictionary
) -> String:
	var scheduled_episode: int = int(slot_entry.get("episode_global", 0))
	if scheduled_episode > 0:
		return ScheduleEpisodeHelperScript.get_compact_label(
			program,
			{
				"episode_global": scheduled_episode,
				"season_number": int(slot_entry.get("season_number", 0)),
				"episode_number": int(slot_entry.get("episode_number", scheduled_episode))
			}
		)

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
	var episode_data: Dictionary = ScheduleEpisodeHelperScript.get_episode_data(program, global_episode)
	return ScheduleEpisodeHelperScript.get_compact_label(program, episode_data)
