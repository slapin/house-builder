tool
extends EditorPlugin

class AddNewBuildingType extends EditorProperty:
	func _init():
		var button = Button.new()
		button.text = "+"
		add_child(button)

class BuildingEditor extends EditorInspectorPlugin:
	func can_handle(object):
		if object is CityParameters:
			print("can handle")
			return true
	func parse_property(object, type, path, hint, hint_text, usage):
		if object is CityParameters:
			if path.ends_with("new_data"):
				add_property_editor(path, AddNewBuildingType.new())
				return true
			if type == TYPE_OBJECT:
				if path.ends_with("/exterior"):
					add_property_editor(path, EditorProperty.new())
					return true
		print(path)
		return false


func _enter_tree():
	add_inspector_plugin(BuildingEditor.new())


func _exit_tree():
	pass
