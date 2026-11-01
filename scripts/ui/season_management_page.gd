class_name SeasonManagementPage
extends RefCounted

const DYNAMIC_NODE_NAME: String = "SeasonManagementDynamic"


static func render(
	content_container: VBoxContainer,
	page_description: Label,
	program: Dictionary,
	on_back: Callable,
	on_save: Callable
) -> void:
	clear(content_container)
	page_description.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	page_description.text = "Classe les unités du programme dans les saisons éditoriales."

	var dynamic: VBoxContainer = VBoxContainer.new()
	dynamic.name = DYNAMIC_NODE_NAME
	dynamic.add_theme_constant_override("separation", 12)
	content_container.add_child(dynamic)

	var back_button: Button = Button.new()
	back_button.text = "← Retour à la fiche programme"
	back_button.custom_minimum_size = Vector2(240, 40)
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back_button.pressed.connect(on_back)
	dynamic.add_child(back_button)

	var form: GridContainer = GridContainer.new()
	form.columns = 2
	form.add_theme_constant_override("h_separation", 14)
	form.add_theme_constant_override("v_separation", 10)
	dynamic.add_child(form)

	var season_input: SpinBox = SpinBox.new()
	season_input.min_value = 1
	season_input.max_value = 999
	season_input.value = 1
	season_input.step = 1
	season_input.custom_minimum_size = Vector2(500, 40)
	_add_field(form, "Saison", season_input)

	var code_select: OptionButton = OptionButton.new()
	code_select.custom_minimum_size = Vector2(500, 40)
	_add_field(form, "Code prod", code_select)

	var add_button: Button = Button.new()
	add_button.text = "Ajouter à la saison"
	add_button.custom_minimum_size = Vector2(200, 40)
	add_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	dynamic.add_child(add_button)

	var selected_title: Label = Label.new()
	selected_title.text = "Ordre éditorial de la saison :"
	dynamic.add_child(selected_title)

	var selected_list: VBoxContainer = VBoxContainer.new()
	selected_list.add_theme_constant_override("separation", 6)
	dynamic.add_child(selected_list)

	var selected_codes: Array[int] = []
	var available_codes: Array[int] = _get_available_codes(program, int(season_input.value))
	var callbacks: Dictionary = {}

	callbacks["refresh_select"] = func() -> void:
		code_select.clear()
		for code_prod: int in available_codes:
			if selected_codes.has(code_prod):
				continue
			code_select.add_item("Code prod %d" % code_prod)
			code_select.set_item_metadata(code_select.item_count - 1, code_prod)
		code_select.disabled = code_select.item_count == 0
		add_button.disabled = code_select.item_count == 0

	callbacks["refresh_selected_list"] = func() -> void:
		for child: Node in selected_list.get_children():
			selected_list.remove_child(child)
			child.queue_free()

		if selected_codes.is_empty():
			var empty_label: Label = Label.new()
			empty_label.text = "Aucun code prod sélectionné."
			selected_list.add_child(empty_label)
			return

		for index: int in range(selected_codes.size()):
			var row: HBoxContainer = HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			selected_list.add_child(row)

			var label: Label = Label.new()
			label.text = "%d. Code prod %d" % [index + 1, selected_codes[index]]
			label.custom_minimum_size = Vector2(260, 36)
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			row.add_child(label)

			var remove_button: Button = Button.new()
			remove_button.text = "Retirer"
			var captured_index: int = index
			remove_button.pressed.connect(func() -> void:
				if captured_index < 0 or captured_index >= selected_codes.size():
					return
				selected_codes.remove_at(captured_index)
				var refresh_list_callable: Callable = callbacks.get("refresh_selected_list", Callable())
				if refresh_list_callable.is_valid():
					refresh_list_callable.call()
				var refresh_select_callable: Callable = callbacks.get("refresh_select", Callable())
				if refresh_select_callable.is_valid():
					refresh_select_callable.call()
			)
			row.add_child(remove_button)

	callbacks["reload_for_season"] = func() -> void:
		selected_codes.clear()
		available_codes = _get_available_codes(program, int(season_input.value))
		var existing_codes: Array[int] = _get_existing_codes_for_season(program, int(season_input.value))
		for code_prod: int in existing_codes:
			selected_codes.append(code_prod)
			if not available_codes.has(code_prod):
				available_codes.append(code_prod)
		available_codes.sort()
		var refresh_list_callable: Callable = callbacks.get("refresh_selected_list", Callable())
		if refresh_list_callable.is_valid():
			refresh_list_callable.call()
		var refresh_select_callable: Callable = callbacks.get("refresh_select", Callable())
		if refresh_select_callable.is_valid():
			refresh_select_callable.call()

	season_input.value_changed.connect(func(_value: float) -> void:
		var reload_callable: Callable = callbacks.get("reload_for_season", Callable())
		if reload_callable.is_valid():
			reload_callable.call()
	)

	add_button.pressed.connect(func() -> void:
		if code_select.item_count <= 0 or code_select.selected < 0:
			return
		var code_prod: int = int(code_select.get_item_metadata(code_select.selected))
		if code_prod <= 0 or selected_codes.has(code_prod):
			return
		selected_codes.append(code_prod)
		var refresh_list_callable: Callable = callbacks.get("refresh_selected_list", Callable())
		if refresh_list_callable.is_valid():
			refresh_list_callable.call()
		var refresh_select_callable: Callable = callbacks.get("refresh_select", Callable())
		if refresh_select_callable.is_valid():
			refresh_select_callable.call()
	)

	var info_label: Label = Label.new()
	info_label.text = "Chaque code choisi disparaît du menu. L'ordre d'ajout devient l'ordre éditorial de la saison."
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dynamic.add_child(info_label)

	var error_label: Label = Label.new()
	error_label.text = ""
	dynamic.add_child(error_label)

	var save_button: Button = Button.new()
	save_button.text = "Enregistrer la saison"
	save_button.custom_minimum_size = Vector2(220, 44)
	save_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	dynamic.add_child(save_button)

	save_button.pressed.connect(func() -> void:
		if selected_codes.is_empty():
			error_label.text = "Ajoute au moins un code prod à la saison."
			return

		var result: Variant = on_save.call(int(season_input.value), selected_codes.duplicate())
		var error_text: String = String(result)
		if not error_text.is_empty():
			error_label.text = error_text
			return
		error_label.text = "Saison enregistrée."
	)

	var reload_callable: Callable = callbacks.get("reload_for_season", Callable())
	if reload_callable.is_valid():
		reload_callable.call()


static func clear(content_container: VBoxContainer) -> void:
	var existing: Node = content_container.get_node_or_null(DYNAMIC_NODE_NAME)
	if existing != null:
		content_container.remove_child(existing)
		existing.queue_free()


static func _add_field(form: GridContainer, label_text: String, control: Control) -> void:
	var label: Label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(190, 40)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	form.add_child(label)
	form.add_child(control)


static func _get_available_codes(program: Dictionary, season_number: int) -> Array[int]:
	var result: Array[int] = []
	var units_value: Variant = program.get("units", [])
	if units_value is Array:
		for value: Variant in units_value:
			if not value is Dictionary:
				continue
			var unit: Dictionary = value
			var code_prod: int = int(unit.get("code_prod", 0))
			var current_season: int = int(unit.get("season", 0))
			if code_prod <= 0:
				continue
			if current_season == 0 or current_season == season_number:
				result.append(code_prod)
	result.sort()
	return result


static func _get_existing_codes_for_season(program: Dictionary, season_number: int) -> Array[int]:
	var result: Array[Dictionary] = []
	var units_value: Variant = program.get("units", [])
	if units_value is Array:
		for value: Variant in units_value:
			if not value is Dictionary:
				continue
			var unit: Dictionary = value
			if int(unit.get("season", 0)) == season_number:
				result.append(unit)

	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("episode_in_season", 0)) < int(b.get("episode_in_season", 0))
	)

	var codes: Array[int] = []
	for unit: Dictionary in result:
		codes.append(int(unit.get("code_prod", 0)))
	return codes
