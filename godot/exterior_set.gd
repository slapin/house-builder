extends Resource

class_name ExteriorSet

export var external_wall: Mesh
export var external_wall_half: Mesh
export var external_doorway: Mesh
export var external_window: Mesh
export var external_angle: Mesh
export var roof_main: Mesh
export var roof_side_left: Mesh
export var roof_side_right: Mesh
export var roof_side_left_block: Mesh
export var roof_side_right_block: Mesh

func get_items():
	var items = {
		"xwall": {
			"mesh": external_wall,
			"size": 2
		},
		"xwallh": {
			"mesh": external_wall_half,
			"size": 1
		},
		"xdoor": {
			"mesh": external_doorway,
			"size": 2
		},
		"xwindow": {
			"mesh": external_window,
			"size": 2
		},
		"xangle": {
			"mesh": external_angle,
			"size": 0
		},
		"roof_main": {
			"mesh": roof_main,
			"size": 2
		},
		"roof_side_left": {
			"mesh": roof_side_left,
			"size": 0
		},
		"roof_side_right": {
			"mesh": roof_side_right,
			"size": 0
		},
		"roof_side_left_block": {
			"mesh": roof_side_left_block,
			"size": 0
		},
		"roof_side_right_block": {
			"mesh": roof_side_right_block,
			"size": 0
		},
	}
	return items
var items = {} setget , get_items
