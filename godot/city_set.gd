extends Resource

class_name CitySet

export var guildhall_building_set: Resource
export(Array, Resource) var building_sets = []
export var center_radius: float = 100.0
export var radius: int = 1000
export var max_buildings = 10
export var min_buildings = 15

func get_items():
	var items = {}
	for e in [guildhall_building_set] + building_sets:
		items[e.house_type] = e.items.duplicate()
	return items
var items = {} setget , get_items
