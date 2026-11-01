class_name LibraryProgramEpisodeTable
extends RefCounted

const PRODUCTION_WIDTHS_NO_TITLE: Array[float] = [150.0, 260.0, 650.0]
const PRODUCTION_WIDTHS_WITH_TITLE: Array[float] = [150.0, 220.0, 300.0, 500.0]
const SEASON_WIDTHS_NO_TITLE: Array[float] = [160.0, 180.0, 150.0, 570.0]
const SEASON_WIDTHS_WITH_TITLE: Array[float] = [150.0, 160.0, 140.0, 280.0, 430.0]


static func build(parent: VBoxContainer, program: Dictionary) -> void:
	build_by_production(parent, program)


static func build_by_production(parent: VBoxContainer, program: Dictionary) -> void:
	var units: Array[Dictionary] = _get_units(program)
	if units.is_empty():
		_add_empty_label(parent, "Ce programme ne possède aucune unité numérotée.")
		return

	units.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("code_prod", 0)) < int(b.get("code_prod", 0))
	)

	var has_titles: bool = _has_custom_titles(units)
	var widths: Array[float] = PRODUCTION_WIDTHS_WITH_TITLE if has_titles else PRODUCTION_WIDTHS_NO_TITLE
	var table: GridContainer = GridContainer.new()
	table.columns = 4 if has_titles else 3
	table.add_theme_constant_override("h_separation", 0)
	table.add_theme_constant_override("v_separation", 0)
	parent.add_child(table)

	_add_cell(table, "Code prod", 0, true, widths)
	_add_cell(table, "Unité", 1, true, widths)
	var diffusion_column: int = 2
	if has_titles:
		_add_cell(table, "Titre", 2, true, widths)
		diffusion_column = 3
	_add_cell(table, "Diffusion(s)", diffusion_column, true, widths)

	var total_units: int = units.size()
	for unit: Dictionary in units:
		var code_prod: int = int(unit.get("code_prod", 0))
		_add_cell(table, str(code_prod), 0, false, widths)
		_add_cell(table, "Unité %d/%d" % [code_prod, total_units], 1, false, widths)
		if has_titles:
			_add_cell(table, String(unit.get("title", "")), 2, false, widths)
		_add_cell(table, _get_unit_broadcasts(program, unit), diffusion_column, false, widths)


static func build_by_season(parent: VBoxContainer, program: Dictionary) -> void:
	var units: Array[Dictionary] = _get_units(program)
	var seasoned_units: Array[Dictionary] = []
	for unit: Dictionary in units:
		if int(unit.get("season", 0)) > 0 and int(unit.get("episode_in_season", 0)) > 0:
			seasoned_units.append(unit)

	if seasoned_units.is_empty():
		_add_empty_label(parent, "Aucun découpage en saison n'a encore été défini pour ce programme.")
		return

	seasoned_units.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var season_a: int = int(a.get("season", 0))
		var season_b: int = int(b.get("season", 0))
		if season_a == season_b:
			return int(a.get("episode_in_season", 0)) < int(b.get("episode_in_season", 0))
		return season_a < season_b
	)

	var has_titles: bool = _has_custom_titles(seasoned_units)
	var widths: Array[float] = SEASON_WIDTHS_WITH_TITLE if has_titles else SEASON_WIDTHS_NO_TITLE
	var table: GridContainer = GridContainer.new()
	table.columns = 5 if has_titles else 4
	table.add_theme_constant_override("h_separation", 0)
	table.add_theme_constant_override("v_separation", 0)
	parent.add_child(table)

	_add_cell(table, "Saison", 0, true, widths)
	_add_cell(table, "Épisode", 1, true, widths)
	_add_cell(table, "Code prod", 2, true, widths)
	var diffusion_column: int = 3
	if has_titles:
		_add_cell(table, "Titre", 3, true, widths)
		diffusion_column = 4
	_add_cell(table, "Diffusion(s)", diffusion_column, true, widths)

	for unit: Dictionary in seasoned_units:
		_add_cell(table, "Saison %d" % int(unit.get("season", 0)), 0, false, widths)
		_add_cell(table, "Épisode %d" % int(unit.get("episode_in_season", 0)), 1, false, widths)
		_add_cell(table, str(int(unit.get("code_prod", 0))), 2, false, widths)
		if has_titles:
			_add_cell(table, String(unit.get("title", "")), 3, false, widths)
		_add_cell(table, _get_unit_broadcasts(program, unit), diffusion_column, false, widths)


static func _get_units(program: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var units_value: Variant = program.get("units", [])
	if units_value is Array:
		for value: Variant in units_value:
			if value is Dictionary:
				result.append((value as Dictionary).duplicate(true))

	if not result.is_empty():
		return result

	var total_units: int = int(program.get("units_total", program.get("episodes_total", 0)))
	for code_prod: int in range(1, total_units + 1):
		result.append({
			"code_prod": code_prod,
			"season": 0,
			"episode_in_season": 0,
			"title": ""
		})

	_apply_legacy_seasons(result, program)
	return result


static func _apply_legacy_seasons(units: Array[Dictionary], program: Dictionary) -> void:
	var seasons_value: Variant = program.get("seasons", [])
	if not seasons_value is Array:
		return

	for season_value: Variant in seasons_value:
		if not season_value is Dictionary:
			continue
		var season: Dictionary = season_value
		var season_number: int = int(season.get("number", 0))
		if season_number <= 0:
			continue

		var codes: Array[int] = []
		var codes_value: Variant = season.get("unit_codes", [])
		if codes_value is Array:
			for code_value: Variant in codes_value:
				var code: int = int(code_value)
				if code > 0:
					codes.append(code)

		if codes.is_empty():
			var first_episode: int = int(season.get("first_episode", 0))
			var last_episode: int = int(season.get("last_episode", 0))
			if first_episode > 0 and last_episode >= first_episode:
				for code_prod: int in range(first_episode, last_episode + 1):
					codes.append(code_prod)

		for editorial_index: int in range(codes.size()):
			var code_prod: int = codes[editorial_index]
			if code_prod < 1 or code_prod > units.size():
				continue
			var unit: Dictionary = units[code_prod - 1]
			unit["season"] = season_number
			unit["episode_in_season"] = editorial_index + 1
			units[code_prod - 1] = unit


static func _has_custom_titles(units: Array[Dictionary]) -> bool:
	for unit: Dictionary in units:
		if not String(unit.get("title", "")).strip_edges().is_empty():
			return true
	return false


static func _get_unit_broadcasts(program: Dictionary, unit: Dictionary) -> String:
	var broadcasts: Array[String] = []
	var code_prod: int = int(unit.get("code_prod", 0))
	var season_number: int = int(unit.get("season", 0))
	var episode_in_season: int = int(unit.get("episode_in_season", 0))
	var history_value: Variant = program.get("broadcast_history", [])

	if history_value is Array:
		for item_value: Variant in history_value:
			if not item_value is Dictionary:
				continue
			var item: Dictionary = item_value

			var history_code_prod: int = int(item.get("code_prod", item.get("episode_global", 0)))
			var matches: bool = history_code_prod == code_prod and code_prod > 0
			if not matches and season_number > 0 and episode_in_season > 0:
				matches = int(item.get("season", 0)) == season_number and int(item.get("episode", 0)) == episode_in_season
			if not matches and season_number <= 0:
				matches = int(item.get("season", 0)) <= 0 and int(item.get("episode", 0)) == code_prod
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


static func _add_empty_label(parent: VBoxContainer, text: String) -> void:
	var label: Label = Label.new()
	label.text = text
	parent.add_child(label)


static func _add_cell(
	table: GridContainer,
	text: String,
	column: int,
	is_header: bool,
	column_widths: Array[float]
) -> void:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(column_widths[column], 44)

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
