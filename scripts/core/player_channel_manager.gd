class_name PlayerChannelManager
extends RefCounted

signal channel_created(channel: Dictionary)

const FIRST_CHANNEL_MMTN_NUMBER: int = 2
const FIRST_CHANNEL_THEME: String = "Généraliste"

var _channels: Array[Dictionary] = []


func reset() -> void:
	_channels.clear()


func has_first_channel() -> bool:
	return not _channels.is_empty()


func create_first_channel(channel_name: String) -> bool:
	var clean_name: String = channel_name.strip_edges()
	if clean_name.is_empty() or has_first_channel():
		return false

	var channel: Dictionary = {
		"mmtn_number": FIRST_CHANNEL_MMTN_NUMBER,
		"name": clean_name,
		"theme": FIRST_CHANNEL_THEME,
		"theme_locked": true,
		"source": "initial"
	}
	_channels.append(channel)
	channel_created.emit(channel)
	return true


func get_first_channel() -> Dictionary:
	if _channels.is_empty():
		return {}
	return _channels[0].duplicate(true)


func get_channels() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for channel: Dictionary in _channels:
		result.append(channel.duplicate(true))
	return result
