class_name TVGridPageController
extends RefCounted

const WeekSelectorScript = preload("res://scripts/ui/schedule_week_selector.gd")
const DayScheduleBuilderScript = preload("res://scripts/ui/tv_day_schedule_builder.gd")
const ProgramCatalogPanelScript = preload("res://scripts/ui/program_catalog_panel.gd")
const DYNAMIC_NODE_NAME: String = "GridDynamic"


static func render(
	content_container: VBoxContainer,
	page_description: Label,
	channel: Dictionary,
	editable: bool,
	programs: Array[Dictionary],
	on_back: Callable = Callable()
) -> void:
	clear(content_container)
	page_description.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	page_description.text = _get_description(channel, editable)

	var dynamic: VBoxContainer = VBoxContainer.new()
	dynamic.name = DYNAMIC_NODE_NAME
	dynamic.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dynamic.add_theme_constant_override("separation", 10)
	content_container.add_child(dynamic)

	if on_back.is_valid():
		var back_button: Button = Button.new()
		back_button.text = "← Retour à Zap'Chaine"
		back_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		back_button.pressed.connect(on_back)
		dynamic.add_child(back_button)

	var body: HBoxContainer = HBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	dynamic.add_child(body)

	var catalog_holder: VBoxContainer = VBoxContainer.new()
	catalog_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	catalog_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	catalog_holder.size_flags_stretch_ratio = 1.0
	catalog_holder.custom_minimum_size = Vector2(220, 0)
	body.add_child(catalog_holder)
	ProgramCatalogPanelScript.build(catalog_holder, editable, programs)

	var scheduler_holder: VBoxContainer = VBoxContainer.new()
	scheduler_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scheduler_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scheduler_holder.size_flags_stretch_ratio = 3.0
	scheduler_holder.add_theme_constant_override("separation", 10)
	body.add_child(scheduler_holder)

	var schedule_holder: VBoxContainer = VBoxContainer.new()
	schedule_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	schedule_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var rebuild_schedule: Callable = func(week_number: int) -> void:
		_clear_holder(schedule_holder)
		DayScheduleBuilderScript.build(schedule_holder, week_number, editable)

	var selector_row: HBoxContainer = WeekSelectorScript.build(rebuild_schedule)
	scheduler_holder.add_child(selector_row)
	scheduler_holder.add_child(schedule_holder)

	rebuild_schedule.call(1)


static func clear(content_container: VBoxContainer) -> void:
	var existing: Node = content_container.get_node_or_null(DYNAMIC_NODE_NAME)
	if existing != null:
		content_container.remove_child(existing)
		existing.queue_free()


static func _get_description(channel: Dictionary, editable: bool) -> String:
	var channel_name: String = String(channel.get("name", ""))
	if editable:
		return "Chaîne : %s | programmation modifiable jusqu'à 52 semaines." % channel_name
	return "Chaîne : %s | consultation uniquement, aucune modification possible." % channel_name


static func _clear_holder(holder: VBoxContainer) -> void:
	for child: Node in holder.get_children():
		holder.remove_child(child)
		child.queue_free()
