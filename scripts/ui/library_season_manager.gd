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

	var season_title := Label.new()
	season_title.text = "Saisons"
	season_title.add_theme_font_size_override("font_size", 18)
	dynamic.add_child(season_title)

	var season_row := HBoxContainer.new()
	season_row.add_theme_constant_override("separation", 8)
	dynamic.add_child(season_row)

	var season_select := OptionButton.new()
	season_select.custom_minimum_size = Vector2(220, 40)
	season_row.add_child(season_select)

	var new_season_button := Button.new()
	new_season_button.text = "+ Nouvelle saison"
	new_season_button.custom_minimum_size = Vector2(180, 40)
	season_row.add_child(new_season_button)

	var save_button := Button.new()
	save_button.text = "Enregistrer la saison"
	save_button.custom_minimum_size = Vector2(220, 40)
	season_row.add_child(save_button)

	var selected_season := [_initial_season_number(program)]
	_populate_season_select(season_select, program, selected_season[0])

	var code_row := HBoxContainer.new()
	code_row.add_theme_constant_override("separation", 8)
	dynamic.add_child(code_row)

	var code_label := Label.new()
	code_label.text = "Code prod"
	code_label.custom_minimum_size = Vector2(190, 40)
	code_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	code_row.add_child(code_label)

	var code_select := OptionButton.new()
	code_select.custom_minimum_size = Vector2(320, 40)
	code_row.add_child(code_select)

	var add_button := Button.new()
	add_button.text = "Ajouter à la saison"
	add_button.custom_minimum_size = Vector2(220, 40)
	code_row.add_child(add_button)

	var editorial_title := Label.new()
	editorial_title.text = "Ordre éditorial de la saison"
	editorial_title.add_theme_font_size_override("font_size", 18)
	dynamic.add_child(editorial_title)

	var selected_holder := VBoxContainer.new()
	selected_holder.add_theme_constant_override("separation", 6)
	dynamic.add_child(selected_holder)

	var selected_codes: Array[int] = _get_existing_codes(program, selected_season[0])
	var current_program := program.duplicate(true)
	var refresh_selection: Callable
	refresh_selection = func() -> void:
		_refresh_code_dropdown(code_select, current_program, selected_codes)
		_rebuild_selected_codes(selected_holder, selected_codes, refresh_selection)
		add_button.disabled = code_select.item_count <= 0

	season_select.item_selected.connect(func(index: int) -> void:
		if index < 0 or index >= season_select.item_count:
			return
		selected_season[0] = int(season_select.get_item_metadata(index))
		selected_codes.clear()
		for code_prod: int in _get_existing_codes(current_program, selected_season[0]):
			selected_codes.append(code_prod)
		refresh_selection.call()
	)

	var error_label := Label.new()
	error_label.text = ""
	dynamic.add_child(error_label)

	new_season_button.pressed.connect(func() -> void:
		var next_season := _next_season_number(current_program)
		selected_season[0] = next_season
		selected_codes.clear()
		_populate_season_select(season_select, current_program, next_season)
		error_label.text = "Ajoute les unités de la nouvelle saison puis clique sur « Enregistrer la saison »."
		refresh_selection.call()
	)

	add_button.pressed.connect(func() -> void:
		if code_select.item_count <= 0 or code_select.selected < 0:
			return
		var code_prod := int(code_select.get_item_metadata(code_select.selected))
		if code_prod <= 0 or selected_codes.has(code_prod):
			return
		selected_codes.append(code_prod)
		refresh_selection.call()
	)

	var help := Label.new()
	help.text = "L'ordre d'ajout devient l'ordre éditorial de la saison. Un code prod sélectionné disparaît du menu jusqu'à ce qu'il soit retiré."
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dynamic.add_child(help)

	var current_seasons_holder := VBoxContainer.new()
	dynamic.add_child(current_seasons_holder)

	var units_holder := VBoxContainer.new()
	dynamic.add_child(units_holder)

	var refresh_saved_views: Callable = func() -> void:
		_clear_children(current_seasons_holder)
		_clear_children(units_holder)
		_build_current_seasons(current_seasons_holder, current_program)
		_build_units_table(units_holder, current_program)

	save_button.pressed.connect(func() -> void:
		if selected_codes.is_empty():
			error_label.text = "Ajoute au moins un code prod."
			return
		var result: Variant = on_save_season.call(selected_season[0], selected_codes.duplicate())
		var error_text := String(result)
		if not error_text.is_empty():
			error_label.text = error_text
			return

		var refreshed_program: Dictionary = GameState.get_program(String(program.get("id", "")))
		if not refreshed_program.is_empty():
			current_program = refreshed_program.duplicate(true)
		else:
			current_program = _program_with_local_season(current_program, selected_season[0], selected_codes)

		error_label.text = "Saison %d enregistrée." % selected_season[0]
		_populate_season_select(season_select, current_program, selected_season[0])
		selected_codes.clear()
		for code_prod: int in _get_existing_codes(current_program, selected_season[0]):
			selected_codes.append(code_prod)
		refresh_selection.call()
		refresh_saved_views.call()
	)

	refresh_selection.call()
	refresh_saved_views.call()


static func clear(content_container: VBoxContainer) -> void:
	var existing := content_container.get_node_or_null(DYNAMIC_NODE_NAME)
	if existing != null:
		content_container.remove_child(existing)
		existing.queue_free()


static func _clear_children(parent: Node) -> void:
	for child: Node in parent.get_children():
		parent.remove_child(child)
		child.queue_free()


static func _initial_season_number(program: Dictionary) -> int:
	var seasons_value: Variant = program.get("seasons", [])
	if seasons_value is Array and not (seasons_value as Array).is_empty():
		var first: Variant = (seasons_value as Array)[0]
		if first is Dictionary:
			return maxi(int((first as Dictionary).get("number", 1)), 1)
	return 1


static func _populate_season_select(select: OptionButton, program: Dictionary, selected_number: int) -> void:
	select.clear()
	var numbers: Array[int] = []
	var seasons_value: Variant = program.get("seasons", [])
	if seasons_value is Array:
		for value: Variant in seasons_value:
			if value is Dictionary:
				var number := int((value as Dictionary).get("number", 0))
				if number > 0 and not numbers.has(number):
					numbers.append(number)
	if numbers.is_empty():
		numbers.append(1)
	if selected_number > 0 and not numbers.has(selected_number):
		numbers.append(selected_number)
	numbers.sort()
	var selected_index := 0
	for number: int in numbers:
		select.add_item("Saison %d" % number)
		var item_index := select.item_count - 1
		select.set_item_metadata(item_index, number)
		if number == selected_number:
			selected_index = item_index
	select.select(selected_index)


static func _next_season_number(program: Dictionary) -> int:
	var max_number := 0
	var seasons_value: Variant = program.get("seasons", [])
	if seasons_value is Array:
		for value: Variant in seasons_value:
			if value is Dictionary:
				max_number = maxi(max_number, int((value as Dictionary).get("number", 0)))
	return max_number + 1 if max_number > 0 else 2


static func _get_existing_codes(program: Dictionary, season_number: int) -> Array[int]:
	var result: Array[int] = []
	var seasons_value: Variant = program.get("seasons", [])
	if seasons_value is Array:
		for value: Variant in seasons_value:
			if not value is Dictionary:
				continue
			var season: Dictionary = value
			if int(season.get("number", 0)) != season_number:
				continue
			var codes_value: Variant = season.get("unit_codes", [])
			if codes_value is Array:
				for code_value: Variant in codes_value:
					var code := int(code_value)
					if code > 0:
						result.append(code)
			break
	return result


static func _refresh_code_dropdown(select: OptionButton, program: Dictionary, selected_codes: Array[int]) -> void:
	select.clear()
	var blocked: Dictionary = {}
	var units_value: Variant = program.get("units", [])
	if units_value is Array:
		for value: Variant in units_value:
			if not value is Dictionary:
				continue
			var unit: Dictionary = value
			var code_prod := int(unit.get("code_prod", 0))
			var season := int(unit.get("season", 0))
			if season > 0 and not selected_codes.has(code_prod):
				blocked[code_prod] = true
	if units_value is Array:
		for value: Variant in units_value:
			if not value is Dictionary:
				continue
			var code_prod := int((value as Dictionary).get("code_prod", 0))
			if code_prod <= 0 or selected_codes.has(code_prod) or blocked.has(code_prod):
				continue
			select.add_item("Code prod %d" % code_prod)
			select.set_item_metadata(select.item_count - 1, code_prod)


static func _rebuild_selected_codes(holder: VBoxContainer, selected_codes: Array[int], refresh_selection: Callable) -> void:
	for child: Node in holder.get_children():
		holder.remove_child(child)
		child.queue_free()
	if selected_codes.is_empty():
		var empty := Label.new()
		empty.text = "Aucune unité sélectionnée."
		holder.add_child(empty)
		return
	for index: int in range(selected_codes.size()):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		holder.add_child(row)
		var label := Label.new()
		label.text = "Épisode %d → Code prod %d" % [index + 1, selected_codes[index]]
		label.custom_minimum_size = Vector2(320, 36)
		row.add_child(label)
		var remove_button := Button.new()
		remove_button.text = "Retirer"
		var code_to_remove := selected_codes[index]
		remove_button.pressed.connect(func() -> void:
			selected_codes.erase(code_to_remove)
			refresh_selection.call()
		)
		row.add_child(remove_button)


static func _program_with_local_season(program: Dictionary, season_number: int, selected_codes: Array[int]) -> Dictionary:
	var copy := program.duplicate(true)
	var seasons: Array = []
	var seasons_value: Variant = copy.get("seasons", [])
	if seasons_value is Array:
		seasons = (seasons_value as Array).duplicate(true)
	var replaced := false
	for index: int in range(seasons.size()):
		var value: Variant = seasons[index]
		if value is Dictionary and int((value as Dictionary).get("number", 0)) == season_number:
			seasons[index] = {"number": season_number, "unit_codes": selected_codes.duplicate()}
			replaced = true
			break
	if not replaced:
		seasons.append({"number": season_number, "unit_codes": selected_codes.duplicate()})
	copy["seasons"] = seasons
	return copy


static func _build_current_seasons(parent: VBoxContainer, program: Dictionary) -> void:
	var title := Label.new()
	title.text = "Saisons actuelles"
	title.add_theme_font_size_override("font_size", 18)
	parent.add_child(title)
	var seasons_value: Variant = program.get("seasons", [])
	if not seasons_value is Array or (seasons_value as Array).is_empty():
		var empty := Label.new()
		empty.text = "Aucune saison éditoriale créée."
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
