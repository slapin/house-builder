extends Resource

class_name InteriorSet

export var wall: Mesh
export var wall_half: Mesh
export var doorway: Mesh
export var window: Mesh
export var internal_angle: Mesh
export var interior_floor: Mesh
export var interior_ceiling: Mesh
func get_items():
	var items = {
		"iwall": {
			"mesh": wall,
			"size": 2
		},
		"iwallh": {
			"mesh": wall_half,
			"size": 1
		},
		"idoor": {
			"mesh": doorway,
			"size": 2
		},
		"iwindow": {
			"mesh": window,
			"size": 2
		},
		"iangle": {
			"mesh": internal_angle,
			"size": 0
		},
		"floor": {
			"mesh": interior_floor,
			"size": 2
		},
		"ceiling": {
			"mesh": interior_ceiling,
			"size": 0
		},
	}
	return items
var items = {} setget , get_items
