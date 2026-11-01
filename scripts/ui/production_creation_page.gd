class_name ProductionCreationPage
extends RefCounted

const ProductionRulesScript = preload("res://scripts/core/production_rules.gd")
const DYNAMIC_NODE_NAME: String = "ProductionCreationDynamic"


static func render(
	content_container: VBoxContainer,
	page_description: Label,
	on_back: Callable,
	on_submit: Callable
) -> void:
	clear(content_container)
	page_description.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	page_description.text = "Créez une nouvelle production pour votre groupe. La saison complète devra être terminée avant toute diffusion."

	var dynamic: VBoxContainer = VBoxContainer.new()
	dynamic.name = DYNAMIC_NODE_NAME
	dynamic.add_theme_constant_override("separation", 12)
	content_container.add_child(dynamic)

	var back_button: Button = Button.new()
	back_button.text = "← Retour aux Productions"
	back_button.custom_minimum_size = Vector2(210, 40)
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back_button.pressed.connect(on_back)
	dynamic.add_child(back_button)

	var form: GridContainer = GridContainer.new()
	form.columns = 2
	form.add_theme_constant_override("h_separation", 14)
	form.add_theme_constant_override("v_separation", 10)
	dynamic.add_child(form)

	var name_input: LineEdit = LineEdit.new()
	name_input.placeholder_text = "Nom du programme"
	name_input.custom_minimum_size = Vector2(420, 40)
	_add_field(form, "Nom", name_input)

	var format_select: OptionButton = OptionButton.new()
	format_select.custom_minimum_size = Vector2(260, 40)
	for format_name: String in ProductionRulesScript.get_formats():
		format_select.add_item(format_name)
	_add_field(form, "Format", format_select)

	var duration_select: OptionButton = OptionButton.new()
	duration_select.custom_minimum_size = Vector2(260, 40)
	_add_field(form, "Durée", duration_select)

	var episodes_input: LineEdit = LineEdit.new()
	episodes_input.text = "7"
	episodes_input.placeholder_text = "Nombre d'épisodes"
	episodes_input.custom_minimum_size = Vector2(260, 40)
	_add_field(form, "Épisodes", episodes_input)

	var season_label: Label = Label.new()
	season_label.text = "Saison 1"
	season_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_add_field(form, "Saison", season_label)

	var summary: VBoxContainer = VBoxContainer.new()
	summary.add_theme_constant_override("separation", 4)
	dynamic.add_child(summary)

	var cost_label: Label = Label.new()
	var time_label: Label = Label.new()
	var availability_label: Label = Label.new()
	availability_label.text = "Disponibilité : après la fin complète de la production."
	summary.add_child(cost_label)
	summary.add_child(time_label)
	summary.add_child(availability_label)

	var error_label: Label = Label.new()
	error_label.text = ""
	dynamic.add_child(error_label)

	var launch_button: Button = Button.new()
	launch_button.text = "Lancer la production"
	launch_button.custom_minimum_size = Vector2(230, 44)
	launch_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	dynamic.add_child(launch_button)

	var refresh_form: Callable = func() -> void:
		_refresh_duration_options(format_select, duration_select, episodes_input)
		_refresh_season_label(format_select, season_label)
		_refresh_summary(format_select, duration_select, episodes_input, cost_label, time_label)

	format_select.item_selected.connect(func(_index: int) -> void:
		refresh_form.call()
	)
	duration_select.item_selected.connect(func(_index: int) -> void:
		_refresh_summary(format_select, duration_select, episodes_input, cost_label, time_label)
	)
	episodes_input.text_changed.connect(func(_text: String) -> void:
		_refresh_summary(format_select, duration_select, episodes_input, cost_label, time_label)
	)

	launch_button.pressed.connect(func() -> void:
		var spec: Dictionary = _build_spec(name_input, format_select, duration_select, episodes_input)
		var validation_error: String = _validate_spec(spec)
		if not validation_error.is_empty():
			error_label.text = validation_error
			return

		var submit_result: Variant = on_submit.call(spec)
		var submit_error: String = String(submit_result)
		if not submit_error.is_empty():
			error_label.text = submit_error
	)

	refresh_form.call()
	name_input.grab_focus()


static func clear(content_container: VBoxContainer) -> void:
	var existing: Node = content_container.get_node_or_null(DYNAMIC_NODE_NAME)
	if existing != null:
		content_container.remove_child(existing)
		existing.queue_free()


static func _add_field(form: GridContainer, label_text: String, control: Control) -> void:
	var label: Label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(150, 40)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	form.add_child(label)
	form.add_child(control)


static func _refresh_duration_options(
	format_select: OptionButton,
	duration_select: OptionButton,
	episodes_input: LineEdit
) -> void:
	var format_name: String = format_select.get_item_text(format_select.selected)
	var previous_duration: int = _get_selected_duration(duration_select)
	duration_select.clear()

	var durations: Array[int] = ProductionRulesScript.get_durations(format_name)
	var selected_index: int = 0
	for index: int in range(durations.size()):
		var duration_minutes: int = durations[index]
		duration_select.add_item("%d min" % duration_minutes)
		duration_select.set_item_metadata(index, duration_minutes)
		if duration_minutes == previous_duration:
			selected_index = index

	if duration_select.item_count > 0:
		duration_select.select(selected_index)

	var single_unit: bool = ProductionRulesScript.is_single_unit(format_name)
	episodes_input.editable = not single_unit
	if single_unit:
		episodes_input.text = "1"
	elif int(episodes_input.text) <= 0:
		episodes_input.text = "7"


static func _refresh_season_label(format_select: OptionButton, season_label: Label) -> void:
	var format_name: String = format_select.get_item_text(format_select.selected)
	season_label.text = "—" if ProductionRulesScript.is_single_unit(format_name) else "Saison 1"


static func _refresh_summary(
	format_select: OptionButton,
	duration_select: OptionButton,
	episodes_input: LineEdit,
	cost_label: Label,
	time_label: Label
) -> void:
	var format_name: String = format_select.get_item_text(format_select.selected)
	var duration_minutes: int = _get_selected_duration(duration_select)
	var episode_count: int = maxi(int(episodes_input.text), 1)
	var cost: int = ProductionRulesScript.get_cost(format_name)
	var days: int = ProductionRulesScript.get_total_days(format_name, duration_minutes, episode_count)

	cost_label.text = "Coût : %d CC" % cost
	time_label.text = "Durée de production : %d jour(s)" % days


static func _build_spec(
	name_input: LineEdit,
	format_select: OptionButton,
	duration_select: OptionButton,
	episodes_input: LineEdit
) -> Dictionary:
	var format_name: String = format_select.get_item_text(format_select.selected)
	return {
		"name": name_input.text.strip_edges(),
		"format": format_name,
		"duration_minutes": _get_selected_duration(duration_select),
		"episodes_total": 1 if ProductionRulesScript.is_single_unit(format_name) else int(episodes_input.text),
		"season_number": 0 if ProductionRulesScript.is_single_unit(format_name) else 1
	}


static func _validate_spec(spec: Dictionary) -> String:
	var name: String = String(spec.get("name", "")).strip_edges()
	if name.is_empty():
		return "Renseigne le nom du programme."

	var format_name: String = String(spec.get("format", ""))
	if not ProductionRulesScript.get_formats().has(format_name):
		return "Format de production invalide."

	var duration_minutes: int = int(spec.get("duration_minutes", 0))
	if not ProductionRulesScript.get_durations(format_name).has(duration_minutes):
		return "Durée non autorisée pour ce format."

	var episode_count: int = int(spec.get("episodes_total", 0))
	if episode_count <= 0:
		return "Le nombre d'épisodes doit être au minimum de 1."

	if ProductionRulesScript.get_total_minutes(format_name, duration_minutes, episode_count) <= 0:
		return "La durée de production de ce format n'est pas encore définie."

	return ""


static func _get_selected_duration(duration_select: OptionButton) -> int:
	if duration_select.item_count <= 0 or duration_select.selected < 0:
		return 0
	var metadata: Variant = duration_select.get_item_metadata(duration_select.selected)
	return int(metadata)
