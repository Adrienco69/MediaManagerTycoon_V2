class_name LaunchSeriesTelefilmDistribution
extends RefCounted

const SERIES_TELEFILMS: Array[Dictionary] = [
	{"name": "Un ange s’en charge", "episodes": 126},
	{"name": "Un paradis au camping", "episodes": 94},
	{"name": "Une école, une histoire", "episodes": 48}
]


static func draw() -> Dictionary:
	var pool: Array[Dictionary] = []
	for item: Dictionary in SERIES_TELEFILMS:
		pool.append(item.duplicate(true))
	pool.shuffle()

	return {
		"player": pool[0].duplicate(true),
		"mg1": pool[1].duplicate(true),
		"shop": pool[2].duplicate(true)
	}
