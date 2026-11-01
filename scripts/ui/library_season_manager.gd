class_name LibrarySeasonManager
extends RefCounted

const DYNAMIC_NODE_NAME: String = "LibrarySeasonManagerDynamic"
const COLUMN_WIDTHS: Array[float] = [150.0, 240.0]


static func render(
	content_container: VBoxContainer,
	page_description: Label,
	program: Dictionary,
	on_back: Callable,
	on_save_season: Callable
) -> void:
	clear(content_container)
	page_description.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	page_description.text = "Créez ou modifiez les saisons éditoriales sans changer les codes prod des unités."

	var dynamic := VBoxContainer.new()
	dynamic.name = DYNAMIC_NODE_NAME
	dynamic.add_theme_constant_override("separation", 12)
	content_container.add_child(dynamic)

	var back_button := Button.new()
	back_button.text = "← Retour au programme"
	back_button.custom_minimum_size = Vector2(220, 40)
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back_button.pressed.connect(on_back)
	dynamic.add_child(back_button)

	var form := GridContainer.new()
	form.columns = 2
	form.add_theme_constant_override("h_separation", 12)
	form.add_theme_constant_override("v_separation", 8)
	dynamic.add_child(form)

	var season_input := SpinBox.new()
	season_input.min_value = 1
	season_input.max_value = 999
	season_input.step = 1
	season_input.value = _next_season_number(program)
	season_input.custom_minimum_size = Vector2(220, 40)
	_add_field(form, "Saison", season_input)

	var codes_input := LineEdit.new()
	codes_input.placeholder_text = "Ex. 50, 12, 451, 1"
	codes_input.custom_minimum_size = Vector2(520, 40)
	_add_field(form, "Codes prod dans l'ordre", codes_input)

	var help := Label.new()
	help.text = "L'ordre saisi devient l'ordre éditorial de la saison. Exemple : 451 en 2e position = Saison X épisode 2."
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dynamic.add_child(help)

	var error_label := Label.new()
	error_label.text = ""
	dynamic.add_child(error_label)

	var save_button := Button.new()
	save_button.text = "Enregistrer la saison"
	save_button.custom_minimum_size = Vector2(220, 42)
	save_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	dynamic.add_child(save_button)

	save_button.pressed.connect(func() -> void:
		var codes := _parse_codes(codes_input.text)
		if codes.is_empty():
			error_label.text = "Ajoute au moins un code prod."
			return
		var result: Variant = on_save_season.call(int(season_input.value), codes)
		var error_text := String(result)
		if not error_text.is_empty():
			error_label.text = error_text
			return
		error_label.text = "Saison enregistrée."
	)

	_build_current_seasons(dynamic, program)
	_build_units_table(dynamic, program)


static func clear(content_container: VBoxContainer) -> void:
	var existing := content_container.get_node_or_null(DYNAMIC_NODE_NAME)
	if existing != null:
		content_container.remove_child(existing)
		existing.queue_free()


static func _add_field(form: GridContainer, label_text: String, control: Control) -> void:
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(190, 40)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	form.add_child(label)
	form.add_child(control)


static func _parse_codes(text: String) -> Array[int]:
	var result: Array[int] = []
	for raw_part: String in text.split(",", false):
		var part := raw_part.strip_edges()
		if part.is_empty() or not part.is_valid_int():
			continue
		var code := int(part)
		if code > 0:
			result.append(code)
	return result


static func _next_season_number(program: Dictionary) -> int:
	var max_number := 0
	var seasons_value: Variant = program.get("seasons", [])
	if seasons_value is Array:
		for value: Variant in seasons_value:
			if value is Dictionary:
				max_number = maxi(max_number, int((value as Dictionary).get("number", 0)))
	return max_number + 1


static func _build_current_seasons(parent: VBoxContainer, program: Dictionary) -> void:
	var title := Label.new()
	title.text = "Saisons actuelles"
	title.add_theme_font_size_override("font_size", 18)
	parent.add_child(title)

	var seasons_value: Variant = program.get("seasons", [])
	if not seasons_value is Array or (seasons_value as Array).is_empty():
		var empty := Label.new()
		empty.text = "Aucun découpage en saison."
		parent.add_child(empty)
		return

	for value: Variant in seasons_value:
		if not value is Dictionary:
			continue
		var season: Dictionary = value
		var codes: Array[String] = []
		var code_values: Variant = season.get("unit_codes", [])
		if code_values is Array:
			for code_value: Variant in code_values:
				codes.append(str(int(code_value)))
		var line := Label.new()
		line.text = "Saison %d : %s" % [int(season.get("number", 0)), ", ".join(codes)]
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		parent.add_child(line)


static func _build_units_table(parent: VBoxContainer, program: Dictionary) -> void:
	var title := Label.new()
	title.text = "Unités"
	title.add_theme_font_size_override("font_size", 18)
	parent.add_child(title)

	var table := GridContainer.new()
	table.columns = 2
	table.add_theme_constant_override("h_separation", 0)
	table.add_theme_constant_override("v_separation", 0)
	parent.add_child(table)
	_add_cell(table, "Code prod", 0, true)
	_add_cell(table, "Classement éditorial", 1, true)

	var units_value: Variant = program.get("units", [])
	if not units_value is Array:
		return
	for value: Variant in units_value:
		if not value is Dictionary:
			continue
		var unit: Dictionary = value
		var code_prod := int(unit.get("code_prod", 0))
		var season := int(unit.get("season", 0))
		var episode := int(unit.get("episode_in_season", 0))
		var editorial := "Non classée"
		if season > 0 and episode > 0:
			editorial = "Saison %d épisode %d" % [season, episode]
		_add_cell(table, str(code_prod), 0, false)
		_add_cell(table, editorial, 1, false)


static func _add_cell(table: GridContainer, text: String, column: int, is_header: bool) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(COLUMN_WIDTHS[column], 42)
	var box := StyleBoxFlat.new()
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
	var label := Label.new()
	label.text = text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if is_header:
		label.add_theme_font_size_override("font_size", 16)
	panel.add_child(label)
