class_name LibraryProgramEpisodeTable
extends RefCounted

const COLUMN_WIDTHS: Array[float] = [150.0, 160.0, 170.0, 520.0]


static func build(parent: VBoxContainer, program: Dictionary) -> void:
	var total_episodes: int = int(program.get("episodes_total", 0))
	if total_episodes <= 0:
		var variable_label: Label = Label.new()
		variable_label.text = "Ce programme n'utilise pas un nombre fixe d'épisodes."
		parent.add_child(variable_label)
		return

	var table: GridContainer = GridContainer.new()
	table.columns = 4
	table.add_theme_constant_override("h_separation", 0)
	table.add_theme_constant_override("v_separation", 0)
	parent.add_child(table)

	_add_cell(table, "Saison", 0, true)
	_add_cell(table, "Épisode", 1, true)
	_add_cell(table, "Épisode total", 2, true)
	_add_cell(table, "Diffusion(s)", 3, true)

	for global_episode_number: int in range(1, total_episodes + 1):
		var season_info: Dictionary = _find_season_info(program, global_episode_number)
		_add_cell(table, _get_season_text(season_info), 0, false)
		_add_cell(table, _get_episode_text(season_info, global_episode_number), 1, false)
		_add_cell(table, "%d/%d" % [global_episode_number, total_episodes], 2, false)
		_add_cell(table, _get_episode_broadcasts(program, global_episode_number), 3, false)


static func _get_season_text(season_info: Dictionary) -> String:
	if season_info.is_empty():
		return "—"
	return "Saison %d" % int(season_info.get("season", 0))


static func _get_episode_text(season_info: Dictionary, global_episode_number: int) -> String:
	if season_info.is_empty():
		return "Épisode %d" % global_episode_number
	return "Épisode %d" % int(season_info.get("episode_in_season", 0))


static func _find_season_info(program: Dictionary, global_episode_number: int) -> Dictionary:
	var season_data_value: Variant = program.get("seasons", [])
	if season_data_value is Array:
		for season_value: Variant in season_data_value:
			if not season_value is Dictionary:
				continue
			var season: Dictionary = season_value
			var season_number: int = int(season.get("number", 0))
			var first_episode: int = int(season.get("first_episode", 0))
			var last_episode: int = int(season.get("last_episode", 0))
			if season_number <= 0 or first_episode <= 0 or last_episode < first_episode:
				continue
			if global_episode_number >= first_episode and global_episode_number <= last_episode:
				return {
					"season": season_number,
					"episode_in_season": (global_episode_number - first_episode) + 1
				}

	var history_value: Variant = program.get("broadcast_history", [])
	if history_value is Array:
		for item_value: Variant in history_value:
			if not item_value is Dictionary:
				continue
			var item: Dictionary = item_value
			if int(item.get("episode_global", 0)) != global_episode_number:
				continue
			var season_number: int = int(item.get("season", 0))
			var episode_in_season: int = int(item.get("episode", 0))
			if season_number > 0 and episode_in_season > 0:
				return {
					"season": season_number,
					"episode_in_season": episode_in_season
				}

	return {}


static func _get_episode_broadcasts(program: Dictionary, global_episode_number: int) -> String:
	var broadcasts: Array[String] = []
	var season_info: Dictionary = _find_season_info(program, global_episode_number)
	var expected_season: int = int(season_info.get("season", 0))
	var expected_episode: int = int(season_info.get("episode_in_season", 0))
	var history_value: Variant = program.get("broadcast_history", [])

	if history_value is Array:
		for item_value: Variant in history_value:
			if not item_value is Dictionary:
				continue
			var item: Dictionary = item_value

			var matches: bool = false
			if int(item.get("episode_global", 0)) == global_episode_number:
				matches = true
			elif expected_season > 0 and expected_episode > 0:
				matches = int(item.get("season", 0)) == expected_season and int(item.get("episode", 0)) == expected_episode
			else:
				matches = int(item.get("episode", 0)) == global_episode_number

			if not matches:
				continue

			var date_text: String = String(item.get("date", "Date inconnue"))
			var time_text: String = String(item.get("time", ""))
			var channel_name: String = String(item.get("channel", ""))
			var broadcast_type: String = String(item.get("type", "Diffusion"))

			var text: String = date_text
			if not time_text.is_empty():
				text += " à %s" % time_text
			if not channel_name.is_empty():
				text += " | %s" % channel_name
			if not broadcast_type.is_empty():
				text += " | %s" % broadcast_type
			broadcasts.append(text)

	if broadcasts.is_empty():
		return "Jamais diffusé"
	return "\n".join(broadcasts)


static func _add_cell(table: GridContainer, text: String, column: int, is_header: bool) -> void:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(COLUMN_WIDTHS[column], 44)

	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = Color(1, 1, 1, 0.025)
	box.border_color = Color(1, 1, 1, 0.18)
	box.border_width_left = 1
	box.border_width_top = 1
	box.border_width_right = 1
	box.border_width_bottom = 1
	box.content_margin_left = 10.0
	box.content_margin_right = 10.0
	box.content_margin_top = 7.0
	box.content_margin_bottom = 7.0
	panel.add_theme_stylebox_override("panel", box)
	table.add_child(panel)

	var label: Label = Label.new()
	label.text = text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if is_header:
		label.add_theme_font_size_override("font_size", 16)
	panel.add_child(label)
