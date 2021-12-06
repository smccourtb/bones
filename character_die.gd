extends RigidBody


signal stopped()
signal die_selected(action)

onready var mesh = $Cube
onready var tween = $Tween
var starting_position: Vector3
var roll: int
var actions: Dictionary


func _ready() -> void:
	connect("stopped", self, "_on_Stopped")


func _physics_process(_delta: float) -> void:
	if linear_velocity.length() < .1:
		emit_signal("stopped")
	else:
		if is_connected("input_event", self, "_on_CharacterDie_input_event"):
			disconnect("input_event", self, "_on_CharacterDie_input_event")
			disconnect("mouse_entered", self, "_on_CharacterDie_mouse_entered")
			disconnect("mouse_exited", self, "_on_CharacterDie_mouse_exited")


func _on_Stopped():
	if not is_connected("input_event", self, "_on_CharacterDie_input_event"):
		connect("input_event", self, "_on_CharacterDie_input_event")
		connect("mouse_entered", self, "_on_CharacterDie_mouse_entered")
		connect("mouse_exited", self, "_on_CharacterDie_mouse_exited")
	
	if $'6'.is_colliding():
		roll = 2
	elif $'5'.is_colliding():
		roll = 1
	elif $'1'.is_colliding():
		roll = 6
	elif $'3'.is_colliding():
		roll = 4
	elif $'4'.is_colliding():
		roll = 5
	elif $'2'.is_colliding():
		roll = 3


func _on_CharacterDie_input_event(_camera: Node, event: InputEvent, _click_position: Vector3, _click_normal: Vector3, _shape_idx: int) -> void:
	var mouse_click = event as InputEventMouseButton
	if mouse_click and mouse_click.button_index == 1 and mouse_click.pressed:
		emit_signal("die_selected", actions[roll])


func build_die(faces: Dictionary, color: Color):
	for i in range(mesh.get_surface_material_count()):
		var x = mesh.get_active_material(i).duplicate()
		x.albedo_color = color
		x.detail_enabled = true
		x.detail_albedo = faces[i+1].texture
		mesh.set_surface_material(i, x)
	actions = faces


func reset():
	linear_velocity = Vector3(1,1,1)
	angular_velocity = Vector3(0,0,3)
	translation = Vector3(0, 24, 0)
	scale = Vector3.ONE


func _on_CharacterDie_mouse_entered() -> void:
	tween.interpolate_property(self, "scale", null, Vector3(1.3, 1.3, 1.3), .1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()


func _on_CharacterDie_mouse_exited() -> void:
	tween.interpolate_property(self, "scale", null, Vector3(1, 1, 1), .1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
