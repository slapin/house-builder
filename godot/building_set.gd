extends Resource

class_name BuildingSet

export var house_type: String = ""
export var min_wings: int = 1
export var max_wings: int = 1
export var min_wing_size_x: int = 4
export var min_wing_size_z: int = 4
export var max_wing_size_x: int = 8
export var max_wing_size_z: int = 8
export var pwindow: float = 0.6
export var pmidwall: float = 0.2
export var exterior_set: Resource
export var interior_set: Resource

func get_items():
	var items = {}
	for e in exterior_set.items.keys():
		items[e] = exterior_set.items[e].duplicate()
	for e in interior_set.items.keys():
		items[e] = interior_set.items[e].duplicate()
	return items
var items = {} setget , get_items
