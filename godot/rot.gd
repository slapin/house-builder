extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
#func _ready():
#	$Camera.set_as_toplevel(true)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
var mode = 0
func _process(delta):
	var motionx = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	var motionz = Input.get_action_strength("ui_up") - Input.get_action_strength("ui_down")
	rotate_y(-motionx * delta * 3.0)
#	$Camera.look_at(Vector3(), Vector3.UP)
	translation -= global_transform.basis[2] * motionz * delta * 10.0
	if Input.is_action_just_pressed("ui_accept"):
		mode = mode + 1
		mode = mode % 3
		var pos: Vector3
		match mode:
			0:
				pos = Vector3(0, 2, 3)
			1:
				pos = Vector3(0, 10, 15)
			2:
				pos = Vector3(0, 10, 0.8)
		var cam_t: Transform = $Camera.global_transform
		cam_t.origin = global_transform.origin + pos
		cam_t = cam_t.looking_at(global_transform.origin + Vector3(0, 1, 0), Vector3.UP)
		$Camera.global_transform = cam_t
