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

	var code_select := OptionButton.new()
	code_select.custom_minimum_size = Vector2(320, 40)
	_add_field(form, "Code prod", code_select)

	var add_button := Button.new()
	add_button.text = "Ajouter à la saison"
	add_button.custom_minimum_size = Vector2(220, 40)
	dynamic.add_child(add_button)

	var selected_title := Label.new()
	selected_title.text = "Ordre éditorial de la saison"
	selected_title.add_theme_font_size_override("font_size", 18)
	dynamic.add_child(selected_title)

	var selected_holder := VBoxContainer.new()
	selected_holder.add_theme_constant_override("separation", 6)
	dynamic.add_child(selected_holder)

	var help := Label.new()
	help.text = "L'ordre d'ajout devient l'ordre éditorial de la saison. Un code prod sélectionné disparaît du menu jusqu'à ce qu'il soit retiré."
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

	var selected_codes: Array[int] = []

	var rebuild_selected_codes: Callable
	var refresh_selection: Callable

	rebuild_selected_codes = func() -> void:
		for child: Node in selected_holder.get_children():
			selected_holder.remove_child(child)
			child.queue_free()

		if selected_codes.is_empty():
			var empty_label := Label.new()
			empty_label.text = "Aucune unité sélectionnée."
			selected_holder.add_child(empty_label)
			return

		for index: int in range(selected_codes.size()):
			var code_prod: int = selected_codes[index]
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			selected_holder.add_child(row)

			var label := Label.new()
			label.text = "Épisode %d → Code prod %d" % [index + 1, code_prod]
			label.custom_minimum_size = Vector2(280, 36)
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			row.add_child(label)

			var remove_button := Button.new()
			remove_button.text = "Retirer"
			remove_button.pressed.connect(func() -> void:
				selected_codes.erase(code_prod)
				refresh_selection.call()
			)
			row.add_child(remove_button)

	refresh_selection = func() -> void:
		_refresh_code_dropdown(code_select, program, selected_codes)
		rebuild_selected_codes.call()
		add_button.disabled = code_select.item_count <= 0

	add_button.pressed.connect(func() -> void:
		if code_select.item_count <= 0 or code_select.selected < 0:
			return

		var code_prod := int(code_select.get_item_metadata(code_select.selected))
		if code_prod <= 0 or selected_codes.has(code_prod):
			return

		selected_codes.append(code_prod)
		refresh_selection.call()
	)

	save_button.pressed.connect(func() -> void:
		if selected_codes.is_empty():
			error_label.text = "Ajoute au moins un code prod."
			return

		var result: Variant = on_save_season.call(int(season_input.value), selected_codes.duplicate())
		var error_text := String(result)
		if not error_text.is_empty():
			error_label.text = error_text
			return

		error_label.text = "Saison enregistrée."
	)

	refresh_selection.call()
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


static func _refresh_code_dropdown(
	code_select: OptionButton,
	program: Dictionary,
	selected_codes: Array[int]
) -> void:
	code_select.clear()

	var units_value: Variant = program.get("units", [])
	if not units_value is Array:
		return

	for value: Variant in units_value:
		if not value is Dictionary:
			continue

		var unit: Dictionary = value
		var code_prod: int = int(unit.get("code_prod", 0))
		var season: int = int(unit.get("season", 0))
		if code_prod <= 0 or season > 0 or selected_codes.has(code_prod):
			continue

		code_select.add_item("Code prod %d" % code_prod)
		code_select.set_item_metadata(code_select.item_count - 1, code_prod)

	if code_select.item_count > 0:
		code_select.select(0)


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
