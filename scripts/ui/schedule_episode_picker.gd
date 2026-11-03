class_name ScheduleEpisodePicker
extends RefCounted

const UIThemeManagerScript = preload("res://scripts/ui/ui_theme_manager.gd")

const ScheduleEpisodeHelperScript = preload("res://scripts/ui/schedule_episode_helper.gd")

const SLOT_MINUTES: int = 30
const SLOTS_PER_DAY: int = 48
const DAYS_PER_YEAR: int = 364
const BROADCAST_EPISODE_COLOR: Color = Color(1.0, 0.55, 0.15, 1.0)
const DAY_NAMES: Array[String] = [
	"Lundi",
	"Mardi",
	"Mercredi",
	"Jeudi",
	"Vendredi",
	"Samedi",
	"Dimanche"
]


static func open(
	anchor: Control,
	channel: Dictionary,
	week_number: int,
	day_index: int,
	slot_index: int,
	program: Dictionary,
	refresh_callback: Callable,
	replace_existing: bool = false
) -> void:
	if anchor == null:
		return

	var existing: Node = anchor.get_node_or_null("ScheduleEpisodePicker")
	if existing != null:
		existing.queue_free()

	var episode_count: int = ScheduleEpisodeHelperScript.get_episode_count(program)
	if episode_count <= 0:
		_place_without_episode(
			channel,
			week_number,
			day_index,
			slot_index,
			program,
			refresh_callback,
			replace_existing
		)
		return

	var popup: PopupPanel = PopupPanel.new()
	popup.name = "ScheduleEpisodePicker"
	anchor.add_child(popup)
	UIThemeManagerScript.apply_popup_theme(popup, anchor)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	popup.add_child(margin)

	var content: VBoxContainer = VBoxContainer.new()
	content.custom_minimum_size = Vector2(720, 0)
	content.add_theme_constant_override("separation", 10)
	margin.add_child(content)

	var title: Label = Label.new()
	title.text = "Programmer | %s" % String(program.get("name", "Programme"))
	title.add_theme_font_size_override("font_size", 22)
	content.add_child(title)

	var mode_row: HBoxContainer = HBoxContainer.new()
	mode_row.add_theme_constant_override("separation", 8)
	content.add_child(mode_row)

	var manual_button: Button = Button.new()
	manual_button.text = "Manuel"
	manual_button.toggle_mode = true
	manual_button.button_pressed = true
	manual_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	manual_button.custom_minimum_size = Vector2(0, 42)
	mode_row.add_child(manual_button)

	var automation_button: Button = Button.new()
	automation_button.text = "Automatisation"
	automation_button.toggle_mode = true
	automation_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	automation_button.custom_minimum_size = Vector2(0, 42)
	mode_row.add_child(automation_button)

	var editing_existing: bool = (
		_is_existing_start(channel, week_number, day_index, slot_index)
		and not replace_existing
	)
	if editing_existing:
		automation_button.disabled = true
		automation_button.tooltip_text = "Une diffusion déjà programmée se modifie en mode manuel."

	var manual_container: VBoxContainer = VBoxContainer.new()
	manual_container.add_theme_constant_override("separation", 8)
	content.add_child(manual_container)

	var manual_hint: Label = Label.new()
	manual_hint.text = "Choisissez l'épisode à diffuser. Orange = épisode déjà programmé ou déjà diffusé."
	manual_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	manual_container.add_child(manual_hint)

	var selected_episode_data: Dictionary = {}
	var episode_selector_button: Button = Button.new()
	episode_selector_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	episode_selector_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	episode_selector_button.custom_minimum_size = Vector2(0, 44)
	manual_container.add_child(episode_selector_button)

	var episode_dropdown: ScrollContainer = ScrollContainer.new()
	episode_dropdown.visible = false
	episode_dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	episode_dropdown.custom_minimum_size = Vector2(0, mini(episode_count * 40, 300))
	manual_container.add_child(episode_dropdown)

	var episode_items: VBoxContainer = VBoxContainer.new()
	episode_items.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	episode_items.add_theme_constant_override("separation", 4)
	episode_dropdown.add_child(episode_items)

	var first_available: bool = false
	for global_episode: int in range(1, episode_count + 1):
		var episode_data: Dictionary = ScheduleEpisodeHelperScript.get_episode_data(program, global_episode)
		if episode_data.is_empty():
			continue

		var compact_label: String = ScheduleEpisodeHelperScript.get_compact_label(program, episode_data)
		if compact_label.is_empty():
			compact_label = "Épisode %d" % global_episode

		var future_broadcast: Dictionary = _find_next_future_broadcast(program, episode_data)
		var display_label: String = compact_label
		if not future_broadcast.is_empty():
			display_label += " | diffusion : %s" % String(future_broadcast.get("date_text", ""))

		var already_used: bool = _episode_was_broadcast(program, episode_data) or not future_broadcast.is_empty()
		var episode_button: Button = Button.new()
		episode_button.text = display_label
		episode_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		episode_button.custom_minimum_size = Vector2(0, 36)
		episode_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		episode_button.tooltip_text = String(episode_data.get("label", compact_label))
		_apply_episode_background(episode_button, already_used)
		episode_items.add_child(episode_button)

		var captured_episode: Dictionary = episode_data.duplicate(true)
		var captured_label: String = display_label
		var captured_used: bool = already_used
		episode_button.pressed.connect(func() -> void:
			selected_episode_data = captured_episode.duplicate(true)
			episode_selector_button.text = captured_label
			_apply_episode_background(episode_selector_button, captured_used)
			episode_dropdown.visible = false
		)

		if not first_available:
			first_available = true
			selected_episode_data = episode_data.duplicate(true)
			episode_selector_button.text = display_label
			_apply_episode_background(episode_selector_button, already_used)

	if not first_available:
		episode_selector_button.text = "Aucun épisode disponible"
		episode_selector_button.disabled = true

	episode_selector_button.pressed.connect(func() -> void:
		episode_dropdown.visible = not episode_dropdown.visible
	)

	var manual_program_button: Button = Button.new()
	manual_program_button.text = "Programmer cet épisode"
	manual_program_button.custom_minimum_size = Vector2(0, 42)
	manual_program_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	manual_container.add_child(manual_program_button)

	manual_program_button.pressed.connect(func() -> void:
		if selected_episode_data.is_empty():
			return

		var saved: bool = false
		if editing_existing:
			saved = GameState.update_scheduled_episode(
				channel,
				week_number,
				day_index,
				slot_index,
				selected_episode_data
			)
		elif replace_existing:
			saved = GameState.replace_scheduled_program(
				channel,
				week_number,
				day_index,
				slot_index,
				program,
				selected_episode_data
			)
		else:
			saved = GameState.schedule_program(
				channel,
				week_number,
				day_index,
				slot_index,
				program,
				selected_episode_data
			)

		if not saved:
			return
		popup.hide()
		if refresh_callback.is_valid():
			refresh_callback.call()
	)

	var automation_container: VBoxContainer = VBoxContainer.new()
	automation_container.visible = false
	automation_container.add_theme_constant_override("separation", 8)
	content.add_child(automation_container)

	var automation_panel: PanelContainer = PanelContainer.new()
	automation_container.add_child(automation_panel)

	var automation_box: VBoxContainer = VBoxContainer.new()
	automation_box.add_theme_constant_override("separation", 6)
	automation_panel.add_child(automation_box)

	var automation_title: Label = Label.new()
	automation_title.text = "Automatisation"
	automation_title.add_theme_font_size_override("font_size", 18)
	automation_box.add_child(automation_title)

	var days_row: HBoxContainer = HBoxContainer.new()
	days_row.add_theme_constant_override("separation", 6)
	automation_box.add_child(days_row)

	var days_label: Label = Label.new()
	days_label.text = "Jours de diffusion :"
	days_label.custom_minimum_size = Vector2(180, 0)
	days_row.add_child(days_label)

	var day_checks: Array[CheckButton] = []
	for index: int in range(DAY_NAMES.size()):
		var day_check: CheckButton = CheckButton.new()
		day_check.text = DAY_NAMES[index].substr(0, 3)
		day_check.button_pressed = index == day_index
		day_check.tooltip_text = DAY_NAMES[index]
		days_row.add_child(day_check)
		day_checks.append(day_check)

	var presets_row: HBoxContainer = HBoxContainer.new()
	presets_row.add_theme_constant_override("separation", 6)
	automation_box.add_child(presets_row)

	var presets_spacer: Control = Control.new()
	presets_spacer.custom_minimum_size = Vector2(180, 0)
	presets_row.add_child(presets_spacer)

	var weekdays_button: Button = Button.new()
	weekdays_button.text = "Lun–Ven"
	presets_row.add_child(weekdays_button)
	weekdays_button.pressed.connect(func() -> void:
		_set_selected_days(day_checks, [0, 1, 2, 3, 4])
	)

	var everyday_button: Button = Button.new()
	everyday_button.text = "Tous les jours"
	presets_row.add_child(everyday_button)
	everyday_button.pressed.connect(func() -> void:
		_set_selected_days(day_checks, [0, 1, 2, 3, 4, 5, 6])
	)

	var weekend_button: Button = Button.new()
	weekend_button.text = "Week-end"
	presets_row.add_child(weekend_button)
	weekend_button.pressed.connect(func() -> void:
		_set_selected_days(day_checks, [5, 6])
	)

	var episodes_per_row: HBoxContainer = HBoxContainer.new()
	episodes_per_row.add_theme_constant_override("separation", 8)
	automation_box.add_child(episodes_per_row)

	var episodes_per_label: Label = Label.new()
	episodes_per_label.text = "Épisodes par jour sélectionné :"
	episodes_per_label.custom_minimum_size = Vector2(220, 0)
	episodes_per_row.add_child(episodes_per_label)

	var episodes_per_spinner: SpinBox = SpinBox.new()
	episodes_per_spinner.min_value = 1
	episodes_per_spinner.max_value = episode_count
	episodes_per_spinner.step = 1
	episodes_per_spinner.value = 1
	episodes_per_spinner.allow_greater = false
	episodes_per_spinner.allow_lesser = false
	episodes_per_spinner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	episodes_per_row.add_child(episodes_per_spinner)

	var period_row: HBoxContainer = HBoxContainer.new()
	period_row.add_theme_constant_override("separation", 8)
	automation_box.add_child(period_row)

	var period_label: Label = Label.new()
	period_label.text = "Nombre de semaines :"
	period_label.custom_minimum_size = Vector2(220, 0)
	period_row.add_child(period_label)

	var period_spinner: SpinBox = SpinBox.new()
	period_spinner.min_value = 1
	period_spinner.max_value = maxi(53 - week_number, 1)
	period_spinner.step = 1
	period_spinner.value = 1
	period_spinner.allow_greater = false
	period_spinner.allow_lesser = false
	period_spinner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	period_row.add_child(period_spinner)

	var start_episode_row: HBoxContainer = HBoxContainer.new()
	start_episode_row.add_theme_constant_override("separation", 8)
	automation_box.add_child(start_episode_row)

	var start_episode_label: Label = Label.new()
	start_episode_label.text = "Commencer à l'épisode :"
	start_episode_label.custom_minimum_size = Vector2(220, 0)
	start_episode_row.add_child(start_episode_label)

	var start_episode_selector: OptionButton = OptionButton.new()
	start_episode_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for global_episode: int in range(1, episode_count + 1):
		var episode_data: Dictionary = ScheduleEpisodeHelperScript.get_episode_data(program, global_episode)
		if episode_data.is_empty():
			continue
		start_episode_selector.add_item(
			ScheduleEpisodeHelperScript.get_compact_label(program, episode_data),
			global_episode
		)
	if start_episode_selector.item_count > 0:
		start_episode_selector.select(0)
	start_episode_row.add_child(start_episode_selector)

	var automation_hint: Label = Label.new()
	automation_hint.text = "Choisissez les jours de diffusion, le nombre d'épisodes à la suite pour chaque jour, le nombre de semaines et l'épisode de départ."
	automation_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	automation_box.add_child(automation_hint)

	var launch_automation_button: Button = Button.new()
	launch_automation_button.text = "Lancer l'automatisation"
	launch_automation_button.custom_minimum_size = Vector2(0, 42)
	launch_automation_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	automation_box.add_child(launch_automation_button)

	launch_automation_button.pressed.connect(func() -> void:
		var episodes_per_period: int = int(episodes_per_spinner.value)
		var period_count: int = int(period_spinner.value)
		var selected_days: Array[int] = _get_selected_days(day_checks)
		if selected_days.is_empty():
			_show_selection_error(anchor)
			return
		if start_episode_selector.item_count <= 0:
			return
		var start_global_episode: int = start_episode_selector.get_selected_id()
		var result: Dictionary = _auto_schedule_episodes(
			channel,
			week_number,
			day_index,
			slot_index,
			program,
			start_global_episode,
			episodes_per_period,
			period_count,
			selected_days,
			replace_existing
		)
		if refresh_callback.is_valid():
			refresh_callback.call()
		_show_automation_result(anchor, result)
		popup.hide()
	)

	manual_button.pressed.connect(func() -> void:
		manual_button.button_pressed = true
		automation_button.button_pressed = false
		manual_container.visible = true
		automation_container.visible = false
	)

	automation_button.pressed.connect(func() -> void:
		if automation_button.disabled:
			return
		automation_button.button_pressed = true
		manual_button.button_pressed = false
		manual_container.visible = false
		automation_container.visible = true
	)

	var cancel_button: Button = Button.new()
	cancel_button.text = "Annuler"
	cancel_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	cancel_button.pressed.connect(popup.hide)
	content.add_child(cancel_button)

	popup.popup_hide.connect(func() -> void:
		if is_instance_valid(popup):
			popup.queue_free()
	)
	popup.popup_centered(Vector2i(800, 620))


static func _find_next_future_broadcast(program: Dictionary, episode_data: Dictionary) -> Dictionary:
	var program_id: String = String(program.get("id", ""))
	var global_episode: int = int(episode_data.get("episode_global", 0))
	if program_id.is_empty() or global_episode <= 0:
		return {}

	var current_absolute_minutes: int = (
		(((GameState.week_in_year - 1) * 7) + (GameState.day_in_week - 1)) * 1440
		+ (GameState.hour * 60)
		+ GameState.minute
	)
	var best_absolute_minutes: int = 2147483647
	var best_result: Dictionary = {}

	for player_channel: Dictionary in GameState.get_player_channels():
		for target_week: int in range(1, 53):
			for target_day: int in range(0, 7):
				var day_slots: Array[Dictionary] = GameState.get_player_day_schedule(
					player_channel,
					target_week,
					target_day
				)
				for target_slot: int in range(day_slots.size()):
					var entry: Dictionary = day_slots[target_slot]
					if String(entry.get("kind", "")) != "start":
						continue
					if String(entry.get("program_id", "")) != program_id:
						continue
					if int(entry.get("episode_global", 0)) != global_episode:
						continue

					var target_absolute_minutes: int = (
						(((target_week - 1) * 7) + target_day) * 1440
						+ (target_slot * SLOT_MINUTES)
					)
					if target_absolute_minutes < current_absolute_minutes:
						continue
					if target_absolute_minutes >= best_absolute_minutes:
						continue

					best_absolute_minutes = target_absolute_minutes
					best_result = {
						"week": target_week,
						"day": target_day,
						"slot": target_slot,
						"date_text": _format_schedule_date(target_week, target_day)
					}

	return best_result


static func _format_schedule_date(week_number: int, day_index: int) -> String:
	var remaining_week: int = maxi(week_number, 1)
	var target_month_index: int = 0
	var week_in_month: int = remaining_week

	for month_index: int in range(GameState.MONTHS.size()):
		var month_weeks: int = int(GameState.MONTHS[month_index].get("weeks", 0))
		if week_in_month <= month_weeks:
			target_month_index = month_index
			break
		week_in_month -= month_weeks
		target_month_index = mini(month_index + 1, GameState.MONTHS.size() - 1)

	var day_of_month: int = ((week_in_month - 1) * 7) + day_index + 1
	var month_name: String = String(GameState.MONTHS[target_month_index].get("name", "Mois"))
	return "%d %s %04d" % [day_of_month, month_name, GameState.year]


static func _apply_episode_background(button: Button, highlighted: bool) -> void:
	if not highlighted:
		button.remove_theme_stylebox_override("normal")
		button.remove_theme_stylebox_override("hover")
		button.remove_theme_stylebox_override("pressed")
		return

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = BROADCAST_EPISODE_COLOR
	style.border_color = BROADCAST_EPISODE_COLOR.lightened(0.20)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)


static func _episode_was_broadcast(program: Dictionary, episode_data: Dictionary) -> bool:
	var global_episode: int = int(episode_data.get("episode_global", 0))
	var season_number: int = int(episode_data.get("season_number", 0))
	var episode_number: int = int(episode_data.get("episode_number", global_episode))
	var history_value: Variant = program.get("broadcast_history", [])
	if not history_value is Array:
		return false

	for history_item_value: Variant in history_value:
		if not history_item_value is Dictionary:
			continue
		var history_item: Dictionary = history_item_value as Dictionary

		var history_global: int = int(history_item.get(
			"episode_global",
			history_item.get("code_prod", 0)
		))
		if global_episode > 0 and history_global == global_episode:
			return true

		if season_number > 0:
			var history_season: int = int(history_item.get("season", 0))
			var history_episode: int = int(history_item.get("episode", 0))
			if history_season == season_number and history_episode == episode_number:
				return true

		if season_number <= 0 and int(history_item.get("episode", 0)) == global_episode:
			return true

	return false


static func _auto_schedule_episodes(
	channel: Dictionary,
	start_week: int,
	start_day: int,
	start_slot: int,
	program: Dictionary,
	start_global_episode: int,
	episodes_per_period: int,
	period_count: int,
	selected_days: Array[int],
	replace_first: bool = false
) -> Dictionary:
	var episode_count: int = ScheduleEpisodeHelperScript.get_episode_count(program)
	var scheduled_count: int = 0
	var stop_reason: String = ""
	var automation_id: String = "%s_%d_%d_%d_%d" % [
		String(program.get("id", program.get("name", "program"))),
		start_week,
		start_day,
		start_slot,
		Time.get_ticks_msec()
	]
	var slots_per_episode: int = maxi(
		1,
		int(ceil(float(maxi(int(program.get("duration_minutes", SLOT_MINUTES)), SLOT_MINUTES)) / float(SLOT_MINUTES)))
	)
	var first_write: bool = true
	var target_days: Array[int] = []
	var ordered_days: Array[int] = selected_days.duplicate()
	ordered_days.sort()

	for week_offset: int in range(maxi(period_count, 1)):
		var target_week_number: int = start_week + week_offset
		if target_week_number > 52:
			break
		for selected_day: int in ordered_days:
			if week_offset == 0 and selected_day < start_day:
				continue
			var absolute_day: int = ((target_week_number - 1) * 7) + selected_day
			if absolute_day >= DAYS_PER_YEAR:
				continue
			target_days.append(absolute_day)

	var requested_count: int = target_days.size() * maxi(episodes_per_period, 1)

	for period_absolute_day: int in target_days:
		var cursor_absolute_slot: int = (period_absolute_day * SLOTS_PER_DAY) + start_slot

		for _episode_in_period: int in range(maxi(episodes_per_period, 1)):
			var sequence_index: int = (start_global_episode - 1) + scheduled_count
			var global_episode: int = (sequence_index % episode_count) + 1
			var is_rerun_cycle: bool = sequence_index >= episode_count

			var target_absolute_day: int = int(cursor_absolute_slot / SLOTS_PER_DAY)
			if target_absolute_day >= DAYS_PER_YEAR:
				stop_reason = "La fin de l'année 1 a été atteinte."
				break

			var target_week: int = int(target_absolute_day / 7) + 1
			var target_day: int = target_absolute_day % 7
			var target_slot: int = cursor_absolute_slot % SLOTS_PER_DAY

			var episode_data: Dictionary = ScheduleEpisodeHelperScript.get_episode_data(
				program,
				global_episode
			)
			if episode_data.is_empty():
				stop_reason = "Impossible de retrouver l'épisode à programmer."
				break
			episode_data["automation_id"] = automation_id
			episode_data["automation_frequency"] = "selected_days"
			episode_data["automation_rerun"] = is_rerun_cycle

			var placed: bool = false
			if first_write and replace_first:
				placed = GameState.replace_scheduled_program(
					channel,
					target_week,
					target_day,
					target_slot,
					program,
					episode_data
				)
			else:
				if not GameState.can_schedule_program(
					channel,
					target_week,
					target_day,
					target_slot,
					program
				):
					stop_reason = "Un créneau est déjà occupé en semaine %d, %s à %s." % [
						target_week,
						_get_day_name(target_day),
						_get_time_text(target_slot)
					]
					break
				placed = GameState.schedule_program(
					channel,
					target_week,
					target_day,
					target_slot,
					program,
					episode_data
				)

			if not placed:
				stop_reason = "La programmation s'est arrêtée sur un créneau incompatible."
				break

			first_write = false
			scheduled_count += 1
			cursor_absolute_slot += slots_per_episode

		if not stop_reason.is_empty():
			break

	if target_days.is_empty() and stop_reason.is_empty():
		stop_reason = "Aucun jour de diffusion valide n'a été trouvé dans la période choisie."

	return {
		"scheduled_count": scheduled_count,
		"requested_count": requested_count,
		"stop_reason": stop_reason
	}


static func _set_selected_days(day_checks: Array[CheckButton], selected_days: Array[int]) -> void:
	for index: int in range(day_checks.size()):
		day_checks[index].button_pressed = selected_days.has(index)


static func _get_selected_days(day_checks: Array[CheckButton]) -> Array[int]:
	var result: Array[int] = []
	for index: int in range(day_checks.size()):
		if day_checks[index].button_pressed:
			result.append(index)
	return result


static func _show_selection_error(anchor: Control) -> void:
	var dialog: AcceptDialog = AcceptDialog.new()
	dialog.title = "Jours de diffusion"
	dialog.dialog_text = "Sélectionnez au moins un jour de diffusion pour l'automatisation."
	anchor.add_child(dialog)
	UIThemeManagerScript.apply_popup_theme(dialog, anchor)
	dialog.confirmed.connect(func() -> void:
		if is_instance_valid(dialog):
			dialog.queue_free()
	)
	dialog.canceled.connect(func() -> void:
		if is_instance_valid(dialog):
			dialog.queue_free()
	)
	dialog.popup_centered(Vector2i(520, 190))


static func _show_automation_result(anchor: Control, result: Dictionary) -> void:
	if anchor == null:
		return

	var dialog: AcceptDialog = AcceptDialog.new()
	dialog.title = "Programmation automatique"
	var scheduled_count: int = int(result.get("scheduled_count", 0))
	var requested_count: int = int(result.get("requested_count", 0))
	var stop_reason: String = String(result.get("stop_reason", ""))

	if stop_reason.is_empty():
		dialog.dialog_text = "%d épisode(s) ont été programmés automatiquement." % scheduled_count
	else:
		dialog.dialog_text = "%d épisode(s) sur %d ont été programmés.\n%s" % [
			scheduled_count,
			requested_count,
			stop_reason
		]

	anchor.add_child(dialog)
	UIThemeManagerScript.apply_popup_theme(dialog, anchor)
	dialog.confirmed.connect(func() -> void:
		if is_instance_valid(dialog):
			dialog.queue_free()
	)
	dialog.canceled.connect(func() -> void:
		if is_instance_valid(dialog):
			dialog.queue_free()
	)
	dialog.popup_centered(Vector2i(520, 220))


static func _is_existing_start(
	channel: Dictionary,
	week_number: int,
	day_index: int,
	slot_index: int
) -> bool:
	var day_slots: Array[Dictionary] = GameState.get_player_day_schedule(
		channel,
		week_number,
		day_index
	)
	if slot_index < 0 or slot_index >= day_slots.size():
		return false
	return String(day_slots[slot_index].get("kind", "")) == "start"


static func _place_without_episode(
	channel: Dictionary,
	week_number: int,
	day_index: int,
	slot_index: int,
	program: Dictionary,
	refresh_callback: Callable,
	replace_existing: bool = false
) -> void:
	var placed: bool = false
	if replace_existing:
		placed = GameState.replace_scheduled_program(
			channel,
			week_number,
			day_index,
			slot_index,
			program,
			{}
		)
	else:
		placed = GameState.schedule_program(
			channel,
			week_number,
			day_index,
			slot_index,
			program,
			{}
		)
	if placed and refresh_callback.is_valid():
		refresh_callback.call()


static func _get_day_name(day_index: int) -> String:
	if day_index < 0 or day_index >= DAY_NAMES.size():
		return "Jour"
	return DAY_NAMES[day_index]


static func _get_time_text(slot_index: int) -> String:
	var total_minutes: int = slot_index * SLOT_MINUTES
	var hour: int = int(total_minutes / 60)
	var minute: int = total_minutes % 60
	return "%02dh%02d" % [hour, minute]
