class_name ProductionManager
extends RefCounted

const LaunchProgramCatalogScript = preload("res://scripts/core/launch_program_catalog.gd")

var _programs: Array[Dictionary] = []


func reset() -> void:
	_programs.clear()


func assign_launch_programs(channel_name: String) -> void:
	if not _programs.is_empty():
		return
	_programs = LaunchProgramCatalogScript.build(channel_name)


func get_programs() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for program: Dictionary in _programs:
		result.append(program.duplicate(true))
	return result
