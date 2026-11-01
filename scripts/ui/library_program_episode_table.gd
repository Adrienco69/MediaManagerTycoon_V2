class_name LibraryProgramEpisodeTable
extends RefCounted

const COLUMN_WIDTHS: Array[float] = [260.0, 620.0]


static func build(parent: VBoxContainer, program: Dictionary) -> void:
	var total_episodes: int = int(program.get("episodes_total", 0))
	if total_episodes <= 0:
		var variable_label: Label = Label.new()
		variable_label.text = "Ce programme n'utilise pas un nombre fixe d'épisodes."
		parent.add_child(variable_label)
		return

	var table: GridContainer = GridContainer.new()
	table.columns = 2
	table.add_theme_constant_override("h_separation", 0)
	table.add_theme_constant_override("v_separation", 0)
	parent.add_child(table)

	_add_cell(table, "Épisode", 0, true)
	_add_cell(table, "Diffusion(s)", 1, true)

	for episode_number: int in range(1, total_episodes + 1):
		_add_cell(table, _get_episode_label(program, episode_number), 0, false)
		_add_cell(table, _get_episode_broadcasts(program, episode_number), 1, false)


static func _get_episode_label(program: Dictionary, episode_number: int) -> String:
	var season_number: int = _find_season_number(program, episode_number)
	if season_number > 0:
		return "Saison %d | Épisode %d" % [season_number, episode_number]
	return "Épisode %d" % episode_number


static func _find_season_number(program: Dictionary, episode_number: int) -> int:
	var history_value: Variant = program.get("broadcast_history", [])
	if history_value is Array:
		for item_value: Variant in history_value:
			if not item_value is Dictionary:
				continue
			var item: Dictionary = item_value
			if int(item.get("episode", 0)) == episode_number:
				var season_number: int = int(item.get("season", 0))
				if season_number > 0:
					return season_number

	var season_data_value: Variant = program.get("seasons", [])
	if season_data_value is Array:
		for season_value: Variant in season_data_value:
			if not season_value is Dictionary:
				continue
			var season: Dictionary = season_value
			var season_number: int = int(season.get("number", 0))
			var first_episode: int = int(season.get("first_episode", 0))
			var last_episode: int = int(season.get("last_episode", 0))
			if season_number > 0 and first_episode > 0 and last_episode >= first_episode:
				if episode_number >= first_episode and episode_number <= last_episode:
					return season_number

	return 0


static func _get_episode_broadcasts(program: Dictionary, episode_number: int) -> String:
	var broadcasts: Array[String] = []
	var history_value: Variant = program.get("broadcast_history", [])
	if history_value is Array:
		for item_value: Variant in history_value:
			if not item_value is Dictionary:
				continue
			var item: Dictionary = item_value
			if int(item.get("episode", 0)) != episode_number:
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
