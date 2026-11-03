class_name TVGridPageController
extends RefCounted

const WeekSelectorScript = preload("res://scripts/ui/schedule_week_selector.gd")
const TimeRangeSelectorScript = preload("res://scripts/ui/schedule_time_range_selector.gd")
const DayScheduleBuilderScript = preload("res://scripts/ui/tv_day_schedule_builder.gd")
const ProgramCatalogPanelScript = preload("res://scripts/ui/program_catalog_panel.gd")
const ScheduleTrashTargetScript = preload("res://scripts/ui/schedule_trash_target.gd")
const DYNAMIC_NODE_NAME: String = "GridDynamic"


static func render(
	content_container: VBoxContainer,
	page_description: Label,
	channel: Dictionary,
	editable: bool,
	programs: Array[Dictionary],
	on_back: Callable = Callable(),
	on_program_selected: Callable = Callable()
) -> void:
	clear(content_container)
	page_description.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	if editable:
		page_description.text = ""
		_update_editable_page_title(content_container, channel)
	else:
		page_description.text = _get_description(channel, editable)

	var displayed_programs: Array[Dictionary] = _get_displayed_programs(channel, programs, editable)
	var view_state: Dictionary = {
		"week_number": 1,
		"time_range_id": TimeRangeSelectorScript.DEFAULT_RANGE_ID
	}

	var dynamic: VBoxContainer = VBoxContainer.new()
	dynamic.name = DYNAMIC_NODE_NAME
	dynamic.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dynamic.add_theme_constant_override("separation", 8)
	content_container.add_child(dynamic)

	if on_back.is_valid():
		var back_button: Button = Button.new()
		back_button.text = "← Retour à Zap'Chaine"
		back_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		back_button.pressed.connect(on_back)
		dynamic.add_child(back_button)

	var top_row: HBoxContainer = HBoxContainer.new()
	top_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_theme_constant_override("separation", 12)
	dynamic.add_child(top_row)

	var week_holder: HBoxContainer = HBoxContainer.new()
	week_holder.custom_minimum_size = Vector2(220, 0)
	week_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	week_holder.size_flags_stretch_ratio = 1.0
	top_row.add_child(week_holder)

	var days_holder: HBoxContainer = HBoxContainer.new()
	days_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	days_holder.size_flags_stretch_ratio = 3.0
	days_holder.add_theme_constant_override("separation", 6)
	top_row.add_child(days_holder)

	var time_range_holder: HBoxContainer = null
	if editable:
		var time_range_row: HBoxContainer = HBoxContainer.new()
		time_range_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		time_range_row.add_theme_constant_override("separation", 12)
		dynamic.add_child(time_range_row)

		var time_range_label_holder: HBoxContainer = HBoxContainer.new()
		time_range_label_holder.custom_minimum_size = Vector2(220, 0)
		time_range_label_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		time_range_label_holder.size_flags_stretch_ratio = 1.0
		time_range_row.add_child(time_range_label_holder)

		var time_range_label: Label = Label.new()
		time_range_label.text = "Plage horaire :"
		time_range_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		time_range_label_holder.add_child(time_range_label)

		time_range_holder = HBoxContainer.new()
		time_range_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		time_range_holder.size_flags_stretch_ratio = 3.0
		time_range_holder.add_theme_constant_override("separation", 6)
		time_range_row.add_child(time_range_holder)

	var trash_target: Control = null
	if editable:
		var trash_row: HBoxContainer = HBoxContainer.new()
		trash_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		trash_row.alignment = BoxContainer.ALIGNMENT_END
		dynamic.add_child(trash_row)

		trash_target = ScheduleTrashTargetScript.new()
		trash_target.size_flags_horizontal = Control.SIZE_SHRINK_END
		trash_row.add_child(trash_target)

	var body: HBoxContainer = HBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	dynamic.add_child(body)
	if editable:
		# Le catalogue et les horaires restent dans la zone visible.
		# Leurs barres de défilement sont indépendantes.
		var main_scroll: ScrollContainer = content_container.get_parent() as ScrollContainer
		if main_scroll != null:
			var fit_to_viewport: Callable = func() -> void:
				if not is_instance_valid(body) or not is_instance_valid(main_scroll):
					return
				var available: float = (
					main_scroll.get_global_rect().end.y
					- body.get_global_rect().position.y - 12.0
				)
				body.custom_minimum_size = Vector2(0, maxf(220.0, available))
			main_scroll.resized.connect(fit_to_viewport)
			fit_to_viewport.call_deferred()

	var catalog_holder: VBoxContainer = VBoxContainer.new()
	catalog_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	catalog_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	catalog_holder.size_flags_stretch_ratio = 1.0
	catalog_holder.custom_minimum_size = Vector2(220, 0)
	body.add_child(catalog_holder)

	var scheduler_holder: VBoxContainer = VBoxContainer.new()
	scheduler_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scheduler_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scheduler_holder.size_flags_stretch_ratio = 3.0
	scheduler_holder.add_theme_constant_override("separation", 6)
	body.add_child(scheduler_holder)

	var schedule_holder: VBoxContainer = VBoxContainer.new()
	schedule_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	schedule_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scheduler_holder.add_child(schedule_holder)

	var rebuild_catalog: Callable = func() -> void:
		var saved_scroll: int = 0
		var current_scroll: ScrollContainer = catalog_holder.find_child(
			"ProgramListScroll", true, false
		) as ScrollContainer
		if current_scroll != null:
			saved_scroll = current_scroll.scroll_vertical
		_clear_holder(catalog_holder)
		ProgramCatalogPanelScript.build(
			catalog_holder,
			editable,
			displayed_programs,
			on_program_selected,
			channel,
			int(view_state.get("week_number", 1))
		)
		var next_scroll: ScrollContainer = catalog_holder.find_child(
			"ProgramListScroll", true, false
		) as ScrollContainer
		if next_scroll != null:
			next_scroll.set_deferred("scroll_vertical", saved_scroll)

	var rebuild_schedule: Callable = func(week_number: int) -> void:
		view_state["week_number"] = week_number
		rebuild_catalog.call()
		_clear_holder(schedule_holder)
		_clear_holder(days_holder)
		DayScheduleBuilderScript.build(
			schedule_holder,
			week_number,
			editable,
			channel,
			displayed_programs,
			on_program_selected,
			days_holder,
			String(view_state.get("time_range_id", "")) if editable else "",
			rebuild_catalog
		)

	if editable and trash_target != null:
		var refresh_after_delete: Callable = func() -> void:
			rebuild_schedule.call(int(view_state.get("week_number", 1)))
		trash_target.call("configure", channel, refresh_after_delete)

	if editable and time_range_holder != null:
		var on_time_range_selected: Callable = func(range_id: String) -> void:
			var selected_day_index: int = 0
			for index: int in range(days_holder.get_child_count()):
				var day_node: Node = days_holder.get_child(index)
				if day_node is Button and (day_node as Button).disabled:
					selected_day_index = index
					break

			view_state["time_range_id"] = range_id
			TimeRangeSelectorScript.select(time_range_holder, range_id)
			rebuild_schedule.call(int(view_state.get("week_number", 1)))

			if selected_day_index >= 0 and selected_day_index < days_holder.get_child_count():
				var restored_day_node: Node = days_holder.get_child(selected_day_index)
				if restored_day_node is Button:
					(restored_day_node as Button).pressed.emit()

		TimeRangeSelectorScript.build(
			time_range_holder,
			String(view_state.get("time_range_id", TimeRangeSelectorScript.DEFAULT_RANGE_ID)),
			on_time_range_selected
		)

	var selector_row: HBoxContainer = WeekSelectorScript.build(rebuild_schedule)
	selector_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	week_holder.add_child(selector_row)

	rebuild_schedule.call(1)


static func clear(content_container: VBoxContainer) -> void:
	var existing: Node = content_container.get_node_or_null(DYNAMIC_NODE_NAME)
	if existing != null:
		content_container.remove_child(existing)
		existing.queue_free()


static func _update_editable_page_title(
	content_container: VBoxContainer,
	channel: Dictionary
) -> void:
	var title_node: Node = content_container.get_node_or_null("PageTitle")
	if not title_node is Label:
		return

	var title_label: Label = title_node as Label
	var channel_name: String = String(channel.get("name", ""))
	title_label.text = "Grille TV | Chaîne : %s" % channel_name


static func _get_displayed_programs(
	channel: Dictionary,
	provided_programs: Array[Dictionary],
	editable: bool
) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for program: Dictionary in provided_programs:
		result.append(program.duplicate(true))

	if editable or not result.is_empty():
		return result

	if _is_player_channel(channel):
		return GameState.get_group_programs()

	var channel_programs_value: Variant = channel.get("programs", [])
	if channel_programs_value is Array:
		for value: Variant in channel_programs_value:
			if value is Dictionary:
				result.append((value as Dictionary).duplicate(true))

	return result


static func _is_player_channel(channel: Dictionary) -> bool:
	var player_channel: Dictionary = GameState.get_first_channel()
	if player_channel.is_empty():
		return false
	return int(channel.get("mmtn_number", 0)) == int(player_channel.get("mmtn_number", -1))


static func _get_description(channel: Dictionary, editable: bool) -> String:
	var channel_name: String = String(channel.get("name", ""))
	if editable:
		return "Chaîne : %s" % channel_name
	return "Chaîne : %s | consultation uniquement, aucune modification possible." % channel_name


static func _clear_holder(holder: Control) -> void:
	for child: Node in holder.get_children():
		holder.remove_child(child)
		child.queue_free()
