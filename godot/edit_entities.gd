tool
extends Spatial

export(Array, Resource) var exteriors = []


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
var buildings = []

#func _get_property_list():
#	var ret = []
#	for e in range(buildings.size()):
#		var n = {
#				"name": "buildings/" + str(e) + "/exterior",
#				"type": TYPE_OBJECT,
#				"hint": PROPERTY_HINT_RESOURCE_TYPE,
#				"hint_string": "ExteriorSet",
#				"usage": PROPERTY_USAGE_DEFAULT
#			}
#		ret.push_back(n)
#		var m = {
#				"name": "buildings/" + str(e) + "/interior",
#				"type": TYPE_OBJECT,
#				"hint": PROPERTY_HINT_RESOURCE_TYPE,
#				"hint_string": "InteriorSet",
#				"usage": PROPERTY_USAGE_DEFAULT
#			}
#		ret.push_back(m)
#	var n1 = {
#			"name": "buildings/new/exterior",
#			"type": TYPE_OBJECT,
#			"hint": PROPERTY_HINT_RESOURCE_TYPE,
#			"hint_string": "ExteriorSet",
#			"usage": PROPERTY_USAGE_DEFAULT
#		}
#	ret.push_back(n1)
#	var n2 = {
#			"name": "buildings/new/interior",
#			"type": TYPE_OBJECT,
#			"hint": PROPERTY_HINT_RESOURCE_TYPE,
#			"hint_string": "ExteriorSet",
#			"usage": PROPERTY_USAGE_DEFAULT
#		}
#	ret.push_back(n1)
#	return ret
#func _get(pname):
#	match pname:
#		"buildings/new/exterior":
#			return ExteriorSet.new()
#		"buildings/new/interior":
#			return InteriorSet.new()
#		"_":
#			if pname.begins_with("buildings/"):
#				var d = pname.split("/")
#				var id = int(d[1])
#				if pname.ends_with("/exterior"):
#					return buildings[id]
#			return null
#	return null
#func _set(pname, value):
#	match pname:
#		"buildings/new/exterior":
#			buildings.push_back(value)
#	property_list_changed_notify()
#
