class_name ProductionPageController
extends RefCounted

const ProductionTableBuilderScript = preload("res://scripts/ui/production_table_builder.gd")
const DYNAMIC_NODE_NAME: String = "ProductionDynamic"


static func render(
	content_container: VBoxContainer,
	page_description: Label,
	active_productions: Array[Dictionary],
	on_create_production: Callable
) -> void:
	clear(content_container)
	page_description.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	page_description.text = "Les productions restent ici jusqu'à leur fin complète. Aucun épisode n'est diffusable avant la fin de toute la production."

	var dynamic: VBoxContainer = VBoxContainer.new()
	dynamic.name = DYNAMIC_NODE_NAME
	dynamic.add_theme_constant_override("separation", 12)
	content_container.add_child(dynamic)

	var actions: HBoxContainer = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	dynamic.add_child(actions)

	var create_button: Button = Button.new()
	create_button.text = "Créer une production"
	create_button.custom_minimum_size = Vector2(190, 42)
	create_button.pressed.connect(on_create_production)
	actions.add_child(create_button)

	var info_label: Label = Label.new()
	info_label.text = "%d / 7 sets occupés au Studio 1" % active_productions.size()
	info_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	actions.add_child(info_label)

	ProductionTableBuilderScript.build(dynamic, active_productions)


static func clear(content_container: VBoxContainer) -> void:
	var existing: Node = content_container.get_node_or_null(DYNAMIC_NODE_NAME)
	if existing != null:
		content_container.remove_child(existing)
		existing.queue_free()
