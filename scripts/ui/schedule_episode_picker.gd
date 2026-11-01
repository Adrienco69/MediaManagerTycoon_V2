class_name ScheduleEpisodePicker
extends RefCounted

const ScheduleEpisodeHelperScript = preload("res://scripts/ui/schedule_episode_helper.gd")

const FREQUENCY_WEEKLY: int = 0
const FREQUENCY_DAILY: int = 1
const SLOT_MINUTES: int = 30
const SLOTS_PER_DAY: int = 48
const DAYS_PER_YEAR: int = 364
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

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	popup.add_child(margin)

	var content: VBoxContainer = VBoxContainer.new()
	content.custom_minimum_size = Vector2(620, 0)
	content.add_theme_constant_override("separation", 10)
	margin.add_child(content)

	var title: Label = Label.new()
	title.text = "Choisir l'épisode | %s" % String(program.get("name", "Programme"))
	title.add_theme_font_size_override("font_size", 22)
	content.add_child(title)

	var hint: Label = Label.new()
	hint.text = "Choisissez un épisode à diffuser ici, ou automatisez la suite sans placer chaque épisode à la main."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(hint)

	var automation_panel: PanelContainer = PanelContainer.new()
	content.add_child(automation_panel)

	var automation_box: VBoxContainer = VBoxContainer.new()
	automation_box.add_theme_constant_override("separation", 6)
	automation_panel.add_child(automation_box)

	var automation_title: Label = Label.new()
	automation_title.text = "Automatisation"
	automation_title.add_theme_font_size_override("font_size", 18)
	automation_box.add_child(automation_title)

	var frequency_row: HBoxContainer = HBoxContainer.new()
	frequency_row.add_theme_constant_override("separation", 8)
	automation_box.add_child(frequency_row)

	var frequency_label: Label = Label.new()
	frequency_label.text = "Fréquence :"
	frequency_label.custom_minimum_size = Vector2(170, 0)
	frequency_row.add_child(frequency_label)

	var frequency_selector: OptionButton = OptionButton.new()
	frequency_selector.add_item("Hebdomadaire", FREQUENCY_WEEKLY)
	frequency_selector.add_item("Quotidienne", FREQUENCY_DAILY)
	frequency_selector.select(0)
	frequency_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frequency_row.add_child(frequency_selector)

	var episodes_per_row: HBoxContainer = HBoxContainer.new()
	episodes_per_row.add_theme_constant_override("separation", 8)
	automation_box.add_child(episodes_per_row)

	var episodes_per_label: Label = Label.new()
	episodes_per_label.text = "Épisodes par soirée :"
	episodes_per_label.custom_minimum_size = Vector2(170, 0)
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
	period_label.custom_minimum_size = Vector2(170, 0)
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

	var automation_hint: Label = Label.new()
	automation_hint.text = "Hebdomadaire : choisissez le nombre d'épisodes diffusés à la suite chaque soirée et le nombre de semaines."
	automation_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	automation_box.add_child(automation_hint)

	frequency_selector.item_selected.connect(func(_index: int) -> void:
		var frequency_id: int = frequency_selector.get_selected_id()
		if frequency_id == FREQUENCY_DAILY:
			episodes_per_label.text = "Épisodes par jour :"
			period_label.text = "Nombre de jours :"
			var start_absolute_day: int = ((week_number - 1) * 7) + day_index
			period_spinner.max_value = maxi(DAYS_PER_YEAR - start_absolute_day, 1)
			automation_hint.text = "Quotidienne : choisissez le nombre d'épisodes diffusés à la suite chaque jour et le nombre de jours."
		else:
			episodes_per_label.text = "Épisodes par soirée :"
			period_label.text = "Nombre de semaines :"
			period_spinner.max_value = maxi(53 - week_number, 1)
			automation_hint.text = "Hebdomadaire : choisissez le nombre d'épisodes diffusés à la suite chaque soirée et le nombre de semaines."
		if period_spinner.value > period_spinner.max_value:
			period_spinner.value = period_spinner.max_value
	)

	var separator: HSeparator = HSeparator.new()
	content.add_child(separator)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 340)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)

	var episode_list: VBoxContainer = VBoxContainer.new()
	episode_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	episode_list.add_theme_constant_override("separation", 6)
	scroll.add_child(episode_list)

	var editing_existing: bool = (
		_is_existing_start(channel, week_number, day_index, slot_index)
		and not replace_existing
	)
	for global_episode: int in range(1, episode_count + 1):
		var episode_data: Dictionary = ScheduleEpisodeHelperScript.get_episode_data(program, global_episode)
		if episode_data.is_empty():
			continue

		var episode_row: HBoxContainer = HBoxContainer.new()
		episode_row.add_theme_constant_override("separation", 6)
		episode_list.add_child(episode_row)

		var episode_button: Button = Button.new()
		episode_button.text = String(episode_data.get("label", "Épisode %d" % global_episode))
		episode_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		episode_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		episode_button.custom_minimum_size = Vector2(0, 40)
		episode_row.add_child(episode_button)

		var auto_button: Button = Button.new()
		auto_button.text = "Automatiser depuis ici"
		auto_button.custom_minimum_size = Vector2(190, 40)
		auto_button.disabled = editing_existing
		auto_button.tooltip_text = (
			"Ce créneau sert actuellement à modifier l'épisode déjà programmé."
			if editing_existing
			else "Programme automatiquement les épisodes suivants."
		)
		episode_row.add_child(auto_button)

		var captured_episode: Dictionary = episode_data.duplicate(true)
		var captured_global_episode: int = global_episode
		episode_button.pressed.connect(func() -> void:
			var saved: bool = false
			if editing_existing:
				saved = GameState.update_scheduled_episode(
					channel,
					week_number,
					day_index,
					slot_index,
					captured_episode
				)
			elif replace_existing:
				saved = GameState.replace_scheduled_program(
					channel,
					week_number,
					day_index,
					slot_index,
					program,
					captured_episode
				)
			else:
				saved = GameState.schedule_program(
					channel,
					week_number,
					day_index,
					slot_index,
					program,
					captured_episode
				)
			if not saved:
				return
			popup.hide()
			if refresh_callback.is_valid():
				refresh_callback.call()
		)

		auto_button.pressed.connect(func() -> void:
			var frequency_id: int = frequency_selector.get_selected_id()
			var episodes_per_period: int = int(episodes_per_spinner.value)
			var period_count: int = int(period_spinner.value)
			var result: Dictionary = _auto_schedule_episodes(
				channel,
				week_number,
				day_index,
				slot_index,
				program,
				captured_global_episode,
				episodes_per_period,
				period_count,
				frequency_id,
				replace_existing
			)
			if refresh_callback.is_valid():
				refresh_callback.call()
			_show_automation_result(anchor, result)
			popup.hide()
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
	popup.popup_centered(Vector2i(700, 700))


static func _auto_schedule_episodes(
	channel: Dictionary,
	start_week: int,
	start_day: int,
	start_slot: int,
	program: Dictionary,
	start_global_episode: int,
	episodes_per_period: int,
	period_count: int,
	frequency_id: int,
	replace_first: bool = false
) -> Dictionary:
	var episode_count: int = ScheduleEpisodeHelperScript.get_episode_count(program)
	var requested_count: int = maxi(episodes_per_period, 1) * maxi(period_count, 1)
	var scheduled_count: int = 0
	var stop_reason: String = ""
	var frequency_name: String = "daily" if frequency_id == FREQUENCY_DAILY else "weekly"
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
	var base_absolute_day: int = ((start_week - 1) * 7) + start_day

	for period_index: int in range(maxi(period_count, 1)):
		var period_absolute_day: int = base_absolute_day
		if frequency_id == FREQUENCY_DAILY:
			period_absolute_day += period_index
		else:
			period_absolute_day += period_index * 7

		if period_absolute_day >= DAYS_PER_YEAR:
			stop_reason = "La fin de l'année 1 a été atteinte."
			break

		var cursor_absolute_slot: int = (period_absolute_day * SLOTS_PER_DAY) + start_slot

		for _episode_in_period: int in range(maxi(episodes_per_period, 1)):
			var global_episode: int = start_global_episode + scheduled_count
			if global_episode > episode_count:
				stop_reason = "Aucun épisode disponible pour poursuivre l'automatisation."
				break

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
				stop_reason = "Aucun épisode disponible pour poursuivre l'automatisation."
				break
			episode_data["automation_id"] = automation_id
			episode_data["automation_frequency"] = frequency_name

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

	return {
		"scheduled_count": scheduled_count,
		"requested_count": requested_count,
		"stop_reason": stop_reason
	}


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
